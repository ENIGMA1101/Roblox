--[[
	The live pull feed: notable pulls by anyone in the server, shown bottom-right on every
	screen. Sent after roughly the time the opener's spin takes, so the feed never spoils a
	reveal that is still spinning.

	Notable = rarity Fx >= GameConfig.Feed.MinFx, anything from behind the gem, or a mutation of
	Tier >= Feed.MinMutationTier. At most Feed.MaxPerOpen per open (the most valuable).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)

local CaseService = require(script.Parent.CaseService)
local Passes = require(script.Parent.Passes)

export type FeedEntry = {
	Player: string,
	UserId: number,
	I: string,
	B: string,
	M: string?,
	N: number?,
	Value: number,
	Case: string,
}

local FeedService = {}

local feedEvent: RemoteEvent

local function notable(result: { I: string, M: string?, Gem: boolean }): boolean
	local config = GameConfig.Feed
	local rarity = Catalog.RarityById[Catalog.ItemById[result.I].Rarity]
	local mutation = result.M and Catalog.MutationById[result.M]
	return rarity.Fx >= config.MinFx or result.Gem or (mutation ~= nil and mutation.Tier >= config.MinMutationTier)
end

-- About how long the opener's spin takes, so the feed shows each pull as it lands.
local function spinSeconds(player: Player, count: number, anyGem: boolean): number
	local spin = GameConfig.Spin
	local seconds = spin.Cruise + spin.Stagger * (count - 1) + spin.Decel + spin.RevealTime
	if anyGem then
		seconds += spin.GemHold + spin.GemCruise + spin.GemDecel
	end
	return seconds * (if Passes.has(player, "SpinSpeed") then spin.FastMultiplier else 1)
end

function FeedService.start()
	feedEvent = Net.event("Feed")
	CaseService.Opened:Connect(function(player, case, results)
		local entries: { FeedEntry } = {}
		local anyGem = false
		for _, result in results do
			anyGem = anyGem or result.Gem
			if notable(result) then
				table.insert(entries, {
					Player = player.DisplayName,
					UserId = player.UserId,
					I = result.I,
					B = result.B,
					M = result.M,
					N = result.N,
					Value = result.Value,
					Case = case.Name,
				})
			end
		end
		if #entries == 0 then
			return
		end
		table.sort(entries, function(a, b)
			return a.Value > b.Value
		end)
		while #entries > GameConfig.Feed.MaxPerOpen do
			table.remove(entries)
		end
		task.delay(spinSeconds(player, #results, anyGem), function()
			if #Players:GetPlayers() > 0 then
				feedEvent:FireAllClients(entries)
			end
		end)
	end)
end

return FeedService
