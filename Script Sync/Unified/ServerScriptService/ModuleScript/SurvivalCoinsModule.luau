-- SurvivalCoinsModule.luau (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SurvivalCoinsModule.luau
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local SurvivalCoinsManager = {}

-- RemoteEvent (wait for SharedEventsSetup to create folders)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SurvivalCoinsUpdateEvent = RemoteEvents:WaitForChild("SurvivalCoinsUpdateEvent")

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function SurvivalCoinsManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[SurvivalCoinsManager] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {} -- Kembalikan tabel kosong untuk mencegah error
	end

	-- Pastikan sub-tabel inventory ada
	if not playerData.data.inventory then
		-- Jika tidak ada, salin dari struktur default di DataStoreManager
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.inventory = {}
		for k, v in pairs(defaultData.inventory) do
			playerData.data.inventory[k] = v
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	local inventory = playerData.data.inventory
	local hasChanges = false

	-- Inisialisasi skin default untuk senjata yang mungkin belum ada di data pemain
	for weaponName, _ in pairs(WeaponModule.Weapons) do
		if not inventory.Skins.Owned[weaponName] then
			inventory.Skins.Owned[weaponName] = {"Default Skin"}
			hasChanges = true
		end
		if not inventory.Skins.Equipped[weaponName] then
			inventory.Skins.Equipped[weaponName] = "Default Skin"
			hasChanges = true
		end
	end

	if hasChanges then
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return inventory
end

function SurvivalCoinsManager.SaveData(player, inventoryData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.inventory = inventoryData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- API PUBLIK
-- =============================================================================

function SurvivalCoinsManager.AddCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return end
	local data = SurvivalCoinsManager.GetData(player)
	data.SurvivalCoins += amount
	SurvivalCoinsManager.SaveData(player, data)
	SurvivalCoinsUpdateEvent:FireClient(player, data.SurvivalCoins)
	StatsModule.AddCoin(player, amount)
	return data.SurvivalCoins
end

function SurvivalCoinsManager.SubtractCoins(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	local data = SurvivalCoinsManager.GetData(player)
	if data.SurvivalCoins < amount then return false end
	data.SurvivalCoins -= amount
	SurvivalCoinsManager.SaveData(player, data)
	SurvivalCoinsUpdateEvent:FireClient(player, data.SurvivalCoins)
	return true
end

function SurvivalCoinsManager.AddSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then return false end
	local data = SurvivalCoinsManager.GetData(player)
	if table.find(data.Skins.Owned[weaponName], skinName) then return false end
	table.insert(data.Skins.Owned[weaponName], skinName)
	SurvivalCoinsManager.SaveData(player, data)
	return true
end

function SurvivalCoinsManager.UpdatePityCount(player, newCount)
	if not player or type(newCount) ~= "number" then return false end
	local data = SurvivalCoinsManager.GetData(player)
	data.PityCount = newCount
	SurvivalCoinsManager.SaveData(player, data)
	return true
end

function SurvivalCoinsManager.UpdateLastFreeGachaClaim(player, timestamp)
	if not player or type(timestamp) ~= "number" then return false end
	local data = SurvivalCoinsManager.GetData(player)
	data.LastFreeGachaClaimUTC = timestamp
	SurvivalCoinsManager.SaveData(player, data)
	return true
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

local function onPlayerAdded(player)
	-- Memulai inisialisasi dalam thread baru.
	-- GetData akan secara internal menunggu data dimuat.
	task.spawn(function()
		local data = SurvivalCoinsManager.GetData(player)
		SurvivalCoinsUpdateEvent:FireClient(player, data.SurvivalCoins)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

return SurvivalCoinsManager
