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

	--[[
		Luck. Item luck is every source multiplied together: upgrades x 2x Luck pass x personal
		Robux stack x server luck x luck bar. It raises the chance of rare items (the rarer,
		the bigger the boost; see Catalog.effectiveLuck). It never touches mutations.

		FullGain: luck works at full strength until it has raised a case's return by this much
		(0.75 = +75% of the case price). Beyond that it keeps helping but with diminishing,
		logarithmic returns; Softness sets how quickly (bigger = more generous). The Boost
		values apply while server luck or a full luck bar is active.

		Mutation luck comes only from the Mutation Luck pass: it divides every mutation's OneIn.
	]]
	Luck = {
		PassMult = 2,
		MutationPassMult = 2,
		FullGain = 0.4,
		Softness = 0.3,
		BoostFullGain = 1.2,
		BoostSoftness = 0.6,
	},

	-- Luck upgrades bought with cash (the long-term cash sink). No max level: each level
	-- multiplies item luck by PerLevel (level 10 = 1.63x, 20 = 2.65x), and level L -> L+1
	-- costs BasePrice * PriceGrowth ^ L. Levels reset on rebirth.
	LuckUpgrades = {
		BasePrice = 25000,
		PriceGrowth = 1.9,
		PerLevel = 1.05,
	},

	--[[
		Rebirth: resets cash (back to StartingCash), luck levels and every item pulled with
		cash. Keeps exclusives (Robux case items and grails), keys, showcase slots, passes,
		personal Robux luck and stats. Each rebirth permanently multiplies item luck by
		LuckMult (compounding: 10 rebirths = x2.59) and adds SellBonus to sell value and
		showcase income (10 rebirths = +150%).
		Rebirth N+1 needs BaseCost * CostGrowth ^ N * CostRamp ^ (N(N-1)/2) cash in hand.
	]]
	Rebirth = {
		LuckMult = 1.1,
		SellBonus = 0.15,
		BaseCost = 500000,
		CostGrowth = 3.5,
		CostRamp = 1.12,
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

	-- Live pull feed (bottom right). Shows pulls of rarity Fx >= MinFx (2 = Epic and up),
	-- anything from behind the gem, and mutations of Tier >= MinMutationTier. Visible cards
	-- at once, and how long a card stays before fading.
	Feed = {
		MinFx = 2,
		MinMutationTier = 3,
		MaxPerOpen = 3,
		Visible = 3,
		Lifetime = 25,
	},

	-- Client spin timings in seconds.
	--
	-- Reels move like a slot machine: every reel blasts along at CellsPerSecond for Cruise
	-- seconds, then brakes over Decel seconds. With several reels, each one brakes Stagger
	-- seconds after the previous one, so they stop one at a time. GemCruise / GemDecel are the
	-- re-spin after a gem. FastMultiplier scales every time with the 2x Spin Speed pass.
	Spin = {
		CellsPerSecond = 24,
		Cruise = 1.1,
		Decel = 2.4,
		Stagger = 0.75,
		GemHold = 1.6,
		GemCruise = 0.5,
		GemDecel = 2.6,
		RevealTime = 0.9,
		MutationTime = 1.4,
		AutoOpenDelay = 1.0,
		FastMultiplier = 0.5,
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
