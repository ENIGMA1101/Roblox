--[[
	Cases, cheapest first.

	Odds    - percent chance per rarity. Must add up to exactly 100.
	Gem     - rarities that hide behind the yellow gem. When one of these rolls, the reel
	          lands on the gem first, plays the gem sequence, then re-spins through
	          only these rarities to reveal the item.
	Robux   - optional developer product that grants keys for this case (one key = one
	          free open). ProductId 0 = not for sale. Because this is a paid random item,
	          the Robux button only appears inside the case preview, where every odd is listed.

	Balance: run tools/balance.py after changing odds, prices or item values. It prints
	each case's expected value and return-to-player (RTP).
]]

export type Case = {
	Id: string,
	Name: string,
	Price: number,
	Icon: string,
	Image: string,
	Color: Color3,
	Odds: { [string]: number },
	Gem: { string },
	Robux: { ProductId: number, Keys: number },
}

local Cases: { Case } = {
	{
		Id = "street",
		Name = "Street Luxe",
		Price = 650,
		Icon = "🛍️",
		Image = "",
		Color = Color3.fromRGB(128, 140, 166),
		Odds = { Common = 76, Uncommon = 18.5, Rare = 5.12, Epic = 0.36, Legendary = 0.02 },
		Gem = { "Epic", "Legendary" },
		Robux = { ProductId = 0, Keys = 5 },
	},
	{
		Id = "boutique",
		Name = "Boutique Box",
		Price = 5200,
		Icon = "🎁",
		Image = "",
		Color = Color3.fromRGB(94, 201, 126),
		Odds = { Common = 42, Uncommon = 40, Rare = 15.4, Epic = 2.238, Legendary = 0.35, Mythic = 0.012 },
		Gem = { "Legendary", "Mythic" },
		Robux = { ProductId = 0, Keys = 5 },
	},
	{
		Id = "atelier",
		Name = "Atelier Crate",
		Price = 41000,
		Icon = "📦",
		Image = "",
		Color = Color3.fromRGB(75, 139, 245),
		Odds = { Uncommon = 7.346, Rare = 40, Epic = 52, Legendary = 0.6, Mythic = 0.05, Sovereign = 0.004 },
		Gem = { "Legendary", "Mythic", "Sovereign" },
		Robux = { ProductId = 0, Keys = 3 },
	},
	{
		Id = "penthouse",
		Name = "Penthouse Case",
		Price = 305000,
		Icon = "🗝️",
		Image = "",
		Color = Color3.fromRGB(157, 92, 246),
		Odds = { Rare = 15.46, Epic = 55, Legendary = 29, Mythic = 0.5, Sovereign = 0.04 },
		Gem = { "Mythic", "Sovereign" },
		Robux = { ProductId = 0, Keys = 3 },
	},
	{
		Id = "monaco",
		Name = "Monaco Vault",
		Price = 2350000,
		Icon = "🎰",
		Image = "",
		Color = Color3.fromRGB(239, 68, 68),
		Odds = { Epic = 15, Legendary = 72, Mythic = 12.5, Sovereign = 0.5 },
		Gem = { "Sovereign" },
		Robux = { ProductId = 0, Keys = 1 },
	},
	{
		Id = "vermeil",
		Name = "The Vermeil Vault",
		Price = 10000000,
		Icon = "👑",
		Image = "",
		Color = Color3.fromRGB(255, 196, 46),
		Odds = { Legendary = 41.8, Mythic = 55, Sovereign = 3.2 },
		Gem = { "Sovereign" },
		Robux = { ProductId = 0, Keys = 1 },
	},
}

return Cases
