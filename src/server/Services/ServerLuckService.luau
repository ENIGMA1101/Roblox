--[[
	Server luck: timed multipliers bought with Robux that boost everyone in this server.

	Each boost type (2x / 3x / 10x) has its own timer. Buying one that's already running adds
	its Minutes to the remaining time. When several run at once, the highest multiplier
	applies. Boosts belong to this server only and end when it shuts down.

	Clients get { Mult, EndsAt, Boosts = { { Key, Mult, EndsAt } } } as the "ServerLuck" sync.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetization = require(Shared.Config.Monetization)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

export type Boost = { Key: string, Name: string, Mult: number, Minutes: number, Robux: number, ProductId: number }

local ServerLuckService = {}

local endsAt: { [string]: number } = {}
local lastMult = 1

local function active(): { { Key: string, Mult: number, EndsAt: number } }
	local now = os.time()
	local list = {}
	for _, boost in Monetization.ServerLuck do
		local ends = endsAt[boost.Key]
		if ends and ends > now then
			table.insert(list, { Key = boost.Key, Mult = boost.Mult, EndsAt = ends })
		end
	end
	table.sort(list, function(a, b)
		return a.Mult > b.Mult
	end)
	return list
end

-- The multiplier everyone in the server currently gets (1 when nothing is running).
function ServerLuckService.multiplier(): number
	local list = active()
	return if list[1] then list[1].Mult else 1
end

local function payload(): { [string]: any }
	local list = active()
	return {
		Mult = if list[1] then list[1].Mult else 1,
		EndsAt = if list[1] then list[1].EndsAt else 0,
		Boosts = list,
	}
end

local function broadcast()
	local data = payload()
	lastMult = data.Mult
	for _, player in Players:GetPlayers() do
		if DataService.get(player) then
			PlayerState.sync(player, "ServerLuck", data)
		end
	end
end

function ServerLuckService.activate(boost: Boost, buyer: Player?, minutes: number?)
	local now = os.time()
	local from = math.max(endsAt[boost.Key] or 0, now)
	endsAt[boost.Key] = from + math.floor((minutes or boost.Minutes) * 60)
	broadcast()
	local who = if buyer then buyer.DisplayName else "Someone"
	for _, player in Players:GetPlayers() do
		PlayerState.notify(player, `🍀 {who} activated {boost.Name} for everyone!`, "gold")
	end
end

-- Developer tools: start a boost by key for two minutes (no purchase).
function ServerLuckService.debugActivate(player: Player, key: string)
	for _, boost in Monetization.ServerLuck do
		if boost.Key == key then
			ServerLuckService.activate(boost, player, 2)
		end
	end
end

function ServerLuckService.start()
	DataService.Loaded:Connect(function(player)
		PlayerState.sync(player, "ServerLuck", payload())
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if ServerLuckService.multiplier() ~= lastMult then
				broadcast()
			end
		end
	end)
end

return ServerLuckService
