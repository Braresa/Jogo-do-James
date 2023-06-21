-- ===========================================================================
-- ModuleScript Initialization
-- ===========================================================================
local Utils = { Loaded = {} }
local MT = {}

-- ===========================================================================
-- Meta-methods
-- ===========================================================================
--[[
    Loads a module from the Utils folder

    @param moduleName [string] The name of the module to load

    @return [Module] The loaded module
]]
function MT.__index(self, moduleName)
	-- Check if the module has already been loaded
	if self.Loaded[moduleName] then
		return self.Loaded[moduleName]
	end

	-- Check if the module exists
	local module = script:FindFirstChild(moduleName)
	if not module then
		error(`[{script}] -> Attempt to require a module that does not exist: {moduleName}`)
	elseif not module:IsA("ModuleScript") then
		error(`[{script}] -> Attempt to require a module that is not a ModuleScript: {moduleName}`)
	end

	-- Load the module
	local success, result = pcall(require, module)
	if success then
		self.Loaded[moduleName] = result
	else
		error(`[{script}] -> Error while requiring module: {moduleName}\n{result}`)
	end

	return result
end

return setmetatable(Utils, MT)
