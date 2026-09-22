--[[
	Always-on HUD: cash and income at the top, menu buttons and the free case timer on the left.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local State = require(script.Parent.Parent.State)
local Inventory = require(script.Parent.Inventory)
local Kit = require(script.Parent.Kit)
local Root = require(script.Parent.Root)
local Spinner = require(script.Parent.Spinner)
local Store = require(script.Parent.Store)
local Theme = require(script.Parent.Theme)
local Toast = require(script.Parent.Toast)

local Colors = Theme.Colors
local Fonts = Theme.Fonts

local Hud = {}

local cashLabel: TextLabel
local incomeLabel: TextLabel
local freeLabel: TextLabel
local freeStroke: UIStroke
local shownCash = Instance.new("NumberValue")
local cashTween: Tween? = nil

local function sideButton(parent: Instance, order: number, icon: string, text: string, onClick: () -> ()): TextButton
	local button = Kit.button({
		LayoutOrder = order,
		Size = UDim2.fromOffset(86, 86),
		Text = "",
		BackgroundColor3 = Colors.Panel,
		Parent = parent,
	}, onClick)
	Kit.stroke(Colors.Stroke, 2).Parent = button
	Kit.label({
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 0, 40),
		Text = icon,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	Kit.label({
		Name = "Caption",
		Position = UDim2.new(0, 4, 1, -30),
		Size = UDim2.new(1, -8, 0, 22),
		Text = text,
		TextScaled = true,
		FontFace = Fonts.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = button,
	})
	return button
end

local function claimFree()
	local remaining = State.FreeCaseReadyAt - State.serverNow()
	if remaining > 0 then
		Toast.show(`Free case ready in {Format.clock(remaining)}`, "info")
		return
	end
	Spinner.run(Catalog.CaseById[GameConfig.FreeCase.CaseId], 1, true)
end

function Hud.start()
	local layer = Root.layer("Hud")

	local top = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(320, 78),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = 0.1,
		Parent = layer,
	}, { Kit.corner(14), Kit.stroke(Colors.GoldDeep, 2, 0.3) })
	cashLabel = Kit.label({
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 40),
		Text = "Loading…",
		FontFace = Fonts.Heavy,
		TextSize = 36,
		TextColor3 = Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})
	incomeLabel = Kit.label({
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		FontFace = Fonts.Bold,
		TextSize = 18,
		TextColor3 = Colors.Good,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	local side = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(86, 380),
		BackgroundTransparency = 1,
		Parent = layer,
	}, { Kit.list(Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center) })
	sideButton(side, 1, "🎒", "Items", function()
		Inventory.open("Items")
	end)
	sideButton(side, 2, "⭐", "Showcase", function()
		Inventory.open("Showcase")
	end)
	sideButton(side, 3, "🛒", "Store", function()
		Store.toggle()
	end)
	local freeButton = sideButton(side, 4, "🎁", "", claimFree)
	freeLabel = freeButton:FindFirstChild("Caption") :: TextLabel
	freeStroke = freeButton:FindFirstChildOfClass("UIStroke") :: UIStroke

	shownCash.Changed:Connect(function(value)
		cashLabel.Text = Format.cash(value)
	end)
	State.Changed:Connect(function(kind)
		if kind == "Cash" or kind == "State" then
			local target = State.Cash
			-- Big jumps (sales, big pulls) roll up; the per-second income tick just snaps.
			if math.abs(target - shownCash.Value) > math.max(State.Income * 2, 1) then
				cashTween = Kit.tween(shownCash, 0.6, { Value = target }, Enum.EasingStyle.Quart)
			else
				if cashTween then
					cashTween:Cancel()
					cashTween = nil
				end
				shownCash.Value = target
			end
		end
		if kind == "Income" or kind == "State" then
			incomeLabel.Text = `+{Format.cash(State.Income)}/s`
		end
	end)

	task.spawn(function()
		local pulse = 0
		while true do
			local remaining = State.FreeCaseReadyAt - State.serverNow()
			if not State.Loaded then
				freeLabel.Text = "…"
			elseif remaining > 0 then
				freeLabel.Text = Format.clock(remaining)
				freeLabel.TextColor3 = Colors.Text
				freeStroke.Color = Colors.Stroke
				freeStroke.Thickness = 2
			else
				pulse += 1
				freeLabel.Text = "FREE!"
				freeLabel.TextColor3 = Colors.Gold
				freeStroke.Color = Colors.Gold
				freeStroke.Thickness = if pulse % 2 == 0 then 3.5 else 2
			end
			task.wait(0.5)
		end
	end)
end

return Hud
