--[[
	Mutations roll independently of the item on every pull (after brand).

	Mult    - value multiplier.
	OneIn   - base chance is 1 in OneIn. Luck divides OneIn (2x luck: 1 in 20 -> 1 in 10).
	Tier    - 1..5, drives how loud the reveal is (sound, flash, shake).
	Effect  - "shine" (sweeping highlight), "sparkle" (twinkling stars),
	          "pulse" (breathing glow), "rainbow" (cycling hue).

	Id is a save key: don't rename it once live.
]]

export type Mutation = {
	Id: string,
	Name: string,
	Mult: number,
	OneIn: number,
	Tier: number,
	Effect: string,
	Color: Color3,
}

local Mutations: { Mutation } = {
	{
		Id = "polished",
		Name = "Polished",
		Mult = 1.1,
		OneIn = 20,
		Tier = 1,
		Effect = "shine",
		Color = Color3.fromRGB(226, 232, 245),
	},
	{
		Id = "engraved",
		Name = "Engraved",
		Mult = 1.25,
		OneIn = 60,
		Tier = 1,
		Effect = "shine",
		Color = Color3.fromRGB(214, 181, 132),
	},
	{
		Id = "gilded",
		Name = "Gilded",
		Mult = 1.5,
		OneIn = 150,
		Tier = 2,
		Effect = "shine",
		Color = Color3.fromRGB(255, 200, 60),
	},
	{
		Id = "icedout",
		Name = "Iced Out",
		Mult = 2,
		OneIn = 400,
		Tier = 2,
		Effect = "sparkle",
		Color = Color3.fromRGB(140, 222, 255),
	},
	{
		Id = "rosegold",
		Name = "Rose Gold",
		Mult = 3,
		OneIn = 1200,
		Tier = 3,
		Effect = "shine",
		Color = Color3.fromRGB(255, 150, 160),
	},
	{
		Id = "obsidian",
		Name = "Obsidian",
		Mult = 4.5,
		OneIn = 4000,
		Tier = 3,
		Effect = "pulse",
		Color = Color3.fromRGB(128, 72, 196),
	},
	{
		Id = "prismatic",
		Name = "Prismatic",
		Mult = 6.5,
		OneIn = 12500,
		Tier = 4,
		Effect = "rainbow",
		Color = Color3.fromRGB(255, 255, 255),
	},
	{
		Id = "celestial",
		Name = "Celestial",
		Mult = 10,
		OneIn = 50000,
		Tier = 4,
		Effect = "sparkle",
		Color = Color3.fromRGB(170, 190, 255),
	},
	{
		Id = "crownjewel",
		Name = "Crown Jewel",
		Mult = 15,
		OneIn = 200000,
		Tier = 5,
		Effect = "rainbow",
		Color = Color3.fromRGB(255, 215, 90),
	},
}

return Mutations
