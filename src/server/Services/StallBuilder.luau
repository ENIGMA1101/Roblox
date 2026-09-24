--[[
	Builds the Vermeil Exchange stall: marble floor with gold trim, wood pillars and roof,
	a lit sign, a menu screen, the case counter and two display pedestals.

	StallService builds it automatically when the map has no part tagged "CaseStall".
	To keep a copy you can edit, run this in the Studio command bar (edit mode), then
	disable auto-build in StallService:

		require(game.ServerScriptService.Server.Services.StallBuilder).build(Vector3.new(50, 0, 50), 0)

	Tags it applies (StallService / the client look for these):
		CaseStall        - the counter; gets the "Open Cases" ProximityPrompt
		BestPullDisplay  - screen that shows the server's best pull
		SpinDecor        - decorative gems the client spins
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)

local GOLD = Color3.fromRGB(212, 175, 55)
local WOOD = Color3.fromRGB(58, 28, 26)
local DARK_WOOD = Color3.fromRGB(40, 20, 22)
local MARBLE = Color3.fromRGB(34, 28, 32)
local VELVET = Color3.fromRGB(110, 16, 28)
local GEM_GOLD = Color3.fromRGB(255, 196, 46)
local ICE = Color3.fromRGB(140, 222, 255)

local StallBuilder = {}

function StallBuilder.build(position: Vector3, facingDegrees: number?): Model
	local origin = CFrame.new(position) * CFrame.Angles(0, math.rad(facingDegrees or 0), 0)
	local model = Instance.new("Model")
	model.Name = "VermeilExchange"

	local function part(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = origin * offset
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function gold(name: string, size: Vector3, offset: CFrame): Part
		local p = part(name, size, offset, GOLD, Enum.Material.Metal)
		p.Reflectance = 0.25
		return p
	end

	local function surface(target: BasePart, pixelsPerStud: number): SurfaceGui
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = pixelsPerStud
		gui.LightInfluence = 0
		gui.Brightness = 1.4
		gui.Parent = target
		return gui
	end

	local function label(
		parent: Instance,
		text: string,
		size: UDim2,
		position: UDim2,
		color: Color3,
		bold: boolean
	): TextLabel
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = size
		l.Position = position
		l.Text = text
		l.TextColor3 = color
		l.TextScaled = true
		l.FontFace = Font.fromEnum(if bold then Enum.Font.BuilderSansExtraBold else Enum.Font.BuilderSansMedium)
		l.Parent = parent
		return l
	end

	local function decorGem(name: string, size: number, offset: CFrame, color: Color3)
		local gem = part(
			name,
			Vector3.one * size,
			offset * CFrame.Angles(math.rad(45), 0, math.rad(45)),
			color,
			Enum.Material.Neon
		)
		gem.CanCollide = false
		gem.CastShadow = false
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 2
		light.Parent = gem
		CollectionService:AddTag(gem, "SpinDecor")
	end

	-- Floor
	local floor = part("Floor", Vector3.new(18, 0.6, 14), CFrame.new(0, 0.3, 0), MARBLE, Enum.Material.Marble)
	gold("TrimFront", Vector3.new(18.4, 0.3, 0.3), CFrame.new(0, 0.45, -7.05))
	gold("TrimBack", Vector3.new(18.4, 0.3, 0.3), CFrame.new(0, 0.45, 7.05))
	gold("TrimLeft", Vector3.new(0.3, 0.3, 14.4), CFrame.new(-9.05, 0.45, 0))
	gold("TrimRight", Vector3.new(0.3, 0.3, 14.4), CFrame.new(9.05, 0.45, 0))
	part("Carpet", Vector3.new(7, 0.1, 4), CFrame.new(0, 0.05, -9.1), VELVET, Enum.Material.Fabric)

	-- Pillars
	for index, corner in
		{ Vector2.new(-8.2, -6.2), Vector2.new(8.2, -6.2), Vector2.new(-8.2, 6.2), Vector2.new(8.2, 6.2) }
	do
		part(`Pillar{index}`, Vector3.new(1.2, 12, 1.2), CFrame.new(corner.X, 6.6, corner.Y), WOOD, Enum.Material.Wood)
		gold(`PillarBase{index}`, Vector3.new(1.6, 0.4, 1.6), CFrame.new(corner.X, 0.8, corner.Y))
		gold(`PillarCap{index}`, Vector3.new(1.6, 0.4, 1.6), CFrame.new(corner.X, 12.4, corner.Y))
	end

	-- Roof
	part("Roof", Vector3.new(19.4, 1, 15.4), CFrame.new(0, 13.1, 0), DARK_WOOD, Enum.Material.Wood)
	gold("FasciaFront", Vector3.new(19.8, 0.35, 0.2), CFrame.new(0, 12.75, -7.8))
	gold("FasciaBack", Vector3.new(19.8, 0.35, 0.2), CFrame.new(0, 12.75, 7.8))
	gold("FasciaLeft", Vector3.new(0.2, 0.35, 15.8), CFrame.new(-9.8, 12.75, 0))
	gold("FasciaRight", Vector3.new(0.2, 0.35, 15.8), CFrame.new(9.8, 12.75, 0))
	part("RoofCrown", Vector3.new(16, 0.5, 12), CFrame.new(0, 13.85, 0), DARK_WOOD, Enum.Material.Wood)

	-- Sign
	local sign = part("Sign", Vector3.new(12, 2.4, 0.4), CFrame.new(0, 15.3, -5.8), DARK_WOOD, Enum.Material.Wood)
	gold("SignTrim", Vector3.new(12.4, 0.2, 0.5), CFrame.new(0, 14.2, -5.8))
	local signGui = surface(sign, 50)
	local signTitle =
		label(signGui, "VERMEIL EXCHANGE", UDim2.fromScale(0.92, 0.72), UDim2.fromScale(0.04, 0.14), GEM_GOLD, true)
	local signStroke = Instance.new("UIStroke")
	signStroke.Color = Color3.fromRGB(90, 50, 0)
	signStroke.Thickness = 3
	signStroke.Parent = signTitle

	-- Back wall and menu screen
	part("BackWall", Vector3.new(15.2, 12, 0.6), CFrame.new(0, 6.6, 6.2), WOOD, Enum.Material.Wood)
	local screen = part(
		"Screen",
		Vector3.new(11, 6, 0.2),
		CFrame.new(0, 7.6, 5.8),
		Color3.fromRGB(12, 12, 18),
		Enum.Material.SmoothPlastic
	)
	gold("ScreenTop", Vector3.new(11.4, 0.2, 0.25), CFrame.new(0, 10.7, 5.75))
	gold("ScreenBottom", Vector3.new(11.4, 0.2, 0.25), CFrame.new(0, 4.5, 5.75))
	gold("ScreenLeft", Vector3.new(0.2, 6.4, 0.25), CFrame.new(-5.6, 7.6, 5.75))
	gold("ScreenRight", Vector3.new(0.2, 6.4, 0.25), CFrame.new(5.6, 7.6, 5.75))

	local screenGui = surface(screen, 40)
	label(screenGui, "OPEN A CASE", UDim2.fromScale(0.9, 0.16), UDim2.fromScale(0.05, 0.05), GEM_GOLD, true)
	label(
		screenGui,
		"Gem drops  •  Mutations up to ×15",
		UDim2.fromScale(0.9, 0.08),
		UDim2.fromScale(0.05, 0.22),
		Color3.fromRGB(200, 200, 215),
		false
	)
	-- The screen lists the mixed progression cases plus a count of everything else.
	local mixed, others = {}, 0
	for _, case in Catalog.Cases do
		if case.Kind == "Mixed" then
			table.insert(mixed, case)
		else
			others += 1
		end
	end
	local rows = #mixed + 1
	label(
		screenGui,
		`+ {others} themed & Robux cases inside`,
		UDim2.fromScale(0.88, 0.62 / rows * 0.7),
		UDim2.fromScale(0.06, 0.33 + #mixed * 0.62 / rows),
		GEM_GOLD,
		false
	)
	for index, case in mixed do
		local rowHeight = 0.62 / rows
		local y = 0.33 + (index - 1) * rowHeight
		label(
			screenGui,
			`{case.Icon}  {case.Name}`,
			UDim2.fromScale(0.6, rowHeight * 0.8),
			UDim2.fromScale(0.06, y),
			case.Color,
			true
		).TextXAlignment =
			Enum.TextXAlignment.Left
		label(
			screenGui,
			Format.cash(case.Price),
			UDim2.fromScale(0.28, rowHeight * 0.8),
			UDim2.fromScale(0.66, y),
			Color3.fromRGB(235, 235, 245),
			true
		).TextXAlignment =
			Enum.TextXAlignment.Right
	end

	-- Counter (the case terminal)
	local counter = part("Counter", Vector3.new(10, 3.4, 2.2), CFrame.new(0, 2.3, -4.2), WOOD, Enum.Material.Wood)
	gold("CounterTop", Vector3.new(10.4, 0.25, 2.6), CFrame.new(0, 4.125, -4.2))
	gold("CounterInlay", Vector3.new(9.6, 0.15, 0.1), CFrame.new(0, 3.4, -5.35))
	CollectionService:AddTag(counter, "CaseStall")

	local gemBase =
		gold("GemBase", Vector3.new(0.4, 1.4, 1.4), CFrame.new(0, 4.45, -4.2) * CFrame.Angles(0, 0, math.rad(90)))
	gemBase.Shape = Enum.PartType.Cylinder
	decorGem("CounterGem", 1.3, CFrame.new(0, 5.9, -4.2), GEM_GOLD)

	-- Display pedestals: left holds a spinning diamond, right shows the server's best pull.
	for _, side in { -1, 1 } do
		local x = 5.6 * side
		part(`Pedestal{side}`, Vector3.new(2.6, 3.4, 2.6), CFrame.new(x, 2.3, 1.8), WOOD, Enum.Material.Wood)
		gold(`PedestalTop{side}`, Vector3.new(2.8, 0.2, 2.8), CFrame.new(x, 4.1, 1.8))
	end
	local glass = part(
		"DisplayGlass",
		Vector3.new(2.4, 2.6, 2.4),
		CFrame.new(-5.6, 5.5, 1.8),
		Color3.fromRGB(190, 220, 255),
		Enum.Material.Glass
	)
	glass.Transparency = 0.7
	decorGem("DisplayDiamond", 0.9, CFrame.new(-5.6, 5.5, 1.8), ICE)

	local bestPull = part(
		"BestPullScreen",
		Vector3.new(3.4, 2.8, 0.25),
		CFrame.new(5.6, 5.6, 1.8),
		Color3.fromRGB(12, 12, 18),
		Enum.Material.SmoothPlastic
	)
	CollectionService:AddTag(bestPull, "BestPullDisplay")

	-- Lighting
	local lamp = part(
		"Lamp",
		Vector3.new(0.5, 0.5, 0.5),
		CFrame.new(0, 12.2, 0),
		Color3.new(1, 1, 1),
		Enum.Material.SmoothPlastic
	)
	lamp.Transparency = 1
	lamp.CanCollide = false
	lamp.CastShadow = false
	local fill = Instance.new("PointLight")
	fill.Color = Color3.fromRGB(255, 220, 170)
	fill.Range = 26
	fill.Brightness = 1.4
	fill.Parent = lamp
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Color = Color3.fromRGB(255, 230, 180)
	spot.Angle = 60
	spot.Range = 20
	spot.Brightness = 3
	spot.Parent = lamp

	model.PrimaryPart = floor
	model.Parent = Workspace
	return model
end

return StallBuilder
