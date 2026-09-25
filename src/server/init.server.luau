--[[
	Server entry point. Services are started in dependency order.
]]

local Services = script.Services

local DataService = require(Services.DataService)
local Passes = require(Services.Passes)
local PlayerState = require(Services.PlayerState)
local SerialService = require(Services.SerialService)
local CaseService = require(Services.CaseService)
local DebugService = require(Services.DebugService)
local ShowcaseService = require(Services.ShowcaseService)
local MonetizationService = require(Services.MonetizationService)
local ServerLuckService = require(Services.ServerLuckService)
local StallService = require(Services.StallService)
local UpgradeService = require(Services.UpgradeService)
local RebirthService = require(Services.RebirthService)
local FeedService = require(Services.FeedService)

-- Remote handlers and listeners first, then player loading, so nothing misses a player.
PlayerState.start()
CaseService.start()
ShowcaseService.start()
UpgradeService.start()
RebirthService.start()
FeedService.start()
ServerLuckService.start()
SerialService.start()
DebugService.start()
DebugService.activateServerLuck = ServerLuckService.debugActivate
MonetizationService.start()
StallService.start()
Passes.start()
DataService.start()
