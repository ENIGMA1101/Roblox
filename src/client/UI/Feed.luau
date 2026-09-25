--[[
	Live pull feed, bottom right. Notable pulls from everyone in the server pop in on the
	right, push the older cards left, and the oldest fades out once there are more than
	Feed.Visible cards (or after Feed.Lifetime seconds). Your own pulls say "You".

	The server sends entries (see server/Services/FeedService) once each spin has landed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Net)

local ItemVisual = require(script.Parent.ItemVisual)
local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors
local Fonts = Theme.Fonts
local FeedConfig = GameConfig.Feed

local CARD_W = 150
local CARD_H = 74
local GAP = 8
local SLIDE = 0.35

type Entry = {
	Player: string,
	UserId: number,
	I: string,
	B: string,
	M: string?,
	N: number?,
	Value: number,
	Case: string,
}

type Card = { Frame: CanvasGroup, Scale: UIScale, Alive: boolean }

local Feed = {}

local container: Frame
local cards: { Card } = {} -- newest first

local function slotPosition(slot: number): UDim2
	return UDim2.new(1, -(slot - 1) * (CARD_W + GAP), 0, 0)
end

local function remove(card: Card)
	if not card.Alive then
		return
	end
	card.Alive = false
	local index = table.find(cards, card)
	if index then
		table.remove(cards, index)
	end
	local frame = card.Frame
	Kit.tween(frame, SLIDE, {
		GroupTransparency = 1,
		Position = frame.Position + UDim2.fromOffset(-CARD_W * 0.5, 0),
	})
	task.delay(SLIDE + 0.05, function()
		frame:Destroy()
	end)
end

local function layout()
	for slot, card in cards do
		if slot > FeedConfig.Visible then
			remove(card)
		else
			Kit.tween(card.Frame, SLIDE, { Position = slotPosition(slot) }, Enum.EasingStyle.Quad)
		end
	end
end

local function build(entry: Entry): Card
	local item = Catalog.ItemById[entry.I]
	local rarity = Catalog.RarityById[item.Rarity]
	local mutation = entry.M and Catalog.MutationById[entry.M]
	local mine = entry.UserId == Players.LocalPlayer.UserId

	local frame = Kit.new("CanvasGroup", {
		Name = "FeedCard",
		AnchorPoint = Vector2.new(1, 0),
		Position = slotPosition(1),
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = Colors.Panel:Lerp(rarity.Color, 0.22),
		GroupTransparency = 1,
		Parent = container,
	}, { Kit.corner(10) })
	local scale = Kit.new("UIScale", { Scale = 0.3, Parent = frame })
	if rarity.Gradient then
		Kit.gradient(rarity.Gradient, 30).Parent = frame
		frame.BackgroundColor3 = Color3.new(1, 1, 1)
		frame.BackgroundTransparency = 0.35
	end
	local stroke = Kit.stroke(if mine then Color3.new(1, 1, 1) else rarity.Color, if mine then 2.5 else 1.5)
	stroke.Parent = frame

	local art = Kit.new("Frame", {
		Position = UDim2.fromOffset(6, 13),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = rarity.Color,
		BackgroundTransparency = 0.75,
		Parent = frame,
	}, { Kit.corner(8) })
	ItemVisual.icon(entry.I, { Size = UDim2.fromScale(0.85, 0.85) }).Parent = art

	local function line(y: number, h: number, text: string, color: Color3, font: Font)
		local label = Kit.label({
			Position = UDim2.fromOffset(60, y),
			Size = UDim2.new(1, -66, 0, h),
			Text = text,
			TextScaled = true,
			FontFace = font,
			TextColor3 = color,
			Parent = frame,
		})
		Kit.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.4, Parent = label })
	end
	line(6, 18, item.Name, rarity.Color:Lerp(Color3.new(1, 1, 1), 0.2), Fonts.Heavy)
	line(25, 14, if mine then "You" else entry.Player, if mine then Colors.Gold else Colors.SubText, Fonts.Bold)
	line(
		42,
		22,
		Format.cash(entry.Value) .. (if mutation then ` ✦{mutation.Name}` else ""),
		if mutation then mutation.Color else Colors.Gold,
		Fonts.Heavy
	)

	return { Frame = frame, Scale = scale, Alive = true }
end

local function push(entry: Entry)
	if not Catalog.ItemById[entry.I] then
		return
	end
	local card = build(entry)
	table.insert(cards, 1, card)
	Kit.tween(card.Frame, 0.3, { GroupTransparency = 0 })
	Kit.tween(card.Scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	layout()
	task.delay(FeedConfig.Lifetime, remove, card)
end

function Feed.start()
	-- Above everything (including the spin screen) so pulls are visible while spinning.
	container = Kit.new("Frame", {
		Name = "Feed",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -96),
		Size = UDim2.fromOffset(FeedConfig.Visible * (CARD_W + GAP), CARD_H),
		BackgroundTransparency = 1,
		Parent = Root.layer("Toasts"),
	})
	Net.event("Feed").OnClientEvent:Connect(function(entries: { Entry })
		if type(entries) ~= "table" then
			return
		end
		for index, entry in entries do
			task.delay((index - 1) * 0.2, push, entry)
		end
	end)
end

return Feed
