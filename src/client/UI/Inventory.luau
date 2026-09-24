--[[
	Inventory window with two tabs:
	- Items: every owned item, sorting, sell / lock / showcase, and bulk sell by rarity.
	- Showcase: the items earning passive income, slot purchases, and "fill with best".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local Actions = require(script.Parent.Parent.Actions)
local State = require(script.Parent.Parent.State)
local ItemVisual = require(script.Parent.ItemVisual)
local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts
local Showcase = GameConfig.Showcase

local SORTS = { "Value", "Newest", "Rarity" }

local Inventory = {}

local window: Window.Window
local tab = "Items"
local sortIndex = 1
local sellTier = 1 -- sell everything up to and including this rarity
local confirmUntil = 0
local selectedId: string? = nil
local dirty = false
local cardsById: { [string]: TextButton } = {}

local itemsTab: Frame
local showcaseTab: Frame
local tabButtons: { [string]: TextButton } = {}

-- Items tab widgets
local summaryLabel: TextLabel
local sortButton: TextButton
local tierButton: TextButton
local sellAllButton: TextButton
local grid: ScrollingFrame
local details: Frame

-- Showcase tab widgets
local incomeLabel: TextLabel
local slotsLabel: TextLabel
local buySlotButton: TextButton
local showcaseGrid: ScrollingFrame

local function sortedIds(): { string }
	local ids = {}
	for id in State.Items do
		table.insert(ids, id)
	end
	local mode = SORTS[sortIndex]
	local values = {}
	for _, id in ids do
		values[id] = Catalog.valueOf(State.Items[id])
	end
	table.sort(ids, function(a, b)
		local ia, ib = State.Items[a], State.Items[b]
		if mode == "Newest" then
			if ia.T ~= ib.T then
				return ia.T > ib.T
			end
			return (tonumber(a) or 0) > (tonumber(b) or 0)
		elseif mode == "Rarity" then
			local ra, rb = Catalog.rarityOf(ia), Catalog.rarityOf(ib)
			local oa, ob = if ra then ra.Order else 0, if rb then rb.Order else 0
			if oa ~= ob then
				return oa > ob
			end
		end
		return values[a] > values[b]
	end)
	return ids
end

local function sellAllPreview(): (number, number)
	local total, count = 0, 0
	for _, owned in State.Items do
		local rarity = Catalog.rarityOf(owned)
		if rarity and rarity.Order <= sellTier and not owned.L and not owned.S then
			total += Catalog.valueOf(owned)
			count += 1
		end
	end
	return total, count
end

local function clearGrid(frame: ScrollingFrame)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Details panel --------------------------------------------------------------------------------

local function renderDetails()
	details:ClearAllChildren()
	Kit.corner(12).Parent = details
	Kit.padding(14).Parent = details

	local owned = selectedId and State.Items[selectedId]
	if not owned then
		Kit.label({
			Size = UDim2.fromScale(1, 1),
			Text = "Select an item",
			TextColor3 = Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = details,
		})
		return
	end
	local id = selectedId :: string
	local item = Catalog.ItemById[owned.I]
	local rarity = Catalog.RarityById[item.Rarity]
	local mutation = owned.M and Catalog.MutationById[owned.M]
	local value = Catalog.valueOf(owned)

	Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(120, 120),
		BackgroundColor3 = rarity.Color,
		BackgroundTransparency = 0.82,
		Parent = details,
	}, {
		Kit.corner(16),
		Kit.stroke(if mutation then mutation.Color else rarity.Color, 2),
		ItemVisual.icon(owned.I, { Size = UDim2.fromScale(0.75, 0.75) }),
	})

	local y = 130
	local function line(text: string, height: number, font: Font, color: Color3)
		Kit.label({
			Position = UDim2.fromOffset(0, y),
			Size = UDim2.new(1, 0, 0, height),
			Text = text,
			TextScaled = true,
			FontFace = font,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = details,
		})
		y += height + 4
	end
	line(item.Name, 24, Fonts.Heavy, rarity.Color)
	line(`{Catalog.Brands[owned.B].Name}  •  {rarity.Name}`, 18, Fonts.Medium, Colors.SubText)
	if mutation then
		line(`✦ {mutation.Name} {Format.mult(mutation.Mult)}`, 20, Fonts.Heavy, mutation.Color)
	end
	if owned.N then
		local supply = item.Supply
		line(
			if supply
				then `Limited #{Format.commas(owned.N)} / {Format.commas(supply)}`
				else `Numbered #{Format.commas(owned.N)} of {Format.commas(State.Serials[owned.I] or owned.N)} pulled`,
			18,
			Fonts.Heavy,
			Catalog.RarityById.Limited.Color
		)
	end
	line(Format.cashFull(value), 26, Fonts.Heavy, Colors.Gold)
	line(`Showcase: +{Format.cash(State.itemIncome(owned))}/s`, 16, Fonts.Medium, Colors.Good)

	local function button(order: number, text: string, color: Color3, onClick: () -> ())
		Kit.button({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 0, 1, -(2 - order) * 50),
			Size = UDim2.new(1, 0, 0, 42),
			Text = text,
			BackgroundColor3 = color,
			Parent = details,
		}, onClick)
	end
	button(0, if owned.S then "Remove from showcase" else "Put in showcase", Colors.Accent, function()
		Actions.setShowcased(id, not owned.S)
	end)
	button(1, if owned.L then "🔓 Unlock" else "🔒 Lock", Colors.PanelLighter, function()
		Actions.setLocked(id, not owned.L)
	end)
	button(2, if owned.L then "Locked" else `Sell for {Format.cash(value)}`, Color3.fromRGB(34, 120, 74), function()
		if owned.L then
			Toast.show("Unlock it first.", "bad")
			return
		end
		local result = Actions.sell({ id })
		if result.ok and result.Count > 0 then
			Toast.show(`Sold for {Format.cash(result.Total)}`, "good")
			selectedId = nil
		end
	end)
end

-- Items tab ------------------------------------------------------------------------------------

local function renderItems()
	local count = State.itemCount()
	local totalValue = 0
	for _, owned in State.Items do
		totalValue += Catalog.valueOf(owned)
	end
	summaryLabel.Text = `{count}/{GameConfig.InventoryCap} items  •  worth {Format.cash(totalValue)}`
	sortButton.Text = `Sort: {SORTS[sortIndex]}`
	local tier = Catalog.Rarities[sellTier]
	tierButton.Text = `Up to {tier.Name}`
	tierButton.TextColor3 = tier.Color
	if os.clock() < confirmUntil then
		local total, sellCount = sellAllPreview()
		sellAllButton.Text = `Confirm: {sellCount} for {Format.cash(total)}`
	else
		sellAllButton.Text = "Sell all"
	end

	clearGrid(grid)
	table.clear(cardsById)
	if selectedId and not State.Items[selectedId] then
		selectedId = nil
	end
	for order, id in sortedIds() do
		local owned = State.Items[id]
		local card = ItemVisual.card(owned, {
			LayoutOrder = order,
			Selected = id == selectedId,
			OnClick = function()
				Inventory.select(id)
			end,
		})
		card.Parent = grid
		cardsById[id] = card
	end
	renderDetails()
end

-- Selecting only restyles two cards and the details panel instead of rebuilding the grid.
function Inventory.select(id: string)
	local previous = selectedId
	selectedId = id
	local function restyle(cardId: string)
		local card = cardsById[cardId]
		local owned = State.Items[cardId]
		if not card or not owned then
			return
		end
		local fresh = ItemVisual.card(owned, {
			LayoutOrder = card.LayoutOrder,
			Selected = cardId == selectedId,
			OnClick = function()
				Inventory.select(cardId)
			end,
		})
		fresh.Parent = grid
		card:Destroy()
		cardsById[cardId] = fresh
	end
	if previous and previous ~= id then
		restyle(previous)
	end
	restyle(id)
	renderDetails()
end

-- Showcase tab ---------------------------------------------------------------------------------

local function renderShowcase()
	local used = State.showcasedCount()
	incomeLabel.Text = `Income  {Format.cash(State.Income)}/s`
	slotsLabel.Text =
		`{used}/{State.ShowcaseSlots} slots  •  base {Format.cash(Showcase.BaseIncome)}/s  •  offline {math.floor(
			Showcase.OfflineRate * 100
		)}%`
	local price = Showcase.SlotPrices[State.ShowcaseSlots - Showcase.BaseSlots + 1]
	if price then
		buySlotButton.Text = `Buy slot  {Format.cash(price)}`
		buySlotButton.TextTransparency = if State.Cash >= price then 0 else 0.45
	else
		buySlotButton.Text = "Showcase maxed"
		buySlotButton.TextTransparency = 0.45
	end

	clearGrid(showcaseGrid)
	local order = 0
	for _, id in sortedIds() do
		local owned = State.Items[id]
		if owned.S then
			order += 1
			local card = ItemVisual.card(owned, {
				LayoutOrder = order,
				OnClick = function()
					Actions.setShowcased(id, false)
				end,
			})
			Kit.label({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 22),
				Size = UDim2.new(1, 0, 0, 18),
				Text = `+{Format.cash(State.itemIncome(owned))}/s`,
				TextColor3 = Colors.Good,
				FontFace = Fonts.Bold,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = card,
			})
			card.Parent = showcaseGrid
		end
	end
	for _ = used + 1, State.ShowcaseSlots do
		order += 1
		Kit.new("Frame", {
			LayoutOrder = order,
			BackgroundColor3 = Colors.PanelLight,
			BackgroundTransparency = 0.4,
			Parent = showcaseGrid,
		}, {
			Kit.corner(10),
			Kit.stroke(Colors.Stroke, 1.5, 0.3),
			Kit.label({
				Size = UDim2.fromScale(1, 1),
				Text = "Empty slot",
				TextColor3 = Colors.SubText,
				TextXAlignment = Enum.TextXAlignment.Center,
			}),
		})
	end
end

local function render()
	if not window:isOpen() then
		return
	end
	for name, button in tabButtons do
		Kit.setButtonColor(button, if name == tab then Colors.Accent else Colors.PanelLighter)
	end
	itemsTab.Visible = tab == "Items"
	showcaseTab.Visible = tab == "Showcase"
	if tab == "Items" then
		renderItems()
	else
		renderShowcase()
	end
end

-- Construction ---------------------------------------------------------------------------------

local function makeGrid(parent: Instance, size: UDim2, position: UDim2): ScrollingFrame
	return Kit.new("ScrollingFrame", {
		Position = position,
		Size = size,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = parent,
	}, {
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(132, 168),
			CellPadding = UDim2.fromOffset(10, 30),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Kit.padding(4),
	})
end

local function buildItemsTab(content: Frame)
	itemsTab = Kit.new("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1,
		Parent = content,
	})
	local toolbar = Kit.new("Frame", {
		Size = UDim2.new(1, -290, 0, 40),
		BackgroundTransparency = 1,
		Parent = itemsTab,
	}, { Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })
	summaryLabel = Kit.label({
		LayoutOrder = 1,
		Size = UDim2.fromOffset(250, 40),
		TextSize = 16,
		TextColor3 = Colors.SubText,
		Parent = toolbar,
	})
	sortButton = Kit.button(
		{ LayoutOrder = 2, Size = UDim2.fromOffset(120, 36), TextSize = 16, Parent = toolbar },
		function()
			sortIndex = sortIndex % #SORTS + 1
			dirty = true
		end
	)
	tierButton = Kit.button(
		{ LayoutOrder = 3, Size = UDim2.fromOffset(140, 36), TextSize = 16, Parent = toolbar },
		function()
			sellTier = sellTier % #Catalog.Rarities + 1
			confirmUntil = 0
			dirty = true
		end
	)
	sellAllButton = Kit.button({
		LayoutOrder = 4,
		Size = UDim2.fromOffset(170, 36),
		TextSize = 15,
		BackgroundColor3 = Color3.fromRGB(34, 120, 74),
		Parent = toolbar,
	}, function()
		if os.clock() < confirmUntil then
			confirmUntil = 0
			local result = Actions.sellAll(sellTier)
			if result.ok then
				Toast.show(
					if result.Count > 0
						then `Sold {result.Count} items for {Format.cash(result.Total)}`
						else "Nothing to sell (locked and showcased items are kept).",
					if result.Count > 0 then "good" else "info"
				)
			end
		else
			confirmUntil = os.clock() + 4
			task.delay(4.1, function()
				dirty = true
			end)
		end
		dirty = true
	end)

	grid = makeGrid(itemsTab, UDim2.new(1, -290, 1, -50), UDim2.fromOffset(0, 50))
	details = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 274, 1, 0),
		BackgroundColor3 = Colors.PanelLight,
		Parent = itemsTab,
	})
end

local function buildShowcaseTab(content: Frame)
	showcaseTab = Kit.new("Frame", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = content,
	})
	incomeLabel = Kit.label({
		Size = UDim2.new(0.5, 0, 0, 32),
		FontFace = Fonts.Heavy,
		TextSize = 28,
		TextColor3 = Colors.Good,
		Parent = showcaseTab,
	})
	slotsLabel = Kit.label({
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(0.6, 0, 0, 20),
		TextSize = 15,
		TextColor3 = Colors.SubText,
		Parent = showcaseTab,
	})
	local buttons = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(420, 44),
		BackgroundTransparency = 1,
		Parent = showcaseTab,
	}, { Kit.list(Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Right) })
	Kit.button(
		{ LayoutOrder = 1, Size = UDim2.fromOffset(180, 44), Text = "Fill with best", Parent = buttons },
		function()
			Actions.showcaseBest()
		end
	)
	buySlotButton = Kit.button({
		LayoutOrder = 2,
		Size = UDim2.fromOffset(220, 44),
		BackgroundColor3 = Colors.GoldDeep,
		TextColor3 = Color3.fromRGB(20, 16, 8),
		Parent = buttons,
	}, function()
		local result = Actions.buySlot()
		if result.ok then
			Toast.show(`Showcase now has {result.Slots} slots`, "good")
		end
	end)
	Kit.label({
		Position = UDim2.fromOffset(0, 60),
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Showcased items pay cash every second, less per dollar the pricier they are. Tap one to take it out.",
		TextSize = 14,
		TextColor3 = Colors.SubText,
		Parent = showcaseTab,
	})
	showcaseGrid = makeGrid(showcaseTab, UDim2.new(1, 0, 1, -92), UDim2.fromOffset(0, 92))
end

function Inventory.open(startTab: string?)
	tab = startTab or tab
	window:open()
	dirty = true
end

function Inventory.toggle()
	if window:isOpen() then
		window:close()
	else
		Inventory.open()
	end
end

function Inventory.start()
	window = Window.create("Inventory", "Inventory", Vector2.new(1000, 600))
	local content = window.Content

	local tabs = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = content,
	}, { Kit.list(Enum.FillDirection.Horizontal, 8) })
	for order, name in { "Items", "Showcase" } do
		tabButtons[name] = Kit.button({
			LayoutOrder = order,
			Size = UDim2.fromOffset(150, 40),
			Text = name,
			Parent = tabs,
		}, function()
			tab = name
			dirty = true
		end)
	end

	buildItemsTab(content)
	buildShowcaseTab(content)

	window.OnOpen = function()
		dirty = true
	end

	State.Changed:Connect(function(kind)
		if kind == "Cash" then
			-- Only the showcase tab shows cash-dependent buttons.
			if tab == "Showcase" and window:isOpen() then
				local price = Showcase.SlotPrices[State.ShowcaseSlots - Showcase.BaseSlots + 1]
				if price then
					buySlotButton.TextTransparency = if State.Cash >= price then 0 else 0.45
				end
			end
			return
		end
		dirty = true
	end)

	-- Batch redraws: many changes in one frame (e.g. selling 200 items) redraw once.
	task.spawn(function()
		while true do
			task.wait(0.1)
			if dirty and window:isOpen() then
				dirty = false
				render()
			end
		end
	end)
end

return Inventory
