-- DataStoreManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/DataStoreManager.lua
-- Script Place: Lobby & ACT 1: Village
-- Deskripsi: Mengelola semua interaksi dengan Roblox DataStore menggunakan ProfileStore (by loleris).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Memuat konfigurasi game
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local ProfileStore = require(game.ServerScriptService.ModuleScript:WaitForChild("ProfileStore"))

local DataStoreManager = {}

-- Menentukan lingkungan datastore
local ENVIRONMENT = GameConfig.DataStore and GameConfig.DataStore.Environment or "dev"
local PROFILE_STORE_NAME = "PlayerProfileStore_" .. ENVIRONMENT

-- Cache untuk menyimpan data pemain yang sedang online (Profile Objects)
local Profiles = {}
local PendingLoads = {} -- [player] = BindableEvent

-- Struktur data default untuk pemain baru.
local DEFAULT_PLAYER_DATA = {
	version = 1,
	lastSaveTimestamp = 0,
	stats = {
		TotalCoins = 0,
		TotalDamageDealt = 0,
		TotalKills = 0,
		TotalRevives = 0,
		TotalKnocks = 0,
		DailyRewardLastClaim = 0,
		DailyRewardCurrentDay = 1,
		AchievementPoints = 0,
		MissionPoints = 0,
		WeaponStats = {},
		MissionsCompleted = 0,
	},
	missions = {
		Daily = { Missions = {}, LastReset = 0, RerollUsed = false },
		Weekly = { Missions = {}, LastReset = 0, RerollUsed = false },
		RecentMissions = {}
	},
	leveling = {
		Level = 1,
		XP = 0,
	},
	globalMissions = {},
	titles = {
		UnlockedTitles = {},
		EquippedTitle = ""
	},
	inventory = {
		Coins = 0,
		Skins = {
			Owned = {},
			Equipped = {}
		},
		PityCount = 0,
		LastFreeGachaClaimUTC = 0
	},
	achievements = {
		Completed = {},
		Progress = {}
	},
	boosters = {
		Owned = {},
		Active = nil
	},
	settings = {
		sound = { enabled = true, sfxVolume = 0.8 },
		controls = { fireControlType = "FireButton" },
		hud = {},
		gameplay = {
			shadows = true
		}
	}
}

-- Inisialisasi ProfileStore
local PlayerProfileStore = ProfileStore.New(PROFILE_STORE_NAME, DEFAULT_PLAYER_DATA)

-- Helper untuk kompatibilitas mundur dengan kode lama yang mengharapkan struktur wrapper
local function createLegacyWrapper(profile)
	if not profile then return nil end

	local wrapper = {
		isDirty = false,
		isLoading = false,
		_profile = profile
	}

	-- Gunakan metatable agar .data selalu menunjuk ke profile.Data terkini
	setmetatable(wrapper, {
		__index = function(t, k)
			if k == "data" then
				return t._profile.Data
			end
			return nil
		end,
		__newindex = function(t, k, v)
			if k == "data" then
				t._profile.Data = v
			else
				rawset(t, k, v)
			end
		end
	})

	return wrapper
end

function DataStoreManager:LoadPlayerData(player)
	-- 1. Cek apakah profile sudah ada
	if Profiles[player] then
		local signal = Instance.new("BindableEvent")
		task.spawn(function()
			signal:Fire(createLegacyWrapper(Profiles[player]))
			signal:Destroy()
		end)
		return signal.Event
	end

	-- 2. Cek apakah sedang loading (Pending)
	if PendingLoads[player] then
		return PendingLoads[player].Event
	end

	-- 3. Mulai proses loading baru
	local signal = Instance.new("BindableEvent")
	PendingLoads[player] = signal

	task.spawn(function()
		local userId = player.UserId
		local profileKey = "Player_" .. userId

		local profile = PlayerProfileStore:StartSessionAsync(profileKey, {
			Cancel = function()
				return player.Parent ~= Players
			end
		})

		if profile ~= nil then
			profile:AddUserId(userId)
			profile:Reconcile()

			profile.OnSessionEnd:Connect(function()
				Profiles[player] = nil
				if player:IsDescendantOf(Players) then
					player:Kick("Sesi profil Anda telah dimuat di server lain.")
				end
			end)

			if player:IsDescendantOf(Players) then
				Profiles[player] = profile
				print("[DataStoreManager] Profile loaded for " .. player.Name)
				signal:Fire(true) -- Pass true to signal completion, avoid cyclic table serialization
			else
				profile:EndSession()
				signal:Fire(nil)
			end
		else
			player:Kick("Gagal memuat profil data. Silakan coba lagi nanti.")
			signal:Fire(nil)
		end

		PendingLoads[player] = nil
		-- Jangan destroy signal di sini karena skrip lain mungkin baru saja connect?
		-- BindableEvent:Fire() mentrigger callbacks segera.
		-- Destroy() setelah yield sedikit aman.
		task.wait()
		signal:Destroy()
	end)

	return signal.Event
end

function DataStoreManager:GetOrWaitForPlayerData(player)
	if Profiles[player] then
		return createLegacyWrapper(Profiles[player])
	end

	-- Jika loading sedang berlangsung, kita tunggu signalnya
	if PendingLoads[player] then
		local result = PendingLoads[player].Event:Wait()
		if result then
			-- If result is true (new behavior), fetch from cache.
			-- If result is table (legacy behavior), return it.
			if result == true then
				if Profiles[player] then
					return createLegacyWrapper(Profiles[player])
				else
					return nil
				end
			end
			return result
		end
	end

	-- Fallback loop jika LoadPlayerData belum dipanggil (misal race condition saat init)
	local startTime = os.time()
	while not Profiles[player] do
		if os.time() - startTime > 30 then
			warn("[DataStoreManager] Timeout waiting for data: " .. player.Name)
			return nil
		end
		if not player.Parent then return nil end

		-- Trigger load jika belum ada pending
		if not PendingLoads[player] and not Profiles[player] then
			self:LoadPlayerData(player)
		end

		task.wait(0.5)
	end

	return createLegacyWrapper(Profiles[player])
end

function DataStoreManager:GetPlayerData(player)
	local profile = Profiles[player]
	if profile then
		return createLegacyWrapper(profile)
	end
	return nil
end

function DataStoreManager:SavePlayerData(player)
	-- Handled by ProfileStore AutoSave
end

function DataStoreManager:UpdatePlayerData(player, newData)
	local profile = Profiles[player]
	if profile then
		if profile.Data ~= newData then
			profile.Data = newData
		end
	end
end

function DataStoreManager:SavePlayerDataYielding(player)
	local profile = Profiles[player]
	if profile then
		local saved = false
		local connection

		-- Dengarkan sinyal OnAfterSave untuk mengetahui kapan penyimpanan selesai
		connection = profile.OnAfterSave:Connect(function()
			saved = true
		end)

		-- Picu penyimpanan manual (non-blocking di library, tapi kita tunggu hasilnya)
		profile:Save()

		-- Tunggu dengan timeout (misal 5 detik)
		local start = os.clock()
		while not saved and os.clock() - start < 5 do
			if not Profiles[player] then break end -- Profile sudah dibersihkan/released
			task.wait()
		end

		if connection then connection:Disconnect() end
		return saved
	end
	return false
end

function DataStoreManager:Init()
	print("DataStoreManager (ProfileStore) Initialized: " .. ENVIRONMENT)

	local function onPlayerAdded(player)
		task.spawn(function()
			self:LoadPlayerData(player)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]
		if profile then
			profile:EndSession()
			Profiles[player] = nil
		end
	end)
end

-- =============================================================================
-- API GLOBAL DATA (LEADERBOARD & GLOBAL VALUES)
-- =============================================================================

local GlobalDS = DataStoreService:GetDataStore("GlobalDSv1", ENVIRONMENT)

function DataStoreManager:UpdateLeaderboard(leaderboardName, key, value)
	local success, err = pcall(function()
		local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
		orderedDataStore:SetAsync(tostring(key), tonumber(value))
	end)
	if not success then
		warn("[DataStoreManager] Failed to update leaderboard '" .. leaderboardName .. "': " .. tostring(err))
	end
end

function DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, userId)
	local success, result = pcall(function()
		local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
		local playerScore = orderedDataStore:GetAsync(tostring(userId))
		if not playerScore then
			return nil, nil
		end

		local rankPages = orderedDataStore:GetSortedAsync(false, 100, playerScore)
		local rankPage = rankPages:GetCurrentPage()

		local playerRank = nil
		for i, entry in ipairs(rankPage) do
			if entry.key == tostring(userId) then
				playerRank = i
				break
			end
		end

		return playerScore, playerRank
	end)

	if success then
		return result
	else
		warn("[DataStoreManager] Failed to get rank '" .. leaderboardName .. "': " .. tostring(result))
		return nil, nil
	end
end

function DataStoreManager:GetLeaderboardData(leaderboardName, isAscending, pageSize)
	isAscending = isAscending or false
	pageSize = pageSize or 50

	local success, result = pcall(function()
		local orderedDataStore = DataStoreService:GetOrderedDataStore(leaderboardName, ENVIRONMENT)
		local pages = orderedDataStore:GetSortedAsync(isAscending, pageSize)
		return pages:GetCurrentPage()
	end)

	if success then
		return result
	else
		warn("[DataStoreManager] Failed to get leaderboard data '" .. leaderboardName .. "': " .. tostring(result))
		return {}
	end
end

function DataStoreManager:SetGlobalData(key, value)
	local success, err = pcall(function()
		GlobalDS:SetAsync(key, value)
	end)
	if not success then
		warn("[DataStoreManager] Failed to set global data '" .. key .. "': " .. tostring(err))
	end
	return success
end

function DataStoreManager:GetGlobalData(key)
	local success, result = pcall(function()
		return GlobalDS:GetAsync(key)
	end)
	if success then
		return result
	else
		warn("[DataStoreManager] Failed to get global data '" .. key .. "': " .. tostring(result))
		return nil
	end
end

-- =============================================================================
-- API ADMIN & UTILS
-- =============================================================================

function DataStoreManager:LoadOfflinePlayerData(userId)
	local profileKey = "Player_" .. userId
	local profile = PlayerProfileStore:GetAsync(profileKey)

	if profile then
		return { data = profile.Data }
	else
		return nil
	end
end

function DataStoreManager:SaveOfflinePlayerData(userId, data)
	warn("[DataStoreManager] SaveOfflinePlayerData not fully supported by ProfileStore for safety. Use with caution.")
	return false
end

function DataStoreManager:DeletePlayerData(userId)
	local profileKey = "Player_" .. userId
	local success = PlayerProfileStore:RemoveAsync(profileKey)

	local LeaderboardConfig = require(game.ReplicatedStorage:WaitForChild("LeaderboardConfig"))
	for _, config in pairs(LeaderboardConfig) do
		pcall(function()
			DataStoreService:GetOrderedDataStore(config.DataStoreName, ENVIRONMENT):RemoveAsync(tostring(userId))
		end)
	end

	return success
end

function DataStoreManager:LogAdminAction(adminPlayer, action, targetUserId)
	print(string.format("ADMIN ACTION: %s (%d) -> '%s' on Target %d", adminPlayer.Name, adminPlayer.UserId, action, targetUserId))
end

DataStoreManager.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA

return DataStoreManager
