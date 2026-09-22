--[[
	Screen layers. Each layer has a "Canvas" frame that is scaled uniformly so the UI can be
	designed at roughly 1280x760 and still fit phones and big monitors.

	Canvas size in design pixels = viewport / scale, so layouts can use scale positions or
	design-pixel offsets freely.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Kit = require(script.Parent.Kit)

local DESIGN_WIDTH = 1280
local DESIGN_HEIGHT = 760
local MIN_SCALE = 0.55
local MAX_SCALE = 1.4

local Root = {}

local layers: { [string]: Frame } = {}
local scales: { UIScale } = {}
local currentScale = 1

local LAYERS = {
	{ Name = "Hud", Order = 1, IgnoreInset = false },
	{ Name = "Windows", Order = 5, IgnoreInset = false },
	{ Name = "Spin", Order = 10, IgnoreInset = true },
	{ Name = "Toasts", Order = 20, IgnoreInset = false },
}

local function refresh()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	currentScale = math.clamp(math.min(viewport.X / DESIGN_WIDTH, viewport.Y / DESIGN_HEIGHT), MIN_SCALE, MAX_SCALE)
	for _, canvas in layers do
		canvas.Size = UDim2.fromScale(1 / currentScale, 1 / currentScale)
	end
	for _, uiScale in scales do
		uiScale.Scale = currentScale
	end
end

function Root.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, layer in LAYERS do
		local gui = Kit.new("ScreenGui", {
			Name = "Vermeil" .. layer.Name,
			DisplayOrder = layer.Order,
			IgnoreGuiInset = layer.IgnoreInset,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = playerGui,
		})
		local canvas = Kit.new("Frame", {
			Name = "Canvas",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Parent = gui,
		})
		table.insert(scales, Kit.new("UIScale", { Parent = canvas }))
		layers[layer.Name] = canvas
	end

	refresh()
	local function watchCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
		refresh()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()
end

function Root.layer(name: string): Frame
	return layers[name]
end

function Root.scale(): number
	return currentScale
end

-- Full screen size in design pixels (what the "Spin" layer covers).
function Root.size(): Vector2
	local camera = Workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Vector2.new(DESIGN_WIDTH, DESIGN_HEIGHT)
	return viewport / currentScale
end

return Root
