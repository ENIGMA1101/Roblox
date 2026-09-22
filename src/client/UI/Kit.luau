--[[
	Small helpers for building UI in code.

		Kit.new("Frame", { Size = ..., Parent = parent }, { Kit.corner(8), child })
]]

local TweenService = game:GetService("TweenService")

local Sound = require(script.Parent.Parent.Sound)
local Theme = require(script.Parent.Theme)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local Kit = {}

function Kit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className) :: any
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Kit.tween(
	instance: Instance,
	seconds: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function Kit.corner(radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function Kit.round(): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(1, 0) })
end

function Kit.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	return Kit.new("UIStroke", {
		Color = color or Colors.Stroke,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Kit.padding(all: number, horizontal: number?): UIPadding
	local side = UDim.new(0, horizontal or all)
	return Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = side,
		PaddingRight = side,
	})
end

function Kit.list(
	direction: Enum.FillDirection,
	gap: number,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	return Kit.new("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, gap),
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

function Kit.gradient(colors: { Color3 }, rotation: number?, transparency: NumberSequence?): UIGradient
	local keypoints = {}
	for index, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / math.max(#colors - 1, 1), color))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(keypoints),
		Rotation = rotation or 90,
		Transparency = transparency or NumberSequence.new(0),
	})
end

function Kit.label(props: { [string]: any }): TextLabel
	local merged = {
		BackgroundTransparency = 1,
		FontFace = Fonts.Medium,
		TextColor3 = Colors.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for key, value in props do
		merged[key] = value
	end
	return Kit.new("TextLabel", merged)
end

-- A text button with hover and press feedback. Returns the button; set .Active = false to disable.
function Kit.button(props: { [string]: any }, onClick: (() -> ())?): TextButton
	local base = props.BackgroundColor3 or Colors.PanelLighter
	local merged = {
		AutoButtonColor = false,
		BackgroundColor3 = base,
		FontFace = Fonts.Bold,
		TextColor3 = Colors.Text,
		TextSize = 18,
	}
	for key, value in props do
		merged[key] = value
	end
	local button = Kit.new("TextButton", merged, { Kit.corner(8) })
	button:SetAttribute("BaseColor", base)
	local scale = Kit.new("UIScale", { Parent = button })

	local function baseColor(): Color3
		return button:GetAttribute("BaseColor") or base
	end
	button.MouseEnter:Connect(function()
		if button.Active then
			Kit.tween(button, 0.12, { BackgroundColor3 = baseColor():Lerp(Color3.new(1, 1, 1), 0.12) })
		end
	end)
	button.MouseLeave:Connect(function()
		Kit.tween(button, 0.12, { BackgroundColor3 = baseColor() })
		Kit.tween(scale, 0.12, { Scale = 1 })
	end)
	button.MouseButton1Down:Connect(function()
		if button.Active then
			Kit.tween(scale, 0.08, { Scale = 0.95 })
		end
	end)
	button.MouseButton1Up:Connect(function()
		Kit.tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	if onClick then
		button.Activated:Connect(function()
			if button.Active then
				Sound.play("Click")
				onClick()
			end
		end)
	end
	return button
end

-- Recolours a Kit.button; hover effects follow the new colour.
function Kit.setButtonColor(button: TextButton, color: Color3)
	button:SetAttribute("BaseColor", color)
	button.BackgroundColor3 = color
end

return Kit
