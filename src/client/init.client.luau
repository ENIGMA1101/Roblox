--[[
	Client entry point.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)

local Actions = require(script.Actions)

local Decor = require(script.Decor)
local Sound = require(script.Sound)
local State = require(script.State)
local CaseShop = require(script.UI.CaseShop)
local DevTools = require(script.UI.DevTools)
local Hud = require(script.UI.Hud)
local Inventory = require(script.UI.Inventory)
local Luck = require(script.UI.Luck)
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
Luck.start()
DevTools.start()
Hud.start()
Decor.start()

Net.event("Notify").OnClientEvent:Connect(function(text: string, kind: string?)
	Toast.show(text, kind)
end)

-- A Robux case opened while no spinner was waiting (e.g. a delayed receipt): just announce it.
Net.event("PaidOpen").OnClientEvent:Connect(function(caseId: string, result)
	if Actions.waitingPaid == caseId then
		return
	end
	if not result.ok then
		if result.error then
			Toast.show(result.error, "gold")
		end
		return
	end
	for _, item in result.Results do
		local def = Catalog.ItemById[item.I]
		Toast.show(`{def.Name}{if item.N then " #" .. item.N else ""} was added to your inventory!`, "gold")
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenCasesPrompt" then
		CaseShop.open()
	end
end)
