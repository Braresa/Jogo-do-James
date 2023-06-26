-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- ===========================================================================
-- Packages
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

-- ===========================================================================
-- Variables
-- ===========================================================================
-- Caches
local DataCache = {}
local PendingCache = {}

-- Configs
local DataConfig = require(script.Parent.DataConfig)
local PlayerData = require(script.Parent.PlayerData)

-- Modules
local ProfileService = require(ServerStorage.Modules.ProfileService)

-- ===========================================================================
-- Services
-- ===========================================================================
local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		DataChanged = Knit.CreateSignal(),
	},
	DataChanged = Signal.new(),
	ProfileStore = ProfileService.GetProfileStore(DataConfig.DataStore, PlayerData),
})

-- ===========================================================================
-- Internal Methods
-- ===========================================================================
--[[
	Gets the player's profile from DataStore as a promise.

	@param player The player to get the profile for.

	@return A promise that resolves with the player's profile.
]]
function GetProfile(player: Player)
	-- If the player is cached, return the profile as a resolved promise
	if DataCache[player] then
		return Promise.resolve(DataCache[player])

	-- If data is already being loaded, return the started promise
	elseif PendingCache[player] then
		return PendingCache[player]
	end

	-- If the player is not cached and data is not being loaded, start loading the data
	PendingCache[player] = Promise.new(function(resolve, reject)
		local profile

		for try = 1, 30 do
			profile = DataService.ProfileStore:LoadProfileAsync(tostring(player.UserId))

			if profile and profile.Data then
				break
			end

			if try == 15 then
				warn(`DataStore is taking longer than usual to load profile for: {player} -> ({player.UserId})`)
			end

			task.wait(1)
		end

		if profile then
			resolve(profile)
		else
			reject(`Failed to load data due to DataStore error for: {player} ({player.UserId})`)
		end
	end)
		:andThen(function(profile)
			-- Add the player to the data cache
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile:ListenToRelease(function()
				-- Remove the player from the data cache
				DataCache[player] = nil

				-- Check if the player is still in the game after the profile has been released
				if player and Players:IsDescendantOf(Players) then
					player:Kick("Your data has been released from the server. Rejoin the game.")
				end
			end)

			-- Check if the player is still in the game after the profile has been loaded
			if player and player:IsDescendantOf(Players) then
				DataCache[player] = profile
			else
				profile:Release()
			end

			return Promise.resolve(profile)
		end)
		:finally(function()
			PendingCache[player.UserId] = nil
		end)
		:catch(function(err)
			warn(err)

			if player then
				player:Kick(err)
			end
		end)

	return PendingCache[player]
end

--[[
	Loads the player's profile from DataStore.

	@param player The player to load the profile for.
]]
function LoadProfile(player: Player)
	local loadStart = tick()
	return GetProfile(player):andThen(function()
		print(`Loaded profile for: {player} ({player.UserId}) in {tick() - loadStart} seconds`)
	end)
end

--[[
	Releases the player's profile from DataStore.

	@param player The player to release the profile for.

	@return A promise that resolves with the profile that has been released.
]]
function ReleaseProfile(player: Player)
	if DataCache[player] == nil then
		return Promise.resolve(player)
	else
		local releaseStart = tick()
		return GetProfile(player):andThen(function(profile)
			profile:Release()
		end):finally(function()
			print(`Released profile for: {player.Name} ({player.UserId}) in {tick() - releaseStart} seconds`)
		end)
	end
end

-- ===========================================================================
-- Public Methods
-- ===========================================================================
--[[
	Gets the player's data.

	@param player The player to get the data for.

	@return A promise that resolves with the player's profile.
]]
function DataService:GetProfile(player: Player)
	return GetProfile(player):andThen(function(profile)
		return profile
	end)
end

--[[
	Get the player's data.

	@param player The player to get the data for.
	@param key The key to get the data for.

	@return A promise that resolves with the player's data key.
]]
function DataService:GetData(player: Player, key: any)
	return self:GetProfile(player):andThen(function(profile)
		return profile.Data[key]
	end)
end

function DataService.Client:GetData(player: Player, key: any)
	return self.Server:GetData(player, key):expect()
end

--[[
	Sets the player's data.

	@param player The player to set the data for.
	@param key The key to set the data for.
	@param value The value to set the data for.
]]
function DataService:SetData(player: Player, key: any, value: any)
	self:GetProfile(player):andThen(function(profile)
		local oldValue = self:GetData(player, key):expect()
		profile.Data[key] = value
		self.DataChanged:Fire(player, key, value, oldValue)
	end)
end

--[[
	Increases the player's data.

	@param player The player to increase the data for.
	@param key The key to increase the data for.
	@param value The value to increase the data for.
]]
function DataService:Increase(player: Player, key: any, value: number)
	self:GetProfile(player):andThen(function(profile)
		local oldValue = self:GetData(player, key):expect()
		profile.Data[key] += value
		self.DataChanged:Fire(player, key, profile.Data[key], oldValue)
	end)
end

function DataService:Decrease(player: Player, key: any, value: number)
	self:GetProfile(player):andThen(function(profile)
		local oldValue = self:GetData(player, key):expect()
		profile.Data[key] -= value
		self.DataChanged:Fire(player, key, profile.Data[key], oldValue)
	end)
end

--[[
	Listens for changes to the player's data.

	@param player The player to listen for changes to the data for.
	@param key The key to listen for changes to the data for.
	@param callback The callback to fire when the data changes.

	@return A connection that can be disconnected.
]]
function DataService:OnChange(player: Player, key: any, callback: any)
	local connection = self.DataChanged:Connect(function(_player, _key, value, oldValue)
		if player == _player and key == _key then
			callback(value, oldValue)
		end
	end)

	return connection
end

--[[
	Initializes events.
]]
function DataService:InitEvents()
	Players.PlayerAdded:Connect(LoadProfile)
	Players.PlayerRemoving:Connect(ReleaseProfile)
	for _, player in ipairs(Players:GetPlayers()) do
		LoadProfile(player)
	end
end

--[[
	Initializes replication.
]]
function DataService:InitReplication()
	self.DataChanged:Connect(function(player, ...)
		self.Client.DataChanged:Fire(player, ...)
	end)
end

-- ===========================================================================
-- Knit Initialization
-- ===========================================================================
--[[
    Initializes the service.
]]
function DataService:KnitInit()
	print("DataService initialized")
end

--[[
    Starts the service.
]]
function DataService:KnitStart()
	print("DataService started")

	-- Initialize replication
	self:InitReplication()

	-- Initialize events
	self:InitEvents()

end

return DataService
