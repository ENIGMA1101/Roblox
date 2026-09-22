--[[
	Showcase payouts, slot purchases and offline earnings.
	Which items are showcased is managed by PlayerState (SetShowcased / ShowcaseBest).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

type Data = DataService.Data

local Showcase = GameConfig.Showcase

local ShowcaseService = {}

-- Fractions of a dollar carried between ticks so low incomes still add up.
local carry: { [Player]: number } = {}

function ShowcaseService.nextSlotPrice(data: Data): number?
	return Showcase.SlotPrices[data.ShowcaseSlots - Showcase.BaseSlots + 1]
end

local function buySlot(player: Player, data: Data)
	local price = ShowcaseService.nextSlotPrice(data)
	if not price then
		return { ok = false, error = "Your showcase is already maxed out." }
	end
	if not PlayerState.trySpend(player, price) then
		return { ok = false, error = `You need {Format.cash(price)} for the next slot.` }
	end
	data.ShowcaseSlots += 1
	PlayerState.sync(player, "Slots", data.ShowcaseSlots)
	return { ok = true, Slots = data.ShowcaseSlots }
end

local function payOfflineEarnings(player: Player, data: Data)
	if data.LastSeen <= 0 then
		return
	end
	local away = math.min(os.time() - data.LastSeen, Showcase.OfflineMaxSeconds)
	local earned = math.floor(away * PlayerState.showcaseIncome(player) * Showcase.OfflineRate)
	if earned > 0 then
		PlayerState.addCash(player, earned)
		PlayerState.notify(player, `Your showcase earned {Format.cash(earned)} while you were away.`, "good")
	end
end

function ShowcaseService.start()
	PlayerState.bind("BuySlot", buySlot)

	-- PlayerState computes income on the same Loaded event, so wait a frame for it.
	DataService.Loaded:Connect(function(player, data)
		task.defer(payOfflineEarnings, player, data)
	end)

	Players.PlayerRemoving:Connect(function(player)
		carry[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				if DataService.get(player) then
					local total = (carry[player] or 0) + PlayerState.income(player)
					local whole = math.floor(total)
					carry[player] = total - whole
					PlayerState.addCash(player, whole)
				end
			end
		end
	end)
end

return ShowcaseService
