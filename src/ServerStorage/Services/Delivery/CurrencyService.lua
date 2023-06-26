-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)
-- ===========================================================================
-- Variables
-- ===========================================================================
local FruitsSalad = {}
local DeliveryConfig = require(script.Parent.DeliveryConfig)
local CurrencyName = DeliveryConfig.currencyName

-- ===========================================================================
-- Services
-- ===========================================================================
local CurrencyService = Knit.CreateService({
	Name = "CurrencyService",
	Client = {},
	UpdateSalad = Signal.new(),
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

-- ===========================================================================
-- Public Methods
-- ===========================================================================

function CurrencyService:GiveCurrency(player, key, value)
	self.DataService:Increase(player, key, value)
end

function CurrencyService:GetData(player, key)
	return self.DataService:GetData(player, key)
end

function CurrencyService:RestoreSalad(player)
	local maxCapacity = self:GetData(player, "MaxSaladCapacity")
	maxCapacity:andThen(function(maxQuantity)
		FruitsSalad[player] = maxQuantity
		self.UpdateSalad:Fire(player, FruitsSalad[player])
	end)
end

function CurrencyService:CheckSalad(player)
	return FruitsSalad[player]
end
function CurrencyService:ChangeSalad(player, value)
	local expectedValue = FruitsSalad[player] + value
	local maxCapacity = self:GetData(player, "MaxSaladCapacity")
	maxCapacity:andThen(function(maxQuantity)
		if expectedValue <= maxQuantity then
			FruitsSalad[player] = expectedValue
		elseif expectedValue <= 0 then
			FruitsSalad[player] = 0
		elseif expectedValue > maxQuantity then
			FruitsSalad[player] = maxQuantity
		end
		self.UpdateSalad:Fire(player, FruitsSalad[player])
	end)
	self.UpdateSalad:Fire(player, FruitsSalad[player])
end

function CurrencyService:DeliverSucess(player)
	self:ChangeSalad(player, -1)

	local moneyPerFruit = DeliveryConfig.moneyPerFruitSalad
	local rng = Random.new():NextInteger(1, #moneyPerFruit)
	local valueToGive = moneyPerFruit[rng]

	self:GiveCurrency(player, CurrencyName, valueToGive)
end

function CurrencyService:SetupCounter(player, gui, trayTrove)
	local maxCapacity = self:GetData(player, "MaxSaladCapacity")
	maxCapacity:andThen(function(maxQuantity)
		gui.Text = `{FruitsSalad[player]}/{maxQuantity}`
	end)

	trayTrove:Connect(self.UpdateSalad, function()
		maxCapacity:andThen(function(maxQuantity)
			gui.Text = `{FruitsSalad[player]}/{maxQuantity}`
		end)
	end)
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
		FruitsSalad[player] = DeliveryConfig.startingFruitSalad
	end)
end

return CurrencyService
