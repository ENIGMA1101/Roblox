--[[
	Read-only view over the config files: lookups, validation and odds maths.

	Every case is turned into an odds table (Entries: item, chance, behind-the-gem) when the
	game starts. The server rolls from exactly that table and the case preview displays it,
	so the odds a player sees are the odds the server uses.
	No Roblox services are used, which keeps this testable outside Studio (tools/balance.py).
]]

local Config = script.Parent.Config
local RaritiesConfig = require(Config.Rarities)
local ItemsConfig = require(Config.Items)
local BrandsConfig = require(Config.Brands)
local MutationsConfig = require(Config.Mutations)
local CasesConfig = require(Config.Cases)
local GameConfig = require(Config.GameConfig)
local Monetization = require(Config.Monetization)

export type Rarity = RaritiesConfig.Rarity & { Order: number }
export type Brand = BrandsConfig.Brand
export type Mutation = MutationsConfig.Mutation

export type Item = {
	Id: string,
	Name: string,
	Rarity: string,
	Value: number,
	Category: string,
	Icon: string,
	Image: string,
	Brands: { string },
	Exclusive: boolean,
	Supply: number?,
	Weight: number,
}

-- Grail = an ultra-rare bragging-rights drop: fixed chance, never scaled by luck.
-- T = how strongly luck boosts this entry: 0 for the case's cheapest item, 1 for its most
-- valuable (log scale), so luck lifts rare items far more than common ones.
export type Entry = { Item: Item, P: number, Gem: boolean, Grail: boolean?, T: number }

export type Case = {
	Id: string,
	Name: string,
	Theme: string,
	Kind: string, -- "Mixed" | "Themed" | "Robux"
	Price: number, -- cash price; 0 for Robux cases
	Icon: string,
	Image: string,
	Color: Color3,
	Paid: { ProductId: number, Robux: number }?,
	Robux: { ProductId: number, Keys: number },
	GuaranteedMutation: boolean,
	Limited: boolean, -- every item has a capped supply
	Entries: { Entry }, -- base odds, most likely first
	BaseValue: number, -- average item value (before mutations) with no luck
}

-- A saved item. Short keys keep the DataStore record small.
export type Owned = {
	I: string, -- item id
	B: string, -- brand id
	M: string?, -- mutation id
	N: number?, -- serial number (numbered exclusives)
	T: number, -- obtained at (unix time)
	L: boolean?, -- locked (never auto-sold)
	S: boolean?, -- in showcase
}

export type Odds = { Id: string, P: number }

-- Item = item luck (every source multiplied together): raises the chance of rare items.
-- Mutation = mutation luck (only the Mutation Luck pass): divides every mutation's OneIn.
-- Boosted = a temporary boost (server luck / full luck bar) is included: higher luck ceiling.
export type Luck = { Item: number, Mutation: number, Boosted: boolean? }

local Catalog = {}

Catalog.NoLuck = table.freeze({ Item = 1, Mutation = 1 }) :: Luck

Catalog.Rarities = {} :: { Rarity }
Catalog.RarityById = {} :: { [string]: Rarity }
Catalog.Items = {} :: { Item }
Catalog.ItemById = {} :: { [string]: Item }
Catalog.ItemsByRarity = {} :: { [string]: { Item } }
Catalog.Categories = {} :: { string }
Catalog.Brands = BrandsConfig
Catalog.Mutations = MutationsConfig
Catalog.MutationById = {} :: { [string]: Mutation }
Catalog.Cases = {} :: { Case }
Catalog.CaseById = {} :: { [string]: Case }

-- Brands ----------------------------------------------------------------------------------------

-- Brand chances for an item (0..1), in the order the item lists them.
function Catalog.brandOdds(item: { Brands: { string } }): { Odds }
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

-- Average value of an item before mutations (its brand spread included).
function Catalog.itemValue(item: { Value: number, Brands: { string } }): number
	local value = 0
	for _, brand in Catalog.brandOdds(item) do
		value += brand.P * item.Value * BrandsConfig[brand.Id].Mult
	end
	return value
end

-- Rarities & items ------------------------------------------------------------------------------

for index, rarity in RaritiesConfig do
	local entry = table.clone(rarity) :: Rarity
	entry.Order = index
	table.insert(Catalog.Rarities, entry)
	Catalog.RarityById[entry.Id] = entry
	Catalog.ItemsByRarity[entry.Id] = {}
end

local function rarityForValue(value: number): string
	local chosen = Catalog.Rarities[1].Id
	for _, rarity in Catalog.Rarities do
		if rarity.MinValue and value >= rarity.MinValue then
			chosen = rarity.Id
		end
	end
	return chosen
end

local categorySeen = {}
for _, def in ItemsConfig do
	assert(Catalog.ItemById[def.Id] == nil, `Items: duplicate id "{def.Id}"`)
	assert(def.Value > 0, `Items: "{def.Id}" needs a positive Value`)
	assert(#def.Brands > 0, `Items: "{def.Id}" has no brands`)
	for _, brandId in def.Brands do
		assert(BrandsConfig[brandId], `Items: "{def.Id}" uses unknown brand "{brandId}"`)
	end
	local rarityId = def.Rarity or rarityForValue(Catalog.itemValue(def))
	assert(Catalog.RarityById[rarityId], `Items: "{def.Id}" has unknown rarity "{rarityId}"`)

	local item: Item = {
		Id = def.Id,
		Name = def.Name,
		Rarity = rarityId,
		Value = def.Value,
		Category = def.Category,
		Icon = def.Icon,
		Image = def.Image,
		Brands = def.Brands,
		Exclusive = def.Exclusive == true,
		Supply = def.Supply,
		Weight = def.Weight or def.Value ^ -0.6,
	}
	table.insert(Catalog.Items, item)
	Catalog.ItemById[item.Id] = item
	table.insert(Catalog.ItemsByRarity[rarityId], item)
	if not categorySeen[item.Category] then
		categorySeen[item.Category] = true
		table.insert(Catalog.Categories, item.Category)
	end
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

-- Mutations -------------------------------------------------------------------------------------

function Catalog.mutationChance(mutation: Mutation, mutationLuck: number?): number
	return math.min(1, math.max(mutationLuck or 1, 1) / mutation.OneIn)
end

--[[
	Mutations rarest first, with their chance at this luck. Each chance is luck / OneIn. Once
	those add up past 1 (very high luck), or with guaranteed = true, they're rescaled to add up
	to exactly 1: every item mutates and the mutations keep their relative odds, so luck can
	never make a Crown Jewel as common as a Polished.
]]
function Catalog.mutationOdds(mutationLuck: number?, guaranteed: boolean?): { Odds }
	local luck = math.max(mutationLuck or 1, 1)
	local odds = {}
	for _, mutation in Catalog.Mutations do
		table.insert(odds, { Id = mutation.Id, P = luck / mutation.OneIn })
	end
	table.sort(odds, function(a, b)
		return a.P < b.P
	end)
	local sum = 0
	for _, entry in odds do
		sum += entry.P
	end
	if sum > 1 or guaranteed then
		for _, entry in odds do
			entry.P /= sum
		end
	end
	return odds
end

-- Expected mutation multiplier (>= 1).
function Catalog.expectedMutationMult(mutationLuck: number?, guaranteed: boolean?): number
	local expected = 1
	for _, entry in Catalog.mutationOdds(mutationLuck, guaranteed) do
		expected += entry.P * (Catalog.MutationById[entry.Id].Mult - 1)
	end
	return expected
end

-- Case odds tables ------------------------------------------------------------------------------

local ThemedConfig = GameConfig.ThemedCases

local function defaultRTP(price: number): number
	local rtp = ThemedConfig.RTP
	return math.clamp(rtp.Base - rtp.Slope * math.log10(math.max(price, 1) / 1000), rtp.Min, rtp.Max)
end

local function resolvePool(caseId: string, pool: any): { Item }
	local items = {}
	if pool.Items then
		for _, id in pool.Items do
			local item = Catalog.ItemById[id]
			assert(item, `Cases: "{caseId}" lists unknown item "{id}"`)
			table.insert(items, item)
		end
		return items
	end
	local categories = if type(pool.Category) == "string" then { pool.Category } else pool.Category
	for _, item in Catalog.Items do
		local ok = not item.Exclusive
		if ok and categories then
			ok = table.find(categories, item.Category) ~= nil
		end
		if ok and pool.Brand then
			ok = #item.Brands == 1 and item.Brands[1] == pool.Brand
		end
		if ok and pool.MinValue then
			ok = item.Value >= pool.MinValue
		end
		if ok and pool.MaxValue then
			ok = item.Value <= pool.MaxValue
		end
		if ok then
			table.insert(items, item)
		end
	end
	return items
end

-- Chances proportional to value ^ -k, with k solved so the average pull equals target.
local function solveChances(caseId: string, items: { Item }, target: number): { number }
	local values = {}
	local low, high = math.huge, 0
	for index, item in items do
		values[index] = Catalog.itemValue(item)
		low = math.min(low, values[index])
		high = math.max(high, values[index])
	end
	assert(
		target > low * 1.0001 and target < high * 0.9999,
		`Cases: "{caseId}" can't average {math.floor(target)}: its items range {math.floor(low)} - {math.floor(high)}. `
			.. "Change its Price, RTP or Pool."
	)
	local logLow = math.log(low)
	local function weights(k: number): ({ number }, number)
		local list, sum, ev = {}, 0, 0
		for index, value in values do
			local w = math.exp(-k * (math.log(value) - logLow))
			list[index] = w
			sum += w
			ev += w * value
		end
		return list, ev / sum
	end
	local lo, hi = -4, 12
	for _ = 1, 80 do
		local mid = (lo + hi) / 2
		local _, ev = weights(mid)
		if ev > target then
			lo = mid
		else
			hi = mid
		end
	end
	local list = weights((lo + hi) / 2)
	local sum = 0
	for _, w in list do
		sum += w
	end
	for index, w in list do
		list[index] = w / sum
	end
	return list
end

local function sortEntries(entries: { Entry })
	table.sort(entries, function(a, b)
		if a.P ~= b.P then
			return a.P > b.P
		end
		return a.Item.Value < b.Item.Value
	end)
end

local function buildCase(def: any): Case
	local kind = if def.Paid then "Robux" elseif def.Odds then "Mixed" else "Themed"
	local entries: { Entry } = {}

	if def.Odds then
		local gems = {}
		for _, rarityId in def.Gem or {} do
			gems[rarityId] = true
		end
		local total = 0
		for rarityId, percent in def.Odds do
			assert(Catalog.RarityById[rarityId], `Cases: "{def.Id}" has odds for unknown rarity "{rarityId}"`)
			assert(percent >= 0, `Cases: "{def.Id}" has negative odds for "{rarityId}"`)
			total += percent
			if percent > 0 then
				local pool = {}
				local weightSum = 0
				for _, item in Catalog.ItemsByRarity[rarityId] do
					if not item.Exclusive then
						table.insert(pool, item)
						weightSum += item.Weight
					end
				end
				assert(#pool > 0, `Cases: "{def.Id}" can roll "{rarityId}" but no items have it`)
				for _, item in pool do
					table.insert(entries, {
						Item = item,
						P = percent / 100 * item.Weight / weightSum,
						Gem = gems[rarityId] == true,
						T = 0,
					})
				end
			end
		end
		assert(math.abs(total - 100) < 1e-6, `Cases: "{def.Id}" odds add up to {total}, not 100`)
		for rarityId in gems do
			assert((def.Odds[rarityId] or 0) > 0, `Cases: "{def.Id}" lists gem rarity "{rarityId}" with no odds`)
		end
	else
		assert(def.Pool, `Cases: "{def.Id}" needs Odds (mixed) or a Pool (themed / Robux)`)
		local items = resolvePool(def.Id, def.Pool)
		assert(#items >= 2, `Cases: "{def.Id}" pool has {#items} items; it needs at least 2`)

		local chances: { number }
		if def.Weights == "supply" then
			local total = 0
			for _, item in items do
				assert(item.Supply, `Cases: "{def.Id}" uses supply weights but "{item.Id}" has no Supply`)
				total += item.Supply :: number
			end
			chances = {}
			for index, item in items do
				chances[index] = (item.Supply :: number) / total
			end
		else
			local target = def.TargetValue
			if not target then
				assert(def.Price and def.Price > 0, `Cases: "{def.Id}" needs a Price or TargetValue`)
				target = def.Price * (def.RTP or defaultRTP(def.Price))
			end
			-- Grails count towards the return; the regular pool makes up the rest.
			local grailSum, grailEv = 0, 0
			for _, grail in def.Grails or {} do
				local item = Catalog.ItemById[grail[1]]
				if item then
					grailSum += 1 / grail[2]
					grailEv += Catalog.itemValue(item) / grail[2]
				end
			end
			target = (target - grailEv) / (1 - grailSum)
			chances = solveChances(def.Id, items, target)
		end

		local expected = 0
		for index, item in items do
			expected += chances[index] * Catalog.itemValue(item)
		end
		local anyGem = false
		for index, item in items do
			local gem = Catalog.itemValue(item) >= expected * ThemedConfig.GemMultiple
			anyGem = anyGem or gem
			table.insert(entries, { Item = item, P = chances[index], Gem = gem, T = 0 })
		end
		if not anyGem then
			local best = entries[1]
			for _, entry in entries do
				if entry.Item.Value > best.Item.Value then
					best = entry
				end
			end
			if Catalog.itemValue(best.Item) >= expected * ThemedConfig.FallbackGemMultiple then
				best.Gem = true
			end
		end
	end

	-- Grails: fixed ultra-rare chances layered on top. They sit behind the gem, and the
	-- regular odds shrink to make room.
	local grailSum = 0
	local grails: { Entry } = {}
	for _, grail in def.Grails or {} do
		local item = Catalog.ItemById[grail[1]]
		assert(item, `Cases: "{def.Id}" lists unknown grail "{grail[1]}"`)
		assert(item.Exclusive and not item.Supply, `Cases: grail "{item.Id}" must be an exclusive without Supply`)
		assert(grail[2] >= 1000, `Cases: grail "{item.Id}" in "{def.Id}" is too common`)
		grailSum += 1 / grail[2]
		table.insert(grails, { Item = item, P = 1 / grail[2], Gem = true, Grail = true, T = 0 })
	end
	assert(grailSum < 0.01, `Cases: "{def.Id}" grails add up to more than 1%`)
	for _, entry in entries do
		entry.P *= 1 - grailSum
	end
	sortEntries(entries)
	for _, entry in grails do
		table.insert(entries, entry)
	end
	local limited = #entries > 0
	for _, entry in entries do
		limited = limited and entry.Item.Supply ~= nil
	end
	if def.Paid then
		for _, entry in entries do
			assert(entry.Item.Exclusive, `Cases: Robux case "{def.Id}" contains non-exclusive "{entry.Item.Id}"`)
		end
	end

	-- Luck exponent per regular entry, and the no-luck average value.
	local low, high, regular, baseValue = math.huge, 0, 0, 0
	for _, entry in entries do
		if not entry.Grail then
			local value = Catalog.itemValue(entry.Item)
			low = math.min(low, value)
			high = math.max(high, value)
			regular += entry.P
			baseValue += entry.P * value
		end
	end
	for _, entry in entries do
		if not entry.Grail and high > low then
			entry.T = math.log(Catalog.itemValue(entry.Item) / low) / math.log(high / low)
		end
	end

	return {
		Id = def.Id,
		Name = def.Name,
		Theme = def.Theme or kind,
		Kind = kind,
		Price = if def.Paid then 0 else def.Price,
		Icon = def.Icon,
		Image = def.Image or "",
		Color = def.Color,
		Paid = def.Paid,
		Robux = def.Robux or { ProductId = 0, Keys = 1 },
		GuaranteedMutation = def.GuaranteedMutation == true,
		Limited = limited,
		Entries = entries,
		BaseValue = baseValue / regular,
	}
end

local KIND_ORDER = { Mixed = 1, Themed = 2, Robux = 3 }

for _, def in CasesConfig do
	assert(Catalog.CaseById[def.Id] == nil, `Cases: duplicate id "{def.Id}"`)
	local case = buildCase(def)
	Catalog.CaseById[case.Id] = case
	table.insert(Catalog.Cases, case)
end

table.sort(Catalog.Cases, function(a, b)
	if a.Kind ~= b.Kind then
		return KIND_ORDER[a.Kind] < KIND_ORDER[b.Kind]
	end
	local pa = if a.Paid then a.Paid.Robux else a.Price
	local pb = if b.Paid then b.Paid.Robux else b.Price
	return pa < pb
end)

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

-- Showcase cash per second for one item of this value (before passes).
function Catalog.incomeOf(value: number): number
	local showcase = GameConfig.Showcase
	return showcase.IncomeRate * math.max(value, 0) ^ showcase.IncomeExponent
end

-- Luck --------------------------------------------------------------------------------------

-- Item luck from luck upgrades alone (multiplies by LuckUpgrades.PerLevel each level).
function Catalog.upgradeLuck(level: number): number
	return GameConfig.LuckUpgrades.PerLevel ^ math.max(level, 0)
end

--[[
	Permanent luck. Item luck = upgrades x rebirths x Luck pass x personal Robux stack (they
	multiply). Mutation luck comes only from the Mutation Luck pass; item luck never touches
	mutations.
]]
function Catalog.luckFor(
	level: number,
	hasPass: boolean,
	personalBuys: number?,
	hasMutationPass: boolean?,
	rebirths: number?
): Luck
	local config = GameConfig.Luck
	return {
		Item = Catalog.upgradeLuck(level) * Catalog.rebirthLuck(rebirths or 0) * (if hasPass
			then config.PassMult
			else 1) * Catalog.personalLuckMult(personalBuys or 0),
		Mutation = if hasMutationPass then config.MutationPassMult else 1,
	}
end

-- Adds a temporary multiplier (server luck, luck bar) on top of permanent item luck.
function Catalog.boostLuck(luck: Luck, mult: number): Luck
	if mult <= 1 then
		return luck
	end
	return { Item = luck.Item * mult, Mutation = luck.Mutation, Boosted = true }
end

-- Price to go from `level` to `level + 1`. Never runs out; grows exponentially.
function Catalog.luckUpgradePrice(level: number): number
	local upgrades = GameConfig.LuckUpgrades
	return math.floor(upgrades.BasePrice * upgrades.PriceGrowth ^ level + 0.5)
end

-- Personal luck stack: 1x with no purchases, then 1.5x, 2x, 2.5x, ...
function Catalog.personalLuckMult(buys: number): number
	return 1 + math.max(buys, 0) * Monetization.PersonalLuck.PerPurchase
end

-- Rebirth ---------------------------------------------------------------------------------------

-- Permanent item luck from rebirths (compounding).
function Catalog.rebirthLuck(rebirths: number): number
	return GameConfig.Rebirth.LuckMult ^ math.max(rebirths, 0)
end

-- Multiplier on sell value and showcase income from rebirths.
function Catalog.rebirthSellMult(rebirths: number): number
	return 1 + GameConfig.Rebirth.SellBonus * math.max(rebirths, 0)
end

-- Cash needed in hand for the next rebirth after `rebirths` rebirths.
function Catalog.rebirthCost(rebirths: number): number
	local config = GameConfig.Rebirth
	local n = math.max(rebirths, 0)
	-- The growth rate itself climbs by CostRamp each rebirth, so later rebirths stay a chase
	-- even as rebirth bonuses stack up.
	return math.floor(config.BaseCost * config.CostGrowth ^ n * config.CostRamp ^ (n * (n - 1) / 2) + 0.5)
end

-- Items that survive a rebirth: exclusives (Robux case items and grails).
function Catalog.keptOnRebirth(owned: { I: string }): boolean
	local item = Catalog.ItemById[owned.I]
	return item ~= nil and item.Exclusive
end

-- Robux price shown for the next personal luck purchase (after `buys` purchases), or nil if
-- every step has been bought.
function Catalog.personalLuckPrice(buys: number): number?
	local config = Monetization.PersonalLuck
	if buys >= #config.ProductIds then
		return nil
	end
	return math.floor(config.BasePrice * config.PriceGrowth ^ buys + 0.5)
end

-- Odds ----------------------------------------------------------------------------------------

--[[
	How luck works on a case. Every regular entry's chance is multiplied by luck ^ T, where T
	runs from 0 (the case's cheapest item) to 1 (its most valuable), then everything is
	rescaled. So 100x luck makes the top item ~100x more likely and barely touches commons.

	Luck applies in full until it has raised the case's average value by FullGain (a fraction
	of the case price, or of its normal value for Robux cases). Past that, gains are
	logarithmic: g becomes FullGain + Softness * ln(1 + (g - FullGain) / Softness). More luck
	always helps, it just slows down at extreme stacks so no case turns into an infinite money
	printer. Temporary boosts use the Boost settings. effectiveLuck() is the plain multiplier
	that gives that gain.
]]
local function averageValue(case: Case, luck: number): number
	local sum, total = 0, 0
	for _, entry in case.Entries do
		if not entry.Grail then
			local weight = entry.P * luck ^ entry.T
			sum += weight
			total += weight * Catalog.itemValue(entry.Item)
		end
	end
	return total / sum
end

local luckCache: { [string]: { [string]: number } } = {}
local luckCacheSize: { [string]: number } = {}

function Catalog.effectiveLuck(case: Case, itemLuck: number?, boosted: boolean?): number
	local luck = math.max(itemLuck or 1, 1)
	if luck <= 1.000001 then
		return 1
	end
	local key = string.format("%.5f%s", math.log(luck), if boosted then "b" else "")
	local cache = luckCache[case.Id]
	if not cache then
		cache = {}
		luckCache[case.Id] = cache
	end
	local cached = cache[key]
	if cached then
		return cached
	end

	local config = GameConfig.Luck
	local free = if boosted then config.BoostFullGain else config.FullGain
	local soft = if boosted then config.BoostSoftness else config.Softness
	local reference = if case.Price > 0 then case.Price else case.BaseValue
	local function gain(l: number): number
		return (averageValue(case, l) - case.BaseValue) / reference
	end
	local raw = gain(luck)
	local result = luck
	if raw > free then
		local target = free + soft * math.log(1 + (raw - free) / soft)
		local lo, hi = 0, math.log(luck)
		for _ = 1, 40 do
			local mid = (lo + hi) / 2
			if gain(math.exp(mid)) < target then
				lo = mid
			else
				hi = mid
			end
		end
		result = math.exp((lo + hi) / 2)
	end

	local size = (luckCacheSize[case.Id] or 0) + 1
	if size > 512 then
		table.clear(cache)
		size = 1
	end
	luckCacheSize[case.Id] = size
	cache[key] = result
	return result
end

-- A case's odds at this item luck, with sold-out items removed. Grails keep their fixed chance.
function Catalog.caseOdds(case: Case, itemLuck: number?, soldOut: { [string]: boolean }?, boosted: boolean?): { Entry }
	local luck = Catalog.effectiveLuck(case, itemLuck, boosted)
	local entries: { Entry } = {}
	local grailSum, total = 0, 0
	for _, entry in case.Entries do
		if not (soldOut and soldOut[entry.Item.Id]) then
			local copy = { Item = entry.Item, P = entry.P, Gem = entry.Gem, Grail = entry.Grail, T = entry.T }
			if entry.Grail then
				grailSum += entry.P
			else
				copy.P = entry.P * luck ^ entry.T
				total += copy.P
			end
			table.insert(entries, copy)
		end
	end
	if total <= 0 then
		return {}
	end
	local scale = (1 - grailSum) / total
	for _, entry in entries do
		if not entry.Grail then
			entry.P *= scale
		end
	end
	return entries
end

-- Chance per rarity (0..1) for display, lowest tier first.
function Catalog.rarityOdds(case: Case, itemLuck: number?, boosted: boolean?): { Odds }
	local byRarity: { [string]: number } = {}
	for _, entry in Catalog.caseOdds(case, itemLuck, nil, boosted) do
		byRarity[entry.Item.Rarity] = (byRarity[entry.Item.Rarity] or 0) + entry.P
	end
	local odds = {}
	for _, rarity in Catalog.Rarities do
		if byRarity[rarity.Id] then
			table.insert(odds, { Id = rarity.Id, P = byRarity[rarity.Id] })
		end
	end
	return odds
end

-- Does any item of this rarity hide behind the gem in this case?
function Catalog.isGem(case: Case, rarityId: string): boolean
	for _, entry in case.Entries do
		if entry.Gem and entry.Item.Rarity == rarityId then
			return true
		end
	end
	return false
end

-- Total chance (0..1) that a case lands on the gem at this item luck.
function Catalog.gemChance(case: Case, itemLuck: number?, boosted: boolean?): number
	local chance = 0
	for _, entry in Catalog.caseOdds(case, itemLuck, nil, boosted) do
		if entry.Gem then
			chance += entry.P
		end
	end
	return chance
end

-- Expected value of one open, including mutations.
function Catalog.expectedValue(case: Case, luck: Luck?): number
	local boost = luck or Catalog.NoLuck
	local expected = 0
	for _, entry in Catalog.caseOdds(case, boost.Item, nil, boost.Boosted) do
		expected += entry.P * Catalog.itemValue(entry.Item)
	end
	return expected * Catalog.expectedMutationMult(boost.Mutation, case.GuaranteedMutation)
end

-- Return-to-player of a cash case (expected value / price).
function Catalog.rtp(case: Case, luck: Luck?): number?
	if case.Price <= 0 then
		return nil
	end
	return Catalog.expectedValue(case, luck) / case.Price
end

return Catalog
