--[[
	Per-player cooldown for remote handlers.

		local canOpen = Throttle.new(0.75)
		if not canOpen(player) then return end
]]

local Players = game:GetService("Players")

local Throttle = {}

function Throttle.new(seconds: number): (Player) -> boolean
	local last: { [Player]: number } = {}
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	return function(player: Player): boolean
		local now = os.clock()
		local previous = last[player]
		if previous and now - previous < seconds then
			return false
		end
		last[player] = now
		return true
	end
end

return Throttle
