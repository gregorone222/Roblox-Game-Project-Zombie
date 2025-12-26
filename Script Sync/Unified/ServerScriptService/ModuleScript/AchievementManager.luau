-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- AchievementManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/AchievementManager.lua
-- Script Place: Lobby & ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))

-- Modul lain
local StatsModule = require(script.Parent:WaitForChild("StatsModule"))

local AchievementManager = {}

-- Tabel untuk melacak rentetan gelombang bertahan hidup (in-memory)
local playerWaveStreaks = {}
Players.PlayerRemoving:Connect(function(player)
	playerWaveStreaks[player] = nil
end)

-- RemoteEvents & RemoteFunctions
local achievementEvent = ReplicatedStorage:FindFirstChild("AchievementUnlocked") or Instance.new("RemoteEvent", ReplicatedStorage)
achievementEvent.Name = "AchievementUnlocked"

local getAchievementsFunc = ReplicatedStorage:FindFirstChild("GetAchievementsFunc") or Instance.new("RemoteFunction", ReplicatedStorage)
getAchievementsFunc.Name = "GetAchievementsFunc"

-- Bindable Events untuk Mendengarkan Perubahan Statistik dari StatsModule
-- Gunakan pola inisialisasi yang aman agar tidak terjadi infinite yield jika folder belum ada
local BindableEvents = ReplicatedStorage:FindFirstChild("BindableEvents")
if not BindableEvents then
	BindableEvents = Instance.new("Folder")
	BindableEvents.Name = "BindableEvents"
	BindableEvents.Parent = ReplicatedStorage
end

local StatChangedEvent = BindableEvents:FindFirstChild("StatChanged")
if not StatChangedEvent then
	StatChangedEvent = Instance.new("BindableEvent")
	StatChangedEvent.Name = "StatChanged"
	StatChangedEvent.Parent = BindableEvents
end

local WeaponStatChangedEvent = BindableEvents:FindFirstChild("WeaponStatChanged")
if not WeaponStatChangedEvent then
	WeaponStatChangedEvent = Instance.new("BindableEvent")
	WeaponStatChangedEvent.Name = "WeaponStatChanged"
	WeaponStatChangedEvent.Parent = BindableEvents
end

-- =============================================================================
-- FUNGSI INTI
-- =============================================================================

function AchievementManager.GetData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[AchievementManager] Gagal mendapatkan data untuk pemain: " .. player.Name)
		return {}
	end

	-- Pastikan sub-tabel achievements ada
	if not playerData.data.achievements then
		local defaultData = require(script.Parent:WaitForChild("DataStoreManager")).DEFAULT_PLAYER_DATA
		playerData.data.achievements = {}
		for k, v in pairs(defaultData.achievements) do
			playerData.data.achievements[k] = v
		end
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end

	return playerData.data.achievements
end

function AchievementManager.SaveData(player, achievementsData)
	local playerData = DataStoreManager:GetPlayerData(player)
	if not playerData or not playerData.data then return end

	playerData.data.achievements = achievementsData
	DataStoreManager:UpdatePlayerData(player, playerData.data)
end

-- =============================================================================
-- LOGIKA PENCAPAIAN
-- =============================================================================

function AchievementManager:UnlockAchievement(player, achievement)
	local achievementsData = self.GetData(player)
	if achievementsData.Completed[achievement.ID] then return end -- Sudah dibuka

	achievementsData.Completed[achievement.ID] = true
	self.SaveData(player, achievementsData)

	StatsModule.AddAchievementPoints(player, achievement.APReward)
	achievementEvent:FireClient(player, achievement)
end

-- Memeriksa pencapaian berdasarkan pembaruan statistik
function AchievementManager:CheckStatAchievements(player, statName, newValue)
	local AchievementConfig = require(script.Parent:WaitForChild("AchievementConfig"))
	local achievementsData = self.GetData(player)

	for _, achievement in ipairs(AchievementConfig) do
		if achievement.Stat == statName and not achievementsData.Completed[achievement.ID] then
			if type(newValue) == "number" and type(achievement.Target) == "number" and newValue >= achievement.Target then
				self:UnlockAchievement(player, achievement)
			end
		end
	end
end

-- Memeriksa pencapaian berdasarkan pembaruan kill senjata
function AchievementManager:CheckWeaponAchievements(player, weaponName, newKillCount)
	local AchievementConfig = require(script.Parent:WaitForChild("AchievementConfig"))
	local achievementsData = self.GetData(player)

	for _, achievement in ipairs(AchievementConfig) do
		if achievement.Weapon == weaponName and not achievementsData.Completed[achievement.ID] then
			if type(newKillCount) == "number" and type(achievement.Target) == "number" and newKillCount >= achievement.Target then
				self:UnlockAchievement(player, achievement)
			end
		end
	end
end

-- =============================================================================
-- API PUBLIK (Dipanggil oleh modul lain)
-- =============================================================================

function AchievementManager:UpdateWaveSurvivedProgress(player)
	playerWaveStreaks[player] = (playerWaveStreaks[player] or 0) + 1
	local currentStreak = playerWaveStreaks[player]

	local statsData = StatsModule.GetData(player)
	local highestStreak = statsData.WavesSurvivedNoKnock or 0

	if currentStreak > highestStreak then
		StatsModule.SetStat(player, "WavesSurvivedNoKnock", currentStreak)
	end
end

function AchievementManager:ResetWaveSurvivedProgress(player)
	playerWaveStreaks[player] = 0
end

-- Fungsi ini sekarang bisa jadi private atau deprecated, karena kita pakai event
-- Tapi kita simpan untuk kompatibilitas jika ada yang memanggil langsung
function AchievementManager:UpdateStatProgress(player, statName, newValue)
	self:CheckStatAchievements(player, statName, newValue)
end

function AchievementManager:UpdateWeaponKill(player, weaponName, newKillCount)
	self:CheckWeaponAchievements(player, weaponName, newKillCount)
end

-- =============================================================================
-- KONEKSI EVENT
-- =============================================================================

-- Menghubungkan ke event dari StatsModule
StatChangedEvent.Event:Connect(function(player, statName, newValue)
	AchievementManager:CheckStatAchievements(player, statName, newValue)
end)

WeaponStatChangedEvent.Event:Connect(function(player, weaponName, newKillCount)
	AchievementManager:CheckWeaponAchievements(player, weaponName, newKillCount)
end)


getAchievementsFunc.OnServerInvoke = function(player)
	local achievementsData = AchievementManager.GetData(player)
	local statsData = StatsModule.GetData(player)
	local clientAchievements = {}

	local AchievementConfig = require(script.Parent:WaitForChild("AchievementConfig"))
	for _, achievement in ipairs(AchievementConfig) do
		local progress = 0
		if achievement.Stat and statsData[achievement.Stat] then
			progress = statsData[achievement.Stat]
		elseif achievement.Weapon and statsData.WeaponStats[achievement.Weapon] then
			progress = statsData.WeaponStats[achievement.Weapon].Kills
		end

		table.insert(clientAchievements, {
			ID = achievement.ID,
			Name = achievement.Name,
			Desc = achievement.Desc,
			Target = achievement.Target,
			APReward = achievement.APReward,
			Progress = progress,
			Completed = achievementsData.Completed[achievement.ID] or false,
			Category = achievement.Category,
		})
	end

	return clientAchievements
end

return AchievementManager
