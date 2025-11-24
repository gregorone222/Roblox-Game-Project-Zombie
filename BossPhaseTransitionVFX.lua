-- BossPhaseTransitionVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/BossPhaseTransitionVFX.lua
-- Script Place: ACT 1: Village
-- Deskripsi: Menangani efek visual "Ledakan Nuklir Korosif" untuk transisi fase bos.

local BossPhaseTransitionVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local CORE_COLOR = Color3.fromRGB(200, 255, 200)
local SHOCKWAVE_COLOR = Color3.fromRGB(100, 255, 100)
local DUST_COLOR = Color3.fromRGB(30, 80, 30)

function BossPhaseTransitionVFX.Play(bossModel, config)
	if not bossModel or not bossModel.PrimaryPart then return end

	local rootPart = bossModel.PrimaryPart
	local originPos = rootPart.Position

	-- Tahap 1: Implosion & Pengumpulan Energi (1 detik)
	task.spawn(function()
		local implosionPart = Instance.new("Part")
		implosionPart.Size = Vector3.new(40, 40, 40)
		implosionPart.Shape = Enum.PartType.Ball
		implosionPart.CFrame = CFrame.new(originPos)
		implosionPart.Anchored = true
		implosionPart.CanCollide = false
		implosionPart.Transparency = 1
		implosionPart.Parent = Workspace
		Debris:AddItem(implosionPart, 1)

		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(CORE_COLOR)
		particles.LightEmission = 0.5
		particles.Size = NumberSequence.new(1)
		particles.Lifetime = NumberRange.new(0.5)
		particles.Speed = NumberRange.new(-20) -- Kecepatan negatif untuk bergerak ke dalam
		particles.Rate = 500
		particles.EmissionDirection = Enum.NormalId.Front
		particles.Shape = Enum.ParticleEmitterShape.Sphere
		particles.Parent = implosionPart
		task.delay(0.5, function() particles.Enabled = false end)

		local coreLight = Instance.new("PointLight")
		coreLight.Color = CORE_COLOR
		coreLight.Range = 60
		coreLight.Brightness = 0
		coreLight.Parent = rootPart
		Debris:AddItem(coreLight, 3)
		TweenService:Create(coreLight, TweenInfo.new(1, Enum.EasingStyle.Quad), {Brightness = 20}):Play()

		-- Efek Retakan Energi pada Tubuh
		for _, bodyPart in ipairs(bossModel:GetChildren()) do
			if bodyPart:IsA("BasePart") and bodyPart.Name ~= "HumanoidRootPart" then
				local decal = Instance.new("Decal")
				decal.Texture = "rbxassetid://249999495" -- Tekstur retakan
				decal.Face = Enum.NormalId.Front
				decal.Color3 = CORE_COLOR
				decal.Transparency = 1
				decal.Parent = bodyPart
				Debris:AddItem(decal, 3)
				TweenService:Create(decal, TweenInfo.new(0.8), {Transparency = 0}):Play()
			end
		end
	end)

	task.wait(1) -- Tunggu antisipasi selesai

	-- Tahap 2: Ledakan Bertingkat
	-- Pelepasan Energi dari Tubuh
	for _, bodyPart in ipairs(bossModel:GetChildren()) do
		if bodyPart:IsA("BasePart") and bodyPart.Name ~= "HumanoidRootPart" then
			local burst = Instance.new("ParticleEmitter")
			burst.Color = ColorSequence.new(CORE_COLOR)
			burst.LightEmission = 1
			burst.Size = NumberSequence.new(0.5, 2)
			burst.Lifetime = NumberRange.new(0.5, 1)
			burst.Speed = NumberRange.new(20, 30)
			burst.Rate = 0
			burst.Parent = bodyPart
			burst:Emit(50)
			Debris:AddItem(burst, 2)
		end
	end
	task.spawn(function()
		-- 1. Kilatan Cahaya
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Size = Vector3.new(100, 100, 100)
		flash.CFrame = CFrame.new(originPos)
		flash.Material = Enum.Material.Neon
		flash.Color = Color3.new(1, 1, 1)
		flash.Anchored = true
		flash.CanCollide = false
		flash.Parent = Workspace
		Debris:AddItem(flash, 0.2)
		TweenService:Create(flash, TweenInfo.new(0.2), {Transparency = 1}):Play()

		-- 2. Gelombang Distorsi
		local distortion = Instance.new("Part")
		distortion.Shape = Enum.PartType.Ball
		distortion.Size = Vector3.new(1, 1, 1)
		distortion.CFrame = CFrame.new(originPos)
		distortion.Material = Enum.Material.ForceField
		distortion.Color = Color3.new(1, 1, 1)
		distortion.Anchored = true
		distortion.CanCollide = false
		distortion.Transparency = 0.8
		distortion.Parent = Workspace
		Debris:AddItem(distortion, 0.5)
		TweenService:Create(distortion, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(150, 150, 150), Transparency = 1}):Play()

		-- 3. Gelombang Neon Utama
		local shockwave = Instance.new("Part")
		shockwave.Shape = Enum.PartType.Cylinder
		shockwave.Size = Vector3.new(1, 2, 1) -- Diameter X/Z, Tinggi Y
		shockwave.CFrame = CFrame.new(originPos) -- Tidak perlu rotasi, silinder sudah tegak
		shockwave.Material = Enum.Material.Neon
		shockwave.Color = SHOCKWAVE_COLOR
		shockwave.Anchored = true
		shockwave.CanCollide = false
		shockwave.Parent = Workspace
		Debris:AddItem(shockwave, 1)
		TweenService:Create(shockwave, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size = Vector3.new(200, 2, 200), Transparency = 1}):Play() -- Animasikan diameter X dan Z

		-- 4. Awan Debu Korosif
		local dustCloud = Instance.new("Part")
		dustCloud.Shape = Enum.PartType.Cylinder
		dustCloud.Size = Vector3.new(1, 2, 1) -- Diameter X/Z, Tinggi Y
		dustCloud.CFrame = CFrame.new(originPos) -- Tidak perlu rotasi
		dustCloud.Anchored = true
		dustCloud.CanCollide = false
		dustCloud.Transparency = 1
		dustCloud.Parent = Workspace
		Debris:AddItem(dustCloud, 3)

		local dustParticles = Instance.new("ParticleEmitter")
		dustParticles.Color = ColorSequence.new(DUST_COLOR)
		dustParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 15)})
		dustParticles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
		dustParticles.Lifetime = NumberRange.new(2, 3)
		dustParticles.Speed = NumberRange.new(20, 30)
		dustParticles.Rate = 0
		dustParticles.SpreadAngle = Vector2.new(10, 10)
		dustParticles.EmissionDirection = Enum.NormalId.Top
		dustParticles.Parent = dustCloud

		TweenService:Create(dustCloud, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {Size = Vector3.new(200, 2, 200)}):Play()
		task.wait(0.1)
		dustParticles:Emit(1000)
	end)

	-- Tahap 3: Efek Sisa
	task.spawn(function()
		task.wait(0.2) -- Tunggu setelah ledakan awal

		-- Retakan Tanah
		for i = 1, 15 do
			local angle = math.random(0, 360)
			local distance = math.random(10, 50)
			-- FIX: Replaced .p with .Position
			local crackPos = originPos + (CFrame.fromAxisAngle(Vector3.new(0, 1, 0), math.rad(angle)) * CFrame.new(0, 0, -distance)).Position

			local rayOrigin = crackPos + Vector3.new(0, 10, 0)
			local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0))
			if rayResult then
				local crack = Instance.new("Part")
				crack.Size = Vector3.new(math.random(5, 15), 0.1, math.random(0.5, 1))
				crack.CFrame = CFrame.new(rayResult.Position) * CFrame.Angles(0, math.rad(angle), 0)
				crack.Material = Enum.Material.Neon
				crack.Color = SHOCKWAVE_COLOR
				crack.Anchored = true
				crack.CanCollide = false
				crack.Parent = Workspace
				Debris:AddItem(crack, 2.5)
				TweenService:Create(crack, TweenInfo.new(2.5, Enum.EasingStyle.Quad), {Transparency = 1}):Play()
			end
		end

		-- Pilar Energi
		local pillar = Instance.new("Part")
		pillar.Size = Vector3.new(10, 0.1, 10)
		pillar.CFrame = CFrame.new(originPos)
		pillar.Material = Enum.Material.ForceField
		pillar.Color = CORE_COLOR
		pillar.Anchored = true
		pillar.CanCollide = false
		pillar.Parent = Workspace
		Debris:AddItem(pillar, 2)
		TweenService:Create(pillar, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = Vector3.new(10, 100, 10), Transparency = 1}):Play()
	end)
end

return BossPhaseTransitionVFX