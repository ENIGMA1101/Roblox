--[[
	Short messages that stack at the top of the screen.
]]

local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors

local Toast = {}

local stack: Frame
local counter = 0

local KIND_COLORS = {
	info = Colors.Accent,
	good = Colors.Good,
	bad = Colors.Bad,
	gold = Colors.Gold,
}

function Toast.start()
	stack = Kit.new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.new(0, 520, 1, -120),
		BackgroundTransparency = 1,
		Parent = Root.layer("Toasts"),
	}, { Kit.list(Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center) })
end

function Toast.show(text: string, kind: string?)
	if not stack then
		return
	end
	local accent = KIND_COLORS[kind or "info"] or Colors.Accent
	counter += 1
	local toast = Kit.new("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = 0.05,
		LayoutOrder = counter,
		Parent = stack,
	}, {
		Kit.corner(10),
		Kit.stroke(accent, 2),
		Kit.padding(10, 16),
	})
	local label = Kit.label({
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Text = text,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Theme.Fonts.Bold,
		TextSize = 19,
		Parent = toast,
	})
	local scale = Kit.new("UIScale", { Scale = 0.8, Parent = toast })
	Kit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)

	task.delay(3.2, function()
		Kit.tween(toast, 0.3, { BackgroundTransparency = 1 })
		Kit.tween(label, 0.3, { TextTransparency = 1 })
		Kit.tween(toast:FindFirstChildOfClass("UIStroke") :: UIStroke, 0.3, { Transparency = 1 })
		task.wait(0.3)
		toast:Destroy()
	end)

	local toasts = {}
	for _, child in stack:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts > 4 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end
end

return Toast
