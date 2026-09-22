--[[
	How items and the gem look everywhere: icon, gem, and inventory-style cards.
	Items without artwork (Image = "") fall back to their emoji Icon.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local ItemVisual = {}

local GEM_LIGHT = Color3.fromRGB(255, 240, 150)
local GEM_MID = Color3.fromRGB(255, 196, 46)
local GEM_DARK = Color3.fromRGB(226, 120, 14)

-- Item artwork (or emoji) filling its parent.
function ItemVisual.icon(itemId: string, props: { [string]: any }?): GuiObject
	local item = Catalog.ItemById[itemId]
	local base = {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}
	if props then
		for key, value in props do
			base[key] = value
		end
	end
	if item and item.Image ~= "" then
		base.Image = item.Image
		base.ScaleType = Enum.ScaleType.Fit
		return Kit.new("ImageLabel", base)
	end
	base.Text = if item then item.Icon else "?"
	base.TextScaled = true
	base.FontFace = Fonts.Regular
	base.TextColor3 = Color3.new(1, 1, 1)
	return Kit.new("TextLabel", base)
end

-- The yellow gem. Uses GameConfig.GemImage when set, otherwise a drawn gem.
function ItemVisual.gem(props: { [string]: any }?): GuiObject
	local base = {
		Name = "Gem",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}
	if props then
		for key, value in props do
			base[key] = value
		end
	end
	if GameConfig.GemImage ~= "" then
		base.Image = GameConfig.GemImage
		base.ScaleType = Enum.ScaleType.Fit
		return Kit.new("ImageLabel", base)
	end

	local holder = Kit.new("Frame", base, { Kit.new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	local body = Kit.new("Frame", {
		Name = "Body",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.6),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = holder,
	}, {
		Kit.new("UICorner", { CornerRadius = UDim.new(0.14, 0) }),
		Kit.gradient({ GEM_LIGHT, GEM_MID, GEM_DARK }, 90),
		Kit.new("UIStroke", { Color = Color3.fromRGB(255, 250, 220), Thickness = 2, Transparency = 0.15 }),
	})
	-- Facet lines and a highlight so it reads as cut stone, not a flat diamond shape.
	Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.fromRGB(255, 250, 225),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = body,
	})
	Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 250, 225),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = body,
	})
	Kit.new("Frame", {
		Position = UDim2.fromScale(0.12, 0.12),
		Size = UDim2.fromScale(0.36, 0.36),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Parent = body,
	}, { Kit.new("UICorner", { CornerRadius = UDim.new(0.2, 0) }) })
	Kit.label({
		Name = "Sparkle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.74, 0.22),
		Size = UDim2.fromScale(0.22, 0.22),
		Text = "✦",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1),
		Parent = holder,
	})
	return holder
end

-- Fades any icon or gem made above.
function ItemVisual.setTransparency(visual: GuiObject, transparency: number)
	for _, object in visual:GetDescendants() do
		if object:IsA("TextLabel") then
			object.TextTransparency = transparency
		elseif object:IsA("Frame") and object.BackgroundTransparency < 1 then
			object.BackgroundTransparency = math.max(object.BackgroundTransparency, transparency)
		end
	end
	if visual:IsA("TextLabel") then
		visual.TextTransparency = transparency
	elseif visual:IsA("ImageLabel") then
		visual.ImageTransparency = transparency
	end
end

export type CardOptions = {
	Size: UDim2?,
	Selected: boolean?,
	LayoutOrder: number?,
	OnClick: (() -> ())?,
}

-- Inventory-style card for an owned item.
function ItemVisual.card(owned: Catalog.Owned, options: CardOptions?): TextButton
	local opts = options or {}
	local item = Catalog.ItemById[owned.I]
	local rarity = Catalog.RarityById[item.Rarity]
	local brand = Catalog.Brands[owned.B]
	local mutation = owned.M and Catalog.MutationById[owned.M]

	local card = Kit.new("TextButton", {
		Name = "Card",
		Size = opts.Size or UDim2.fromOffset(140, 176),
		BackgroundColor3 = Colors.PanelLight,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = opts.LayoutOrder or 0,
	}, {
		Kit.corner(10),
		Kit.new("UIStroke", {
			Color = if opts.Selected then Colors.Text elseif mutation then mutation.Color else rarity.Color,
			Thickness = if opts.Selected or mutation then 2.5 else 1.5,
			Transparency = if opts.Selected or mutation then 0 else 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	Kit.new("Frame", {
		Name = "Glow",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = rarity.Color,
		Parent = card,
	}, {
		Kit.corner(10),
		Kit.new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.55, 0.9),
				NumberSequenceKeypoint.new(1, 0.68),
			}),
		}),
	})
	Kit.new("Frame", {
		Name = "IconArea",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.new(1, -30, 0.5, -6),
		BackgroundTransparency = 1,
		Parent = card,
	}, { ItemVisual.icon(owned.I) })

	Kit.label({
		Name = "ItemName",
		Position = UDim2.new(0, 8, 0.56, 0),
		Size = UDim2.new(1, -16, 0.12, 0),
		Text = item.Name,
		TextScaled = true,
		FontFace = Fonts.Bold,
		TextColor3 = rarity.Color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	Kit.label({
		Name = "Brand",
		Position = UDim2.new(0, 8, 0.68, 0),
		Size = UDim2.new(1, -16, 0.1, 0),
		Text = brand and brand.Name or "",
		TextScaled = true,
		TextColor3 = Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	Kit.label({
		Name = "Value",
		Position = UDim2.new(0, 8, 0.8, 0),
		Size = UDim2.new(1, -16, 0.13, 0),
		Text = Format.cash(Catalog.valueOf(owned)),
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})

	if mutation then
		local badge = Kit.label({
			Name = "Mutation",
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(0.62, 0, 0, 18),
			BackgroundTransparency = 0,
			BackgroundColor3 = mutation.Color,
			Text = mutation.Name,
			TextScaled = true,
			FontFace = Fonts.Heavy,
			TextColor3 = Color3.fromRGB(20, 20, 26),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 3,
			Parent = card,
		})
		Kit.round().Parent = badge
		if mutation.Effect == "rainbow" then
			Kit.gradient({
				Color3.fromRGB(255, 110, 110),
				Color3.fromRGB(255, 220, 110),
				Color3.fromRGB(120, 255, 160),
				Color3.fromRGB(110, 190, 255),
				Color3.fromRGB(220, 130, 255),
			}, 0).Parent =
				badge
		end
	end

	local flags = (if owned.L then "🔒" else "") .. (if owned.S then "⭐" else "")
	if flags ~= "" then
		Kit.label({
			Name = "Flags",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 5),
			Size = UDim2.fromOffset(44, 20),
			Text = flags,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = card,
		})
	end

	if opts.OnClick then
		local onClick = opts.OnClick
		card.Activated:Connect(function()
			onClick()
		end)
	end
	return card
end

return ItemVisual
