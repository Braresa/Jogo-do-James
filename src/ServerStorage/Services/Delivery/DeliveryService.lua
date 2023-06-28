-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- ===========================================================================
-- Dependencies
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

-- ===========================================================================
-- Variables
-- ===========================================================================

local AvailablePoints = {}
local DeliveryConfig = require(script.Parent.DeliveryConfig)
local ActivePlayers = {}
local expirySeconds = DeliveryConfig.expirySeconds

-- ===========================================================================
-- Services
-- ===========================================================================
local DeliveryService = Knit.CreateService({
	Name = "DeliveryService",
	Client = {
		DeliveryLocation = Knit:CreateSignal(),
		Delivered = Knit:CreateSignal(),
		FailDelivery = Knit:CreateSignal(),
		NoSalad = Knit:CreateSignal(),
		Warning = Knit:CreateSignal(),
	},
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================

function createNPC(friendsId, destiny)
	local randomFriend = if destiny:GetAttribute("CustomAvatar") and destiny:GetAttribute("CustomAvatar") ~= 0
		then destiny:GetAttribute("CustomAvatar")
		else friendsId[Random.new():NextInteger(1, #friendsId)]
	local sucess, humanoidDescription = pcall(Players.GetHumanoidDescriptionFromUserId, Players, randomFriend)

	local function cloneDummy()
		local dummy = DeliveryConfig.dummyLocation
		local clonedDummy = dummy:Clone()
		clonedDummy:PivotTo(CFrame.new(destiny.Position + Vector3.new(0, 4, 0)))
		clonedDummy:WaitForChild("HumanoidRootPart").Orientation = Vector3.new(0, destiny.Orientation.Y, 0)
		clonedDummy.Parent = game.Workspace
		clonedDummy.HumanoidRootPart.Anchored = false
		return clonedDummy
	end

	if sucess then
		local appearanceInfo = humanoidDescription
		local clonedDummy = cloneDummy()
		local humanoid = clonedDummy:WaitForChild("Humanoid")
		humanoid:ApplyDescription(appearanceInfo)
		return clonedDummy
	else
		local clonedDummy = cloneDummy()
		return clonedDummy
	end
end

function GetPlayersFriend(player, destiny)
	return Promise.new(function(resolve)
		local friendsId = {}

		local function processPages(page)
			local n = 1
			while true do
				for _, item in ipairs(page:GetCurrentPage()) do
					table.insert(friendsId, item.Id)
				end
				if page.IsFinished then
					break
				end
				page:AdvanceToNextPageAsync()
				n += 1
			end
			local npc = createNPC(friendsId, destiny)
			ActivePlayers[player].NPC = npc
			ActivePlayers[player].Friends = friendsId
			resolve()
		end

		if ActivePlayers[player].Friends ~= nil then
			local npc = createNPC(ActivePlayers[player].Friends, destiny)
			ActivePlayers[player].NPC = npc
			resolve()
			return
		end
		local userId = player.UserId
		local success, result = pcall(Players.GetFriendsAsync, Players, userId)

		if success then
			processPages(result)
		else
			local npc = createNPC(friendsId, destiny)
			ActivePlayers[player].NPC = npc
			resolve()
		end
	end)
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================

function DeliveryService:InitServices() -- Set the variables for the service that the script will use.
	self.CurrencyService = Knit.GetService("CurrencyService")
end

--[[
	Remove the player from the state of delivering.
	@param player The player to execute this function.
]]
function resetPlayer(player)
	local playerTable = ActivePlayers[player]
	playerTable.Active = false
	playerTable.Connection:Disconnect()
	playerTable.Connection = nil
	table.insert(AvailablePoints, playerTable.PartUsed)
	ActivePlayers[player].NPC:Destroy()
end

--[[
	Communicate to the client and the service(s) that the delivery was a sucess.
	@param player The player to execute this function.
]]
function DeliveryService:DeliverSucess(player)
	resetPlayer(player)
	self.Client.Delivered:Fire(player) -- Avisando ao cliente que a entrega foi um sucesso.
	self.CurrencyService:DeliverSucess(player) -- Avisando ao CurrencyService que a entrega foi um sucesso.
end

--[[
	Communicate to the client and the service(s) that the delivery has failed.
	@param player The player to execute this function.
]]
function DeliveryService:DeliverFailed(player)
	resetPlayer(player)
	ActivePlayers[player].LastPart = nil
	self.Client.FailDelivery:Fire(player)
end

--[[
	Create a touch event that detects which player touched.
	@param otherPart The part that touched.
	@param player The player which "owns" this part.
	@originalPart The original part that is getting this touched event.
]]
function DeliveryService:DetectTouch(otherPart, player, originalPart)
	local character = otherPart:FindFirstAncestorOfClass("Model")
	local humanoid = if not character then nil else character:FindFirstChild("Humanoid")
	local playerCheck = if not character then nil else Players:GetPlayerFromCharacter(character)
	if not humanoid then
		return
	end
	if playerCheck == player then
		ActivePlayers[player].LastPart = originalPart
		self:DeliverSucess(player)
	end
end
--[[
	Gets a random point from the available points.
	@param player The player to get this deliverypoint.
]]
function createRNG(player)
	local rn = Random.new()
	local rng = rn:NextInteger(1, #AvailablePoints)
	local destiny = AvailablePoints[rng]

	while destiny == ActivePlayers[player].LastPart and #AvailablePoints > 1 do
		rng = rn:NextInteger(1, #AvailablePoints)
		destiny = AvailablePoints[rng]
	end
	table.remove(AvailablePoints, rng)
	ActivePlayers[player].PartUsed = destiny
	return destiny
end
-- ===========================================================================
-- Private Methods
-- ===========================================================================

--[[
	Determine the seconds that the delivery will take.
	@param player The player to execute this function.
	@param destiny The destiny of the delivery.
	@return The seconds that the delivery will take.
]]

function determineDeliverySeconds(player, destiny)
	local distance = (player.Character.HumanoidRootPart.Position - destiny.Position).Magnitude
	local seconds = math.floor(distance / 100) * 10
	if seconds > 10 and seconds < 40 then
		seconds = 30
	elseif seconds > 30 and seconds < 60 then
		seconds = 45
	elseif seconds > 60 and seconds < 90 then
		seconds = 60
	elseif seconds >= 90 then
		seconds = 80
	end
	return seconds
end

--[[
	Initiate the timer of the delivery.
	@param player The player to execute this function.
]]
function initTimer(player, DefaultSeconds)
	local self = Knit.GetService("DeliveryService")
	local seconds = DefaultSeconds
	while task.wait(1) do
		if ActivePlayers[player].Active == false then
			break
		end
		if seconds <= 0 then
			self:DeliverFailed(player)
			break
		end
		seconds = seconds - 1
	end
end
--[[
	Generate the delivery location.
	@param player The player to execute this function.
]]

function DeliveryService:GenerateLocation(player) -- Cria uma localização baseada nos pontos de entrega disponível, e detecta qual foi a última entrega do player para não repetir.
	if ActivePlayers[player].Active == true then
		return print(`{player.Name} já está entregando.`)
	end
	if self.CurrencyService:CheckSalad(player) <= 0 then
		self.Client.NoSalad:Fire(player)
		return
	end
	ActivePlayers[player].Active = true

	local destiny = createRNG(player)
	determineDeliverySeconds(player, destiny)
	GetPlayersFriend(player, destiny):finally(function()
		ActivePlayers[player].Connection = destiny.Touched:Connect(function(hit)
			self:DetectTouch(hit, player, destiny)
		end)
		local secondsToDelivery = determineDeliverySeconds(player, destiny)
		task.defer(initTimer, player, secondsToDelivery)
		self.Client.DeliveryLocation:Fire(player, secondsToDelivery, ActivePlayers[player].NPC)
	end)
	return
end

function DeliveryService.Client:GenerateLocation(player)
	return self.Server:GenerateLocation(player)
end

function DeliveryService.Client:CancelDelivery(player)
	if ActivePlayers[player].Active == true then
		self.Server:DeliverFailed(player)
	end
end
-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the service.
]]
function DeliveryService:KnitInit()
	print("DeliveryService initialized")
end

--[[
    Starts the service.
]]
function DeliveryService:KnitStart()
	local DeliveryPoint = CollectionService:GetTagged("DeliveryPoint")
	if #DeliveryPoint == 0 then
		error("Nenhum DeliveryPoint encontrado! Adicione a tag DeliveryPoint em um part para que o script funcione.")
		return
	end
	self:InitServices()
	for _, point in pairs(DeliveryPoint) do
		if point:GetAttribute("Enabled") == false then
			continue
		else
			table.insert(AvailablePoints, point)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		ActivePlayers[player] = {
			Active = false,
			Connection = nil,
			PartUsed = nil,
			LastPart = nil,
			NPC = nil,
			Friends = nil,
			PlayerTrove = Trove.new(),
		}
		local playersTable = ActivePlayers[player]
		local trayTrove
		playersTable.PlayerTrove:Connect(player.CharacterAdded, function(character)
			if trayTrove then
				trayTrove:Destroy()
			else
				trayTrove = playersTable.PlayerTrove:Extend()
			end

			local trayCloned = DeliveryConfig.trayLocation:Clone()
			local counterGui = trayCloned.Handle.MaxSalad.Gui.Quantity

			trayCloned.Parent = player.Backpack
			local humanoid = character:FindFirstChild("Humanoid")
			humanoid:EquipTool(trayCloned)
			self.CurrencyService:SetupCounter(player, counterGui, trayTrove)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if ActivePlayers[player].Active then
			local playerTable = ActivePlayers[player] -- Resetando o player de tudo que envolve ele dentro da entrega.
			playerTable.Active = false
			playerTable.Connection:Disconnect()
			playerTable.Connection = nil
			table.insert(AvailablePoints, playerTable.PartUsed)
			playerTable.NPC:Destroy()
			playerTable.PlayerTrove:Destroy()
		end
		task.wait(5)
		ActivePlayers[player] = nil
	end)
end

return DeliveryService
