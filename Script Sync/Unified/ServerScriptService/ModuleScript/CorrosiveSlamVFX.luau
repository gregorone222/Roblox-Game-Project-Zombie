-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- CorrosiveSlamVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CorrosiveSlamVFX.lua
-- Script Place: ACT 1: Village

local CorrosiveSlamVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VFX_FOLDER_NAME = "VFX_CorrosiveSlam"

-- Color Palette
local COLORS = {
	Core = Color3.fromHex("ecfccb"),   -- Almost white green
	Mid = Color3.fromHex("84cc16"),    -- Lime
	Dark = Color3.fromHex("3f6212"),   -- Dark swamp
	Glow = Color3.fromHex("a3e635")    -- Neon Glow
}

local function getVfxFolder()
	local folder = workspace:FindFirstChild(VFX_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder", workspace)
		folder.Name = VFX_FOLDER_NAME
	end
	return folder
end

-- Utility: Create a jagged path using Beams
-- CHANGED: Now accepts a parent Model and creates relative positions (since we will move the model)
local function createJaggedCrack(parentModel, angle, length, duration)
	-- Determine "Root" position based on current Parent Model PrimaryPart
	-- But since we are parenting to the Model, and the Model's PrimaryPart is at (0,0,0) relative to itself?
	-- No, we just parent parts to the Model. If we move the Model via SetPrimaryPartCFrame, all parts move.

	-- We assume the crack starts at the center of the Model (RootPart)
	local origin = parentModel.PrimaryPart.Position

	local numSegments = 5
	local segmentLength = length / numSegments

	local currentPos = origin

	-- Root Attachment for this crack branch
	local branchRoot = Instance.new("Part")
	branchRoot.Transparency = 1
	branchRoot.Anchored = true -- Needs to be anchored to move with SetPrimaryPartCFrame? 
	-- Actually, if we use SetPrimaryPartCFrame on the Model, ALL parts inside should be moved.
	-- If parts are Anchored, SetPrimaryPartCFrame WILL move them if they are part of the assembly or just children?
	-- Roblox Model:SetPrimaryPartCFrame moves all parts in the model, maintaining relative offsets, even if Anchored.
	branchRoot.CanCollide = false
	branchRoot.Size = Vector3.new(0.1, 0.1, 0.1)
	branchRoot.Position = currentPos
	branchRoot.Parent = parentModel
	-- No Debris here, parent model handles lifetime

	local lastAtt = Instance.new("Attachment", branchRoot)

	for i = 1, numSegments do
		local segmentAngle = angle + (math.random() - 0.5) * 1 -- Jitter angle
		local nextX = currentPos.X + math.cos(segmentAngle) * segmentLength
		local nextZ = currentPos.Z + math.sin(segmentAngle) * segmentLength
		local nextPos = Vector3.new(nextX, origin.Y, nextZ)

		local p = Instance.new("Part")
		p.Transparency = 1
		p.Anchored = true
		p.CanCollide = false
		p.Size = Vector3.new(0.1, 0.1, 0.1)
		p.Position = nextPos
		p.Parent = parentModel

		local nextAtt = Instance.new("Attachment", p)

		local beam = Instance.new("Beam")
		beam.Attachment0 = lastAtt
		beam.Attachment1 = nextAtt
		beam.Color = ColorSequence.new(COLORS.Glow)
		beam.Width0 = 0.5
		beam.Width1 = 0.5
		beam.FaceCamera = true
		beam.Parent = branchRoot -- Attach beam to branch root to keep organized

		-- Animate Beam appearing
		beam.Width0 = 0
		beam.Width1 = 0
		local tween = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Width0 = 0.3 + (math.random() * 0.2), 
			Width1 = 0.1
		})
		tween:Play()

		lastAtt = nextAtt
		currentPos = nextPos
	end
end

-- Utility: Create BillboardGui Text Particle
local function createTextParticle(position, text, color, size, lifetime, velocityY, parent)
	local p = Instance.new("Part")
	p.Transparency = 1
	p.Anchored = false
	p.CanCollide = false
	p.Size = Vector3.new(0.1, 0.1, 0.1)
	p.Position = position
	p.Parent = parent

	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(size, 0, size, 0)
	bg.Adornee = p
	bg.AlwaysOnTop = true
	bg.Parent = p

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = bg

	-- Physics
	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(100, 100, 100)
	bodyVel.Velocity = Vector3.new((math.random()-0.5)*2, velocityY, (math.random()-0.5)*2)
	bodyVel.Parent = p

	Debris:AddItem(p, lifetime)

	-- Fade out
	local tween = TweenService:Create(label, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {TextTransparency = 1})
	tween:Play()
end

-- Utility: Create Splash Particle (Part)
local function createSplashParticle(position, color, parent)
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.Shape = Enum.PartType.Ball
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Position = position
	p.CanCollide = true
	p.Parent = parent

	local vec = Vector3.new((math.random()-0.5)*30, math.random(20, 40), (math.random()-0.5)*30)
	p.AssemblyLinearVelocity = vec

	Debris:AddItem(p, 2)
end

-- === PUBLIC API ===

function CorrosiveSlamVFX.createTelegraph(bossModel, config)
	local vfxFolder = getVfxFolder()

	-- Determine Initial Ground Position via Raycast
	local bossPos = bossModel.PrimaryPart.Position
	local rayOrigin = bossPos + Vector3.new(0, 5, 0)
	local rayDir = Vector3.new(0, -50, 0)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {bossModel, vfxFolder}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local res = workspace:Raycast(rayOrigin, rayDir, params)
	local groundPos = res and res.Position or (bossPos - Vector3.new(0, 2.5, 0))

	-- Create Main Model Container
	local telegraphModel = Instance.new("Model")
	telegraphModel.Name = "TelegraphModel"
	telegraphModel.Parent = vfxFolder
	Debris:AddItem(telegraphModel, config.TelegraphDuration + 2) -- Cleanup backup

	-- Create Root Part for Model
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Size = Vector3.new(1, 1, 1)
	root.Position = groundPos
	root.Parent = telegraphModel
	telegraphModel.PrimaryPart = root

	local telegraphAssets = {
		model = telegraphModel,
		updateConn = nil
	}

	-- Generate Cracks (inside the model)
	local numCracks = 8
	local radius = config.Radius or 20

	for i = 1, numCracks do
		local angle = (i / numCracks) * math.pi * 2
		createJaggedCrack(telegraphModel, angle, radius, config.TelegraphDuration)
	end

	-- Update Loop: Follow Boss
	telegraphAssets.updateConn = RunService.Heartbeat:Connect(function()
		if not bossModel or not bossModel.Parent or not bossModel.PrimaryPart then
			if telegraphAssets.updateConn then telegraphAssets.updateConn:Disconnect() end
			return
		end

		-- Raycast every frame to find ground under boss
		local currPos = bossModel.PrimaryPart.Position
		local rOrigin = currPos + Vector3.new(0, 5, 0)
		local hit = workspace:Raycast(rOrigin, rayDir, params)
		local targetPos = hit and hit.Position or (currPos - Vector3.new(0, 2.5, 0))

		if telegraphModel and telegraphModel.PrimaryPart then
			telegraphModel:PivotTo(CFrame.new(targetPos))
		else
			if telegraphAssets.updateConn then telegraphAssets.updateConn:Disconnect() end
		end
	end)

	return telegraphAssets
end

function CorrosiveSlamVFX.triggerImpact(bossModel, config, telegraphAssets)
	local vfxFolder = getVfxFolder()

	-- Stop Following
	if telegraphAssets and telegraphAssets.updateConn then
		telegraphAssets.updateConn:Disconnect()
	end

	-- Cleanup Telegraph Visuals
	if telegraphAssets and telegraphAssets.model then
		telegraphAssets.model:Destroy()
	end

	-- Determine Final Impact Position (Static)
	local bossPos = bossModel.PrimaryPart.Position
	local rayOrigin = bossPos + Vector3.new(0, 5, 0)
	local rayDir = Vector3.new(0, -50, 0)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {bossModel, vfxFolder}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local res = workspace:Raycast(rayOrigin, rayDir, params)
	local groundPos = res and res.Position or (bossPos - Vector3.new(0, 2.5, 0))

	-- 1. Shockwave (Expanding Cylinder)
	local shockwave = Instance.new("Part")
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Shape = Enum.PartType.Cylinder
	-- Cylinder orientation is sideways by default, need to rotate
	shockwave.CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.pi/2)
	shockwave.Size = Vector3.new(1, 1, 1) -- Height(X), Radius(Y), Radius(Z)
	shockwave.Color = COLORS.Mid
	shockwave.Material = Enum.Material.Neon
	shockwave.Parent = vfxFolder

	local targetSize = config.Radius * 2
	local swTween = TweenService:Create(shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(1, targetSize, targetSize),
		Transparency = 1
	})
	swTween:Play()
	Debris:AddItem(shockwave, 0.5)

	-- 2. Puddle (Growing Flat Cylinder)
	local puddle = Instance.new("Part")
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.Shape = Enum.PartType.Cylinder
	puddle.CFrame = CFrame.new(groundPos) * CFrame.Angles(0, 0, math.pi/2)
	puddle.Size = Vector3.new(0.2, 1, 1)
	puddle.Color = COLORS.Dark
	puddle.Material = Enum.Material.SmoothPlastic
	puddle.Parent = vfxFolder

	local puddleTween = TweenService:Create(puddle, TweenInfo.new(1.0, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, targetSize * 0.8, targetSize * 0.8)
	})
	puddleTween:Play()

	-- Fade out puddle after some time (simulating cleanup or long duration)
	task.delay(3, function()
		if puddle.Parent then
			TweenService:Create(puddle, TweenInfo.new(1), {Transparency = 1}):Play()
			Debris:AddItem(puddle, 1)
		end
	end)

	-- 3. Splash Particles (Parts)
	for i = 1, 30 do
		createSplashParticle(groundPos, COLORS.Mid, vfxFolder)
	end

	-- 4. Gas & Bubbles (Unicode TextLabels)
	task.spawn(function()
		for i = 1, 10 do
			-- Gas
			local offset = Vector3.new((math.random()-0.5)*targetSize/2, 2, (math.random()-0.5)*targetSize/2)
			createTextParticle(groundPos + offset, "☁", COLORS.Dark, 4, 3, 2, vfxFolder)
			task.wait(0.1)
		end
	end)

	-- Bubbles loop
	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < 3 do -- Puddle duration approx
			if not puddle.Parent then break end
			local r = math.random() * (targetSize * 0.4) -- Radius
			local theta = math.random() * math.pi * 2
			local bx = groundPos.X + math.cos(theta) * r
			local bz = groundPos.Z + math.sin(theta) * r
			local bPos = Vector3.new(bx, groundPos.Y + 0.5, bz)

			createTextParticle(bPos, "●", COLORS.Glow, 2, 1, 1, vfxFolder)
			task.wait(0.2)
		end
	end)
end

return CorrosiveSlamVFX
