-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- ===========================================================================
-- Module Scripts
-- ===========================================================================
local Modules = ReplicatedStorage.Modules
local Loader = require(Modules.Loader)

-- ===========================================================================
-- Initialization
-- ===========================================================================
local Content = {
	{ "Service", ServerStorage.Services },
	{ "Component", ServerStorage.Components },
}

local Middleware = {}

Loader(Content, Middleware)
