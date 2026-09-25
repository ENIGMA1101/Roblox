--[[
	Luck on the HUD:
	- Bottom: the luck bar. Fills by one per item opened; when full the next open gets 10x luck.
	- Right: the personal luck stack (Robux, permanent, 2x then +2x each buy) and the server
	  luck button with its three timed boosts.
	- Top: a banner while server luck is running.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Monetization = require(Shared.Config.Monetization)

local Actions = require(script.Parent.Parent.Actions)
local State = require(script.Parent.Parent.State)
local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local LUCK_GREEN = Color3.fromRGB(80, 220, 120)
local ROBUX_GREEN = Color3.fromRGB(34, 140, 74)

local LuckHud = {}

local barFill: Frame
local barLabel: TextLabel
local barStroke: UIStroke
local personalMult: TextLabel
local personalPrice: TextLabel
local serverButtonLabel: TextLabel
local serverPanel: Frame
local banner: Frame
local bannerLabel: TextLabel

local function refreshBar()
	local fill = GameConfig.LuckBar.RollsToFill
	local full = State.barFull()
	Kit.tween(barFill, 0.25, { Size = UDim2.fromScale(math.clamp(State.LuckBar / fill, 0, 1), 1) })
	barFill.BackgroundColor3 = if full then Colors.Gold else LUCK_GREEN
	barStroke.Color = if full then Colors.Gold else Colors.Stroke
	barLabel.Text = if full
		then `🍀 {GameConfig.LuckBar.Mult}x LUCK READY: your next open is boosted!`
		else `🍀 Luck bar  {State.LuckBar} / {fill}  •  {GameConfig.LuckBar.Mult}x luck when full`
end

local function refreshPersonal()
	local buys = State.PersonalLuck
	personalMult.Text = `{Format.mult(Catalog.personalLuckMult(buys + 1))}`
	local price = Catalog.personalLuckPrice(buys)
	personalPrice.Text = if price then `R$ {price}` else "MAX"
end

local function refreshServer()
	local mult = State.serverLuckMult()
	local now = State.serverNow()
	local remaining = 0
	for _, boost in State.ServerLuck.Boosts do
		if boost.Mult == mult and boost.EndsAt > now then
			remaining = boost.EndsAt - now
		end
	end
	banner.Visible = mult > 1
	if mult > 1 then
		bannerLabel.Text = `🍀 {mult}x SERVER LUCK  •  {Format.clock(remaining)}`
		serverButtonLabel.Text = `{mult}x`
	else
		serverButtonLabel.Text = "Server"
	end
end

local function build()
	local layer = Root.layer("Hud")

	-- Bottom luck bar
	local bar = Kit.new("Frame", {
		Name = "LuckBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(460, 34),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = layer,
	}, { Kit.round() })
	barStroke = Kit.stroke(Colors.Stroke, 2)
	barStroke.Parent = bar
	local track = Kit.new("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = bar,
	}, { Kit.round() })
	barFill = Kit.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = LUCK_GREEN,
		Parent = track,
	}, { Kit.round() })
	barLabel = Kit.label({
		Size = UDim2.fromScale(1, 1),
		TextSize = 16,
		FontFace = Fonts.Heavy,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = bar,
	})
	Kit.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Transparency = 0.3, Parent = barLabel })

	-- Right column
	local right = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(92, 200),
		BackgroundTransparency = 1,
		Parent = layer,
	}, { Kit.list(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center) })

	local personal = Kit.button({
		LayoutOrder = 1,
		Size = UDim2.fromOffset(92, 92),
		Text = "",
		BackgroundColor3 = Colors.Panel,
		Parent = right,
	}, function()
		Actions.buyPersonalLuck(State.PersonalLuck)
	end)
	Kit.stroke(LUCK_GREEN, 2).Parent = personal
	Kit.label({
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, 0, 0, 30),
		Text = "🍀",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = personal,
	})
	personalMult = Kit.label({
		Position = UDim2.fromOffset(4, 34),
		Size = UDim2.new(1, -8, 0, 26),
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = LUCK_GREEN,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = personal,
	})
	personalPrice = Kit.label({
		Position = UDim2.fromOffset(4, 62),
		Size = UDim2.new(1, -8, 0, 22),
		BackgroundTransparency = 0,
		BackgroundColor3 = ROBUX_GREEN,
		TextScaled = true,
		FontFace = Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = personal,
	})
	Kit.round().Parent = personalPrice

	local server = Kit.button({
		LayoutOrder = 2,
		Size = UDim2.fromOffset(92, 92),
		Text = "",
		BackgroundColor3 = Colors.Panel,
		Parent = right,
	}, function()
		serverPanel.Visible = not serverPanel.Visible
	end)
	Kit.stroke(Colors.Gold, 2).Parent = server
	Kit.label({
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, 0, 0, 34),
		Text = "🌐",
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = server,
	})
	serverButtonLabel = Kit.label({
		Position = UDim2.fromOffset(4, 40),
		Size = UDim2.new(1, -8, 0, 22),
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = server,
	})
	Kit.label({
		Position = UDim2.fromOffset(4, 64),
		Size = UDim2.new(1, -8, 0, 18),
		Text = "Luck",
		TextScaled = true,
		FontFace = Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = server,
	})

	-- Server luck popover (opens to the left of the right column)
	serverPanel = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -118, 0.5, 0),
		Size = UDim2.fromOffset(260, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Colors.Panel,
		Visible = false,
		Parent = layer,
	}, {
		Kit.corner(12),
		Kit.stroke(Colors.Gold, 2),
		Kit.padding(12),
		Kit.list(Enum.FillDirection.Vertical, 8),
	})
	Kit.label({
		LayoutOrder = 0,
		Size = UDim2.new(1, 0, 0, 44),
		Text = "Boost luck for EVERYONE in this server. Buying one that's running adds time.",
		TextSize = 14,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextColor3 = Colors.SubText,
		Parent = serverPanel,
	})
	for order, boost in Monetization.ServerLuck do
		Kit.button({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 44),
			Text = `{boost.Mult}x for {boost.Minutes} min   R$ {boost.Robux}`,
			TextSize = 17,
			BackgroundColor3 = ROBUX_GREEN,
			Parent = serverPanel,
		}, function()
			Actions.buyServerLuck(boost)
		end)
	end

	-- Top banner (under the cash panel)
	banner = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 98),
		Size = UDim2.fromOffset(320, 30),
		BackgroundColor3 = Color3.fromRGB(30, 60, 36),
		Visible = false,
		Parent = layer,
	}, { Kit.round(), Kit.stroke(LUCK_GREEN, 2) })
	bannerLabel = Kit.label({
		Size = UDim2.fromScale(1, 1),
		TextSize = 17,
		FontFace = Fonts.Heavy,
		TextColor3 = LUCK_GREEN,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = banner,
	})
end

function LuckHud.start()
	build()
	refreshBar()
	refreshPersonal()
	refreshServer()
	State.Changed:Connect(function(kind)
		if kind == "LuckBar" or kind == "State" then
			refreshBar()
		end
		if kind == "PersonalLuck" or kind == "State" then
			refreshPersonal()
		end
		if kind == "ServerLuck" or kind == "State" then
			refreshServer()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			refreshServer()
		end
	end)
end

return LuckHud
