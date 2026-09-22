--[[
	Centered modal windows. Only one is open at a time; opening another closes the current one.
]]

local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

export type Window = {
	Frame: Frame,
	Content: Frame,
	Title: TextLabel,
	open: (self: Window) -> (),
	close: (self: Window) -> (),
	isOpen: (self: Window) -> boolean,
	OnOpen: (() -> ())?,
	OnClose: (() -> ())?,
}

local Window = {}

local current: Window? = nil

function Window.create(name: string, title: string, size: Vector2): Window
	local frame = Kit.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = Colors.Panel,
		Visible = false,
		Parent = Root.layer("Windows"),
	}, {
		Kit.corner(16),
		Kit.stroke(Colors.Stroke, 2),
	})
	local scale = Kit.new("UIScale", { Parent = frame })

	local titleLabel = Kit.label({
		Name = "Title",
		Position = UDim2.fromOffset(22, 14),
		Size = UDim2.new(1, -90, 0, 34),
		Text = title,
		FontFace = Fonts.Heavy,
		TextSize = 28,
		Parent = frame,
	})
	Kit.new("Frame", {
		Name = "TitleRule",
		Position = UDim2.fromOffset(22, 56),
		Size = UDim2.new(1, -44, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = Colors.Gold,
		Parent = frame,
	}, {
		Kit.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.6, 0.8),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local content = Kit.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(22, 70),
		Size = UDim2.new(1, -44, 1, -88),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local window: Window
	window = {
		Frame = frame,
		Content = content,
		Title = titleLabel,
		open = function(self: Window)
			if current and current ~= self then
				current:close()
			end
			current = self
			if frame.Visible then
				return
			end
			frame.Visible = true
			scale.Scale = 0.92
			Kit.tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
			if self.OnOpen then
				self.OnOpen()
			end
		end,
		close = function(self: Window)
			if current == self then
				current = nil
			end
			if not frame.Visible then
				return
			end
			frame.Visible = false
			if self.OnClose then
				self.OnClose()
			end
		end,
		isOpen = function(_self: Window): boolean
			return frame.Visible
		end,
	}

	Kit.button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(38, 38),
		Text = "✕",
		TextSize = 20,
		BackgroundColor3 = Colors.PanelLight,
		Parent = frame,
	}, function()
		window:close()
	end)

	return window
end

function Window.closeAll()
	if current then
		current:close()
	end
end

return Window
