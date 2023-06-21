-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Package
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

-- ===========================================================================
-- Module
-- ===========================================================================
local Badge = {}

--[[
    Gets the badge info for a badge.

    @param badgeId [number] The badge ID to get the info for.

    @return [ResolvedPromise<BadgeInfo>]
]]
function Badge.GetBadgeInfoAsync(badgeId: number)
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return BadgeService:GetBadgeInfoAsync(badgeId)
		end)

		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

--[[
    Awards a badge to a player.

    @param player [Player] The player to award the badge to.
    @param badgeId [number] The badge ID to award.

    @return [ResolvedPromise<BadgeAwardResult>]
]]
function Badge.AwardBadge(player: Player, badgeId: number)
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return BadgeService:AwardBadge(player.UserId, badgeId)
		end)

		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

--[[
    Checks if a player has a badge.

    @param player [Player] The player to check.
    @param badgeId [number] The badge ID to check.

    @return [ResolvedPromise<boolean>]
]]
function Badge.PlayerHasBadgeAsync(player: Player, badgeId: number)
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if success then
			resolve(result)
		else
			reject(result)
		end
	end)
end

return Badge
