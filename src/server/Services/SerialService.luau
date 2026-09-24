--[[
	Global serial numbers for numbered (Exclusive) items, and supply caps for Limited ones.

	Each numbered item has one DataStore key holding how many copies exist. allocate() bumps
	it with UpdateAsync, which is atomic across every server, so two players can never get
	the same serial and a Limited item can never go past its Supply.

	Counts are cached per server (refreshed every REFRESH seconds and after each pull) and
	sent to clients as the "Serials" sync so previews can show "412 / 500 left".

	Without DataStore access (Studio without API services) counters live in memory.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

local STORE_NAME = "VermeilExchange_Serials_v1"
local REFRESH = 120

local SerialService = {}

local store: DataStore? = nil
local counts: { [string]: number } = {}
local numbered: { Catalog.Item } = {}

for _, item in Catalog.Items do
	if item.Exclusive then
		table.insert(numbered, item)
		counts[item.Id] = 0
	end
end

local function broadcast()
	for _, player in Players:GetPlayers() do
		if DataService.get(player) then
			PlayerState.sync(player, "Serials", counts)
		end
	end
end

function SerialService.count(itemId: string): number
	return counts[itemId] or 0
end

-- Limited items whose supply is (as far as this server knows) used up.
function SerialService.soldOut(): { [string]: boolean }
	local result = {}
	for _, item in numbered do
		if item.Supply and counts[item.Id] >= item.Supply then
			result[item.Id] = true
		end
	end
	return result
end

--[[
	Claims the next serial for an item. Returns the serial, or nil if a Limited item is sold
	out. Errors if the DataStore fails, so callers (receipts) can retry later.
]]
function SerialService.allocate(itemId: string): number?
	local item = Catalog.ItemById[itemId]
	local cap = item and item.Supply
	if not store then
		local current = counts[itemId] or 0
		if cap and current >= cap then
			return nil
		end
		counts[itemId] = current + 1
		broadcast()
		return current + 1
	end

	local dataStore = store :: DataStore
	local soldOut = false
	local result = dataStore:UpdateAsync(itemId, function(old)
		-- UpdateAsync can rerun this on a write conflict, so decide afresh each time.
		soldOut = false
		local current = old or 0
		if cap and current >= cap then
			soldOut = true
			counts[itemId] = current
			return nil
		end
		return current + 1
	end)
	if soldOut or result == nil then
		broadcast()
		return nil
	end
	counts[itemId] = result
	broadcast()
	return result
end

local function refresh()
	if not store then
		return
	end
	local dataStore = store :: DataStore
	local pending = #numbered
	for _, item in numbered do
		task.spawn(function()
			local ok, value = pcall(dataStore.GetAsync, dataStore, item.Id)
			if ok and type(value) == "number" then
				counts[item.Id] = value
			end
			pending -= 1
		end)
	end
	local deadline = os.clock() + 20
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
	broadcast()
end

function SerialService.start()
	local ok, result = pcall(function()
		local candidate = DataStoreService:GetDataStore(STORE_NAME)
		candidate:GetAsync("__probe")
		return candidate
	end)
	if ok then
		store = result
	else
		warn(`[SerialService] DataStores unavailable ({result}). Serials are in-memory for this server.`)
	end

	DataService.Loaded:Connect(function(player)
		PlayerState.sync(player, "Serials", counts)
	end)

	task.spawn(function()
		while true do
			refresh()
			task.wait(REFRESH)
		end
	end)
end

return SerialService
