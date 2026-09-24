--[[
	Developer panel (Studio, or live-server admins from GameConfig.Debug.Admins).

	Arm overrides for the next open (gem, mutation), then open any case straight from here
	to watch the full sequence without grinding for it. The server enforces who can use this.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local Actions = require(script.Parent.Parent.Actions)
local State = require(script.Parent.Parent.State)
local Kit = require(script.Parent.Kit)
local Spinner = require(script.Parent.Spinner)
local Theme = require(script.Parent.Theme)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local DevTools = {}

local window: Window.Window
local statusLabel: TextLabel
local openCount = 1

local function armedText(): string
	local parts = {}
	if State.Force.Gem then
		table.insert(parts, if State.Force.Gem == "top" then "💎 Gem (top tier)" else "💎 Gem (random tier)")
	end
	if State.Force.Mutation then
		local mutation = Catalog.MutationById[State.Force.Mutation]
		table.insert(parts, `✦ {mutation.Name}`)
	end
	return if #parts > 0
		then "Next open: " .. table.concat(parts, "  +  ")
		else "Nothing armed: the next open rolls normally."
end

local function refresh()
	statusLabel.Text = armedText()
	statusLabel.TextColor3 = if next(State.Force) then Colors.Gold else Colors.SubText
end

local function heading(parent: Instance, order: number, text: string)
	Kit.label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 26),
		Text = text,
		FontFace = Fonts.Heavy,
		TextSize = 18,
		TextColor3 = Colors.Gold,
		Parent = parent,
	})
end

local function buttonRow(parent: Instance, order: number, height: number?): Frame
	return Kit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = parent,
	}, {
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(150, height or 38),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function button(parent: Instance, order: number, text: string, color: Color3?, onClick: () -> ())
	Kit.button({
		LayoutOrder = order,
		Text = text,
		TextSize = 15,
		TextWrapped = true,
		BackgroundColor3 = color or Colors.PanelLighter,
		Parent = parent,
	}, onClick)
end

function DevTools.open()
	if State.Debug then
		window:open()
	end
end

function DevTools.start()
	window = Window.create("DevTools", "Developer Tools", Vector2.new(820, 580))
	local scroller = Kit.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = window.Content,
	}, { Kit.list(Enum.FillDirection.Vertical, 8) })

	statusLabel = Kit.label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 30),
		FontFace = Fonts.Bold,
		TextSize = 18,
		Parent = scroller,
	})

	heading(scroller, 2, "1. Arm the next open")
	local gemRow = buttonRow(scroller, 3)
	button(gemRow, 1, "💎 Force gem (random tier)", Colors.GoldDeep, function()
		Actions.debug("ForceGem", "random")
	end)
	button(gemRow, 2, "💎 Force gem (top tier)", Colors.GoldDeep, function()
		Actions.debug("ForceGem", "top")
	end)
	button(gemRow, 3, "Clear all", nil, function()
		Actions.debug("ClearForce")
	end)

	local mutationRow = buttonRow(scroller, 4)
	for index, mutation in Catalog.Mutations do
		local lum = mutation.Color.R * 0.3 + mutation.Color.G * 0.59 + mutation.Color.B * 0.11
		Kit.button({
			LayoutOrder = index,
			Text = `{mutation.Name} {Format.mult(mutation.Mult)}`,
			TextSize = 15,
			BackgroundColor3 = mutation.Color,
			TextColor3 = if lum > 0.55 then Color3.fromRGB(20, 20, 26) else Colors.Text,
			Parent = mutationRow,
		}, function()
			Actions.debug("ForceMutation", mutation.Id)
		end)
	end

	heading(scroller, 5, "2. Open a case (uses your cash or keys)")
	local countRow = buttonRow(scroller, 6)
	local countButtons = {}
	for count = 1, GameConfig.MaxOpenWithPass do
		countButtons[count] = Kit.button({
			LayoutOrder = count,
			Text = `×{count}`,
			TextSize = 15,
			Parent = countRow,
		}, function()
			openCount = math.min(count, State.maxOpen())
			for other, b in countButtons do
				Kit.setButtonColor(b, if other == openCount then Colors.Accent else Colors.PanelLighter)
			end
		end)
	end
	Kit.setButtonColor(countButtons[1], Colors.Accent)
	local caseRow = buttonRow(scroller, 7, 44)
	for index, case in Catalog.Cases do
		button(caseRow, index, `{case.Icon} {case.Name}`, case.Color:Lerp(Colors.Panel, 0.45), function()
			Spinner.run(case, math.min(openCount, State.maxOpen()))
		end)
	end

	heading(scroller, 8, "Economy")
	local cashRow = buttonRow(scroller, 9)
	for index, amount in { 1e6, 1e8, 1e10 } do
		button(
			cashRow,
			index,
			`+{if amount >= 1e9 then "$10B" elseif amount >= 1e8 then "$100M" else "$1M"}`,
			nil,
			function()
				Actions.debug("AddCash", amount)
			end
		)
	end
	button(cashRow, 4, "Free case ready", nil, function()
		Actions.debug("FreeCaseReady")
	end)
	local luckRow = buttonRow(scroller, 10)
	for index, level in { 0, math.floor(GameConfig.LuckUpgrades.MaxLevel / 2), GameConfig.LuckUpgrades.MaxLevel } do
		button(luckRow, index, `Luck level {level}`, nil, function()
			Actions.debug("SetLuck", level)
		end)
	end

	Kit.label({
		LayoutOrder = 11,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "Items from forced opens are real and saved. Players only see this panel in Studio or if "
			.. "their UserId is in GameConfig.Debug.Admins; the server checks this on every request.",
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextSize = 14,
		TextColor3 = Colors.SubText,
		Parent = scroller,
	})

	window.OnOpen = refresh
	State.Changed:Connect(function(kind)
		if kind == "Force" or kind == "State" then
			refresh()
		end
	end)
end

return DevTools
