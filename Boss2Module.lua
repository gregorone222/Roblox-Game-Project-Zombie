-- Boss2Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss2Module.lua
-- Script Place: ACT 1: Village

local Boss2 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Memanggil modul VFX
local OrbOfAnnihilationVFX = require(ServerScriptService.ModuleScript:WaitForChild("OrbOfAnnihilationVFX"))
local Boss2PhaseTransitionVFX = require(ServerScriptService.ModuleScript:WaitForChild("Boss2PhaseTransitionVFX"))
local CurseOfBanishmentVFX = require(ServerScriptService.ModuleScript:WaitForChild("CurseOfBanishmentVFX"))
local VoidMeteorVFX = require(ServerScriptService.ModuleScript:WaitForChild("VoidMeteorVFX"))
local Boss2VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss2VFXModule"))
local ElementModule = require(ServerScriptService.ModuleScript:WaitForChild("ElementConfigModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))

-- Remote Events
local BossTimerEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossTimerEvent")
local BossAlertEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BossIncoming")
local HardWipeVFXEvent = ReplicatedStorage.RemoteEvents:WaitForChild("HardWipeVFXEvent")

-- Fungsi LOKAL untuk membuat orb timer
local function createTimerOrb(centerPosition, duration)
	local orbModel = Instance.new("Model")
	orbModel.Name = "SingularityCore"

	local mainPart = Instance.new("Part")
	mainPart.Name = "MainPart"
	mainPart.Anchored = true
	mainPart.CanCollide = false
	mainPart.Transparency = 1
	mainPart.Parent = orbModel
	orbModel.PrimaryPart = mainPart

	local innerCore = Instance.new("Part")
	innerCore.Name = "InnerCore"
	innerCore.Shape = Enum.PartType.Ball
	innerCore.Material = Enum.Material.Basalt
	innerCore.Color = Color3.fromRGB(0, 0, 0)
	innerCore.Anchored = true
	innerCore.CanCollide = false
	innerCore.Size = Vector3.new(0.5, 0.5, 0.5)
	innerCore.Parent = orbModel

	local beamAttachment = Instance.new("Attachment", innerCore)
	beamAttachment.Name = "BeamTarget"

	local weld1 = Instance.new("WeldConstraint", mainPart)
	weld1.Part0 = mainPart
	weld1.Part1 = innerCore

	local outerShell = Instance.new("Part")
	outerShell.Name = "OuterShell"
	outerShell.Shape = Enum.PartType.Ball
	outerShell.Material = Enum.Material.ForceField
	outerShell.Color = Color3.fromRGB(80, 0, 120)
	outerShell.Anchored = true
	outerShell.CanCollide = false
	outerShell.Size = Vector3.new(1, 1, 1)
	outerShell.Transparency = 0.8
	outerShell.Parent = orbModel

	local weld2 = Instance.new("WeldConstraint", mainPart)
	weld2.Part0 = mainPart
	weld2.Part1 = outerShell

	local particleEmitterPart = Instance.new("Part")
	particleEmitterPart.Name = "EmitterPart"
	particleEmitterPart.Anchored = true
	particleEmitterPart.CanCollide = false
	particleEmitterPart.Transparency = 1
	particleEmitterPart.Parent = orbModel

	local weld3 = Instance.new("WeldConstraint", mainPart)
	weld3.Part0 = mainPart
	weld3.Part1 = particleEmitterPart

	local particles = Instance.new("ParticleEmitter", particleEmitterPart)
	particles.Color = ColorSequence.new(Color3.fromRGB(150, 50, 200))
	particles.LightEmission = 0.5
	particles.Transparency = NumberSequence.new(0.6, 1)
	particles.Size = NumberSequence.new(1, 0)
	particles.Lifetime = NumberRange.new(1, 1.5)
	particles.Rate = 50
	particles.Speed = NumberRange.new(0, 0)
	particles.Acceleration = Vector3.new(0, 0, 15)

	orbModel:PivotTo(CFrame.new(centerPosition))
	orbModel.Parent = Workspace

	local rotationConnection
	rotationConnection = RunService.Heartbeat:Connect(function(dt)
		if not particleEmitterPart or not particleEmitterPart.Parent then
			rotationConnection:Disconnect()
			return
		end
		particleEmitterPart.CFrame = particleEmitterPart.CFrame * CFrame.Angles(dt * 2, dt * 3, dt * 1.5)
	end)

	local finalSize = 50
	local growthTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	TweenService:Create(outerShell, growthTweenInfo, {Size = Vector3.new(finalSize, finalSize, finalSize)}):Play()
	TweenService:Create(innerCore, growthTweenInfo, {Size = Vector3.new(finalSize * 0.4, finalSize * 0.4, finalSize * 0.4)}):Play()

	return orbModel
end

function Boss2.Init(zombie, humanoid, config, executeHardWipe)
	local Lighting = game:GetService("Lighting")
	local originalAmbient = Lighting.Ambient
	local originalOutdoorAmbient = Lighting.OutdoorAmbient
	local originalBrightness = Lighting.Brightness

	local centerArenaPart = Workspace:FindFirstChild("CenterArena")
	local arenaCenterPoint
	if centerArenaPart then
		arenaCenterPoint = centerArenaPart.Position
	else
		warn("Boss2 WARNING: 'CenterArena' part not found in Workspace. Using boss spawn position as fallback.")
		arenaCenterPoint = zombie.PrimaryPart.Position
	end

	local bossTag = Instance.new("BoolValue", zombie)
	bossTag.Name = "IsBoss"
	BossAlertEvent:FireAllClients(config.Name or "Boss")

	local currentState = "Phase1"
	local transitioning = false
	local attackCooldowns = {
		OrbOfAnnihilation = 0,
		CurseOfBanishment = 0,
		DualOrbSummon = 0,
		VoidMeteorShower = 0,
	}
	local arenaPlatforms = {}
	local pillarOrbs = {}

	local function cleanupPhase2Assets()
		for _, orb in ipairs(pillarOrbs) do if orb and orb.Parent then orb:Destroy() end end
		pillarOrbs = {}
		for _, platform in ipairs(arenaPlatforms) do
			Boss2VFXModule.DestroyPillar(platform)
			task.wait(math.random() * 0.3)
		end
		arenaPlatforms = {}
	end

	local bossStartTime = tick()
	local specialTimeout = config.SpecialTimeout or 300
	local bossName = config.Name or "Boss"
	local function getPhaseName()
		if currentState == "Phase1" then
			return "PHASE 1"
		elseif currentState == "Phase2" then
			return "PHASE 2"
		else
			return "TRANSITION"
		end
	end
	BossTimerEvent:FireAllClients(specialTimeout, specialTimeout, bossName, getPhaseName())

	local timeoutOrb = createTimerOrb(arenaCenterPoint + Vector3.new(0, 90, 0), specialTimeout)

	local timerCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			local elapsed = tick() - bossStartTime
			local remaining = math.max(0, specialTimeout - elapsed)
			BossTimerEvent:FireAllClients(remaining, specialTimeout, bossName, getPhaseName())
			if remaining <= 0 then
				local wipeOrigin = arenaCenterPoint
				if timeoutOrb and timeoutOrb.PrimaryPart then
					wipeOrigin = timeoutOrb.PrimaryPart.Position
				end

				HardWipeVFXEvent:FireAllClients(wipeOrigin)

				task.wait(3.0)

				if currentState == "Phase2" then
					cleanupPhase2Assets()
				end
				executeHardWipe(zombie, humanoid)

				break
			end
			task.wait(1)
		end
	end)

	local function findTarget()
		local furthestTarget = nil
		local maxDistance = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
				local distance = (zombie.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
				if distance > maxDistance then
					maxDistance = distance
					furthestTarget = player
				end
			end
		end
		return furthestTarget
	end

	local function onOrbExplode(explosionPosition)
		local orbConfig = config.OrbOfAnnihilation
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and not ElementModule.IsPlayerInvincible(player) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hum and hum.Health > 0 and hrp and (hrp.Position - explosionPosition).Magnitude <= orbConfig.ExplosionRadius then
					local damage = ElementModule.ApplyDamageReduction(player, orbConfig.ExplosionDamage)
					local leftoverDamage = ShieldModule.Damage(player, damage)
					if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
				end
			end
		end
	end

	local function spawnOrb(targetPlayer)
		local orb = OrbOfAnnihilationVFX.create(config.OrbOfAnnihilation)
		if zombie:FindFirstChild("Head") then
			orb.CFrame = zombie.Head.CFrame * CFrame.new(0, 0, -8)
		else
			orb.CFrame = zombie.PrimaryPart.CFrame * CFrame.new(0, 5, -10)
		end
		OrbOfAnnihilationVFX.launch(orb, targetPlayer.Character, config.OrbOfAnnihilation, onOrbExplode)
	end

	humanoid.HealthChanged:Connect(function(health)
		if transitioning or currentState ~= "Phase1" then return end

		if health / humanoid.MaxHealth <= config.Upheaval.TriggerHPPercent then
			transitioning = true
			currentState = "Transition"
			humanoid.WalkSpeed = 0
			zombie:SetAttribute("Immune", true)

			local hrp = zombie:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Anchored = true end
			task.wait(3)
			if hrp then hrp.Anchored = false end

			local upheavalResult = Boss2PhaseTransitionVFX.CreateUpheaval(arenaCenterPoint, config.Upheaval, timeoutOrb)
			arenaPlatforms = upheavalResult.platforms
			pillarOrbs = upheavalResult.pillarOrbs

			task.wait(config.Upheaval.Duration)

			zombie:SetAttribute("Immune", false)

			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local goals = { Ambient = Color3.fromRGB(80, 0, 120), OutdoorAmbient = Color3.fromRGB(40, 0, 60), Brightness = 0.5 }
			TweenService:Create(Lighting, tweenInfo, goals):Play()

			humanoid.WalkSpeed = config.WalkSpeed
			currentState = "Phase2"
			transitioning = false
		end
	end)

	local isAttacking = false
	local attackCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			if transitioning or isAttacking then task.wait(0.5); continue end

			local now = tick()
			local target = findTarget()
			if not target then task.wait(1); continue end

			isAttacking = true

			local success, err = pcall(function()
				if currentState == "Phase1" then
					humanoid:MoveTo(target.Character.HumanoidRootPart.Position)
					if now > attackCooldowns.OrbOfAnnihilation then
						attackCooldowns.OrbOfAnnihilation = now + config.OrbOfAnnihilation.Cooldown
						local orbTarget = findTarget()
						if orbTarget then spawnOrb(orbTarget) end
					end
				elseif currentState == "Phase2" then
					local attackOrder = {"CurseOfBanishment", "DualOrbSummon", "VoidMeteorShower"}
					for i = #attackOrder, 1, -1 do
						local j = math.random(i)
						attackOrder[i], attackOrder[j] = attackOrder[j], attackOrder[i]
					end

					local attackExecuted = false
					for _, attackName in ipairs(attackOrder) do
						if now > attackCooldowns[attackName] then
							attackCooldowns[attackName] = now + config[attackName].Cooldown

							if attackName == "CurseOfBanishment" then
								local allPlayers = Players:GetPlayers()
								local validTargets = {}
								for _, p in ipairs(allPlayers) do
									if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
										table.insert(validTargets, p)
									end
								end
								if #validTargets > 0 then
									local cursedPlayer = validTargets[math.random(#validTargets)]
									CurseOfBanishmentVFX.apply(cursedPlayer.Character, config.CurseOfBanishment)
									local curseConfig = config.CurseOfBanishment
									local startTime = tick()
									task.spawn(function()
										while tick() - startTime < curseConfig.Duration do
											if not cursedPlayer.Parent or not cursedPlayer.Character or cursedPlayer.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then break end
											local cursedPos = cursedPlayer.Character.HumanoidRootPart.Position
											for _, player in ipairs(allPlayers) do
												if player ~= cursedPlayer and player.Character and not ElementModule.IsPlayerInvincible(player) then
													local hum = player.Character:FindFirstChildOfClass("Humanoid")
													local hrp = player.Character:FindFirstChild("HumanoidRootPart")
													if hum and hum.Health > 0 and hrp and (hrp.Position - cursedPos).Magnitude <= curseConfig.Radius then
														local damage = ElementModule.ApplyDamageReduction(player, curseConfig.DamagePerTick)
														local leftoverDamage = ShieldModule.Damage(player, damage)
														if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
													end
												end
											end
											task.wait(curseConfig.TickInterval)
										end
									end)
								end
							elseif attackName == "DualOrbSummon" then
								local targets = Players:GetPlayers()
								if #targets > 0 then spawnOrb(targets[math.random(#targets)]) end
								if #targets > 1 then spawnOrb(targets[math.random(#targets)]) end
							elseif attackName == "VoidMeteorShower" then
								humanoid:MoveTo(zombie.PrimaryPart.Position)
								local meteorConfig = config.VoidMeteorShower
								local targetPositions = {}
								local validPlayers = {}
								for _, p in ipairs(Players:GetPlayers()) do
									if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
										table.insert(validPlayers, p)
									end
								end

								if #validPlayers > 0 then
									for _, player in ipairs(validPlayers) do
										local targetPos = player.Character.HumanoidRootPart.Position
										table.insert(targetPositions, targetPos)
										VoidMeteorVFX.createTelegraph(targetPos, meteorConfig)
									end

									task.wait(meteorConfig.TelegraphDuration)

									for _, pos in ipairs(targetPositions) do
										VoidMeteorVFX.launchMeteor(pos, meteorConfig)
										task.wait(1.3)
										for _, player in ipairs(Players:GetPlayers()) do
											local char = player.Character
											if char and not ElementModule.IsPlayerInvincible(player) then
												local hum = char:FindFirstChildOfClass("Humanoid")
												local hrp = char:FindFirstChild("HumanoidRootPart")
												if hum and hum.Health > 0 and hrp and (hrp.Position - pos).Magnitude <= meteorConfig.BlastRadius then
													local damage = ElementModule.ApplyDamageReduction(player, meteorConfig.BlastDamage)
													local leftoverDamage = ShieldModule.Damage(player, damage)
													if leftoverDamage > 0 then hum:TakeDamage(leftoverDamage) end
												end
											end
										end
									end
								end
							end

							attackExecuted = true
							break
						end
					end

					if not attackExecuted then
						humanoid:MoveTo(target.Character.HumanoidRootPart.Position)
					end
				end
			end)

			if not success then
				warn("Boss2 Attack Coroutine Error: ", err)
			end

			isAttacking = false
			task.wait(0.5)
		end
	end)

	humanoid.Died:Connect(function()
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local goals = { Ambient = originalAmbient, OutdoorAmbient = originalOutdoorAmbient, Brightness = originalBrightness }
		TweenService:Create(Lighting, tweenInfo, goals):Play()
		BossTimerEvent:FireAllClients(0, 0, bossName, "DEFEATED")

		if timeoutOrb and timeoutOrb.Parent then timeoutOrb:Destroy() end

		if currentState == "Phase2" then
			cleanupPhase2Assets()
		end
		task.cancel(timerCoroutine)
		task.cancel(attackCoroutine)
	end)
end

return Boss2
