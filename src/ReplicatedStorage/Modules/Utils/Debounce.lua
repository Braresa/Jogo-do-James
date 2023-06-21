local Debounce = {}
local MT = {}

function Debounce.new()
	return setmetatable({
		Track = {},
	}, MT)
end

function MT.__index(self, index)
	if index == "Track" then
		return self.Track
	end

	return Debounce[index]
end

function Debounce:Set(index: any, timeout: number)
	assert(typeof(index) ~= nil, "[Debounce] -> Invalid argument #1 to Debounce:Set(): index cannot be nil")
	assert(
		timeout == nil or type(timeout) == "number",
		"[Debounce] -> Invalid argument #2 to Debounce:Set(): timeout must be a number or nil"
	)

	local nextTick = timeout and tick() + timeout or 0
	self.Track[index] = nextTick

	if timeout and timeout > 0 then
		task.delay(timeout or 0, function()
			if self.Track[index] == nextTick then
				self.Track[index] = nil
			end
		end)
	end
end

function Debounce:Get(index: any)
	return self.Track[index] ~= nil
end

function Debounce:Destroy()
	self.Track = nil
	setmetatable(self, nil)
end

return {
	new = Debounce.new,
}
