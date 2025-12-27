-- DataRecoveryAdmin.luau
-- Path: ServerScriptService/ModuleScript/DataRecoveryAdmin.luau
-- Description: Admin tool untuk recovery data player menggunakan ProfileStore version history

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(script.Parent:WaitForChild("ProfileStore"))
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local AdminConfig = require(script.Parent:WaitForChild("AdminConfig"))

local DataRecoveryAdmin = {}

-- Configuration
local ENVIRONMENT = GameConfig.DataStore and GameConfig.DataStore.Environment or "dev"
local PROFILE_STORE_NAME = "PlayerProfileStore_" .. ENVIRONMENT

-- Initialize ProfileStore for recovery operations
local RecoveryProfileStore = ProfileStore.New(PROFILE_STORE_NAME, DataStoreManager.DEFAULT_PLAYER_DATA)

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

local function IsAdmin(player)
	return AdminConfig.IsAdmin(player)
end

local function FormatTimestamp(unixTime)
	local date = os.date("*t", unixTime)
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", 
		date.year, date.month, date.day, date.hour, date.min, date.sec)
end

-- =============================================================================
-- VERSION HISTORY FUNCTIONS
-- =============================================================================

--- Get list of available versions for a player
-- @param targetUserId: The UserId of the player to lookup
-- @param maxVersions: Maximum number of versions to retrieve (default 10)
-- @return: Array of version info {Version, UpdatedTime, CreatedTime}
function DataRecoveryAdmin.GetVersionHistory(targetUserId, maxVersions)
	maxVersions = maxVersions or 10
	
	local profileKey = "Player_" .. tostring(targetUserId)
	local versions = {}
	
	local success, error = pcall(function()
		local versionQuery = RecoveryProfileStore:VersionQuery(
			profileKey,
			Enum.SortDirection.Descending -- Newest first
		)
		
		for i = 1, maxVersions do
			local profile = versionQuery:NextAsync()
			if not profile then break end
			
			table.insert(versions, {
				Version = profile.KeyInfo.Version,
				UpdatedTime = profile.KeyInfo.UpdatedTime,
				UpdatedTimeFormatted = FormatTimestamp(math.floor(profile.KeyInfo.UpdatedTime / 1000)),
				CreatedTime = profile.KeyInfo.CreatedTime,
				Data = profile.Data -- Include data for preview
			})
		end
	end)
	
	if not success then
		warn("[DataRecoveryAdmin] Failed to get version history: " .. tostring(error))
		return nil, error
	end
	
	return versions
end

--- Get specific version of player data
-- @param targetUserId: The UserId of the player
-- @param version: The version string to retrieve
-- @return: Profile data or nil
function DataRecoveryAdmin.GetVersionData(targetUserId, version)
	local profileKey = "Player_" .. tostring(targetUserId)
	
	local success, result = pcall(function()
		return RecoveryProfileStore:GetAsync(profileKey, version)
	end)
	
	if success and result then
		return result.Data
	else
		warn("[DataRecoveryAdmin] Failed to get version: " .. tostring(result))
		return nil
	end
end

--- Preview what data would be restored
-- @param targetUserId: The UserId of the player
-- @param version: The version to preview
-- @return: Table with comparison of current vs restore data
function DataRecoveryAdmin.PreviewRestore(targetUserId, version)
	local currentData = nil
	local restoreData = nil
	
	-- Get current data
	local player = Players:GetPlayerByUserId(targetUserId)
	if player then
		local playerData = DataStoreManager:GetPlayerData(player)
		if playerData then
			currentData = playerData.data
		end
	end
	
	-- If player is offline, get from DataStore
	if not currentData then
		local offlineData = DataStoreManager:LoadOfflinePlayerData(targetUserId)
		if offlineData then
			currentData = offlineData.data
		end
	end
	
	-- Get restore data
	restoreData = DataRecoveryAdmin.GetVersionData(targetUserId, version)
	
	return {
		CurrentData = currentData,
		RestoreData = restoreData,
		TargetUserId = targetUserId,
		TargetVersion = version
	}
end

--- Restore player data to a specific version
-- WARNING: This will overwrite current data!
-- @param adminPlayer: The admin player performing the action
-- @param targetUserId: The UserId of the player to restore
-- @param version: The version to restore to
-- @return: Success boolean and message
function DataRecoveryAdmin.RestoreToVersion(adminPlayer, targetUserId, version)
	-- Verify admin
	if not IsAdmin(adminPlayer) then
		return false, "Unauthorized: Not an admin"
	end
	
	-- Get the version data
	local restoreData = DataRecoveryAdmin.GetVersionData(targetUserId, version)
	if not restoreData then
		return false, "Failed to retrieve version data"
	end
	
	-- Check if player is online
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	
	if targetPlayer then
		-- Player is online - update their active profile
		local playerData = DataStoreManager:GetPlayerData(targetPlayer)
		if playerData then
			-- Restore the data
			playerData.data = restoreData
			DataStoreManager:UpdatePlayerData(targetPlayer, restoreData)
			
			-- Log the action
			DataRecoveryAdmin.LogRecoveryAction(adminPlayer, targetUserId, version, "RESTORED_ONLINE")
			
			return true, "Data restored successfully (player online)"
		else
			return false, "Failed to get player's active profile"
		end
	else
		-- Player is offline - we cannot safely restore offline players with ProfileStore
		-- The player needs to be online for session locking to work properly
		return false, "Player must be online to restore data. Ask player to join, then retry."
	end
end

-- =============================================================================
-- LOGGING
-- =============================================================================

local RecoveryLog = {} -- In-memory log (consider persisting to DataStore for production)

function DataRecoveryAdmin.LogRecoveryAction(adminPlayer, targetUserId, version, action)
	local logEntry = {
		Timestamp = os.time(),
		TimestampFormatted = FormatTimestamp(os.time()),
		AdminUserId = adminPlayer.UserId,
		AdminName = adminPlayer.Name,
		TargetUserId = targetUserId,
		Version = version,
		Action = action
	}
	
	table.insert(RecoveryLog, 1, logEntry) -- Insert at beginning (newest first)
	
	-- Keep only last 100 entries in memory
	if #RecoveryLog > 100 then
		table.remove(RecoveryLog)
	end
	
	print(string.format("[DataRecoveryAdmin] %s: Admin %s (%d) performed %s on User %d (Version: %s)",
		logEntry.TimestampFormatted,
		logEntry.AdminName,
		logEntry.AdminUserId,
		logEntry.Action,
		logEntry.TargetUserId,
		tostring(logEntry.Version)
	))
	
	return logEntry
end

function DataRecoveryAdmin.GetRecoveryLog()
	return RecoveryLog
end

-- =============================================================================
-- COMPENSATION HELPERS
-- =============================================================================

--- Give compensation to a player (for data loss cases)
-- @param player: The player to compensate
-- @param compensationType: Type of compensation
-- @param amount: Amount to give
function DataRecoveryAdmin.GiveCompensation(adminPlayer, targetPlayer, compensationType, amount)
	if not IsAdmin(adminPlayer) then
		return false, "Unauthorized"
	end
	
	local SurvivalCoinsModule = require(script.Parent:WaitForChild("SurvivalCoinsModule"))
	local MissionPointsModule = require(script.Parent:WaitForChild("MissionPointsModule"))
	
	if compensationType == "SurvivalCoins" then
		SurvivalCoinsModule.AddCoins(targetPlayer, amount)
		DataRecoveryAdmin.LogRecoveryAction(adminPlayer, targetPlayer.UserId, nil, "COMPENSATION_COINS_" .. amount)
		return true, "Gave " .. amount .. " Survival Coins"
		
	elseif compensationType == "MissionPoints" then
		MissionPointsModule.AddMP(targetPlayer, amount)
		DataRecoveryAdmin.LogRecoveryAction(adminPlayer, targetPlayer.UserId, nil, "COMPENSATION_MP_" .. amount)
		return true, "Gave " .. amount .. " Mission Points"
	end
	
	return false, "Unknown compensation type"
end

-- =============================================================================
-- EXPORT
-- =============================================================================

DataRecoveryAdmin.IsAdmin = IsAdmin

return DataRecoveryAdmin
