--[[
	Rebirth: trade a run's progress for permanent bonuses.

	Needs Catalog.rebirthCost(Rebirths) cash in hand. Resets cash to StartingCash, luck
	upgrade levels to 0 and removes every item pulled with cash. Keeps exclusives (Robux case
	items and grails), keys, showcase slots, passes, personal Robux luck, the luck bar and
	stats. Each rebirth multiplies item luck by Rebirth.LuckMult and adds Rebirth.SellBonus to
	sell value and showcase income (GameConfig.Rebirth).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

type Data = DataService.Data

local RebirthService = {}

local function rebirth(player: Player, data: Data)
	local cost = Catalog.rebirthCost(data.Rebirths)
	if data.Cash < cost then
		return { ok = false, error = `You need {Format.cash(cost)} cash to rebirth.` }
	end

	local removed = {}
	local kept = 0
	for id, owned in data.Items do
		if Catalog.keptOnRebirth(owned) then
			kept += 1
		else
			data.Items[id] = nil
			table.insert(removed, id)
		end
	end
	data.Rebirths += 1
	data.LuckLevel = 0

	-- Straight back to starting cash (not counted as earned or spent).
	data.Cash = GameConfig.StartingCash
	PlayerState.sync(player, "Cash", data.Cash)
	local stats = player:FindFirstChild("leaderstats")
	local cashStat = stats and stats:FindFirstChild("Cash")
	if cashStat and cashStat:IsA("StringValue") then
		cashStat.Value = Format.cash(data.Cash)
	end
	local rebirthStat = stats and stats:FindFirstChild("Rebirths")
	if rebirthStat and rebirthStat:IsA("IntValue") then
		rebirthStat.Value = data.Rebirths
	end

	if #removed > 0 then
		PlayerState.sync(player, "Items", { Removed = removed })
	end
	PlayerState.sync(player, "Luck", data.LuckLevel)
	PlayerState.sync(player, "Rebirths", data.Rebirths)
	PlayerState.recomputeIncome(player)
	task.spawn(DataService.save, player)

	for _, other in Players:GetPlayers() do
		PlayerState.notify(
			other,
			`🔁 {player.DisplayName} reached Rebirth {data.Rebirths}!`,
			if other == player then "gold" else "info"
		)
	end
	return { ok = true, Rebirths = data.Rebirths, Kept = kept }
end

function RebirthService.start()
	PlayerState.bind("Rebirth", rebirth)
end

return RebirthService
