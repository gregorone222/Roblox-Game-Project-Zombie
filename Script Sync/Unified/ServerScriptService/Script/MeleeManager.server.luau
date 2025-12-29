-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- MeleeManager.server.luau (Script)
-- Path: ServerScriptService/Script/MeleeManager.server.luau
-- Purpose: Handle melee weapon attacks, hitbox detection, damage, and stamina

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Modules
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local Constants = require(ModuleScriptServerScriptService:WaitForChild("Constants"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("ValorModule"))

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MeleeAttackEvent = RemoteEvents:FindFirstChild("MeleeAttackEvent")
if not MeleeAttackEvent then
	MeleeAttackEvent = Instance.new("RemoteEvent")
	MeleeAttackEvent.Name = "MeleeAttackEvent"
	MeleeAttackEvent.Parent = RemoteEvents
end

local HitmarkerEvent = RemoteEvents:WaitForChild("HitmarkerEvent")

local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")
local ReportDamageEvent = BindableEvents:FindFirstChild("ReportDamage")

-- Anti-spam tracking
local lastAttackTime = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

local function isMeleeWeapon(tool)
	if not tool or not tool:IsA("Tool") then return false end
	local weaponData = WeaponModule.Weapons[tool.Name]
	return weaponData and weaponData.IsMelee == true
end

local function getCharacterFromHit(hitPart)
	local model = hitPart:FindFirstAncestorOfClass("Model")
	if model then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return model, humanoid
		end
	end
	return nil, nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MELEE ATTACK HANDLER
-- ═══════════════════════════════════════════════════════════════════════════════

MeleeAttackEvent.OnServerEvent:Connect(function(player, tool, attackDirection)
	-- Validation
	if not player or not player.Character then return end
	if not tool or not isMeleeWeapon(tool) then return end
	
	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	-- Check if player is knocked
	if character:FindFirstChild(Constants.Attributes.KNOCKED) then return end
	
	local weaponData = WeaponModule.Weapons[tool.Name]
	if not weaponData then return end
	
	-- Anti-spam check
	local now = tick()
	local attackSpeed = weaponData.AttackSpeed or 0.8
	if lastAttackTime[player] and (now - lastAttackTime[player]) < attackSpeed * 0.8 then
		return -- Too fast, ignore
	end
	lastAttackTime[player] = now
	
	-- ═══════════════════════════════════════════════════════════════
	-- STAMINA COST (using SprintManager's stamina system)
	-- ═══════════════════════════════════════════════════════════════
	local staminaCost = weaponData.StaminaCost or 5
	
	-- Get stamina from SprintManager via BindableFunction
	local GetStaminaFunction = BindableEvents:FindFirstChild("GetStamina")
	local DeductStaminaEvent = BindableEvents:FindFirstChild("DeductStamina")
	
	if GetStaminaFunction and DeductStaminaEvent then
		local currentStamina = GetStaminaFunction:Invoke(player)
		
		if currentStamina < staminaCost then
			return -- Not enough stamina
		end
		
		-- Deduct stamina via BindableEvent
		DeductStaminaEvent:Fire(player, staminaCost)
	else
		warn("[MeleeManager] Stamina API not found - SprintManager may not be loaded yet")
	end
	
	-- ═══════════════════════════════════════════════════════════════
	-- HITBOX DETECTION
	-- ═══════════════════════════════════════════════════════════════
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local range = weaponData.Range or 5
	local damage = weaponData.Damage or 30
	local headshotMultiplier = weaponData.HeadshotMultiplier or 1.5
	
	-- Create a sphere overlap for hit detection
	local hitPosition = rootPart.Position + attackDirection * (range / 2)
	local hitRadius = range / 2
	
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = {character}
	
	local hitParts = workspace:GetPartBoundsInRadius(hitPosition, hitRadius, overlapParams)
	
	local hitTargets = {} -- Track what we've hit to avoid double damage
	local hitSomething = false
	
	for _, part in ipairs(hitParts) do
		local model, targetHumanoid = getCharacterFromHit(part)
		if model and targetHumanoid and not hitTargets[model] then
			hitTargets[model] = true
			
			local isZombie = model:FindFirstChild(Constants.Attributes.IS_ZOMBIE)
			local targetPlayer = Players:GetPlayerFromCharacter(model)
			
			-- Only damage zombies (no friendly fire)
			if isZombie then
				-- Check if headshot
				local isHeadshot = part.Name == "Head"
				local finalDamage = damage
				
				if isHeadshot then
					finalDamage = damage * headshotMultiplier
				end
				
				-- Apply damage reduction if any
				local dr = model:GetAttribute("DamageReductionPct") or 0
				finalDamage = finalDamage * (1 - math.clamp(dr, 0, 0.95))
				
				-- Apply damage
				targetHumanoid:TakeDamage(finalDamage)
				
				-- Track stats
				if ReportDamageEvent then
					ReportDamageEvent:Fire(player, finalDamage)
				end
				StatsModule.AddTotalDamage(player, finalDamage)
				StatsModule.AddWeaponDamage(player, tool.Name, finalDamage)
				
				-- Add valor points (10 per hit, 20 for headshot)
				local valorPoints = isHeadshot and 20 or 10
				PointsSystem.AddPoints(player, valorPoints)
				
				-- Set creator tag for kill credit
				local creatorTag = model:FindFirstChild("creator")
				if not creatorTag then
					creatorTag = Instance.new("StringValue")
					creatorTag.Name = "creator"
					creatorTag.Parent = model
				end
				local HttpService = game:GetService("HttpService")
				local creatorData = {
					Player = player.UserId,
					WeaponType = weaponData.DisplayName or tool.Name,
					IsHeadshot = isHeadshot
				}
				creatorTag.Value = HttpService:JSONEncode(creatorData)
				
				-- Send hitmarker to client
				HitmarkerEvent:FireClient(player, isHeadshot)
				
				hitSomething = true
				
				-- Play hit sound
				if weaponData.Sounds and weaponData.Sounds.Hit then
					-- Play 3D sound at hit position
					local soundPart = Instance.new("Part")
					soundPart.Size = Vector3.new(1, 1, 1)
					soundPart.Position = part.Position
					soundPart.Anchored = true
					soundPart.CanCollide = false
					soundPart.Transparency = 1
					soundPart.Parent = workspace
					
					-- Create and play sound
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://0" -- TODO: Get actual sound ID from AudioManager
					sound.Volume = 0.5
					sound.RollOffMaxDistance = 50
					sound.Parent = soundPart
					sound:Play()
					
					game.Debris:AddItem(soundPart, 1)
				end
			end
		end
	end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
	lastAttackTime[player] = nil
end)

print("[MeleeManager] Initialized")
