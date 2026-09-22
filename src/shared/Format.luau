--[[
	Number and text formatting shared by the UI and the server's messages.
]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimZeros(text: string): string
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text
end

function Format.commas(n: number): string
	local negative = n < 0
	local digits = tostring(math.floor(math.abs(n) + 0.5))
	local out = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	out = string.gsub(out, "^,", "")
	return if negative then "-" .. out else out
end

-- 1234 -> "1.23K", 45600000 -> "45.6M". Always 3 significant digits above 1000.
function Format.short(n: number): string
	local negative = n < 0
	n = math.abs(n)
	if n < 1000 then
		local text = tostring(math.floor(n + 0.5))
		return if negative then "-" .. text else text
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	-- Rounding 999.6K up should read 1M, not 1000K.
	if scaled >= 999.5 and tier < #SUFFIXES - 1 then
		tier += 1
		scaled = n / 10 ^ (tier * 3)
	end
	local decimals = if scaled >= 100 then 0 elseif scaled >= 10 then 1 else 2
	local text = trimZeros(string.format(`%.{decimals}f`, scaled)) .. SUFFIXES[tier + 1]
	return if negative then "-" .. text else text
end

function Format.cash(n: number): string
	return "$" .. Format.short(n)
end

function Format.cashFull(n: number): string
	return "$" .. Format.commas(n)
end

-- Probability (0..1) as a percentage with enough decimals to never show 0 for a real chance.
function Format.chance(p: number): string
	if p <= 0 then
		return "0%"
	end
	local percent = p * 100
	local decimals = math.clamp(math.ceil(-math.log10(percent)) + 2, 0, 6)
	return trimZeros(string.format(`%.{decimals}f`, percent)) .. "%"
end

function Format.oneIn(p: number): string
	if p <= 0 then
		return "never"
	end
	return "1 in " .. Format.commas(1 / p)
end

function Format.mult(m: number): string
	return "×" .. trimZeros(string.format("%.2f", m))
end

function Format.clock(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

return Format
