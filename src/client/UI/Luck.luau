--[[
	Luck upgrade window: spend cash on permanent luck levels and see exactly how each level
	changes every case's gem chance and the rarest mutations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local Actions = require(script.Parent.Parent.Actions)
local State = require(script.Parent.Parent.State)
local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts
local Upgrades = GameConfig.LuckUpgrades

local LUCK_GREEN = Color3.fromRGB(80, 220, 120)

local Luck = {}

local window: Window.Window
local levelLabel: TextLabel
local barFill: Frame
local boostLabel: TextLabel
local buyButton: TextButton
local table_: ScrollingFrame

local function multiplier(value: number): string
	return "×" .. string.format("%.2f", value)
end

local function refreshButton()
	local price = Catalog.luckUpgradePrice(State.LuckLevel)
	if not price then
		buyButton.Text = "MAX LUCK"
		buyButton.Active = false
		Kit.setButtonColor(buyButton, Colors.PanelLighter)
		buyButton.TextColor3 = Colors.Gold
		return
	end
	local affordable = State.Cash >= price
	buyButton.Text = `UPGRADE   {Format.cash(price)}`
	buyButton.Active = affordable
	Kit.setButtonColor(buyButton, if affordable then Color3.fromRGB(34, 140, 74) else Colors.PanelLighter)
	buyButton.TextColor3 = if affordable then Colors.Text else Colors.SubText
end

local function tableRow(order: number, label: string, color: Color3, now: string, nextValue: string)
	local row = Kit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 34),
		BackgroundColor3 = Colors.PanelLight,
		Parent = table_,
	}, { Kit.corner(8) })
	Kit.label({
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.45, 0, 1, 0),
		Text = label,
		FontFace = Fonts.Bold,
		TextColor3 = color,
		Parent = row,
	})
	Kit.label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.55, -12, 1, 0),
		Text = if nextValue ~= "" then `{now}  →  <font color="#50DC78">{nextValue}</font>` else now,
		RichText = true,
		FontFace = Fonts.Heavy,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
end

local function section(order: number, text: string)
	Kit.label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 28),
		Text = text,
		FontFace = Fonts.Heavy,
		TextSize = 19,
		TextColor3 = Colors.Gold,
		Parent = table_,
	})
end

function Luck.render()
	local level = State.LuckLevel
	local hasPass = State.hasPass("Luck")
	local now = Catalog.luckFor(level, hasPass)
	local maxed = level >= Upgrades.MaxLevel
	local nextLuck = if maxed then nil else Catalog.luckFor(level + 1, hasPass)

	levelLabel.Text = `Level {level} / {Upgrades.MaxLevel}`
	Kit.tween(barFill, 0.3, { Size = UDim2.fromScale(level / Upgrades.MaxLevel, 1) })
	boostLabel.Text = `Gem pulls {multiplier(now.Gem)}{if nextLuck then "  →  " .. multiplier(nextLuck.Gem) else ""}\n`
		.. `Mutations {multiplier(now.Mutation)}{if nextLuck then "  →  " .. multiplier(nextLuck.Mutation) else ""}`
		.. (if hasPass then "\n(includes your 2x Luck pass)" else "")
	refreshButton()

	for _, child in table_:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	section(nextOrder(), "Gem chance per case")
	for _, case in Catalog.Cases do
		tableRow(
			nextOrder(),
			`{case.Icon} {case.Name}`,
			case.Color,
			Format.oneIn(Catalog.gemChance(case, now.Gem)),
			if nextLuck then Format.oneIn(Catalog.gemChance(case, nextLuck.Gem)) else ""
		)
	end

	section(nextOrder(), "Rarest mutations")
	for i = #Catalog.Mutations, math.max(#Catalog.Mutations - 3, 1), -1 do
		local mutation = Catalog.Mutations[i]
		tableRow(
			nextOrder(),
			`{mutation.Name} {Format.mult(mutation.Mult)}`,
			mutation.Color,
			Format.oneIn(Catalog.mutationChance(mutation, now.Mutation)),
			if nextLuck then Format.oneIn(Catalog.mutationChance(mutation, nextLuck.Mutation)) else ""
		)
	end
end

function Luck.open()
	window:open()
end

function Luck.start()
	window = Window.create("Luck", "Luck Upgrades", Vector2.new(780, 540))
	local content = window.Content

	local left = Kit.new("Frame", {
		Size = UDim2.new(0, 290, 1, 0),
		BackgroundColor3 = Colors.PanelLight,
		Parent = content,
	}, { Kit.corner(12), Kit.padding(16) })
	Kit.label({
		Size = UDim2.new(1, 0, 0, 90),
		Text = "🍀",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	levelLabel = Kit.label({
		Position = UDim2.fromOffset(0, 98),
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Fonts.Heavy,
		TextSize = 26,
		TextColor3 = LUCK_GREEN,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	local bar = Kit.new("Frame", {
		Position = UDim2.fromOffset(0, 136),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Colors.Panel,
		Parent = left,
	}, { Kit.round() })
	barFill = Kit.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = LUCK_GREEN,
		Parent = bar,
	}, { Kit.round() })
	boostLabel = Kit.label({
		Position = UDim2.fromOffset(0, 164),
		Size = UDim2.new(1, 0, 0, 90),
		TextSize = 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Fonts.Bold,
		Parent = left,
	})
	Kit.label({
		Position = UDim2.fromOffset(0, 262),
		Size = UDim2.new(1, 0, 0, 60),
		Text = "Luck makes each case's gem rarities and every mutation more likely. Levels are permanent.",
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Colors.SubText,
		Parent = left,
	})
	buyButton = Kit.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 58),
		FontFace = Fonts.Heavy,
		TextSize = 22,
		Parent = left,
	}, function()
		local result = Actions.buyLuck()
		if result.ok then
			Toast.show(`Luck level {result.Level}!`, "good")
		end
	end)

	table_ = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(306, 0),
		Size = UDim2.new(1, -306, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = content,
	}, { Kit.list(Enum.FillDirection.Vertical, 6) })

	window.OnOpen = Luck.render
	State.Changed:Connect(function(kind)
		if not window:isOpen() then
			return
		end
		if kind == "Cash" then
			refreshButton()
		elseif kind == "Luck" or kind == "Passes" or kind == "State" then
			Luck.render()
		end
	end)
end

return Luck
