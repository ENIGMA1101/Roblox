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

	-- Luck raises a case's gem odds only until the case would return MaxRTP of its price on
	-- average, but always allows at least MinGain x the case's normal value. Without this, cases
	-- that keep most of their value behind the gem would pay back far more than they cost.
	-- Temporary boosts (server luck, a full luck bar) use the looser Boost limits, so a 10x
	-- moment really pays off without turning a case into an unlimited money printer.
	-- Both are measured on item value before mutations; mutation luck can add up to ~24% more.
	LuckLimits = { MaxRTP = 0.85, MinGain = 1.15, BoostMaxRTP = 1.3, BoostMinGain = 1.6 },

	-- Luck upgrades bought with cash (the long-term cash sink). No max level: each level adds
	-- GemPerLevel to the gem multiplier and MutationPerLevel to the mutation multiplier, and
	-- level L -> L+1 costs BasePrice * PriceGrowth ^ L, so prices explode (level 20 ~$4.9B,
	-- level 30 ~$3T, level 40 ~$1.9Q). Gem luck still obeys LuckLimits per case.
	LuckUpgrades = {
		BasePrice = 25000,
		PriceGrowth = 1.9,
		GemPerLevel = 0.025,
		MutationPerLevel = 0.1,
	},

	-- The luck bar at the bottom of the screen: every item opened adds 1. When it reaches
	-- RollsToFill, the player's next open gets Mult x luck (all its reels), then it empties.
	LuckBar = { RollsToFill = 30, Mult = 10 },

	-- Developer tools (force the gem, force mutations, free cash). Always available in Studio.
	-- In live servers only for the UserIds listed in Admins. Items made with it are real.
	Debug = {
		Enabled = true,
		Admins = {} :: { number },
	},

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

	-- Themed cases: automatic odds and gem.
	ThemedCases = {
		-- Return-to-player by price when a case has no RTP: RTP = Base - Slope * log10(price / 1000),
		-- clamped to [Min, Max]. ~98% at $1K, ~86% at $100K, ~74% at $10M.
		RTP = { Base = 0.98, Slope = 0.06, Min = 0.68, Max = 1.0 },
		-- Items worth at least this many times the case's expected pull hide behind the gem...
		GemMultiple = 10,
		-- ...and if none are, the single best item does when it's worth this many times.
		FallbackGemMultiple = 4,
	},

	-- If a Limited case sells out between the purchase prompt and the receipt, the buyer gets
	-- this much cash instead (it can't be refunded in Robux).
	SoldOutCash = 5000000,

	-- "rbxassetid://..." artwork for the yellow gem on the reel. Leave "" to use the built-in
	-- drawn gem.
	GemImage = "",

	DataStoreName = "VermeilExchange_PlayerData_v1",
	AutosaveInterval = 90,
}

return GameConfig
