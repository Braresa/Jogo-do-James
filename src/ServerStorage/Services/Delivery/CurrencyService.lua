-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ProcessInstancePhysicsService = game:GetService("ProcessInstancePhysicsService")
local ServerStorage = game:GetService("ServerStorage")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local PlayerData = require(ServerStorage.Services.Data.PlayerData)
local Knit = require(Packages.Knit)
-- ===========================================================================
-- Variables
-- ===========================================================================
local FruitsSalad = {}
local DeliveryConfig = require(script.Parent.DeliveryConfig)
local CurrencyName = DeliveryConfig.currencyName
local StartingFruitSalad = DeliveryConfig.startingFruitSalad

-- ===========================================================================
-- Services
-- ===========================================================================
local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {
		UpdateSalad = Knit.CreateSignal(),
		UpdateMoney = Knit.CreateSignal(),
	},
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================


function GetMoney(player)
	local DataService = Knit.GetService('DataService')
	return DataService:GetData(player,CurrencyName):expect()
end

function GiveMoney(player, value)
	local DataService = Knit.GetService('DataService')
		DataService:Increase(player,CurrencyName, value)
	end

function _RemoveMoney(player, value)
	local DataService = Knit.GetService('DataService')
	DataService:Decrease(player,CurrencyName, value)
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================

function CurrencyService:CheckSalad(player)
	return FruitsSalad[player]
end

function CurrencyService:GetMoney(player)
	return GetMoney(player)
end

function CurrencyService:GiveSalad(player, value)
	FruitsSalad[player] = FruitsSalad[player] + value
	self.Client.UpdateSalad:Fire(player, FruitsSalad[player])
end

function CurrencyService:RemoveSalad(player, value)
	FruitsSalad[player] = FruitsSalad[player] - value
	self.Client.UpdateSalad:Fire(player, FruitsSalad[player])
end

function CurrencyService:DeliverSucess(player)
	self:RemoveSalad(player, 1)
	local moneyPerFruit = DeliveryConfig.moneyPerFruitSalad
	local rng = Random.new():NextInteger(1, #moneyPerFruit)
	local valueToGive = moneyPerFruit[rng]
	GiveMoney(player, valueToGive)
	print(GetMoney(player))
end

function CurrencyService:ImportServices()
	self.DataService = Knit.GetService("DataService")
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the service.
]]
function CurrencyService:KnitInit()
	print("CurrencyService initialized")
end

--[[
    Starts the service.
]]
function CurrencyService:KnitStart()
	self:ImportServices()

	Players.PlayerAdded:Connect(function(player)
		FruitsSalad[player] = StartingFruitSalad
	end)

end

return CurrencyService
