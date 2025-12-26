-- EarthVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/EarthVFXModule.lua
-- Script Place: ACT 1: Village

local EarthVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Constants for VFX visuals
local EARTH_COLOR_PRIMARY = Color3.fromRGB(80, 60, 50) -- Dark brown
local EARTH_COLOR_SECONDARY = Color3.fromRGB(110, 90, 80) -- Lighter earthy tone
local EARTH_MATERIAL = Enum.Material.Slate
local NEON_MATERIAL = Enum.Material.Neon

local function _ensureEarthFolder(char)
	local f = char:FindFirstChild("EarthVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "EarthVFX"
		f.Parent = char
	end
	return f
end

-- Helper to create a "jagged" rock part
local function createRockPart(size, color, material)
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color or EARTH_COLOR_PRIMARY
	part.Material = material or EARTH_MATERIAL
	part.CanCollide = false
	part.Massless = true
	part.Anchored = true
	part.CastShadow = false
	return part
end

function EarthVFX.SpawnForPlayer(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Cleanup old VFX
	local old = char:FindFirstChild("EarthVFX")
	if old then old:Destroy() end

	local folder = _ensureEarthFolder(char)

	-- 1. Ground Ring (The foundation)
	local groundRing = Instance.new("Part")
	groundRing.Name = "GroundRing"
	groundRing.Shape = Enum.PartType.Cylinder
	groundRing.Color = EARTH_COLOR_PRIMARY
	groundRing.Material = EARTH_MATERIAL
	groundRing.Transparency = 0.8
	groundRing.Size = Vector3.new(0.5, 8, 8) -- Height is X for Cylinder
	groundRing.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.pi/2)
	groundRing.Anchored = true
	groundRing.CanCollide = false
	groundRing.Parent = folder

	-- 2. Floating Rocks (Orbiting Shield)
	local numRocks = 4
	local rocks = {}

	for i = 1, numRocks do
		local rock = createRockPart(Vector3.new(1.5, 2, 1.5), EARTH_COLOR_SECONDARY, EARTH_MATERIAL)
		rock.Name = "OrbitRock_" .. i
		rock.Parent = folder
		table.insert(rocks, {part = rock, angle = (i/numRocks) * math.pi * 2, speed = 0.5 + (math.random() * 0.5), yOffset = math.random(-1, 1) * 0.5})
	end

	-- 3. Dust/Debris Particles (Attached to HRP)
	local dustEmitter = Instance.new("ParticleEmitter")
	dustEmitter.Name = "EarthDust"
	dustEmitter.Texture = "" -- Default texture
	dustEmitter.Color = ColorSequence.new(EARTH_COLOR_SECONDARY)
	dustEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 2)
	})
	dustEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	dustEmitter.Lifetime = NumberRange.new(1, 2)
	dustEmitter.Rate = 10
	dustEmitter.Speed = NumberRange.new(2, 4)
	dustEmitter.SpreadAngle = Vector2.new(180, 0) -- Flat horizontal spread
	dustEmitter.Drag = 1
	dustEmitter.Parent = groundRing

	-- Animate the aura
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not char.Parent or not folder.Parent then
			connection:Disconnect()
			return
		end

		-- Keep ring at feet
		groundRing.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.pi/2)

		-- Orbit rocks
		for _, rockData in ipairs(rocks) do
			rockData.angle = rockData.angle + (dt * rockData.speed)
			local radius = 5
			local x = math.cos(rockData.angle) * radius
			local z = math.sin(rockData.angle) * radius
			local bob = math.sin(os.clock() * 2 + rockData.angle) * 0.5 -- Vertical bobbing

			rockData.part.CFrame = hrp.CFrame * CFrame.new(x, bob + rockData.yOffset, z) 
				* CFrame.Angles(os.clock(), os.clock() * 0.5, 0) -- Tumble rotation
		end
	end)

	-- Store connection in folder to clean up later if needed (optional, but good practice)
	-- For simplicity here, we rely on parent check inside Heartbeat.
end

function EarthVFX.RemoveForPlayer(player)
	local char = player.Character
	if not char then return end
	local f = char:FindFirstChild("EarthVFX")
	if f then f:Destroy() end
end

function EarthVFX.SpawnImpact(part, life)
	-- No hit effect for Earth element as it is purely defensive/aura based.
end

function EarthVFX.SpawnDefenseEffect(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- 1. Create a transient rock shield sphere
	local shield = Instance.new("Part")
	shield.Name = "EarthDefenseShield"
	shield.Shape = Enum.PartType.Ball
	shield.Size = Vector3.new(6, 6, 6)
	shield.Color = EARTH_COLOR_SECONDARY
	shield.Material = Enum.Material.ForceField -- Use ForceField to show "energy" + "rock" color
	shield.Transparency = 0 -- Start visible
	shield.Anchored = true
	shield.CanCollide = false
	shield.CFrame = hrp.CFrame
	shield.Parent = workspace

	-- Tween it out (Flash effect)
	local tween = TweenService:Create(shield, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(7, 7, 7)
	})
	tween:Play()
	Debris:AddItem(shield, 0.5)

	-- 2. Spawn some defensive rocks popping up briefly
	local numRocks = 3
	for i = 1, numRocks do
		local angle = math.rad(math.random(0, 360))
		local offset = Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
		local rock = createRockPart(Vector3.new(1, 2, 1), EARTH_COLOR_PRIMARY, EARTH_MATERIAL)
		rock.CFrame = hrp.CFrame * CFrame.new(offset) * CFrame.new(0, -2, 0) -- Start below ground
		rock.Parent = workspace

		-- Pop up
		local upTween = TweenService:Create(rock, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = rock.CFrame * CFrame.new(0, 2, 0)
		})
		upTween:Play()

		-- Fade down
		task.delay(0.3, function()
			if rock.Parent then
				TweenService:Create(rock, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = rock.CFrame * CFrame.new(0, -2, 0),
					Transparency = 1
				}):Play()
			end
		end)
		Debris:AddItem(rock, 0.6)
	end

	-- 3. Sound
	EarthVFX.PlaySoundAt(hrp)
end

function EarthVFX.PlaySoundAt(part)
	if not part then return end
	-- Use existing AudioManager but maybe we can tweak params if needed
	local sound = AudioManager.playSound("Elements.Earth", part, {
		Name = "EarthSFX",
		Volume = 1.0, -- Increased volume for impact
		PlaybackSpeed = 0.8 + (math.random() * 0.4), -- Varied pitch
		RollOffMaxDistance = 50
	})
	if sound then
		Debris:AddItem(sound, 3)
	end
end

return EarthVFX
