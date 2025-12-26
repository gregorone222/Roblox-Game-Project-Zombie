-- Boss1VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/BossVFXModule.lua
-- Script Place: ACT 1: Village

local BossVFXModule = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- === Helpers khusus Boss ===
function BossVFXModule.ApplyPlayerPoisonEffect(character, isSpecial, duration)
	if not character or not character:FindFirstChild("Humanoid") then return end
	local existingEffect = character:FindFirstChild("PoisonEffect")
	if existingEffect then existingEffect:Destroy() end

	local poisonEffect = Instance.new("Folder")
	poisonEffect.Name = "PoisonEffect"

	local attachPoint = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character.PrimaryPart
	if not attachPoint then return end

	-- Main poison gas particles (more realistic)
	local poisonParticles = Instance.new("ParticleEmitter")
	poisonParticles.Parent = attachPoint
	poisonParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(180, 0, 0)) or ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 120, 40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 180, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 100, 30))
	})
	poisonParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 1.2),
		NumberSequenceKeypoint.new(0.7, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	poisonParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	poisonParticles.Lifetime = NumberRange.new(1.5, 3)
	poisonParticles.Rate = 80
	poisonParticles.SpreadAngle = Vector2.new(360, 360)
	poisonParticles.Speed = NumberRange.new(1, 4)
	poisonParticles.Rotation = NumberRange.new(0, 360)
	poisonParticles.RotSpeed = NumberRange.new(-45, 45)
	poisonParticles.LightEmission = 0.3
	poisonParticles.LightInfluence = 0
	poisonParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	poisonParticles.Drag = 2

	-- Toxic bubble particles (improved)
	local bubbleParticles = Instance.new("ParticleEmitter")
	bubbleParticles.Parent = attachPoint
	bubbleParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(100, 200, 80))
	bubbleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.4, 0.6),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	bubbleParticles.Lifetime = NumberRange.new(1, 2.5)
	bubbleParticles.Rate = 25
	bubbleParticles.SpreadAngle = Vector2.new(180, 180)
	bubbleParticles.Shape = Enum.ParticleEmitterShape.Sphere
	bubbleParticles.Speed = NumberRange.new(0.5, 2)
	bubbleParticles.Acceleration = Vector3.new(0, 3, 0) -- Bubbles rise up
	bubbleParticles.Drag = 1

	-- Add dripping poison effect
	local dripParticles = Instance.new("ParticleEmitter")
	dripParticles.Parent = attachPoint
	dripParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(70, 160, 50))
	dripParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	dripParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	dripParticles.Lifetime = NumberRange.new(0.5, 1.2)
	dripParticles.Rate = 15
	dripParticles.SpreadAngle = Vector2.new(90, 90)
	dripParticles.Speed = NumberRange.new(1, 3)
	dripParticles.Acceleration = Vector3.new(0, -10, 0) -- Drips fall down
	dripParticles.Drag = 0.5

	-- Add poison glow using point light
	local poisonLight = Instance.new("PointLight")
	poisonLight.Brightness = isSpecial and 8 or 4
	poisonLight.Range = 15
	poisonLight.Color = isSpecial and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(60, 200, 60)
	poisonLight.Shadows = true
	poisonLight.Parent = attachPoint

	-- Add screen blur effect for immersed feeling
	if character == game.Players.LocalPlayer then
		local blurEffect = Instance.new("BlurEffect")
		blurEffect.Size = 8
		blurEffect.Name = "PoisonBlur"
		blurEffect.Parent = game.Lighting

		-- Animate blur intensity
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < duration and blurEffect.Parent do
				local tween1 = TweenService:Create(blurEffect, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = 12})
				tween1:Play()
				tween1.Completed:Wait()
				local tween2 = TweenService:Create(blurEffect, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = 8})
				tween2:Play()
				tween2.Completed:Wait()
			end
			if blurEffect.Parent then
				blurEffect:Destroy()
			end
		end)
	end

	local sound = AudioManager.createSound("VFX.Poison", poisonEffect, {Volume = isSpecial and 1.0 or 0.7})

	poisonParticles.Name = "PoisonParticles"
	bubbleParticles.Name = "BubbleParticles"
	dripParticles.Name = "DripParticles"
	poisonLight.Name = "PoisonLight"
	poisonParticles.Parent = poisonEffect
	bubbleParticles.Parent = poisonEffect
	dripParticles.Parent = poisonEffect
	poisonLight.Parent = poisonEffect
	poisonEffect.Parent = character

	if sound then sound:Play() end

	-- Pulsing light effect
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < duration and poisonLight and poisonLight.Parent do
			local tween1 = TweenService:Create(poisonLight, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 12 or 6})
			local tween2 = TweenService:Create(poisonParticles, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 120})
			tween1:Play()
			tween2:Play()
			tween1.Completed:Wait()
			local tween3 = TweenService:Create(poisonLight, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 8 or 4})
			local tween4 = TweenService:Create(poisonParticles, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 80})
			tween3:Play()
			tween4:Play()
			tween3.Completed:Wait()
		end
	end)

	Debris:AddItem(poisonEffect, duration)
end

function BossVFXModule.CreateBossPoisonAura(bossModel)
	if not bossModel or not bossModel.PrimaryPart then return end

	local aura = Instance.new("Part")
	aura.Size = Vector3.new(20, 20, 20)
	aura.Shape = Enum.PartType.Ball
	aura.CFrame = bossModel.PrimaryPart.CFrame
	aura.Anchored = true
	aura.CanCollide = false
	aura.Transparency = 1
	aura.Material = Enum.Material.Neon
	aura.Color = Color3.fromRGB(40, 120, 40)
	aura.Name = "BossPoisonAura"

	-- Main poison particles (more toxic look)
	local mainParticles = Instance.new("ParticleEmitter")
	mainParticles.Parent = aura
	mainParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 100, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 180, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 80, 20))
	})
	mainParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 2),
		NumberSequenceKeypoint.new(0.7, 4),
		NumberSequenceKeypoint.new(1, 0)
	})
	mainParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	mainParticles.Lifetime = NumberRange.new(2, 4)
	mainParticles.Rate = 150
	mainParticles.SpreadAngle = Vector2.new(360, 360)
	mainParticles.Shape = Enum.ParticleEmitterShape.Sphere
	mainParticles.Speed = NumberRange.new(1, 5)
	mainParticles.Rotation = NumberRange.new(0, 360)
	mainParticles.RotSpeed = NumberRange.new(-30, 30)
	mainParticles.LightEmission = 0.6
	mainParticles.LightInfluence = 0
	mainParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mainParticles.Drag = 1.5

	-- Toxic bubble particles (improved)
	local bubbleParticles = Instance.new("ParticleEmitter")
	bubbleParticles.Parent = aura
	bubbleParticles.Color = ColorSequence.new(Color3.fromRGB(80, 220, 80))
	bubbleParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbleParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	bubbleParticles.Lifetime = NumberRange.new(1.5, 3)
	bubbleParticles.Rate = 60
	bubbleParticles.SpreadAngle = Vector2.new(270, 270)
	bubbleParticles.Shape = Enum.ParticleEmitterShape.Sphere
	bubbleParticles.Speed = NumberRange.new(0.5, 3)
	bubbleParticles.Acceleration = Vector3.new(0, 2, 0)
	bubbleParticles.Drag = 1

	-- Toxic mist rising from the ground
	local mistParticles = Instance.new("ParticleEmitter")
	mistParticles.Parent = aura
	mistParticles.Color = ColorSequence.new(Color3.fromRGB(60, 150, 60))
	mistParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.6, 6),
		NumberSequenceKeypoint.new(1, 0)
	})
	mistParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.2, 0.4),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	mistParticles.Lifetime = NumberRange.new(3, 6)
	mistParticles.Rate = 40
	mistParticles.SpreadAngle = Vector2.new(45, 45)
	mistParticles.Shape = Enum.ParticleEmitterShape.Cylinder
	mistParticles.Speed = NumberRange.new(1, 3)
	mistParticles.LockedToPart = true
	mistParticles.Acceleration = Vector3.new(0, 1, 0)
	mistParticles.Texture = "rbxasset://textures/particles/cloud_main.dds"

	local light = Instance.new("PointLight")
	light.Brightness = 10
	light.Range = 30
	light.Color = Color3.fromRGB(40, 200, 40)
	light.Shadows = true
	light.Parent = aura

	-- Pulsing effect for particles and light
	task.spawn(function()
		while aura and aura.Parent do
			local tween1 = TweenService:Create(light, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 6})
			local tween2 = TweenService:Create(mainParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 100})
			local tween3 = TweenService:Create(bubbleParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 40})
			tween1:Play()
			tween2:Play()
			tween3:Play()
			tween1.Completed:Wait()

			local tween4 = TweenService:Create(light, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 10})
			local tween5 = TweenService:Create(mainParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 150})
			local tween6 = TweenService:Create(bubbleParticles, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 60})
			tween4:Play()
			tween5:Play()
			tween6:Play()
			tween4.Completed:Wait()
		end
	end)

	aura.Parent = workspace
	task.spawn(function()
		while bossModel and bossModel.Parent and aura do
			if bossModel.PrimaryPart then
				aura.CFrame = bossModel.PrimaryPart.CFrame
			end
			task.wait(0.1)
		end
		if aura then aura:Destroy() end
	end)

	return aura
end

function BossVFXModule.CreateBossPoisonEffect(position, isSpecial, duration)
	duration = duration or (isSpecial and 10 or 6) -- Fallback jika durasi tidak disediakan
	local scale = isSpecial and 3 or 1.5

	local cloud = Instance.new("Part")
	cloud.Size = Vector3.new(15 * scale, 8 * scale, 15 * scale)
	cloud.Shape = Enum.PartType.Ball
	cloud.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.CanQuery = false
	cloud.Transparency = 1
	cloud.Material = Enum.Material.Neon
	cloud.Color = isSpecial and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 120, 40)
	cloud.Name = isSpecial and "SpecialPoisonCloud" or "PoisonCloud"

	-- Main toxic gas particles (more realistic)
	local gasParticles = Instance.new("ParticleEmitter")
	gasParticles.Parent = cloud
	gasParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(200, 50, 50)) or ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 90, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 160, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 70, 20))
	})
	gasParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 4 * scale),
		NumberSequenceKeypoint.new(0.8, 3 * scale),
		NumberSequenceKeypoint.new(1, 0)
	})
	gasParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	gasParticles.Lifetime = NumberRange.new(2.5, 5)
	gasParticles.Rate = 200 * scale
	gasParticles.SpreadAngle = Vector2.new(360, 360)
	gasParticles.Shape = Enum.ParticleEmitterShape.Sphere
	gasParticles.Speed = NumberRange.new(0.5, 3)
	gasParticles.Rotation = NumberRange.new(0, 360)
	gasParticles.RotSpeed = NumberRange.new(-20, 20)
	gasParticles.LightEmission = 0.5
	gasParticles.LightInfluence = 0
	gasParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	gasParticles.Drag = 1

	-- Rising toxic mist (improved)
	local mistParticles = Instance.new("ParticleEmitter")
	mistParticles.Parent = cloud
	mistParticles.Color = isSpecial and ColorSequence.new(Color3.fromRGB(180, 80, 80)) or ColorSequence.new(Color3.fromRGB(60, 140, 60))
	mistParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2 * scale),
		NumberSequenceKeypoint.new(0.5, 6 * scale),
		NumberSequenceKeypoint.new(0.9, 4 * scale),
		NumberSequenceKeypoint.new(1, 0)
	})
	mistParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	mistParticles.Lifetime = NumberRange.new(2, 4) -- Mengurangi lifetime agar pudar lebih cepat
	mistParticles.Rate = 100 * scale
	mistParticles.SpreadAngle = Vector2.new(120, 120)
	mistParticles.Shape = Enum.ParticleEmitterShape.Cylinder
	mistParticles.Speed = NumberRange.new(1, 4)
	mistParticles.LockedToPart = true
	mistParticles.Acceleration = Vector3.new(0, 0.5, 0)
	mistParticles.Texture = "rbxasset://textures/particles/cloud_main.dds"

	-- Toxic droplets falling from the cloud
	local dripParticles = Instance.new("ParticleEmitter")
	dripParticles.Parent = cloud
	dripParticles.Color = ColorSequence.new(isSpecial and Color3.fromRGB(220, 100, 100) or Color3.fromRGB(70, 150, 50))
	dripParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	dripParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.4, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	dripParticles.Lifetime = NumberRange.new(1, 2.5)
	dripParticles.Rate = 50 * scale
	dripParticles.SpreadAngle = Vector2.new(180, 180)
	dripParticles.Speed = NumberRange.new(2, 6)
	dripParticles.Acceleration = Vector3.new(0, -15, 0)
	dripParticles.Drag = 0.3

	if isSpecial then
		local ring = Instance.new("Part")
		ring.Size = Vector3.new(1, 1, 1)
		ring.Shape = Enum.PartType.Cylinder
		ring.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Transparency = 0.2
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 50, 50)
		ring.Name = "PoisonShockwave"

		local ringMesh = Instance.new("CylinderMesh")
		ringMesh.Parent = ring
		ring.Parent = workspace

		local expandTween = TweenService:Create(ring, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(100, 1, 100), Transparency = 1})
		expandTween:Play()
		expandTween.Completed:Connect(function() ring:Destroy() end)

		-- Toxic tendrils effect
		for i = 1, 12 do
			local angle = (i / 12) * math.pi * 2
			local crackPos = position + Vector3.new(math.cos(angle) * 20, 0, math.sin(angle) * 20)
			local crack = Instance.new("Part")
			crack.Size = Vector3.new(8, 0.2, 3)
			crack.CFrame = CFrame.new(crackPos) * CFrame.Angles(0, angle, 0)
			crack.Anchored = true
			crack.CanCollide = false
			crack.CanQuery = false
			crack.Transparency = 0.3
			crack.Material = Enum.Material.Neon
			crack.Color = Color3.fromRGB(255, 80, 80)
			crack.Name = "PoisonCrack"

			-- Add particles to cracks
			local crackParticles = Instance.new("ParticleEmitter")
			crackParticles.Parent = crack
			crackParticles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
			crackParticles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1.5)
			})
			crackParticles.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.7, 0.8),
				NumberSequenceKeypoint.new(1, 1)
			})
			crackParticles.Lifetime = NumberRange.new(0.8, 2)
			crackParticles.Rate = 40
			crackParticles.SpreadAngle = Vector2.new(25, 25)
			crackParticles.Speed = NumberRange.new(1, 4)
			crackParticles.Drag = 2

			crack.Parent = workspace
			Debris:AddItem(crack, 5)
		end
	end

	local light = Instance.new("PointLight")
	light.Brightness = isSpecial and 18 or 12
	light.Range = isSpecial and 50 or 35
	light.Color = isSpecial and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 200, 50)
	light.Shadows = true
	light.Parent = cloud

	-- Pulsing effect for particles and light
	task.spawn(function()
		while cloud and cloud.Parent do
			local tween1 = TweenService:Create(light, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 12 or 8})
			local tween2 = TweenService:Create(gasParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 150 * scale})
			local tween3 = TweenService:Create(mistParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 70 * scale})
			tween1:Play()
			tween2:Play()
			tween3:Play()
			tween1.Completed:Wait()

			local tween4 = TweenService:Create(light, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = isSpecial and 18 or 12})
			local tween5 = TweenService:Create(gasParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 200 * scale})
			local tween6 = TweenService:Create(mistParticles, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rate = 100 * scale})
			tween4:Play()
			tween5:Play()
			tween6:Play()
			tween4.Completed:Wait()
		end
	end)

	local sound = AudioManager.createSound("VFX.Poison", cloud, {Volume = isSpecial and 1.0 or 0.7})
	if sound then sound:Play() end

	cloud.Parent = workspace
	cloud.Size = Vector3.new(3 * scale, 2 * scale, 3 * scale)
	local growTween = TweenService:Create(cloud, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(15 * scale, 8 * scale, 15 * scale)})
	growTween:Play()

	-- Logika pudar yang disempurnakan
	local fadeDuration = 3.0 -- Durasi pudar yang lebih lama untuk efek yang lebih halus
	if duration > fadeDuration then
		task.delay(duration - fadeDuration, function()
			if not cloud or not cloud.Parent then return end

			local fadeInfo = TweenInfo.new(fadeDuration)
			TweenService:Create(gasParticles, fadeInfo, { Rate = 0 }):Play()
			TweenService:Create(mistParticles, fadeInfo, { Rate = 0 }):Play()
			TweenService:Create(dripParticles, fadeInfo, { Rate = 0 }):Play()

			if light and light.Parent then
				TweenService:Create(light, fadeInfo, { Brightness = 0 }):Play()
			end
		end)
	end

	Debris:AddItem(cloud, duration + fadeDuration) -- Waktu hancur = durasi total + durasi pudar
	return cloud
end

function BossVFXModule.CreateBossPoisonEffectFollow(targetCharacter, isSpecial, durationOverride)
	if not targetCharacter then return end
	local hrp = targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChild("Head")
	if not hrp then return end

	local duration = durationOverride or (isSpecial and 10 or 6)
	local cloud = BossVFXModule.CreateBossPoisonEffect(hrp.Position + Vector3.new(0, 12, 0), isSpecial)
	if not cloud then return end

	task.spawn(function()
		local t0 = tick()
		while cloud and cloud.Parent and targetCharacter.Parent do
			if tick() - t0 >= duration then break end
			local p = hrp and hrp.Position or nil
			if not p then break end
			cloud.CFrame = CFrame.new(p + Vector3.new(0, 12, 0))
			task.wait(0.05)
		end
		if cloud and cloud.Parent then cloud:Destroy() end
	end)
	return cloud
end

-- === REVISED VFX FOR PROTOTYPE-MATCHING TOXIC LOB ===

-- Helper: Find nearest Boss
local function getBossPosition(targetPos)
	local bestPos = targetPos + Vector3.new(0, 50, 0) -- Fallback: Sky
	local minDist = math.huge

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChild("IsBoss") then
			local pp = child.PrimaryPart
			if pp then
				local dist = (pp.Position - targetPos).Magnitude
				if dist < minDist then
					minDist = dist
					bestPos = pp.Position + Vector3.new(0, 4, 0) -- From "mouth" height
				end
			end
		end
	end
	return bestPos
end

function BossVFXModule.CreateToxicLobTelegraph(position, config)
	local duration = config.TelegraphDuration or 1.5
	local radius = config.PuddleRadius or 8

	-- 1. Create Filling Circle (Inner)
	local fill = Instance.new("Part")
	fill.Shape = Enum.PartType.Cylinder
	fill.Size = Vector3.new(0.1, 0.1, 0.1) -- Start small
	fill.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	fill.Anchored = true
	fill.CanCollide = false
	fill.Material = Enum.Material.Neon
	fill.Color = Color3.fromRGB(255, 100, 50)
	fill.Transparency = 0.5
	fill.Name = "ToxicLobFill"
	fill.Parent = Workspace

	-- Animate Fill
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tweenFill = TweenService:Create(fill, tweenInfo, { Size = Vector3.new(0.1, radius * 2, radius * 2) })
	tweenFill:Play()

	-- 2. Launch Projectile (Timed to land at end of duration)
	task.spawn(function()
		local startPos = getBossPosition(position)
		local endPos = position

		-- Projectile Mesh
		local projectile = Instance.new("Part")
		projectile.Shape = Enum.PartType.Ball
		projectile.Size = Vector3.new(2, 2, 2)
		projectile.Material = Enum.Material.Neon
		projectile.Color = Color3.fromRGB(57, 255, 20) -- Toxic Green
		projectile.Anchored = true
		projectile.CanCollide = false
		projectile.CFrame = CFrame.new(startPos)
		projectile.Parent = Workspace

		-- Add Trail (No Asset ID, just Attachment + Trail)
		local att0 = Instance.new("Attachment", projectile)
		att0.Position = Vector3.new(0, 0.5, 0)
		local att1 = Instance.new("Attachment", projectile)
		att1.Position = Vector3.new(0, -0.5, 0)

		local trail = Instance.new("Trail")
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Lifetime = 0.3
		trail.Color = ColorSequence.new(Color3.fromRGB(57, 255, 20), Color3.fromRGB(0, 100, 0))
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.FaceCamera = true
		trail.Parent = projectile

		-- Parabolic Movement Loop
		local startTime = tick()
		local height = 15 -- Arc height

		while true do
			local elapsed = tick() - startTime
			local t = elapsed / duration
			if t >= 1 then break end

			-- Parabola Math: P(t) = Lerp(S, E, t) + VerticalOffset
			local currentPos = startPos:Lerp(endPos, t)
			-- Height offset: 4 * h * t * (1-t)
			local yOffset = 4 * height * t * (1 - t)

			projectile.Position = currentPos + Vector3.new(0, yOffset, 0)

			RunService.Heartbeat:Wait()
		end

		projectile:Destroy()
	end)

	-- Cleanup Telegraph
	Debris:AddItem(fill, duration)
end

function BossVFXModule.ExecuteToxicLob(position, config)
	local duration = config.PuddleDuration or 5
	local radius = config.PuddleRadius or 8

	-- Container for the puddle parts
	local puddleModel = Instance.new("Model")
	puddleModel.Name = "ToxicPuddleModel"
	puddleModel.Parent = Workspace

	-- 1. Create Core Puddle (Bright Neon)
	local puddleCore = Instance.new("Part")
	puddleCore.Shape = Enum.PartType.Cylinder
	puddleCore.Size = Vector3.new(0.2, radius * 1.6, radius * 1.6) -- Slightly smaller
	puddleCore.CFrame = CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
	puddleCore.Anchored = true
	puddleCore.CanCollide = false
	puddleCore.Material = Enum.Material.Neon
	puddleCore.Color = Color3.fromRGB(80, 255, 50) -- Brighter Green
	puddleCore.Transparency = 0.3
	puddleCore.Name = "Core"
	puddleCore.Parent = puddleModel

	-- 2. Create Outer Rim (Darker/Transparent)
	local puddleRim = Instance.new("Part")
	puddleRim.Shape = Enum.PartType.Cylinder
	puddleRim.Size = Vector3.new(0.1, radius * 2, radius * 2)
	puddleRim.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	puddleRim.Anchored = true
	puddleRim.CanCollide = false
	puddleRim.Material = Enum.Material.SmoothPlastic
	puddleRim.Color = Color3.fromRGB(40, 150, 20) -- Darker Green
	puddleRim.Transparency = 0.6
	puddleRim.Name = "Rim"
	puddleRim.Parent = puddleModel

	-- 3. Toxic Mist (Low lying fog)
	local mist = Instance.new("ParticleEmitter")
	mist.Name = "ToxicMist"
	mist.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 4),
		NumberSequenceKeypoint.new(1, 2)
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.7),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	mist.Lifetime = NumberRange.new(2, 3)
	mist.Rate = 20
	mist.Speed = NumberRange.new(1, 2)
	mist.SpreadAngle = Vector2.new(180, 0) -- Spread horizontally
	mist.Acceleration = Vector3.new(0, 0.5, 0) -- Slight rise
	mist.Parent = puddleCore

	-- 4. Bubbling Particles
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "Bubbles"
	bubbles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
	bubbles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2), 
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	bubbles.Transparency = NumberSequence.new(0.2, 1)
	bubbles.Lifetime = NumberRange.new(1, 1.5)
	bubbles.Rate = 30
	bubbles.Speed = NumberRange.new(2, 5)
	bubbles.Acceleration = Vector3.new(0, 8, 0) -- Rise faster
	bubbles.Shape = Enum.ParticleEmitterShape.Sphere
	bubbles.ShapePartial = 1
	bubbles.Parent = puddleCore

	-- 5. Splash Impact (Burst)
	local splash = Instance.new("ParticleEmitter")
	splash.Color = ColorSequence.new(Color3.fromRGB(80, 255, 50))
	splash.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
	splash.Lifetime = NumberRange.new(0.4, 0.8)
	splash.Speed = NumberRange.new(15, 25)
	splash.SpreadAngle = Vector2.new(45, 45)
	splash.Acceleration = Vector3.new(0, -40, 0) -- Strong Gravity
	splash.Parent = puddleCore
	splash.Enabled = false -- One shot

	task.delay(0, function()
		splash:Emit(60)
	end)

	-- 6. Pulsing Animation Loop
	local pulseTime = 0
	local pulseConnection
	pulseConnection = RunService.Heartbeat:Connect(function(dt)
		if not puddleCore or not puddleCore.Parent then
			if pulseConnection then pulseConnection:Disconnect() end
			return
		end
		pulseTime += dt * 3 -- Speed of pulse
		local scale = 1 + math.sin(pulseTime) * 0.05 -- +/- 5% size
		puddleCore.Size = Vector3.new(0.2, radius * 1.6 * scale, radius * 1.6 * scale)
		puddleCore.Transparency = 0.3 + math.sin(pulseTime) * 0.1 -- vary transparency
	end)

	-- 7. Fade Out Logic
	task.delay(duration - 1, function()
		if puddleModel and puddleModel.Parent then
			-- Fade out parts
			local tweenInfo = TweenInfo.new(1)
			TweenService:Create(puddleCore, tweenInfo, {Transparency = 1}):Play()
			TweenService:Create(puddleRim, tweenInfo, {Transparency = 1}):Play()

			-- Stop particles
			mist.Rate = 0
			bubbles.Rate = 0
		end
	end)

	-- Cleanup
	Debris:AddItem(puddleModel, duration)
	-- Ensure connection is cleaned up if model is destroyed early
	puddleModel.Destroying:Connect(function()
		if pulseConnection then pulseConnection:Disconnect() end
	end)
end

function BossVFXModule.CreateVolatileMinionExplosion(position, config)
	local explosionSphere = Instance.new("Part")
	explosionSphere.Shape = Enum.PartType.Ball
	explosionSphere.Size = Vector3.new(1, 1, 1)
	explosionSphere.CFrame = CFrame.new(position)
	explosionSphere.Anchored = true
	explosionSphere.CanCollide = false
	explosionSphere.Material = Enum.Material.Neon
	explosionSphere.Color = Color3.fromRGB(180, 255, 180)
	explosionSphere.Parent = Workspace

	local duration = 0.5
	local expandTween = TweenService:Create(explosionSphere, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(config.ExplosionRadius * 2, config.ExplosionRadius * 2, config.ExplosionRadius * 2),
		Transparency = 1
	})
	expandTween:Play()
	Debris:AddItem(explosionSphere, duration)

	local burstPart = Instance.new("Part")
	burstPart.Size = Vector3.new(1,1,1)
	burstPart.CFrame = CFrame.new(position)
	burstPart.Anchored = true
	burstPart.CanCollide = false
	burstPart.Transparency = 1
	burstPart.Parent = Workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
	particles.LightEmission = 0.5
	particles.Size = NumberSequence.new(2, 4)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 0
	particles.Speed = NumberRange.new(20, 30)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = burstPart

	particles:Emit(150)
	Debris:AddItem(burstPart, 2)
end


return BossVFXModule
