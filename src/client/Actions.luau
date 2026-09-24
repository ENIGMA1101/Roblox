--[[
	Calls to the server. Failures show a toast, so callers only need to check result.ok.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared").Net)

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

return Actions
