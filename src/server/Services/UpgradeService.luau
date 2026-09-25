--[[
	Luck upgrades: players spend cash to permanently raise their gem and mutation odds.
	Levels, prices and boosts come from GameConfig.LuckUpgrades. There is no max level; the
	price grows exponentially.

	Also grants the personal Robux luck stack (Monetization.PersonalLuck).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

type Data = DataService.Data

local UpgradeService = {}

local function buyLuck(player: Player, data: Data)
	local price = Catalog.luckUpgradePrice(data.LuckLevel)
	if not PlayerState.trySpend(player, price) then
		return { ok = false, error = `You need {Format.cash(price)} for the next luck level.` }
	end
	data.LuckLevel += 1
	PlayerState.sync(player, "Luck", data.LuckLevel)
	return { ok = true, Level = data.LuckLevel }
end

-- One personal luck purchase: 2x, then +2x each time.
function UpgradeService.addPersonalLuck(player: Player)
	local data = DataService.get(player)
	if not data then
		error("player data not loaded")
	end
	data.PersonalLuck += 1
	PlayerState.sync(player, "PersonalLuck", data.PersonalLuck)
	PlayerState.notify(
		player,
		`🍀 Personal luck is now {Format.mult(Catalog.personalLuckMult(data.PersonalLuck))}!`,
		"gold"
	)
end

function UpgradeService.start()
	PlayerState.bind("BuyLuck", buyLuck)
end

return UpgradeService
