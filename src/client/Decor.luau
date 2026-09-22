--[[
	Spins and bobs every part tagged "SpinDecor" (the gems on the stall). Done on the client
	so it is perfectly smooth and costs the server nothing.
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Decor = {}

local bases: { [BasePart]: CFrame } = {}

local function add(instance: Instance)
	if instance:IsA("BasePart") then
		bases[instance] = instance.CFrame
	end
end

function Decor.start()
	for _, instance in CollectionService:GetTagged("SpinDecor") do
		add(instance)
	end
	CollectionService:GetInstanceAddedSignal("SpinDecor"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("SpinDecor"):Connect(function(instance)
		bases[instance :: BasePart] = nil
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for part, base in bases do
			local bob = Vector3.new(0, math.sin(t * 2 + base.Position.X) * 0.15, 0)
			part.CFrame = CFrame.new(base.Position + bob) * CFrame.Angles(0, t * 1.2, 0) * base.Rotation
		end
	end)
end

return Decor
