--[[
	Parody luxury houses. An item lists which brands can appear on it (Items.luau);
	the brand then nudges the price and decides how often it shows up.

	Mult   - value multiplier applied to the item's base value (keep it "slight": ~0.85-1.25)
	Weight - how common the brand is relative to the other brands on the same item.
	         Prestige brands get a higher Mult and a lower Weight.

	For real estate and art the "brand" is the location / artist.
]]

export type Brand = {
	Name: string,
	Mult: number,
	Weight: number,
}

local Brands: { [string]: Brand } = {
	-- Eyewear
	raybam = { Name = "Ray-Bam", Mult = 0.92, Weight = 50 },
	oakleaf = { Name = "Oakleaf", Mult = 0.96, Weight = 35 },
	persoll = { Name = "Persoll", Mult = 1.10, Weight = 15 },

	-- Fashion houses
	guchi = { Name = "Guchi", Mult = 1.00, Weight = 30 },
	louie = { Name = "Louie Vuittin", Mult = 1.08, Weight = 22 },
	pradda = { Name = "Pradda", Mult = 1.02, Weight = 25 },
	hermez = { Name = "Hermez", Mult = 1.22, Weight = 8 },
	balenciago = { Name = "Balenciago", Mult = 0.96, Weight = 24 },
	burbury = { Name = "Burbury", Mult = 0.92, Weight = 30 },
	versacci = { Name = "Versacci", Mult = 1.04, Weight = 20 },
	dioor = { Name = "Dioor", Mult = 1.06, Weight = 18 },
	chanelle = { Name = "Chanelle", Mult = 1.12, Weight = 14 },
	offwhyte = { Name = "Off-Whyte", Mult = 0.90, Weight = 30 },
	jordon = { Name = "Jordon", Mult = 0.88, Weight = 36 },
	moncleer = { Name = "Moncleer", Mult = 1.05, Weight = 18 },
	supremo = { Name = "Supremo", Mult = 0.90, Weight = 32 },

	-- Fragrance
	tomfard = { Name = "Tom Fard", Mult = 1.05, Weight = 20 },
	creedd = { Name = "Creedd", Mult = 1.18, Weight = 10 },

	-- Tech
	appel = { Name = "Appel", Mult = 0.90, Weight = 60 },
	caviarr = { Name = "Caviarr", Mult = 1.05, Weight = 25 },
	vertoo = { Name = "Vertoo", Mult = 1.15, Weight = 15 },

	-- Watches
	taghoyer = { Name = "Tag Hoyer", Mult = 0.88, Weight = 40 },
	omego = { Name = "Omego", Mult = 0.95, Weight = 35 },
	breitlin = { Name = "Breitlin", Mult = 0.98, Weight = 25 },
	rolax = { Name = "Rolax", Mult = 1.00, Weight = 40 },
	audemars = { Name = "Audemars Pigeon", Mult = 1.15, Weight = 18 },
	patek = { Name = "Patek Filippe", Mult = 1.22, Weight = 12 },
	richardmillie = { Name = "Richard Millie", Mult = 1.25, Weight = 6 },

	-- Jewellery
	tiffanny = { Name = "Tiffanny & Co.", Mult = 1.00, Weight = 34 },
	bulgarri = { Name = "Bulgarri", Mult = 0.98, Weight = 26 },
	cartiay = { Name = "Cartiay", Mult = 1.05, Weight = 28 },
	vanklief = { Name = "Van Klief & Arpels", Mult = 1.12, Weight = 14 },
	harrywinstone = { Name = "Harry Winstone", Mult = 1.22, Weight = 10 },

	-- Champagne
	domperignonn = { Name = "Dom Perignonn", Mult = 1.00, Weight = 40 },
	krugg = { Name = "Krugg", Mult = 1.05, Weight = 20 },
	crystall = { Name = "Crystall", Mult = 1.08, Weight = 30 },
	aceofspadez = { Name = "Ace of Spadez", Mult = 1.20, Weight = 15 },

	-- Pianos
	yamahaa = { Name = "Yamahaa", Mult = 0.85, Weight = 50 },
	steinwey = { Name = "Steinwey", Mult = 1.05, Weight = 45 },
	bosendorfur = { Name = "Bosendorfur", Mult = 1.12, Weight = 25 },
	fazzioli = { Name = "Fazzioli", Mult = 1.20, Weight = 15 },

	-- Cars
	porshe = { Name = "Porshe", Mult = 0.88, Weight = 34 },
	mclarin = { Name = "McLarin", Mult = 0.96, Weight = 24 },
	astonmarten = { Name = "Aston Marten", Mult = 0.98, Weight = 22 },
	bentlee = { Name = "Bentlee", Mult = 1.00, Weight = 24 },
	lamborgino = { Name = "Lamborgino", Mult = 1.06, Weight = 28 },
	ferrarri = { Name = "Ferrarri", Mult = 1.10, Weight = 26 },
	rollsroyz = { Name = "Rolls-Royz", Mult = 1.18, Weight = 12 },

	-- Hypercars
	rimack = { Name = "Rimack", Mult = 0.90, Weight = 30 },
	paggani = { Name = "Paggani", Mult = 1.06, Weight = 22 },
	kronigsegg = { Name = "Kronigsegg", Mult = 1.10, Weight = 20 },
	bugatty = { Name = "Bugatty", Mult = 1.22, Weight = 14 },

	-- Boats & yachts
	cigarrette = { Name = "Cigarrette", Mult = 0.95, Weight = 30 },
	rivah = { Name = "Rivah", Mult = 1.08, Weight = 20 },
	sunseaker = { Name = "Sunseaker", Mult = 0.90, Weight = 35 },
	benetty = { Name = "Benetty", Mult = 1.00, Weight = 30 },
	feadshipp = { Name = "Feadshipp", Mult = 1.15, Weight = 14 },
	lurssenn = { Name = "Lurssenn", Mult = 1.22, Weight = 10 },

	-- Helicopters
	airbuzz = { Name = "Airbuzz", Mult = 0.95, Weight = 35 },
	sikorski = { Name = "Sikorski", Mult = 1.00, Weight = 28 },
	agusta = { Name = "Agusta Westlend", Mult = 1.12, Weight = 18 },

	-- Jets
	embrayer = { Name = "Embrayer", Mult = 0.88, Weight = 30 },
	dassot = { Name = "Dassot", Mult = 0.96, Weight = 28 },
	bombardeer = { Name = "Bombardeer", Mult = 1.00, Weight = 32 },
	gulfstreem = { Name = "Gulfstreem", Mult = 1.08, Weight = 30 },

	-- Space
	virgo = { Name = "Virgo Galactik", Mult = 0.88, Weight = 30 },
	blueorijin = { Name = "Blue Orijin", Mult = 0.94, Weight = 40 },
	spacey = { Name = "Space-Y", Mult = 1.05, Weight = 40 },

	-- Artists
	bankzy = { Name = "Bankzy", Mult = 0.88, Weight = 36 },
	monay = { Name = "Monay", Mult = 1.00, Weight = 30 },
	pickasso = { Name = "Pickasso", Mult = 1.10, Weight = 24 },
	vangoh = { Name = "Van Goh", Mult = 1.20, Weight = 14 },

	-- Locations (penthouses, estates, islands)
	dubay = { Name = "Dubay", Mult = 0.95, Weight = 34 },
	manhatton = { Name = "Manhatton", Mult = 1.00, Weight = 30 },
	londun = { Name = "Londun", Mult = 1.02, Weight = 26 },
	monako = { Name = "Monako", Mult = 1.18, Weight = 14 },
	aspenn = { Name = "Aspenn", Mult = 0.94, Weight = 30 },
	beverlyhilts = { Name = "Beverly Hilts", Mult = 1.05, Weight = 28 },
	belaire = { Name = "Bel-Aire", Mult = 1.12, Weight = 18 },
	carribbean = { Name = "Carribbean", Mult = 0.92, Weight = 36 },
	maldeeves = { Name = "Maldeeves", Mult = 1.10, Weight = 22 },
	boraborah = { Name = "Bora Borah", Mult = 1.18, Weight = 14 },
}

-- Houses that only appear on specific products (one brand per item), so their multiplier is
-- neutral: the item's Value is its price.
local SINGLE_PRODUCT_HOUSES: { [string]: string } = {
	-- Streetwear & sneakers
	nikey = "Nikey",
	yeezus = "Yeezus",
	newbalanse = "New Balanse",
	monke = "A Bathing Monke",
	stussie = "Stussie",
	palase = "Palase",
	fearofgawd = "Fear of Gawd",
	chromeheartz = "Chrome Heartz",
	-- Fragrance
	kurkjin = "Maison Kurkjin",
	lelabbo = "Le Labbo",
	clivekristen = "Clive Kristen",
	-- Tech
	sonee = "Sonee",
	nintendough = "Nintendough",
	beets = "Beets",
	bowse = "Bowse",
	leeca = "Leeca",
	hasselbladd = "Hasselbladd",
	djay = "DJay",
	rigforge = "RigForge",
	-- Watches
	casioh = "Casioh",
	seeko = "Seeko",
	grandseeko = "Grand Seeko",
	tudr = "Tudr",
	hublo = "Hublo",
	vasheron = "Vasheron Konstantin",
	jakob = "Jakob & Ko",
	-- Bags & jewellery
	fendy = "Fendy",
	yslorent = "Yves St Lorent",
	celeen = "Celeen",
	goyardd = "Goyardd",
	bottega = "Bottega Venetta",
	iceboxco = "Ice Box Co.",
	graaf = "Graaf",
	faberje = "Fabergé House",
	-- Drinks
	patrone = "Patrone",
	hennesy = "Hennesy",
	claseazool = "Clase Azool",
	macallen = "Macallen",
	louie13 = "Louie XIII",
	romanay = "Domaine Romanay",
	-- Collectibles
	pokemann = "Pocket Monsterz",
	topz = "Topz",
	leggo = "Leggo",
	kawz = "Kawz",
	medicomm = "Medicomm",
	funkoh = "Funkoh",
	marvelus = "Marvelus Comics",
	-- Cars & bikes
	teslo = "Teslo",
	bmv = "BMV",
	mercedez = "Mercedez",
	rangrover = "Rang Rover",
	maybock = "Maybock",
	awdi = "Awdi",
	vespah = "Vespah",
	ducatti = "Ducatti",
	harleydavidsun = "Harley-Davidsun",
	kawasakee = "Kawasakee",
	mvagoosta = "MV Agoosta",
	ecossee = "Ecossee",
	nimen = "Nimen Customs",
	vyruss = "Vyruss",
	specialised = "Specialised",
	-- Water & air
	seadu = "Sea-Du",
	wallee = "Wallee",
	tritton = "Tritton Subs",
	benningtun = "Benningtun",
	cirruss = "Cirruss",
	robinsun = "Robinsun",
	hondajett = "HondaJett",
	boing = "Boing",
	concordia = "Concordia",
	-- Art & property
	warhole = "Andee Warhole",
	basquiet = "Basquiet",
	davinchi = "Da Vinchi",
	koonz = "Koonz",
	hylands = "Hylands Estates",
	bordo = "Château Bordo",
	-- Robux-case houses
	velvetrope = "Velvet Rope",
	blackcard = "Obsidian Card Co.",
	highroller = "High Roller",
	popmartt = "Pop Martt",
	stanlee = "Stanlee",
	prym = "Prym",
	brainrotstudio = "Brainrot Studio",
	pixelapeclub = "Pixel Ape Club",
	fixx = "Fixx Chocolatier",
}

for id, name in SINGLE_PRODUCT_HOUSES do
	assert(Brands[id] == nil, `Brands: "{id}" is defined twice`)
	Brands[id] = { Name = name, Mult = 1, Weight = 1 }
end

return Brands
