--[[
	Calls to the server. Failures show a toast, so callers only need to check result.ok.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)

local Sound = require(script.Parent.Sound)
local Toast = require(script.Parent.UI.Toast)

export type Result = { ok: boolean, error: string?, [string]: any }

local Actions = {}

local function call(name: string, ...: any): Result
	local remote = Net.fn(name)
	local ok, result = pcall(remote.InvokeServer, remote, ...)
	if not ok or type(result) ~= "table" then
		result = { ok = false, error = "Couldn't reach the server. Try again." }
	end
	if not result.ok and result.error then
		Toast.show(result.error, "bad")
		Sound.play("Error")
	end
	return result
end

function Actions.openCase(caseId: string, count: number): Result
	return call("OpenCase", caseId, count)
end

function Actions.claimFreeCase(): Result
	return call("ClaimFreeCase")
end

function Actions.sell(ids: { string }): Result
	local result = call("SellItems", ids)
	if result.ok and result.Count > 0 then
		Sound.play("Sell")
	end
	return result
end

function Actions.sellAll(maxRarityOrder: number): Result
	local result = call("SellAll", maxRarityOrder)
	if result.ok and result.Count > 0 then
		Sound.play("Sell")
	end
	return result
end

function Actions.setLocked(id: string, locked: boolean): Result
	return call("SetLocked", id, locked)
end

function Actions.setShowcased(id: string, showcased: boolean): Result
	return call("SetShowcased", id, showcased)
end

function Actions.showcaseBest(): Result
	return call("ShowcaseBest")
end

function Actions.buySlot(): Result
	local result = call("BuySlot")
	if result.ok then
		Sound.play("Purchase")
	end
	return result
end

function Actions.buyLuck(): Result
	local result = call("BuyLuck")
	if result.ok then
		Sound.play("Purchase")
	end
	return result
end

function Actions.debug(action: string, arg: any?): Result
	return call("Debug", action, arg)
end

-- Robux cases ----------------------------------------------------------------------------------

local robuxPrices: { [number]: number } = {}

-- The case's real Robux price once fetched (falls back to the price in Cases.luau).
function Actions.robuxPrice(case: Catalog.Case): number
	local paid = case.Paid :: { ProductId: number, Robux: number }
	local productId = paid.ProductId
	if productId ~= 0 and robuxPrices[productId] == nil then
		robuxPrices[productId] = paid.Robux
		task.spawn(function()
			local ok, info =
				pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
			if ok and info and info.PriceInRobux then
				robuxPrices[productId] = info.PriceInRobux
			end
		end)
	end
	return robuxPrices[productId] or paid.Robux
end

-- True while a purchase prompt is waiting for its case to open (the spinner shows it).
Actions.waitingPaid = nil :: string?

--[[
	Prompts the Robux purchase and yields until the server has opened the case (returns the
	results), the player cancels, or it takes too long (the item still lands in the inventory).
]]
function Actions.openPaid(case: Catalog.Case): Result
	local paid = case.Paid :: { ProductId: number, Robux: number }
	if paid.ProductId == 0 then
		local result = { ok = false, error = "This case isn't on sale yet (no ProductId set)." }
		Toast.show(result.error :: string, "bad")
		return result
	end

	local response: Result? = nil
	local purchaseConnection = MarketplaceService.PromptProductPurchaseFinished:Connect(
		function(_userId, productId, purchased)
			if productId == paid.ProductId and not purchased and response == nil then
				response = { ok = false }
			end
		end
	)
	local openConnection = Net.event("PaidOpen").OnClientEvent:Connect(function(caseId: string, result: Result)
		if caseId == case.Id then
			response = result
		end
	end)

	Actions.waitingPaid = case.Id
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, paid.ProductId)
	local deadline = os.clock() + 90
	while response == nil and os.clock() < deadline do
		task.wait()
	end
	Actions.waitingPaid = nil
	purchaseConnection:Disconnect()
	openConnection:Disconnect()

	local result = response
		or {
			ok = false,
			error = "Your purchase is still processing. The item will appear in your inventory.",
		}
	if not result.ok and result.error then
		Toast.show(result.error, "bad")
	end
	return result
end

return Actions
