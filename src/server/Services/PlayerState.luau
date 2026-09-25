--[[
	The one place that changes a player's cash, items, keys and showcase, and tells their
	client about it. Other services call these functions instead of editing data directly,
	so the client mirror and the leaderboard never drift.

	Sync kinds sent to the client:
		"State"    full snapshot
		"Cash"     number
		"Items"    { Added = {[id] = owned}?, Changed = {[id] = owned}?, Removed = {id}? }
		"Keys"     {[caseId] = count}
		"Income"   cash per second
		"Slots"    showcase slot count
		"Luck"     luck upgrade level
		"Rebirths" rebirth count
		"PersonalLuck" personal Robux luck purchases
		"LuckBar"  items opened toward the next 10x luck bar
		"ServerLuck" { Mult, EndsAt, Boosts } server-wide timed luck
		"Force"    developer overrides armed for the next open ({ Gem?, Mutation? })
		"Serials"  copies issued so far per numbered item ({ [itemId] = count })
		"FreeCase" unix time the free case is ready
		"Passes"   {[passKey] = true}
		"Stats"    lifetime stats
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)
local Roller = require(Shared.Roller)

local DataService = require(script.Parent.DataService)
local Passes = require(script.Parent.Passes)

type Data = DataService.Data

local MAX_IDS_PER_CALL = 500

local PlayerState = {}

local incomes: { [Player]: number } = {}
local syncEvent: RemoteEvent
local notifyEvent: RemoteEvent

function PlayerState.sync(player: Player, kind: string, payload: any)
	syncEvent:FireClient(player, kind, payload)
end

function PlayerState.notify(player: Player, text: string, kind: string?)
	notifyEvent:FireClient(player, text, kind or "info")
end

-- Wraps a RemoteFunction handler: waits for data, validates nothing crashes the caller,
-- and always returns a { ok, error?, ... } table.
function PlayerState.bind(name: string, handler: (Player, Data, ...any) -> { [string]: any })
	Net.fn(name).OnServerInvoke = function(player: Player, ...)
		local data = DataService.get(player)
		if not data then
			return { ok = false, error = "Your data is still loading." }
		end
		local ok, result = pcall(handler, player, data, ...)
		if not ok then
			warn(`[{name}] {player.Name}: {result}`)
			return { ok = false, error = "Something went wrong. Try again." }
		end
		return result
	end
end

-- Permanent luck (upgrade level, rebirths, Luck pass, personal Robux stack, Mutation Luck
-- pass). Temporary boosts are added on top by CaseService.
function PlayerState.luck(player: Player): Catalog.Luck
	local data = DataService.get(player)
	return Catalog.luckFor(
		if data then data.LuckLevel else 0,
		Passes.has(player, "Luck"),
		if data then data.PersonalLuck else 0,
		Passes.has(player, "MutationLuck"),
		if data then data.Rebirths else 0
	)
end

-- Rebirth bonus on sell value and showcase income.
function PlayerState.sellMult(player: Player): number
	local data = DataService.get(player)
	return Catalog.rebirthSellMult(if data then data.Rebirths else 0)
end

function PlayerState.debugAllowed(player: Player): boolean
	local debug = GameConfig.Debug
	return debug.Enabled and (RunService:IsStudio() or table.find(debug.Admins, player.UserId) ~= nil)
end

function PlayerState.snapshot(player: Player): { [string]: any }?
	local data = DataService.get(player)
	if not data then
		return nil
	end
	return {
		Cash = data.Cash,
		Items = data.Items,
		ShowcaseSlots = data.ShowcaseSlots,
		LuckLevel = data.LuckLevel,
		Rebirths = data.Rebirths,
		PersonalLuck = data.PersonalLuck,
		LuckBar = data.LuckBar,
		Debug = PlayerState.debugAllowed(player),
		Keys = data.Keys,
		FreeCaseReadyAt = data.LastFreeCase + GameConfig.FreeCase.Cooldown,
		Passes = Passes.list(player),
		Income = PlayerState.income(player),
		Stats = data.Stats,
	}
end

-- Cash -----------------------------------------------------------------------------------------

local function updateLeaderstats(player: Player, data: Data)
	local stats = player:FindFirstChild("leaderstats")
	local cash = stats and stats:FindFirstChild("Cash")
	if cash and cash:IsA("StringValue") then
		cash.Value = Format.cash(data.Cash)
	end
end

function PlayerState.addCash(player: Player, amount: number)
	local data = DataService.get(player)
	if not data or amount == 0 then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.Stats.Earned += amount
	end
	updateLeaderstats(player, data)
	PlayerState.sync(player, "Cash", data.Cash)
end

function PlayerState.trySpend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or data.Cash < amount then
		return false
	end
	if amount > 0 then
		PlayerState.addCash(player, -amount)
	end
	return true
end

-- Keys -----------------------------------------------------------------------------------------

function PlayerState.addKeys(player: Player, caseId: string, count: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.Keys[caseId] = (data.Keys[caseId] or 0) + count
	PlayerState.sync(player, "Keys", data.Keys)
end

function PlayerState.takeKeys(player: Player, caseId: string, wanted: number): number
	local data = DataService.get(player)
	if not data then
		return 0
	end
	local taken = math.min(data.Keys[caseId] or 0, wanted)
	if taken > 0 then
		data.Keys[caseId] -= taken
		if data.Keys[caseId] <= 0 then
			data.Keys[caseId] = nil
		end
		PlayerState.sync(player, "Keys", data.Keys)
	end
	return taken
end

-- Items & income -------------------------------------------------------------------------------

function PlayerState.countItems(data: Data): number
	local count = 0
	for _ in data.Items do
		count += 1
	end
	return count
end

function PlayerState.countShowcased(data: Data): number
	local count = 0
	for _, owned in data.Items do
		if owned.S then
			count += 1
		end
	end
	return count
end

function PlayerState.income(player: Player): number
	return incomes[player] or GameConfig.Showcase.BaseIncome
end

-- Showcase income only (no base), used for offline earnings and cash packs.
function PlayerState.showcaseIncome(player: Player): number
	return PlayerState.income(player) - GameConfig.Showcase.BaseIncome
end

function PlayerState.recomputeIncome(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local income = 0
	for _, owned in data.Items do
		if owned.S then
			income += Catalog.incomeOf(Catalog.valueOf(owned))
		end
	end
	if Passes.has(player, "DoubleIncome") then
		income *= 2
	end
	income *= Catalog.rebirthSellMult(data.Rebirths)
	income += GameConfig.Showcase.BaseIncome
	incomes[player] = income
	PlayerState.sync(player, "Income", income)
end

export type NewItem = { Id: string, Owned: Catalog.Owned }

function PlayerState.addItems(player: Player, rolls: { Roller.Roll }): { NewItem }
	local data = DataService.get(player)
	if not data then
		return {}
	end
	local added = {}
	local list = {}
	for _, roll in rolls do
		local id = tostring(data.NextId)
		data.NextId += 1
		local owned: Catalog.Owned = { I = roll.I, B = roll.B, M = roll.M, N = roll.N, T = os.time() }
		data.Items[id] = owned
		added[id] = owned
		table.insert(list, { Id = id, Owned = owned })
	end
	PlayerState.sync(player, "Items", { Added = added })
	return list
end

-- Sells the given ids (skipping locked ones). Returns total cash and how many sold.
function PlayerState.sell(player: Player, ids: { string }): (number, number)
	local data = DataService.get(player)
	if not data then
		return 0, 0
	end
	local total, count = 0, 0
	local removed = {}
	local showcaseChanged = false
	for _, id in ids do
		local owned = data.Items[id]
		if owned and not owned.L then
			total += Catalog.valueOf(owned)
			count += 1
			showcaseChanged = showcaseChanged or owned.S == true
			data.Items[id] = nil
			table.insert(removed, id)
		end
	end
	if count > 0 then
		total = math.floor(total * Catalog.rebirthSellMult(data.Rebirths) + 0.5)
		PlayerState.sync(player, "Items", { Removed = removed })
		PlayerState.addCash(player, total)
		if showcaseChanged then
			PlayerState.recomputeIncome(player)
		end
	end
	return total, count
end

-- Remote handlers ------------------------------------------------------------------------------

local function validIds(ids: any): { string }?
	if type(ids) ~= "table" or #ids > MAX_IDS_PER_CALL then
		return nil
	end
	for _, id in ids do
		if type(id) ~= "string" or #id > 16 then
			return nil
		end
	end
	return ids
end

local function sellItems(player: Player, _data: Data, ids: any)
	local list = validIds(ids)
	if not list then
		return { ok = false, error = "Bad request." }
	end
	local total, count = PlayerState.sell(player, list)
	return { ok = true, Total = total, Count = count }
end

local function sellAll(player: Player, data: Data, maxOrder: any)
	if type(maxOrder) ~= "number" or maxOrder ~= maxOrder then
		return { ok = false, error = "Bad request." }
	end
	local ids = {}
	for id, owned in data.Items do
		local rarity = Catalog.rarityOf(owned)
		-- Grail tiers are never bulk-sold; sell them one at a time on purpose.
		if rarity and rarity.Order <= maxOrder and rarity.Fx < 6 and not owned.L and not owned.S then
			table.insert(ids, id)
		end
	end
	local total, count = PlayerState.sell(player, ids)
	return { ok = true, Total = total, Count = count }
end

local function setLocked(player: Player, data: Data, id: any, locked: any)
	if type(id) ~= "string" or type(locked) ~= "boolean" or not data.Items[id] then
		return { ok = false, error = "That item doesn't exist." }
	end
	local owned = data.Items[id]
	owned.L = if locked then true else nil
	PlayerState.sync(player, "Items", { Changed = { [id] = owned } })
	return { ok = true }
end

local function setShowcased(player: Player, data: Data, id: any, showcased: any)
	if type(id) ~= "string" or type(showcased) ~= "boolean" or not data.Items[id] then
		return { ok = false, error = "That item doesn't exist." }
	end
	local owned = data.Items[id]
	if showcased and not owned.S and PlayerState.countShowcased(data) >= data.ShowcaseSlots then
		return { ok = false, error = "Your showcase is full. Buy a slot or take an item out." }
	end
	owned.S = if showcased then true else nil
	PlayerState.sync(player, "Items", { Changed = { [id] = owned } })
	PlayerState.recomputeIncome(player)
	return { ok = true }
end

local function showcaseBest(player: Player, data: Data)
	local ranked = {}
	for id, owned in data.Items do
		table.insert(ranked, { Id = id, Value = Catalog.valueOf(owned) })
	end
	table.sort(ranked, function(a, b)
		return a.Value > b.Value
	end)

	local changed = {}
	for index, entry in ranked do
		local owned = data.Items[entry.Id]
		local shouldShow = index <= data.ShowcaseSlots
		if (owned.S == true) ~= shouldShow then
			owned.S = if shouldShow then true else nil
			changed[entry.Id] = owned
		end
	end
	if next(changed) then
		PlayerState.sync(player, "Items", { Changed = changed })
		PlayerState.recomputeIncome(player)
	end
	return { ok = true }
end

local function onLoaded(player: Player, data: Data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = data.Rebirths
	rebirths.Parent = stats
	stats.Parent = player
	updateLeaderstats(player, data)

	PlayerState.recomputeIncome(player)
	PlayerState.sync(player, "State", PlayerState.snapshot(player))
end

function PlayerState.start()
	syncEvent = Net.event("Sync")
	notifyEvent = Net.event("Notify")

	Net.fn("GetState").OnServerInvoke = function(player: Player)
		DataService.waitFor(player, 30)
		return PlayerState.snapshot(player)
	end

	PlayerState.bind("SellItems", sellItems)
	PlayerState.bind("SellAll", sellAll)
	PlayerState.bind("SetLocked", setLocked)
	PlayerState.bind("SetShowcased", setShowcased)
	PlayerState.bind("ShowcaseBest", showcaseBest)

	DataService.Loaded:Connect(onLoaded)
	Passes.Changed:Connect(function(player)
		if DataService.get(player) then
			PlayerState.sync(player, "Passes", Passes.list(player))
			PlayerState.recomputeIncome(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		incomes[player] = nil
	end)
end

return PlayerState
