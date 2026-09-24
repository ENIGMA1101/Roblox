--[[
	Server entry point. Services are started in dependency order.
]]

local Services = script.Services

local DataService = require(Services.DataService)
local Passes = require(Services.Passes)
local PlayerState = require(Services.PlayerState)
local CaseService = require(Services.CaseService)
local DebugService = require(Services.DebugService)
local ShowcaseService = require(Services.ShowcaseService)
local MonetizationService = require(Services.MonetizationService)
local StallService = require(Services.StallService)
local UpgradeService = require(Services.UpgradeService)

-- Remote handlers and listeners first, then player loading, so nothing misses a player.
PlayerState.start()
CaseService.start()
ShowcaseService.start()
UpgradeService.start()
DebugService.start()
MonetizationService.start()
StallService.start()
Passes.start()
DataService.start()
