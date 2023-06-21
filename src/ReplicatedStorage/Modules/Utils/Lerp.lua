--[[
	Returns a number between a and b, based on x.

	@param a number
	@param b number
	@param x number

	@return number
]]

return function(a: number, b: number, x: number)
	return a + ((b - a) * x)
end