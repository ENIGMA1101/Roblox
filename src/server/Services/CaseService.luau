--[[
	Opening cases. The server rolls, charges and grants the items before the client
	animates anything; the spin is purely a replay of a result that is already saved.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Roller = require(Shared.Roller)
local Signal = require(Shared.Signal)

local DataService = require(script.Parent.DataService)
local DebugService = require(script.Parent.DebugService)
local Passes = require(script.Parent.Passes)
local PlayerState = require(script.Parent.PlayerState)
local Throttle = require(script.Parent.Throttle)

type Data = DataService.Data

export type Result = {
	Id: string,
	I: string,
	B: string,
	M: string?,
	Gem: boolean,
	Value: number,
}

local CaseService = {}
-- (player, case, results) after every successful open, including free cases.
CaseService.Opened = Signal.new() :: Signal.Signal<Player, Catalog.Case, { Result }>

local rng = Random.new()
local canOpen = Throttle.new(GameConfig.OpenCooldown)

local function inventoryError(data: Data, count: number): string?
	local held = PlayerState.countItems(data)
	if held + count > GameConfig.InventoryCap then
		return `Inventory full ({held}/{GameConfig.InventoryCap}). Sell some items first.`
	end
	return nil
end

local function roll(player: Player, data: Data, case: Catalog.Case, count: number): { Result }
	local luck = PlayerState.luck(player)
	local force = DebugService.takeForce(player)
	local rolls = {}
	for _ = 1, count do
		table.insert(rolls, Roller.roll(case, luck, rng, force))
	end

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
			Gem = gem,
			Value = value,
		})
		data.Stats.Opened += 1
		if gem then
			data.Stats.GemHits += 1
		end
		data.Stats.BestValue = math.max(data.Stats.BestValue, value)
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

	return { ok = true, CaseId = caseId, Results = roll(player, data, case, count), KeysUsed = keys, Cost = cost }
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
	return { ok = true, CaseId = case.Id, Results = roll(player, data, case, 1), KeysUsed = 0, Cost = 0 }
end

function CaseService.start()
	assert(
		Catalog.CaseById[GameConfig.FreeCase.CaseId],
		`GameConfig.FreeCase.CaseId "{GameConfig.FreeCase.CaseId}" is not a case`
	)
	PlayerState.bind("OpenCase", openCase)
	PlayerState.bind("ClaimFreeCase", claimFreeCase)
end

return CaseService
