-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local ItemsToBuy = {"Salad","Milk"}
-- ===========================================================================
-- Variables
-- ===========================================================================

-- ===========================================================================
-- Services
-- ===========================================================================
local ShopService = Knit.CreateService({
    Name = "ShopService",
    Client = {
        buyRequest = Knit.CreateSignal()
    },
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

-- ===========================================================================
-- Public Methods
-- ===========================================================================
function ShopService:CheckMoney(Player, item)
    
    if table.find(ItemsToBuy,item) then
        print(item)
        end
end
-- ===========================================================================
-- Knit Initialization
-- ===========================================================================  
--[[
    Initializes the service.
]]
function ShopService:KnitInit()
    print("ShopService initialized")
end

--[[
    Starts the service.
]]
function ShopService:KnitStart()
    print("ShopService started")
    self.Client.buyRequest:Connect(self.CheckMoney)
end

return ShopService