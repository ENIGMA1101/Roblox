--[[
	Client entry point.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)

local Decor = require(script.Decor)
local Sound = require(script.Sound)
local State = require(script.State)
local CaseShop = require(script.UI.CaseShop)
local Hud = require(script.UI.Hud)
local Inventory = require(script.UI.Inventory)
local Root = require(script.UI.Root)
local Spinner = require(script.UI.Spinner)
local Store = require(script.UI.Store)
local Toast = require(script.UI.Toast)

Root.start()
Toast.start()
Sound.preload()
State.start()
Spinner.start()
CaseShop.start()
Inventory.start()
Store.start()
Hud.start()
Decor.start()

Net.event("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
	Toast.show(text, kind)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenCasesPrompt" then
		CaseShop.open()
	end
end)
