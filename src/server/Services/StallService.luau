--[[
	Hooks the map up to the game:
	- builds the Vermeil Exchange stall if the map has no part tagged "CaseStall"
	- gives every "CaseStall" part an "Open Cases" ProximityPrompt (the client opens the shop)
	- keeps every "BestPullDisplay" part showing the best pull in this server

	Using your own map: tag your counter part "CaseStall" (and any screen "BestPullDisplay")
	with the Tag Editor, and the auto-build is skipped.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)

local CaseService = require(script.Parent.CaseService)
local StallBuilder = require(script.Parent.StallBuilder)

local CONFIG = {
	AutoBuild = true,
	Position = Vector3.new(50, 0, 50),
	FacingDegrees = 0, -- 0 = counter faces -Z
	PromptDistance = 12,
}

local STALL_TAG = "CaseStall"
local DISPLAY_TAG = "BestPullDisplay"
local PROMPT_NAME = "OpenCasesPrompt"

local StallService = {}

type Best = { Value: number, Owned: { I: string, B: string, M: string? }, PlayerName: string }
local best: Best? = nil

local function inWorkspace(instance: Instance): boolean
	return instance:IsDescendantOf(Workspace)
end

local function addPrompt(instance: Instance)
	if not instance:IsA("BasePart") or not inWorkspace(instance) or instance:FindFirstChild(PROMPT_NAME) then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Open Cases"
	prompt.ObjectText = "Vermeil Exchange"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = instance
end

local function text(parent: Instance, name: string, size: UDim2, position: UDim2, bold: boolean): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(235, 235, 245)
	label.FontFace = Font.fromEnum(if bold then Enum.Font.BuilderSansExtraBold else Enum.Font.BuilderSansMedium)
	label.Text = ""
	label.Parent = parent
	return label
end

local function buildDisplay(part: BasePart): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BestPullGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0
	gui.Brightness = 1.3

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	frame.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Thickness = 6
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Color3.fromRGB(212, 175, 55)
	stroke.Parent = frame

	local title = text(frame, "Title", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.04), true)
	title.Text = "SERVER BEST PULL"
	title.TextColor3 = Color3.fromRGB(255, 196, 46)
	text(frame, "Icon", UDim2.fromScale(0.9, 0.32), UDim2.fromScale(0.05, 0.17), false)
	text(frame, "ItemName", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.5), true)
	text(frame, "Brand", UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.62), false)
	text(frame, "Mutation", UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.05, 0.7), true)
	text(frame, "Value", UDim2.fromScale(0.9, 0.1), UDim2.fromScale(0.05, 0.78), true).TextColor3 =
		Color3.fromRGB(255, 196, 46)
	text(frame, "Player", UDim2.fromScale(0.9, 0.07), UDim2.fromScale(0.05, 0.89), false).TextColor3 =
		Color3.fromRGB(150, 150, 170)

	gui.Parent = part
	return gui
end

local function renderDisplay(part: Instance)
	if not part:IsA("BasePart") or not inWorkspace(part) then
		return
	end
	local gui = part:FindFirstChild("BestPullGui") or buildDisplay(part)
	local frame = gui:FindFirstChild("Frame") :: Frame
	local function set(name: string, value: string, color: Color3?)
		local label = frame:FindFirstChild(name) :: TextLabel
		label.Text = value
		if color then
			label.TextColor3 = color
		end
	end

	if not best then
		set("Icon", "💎")
		set("ItemName", "No pulls yet")
		set("Brand", "Be the first!")
		set("Mutation", "")
		set("Value", "")
		set("Player", "")
		return
	end

	local current = best :: Best
	local item = Catalog.ItemById[current.Owned.I]
	local rarity = Catalog.RarityById[item.Rarity]
	local mutation = current.Owned.M and Catalog.MutationById[current.Owned.M]
	set("Icon", item.Icon)
	set("ItemName", item.Name, rarity.Color)
	set("Brand", `{Catalog.Brands[current.Owned.B].Name}  •  {rarity.Name}`)
	if mutation then
		set("Mutation", `{mutation.Name} {Format.mult(mutation.Mult)}`, mutation.Color)
	else
		set("Mutation", "")
	end
	set("Value", Format.cashFull(current.Value))
	set("Player", `pulled by {current.PlayerName}`)
	local stroke = frame:FindFirstChild("Stroke") :: UIStroke
	stroke.Color = rarity.Color
end

local function renderAll()
	for _, part in CollectionService:GetTagged(DISPLAY_TAG) do
		renderDisplay(part)
	end
end

function StallService.start()
	local hasStall = false
	for _, instance in CollectionService:GetTagged(STALL_TAG) do
		if inWorkspace(instance) then
			hasStall = true
		end
	end
	if not hasStall and CONFIG.AutoBuild then
		StallBuilder.build(CONFIG.Position, CONFIG.FacingDegrees)
	end

	for _, instance in CollectionService:GetTagged(STALL_TAG) do
		addPrompt(instance)
	end
	CollectionService:GetInstanceAddedSignal(STALL_TAG):Connect(addPrompt)

	renderAll()
	CollectionService:GetInstanceAddedSignal(DISPLAY_TAG):Connect(renderDisplay)

	CaseService.Opened:Connect(function(player, _case, results)
		local improved = false
		for _, result in results do
			if not best or result.Value > (best :: Best).Value then
				best = {
					Value = result.Value,
					Owned = { I = result.I, B = result.B, M = result.M },
					PlayerName = player.DisplayName,
				}
				improved = true
			end
		end
		if improved then
			renderAll()
		end
	end)
end

return StallService
