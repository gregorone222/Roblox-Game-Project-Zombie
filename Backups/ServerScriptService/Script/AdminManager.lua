-- AdminManager.lua (Script)
-- Path: ServerScriptService/Script/AdminManager.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(script.Parent.Parent.ModuleScript:WaitForChild("DataStoreManager"))
local AdminConfig = require(ServerScriptService.ModuleScript:WaitForChild("AdminConfig"))

local AdminManager = {}

-- Folder & Event
local adminEventsFolder = ReplicatedStorage:FindFirstChild("AdminEvents") or Instance.new("Folder", ReplicatedStorage)
adminEventsFolder.Name = "AdminEvents"

local requestDataFunc = adminEventsFolder:FindFirstChild("AdminRequestData") or Instance.new("RemoteFunction", adminEventsFolder)
requestDataFunc.Name = "AdminRequestData"

local updateDataEvent = adminEventsFolder:FindFirstChild("AdminUpdateData") or Instance.new("RemoteEvent", adminEventsFolder)
updateDataEvent.Name = "AdminUpdateData"

local deleteDataEvent = adminEventsFolder:FindFirstChild("AdminDeleteData") or Instance.new("RemoteEvent", adminEventsFolder)
deleteDataEvent.Name = "AdminDeleteData"

-- [[ PERBAIKAN KEAMANAN: Daftar Putih Bidang yang Dapat Diedit ]]
-- Hanya bidang-bidang ini yang akan diterima dari klien.
local EDITABLE_FIELDS = {
	leveling = {
		Level = true,
		XP = true
	},
	stats = {
		SkillPoints = true,
		MissionPoints = true,
		AchievementPoints = true,
		-- TotalKills, TotalDamage, dll SENGATA TIDAK diizinkan untuk diedit.
	},
	inventory = {
		Coins = true,
		PityCount = true,
	}
}


-- Fungsi untuk menggabungkan tabel secara rekursif
local function deepMerge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" and type(t1[k]) == "table" then
			deepMerge(t1[k], v)
		else
			t1[k] = v
		end
	end
	return t1
end

-- =============================================================================
-- HANDLER REMOTE
-- =============================================================================

requestDataFunc.OnServerInvoke = function(adminPlayer, targetUserId)
	if not AdminConfig.IsAdmin(adminPlayer) then return nil, "Unauthorized" end
	if type(targetUserId) ~= "number" then return nil, "Invalid UserID" end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local data

	if targetPlayer then
		data = DataStoreManager:GetPlayerData(targetPlayer)
	else
		data = DataStoreManager:LoadOfflinePlayerData(targetUserId) 
	end

	if not data or not data.data then return nil, "No data found" end

	return data.data -- Kirim data mentah
end

updateDataEvent.OnServerEvent:Connect(function(adminPlayer, targetUserId, newData)
	if not AdminConfig.IsAdmin(adminPlayer) then return end
	if type(targetUserId) ~= "number" or type(newData) ~= "table" then return end

	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	local currentData

	if targetPlayer then
		currentData = DataStoreManager:GetPlayerData(targetPlayer)
	else
		currentData = DataStoreManager:LoadOfflinePlayerData(targetUserId)
	end

	if not currentData or not currentData.data then return end

	-- [[ PERBAIKAN KEAMANAN: Validasi dan sanitasi data yang masuk ]]
	local dataToMerge = {}

	-- 1. Validasi 'leveling'
	if newData.leveling and type(newData.leveling) == "table" and EDITABLE_FIELDS.leveling then
		dataToMerge.leveling = {}
		if newData.leveling.Level ~= nil and EDITABLE_FIELDS.leveling.Level then
			dataToMerge.leveling.Level = tonumber(newData.leveling.Level) or 0
		end
		if newData.leveling.XP ~= nil and EDITABLE_FIELDS.leveling.XP then
			dataToMerge.leveling.XP = tonumber(newData.leveling.XP) or 0
		end
	end

	-- 2. Validasi 'stats'
	if newData.stats and type(newData.stats) == "table" and EDITABLE_FIELDS.stats then
		dataToMerge.stats = {}
		if newData.stats.SkillPoints ~= nil and EDITABLE_FIELDS.stats.SkillPoints then
			dataToMerge.stats.SkillPoints = tonumber(newData.stats.SkillPoints) or 0
		end
		if newData.stats.MissionPoints ~= nil and EDITABLE_FIELDS.stats.MissionPoints then
			dataToMerge.stats.MissionPoints = tonumber(newData.stats.MissionPoints) or 0
		end
		if newData.stats.AchievementPoints ~= nil and EDITABLE_FIELDS.stats.AchievementPoints then
			dataToMerge.stats.AchievementPoints = tonumber(newData.stats.AchievementPoints) or 0
		end
	end

	-- 3. Validasi 'inventory'
	if newData.inventory and type(newData.inventory) == "table" and EDITABLE_FIELDS.inventory then
		dataToMerge.inventory = {}
		if newData.inventory.Coins ~= nil and EDITABLE_FIELDS.inventory.Coins then
			dataToMerge.inventory.Coins = tonumber(newData.inventory.Coins) or 0
		end
		if newData.inventory.PityCount ~= nil and EDITABLE_FIELDS.inventory.PityCount then
			dataToMerge.inventory.PityCount = tonumber(newData.inventory.PityCount) or 0
		end
	end
	-- [[ AKHIR PERBAIKAN KEAMANAN ]]

	-- Hanya gabungkan data yang telah divalidasi dengan aman
	local mergedData = deepMerge(currentData.data, dataToMerge)

	if targetPlayer then
		DataStoreManager:UpdatePlayerData(targetPlayer, mergedData)
	else
		DataStoreManager:SaveOfflinePlayerData(targetUserId, mergedData)
	end

	DataStoreManager:LogAdminAction(adminPlayer, "update", targetUserId)
end)

deleteDataEvent.OnServerEvent:Connect(function(adminPlayer, targetUserId)
	if not AdminConfig.IsAdmin(adminPlayer) then return end
	if type(targetUserId) ~= "number" then return end

	DataStoreManager:DeletePlayerData(targetUserId)
	DataStoreManager:LogAdminAction(adminPlayer, "delete", targetUserId)
end)

-- =============================================================================
-- INISIALISASI
-- =============================================================================

Players.PlayerAdded:Connect(function(player)
	if AdminConfig.IsAdmin(player) then
		player:SetAttribute("IsAdmin", true)
	end
end)

return AdminManager