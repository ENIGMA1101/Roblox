--[[
	All randomness. The server uses roll() for real results; the client only uses
	filler() to decorate the reel around the result the server already decided.

	rng is anything with :NextNumber() returning [0, 1) - a Roblox Random object.
]]

local Catalog = require(script.Parent.Catalog)

export type Rng = { NextNumber: (self: any) -> number }

export type Roll = {
	I: string,
	B: string,
	M: string?,
	Rarity: string,
	Gem: boolean,
}

export type Filler = {
	Gem: boolean,
	I: string?,
	B: string?,
}

local Roller = {}

local function pick(odds: { Catalog.Odds }, rng: Rng): string
	local total = 0
	for _, entry in odds do
		total += entry.P
	end
	local r = rng:NextNumber() * total
	for _, entry in odds do
		r -= entry.P
		if r < 0 then
			return entry.Id
		end
	end
	return odds[#odds].Id
end

function Roller.rarity(case: Catalog.Case, gemLuck: number, rng: Rng): string
	return pick(Catalog.rarityOdds(case, gemLuck), rng)
end

function Roller.item(rarityId: string, rng: Rng): Catalog.Item
	local items = Catalog.ItemsByRarity[rarityId]
	local odds = table.create(#items)
	for _, item in items do
		table.insert(odds, { Id = item.Id, P = item.Weight })
	end
	return Catalog.ItemById[pick(odds, rng)]
end

function Roller.brand(item: Catalog.Item, rng: Rng): string
	return pick(Catalog.brandOdds(item), rng)
end

-- Each mutation keeps exactly its own chance: one draw, walked rarest-first.
function Roller.mutation(mutationLuck: number, rng: Rng): string?
	local r = rng:NextNumber()
	for _, entry in Catalog.mutationOdds(mutationLuck) do
		r -= entry.P
		if r < 0 then
			return entry.Id
		end
	end
	return nil
end

function Roller.roll(case: Catalog.Case, luck: Catalog.Luck, rng: Rng): Roll
	local rarityId = Roller.rarity(case, luck.Gem, rng)
	local item = Roller.item(rarityId, rng)
	return {
		I = item.Id,
		B = Roller.brand(item, rng),
		M = Roller.mutation(luck.Mutation, rng),
		Rarity = rarityId,
		Gem = Catalog.isGem(case, rarityId),
	}
end

-- Cosmetic reel entry. Uses the case's real odds (no luck), so what scrolls past is a fair
-- picture of the case. gemPhase = the re-spin after a gem, which only shows gem rarities.
function Roller.filler(case: Catalog.Case, rng: Rng, gemPhase: boolean): Filler
	local odds = Catalog.rarityOdds(case, 1)
	if gemPhase then
		local gemOdds = {}
		for _, entry in odds do
			if Catalog.isGem(case, entry.Id) then
				table.insert(gemOdds, entry)
			end
		end
		odds = gemOdds
	end

	local rarityId = pick(odds, rng)
	if not gemPhase and Catalog.isGem(case, rarityId) then
		return { Gem = true }
	end
	local item = Roller.item(rarityId, rng)
	return { Gem = false, I = item.Id, B = Roller.brand(item, rng) }
end

return Roller
