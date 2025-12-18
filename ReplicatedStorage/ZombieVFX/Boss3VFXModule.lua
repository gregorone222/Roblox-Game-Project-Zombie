-- Boss3VFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss3VFXModule.lua
-- Script Place: ACT 1: Village

local Boss3VFXModule = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import the specialized Syringe Volley VFX module
local SyringeVolleyVFX = require(ReplicatedStorage.ZombieVFX:WaitForChild("SyringeVolleyVFX"))

-- === FUNGSI VFX BARU UNTUK BOSS 3 V2 ===
-- === FUNGSI VFX BARU UNTUK THE BLIGHTED ALCHEMIST ===

function Boss3VFXModule.CreateMovementTransition(bossModel, movementName)
	local color = Color3.fromRGB(255, 255, 255)
	-- Warna baru yang sesuai dengan tema Alchemist
	if movementName == "Volatile Formula" then
		color = Color3.fromRGB(170, 255, 0) -- Hijau Asam Terang
	elseif movementName == "Debilitating Formula" then
		color = Color3.fromRGB(130, 0, 255)   -- Ungu Racun Pekat
	elseif movementName == "Terminal Formula" then
		color = Color3.fromRGB(200, 50, 20)   -- Merah Bahaya Gelap
	end

	local shockwave = Instance.new("Part")
	shockwave.Size = Vector3.new(0.5, 1, 1)
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.CFrame = CFrame.new(bossModel.PrimaryPart.Position) * CFrame.Angles(0,0,math.rad(90))
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Material = Enum.Material.Neon
	shockwave.Color = color
	shockwave.Parent = Workspace

	local duration = 1.5
	local expandTween = TweenService:Create(shockwave, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = Vector3.new(0.5, 200, 200), Transparency = 1})
	expandTween:Play()
	Debris:AddItem(shockwave, duration)
end

-- Wrapper function for syringe volley that delegates to the specialized module
function Boss3VFXModule.FireSyringeVolley(bossPosition, targetPosition, config)
	return SyringeVolleyVFX.FireSyringeVolley(bossPosition, targetPosition, config)
end

-- Legacy function for backward compatibility (delegates to specialized module)
function Boss3VFXModule.CreateSyringeVolleyProjectile(startPos, direction, config)
	return SyringeVolleyVFX.CreateSyringeVolleyProjectile(startPos, direction, config)
end

function Boss3VFXModule.CreateUnstableVialsTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.Radius * 2, config.Radius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
	telegraph.Anchored = true
	telegraph.CanCollide = false
	telegraph.Material = Enum.Material.ForceField
	telegraph.Color = Color3.fromRGB(170, 255, 0) -- Hijau Asam
	telegraph.Transparency = 0.5
	telegraph.Parent = Workspace
	Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss3VFXModule.CreateCausticCatalystTelegraph(position, config)
	local telegraph = Instance.new("Part")
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
	telegraph.Anchored = true
	telegraph.CanCollide = false
	telegraph.Material = Enum.Material.ForceField
	telegraph.Color = Color3.fromRGB(130, 0, 255) -- Ungu Racun
	telegraph.Transparency = 0.5
	telegraph.Parent = Workspace
	Debris:AddItem(telegraph, config.TelegraphDuration)
end

function Boss3VFXModule.ExecuteCausticCatalyst(position, config)
	local puddle = Instance.new("Part")
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Size = Vector3.new(0.5, config.BlastRadius * 2, config.BlastRadius * 2)
	puddle.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.Material = Enum.Material.Neon
	puddle.Color = Color3.fromRGB(130, 0, 255) -- Ungu Racun
	puddle.Transparency = 0.6

	local smoke = Instance.new("Smoke", puddle)
	smoke.Color = Color3.fromRGB(150, 50, 255)
	smoke.Opacity = 0.3
	smoke.Size = 8

	puddle.Parent = Workspace
	Debris:AddItem(puddle, config.PuddleDuration)
end

function Boss3VFXModule.CreateSymbioticLink(player1, player2, config)
	local p1Attach = Instance.new("Attachment", player1.Character.HumanoidRootPart)
	local p2Attach = Instance.new("Attachment", player2.Character.HumanoidRootPart)

	local chain = Instance.new("Beam")
	chain.Attachment0 = p1Attach
	chain.Attachment1 = p2Attach
	chain.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
	chain.Width0 = 1
	chain.Width1 = 1
	chain.Segments = 10
	chain.Parent = player1.Character.HumanoidRootPart

	Debris:AddItem(chain, config.Duration)
	Debris:AddItem(p1Attach, config.Duration)
	Debris:AddItem(p2Attach, config.Duration)
	return chain
end

function Boss3VFXModule.CreatePlagueBombTelegraph(bossModel, config)
	local pillars = Workspace:FindFirstChild("ArenaPillars") -- Assuming pillars are grouped
	if not pillars then return nil end

	local safePillar = pillars:GetChildren()[math.random(#pillars:GetChildren())]

	for _, pillar in ipairs(pillars:GetChildren()) do
		local light = Instance.new("SpotLight", pillar)
		light.Range = 200
		light.Angle = 180
		if pillar == safePillar then
			light.Color = Color3.fromRGB(0, 255, 255) -- Cyan for safe zone
		else
			light.Color = Color3.fromRGB(200, 50, 20) -- Red danger
		end
		Debris:AddItem(light, config.ChargeDuration)
	end

	return safePillar
end

function Boss3VFXModule.ExecutePlagueBomb(bossModel, safePillar, config)
	local gasCloud = Instance.new("Part")
	gasCloud.Shape = Enum.PartType.Ball
	gasCloud.Size = Vector3.new(1, 1, 1)
	gasCloud.Position = bossModel.PrimaryPart.Position
	gasCloud.Material = Enum.Material.ForceField
	gasCloud.Color = Color3.fromRGB(200, 50, 20)
	gasCloud.Anchored = true
	gasCloud.CanCollide = false
	gasCloud.Transparency = 0.8
	gasCloud.Parent = Workspace

	local tween = TweenService:Create(gasCloud, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = Vector3.new(500, 500, 500), Transparency = 1})
	tween:Play()
	Debris:AddItem(gasCloud, 2)
end

return Boss3VFXModule
