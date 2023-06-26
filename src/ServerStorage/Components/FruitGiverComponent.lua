-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)
local CollectionService = game:GetService("CollectionService")
local Knit = require(ReplicatedStorage.Packages.Knit)
-- ===========================================================================
-- Variables
-- ===========================================================================

-- ===========================================================================
-- Components
-- ===========================================================================
local FruitGiverComponent = Component.new({
	Tag = "FruitGiver",
	Ancestors = {
		workspace,
	},
	Extensions = {},
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

-- ===========================================================================
-- Public Methods
-- ===========================================================================
function FruitGiverComponent:importServices()
	self.CurrencyService = Knit.GetService("CurrencyService")
	self.DeliveryService = Knit.GetService("DeliveryService")
end

function FruitGiverComponent:InitPrompt() 
	local proximityPrompt = self.Instance:FindFirstChildOfClass("ProximityPrompt")
	if not proximityPrompt then
		proximityPrompt = self._trove:Construct(Instance,"ProximityPrompt")
		proximityPrompt.Parent = self.Instance
		proximityPrompt.HoldDuration = 5
		proximityPrompt.ObjectText = "Reabastecer"
		proximityPrompt.ActionText = "Interagir"
	else
		self._trove:Add(proximityPrompt)
	end

	local function onTriggered(player)
		self.CurrencyService:ChangeSalad(player, 100)
	end

	self._trove:Connect(proximityPrompt.Triggered, onTriggered)
end
-- ===========================================================================
-- Component Initialization
-- ===========================================================================
--[[
    Construct is called before the component is started.
    It should be used to construct the component instance.
]]
function FruitGiverComponent:Construct()
	self._trove = Trove.new()
end

--[[
    Start is called when the component is started.
    At this point in time, it is safe to grab other components also bound to the same instance.
]]
function FruitGiverComponent:Start()
	-- import services
	self:importServices()

	--Init prompt
	self:InitPrompt()
end

--[[
    Stop is called when the component is stopped.
    This is called when the bound instance is removed from the whitelisted ancestors or when the tag is removed from the instance.
]]
function FruitGiverComponent:Stop()
	print("FruitGiverComponent stopped")
	self._trove:Destroy()
end

return FruitGiverComponent
