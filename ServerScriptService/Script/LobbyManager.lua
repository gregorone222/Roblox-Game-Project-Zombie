-- LobbyManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyManager.lua
-- Script Place: Lobby

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Helper untuk memastikan folder ada
local function getOrCreateFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local RemoteEvents = getOrCreateFolder(ReplicatedStorage, "RemoteEvents")
local RemoteFunctions = getOrCreateFolder(ReplicatedStorage, "RemoteFunctions")

-- *** FUNGSI PENTING UNTUK MEMPERBAIKI ERROR TIPE ***
local function ensureRemote(parent, name, className)
	local existing = parent:FindFirstChild(name)

	-- Hapus jika tipenya salah (misal RemoteEvent padahal butuh RemoteFunction)
	if existing and not existing:IsA(className) then
		print("LobbyManager: Memperbaiki tipe remote '" .. name .. "'. Mengganti " .. existing.ClassName .. " dengan " .. className)
		existing:Destroy()
		existing = nil
	end

	-- Buat baru jika tidak ada
	if not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = parent -- Simpan di folder yang benar
	end
	return existing
end

-- Modules
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
DataStoreManager:Init()
local DailyRewardManager = require(ServerScriptService.ModuleScript:WaitForChild("DailyRewardManager"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local ProfileModule = require(ServerScriptService.ModuleScript:WaitForChild("ProfileModule"))
local MissionManager = require(ServerScriptService.ModuleScript:WaitForChild("MissionManager"))

-- === BUILD LOBBY ENVIRONMENT ===
-- UPDATED: Use Farmhouse lobby (Cozy Apocalypse theme)
local LobbyBuilder = nil
local farmhouseModule = ServerScriptService.ModuleScript:FindFirstChild("LobbyBuilder_Farmhouse")
if farmhouseModule then
	local success, result = pcall(require, farmhouseModule)
	if success then
		LobbyBuilder = result
	end
end

-- Fallback to Subway if Farmhouse not found
if not LobbyBuilder then
	local subwayModule = ServerScriptService.ModuleScript:FindFirstChild("LobbyBuilder_Subway")
	if subwayModule then
		local success, result = pcall(require, subwayModule)
		if success then
			LobbyBuilder = result
		end
	end
end

if LobbyBuilder and LobbyBuilder.Build then
	LobbyBuilder.Build()
else
	warn("LobbyManager: Failed to load any LobbyBuilder module.")
end

-- === SETUP REMOTES (MENGGUNAKAN FUNGSI SAFE) ===

-- 1. Daily Reward (RemoteFunctions -> Karena return data)
local getRewardInfo = ensureRemote(RemoteFunctions, "GetDailyRewardInfo", "RemoteFunction")
getRewardInfo.OnServerInvoke = function(player)
	local success, result = pcall(function()
		return DailyRewardManager:GetPlayerState(player)
	end)
	return success and result or nil
end

local claimRewardEvent = ensureRemote(RemoteFunctions, "ClaimDailyReward", "RemoteFunction")
claimRewardEvent.OnServerInvoke = function(player)
	return DailyRewardManager:ClaimReward(player)
end

-- 2. Profile & Inventory
local profileFunc = ensureRemote(RemoteFunctions, "GetProfileData", "RemoteFunction")
profileFunc.OnServerInvoke = function(player) return ProfileModule.GetProfileData(player) end

local invFunc = ensureRemote(RemoteFunctions, "GetInventoryData", "RemoteFunction")
invFunc.OnServerInvoke = function(player) return CoinsManager.GetData(player) end

-- 3. Missions
local missionDataFunc = ensureRemote(RemoteFunctions, "GetMissionData", "RemoteFunction")
missionDataFunc.OnServerInvoke = function(player) return MissionManager:GetMissionDataForClient(player) end

local claimMissionFunc = ensureRemote(RemoteFunctions, "ClaimMissionReward", "RemoteFunction")
claimMissionFunc.OnServerInvoke = function(player, missionID) return MissionManager:ClaimMissionReward(player, missionID) end

local rerollMissionFunc = ensureRemote(RemoteFunctions, "RerollMission", "RemoteFunction")
rerollMissionFunc.OnServerInvoke = function(player, missionType, missionID)
	if missionType == "Daily" then
		return MissionManager:RerollDailyMission(player, missionID)
	elseif missionType == "Weekly" then
		return MissionManager:RerollWeeklyMission(player, missionID)
	else
		return false, "Invalid mission type"
	end
end


-- === PLAYER INIT ===
local function onPlayerAdded(player)
	DataStoreManager:LoadPlayerData(player)
	-- NOTE: Auto-open Daily Reward UI removed to support diegetic interaction.
	-- Client will handle notification via 'GetDailyRewardInfo' and ProximityPrompt.
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

print("LobbyManager & Remotes Initialized.")
