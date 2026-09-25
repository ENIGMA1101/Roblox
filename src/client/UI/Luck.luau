--[[
	Luck upgrade window: spend cash on permanent luck levels, see every luck source stacked
	together, and see exactly how the next level changes each case's top item and gem chance.
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

local LUCK_GREEN = Color3.fromRGB(80, 220, 120)

local Luck = {}

local window: Window.Window
local levelLabel: TextLabel
local barFill: Frame
local boostLabel: TextLabel
local buyButton: TextButton
local table_: ScrollingFrame

local function refreshButton()
	local price = Catalog.luckUpgradePrice(State.LuckLevel)
	local affordable = State.Cash >= price
	buyButton.Text = `UPGRADE   {Format.cash(price)}`
	buyButton.Active = affordable
	Kit.setButtonColor(buyButton, if affordable then Color3.fromRGB(34, 140, 74) else Colors.PanelLighter)
	buyButton.TextColor3 = if affordable then Colors.Text else Colors.SubText
	-- The bar shows how close your cash is to the next level.
	Kit.tween(barFill, 0.3, { Size = UDim2.fromScale(math.clamp(State.Cash / price, 0, 1), 1) })
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

-- Chance of a case's most valuable regular (non-grail) item at this luck.
local function topItemChance(case: Catalog.Case, itemLuck: number, boosted: boolean?): number
	local best: Catalog.Entry? = nil
	for _, entry in Catalog.caseOdds(case, itemLuck, nil, boosted) do
		if not entry.Grail and (best == nil or entry.Item.Value > best.Item.Value) then
			best = entry
		end
	end
	return if best then best.P else 0
end

function Luck.render()
	local level = State.LuckLevel
	local now = State.luck()
	local nextItem = now.Item * GameConfig.LuckUpgrades.PerLevel

	levelLabel.Text = `Level {level}`
	local parts = {}
	for _, source in State.luckSources() do
		if source.Mult > 1 then
			table.insert(parts, `{source.Name} {Format.mult(source.Mult)}`)
		end
	end
	boostLabel.Text = `Item luck {Format.mult(now.Item)}  →  <font color="#50DC78">{Format.mult(nextItem)}</font>\n`
		.. (if #parts > 0 then table.concat(parts, " × ") else "No luck yet")
		.. `\nMutation luck {Format.mult(now.Mutation)}{if now.Mutation > 1 then "" else " (Mutation Luck pass)"}`
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

	section(nextOrder(), "Top item chance per case")
	for _, case in Catalog.Cases do
		tableRow(
			nextOrder(),
			`{case.Icon} {case.Name}`,
			case.Color,
			Format.oneIn(topItemChance(case, now.Item, now.Boosted)),
			Format.oneIn(topItemChance(case, nextItem, now.Boosted))
		)
	end

	section(nextOrder(), "Gem chance per case")
	for _, case in Catalog.Cases do
		tableRow(
			nextOrder(),
			`{case.Icon} {case.Name}`,
			case.Color,
			Format.oneIn(Catalog.gemChance(case, now.Item, now.Boosted)),
			Format.oneIn(Catalog.gemChance(case, nextItem, now.Boosted))
		)
	end

	section(nextOrder(), "Rarest mutations (item luck doesn't change these)")
	for i = #Catalog.Mutations, math.max(#Catalog.Mutations - 3, 1), -1 do
		local mutation = Catalog.Mutations[i]
		tableRow(
			nextOrder(),
			`{mutation.Name} {Format.mult(mutation.Mult)}`,
			mutation.Color,
			Format.oneIn(Catalog.mutationChance(mutation, now.Mutation)),
			""
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
		RichText = true,
		TextSize = 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Fonts.Bold,
		Parent = left,
	})
	Kit.label({
		Position = UDim2.fromOffset(0, 258),
		Size = UDim2.new(1, 0, 0, 120),
		Text = "Every luck source multiplies together. Luck boosts rare items the most: at 100x luck a case's "
			.. "top item is close to 100x more likely, while commons barely change. Each case has diminishing "
			.. "returns so luck always helps but can't break it. Grails and mutations are never affected. "
			.. "Levels reset when you rebirth.",
		TextSize = 13,
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
		elseif
			kind == "Luck"
			or kind == "Rebirths"
			or kind == "Passes"
			or kind == "State"
			or kind == "PersonalLuck"
			or kind == "ServerLuck"
			or kind == "LuckBar"
		then
			Luck.render()
		end
	end)
end

return Luck
