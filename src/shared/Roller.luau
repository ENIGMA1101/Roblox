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
	N: number?, -- serial, filled in by the server for numbered items
	Rarity: string,
	Gem: boolean,
}

export type Filler = {
	Gem: boolean,
	I: string?,
	B: string?,
}

-- Developer override (Studio / admins only): Gem = "random" picks a gem item with its normal
-- relative odds, "top" the case's most valuable one; Mutation forces that mutation id.
export type Force = { Gem: string?, Mutation: string? }

local Roller = {}

local function pick<T>(list: { T }, weightOf: (T) -> number, rng: Rng): T
	local total = 0
	for _, entry in list do
		total += weightOf(entry)
	end
	local r = rng:NextNumber() * total
	for _, entry in list do
		r -= weightOf(entry)
		if r < 0 then
			return entry
		end
	end
	return list[#list]
end

local function entryWeight(entry: Catalog.Entry): number
	return entry.P
end

local function oddsWeight(entry: Catalog.Odds): number
	return entry.P
end

function Roller.brand(item: Catalog.Item, rng: Rng): string
	return pick(Catalog.brandOdds(item), oddsWeight, rng).Id
end

-- Each mutation keeps exactly its own chance: one draw, walked rarest-first.
function Roller.mutation(mutationLuck: number, rng: Rng, guaranteed: boolean?): string?
	local r = rng:NextNumber()
	local odds = Catalog.mutationOdds(mutationLuck, guaranteed)
	for _, entry in odds do
		r -= entry.P
		if r < 0 then
			return entry.Id
		end
	end
	return if guaranteed then odds[#odds].Id else nil
end

-- Returns nil only when every item in the case is sold out.
function Roller.roll(
	case: Catalog.Case,
	luck: Catalog.Luck,
	rng: Rng,
	force: Force?,
	soldOut: { [string]: boolean }?
): Roll?
	local entries = Catalog.caseOdds(case, luck.Gem, soldOut, luck.Boosted)
	if #entries == 0 then
		return nil
	end

	local chosen: Catalog.Entry
	if force and force.Gem then
		local gems = {}
		for _, entry in entries do
			if entry.Gem then
				table.insert(gems, entry)
			end
		end
		if #gems == 0 then
			gems = entries
		end
		if force.Gem == "top" then
			chosen = gems[1]
			for _, entry in gems do
				if entry.Item.Value > chosen.Item.Value then
					chosen = entry
				end
			end
		else
			chosen = pick(gems, entryWeight, rng)
		end
	else
		chosen = pick(entries, entryWeight, rng)
	end

	local mutation = if force
			and force.Mutation
			and Catalog.MutationById[force.Mutation]
		then force.Mutation
		else Roller.mutation(luck.Mutation, rng, case.GuaranteedMutation)
	return {
		I = chosen.Item.Id,
		B = Roller.brand(chosen.Item, rng),
		M = mutation,
		Rarity = chosen.Item.Rarity,
		Gem = chosen.Gem,
	}
end

-- Cosmetic reel entry. Uses the case's real odds (no luck), so what scrolls past is a fair
-- picture of the case. gemPhase = the re-spin after a gem, which only shows gem items.
function Roller.filler(case: Catalog.Case, rng: Rng, gemPhase: boolean): Filler
	local entries = case.Entries
	if gemPhase then
		local gems = {}
		for _, entry in entries do
			if entry.Gem then
				table.insert(gems, entry)
			end
		end
		if #gems > 0 then
			entries = gems
		end
	end
	local entry = pick(entries, entryWeight, rng)
	if entry.Gem and not gemPhase then
		return { Gem = true }
	end
	return { Gem = false, I = entry.Item.Id, B = Roller.brand(entry.Item, rng) }
end

return Roller
