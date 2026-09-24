--[[
	Luck upgrades: players spend cash to permanently raise their gem and mutation odds.
	Levels, prices and boosts come from GameConfig.LuckUpgrades.
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
	if not price then
		return { ok = false, error = "Your luck is already maxed out." }
	end
	if not PlayerState.trySpend(player, price) then
		return { ok = false, error = `You need {Format.cash(price)} for the next luck level.` }
	end
	data.LuckLevel += 1
	PlayerState.sync(player, "Luck", data.LuckLevel)
	return { ok = true, Level = data.LuckLevel }
end

function UpgradeService.start()
	PlayerState.bind("BuyLuck", buyLuck)
end

return UpgradeService
