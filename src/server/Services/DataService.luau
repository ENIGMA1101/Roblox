--[[
	Player save data with session locking.

	Each record is { Data = <player data>, Lock = { JobId, Time } }. While a server holds a
	player's lock, other servers wait instead of loading, so a quick server-hop can't load
	stale data and duplicate or lose items. A lock older than LOCK_EXPIRY belongs to a
	crashed server and is taken over.

	In Studio without "Enable Studio Access to API Services" the service falls back to
	in-memory data (nothing is saved) and says so in the output.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local GameConfig = require(Shared.Config.GameConfig)
local Signal = require(Shared.Signal)

export type Stats = {
	Opened: number,
	GemHits: number,
	BestValue: number,
	Earned: number,
}

export type Data = {
	Cash: number,
	Items: { [string]: Catalog.Owned },
	NextId: number,
	ShowcaseSlots: number,
	Keys: { [string]: number },
	LastFreeCase: number,
	LastSeen: number,
	Stats: Stats,
	Receipts: { string },
	-- Items whose id no longer exists in the catalogue. Kept so re-adding the id restores them.
	Orphans: { [string]: Catalog.Owned },
}

type Profile = {
	Data: Data,
	Saving: boolean,
	Released: boolean,
}

local LOCK_EXPIRY = 30 * 60
local LOAD_ATTEMPTS = 5
local MAX_RECEIPTS = 100

local DataService = {}
DataService.Loaded = Signal.new() :: Signal.Signal<Player, Data>

local store: DataStore? = nil
local profiles: { [Player]: Profile } = {}
local releasing: { [number]: boolean } = {}

local function template(): Data
	return {
		Cash = GameConfig.StartingCash,
		Items = {},
		NextId = 1,
		ShowcaseSlots = GameConfig.Showcase.BaseSlots,
		Keys = {},
		LastFreeCase = 0,
		LastSeen = 0,
		Stats = { Opened = 0, GemHits = 0, BestValue = 0, Earned = 0 },
		Receipts = {},
		Orphans = {},
	}
end

-- Fill in fields added since the player last saved.
local function reconcile(data: any, defaults: any)
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
		end
	end
end

-- Repair anything the current catalogue can't understand.
local function sanitize(data: Data)
	for id, owned in data.Items do
		local item = Catalog.ItemById[owned.I]
		if not item then
			data.Orphans[id] = owned
			data.Items[id] = nil
			warn(`[DataService] item "{owned.I}" is no longer in the catalogue; moved to Orphans`)
		else
			if not Catalog.Brands[owned.B] or not table.find(item.Brands, owned.B) then
				owned.B = item.Brands[1]
			end
			if owned.M and not Catalog.MutationById[owned.M] then
				owned.M = nil
			end
		end
	end

	for id, owned in data.Orphans do
		if Catalog.ItemById[owned.I] then
			data.Items[id] = owned
			data.Orphans[id] = nil
		end
	end

	local showcased = 0
	for _, owned in data.Items do
		if owned.S then
			showcased += 1
			if showcased > data.ShowcaseSlots then
				owned.S = nil
			end
		end
	end
end

local function keyFor(userId: number): string
	return `player_{userId}`
end

local function loadRecord(player: Player): Data?
	if not store then
		return template()
	end
	local dataStore = store :: DataStore
	local key = keyFor(player.UserId)

	for attempt = 1, LOAD_ATTEMPTS do
		local lastAttempt = attempt == LOAD_ATTEMPTS
		local ok, result = pcall(function()
			return dataStore:UpdateAsync(key, function(record)
				record = record or {}
				local lock = record.Lock
				if lock and lock.JobId ~= game.JobId and os.time() - lock.Time < LOCK_EXPIRY and not lastAttempt then
					return nil -- Another server still has this player; don't touch the record.
				end
				record.Lock = { JobId = game.JobId, Time = os.time() }
				return record
			end)
		end)

		if ok and type(result) == "table" and result.Lock and result.Lock.JobId == game.JobId then
			local data = result.Data or template()
			reconcile(data, template())
			sanitize(data)
			return data
		elseif not ok then
			warn(`[DataService] load attempt {attempt} for {player.Name} failed: {result}`)
		end

		if not player.Parent then
			return nil
		end
		task.wait(attempt * 2)
	end
	return nil
end

local function writeRecord(player: Player, profile: Profile, release: boolean): boolean
	if not store then
		return true
	end
	local dataStore = store :: DataStore

	while profile.Saving do
		task.wait()
	end
	profile.Saving = true
	profile.Data.LastSeen = os.time()

	local stolen = false
	local ok, err = pcall(function()
		dataStore:UpdateAsync(keyFor(player.UserId), function(record)
			record = record or {}
			if record.Lock and record.Lock.JobId ~= game.JobId then
				stolen = true
				return nil
			end
			record.Data = profile.Data
			record.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return record
		end)
	end)
	profile.Saving = false

	if not ok then
		warn(`[DataService] save for {player.Name} failed: {err}`)
		return false
	end
	if stolen then
		-- Another server took this session over; its copy is newer. Stop writing ours.
		profile.Released = true
		profiles[player] = nil
		player:Kick("Your data was opened in another server. Please rejoin.")
		return false
	end
	return true
end

function DataService.get(player: Player): Data?
	local profile = profiles[player]
	return profile and profile.Data
end

function DataService.waitFor(player: Player, timeout: number?): Data?
	local deadline = os.clock() + (timeout or 20)
	while player.Parent and os.clock() < deadline do
		local data = DataService.get(player)
		if data then
			return data
		end
		task.wait(0.1)
	end
	return DataService.get(player)
end

-- Save now. Used after Robux purchases so they are never lost.
function DataService.save(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.Released then
		return false
	end
	return writeRecord(player, profile, false)
end

function DataService.recordReceipt(data: Data, purchaseId: string)
	table.insert(data.Receipts, purchaseId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
end

local function onPlayerAdded(player: Player)
	while releasing[player.UserId] do
		task.wait(0.1)
	end

	local data = loadRecord(player)
	if not data then
		if player.Parent then
			player:Kick("We couldn't load your data. Please rejoin in a moment.")
		end
		return
	end

	local profile: Profile = { Data = data, Saving = false, Released = false }
	if not player.Parent then
		-- Left while loading: give the lock back straight away.
		writeRecord(player, profile, true)
		return
	end
	profiles[player] = profile
	DataService.Loaded:Fire(player, data)
end

local function release(player: Player)
	local profile = profiles[player]
	if not profile or profile.Released then
		return
	end
	profile.Released = true
	releasing[player.UserId] = true
	writeRecord(player, profile, true)
	profiles[player] = nil
	releasing[player.UserId] = nil
end

function DataService.start()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(GameConfig.DataStoreName)
	end)
	if ok then
		-- GetDataStore succeeds even without API access; probe once to find out.
		local probeOk, probeErr = pcall(function()
			result:GetAsync("__probe")
		end)
		if probeOk then
			store = result
		else
			warn(`[DataService] DataStores unavailable ({probeErr}). Using in-memory data: nothing will save.`)
		end
	else
		warn(`[DataService] DataStores unavailable ({result}). Using in-memory data: nothing will save.`)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(release)

	task.spawn(function()
		while true do
			task.wait(GameConfig.AutosaveInterval)
			for player, profile in profiles do
				if not profile.Released then
					task.spawn(writeRecord, player, profile, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait()
		end
	end)
end

return DataService
