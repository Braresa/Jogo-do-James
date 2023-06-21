--[[
	Based on the Spring class made by @Fraktality.
	This is a modified version of the Spring class made by @staylow.
]]

-- Roblox Services
local RunService = game:GetService("RunService")

-- Constants
local pi = math.pi
local exp = math.exp
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local tau = pi * 2
local eps = 1e-5

-- Spring definition
local Spring = {}
local MT = {}

-- Updater definition
local Queue = {}
local Connection = nil

--[[
    Gets the value of an index.

    @param [string] index The index to get.

    @return [any] The value of the index.
]]
function MT:__index(index: string)
	if Spring[index] then
		return Spring[index]
	else
		error(`Attempt to get undefined index {tostring(index)}`)
	end
end

--[[
    Sets the value of an index.

    @param [string] index The index to set.
    @param [any] value The value to set the index to.
]]
function MT:__newindex(index: string, value: any)
	if Spring[index] then
		error(`Attempt to set undefined index {tostring(index)}`)
	else
		rawset(self, index, value)
	end
end

--[[
    Constructs a new Spring.

    @param startValue [any] The initial value of the spring.
    @param angularFrequency [number?] The angular frequency of the spring.
    @param dampingRatio [number?] The damping ratio of the spring.

    @return [Spring] The new spring.
]]
function Spring.new(startValue: any, angularFrequency: number?, dampingRatio: number?)
	assert(typeof(startValue) ~= nil, "Invalid argument #1 to Spring.new(): argument expected")

	local af = angularFrequency or 4
	local dr = dampingRatio or 1

	if dr * af < 0 then
		error("[Spring] -> AngularFrequency and DampingRatio does not converge.", 2)
	end

	return setmetatable({
		-- Spring properties
		Goal = startValue,
		Position = startValue,
		Velocity = startValue * 0,

		-- Spring settings
		DampingRatio = dr,
		AngularFrequency = af,
	}, MT)
end

--[[
    Resets the spring to its initial state.

    @param [any] initial The initial value of the spring.

    @return [any] The spring.
]]
function Spring:Reset(goalValue: any)
	assert(self.Goal ~= nil, "Invalid argument #1 to Spring:Reset(): Spring is not running")

	-- Resets the spring
	self.Position = goalValue
	self.Velocity = goalValue * 0
	return self
end

--[[
    Updates the spring.

    @param [number] deltaTime The time since the last update.

    @return [any] The new position of the spring.
]]
function Spring:Update(deltaTime: number)
	assert(self.Goal ~= nil, "Invalid argument #1 to Spring:Update(): Spring is not running")

	-- Updates the spring
	local dt =
		assert(typeof(deltaTime) == "number" and deltaTime, "Invalid argument #1 to Spring:Update(): number expected")
	local dr = self.DampingRatio
	local af = (self.AngularFrequency or 0) * tau
	local g = self.Goal or 0
	local p = self.Position or 0
	local v = self.Velocity or 0

	-- Calculates the new position and velocity
	local offset = p - g
	local decay = exp(-dr * af * dt)
	local position, velocity

	if dr == 1 then
		position = (offset * (1 + af * dt) + v * dt) * decay + g
		velocity = (v * (1 - af * dt) - offset * (af ^ 2 * dt)) * decay
	elseif dr < 1 then
		local e = 1 - dr ^ 2
		local c = sqrt(e)
		local y = af * c
		local i = cos(y * dt)
		local j = sin(y * dt)
		local z

		if c > eps then
			z = j / c
		else
			z = dt * af * (((e ^ 2 * dt ^ 2 - 20 * e) / 120) * dt ^ 2 + 1)
		end

		y = y > eps and j / y or dt * (1 + e * dt ^ 2 * af ^ 2 / 6)

		position = (offset * (i + z * dr) + v * y) * decay + g
		velocity = (v * (i - z * dr) - offset * z * af) * decay
	else
		local x = dr * af * -1
		local y = sqrt(dr ^ 2 - 1) * af
		local r1 = x + y
		local r2 = x - y
		local co2 = (v - offset * r1) / (2 * y)
		local co1 = offset - co2
		local e1 = co1 * exp(r1 * dt)
		local e2 = co2 * exp(r2 * dt)

		position = e1 + e2 + g
		velocity = e1 * r1 + e2 * r2
	end

	self.Position = position
	self.Velocity = velocity

	return position
end

--[[
    Steps the spring.

    @param goal [any] The goal value of the spring.
    @param deltaTime [number] The time since the last update.

    @return [any] The new position of the spring.
]]
function Spring:Step(goal: any, deltaTime: number)
	assert(typeof(goal) ~= nil, "Invalid argument #1 to Spring:Step(): argument expected")
	assert(typeof(deltaTime) == "number", "Invalid argument #2 to Spring:Step(): number expected")

	-- Sets the goal and updates the spring
	self.Goal = goal
	return self:Update(deltaTime)
end

--[[
    Binds a callback to the spring.

    @param callback [function] The callback to bind.
]]
function Spring:Start(callback: any)
	assert(typeof(callback) == "function", "Invalid argument #1 to Spring:Start(): function expected")

	-- Stops the previous callback
	self:Stop()

	-- Adds the callback to the processing queue
	self.Callback = callback
	Queue[self] = callback

	-- Connects the connection if it doesn't exist
	if not Connection then
		local renderStep = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
		Connection = renderStep:Connect(function(deltaTime)
			for spring, fn in pairs(Queue) do
				fn(spring:Update(deltaTime))
			end
		end)
	end
end

--[[
    Unbinds the callback from the spring.
]]
function Spring:Stop()
	assert(self.Goal ~= nil, "Invalid argument #1 to Spring:Stop(): Spring is not running")

	-- Removes the callback from the processing queue
	Queue[self] = nil

	-- Disconnects the connection if there are no more callbacks
	if Connection and next(Queue) == nil then
		Connection:Disconnect()
		Connection = nil
	end
end

--[[
	Destroys the spring.
]]
function Spring:Destroy()
	assert(self.Goal ~= nil, "Invalid argument #1 to Spring:Destroy(): Spring is not running")

	-- Stops the spring and clears the metatable
	self:Stop()
	setmetatable(self, nil)
end

return {
	new = Spring.new,
}
