--[[
	Robux products. Create them on the Creator Dashboard (your experience -> Monetization),
	then paste the ids here. Anything left at 0 is hidden in live games (shown greyed out in
	Studio so you can see what still needs setting up).

	Per-case key bundles are configured on each case in Cases.luau (Robux.ProductId).
]]

export type Pass = {
	Key: string,
	Name: string,
	Description: string,
	Icon: string,
	PassId: number,
}

export type CashPack = {
	Name: string,
	Icon: string,
	ProductId: number,
	-- Grants whichever is larger: a flat amount, or this many minutes of the buyer's showcase income.
	Cash: number,
	IncomeMinutes: number,
}

local Monetization = {
	-- Studio only: pretend you own every pass so you can test them before creating them.
	StudioOwnsAllPasses = false,

	Passes = {
		{
			Key = "Luck",
			Name = "2x Luck",
			Description = "Doubles your item luck: rare items drop far more often. Stacks with all other luck.",
			Icon = "🍀",
			PassId = 0,
		},
		{
			Key = "MutationLuck",
			Name = "2x Mutation Luck",
			Description = "Doubles your chance of every mutation. The only way to raise mutation odds.",
			Icon = "🧬",
			PassId = 0,
		},
		{
			Key = "FastOpen",
			Name = "Fast Open",
			Description = "Spins play more than twice as fast.",
			Icon = "⚡",
			PassId = 0,
		},
		{
			Key = "AutoOpen",
			Name = "Auto Open",
			Description = "Keeps re-opening the same case for you.",
			Icon = "🔁",
			PassId = 0,
		},
		{
			Key = "MultiOpen",
			Name = "Multi Open+",
			Description = "Open up to 5 cases at once.",
			Icon = "🎰",
			PassId = 0,
		},
		{
			Key = "DoubleIncome",
			Name = "2x Showcase Income",
			Description = "Your showcase earns double cash.",
			Icon = "💸",
			PassId = 0,
		},
	} :: { Pass },

	-- Server luck: multiplies everyone's luck in the server for Minutes. Buying a boost that's
	-- already running adds Minutes to it. When several run, the highest multiplier applies.
	ServerLuck = {
		{ Key = "x2", Name = "2x Server Luck", Mult = 2, Minutes = 15, Robux = 33, ProductId = 0 },
		{ Key = "x3", Name = "3x Server Luck", Mult = 3, Minutes = 15, Robux = 99, ProductId = 0 },
		{ Key = "x10", Name = "10x Server Luck", Mult = 10, Minutes = 15, Robux = 199, ProductId = 0 },
	},

	--[[
		Personal luck stack (the icon on the right). Permanent. The first purchase gives 2x luck,
		each one after adds +PerPurchase (2x, 4x, 6x, ...). Roblox products have fixed prices, so
		each step is its own developer product: step N should cost BasePrice * PriceGrowth^(N-1)
		Robux (5, 8, 11, 17, 25, 38, 57, 85, 128, 192, ...). List the ids in order; the number of
		ids is how many times it can be bought.
	]]
	PersonalLuck = {
		PerPurchase = 2,
		BasePrice = 5,
		PriceGrowth = 1.5,
		ProductIds = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
	},

	CashPacks = {
		{ Name = "Pocket Change", Icon = "💵", ProductId = 0, Cash = 25000, IncomeMinutes = 15 },
		{ Name = "Briefcase", Icon = "💼", ProductId = 0, Cash = 150000, IncomeMinutes = 60 },
		{ Name = "Vault Drop", Icon = "🏦", ProductId = 0, Cash = 1000000, IncomeMinutes = 240 },
	} :: { CashPack },
}

return Monetization
