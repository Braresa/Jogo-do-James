--[[
	Returns the index of the first occurence of a value in a list.

	@param list table
	@param value any

	@return index number?
]]

return function(list: any, value: any)
	local index = nil

	for i, v in ipairs(list) do
		if v == value then
			index = i
			break
		end
	end

	return index
end
