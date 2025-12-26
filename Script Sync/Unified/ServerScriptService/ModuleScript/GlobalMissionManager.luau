-- GlobalMissionManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/GlobalMissionManager.lua
-- Script Place: Lobby & ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Muat modul yang diperlukan
local GlobalMissionConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("GlobeMissionConfig"))
local MissionPointsModule = require(ServerScriptService.ModuleScript:WaitForChild("MissionPointsModule"))
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))

local GlobalMissionManager = {}

-- Cache untuk data misi global
local missionCache = {
	IsLoaded = false,
	ActiveMissionID = nil,
	GlobalProgress = 0,
	StartTime = 0,
	PreviousMission = nil,
	Notified50 = false,
	Notified75 = false,
	Notified100 = false
}

local GLOBAL_KEY = GlobalMissionConfig.GLOBAL_DATA_KEY
local LEADERBOARD_PREFIX = "GML_V2_"

local pendingLeaderboardUpdates = {} -- [UserId] = { key = ..., value = ... }

-- ==================================================
-- FUNGSI INTERNAL
-- ==================================================

local function GetMissionInstanceKey()
	if not missionCache.ActiveMissionID or not missionCache.StartTime then return nil end
	return missionCache.ActiveMissionID .. "_" .. missionCache.StartTime
end

function GlobalMissionManager:_loadGlobalData()
	local data = DataStoreManager:GetGlobalData(GLOBAL_KEY)
	if data and type(data) == "table" then
		missionCache.ActiveMissionID = data.ActiveMissionID
		missionCache.GlobalProgress = data.GlobalProgress
		missionCache.StartTime = data.StartTime
		missionCache.PreviousMission = data.PreviousMission
		missionCache.Notified50 = data.Notified50 or false
		missionCache.Notified75 = data.Notified75 or false
		missionCache.Notified100 = data.Notified100 or false
	else
		warn("[GlobalMissionManager] Tidak ada data global, akan memulai misi baru jika perlu.")
		missionCache.StartTime = 0
	end
	missionCache.IsLoaded = true
end

local function SanitizeData(data)
	local function copy(t, stack)
		if type(t) ~= "table" then return t end
		if stack[t] then return nil end -- Cycle detected
		stack[t] = true

		local newT = {}
		for k, v in pairs(t) do
			local newK = copy(k, stack)
			if newK ~= nil then
				newT[newK] = copy(v, stack)
			end
		end

		stack[t] = nil
		return newT
	end
	return copy(data, {})
end

function GlobalMissionManager:_saveGlobalData()
	if not missionCache.IsLoaded then return end
	local dataToSave = {
		ActiveMissionID = missionCache.ActiveMissionID,
		GlobalProgress = missionCache.GlobalProgress,
		StartTime = missionCache.StartTime,
		PreviousMission = missionCache.PreviousMission,
		Notified50 = missionCache.Notified50,
		Notified75 = missionCache.Notified75,
		Notified100 = missionCache.Notified100
	}
	DataStoreManager:SetGlobalData(GLOBAL_KEY, SanitizeData(dataToSave))
end

function GlobalMissionManager:_selectNewMission()
	local availableMissions = {}
	for _, mission in ipairs(GlobalMissionConfig.Missions) do
		if not missionCache.PreviousMission or mission.ID ~= missionCache.PreviousMission.ID then
			table.insert(availableMissions, mission)
		end
	end
	if #availableMissions == 0 then return GlobalMissionConfig.Missions[1] end
	return availableMissions[math.random(#availableMissions)]
end

function GlobalMissionManager:_startNewWeeklyMission()
	print("[GlobalMissionManager] Memulai misi mingguan baru...")
	local newMission = self:_selectNewMission()
	if not newMission then
		warn("[GlobalMissionManager] Tidak ada misi global yang bisa dimulai!")
		return
	end

	local currentConfig = self:GetCurrentMissionConfig()
	if currentConfig then
		missionCache.PreviousMission = {
			ID = currentConfig.ID,
			RewardTiers = currentConfig.RewardTiers,
			InstanceKey = GetMissionInstanceKey() -- Simpan kunci unik sesi sebelumnya
		}
	else
		missionCache.PreviousMission = nil
	end

	missionCache.ActiveMissionID = newMission.ID
	missionCache.GlobalProgress = 0
	missionCache.StartTime = os.time()
	missionCache.Notified50 = false
	missionCache.Notified75 = false
	missionCache.Notified100 = false

	self:_saveGlobalData()
	print(string.format("[GlobalMissionManager] Misi baru dimulai: %s", newMission.Description))

	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local notificationEvent = remoteEvents and remoteEvents:FindFirstChild("GlobalMissionNotification")
	if notificationEvent then
		notificationEvent:FireAllClients("Misi Baru Dimulai!", newMission.Description)
	end
end

function GlobalMissionManager:CheckForWeeklyReset()
	if not missionCache.IsLoaded then return end
	local timeSinceStart = os.time() - (missionCache.StartTime or 0)
	if not missionCache.StartTime or missionCache.StartTime == 0 or timeSinceStart >= GlobalMissionConfig.MISSION_DURATION then
		self:_startNewWeeklyMission()
	end
end

-- ==================================================
-- FUNGSI PUBLIK
-- ==================================================

function GlobalMissionManager:GetCurrentMissionConfig()
	if not missionCache.ActiveMissionID then return nil end
	for _, mission in ipairs(GlobalMissionConfig.Missions) do
		if mission.ID == missionCache.ActiveMissionID then return mission end
	end
	return nil
end

function GlobalMissionManager:IncrementProgress(eventType, amount, player)
	if not missionCache.IsLoaded or not missionCache.ActiveMissionID then return end
	local config = self:GetCurrentMissionConfig()
	if not config or config.Type ~= eventType then return end

	missionCache.GlobalProgress += amount

	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then return end

	-- Gunakan KUNCI UNIK (ID + StartTime) untuk memastikan kontribusi direset setiap sesi baru
	local instanceKey = GetMissionInstanceKey()
	if not instanceKey then return end

	if not playerData.data.globalMissions[instanceKey] then
		playerData.data.globalMissions[instanceKey] = { Contribution = 0, Claimed = false }
	end

	playerData.data.globalMissions[instanceKey].Contribution += amount
	DataStoreManager:UpdatePlayerData(player, playerData.data)

	-- Buffer leaderboard update untuk mencegah throttling
	local leaderboardName = LEADERBOARD_PREFIX .. instanceKey
	pendingLeaderboardUpdates[player.UserId] = {
		LeaderboardName = leaderboardName,
		Value = playerData.data.globalMissions[instanceKey].Contribution
	}
end

function GlobalMissionManager:ClaimReward(player)
	local prevMission = missionCache.PreviousMission
	if not prevMission or not prevMission.ID or not prevMission.InstanceKey then
		return { Success = false, Reason = "Tidak ada hadiah dari misi sebelumnya." }
	end

	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	-- Gunakan kunci sesi misi sebelumnya
	if not playerData or not playerData.data or not playerData.data.globalMissions[prevMission.InstanceKey] then
		return { Success = false, Reason = "Anda tidak berpartisipasi dalam misi minggu lalu." }
	end

	local playerDataForMission = playerData.data.globalMissions[prevMission.InstanceKey]
	if playerDataForMission.Claimed then
		return { Success = false, Reason = "Anda sudah mengklaim hadiah untuk misi ini." }
	end

	local rewardToGive = nil
	for i = #prevMission.RewardTiers, 1, -1 do
		local tier = prevMission.RewardTiers[i]
		if playerDataForMission.Contribution >= tier.Contribution then
			rewardToGive = tier.Reward
			break
		end
	end

	if not rewardToGive then
		return { Success = false, Reason = "Kontribusi Anda tidak mencapai tingkatan hadiah." }
	end

	MissionPointsModule:AddMissionPoints(player, rewardToGive.Value)
	playerDataForMission.Claimed = true
	DataStoreManager:UpdatePlayerData(player, playerData.data)

	return { Success = true, Reward = rewardToGive }
end

-- ==================================================
-- INISIALISASI & KONEKSI
-- ==================================================

function GlobalMissionManager:Init()
	self:_loadGlobalData()
	self:CheckForWeeklyReset()

	coroutine.wrap(function()
		while true do task.wait(60); self:_saveGlobalData() end
	end)()
	coroutine.wrap(function()
		while true do task.wait(3600); self:CheckForWeeklyReset() end
	end)()

	-- Flush pending leaderboard updates
	coroutine.wrap(function()
		while true do
			task.wait(15) -- Flush setiap 15 detik
			local updates = pendingLeaderboardUpdates
			pendingLeaderboardUpdates = {} -- Reset buffer

			for userId, data in pairs(updates) do
				task.spawn(function()
					DataStoreManager:UpdateLeaderboard(data.LeaderboardName, userId, data.Value)
				end)
			end
		end
	end)()
end

-- RemoteFunctions (disederhanakan untuk keringkasan, logika inti dipindahkan ke DataStoreManager)
-- RemoteFunctions
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions") or Instance.new("Folder", ReplicatedStorage)
remoteFunctions.Name = "RemoteFunctions"

local getGlobalMissionState = remoteFunctions:FindFirstChild("GetGlobalMissionState") or Instance.new("RemoteFunction", remoteFunctions)
getGlobalMissionState.Name = "GetGlobalMissionState"
getGlobalMissionState.OnServerInvoke = function(player)
	if not missionCache.IsLoaded then return nil end
	local config = GlobalMissionManager:GetCurrentMissionConfig()
	if not config then return nil end

	local playerContribution = 0
	local instanceKey = GetMissionInstanceKey()

	if instanceKey then
		-- Cek data pemain menggunakan KUNCI UNIK sesi ini
		local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
		if playerData and playerData.data and playerData.data.globalMissions and playerData.data.globalMissions[instanceKey] then
			playerContribution = playerData.data.globalMissions[instanceKey].Contribution or 0
		else
			-- Fallback ke leaderboard sesi ini
			local leaderboardName = LEADERBOARD_PREFIX .. instanceKey
			local score, _ = DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, player.UserId)
			playerContribution = score or 0
		end
	end

	return {
		Description = config.Description,
		GlobalProgress = missionCache.GlobalProgress,
		GlobalTarget = config.GlobalTarget,
		PlayerContribution = playerContribution,
		EndTime = missionCache.StartTime + GlobalMissionConfig.MISSION_DURATION,
		RewardTiers = config.RewardTiers
	}
end

local claimGlobalMissionReward = remoteFunctions:FindFirstChild("ClaimGlobalMissionReward") or Instance.new("RemoteFunction", remoteFunctions)
claimGlobalMissionReward.Name = "ClaimGlobalMissionReward"
claimGlobalMissionReward.OnServerInvoke = function(player)
	return GlobalMissionManager:ClaimReward(player)
end

local getGlobalMissionLeaderboard = remoteFunctions:FindFirstChild("GetGlobalMissionLeaderboard") or Instance.new("RemoteFunction", remoteFunctions)
getGlobalMissionLeaderboard.Name = "GetGlobalMissionLeaderboard"
getGlobalMissionLeaderboard.OnServerInvoke = function(player)
	local instanceKey = GetMissionInstanceKey()
	if not instanceKey then return {} end

	local leaderboardName = LEADERBOARD_PREFIX .. instanceKey
	local topPlayersRaw = DataStoreManager:GetLeaderboardData(leaderboardName, false, 10)
	if not topPlayersRaw then return {} end

	local leaderboardData = {}
	for rank, data in ipairs(topPlayersRaw) do
		local userId = tonumber(data.key)
		local username = "???"
		local success, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
		if success then username = name end
		table.insert(leaderboardData, { Rank = rank, Name = username, Contribution = data.value })
	end
	return leaderboardData
end

local getPlayerGlobalMissionRank = remoteFunctions:FindFirstChild("GetPlayerGlobalMissionRank") or Instance.new("RemoteFunction", remoteFunctions)
getPlayerGlobalMissionRank.Name = "GetPlayerGlobalMissionRank"
getPlayerGlobalMissionRank.OnServerInvoke = function(player)
	local instanceKey = GetMissionInstanceKey()
	if not instanceKey then return "N/A" end

	local leaderboardName = LEADERBOARD_PREFIX .. instanceKey
	local score, rank = DataStoreManager:GetPlayerRankInLeaderboard(leaderboardName, player.UserId)

	return rank or "N/A"
end

GlobalMissionManager:Init()

return GlobalMissionManager
