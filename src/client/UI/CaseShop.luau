--[[
	The case menu opened from the stall: a grid of cases, then a preview with the open
	buttons and every odd (rarity, item, brand, mutation) the server rolls with.

	Roblox requires odds to be shown before any paid random item is bought, so the Robux
	key button lives only here, next to the full odds list.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)

local State = require(script.Parent.Parent.State)
local ItemVisual = require(script.Parent.ItemVisual)
local Kit = require(script.Parent.Kit)
local Spinner = require(script.Parent.Spinner)
local Theme = require(script.Parent.Theme)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local CaseShop = {}

local window: Window.Window
local listView: ScrollingFrame
local previewView: Frame
local previewLeft: Frame
local previewOdds: ScrollingFrame
local selected: Catalog.Case? = nil
local openCount = 1
local robuxPrices: { [number]: number } = {}

-- Redraws are skipped when nothing the player can see has changed (cash ticks every second).
local listSignature = ""
local leftSignature = ""

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

local function renderList(force: boolean?)
	local parts = {}
	for _, case in Catalog.Cases do
		table.insert(parts, `{State.Cash >= case.Price}{State.keysFor(case.Id)}`)
	end
	local signature = table.concat(parts, ",")
	if signature == listSignature and not force then
		return
	end
	listSignature = signature

	for _, child in listView:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for index, case in Catalog.Cases do
		local card = Kit.new("TextButton", {
			LayoutOrder = index,
			BackgroundColor3 = Colors.PanelLight,
			AutoButtonColor = false,
			Text = "",
			Parent = listView,
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
		local bubble = iconBubble(case, 108, card)
		bubble.Position = UDim2.new(0.5, 0, 0, 16)
		Kit.label({
			Position = UDim2.fromOffset(10, 134),
			Size = UDim2.new(1, -20, 0, 26),
			Text = case.Name,
			FontFace = Fonts.Heavy,
			TextSize = 21,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		local affordable = State.Cash >= case.Price or State.keysFor(case.Id) > 0
		Kit.label({
			Position = UDim2.fromOffset(10, 162),
			Size = UDim2.new(1, -20, 0, 28),
			Text = Format.cash(case.Price),
			FontFace = Fonts.Heavy,
			TextSize = 24,
			TextColor3 = if affordable then Colors.Gold else Colors.Bad,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		local keys = State.keysFor(case.Id)
		Kit.label({
			Position = UDim2.fromOffset(10, 194),
			Size = UDim2.new(1, -20, 0, 20),
			Text = if keys > 0 then `🔑 {keys} key{if keys == 1 then "" else "s"}` else "Tap to preview",
			TextSize = 15,
			TextColor3 = if keys > 0 then Colors.Gold else Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		card.Activated:Connect(function()
			CaseShop.preview(case)
		end)
	end
end

-- Preview --------------------------------------------------------------------------------------

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

	local rarityOdds = Catalog.rarityOdds(case, luck.Gem)
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
			Text = rarity.Name .. (if Catalog.isGem(case, entry.Id) then "   💎 behind the gem" else ""),
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

	sectionTitle(scroller, nextOrder(), "Items")
	for i = #rarityOdds, 1, -1 do
		local entry = rarityOdds[i]
		local rarity = Catalog.RarityById[entry.Id]
		local items = Catalog.ItemsByRarity[entry.Id]
		for j = #items, 1, -1 do
			local item = items[j]
			local r = row(scroller, nextOrder(), 58)
			r.AutomaticSize = Enum.AutomaticSize.Y
			Kit.new("Frame", {
				Position = UDim2.fromOffset(8, 7),
				Size = UDim2.fromOffset(44, 44),
				BackgroundColor3 = rarity.Color,
				BackgroundTransparency = 0.82,
				Parent = r,
			}, { Kit.corner(8), ItemVisual.icon(item.Id, { Size = UDim2.fromScale(0.8, 0.8) }) })
			Kit.label({
				Position = UDim2.fromOffset(62, 6),
				Size = UDim2.new(1, -200, 0, 22),
				Text = item.Name,
				FontFace = Fonts.Bold,
				TextColor3 = rarity.Color,
				Parent = r,
			})
			local brandParts = {}
			for _, brand in Catalog.brandOdds(item) do
				table.insert(brandParts, `{Catalog.Brands[brand.Id].Name} {Format.chance(brand.P)}`)
			end
			Kit.label({
				Position = UDim2.fromOffset(62, 29),
				Size = UDim2.new(1, -200, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = table.concat(brandParts, "  ·  "),
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
				Text = Format.chance(entry.P * Catalog.itemShare(item)),
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
	end

	sectionTitle(scroller, nextOrder(), "Mutations (rolled on every item)")
	local mutationOdds = Catalog.mutationOdds(luck.Mutation)
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

	Kit.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "Item chance = rarity chance × the item's share of that rarity. The brand is picked "
			.. "after the item, then every item rolls for a mutation on its own. "
			.. (
				if State.LuckLevel > 0 or State.hasPass("Luck")
					then `Odds shown include your luck (level {State.LuckLevel}{if State.hasPass("Luck")
						then " + 2x Luck pass"
						else ""}).`
					else ""
			),
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextColor3 = Colors.SubText,
		Parent = scroller,
	})
end

local function fetchRobuxPrice(productId: number, onLoaded: () -> ())
	if robuxPrices[productId] then
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			robuxPrices[productId] = info.PriceInRobux
			onLoaded()
		end
	end)
end

local renderLeft: (boolean?) -> ()

renderLeft = function(force: boolean?)
	local case = selected
	if not case then
		return
	end
	local keys = State.keysFor(case.Id)
	local maxOpen = State.maxOpen()
	openCount = math.min(openCount, maxOpen)
	local canAfford = State.canAfford(case, openCount)
	local price = robuxPrices[case.Robux.ProductId]
	local signature = `{case.Id}|{keys}|{maxOpen}|{openCount}|{canAfford}|{price}`
	if signature == leftSignature and not force then
		return
	end
	leftSignature = signature

	local left = previewLeft
	for _, child in left:GetChildren() do
		if not child:IsA("UICorner") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

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
		Text = `{Format.cash(case.Price)} per case` .. (if keys > 0 then `   •   🔑 {keys} (used first)` else ""),
		TextColor3 = Colors.Gold,
		FontFace = Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = left,
	})

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
		Kit.button({
			Position = UDim2.fromOffset(0, 378),
			Size = UDim2.new(1, 0, 0, 44),
			Text = `Buy {case.Robux.Keys} key{if case.Robux.Keys == 1 then "" else "s"}   {if price
				then "R$ " .. price
				else "R$ …"}`,
			BackgroundColor3 = Color3.fromRGB(34, 120, 74),
			TextSize = 18,
			Parent = left,
		}, function()
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, case.Robux.ProductId)
		end)
		fetchRobuxPrice(case.Robux.ProductId, function()
			renderLeft()
		end)
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
	listView = Kit.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = window.Content,
	}, {
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(206, 230),
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
		elseif kind == "Cash" or kind == "Keys" then
			if selected then
				renderLeft()
			else
				renderList()
			end
		end
	end)
end

return CaseShop
