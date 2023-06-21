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
local Replion
local ReplionServer


-- ===========================================================================
-- Variables
-- ===========================================================================
local FruitsSalad = {}
local CurrencyConfig = require(script.Parent.CurrencyConfig)
local CurrencyName = CurrencyConfig.currencyName
local StartingFruitSalad = CurrencyConfig.startingFruitSalad

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

function getReplion(player)
    return ReplionServer:GetReplionFor(player)
end


function GetMoney(player)
    local playerReplion = getReplion(player)
    return playerReplion:Get(CurrencyName)
end

function GiveMoney(player,value)
    local playerReplion = getReplion(player)
    if playerReplion then
    playerReplion:Increase(CurrencyName, value)
    print(playerReplion:Get(CurrencyName))
    end
end

function RemoveMoney(player,value)
    local playerReplion = getReplion(player)
    if playerReplion then
        playerReplion:Decrease(CurrencyName,value)
    end
end




-- ===========================================================================
-- Public Methods
-- ===========================================================================

function CurrencyService:CheckSalad(player)
    print(`{player.Name} tem {FruitsSalad[player]} de fruta!`)
    return FruitsSalad[player]
end

function CurrencyService:GetMoney(player)
    return GetMoney(player)
end

function CurrencyService:GiveSalad(player,value)
    FruitsSalad[player] = FruitsSalad[player] + value
    self.Client.UpdateSalad:Fire(player,FruitsSalad[player])
end

function CurrencyService:RemoveSalad(player,value)
    FruitsSalad[player] = FruitsSalad[player] - value
    self.Client.UpdateSalad:Fire(player,FruitsSalad[player])
end

function CurrencyService:DeliverSucess(player)
    self:RemoveSalad(player,1)
    local moneyPerFruit = CurrencyConfig.moneyPerFruitSalad
    local rng = Random.new():NextInteger(1, #moneyPerFruit)
    local valueToGive = moneyPerFruit[rng]
    GiveMoney(player,valueToGive)
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
    Replion = require(ReplicatedStorage.Packages.Replion)
    ReplionServer = Replion.Server


    Players.PlayerAdded:Connect(function(player)
        FruitsSalad[player] = StartingFruitSalad
    end)
end

return CurrencyService