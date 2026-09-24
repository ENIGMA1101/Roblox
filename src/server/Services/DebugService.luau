--[[
	Developer tools for testing rare moments without grinding for them.

	Allowed in Studio, and in live servers only for GameConfig.Debug.Admins (while
	GameConfig.Debug.Enabled is true). Every request from anyone else is refused.

	Actions (Debug remote):
		"ForceGem", "random" | "top" | nil   next open lands every column on the gem
		"ForceMutation", mutationId | nil     next open gives every item this mutation
		"ClearForce"
		"AddCash", amount
		"FreeCaseReady"
		"OpenPaid", caseId                   open a Robux case without paying
		"SetLuck", level

	Forced items are real items saved to the player's data.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Roller = require(Shared.Roller)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

type Data = DataService.Data

local DebugService = {}

-- Set by CaseService (which depends on this module) to open a Robux case for free.
DebugService.openPaid = nil :: ((Player, string) -> { [string]: any })?

local forces: { [Player]: Roller.Force } = {}

-- Called by CaseService once per open: returns and clears the armed overrides.
function DebugService.takeForce(player: Player): Roller.Force?
	local force = forces[player]
	if not force then
		return nil
	end
	forces[player] = nil
	PlayerState.sync(player, "Force", {})
	return force
end

local function arm(player: Player): Roller.Force
	local force = forces[player] or {}
	forces[player] = force
	return force
end

local function handle(player: Player, data: Data, action: any, arg: any)
	if not PlayerState.debugAllowed(player) then
		return { ok = false, error = "Developer tools are disabled." }
	end

	if action == "ForceGem" then
		if arg ~= nil and arg ~= "random" and arg ~= "top" then
			return { ok = false, error = "Bad request." }
		end
		arm(player).Gem = arg
	elseif action == "ForceMutation" then
		if arg ~= nil and not (type(arg) == "string" and Catalog.MutationById[arg]) then
			return { ok = false, error = "Unknown mutation." }
		end
		arm(player).Mutation = arg
	elseif action == "OpenPaid" then
		local openPaid = DebugService.openPaid
		if type(arg) ~= "string" or not openPaid then
			return { ok = false, error = "Bad request." }
		end
		return openPaid(player, arg)
	elseif action == "ClearForce" then
		forces[player] = nil
	elseif action == "AddCash" then
		if type(arg) ~= "number" or arg ~= arg then
			return { ok = false, error = "Bad request." }
		end
		PlayerState.addCash(player, math.clamp(math.floor(arg), 0, 1e15))
	elseif action == "FreeCaseReady" then
		data.LastFreeCase = 0
		PlayerState.sync(player, "FreeCase", GameConfig.FreeCase.Cooldown)
	elseif action == "SetLuck" then
		if type(arg) ~= "number" or arg ~= arg then
			return { ok = false, error = "Bad request." }
		end
		data.LuckLevel = math.clamp(math.floor(arg), 0, GameConfig.LuckUpgrades.MaxLevel)
		PlayerState.sync(player, "Luck", data.LuckLevel)
	else
		return { ok = false, error = "Unknown action." }
	end

	if action == "ForceGem" or action == "ForceMutation" or action == "ClearForce" then
		PlayerState.sync(player, "Force", forces[player] or {})
	end
	return { ok = true }
end

function DebugService.start()
	PlayerState.bind("Debug", handle)
	Players.PlayerRemoving:Connect(function(player)
		forces[player] = nil
	end)
end

return DebugService
