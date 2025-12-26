-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

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
		if name == "LobbyBuilderFarmhouse" then
			module = script.Parent:FindFirstChild("LobbyBuilder_Farmhouse")
		end
	end
	if module then return require(module) end
	return nil
end

-- UPDATED: Use Farmhouse lobby (Cozy Apocalypse theme)
local LobbyBuilder = safeRequire("LobbyBuilderFarmhouse")
local VillageBuilder = safeRequire("MapBuilderVillage")

function BuildingManager.LoadMap(mapName)
	print("BuildingManager: Loading Map -> " .. mapName)

	-- Cleanup existing maps
	if Workspace:FindFirstChild("LobbyEnvironment") then Workspace.LobbyEnvironment:Destroy() end
	if Workspace:FindFirstChild("Map_Village") then Workspace.Map_Village:Destroy() end

	if mapName == "Lobby" then
		if LobbyBuilder and LobbyBuilder.Build then LobbyBuilder.Build() end
	elseif mapName == "Village" or mapName == "ACT 1: Village" then
		if VillageBuilder and VillageBuilder.Build then VillageBuilder.Build() end
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
