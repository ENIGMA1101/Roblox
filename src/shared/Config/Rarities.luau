--[[
	Rarity tiers, lowest to highest. Order in this list is the tier order.

	MinValue - an item without an explicit Rarity gets the highest tier whose MinValue its
	           base value reaches, so a $90 watch is Common and an $8.5M watch is Mythic.
	Limited  - never assigned by value; only the numbered Robux-case exclusives use it.

	Which items hide behind the yellow gem is decided per case (see Cases.luau).
]]

export type Rarity = {
	Id: string,
	Name: string,
	Color: Color3,
	MinValue: number?,
}

local Rarities: { Rarity } = {
	{ Id = "Common", Name = "Common", Color = Color3.fromRGB(170, 177, 192), MinValue = 0 },
	{ Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(94, 201, 126), MinValue = 400 },
	{ Id = "Rare", Name = "Rare", Color = Color3.fromRGB(75, 139, 245), MinValue = 2000 },
	{ Id = "Epic", Name = "Epic", Color = Color3.fromRGB(157, 92, 246), MinValue = 15000 },
	{ Id = "Legendary", Name = "Legendary", Color = Color3.fromRGB(239, 68, 68), MinValue = 200000 },
	{ Id = "Mythic", Name = "Mythic", Color = Color3.fromRGB(255, 79, 216), MinValue = 3000000 },
	{ Id = "Sovereign", Name = "Sovereign", Color = Color3.fromRGB(255, 196, 46), MinValue = 30000000 },
	{ Id = "Limited", Name = "Limited", Color = Color3.fromRGB(0, 224, 255) },
}

return Rarities
