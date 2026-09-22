--[[
	Read-only view over the config files: lookups, validation and odds maths.

	Everything that shows or uses a probability goes through here, so the odds the
	player sees in the case preview are exactly the odds the server rolls with.
	No Roblox services are used, which keeps this testable outside Studio (tools/balance.py).
]]

local Config = script.Parent.Config
local RaritiesConfig = require(Config.Rarities)
local ItemsConfig = require(Config.Items)
local BrandsConfig = require(Config.Brands)
local MutationsConfig = require(Config.Mutations)
local CasesConfig = require(Config.Cases)
local GameConfig = require(Config.GameConfig)

export type Rarity = RaritiesConfig.Rarity & { Order: number }
export type Item = ItemsConfig.Item
export type Brand = BrandsConfig.Brand
export type Mutation = MutationsConfig.Mutation
export type Case = CasesConfig.Case

-- A saved item. Short keys keep the DataStore record small.
export type Owned = {
	I: string, -- item id
	B: string, -- brand id
	M: string?, -- mutation id
	T: number, -- obtained at (unix time)
	L: boolean?, -- locked (never auto-sold)
	S: boolean?, -- in showcase
}

export type Odds = { Id: string, P: number }

-- Gem multiplies the case's gem-rarity odds, Mutation divides every mutation's OneIn.
export type Luck = { Gem: number, Mutation: number }

local Catalog = {}

Catalog.NoLuck = table.freeze({ Gem = 1, Mutation = 1 }) :: Luck

Catalog.Rarities = {} :: { Rarity }
Catalog.RarityById = {} :: { [string]: Rarity }
Catalog.Items = ItemsConfig
Catalog.ItemById = {} :: { [string]: Item }
Catalog.ItemsByRarity = {} :: { [string]: { Item } }
Catalog.Brands = BrandsConfig
Catalog.Mutations = MutationsConfig
Catalog.MutationById = {} :: { [string]: Mutation }
Catalog.Cases = table.clone(CasesConfig)
Catalog.CaseById = {} :: { [string]: Case }

local gemSets: { [string]: { [string]: boolean } } = {}

for index, rarity in RaritiesConfig do
	local entry = table.clone(rarity) :: Rarity
	entry.Order = index
	table.insert(Catalog.Rarities, entry)
	Catalog.RarityById[entry.Id] = entry
	Catalog.ItemsByRarity[entry.Id] = {}
end

for _, item in ItemsConfig do
	assert(Catalog.ItemById[item.Id] == nil, `Items: duplicate id "{item.Id}"`)
	assert(Catalog.RarityById[item.Rarity], `Items: "{item.Id}" has unknown rarity "{item.Rarity}"`)
	assert(item.Value > 0 and item.Weight > 0, `Items: "{item.Id}" needs a positive Value and Weight`)
	assert(#item.Brands > 0, `Items: "{item.Id}" has no brands`)
	for _, brandId in item.Brands do
		assert(BrandsConfig[brandId], `Items: "{item.Id}" uses unknown brand "{brandId}"`)
	end
	Catalog.ItemById[item.Id] = item
	table.insert(Catalog.ItemsByRarity[item.Rarity], item)
end

for _, list in Catalog.ItemsByRarity do
	table.sort(list, function(a, b)
		return a.Value < b.Value
	end)
end

for _, mutation in MutationsConfig do
	assert(Catalog.MutationById[mutation.Id] == nil, `Mutations: duplicate id "{mutation.Id}"`)
	assert(mutation.OneIn >= 1 and mutation.Mult > 0, `Mutations: "{mutation.Id}" has a bad OneIn or Mult`)
	Catalog.MutationById[mutation.Id] = mutation
end

table.sort(Catalog.Cases, function(a, b)
	return a.Price < b.Price
end)

for _, case in Catalog.Cases do
	assert(Catalog.CaseById[case.Id] == nil, `Cases: duplicate id "{case.Id}"`)
	Catalog.CaseById[case.Id] = case

	local total = 0
	for rarityId, percent in case.Odds do
		assert(Catalog.RarityById[rarityId], `Cases: "{case.Id}" has odds for unknown rarity "{rarityId}"`)
		assert(percent >= 0, `Cases: "{case.Id}" has negative odds for "{rarityId}"`)
		if percent > 0 then
			assert(
				#Catalog.ItemsByRarity[rarityId] > 0,
				`Cases: "{case.Id}" can roll "{rarityId}" but no items have it`
			)
		end
		total += percent
	end
	assert(math.abs(total - 100) < 1e-6, `Cases: "{case.Id}" odds add up to {total}, not 100`)

	local gems = {}
	for _, rarityId in case.Gem do
		assert((case.Odds[rarityId] or 0) > 0, `Cases: "{case.Id}" lists gem rarity "{rarityId}" with no odds`)
		gems[rarityId] = true
	end
	gemSets[case.Id] = gems
end

-- Values ------------------------------------------------------------------------------------

function Catalog.valueOf(owned: { I: string, B: string, M: string? }): number
	local item = Catalog.ItemById[owned.I]
	local brand = BrandsConfig[owned.B]
	if not item or not brand then
		return 0
	end
	local mutation = owned.M and Catalog.MutationById[owned.M]
	local mult = if mutation then mutation.Mult else 1
	return math.floor(item.Value * brand.Mult * mult + 0.5)
end

-- Showcase cash per second for one item of this value (before passes).
function Catalog.incomeOf(value: number): number
	local showcase = GameConfig.Showcase
	return showcase.IncomeRate * math.max(value, 0) ^ showcase.IncomeExponent
end

-- Lowest and highest value an item can have before mutations.
function Catalog.valueRange(item: Item): (number, number)
	local low, high = math.huge, 0
	for _, brandId in item.Brands do
		local value = math.floor(item.Value * BrandsConfig[brandId].Mult + 0.5)
		low = math.min(low, value)
		high = math.max(high, value)
	end
	return low, high
end

function Catalog.rarityOf(owned: { I: string }): Rarity?
	local item = Catalog.ItemById[owned.I]
	return item and Catalog.RarityById[item.Rarity]
end

-- Odds ----------------------------------------------------------------------------------------

function Catalog.isGem(case: Case, rarityId: string): boolean
	return gemSets[case.Id][rarityId] == true
end

-- Rarity probabilities (0..1) for a case, lowest tier first. gemLuck multiplies the gem
-- rarities and takes the extra from the most common non-gem tiers.
function Catalog.rarityOdds(case: Case, gemLuck: number?): { Odds }
	local boost = math.max(gemLuck or 1, 1)
	local odds: { Odds } = {}
	local extra = 0
	for _, rarity in Catalog.Rarities do
		local percent = case.Odds[rarity.Id] or 0
		if percent > 0 then
			local p = percent / 100
			if gemSets[case.Id][rarity.Id] and boost > 1 then
				local boosted = p * boost
				extra += boosted - p
				p = boosted
			end
			table.insert(odds, { Id = rarity.Id, P = p })
		end
	end

	for _, entry in odds do
		if extra <= 0 then
			break
		end
		if not gemSets[case.Id][entry.Id] then
			local take = math.min(entry.P, extra)
			entry.P -= take
			extra -= take
		end
	end

	-- Only possible with absurd luck values: renormalise so the table still sums to 1.
	if extra > 0 then
		local sum = 0
		for _, entry in odds do
			sum += entry.P
		end
		for _, entry in odds do
			entry.P /= sum
		end
	end
	return odds
end

-- Chance of each item inside its rarity (0..1).
function Catalog.itemShare(item: Item): number
	local total = 0
	for _, other in Catalog.ItemsByRarity[item.Rarity] do
		total += other.Weight
	end
	return item.Weight / total
end

-- Brand chances for an item (0..1), in the order the item lists them.
function Catalog.brandOdds(item: Item): { Odds }
	local total = 0
	for _, brandId in item.Brands do
		total += BrandsConfig[brandId].Weight
	end
	local odds = {}
	for _, brandId in item.Brands do
		table.insert(odds, { Id = brandId, P = BrandsConfig[brandId].Weight / total })
	end
	return odds
end

function Catalog.mutationChance(mutation: Mutation, mutationLuck: number?): number
	return math.min(1, math.max(mutationLuck or 1, 1) / mutation.OneIn)
end

-- Mutations rarest first, with their chance at this luck. Used by the roller and the preview.
function Catalog.mutationOdds(mutationLuck: number?): { Odds }
	local odds = {}
	for _, mutation in Catalog.Mutations do
		table.insert(odds, { Id = mutation.Id, P = Catalog.mutationChance(mutation, mutationLuck) })
	end
	table.sort(odds, function(a, b)
		return a.P < b.P
	end)
	local sum = 0
	for _, entry in odds do
		sum += entry.P
	end
	if sum > 1 then
		for _, entry in odds do
			entry.P /= sum
		end
	end
	return odds
end

-- Expected mutation multiplier (>= 1).
function Catalog.expectedMutationMult(mutationLuck: number?): number
	local expected = 1
	for _, entry in Catalog.mutationOdds(mutationLuck) do
		expected += entry.P * (Catalog.MutationById[entry.Id].Mult - 1)
	end
	return expected
end

-- Expected value of one item of this rarity, including brand spread but not mutations.
function Catalog.expectedRarityValue(rarityId: string): number
	local expected = 0
	for _, item in Catalog.ItemsByRarity[rarityId] do
		local itemValue = 0
		for _, brand in Catalog.brandOdds(item) do
			itemValue += brand.P * item.Value * BrandsConfig[brand.Id].Mult
		end
		expected += Catalog.itemShare(item) * itemValue
	end
	return expected
end

-- Expected value of one open, including mutations.
function Catalog.expectedValue(case: Case, luck: Luck?): number
	local boost = luck or Catalog.NoLuck
	local expected = 0
	for _, entry in Catalog.rarityOdds(case, boost.Gem) do
		expected += entry.P * Catalog.expectedRarityValue(entry.Id)
	end
	return expected * Catalog.expectedMutationMult(boost.Mutation)
end

return Catalog
