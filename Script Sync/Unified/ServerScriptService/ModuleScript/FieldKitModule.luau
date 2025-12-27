-- FieldKitModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/FieldKitModule.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local FieldKitConfig = require(script.Parent:WaitForChild("FieldKitConfig"))
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))

local FieldKitModule = {}

-- RemoteEvents (wait for SharedEventsSetup to create folders)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local FieldKitUpdateEvent = RemoteEvents:WaitForChild("FieldKitUpdateEvent")
local UpdatePlayerFieldKitStatusEvent = RemoteEvents:WaitForChild("UpdatePlayerFieldKitStatusEvent")
local ActivateFieldKitEvent = RemoteEvents:WaitForChild("ActivateFieldKitEvent")

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function FieldKitModule.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[FieldKitModule] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return { Owned = {}, Active = nil }
	end

	-- Pastikan sub-tabel fieldKits ada (backward compatible dengan boosters)
	if not playerData.data.fieldKits then
		-- Migrate dari boosters jika ada
		if playerData.data.boosters then
			playerData.data.fieldKits = playerData.data.boosters
		else
			local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
			playerData.data.fieldKits = {}
			if defaultData.fieldKits then
				for k, v in pairs(defaultData.fieldKits) do 
					playerData.data.fieldKits[k] = v 
				end
			elseif defaultData.boosters then
				for k, v in pairs(defaultData.boosters) do 
					playerData.data.fieldKits[k] = v 
				end
			end
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	local fieldKits = playerData.data.fieldKits
	local hasChanges = false

	-- Pastikan semua field kit dari config ada di data pemain
	for fieldKitName, _ in pairs(FieldKitConfig) do
		if fieldKits.Owned[fieldKitName] == nil then
			fieldKits.Owned[fieldKitName] = 0
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return fieldKits
end

function FieldKitModule.SaveData(player, fieldKitsData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.fieldKits = fieldKitsData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function FieldKitModule.AddFieldKit(player, fieldKitName, amount)
	if not player or not FieldKitConfig[fieldKitName] or not tonumber(amount) then return false end
	local data = FieldKitModule.GetData(player)
	data.Owned[fieldKitName] = (data.Owned[fieldKitName] or 0) + amount
	FieldKitModule.SaveData(player, data)
	FieldKitUpdateEvent:FireClient(player, data)
	return true
end

function FieldKitModule.ActivateFieldKit(player, fieldKitName)
	if not player or (fieldKitName and not FieldKitConfig[fieldKitName]) then return end
	local data = FieldKitModule.GetData(player)

	if data.Active == fieldKitName then -- Unequip
		data.Active = nil
	elseif fieldKitName and data.Owned[fieldKitName] > 0 then -- Equip
		data.Active = fieldKitName
	else -- Gagal equip
		return
	end

	FieldKitModule.SaveData(player, data)
	FieldKitUpdateEvent:FireClient(player, data)
	UpdatePlayerFieldKitStatusEvent:FireAllClients(player.UserId, data.Active)
end

function FieldKitModule.UseActiveFieldKit(player)
	local data = FieldKitModule.GetData(player)
	local activeFieldKit = data.Active

	if not activeFieldKit or (data.Owned[activeFieldKit] or 0) <= 0 then
		return nil
	end

	data.Owned[activeFieldKit] -= 1
	data.Active = nil
	FieldKitModule.SaveData(player, data)

	StatsModule.IncrementStat(player, "FieldKitsUsed", 1)
	FieldKitUpdateEvent:FireClient(player, data)
	UpdatePlayerFieldKitStatusEvent:FireAllClients(player.UserId, data.Active)

	return activeFieldKit
end

-- Backward compatibility aliases
FieldKitModule.AddBooster = FieldKitModule.AddFieldKit
FieldKitModule.ActivateBooster = FieldKitModule.ActivateFieldKit
FieldKitModule.UseActiveBooster = FieldKitModule.UseActiveFieldKit

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

local function onPlayerAdded(player)
	task.spawn(function()
		local data = FieldKitModule.GetData(player)
		FieldKitUpdateEvent:FireClient(player, data)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

ActivateFieldKitEvent.OnServerEvent:Connect(function(player, fieldKitName)
	FieldKitModule.ActivateFieldKit(player, fieldKitName)
end)

return FieldKitModule

