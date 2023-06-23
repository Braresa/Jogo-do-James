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
local Promise = require(ReplicatedStorage.Packages.Promise)
local Knit = require(Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- ===========================================================================
-- Variables
-- ===========================================================================

local Player = Players.LocalPlayer
local DeliveryGui = Player.PlayerGui:WaitForChild("DeliveryGui")
local Warning = DeliveryGui.Warning
local RequestFrame = DeliveryGui.RequestFrame
local RequestButton = RequestFrame.Request
local OnGoingFrame = DeliveryGui.OnGoing
local CancelButton = OnGoingFrame.Cancel.CancelButton
local OnDelivery = false
local TimerLabel = OnGoingFrame.Inside.TimerLabel
local MoneyFrame = DeliveryGui.MoneyFrame
local Money = MoneyFrame.Money

local DefaultPosition = {
	[RequestFrame] = RequestFrame.Position,
	[MoneyFrame] = MoneyFrame.Position,
	[OnGoingFrame] = OnGoingFrame.Position,
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
	return Promise.new(function(resolve)
		local guiTrove = Trove.new()
		local enumType = Enum.EasingStyle.Linear
		local tweenInfo = TweenInfo.new(speed, enumType)

		local function createAnimation(targetGui)
			local originalPosition = DefaultPosition[targetGui]
			if animation == "leftOut" then
				local propertyTable = { Position = targetGui.Position - UDim2.new(0.1, 0, 0, 0) }
				local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
				return tween
			elseif animation == "original" then
				local propertyTable = { Position = originalPosition }
				local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
				return tween
			elseif animation == "rightIn" then
				targetGui.Position = targetGui.Position - UDim2.new(0.5, 0, 0, 0)
				local propertyTable = { Position = originalPosition }
				local tween = TweenService:Create(targetGui, tweenInfo, propertyTable)
				return tween
			end
			return warn("Nenhuma animação válida foi inserida.")
		end

		if typeof(gui) == "table" then
			for index, tableGui in ipairs(gui) do
				local tween = createAnimation(tableGui)
				guiTrove:Add(tween)
				if index == #gui then
					tween:Play()
					guiTrove:Connect(tween.Completed, function()
						guiTrove:Destroy()
						resolve()
					end)
				else
					tween:Play()
				end
			end
		else
			local tween = createAnimation(gui)
			guiTrove:Add(tween)
			tween:Play()
			guiTrove:Connect(tween.Completed, function()
				guiTrove:Destroy()
				resolve()
			end)
		end
	end)
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
	TweenCreate(OnGoingFrame, 0.8, "rightIn")

	OnGoingFrame.Visible = true
	RequestFrame.Visible = false
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
	TweenCreate(OnGoingFrame, 0.4, "leftOut"):andThen(function()
		OnGoingFrame.Visible = false
		RequestFrame.Visible = true
		TweenCreate({ RequestFrame, MoneyFrame }, 0.5, "original")
		warnText("A entrega falhou!", Color3.fromRGB(255, 0, 0))
	end)
end

local function Delivered()
	OnDelivery = false
	TweenCreate(OnGoingFrame, 0.5, "leftOut"):andThen(function()
		OnGoingFrame.Visible = false
		RequestFrame.Visible = true
		SFX.DeliveryComplete:Play()
		warnText("A entrega foi um sucesso!", Color3.fromRGB(0, 255, 0))
		TweenCreate({ RequestFrame, MoneyFrame }, 0.5, "original")
	end)
end

local function NoSalad() -- Ativado quando o player não possui saladas para entregar.
	warnText("Você não possui nenhuma salada de fruta para entregar!", Color3.fromRGB(255, 0, 0))
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================

--[[
	- esquerda
	+ direita
]]
function DeliveryGuiController:RequestSalad()
	TweenCreate({ MoneyFrame, RequestFrame }, 0.5, "leftOut"):andThen(function()
		self.DeliveryService:GenerateLocation()
	end)
end

function DeliveryGuiController:CancelDelivery()
	self.DeliveryService:CancelDelivery()
end

function UpdateMoneyLabel(newValue, oldValue)
	if oldValue > newValue then
		print("Perdeu dinheiro")
		Money.Text = tostring(newValue)
	elseif oldValue < newValue then
		print("Ganhou dinheiro")
		Money.Text = tostring(newValue)
	elseif oldValue == nil or oldValue == newValue then
		print("Mesma quantidade")
		Money.Text = tostring(newValue)
	end
end

function DeliveryGuiController:InitGui()
	self.DeliveryService = Knit.GetService("DeliveryService")
	self.DataService = Knit.GetService("DataService")
	local function setupDataUpdate()
		return Promise.new(function(resolve)
			local connection = self.DataService:OnChange(Player,'Dinheiro',UpdateMoneyLabel)
			self._Trove:Add(connection)
			resolve()
		end)
	end

	local function connectServerSignals()
		return Promise.try(function()
			self.DeliveryService.DeliveryLocation:Connect(
				function(expirySeconds: number, npc: Instance) -- Recebe do servidor o sinal de que a entrega começou.
					LocationGenerated(expirySeconds, npc)
				end
			)

			CancelButton.Activated:Connect(
				function() -- Conecta o botão de cancelar com o de cancelar dentro do servidor.
					self:CancelDelivery()
				end
			)

			self.DeliveryService.Delivered:Connect(
				function() -- Recebe do servidor o sinal de que a entrega foi um sucesso.
					Delivered()
				end
			)

			self.DeliveryService.FailDelivery:Connect(function() -- Recebe do servidor o sinal de que a entrega falhou.
				FailDelivery()
			end)

			self.DeliveryService.NoSalad:Connect(function() -- Recebe do servidor o sinal de que você não tem saladas
				NoSalad()
			end)
			self.DeliveryService.Warning:Connect(
				function(text: string, color: Color3) -- Toca um warning predefinido do servidor.
					warnText(text, color)
				end
			)
		end)
	end

	local function setupGui()
		return Promise.try(function()
			MoneyFrame.Visible = true
			RequestFrame.Visible = true
			TweenCreate({ MoneyFrame, RequestFrame }, 1, "rightIn"):andThen(function()
				RequestButton.Activated:Connect(function()
					if not OnDelivery then
						self:RequestSalad()
					else
						warnText("Você já está entregando!", Color3.fromRGB(255, 0, 0))
					end
				end)
			end)
		end)
	end

	--[[setupReplion():andThen(function()
		connectServerSignals():andThenCall(setupGui())
	end)
	]]
	setupDataUpdate():andThenCall(setupGui):andThenCall(connectServerSignals)
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the controller.
]]
function DeliveryGuiController:KnitInit()
	print("DeliveryGuiController initialized")
	self._Trove = Trove.new()
end

--[[
    Starts the controller.
]]
function DeliveryGuiController:KnitStart()
	print("DeliveryGuiController started")
	self:InitGui()
end

return DeliveryGuiController
