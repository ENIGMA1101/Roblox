--[[
	The item catalogue.

	Id        - permanent save key. NEVER rename an Id once the game is live (saved items point at it).
	            Renaming Name is safe.
	Rarity    - optional. Left out, it comes from the item's value (see Rarities.luau MinValue).
	Value     - base value. The brand multiplier and any mutation apply on top.
	Category  - used by themed cases ("watches", "sneakers", ...).
	Brands    - Brands.luau ids. The first 31 "generic" items roll one of several brands; every
	            other item is a specific product with exactly one brand, which brand cases use.
	Icon      - emoji fallback shown until you upload artwork.
	Image     - "rbxassetid://..." artwork. Leave "" to use Icon.
	Exclusive - only obtainable from cases that list it by id (the Robux cases' pools, or any
	            case's Grails). Every copy is numbered with a global serial.
	Names     - every Name is a parody. Don't use real product or model names.
	Supply    - total copies that can ever exist (Limited items). Leave out for unlimited.
	Weight    - optional; relative pick weight inside the mixed cases' rarity pools. Defaults to
	            value ^ -0.6, so cheaper items of a rarity show up more often.
]]

export type Item = {
	Id: string,
	Name: string,
	Rarity: string?,
	Value: number,
	Category: string,
	Icon: string,
	Image: string,
	Brands: { string },
	Exclusive: boolean?,
	Supply: number?,
	Weight: number?,
}

local Items: { Item } = {
	-- Common
	{
		Id = "socks",
		Category = "streetwear",
		Name = "Luxury Socks",
		Rarity = "Common",
		Value = 60,
		Icon = "🧦",
		Image = "",
		Brands = { "supremo", "offwhyte", "guchi", "balenciago" },
	},
	{
		Id = "cap",
		Category = "streetwear",
		Name = "Designer Cap",
		Rarity = "Common",
		Value = 110,
		Icon = "🧢",
		Image = "",
		Brands = { "supremo", "offwhyte", "guchi", "burbury" },
	},
	{
		Id = "tie",
		Category = "fashion",
		Name = "Silk Tie",
		Rarity = "Common",
		Value = 150,
		Icon = "👔",
		Image = "",
		Brands = { "burbury", "guchi", "versacci", "hermez" },
	},
	{
		Id = "perfume",
		Category = "fragrance",
		Name = "Signature Perfume",
		Rarity = "Common",
		Value = 190,
		Icon = "🧴",
		Image = "",
		Brands = { "tomfard", "dioor", "chanelle", "creedd" },
	},
	{
		Id = "sunglasses",
		Category = "fashion",
		Name = "Designer Sunglasses",
		Rarity = "Common",
		Value = 250,
		Icon = "🕶️",
		Image = "",
		Brands = { "raybam", "oakleaf", "persoll" },
	},

	-- Uncommon
	{
		Id = "scarf",
		Category = "fashion",
		Name = "Silk Scarf",
		Rarity = "Uncommon",
		Value = 450,
		Icon = "🧣",
		Image = "",
		Brands = { "burbury", "guchi", "louie", "hermez" },
	},
	{
		Id = "wallet",
		Category = "fashion",
		Name = "Leather Wallet",
		Rarity = "Uncommon",
		Value = 620,
		Icon = "👛",
		Image = "",
		Brands = { "guchi", "pradda", "louie", "chanelle" },
	},
	{
		Id = "heels",
		Category = "fashion",
		Name = "Designer Heels",
		Rarity = "Uncommon",
		Value = 850,
		Icon = "👠",
		Image = "",
		Brands = { "pradda", "versacci", "dioor", "chanelle" },
	},
	{
		Id = "sneakers",
		Category = "sneakers",
		Name = "Designer Sneakers",
		Rarity = "Uncommon",
		Value = 1100,
		Icon = "👟",
		Image = "",
		Brands = { "jordon", "offwhyte", "balenciago", "guchi", "dioor" },
	},

	-- Rare
	{
		Id = "phone",
		Category = "tech",
		Name = "Gold-Plated Phone",
		Rarity = "Rare",
		Value = 2400,
		Icon = "📱",
		Image = "",
		Brands = { "appel", "caviarr", "vertoo" },
	},
	{
		Id = "coat",
		Category = "streetwear",
		Name = "Designer Coat",
		Rarity = "Rare",
		Value = 3000,
		Icon = "🧥",
		Image = "",
		Brands = { "burbury", "balenciago", "pradda", "moncleer" },
	},
	{
		Id = "handbag",
		Category = "bags",
		Name = "Designer Handbag",
		Rarity = "Rare",
		Value = 4200,
		Icon = "👜",
		Image = "",
		Brands = { "guchi", "pradda", "dioor", "louie", "chanelle" },
	},
	{
		Id = "sportwatch",
		Category = "watches",
		Name = "Sport Watch",
		Rarity = "Rare",
		Value = 5500,
		Icon = "⌚",
		Image = "",
		Brands = { "taghoyer", "omego", "breitlin" },
	},
	{
		Id = "chain",
		Category = "jewellery",
		Name = "Cuban Link Chain",
		Rarity = "Rare",
		Value = 7000,
		Icon = "⛓️",
		Image = "",
		Brands = { "bulgarri", "tiffanny", "cartiay" },
	},

	-- Epic
	{
		Id = "champagne",
		Category = "drinks",
		Name = "Vintage Champagne Crate",
		Rarity = "Epic",
		Value = 18000,
		Icon = "🍾",
		Image = "",
		Brands = { "domperignonn", "krugg", "crystall", "aceofspadez" },
	},
	{
		Id = "watch",
		Category = "watches",
		Name = "Luxury Watch",
		Rarity = "Epic",
		Value = 32000,
		Icon = "⌚",
		Image = "",
		Brands = { "rolax", "audemars", "patek", "richardmillie" },
	},
	{
		Id = "ring",
		Category = "jewellery",
		Name = "Diamond Ring",
		Rarity = "Epic",
		Value = 48000,
		Icon = "💍",
		Image = "",
		Brands = { "tiffanny", "cartiay", "vanklief", "harrywinstone" },
	},
	{
		Id = "birkin",
		Category = "bags",
		Name = "Crocodile Birkyn",
		Rarity = "Epic",
		Value = 75000,
		Icon = "👜",
		Image = "",
		Brands = { "hermez" },
	},
	{
		Id = "piano",
		Category = "collectibles",
		Name = "Grand Piano",
		Rarity = "Epic",
		Value = 110000,
		Icon = "🎹",
		Image = "",
		Brands = { "yamahaa", "steinwey", "bosendorfur", "fazzioli" },
	},

	-- Legendary
	{
		Id = "supercar",
		Category = "cars",
		Name = "Supercar",
		Rarity = "Legendary",
		Value = 280000,
		Icon = "🏎️",
		Image = "",
		Brands = { "porshe", "mclarin", "lamborgino", "ferrarri" },
	},
	{
		Id = "grandtourer",
		Category = "cars",
		Name = "Grand Tourer",
		Rarity = "Legendary",
		Value = 350000,
		Icon = "🚗",
		Image = "",
		Brands = { "astonmarten", "bentlee", "rollsroyz" },
	},
	{
		Id = "speedboat",
		Category = "boats",
		Name = "Speedboat",
		Rarity = "Legendary",
		Value = 520000,
		Icon = "🚤",
		Image = "",
		Brands = { "cigarrette", "sunseaker", "rivah" },
	},
	{
		Id = "helicopter",
		Category = "aviation",
		Name = "Private Helicopter",
		Rarity = "Legendary",
		Value = 1400000,
		Icon = "🚁",
		Image = "",
		Brands = { "airbuzz", "sikorski", "agusta" },
	},

	-- Mythic
	{
		Id = "hypercar",
		Category = "hypercars",
		Name = "Hypercar",
		Rarity = "Mythic",
		Value = 3800000,
		Icon = "🏎️",
		Image = "",
		Brands = { "rimack", "paggani", "kronigsegg", "bugatty" },
	},
	{
		Id = "painting",
		Category = "art",
		Name = "Masterpiece Painting",
		Rarity = "Mythic",
		Value = 6500000,
		Icon = "🖼️",
		Image = "",
		Brands = { "bankzy", "monay", "pickasso", "vangoh" },
	},
	{
		Id = "penthouse",
		Category = "property",
		Name = "Sky Penthouse",
		Rarity = "Mythic",
		Value = 11000000,
		Icon = "🏙️",
		Image = "",
		Brands = { "dubay", "manhatton", "londun", "monako" },
	},
	{
		Id = "superyacht",
		Category = "boats",
		Name = "Superyacht",
		Rarity = "Mythic",
		Value = 17000000,
		Icon = "🛥️",
		Image = "",
		Brands = { "sunseaker", "benetty", "feadshipp", "lurssenn" },
	},

	-- Sovereign
	{
		Id = "orbital",
		Category = "aviation",
		Name = "Orbital Flight",
		Rarity = "Sovereign",
		Value = 32000000,
		Icon = "🚀",
		Image = "",
		Brands = { "virgo", "blueorijin", "spacey" },
	},
	{
		Id = "jet",
		Category = "aviation",
		Name = "Private Jet",
		Rarity = "Sovereign",
		Value = 55000000,
		Icon = "✈️",
		Image = "",
		Brands = { "embrayer", "dassot", "bombardeer", "gulfstreem" },
	},
	{
		Id = "estate",
		Category = "property",
		Name = "Mega Estate",
		Rarity = "Sovereign",
		Value = 90000000,
		Icon = "🏰",
		Image = "",
		Brands = { "aspenn", "beverlyhilts", "belaire", "monako" },
	},
	{
		Id = "island",
		Category = "property",
		Name = "Private Island",
		Rarity = "Sovereign",
		Value = 150000000,
		Icon = "🏝️",
		Image = "",
		Brands = { "carribbean", "maldeeves", "boraborah" },
	},
}

-- Specific products: { id, name, brand, value, icon, extras? } ----------------------------------

local function add(category: string, rows: { { any } }, shared: { [string]: any }?)
	for _, row in rows do
		local item: { [string]: any } = {
			Id = row[1],
			Name = row[2],
			Brands = { row[3] },
			Value = row[4],
			Icon = row[5],
			Image = "",
			Category = category,
		}
		if shared then
			for key, value in shared do
				item[key] = value
			end
		end
		local extras = row[6]
		if extras then
			for key, value in extras do
				item[key] = value
			end
		end
		table.insert(Items, item :: any)
	end
end

add("sneakers", {
	{ "yeezus_slide", "Foam Glider Slide", "yeezus", 190, "🩴" },
	{ "nikey_dunk", "Dunkk Low 'Pandah'", "nikey", 280, "👟" },
	{ "newbalanse_990", "991 Made in Somewhere", "newbalanse", 360, "👟" },
	{ "jordon_retro", "Retro Hi Won", "jordon", 450, "👟" },
	{ "yeezus_350", "Bounce 305 V3", "yeezus", 520, "👟" },
	{ "balenciago_triple", "Triple-Stack Runner", "balenciago", 1100, "👟" },
	{ "dioor_b23", "B32 Hi-Top", "dioor", 1300, "👟" },
	{ "jordon_cactus", "Kaktus Retro Low", "jordon", 1600, "👟" },
	{ "offwhyte_ten", "The Tenn Collab", "offwhyte", 1900, "👟" },
	{ "nikey_mag", "Self-Lacing Futures", "nikey", 42000, "👟" },
	{ "jordon_gameworn", "1985 Game-Worn Originals", "jordon", 180000, "👟" },
	{ "jordon_gold", "24K Solid Gold Wons", "jordon", 650000, "👟" },
})

add("streetwear", {
	{ "stussie_tee", "8-Bawl Tee", "stussie", 120, "👕" },
	{ "fog_sweats", "Essentialz Sweatpants", "fearofgawd", 140, "👖" },
	{ "palase_crew", "Tri-Fergo Crewneck", "palase", 260, "👕" },
	{ "supremo_brick", "Logo Brick", "supremo", 380, "🧱" },
	{ "monke_shark", "Shork Full-Zip Hoodie", "monke", 750, "🧥" },
	{ "supremo_box", "Box Logoh Hoodie", "supremo", 900, "🧥" },
	{ "balenciago_hoodie", "Oversized Hoodie", "balenciago", 1050, "🧥" },
	{ "moncleer_maya", "Mayah Puffer", "moncleer", 1900, "🧥" },
	{ "chromeheartz_hoodie", "Cross Patch Hoodie", "chromeheartz", 2800, "🧥" },
	{ "guchi_tracksuit", "Webb Tracksuit", "guchi", 3200, "🧥" },
	{ "louie_varsity", "Monogrammed Varsity", "louie", 7500, "🧥" },
	{ "supremo_sample", "Unreleased Sample Jacket", "supremo", 24000, "🧥" },
})

add("fragrance", {
	{ "chanelle_no5", "No. 6 Parfum", "chanelle", 150, "🧴" },
	{ "dioor_sauvage", "Savage Elixxir", "dioor", 170, "🧴" },
	{ "lelabbo_santal", "Santol 34", "lelabbo", 290, "🧴" },
	{ "tomfard_tobacco", "Tobaco Vanilla", "tomfard", 320, "🧴" },
	{ "kurkjin_540", "Bakkara Rouge 450", "kurkjin", 380, "🧴" },
	{ "creedd_aventus", "Adventurus", "creedd", 450, "🧴" },
	{ "creedd_magnum", "Royale Oudh Magnum", "creedd", 1400, "🧴" },
	{ "tomfard_set", "Private Blends Decanter Set", "tomfard", 2300, "🧴" },
	{ "kurkjin_crystal", "Bakkara Crystal Edition", "kurkjin", 6500, "🧴" },
	{ "clivekristen_imperial", "Imperial Majestee", "clivekristen", 18000, "🧴" },
})

add("tech", {
	{ "appel_airbuds", "AirBuds Pro", "appel", 250, "🎧" },
	{ "beets_studio", "Studio Pro Headphones", "beets", 350, "🎧" },
	{ "bowse_soundlink", "SoundLynk Max", "bowse", 400, "🔊" },
	{ "nintendough_swytch", "Swytch 2", "nintendough", 450, "🎮" },
	{ "sonee_ps5", "PlayStayshun 5 Pro", "sonee", 700, "🎮" },
	{ "appel_watchultra", "Appel Watch Ultra", "appel", 900, "⌚" },
	{ "appel_iphonne", "iPhonne 16 Pro Max", "appel", 1300, "📱" },
	{ "djay_mavik", "Mavik 4 Drone", "djay", 2100, "🛸" },
	{ "appel_vizion", "Vizion Pro", "appel", 3600, "🥽" },
	{ "appel_macbok", "MacBok Pro M4 Max", "appel", 4200, "💻" },
	{ "rigforge_4090", "Custom 4090 Gaming Rig", "rigforge", 5500, "🖥️" },
	{ "appel_display", "Pro Display XDRR", "appel", 5500, "🖥️" },
	{ "hasselbladd_x2d", "XD2 Medium Format", "hasselbladd", 8200, "📷" },
	{ "leeca_m11", "M-Eleven Rangefinder", "leeca", 9800, "📷" },
	{ "appel_macpro", "MacBok Tower (Wheels Kit)", "appel", 12000, "🖥️" },
	{ "appel_goldwatch", "Watch Edition 18K Gold", "appel", 17000, "⌚" },
	{ "caviarr_goldphone", "Solid Gold iPhonne", "caviarr", 38000, "📱" },
	{ "appel_prototype", "Prototype iPhonne", "appel", 90000, "📱" },
	{ "vertoo_cobra", "Signature Cobra Phone", "vertoo", 310000, "📱" },
	{ "appel_one", "Original Appel-1 Computer", "appel", 400000, "🖥️" },
})

add("watches", {
	{ "casioh_gold", "Gold Digital Watch", "casioh", 90, "⌚" },
	{ "seeko_5", "Seeko Fivey Sports", "seeko", 300, "⌚" },
	{ "tudr_bb58", "Black Bayou 58", "tudr", 4300, "⌚" },
	{ "taghoyer_carrera", "Carrerra Chronograph", "taghoyer", 5200, "⌚" },
	{ "omego_seamaster", "Seamasterr Diver 300M", "omego", 5800, "⌚" },
	{ "grandseeko_snowflake", "Snowflayke", "grandseeko", 6200, "⌚" },
	{ "omego_speedy", "Speedmasterr Moonwotch", "omego", 7500, "⌚" },
	{ "cartiay_santos", "Santoss Large", "cartiay", 8100, "⌚" },
	{ "breitlin_navitimer", "Navitymer B02", "breitlin", 8900, "⌚" },
	{ "rolax_datejust", "Datejusst 41", "rolax", 11000, "⌚" },
	{ "rolax_sub", "Submarinerr Date", "rolax", 14000, "⌚" },
	{ "rolax_gmt", "GMT-Mastah II 'Soda'", "rolax", 21000, "⌚" },
	{ "hublo_bigbang", "Big Bong Uniko", "hublo", 22000, "⌚" },
	{ "rolax_daytona", "Daytonna Steel", "rolax", 32000, "⌚" },
	{ "vasheron_overseas", "Overseez", "vasheron", 42000, "⌚" },
	{ "rolax_daydate", "Day-Dayt Presidential", "rolax", 45000, "⌚" },
	{ "audemars_offshore", "Royal Oke Offshore", "audemars", 48000, "⌚" },
	{ "audemars_royaloak", "Royal Oke 15505", "audemars", 55000, "⌚" },
	{ "patek_aquanaut", "Aquanaught 5176", "patek", 95000, "⌚" },
	{ "patek_nautilus", "Nautilous 5171", "patek", 140000, "⌚" },
	{ "richardmillie_rm11", "RM 13-11", "richardmillie", 320000, "⌚" },
	{ "rolax_rainbow", "Daytonna Rainbow", "rolax", 480000, "⌚" },
	{ "richardmillie_rm27", "RM 72 Tennis Edition", "richardmillie", 1200000, "⌚" },
	{ "rolax_exotic", "1969 Exotic Dial Daytonna", "rolax", 2500000, "⌚" },
	{ "patek_grandmaster", "Grandmastah Chyme", "patek", 8500000, "⌚" },
	{ "jakob_billionaire", "Billionaire Diamond Watch", "jakob", 18000000, "⌚" },
})

add("bags", {
	{ "pradda_nylon", "Re-Edishun Nylon", "pradda", 1900, "👜" },
	{ "louie_neverfull", "Neverempty MM", "louie", 2100, "👜" },
	{ "goyardd_tote", "Saint Lewis Tote", "goyardd", 2200, "👜" },
	{ "guchi_marmont", "Marmot Shoulder Bag", "guchi", 2600, "👜" },
	{ "louie_keepall", "Keep-It-All 55", "louie", 2800, "🧳" },
	{ "yslorent_loulou", "Loolah Puffer", "yslorent", 3100, "👜" },
	{ "bottega_jodie", "Jodee", "bottega", 3300, "👜" },
	{ "celeen_triomphe", "Triumf", "celeen", 3600, "👜" },
	{ "fendy_baguette", "Bagette", "fendy", 3800, "👜" },
	{ "dioor_saddle", "Sadle Bag", "dioor", 4300, "👜" },
	{ "chanelle_22", "Chanelle 23", "chanelle", 7000, "👜" },
	{ "chanelle_flap", "Classic Flapp", "chanelle", 11000, "👜" },
	{ "hermez_birkin25", "Birkyn 25 Togoh", "hermez", 32000, "👜" },
	{ "hermez_kelly", "Kellee 28", "hermez", 38000, "👜" },
	{ "louie_trunk", "Monogrammed Hard Trunk", "louie", 65000, "🧳" },
	{ "hermez_himalaya", "Himalayan Birkyn", "hermez", 700000, "👜" },
	{ "hermez_diamond", "Diamond Himalayan Birkyn", "hermez", 3800000, "👜" },
})

add("jewellery", {
	{ "chromeheartz_ring", "Cross Ring", "chromeheartz", 650, "💍" },
	{ "tiffanny_hardwear", "HardWare Bracelet", "tiffanny", 2400, "📿" },
	{ "cartiay_clou", "Just a Nail Ring", "cartiay", 3100, "💍" },
	{ "vanklief_alhambra", "Alhambrah Necklace", "vanklief", 5200, "📿" },
	{ "cartiay_love", "Luv Bracelet", "cartiay", 7600, "📿" },
	{ "bulgarri_serpenti", "Serpentee Bracelet", "bulgarri", 12000, "🐍" },
	{ "iceboxco_grillz", "VVS Diamond Grillz", "iceboxco", 18000, "😁" },
	{ "iceboxco_cuban", "Iced Cuban Link", "iceboxco", 45000, "⛓️" },
	{ "tiffanny_solitaire", "3ct Solitaire Ring", "tiffanny", 68000, "💍" },
	{ "harrywinstone_tennis", "Diamond Tennis Necklace", "harrywinstone", 120000, "📿" },
	{ "iceboxco_pendant", "Custom Diamond Pendant", "iceboxco", 150000, "🏅" },
	{ "harrywinstone_pink", "Pink Diamond Ring", "harrywinstone", 4500000, "💍" },
	{ "graaf_blueheart", "Blue Hart Diamond", "graaf", 28000000, "🔷" },
	{ "faberje_egg", "Imperial Jewelled Egg", "faberje", 35000000, "🥚" },
})

add("drinks", {
	{ "patrone_silver", "Silver Tequila", "patrone", 60, "🥃" },
	{ "claseazool_reposado", "Reposado Decanter", "claseazool", 180, "🍶" },
	{ "hennesy_xo", "X.O.O. Cognac", "hennesy", 240, "🥃" },
	{ "domperignonn_brut", "Vintage Brut", "domperignonn", 310, "🍾" },
	{ "aceofspadez_gold", "Brut Gold", "aceofspadez", 420, "🍾" },
	{ "macallen_18", "18 Year Sherry Oak", "macallen", 520, "🥃" },
	{ "macallen_30", "30 Year Fine Oak", "macallen", 4800, "🥃" },
	{ "louie13_cognac", "Louie XIII Cognac", "louie13", 5500, "🥃" },
	{ "aceofspadez_nebu", "Nebuchadnezzar Bottle", "aceofspadez", 45000, "🍾" },
	{ "macallen_72", "72 Year Genesys Decanter", "macallen", 95000, "🥃" },
	{ "romanay_1945", "1945 Grand Cru", "romanay", 560000, "🍷" },
	{ "macallen_cask", "Private Whisky Cask", "macallen", 650000, "🛢️" },
})

add("collectibles", {
	{ "funkoh_chase", "Chase Vinyl Figure", "funkoh", 140, "🧸" },
	{ "pokemann_booster", "Holo Booster Box", "pokemann", 350, "🃏" },
	{ "leggo_freighter", "Ultimate Star Freighter Set", "leggo", 850, "🧱" },
	{ "medicomm_1000", "Bearbrik 1000%", "medicomm", 2400, "🧸" },
	{ "topz_jersey", "Signed Championship Jersey", "topz", 2800, "👕" },
	{ "topz_rookie", "Graded Rookie Card", "topz", 9000, "🏀" },
	{ "topz_ball", "Final Game Ball", "topz", 18000, "🏈" },
	{ "pokemann_dragon", "1st Edition Holo Dragon", "pokemann", 42000, "🃏" },
	{ "kawz_companion", "Kompanion Figure 4ft", "kawz", 55000, "🧸" },
	{ "pokemann_psa10", "PSA 10 Shadowless Dragon", "pokemann", 400000, "🃏" },
	{ "nintendough_sealed", "Sealed '85 Plumber Bros.", "nintendough", 1200000, "🎮" },
	{ "marvelus_first", "First Appearance Comic #1", "marvelus", 3500000, "📕" },
})

add("cars", {
	{ "bmv_m4", "M-Four Competishun", "bmv", 85000, "🚗" },
	{ "teslo_plaid", "Model Z Plaidd", "teslo", 90000, "🚗" },
	{ "awdi_rs6", "RS-Six Avant", "awdi", 130000, "🚗" },
	{ "mercedez_g63", "G-Wagon G36", "mercedez", 180000, "🚙" },
	{ "rangrover_sv", "SVV Autobiographee", "rangrover", 210000, "🚙" },
	{ "maybock_s680", "S860 Maybock", "maybock", 240000, "🚗" },
	{ "porshe_gt3rs", "119 GT3 RSS", "porshe", 260000, "🏎️" },
	{ "lamborgino_urus", "Uruz Performantay", "lamborgino", 270000, "🚙" },
	{ "bentlee_gtspeed", "Continentel GT Speed", "bentlee", 300000, "🚗" },
	{ "mercedez_black", "AMG GT Blak Series", "mercedez", 310000, "🏎️" },
	{ "lamborgino_sto", "Hurricane STOO", "lamborgino", 340000, "🏎️" },
	{ "mclarin_765", "567LT Spider", "mclarin", 380000, "🏎️" },
	{ "rollsroyz_cullinan", "Cullinun Black Badge", "rollsroyz", 420000, "🚙" },
	{ "ferrarri_purosangue", "Purrosangue", "ferrarri", 450000, "🚙" },
	{ "rollsroyz_spectre", "Spektre", "rollsroyz", 450000, "🚗" },
	{ "ferrarri_sf90", "FS09 Stradalay", "ferrarri", 520000, "🏎️" },
	{ "lamborgino_revuelto", "Revoltoh", "lamborgino", 620000, "🏎️" },
	{ "astonmarten_valkyrie", "Valkyree", "astonmarten", 3500000, "🏎️" },
	{ "rollsroyz_boattail", "Boat Tayl Coachbuild", "rollsroyz", 28000000, "🚗" },
	{ "ferrarri_250gto", "1962 205 GTOO", "ferrarri", 48000000, "🏎️" },
})

add("hypercars", {
	{ "rimack_nevera", "Neverrah", "rimack", 2400000, "🏎️" },
	{ "kronigsegg_jesko", "Jeskoh Absolute", "kronigsegg", 3600000, "🏎️" },
	{ "bugatty_chiron", "Chyron Super Sport", "bugatty", 3900000, "🏎️" },
	{ "paggani_huayra", "Wayrah BC", "paggani", 4200000, "🏎️" },
	{ "kronigsegg_ccxr", "CCRX Trevitah", "kronigsegg", 5000000, "🏎️" },
	{ "ferrarri_laferrari", "LaFerrarri Apertah", "ferrarri", 5500000, "🏎️" },
	{ "bugatty_divo", "Deevo", "bugatty", 6000000, "🏎️" },
	{ "paggani_zonda", "Zondah R", "paggani", 9000000, "🏎️" },
	{ "bugatty_noire", "La Voiturr Noir", "bugatty", 19000000, "🏎️" },
	{ "mclarin_f1", "Original Eff-One (1994)", "mclarin", 21000000, "🏎️" },
})

add("bikes", {
	{ "vespah_gts", "GTS Scooter", "vespah", 8000, "🛵" },
	{ "specialised_ebike", "Carbon E-Bike", "specialised", 11000, "🚲" },
	{ "ducatti_monster", "Monstah SP", "ducatti", 18000, "🏍️" },
	{ "harley_fatboy", "Phat Boy 114", "harleydavidsun", 24000, "🏍️" },
	{ "bmv_m1000", "M 1001 RR", "bmv", 38000, "🏍️" },
	{ "mvagoosta_rush", "Rushh 1000", "mvagoosta", 42000, "🏍️" },
	{ "ducatti_panigale", "Panigalay V4 R", "ducatti", 45000, "🏍️" },
	{ "kawasakee_h2r", "Ninjah H2RR", "kawasakee", 58000, "🏍️" },
	{ "nimen_chopper", "Limited Custom Chopper", "nimen", 110000, "🏍️" },
	{ "ecossee_titanium", "Titanium Series FE", "ecossee", 150000, "🏍️" },
	{ "vyruss_prototype", "Carbon Superbike Prototype", "vyruss", 350000, "🏍️" },
	{ "harley_1908", "1908 Strap Tank Original", "harleydavidsun", 1000000, "🏍️" },
})

add("boats", {
	{ "seadu_rxpx", "RXX-P Jet Ski", "seadu", 22000, "🚤" },
	{ "benningtun_pontoon", "Luxury Pontoon", "benningtun", 95000, "🚤" },
	{ "rivah_aquarama", "Aquaramah Classic", "rivah", 1400000, "🚤" },
	{ "cigarrette_tirranna", "Tiranna 95", "cigarrette", 3300000, "🚤" },
	{ "sunseaker_manhattan", "Manhattun 86", "sunseaker", 4000000, "🛥️" },
	{ "tritton_sub", "Personal Submarine", "tritton", 5500000, "🚢" },
	{ "benetty_oasis", "Oasys 40M", "benetty", 14000000, "🛥️" },
	{ "wallee_cento", "WalleeCentoh Sailing Yacht", "wallee", 18000000, "⛵" },
	{ "feadshipp_symphony", "Symfonee 101M", "feadshipp", 150000000, "🛥️" },
	{ "lurssenn_azzam", "Azzamm 180M", "lurssenn", 600000000, "🛥️" },
})

add("aviation", {
	{ "robinsun_r44", "R-44 Heli", "robinsun", 600000, "🚁" },
	{ "cirruss_sr22", "SR-222 Turbo", "cirruss", 900000, "🛩️" },
	{ "hondajett_elite", "Elyte II", "hondajett", 7000000, "✈️" },
	{ "embrayer_phenom", "Fenom 300E", "embrayer", 11000000, "✈️" },
	{ "airbuzz_h160", "H-161 VIP Helicopter", "airbuzz", 21000000, "🚁" },
	{ "dassot_falcon", "Falkon 10XX", "dassot", 75000000, "✈️" },
	{ "gulfstreem_g700", "G-7000", "gulfstreem", 78000000, "✈️" },
	{ "bombardeer_global", "Globel 8008", "bombardeer", 80000000, "✈️" },
	{ "concordia_super", "Retired Supersonic Airliner", "concordia", 250000000, "✈️" },
	{ "boing_bbj", "Business Jet 787", "boing", 300000000, "✈️" },
	{ "spacey_lunar", "Lunar Flyby Seat", "spacey", 450000000, "🚀" },
})

add("art", {
	{ "bankzy_print", "Signed Balloon Print", "bankzy", 45000, "🖼️" },
	{ "warhole_soup", "Soup Tin Screenprint", "warhole", 160000, "🖼️" },
	{ "kawz_canvas", "Kawz Canvas", "kawz", 900000, "🖼️" },
	{ "bankzy_mural", "Commissioned Street Mural", "bankzy", 2200000, "🎨" },
	{ "warhole_pop", "Pop Portrait Silkscreen", "warhole", 5000000, "🖼️" },
	{ "bankzy_shredded", "Self-Shredding Canvas", "bankzy", 25000000, "🖼️" },
	{ "monay_lilies", "Water Lillys", "monay", 55000000, "🎨" },
	{ "koonz_rabbit", "Chrome Balloon Rabbit", "koonz", 90000000, "🐰" },
	{ "basquiet_skull", "Untitled Skull", "basquiet", 110000000, "🎨" },
	{ "pickasso_cubist", "Cubist Portrait", "pickasso", 140000000, "🎨" },
	{ "vangoh_starry", "Starry Nite Study", "vangoh", 380000000, "🎨" },
	{ "davinchi_lost", "Lost Renaissance Masterpiece", "davinchi", 450000000, "🖼️" },
})

add("property", {
	{ "dubay_studio", "Marina Studio", "dubay", 900000, "🏢" },
	{ "manhatton_loft", "SoHo Loft", "manhatton", 4500000, "🏙️" },
	{ "maldeeves_villa", "Overwater Villa", "maldeeves", 6000000, "🏝️" },
	{ "hylands_castle", "Highland Castle", "hylands", 12000000, "🏰" },
	{ "aspenn_chalet", "Ski Chalet", "aspenn", 18000000, "🏔️" },
	{ "londun_townhouse", "Mayfair Townhouse", "londun", 22000000, "🏘️" },
	{ "beverlyhilts_mansion", "Hillside Mansion", "beverlyhilts", 38000000, "🏡" },
	{ "bordo_chateau", "Wine Château", "bordo", 45000000, "🍇" },
	{ "monako_harbour", "Harbour Penthouse", "monako", 60000000, "🏙️" },
	{ "dubay_skyfloor", "Private Skyscraper Floor", "dubay", 95000000, "🏙️" },
	{ "belaire_giga", "Giga Estate", "belaire", 180000000, "🏰" },
})

-- Robux-case exclusives: numbered (every copy gets a global serial) -----------------------------

local EXCLUSIVE = { Rarity = "Limited", Exclusive = true }

add("velvetrope", {
	{ "vr_wristband", "Gold VIP Wristband", "velvetrope", 12000, "🎟️" },
	{ "vr_bottle", "Sparkler Bottle Service", "velvetrope", 28000, "🍾" },
	{ "vr_mic", "Gold Microphone", "velvetrope", 55000, "🎤" },
	{ "vr_grillz", "Rose Gold Grillz", "velvetrope", 90000, "😁" },
	{ "vr_booth", "Private Booth Key", "velvetrope", 180000, "🗝️" },
	{ "vr_supercar", "Neon-Wrapped Supercar", "velvetrope", 750000, "🏎️" },
	{ "vr_club", "The Whole Nightclub", "velvetrope", 6000000, "🪩" },
}, EXCLUSIVE)

add("blackcard", {
	{ "bc_card", "Titanium Black Card", "blackcard", 60000, "💳" },
	{ "bc_chef", "Private Chef Night", "blackcard", 110000, "🍽️" },
	{ "bc_suite", "Presidential Suite Stay", "blackcard", 240000, "🛎️" },
	{ "bc_tourbillon", "Black Card Tourbillon", "blackcard", 600000, "⌚" },
	{ "bc_charter", "Superyacht Charter Week", "blackcard", 1500000, "🛥️" },
	{ "bc_jetcard", "Jet Card: 100 Hours", "blackcard", 4500000, "✈️" },
	{ "bc_island", "Island Buyout Weekend", "blackcard", 25000000, "🏝️" },
}, EXCLUSIVE)

add("jackpot", {
	{ "jp_chip", "High Roller Chip", "highroller", 250000, "🪙" },
	{ "jp_dice", "Diamond Dice", "highroller", 600000, "🎲" },
	{ "jp_slot", "Golden Slot Machine", "highroller", 1500000, "🎰" },
	{ "jp_roulette", "Solid Gold Roulette Wheel", "highroller", 3500000, "🎡" },
	{ "jp_whale", "Whale Suite Key", "highroller", 8000000, "🐋" },
	{ "jp_floor", "Your Own Casino Floor", "highroller", 40000000, "🏛️" },
	{ "jp_strip", "The Strip Megaresort", "highroller", 250000000, "🌃" },
}, EXCLUSIVE)

-- Limited: capped supply across every server, forever.
add("popculture", {
	{ "lim_lubbu", "Lubbu Plush (Secret Edition)", "popmartt", 1200000, "🧸", { Supply = 5000 } },
	{ "lim_quencher", "Diamond Quenchah 40oz", "stanlee", 2000000, "🥤", { Supply = 4000 } },
	{ "lim_dubaichoc", "Gold Leaf Pistachio Chocolate", "fixx", 3500000, "🍫", { Supply = 3000 } },
	{ "lim_prym", "Prym Launch Crate (Sealed)", "prym", 6000000, "🧃", { Supply = 2000 } },
	{ "lim_brainrot", "Golden Brainrot Idol", "brainrotstudio", 15000000, "🗿", { Supply = 800 } },
	{ "lim_pixelape", "Pixel Ape #0001 Canvas", "pixelapeclub", 40000000, "🐵", { Supply = 300 } },
	{ "lim_cyberpickup", "Cyber Pickup (Stainless)", "teslo", 120000000, "🛻", { Supply = 100 } },
	{ "lim_goldlubbu", "The Golden Lubbu", "popmartt", 500000000, "👑", { Supply = 10 } },
}, EXCLUSIVE)

-- Grails: the ultra-rare bragging-rights tiers. Numbered, and only drop from cases that list
-- them in Grails (at odds like 1 in 250,000), so cheap cases hold a one-in-a-lifetime pull too.

local function grails(rarity: string, category: string, rows: { { any } })
	add(category, rows, { Rarity = rarity, Exclusive = true })
end

grails("Imperial", "fragrance", { { "imp_perfume", "Liquid Diamond Parfum", "kurkjin", 6000000, "💧" } })
grails("Imperial", "streetwear", { { "imp_hoodie", "Gold Thread Box Hoodie", "supremo", 8000000, "🧥" } })
grails("Imperial", "tech", {
	{ "imp_console", "24K Prototype Console", "sonee", 12000000, "🎮" },
	{ "imp_phone", "Diamond Prototype iPhonne", "appel", 20000000, "📱" },
})
grails("Imperial", "drinks", { { "imp_whisky", "Cask No. 1 Whisky", "macallen", 15000000, "🥃" } })
grails("Imperial", "bikes", { { "imp_bike", "Gold-Plated Hyperbike", "ducatti", 18000000, "🏍️" } })
grails("Imperial", "sneakers", { { "imp_sneakers", "Diamond Grail Sneakers", "nikey", 25000000, "👟" } })
grails("Imperial", "watches", {
	{ "imp_rolax", "Rainbow Sapphire Daytonna", "rolax", 30000000, "⌚" },
	{ "imp_watch", "Meteorite Tourbillon One-Off", "patek", 40000000, "⌚" },
})
grails("Imperial", "collectibles", { { "imp_card", "1-of-1 Golden Rookie Card", "topz", 30000000, "🃏" } })
grails("Imperial", "bags", { { "imp_bag", "Rainbow Diamond Birkyn", "hermez", 45000000, "👜" } })
grails("Imperial", "jewellery", { { "imp_ring", "Flawless Pink Heart Ring", "graaf", 55000000, "💖" } })

grails("Ethereal", "cars", { { "eth_stallion", "Crystal One-Off Stallion", "ferrarri", 400000000, "🏎️" } })
grails("Ethereal", "hypercars", { { "eth_hypercar", "Carbon Diamond Hypercar", "bugatty", 600000000, "🏎️" } })
grails("Ethereal", "jewellery", { { "eth_necklace", "Ocean's Heart Diamond", "harrywinstone", 800000000, "💎" } })
grails("Ethereal", "art", { { "eth_triptych", "The Lost Da Vinchi Triptych", "davinchi", 1200000000, "🖼️" } })
grails("Ethereal", "aviation", { { "eth_palace", "Flying Palace Airliner", "boing", 2000000000, "✈️" } })
grails("Ethereal", "property", { { "eth_tower", "Private Supertall Tower", "dubay", 3000000000, "🏙️" } })
grails("Ethereal", "boats", { { "eth_yacht", "Solid Gold Superyacht", "lurssenn", 4000000000, "🛥️" } })

grails("Omega", "property", {
	{ "om_nation", "Private Island Nation", "maldeeves", 20000000000, "🏝️" },
	{ "om_moon", "Deed to a Lunar Crater", "spacey", 100000000000, "🌕" },
})
grails("Omega", "aviation", { { "om_station", "Private Space Station", "spacey", 50000000000, "🛰️" } })

return Items
