--[[
	Sound ids. Pick sounds from the Creator Store (Toolbox -> Audio) or upload your own,
	then paste "rbxassetid://<id>". Empty strings are skipped silently, so the game runs
	without any of these set.

	Suggested searches are in the comments.
]]

return {
	Tick = { Id = "", Volume = 0.35 }, -- "ui tick", "click short": plays as each item passes the line
	Land = { Id = "", Volume = 0.6 }, -- "thud soft", "card place"
	Reveal = { Id = "", Volume = 0.6 }, -- "reward chime": pitched up per rarity tier
	RevealBig = { Id = "", Volume = 0.8 }, -- "epic win", "fanfare short": Legendary and above
	CountUp = { Id = "", Volume = 0.3 }, -- "coin counter loop": looped during value count-up

	GemHit = { Id = "", Volume = 0.9 }, -- "impact bass boom", "cinematic hit"
	GemRiser = { Id = "", Volume = 0.7 }, -- "riser", "whoosh build up" (~1.5s)
	GemBurst = { Id = "", Volume = 0.9 }, -- "glass shatter sparkle", "magic burst"

	Mutation = { Id = "", Volume = 0.7 }, -- "magic shimmer", "sparkle"
	MutationBig = { Id = "", Volume = 0.9 }, -- "angelic choir", "legendary drop"

	Click = { Id = "", Volume = 0.4 },
	Sell = { Id = "", Volume = 0.6 }, -- "cash register"
	Error = { Id = "", Volume = 0.5 },
	Purchase = { Id = "", Volume = 0.7 },
}
