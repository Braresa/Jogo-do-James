-- ===========================================================================
-- Roblox Services
-- ===========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===========================================================================
-- Module Scripts
-- ===========================================================================
local Modules = ReplicatedStorage.Modules
local Loader = require(Modules.Loader)

-- ===========================================================================
-- Initialization
-- ===========================================================================
local Content = {
	{ "Controller", ReplicatedStorage.Controllers },
	{ "Component", ReplicatedStorage.Components },
}

local Middleware = {}

Loader(Content, Middleware)
