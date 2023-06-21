-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ===========================================================================
-- Module Scripts
-- ===========================================================================
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)
local Knit = require(Packages.Knit)
local TableUtil = require(Packages.TableUtil)

-- ===========================================================================
-- Module Scripts
-- ===========================================================================
local Context = RunService:IsServer() and "Server" or "Client"

--[[
	Loads content from a list of modules.

	@param modules A list of modules to load.
	@param logs A list of logs to append to.
]]
local function LoadContent(modules: { any }, logs: { any }?)
	for _, content in ipairs(modules) do
		local type = content[1]
		local path = content[2]

		if not path then
			if logs then
				table.insert(logs, {
					Type = type,
					Name = "N/A",
					Status = "ERROR",
					Message = "Path not found",
					Time = 0,
				})
			end

			continue
		end

		for _, item in ipairs(path:GetDescendants()) do
			local isModule = item:IsA("ModuleScript") and item.Name:match(`{type}$`)

			if not isModule then
				continue
			end

			local loadStart = tick()
			local success, result = pcall(function()
				return require(item)
			end)

			if success then
				if logs then
					table.insert(logs, {
						Type = type,
						Name = item.Name,
						Status = "OK",
						Message = "N/A",
						Time = tick() - loadStart,
					})
				end
			else
				if logs then
					table.insert(logs, {
						Type = type,
						Name = item.Name,
						Status = "ERROR",
						Message = result,
						Time = tick() - loadStart,
					})
				end
			end
		end
	end
end

--[[
	Loads KnitClient or KnitServer.

	@param middleware A list of middleware to load.
	@param logs A list of logs to append to.
]]
local function BootKnit(middleware: { any }?, logs: { any }?)
	local bootStart = tick()
	local success, result = pcall(function()
		return Knit.Start(middleware)
			:andThen(function()
				print(`Knit{Context} started`)
			end)
			:catch(warn)
	end)

	if success then
		if logs then
			table.insert(logs, {
				Type = `Knit{Context}`,
				Name = "Knit",
				Status = "OK",
				Message = "N/A",
				Time = tick() - bootStart,
			})
		end
	else
		error(`Knit{Context} failed to start: {result}`)
	end
end

--[[
	Shows a list of logs in the output.

	@param logs A list of logs to show.
]]
local function ShowLogs(logs: { any }?)
	if logs then
		local longestType = 0
		local longestName = 0
		local longestStatus = 0
		local longestMessage = 0
		local longestTime = 0

		for _, log in ipairs(logs) do
			longestType = math.max(longestType, #log.Type)
			longestName = math.max(longestName, #log.Name)
			longestStatus = math.max(longestStatus, #tostring(log.Status))
			longestMessage = math.max(longestMessage, #tostring(log.Message))
			longestTime = math.max(longestTime, #tostring(log.Time))
		end

		local function pad(str, length): string
			return str .. string.rep(" ", length - #str)
		end

		local feedback = TableUtil.Map(logs, function(log)
			local type = pad(log.Type, longestType)
			local name = pad(log.Name, longestName)
			local status = pad(tostring(log.Status), longestStatus)
			local message = pad(tostring(log.Message), longestMessage)
			local time = pad(tostring(log.Time), longestTime)

			return table.concat({
				"\n",
				`[{type}] -> {name}`,
				`\tStatus  : {status}`,
				`\tMessage : {message}`,
				`\tTime    : {time}`,
			}, "\n")
		end)

		print(table.concat(feedback))
	end
end

--[[
	Loads content and boots Knit.

	@param modules A list of modules to load.
	@param middleware A list of middleware to load.
	@param noLogs Whether or not to show logs.
]]
return function(modules: { any }, middleware: { any }?, noLogs: boolean?)
	local logs = noLogs ~= true and {}

	return Promise.resolve()
		:andThenCall(LoadContent, modules, logs)
		:andThenCall(BootKnit, middleware, logs)
		:andThenCall(ShowLogs, logs)
		:catch(warn)
end
