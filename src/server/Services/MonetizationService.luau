--[[
	Developer product receipts (cash packs and case keys).

	ProcessReceipt rules followed here:
	- Only return PurchaseGranted after the grant is saved. If the save fails, return
	  NotProcessedYet and Roblox retries later.
	- Every PurchaseId is remembered in the player's data so a retry never grants twice.

	Gamepasses are handled by Passes.luau.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Format = require(Shared.Format)
local Monetization = require(Shared.Config.Monetization)

local CaseService = require(script.Parent.CaseService)
local DataService = require(script.Parent.DataService)
local PlayerState = require(script.Parent.PlayerState)

local MonetizationService = {}

local handlers: { [number]: (Player) -> () } = {}

local function register(productId: number, handler: (Player) -> ())
	if productId == 0 then
		return
	end
	assert(handlers[productId] == nil, `Monetization: product {productId} is used twice`)
	handlers[productId] = handler
end

function MonetizationService.cashPackAmount(player: Player, pack: Monetization.CashPack): number
	local fromIncome = PlayerState.showcaseIncome(player) * 60 * pack.IncomeMinutes
	return math.floor(math.max(pack.Cash, fromIncome))
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.waitFor(player, 15)
	local handler = handlers[receipt.ProductId]
	if not data or not handler then
		if not handler then
			warn(`[Monetization] no handler for product {receipt.ProductId}`)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	if not table.find(data.Receipts, purchaseId) then
		local ok, err = pcall(handler, player)
		if not ok then
			warn(`[Monetization] product {receipt.ProductId} for {player.Name} failed, will retry: {err}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		DataService.recordReceipt(data, purchaseId)
	end

	if DataService.save(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.start()
	for _, pack in Monetization.CashPacks do
		register(pack.ProductId, function(player)
			local amount = MonetizationService.cashPackAmount(player, pack)
			PlayerState.addCash(player, amount)
			PlayerState.notify(player, `{pack.Name}: +{Format.cash(amount)}`, "good")
		end)
	end

	for _, case in Catalog.Cases do
		register(case.Robux.ProductId, function(player)
			PlayerState.addKeys(player, case.Id, case.Robux.Keys)
			PlayerState.notify(
				player,
				`+{case.Robux.Keys} {case.Name} key{if case.Robux.Keys == 1 then "" else "s"}`,
				"good"
			)
		end)
	end

	for _, case in Catalog.Cases do
		local paid = case.Paid
		if paid then
			register(paid.ProductId, function(player)
				CaseService.openPaid(player, case)
			end)
		end
	end

	MarketplaceService.ProcessReceipt = processReceipt
end

return MonetizationService
