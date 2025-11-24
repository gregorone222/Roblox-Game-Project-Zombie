-- Boss2VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss2VFXModule.lua
-- Script Place: ACT 1: Village

local Boss2VFXModule = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

function Boss2VFXModule.PlayWipeVFX(position)
	-- A large, dramatic explosion for the wipe mechanic
	local explosion = Instance.new("Part")
	explosion.Shape = Enum.PartType.Ball
	explosion.Size = Vector3.new(1, 1, 1)
	explosion.CFrame = CFrame.new(position)
	explosion.Anchored = true
	explosion.CanCollide = false
	explosion.Material = Enum.Material.Neon
	explosion.Color = Color3.fromRGB(255, 50, 50) -- Warna merah yang mengancam

	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(explosion, tweenInfo, {
		Size = Vector3.new(200, 200, 200), -- Ledakan masif
		Transparency = 1
	})
	tween:Play()

	explosion.Parent = Workspace
	Debris:AddItem(explosion, 1.6)

	-- Tambahkan partikel untuk dampak ekstra
	local burst = Instance.new("Part")
	burst.Size = Vector3.new(1,1,1)
	burst.CFrame = CFrame.new(position)
	burst.Anchored = true
	burst.CanCollide = false
	burst.Transparency = 1
	burst.Parent = Workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
	particles.Size = NumberSequence.new(5, 15)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Speed = NumberRange.new(50, 80)
	particles.Rate = 0
	particles.Parent = burst
	particles:Emit(2000)
	Debris:AddItem(burst, 3)
end

function Boss2VFXModule.DestroyPillar(platform)
	if not platform or not platform.Parent then return end

	local debrisCount = 20
	local explosionForce = 80
	local debrisLifetime = 3

	local center = platform.Position
	local size = platform.Size

	for i = 1, debrisCount do
		local debris = Instance.new("Part")
		debris.Material = Enum.Material.Basalt
		debris.Color = platform.Color
		debris.Size = Vector3.new(size.X / 4, size.Y / 4, size.Z / 4) + Vector3.new(math.random(), math.random(), math.random()) * 2
		debris.Position = center + Vector3.new(math.random(-size.X/4, size.X/4), math.random(-size.Y/2, size.Y/2), math.random(-size.Z/4, size.Z/4))

		debris.Anchored = false
		debris.CanCollide = false
		debris.Parent = Workspace

		local direction = (debris.Position - center).Unit + Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5)
		debris.AssemblyLinearVelocity = direction * explosionForce

		Debris:AddItem(debris, debrisLifetime)
	end

	platform:Destroy()
end

return Boss2VFXModule
