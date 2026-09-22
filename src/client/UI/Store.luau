--[[
	Robux store: gamepasses and cash packs. Case keys are sold in each case's preview,
	beside its odds.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Monetization = require(Shared.Config.Monetization)

local State = require(script.Parent.Parent.State)
local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Theme)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local Store = {}

local window: Window.Window
local scroller: ScrollingFrame
local prices: { [string]: number } = {}

local function fetchPrice(key: string, id: number, infoType: Enum.InfoType)
	if prices[key] or id == 0 then
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		if ok and info and info.PriceInRobux then
			prices[key] = info.PriceInRobux
			if window:isOpen() then
				Store.render()
			end
		end
	end)
end

local function card(parent: Instance, order: number, icon: string, title: string, body: string): Frame
	local frame = Kit.new("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Colors.PanelLight,
		Parent = parent,
	}, { Kit.corner(12), Kit.stroke(Colors.Stroke, 1.5), Kit.padding(12) })
	Kit.label({
		Size = UDim2.fromOffset(44, 44),
		Text = icon,
		TextScaled = true,
		Parent = frame,
	})
	Kit.label({
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.new(1, -54, 0, 24),
		Text = title,
		FontFace = Fonts.Heavy,
		TextSize = 20,
		Parent = frame,
	})
	Kit.label({
		Position = UDim2.fromOffset(54, 26),
		Size = UDim2.new(1, -54, 0, 44),
		Text = body,
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = Colors.SubText,
		Parent = frame,
	})
	return frame
end

local function buyButton(parent: Frame, text: string, enabled: boolean, onClick: () -> ())
	local button = Kit.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 38),
		Text = text,
		BackgroundColor3 = if enabled then Color3.fromRGB(34, 120, 74) else Colors.PanelLighter,
		TextColor3 = if enabled then Colors.Text else Colors.SubText,
		Parent = parent,
	}, function()
		if enabled then
			onClick()
		end
	end)
	button.Active = enabled
end

local function section(order: number, text: string): Frame
	Kit.label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 30),
		Text = text,
		FontFace = Fonts.Heavy,
		TextSize = 22,
		TextColor3 = Colors.Gold,
		Parent = scroller,
	})
	return Kit.new("Frame", {
		LayoutOrder = order + 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = scroller,
	}, {
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(250, 150),
			CellPadding = UDim2.fromOffset(12, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function Store.render()
	for _, child in scroller:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local studio = RunService:IsStudio()
	local player = Players.LocalPlayer
	local shown = 0

	local passGrid = section(1, "Game Passes")
	for order, pass in Monetization.Passes do
		if pass.PassId ~= 0 or studio then
			shown += 1
			local frame = card(passGrid, order, pass.Icon, pass.Name, pass.Description)
			if State.hasPass(pass.Key) then
				buyButton(frame, "Owned ✓", false, function() end)
			elseif pass.PassId == 0 then
				buyButton(frame, "Set PassId in Config", false, function() end)
			else
				local key = "pass" .. pass.PassId
				fetchPrice(key, pass.PassId, Enum.InfoType.GamePass)
				buyButton(frame, if prices[key] then `R$ {prices[key]}` else "R$ …", true, function()
					MarketplaceService:PromptGamePassPurchase(player, pass.PassId)
				end)
			end
		end
	end

	local showcaseIncome = math.max(State.Income - GameConfig.Showcase.BaseIncome, 0)
	local cashGrid = section(3, "Cash")
	for order, pack in Monetization.CashPacks do
		if pack.ProductId ~= 0 or studio then
			shown += 1
			local amount = math.floor(math.max(pack.Cash, showcaseIncome * 60 * pack.IncomeMinutes))
			local frame = card(
				cashGrid,
				order,
				pack.Icon,
				`+{Format.cash(amount)}`,
				`{pack.Name}: {Format.cash(pack.Cash)} or {pack.IncomeMinutes} min of showcase income, whichever is more.`
			)
			if pack.ProductId == 0 then
				buyButton(frame, "Set ProductId in Config", false, function() end)
			else
				local key = "product" .. pack.ProductId
				fetchPrice(key, pack.ProductId, Enum.InfoType.Product)
				buyButton(frame, if prices[key] then `R$ {prices[key]}` else "R$ …", true, function()
					MarketplaceService:PromptProductPurchase(player, pack.ProductId)
				end)
			end
		end
	end

	Kit.label({
		LayoutOrder = 10,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = if shown == 0
			then "Nothing for sale yet."
			else "Case keys are sold inside each case's preview, right next to its full odds.",
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextSize = 15,
		TextColor3 = Colors.SubText,
		Parent = scroller,
	})
end

function Store.open()
	window:open()
end

function Store.toggle()
	if window:isOpen() then
		window:close()
	else
		window:open()
	end
end

function Store.start()
	window = Window.create("Store", "Store", Vector2.new(820, 560))
	scroller = Kit.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Colors.Stroke,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = window.Content,
	}, { Kit.list(Enum.FillDirection.Vertical, 10) })
	window.OnOpen = Store.render

	State.Changed:Connect(function(kind)
		if window:isOpen() and (kind == "Passes" or kind == "Income") then
			Store.render()
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, _, purchased)
		if purchased then
			task.wait(1)
			if window:isOpen() then
				Store.render()
			end
		end
	end)
end

return Store
