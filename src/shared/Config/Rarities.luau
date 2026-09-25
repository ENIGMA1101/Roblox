--[[
	Rarity tiers, lowest to highest. Order in this list is the tier order.

	MinValue - an item without an explicit Rarity gets the highest tier whose MinValue its
	           base value reaches, so a $90 watch is Common and an $8.5M watch is Mythic.
	Limited  - never assigned by value; only the numbered Robux-case exclusives use it.
	Imperial / Ethereal / Omega - the ultra-rare "grail" tiers. Never assigned by value: grail
	           items set them explicitly and only drop from the cases that list them in Grails.
	Fx       - how loudly the tier shows on the reel and in reveals: 0 plain ... 8 maximum.
	Gradient - optional colours for the animated card background of the top tiers.

	Which items hide behind the yellow gem is decided per case (see Cases.luau).
]]

export type Rarity = {
	Id: string,
	Name: string,
	Color: Color3,
	MinValue: number?,
	Fx: number,
	Gradient: { Color3 }?,
}

local Rarities: { Rarity } = {
	{ Id = "Common", Name = "Common", Color = Color3.fromRGB(170, 177, 192), MinValue = 0, Fx = 0 },
	{ Id = "Uncommon", Name = "Uncommon", Color = Color3.fromRGB(94, 201, 126), MinValue = 400, Fx = 0 },
	{ Id = "Rare", Name = "Rare", Color = Color3.fromRGB(75, 139, 245), MinValue = 2000, Fx = 1 },
	{ Id = "Epic", Name = "Epic", Color = Color3.fromRGB(157, 92, 246), MinValue = 15000, Fx = 2 },
	{ Id = "Legendary", Name = "Legendary", Color = Color3.fromRGB(239, 68, 68), MinValue = 200000, Fx = 3 },
	{ Id = "Mythic", Name = "Mythic", Color = Color3.fromRGB(255, 79, 216), MinValue = 3000000, Fx = 4 },
	{ Id = "Sovereign", Name = "Sovereign", Color = Color3.fromRGB(255, 196, 46), MinValue = 30000000, Fx = 5 },
	{
		Id = "Imperial",
		Name = "Imperial",
		Color = Color3.fromRGB(255, 92, 52),
		Fx = 6,
		Gradient = { Color3.fromRGB(150, 0, 30), Color3.fromRGB(255, 92, 52), Color3.fromRGB(255, 215, 90) },
	},
	{
		Id = "Ethereal",
		Name = "Ethereal",
		Color = Color3.fromRGB(190, 235, 255),
		Fx = 7,
		Gradient = {
			Color3.fromRGB(255, 255, 255),
			Color3.fromRGB(170, 225, 255),
			Color3.fromRGB(220, 190, 255),
			Color3.fromRGB(255, 255, 255),
		},
	},
	{
		Id = "Omega",
		Name = "Omega",
		Color = Color3.fromRGB(200, 120, 255),
		Fx = 8,
		Gradient = {
			Color3.fromRGB(255, 80, 80),
			Color3.fromRGB(255, 210, 80),
			Color3.fromRGB(90, 255, 150),
			Color3.fromRGB(80, 170, 255),
			Color3.fromRGB(200, 90, 255),
			Color3.fromRGB(255, 80, 80),
		},
	},
	{ Id = "Limited", Name = "Limited", Color = Color3.fromRGB(0, 224, 255), Fx = 5 },
}

return Rarities
