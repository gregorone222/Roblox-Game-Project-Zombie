-- BuildingModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BuildingModule.lua
-- Script Place: ACT 1: Village

local BuildingManager = {}

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local buildingsFolder = Workspace:FindFirstChild("Buildings")
local backupFolder = ServerStorage:FindFirstChild("BuildingsBackup")

-- MAP BUILDERS
-- Use pcall/WaitForChild safely to avoid race conditions during require
local function safeRequire(name)
	local module = script.Parent:FindFirstChild(name)
	if not module then
		-- Fallback search if naming is inconsistent
		if name == "LobbyBuilderSubway" then
			module = script.Parent:FindFirstChild("LobbyBuilder_Subway")
		end
	end
	if module then return require(module) end
	return nil
end

local LobbyBuilder = safeRequire("LobbyBuilderSubway")
local VillageBuilder = safeRequire("MapBuilderVillage")

function BuildingManager.LoadMap(mapName)
	print("BuildingManager: Loading Map -> " .. mapName)

	-- Cleanup existing maps
	if Workspace:FindFirstChild("LobbyEnvironment") then Workspace.LobbyEnvironment:Destroy() end
	if Workspace:FindFirstChild("Map_Village") then Workspace.Map_Village:Destroy() end

	if mapName == "Lobby" then
		if LobbyBuilder then LobbyBuilder.Build() end
	elseif mapName == "Village" or mapName == "ACT 1: Village" then
		if VillageBuilder then VillageBuilder.Build() end
	else
		warn("Unknown Map: " .. mapName)
	end
end

function BuildingManager.hideBuildings()
	-- Deprecated legacy function kept for compatibility
end

function BuildingManager.restoreBuildings()
	-- Deprecated legacy function kept for compatibility
end

return BuildingManager
