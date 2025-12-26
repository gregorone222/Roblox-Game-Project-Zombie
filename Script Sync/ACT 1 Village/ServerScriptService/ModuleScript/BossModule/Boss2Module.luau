-- Boss2Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss2Module.lua
-- Script Place: ACT 1: Village
-- Boss: The Hive Mother (Insectoid/Summoner)

local Boss2 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Modules
local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
-- Note: We avoid requiring SpawnerModule at the top level to prevent cyclic dependency (Spawner -> Boss2 -> Spawner)
local ZombieModule = require(ServerScriptService.ModuleScript:WaitForChild("ZombieModule"))

-- Remote Events
local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")
local BossAlertEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossIncoming")
local HardWipeVFXEvent = ReplicatedStorage.RemoteEvents:WaitForChild("HardWipeVFXEvent")
local PlayBossSkillEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("PlayBossSkillEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
PlayBossSkillEvent.Name = "PlayBossSkillEvent"

function Boss2.Init(zombie, humanoid, config, executeHardWipe)
	print("Boss2 (Hive Mother) Initialized")
	local Lighting = game:GetService("Lighting")

	local bossTag = Instance.new("BoolValue", zombie)
	bossTag.Name = "IsBoss"
	BossAlertEvent:FireAllClients(config.Name or "The Hive Mother")

	-- State
	local currentState = "Phase1"
	local transitioning = false
	local attackCooldowns = {
		AcidSpit = 0,
		SpawnLarva = 0,
		ToxicCloud = 0,
		BroodFrenzy = 0
	}

	-- Helper: Find valid player targets
	local function getTargets()
		local targets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
				table.insert(targets, p)
			end
		end
		return targets
	end

	-- Timer Logic (Hard Wipe)
	local bossStartTime = tick()
	local specialTimeout = config.SpecialTimeout or 300
	local bossName = config.Name or "The Hive Mother"

	local timerCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			local elapsed = tick() - bossStartTime
			local remaining = math.max(0, specialTimeout - elapsed)
			BossTimerEvent:FireAllClients(remaining, specialTimeout, bossName, currentState)

			if remaining <= 0 then
				HardWipeVFXEvent:FireAllClients(zombie.PrimaryPart.Position)
				task.wait(3.0)
				executeHardWipe(zombie, humanoid)
				break
			end
			task.wait(1)
		end
	end)

	-- Phase Transition Handler
	humanoid.HealthChanged:Connect(function(health)
		if transitioning or currentState ~= "Phase1" then return end

		if health / humanoid.MaxHealth <= 0.5 then
			transitioning = true
			currentState = "Transition"
			humanoid.WalkSpeed = 0
			zombie:SetAttribute("Immune", true)

			-- Play Animation/VFX
			PlayBossSkillEvent:FireAllClients("Metamorphosis", {BossModel = zombie})

			-- Heal slightly
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (config.Metamorphosis.HealAmount or 5000))

			task.wait(config.Metamorphosis.Duration or 5)

			zombie:SetAttribute("Immune", false)
			humanoid.WalkSpeed = config.WalkSpeed or 6
			currentState = "Phase2"
			transitioning = false
			print("Hive Mother entered Phase 2")
		end
	end)

	-- AI Loop
	local attackCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			if transitioning then task.wait(1); continue end

			local now = tick()
			local targets = getTargets()
			local target = targets[math.random(#targets)]

			if target then
				-- Move towards target
				humanoid:MoveTo(target.Character.HumanoidRootPart.Position)

				-- SKILL 1: Acid Spit (Ranged)
				if now > attackCooldowns.AcidSpit then
					attackCooldowns.AcidSpit = now + config.AcidSpit.Cooldown

					-- Visuals
					local origin = zombie.PrimaryPart.Position + Vector3.new(0,5,0)
					local targetPos = target.Character.HumanoidRootPart.Position
					PlayBossSkillEvent:FireAllClients("AcidSpit", {Origin = origin, TargetPos = targetPos})

					task.wait(0.5) -- Travel time approx

					-- Damage Logic
					for _, p in ipairs(getTargets()) do
						local dist = (p.Character.HumanoidRootPart.Position - targetPos).Magnitude
						if dist <= config.AcidSpit.AoE_Radius then
							p.Character.Humanoid:TakeDamage(config.AcidSpit.Damage)
						end
					end
				end

				-- SKILL 2: Spawn Larva (Summon)
				if now > attackCooldowns.SpawnLarva then
					attackCooldowns.SpawnLarva = now + config.SpawnLarva.Cooldown

					local count = math.random(config.SpawnLarva.Count[1], config.SpawnLarva.Count[2])
					local spawnPoints = {}

					for i=1, count do
						local offset = Vector3.new(math.random(-10,10), 0, math.random(-10,10))
						local pos = zombie.PrimaryPart.Position + offset
						table.insert(spawnPoints, pos)

						-- Actual Spawn (Using ZombieModule directly to avoid SpawnerModule cycle)
						task.delay(1, function()
							local fakeSpawn = { Position = pos, CFrame = CFrame.new(pos) }
							local zombie = ZombieModule.SpawnZombie(fakeSpawn, config.SpawnLarva.MinionType, 1, "Easy", {isMinion = true})
							if zombie then
								-- Tag minion so it can be handled if needed
								local tag = Instance.new("StringValue")
								tag.Name = "VolatileMinion" -- Reuse tag for consistency
								tag.Value = "Boss2"
								tag.Parent = zombie
							end
						end)
					end

					PlayBossSkillEvent:FireAllClients("SpawnLarva", {SpawnPoints = spawnPoints})
				end

				-- PHASE 2 SKILLS
				if currentState == "Phase2" then

					-- SKILL 3: Toxic Cloud (Area Denial)
					if now > attackCooldowns.ToxicCloud then
						attackCooldowns.ToxicCloud = now + config.ToxicCloud.Cooldown

						local cloudPos = zombie.PrimaryPart.Position
						PlayBossSkillEvent:FireAllClients("ToxicCloud", {
							Origin = cloudPos, 
							Radius = config.ToxicCloud.Radius, 
							Duration = config.ToxicCloud.Duration
						})

						-- DoT Logic
						task.spawn(function()
							local elapsed = 0
							while elapsed < config.ToxicCloud.Duration do
								for _, p in ipairs(getTargets()) do
									if (p.Character.HumanoidRootPart.Position - cloudPos).Magnitude <= config.ToxicCloud.Radius then
										p.Character.Humanoid:TakeDamage(config.ToxicCloud.DamagePerSecond)
									end
								end
								task.wait(1)
								elapsed += 1
							end
						end)
					end
				end
			end

			task.wait(1) -- AI Tick
		end
	end)

	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0, bossName, "DEFEATED")
		task.cancel(timerCoroutine)
		task.cancel(attackCoroutine)
	end)
end

return Boss2
