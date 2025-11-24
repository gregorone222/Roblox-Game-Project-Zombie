-- ZombieModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ZombieModule.lua
-- Script Place: ACT 1: Village

local ZombieModule = {}

local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local BindableEvents = ReplicatedStorage.BindableEvents
local ZombieVFX = ReplicatedStorage.ZombieVFX
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local ShooterVFXModule = require(ZombieVFX:WaitForChild("ShooterVFXModule"))
local Boss1VFXModule = require(ZombieVFX:WaitForChild("Boss1VFXModule"))
local Boss2VFXModule = require(ZombieVFX:WaitForChild("Boss2VFXModule"))
local Boss3VFXModule = require(ZombieVFX:WaitForChild("Boss3VFXModule"))
local Boss1TimeoutVFX = require(ZombieVFX:WaitForChild("Boss1TimeoutVFX"))
local ZombieConfig = require(ModuleScriptReplicatedStorage:WaitForChild("ZombieConfig"))
local SkillConfig = require(ModuleScriptReplicatedStorage:WaitForChild("SkillConfig"))
local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local ShieldModule = require(ModuleScriptServerScriptService:WaitForChild("ShieldModule"))
local SkillModule = require(ModuleScriptServerScriptService:WaitForChild("SkillModule"))
local MissionManager = require(ModuleScriptServerScriptService:WaitForChild("MissionManager"))
local GlobalMissionManager = require(ModuleScriptServerScriptService:WaitForChild("GlobeMissionManager"))

local BossTimerEvent = RemoteEvents:WaitForChild("BossTimerEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")

local ZombieDiedEvent = BindableEvents:WaitForChild("ZombieDiedEvent")

-- Helper function for a "hard wipe" mechanic used by bosses on timeout.
function ZombieModule.ExecuteHardWipe(zombie, humanoid)
	local bossPos = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p

	-- Make the boss immune and freeze them to signify the start of the wipe.
	zombie:SetAttribute("Immune", true)
	zombie:SetAttribute("MechanicFreeze", true) -- Prevent anti-stuck from interfering
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
	end
	zombie:SetAttribute("AttackRange", 0)

	-- Play a specific or generic timeout VFX.
	if zombie.Name == "Boss" then -- Perbaikan: Nama model yang benar adalah "Boss"
		Boss1TimeoutVFX.Play(zombie, bossPos) -- Mengirimkan model bos juga jika diperlukan
	else
		-- Fallback to Boss2's wipe VFX for any other boss for now.
		Boss2VFXModule.PlayWipeVFX(bossPos)
	end

	-- A short delay to let the VFX play out before the wipe.
	task.wait(3)

	-- Kill all players in the game.
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if h then
			h.Health = 0
		end
	end

	-- Stop the boss from moving permanently after the wipe.
	if humanoid then
		humanoid.WalkSpeed = 0
	end
end

function ZombieModule.SpawnZombie(spawnPoint, typeName, playerCount, difficulty, waveModifiers)
	waveModifiers = waveModifiers or {} -- Pastikan tidak nil
	difficulty = difficulty or "Easy"
	local diffSettings = GameConfig.Difficulty[difficulty] or GameConfig.Difficulty.Easy

	-- choose template:
	typeName = typeName or "Base"
	local templateName = "Zombie"
	if typeName and typeName ~= "Base" then
		-- expect models named Runner, Shooter, Tank, Boss in ServerStorage
		local candidate = ServerStorage.Zombies:FindFirstChild(typeName)
		if candidate then
			templateName = typeName
		end
	end

	local zombieTemplate = ServerStorage.Zombies:FindFirstChild(templateName) or ServerStorage:FindFirstChild("Zombie")
	if not zombieTemplate then return end

	local zombie = zombieTemplate:Clone()
	zombie.Parent = workspace
	if zombie.PrimaryPart == nil then
		-- try to set primary part
		local hrp = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
		if hrp then zombie.PrimaryPart = hrp end
	end

	local humanoid = zombie:FindFirstChild("Humanoid")
	-- apply base or type config
	local cfg = ZombieConfig.BaseZombie
	if typeName and ZombieConfig.Types[typeName] then
		cfg = ZombieConfig.Types[typeName]
	end

	if humanoid then
		humanoid.MaxHealth = (cfg.MaxHealth or humanoid.MaxHealth) * diffSettings.HealthMultiplier
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = cfg.WalkSpeed or humanoid.WalkSpeed

		-- Terapkan pengganda kecepatan jika ini adalah Gelombang Cepat
		if waveModifiers.isFast then
			humanoid.WalkSpeed = humanoid.WalkSpeed * GameConfig.FastWave.SpeedMultiplier
		end
	end

	zombie:SetAttribute("AttackRange", cfg.AttackRange or 4)
	zombie:SetAttribute("AttackDamage", (cfg.AttackDamage or ZombieConfig.BaseZombie.AttackDamage) * diffSettings.DamageMultiplier)

	local isZombieTag = Instance.new("BoolValue")
	isZombieTag.Name = "IsZombie"
	isZombieTag.Value = true
	isZombieTag.Parent = zombie

	if zombie.PrimaryPart then
		zombie:SetPrimaryPartCFrame(CFrame.new(spawnPoint.Position))
		-- FIX: Force server ownership to prevent jittery movement caused by client network lag
		zombie.PrimaryPart:SetNetworkOwner(nil)
	end

	-- Assign the zombie to its collision group
	local CollisionUtil = require(ServerScriptService.ModuleScript:WaitForChild("CollisionUtil"))
	CollisionUtil.SetGroupRecursive(zombie, CollisionUtil.ZOMBIE_GROUP)

	-- specific behaviours
	if typeName == "Runner" then
		-- faster chase handled by WalkSpeed; keep standard attack
	elseif typeName == "Shooter" then
		-- shooter will periodically spit projectiles at nearest player
		task.spawn(function()
			while zombie.Parent and humanoid and humanoid.Health > 0 do
				local target = ZombieModule.GetNearestPlayer(zombie)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					local from = (zombie.PrimaryPart and zombie.PrimaryPart.Position) or zombie:GetModelCFrame().p
					local to = target.Character.HumanoidRootPart.Position

					-- Line of Sight Check
					local raycastParams = RaycastParams.new()
					raycastParams.FilterDescendantsInstances = {zombie}
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					local origin = from + Vector3.new(0, 2.5, 0) -- Start ray from zombie's chest height
					local direction = (to - origin)
					local result = workspace:Raycast(origin, direction, raycastParams)

					local hasLineOfSight = false
					if result and result.Instance and result.Instance:IsDescendantOf(target.Character) then
						hasLineOfSight = true
					end

					if hasLineOfSight then
						ShooterVFXModule.ShootAcidProjectile(from + Vector3.new(0,2,0), to, (ZombieConfig.Types.Shooter.ProjectileSpeed or 80), zombie, ZombieConfig.Types.Shooter.Acid)
					end
				end
				task.wait(2 + math.random()) -- interval
			end
		end)
	end

	-- [[ REVISED ZOMBIE CHASE AND PATHFINDING LOOP ]]
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = true
		})

		-- Variables to track the current path and target's position
		local currentWaypoints = {}
		local currentWaypointIndex = 1
		local lastTargetPosition = Vector3.new()

		-- Cooldowns to manage behavior frequency
		local attackCooldown = (cfg and cfg.AttackCooldown) or ZombieConfig.BaseZombie.AttackCooldown or 1.5
		local lastAttackTime = 0

		-- Optimization: Throttling variables
		local lastLoSCheckTime = 0
		local losCheckInterval = 0.5

		while zombie.Parent and humanoid and humanoid.Health > 0 do
			-- OPTIMIZATION: Dynamic wait based on distance to player
			local updateRate = 0.1
			local target = ZombieModule.GetNearestPlayer(zombie)
			local currentPos = zombie.PrimaryPart.Position
			local targetPos = (target and target.Character and target.Character.PrimaryPart) and target.Character.PrimaryPart.Position

			if targetPos then
				local dist = (targetPos - currentPos).Magnitude
				if dist > 100 then
					updateRate = 0.5
				elseif dist > 40 then
					updateRate = 0.25
				end
			end

			task.wait(updateRate)

			-- Handle special states like being stunned or frozen by a mechanic
			if zombie:GetAttribute("MechanicFreeze") or zombie:GetAttribute("Stunned") then
				if humanoid.WalkSpeed > 0 then humanoid.WalkSpeed = 0 end
				continue -- Skip all logic below
			else
				-- Restore speed if it was zeroed out by a mechanic or an attack
				if humanoid.WalkSpeed == 0 and not zombie:GetAttribute("Attacking") then
					humanoid.WalkSpeed = cfg.WalkSpeed or 16
				end
			end

			if not target or not target.Character or not target.Character.PrimaryPart then
				continue -- No target, wait for the next cycle
			end

			local distanceToTarget = (targetPos - currentPos).Magnitude
			local attackRange = zombie:GetAttribute("AttackRange") or 4

			-- 1. ATTACK LOGIC: Highest priority. If in range, attack.
			if distanceToTarget <= attackRange then
				-- OPTIMIZATION: Throttled Line of Sight Check
				if tick() - lastLoSCheckTime > losCheckInterval then
					lastLoSCheckTime = tick()

					local raycastParams = RaycastParams.new()
					raycastParams.FilterDescendantsInstances = {zombie}
					raycastParams.FilterType = Enum.RaycastFilterType.Exclude
					local origin = currentPos + Vector3.new(0, 2.5, 0) -- Start ray from zombie's chest height
					local direction = (targetPos - origin)
					local result = workspace:Raycast(origin, direction, raycastParams)

					local hasLineOfSight = false
					if result and result.Instance and result.Instance:IsDescendantOf(target.Character) then
						hasLineOfSight = true
					end

					if hasLineOfSight then
						-- Clear any existing path since we've reached the target
						currentWaypoints = {}

						-- Check attack cooldown
						if tick() - lastAttackTime > attackCooldown then
							lastAttackTime = tick()
							zombie:SetAttribute("Attacking", true)
							humanoid.WalkSpeed = 0 -- Stop moving to attack

							-- Face the target for the attack
							zombie:SetPrimaryPartCFrame(CFrame.new(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)))

							-- Perform the attack damage in a separate thread
							task.spawn(function()
								local playerHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
								if playerHumanoid and not target.Character:FindFirstChild("Knocked") and not ElementModule.IsPlayerInvincible(target) then
									local damage = zombie:GetAttribute("AttackDamage")
									damage = ElementModule.ApplyDamageReduction(target, damage)
									local leftoverDamage = ShieldModule.Damage(target, damage)
									if leftoverDamage > 0 then
										playerHumanoid:TakeDamage(leftoverDamage)
									end
								end

								-- Brief delay after attacking before moving again
								task.wait(0.5) 
								zombie:SetAttribute("Attacking", false)
							end)
						end
						continue -- Do not proceed to movement logic this cycle
					end
				end
			end

			-- 2. MOVEMENT LOGIC: Diverge based on whether it's a boss
			if zombie:FindFirstChild("IsBoss") then
				-- BOSS MOVEMENT: Simple, direct chase.
				humanoid:MoveTo(targetPos)
			else
				-- NON-BOSS MOVEMENT: Use existing pathfinding.
				local needsNewPath = false
				-- Reason a) Target has moved a significant distance since last path calculation
				if (targetPos - lastTargetPosition).Magnitude > 10 then
					needsNewPath = true
					-- Reason b) We don't have a path, or we've reached the end of our current one
				elseif not currentWaypoints or currentWaypointIndex >= #currentWaypoints then
					needsNewPath = true
					-- Reason c) Check if we've arrived at the current waypoint to advance the index
				else
					local nextWaypointPos = currentWaypoints[currentWaypointIndex].Position
					if (Vector2.new(nextWaypointPos.X, nextWaypointPos.Z) - Vector2.new(currentPos.X, currentPos.Z)).Magnitude < 4 then
						-- We are close enough to the waypoint, so advance to the next one
						currentWaypointIndex += 1
					end
				end

				if needsNewPath then
					local success, err = pcall(function()
						path:ComputeAsync(currentPos, targetPos)
					end)

					if success and path.Status == Enum.PathStatus.Success and #path:GetWaypoints() > 1 then
						currentWaypoints = path:GetWaypoints()
						currentWaypointIndex = 2 -- Start with the second waypoint (first is current location)
						lastTargetPosition = targetPos -- Update last known target position
					else
						-- Path failed, clear old path and attempt to move directly as a fallback
						currentWaypoints = {}
						humanoid:MoveTo(targetPos)
						continue -- Skip to the next iteration
					end
				end

				-- 3. MOVEMENT EXECUTION: Follow the current path.
				if currentWaypoints and currentWaypoints[currentWaypointIndex] then
					local waypoint = currentWaypoints[currentWaypointIndex]
					humanoid:MoveTo(waypoint.Position)

					-- If the path requires a jump, make the humanoid jump
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
				else
					-- Fallback if something is wrong with the path
					humanoid:MoveTo(targetPos)
				end
			end
		end
	end)

	-- [[ DEATH & CLEANUP HANDLING ]]
	local isDead = false
	local function handleDeath(killedByPlayer)
		if isDead then return end
		isDead = true

		-- 1. Stop Boss Timer (Always)
		if zombie:FindFirstChild("IsBoss") then
			BossTimerEvent:FireAllClients(0, 0)
		end

		-- 2. Handle Volatile Minions (Separate Logic, NO Wave Progress)
		local volatileTag = zombie:FindFirstChild("VolatileMinion")
		if volatileTag and volatileTag.Value == "Boss1" then
			if killedByPlayer and zombie.PrimaryPart then
				local minionConfig = ZombieConfig.Types.Boss.VolatileMinions
				local explosionPos = zombie.PrimaryPart.Position

				Boss1VFXModule.CreateVolatileMinionExplosion(explosionPos, minionConfig)

				for _, player in ipairs(game.Players:GetPlayers()) do
					local char = player.Character
					if char and not ElementModule.IsPlayerInvincible(player) then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hum and hum.Health > 0 and hrp then
							if (hrp.Position - explosionPos).Magnitude <= minionConfig.ExplosionRadius then
								local damage = minionConfig.ExplosionDamage
								damage = ElementModule.ApplyDamageReduction(player, damage)
								local leftoverDamage = ShieldModule.Damage(player, damage)
								if leftoverDamage > 0 then
									hum:TakeDamage(leftoverDamage)
								end
							end
						end
					end
				end
			end
			if zombie.Parent then
				task.delay(0, function() zombie:Destroy() end)
			end
			return -- IMPORTANT: Minions do not trigger ZombieDiedEvent
		end

		-- 3. Cleanup Highlights
		local ch = zombie:FindFirstChild("ChamsHighlight")
		if ch then ch:Destroy() end

		-- 4. Handle Void/Despawn (Not Killed by Player)
		if not killedByPlayer then
			ZombieDiedEvent:Fire() -- Still counts for wave progress
			return
		end

		-- 5. Handle Legit Kill Rewards
		if zombie:FindFirstChild("IsBoss") then
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and not player.Character:FindFirstChild("Knocked") then
					PointsSystem.AddPoints(player, GameConfig.Wave.BossKillBonus)
				end
			end
		end

		ZombieDiedEvent:Fire() -- Progress wave

		-- Credit Killer
		local creatorTag = zombie:FindFirstChild("creator")
		if creatorTag and creatorTag.Value then
			local success, creatorData = pcall(HttpService.JSONDecode, HttpService, creatorTag.Value)
			if success and creatorData and creatorData.Player then
				local player = game.Players:GetPlayerByUserId(creatorData.Player)
				if player then
					if PointsSystem and PointsSystem.AddKill then PointsSystem.AddKill(player) end
					if StatsModule and StatsModule.AddKill then StatsModule.AddKill(player) end

					if StatsModule and StatsModule.AddWeaponKill and creatorData.WeaponType then
						StatsModule.AddWeaponKill(player, creatorData.WeaponType)
					end

					if MissionManager then
						local weaponType = creatorData.WeaponType
						local wasHeadshot = creatorData.IsHeadshot or false

						MissionManager:UpdateMissionProgress(player, { eventType = "KILL", amount = 1, weaponType = weaponType })
						GlobalMissionManager:IncrementProgress("KILL", 1, player)

						if wasHeadshot then
							MissionManager:UpdateMissionProgress(player, { eventType = "HEADSHOT", amount = 1, weaponType = weaponType })
							if StatsModule and StatsModule.IncrementStat then
								StatsModule.IncrementStat(player, "Headshots", 1)
							end
							GlobalMissionManager:IncrementProgress("HEADSHOT", 1, player)
						end
						if zombie:FindFirstChild("IsBoss") then
							MissionManager:UpdateMissionProgress(player, { eventType = "KILL_BOSS", amount = 1 })
							if StatsModule and StatsModule.IncrementStat then
								StatsModule.IncrementStat(player, "BossKills", 1)
							end
						end
					end

					if SkillConfig.GreedGash and not zombie:FindFirstChild("IsBoss") then
						local playerData = SkillModule.GetSkillData(player)
						local skillLevel = playerData.Skills.GreedGash or 0
						if skillLevel > 0 then
							local config = SkillConfig.GreedGash
							local chance = skillLevel * config.ChancePerLevel
							if math.random(1, 100) <= chance then
								PointsSystem.AddPoints(player, config.BonusAmount)
							end
						end
					end
				end
			end
		end

		-- 6. Final Cleanup
		task.wait(5)
		if zombie and zombie.Parent then zombie:Destroy() end
	end

	humanoid.Died:Connect(function() handleDeath(true) end)
	zombie.AncestryChanged:Connect(function(_, parent)
		if not parent then handleDeath(false) end
	end)

	return zombie
end

function ZombieModule.GetNearestPlayer(zombie)
	local closestPlayer = nil
	local closestDistance = math.huge
	local zombiePosition = zombie and zombie.PrimaryPart and zombie.PrimaryPart.Position

	if not zombiePosition then return nil end

	for _, player in pairs(game.Players:GetPlayers()) do
		local char = player.Character
		if char and not char:FindFirstChild("Knocked") then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (hrp.Position - zombiePosition).Magnitude
				if dist < closestDistance then
					closestDistance = dist
					closestPlayer = player
				end
			end
		end
	end
	return closestPlayer
end

return ZombieModule
