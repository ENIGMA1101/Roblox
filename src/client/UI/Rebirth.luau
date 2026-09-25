--[[
	Rebirth window: what the next rebirth costs, what it resets, what it keeps, and the
	permanent bonuses it adds. The button needs a second click to confirm.
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

local REBIRTH_PINK = Color3.fromRGB(255, 92, 170)
local CONFIRM_SECONDS = 4

local Rebirth = {}

local window: Window.Window
local countLabel: TextLabel
local bonusLabel: TextLabel
local barFill: Frame
local costLabel: TextLabel
local rebirthButton: TextButton
local ladder: ScrollingFrame
local confirmUntil = 0

local function percent(mult: number): string
	return `+{math.floor((mult - 1) * 100 + 0.5)}%`
end

local function keptCount(): number
	local count = 0
	for _, owned in State.Items do
		if Catalog.keptOnRebirth(owned) then
			count += 1
		end
	end
	return count
end

local function refreshButton()
	local cost = Catalog.rebirthCost(State.Rebirths)
	local ready = State.Cash >= cost
	Kit.tween(barFill, 0.3, { Size = UDim2.fromScale(math.clamp(State.Cash / cost, 0, 1), 1) })
	costLabel.Text = `{Format.cash(math.min(State.Cash, cost))} / {Format.cash(cost)}`
	if os.clock() < confirmUntil and ready then
		rebirthButton.Text = "CLICK AGAIN TO CONFIRM"
		Kit.setButtonColor(rebirthButton, Colors.Bad)
	else
		rebirthButton.Text = if ready then `🔁 REBIRTH` else `Need {Format.cash(cost - State.Cash)} more`
		Kit.setButtonColor(rebirthButton, if ready then REBIRTH_PINK else Colors.PanelLighter)
	end
	rebirthButton.TextColor3 = if ready then Colors.Text else Colors.SubText
end

local function ladderRow(order: number, rebirths: number, current: boolean)
	local row = Kit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 34),
		BackgroundColor3 = if current then Colors.PanelLighter else Colors.PanelLight,
		Parent = ladder,
	}, { Kit.corner(8) })
	if current then
		Kit.stroke(REBIRTH_PINK, 1.5).Parent = row
	end
	local function cell(x: number, width: number, text: string, color: Color3?, align: Enum.TextXAlignment?)
		Kit.label({
			Position = UDim2.new(x, 8, 0, 0),
			Size = UDim2.new(width, -16, 1, 0),
			Text = text,
			FontFace = Fonts.Bold,
			TextColor3 = color or Colors.Text,
			TextXAlignment = align or Enum.TextXAlignment.Left,
			Parent = row,
		})
	end
	cell(0, 0.22, `Rebirth {rebirths}`, if current then REBIRTH_PINK else nil)
	cell(0.22, 0.26, Format.cash(Catalog.rebirthCost(rebirths - 1)), Colors.Gold, Enum.TextXAlignment.Right)
	cell(
		0.48,
		0.26,
		`🍀 {Format.mult(Catalog.rebirthLuck(rebirths))}`,
		Color3.fromRGB(80, 220, 120),
		Enum.TextXAlignment.Right
	)
	cell(0.74, 0.26, `💸 {percent(Catalog.rebirthSellMult(rebirths))}`, Colors.Good, Enum.TextXAlignment.Right)
end

function Rebirth.render()
	local rebirths = State.Rebirths
	countLabel.Text = `Rebirth {rebirths}`
	local config = GameConfig.Rebirth
	bonusLabel.Text = `Luck {Format.mult(Catalog.rebirthLuck(rebirths))}  →  <font color="#50DC78">{Format.mult(
		Catalog.rebirthLuck(rebirths + 1)
	)}</font>\n` .. `Sell & income {percent(Catalog.rebirthSellMult(rebirths))}  →  <font color="#50DC78">{percent(
		Catalog.rebirthSellMult(rebirths + 1)
	)}</font>\n` .. `<font color="#8A8F9C">Each rebirth: ×{config.LuckMult} luck, +{math.floor(config.SellBonus * 100)}% sell & income</font>`
	refreshButton()

	for _, child in ladder:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	Kit.label({
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 28),
		Text = "Rebirth ladder",
		FontFace = Fonts.Heavy,
		TextSize = 19,
		TextColor3 = Colors.Gold,
		Parent = ladder,
	})
	for index = 1, 8 do
		ladderRow(index, rebirths + index, index == 1)
	end
	Kit.label({
		LayoutOrder = 20,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "<b>Resets:</b> cash (back to "
			.. Format.cash(GameConfig.StartingCash)
			.. "), luck upgrade levels and every item pulled with cash.\n"
			.. `<b>Keeps:</b> Robux case items and grails ({keptCount()} you own now), keys, showcase slots, `
			.. "gamepasses, personal Robux luck and your stats.",
		RichText = true,
		TextSize = 15,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextColor3 = Colors.SubText,
		Parent = ladder,
	})
end

function Rebirth.open()
	window:open()
end

function Rebirth.start()
	window = Window.create("Rebirth", "Rebirth", Vector2.new(780, 540))
	local content = window.Content

	local left = Kit.new("Frame", {
		Size = UDim2.new(0, 290, 1, 0),
		BackgroundColor3 = Colors.PanelLight,
		Parent = content,
	}, { Kit.corner(12), Kit.padding(16) })
	Kit.label({
		Size = UDim2.new(1, 0, 0, 80),
		Text = "🔁",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	countLabel = Kit.label({
		Position = UDim2.fromOffset(0, 86),
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Fonts.Heavy,
		TextSize = 26,
		TextColor3 = REBIRTH_PINK,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	bonusLabel = Kit.label({
		Position = UDim2.fromOffset(0, 124),
		Size = UDim2.new(1, 0, 0, 96),
		RichText = true,
		TextSize = 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Fonts.Bold,
		Parent = left,
	})
	local bar = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -100),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundColor3 = Colors.Panel,
		Parent = left,
	}, { Kit.round() })
	barFill = Kit.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = REBIRTH_PINK,
		Parent = bar,
	}, { Kit.round() })
	costLabel = Kit.label({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -70),
		Size = UDim2.new(1, 0, 0, 24),
		FontFace = Fonts.Heavy,
		TextSize = 18,
		TextColor3 = Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	rebirthButton = Kit.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 58),
		FontFace = Fonts.Heavy,
		TextSize = 22,
		Parent = left,
	}, function()
		if State.Cash < Catalog.rebirthCost(State.Rebirths) then
			Toast.show("Not enough cash to rebirth yet.", "bad")
			return
		end
		if os.clock() >= confirmUntil then
			confirmUntil = os.clock() + CONFIRM_SECONDS
			refreshButton()
			task.delay(CONFIRM_SECONDS, refreshButton)
			return
		end
		confirmUntil = 0
		local result = Actions.rebirth()
		if result.ok then
			Toast.show(`🔁 Rebirth {result.Rebirths}! Luck and sell value boosted forever.`, "gold")
		end
		Rebirth.render()
	end)

	ladder = Kit.new("ScrollingFrame", {
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

	window.OnOpen = Rebirth.render
	State.Changed:Connect(function(kind)
		if not window:isOpen() then
			return
		end
		if kind == "Cash" then
			refreshButton()
		elseif kind == "Rebirths" or kind == "State" or kind == "Items" then
			Rebirth.render()
		end
	end)
end

return Rebirth
