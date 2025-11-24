-- SpawnerModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SpawnerModule.lua
-- Script Place: ACT 1: Village

local SpawnerModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local ZombieConfig = require(ModuleScriptReplicatedStorage.ZombieConfig)
local GameConfig = require(ServerScriptService.ModuleScript.GameConfig)

local ZombieModule = require(ModuleScriptServerScriptService:WaitForChild("ZombieModule"))
local BuildingManager = require(ModuleScriptServerScriptService:WaitForChild("BuildingModule"))

_G.bossSpawnTracker = _G.bossSpawnTracker or {}

local function resetBossWindowIfNeeded(currentWave)
	for bossName, bossConf in pairs(ZombieConfig.Types) do
		if string.find(bossName, "Boss") then
			local minW = bossConf.ChanceWaveMin or -1
			local maxW = bossConf.ChanceWaveMax or -1
			local windowKey = bossName .. "WindowSpawned"
			if currentWave < minW or currentWave > maxW then
				_G[windowKey] = false
			end
		end
	end
end

function SpawnerModule.IsBossWave(wave, gameMode, difficulty)
	if gameMode ~= "Story" then return false, nil end

	for bossName, bossConf in pairs(ZombieConfig.Types) do
		if string.find(bossName, "Boss") then
			if bossConf.GuaranteedSpawn and
				bossConf.GuaranteedSpawn.GameMode == gameMode and
				bossConf.GuaranteedSpawn.Wave == wave then
				return true, bossName
			end
			local windowKey = bossName .. "WindowSpawned"
			local isSpawned = _G[windowKey] or false
			if not isSpawned and
				wave >= (bossConf.ChanceWaveMin or -1) and
				wave <= (bossConf.ChanceWaveMax or -1) and
				math.random() < (bossConf.ChanceToSpawn or 0) then
				_G[windowKey] = true -- Tandai sebagai terpilih untuk spawn
				return true, bossName
			end
		end
	end
	return false, nil
end

function SpawnerModule.SpawnWave(amount, wave, playerCount, gameMode, difficulty, waveModifiers, forcedBossType)
	waveModifiers = waveModifiers or {}
	local spawners = workspace:FindFirstChild("Spawners")
	if not spawners then return false end

	local isBossWave = false
	local bossTypeToSpawn = nil

	if forcedBossType then
		isBossWave = true
		bossTypeToSpawn = forcedBossType
	else
		resetBossWindowIfNeeded(wave)
		isBossWave, bossTypeToSpawn = SpawnerModule.IsBossWave(wave, gameMode, difficulty)
	end

	if isBossWave then
		print("Boss wave detected! Hiding buildings.")
		BuildingManager.hideBuildings()
	end

	local bossHasBeenSpawned = false
	local zombiesSpawnedInBatch = 0
	local batchSize = math.floor(1 + (wave * 0.5)) -- Increase batch size with wave to prevent long spawn times

	for i = 1, amount do
		local spawnPoints = spawners:GetChildren()
		local randomSpawn = spawnPoints[math.random(1, #spawnPoints)]
		local chosenType = nil

		if isBossWave and not bossHasBeenSpawned then
			chosenType = bossTypeToSpawn
			bossHasBeenSpawned = true
		elseif waveModifiers.isSpecial then
			local allowedTypes = GameConfig.SpecialWave.AllowedTypes
			if allowedTypes and #allowedTypes > 0 then
				chosenType = allowedTypes[math.random(1, #allowedTypes)]
			end
		else
			if wave and wave >= 3 and math.random() < (ZombieConfig.Types.Runner.Chance or 0.30) then
				chosenType = "Runner"
			elseif wave and wave >= 6 and math.random() < (ZombieConfig.Types.Shooter.Chance or 0.25) then
				chosenType = "Shooter"
			elseif wave and wave >= 9 and math.random() < (ZombieConfig.Types.Tank.Chance or 0.10) then
				chosenType = "Tank"
			end
		end

		local zombie = ZombieModule.SpawnZombie(randomSpawn, chosenType, playerCount, difficulty, waveModifiers)

		if zombie and chosenType and string.find(chosenType, "Boss") then
			local humanoid = zombie:FindFirstChildOfClass("Humanoid")
			local cfg = ZombieConfig.Types[chosenType]
			if humanoid and cfg then
				if chosenType == "Boss" then
					local Boss1 = require(ModuleScriptServerScriptService.BossModule:WaitForChild("Boss1Module"))
					Boss1.Init(zombie, humanoid, cfg, ZombieModule.ExecuteHardWipe, SpawnerModule)
				elseif chosenType == "Boss2" then
					local Boss2 = require(ModuleScriptServerScriptService.BossModule:WaitForChild("Boss2Module"))
					Boss2.Init(zombie, humanoid, cfg, ZombieModule.ExecuteHardWipe)
				elseif chosenType == "Boss3" then
					local Boss3 = require(ModuleScriptServerScriptService.BossModule:WaitForChild("Boss3Module"))
					Boss3.Init(zombie, humanoid, cfg, ZombieModule.ExecuteHardWipe, SpawnerModule)
				end
			end
		end

		zombiesSpawnedInBatch += 1
		if zombiesSpawnedInBatch >= batchSize then
			zombiesSpawnedInBatch = 0
			task.wait(1)
		end
	end
	return isBossWave
end

function SpawnerModule.SpawnVolatileMinion(spawnPosition, minionConfig)
	local fakeSpawn = { Position = spawnPosition, CFrame = CFrame.new(spawnPosition) }
	local zombie = ZombieModule.SpawnZombie(fakeSpawn, minionConfig.MinionType, 1, "Easy", {isMinion = true})
	if zombie then
		local volatileTag = Instance.new("StringValue")
		volatileTag.Name = "VolatileMinion"
		volatileTag.Value = "Boss1"
		volatileTag.Parent = zombie
	end
end

function SpawnerModule.SpawnEcho(bossPosition, echoConfig)
	local spawners = workspace:FindFirstChild("Spawners")
	if not spawners then return end
	local spawnPoint = nil
	local attempts = 0
	while not spawnPoint and attempts < 15 do
		local potentialSpawners = spawners:GetChildren()
		local randomSpawn = potentialSpawners[math.random(1, #potentialSpawners)]
		if (randomSpawn.Position - bossPosition).Magnitude > 15 then
			spawnPoint = randomSpawn
		end
		attempts += 1
	end
	if not spawnPoint then
		local potentialSpawners = spawners:GetChildren()
		spawnPoint = potentialSpawners[math.random(1, #potentialSpawners)]
	end
	local echo = ZombieModule.SpawnZombie(spawnPoint, "Boss3", 1, "Easy", {isEcho = true})
	if echo then
		local humanoid = echo:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.MaxHealth = echoConfig.EchoHealth
			humanoid.Health = echoConfig.EchoHealth
		end
		for _, part in ipairs(echo:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.7
				part.Color = Color3.fromRGB(150, 100, 255)
			end
		end
	end
	return echo
end

return SpawnerModule
