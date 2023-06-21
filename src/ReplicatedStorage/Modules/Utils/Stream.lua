-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Package
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

-- ===========================================================================
-- Module
-- ===========================================================================
local Stream = {}

function Stream.StreamAround(player: Player, position: Vector3, timeOut: number?)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		"[Stream] -> StreamAround() argument #1 must be a Player"
	)
	assert(typeof(position) == "Vector3", "[Stream] -> StreamAround() argument #2 must be a Vector3")
	assert(typeof(timeOut) == "number", "[Stream] -> StreamAround() argument #3 must be a number or nil")

	-- Guaranteed to be streamed in, no need to do anything
	if not workspace.StreamingEnabled then
		return Promise.resolve()
	end

	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			player:RequestStreamAroundAsync(position, timeOut)
		end)

		if not success then
			return reject(result)
		end

		return resolve()
	end)
end
