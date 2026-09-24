--[[
	Every case in the game. Three kinds:

	Mixed  - has Odds (percent per rarity, must add to 100) and Gem (rarities hidden behind
	         the gem). Pulls from every non-exclusive item of each rarity.
	Themed - has a Pool (which items it contains). Odds are worked out automatically so the
	         case returns RTP of its Price on average: cheaper items get higher chances, like
	         PackDraw. Items worth GemMultiple x the case's expected value or more hide
	         behind the gem.
	Robux  - has Paid (a developer product). Buying it opens the case straight away. Items
	         are numbered exclusives; TargetValue sets the average pull value in cash.

	Pool filters (combine freely):
		Items = { ids }             exactly these items
		Category = "watches" or { "cars", "hypercars" }
		Brand = "rolax"             single-brand products of that house
		MinValue / MaxValue         base value range
	Exclusive items only ever appear in pools that list them by id.

	Optional on any case:
		RTP                  override the automatic return (Themed)
		Weights = "supply"   chance proportional to each item's Supply (Limited cases)
		GuaranteedMutation   every item gets a mutation (odds renormalised across mutations)
		Robux = { ProductId, Keys }   Robux key bundles, sold beside the odds

	Balance: run tools/balance.py after any change. It prints every case's odds, gem chance
	and return.
]]

export type Pool = {
	Items: { string }?,
	Category: (string | { string })?,
	Brand: string?,
	MinValue: number?,
	MaxValue: number?,
}

export type CaseDef = {
	Id: string,
	Name: string,
	Theme: string?,
	Price: number?,
	Icon: string,
	Image: string?,
	Color: Color3,
	Odds: { [string]: number }?,
	Gem: { string }?,
	Pool: Pool?,
	RTP: number?,
	TargetValue: number?,
	Weights: string?,
	GuaranteedMutation: boolean?,
	Paid: { ProductId: number, Robux: number }?,
	Robux: { ProductId: number, Keys: number }?,
}

local Cases: { CaseDef } = {
	-- Mixed progression cases ------------------------------------------------------------------
	{
		Id = "street",
		Name = "Street Luxe",
		Theme = "Mixed",
		Price = 800,
		Icon = "🛍️",
		Color = Color3.fromRGB(128, 140, 166),
		Odds = { Common = 76, Uncommon = 18.5, Rare = 5.12, Epic = 0.36, Legendary = 0.02 },
		Gem = { "Epic", "Legendary" },
		Robux = { ProductId = 0, Keys = 5 },
	},
	{
		Id = "boutique",
		Name = "Boutique Box",
		Theme = "Mixed",
		Price = 5800,
		Icon = "🎁",
		Color = Color3.fromRGB(94, 201, 126),
		Odds = { Common = 42, Uncommon = 40, Rare = 15.4, Epic = 2.238, Legendary = 0.35, Mythic = 0.012 },
		Gem = { "Legendary", "Mythic" },
		Robux = { ProductId = 0, Keys = 5 },
	},
	{
		Id = "atelier",
		Name = "Atelier Crate",
		Theme = "Mixed",
		Price = 48000,
		Icon = "📦",
		Color = Color3.fromRGB(75, 139, 245),
		Odds = { Uncommon = 7.346, Rare = 40, Epic = 52, Legendary = 0.6, Mythic = 0.05, Sovereign = 0.004 },
		Gem = { "Legendary", "Mythic", "Sovereign" },
		Robux = { ProductId = 0, Keys = 3 },
	},
	{
		Id = "penthouse",
		Name = "Penthouse Case",
		Theme = "Mixed",
		Price = 350000,
		Icon = "🗝️",
		Color = Color3.fromRGB(157, 92, 246),
		Odds = { Rare = 15.46, Epic = 55, Legendary = 29, Mythic = 0.5, Sovereign = 0.04 },
		Gem = { "Mythic", "Sovereign" },
		Robux = { ProductId = 0, Keys = 3 },
	},
	{
		Id = "monaco",
		Name = "Monaco Vault",
		Theme = "Mixed",
		Price = 2650000,
		Icon = "🎰",
		Color = Color3.fromRGB(239, 68, 68),
		Odds = { Epic = 15, Legendary = 72, Mythic = 12.5, Sovereign = 0.5 },
		Gem = { "Sovereign" },
		Robux = { ProductId = 0, Keys = 1 },
	},
	{
		Id = "vermeil",
		Name = "The Vermeil Vault",
		Theme = "Mixed",
		Price = 12000000,
		Icon = "👑",
		Color = Color3.fromRGB(255, 196, 46),
		Odds = { Legendary = 41.8, Mythic = 55, Sovereign = 3.2 },
		Gem = { "Sovereign" },
		Robux = { ProductId = 0, Keys = 1 },
	},

	-- Themed cases -----------------------------------------------------------------------------
	{
		Id = "scentlab",
		Name = "Scent Lab",
		Theme = "Fragrance",
		Price = 800,
		Icon = "🧴",
		Color = Color3.fromRGB(236, 150, 200),
		Pool = { Category = "fragrance" },
	},
	{
		Id = "dropday",
		Name = "Drop Day",
		Theme = "Streetwear",
		Price = 1200,
		Icon = "🧥",
		Color = Color3.fromRGB(230, 60, 60),
		Pool = { Category = "streetwear" },
	},
	{
		Id = "sneakerhead",
		Name = "Sneakerhead",
		Theme = "Sneakers",
		Price = 2500,
		Icon = "👟",
		Color = Color3.fromRGB(255, 140, 50),
		Pool = { Category = "sneakers" },
	},
	{
		Id = "topshelf",
		Name = "Top Shelf",
		Theme = "Spirits",
		Price = 3500,
		Icon = "🥃",
		Color = Color3.fromRGB(196, 132, 60),
		Pool = { Category = "drinks" },
	},
	{
		Id = "techhaul",
		Name = "Tech Haul",
		Theme = "Tech",
		Price = 4000,
		Icon = "💻",
		Color = Color3.fromRGB(90, 170, 255),
		Pool = { Category = "tech", MaxValue = 100000 },
	},
	{
		Id = "appelstore",
		Name = "Appel Store",
		Theme = "Brand: Appel",
		Price = 6000,
		Icon = "🍏",
		Color = Color3.fromRGB(200, 205, 215),
		Pool = { Brand = "appel" },
	},
	{
		Id = "ticktock",
		Name = "Tick Tock",
		Theme = "Watches",
		Price = 12000,
		Icon = "⌚",
		Color = Color3.fromRGB(120, 200, 190),
		Pool = { Category = "watches", MaxValue = 500000 },
	},
	{
		Id = "bagdrop",
		Name = "Bag Drop",
		Theme = "Handbags",
		Price = 12000,
		Icon = "👜",
		Color = Color3.fromRGB(214, 160, 110),
		Pool = { Category = "bags", MaxValue = 1000000 },
	},
	{
		Id = "grailhunter",
		Name = "Grail Hunter",
		Theme = "Collectibles",
		Price = 15000,
		Icon = "🃏",
		Color = Color3.fromRGB(255, 210, 70),
		Pool = { Category = "collectibles" },
	},
	{
		Id = "rolaxonly",
		Name = "Rolax Only",
		Theme = "Brand: Rolax",
		Price = 40000,
		Icon = "👑",
		Color = Color3.fromRGB(40, 150, 90),
		Pool = { Brand = "rolax" },
	},
	{
		Id = "icebox",
		Name = "Ice Box",
		Theme = "Jewellery",
		Price = 50000,
		Icon = "💍",
		Color = Color3.fromRGB(150, 225, 255),
		Pool = { Category = "jewellery" },
	},
	{
		Id = "twowheels",
		Name = "Two Wheels",
		Theme = "Motorbikes",
		Price = 60000,
		Icon = "🏍️",
		Color = Color3.fromRGB(255, 110, 40),
		Pool = { Category = "bikes" },
	},
	{
		Id = "hermezvault",
		Name = "Hermez Vault",
		Theme = "Brand: Hermez",
		Price = 150000,
		Icon = "🟠",
		Color = Color3.fromRGB(245, 130, 30),
		Pool = { Brand = "hermez" },
	},
	{
		Id = "horology",
		Name = "Haute Horlogerie",
		Theme = "Luxury Watches",
		Price = 250000,
		Icon = "⏱️",
		Color = Color3.fromRGB(70, 110, 200),
		Pool = { Category = "watches", MinValue = 20000 },
	},
	{
		Id = "dreamgarage",
		Name = "Dream Garage",
		Theme = "Cars",
		Price = 800000,
		Icon = "🏎️",
		Color = Color3.fromRGB(220, 40, 60),
		Pool = { Category = "cars" },
	},
	{
		Id = "prancinghorse",
		Name = "Prancing Horse",
		Theme = "Brand: Ferrarri",
		Price = 4000000,
		Icon = "🐎",
		Color = Color3.fromRGB(255, 40, 30),
		Pool = { Brand = "ferrarri" },
	},
	{
		Id = "hypercarhunt",
		Name = "Hypercar Hunt",
		Theme = "Hypercars",
		Price = 6000000,
		Icon = "🏁",
		Color = Color3.fromRGB(40, 40, 50),
		Pool = { Category = "hypercars" },
	},
	{
		Id = "openwater",
		Name = "Open Water",
		Theme = "Boats & Yachts",
		Price = 12000000,
		Icon = "🛥️",
		Color = Color3.fromRGB(30, 140, 220),
		Pool = { Category = "boats", MinValue = 1000000 },
	},
	{
		Id = "thegallery",
		Name = "The Gallery",
		Theme = "Fine Art",
		Price = 20000000,
		Icon = "🖼️",
		Color = Color3.fromRGB(180, 140, 255),
		Pool = { Category = "art", MinValue = 1000000 },
	},
	{
		Id = "realestate",
		Name = "Real Estate Mogul",
		Theme = "Property",
		Price = 40000000,
		Icon = "🏙️",
		Color = Color3.fromRGB(120, 130, 150),
		Pool = { Category = "property" },
	},
	{
		Id = "jetset",
		Name = "Jet Set",
		Theme = "Aviation",
		Price = 60000000,
		Icon = "✈️",
		Color = Color3.fromRGB(200, 220, 240),
		Pool = { Category = "aviation", MinValue = 5000000 },
	},

	-- Robux cases: buying one opens it instantly. Every item is numbered. -----------------------
	{
		Id = "velvetrope",
		Name = "Velvet Rope",
		Theme = "Robux · Numbered",
		Icon = "🎟️",
		Color = Color3.fromRGB(200, 30, 90),
		Pool = { Items = { "vr_wristband", "vr_bottle", "vr_mic", "vr_grillz", "vr_booth", "vr_supercar", "vr_club" } },
		TargetValue = 100000,
		GuaranteedMutation = true,
		Paid = { ProductId = 0, Robux = 99 },
	},
	{
		Id = "blackcard",
		Name = "Black Card",
		Theme = "Robux · Numbered",
		Icon = "💳",
		Color = Color3.fromRGB(60, 60, 70),
		Pool = {
			Items = { "bc_card", "bc_chef", "bc_suite", "bc_tourbillon", "bc_charter", "bc_jetcard", "bc_island" },
		},
		TargetValue = 450000,
		GuaranteedMutation = true,
		Paid = { ProductId = 0, Robux = 333 },
	},
	{
		Id = "jackpot",
		Name = "Jackpot",
		Theme = "Robux · Numbered",
		Icon = "🎰",
		Color = Color3.fromRGB(255, 180, 0),
		Pool = { Items = { "jp_chip", "jp_dice", "jp_slot", "jp_roulette", "jp_whale", "jp_floor", "jp_strip" } },
		TargetValue = 1800000,
		GuaranteedMutation = true,
		Paid = { ProductId = 0, Robux = 777 },
	},
	{
		Id = "popicons",
		Name = "Pop Icons",
		Theme = "Robux · Limited",
		Icon = "🧸",
		Color = Color3.fromRGB(0, 224, 255),
		Pool = {
			Items = {
				"lim_lubbu",
				"lim_quencher",
				"lim_dubaichoc",
				"lim_prym",
				"lim_brainrot",
				"lim_pixelape",
				"lim_cyberpickup",
				"lim_goldlubbu",
			},
		},
		Weights = "supply",
		GuaranteedMutation = true,
		Paid = { ProductId = 0, Robux = 999 },
	},
}

return Cases
