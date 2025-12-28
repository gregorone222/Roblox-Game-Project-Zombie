-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- GameManager.lua (Script)
-- Path: ServerScriptService/Script/GameManager.lua
-- Script Place: ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Constants = require(ServerScriptService.ModuleScript:WaitForChild("Constants"))
local TeleportService = game:GetService("TeleportService")

-- Module Requirements - Moved up to scope level to fix Type Error
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript
local GameConfig = require(game.ServerScriptService.ModuleScript.GameConfig)
local BuildingManager = require(ModuleScriptServerScriptService:WaitForChild("BuildingModule"))
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local SessionDataManager = require(ModuleScriptServerScriptService:WaitForChild("SessionDataManager"))
local PlaceData = require(ModuleScriptServerScriptService:WaitForChild("PlaceDataConfig"))
local SpawnerModule = require(ModuleScriptServerScriptService:WaitForChild("SpawnerModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("ValorModule"))
local CoinsModule = require(ModuleScriptServerScriptService:WaitForChild("SurvivalCoinsModule"))
local LevelModule = require(ModuleScriptServerScriptService:WaitForChild("LevelModule"))
local BoosterManager = require(ModuleScriptServerScriptService:WaitForChild("BoosterManager"))
local TacticalBoostModule = require(ModuleScriptServerScriptService:WaitForChild("TacticalBoostModule"))
local PerkHandler = require(ModuleScriptServerScriptService:WaitForChild("PerkModule"))
local WalkSpeedManager = require(ModuleScriptServerScriptService:WaitForChild("WalkSpeedManager"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))
local ShieldModule = require(ModuleScriptServerScriptService:WaitForChild("ShieldModule"))
local MissionManager = require(ModuleScriptServerScriptService:WaitForChild("MissionManager"))
local GlobalMissionManager = require(ModuleScriptServerScriptService:WaitForChild("GlobeMissionManager"))
local AchievementManager = require(ModuleScriptServerScriptService:WaitForChild("AchievementManager"))
local DataStoreManager = require(ModuleScriptServerScriptService:WaitForChild("DataStoreManager"))
local ObjectiveManager = require(ModuleScriptServerScriptService:WaitForChild("ObjectiveManager"))

DataStoreManager:Init()

-- Game Mode Initialization
-- Game Initialization
local gameMode = Constants.Strings.GAME_MODE_STORY -- Default to Story
local difficulty = Constants.Strings.DIFFICULTY_NORMAL -- Default difficulty
local gameInitialized = false

local function initializeGameSettings(player)
	if gameInitialized then return end

	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData

	if teleportData then
		gameMode = teleportData.gameMode or Constants.Strings.GAME_MODE_STORY
		difficulty = teleportData.difficulty or Constants.Strings.DIFFICULTY_NORMAL
		gameInitialized = true
		print(string.format("Game settings initialized from JoinData. Mode: %s, Difficulty: %s", gameMode, difficulty))
	else
		-- Fallback for players joining directly or if data is missing
		gameInitialized = true
		print("No JoinData found for game settings. Defaulting to Story and Normal.")
	end

	-- DEBUG / PREVIEW MODE: Load Act 1 Map immediately if requested
	-- For this task, we default to Village to satisfy "Make map without needing to start game"
	if GameConfig.DebugMode then
		task.spawn(function()
			task.wait(1)
			BuildingManager.LoadMap("Village")
		end)
	else
		-- Default Production Flow
		task.spawn(function()
			task.wait(1)
			BuildingManager.LoadMap("Lobby")
		end)
	end
end

-- Connect to PlayerAdded to get the game mode from the first player
local playerAddedConnection
playerAddedConnection = Players.PlayerAdded:Connect(function(player)
	initializeGameSettings(player)
	-- Disconnect after the first player joins to avoid re-initializing
	if gameInitialized and playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
end)

-- Handle players who might already be in the game when the script runs
if #Players:GetPlayers() > 0 then
	initializeGameSettings(Players:GetPlayers()[1])
	if gameInitialized and playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
end



local BindableEvents = game.ReplicatedStorage:WaitForChild("BindableEvents")
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")

-- Pastikan MissionCompleteEvent ada
if not RemoteEvents:FindFirstChild(Constants.Events.MISSION_COMPLETE) then
	local event = Instance.new("RemoteEvent")
	event.Name = Constants.Events.MISSION_COMPLETE
	event.Parent = RemoteEvents
end

-- Pastikan GameModeUpdateEvent ada
-- Pastikan GameSettingsUpdateEvent ada
if not RemoteEvents:FindFirstChild(Constants.Events.GAME_SETTINGS_UPDATE) then
	local event = Instance.new("RemoteEvent")
	event.Name = Constants.Events.GAME_SETTINGS_UPDATE
	event.Parent = RemoteEvents
end

-- Pastikan SpecialWaveAlertEvent ada
if not RemoteEvents:FindFirstChild(Constants.Events.SPECIAL_WAVE_ALERT) then
	local event = Instance.new("RemoteEvent")
	event.Name = Constants.Events.SPECIAL_WAVE_ALERT
	event.Parent = RemoteEvents
end

local WaveCountdownEvent = RemoteEvents:WaitForChild(Constants.Events.WAVE_COUNTDOWN)
local PlayerCountEvent   = RemoteEvents:WaitForChild(Constants.Events.PLAYER_COUNT)
local OpenStartUIEvent   = RemoteEvents:WaitForChild(Constants.Events.OPEN_START_UI)
local ReadyCountEvent    = RemoteEvents:WaitForChild(Constants.Events.READY_COUNT)
local RestartGameEvent = RemoteEvents:WaitForChild(Constants.Events.RESTART_GAME)
local StartGameEvent = RemoteEvents:WaitForChild(Constants.Events.START_GAME)
local ExitGameEvent = RemoteEvents:WaitForChild(Constants.Events.EXIT_GAME)
local WaveUpdateEvent = RemoteEvents:WaitForChild(Constants.Events.WAVE_UPDATE)
local StartVoteCountdownEvent = RemoteEvents:WaitForChild(Constants.Events.START_VOTE_COUNTDOWN)
local StartVoteCanceledEvent  = RemoteEvents:WaitForChild(Constants.Events.START_VOTE_CANCELED)
local CancelStartVoteEvent = RemoteEvents:WaitForChild(Constants.Events.CANCEL_START_VOTE)
local GameOverEvent = RemoteEvents:WaitForChild(Constants.Events.GAME_OVER) -- Defined here to ensure visibility

local ZombieDiedEvent = BindableEvents:WaitForChild(Constants.Events.ZOMBIE_DIED)
local LightingManager = require(ModuleScriptServerScriptService:WaitForChild("LightingManager"))

-- Initialize Lighting immediately
LightingManager.Init()

local Lighting = game:GetService("Lighting")
-- Simpan nilai default lighting untuk dipulihkan nanti (Use LightingManager Base)
local defaultLightingSettings = LightingManager.BaseSettings

local ReportDamageEvent = BindableEvents:FindFirstChild(Constants.Events.REPORT_DAMAGE) or Instance.new("BindableEvent", BindableEvents)
ReportDamageEvent.Name = Constants.Events.REPORT_DAMAGE

-- Penanda sesi voting agar timer lama tidak 'menimpa' sesi baru
local currentVoteSession = 0
local zombiesToSpawn = 0
local zombiesKilled = 0
local chamsApplied = false
local wave = 1
local gameStarted = false
-- Token sesi untuk membatalkan loop lama
local runToken = 0
local activePlayers = 0
local initialPlayerCount = 0
-- Kumpulan pemain yang sudah menekan YES
local readyPlayers = {}
local waveDamageTracker = {}

ReportDamageEvent.Event:Connect(function(player, damageAmount)
	if not gameStarted or not player or not damageAmount then return end

	local userId = player.UserId
	if not waveDamageTracker[userId] then
		waveDamageTracker[userId] = 0
	end
	waveDamageTracker[userId] += damageAmount
end)

-- === ADMIN COMMAND LISTENERS ===
-- Listen for admin commands from AdminCommands.lua

local function killAllZombiesAdmin()
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild(Constants.Attributes.IS_ZOMBIE) then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
	end
end

-- AdminSetWave event
local adminSetWaveEvent = BindableEvents:FindFirstChild("AdminSetWave")
if not adminSetWaveEvent then
	adminSetWaveEvent = Instance.new("BindableEvent")
	adminSetWaveEvent.Name = "AdminSetWave"
	adminSetWaveEvent.Parent = BindableEvents
end

adminSetWaveEvent.Event:Connect(function(targetWave)
	if not gameStarted then
		warn("AdminSetWave: Game not started")
		return
	end
	
	targetWave = math.clamp(targetWave, 1, 50)
	killAllZombiesAdmin()
	wave = targetWave - 1
	zombiesKilled = zombiesToSpawn
	print("Admin: Wave set to " .. targetWave)
end)

-- AdminSkipWave event
local adminSkipWaveEvent = BindableEvents:FindFirstChild("AdminSkipWave")
if not adminSkipWaveEvent then
	adminSkipWaveEvent = Instance.new("BindableEvent")
	adminSkipWaveEvent.Name = "AdminSkipWave"
	adminSkipWaveEvent.Parent = BindableEvents
end

adminSkipWaveEvent.Event:Connect(function()
	if not gameStarted then return end
	killAllZombiesAdmin()
	zombiesKilled = zombiesToSpawn
	print("Admin: Skipped to next wave")
end)

-- >>> TRANSISI LIGHTING ANTAR-WAVE <<<
local function tweenLightingTo(targetSettings, duration)
	LightingManager.ApplySettings(targetSettings, duration)
end
-- <<< END TRANSISI LIGHTING >>>

-- Fungsi untuk memulihkan lighting ke kondisi awal
local function restoreLighting()
	LightingManager.ApplySettings(LightingManager.BaseSettings, 1)
end

local function ApplyChamsToZombies()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild(Constants.Attributes.IS_ZOMBIE) and not m:FindFirstChild(Constants.Attributes.IS_BOSS) then
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				-- Hanya zombie yang masih hidup yang diberi highlight
				if not m:FindFirstChild(Constants.Strings.CHAMS_HIGHLIGHT) then
					local h = Instance.new("Highlight")
					h.Name = Constants.Strings.CHAMS_HIGHLIGHT
					h.FillTransparency = 1 -- hanya outline
					h.OutlineTransparency = 0
					h.OutlineColor = Color3.fromRGB(0, 255, 0) -- hijau
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- tembus tembok
					h.Parent = m
				end
			else
				-- Jika mayat masih tersisa dan sempat punya highlight, cabut supaya tidak ikut ter-highlight
				local h = m:FindFirstChild(Constants.Strings.CHAMS_HIGHLIGHT)
				if h then h:Destroy() end
			end
		end
	end
end

local function ClearChams()
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild(Constants.Attributes.IS_ZOMBIE) then
			local h = m:FindFirstChild(Constants.Strings.CHAMS_HIGHLIGHT)
			if h then h:Destroy() end
		end
	end
end

local function HandleGameOver()
	if not gameStarted then return end
	print("Semua pemain telah kalah. Game Over.")

	runToken += 1 -- Hentikan semua loop game yang sedang berjalan
	gameStarted = false

	-- Konsumsi booster berbasis game
	for _, player in ipairs(Players:GetPlayers()) do
		BoosterManager.ConsumeGameBooster(player, Constants.Strings.COIN_BOOSTER_1GAME)
	end

	-- Kirim event ke semua client untuk menampilkan layar Game Over
	GameOverEvent:FireAllClients()

	-- Reset Objectives to prevent softlock on next game
	ObjectiveManager:Reset()

	-- Di sini kita tidak langsung teleport. Client akan memiliki tombol untuk kembali ke lobi.
end

-- Fungsi untuk menghitung pemain aktif
local function countActivePlayers()
	-- Di lobby/awal, Character bisa belum spawn ? hitung taotal pemain saja
	if not gameStarted then
		return #game.Players:GetPlayers()
	end

	-- Saat game berjalan, hitung pemain yang benar-benar aktif (punya Character dan tidak Knocked)
	local count = 0
	for _, player in ipairs(game.Players:GetPlayers()) do
		if player.Character and not player.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				count += 1
			end
		end
	end
	return count
end


-- Fungsi update jumlah pemain ke semua client
local function updatePlayerCount()
	activePlayers = countActivePlayers()
	PlayerCountEvent:FireAllClients(activePlayers)

	-- Cek kondisi game over jika permainan sudah dimulai
	if gameStarted and activePlayers == 0 then
		HandleGameOver()
	end

	return activePlayers
end

-- Fungsi reset game
local function ResetGame()
	gameStarted = false
	wave = 1
	zombiesKilled = 0
	-- Naikkan token agar loop lama segera berhenti
	runToken += 1

	-- Bersihkan semua zombie sisa sesi sebelumnya
	for _, m in ipairs(workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild(Constants.Attributes.IS_ZOMBIE) then
			m:Destroy()
		end
	end

	restoreLighting() -- pastikan lighting balik normal saat reset
	ClearChams()
	-- Reset purchased elements
	ElementModule.ClearPurchasedElements()

	-- Reset Objectives
	ObjectiveManager:Reset()

	-- Load Lobby Map
	BuildingManager.LoadMap("Lobby")

	-- Reset perks, points & leaderstats untuk semua player
	for _, player in ipairs(game.Players:GetPlayers()) do
		PerkHandler.clearPlayerPerks(player)
		PointsSystem.SetupPlayer(player)
	end
end

-- Event zombie mati
ZombieDiedEvent.Event:Connect(function()
	-- Abaikan kill jika game tidak berjalan (hindari wave skip)
	if not gameStarted then return end
	zombiesKilled += 1
end)

-- Fungsi start loop game
local function startGameLoop()
	if gameStarted then return end

	-- Load Village Map for Game
	BuildingManager.LoadMap("Village")

	-- Atur tingkat kesulitan di GameStatus
	GameStatus:SetDifficulty(difficulty)

	-- Reset data sesi permainan
	SessionDataManager:ResetAllSessionData()

	gameStarted = true
	-- Buat sesi baru dan ikat loop ke sesi ini
	runToken += 1
	local myToken = runToken

	-- Update jumlah pemain
	activePlayers = updatePlayerCount()
	initialPlayerCount = activePlayers
	print("Game started with " .. initialPlayerCount .. " players.")

	-- Tambahkan ini untuk menginisialisasi UI pada semua pemain saat game dimulai
	for _, plr in pairs(game.Players:GetPlayers()) do
		PointsSystem.AddPoints(plr, 0) -- Menginisialisasi poin dan menampilkan UI

		-- Cek dan gunakan booster
		local boosterData = BoosterModule.GetData(plr)
		if boosterData and boosterData.Active then
			local activeBooster = boosterData.Active -- Simpan nama booster aktif
			local usedBooster = BoosterModule.UseActiveBooster(plr) -- Gunakan dan konsumsi

			if usedBooster then -- Pastikan booster berhasil digunakan
				if usedBooster == Constants.Strings.STARTER_POINTS_BOOSTER then
					PointsSystem.AddPoints(plr, 1500)
					print(plr.Name .. " used StarterPoints booster and received 1500 points.")
				elseif usedBooster == Constants.Strings.STARTING_SHIELD_BOOSTER then
					if plr.Character then
						local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local shieldAmount = humanoid.MaxHealth * 0.5
							ShieldModule.Set(plr, shieldAmount)
							print(plr.Name .. " used StartingShield booster and received a 50% shield.")
						end
					end
				elseif usedBooster == Constants.Strings.AMMO_CACHE_BOOSTER then
					-- AmmoCache: +50% max ammo pada semua senjata
					if plr.Character then
						plr.Character:SetAttribute("AmmoBoost", true)
					end
					print(plr.Name .. " used AmmoCache booster and received +50% max ammo.")
				elseif usedBooster == Constants.Strings.COMMANDER_BUFF_BOOSTER then
					-- CommanderBuff: +10% damage untuk semua ally
					for _, ally in ipairs(Players:GetPlayers()) do
						if ally.Character then
							local currentBonus = ally.Character:GetAttribute("DamageBonusPct") or 0
							ally.Character:SetAttribute("DamageBonusPct", currentBonus + 10)
						end
					end
					print(plr.Name .. " used CommanderBuff booster! All allies get +10% damage.")
				end
			end
		end
	end

	-- Start playtime tracking loop
	task.spawn(function()
		while myToken == runToken and gameStarted do
			task.wait(60) -- Wait for 60 seconds
			if not gameStarted then break end -- Double check if game has ended

			for _, player in ipairs(game.Players:GetPlayers()) do
				-- Add playtime only to active (not knocked) players
				if player.Character and not player.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
					if StatsModule and StatsModule.AddPlaytime then
						StatsModule.AddPlaytime(player, 60)
					end
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			if (myToken ~= runToken) or (not gameStarted) then break end

			print("Wave " .. wave .. " dimulai! Jumlah Pemain: " .. activePlayers)
			WaveUpdateEvent:FireAllClients(wave, activePlayers)

			-- === PROGRESSIVE DAY CYCLE ===
			if GameConfig.DayCycle and GameConfig.DayCycle.Enabled then
				local clockTime = LightingManager.CalculateTimeForWave(
					wave,
					GameConfig.DayCycle.StartTime,
					GameConfig.DayCycle.EndTime,
					GameConfig.DayCycle.TotalWaves
				)
				LightingManager.SetTimeOfDay(clockTime, GameConfig.DayCycle.TransitionDuration)
			end

			local waveModifiers = {}

			-- Cek dulu apakah ini boss wave
			local isBossWave, bossType = SpawnerModule.IsBossWave(wave, gameMode, difficulty)

			-- Hanya jalankan logika special wave jika BUKAN boss wave
			-- NOTE: DarkWave and BloodMoon are DISABLED (replaced by progressive day cycle)
			if not isBossWave then
				local isSpecialEventTriggered = false
				
				-- Only check FastWave and SpecialWave now
				local rand = math.random()
				if rand < GameConfig.FastWave.Chance then
					waveModifiers.isFast = true
					RemoteEvents.SpecialWaveAlertEvent:FireAllClients("Fast Wave")
					print("Fast Wave!")
				elseif rand < (GameConfig.FastWave.Chance + GameConfig.SpecialWave.Chance) then
					waveModifiers.isSpecial = true
					RemoteEvents.SpecialWaveAlertEvent:FireAllClients("Special Wave")
					print("Special Wave!")
				end
			end

			zombiesToSpawn = wave * GameConfig.Wave.ZombiesPerWavePerPlayer * initialPlayerCount
			updatePlayerCount()

			zombiesKilled = 0
			chamsApplied = false
			ClearChams()
			waveDamageTracker = {}

			-- Check for Special Objective Waves
			local objectiveActive = false

			-- Helper to find map nodes
			local function getObjectiveNodes(name)
				local nodes = {}
				local map = workspace:FindFirstChild("Map_Village")
				if map then
					for _, desc in ipairs(map:GetDescendants()) do
						if desc.Name == name and desc:IsA("Attachment") then
							table.insert(nodes, desc.WorldPosition)
						end
					end
				end
				return nodes
			end

			local function getObjectivePos(name)
				local map = workspace:FindFirstChild("Map_Village")
				if map then
					for _, desc in ipairs(map:GetDescendants()) do
						if desc.Name == name and desc:IsA("Attachment") then
							return desc.WorldPosition
						end
					end
				end
				return Vector3.new(0,5,0)
			end

			if wave == 8 then
				-- Wave 8: Power Restoration
				objectiveActive = true
				local gasSpawns = getObjectiveNodes("Spawn_Gas")
				if #gasSpawns == 0 then gasSpawns = {Vector3.new(50,2,50)} end -- Fallback

				ObjectiveManager:StartObjective("SCAVENGE", {
					Count = 3,
					Spawns = gasSpawns,
					GenPos = Vector3.new(0, 2, 30) -- Near spawn/center
				})
			elseif wave == 22 then
				-- Wave 22: Data Uplink
				objectiveActive = true
				local zonePos = getObjectivePos("Zone_Defend")
				ObjectiveManager:StartObjective("DEFEND", {
					Duration = 60,
					ZonePos = zonePos,
					Radius = 20
				})
			elseif wave == 38 then
				-- Wave 38: Retrieval
				objectiveActive = true
				local sampleSpawns = getObjectiveNodes("Spawn_Sample")
				if #sampleSpawns == 0 then sampleSpawns = {Vector3.new(40,2,40)} end

				ObjectiveManager:StartObjective("RETRIEVE", {
					Count = 4,
					Spawns = sampleSpawns
				})
			end

			-- Panggil SpawnWave setelah semua modifier ditentukan
			SpawnerModule.SpawnWave(zombiesToSpawn, wave, activePlayers, gameMode, difficulty, waveModifiers, bossType)

			print("Waiting for completion...")

			-- Modified Loop: Wait for BOTH zombies and Objective (if active)
			while true do
				local remainingZombies = math.max(0, zombiesToSpawn - zombiesKilled)
				local objectiveDone = (not objectiveActive) or (not ObjectiveManager:IsObjectiveActive())

				-- Objective waves continue until objective is done, even if zombies are dead (infinite spawn logic could be added here later)
				if objectiveActive then
					if objectiveDone and remainingZombies <= 0 then
						break -- All done
					end
				else
					if remainingZombies <= 0 then
						break -- Only zombies mattered
					end
				end

				if (not chamsApplied) and remainingZombies <= 3 and not objectiveActive then
					chamsApplied = true
					ApplyChamsToZombies()
				end

				if (myToken ~= runToken) or (not gameStarted) then return end
				task.wait(1)
			end

			print("Wave " .. wave .. " complete!")
			if (myToken ~= runToken) or (not gameStarted) then break end

			-- FORCE BREAK JIKA GAME OVER
			if activePlayers <= 0 then
				print("No active players remaining. Breaking wave loop.")
				break
			end

			-- DOUBLE CHECK GAME OVER STATUS
			updatePlayerCount() -- Force update to ensure we catch recent deaths
			if activePlayers <= 0 then
				print("No active players remaining. Breaking wave loop.")
				break
			end

			-- <<< KONDISI KEMENANGAN (HANYA UNTUK MODE STORY) >>>
			if gameMode == Constants.Strings.GAME_MODE_STORY then
				if wave == 50 then
					print("Wave 50 selesai! Blighted Alchemist defeated! Mission Complete!")
					
					-- Apply beautiful golden hour victory lighting
					LightingManager.ApplyVictoryLighting(5)
					
					local missionCompleteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild(Constants.Events.MISSION_COMPLETE)
					if missionCompleteEvent then
						missionCompleteEvent:FireAllClients()
					end
					runToken += 1
					gameStarted = false
					for _, player in ipairs(Players:GetPlayers()) do
						BoosterManager.ConsumeGameBooster(player, Constants.Strings.COIN_BOOSTER_1GAME)
					end
					task.wait(10)
					local lobbyId = PlaceData[Constants.Strings.LOBBY_PLACE]
					if lobbyId then
						local playersToTeleport = game.Players:GetPlayers()
						if #playersToTeleport > 0 then
							for _, p in ipairs(playersToTeleport) do
								DataStoreManager:SavePlayerDataYielding(p)
							end
							local success, result = pcall(function()
								return TeleportService:TeleportAsync(lobbyId, playersToTeleport)
							end)
							if not success then
								warn("Gagal teleport pemain setelah kemenangan: " .. tostring(result))
							end
						end
					else
						warn("ID Lobi tidak ditemukan untuk teleport kemenangan.")
					end
					break
				end
			end
			-- <<< AKHIR KONDISI KEMENANGAN >>>

			if isBossWave then
				-- BuildingManager.restoreBuildings() -- Deprecated
			end

			-- NOTE: DarkWave/BloodMoon lighting restoration removed
			-- Day cycle is now progressive and doesn't need restoration

			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character then
					local isKnocked = player.Character:FindFirstChild(Constants.Attributes.KNOCKED)
					-- All players now get 100% of the rewards regardless of knocked status.

					local userId = player.UserId
					local totalDamage = waveDamageTracker[userId] or 0
					local coinConfig = GameConfig.Economy.Coins
					local difficultyConfig = GameConfig.Difficulty[difficulty]
					if coinConfig and difficultyConfig then
						local healthMultiplier = difficultyConfig.HealthMultiplier
						local adjustedRatio = coinConfig.DamageToCoinConversionRatio * healthMultiplier
						local coinsFromDamage = 0
						if adjustedRatio > 0 then
							coinsFromDamage = math.floor(totalDamage / adjustedRatio)
						end
						local baseReward = coinConfig.WaveCompleteBonus + coinsFromDamage
						local difficultyMultiplier = coinConfig.DifficultyCoinMultipliers[difficulty] or 1
						local finalCoinReward = math.floor(baseReward * difficultyMultiplier)
						if BoosterManager.IsBoosterActive(player, Constants.Strings.COIN_BOOSTER_1GAME) then
							finalCoinReward = math.floor(finalCoinReward * 1.5)
							print(player.Name .. " gets 50% Coin bonus from booster!")
						end

						if finalCoinReward > 0 then
							CoinsModule.AddCoins(player, finalCoinReward)
						end
					end
					local xpConfig = GameConfig.Economy.XP
					if xpConfig and difficultyConfig then
						local healthMultiplier = difficultyConfig.HealthMultiplier
						local adjustedRatio = xpConfig.DamageToXPConversionRatio * healthMultiplier
						local xpFromDamage = 0
						if adjustedRatio > 0 then
							xpFromDamage = math.floor(totalDamage / adjustedRatio)
						end
						local baseReward = xpConfig.WaveCompleteXPBonus + xpFromDamage
						local difficultyMultiplier = xpConfig.DifficultyXPMultipliers[difficulty] or 1
						local finalXPReward = math.floor(baseReward * difficultyMultiplier)
						if BoosterManager.IsBoosterActive(player, Constants.Strings.XP_BOOSTER_30MIN) then
							finalXPReward = finalXPReward * 2
							print(player.Name .. " gets 2x XP bonus from booster!")
						end

						if finalXPReward > 0 then
							LevelModule.AddXP(player, finalXPReward)
						end
					end

					PointsSystem.AddPoints(player, GameConfig.Wave.BonusPoints)

					if not isKnocked then
						local humanoid = player.Character:FindFirstChild("Humanoid")
						if humanoid then
							local healAmount = humanoid.MaxHealth * GameConfig.Wave.HealPercentage
							humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healAmount)
						end
					end

					if MissionManager then
						MissionManager:UpdateMissionProgress(player, { eventType = "WAVE_COMPLETE", amount = 1 })
						GlobalMissionManager:IncrementProgress("WAVE_COMPLETE", 1, player)
					end
					if AchievementManager and AchievementManager.UpdateWaveSurvivedProgress then
						AchievementManager:UpdateWaveSurvivedProgress(player)
					end
					if AchievementManager and AchievementManager.UpdateStatProgress then
						AchievementManager:UpdateStatProgress(player, "TotalWavesCompleted")
					end
				end
			end

			if difficulty == Constants.Strings.DIFFICULTY_CRAZY then
				for _, player in ipairs(game.Players:GetPlayers()) do
					if player.Character and player.Character:FindFirstChild(Constants.Attributes.KNOCKED) then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							print("Auto-reviving " .. player.Name .. " for Crazy mode.")
							humanoid.Health = humanoid.MaxHealth * 0.1
							WalkSpeedManager.remove_modifier(player, "knock")
							humanoid.JumpPower = 50
							humanoid.PlatformStand = false
							local knockedTag = player.Character:FindFirstChild(Constants.Attributes.KNOCKED)
							if knockedTag then knockedTag:Destroy() end
							RemoteEvents.KnockEvent:FireClient(player, false)
						end
					end
				end
			end

			-- NOTE: DarkWave prediction removed - day cycle is now continuous
			-- No need to predict or transition to dark settings

			for count = 10, 1, -1 do
				if (myToken ~= runToken) or (not gameStarted) then break end
				WaveCountdownEvent:FireAllClients(count)
				task.wait(1)
			end
			WaveCountdownEvent:FireAllClients(0)
			task.wait(0.1)

			ElementModule.ClearPurchasedElements()
			updatePlayerCount()
			wave += 1
		end
	end)
end

StartGameEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end
	readyPlayers[player.UserId] = true
	local total = #game.Players:GetPlayers()
	local ready = 0
	for _, plr in ipairs(game.Players:GetPlayers()) do
		if readyPlayers[plr.UserId] then ready += 1 end
	end
	ReadyCountEvent:FireAllClients(ready, total)
	if ready >= total then
		readyPlayers = {}
		print("All players are ready. Starting the game...")
		currentVoteSession += 1
		startGameLoop()
	end
end)

CancelStartVoteEvent.OnServerEvent:Connect(function(player)
	if gameStarted then return end
	currentVoteSession += 1
	readyPlayers = {}
	local total = #game.Players:GetPlayers()
	local who = (player.DisplayName or player.Name)
	StartVoteCanceledEvent:FireAllClients(who)
	ReadyCountEvent:FireAllClients(0, total)
end)

local teleportingPlayers = {}

ExitGameEvent.OnServerEvent:Connect(function(player)
	if teleportingPlayers[player.UserId] then
		warn("Player " .. player.Name .. " is already being teleported.")
		return
	end
	print(player.Name .. " chose to exit.")
	local lobbyId = PlaceData[Constants.Strings.LOBBY_PLACE]
	if lobbyId then
		DataStoreManager:SavePlayerDataYielding(player)
		teleportingPlayers[player.UserId] = true
		local success, result = pcall(function()
			return TeleportService:TeleportAsync(lobbyId, {player})
		end)
		if success then
			print("Successfully initiated teleport for " .. player.Name .. " to Lobby (ID: " .. lobbyId .. ")")
		else
			warn("TeleportAsync failed for " .. player.Name .. ": " .. tostring(result))
		end
		task.delay(5, function()
			teleportingPlayers[player.UserId] = nil
		end)
	else
		warn("Lobby place ID not found in PlaceData.")
	end
	ResetGame()
end)

game.Players.PlayerAdded:Connect(function(player)
	if PointsSystem and type(PointsSystem.SetupPlayer) == "function" then
		PointsSystem.SetupPlayer(player)
	end
	updatePlayerCount()
	DataStoreManager:LoadPlayerData(player)
	task.spawn(function()
		local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
		if not player.Parent then return end
	end)
	local gameSettingsUpdateEvent = RemoteEvents:FindFirstChild("GameSettingsUpdateEvent")
	if gameSettingsUpdateEvent then
		gameSettingsUpdateEvent:FireClient(player, {gameMode = gameMode, difficulty = difficulty})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	updatePlayerCount()
end)

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character.ChildAdded:Connect(function(child)
			if child.Name == Constants.Attributes.KNOCKED then
				updatePlayerCount()
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child.Name == Constants.Attributes.KNOCKED then
				updatePlayerCount()
			end
		end)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			task.wait(0.1)
			updatePlayerCount()
		end)
	end)
end)

OpenStartUIEvent.OnServerEvent:Connect(function(_player)
	if gameStarted then return end
	readyPlayers = {}
	updatePlayerCount()
	ReadyCountEvent:FireAllClients(0, #game.Players:GetPlayers())
	OpenStartUIEvent:FireAllClients()
	currentVoteSession += 1
	local mySession = currentVoteSession
	task.spawn(function()
		for t = 30, 0, -1 do
			if gameStarted or currentVoteSession ~= mySession then return end
			StartVoteCountdownEvent:FireAllClients(t)
			task.wait(1)
		end
		if not gameStarted and currentVoteSession == mySession then
			local total = #game.Players:GetPlayers()
			local ready = 0
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if readyPlayers[plr.UserId] then ready += 1 end
			end
		if ready < total then
				-- Timeout - not enough players voted, do nothing (vote expired)
				StartVoteCanceledEvent:FireAllClients("Vote Timeout")
			end
		end
	end)
end)

-- Admin commands are now handled by AdminCommands.server.lua
