-- Appended to the bundle built by tools/balance.py. `Shared` is the fake ReplicatedStorage.Shared.

local Catalog = require(Shared.Catalog)
local Roller = require(Shared.Roller)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local args = { ... }
local QUICK = table.find(args, "--quick") ~= nil
local SKIP_CHECK = table.find(args, "--no-check") ~= nil
local BOTS = 15
local HOURS = 80

math.randomseed(20260922)
local rng = {
	NextNumber = function(_self)
		return math.random()
	end,
}

local function pad(text: string, width: number): string
	return text .. string.rep(" ", math.max(0, width - #text))
end

local function lpad(text: string, width: number): string
	return string.rep(" ", math.max(0, width - #text)) .. text
end

-- 1. Expected value per case ------------------------------------------------------------------

-- "Max luck" columns use a late-game reference: level 20 and 4 personal luck purchases (8x).
local REFERENCE_LEVEL = 20
local REFERENCE_PERSONAL = 4
local maxLuck = Catalog.luckFor(REFERENCE_LEVEL, false, REFERENCE_PERSONAL)
local maxLuckPass = Catalog.luckFor(REFERENCE_LEVEL, true, REFERENCE_PERSONAL)
local boosted = Catalog.boostLuck(maxLuckPass, 10 * GameConfig.LuckBar.Mult)
local passLuck = Catalog.luckFor(0, true, 0)

local function pct(value: number?): string
	return if value then string.format("%.1f%%", value * 100) else "-"
end

print("\n== Cases (exact maths) ==")
print(
	pad("case", 20)
		.. pad("kind", 8)
		.. lpad("items", 6)
		.. lpad("price", 9)
		.. lpad("EV", 9)
		.. lpad("RTP", 8)
		.. lpad("RTP pass", 10)
		.. lpad("max luck", 10)
		.. lpad("max+pass", 10)
		.. lpad("x100 boost", 11)
		.. lpad("gem", 14)
		.. lpad("gem EV", 8)
		.. lpad("top item", 11)
)
for _, case in Catalog.Cases do
	local ev = Catalog.expectedValue(case)
	local gemEv, top = 0, 0
	for _, entry in case.Entries do
		if entry.Gem then
			gemEv += entry.P * Catalog.itemValue(entry.Item)
		end
		top = math.max(top, entry.Item.Value)
	end
	gemEv *= Catalog.expectedMutationMult(1, case.GuaranteedMutation)
	local gem = Catalog.gemChance(case)
	print(
		pad(case.Name, 20)
			.. pad(case.Kind, 8)
			.. lpad(tostring(#case.Entries), 6)
			.. lpad(if case.Paid then "R$" .. case.Paid.Robux else Format.short(case.Price), 9)
			.. lpad(Format.short(ev), 9)
			.. lpad(pct(Catalog.rtp(case)), 8)
			.. lpad(pct(Catalog.rtp(case, passLuck)), 10)
			.. lpad(pct(Catalog.rtp(case, maxLuck)), 10)
			.. lpad(pct(Catalog.rtp(case, maxLuckPass)), 10)
			.. lpad(pct(Catalog.rtp(case, boosted)), 11)
			.. lpad(if gem > 0 then Format.oneIn(gem) else "no gem", 14)
			.. lpad(string.format("%.0f%%", gemEv / ev * 100), 8)
			.. lpad(Format.short(top), 11)
	)
end

local anyMutation = 0
for _, entry in Catalog.mutationOdds(1) do
	anyMutation += entry.P
end
print(
	string.format(
		"\nMutations: %s chance of any, expected multiplier %.4f (Mutation Luck pass: %.4f, guaranteed: %.4f)",
		Format.chance(anyMutation),
		Catalog.expectedMutationMult(1),
		Catalog.expectedMutationMult(GameConfig.Luck.MutationPassMult),
		Catalog.expectedMutationMult(1, true)
	)
)

print(
	string.format(
		"\nReference luck: level %d + %d personal buys = %s, with pass %s, x100 boost %s",
		REFERENCE_LEVEL,
		REFERENCE_PERSONAL,
		Format.mult(maxLuck.Item),
		Format.mult(maxLuckPass.Item),
		Format.mult(boosted.Item)
	)
)

print("\n== Luck curve: RTP (and top item chance) at total item luck; boosted = temporary boost ==")
local LUCKS = { 1, 2, 10, 100, 1000, 10000 }
local head = pad("case", 20)
for _, l in LUCKS do
	head ..= lpad(Format.mult(l), 20)
end
print(head .. lpad("x1000 boosted", 20))
for _, case in Catalog.Cases do
	local line = pad(case.Name, 20)
	local function cell(l: number, isBoost: boolean): string
		local top = 0
		local topValue = 0
		for _, entry in Catalog.caseOdds(case, l, nil, isBoost) do
			if not entry.Grail and entry.Item.Value > topValue then
				topValue = entry.Item.Value
				top = entry.P
			end
		end
		local luck = { Item = l, Mutation = 1, Boosted = isBoost }
		local value = if case.Price > 0
			then pct(Catalog.rtp(case, luck))
			else string.format("%.2fx", Catalog.expectedValue(case, luck) / Catalog.expectedValue(case))
		return lpad(`{value} ({Format.oneIn(top)})`, 20)
	end
	for _, l in LUCKS do
		line ..= cell(l, false)
	end
	print(line .. cell(1000, true))
end

print("\n== Items per rarity ==")
for _, rarity in Catalog.Rarities do
	print(pad(rarity.Name, 12) .. lpad(tostring(#Catalog.ItemsByRarity[rarity.Id]), 5))
end
print(pad("Total", 12) .. lpad(tostring(#Catalog.Items), 5))

if QUICK then
	return
end

-- 2. Roll check: the roller must agree with the maths -----------------------------------------

print("\n== Roll check (40k rolls per case) ==")
local ROLLS = 40000
for _, case in if SKIP_CHECK then {} else Catalog.Cases do
	local total, gems, mutated = 0, 0, 0
	for _ = 1, ROLLS do
		local roll = Roller.roll(case, Catalog.NoLuck, rng) :: Roller.Roll
		total += Catalog.valueOf(roll)
		if roll.Gem then
			gems += 1
		end
		if roll.M then
			mutated += 1
		end
	end
	local ev = Catalog.expectedValue(case)
	print(
		pad(case.Name, 20)
			.. string.format(
				"mean %s vs EV %s (%+.1f%%)   gems %d vs %.0f   mutated %.1f%%",
				lpad(Format.short(total / ROLLS), 7),
				lpad(Format.short(ev), 7),
				(total / ROLLS / ev - 1) * 100,
				gems,
				Catalog.gemChance(case) * ROLLS,
				mutated / ROLLS * 100
			)
	)
end

-- 3. Progression bots --------------------------------------------------------------------------
--[[
	A simple player: claims the free case whenever ready, opens the priciest case it can
	afford 3 of (else as many as it can of the priciest affordable one), keeps its best
	items in the showcase, sells everything else, and buys a showcase slot when it has
	twice the price, and a luck level when it has three times the price. No passes, no
	Robux, no offline time.
]]

local Spin = GameConfig.Spin
local Showcase = GameConfig.Showcase
local freeCase = Catalog.CaseById[GameConfig.FreeCase.CaseId]
local botCases = {}
for _, case in Catalog.Cases do
	if case.Kind == "Mixed" then
		table.insert(botCases, case)
	end
end
local maxOpen = GameConfig.MaxOpenBase

local function batchSeconds(count: number, gem: boolean): number
	local seconds = Spin.Duration + Spin.Stagger * (count - 1) + Spin.RevealTime + 1.5
	if gem then
		seconds += Spin.GemHold + Spin.GemSpinDuration
	end
	return seconds
end

local CHECKPOINTS = { 0.25, 0.5, 1, 2, 4, 8, 16, 32, 48, 80 }

local function runBot()
	local cash = GameConfig.StartingCash
	local slots = Showcase.BaseSlots
	local luckLevel = 0
	local shown: { number } = {} -- showcased values, ascending
	local income = Showcase.BaseIncome
	local t = 0
	local freeReadyAt = 0
	local firstOpen: { [string]: number } = {}
	local snapshots = {}
	local nextCheckpoint = 1

	local function recalc()
		income = Showcase.BaseIncome
		for _, v in shown do
			income += Catalog.incomeOf(v)
		end
	end

	local function receive(value: number)
		if #shown < slots then
			table.insert(shown, value)
		elseif value > shown[1] then
			cash += shown[1]
			shown[1] = value
		else
			cash += value
			return
		end
		table.sort(shown)
		recalc()
	end

	local function advance(dt: number)
		t += dt
		cash += income * dt
		while CHECKPOINTS[nextCheckpoint] and t >= CHECKPOINTS[nextCheckpoint] * 3600 do
			local total = 0
			for _, v in shown do
				total += v
			end
			snapshots[nextCheckpoint] =
				{ cash = cash, income = income, showcase = total, slots = slots, luck = luckLevel }
			nextCheckpoint += 1
		end
	end

	while t < HOURS * 3600 do
		if t >= freeReadyAt then
			local roll = Roller.roll(freeCase, Catalog.luckFor(luckLevel, false, 0), rng) :: Roller.Roll
			receive(Catalog.valueOf(roll))
			freeReadyAt = t + GameConfig.FreeCase.Cooldown
			advance(batchSeconds(1, roll.Gem))
		end

		local extra = Showcase.SlotPrices[slots - Showcase.BaseSlots + 1]
		local luckPrice = Catalog.luckUpgradePrice(luckLevel)
		if luckPrice and cash >= luckPrice * 3 then
			cash -= luckPrice
			luckLevel += 1
		end
		local luck = Catalog.luckFor(luckLevel, false, 0)

		if extra and cash >= extra * 2 then
			cash -= extra
			slots += 1
		end

		local chosen: any, count = nil, 0
		for i = #botCases, 1, -1 do
			local case = botCases[i]
			if case.Price * maxOpen <= cash then
				chosen, count = case, maxOpen
				break
			end
		end
		if not chosen then
			for i = #botCases, 1, -1 do
				local case = botCases[i]
				if case.Price <= cash then
					chosen, count = case, math.min(maxOpen, math.floor(cash / case.Price))
					break
				end
			end
		end

		if chosen then
			cash -= chosen.Price * count
			firstOpen[chosen.Id] = firstOpen[chosen.Id] or t
			local gem = false
			for _ = 1, count do
				local roll = Roller.roll(chosen, luck, rng) :: Roller.Roll
				gem = gem or roll.Gem
				receive(Catalog.valueOf(roll))
			end
			advance(batchSeconds(count, gem))
		else
			local cheapest = botCases[1].Price
			local wait = freeReadyAt - t
			if income > 0 then
				wait = math.min(wait, (cheapest - cash) / income)
			end
			advance(math.max(wait, 1))
		end
	end

	return firstOpen, snapshots
end

local function hm(seconds: number?): string
	if not seconds then
		return "never"
	end
	local minutes = math.floor(seconds / 60 + 0.5)
	return string.format("%dh%02dm", minutes // 60, minutes % 60)
end

local function median(list: { number }): number?
	if #list == 0 then
		return nil
	end
	table.sort(list)
	return list[math.ceil(#list / 2)]
end

print(string.format("\n== Progression: %d bots, %d hours of play each ==", BOTS, HOURS))
local opens: { [string]: { number } } = {}
local snaps: { { { [string]: number } } } = {}
for _, case in botCases do
	opens[case.Id] = {}
end
for _ = 1, BOTS do
	local firstOpen, snapshots = runBot()
	for id, at in firstOpen do
		table.insert(opens[id], at)
	end
	table.insert(snaps, snapshots)
end

print(pad("case", 20) .. lpad("reached by", 12) .. lpad("median", 10) .. lpad("fastest", 10))
for _, case in botCases do
	local list = opens[case.Id]
	local fastest = if #list > 0 then math.min(table.unpack(list)) else nil
	print(
		pad(case.Name, 20)
			.. lpad(string.format("%d/%d", #list, BOTS), 12)
			.. lpad(hm(median(list)), 10)
			.. lpad(hm(fastest), 10)
	)
end

print(
	"\n"
		.. pad("played", 10)
		.. lpad("showcase", 12)
		.. lpad("income/s", 12)
		.. lpad("slots", 8)
		.. lpad("luck", 6)
		.. "   (medians)"
)
for index, hours in CHECKPOINTS do
	local showcase, income, slots, luck = {}, {}, {}, {}
	for _, snapshots in snaps do
		local snap = snapshots[index]
		if snap then
			table.insert(showcase, snap.showcase)
			table.insert(income, snap.income)
			table.insert(slots, snap.slots)
			table.insert(luck, snap.luck)
		end
	end
	print(
		pad(hours .. "h", 10)
			.. lpad(Format.cash(median(showcase) or 0), 12)
			.. lpad(Format.cash(median(income) or 0), 12)
			.. lpad(tostring(median(slots) or 0), 8)
			.. lpad(tostring(median(luck) or 0), 6)
	)
end
