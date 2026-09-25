--[[
	The fullscreen case opening.

	One vertical reel per case. Items scroll down and ease to a stop on the centre line.
	If the server's result is a gem rarity, the reel first lands on the yellow gem:
	the gem pops, a gold pixel mosaic flickers behind it, rays spin, the column glows
	and the riser plays; then the gem bursts and the reel re-spins through only the
	gem rarities to reveal the item. Every result then gets a rarity reveal (mosaic in
	the rarity colour, value counting up) and, if it mutated, a mutation reveal that
	multiplies the value on screen.

	Everything here is cosmetic: the server has already rolled, charged and saved.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)
local Roller = require(Shared.Roller)

local Actions = require(script.Parent.Parent.Actions)
local Sound = require(script.Parent.Parent.Sound)
local State = require(script.Parent.Parent.State)
local ItemVisual = require(script.Parent.ItemVisual)
local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)
local Window = require(script.Parent.Window)

local Colors = Theme.Colors
local Fonts = Theme.Fonts
local SpinConfig = GameConfig.Spin

local GOLD = Color3.fromRGB(255, 196, 46)
local RAINBOW = {
	Color3.fromRGB(255, 96, 96),
	Color3.fromRGB(255, 214, 96),
	Color3.fromRGB(110, 255, 150),
	Color3.fromRGB(96, 186, 255),
	Color3.fromRGB(214, 120, 255),
	Color3.fromRGB(255, 96, 96),
}

local MAIN_TARGET = 44 -- index of the landing cell on the first spin
local GEM_TARGET = 30 -- index of the landing cell on the gem re-spin
local START_INDEX = 2
local CELLS_AFTER = 4
local MOSAIC_GRID = 9
local BOARD_Y = -10

type Result = {
	Id: string,
	I: string,
	B: string,
	M: string?,
	N: number?,
	Supply: number?,
	Gem: boolean,
	Value: number,
}

type Entry = { Gem: boolean, I: string?, B: string? }

type Square = { Frame: Frame, D: number }

type Column = {
	Frame: Frame,
	EdgeFade: Frame,
	Stroke: UIStroke,
	Strip: Frame,
	Shade: Frame,
	Flash: Frame,
	Hero: Frame,
	HeroScale: UIScale,
	Rays: Frame,
	Squares: { Square },
	Mosaic: Frame,
	Info: Frame,
	NameLabel: TextLabel,
	BrandLabel: TextLabel,
	ValueLabel: TextLabel,
	Badge: TextLabel,
	BadgeScale: UIScale,
	SoldLabel: TextLabel,
	Cells: { [number]: Frame },
	CellHeight: number,
	Height: number,
	Connections: { RBXScriptConnection },
	RaysSpinning: boolean,
	MosaicRun: number,
}

local Spinner = {}

local rng = Random.new()
local busy = false
local autoOn = false
local lastTick = 0

local overlay: Frame
local board: Frame
local headerLabel: TextLabel
local subLabel: TextLabel
local footer: Frame
local totalLabel: TextLabel
local sellButton: TextButton
local againButton: TextButton
local autoButton: TextButton
local screenFlash: Frame
local leftArrow: TextLabel
local rightArrow: TextLabel

local choice: string? = nil

-- Helpers --------------------------------------------------------------------------------------

local function animate(duration: number, step: (number) -> ())
	local elapsed = 0
	while elapsed < duration do
		elapsed += RunService.RenderStepped:Wait()
		step(math.min(elapsed / duration, 1))
	end
	step(1)
end

local function easeOutQuart(x: number): number
	return 1 - (1 - x) ^ 4
end

local function easeInOutQuad(x: number): number
	return if x < 0.5 then 2 * x * x else 1 - (-2 * x + 2) ^ 2 / 2
end

local function flashScreen(color: Color3, strength: number)
	screenFlash.BackgroundColor3 = color
	screenFlash.BackgroundTransparency = 1 - strength
	Kit.tween(screenFlash, 0.5, { BackgroundTransparency = 1 })
end

local function shake(duration: number, magnitude: number)
	task.spawn(function()
		animate(duration, function(alpha)
			local m = magnitude * (1 - alpha)
			board.Position = UDim2.new(0.5, rng:NextNumber(-m, m), 0.5, BOARD_Y + rng:NextNumber(-m, m))
		end)
		board.Position = UDim2.new(0.5, 0, 0.5, BOARD_Y)
	end)
end

local function playTick(progress: number)
	local now = os.clock()
	if now - lastTick < 0.03 then
		return
	end
	lastTick = now
	Sound.play("Tick", { Pitch = 0.95 + progress * 0.15 + rng:NextNumber(0, 0.05) })
end

local function speedFactor(): number
	return if State.hasPass("FastOpen") then SpinConfig.FastMultiplier else 1
end

-- Column construction --------------------------------------------------------------------------

local function buildMosaic(parent: Frame, size: number): (Frame, { Square })
	local frame = Kit.new("Frame", {
		Name = "Mosaic",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 2,
		Parent = parent,
	})
	local squares = {}
	local step = size / MOSAIC_GRID
	local half = (MOSAIC_GRID - 1) / 2
	for gx = 0, MOSAIC_GRID - 1 do
		for gy = 0, MOSAIC_GRID - 1 do
			local dx, dy = (gx - half) / half, (gy - half) / half
			local d = math.sqrt(dx * dx + dy * dy)
			if d <= 1.25 then
				local square = Kit.new("Frame", {
					Position = UDim2.fromOffset(gx * step + step * 0.12, gy * step + step * 0.12),
					Size = UDim2.fromOffset(step * 0.76, step * 0.76),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 2,
					Parent = frame,
				}, { Kit.corner(2) })
				table.insert(squares, { Frame = square, D = d })
			end
		end
	end
	return frame, squares
end

local function buildRays(parent: Frame, size: number): Frame
	local rays = Kit.new("Frame", {
		Name = "Rays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 1,
		Parent = parent,
	})
	for i = 0, 5 do
		Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 0, size * 0.1),
			Rotation = i * 30,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = rays,
		}, {
			Kit.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.3, 0.75),
					NumberSequenceKeypoint.new(0.5, 0.2),
					NumberSequenceKeypoint.new(0.7, 0.75),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
	end
	return rays
end

local function buildColumn(
	index: number,
	count: number,
	width: number,
	height: number,
	cellHeight: number,
	gap: number
): Column
	local totalWidth = count * width + (count - 1) * gap
	local frame = Kit.new("Frame", {
		Name = `Column{index}`,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, -totalWidth / 2 + (index - 1) * (width + gap), 0.5, 0),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = Colors.Panel,
		ClipsDescendants = true,
		Parent = board,
	}, { Kit.corner(14) })
	local stroke = Kit.stroke(Colors.Stroke, 2)
	stroke.Parent = frame

	local strip = Kit.new("Frame", {
		Name = "Strip",
		Size = UDim2.new(1, 0, 0, cellHeight),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = frame,
	})

	-- Centre line and edge fade, above the strip.
	Kit.new("Frame", {
		Name = "CenterLine",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = GOLD,
		BackgroundTransparency = 0.75,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = frame,
	})
	local edgeFade = Kit.new("Frame", {
		Name = "EdgeFade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colors.Panel,
		ZIndex = 4,
		Parent = frame,
	}, {
		Kit.new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.2, 1),
				NumberSequenceKeypoint.new(0.8, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		}),
	})

	local shade = Kit.new("Frame", {
		Name = "Shade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = frame,
	})
	local stage = Kit.new("Frame", {
		Name = "Stage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = frame,
	})
	local flash = Kit.new("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = frame,
	})

	local rays = buildRays(stage, math.min(width, height) * 1.05)
	local mosaic, squares = buildMosaic(stage, math.min(width - 12, cellHeight * 1.35))

	local hero = Kit.new("Frame", {
		Name = "Hero",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(cellHeight, cellHeight),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 3,
		Parent = stage,
	})
	local heroScale = Kit.new("UIScale", { Parent = hero })

	local infoTop = height / 2 + cellHeight * 0.52
	local info = Kit.new("Frame", {
		Name = "Info",
		Position = UDim2.fromOffset(8, infoTop),
		Size = UDim2.new(1, -16, 0, math.max(height - infoTop - 8, 40)),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 4,
		Parent = stage,
	}, { Kit.list(Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center) })
	local function infoLabel(order: number, h: number, font: Font, color: Color3): TextLabel
		return Kit.label({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, h),
			TextScaled = true,
			FontFace = font,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
			Parent = info,
		})
	end
	local nameLabel = infoLabel(1, 22, Fonts.Heavy, Colors.Text)
	local brandLabel = infoLabel(2, 16, Fonts.Medium, Colors.SubText)
	local valueLabel = infoLabel(3, 24, Fonts.Heavy, GOLD)

	local badge = Kit.label({
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -cellHeight * 0.62),
		Size = UDim2.new(0.9, 0, 0, 26),
		BackgroundTransparency = 0,
		BackgroundColor3 = GOLD,
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = Color3.fromRGB(18, 18, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 5,
		Parent = stage,
	})
	Kit.round().Parent = badge
	Kit.padding(3, 10).Parent = badge
	local badgeScale = Kit.new("UIScale", { Parent = badge })

	local sold = Kit.label({
		Name = "Sold",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(width / 2, 10),
		Size = UDim2.fromOffset(width - 20, 22),
		Text = "SOLD",
		TextScaled = true,
		FontFace = Fonts.Heavy,
		TextColor3 = Colors.Good,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 6,
		Parent = stage,
	})

	return {
		Frame = frame,
		EdgeFade = edgeFade,
		Stroke = stroke,
		Strip = strip,
		Shade = shade,
		Flash = flash,
		Hero = hero,
		HeroScale = heroScale,
		Rays = rays,
		Squares = squares,
		Mosaic = mosaic,
		Info = info,
		NameLabel = nameLabel,
		BrandLabel = brandLabel,
		ValueLabel = valueLabel,
		Badge = badge,
		BadgeScale = badgeScale,
		SoldLabel = sold,
		Cells = {},
		CellHeight = cellHeight,
		Height = height,
		Connections = {},
		RaysSpinning = false,
		MosaicRun = 0,
	}
end

-- Reel -----------------------------------------------------------------------------------------

local function makeCell(column: Column, index: number, entry: Entry): Frame
	local cell = Kit.new("Frame", {
		Name = tostring(index),
		Position = UDim2.fromOffset(0, -index * column.CellHeight),
		Size = UDim2.new(1, 0, 0, column.CellHeight),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = column.Strip,
	})
	if entry.Gem then
		ItemVisual.gem({ Size = UDim2.fromScale(0.74, 0.74), ZIndex = 2 }).Parent = cell
	else
		local item = Catalog.ItemById[entry.I :: string]
		local rarity = Catalog.RarityById[item.Rarity]
		Kit.new("Frame", {
			Name = "Aura",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.62, 0.62),
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.86,
			ZIndex = 2,
			Parent = cell,
		}, { Kit.round(), Kit.new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
		Kit.new("Frame", {
			Name = "Bar",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(0.5, 0, 0, 4),
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.1,
			ZIndex = 2,
			Parent = cell,
		}, { Kit.round() })
		ItemVisual.icon(entry.I :: string, { Size = UDim2.fromScale(0.6, 0.6), ZIndex = 2 }).Parent = cell
	end
	column.Cells[index] = cell
	return cell
end

local function setScroll(column: Column, scroll: number)
	column.Strip.Position = UDim2.fromOffset(0, column.Height / 2 - column.CellHeight / 2 + scroll)
end

local function fillStrip(column: Column, case: Catalog.Case, target: Entry, targetIndex: number, gemPhase: boolean)
	column.Strip:ClearAllChildren()
	table.clear(column.Cells)
	for index = 0, targetIndex + CELLS_AFTER do
		local entry: Entry = if index == targetIndex then target else Roller.filler(case, rng, gemPhase) :: any
		makeCell(column, index, entry)
	end
	setScroll(column, START_INDEX * column.CellHeight)
end

local function spinTo(column: Column, targetIndex: number, duration: number)
	local cellHeight = column.CellHeight
	local startScroll = START_INDEX * cellHeight
	local endScroll = targetIndex * cellHeight + rng:NextNumber(-0.36, 0.36) * cellHeight
	local lastIndex = START_INDEX
	animate(duration, function(alpha)
		local scroll = startScroll + (endScroll - startScroll) * easeOutQuart(alpha)
		setScroll(column, scroll)
		local index = math.floor(scroll / cellHeight + 0.5)
		if index ~= lastIndex then
			lastIndex = index
			playTick(alpha)
		end
	end)
	-- Settle onto the centre line, like the reel clicking into place.
	local settleFrom = endScroll
	local settleTo = targetIndex * cellHeight
	animate(0.3, function(alpha)
		setScroll(column, settleFrom + (settleTo - settleFrom) * easeInOutQuad(alpha))
	end)
	Sound.play("Land")
end

-- Effects --------------------------------------------------------------------------------------

local function track(column: Column, connection: RBXScriptConnection)
	table.insert(column.Connections, connection)
end

local function glow(column: Column, color: Color3, thickness: number?)
	column.Stroke.Color = color
	Kit.tween(column.Stroke, 0.2, { Thickness = thickness or 3.5, Transparency = 0 })
	local tint = Colors.Panel:Lerp(color, 0.1)
	Kit.tween(column.Frame, 0.3, { BackgroundColor3 = tint })
	Kit.tween(column.EdgeFade, 0.3, { BackgroundColor3 = tint })
end

local function raysOn(column: Column, color: Color3, strength: number)
	column.Rays.Visible = true
	for _, ray in column.Rays:GetChildren() do
		local frame = ray :: Frame
		frame.BackgroundColor3 = color
		Kit.tween(frame, 0.3, { BackgroundTransparency = 1 - strength })
	end
	if not column.RaysSpinning then
		column.RaysSpinning = true
		track(
			column,
			RunService.RenderStepped:Connect(function(dt)
				column.Rays.Rotation += dt * 28
			end)
		)
	end
end

local function raysOff(column: Column)
	for _, ray in column.Rays:GetChildren() do
		Kit.tween(ray, 0.25, { BackgroundTransparency = 1 })
	end
end

-- Flickers the pixel mosaic, then leaves it faintly lit (residual) or clears it.
-- A newer burst on the same column takes over from an older one still running.
local function mosaicBurst(column: Column, color: Color3 | () -> Color3, duration: number, residual: boolean)
	column.MosaicRun += 1
	local run = column.MosaicRun
	column.Mosaic.Visible = true
	local colorAt: () -> Color3
	if typeof(color) == "Color3" then
		colorAt = function()
			return color
		end
	else
		colorAt = color
	end
	local elapsed, nextShuffle = 0, 0
	while elapsed < duration do
		elapsed += RunService.RenderStepped:Wait()
		if column.MosaicRun ~= run then
			return
		end
		if elapsed >= nextShuffle then
			nextShuffle = elapsed + 0.07
			local energy = 1 - (elapsed / duration) * 0.45
			local tint = colorAt()
			for _, square in column.Squares do
				local lit = rng:NextNumber() < (1.2 - square.D) * energy
				square.Frame.BackgroundColor3 = tint
				square.Frame.BackgroundTransparency = if lit
					then math.clamp(0.05 + square.D * 0.5 + rng:NextNumber() * 0.25, 0, 1)
					else 1
			end
		end
	end
	for _, square in column.Squares do
		local goal = if residual and rng:NextNumber() < 1.1 - square.D
			then math.clamp(0.55 + square.D * 0.35, 0, 1)
			else 1
		Kit.tween(square.Frame, 0.45, { BackgroundTransparency = goal })
	end
end

local function showHero(column: Column, entry: Entry, targetIndex: number)
	for _, child in column.Hero:GetChildren() do
		if not child:IsA("UIScale") then
			child:Destroy()
		end
	end
	local visual = if entry.Gem
		then ItemVisual.gem({ Size = UDim2.fromScale(0.74, 0.74), ZIndex = 3 })
		else ItemVisual.icon(entry.I :: string, { Size = UDim2.fromScale(0.62, 0.62), ZIndex = 3 })
	visual.Parent = column.Hero
	column.Hero.Rotation = 0
	column.HeroScale.Scale = 1
	column.Hero.Visible = true
	local cell = column.Cells[targetIndex]
	if cell then
		cell.Visible = false
	end
end

local function countUp(label: TextLabel, from: number, to: number, duration: number)
	local stop = Sound.loop("CountUp")
	animate(duration, function(alpha)
		label.Text = Format.cashFull(from + (to - from) * (1 - (1 - alpha) ^ 3))
	end)
	stop()
end

local function gemSequence(column: Column, speed: number)
	local hold = SpinConfig.GemHold * speed
	Sound.play("GemHit")
	Sound.play("GemRiser")
	flashScreen(GOLD, 0.25)
	shake(0.3, 6)
	glow(column, GOLD, 4)
	Kit.tween(column.Shade, 0.25, { BackgroundTransparency = 0.35 })
	Kit.tween(column.HeroScale, 0.35, { Scale = 1.5 }, Enum.EasingStyle.Back)
	raysOn(column, GOLD, 0.65)
	task.spawn(mosaicBurst, column, GOLD, hold, false)
	task.wait(0.35 * speed)

	animate(math.max(hold - 0.35 * speed, 0), function(alpha)
		column.Hero.Rotation = math.sin(alpha * math.pi * 10) * 7 * alpha
		column.HeroScale.Scale = 1.5 + alpha * 0.2 + math.sin(alpha * math.pi * 8) * 0.05
		column.Stroke.Thickness = 3.5 + math.sin(alpha * math.pi * 12) * 1.5
	end)

	Sound.play("GemBurst")
	Kit.tween(column.HeroScale, 0.18, { Scale = 2.4 })
	column.Flash.BackgroundTransparency = 0.15
	Kit.tween(column.Flash, 0.45, { BackgroundTransparency = 1 })
	task.wait(0.18)
	column.Hero.Visible = false
	column.Hero.Rotation = 0
	raysOff(column)
	Kit.tween(column.Shade, 0.2, { BackgroundTransparency = 1 })
	Kit.tween(column.Stroke, 0.3, { Thickness = 2.5 })
end

local function reveal(column: Column, result: Result, speed: number)
	local item = Catalog.ItemById[result.I]
	local rarity = Catalog.RarityById[item.Rarity]
	local order = rarity.Order
	local big = order >= 5

	Sound.play(if big then "RevealBig" else "Reveal", { Pitch = 0.85 + order * 0.06 })
	glow(column, rarity.Color, if big then 4.5 else 3)
	Kit.tween(column.Shade, 0.3, { BackgroundTransparency = 0.35 })
	column.HeroScale.Scale = 0.8
	Kit.tween(column.HeroScale, 0.4, { Scale = 1.15 }, Enum.EasingStyle.Back)
	if order >= 4 then
		raysOn(column, rarity.Color, if order >= 6 then 0.75 else 0.45)
	end
	if big then
		flashScreen(rarity.Color, if order >= 6 then 0.4 else 0.25)
		shake(0.35, if order >= 6 then 10 else 5)
	end
	task.spawn(mosaicBurst, column, rarity.Color, 1.1 * speed + 0.3, true)

	column.NameLabel.Text = item.Name
	column.NameLabel.TextColor3 = rarity.Color
	local serial = if result.N
		then `  •  #{Format.commas(result.N)}{if result.Supply then " / " .. Format.commas(result.Supply) else ""}`
		else ""
	column.BrandLabel.Text = `{Catalog.Brands[result.B].Name}  •  {rarity.Name}{serial}`
	column.ValueLabel.Text = "$0"
	column.Info.Visible = true

	countUp(column.ValueLabel, 0, Catalog.valueOf({ I = result.I, B = result.B }), SpinConfig.RevealTime * speed)
end

local function mutationEffect(column: Column, mutation: Catalog.Mutation, duration: number)
	if mutation.Effect == "shine" then
		local shine = Kit.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			Parent = column.Hero,
		})
		local gradient = Kit.new("UIGradient", {
			Rotation = 25,
			Offset = Vector2.new(-1, 0),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.42, 1),
				NumberSequenceKeypoint.new(0.5, 0.35),
				NumberSequenceKeypoint.new(0.58, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = shine,
		})
		animate(duration, function(alpha)
			gradient.Offset = Vector2.new(-1 + ((alpha * 2) % 1) * 2, 0)
		end)
		shine:Destroy()
	elseif mutation.Effect == "sparkle" then
		local elapsed = 0
		while elapsed < duration do
			local star = Kit.label({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
				Size = UDim2.fromOffset(rng:NextNumber(14, 28), rng:NextNumber(14, 28)),
				Text = "✦",
				TextScaled = true,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextColor3 = mutation.Color:Lerp(Color3.new(1, 1, 1), 0.4),
				Rotation = rng:NextNumber(0, 90),
				ZIndex = 4,
				Parent = column.Hero,
			})
			local scale = Kit.new("UIScale", { Scale = 0, Parent = star })
			Kit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			task.delay(0.35, function()
				Kit.tween(scale, 0.25, { Scale = 0 })
				task.wait(0.25)
				star:Destroy()
			end)
			local waitTime = task.wait(0.08)
			elapsed += waitTime
		end
	elseif mutation.Effect == "pulse" then
		task.spawn(mosaicBurst, column, mutation.Color, duration, true)
		animate(duration, function(alpha)
			column.HeroScale.Scale = 1.15 + math.sin(alpha * math.pi * 6) * 0.08
		end)
	elseif mutation.Effect == "rainbow" then
		local gradient = Kit.gradient(RAINBOW, 0)
		gradient.Parent = column.Stroke
		column.Stroke.Color = Color3.new(1, 1, 1)
		track(
			column,
			RunService.RenderStepped:Connect(function(dt)
				gradient.Rotation = (gradient.Rotation + dt * 180) % 360
			end)
		)
		local hue = rng:NextNumber()
		task.spawn(mosaicBurst, column, function()
			hue = (hue + 0.04) % 1
			return Color3.fromHSV(hue, 0.7, 1)
		end, duration, true)
		animate(duration, function(alpha)
			column.HeroScale.Scale = 1.15 + math.sin(alpha * math.pi * 4) * 0.06
		end)
	end
end

local function mutationReveal(column: Column, result: Result, speed: number)
	local mutation = Catalog.MutationById[result.M :: string]
	local duration = SpinConfig.MutationTime * speed
	task.wait(0.2 * speed)

	Sound.play(if mutation.Tier >= 4 then "MutationBig" else "Mutation", { Pitch = 0.9 + mutation.Tier * 0.07 })
	column.Badge.Text = `✦ {mutation.Name} {Format.mult(mutation.Mult)}`
	column.Badge.BackgroundColor3 = mutation.Color
	column.Badge.Visible = true
	column.BadgeScale.Scale = 2.2
	Kit.tween(column.BadgeScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	if mutation.Effect == "rainbow" then
		Kit.gradient(RAINBOW, 0).Parent = column.Badge
		column.Badge.BackgroundColor3 = Color3.new(1, 1, 1)
	else
		glow(column, mutation.Color, 3.5 + mutation.Tier * 0.4)
	end
	if mutation.Tier >= 3 then
		flashScreen(mutation.Color, 0.15 + mutation.Tier * 0.07)
		shake(0.25 + mutation.Tier * 0.1, mutation.Tier * 3)
	end

	task.spawn(mutationEffect, column, mutation, duration)
	column.ValueLabel.TextColor3 = mutation.Color:Lerp(Color3.new(1, 1, 1), 0.2)
	local base = Catalog.valueOf({ I = result.I, B = result.B })
	countUp(column.ValueLabel, base, result.Value, math.min(0.9 * speed, duration))
	Kit.tween(column.ValueLabel, 0.4, { TextColor3 = GOLD })
	task.wait(math.max(duration - 0.9 * speed, 0))
end

local function runColumn(column: Column, case: Catalog.Case, result: Result, index: number, speed: number)
	local item: Entry = { Gem = false, I = result.I, B = result.B }
	local duration = (SpinConfig.Duration + SpinConfig.Stagger * (index - 1)) * speed

	fillStrip(column, case, if result.Gem then { Gem = true } else item, MAIN_TARGET, false)
	spinTo(column, MAIN_TARGET, duration)
	local landed = MAIN_TARGET

	if result.Gem then
		showHero(column, { Gem = true }, MAIN_TARGET)
		gemSequence(column, speed)
		fillStrip(column, case, item, GEM_TARGET, true)
		spinTo(column, GEM_TARGET, SpinConfig.GemSpinDuration * speed)
		landed = GEM_TARGET
	end

	showHero(column, item, landed)
	reveal(column, result, speed)
	if result.M then
		mutationReveal(column, result, speed)
	end
end

-- Overlay --------------------------------------------------------------------------------------

local function clearBoard(columns: { Column })
	for _, column in columns do
		for _, connection in column.Connections do
			connection:Disconnect()
		end
	end
	for _, child in board:GetChildren() do
		child:Destroy()
	end
end

local function layout(count: number): (number, number, number, number)
	local size = Root.size()
	local gap = 16
	local width = math.clamp((size.X - 140 - gap * (count - 1)) / count, 120, 230)
	local height = math.clamp(size.Y - 280, 300, 520)
	local cellHeight = math.min(width * 0.82, height / 2.7)
	return width, height, cellHeight, gap
end

local function setFooterVisible(visible: boolean)
	footer.Visible = visible
end

local function build()
	local layer = Root.layer("Spin")
	overlay = Kit.new("Frame", {
		Name = "Spinner",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colors.Backdrop,
		BackgroundTransparency = 0.06,
		Visible = false,
		Active = true,
		Parent = layer,
	})
	headerLabel = Kit.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34),
		Size = UDim2.fromOffset(900, 44),
		FontFace = Fonts.Heavy,
		TextSize = 40,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = overlay,
	})
	subLabel = Kit.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 80),
		Size = UDim2.fromOffset(900, 24),
		TextColor3 = Colors.SubText,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = overlay,
	})
	board = Kit.new("Frame", {
		Name = "Board",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, BOARD_Y),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = overlay,
	})
	leftArrow = Kit.label({
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "▶",
		TextSize = 30,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.fromOffset(30, 30),
		Parent = overlay,
	})
	rightArrow = Kit.label({
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "◀",
		TextSize = 30,
		TextColor3 = GOLD,
		Size = UDim2.fromOffset(30, 30),
		Parent = overlay,
	})

	footer = Kit.new("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -26),
		Size = UDim2.fromOffset(900, 104),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = overlay,
	})
	totalLabel = Kit.label({
		Size = UDim2.new(1, 0, 0, 34),
		FontFace = Fonts.Heavy,
		TextSize = 30,
		TextColor3 = GOLD,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = footer,
	})
	local row = Kit.new("Frame", {
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundTransparency = 1,
		Parent = footer,
	}, { Kit.list(Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center) })

	sellButton = Kit.button({
		LayoutOrder = 1,
		Size = UDim2.fromOffset(220, 52),
		BackgroundColor3 = Color3.fromRGB(34, 120, 74),
		Parent = row,
	}, function()
		choice = "sell"
	end)
	againButton = Kit.button({
		LayoutOrder = 2,
		Size = UDim2.fromOffset(240, 52),
		BackgroundColor3 = Theme.Colors.GoldDeep,
		TextColor3 = Color3.fromRGB(20, 16, 8),
		Parent = row,
	}, function()
		choice = "again"
	end)
	autoButton = Kit.button({
		LayoutOrder = 3,
		Size = UDim2.fromOffset(140, 52),
		Parent = row,
	}, function()
		autoOn = not autoOn
		autoButton.Text = if autoOn then "Auto: ON" else "Auto: OFF"
		Kit.setButtonColor(autoButton, if autoOn then Colors.Accent else Colors.PanelLighter)
		if autoOn then
			choice = "again"
		end
	end)
	autoButton.Text = "Auto: OFF"
	Kit.button({
		LayoutOrder = 4,
		Size = UDim2.fromOffset(140, 52),
		Text = "Close",
		Parent = row,
	}, function()
		choice = "close"
	end)

	screenFlash = Kit.new("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = overlay,
	})
end

type Request = () -> Actions.Result

local function play(case: Catalog.Case, results: { Result }): { Column }
	local count = #results
	local width, height, cellHeight, gap = layout(count)
	local columns = {}
	for index = 1, count do
		table.insert(columns, buildColumn(index, count, width, height, cellHeight, gap))
	end

	local totalWidth = count * width + (count - 1) * gap
	leftArrow.Position = UDim2.new(0.5, -totalWidth / 2 - 8, 0.5, BOARD_Y)
	rightArrow.Position = UDim2.new(0.5, totalWidth / 2 + 8, 0.5, BOARD_Y)

	local speed = speedFactor()
	local remaining = count
	for index, result in results do
		task.spawn(function()
			local ok, err = pcall(runColumn, columns[index], case, result, index, speed)
			if not ok then
				warn(`[Spinner] column {index} failed: {err}`)
			end
			remaining -= 1
		end)
	end
	while remaining > 0 do
		task.wait()
	end
	return columns
end

local function updateAgainButton(case: Catalog.Case, count: number, mode: string?)
	if case.Paid then
		againButton.Text = if mode == "devrobux"
			then "Open again (dev, free)"
			else `Open again (R$ {Actions.robuxPrice(case)})`
		againButton.Active = true
		againButton.TextTransparency = 0
		return
	end
	local keys = math.min(State.keysFor(case.Id), count)
	local cost = (count - keys) * case.Price
	local label = if count > 1 then `Open {count} again` else "Open again"
	if keys > 0 then
		againButton.Text = `{label} (🔑{keys}{if cost > 0 then " + " .. Format.cash(cost) else ""})`
	else
		againButton.Text = `{label} ({Format.cash(cost)})`
	end
	againButton.Active = State.canAfford(case, count)
	againButton.AutoButtonColor = false
	againButton.TextTransparency = if againButton.Active then 0 else 0.5
end

local function waitForChoice(case: Catalog.Case, count: number, autoAllowed: boolean, mode: string?): string
	choice = nil
	updateAgainButton(case, count, mode)
	local autoAt = if autoOn and autoAllowed then os.clock() + SpinConfig.AutoOpenDelay else math.huge
	while true do
		if choice == "again" and not State.canAfford(case, count) then
			choice = nil
			Toast.show("Not enough cash to open again.", "bad")
		end
		if choice then
			break
		end
		if os.clock() >= autoAt then
			if State.canAfford(case, count) then
				return "again"
			end
			autoOn = false
			autoButton.Text = "Auto: OFF"
			Kit.setButtonColor(autoButton, Colors.PanelLighter)
			Toast.show("Auto open stopped: not enough cash.", "bad")
			autoAt = math.huge
		end
		task.wait()
	end
	return choice :: string
end

--[[
	Opens a case and runs the whole spin loop until the player closes it.
	mode: nil = pay with cash/keys, "free" = the free case, "robux" = buy a Robux case (prompts
	the purchase, spins when the server opens it), "devrobux" = developer test open of a
	Robux case without paying.
]]
function Spinner.run(case: Catalog.Case, count: number, mode: string?)
	if busy then
		return
	end
	busy = true
	Window.closeAll()

	local free = mode == "free"
	local request: Request
	if free then
		request = Actions.claimFreeCase
	elseif mode == "robux" then
		request = function()
			return Actions.openPaid(case)
		end
	elseif mode == "devrobux" then
		request = function()
			return Actions.debug("OpenPaid", case.Id)
		end
	else
		request = function()
			return Actions.openCase(case.Id, count)
		end
	end

	local columns: { Column } = {}
	local shown = false
	while true do
		local response = request()
		if not response.ok then
			break
		end

		if not shown then
			overlay.Visible = true
			shown = true
		end
		clearBoard(columns)
		setFooterVisible(false)
		headerLabel.Text = `{case.Icon}  {case.Name}`
		local luckMult = response.LuckMult or 1
		headerLabel.TextColor3 = case.Color
		subLabel.Text = if free
			then "Free case!"
			elseif mode == "devrobux" then "Developer test open (free)  •  guaranteed mutation"
			elseif case.Paid then `Robux case  •  guaranteed mutation{if case.Limited
				then "  •  Limited supply"
				else ""}`
			elseif response.KeysUsed > 0 then `Opening {count}  •  used {response.KeysUsed} key{if response.KeysUsed
					== 1
				then ""
				else "s"}`
			else `Opening {count}  •  {Format.cash(response.Cost)}`
		if response.BarBoost then
			subLabel.Text = `🍀 {GameConfig.LuckBar.Mult}x LUCK BAR BOOST!  •  ` .. subLabel.Text
			subLabel.TextColor3 = Colors.Gold
			flashScreen(Colors.Good, 0.2)
			Sound.play("GemHit", { Pitch = 1.3, Volume = 0.6 })
		elseif luckMult > 1 then
			subLabel.Text = `🍀 {luckMult}x server luck  •  ` .. subLabel.Text
			subLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
		else
			subLabel.TextColor3 = Colors.SubText
		end

		local results = response.Results :: { Result }
		columns = play(case, results)

		local total, bigHit = 0, false
		local ids = {}
		for _, result in results do
			total += result.Value
			table.insert(ids, result.Id)
			local mutation = result.M and Catalog.MutationById[result.M]
			if result.Gem or (mutation and mutation.Tier >= 3) then
				bigHit = true
			end
		end
		totalLabel.Text = `Total  {Format.cashFull(total)}`
		sellButton.Text = `Sell all ({Format.cash(total)})`
		sellButton.Active = true
		sellButton.TextTransparency = 0
		autoButton.Visible = State.hasPass("AutoOpen")
		setFooterVisible(true)

		if bigHit and autoOn then
			Toast.show("Big hit! Auto open paused so you can enjoy it.", "gold")
		end

		-- After a free case, "again" means buying one of the same case.
		if free then
			free = false
			count = 1
			request = function()
				return Actions.openCase(case.Id, count)
			end
		end

		local picked = waitForChoice(case, count, not bigHit and not case.Paid, mode)
		while picked == "sell" do
			local sold = Actions.sell(ids)
			if sold.ok then
				Toast.show(
					`Sold {sold.Count} item{if sold.Count == 1 then "" else "s"} for {Format.cash(sold.Total)}`,
					"good"
				)
				for _, column in columns do
					column.SoldLabel.Visible = true
					Kit.tween(column.Shade, 0.3, { BackgroundTransparency = 0.15 })
				end
				sellButton.Active = false
				sellButton.TextTransparency = 0.5
			end
			picked = waitForChoice(case, count, false, mode)
		end
		if picked ~= "again" then
			break
		end
	end

	clearBoard(columns)
	overlay.Visible = false
	busy = false
end

function Spinner.isBusy(): boolean
	return busy
end

function Spinner.start()
	build()
end

return Spinner
