-- VolatileMinionVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/VolatileMinionVFX.lua
-- Script Place: ACT 1: Village
-- Deskripsi: Menangani efek visual untuk kemunculan Volatile Minion dari Boss 1.

local VolatileMinionVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- Konstanta untuk efek Corrosive Birthing Pod
local CORROSIVE_COLOR = Color3.fromRGB(170, 255, 0) -- #AAFF00
local CORROSIVE_COLOR_DARK = Color3.fromRGB(106, 156, 0) -- #6a9c00
local TELEGRAPH_DURATION = 1.5 -- Durasi fase telegraph
local LAUNCH_DURATION = 1.0 -- Durasi fase launch
local IMPACT_DURATION = 1.5 -- Durasi fase impact dan birthing sac
local PUDDLE_LIFETIME = 5.0 -- Durasi puddle fade out
local SPLASH_PARTICLE_COUNT = 20 -- Partikel splash
local DRIP_RATE = 10 -- Rate untuk drip particles

-- Fungsi untuk menampilkan peringatan (benjolan di tubuh bos)
function VolatileMinionVFX.PlayTelegraph(bossModel)
	if not bossModel or not bossModel:FindFirstChild("Torso") then return end

	local torso = bossModel.Torso

	-- Membuat benjolan
	local boil = Instance.new("Part")
	boil.Shape = Enum.PartType.Ball
	boil.Material = Enum.Material.Neon
	boil.Color = CORROSIVE_COLOR
	boil.Size = Vector3.new(0.5, 0.5, 0.5)
	boil.Anchored = true
	boil.CanCollide = false
	boil.Transparency = 1
	boil.Parent = workspace

	-- Menambahkan cahaya untuk efek bersinar
	local light = Instance.new("PointLight")
	light.Color = CORROSIVE_COLOR
	light.Brightness = 0
	light.Range = 10
	light.Parent = boil

	-- Memposisikannya secara acak di tubuh
	local randomCFrame = torso.CFrame * CFrame.new(
		math.random(-torso.Size.X / 2, torso.Size.X / 2),
		math.random(-torso.Size.Y / 2, torso.Size.Y / 2),
		-torso.Size.Z / 2
	)
	boil.CFrame = randomCFrame

	-- Menggunakan WeldConstraint agar menempel pada bos
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = boil
	weld.Parent = boil

	-- Tween untuk grow and pulse
	local growInfo = TweenInfo.new(TELEGRAPH_DURATION * 0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local pulseInfo = TweenInfo.new(TELEGRAPH_DURATION * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local goalsGrow = {
		Size = Vector3.new(4, 4, 4),
		Transparency = 0,
	}
	local goalsPulse = {
		Size = Vector3.new(5, 5, 5),
	}

	TweenService:Create(boil, growInfo, goalsGrow):Play()
	TweenService:Create(light, growInfo, { Brightness = 10, Range = 25 }):Play()

	-- Pulse effect
	task.delay(TELEGRAPH_DURATION * 0.7, function()
		TweenService:Create(boil, pulseInfo, goalsPulse):Play()
	end)

	-- Menjadwalkan penghapusan otomatis
	Debris:AddItem(boil, TELEGRAPH_DURATION)
end

-- Fungsi untuk menampilkan efek kemunculan Corrosive Birthing Pod
function VolatileMinionVFX.PlaySpawn(startPosition, endPosition)
	-- Launch phase: Projectile pod with dripping particles
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = CORROSIVE_COLOR
	projectile.Size = Vector3.new(1.5, 2.5, 1.5) -- Pod shape
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.Position = startPosition
	projectile.Parent = workspace

	-- Drip particles during flight
	local dripEmitter = Instance.new("ParticleEmitter")
	dripEmitter.Color = ColorSequence.new(CORROSIVE_COLOR)
	dripEmitter.LightEmission = 0.8
	dripEmitter.Size = NumberSequence.new(0.2, 0.5)
	dripEmitter.Transparency = NumberSequence.new(0, 1)
	dripEmitter.Lifetime = NumberRange.new(0.5, 1.0)
	dripEmitter.Speed = NumberRange.new(5, 10)
	dripEmitter.EmissionDirection = Enum.NormalId.Bottom
	dripEmitter.Shape = Enum.ParticleEmitterShape.Sphere
	dripEmitter.Rate = DRIP_RATE
	dripEmitter.Parent = projectile

	-- Tween untuk launch
	local launchTween = TweenService:Create(projectile, TweenInfo.new(LAUNCH_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = endPosition })
	launchTween:Play()

	-- Impact phase after launch
	task.delay(LAUNCH_DURATION, function()
		-- Splash particles
		local splashPart = Instance.new("Part")
		splashPart.Size = Vector3.new(0.1, 0.1, 0.1)
		splashPart.Position = endPosition
		splashPart.Anchored = true
		splashPart.CanCollide = false
		splashPart.Transparency = 1
		splashPart.Parent = workspace

		local splashEmitter = Instance.new("ParticleEmitter")
		splashEmitter.Color = ColorSequence.new(CORROSIVE_COLOR)
		splashEmitter.LightEmission = 1
		splashEmitter.Size = NumberSequence.new(0.3, 0.8)
		splashEmitter.Transparency = NumberSequence.new(0, 1)
		splashEmitter.Lifetime = NumberRange.new(0.3, 0.8)
		splashEmitter.Speed = NumberRange.new(10, 25)
		splashEmitter.EmissionDirection = Enum.NormalId.Top
		splashEmitter.Shape = Enum.ParticleEmitterShape.Sphere
		splashEmitter.Parent = splashPart
		splashEmitter:Emit(SPLASH_PARTICLE_COUNT)
		Debris:AddItem(splashPart, 1.0)

		-- Birthing sac phase
		local sac = Instance.new("Part")
		sac.Shape = Enum.PartType.Ball
		sac.Material = Enum.Material.Neon
		sac.Color = CORROSIVE_COLOR
		sac.Size = Vector3.new(0.1, 0.05, 0.1)
		sac.Anchored = true
		sac.CanCollide = false
		sac.Transparency = 0.7
		sac.Position = endPosition + Vector3.new(0, 0.025, 0)
		sac.Parent = workspace

		local sacLight = Instance.new("PointLight")
		sacLight.Color = CORROSIVE_COLOR
		sacLight.Brightness = 5
		sacLight.Range = 15
		sacLight.Parent = sac

		-- Inflate and burst animation
		local inflateTween = TweenService:Create(sac, TweenInfo.new(IMPACT_DURATION * 0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = Vector3.new(8, 4, 8),
			Transparency = 0.2
		})
		inflateTween:Play()

		task.delay(IMPACT_DURATION * 0.8, function()
			local burstTween = TweenService:Create(sac, TweenInfo.new(IMPACT_DURATION * 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = Vector3.new(0.1, 0.1, 0.1),
				Transparency = 1
			})
			burstTween:Play()
			Debris:AddItem(sac, IMPACT_DURATION * 0.2)
		end)

	end)

	Debris:AddItem(projectile, LAUNCH_DURATION + 0.1)
end

return VolatileMinionVFX
