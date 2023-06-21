local Time = {}

local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = SECONDS_PER_MINUTE * 60

function Time.ToH(time: number)
	local hours = math.floor(time / SECONDS_PER_HOUR)

	return string.format("%02d", hours)
end

function Time.ToHM(time: number)
	local hours = math.floor(time / SECONDS_PER_HOUR)
	local minutes = math.floor(time / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE

	return string.format("%02d:%02d", hours, minutes)
end

function Time.ToHMS(time: number)
	local hours = math.floor(time / SECONDS_PER_HOUR)
	local minutes = math.floor(time / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	local seconds = time % SECONDS_PER_MINUTE

	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function Time.ToM(time: number)
	local minutes = math.floor(time / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE

	return string.format("%02d", minutes)
end

function Time.ToMS(time: number)
	local minutes = math.floor(time / SECONDS_PER_MINUTE) % SECONDS_PER_MINUTE
	local seconds = time % SECONDS_PER_MINUTE

	return string.format("%02d:%02d", minutes, seconds)
end

function Time.ToS(time: number)
	local seconds = time % SECONDS_PER_MINUTE

	return string.format("%02d", seconds)
end

return Time
