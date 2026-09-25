--[[
	Client mirror of the player's server data. Read-only here: every change arrives from the
	server's Sync event. UI listens to State.Changed(kind) to refresh.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)
local Signal = require(Shared.Signal)

local State = {
	Loaded = false,
	Cash = 0,
	Income = GameConfig.Showcase.BaseIncome,
	Items = {} :: { [string]: Catalog.Owned },
	Keys = {} :: { [string]: number },
	ShowcaseSlots = GameConfig.Showcase.BaseSlots,
	LuckLevel = 0,
	PersonalLuck = 0,
	LuckBar = 0,
	ServerLuck = { Mult = 1, EndsAt = 0, Boosts = {} } :: { Mult: number, EndsAt: number, Boosts: { any } },
	Debug = false,
	Force = {} :: { Gem: string?, Mutation: string? },
	Serials = {} :: { [string]: number },
	FreeCaseReadyAt = 0,
	Passes = {} :: { [string]: boolean },
	Stats = {} :: { [string]: number },
}

State.Changed = Signal.new() :: Signal.Signal<string>

local function apply(kind: string, payload: any)
	if kind == "State" then
		if type(payload) ~= "table" then
			return
		end
		State.Cash = payload.Cash
		State.Income = payload.Income
		State.Items = payload.Items
		State.Keys = payload.Keys
		State.ShowcaseSlots = payload.ShowcaseSlots
		State.LuckLevel = payload.LuckLevel or 0
		State.PersonalLuck = payload.PersonalLuck or 0
		State.LuckBar = payload.LuckBar or 0
		State.Debug = payload.Debug == true
		State.FreeCaseReadyAt = payload.FreeCaseReadyAt
		State.Passes = payload.Passes
		State.Stats = payload.Stats
		State.Loaded = true
	elseif kind == "Cash" then
		State.Cash = payload
	elseif kind == "Income" then
		State.Income = payload
	elseif kind == "Items" then
		for id, owned in payload.Added or {} do
			State.Items[id] = owned
		end
		for id, owned in payload.Changed or {} do
			State.Items[id] = owned
		end
		for _, id in payload.Removed or {} do
			State.Items[id] = nil
		end
	elseif kind == "Keys" then
		State.Keys = payload
	elseif kind == "Slots" then
		State.ShowcaseSlots = payload
	elseif kind == "Luck" then
		State.LuckLevel = payload
	elseif kind == "PersonalLuck" then
		State.PersonalLuck = payload
	elseif kind == "LuckBar" then
		State.LuckBar = payload
	elseif kind == "ServerLuck" then
		State.ServerLuck = payload
	elseif kind == "Force" then
		State.Force = payload
	elseif kind == "Serials" then
		State.Serials = payload
	elseif kind == "FreeCase" then
		State.FreeCaseReadyAt = payload
	elseif kind == "Passes" then
		State.Passes = payload
	elseif kind == "Stats" then
		State.Stats = payload
	end
	State.Changed:Fire(kind)
end

function State.start()
	Net.event("Sync").OnClientEvent:Connect(apply)
	task.spawn(function()
		local snapshot = Net.fn("GetState"):InvokeServer()
		if snapshot and not State.Loaded then
			apply("State", snapshot)
		end
	end)
end

function State.hasPass(key: string): boolean
	return State.Passes[key] == true
end

function State.maxOpen(): number
	return if State.hasPass("MultiOpen") then GameConfig.MaxOpenWithPass else GameConfig.MaxOpenBase
end

-- Permanent luck: upgrades, Luck pass and the personal Robux stack.
function State.permanentLuck(): Catalog.Luck
	return Catalog.luckFor(State.LuckLevel, State.hasPass("Luck"), State.PersonalLuck)
end

-- Server luck multiplier right now (1 when none is running).
function State.serverLuckMult(): number
	local now = State.serverNow()
	local best = 1
	for _, boost in State.ServerLuck.Boosts do
		if boost.EndsAt > now then
			best = math.max(best, boost.Mult)
		end
	end
	return best
end

function State.barFull(): boolean
	return State.LuckBar >= GameConfig.LuckBar.RollsToFill
end

-- Temporary multiplier the next open gets (server luck x a full luck bar).
function State.boostMult(): number
	return State.serverLuckMult() * (if State.barFull() then GameConfig.LuckBar.Mult else 1)
end

-- The luck the player's next open actually rolls with.
function State.luck(): Catalog.Luck
	return Catalog.boostLuck(State.permanentLuck(), State.boostMult())
end

function State.serverNow(): number
	return Workspace:GetServerTimeNow()
end

function State.itemCount(): number
	local count = 0
	for _ in State.Items do
		count += 1
	end
	return count
end

function State.showcasedCount(): number
	local count = 0
	for _, owned in State.Items do
		if owned.S then
			count += 1
		end
	end
	return count
end

-- Cash per second this item earns in the showcase, including the 2x Income pass.
function State.itemIncome(owned: Catalog.Owned): number
	local income = Catalog.incomeOf(Catalog.valueOf(owned))
	return if State.hasPass("DoubleIncome") then income * 2 else income
end

function State.keysFor(caseId: string): number
	return State.Keys[caseId] or 0
end

-- Limited copies left for an item (nil if its supply isn't capped).
function State.remaining(item: Catalog.Item): number?
	if not item.Supply then
		return nil
	end
	return math.max((item.Supply :: number) - (State.Serials[item.Id] or 0), 0)
end

-- Can the player pay for `count` opens of this case right now (keys first, then cash)?
function State.canAfford(case: Catalog.Case, count: number): boolean
	local keys = math.min(State.keysFor(case.Id), count)
	return State.Cash >= (count - keys) * case.Price
end

return State
