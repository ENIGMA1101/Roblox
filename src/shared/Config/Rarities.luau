--[[
	Rarity tiers, lowest to highest. Order in this list is the tier order.

	Which rarities hide behind the yellow gem is decided per case (see Cases.luau), so
	a cheap case can put Epic behind the gem while the top case keeps it for Mythic+.
]]

export type Rarity = {
	Id: string,
	Name: string,
	Color: Color3,
}

local Rarities: { Rarity } = {
	{ Id = "Common", Name = "Common", Color = Color3.fromRGB(170, 177, 192) },
	{ Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(94, 201, 126) },
	{ Id = "Rare", Name = "Rare", Color = Color3.fromRGB(75, 139, 245) },
	{ Id = "Epic", Name = "Epic", Color = Color3.fromRGB(157, 92, 246) },
	{ Id = "Legendary", Name = "Legendary", Color = Color3.fromRGB(239, 68, 68) },
	{ Id = "Mythic", Name = "Mythic", Color = Color3.fromRGB(255, 79, 216) },
	{ Id = "Sovereign", Name = "Sovereign", Color = Color3.fromRGB(255, 196, 46) },
}

return Rarities
