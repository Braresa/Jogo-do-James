-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

-- ===========================================================================
-- Variables
-- ===========================================================================

-- ===========================================================================
-- Services
-- ===========================================================================

-- ===========================================================================
-- Controllers
-- ===========================================================================
local DataController = Knit.CreateController({
	Name = "DataController",
	GuiUpdate = Signal.new()
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

-- ===========================================================================
-- Public Methods
-- ===========================================================================
--[[
    Imports the services.
]]
function DataController:ImportServices()
	self.DataService = Knit.GetService("DataService")
end

--[[
    Gets data from the data service.

    @param key The key to get.

    @return A promise that resolves with the data key.
]]
function DataController:GetData(key: any)
	return self.DataService:GetData(key)
end

--[[
    Listen for data changes.

    @param key The key to listen for.
    @param callback The callback to fire when the key changes.

    @return A connection to the event.
]]
function DataController:OnChange(key: any)
	print("Rodado")
	local connection = self.DataService.DataChanged:Connect(function(_key: any, _value: any, _oldValue: any)
		if _key == key then
			self.GuiUpdate(_value, _oldValue)
		end
	end)

	return connection
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the controller.
]]
function DataController:KnitInit()
	print("DataController initialized")
end

--[[
    Starts the controller.
]]
function DataController:KnitStart()
	print("DataController started")
	self:OnChange('Dinheiro')
end

return DataController
