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
			Description = "Double mutation chance and +35% gem chance.",
			Icon = "🍀",
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

	CashPacks = {
		{ Name = "Pocket Change", Icon = "💵", ProductId = 0, Cash = 25000, IncomeMinutes = 15 },
		{ Name = "Briefcase", Icon = "💼", ProductId = 0, Cash = 150000, IncomeMinutes = 60 },
		{ Name = "Vault Drop", Icon = "🏦", ProductId = 0, Cash = 1000000, IncomeMinutes = 240 },
	} :: { CashPack },
}

return Monetization
