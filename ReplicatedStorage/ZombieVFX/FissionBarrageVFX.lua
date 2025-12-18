-- FissionBarrageVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/FissionBarrageVFX.lua
-- Script Place: ACT 1: Village
-- Deskripsi: Menangani efek visual untuk serangan Fission Barrage Boss 1.

local FissionBarrageVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local TELEGRAPH_COLOR = Color3.fromRGB(180, 255, 180)
local PROJECTILE_COLOR = Color3.fromRGB(220, 255, 220)
local PROJECTILE_SPEED = 200 -- Sangat cepat
local CHAIN_COLOR = Color3.fromRGB(255, 255, 255)

-- Fungsi untuk membuat peringatan di darat
function FissionBarrageVFX.CreateTelegraph(position, config)
	local telegraphPart = Instance.new("Part")
	telegraphPart.Shape = Enum.PartType.Cylinder
	telegraphPart.Size = Vector3.new(0.5, config.PuddleRadius * 2, config.PuddleRadius * 2)
	telegraphPart.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	telegraphPart.Anchored = true
	telegraphPart.CanCollide = false
	telegraphPart.Material = Enum.Material.ForceField
	telegraphPart.Color = TELEGRAPH_COLOR
	telegraphPart.Transparency = 1
	telegraphPart.Name = "FissionTelegraph"
	telegraphPart.Parent = Workspace

	local tweenInfo = TweenInfo.new(config.TelegraphDuration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeIn = TweenService:Create(telegraphPart, tweenInfo, {Transparency = 0.5})
	local fadeOut = TweenService:Create(telegraphPart, tweenInfo, {Transparency = 1})

	fadeIn:Play()
	fadeIn.Completed:Wait()
	fadeOut:Play()

	Debris:AddItem(telegraphPart, config.TelegraphDuration)
end

-- Fungsi BARU untuk visualisasi petir berantai
function FissionBarrageVFX.CreateChainLightning(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local lightning = Instance.new("Part")
	lightning.Size = Vector3.new(0.5, 0.5, distance)
	lightning.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	lightning.Material = Enum.Material.Neon
	lightning.Color = CHAIN_COLOR
	lightning.Anchored = true
	lightning.CanCollide = false
	lightning.Parent = Workspace

	local flash = Instance.new("PointLight", lightning)
	flash.Color = CHAIN_COLOR
	flash.Range = 25
	flash.Brightness = 10

	Debris:AddItem(lightning, 0.2)
end

-- Fungsi untuk menembakkan proyektil dan menangani ledakan
function FissionBarrageVFX.FireProjectile(startPosition, endPosition, config)
	local distance = (endPosition - startPosition).Magnitude
	local duration = distance / PROJECTILE_SPEED

	-- 1. Buat proyektil komet
	local projectile = Instance.new("Part")
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = PROJECTILE_COLOR
	projectile.Size = Vector3.new(2, 2, 4) -- Sedikit lonjong untuk tampilan "komet"
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CFrame = CFrame.new(startPosition, endPosition)
	projectile.Parent = Workspace

	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(PROJECTILE_COLOR)
	trail.Lifetime = 0.3
	trail.Attachment0 = Instance.new("Attachment", projectile)
	trail.Attachment1 = Instance.new("Attachment", projectile, {Position = Vector3.new(0, 0, -2)})
	trail.Parent = projectile

	local light = Instance.new("PointLight")
	light.Color = PROJECTILE_COLOR
	light.Range = 20
	light.Brightness = 5
	light.Parent = projectile

	-- 2. Luncurkan proyektil
	local projectileTween = TweenService:Create(projectile, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(endPosition, endPosition + (endPosition - startPosition).Unit)})
	projectileTween:Play()
	Debris:AddItem(projectile, duration)

	-- 3. Ledakan saat tumbukan (TANPA genangan asam)
	task.delay(duration, function()
		-- Kilatan cahaya
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Ball
		flash.Size = Vector3.new(config.PuddleRadius * 2, config.PuddleRadius * 2, config.PuddleRadius * 2)
		flash.CFrame = CFrame.new(endPosition)
		flash.Material = Enum.Material.Neon
		flash.Color = Color3.new(1, 1, 1)
		flash.Anchored = true
		flash.CanCollide = false
		flash.Parent = Workspace
		Debris:AddItem(flash, 0.2)
		TweenService:Create(flash, TweenInfo.new(0.2), {Transparency = 1}):Play()

		-- Percikan listrik
		local sparkPart = Instance.new("Part")
		sparkPart.Size = Vector3.new(1, 1, 1)
		sparkPart.CFrame = CFrame.new(endPosition)
		sparkPart.Anchored = true
		sparkPart.CanCollide = false
		sparkPart.Transparency = 1
		sparkPart.Parent = Workspace

		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(TELEGRAPH_COLOR)
		sparks.Size = NumberSequence.new(1, 0)
		sparks.Lifetime = NumberRange.new(0.3, 0.6)
		sparks.Speed = NumberRange.new(30, 50)
		sparks.Shape = Enum.ParticleEmitterShape.Sphere
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Rate = 0
		sparks.Parent = sparkPart
		sparks:Emit(50)
		Debris:AddItem(sparkPart, 1)
	end)
end

return FissionBarrageVFX
