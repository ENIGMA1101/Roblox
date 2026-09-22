--[[
	Gamepass ownership. Roblox is the source of truth, so ownership is checked on join and
	cached for the session, then updated live when a pass is bought in-game.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Monetization = require(Shared.Config.Monetization)
local Signal = require(Shared.Signal)

local Passes = {}
Passes.Changed = Signal.new() :: Signal.Signal<Player>

local owned: { [Player]: { [string]: boolean } } = {}

local function keyForPassId(passId: number): string?
	for _, pass in Monetization.Passes do
		if pass.PassId == passId and passId ~= 0 then
			return pass.Key
		end
	end
	return nil
end

local function load(player: Player)
	local result: { [string]: boolean } = {}
	owned[player] = result
	for _, pass in Monetization.Passes do
		if Monetization.StudioOwnsAllPasses and RunService:IsStudio() then
			result[pass.Key] = true
		elseif pass.PassId ~= 0 then
			local ok, has =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.PassId)
			if ok and has then
				result[pass.Key] = true
			elseif not ok then
				warn(`[Passes] ownership check for {pass.Key} failed: {has}`)
			end
		end
	end
	Passes.Changed:Fire(player)
end

function Passes.has(player: Player, key: string): boolean
	local list = owned[player]
	return list ~= nil and list[key] == true
end

function Passes.list(player: Player): { [string]: boolean }
	return table.clone(owned[player] or {})
end

function Passes.luck(player: Player): Catalog.Luck
	if Passes.has(player, "Luck") then
		return GameConfig.LuckPass
	end
	return Catalog.NoLuck
end

function Passes.maxOpen(player: Player): number
	return if Passes.has(player, "MultiOpen") then GameConfig.MaxOpenWithPass else GameConfig.MaxOpenBase
end

function Passes.start()
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = keyForPassId(passId)
		if purchased and key and owned[player] then
			owned[player][key] = true
			Passes.Changed:Fire(player)
		end
	end)
end

return Passes
