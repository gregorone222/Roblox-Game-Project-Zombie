-- WeaponManager.lua (Script)
-- Path: ServerScriptService/Script/WeaponManager.lua
-- Script Place: ACT 1: Village

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local BindableEvents = game.ReplicatedStorage.BindableEvents
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local ReportDamageEvent = BindableEvents:WaitForChild("ReportDamageEvent")
local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local ElementModule = require(ModuleScriptServerScriptService:WaitForChild("ElementConfigModule"))
local CoinsManager = require(ModuleScriptServerScriptService:WaitForChild("CoinsModule"))
local SkillModule = require(ModuleScriptServerScriptService:WaitForChild("SkillModule"))
local SkillConfig = require(ModuleScriptReplicatedStorage:WaitForChild("SkillConfig"))
local StatsModule = require(ModuleScriptServerScriptService:WaitForChild("StatsModule"))
local MissionManager = require(ModuleScriptServerScriptService:WaitForChild("MissionManager"))
local CollisionUtil = require(ServerScriptService.ModuleScript:WaitForChild("CollisionUtil"))

-- Ragdoll Force Constants
local RAGDOLL_FORCE_MULTIPLIER = 1.25 -- Force = Damage * this value (reduced for subtle effect)
local RAGDOLL_UPWARD_COMPONENT = 1 -- Add slight upward force for better ragdoll effect

-- Helper function to store hit direction for ragdoll
local function storeHitForRagdoll(hitModel, hitDirection, damage)
	if not hitModel or not hitModel:FindFirstChild("IsZombie") then return end

	-- Store normalized direction
	local normalizedDir = hitDirection.Unit
	-- Add slight upward component for more dramatic ragdoll
	local adjustedDir = (normalizedDir + Vector3.new(0, RAGDOLL_UPWARD_COMPONENT, 0)).Unit

	hitModel:SetAttribute("LastHitDirection", adjustedDir)
	hitModel:SetAttribute("LastHitForce", damage * RAGDOLL_FORCE_MULTIPLIER)
end

local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local ReloadEvent = RemoteEvents:WaitForChild("ReloadEvent")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")
local HitmarkerEvent = RemoteEvents:WaitForChild("HitmarkerEvent")
local BulletholeEvent = RemoteEvents:WaitForChild("BulletholeEvent")
local ExplosionEvent = RemoteEvents:FindFirstChild("ExplosionEvent") or Instance.new("RemoteEvent", RemoteEvents)
ExplosionEvent.Name = "ExplosionEvent"
local DamageDisplayEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("DamageDisplayEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
DamageDisplayEvent.Name = "DamageDisplayEvent"

local PlayGunshotSoundEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("PlayGunshotSoundEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
PlayGunshotSoundEvent.Name = "PlayGunshotSoundEvent"

local PlayLocalGunshotSoundEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("PlayLocalGunshotSoundEvent") or Instance.new("RemoteEvent", ReplicatedStorage.RemoteEvents)
PlayLocalGunshotSoundEvent.Name = "PlayLocalGunshotSoundEvent"

-- Anti-spam tembak: catat waktu tembak terakhir per-player per-senjata
local lastFireTime = {}

local playerAmmo = {}
local playerReserveAmmo = {}

local function applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshot, weaponName)
	if damage <= 0 then return end

	local isZombie = hitModel:FindFirstChild("IsZombie")
	local targetPlayer = game.Players:GetPlayerFromCharacter(hitModel)

	-- Jika bukan zombie atau pemain, abaikan
	if not isZombie and not targetPlayer then return end

	-- Cek kondisi friendly fire
	if targetPlayer and targetPlayer ~= player then
		local currentDifficulty = GameStatus:GetDifficulty()
		local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules
		if not (difficultyRules and difficultyRules.FriendlyFire) then
			return -- Friendly fire tidak aktif, jangan beri damage
		end
	end

	local finalDamage = damage
	-- Terapkan efek elemental dan reduksi damage hanya pada zombie
	if isZombie then
		finalDamage = ElementModule.OnPlayerHit(player, hitModel, damage) or damage
		if hitModel:GetAttribute("Immune") then
			finalDamage = 0
		else
			local dr = hitModel:GetAttribute("DamageReductionPct") or 0
			finalDamage = finalDamage * (1 - math.clamp(dr, 0, 0.95))
		end
	end

	if finalDamage <= 0 then return end

	targetHumanoid:TakeDamage(finalDamage)

	-- Update statistik, poin, dan creator tag hanya untuk zombie
	if isZombie then
		ReportDamageEvent:Fire(player, finalDamage)
		StatsModule.AddTotalDamage(player, finalDamage)
		StatsModule.AddWeaponDamage(player, weaponName, finalDamage)
		PointsSystem.AddDamage(player, finalDamage)
		DamageDisplayEvent:FireAllClients(finalDamage, hitModel, isHeadshot)

		-- Handle creator tag for kill credit
		local creatorTag = hitModel:FindFirstChild("creator")
		if not creatorTag then
			creatorTag = Instance.new("StringValue")
			creatorTag.Name = "creator"
			creatorTag.Parent = hitModel
		end

		local existingData = {}
		if creatorTag.Value and creatorTag.Value ~= "" then
			local success, result = pcall(HttpService.JSONDecode, HttpService, creatorTag.Value)
			if success and typeof(result) == "table" then
				existingData = result
			end
		end

		if not existingData.IsHeadshot or isHeadshot then
			local weaponDisplayName = (WeaponModule.Weapons[weaponName] and WeaponModule.Weapons[weaponName].DisplayName) or weaponName
			local creatorData = {
				Player = player.UserId,
				WeaponType = weaponDisplayName,
				IsHeadshot = existingData.IsHeadshot or isHeadshot
			}
			creatorTag.Value = HttpService:JSONEncode(creatorData)
		end
	end

	return finalDamage
end



local function ensureToolHasId(tool)
	if not tool then return nil end
	if not tool:GetAttribute("WeaponId") then
		tool:SetAttribute("WeaponId", HttpService:GenerateGUID(false))
	end
	return tool:GetAttribute("WeaponId")
end

-- Helper function to calculate weapon stats based on upgrades and attributes
local function calculateWeaponStats(tool, weaponStats)
	local defaultMax = weaponStats.MaxAmmo or 0
	local defaultReserve = weaponStats.ReserveAmmo or 0

	-- Calculate dynamic stats based on UpgradeLevel
	local level = tool:GetAttribute("UpgradeLevel") or 0

	-- Level 1+: MaxAmmo increases by 50%
	if level >= 1 then
		defaultMax = math.floor(defaultMax * 1.5)
	end

	-- Level 2+: ReserveAmmo increases by flat amount per level
	if level >= 2 then
		local cfg = weaponStats.UpgradeConfig
		local ammoPerLevel = cfg and cfg.AmmoPerLevel or 0
		defaultReserve = defaultReserve + ((level - 1) * ammoPerLevel)
	end

	local customMax = tool:GetAttribute("CustomMaxAmmo")
	local customReserve = tool:GetAttribute("CustomReserveAmmo")

	local initMax = customMax or defaultMax
	local initReserve = customReserve or defaultReserve

	return initMax, initReserve
end

local function setupToolAmmoForPlayer(player, tool)
	if not tool or not tool:IsA("Tool") then return end
	local weaponName = tool.Name
	if not WeaponModule.Weapons[weaponName] then return end
	local id = ensureToolHasId(tool)
	if not id then return end
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}

	local weaponStats = WeaponModule.Weapons[weaponName]
	local initMax, initReserve = calculateWeaponStats(tool, weaponStats)

	if playerAmmo[player][id] == nil then
		playerAmmo[player][id] = initMax
		playerReserveAmmo[player][id] = initReserve
	end

	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	if not tool:GetAttribute("_AmmoListenerAttached") then
		tool:SetAttribute("_AmmoListenerAttached", true)
		tool.AttributeChanged:Connect(function(attr)
			if attr == "CustomMaxAmmo" or attr == "CustomReserveAmmo" or attr == "UpgradeLevel" then
				local newMax, newReserve = calculateWeaponStats(tool, weaponStats)

				playerAmmo[player] = playerAmmo[player] or {}
				playerReserveAmmo[player] = playerReserveAmmo[player] or {}

				playerAmmo[player][id] = newMax
				playerReserveAmmo[player][id] = newReserve

				AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)
			end
		end)
	end
end

ShootEvent.OnServerEvent:Connect(function(player, tool, cameraDirection, isAiming)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then
		return
	end

	-- NEW: Cek jika player sedang knock
	if char:FindFirstChild("Knocked") then
		return
	end

	-- Atur atribut IsShooting untuk membatalkan revive jika sedang berlangsung
	char:SetAttribute("IsShooting", true)
	task.delay(0.1, function()
		if char then
			char:SetAttribute("IsShooting", false)
		end
	end)

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}
	if playerAmmo[player][id] == nil then
		print("DEBUG: Init ammo for " .. weaponName .. " | ID: " .. tostring(id))
		playerAmmo[player][id] = weaponStats.MaxAmmo
		playerReserveAmmo[player][id] = weaponStats.ReserveAmmo
	end

	-- ===== Server-side fire-rate gate =====
	if player.Character and player.Character:GetAttribute("IsReloading") then
		print("DEBUG: Shoot blocked - IsReloading")
		return
	end

	lastFireTime[player] = lastFireTime[player] or {}

	local now = tick()
	local cooldown = weaponStats.FireRate

	local last = lastFireTime[player][id] or 0
	if (now - last) < cooldown then
		-- print("DEBUG: Shoot blocked - Cooldown") -- Spammy
		return
	end

	-- Lewat gate: set timestamp tembakan
	lastFireTime[player][id] = now
	-- ===== End gate =====

	if playerAmmo[player][id] <= 0 then
		return
	end

	playerAmmo[player][id] = playerAmmo[player][id] - 1
	AmmoUpdateEvent:FireClient(player, weaponName, playerAmmo[player][id], playerReserveAmmo[player][id], true)

	-- Play 3D gunshot sound for all players to hear from weapon muzzle position
	local weaponPosition = char.Head.Position
	-- Get the actual weapon position using its offset
	if char:FindFirstChild("HumanoidRootPart") then
		local rootPart = char.HumanoidRootPart
		local muzzleOffset = weaponStats.MuzzleOffset or Vector3.new(0, 0, 0)
		weaponPosition = rootPart.CFrame:PointToWorldSpace(muzzleOffset)
	end

	-- Play 3D gunshot sound for all players (client filters out shooter)
	PlayGunshotSoundEvent:FireAllClients(player, weaponPosition, weaponName)

	-- Fire local gunshot event to the weapon owner for immediate, clear audio
	PlayLocalGunshotSoundEvent:FireClient(player, weaponName)

	-- FIX: Ghost Bullets. Calculate origin from MuzzleOffset instead of Head.
	local origin = char.Head.Position
	if char:FindFirstChild("HumanoidRootPart") then
		-- We use camera cframe rotation logic implicitly by transforming the offset via RootPart or Camera
		-- Ideally, we want the exact muzzle position. Since the server doesn't have the Viewmodel,
		-- we approximate it using the RootPart's CFrame translated by the MuzzleOffset.
		-- However, MuzzleOffset in WeaponModule is often relative to camera/viewmodel.
		-- A safer bet for gameplay consistency (so you don't shoot walls in front of you)
		-- is to offset slightly from the Head in the direction of the camera.

		-- BETTER APPROACH: Use the visual muzzle position logic if possible,
		-- but fallback to a simpler "Head + Offset" to avoid shooting from inside the body.

		local muzzleOffset = weaponStats.MuzzleOffset or Vector3.new(0, 0, -2)
		-- We project the offset relative to the camera direction (approximated by Head CFrame looking at direction)
		local aimCFrame = CFrame.new(char.Head.Position, char.Head.Position + cameraDirection)
		origin = aimCFrame:PointToWorldSpace(muzzleOffset)
	end

	-- The direction is now the LookVector sent from the client, multiplied by a max distance.
	local direction = cameraDirection * 300
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {char}

	-- Abaikan semua instance drop di workspace (nama diawali "Drop_")
	for _, child in ipairs(workspace:GetChildren()) do
		if typeof(child.Name) == "string" and string.sub(child.Name, 1, 5) == "Drop_" then
			table.insert(raycastParams.FilterDescendantsInstances, child)
		end
	end
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Set the raycast to use the Projectiles collision group
	raycastParams.CollisionGroup = CollisionUtil.PROJECTILE_GROUP

	local hasHeadshot = false
	local hasBodyshot = false
	local explosionTriggered = false -- Flag untuk memastikan hanya satu ledakan per tembakan

	local currentLevel = tool:GetAttribute("UpgradeLevel") or 0
	local baseRecoil = weaponStats.Recoil or 1
	-- Recoil reduction: 0.1 per level
	local effectiveRecoil = math.max(0, baseRecoil - (currentLevel * 0.1))

	-- Use effective recoil to influence spread (Server-Authoritative)
	-- Multiplier: Lower recoil = Lower spread (more accurate)
	-- We normalize base recoil around 1.0 to keep spread predictable
	local spreadMultiplier = math.max(0.2, effectiveRecoil) -- Prevent 0 spread absolute laser

	if weaponStats.Pellets then
		local baseSpread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		local spread = baseSpread * spreadMultiplier

		for i = 1, weaponStats.Pellets do
			local pelletSpread = Vector3.new(
				(math.random() - 0.5) * spread,
				(math.random() - 0.5) * spread,
				(math.random() - 0.5) * spread
			)
			local pelletDir = (cameraDirection + pelletSpread).Unit * 300
			local res = workspace:Raycast(origin, pelletDir, raycastParams)

			if res and res.Instance then
				local hitPart = res.Instance
				local hitModel = hitPart:FindFirstAncestorOfClass("Model")
				-- hanya buat bullethole kalau yang kena bukan zombie atau player
				local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
				local isPlayer = hitModel and game.Players:GetPlayerFromCharacter(hitModel)
				if not isZombie and not isPlayer then
					BulletholeEvent:FireClient(player, res.Position, res.Normal)
				end

				if hitModel and hitModel:FindFirstChild("Humanoid") then
					local targetHumanoid = hitModel:FindFirstChild("Humanoid")
					local immune = (hitModel:GetAttribute("Immune") == true)
					local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
					local base = weaponStats.Damage or 0
					local cfg = weaponStats.UpgradeConfig
					local damage = base
					if cfg then
						damage = base + (cfg.DamagePerLevel * instanceLevel)
					end
					local isHeadshotPellet = false

					if hitModel:FindFirstChild("IsZombie") and targetHumanoid.Health > 0 then
						local skillData = SkillModule.GetSkillData(player)
						if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
							local headshotLevel = skillData.Skills.HeadshotDamage or 0
							local headshotBonus = headshotLevel * (SkillConfig.HeadshotDamage.DamagePerLevel or 1)
							damage = (damage * weaponStats.HeadshotMultiplier) + headshotBonus
							isHeadshotPellet = true
							if not immune then hasHeadshot = true end
						else
							if not immune then hasBodyshot = true end
						end
						if hitModel:FindFirstChild("IsBoss") then
							local bossDamageLevel = skillData.Skills.DamageBoss or 0
							local bossDamageBonus = bossDamageLevel * (SkillConfig.DamageBoss.DamagePerLevel or 0)
							damage = damage + bossDamageBonus
						end

						-- Apply weapon specialist damage
						if weaponName ~= "Minigun" then
							local category = weaponStats.Category
							if category then
								local categoryKey = string.gsub(category, " ", "")
								if SkillConfig.WeaponSpecialist.Categories[categoryKey] and skillData.Skills.WeaponSpecialist then
									local specialistLevel = skillData.Skills.WeaponSpecialist[categoryKey] or 0
									if specialistLevel > 0 then
										local specialistBonus = specialistLevel * (SkillConfig.WeaponSpecialist.DamagePerLevel or 1)
										damage = damage + specialistBonus
									end
								end
							end
						end
					end

					-- Store hit direction for ragdoll (using pellet direction)
					storeHitForRagdoll(hitModel, pelletDir, damage)

					local finalDamage = applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshotPellet, weaponName)
					if finalDamage and finalDamage > 0 then
						-- Logika Poin & Misi per Pellet
						if not immune then
							local bpMultiplier = GameConfig.Economy and GameConfig.Economy.BP_Per_Damage_Multiplier or 0
							PointsSystem.AddPoints(player, math.floor(finalDamage * bpMultiplier))
						end

						if isHeadshotPellet then
							HitmarkerEvent:FireClient(player, true)
							-- Update misi headshot
							if MissionManager then
								MissionManager:UpdateMissionProgress(player, {
									eventType = "HEADSHOT",
									amount = 1,
									weaponType = weaponStats.Category
								})
							end
						else
							HitmarkerEvent:FireClient(player, false)
							-- Update misi 'hit' jika ada di masa depan
							if MissionManager then
								MissionManager:UpdateMissionProgress(player, {
									eventType = "HIT",
									amount = 1,
									weaponType = weaponStats.Category
								})
							end
						end


					end

					-- DESTUCTIBLE COVER LOGIC FOR PELLETS
				elseif hitModel and hitModel:GetAttribute("Destructible") then
					local ObjectDamagedEvent = ReplicatedStorage.BindableEvents:FindFirstChild("ObjectDamaged")
					if ObjectDamagedEvent then
						-- Calculate base damage for prop
						local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
						local base = weaponStats.Damage or 10
						local cfg = weaponStats.UpgradeConfig
						local damage = base
						if cfg then
							damage = base + (cfg.DamagePerLevel * instanceLevel)
						end

						ObjectDamagedEvent:Fire(hitModel, damage, res.Position)
					end
				end
			end
		end
	else
		local baseSpread = isAiming and weaponStats.ADS_Spread or weaponStats.Spread
		local spread = baseSpread * spreadMultiplier

		local spreadOffset = Vector3.new(
			(math.random() - 0.5) * spread,
			(math.random() - 0.5) * spread,
			(math.random() - 0.5) * spread
		)
		direction = (cameraDirection + spreadOffset).Unit * 300

		local result = workspace:Raycast(origin, direction, raycastParams)

		if result and result.Instance then
			local hitPart = result.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			-- hanya buat bullethole kalau yang kena bukan zombie atau player
			local isZombie = hitModel and hitModel:FindFirstChild("IsZombie")
			local isPlayer = hitModel and game.Players:GetPlayerFromCharacter(hitModel)
			if not isZombie and not isPlayer then
				BulletholeEvent:FireClient(player, result.Position, result.Normal)
			end

			-- Handle Explosion VFX
			if weaponStats.ExplosionRadius and weaponStats.ExplosionRadius > 0 then
				ExplosionEvent:FireAllClients(result.Position, weaponStats.ExplosionRadius)
			end

			if hitModel and hitModel:FindFirstChild("Humanoid") then
				local targetHumanoid = hitModel:FindFirstChild("Humanoid")
				local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
				local base = weaponStats.Damage or 0
				local cfg = weaponStats.UpgradeConfig
				local damage = base
				if cfg then
					damage = base + (cfg.DamagePerLevel * instanceLevel)
				end

				local isHeadshot = false
				local isZombie = hitModel:FindFirstChild("IsZombie")
				local isBoss = hitModel:FindFirstChild("IsBoss")

				if isZombie and targetHumanoid.Health > 0 then
					local skillData = SkillModule.GetSkillData(player)
					if hitPart.Name == "Head" or hitPart.Parent and hitPart.Parent.Name == "Head" then
						local headshotLevel = skillData.Skills.HeadshotDamage or 0
						local headshotBonus = headshotLevel * (SkillConfig.HeadshotDamage.DamagePerLevel or 1)
						damage = (damage * weaponStats.HeadshotMultiplier) + headshotBonus
						isHeadshot = true
					end

					if isBoss then
						local bossDamageLevel = skillData.Skills.DamageBoss or 0
						local bossDamageBonus = bossDamageLevel * (SkillConfig.DamageBoss.DamagePerLevel or 0)
						damage = damage + bossDamageBonus
					end

					-- Apply weapon specialist damage
					if weaponName ~= "Minigun" then
						local category = weaponStats.Category
						if category then
							local categoryKey = string.gsub(category, " ", "")
							if SkillConfig.WeaponSpecialist.Categories[categoryKey] and skillData.Skills.WeaponSpecialist then
								local specialistLevel = skillData.Skills.WeaponSpecialist[categoryKey] or 0
								if specialistLevel > 0 then
									local specialistBonus = specialistLevel * (SkillConfig.WeaponSpecialist.DamagePerLevel or 1)
									damage = damage + specialistBonus
								end
							end
						end
					end
				end

				-- Store hit direction for ragdoll
				storeHitForRagdoll(hitModel, direction, damage)

				HitmarkerEvent:FireClient(player, isHeadshot)

				-- SINGLE POINT OF DAMAGE APPLICATION
				local finalDamage = applyDamageAndStats(player, targetHumanoid, hitModel, damage, isHeadshot, weaponName)

				-- Berikan poin berdasarkan damage jika target bukan immune
				if finalDamage and finalDamage > 0 and isZombie and not hitModel:GetAttribute("Immune") then
					local bpMultiplier = GameConfig.Economy and GameConfig.Economy.BP_Per_Damage_Multiplier or 0
					PointsSystem.AddPoints(player, math.floor(finalDamage * bpMultiplier))
				end

				-- Update Misi
				if MissionManager and finalDamage and finalDamage > 0 then
					local eventType = isHeadshot and "HEADSHOT" or "HIT"
					MissionManager:UpdateMissionProgress(player, {
						eventType = eventType,
						amount = 1,
						weaponType = weaponStats.Category
					})
				end

				-- DESTUCTIBLE COVER LOGIC (No Humanoid)
			elseif hitModel and hitModel:GetAttribute("Destructible") then
				local ObjectDamagedEvent = ReplicatedStorage.BindableEvents:FindFirstChild("ObjectDamaged")
				if ObjectDamagedEvent then
					-- Calculate base damage for prop
					local instanceLevel = tool:GetAttribute("UpgradeLevel") or 0
					local base = weaponStats.Damage or 10
					local cfg = weaponStats.UpgradeConfig
					local damage = base
					if cfg then
						damage = base + (cfg.DamagePerLevel * instanceLevel)
					end

					ObjectDamagedEvent:Fire(hitModel, damage, result.Position)

					-- Optional: Hitmarker for props?
					HitmarkerEvent:FireClient(player, false) 
				end
			end


		end
	end
end)

ReloadEvent.OnServerEvent:Connect(function(player, tool)
	-- HARD GUARD: cegah spam reload (double-tap/berkali-kali)
	if player.Character then
		-- kalau sudah sedang reload ATAU ada lock aktif, tolak segera
		if player.Character:GetAttribute("IsReloading") or player.Character:GetAttribute("_ReloadLock") then
			return
		end
		-- pasang lock sedini mungkin untuk menutup race condition
		player.Character:SetAttribute("_ReloadLock", true)
	end
	if not tool or not tool:IsA("Tool") then return end
	if not player.Character or not tool:IsDescendantOf(player.Character) then return end

	-- NEW: Cek jika player sedang knock
	if player.Character:FindFirstChild("Knocked") then
		return
	end

	local weaponName = tool.Name
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return end

	local id = ensureToolHasId(tool)

	-- Initialize tables if missing (possible race condition fix)
	playerAmmo[player] = playerAmmo[player] or {}
	playerReserveAmmo[player] = playerReserveAmmo[player] or {}

	local currentAmmo = playerAmmo[player][id] or weaponStats.MaxAmmo
	local reserveAmmo = playerReserveAmmo[player][id] or weaponStats.ReserveAmmo

	local maxAmmo, _ = calculateWeaponStats(tool, weaponStats)

	local ammoNeeded = maxAmmo - currentAmmo
	local ammoToReload = math.min(ammoNeeded, reserveAmmo)

	if ammoToReload > 0 then
		-- Tandai RELOADING seawal mungkin (lock sudah terpasang di atas)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end
		-- Cek perk ReloadPlus
		-- Tandai karakter sedang reload (atribut global & konsisten untuk semua senjata)
		if player.Character then
			player.Character:SetAttribute("IsReloading", true)
		end

		local reloadTime = weaponStats.ReloadTime
		if player.Character and player.Character:GetAttribute("ReloadBoost") then
			reloadTime = reloadTime * 0.7 -- 30% faster
		end

		for i = 1, 20 do
			if not tool.Parent or not player.Character or not tool:IsDescendantOf(player.Character) then
				break
			end
			local progress = i / 20
			local reloadPercentage = math.floor(progress * 100)
			AmmoUpdateEvent:FireClient(player, weaponName, reloadPercentage, 0, true, true)
			task.wait(reloadTime / 20)
		end

		if tool.Parent and player.Character and tool:IsDescendantOf(player.Character) then
			-- Ensure tables still exist after yield
			playerAmmo[player] = playerAmmo[player] or {}
			playerReserveAmmo[player] = playerReserveAmmo[player] or {}

			playerAmmo[player][id] = currentAmmo + ammoToReload
			playerReserveAmmo[player][id] = reserveAmmo - ammoToReload
		else
			-- Tidak ada peluru untuk di-reload ? bebaskan lock bila ada
			if player.Character then
				player.Character:SetAttribute("_ReloadLock", false)
			end
		end
	end
	-- Selesai reload ? hapus tanda reload
	if player.Character then
		player.Character:SetAttribute("IsReloading", false)
		-- Bersihkan lock setelah reload beres
		player.Character:SetAttribute("_ReloadLock", false)
	end

	-- Final safety check before firing event
	local finalAmmo = (playerAmmo[player] and playerAmmo[player][id]) or maxAmmo
	local finalReserve = (playerReserveAmmo[player] and playerReserveAmmo[player][id]) or reserveAmmo

	AmmoUpdateEvent:FireClient(player, weaponName, finalAmmo, finalReserve, true, false)
end)

game.Players.PlayerAdded:Connect(function(player)
	playerAmmo[player] = {}
	playerReserveAmmo[player] = {}
	player.CharacterAdded:Connect(function(char)
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("Tool") then
				setupToolAmmoForPlayer(player, v)
			end
		end
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.wait(0.1) -- Beri waktu agar replikasi equip selesai di client
				print("DEBUG: Tool equipped, syncing ammo for " .. child.Name)
				setupToolAmmoForPlayer(player, child)
			end
		end)
	end)

	local backpack = player:WaitForChild("Backpack")
	for _, v in pairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			setupToolAmmoForPlayer(player, v)
		end
	end
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.wait(0.02)
			setupToolAmmoForPlayer(player, child)
		end
	end)
end)

-- Bersihkan state saat player keluar
game.Players.PlayerRemoving:Connect(function(plr)
	playerAmmo[plr] = nil
	playerReserveAmmo[plr] = nil
	lastFireTime[plr] = nil
end)
