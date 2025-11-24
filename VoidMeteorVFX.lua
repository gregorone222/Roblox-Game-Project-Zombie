-- VoidMeteorVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/VoidMeteorVFX.lua
-- Script Place: ACT 1: Village

local VoidMeteorVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FALL_HEIGHT = 150
local FALL_TIME = 1.2

function VoidMeteorVFX.createTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	-- Posisikan telegraph rata dengan tanah
	telegraph.CFrame = CFrame.new(position - Vector3.new(0, telegraph.Size.X / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	telegraph.Anchored = true
	telegraph.CanCollide = false
	telegraph.Material = Enum.Material.Neon
	telegraph.Color = Color3.fromRGB(150, 50, 200)
	telegraph.Name = "MeteorTelegraph"
	telegraph.Transparency = 0.5
	telegraph.Parent = Workspace

	-- Efek glowing hitam
	local light = Instance.new("PointLight", telegraph)
	light.Color = Color3.fromRGB(80, 0, 120)
	light.Brightness = 2
	light.Range = config.BlastRadius * 2.5

	-- Animate telegraph untuk berdenyut
	local tweenInfo = TweenInfo.new(config.TelegraphDuration / 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local originalSize = telegraph.Size
	local tween = TweenService:Create(telegraph, tweenInfo, {Size = originalSize * 1.1})
	tween:Play()

	Debris:AddItem(telegraph, config.TelegraphDuration)
end

function VoidMeteorVFX.launchMeteor(targetPosition, config)
	local startPosition = targetPosition + Vector3.new(0, FALL_HEIGHT, 0)

	-- 1. Portal di Langit (tidak berubah)
	local portal = Instance.new("Part")
	portal.Shape = Enum.PartType.Cylinder
	portal.Size = Vector3.new(0.2, config.BlastRadius * 1.5, config.BlastRadius * 1.5)
	portal.CFrame = CFrame.new(startPosition) * CFrame.Angles(0, 0, math.rad(90))
	portal.Anchored = true
	portal.CanCollide = false
	portal.Material = Enum.Material.ForceField
	portal.Color = Color3.fromRGB(100, 20, 150)
	portal.Parent = Workspace
	Debris:AddItem(portal, FALL_TIME + 0.5)

	-- 2. Meteor Projectile
	local meteor = Instance.new("Part")
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(config.BlastRadius, config.BlastRadius, config.BlastRadius)
	meteor.CFrame = CFrame.new(startPosition)
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.Material = Enum.Material.Basalt
	meteor.Color = Color3.fromRGB(20, 0, 30)
	meteor.Parent = Workspace

	-- EFEK BARU: Jejak Partikel (Trail)
	local trailEmitter = Instance.new("ParticleEmitter", meteor)
	trailEmitter.Color = ColorSequence.new(Color3.fromRGB(80, 0, 120), Color3.fromRGB(20, 0, 30))
	trailEmitter.LightEmission = 0.5
	trailEmitter.Size = NumberSequence.new(2, 5)
	trailEmitter.Texture = "rbxassetid://281329598" -- Smoke texture
	trailEmitter.Transparency = NumberSequence.new(0.6, 1)
	trailEmitter.Lifetime = NumberRange.new(0.5, 1)
	trailEmitter.Rate = 50
	trailEmitter.Speed = NumberRange.new(1, 3)
	trailEmitter.SpreadAngle = Vector2.new(360, 360)

	-- EFEK BARU: Cahaya pada meteor
	local meteorLight = Instance.new("PointLight", meteor)
	meteorLight.Color = Color3.fromRGB(150, 50, 200)
	meteorLight.Brightness = 3
	meteorLight.Range = config.BlastRadius * 4

	-- Animasi jatuh meteor (tidak berubah)
	local fallTweenInfo = TweenInfo.new(FALL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fallTween = TweenService:Create(meteor, fallTweenInfo, {Position = targetPosition})
	fallTween:Play()

	fallTween.Completed:Connect(function()
		meteor:Destroy() -- Hancurkan meteor asli

		-- 3. Ledakan Utama
		local explosionParticles = Instance.new("ParticleEmitter")
		explosionParticles.Color = ColorSequence.new(Color3.fromRGB(180, 80, 220), Color3.fromRGB(80, 0, 120))
		explosionParticles.LightEmission = 0.7
		explosionParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 4),
			NumberSequenceKeypoint.new(0.5, config.BlastRadius * 1.5),
			NumberSequenceKeypoint.new(1, config.BlastRadius * 0.5)
		})
		explosionParticles.Texture = "rbxassetid://2558989979" -- Explosion texture
		explosionParticles.Transparency = NumberSequence.new(0, 1)
		explosionParticles.Lifetime = NumberRange.new(0.4, 0.8)
		explosionParticles.Speed = NumberRange.new(20, 35)
		explosionParticles.SpreadAngle = Vector2.new(360, 360)
		explosionParticles.Parent = Workspace

		-- Emit partikel ledakan
		explosionParticles.Enabled = true
		explosionParticles:Emit(100)
		explosionParticles.Enabled = false

		local particleHost = Instance.new("Part", Workspace)
		particleHost.Anchored = true
		particleHost.CanCollide = false
		particleHost.Transparency = 1
		particleHost.Position = targetPosition
		explosionParticles.Parent = particleHost
		Debris:AddItem(particleHost, 2)

		-- EFEK BARU: Gelombang Kejut (Shockwave)
		local shockwave = Instance.new("Part")
		shockwave.Shape = Enum.PartType.Cylinder
		shockwave.Size = Vector3.new(0.2, 1, 1)
		shockwave.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, 0, math.rad(90))
		shockwave.Anchored = true
		shockwave.CanCollide = false
		shockwave.Material = Enum.Material.ForceField
		shockwave.Color = Color3.fromRGB(200, 150, 255)
		shockwave.Parent = Workspace

		local shockwaveTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local shockwaveTween = TweenService:Create(shockwave, shockwaveTweenInfo, {
			Size = Vector3.new(0.2, config.BlastRadius * 3, config.BlastRadius * 3),
			Transparency = 1
		})
		shockwaveTween:Play()
		Debris:AddItem(shockwave, 0.8)
	end)
end

return VoidMeteorVFX