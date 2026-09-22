--[[
	Global tuning knobs. Everything economy-related lives here or in the catalogue files.
]]

local GameConfig = {
	StartingCash = 5000,
	InventoryCap = 400,

	-- How many cases can be opened at once (one reel column each).
	MaxOpenBase = 3,
	MaxOpenWithPass = 5,

	-- Minimum seconds between open requests from one player (server enforced).
	OpenCooldown = 0.75,

	FreeCase = {
		CaseId = "street",
		Cooldown = 5 * 60,
	},

	Showcase = {
		BaseSlots = 3,
		-- Price of each extra slot, in order. Length of this list = how many extra slots exist.
		SlotPrices = { 20000, 150000, 1000000, 6000000, 40000000, 250000000, 1500000000, 10000000000 },
		-- Cash per second from one showcased item = IncomeRate * value ^ IncomeExponent.
		-- An exponent below 1 gives diminishing returns: cheap items pay back fast (a $1K item
		-- in ~12 min), top items slowly (a $100M item in ~1.1 h), which keeps the early game
		-- snappy and stops late-game income from exploding.
		IncomeRate = 0.005,
		IncomeExponent = 0.82,
		-- Flat cash per second everyone earns, so a broke player is never stuck.
		BaseIncome = 12,
		-- Players earn this fraction of their showcase income while offline, up to OfflineMaxSeconds.
		OfflineRate = 0.25,
		OfflineMaxSeconds = 4 * 60 * 60,
	},

	-- The Luck pass. Mutation luck divides every mutation's OneIn. Gem luck multiplies the
	-- chance of each case's gem rarities (taken from that case's most common rarity).
	-- Gem luck is kept below 2x on purpose: gem pulls carry 40-60% of a case's value, so
	-- doubling them would push cheap cases past 100% return and make the pass a money printer.
	LuckPass = { Gem = 1.35, Mutation = 2 },

	-- Client spin timings in seconds. FastMultiplier applies with the Fast Open pass.
	Spin = {
		Duration = 5.0,
		Stagger = 0.22,
		GemHold = 1.6,
		GemSpinDuration = 3.6,
		RevealTime = 0.9,
		MutationTime = 1.4,
		AutoOpenDelay = 1.0,
		FastMultiplier = 0.45,
	},

	-- "rbxassetid://..." artwork for the yellow gem on the reel. Leave "" to use the built-in
	-- drawn gem.
	GemImage = "",

	DataStoreName = "VermeilExchange_PlayerData_v1",
	AutosaveInterval = 90,
}

return GameConfig
