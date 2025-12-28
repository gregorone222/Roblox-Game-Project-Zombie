-- Boss3Module.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BossModule/Boss3Module.lua
-- Script Place: ACT 1: Village

local Boss3 = {}

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Boss3VFXModule = require(ReplicatedStorage.ZombieVFX:WaitForChild("Boss3VFXModule"))
local SyringeVolleyVFX = require(ReplicatedStorage.ZombieVFX:WaitForChild("SyringeVolleyVFX"))
local TacticalBoostModule = require(ServerScriptService.ModuleScript:WaitForChild("TacticalBoostModule"))
local ShieldModule = require(ServerScriptService.ModuleScript:WaitForChild("ShieldModule"))
local SpawnerModule -- Akan diinisialisasi melalui Init

local BossTimerEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BossTimerEvent")
local BossAlertEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BossIncoming")

-- Helper function to find a valid target
local function findTarget(bossModel)
	local furthestTarget = nil
	local maxDistance = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			local distance = (bossModel.PrimaryPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
			if distance > maxDistance then
				maxDistance = distance
				furthestTarget = player
			end
		end
	end
	return furthestTarget
end

-- Helper function to determine current phase based on health
local function getCurrentPhase(currentHealth, maxHealth)
	local healthPercent = (currentHealth / maxHealth) * 100
	if healthPercent >= 75 then
		return 1, "Volatile Formula" -- Phase 1: 100% to 75%
	elseif healthPercent >= 50 then
		return 2, "Debilitating Formula" -- Phase 2: 74% to 50%
	else
		return 3, "Terminal Formula" -- Phase 3: 49% to 0%
	end
end

function Boss3.Init(zombie, humanoid, config, executeHardWipe, spawnerModuleRef)
	SpawnerModule = spawnerModuleRef
	-- === INITIALIZATION ===
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Parent = zombie
	BossAlertEvent:FireAllClients(config.Name or "Boss")

	local maxHealth = humanoid.MaxHealth
	local currentPhase = 1
	local lastPhase = 1
	local attackCooldowns = {
		SyringeVolley = 0,
		UnstableVials = 0,
		CausticCatalyst = 0,
		SymbioticLink = 0,
		MutatedSpecimens = 0,
		PlagueBomb = 0,
	}
	local activeEchoes = {}
	local chainedPlayers = {}

	-- === TIMER & WIPE MECHANIC ===
	local bossStartTime = tick()
	local specialTimeout = config.SpecialTimeout or 300
	local bossName = config.Name or "Boss"
	BossTimerEvent:FireAllClients(specialTimeout, specialTimeout, bossName, "PHASE " .. currentPhase)
	local timerCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			local elapsed = tick() - bossStartTime
			local remaining = math.max(0, specialTimeout - elapsed)
			BossTimerEvent:FireAllClients(remaining, specialTimeout, bossName, "PHASE " .. currentPhase)
			if remaining <= 0 then
				executeHardWipe(zombie, humanoid)
				break
			end
			task.wait(1)
		end
	end)

	-- === PHASE MANAGER (Health-based) ===
	local phaseManagerCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			-- Check current phase based on health
			local newPhase, phaseName = getCurrentPhase(humanoid.Health, maxHealth)

			-- Phase transition detected
			if newPhase ~= lastPhase then
				currentPhase = newPhase
				print("Boss 3 Phase Transition: Phase " .. currentPhase .. " - " .. phaseName)

				-- Create phase transition VFX
				Boss3VFXModule.CreateMovementTransition(zombie, phaseName)

				-- Reset cooldowns for new phase
				for key, _ in pairs(attackCooldowns) do
					attackCooldowns[key] = 0
				end

				lastPhase = newPhase
			end

			task.wait(0.1) -- Check phase every 0.1 seconds
		end
	end)

	-- === ATTACK LOGIC (Phase-based) ===
	local attackCoroutine = task.spawn(function()
		while zombie.Parent and humanoid.Health > 0 do
			local now = tick()
			local target = findTarget(zombie)

			if target then
				humanoid:MoveTo(target.Character.HumanoidRootPart.Position)

				-- Execute attacks based on current phase
				if currentPhase == 1 then
					-- PHASE 1: Volatile Formula (Syringe Volley + Unstable Vials)
					local movementConfig = config.Movements.VolatileFormula

					if now > attackCooldowns.SyringeVolley then
						attackCooldowns.SyringeVolley = now + movementConfig.SyringeVolley.Cooldown
						local streamTarget = findTarget(zombie)
						if streamTarget then
							local volleyConfig = {
								ProjectileCount = movementConfig.SyringeVolley.ProjectileCount or 15,
								Interval = movementConfig.SyringeVolley.Interval or 0.05,
								ProjectileSpeed = movementConfig.SyringeVolley.ProjectileSpeed or 8,
								SpreadAngle = 0.3
							}
							-- [[ PERBAIKAN BUG ]]
							-- Kirim seluruh model 'zombie', bukan hanya 'zombie.PrimaryPart.Position'
							SyringeVolleyVFX.FireSyringeVolley(
								zombie,
								streamTarget.Character.HumanoidRootPart.Position,
								volleyConfig
							)
						end
					elseif now > attackCooldowns.UnstableVials then
						attackCooldowns.UnstableVials = now + movementConfig.UnstableVials.Cooldown
						task.spawn(function()
							local players = Players:GetPlayers()
							for i = 1, movementConfig.UnstableVials.PillarCount do
								if #players == 0 then break end
								local player = players[math.random(#players)]
								local char = player.Character
								if char then
									local pos = char.HumanoidRootPart.Position
									Boss3VFXModule.CreateUnstableVialsTelegraph(pos, movementConfig.UnstableVials)
								end
							end
							task.wait(movementConfig.UnstableVials.TelegraphDuration)
						end)
					end

				elseif currentPhase == 2 then
					-- PHASE 2: Debilitating Formula (Caustic Catalyst + Symbiotic Link)
					local movementConfig = config.Movements.DebilitatingFormula

					if now > attackCooldowns.CausticCatalyst then
						attackCooldowns.CausticCatalyst = now + movementConfig.CausticCatalyst.Cooldown
						local blastTarget = findTarget(zombie)
						if blastTarget then
							task.spawn(function()
								local targetPos = blastTarget.Character.HumanoidRootPart.Position
								Boss3VFXModule.CreateCausticCatalystTelegraph(targetPos, movementConfig.CausticCatalyst)
								task.wait(movementConfig.CausticCatalyst.TelegraphDuration)
								Boss3VFXModule.ExecuteCausticCatalyst(targetPos, movementConfig.CausticCatalyst)

								-- Damage logic for puddle
								local puddleEndTime = tick() + movementConfig.CausticCatalyst.PuddleDuration
								while tick() < puddleEndTime do
									for _, plr in ipairs(Players:GetPlayers()) do
										if plr.Character and (plr.Character.HumanoidRootPart.Position - targetPos).Magnitude < movementConfig.CausticCatalyst.BlastRadius then
											plr.Character.Humanoid:TakeDamage(movementConfig.CausticCatalyst.PuddleDamagePerTick)
										end
									end
									task.wait(movementConfig.CausticCatalyst.PuddleTickInterval)
								end
							end)
						end
					elseif now > attackCooldowns.SymbioticLink then
						attackCooldowns.SymbioticLink = now + movementConfig.SymbioticLink.Cooldown
						local players = Players:GetPlayers()
						if #players >= 2 then
							local p1 = players[math.random(#players)]
							local p2 = players[math.random(#players)]
							while p1 == p2 do p2 = players[math.random(#players)] end

							local chain = Boss3VFXModule.CreateSymbioticLink(p1, p2, movementConfig.SymbioticLink)
							table.insert(chainedPlayers, {p1, p2, chain, tick()})
						end
					end

				elseif currentPhase == 3 then
					-- PHASE 3: Terminal Formula (Plague Bomb + Mutated Specimens)
					local movementConfig = config.Movements.TerminalFormula

					if now > attackCooldowns.PlagueBomb then
						attackCooldowns.PlagueBomb = now + movementConfig.PlagueBomb.Cooldown
						humanoid:MoveTo(zombie.PrimaryPart.Position)
						task.spawn(function()
							local safePillar = Boss3VFXModule.CreatePlagueBombTelegraph(zombie, movementConfig.PlagueBomb)
							task.wait(movementConfig.PlagueBomb.ChargeDuration)
							Boss3VFXModule.ExecutePlagueBomb(zombie, safePillar, movementConfig.PlagueBomb)
							for _, plr in ipairs(Players:GetPlayers()) do
								if plr.Character then
									local hrp = plr.Character.HumanoidRootPart
									if hrp and safePillar and (hrp.Position - safePillar.Position).Magnitude > 20 then
										plr.Character.Humanoid:TakeDamage(movementConfig.PlagueBomb.Damage)
									end
								end
							end
						end)
					elseif now > attackCooldowns.MutatedSpecimens then
						attackCooldowns.MutatedSpecimens = now + movementConfig.MutatedSpecimens.Cooldown
						local echoCount = math.min(movementConfig.MutatedSpecimens.MaxEchoes, math.floor(#Players:GetPlayers() / 2))
						for i = 1, echoCount do
							local echo = SpawnerModule.SpawnEcho(zombie.PrimaryPart.Position, movementConfig.MutatedSpecimens)
							if echo then
								table.insert(activeEchoes, echo)
							end
						end
					end
				end

				-- Handle Symbiotic Link damage (from Phase 2)
				for i = #chainedPlayers, 1, -1 do
					local chainInfo = chainedPlayers[i]
					local p1, p2, chain, startTime = chainInfo[1], chainInfo[2], chainInfo[3], chainInfo[4]
					if not p1 or not p1.Parent or not p2 or not p2.Parent or (tick() - startTime) > config.Movements.DebilitatingFormula.SymbioticLink.Duration then
						if chain and chain.Parent then chain:Destroy() end
						table.remove(chainedPlayers, i)
					else
						if (p1.Character.HumanoidRootPart.Position - p2.Character.HumanoidRootPart.Position).Magnitude > config.Movements.DebilitatingFormula.SymbioticLink.MaxDistance then
							p1.Character.Humanoid:TakeDamage(config.Movements.DebilitatingFormula.SymbioticLink.DamagePerSecond)
							p2.Character.Humanoid:TakeDamage(config.Movements.DebilitatingFormula.SymbioticLink.DamagePerSecond)
						end
					end
				end
			end

			task.wait(0.5)
		end
	end)

	-- === CLEANUP ===
	humanoid.Died:Connect(function()
		BossTimerEvent:FireAllClients(0, 0, bossName, "DEFEATED")
		task.cancel(timerCoroutine)
		task.cancel(attackCoroutine)
		task.cancel(phaseManagerCoroutine)
		for _, echo in ipairs(activeEchoes) do 
			if echo and echo.Parent then 
				echo:Destroy() 
			end 
		end
	end)
end

return Boss3