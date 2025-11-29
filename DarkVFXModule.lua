-- DarkVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/DarkVFXModule.lua
-- Script Place: ACT 1: Village

local DarkVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local AudioManager = require(ModuleScriptReplicatedStorage:WaitForChild("AudioManager"))

-- Constants for Dark VFX
local DARK_COLOR_PRIMARY = Color3.fromRGB(20, 0, 30) -- Deepest purple/black
local DARK_COLOR_SECONDARY = Color3.fromRGB(80, 20, 120) -- Neon purple for edges
local VOID_MATERIAL = Enum.Material.Neon
local SHARD_MATERIAL = Enum.Material.Glass

local function _ensureDarkFolder(char)
	local f = char:FindFirstChild("DarkVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "DarkVFX"
		f.Parent = char
	end
	return f
end

function DarkVFX.SpawnImpact(part, life)
	if not part then return end
	local position = part.Position

	-- 1. Singularity (Implosion)
	local singularity = Instance.new("Part")
	singularity.Name = "DarkSingularity"
	singularity.Shape = Enum.PartType.Ball
	singularity.Size = Vector3.new(12, 12, 12) -- Start big
	singularity.Color = Color3.new(0, 0, 0) -- Pure black
	singularity.Material = VOID_MATERIAL
	singularity.Transparency = 0.2
	singularity.Anchored = true
	singularity.CanCollide = false
	singularity.CFrame = part.CFrame
	singularity.Parent = workspace

	-- Implosion Tween (Shrink rapidly)
	local shrinkTween = TweenService:Create(singularity, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = Vector3.new(0.5, 0.5, 0.5),
		Transparency = 0
	})
	shrinkTween:Play()

	task.delay(0.2, function()
		if not singularity.Parent then return end
		-- 2. Explosion (Burst)
		-- Change color to purple for explosion
		singularity.Color = DARK_COLOR_SECONDARY
		singularity.Material = VOID_MATERIAL

		local burstTween = TweenService:Create(singularity, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Size = Vector3.new(8, 8, 8),
			Transparency = 0.8
		})
		burstTween:Play()

		-- 3. Shockwave Ring
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.5, 1, 1)
		ring.Color = DARK_COLOR_SECONDARY
		ring.Material = VOID_MATERIAL
		ring.Transparency = 0.5
		ring.Anchored = true
		ring.CanCollide = false
		ring.CFrame = part.CFrame * CFrame.Angles(0, 0, math.pi/2)
		ring.Parent = workspace

		local ringTween = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.5, 25, 25),
			Transparency = 1
		})
		ringTween:Play()
		Debris:AddItem(ring, 0.5)

		-- 4. Particles (Void Motes)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "VoidMotes"
		emitter.Texture = "" -- Default
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, DARK_COLOR_SECONDARY),
			ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
		})
		emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Speed = NumberRange.new(10, 20)
		emitter.SpreadAngle = Vector2.new(360, 360)
		emitter.Rate = 0
		emitter.Parent = singularity

		emitter:Emit(30)

		-- Cleanup singularity
		task.delay(0.5, function()
			if singularity.Parent then
				TweenService:Create(singularity, TweenInfo.new(0.3), {Transparency = 1, Size = Vector3.new(0,0,0)}):Play()
				Debris:AddItem(singularity, 0.3)
			end
		end)
	end)
end

function DarkVFX.SpawnLifestealVFX(sourceModel, targetCharacter, amount)
	if not (sourceModel and targetCharacter) then return end
	local srcPart = sourceModel.PrimaryPart or sourceModel:FindFirstChild("HumanoidRootPart")
	local tgtPart = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not (srcPart and tgtPart) then return end

	-- Create a trail of "souls" flowing from source(enemy) to target(player)
	local soul = Instance.new("Part")
	soul.Size = Vector3.new(1, 1, 1)
	soul.Shape = Enum.PartType.Ball
	soul.Color = DARK_COLOR_SECONDARY
	soul.Material = VOID_MATERIAL
	soul.Transparency = 0.5
	soul.Anchored = true
	soul.CanCollide = false
	soul.CFrame = srcPart.CFrame
	soul.Parent = workspace

	-- Trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = Instance.new("Attachment", soul)
	trail.Attachment0.Position = Vector3.new(0, 0.5, 0)
	trail.Attachment1 = Instance.new("Attachment", soul)
	trail.Attachment1.Position = Vector3.new(0, -0.5, 0)
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(DARK_COLOR_SECONDARY, Color3.new(0,0,0))
	trail.Lifetime = 0.3
	trail.Transparency = NumberSequence.new(0.5, 1)
	trail.Parent = soul

	-- Tween travel
	local dist = (tgtPart.Position - srcPart.Position).Magnitude
	local travelTime = math.clamp(dist / 40, 0.2, 0.5)

	local tween = TweenService:Create(soul, TweenInfo.new(travelTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = tgtPart.CFrame
	})
	tween:Play()

	-- On arrival, heal effect on player
	task.delay(travelTime, function()
		if soul.Parent then
			soul:Destroy()

			-- Heal flash on player
			local healFlash = Instance.new("Part")
			healFlash.Shape = Enum.PartType.Ball
			healFlash.Size = Vector3.new(4, 4, 4)
			healFlash.Color = Color3.fromRGB(0, 255, 100) -- Greenish tint for healing mixed with dark? No, keep dark theme -> Purple heal
			healFlash.Color = DARK_COLOR_SECONDARY
			healFlash.Material = VOID_MATERIAL
			healFlash.Anchored = true
			healFlash.CanCollide = false
			healFlash.CFrame = tgtPart.CFrame
			healFlash.Transparency = 0.5
			healFlash.Parent = workspace

			TweenService:Create(healFlash, TweenInfo.new(0.3), {Size = Vector3.new(2,2,2), Transparency = 1}):Play()
			Debris:AddItem(healFlash, 0.3)
		end
	end)
end

function DarkVFX.SpawnForPlayer(player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Cleanup old
	local old = char:FindFirstChild("DarkVFX")
	if old then old:Destroy() end

	local folder = _ensureDarkFolder(char)

	-- 1. Void Vortex (Ground)
	local vortex = Instance.new("Part")
	vortex.Name = "VoidVortex"
	vortex.Shape = Enum.PartType.Cylinder
	vortex.Color = Color3.new(0, 0, 0)
	vortex.Material = VOID_MATERIAL
	vortex.Transparency = 0.2
	vortex.Size = Vector3.new(0.2, 8, 8) -- Height X
	vortex.Anchored = true
	vortex.CanCollide = false
	vortex.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.pi/2)
	vortex.Parent = folder

	-- 2. Void Shards (Orbiting)
	local shards = {}
	local numShards = 5
	for i = 1, numShards do
		local shard = Instance.new("Part")
		shard.Name = "VoidShard"
		shard.Shape = Enum.PartType.Block -- We'll use Block but scaled thin
		shard.Size = Vector3.new(0.5, 2, 0.5)
		shard.Color = DARK_COLOR_PRIMARY
		shard.Material = SHARD_MATERIAL
		shard.Reflectance = 0.5
		shard.Anchored = true
		shard.CanCollide = false
		shard.Parent = folder

		-- Add neon edge (SelectionBox hack for wireframe look? No, just use Highlight or another Part. Let's keep it simple: Highlight)
		local hl = Instance.new("Highlight")
		hl.Adornee = shard
		hl.FillTransparency = 1
		hl.OutlineColor = DARK_COLOR_SECONDARY
		hl.Parent = shard

		table.insert(shards, {
			part = shard,
			angle = (i/numShards) * math.pi * 2,
			radius = 4 + math.random(),
			speed = 2 + math.random(),
			yOffset = math.random(-1, 2)
		})
	end

	-- Animation Loop
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not char.Parent or not folder.Parent then
			connection:Disconnect()
			return
		end

		local t = os.clock()

		-- Vortex spin
		vortex.CFrame = hrp.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, t, math.pi/2)

		-- Shard orbit
		for _, data in ipairs(shards) do
			data.angle = data.angle + (dt * data.speed)
			local x = math.cos(data.angle) * data.radius
			local z = math.sin(data.angle) * data.radius
			local y = math.sin(t * 2 + data.angle) * 0.5 + data.yOffset

			-- Erratic rotation
			local rot = CFrame.Angles(t * 2, t, t * 1.5)

			data.part.CFrame = hrp.CFrame * CFrame.new(x, y, z) * rot
		end
	end)
end

function DarkVFX.RemoveForPlayer(player)
	local char = player.Character
	if not char then return end
	local f = char:FindFirstChild("DarkVFX")
	if f then f:Destroy() end
end

function DarkVFX.PlaySoundAt(part)
	if not part then return end
	local sound = AudioManager.playSound("Elements.Dark", part, {
		Name = "DarkSFX",
		Volume = 1.0,
		PlaybackSpeed = 0.6, -- Low pitch for "heavy" sound
		RollOffMaxDistance = 60
	})
	if sound then
		Debris:AddItem(sound, 5)
	end
end

return DarkVFX
