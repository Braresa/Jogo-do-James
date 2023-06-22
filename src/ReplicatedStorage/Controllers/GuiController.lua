-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

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
local DefaultRequestPosition = RequestFrame.Position

local SFX = SoundService:WaitForChild("SFX")

-- ===========================================================================
-- Controllers
-- ===========================================================================
local GuiController = Knit.CreateController({
	Name = "GuiController",
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

local lastMessageAt = 0

local function warnText(text,color)
	lastMessageAt = tick()
	local currentMessage = lastMessageAt
	Warning.TextColor3 = color
	Warning.Text = text
	task.delay(3, function() 
		if lastMessageAt == currentMessage then
			Warning.Text = ""
			Warning.TextColor3 = Color3.fromRGB(255,255,255)
		end
	end)
end

function startTimer(expirySeconds)
	local seconds = expirySeconds
	TimerLabel.Text = tostring(seconds)
	while true do
		if not OnDelivery then break end
		seconds = seconds - 1
		if TimerLabel.Text ~= '0' then
		TimerLabel.Text = tostring(seconds)
		end
		task.wait(1)
	end
end

local function LocationGenerated(expirySeconds,npc)
	OnDelivery = true
	task.defer(startTimer,expirySeconds)
	RequestFrame.Visible = false
	OnGoingFrame.Visible = true
	SFX.DeliveryStarted:Play()
	local highlight = Instance.new("Highlight")
	highlight.Parent = npc
	highlight.FillTransparency = 0.7
	highlight.FillColor = Color3.fromRGB(99, 255, 120)
	highlight.OutlineColor = Color3.fromRGB(255,255,255)
	highlight.OutlineTransparency = 0
	local arrow = DeliveryGui.Arrow:Clone()
	arrow.Parent = npc.Head
	arrow.Enabled = true


	warnText("Uma entrega começou!",Color3.fromRGB(0, 255, 0))
end

local function FailDelivery()
	OnDelivery = false
	warnText("A entrega falhou!", Color3.fromRGB(255,0,0))
	OnGoingFrame.Visible = false
	RequestFrame.Visible = true

	--[[local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(RequestButton, tweenInfo, { BackgroundColor3 = DefaultButtonColor })
	RequestButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	RequestButton.Text = "A entrega falhou!"
	tween:Play()
	]]
end

local function Delivered()
	OnDelivery = false
	OnGoingFrame.Visible = false
	RequestFrame.Visible = true
	SFX.DeliveryComplete:Play()
	warnText("A entrega foi um sucesso!",Color3.fromRGB(0, 255, 0))
end

local function NoSalad() -- Ativado quando o player não possui saladas para entregar.
	warnText("Você não possui nenhuma salada de fruta para entregar!", Color3.fromRGB(255,0,0))
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================

function GuiController:InitServices()
	self.DeliveryService = Knit.GetService("DeliveryService")
end

--[[
	- esquerda
	+ direita
]]
function GuiController:RequestSalad()
	local tweenInfo = TweenInfo.new(2.5,Enum.EasingStyle.Linear)
	local tween = TweenService:Create(RequestFrame, tweenInfo, {DefaultRequestPosition = UDim2.new(-1,DefaultRequestPosition.Position.Y)})
	tween:Play()
	
	self.DeliveryService:GenerateLocation()

	--[[local tweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(RequestButton, tweenInfo, { BackgroundColor3 = DefaultButtonColor })
	RequestButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	RequestButton.Text = "A entrega falhou!"
	tween:Play()
	]]
end

function GuiController:CancelDelivery()
	self.DeliveryService:CancelDelivery()
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the controller.
]]
function GuiController:KnitInit()
	print("GuiController initialized")
end

--[[
    Starts the controller.
]]
function GuiController:KnitStart()
	self:InitServices()

	print("GuiController started")
	RequestButton.Activated:Connect(function()
		warnText("A entrega irá começar em breve!",Color3.fromRGB(255,255,255))
		self:RequestSalad()
	end)

	CancelButton.Activated:Connect(function()
		self:CancelDelivery()
	end)

	self.DeliveryService.DeliveryLocation:Connect(function(expirySeconds,npc)
		LocationGenerated(expirySeconds,npc)
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
	self.DeliveryService.Warning:Connect(function(text,color)
		warnText(text, color)
	end)

end

return GuiController
