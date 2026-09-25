--[[
	Opening cases. The server rolls, charges and grants the items before the client
	animates anything; the spin is purely a replay of a result that is already saved.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)
local Roller = require(Shared.Roller)
local Signal = require(Shared.Signal)

local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local Passes = require(script.Parent.Passes)
local PlayerState = require(script.Parent.PlayerState)
local ServerLuckService = require(script.Parent.ServerLuckService)
local SerialService = require(script.Parent.SerialService)
local Throttle = require(script.Parent.Throttle)

type Data = DataService.Data

export type Result = {
	Id: string,
	I: string,
	B: string,
	M: string?,
	N: number?, -- serial number (numbered items)
	Supply: number?, -- total copies that can exist (Limited items)
	Gem: boolean,
	Value: number,
}

local CaseService = {}
-- (player, case, results) after every successful open, including free and Robux cases.
CaseService.Opened = Signal.new() :: Signal.Signal<Player, Catalog.Case, { Result }>

local rng = Random.new()
local canOpen = Throttle.new(GameConfig.OpenCooldown)
local paidOpenEvent: RemoteEvent

local function inventoryError(data: Data, count: number): string?
	local held = PlayerState.countItems(data)
	if held + count > GameConfig.InventoryCap then
		return `Inventory full ({held}/{GameConfig.InventoryCap}). Sell some items first.`
	end
	return nil
end

export type Boost = { Mult: number, Bar: boolean }

--[[
	Rolls `count` items and assigns serials to numbered ones. Luck = the player's permanent
	luck x server luck x the luck bar (when full, it's used up by this open). If a Limited item turns out to
	be sold out while claiming its serial, that item is removed and the pull is rerolled.
	Returns fewer rolls than asked only when the whole case is sold out. May yield (DataStore)
	and may error if serials can't be claimed; nothing is granted in that case.
]]
local function rollWithSerials(player: Player, case: Catalog.Case, count: number): ({ Roller.Roll }, Boost)
	local data = DataService.get(player) :: Data
	local barConfig = GameConfig.LuckBar
	local barFull = data.LuckBar >= barConfig.RollsToFill
	local mult = ServerLuckService.multiplier() * (if barFull then barConfig.Mult else 1)
	local luck = Catalog.boostLuck(PlayerState.luck(player), mult)
	local boost = { Mult = mult, Bar = barFull }
	local force = DebugService.takeForce(player)
	local soldOut = SerialService.soldOut()
	local rolls = {}
	for _ = 1, count do
		while true do
			local rolled = Roller.roll(case, luck, rng, force, soldOut)
			if not rolled then
				break
			end
			local item = Catalog.ItemById[rolled.I]
			if not item.Exclusive then
				table.insert(rolls, rolled)
				break
			end
			local serial = SerialService.allocate(item.Id)
			if serial then
				rolled.N = serial
				table.insert(rolls, rolled)
				break
			end
			soldOut[item.Id] = true
		end
	end

	if #rolls > 0 then
		if barFull then
			data.LuckBar = 0
		end
		data.LuckBar = math.min(data.LuckBar + #rolls, barConfig.RollsToFill)
		PlayerState.sync(player, "LuckBar", data.LuckBar)
	end
	return rolls, boost
end

local function grant(player: Player, data: Data, case: Catalog.Case, rolls: { Roller.Roll }): { Result }
	local added = PlayerState.addItems(player, rolls)
	local results: { Result } = {}
	for index, entry in added do
		local value = Catalog.valueOf(entry.Owned)
		local gem = rolls[index].Gem
		table.insert(results, {
			Id = entry.Id,
			I = entry.Owned.I,
			B = entry.Owned.B,
			M = entry.Owned.M,
			N = entry.Owned.N,
			Supply = Catalog.ItemById[entry.Owned.I].Supply,
			Gem = gem,
			Value = value,
		})
		data.Stats.Opened += 1
		if gem then
			data.Stats.GemHits += 1
		end
		data.Stats.BestValue = math.max(data.Stats.BestValue, value)

		-- Grails are bragging rights: tell the whole server.
		local item = Catalog.ItemById[entry.Owned.I]
		local rarity = Catalog.RarityById[item.Rarity]
		if rarity.Fx >= 6 then
			local serial = if entry.Owned.N then ` #{entry.Owned.N}` else ""
			for _, other in Players:GetPlayers() do
				PlayerState.notify(
					other,
					`🏆 {player.DisplayName} pulled {rarity.Name} {item.Name}{serial} from {case.Name}!`,
					"gold"
				)
			end
		end
	end
	PlayerState.sync(player, "Stats", data.Stats)
	CaseService.Opened:Fire(player, case, results)
	return results
end

local function openCase(player: Player, data: Data, caseId: any, count: any)
	if type(caseId) ~= "string" or type(count) ~= "number" then
		return { ok = false, error = "Bad request." }
	end
	local case = Catalog.CaseById[caseId]
	if not case then
		return { ok = false, error = "That case doesn't exist." }
	end
	if case.Paid then
		return { ok = false, error = "This case is opened with Robux." }
	end
	if count ~= math.floor(count) or count < 1 or count > Passes.maxOpen(player) then
		return { ok = false, error = "You can't open that many at once." }
	end
	if not canOpen(player) then
		return { ok = false, error = "Slow down!" }
	end
	local full = inventoryError(data, count)
	if full then
		return { ok = false, error = full }
	end

	local keys = math.min(data.Keys[caseId] or 0, count)
	local cost = (count - keys) * case.Price
	if data.Cash < cost then
		return { ok = false, error = "Not enough cash." }
	end
	PlayerState.takeKeys(player, caseId, keys)
	PlayerState.trySpend(player, cost)

	local rolls, boost = rollWithSerials(player, case, count)
	return {
		ok = true,
		CaseId = caseId,
		Results = grant(player, data, case, rolls),
		KeysUsed = keys,
		Cost = cost,
		LuckMult = boost.Mult,
		BarBoost = boost.Bar,
	}
end

local function claimFreeCase(player: Player, data: Data)
	local now = os.time()
	local readyAt = data.LastFreeCase + GameConfig.FreeCase.Cooldown
	if now < readyAt then
		return { ok = false, error = "Your free case isn't ready yet." }
	end
	local full = inventoryError(data, 1)
	if full then
		return { ok = false, error = full }
	end
	local case = Catalog.CaseById[GameConfig.FreeCase.CaseId]
	data.LastFreeCase = now
	PlayerState.sync(player, "FreeCase", now + GameConfig.FreeCase.Cooldown)
	local rolls, boost = rollWithSerials(player, case, 1)
	return {
		ok = true,
		CaseId = case.Id,
		Results = grant(player, data, case, rolls),
		KeysUsed = 0,
		Cost = 0,
		LuckMult = boost.Mult,
		BarBoost = boost.Bar,
	}
end

--[[
	Opens a Robux case that has already been paid for (called from ProcessReceipt, or from
	the developer tools with quiet = true). Ignores the inventory cap: a purchase can't be
	refused after payment. If every item is sold out the buyer gets GameConfig.SoldOutCash.
	Errors if serials can't be claimed, so the receipt is retried later.
]]
function CaseService.openPaid(player: Player, case: Catalog.Case, quiet: boolean?): { [string]: any }
	local data = DataService.get(player)
	if not data then
		error("player data not loaded")
	end
	local rolls, boost = rollWithSerials(player, case, 1)
	local response
	if #rolls == 0 then
		PlayerState.addCash(player, GameConfig.SoldOutCash)
		response = {
			ok = false,
			error = `{case.Name} just sold out, so you got {GameConfig.SoldOutCash} cash instead.`,
			CaseId = case.Id,
		}
	else
		response = {
			ok = true,
			CaseId = case.Id,
			Results = grant(player, data, case, rolls),
			KeysUsed = 0,
			Cost = 0,
			LuckMult = boost.Mult,
			BarBoost = boost.Bar,
		}
	end
	if not quiet then
		paidOpenEvent:FireClient(player, case.Id, response)
	end
	return response
end

function CaseService.start()
	assert(
		Catalog.CaseById[GameConfig.FreeCase.CaseId],
		`GameConfig.FreeCase.CaseId "{GameConfig.FreeCase.CaseId}" is not a case`
	)
	paidOpenEvent = Net.event("PaidOpen")
	PlayerState.bind("OpenCase", openCase)
	PlayerState.bind("ClaimFreeCase", claimFreeCase)

	DebugService.openPaid = function(player: Player, caseId: string)
		local case = Catalog.CaseById[caseId]
		if not case or not case.Paid then
			return { ok = false, error = "Not a Robux case." }
		end
		return CaseService.openPaid(player, case, true)
	end
end

return CaseService
