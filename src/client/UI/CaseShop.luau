--[[
	The case menu opened from the stall: tabs of cases (All / Mixed / Themed / Robux), then a
	preview with the open buttons and every odd (item, brand, mutation) the server rolls with.

	Roblox requires odds to be shown before any paid random item is bought, so every Robux
	button (case purchase or key bundle) lives only here, next to the full odds list.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)

local Actions = require(script.Parent.Parent.Actions)
local State = require(script.Parent.Parent.State)
local ItemVisual = require(script.Parent.ItemVisual)
local Kit = require(script.Parent.Kit)
local Spinner = require(script.Parent.Spinner)
local Theme = require(script.Parent.Theme)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local TABS = { "All", "Mixed", "Themed", "Robux" }
local ROBUX_GREEN = Color3.fromRGB(34, 140, 74)

local CaseShop = {}

local window: Window.Window
local listView: Frame
local listGrid: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local previewView: Frame
local previewLeft: Frame
local previewOdds: ScrollingFrame
local selected: Catalog.Case? = nil
local tab = "All"
local openCount = 1
local keyPrices: { [number]: number } = {}

-- Redraws are skipped when nothing the player can see has changed (cash ticks every second).
local listSignature = ""
local leftSignature = ""

local function soldOut(case: Catalog.Case): boolean
	if not case.Limited then
		return false
	end
	for _, entry in case.Entries do
		if (State.remaining(entry.Item) or 1) > 0 then
			return false
		end
	end
	return true
end

local function priceText(case: Catalog.Case): string
	return if case.Paid then `R$ {Actions.robuxPrice(case)}` else Format.cash(case.Price)
end

-- Case grid ------------------------------------------------------------------------------------

local function iconBubble(case: Catalog.Case, size: number, parent: Instance): Frame
	local bubble = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = case.Color,
		BackgroundTransparency = 0.78,
		Parent = parent,
	}, { Kit.round(), Kit.stroke(case.Color, 2, 0.3) })
	local visual = if case.Image ~= ""
		then Kit.new("ImageLabel", { Image = case.Image, ScaleType = Enum.ScaleType.Fit })
		else Kit.label({ Text = case.Icon, TextScaled = true, TextXAlignment = Enum.TextXAlignment.Center })
	visual.AnchorPoint = Vector2.new(0.5, 0.5)
	visual.Position = UDim2.fromScale(0.5, 0.5)
	visual.Size = UDim2.fromScale(0.62, 0.62)
	visual.BackgroundTransparency = 1
	visual.Parent = bubble
	return bubble
end

local function badge(parent: Instance, text: string, color: Color3)
	local label = Kit.label({
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(78, 20),
		BackgroundTransparency = 0,
		BackgroundColor3 = color,
		Text = text,
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = Color3.fromRGB(16, 16, 22),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.round().Parent = label
end

local function renderList(force: boolean?)
	local parts = { tab }
	for _, case in Catalog.Cases do
		table.insert(parts, `{State.Cash >= case.Price}{State.keysFor(case.Id)}{soldOut(case)}`)
	end
	local signature = table.concat(parts, ",")
	if signature == listSignature and not force then
		return
	end
	listSignature = signature

	for name, button in tabButtons do
		Kit.setButtonColor(button, if name == tab then Colors.Accent else Colors.PanelLighter)
	end
	for _, child in listGrid:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	for index, case in Catalog.Cases do
		if tab ~= "All" and case.Kind ~= tab then
			continue
		end
		local card = Kit.new("TextButton", {
			LayoutOrder = index,
			BackgroundColor3 = Colors.PanelLight,
			AutoButtonColor = false,
			Text = "",
			Parent = listGrid,
		}, {
			Kit.corner(14),
			Kit.stroke(case.Color, 2, 0.45),
			Kit.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = case.Color,
			}, {
				Kit.corner(14),
				Kit.new("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.6, 0.92),
						NumberSequenceKeypoint.new(1, 0.7),
					}),
				}),
			}),
		})
		if case.Limited then
			badge(card, "LIMITED", Catalog.RarityById.Limited.Color)
		elseif case.Paid then
			badge(card, "NUMBERED", Colors.Gold)
		end

		local bubble = iconBubble(case, 96, card)
		bubble.Position = UDim2.new(0.5, 0, 0, 16)
		Kit.label({
			Position = UDim2.fromOffset(10, 120),
			Size = UDim2.new(1, -20, 0, 26),
			Text = case.Name,
			FontFace = Fonts.Heavy,
			TextSize = 21,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		Kit.label({
			Position = UDim2.fromOffset(10, 146),
			Size = UDim2.new(1, -20, 0, 18),
			Text = case.Theme,
			TextSize = 14,
			TextColor3 = case.Color:Lerp(Colors.Text, 0.4),
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})

		local affordable = case.Paid ~= nil or State.Cash >= case.Price or State.keysFor(case.Id) > 0
		Kit.label({
			Position = UDim2.fromOffset(10, 168),
			Size = UDim2.new(1, -20, 0, 28),
			Text = if soldOut(case) then "SOLD OUT" else priceText(case),
			FontFace = Fonts.Heavy,
			TextSize = 24,
			TextColor3 = if case.Paid
				then Color3.fromRGB(90, 230, 130)
				elseif affordable then Colors.Gold
				else Colors.Bad,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		local keys = State.keysFor(case.Id)
		Kit.label({
			Position = UDim2.fromOffset(10, 198),
			Size = UDim2.new(1, -20, 0, 18),
			Text = if keys > 0
				then `🔑 {keys} key{if keys == 1 then "" else "s"}`
				else `{#case.Entries} items  •  gem {Format.oneIn(
					Catalog.gemChance(case, State.luck().Gem, State.luck().Boosted)
				)}`,
			TextSize = 14,
			TextColor3 = if keys > 0 then Colors.Gold else Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		card.Activated:Connect(function()
			CaseShop.preview(case)
		end)
	end
end

-- Preview: odds list ---------------------------------------------------------------------------

local function sectionTitle(parent: Instance, order: number, text: string)
	Kit.label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 30),
		Text = text,
		FontFace = Fonts.Heavy,
		TextSize = 20,
		TextColor3 = Colors.Gold,
		Parent = parent,
	})
end

local function row(parent: Instance, order: number, height: number): Frame
	return Kit.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = Colors.PanelLight,
		Parent = parent,
	}, { Kit.corner(8) })
end

local function renderOdds(case: Catalog.Case, scroller: ScrollingFrame)
	local luck = State.luck()
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local rarityOdds = Catalog.rarityOdds(case, luck.Gem, luck.Boosted)
	sectionTitle(scroller, nextOrder(), "Rarity odds")
	for i = #rarityOdds, 1, -1 do
		local entry = rarityOdds[i]
		local rarity = Catalog.RarityById[entry.Id]
		local r = row(scroller, nextOrder(), 34)
		Kit.new("Frame", {
			Position = UDim2.fromOffset(10, 9),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = rarity.Color,
			Parent = r,
		}, { Kit.corner(4) })
		Kit.label({
			Position = UDim2.fromOffset(36, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
			Text = rarity.Name .. (if Catalog.isGem(case, entry.Id) then "   💎 gem" else ""),
			FontFace = Fonts.Bold,
			TextColor3 = rarity.Color,
			Parent = r,
		})
		Kit.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.35, 0, 1, 0),
			Text = Format.chance(entry.P),
			FontFace = Fonts.Heavy,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = r,
		})
	end

	sectionTitle(scroller, nextOrder(), `Items ({#case.Entries})`)
	local soldOutItems = {}
	for _, entry in case.Entries do
		if State.remaining(entry.Item) == 0 then
			soldOutItems[entry.Item.Id] = true
		end
	end
	local entries = Catalog.caseOdds(case, luck.Gem, soldOutItems, luck.Boosted)
	table.sort(entries, function(a, b)
		return a.Item.Value > b.Item.Value
	end)
	for _, entry in entries do
		local item = entry.Item
		local rarity = Catalog.RarityById[item.Rarity]
		local r = row(scroller, nextOrder(), 58)
		r.AutomaticSize = Enum.AutomaticSize.Y
		Kit.new("Frame", {
			Position = UDim2.fromOffset(8, 7),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.82,
			Parent = r,
		}, { Kit.corner(8), ItemVisual.icon(item.Id, { Size = UDim2.fromScale(0.8, 0.8) }) })
		-- Rare rows stand out: outlined in the rarity colour, grails in their animated colours.
		if rarity.Fx >= 3 then
			local stroke = Kit.stroke(if rarity.Gradient then Color3.new(1, 1, 1) else rarity.Color, 1.5)
			stroke.Parent = r
			if rarity.Gradient then
				Kit.gradient(rarity.Gradient, 0).Parent = stroke
			end
		end
		Kit.label({
			Position = UDim2.fromOffset(62, 6),
			Size = UDim2.new(1, -200, 0, 22),
			Text = (if entry.Grail then "🏆 " elseif entry.Gem then "💎 " else "") .. item.Name,
			FontFace = Fonts.Bold,
			TextColor3 = rarity.Color,
			Parent = r,
		})

		local detail
		if #item.Brands > 1 then
			local brandParts = {}
			for _, brand in Catalog.brandOdds(item) do
				table.insert(brandParts, `{Catalog.Brands[brand.Id].Name} {Format.chance(brand.P)}`)
			end
			detail = table.concat(brandParts, "  ·  ")
		else
			detail = `{Catalog.Brands[item.Brands[1]].Name}  •  {rarity.Name}`
		end
		local remaining = State.remaining(item)
		if remaining then
			detail ..= `  •  {Format.commas(remaining)} / {Format.commas(item.Supply :: number)} left`
		elseif item.Exclusive then
			detail ..= `  •  numbered, {Format.commas(State.Serials[item.Id] or 0)} pulled`
		end
		if entry.Grail then
			detail ..= "  •  grail: fixed odds, luck doesn't change them"
		end
		Kit.label({
			Position = UDim2.fromOffset(62, 29),
			Size = UDim2.new(1, -200, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = detail,
			TextSize = 14,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextColor3 = Colors.SubText,
			Parent = r,
		})
		Kit.new("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = r })
		local low, high = Catalog.valueRange(item)
		Kit.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 6),
			Size = UDim2.fromOffset(130, 22),
			Text = Format.chance(entry.P),
			FontFace = Fonts.Heavy,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = r,
		})
		Kit.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 29),
			Size = UDim2.fromOffset(130, 18),
			Text = if low == high then Format.cash(low) else `{Format.cash(low)} – {Format.cash(high)}`,
			TextSize = 15,
			TextColor3 = Colors.Gold,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = r,
		})
	end
	for id in soldOutItems do
		local item = Catalog.ItemById[id]
		local r = row(scroller, nextOrder(), 34)
		Kit.label({
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 1, 0),
			Text = `SOLD OUT  •  {item.Name}  •  all {Format.commas(item.Supply :: number)} claimed`,
			FontFace = Fonts.Bold,
			TextColor3 = Colors.SubText,
			Parent = r,
		})
	end

	sectionTitle(
		scroller,
		nextOrder(),
		if case.GuaranteedMutation then "Mutations (guaranteed on every item)" else "Mutations (rolled on every item)"
	)
	local mutationOdds = Catalog.mutationOdds(luck.Mutation, case.GuaranteedMutation)
	for i = #mutationOdds, 1, -1 do
		local entry = mutationOdds[i]
		local mutation = Catalog.MutationById[entry.Id]
		local r = row(scroller, nextOrder(), 34)
		Kit.new("Frame", {
			Position = UDim2.fromOffset(10, 9),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = mutation.Color,
			Parent = r,
		}, { Kit.round() })
		Kit.label({
			Position = UDim2.fromOffset(36, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Text = `{mutation.Name}  {Format.mult(mutation.Mult)} value`,
			FontFace = Fonts.Bold,
			TextColor3 = mutation.Color,
			Parent = r,
		})
		Kit.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Text = `{Format.oneIn(entry.P)}  ({Format.chance(entry.P)})`,
			FontFace = Fonts.Heavy,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = r,
		})
	end

	local notes = {
		"💎 items hide behind the gem: the reel lands on the gem first, then re-spins through them.",
		"The brand is picked after the item; then the item rolls for a mutation on its own.",
	}
	if case.Paid then
		table.insert(notes, "Every item from this case gets a serial number, shared across all servers.")
	end
	if case.Limited then
		table.insert(
			notes,
			"Limited: each item has a fixed supply. Sold-out items are removed and the rest share their odds."
		)
	end
	if luck.Gem > 1 or luck.Mutation > 1 then
		table.insert(
			notes,
			`Odds include your luck: gems {Format.mult(luck.Gem)}, mutations {Format.mult(luck.Mutation)}`
				.. (if State.boostMult() > 1 then ` (incl. a {Format.mult(State.boostMult())} boost right now)` else "")
				.. ". Each case caps how far luck can raise its gem odds."
		)
	end
	Kit.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = table.concat(notes, "\n"),
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextColor3 = Colors.SubText,
		Parent = scroller,
	})
end

-- Preview: left panel ---------------------------------------------------------------------------

local function fetchKeyPrice(productId: number, onLoaded: () -> ())
	if keyPrices[productId] then
		return
	end
	keyPrices[productId] = 0
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			keyPrices[productId] = info.PriceInRobux
			onLoaded()
		end
	end)
end

local renderLeft: (boolean?) -> ()

local function leftHeader(case: Catalog.Case, left: Frame, subtitle: string)
	Kit.button({
		Size = UDim2.fromOffset(110, 32),
		Text = "← Cases",
		TextSize = 16,
		Parent = left,
	}, function()
		CaseShop.showList()
	end)
	local bubble = iconBubble(case, 120, left)
	bubble.Position = UDim2.new(0.5, 0, 0, 44)
	Kit.label({
		Position = UDim2.fromOffset(0, 172),
		Size = UDim2.new(1, 0, 0, 32),
		Text = case.Name,
		FontFace = Fonts.Heavy,
		TextSize = 26,
		TextColor3 = case.Color,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
	Kit.label({
		Position = UDim2.fromOffset(0, 204),
		Size = UDim2.new(1, 0, 0, 22),
		Text = subtitle,
		TextColor3 = Colors.Gold,
		FontFace = Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})
end

local function renderPaidLeft(case: Catalog.Case, left: Frame)
	local paid = case.Paid :: { ProductId: number, Robux: number }
	local isSoldOut = soldOut(case)
	leftHeader(case, left, `{case.Theme}  •  guaranteed mutation`)
	Kit.label({
		Position = UDim2.fromOffset(0, 236),
		Size = UDim2.new(1, 0, 0, 60),
		Text = if case.Limited
			then "Every item is Limited: a fixed number will ever exist, and each copy is numbered."
			else "Every item is exclusive to this case and numbered in the order it's pulled.",
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Colors.SubText,
		Parent = left,
	})

	local onSale = paid.ProductId ~= 0 and not isSoldOut
	local buy = Kit.button({
		Position = UDim2.fromOffset(0, 310),
		Size = UDim2.new(1, 0, 0, 58),
		Text = if isSoldOut
			then "SOLD OUT"
			elseif paid.ProductId == 0 then "Not on sale yet"
			else `OPEN  R$ {Actions.robuxPrice(case)}`,
		FontFace = Fonts.Heavy,
		TextSize = 22,
		BackgroundColor3 = if onSale then ROBUX_GREEN else Colors.PanelLighter,
		TextColor3 = if onSale then Colors.Text else Colors.SubText,
		Parent = left,
	}, function()
		if onSale then
			Spinner.run(case, 1, "robux")
			CaseShop.preview(case)
		end
	end)
	buy.Active = onSale

	if State.Debug then
		Kit.button({
			Position = UDim2.fromOffset(0, 378),
			Size = UDim2.new(1, 0, 0, 40),
			Text = "🛠️ Test open (dev, free)",
			TextSize = 16,
			Parent = left,
		}, function()
			Spinner.run(case, 1, "devrobux")
			CaseShop.preview(case)
		end)
	elseif paid.ProductId == 0 and RunService:IsStudio() then
		Kit.label({
			Position = UDim2.fromOffset(0, 378),
			Size = UDim2.new(1, 0, 0, 40),
			Text = "Set Paid.ProductId in Config/Cases.luau",
			TextSize = 13,
			TextColor3 = Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = left,
		})
	end
end

local function renderCashLeft(case: Catalog.Case, left: Frame)
	local keys = State.keysFor(case.Id)
	local maxOpen = State.maxOpen()
	leftHeader(
		case,
		left,
		`{Format.cash(case.Price)} per case` .. (if keys > 0 then `   •   🔑 {keys} (used first)` else "")
	)

	local selector = Kit.new("Frame", {
		Position = UDim2.fromOffset(0, 238),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Parent = left,
	}, { Kit.list(Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center) })
	for count = 1, 5 do
		local locked = count > maxOpen
		local button = Kit.button({
			LayoutOrder = count,
			Size = UDim2.fromOffset(48, 44),
			Text = if locked then "🔒" else `×{count}`,
			BackgroundColor3 = if count == openCount then Colors.Accent else Colors.PanelLighter,
			Parent = selector,
		}, function()
			if count > State.maxOpen() then
				return
			end
			openCount = count
			renderLeft()
		end)
		button.TextTransparency = if locked then 0.4 else 0
	end
	if maxOpen < 5 then
		Kit.label({
			Position = UDim2.fromOffset(0, 284),
			Size = UDim2.new(1, 0, 0, 18),
			Text = "Multi Open+ pass unlocks ×4 and ×5",
			TextSize = 13,
			TextColor3 = Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = left,
		})
	end

	local useKeys = math.min(keys, openCount)
	local cost = (openCount - useKeys) * case.Price
	local canAfford = State.canAfford(case, openCount)
	local openButton = Kit.button({
		Position = UDim2.fromOffset(0, 310),
		Size = UDim2.new(1, 0, 0, 58),
		Text = if canAfford
			then `OPEN ×{openCount}   {if cost > 0 then Format.cash(cost) else "FREE"}`
			else `Need {Format.cash(cost)}`,
		FontFace = Fonts.Heavy,
		TextSize = 22,
		BackgroundColor3 = if canAfford then Colors.GoldDeep else Colors.PanelLighter,
		TextColor3 = if canAfford then Color3.fromRGB(20, 16, 8) else Colors.SubText,
		Parent = left,
	}, function()
		if not State.canAfford(case, openCount) then
			return
		end
		Spinner.run(case, openCount)
		CaseShop.preview(case)
	end)
	openButton.Active = canAfford

	if case.Robux.ProductId ~= 0 then
		local price = keyPrices[case.Robux.ProductId]
		Kit.button({
			Position = UDim2.fromOffset(0, 378),
			Size = UDim2.new(1, 0, 0, 44),
			Text = `Buy {case.Robux.Keys} key{if case.Robux.Keys == 1 then "" else "s"}   {if price
					and price > 0
				then "R$ " .. price
				else "R$ …"}`,
			BackgroundColor3 = ROBUX_GREEN,
			TextSize = 18,
			Parent = left,
		}, function()
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, case.Robux.ProductId)
		end)
		fetchKeyPrice(case.Robux.ProductId, function()
			renderLeft(true)
		end)
	end
end

renderLeft = function(force: boolean?)
	local case = selected
	if not case then
		return
	end
	openCount = math.min(openCount, State.maxOpen())
	local signature = if case.Paid
		then `{case.Id}|{soldOut(case)}|{Actions.robuxPrice(case)}|{State.Debug}`
		else `{case.Id}|{State.keysFor(case.Id)}|{State.maxOpen()}|{openCount}|{State.canAfford(case, openCount)}`
	if signature == leftSignature and not force then
		return
	end
	leftSignature = signature

	for _, child in previewLeft:GetChildren() do
		if not child:IsA("UICorner") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	if case.Paid then
		renderPaidLeft(case, previewLeft)
	else
		renderCashLeft(case, previewLeft)
	end
end

local function renderPreview()
	local case = selected
	if not case then
		return
	end
	previewView:ClearAllChildren()
	previewLeft = Kit.new("Frame", {
		Size = UDim2.new(0, 300, 1, 0),
		BackgroundColor3 = Colors.PanelLight,
		Parent = previewView,
	}, { Kit.corner(12), Kit.padding(14) })
	previewOdds = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(316, 0),
		Size = UDim2.new(1, -316, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = previewView,
	}, { Kit.list(Enum.FillDirection.Vertical, 6) })
	renderLeft(true)
	renderOdds(case, previewOdds)
end

-- Public -----------------------------------------------------------------------------------------

function CaseShop.showList()
	selected = nil
	window.Title.Text = "Vermeil Exchange"
	previewView.Visible = false
	listView.Visible = true
	renderList(true)
end

function CaseShop.preview(case: Catalog.Case)
	selected = case
	window.Title.Text = case.Name
	listView.Visible = false
	previewView.Visible = true
	openCount = math.min(openCount, State.maxOpen())
	renderPreview()
	window:open()
end

function CaseShop.open()
	if Spinner.isBusy() then
		return
	end
	CaseShop.showList()
	window:open()
end

function CaseShop.start()
	window = Window.create("CaseShop", "Vermeil Exchange", Vector2.new(940, 600))
	listView = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = window.Content,
	})
	local tabs = Kit.new("Frame", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 1,
		Parent = listView,
	}, { Kit.list(Enum.FillDirection.Horizontal, 8) })
	for order, name in TABS do
		tabButtons[name] = Kit.button({
			LayoutOrder = order,
			Size = UDim2.fromOffset(120, 38),
			Text = name,
			TextSize = 17,
			Parent = tabs,
		}, function()
			tab = name
			renderList(true)
		end)
	end
	listGrid = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = listView,
	}, {
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(206, 226),
			CellPadding = UDim2.fromOffset(14, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Kit.padding(4),
	})
	previewView = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = window.Content,
	})

	State.Changed:Connect(function(kind)
		if not window:isOpen() then
			return
		end
		if kind == "Passes" or kind == "State" or kind == "Luck" then
			-- Luck changes the odds list itself.
			if selected then
				renderPreview()
			else
				renderList(true)
			end
		elseif kind == "PersonalLuck" or kind == "LuckBar" or kind == "ServerLuck" then
			if selected then
				renderPreview()
			else
				renderList(true)
			end
		elseif kind == "Cash" or kind == "Keys" or kind == "Serials" then
			if selected then
				renderLeft()
			else
				renderList()
			end
		end
	end)
end

return CaseShop
