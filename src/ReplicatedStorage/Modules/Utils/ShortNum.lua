local SUFFIXES = {
	{ Short = "K", Long = "Thousand", Number = 10 ^ 3 },
	{ Short = "M", Long = "Million", Number = 10 ^ 6 },
	{ Short = "B", Long = "Billion", Number = 10 ^ 9 },
	{ Short = "T", Long = "Trillion", Number = 10 ^ 12 },
	{ Short = "Qa", Long = "Quadrillion", Number = 10 ^ 15 },
	{ Short = "Qi", Long = "Quintillion", Number = 10 ^ 18 },
	{ Short = "Sx", Long = "Sextillion", Number = 10 ^ 21 },
	{ Short = "Sp", Long = "Septillion", Number = 10 ^ 24 },
	{ Short = "Oc", Long = "Octillion", Number = 10 ^ 27 },
	{ Short = "No", Long = "Nonillion", Number = 10 ^ 30 },
	{ Short = "De", Long = "Decillion", Number = 10 ^ 33 },
	{ Short = "UnDe", Long = "Undecillion", Number = 10 ^ 36 },
	{ Short = "DuDe", Long = "Duodecillion", Number = 10 ^ 39 },
	{ Short = "TreDe", Long = "Tredecillion", Number = 10 ^ 42 },
	{ Short = "QaDe", Long = "Quattuordecillion", Number = 10 ^ 45 },
	{ Short = "QiDe", Long = "Quindecillion", Number = 10 ^ 48 },
	{ Short = "SxDe", Long = "Sexdecillion", Number = 10 ^ 51 },
	{ Short = "SpDe", Long = "Septendecillion", Number = 10 ^ 54 },
	{ Short = "OcDe", Long = "Octodecillion", Number = 10 ^ 57 },
	{ Short = "NoDe", Long = "Novemdecillion", Number = 10 ^ 60 },
	{ Short = "Vi", Long = "Vigintillion", Number = 10 ^ 63 },
	{ Short = "UnVi", Long = "Unvigintillion", Number = 10 ^ 66 },
	{ Short = "DuVi", Long = "Duovigintillion", Number = 10 ^ 69 },
	{ Short = "TreVi", Long = "Trevigintillion", Number = 10 ^ 72 },
	{ Short = "QaVi", Long = "Quattuorvigintillion", Number = 10 ^ 75 },
	{ Short = "QiVi", Long = "Quinvigintillion", Number = 10 ^ 78 },
	{ Short = "SxVi", Long = "Sexvigintillion", Number = 10 ^ 81 },
	{ Short = "SpVi", Long = "Septenvigintillion", Number = 10 ^ 84 },
	{ Short = "OcVi", Long = "Octovigintillion", Number = 10 ^ 87 },
	{ Short = "NoVi", Long = "Novemvigintillion", Number = 10 ^ 90 },
	{ Short = "Tri", Long = "Trigintillion", Number = 10 ^ 93 },
	{ Short = "UnTri", Long = "Untrigintillion", Number = 10 ^ 96 },
	{ Short = "DuTri", Long = "Duotrigintillion", Number = 10 ^ 99 },
	{ Short = "TreTri", Long = "Tretrigintillion", Number = 10 ^ 102 },
	{ Short = "QaTri", Long = "Quattuortrigintillion", Number = 10 ^ 105 },
	{ Short = "QiTri", Long = "Quintrigintillion", Number = 10 ^ 108 },
	{ Short = "SxTri", Long = "Sextrigintillion", Number = 10 ^ 111 },
	{ Short = "SpTri", Long = "Septentrigintillion", Number = 10 ^ 114 },
	{ Short = "OcTri", Long = "Octotrigintillion", Number = 10 ^ 117 },
	{ Short = "NoTri", Long = "Novemtrigintillion", Number = 10 ^ 120 },
	{ Short = "Qua", Long = "Quadragintillion", Number = 10 ^ 123 },
	{ Short = "UnQua", Long = "Unquadragintillion", Number = 10 ^ 126 },
	{ Short = "DuQua", Long = "Duoquadragintillion", Number = 10 ^ 129 },
	{ Short = "TreQua", Long = "Trequadragintillion", Number = 10 ^ 132 },
	{ Short = "QaQua", Long = "Quattuorquadragintillion", Number = 10 ^ 135 },
	{ Short = "QiQua", Long = "Quinquadragintillion", Number = 10 ^ 138 },
	{ Short = "SxQua", Long = "Sexquadragintillion", Number = 10 ^ 141 },
	{ Short = "SpQua", Long = "Septenquadragintillion", Number = 10 ^ 144 },
	{ Short = "OcQua", Long = "Octoquadragintillion", Number = 10 ^ 147 },
	{ Short = "NoQua", Long = "Novemquadragintillion", Number = 10 ^ 150 },
}

--[[
	Converts a number to a shortened string.

	@param value number

	@return text string
]]
function ToString(value: number): string
	if value < 1000 then
		return tostring(value)
	end

	local suffix = SUFFIXES[#SUFFIXES]
	for i = 1, #SUFFIXES do
		if value < SUFFIXES[i].Number then
			suffix = SUFFIXES[i - 1]
			break
		end
	end

	local shortened = value / suffix.Number
	local rounded = math.floor(shortened * 100) / 100
	return `{rounded}{suffix.Short}`
end

--[[
	Converts a shortened string to a number.

	@param text string

	@return number number
]]
function ToNumber(text: string): number
	local number = tonumber(text)
	if number then
		return number
	end

	local suffix = SUFFIXES[#SUFFIXES]
	for i = 1, #SUFFIXES do
		if text:sub(-#SUFFIXES[i].Short) == SUFFIXES[i].Short then
			suffix = SUFFIXES[i]
			break
		end
	end

	local shortened = tonumber(text:sub(1, -#suffix.Short - 1))
	return shortened * suffix.Number
end

function ToDecimals(number: number, decimals: number)
	return math.floor(number * 10 ^ decimals) / 10 ^ decimals
end

-- Return a metatable so we can call ToString and ToNumber directly
return {
	ToString = ToString,
	ToNumber = ToNumber,
	ToDecimals = ToDecimals,
}
