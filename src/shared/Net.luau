--[[
	Remote definitions. The server creates them on first use; the client waits for them.

	Functions (client -> server, returns a result table):
		GetState()                      full snapshot of the player's data
		OpenCase(caseId, count)         buy/open cases, returns the rolls
		ClaimFreeCase()                 open the free case when its timer is up
		SellItems({ itemIds })
		SellAll(maxRarityOrder)         sells unlocked, non-showcased items up to a tier
		SetLocked(itemId, locked)
		SetShowcased(itemId, showcased)
		ShowcaseBest()                  fill the showcase with the most valuable items
		BuySlot()                       buy the next showcase slot
		BuyLuck()                       buy the next luck upgrade level
		Rebirth()                       reset for permanent luck and sell/income bonuses
		Debug(action, arg)              developer tools (Studio / admins only)

	Events (server -> client):
		Sync(kind, payload)             state changes, see server/Services/PlayerState
		Notify(text, kind)              toast message
		PaidOpen(caseId, response)      a Robux case purchase was opened (results to animate)
		Feed(entries)                   notable pulls anyone in the server just made (live feed)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FUNCTIONS = {
	"GetState",
	"OpenCase",
	"ClaimFreeCase",
	"SellItems",
	"SellAll",
	"SetLocked",
	"SetShowcased",
	"ShowcaseBest",
	"BuySlot",
	"BuyLuck",
	"Rebirth",
	"Debug",
}
local EVENTS = { "Sync", "Notify", "PaidOpen", "Feed" }

local Net = {}

local folder: Folder? = nil

local function getFolder(): Folder
	local existing = folder
	if existing then
		return existing
	end
	local result: Folder
	if RunService:IsServer() then
		result = Instance.new("Folder")
		result.Name = "Remotes"
		for _, name in FUNCTIONS do
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = result
		end
		for _, name in EVENTS do
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = result
		end
		result.Parent = ReplicatedStorage
	else
		result = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	folder = result
	return result
end

function Net.fn(name: string): RemoteFunction
	assert(table.find(FUNCTIONS, name), `Net: unknown function "{name}"`)
	return getFolder():WaitForChild(name) :: RemoteFunction
end

function Net.event(name: string): RemoteEvent
	assert(table.find(EVENTS, name), `Net: unknown event "{name}"`)
	return getFolder():WaitForChild(name) :: RemoteEvent
end

return Net
