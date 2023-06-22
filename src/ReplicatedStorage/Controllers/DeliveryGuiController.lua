-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local AppUpdateService = game:GetService("AppUpdateService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Replion = require(ReplicatedStorage.Packages.Replion)
local ReplionClient = Replion.Client

-- ===========================================================================
-- Variables
-- ===========================================================================

local Player = Players.LocalPlayer
local DeliveryGui = Player.PlayerGui:WaitForChild("DeliveryGui")
local Warning = DeliveryGui.Warning
local RequestFrame = DeliveryGui.RequestFrame
local RequestButton = RequestFrame.Request
local OnGoingFrame = DeliveryGui.OnGoing
local CancelButton = OnGoingFrame.CancelButton
local OnDelivery = false
local TimerLabel = OnGoingFrame.Inside.TimerLabel
local MoneyFrame = DeliveryGui.MoneyFrame
local Money = MoneyFrame.Money

local DefaultPosition = {
	[RequestFrame] = RequestFrame.Position,
	[MoneyFrame] = MoneyFrame.Position,
	[OnGoingFrame] = OnGoingFrame.Position
}

local SFX = SoundService:WaitForChild("SFX")

-- ===========================================================================
-- Controllers
-- ===========================================================================
local DeliveryGuiController = Knit.CreateController({
	Name = "DeliveryGuiController",
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

function TweenCreate(gui, speed, animation)
	local enumType = Enum.EasingStyle.Linear
	local tweenInfo = TweenInfo.new(speed, enumType)

	local function playAnimation(targetGui)
		local originalPosition = DefaultPosition[targetGui]
		print(originalPosition)
		if animation == "leftOut" then
			local propertyTable = { Position = targetGui.Position - UDim2.new(0.1, 0, 0, 0) }
			local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
			return tween
		elseif animation == "original" then
			local propertyTable = { Position = originalPosition }
			local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
			return tween
		elseif animation == "rightIn" then
			gui.Position = gui.Position + UDim2.new(0.1, 0, 0, 0)
			local propertyTable = { Position = originalPosition }
			local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
			return tween
		end
		return warn("Nenhuma animação foi inserida.")
	end

	if typeof(gui) == "table" then
		for _, tableGui in ipairs(gui) do
			playAnimation(tableGui):Play()
		end
	else
		playAnimation(gui):Play()
	end
end

local lastMessageAt = 0

local function warnText(text, color)
	lastMessageAt = tick()
	local currentMessage = lastMessageAt
	Warning.TextColor3 = color
	Warning.Text = text
	task.delay(3, function()
		if lastMessageAt == currentMessage then
			Warning.Text = ""
			Warning.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end

function startTimer(expirySeconds)
	local seconds = expirySeconds
	TimerLabel.Text = tostring(seconds)
	while true do
		if not OnDelivery then
			break
		end
		seconds = seconds - 1
		if TimerLabel.Text ~= "0" then
			TimerLabel.Text = tostring(seconds)
		end
		task.wait(1)
	end
end

local function LocationGenerated(expirySeconds, npc)
	OnDelivery = true
	task.defer(startTimer, expirySeconds)

	RequestFrame.Visible = false
	OnGoingFrame.Visible = true
	SFX.DeliveryStarted:Play()
	local highlight = Instance.new("Highlight")
	highlight.Parent = npc
	highlight.FillTransparency = 0.7
	highlight.FillColor = Color3.fromRGB(99, 255, 120)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0
	local arrow = DeliveryGui.Arrow:Clone()
	arrow.Parent = npc.Head
	arrow.Enabled = true

	warnText("Uma entrega começou!", Color3.fromRGB(0, 255, 0))
end

local function FailDelivery()
	OnDelivery = false
	TweenCreate(OnGoingFrame, 0.5, "leftOut")
	OnGoingFrame.Visible = false
	RequestFrame.Visible = true
	TweenCreate({ RequestFrame, MoneyFrame }, 0.5, "original")
	warnText("A entrega falhou!", Color3.fromRGB(255, 0, 0))
	--[[local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(RequestButton, tweenInfo, { BackgroundColor3 = DefaultButtonColor })
	RequestButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	RequestButton.Text = "A entrega falhou!"
	tween:Play()
	]]
end

local function Delivered()
	OnDelivery = false
	TweenCreate(OnGoingFrame, 0.5, "leftOut")
	OnGoingFrame.Visible = false
	RequestFrame.Visible = true
	SFX.DeliveryComplete:Play()
	warnText("A entrega foi um sucesso!", Color3.fromRGB(0, 255, 0))
	TweenCreate({ RequestFrame, MoneyFrame }, 0.5, "original")
end

local function NoSalad() -- Ativado quando o player não possui saladas para entregar.
	warnText("Você não possui nenhuma salada de fruta para entregar!", Color3.fromRGB(255, 0, 0))
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================

function DeliveryGuiController:InitGui()
	self.DeliveryService = Knit.GetService("DeliveryService")
	CancelButton.Activated:Connect(function()
		self:CancelDelivery()
	end)

	self.DeliveryService.DeliveryLocation:Connect(function(expirySeconds: number, npc: Instance)
		LocationGenerated(expirySeconds, npc)
	end)

	self.DeliveryService.Delivered:Connect(function()
		Delivered()
	end)

	self.DeliveryService.FailDelivery:Connect(function()
		FailDelivery()
	end)

	self.DeliveryService.NoSalad:Connect(function()
		NoSalad()
	end)
	self.DeliveryService.Warning:Connect(function(text: string, color: Color3)
		warnText(text, color)
	end)
end

--[[
	- esquerda
	+ direita
]]
function DeliveryGuiController:RequestSalad()
	TweenCreate({ MoneyFrame, RequestFrame }, 0.5, "leftOut")
	self.DeliveryService:GenerateLocation()
end

function DeliveryGuiController:CancelDelivery()
	self.DeliveryService:CancelDelivery()
end

function UpdateMoneyLabel(newValue, oldValue)
	if oldValue > newValue then
		-- perdeu dinheiro
	elseif oldValue < newValue then
		-- ganhou dinheiro
	end
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the controller.
]]
function DeliveryGuiController:KnitInit()
	print("DeliveryGuiController initialized")
end

--[[
    Starts the controller.
]]
function DeliveryGuiController:KnitStart()
	print("DeliveryGuiController started")
	self:InitGui()

	ReplionClient:AwaitReplion("PlayerData", function(data)
		self.Replion = data
		local dinheiro = data:Get("Dinheiro")
		Money.Text = tostring(dinheiro)
		data:OnChange("Dinheiro", UpdateMoneyLabel)
	end)
	RequestButton.Activated:Connect(function()
		warnText("A entrega irá começar em breve!", Color3.fromRGB(255, 255, 255))
		self:RequestSalad()
	end)
end

return DeliveryGuiController
