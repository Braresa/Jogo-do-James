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
local Knit = require(Packages.Knit)

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
	local randomFriend = if destiny:GetAttribute("CustomAvatar")
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
			print("Pages processada, criando npc.")
			local npc = createNPC(friendsId, destiny)
			ActivePlayers[player].NPC = npc
			ActivePlayers[player].Friends = friendsId
			resolve()
		end

		local function getFriendsPage()
			if ActivePlayers[player].Friends ~= nil then
				print(`A tabela de amigos do player {player.Name} já foi obtida, criando um dummy com os amigos dele.`)
				local npc = createNPC(ActivePlayers[player].Friends, destiny)
				ActivePlayers[player].NPC = npc
				resolve()
				return
			end
			local userId = player.UserId
			local success, result = pcall(Players.GetFriendsAsync, Players, userId)

			if success then
				print("Players.GetFriendsAsync foi um sucesso, processando as páginas retornadas.")
				processPages(result)
			else
				warn(`Ocorreu um erro ao tentar pegar os amigos de um player, criando um dummy default.`)
				local npc = createNPC(friendsId, destiny)
				ActivePlayers[player].NPC = npc
				resolve()
			end
		end


		getFriendsPage()
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
	local playerTable = ActivePlayers[player] -- Resetando o player de tudo que envolve ele dentro da entrega.
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
	GetPlayersFriend(player, destiny):finally(function()
		print("A promise de criar o NPC terminou.")
		ActivePlayers[player].Connection = destiny.Touched:Connect(function(hit)
			self:DetectTouch(hit, player, destiny)
		end)
		if destiny:GetAttribute("CustomExpiry") then
			task.defer(initTimer, player, destiny:GetAttribute("CustomExpiry"))
			self.Client.DeliveryLocation:Fire(player, destiny:GetAttribute("CustomExpiry"), ActivePlayers[player].NPC)
		else
			task.defer(initTimer, player, expirySeconds)
			self.Client.DeliveryLocation:Fire(player, expirySeconds, ActivePlayers[player].NPC)
		end
	end)
	return
end

function DeliveryService.Client:GenerateLocation(player)
	return self.Server:GenerateLocation(player)
end

function DeliveryService.Client:CancelDelivery(player)
	return self.Server:DeliverFailed(player)
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
	self:InitServices()
	for _, point in pairs(DeliveryPoint) do
		table.insert(AvailablePoints, point)
	end

	Players.PlayerAdded:Connect(function(player)
		ActivePlayers[player] = {
			Active = false,
			Connection = nil,
			PartUsed = nil,
			LastPart = nil,
			NPC = nil,
			Friends = nil,
		}
	end)

	Players.PlayerRemoving:Connect(function(player)
		if ActivePlayers[player].Active then
			local playerTable = ActivePlayers[player] -- Resetando o player de tudo que envolve ele dentro da entrega.
			playerTable.Active = false
			playerTable.Connection:Disconnect()
			playerTable.Connection = nil
			table.insert(AvailablePoints, playerTable.PartUsed)
			ActivePlayers[player].NPC:Destroy()
		end
		task.wait(5)
		ActivePlayers[player] = nil
	end)
end

return DeliveryService
