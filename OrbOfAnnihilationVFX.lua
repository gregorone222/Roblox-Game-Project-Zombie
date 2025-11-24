-- OrbOfAnnihilationVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/OrbOfAnnihilationVFX.lua
-- Script Place: ACT 1: Village

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ZombieConfig = require(game.ReplicatedStorage.ModuleScript.ZombieConfig)

local OrbVFX = {}

-- Helper function for smooth transitions (kept for potential future use)
local function lerp(a, b, t)
	return a + (b - a) * t
end

function OrbVFX.create(config)
	print("[OrbVFX] Creating orb with config:", config)
	-- Orb Part (Inti Hampa) - Black core
	local orb = Instance.new("Part")
	orb.Size = Vector3.new(1, 1, 1) -- Start small
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.SmoothPlastic
	orb.Color = Color3.new(0, 0, 0) -- Pure black
	orb.Reflectance = 0
	orb.CanCollide = false
	orb.Anchored = true
	orb.Name = "VoidCore"
	print("[OrbVFX] Orb created:", orb.Name, "Size:", orb.Size, "Anchored:", orb.Anchored)

	-- Aura Part (Distortion aura around orb) - Pulsing purple glow
	local aura = Instance.new("Part")
	aura.Size = Vector3.new(3, 3, 3) -- Start larger than orb
	aura.Shape = Enum.PartType.Ball
	aura.Material = Enum.Material.Plastic
	aura.Color = Color3.new(1, 1, 1) -- White for light carrier
	aura.Transparency = 1 -- Invisible, only for light
	aura.CanCollide = false
	aura.Anchored = true
	aura.Parent = orb
	print("[OrbVFX] Aura created and parented to orb")

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(124, 58, 237) -- Purple
	light.Range = 10
	light.Brightness = 1
	light.Parent = aura
	print("[OrbVFX] Light created and parented to aura")

	orb.Parent = Workspace
	print("[OrbVFX] Orb parented to Workspace")

	return orb
end

function OrbVFX.handleExplosion(orb, config)
	local position = orb.Position

	-- 1. Implosion (Suction effect)
	local implosion = Instance.new("Part")
	implosion.Size = Vector3.new(30, 30, 30) -- Large initial size
	implosion.Shape = Enum.PartType.Ball
	implosion.Material = Enum.Material.ForceField
	implosion.Color = Color3.fromRGB(124, 58, 237) -- Purple
	implosion.Transparency = 0.8
	implosion.CanCollide = false
	implosion.Anchored = true
	implosion.Position = position
	implosion.Parent = Workspace

	local implodeTween = TweenService:Create(implosion, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {Size = Vector3.new(0, 0, 0), Transparency = 1})
	implodeTween:Play()
	Debris:AddItem(implosion, 0.3)

	-- 2. Shockwave (Expanding ring)
	task.wait(0.3)
	local shockwave = Instance.new("Part")
	shockwave.Size = Vector3.new(1, 1, 1) -- Start small
	shockwave.Shape = Enum.PartType.Ball
	shockwave.Material = Enum.Material.ForceField
	shockwave.Color = Color3.fromRGB(224, 242, 254) -- Light purple-white
	shockwave.Transparency = 0
	shockwave.CanCollide = false
	shockwave.Anchored = true
	shockwave.Position = position
	shockwave.Parent = Workspace

	local shockwaveTween = TweenService:Create(shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = Vector3.new(config.ExplosionRadius * 4, config.ExplosionRadius * 4, config.ExplosionRadius * 4), Transparency = 1})
	shockwaveTween:Play()
	Debris:AddItem(shockwave, 0.5)

	-- 3. Puddle (Void puddle that fades)
	task.wait(0.2)
	local puddle = Instance.new("Part")
	puddle.Size = Vector3.new(config.ExplosionRadius * 2, 0.1, config.ExplosionRadius * 2)
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Material = Enum.Material.Neon
	puddle.Color = Color3.fromRGB(88, 28, 135) -- Dark purple
	puddle.Transparency = 1
	puddle.CanCollide = false
	puddle.Anchored = true
	puddle.Position = position - Vector3.new(0, 0.5, 0) -- Slightly below ground
	puddle.Parent = Workspace

	local puddleFadeTween = TweenService:Create(puddle, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 7), {Transparency = 1})
	puddleFadeTween:Play()
	Debris:AddItem(puddle, 8)
end

function OrbVFX.launch(orb, targetCharacter, config, onExplodeCallback, activeOrbsTable)
	print("[OrbVFX] Launching orb, targetCharacter:", targetCharacter, "config:", config)
	task.spawn(function()
		local startTime = tick()
		local homingStrength = config.HomingStrength or 0.1
		print("[OrbVFX] Keeping orb anchored for manual movement")

		-- orb.Anchored = false -- Keep anchored to prevent gravity sinking

		-- Set initial position if not set
		if not orb.Position or orb.Position == Vector3.new(0, 0, 0) then
			local targetHrp = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetHrp then
				orb.Position = targetHrp.Position + Vector3.new(0, ZombieConfig.Types.Boss2.OrbOfAnnihilation.ORB_HEIGHT, 0) -- Start above target
				print("[OrbVFX] Initial position set to:", orb.Position)
			else
				print("[OrbVFX] Warning: No target HumanoidRootPart found for initial positioning")
			end
		end

		-- Growth animation for orb and aura
		local finalSize = Vector3.new(7, 7, 7)
		local growTweenInfo = TweenInfo.new(config.Lifetime, Enum.EasingStyle.Linear)
		local growTween = TweenService:Create(orb, growTweenInfo, {Size = finalSize})
		growTween:Play()
		print("[OrbVFX] Growth tween started for orb")

		-- Aura scaling (grows with orb)
		local aura = orb:FindFirstChildOfClass("Part") -- The aura part
		if aura then
			local auraGrowTween = TweenService:Create(aura, growTweenInfo, {Size = finalSize * 1.5}) -- Slightly larger than orb
			auraGrowTween:Play()
			print("[OrbVFX] Aura growth tween started")
		else
			print("[OrbVFX] Warning: Aura part not found")
		end

		while orb.Parent and (tick() - startTime) < config.Lifetime do
			local currentPosition = orb.Position

			-- Homing logic
			local targetHrp = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			if not targetHrp or not targetHrp.Parent then
				print("[OrbVFX] Target HumanoidRootPart not found or invalid, breaking")
				break
			end

			-- Calculate ground level at target's position
			local rayOrigin = targetHrp.Position + Vector3.new(0, ZombieConfig.Types.Boss2.OrbOfAnnihilation.ORB_HEIGHT, 0) -- Start higher above to ensure clear raycast
			local rayDirection = Vector3.new(0, -50, 0) -- Longer raycast downward to ensure hitting ground
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {targetCharacter} -- Ignore the target character
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			local groundY = 0 -- Default ground level
			if raycastResult then
				groundY = raycastResult.Position.Y
				print("[OrbVFX] Raycast hit ground at Y:", groundY)
			else
				print("[OrbVFX] Raycast failed to hit ground, using default Y=0")
			end

			local targetPosition = Vector3.new(targetHrp.Position.X, groundY + ZombieConfig.Types.Boss2.OrbOfAnnihilation.ORB_HEIGHT, targetHrp.Position.Z)
			local targetDirection = (targetPosition - currentPosition).Unit
			local newLookVector = (orb.CFrame.LookVector + (targetDirection * homingStrength)).Unit

			-- Manually move the orb towards the target
			local moveDirection = (targetPosition - currentPosition).Unit
			local newPosition = currentPosition + moveDirection * config.OrbSpeed * 0.1 -- Adjust speed factor as needed
			orb.Position = newPosition
			orb.CFrame = CFrame.new(newPosition, newPosition + newLookVector)

			-- Update aura position to follow orb
			if aura then
				aura.Position = orb.Position
			end

			-- Check distance for explosion trigger
			local distanceToTarget = (orb.Position - targetHrp.Position).Magnitude
			if distanceToTarget < config.ExplosionRadius then
				print("[OrbVFX] Explosion triggered, distance:", distanceToTarget)
				break
			end

			task.wait()
		end

		if not orb.Parent then
			print("[OrbVFX] Orb has no parent, returning")
			return
		end

		local explosionPosition = orb.Position
		print("[OrbVFX] Handling explosion at position:", explosionPosition)

		OrbVFX.handleExplosion(orb, config)

		if onExplodeCallback then
			onExplodeCallback(explosionPosition)
		end

		orb:Destroy()
		print("[OrbVFX] Orb destroyed")
		if activeOrbsTable then
			for i, activeOrb in ipairs(activeOrbsTable) do
				if activeOrb == orb then
					table.remove(activeOrbsTable, i)
					print("[OrbVFX] Removed orb from activeOrbsTable")
					break
				end
			end
		end
	end)
end

return OrbVFX
