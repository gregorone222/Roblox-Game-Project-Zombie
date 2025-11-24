-- Boss2PhaseTransitionVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/Boss2PhaseTransitionVFX.lua
-- Script Place: ACT 1: Village

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local PhaseVFX = {}

-- Fungsi untuk efek debu saat pilar naik
local function createDustEffect(position, size)
	local dustEmitterPart = Instance.new("Part", Workspace)
	dustEmitterPart.Size = Vector3.new(size.X, 1, size.Z)
	dustEmitterPart.Position = position
	dustEmitterPart.Anchored = true
	dustEmitterPart.CanCollide = false
	dustEmitterPart.Transparency = 1

	local dustEmitter = Instance.new("ParticleEmitter", dustEmitterPart)
	dustEmitter.Color = ColorSequence.new(Color3.fromRGB(118, 106, 94))
	dustEmitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.7, 0.8), NumberSequenceKeypoint.new(1, 1)})
	dustEmitter.Size = NumberSequence.new(4, 10)
	dustEmitter.Lifetime = NumberRange.new(1.5, 2.5)
	dustEmitter.Speed = NumberRange.new(8, 15)
	dustEmitter.Rate = 0
	dustEmitter.Shape = Enum.ParticleEmitterShape.Cylinder
	dustEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	dustEmitter:Emit(100)
	Debris:AddItem(dustEmitterPart, 3)
end

-- Fungsi untuk telegraph retakan di tanah
local function createCrackTelegraph(position, size)
	local rayOrigin = position + Vector3.new(0, 50, 0)
	local rayDirection = Vector3.new(0, -100, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	local groundPosition = raycastResult and raycastResult.Position or position

	local telegraphDuration = 1.5
	local crackContainer = Instance.new("Model", Workspace)
	crackContainer.Name = "CrackTelegraph"
	Debris:AddItem(crackContainer, telegraphDuration + 0.5)

	local lightPart = Instance.new("Part", crackContainer)
	lightPart.Size = Vector3.new(1, 1, 1)
	lightPart.Position = groundPosition
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Transparency = 1

	local pointLight = Instance.new("PointLight", lightPart)
	pointLight.Color = Color3.fromRGB(130, 40, 180)
	pointLight.Brightness = 0
	pointLight.Range = 8

	local tweenInfo = TweenInfo.new(telegraphDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(pointLight, tweenInfo, { Brightness = 5, Range = 25 }):Play()

	for i = 1, 7 do
		local crack = Instance.new("Part", crackContainer)
		crack.Material = Enum.Material.Basalt
		crack.Color = Color3.fromRGB(10, 10, 10)
		crack.Anchored = true
		crack.CanCollide = false
		crack.TopSurface = Enum.SurfaceType.Smooth
		crack.BottomSurface = Enum.SurfaceType.Smooth
		crack.Size = Vector3.new(math.random(size.X * 0.4, size.X * 0.8), 0.1, math.random(size.Z * 0.1, size.Z * 0.2))
		local offsetX = (math.random() - 0.5) * size.X * 0.8
		local offsetZ = (math.random() - 0.5) * size.Z * 0.8
		local angleY = math.rad(math.random(0, 360))
		crack.CFrame = CFrame.new(groundPosition + Vector3.new(offsetX, 0.1, offsetZ)) * CFrame.Angles(0, angleY, 0)
	end
end

function PhaseVFX.CreateUpheaval(centerPosition, upheavalConfig, timeoutOrb)
	local platforms = {}
	local pillarOrbs = {}
	local telegraphDelay = 1.5

	local pillarHeight = upheavalConfig.PlatformSize.Y
	local pillarOrbHeight = pillarHeight / 2 + 4

	local targetAttachment = timeoutOrb and timeoutOrb:FindFirstChild("InnerCore", true) and timeoutOrb.InnerCore:FindFirstChild("BeamTarget")

	for i = 1, upheavalConfig.PlatformCount do
		local angle = (i / upheavalConfig.PlatformCount) * math.pi * 2
		local x = math.cos(angle) * upheavalConfig.ArenaRadius
		local z = math.sin(angle) * upheavalConfig.ArenaRadius
		local targetPosition = centerPosition + Vector3.new(x, 0, z)

		createCrackTelegraph(targetPosition, upheavalConfig.PlatformSize)

		local platform = Instance.new("Part", Workspace)
		platform.Size = upheavalConfig.PlatformSize
		platform.Position = centerPosition + Vector3.new(x, -(upheavalConfig.PlatformSize.Y * 2), z)
		platform.Anchored = true
		platform.Material = Enum.Material.Basalt
		table.insert(platforms, platform)

		local core = Instance.new("Part", platform)
		core.Shape = Enum.PartType.Ball
		core.Size = Vector3.new(4, 4, 4)
		core.Material = Enum.Material.SmoothPlastic
		core.Color = Color3.new(0,0,0)
		core.Anchored = true
		core.CanCollide = false
		local coreTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(core, coreTweenInfo, {Size = Vector3.new(6, 6, 6)}):Play()

		local distortion = Instance.new("ParticleEmitter", platform)
		distortion.Texture = ""
		distortion.LightEmission = 1
		distortion.Transparency = NumberSequence.new(0.9)
		distortion.Size = NumberSequence.new(8, 12)
		distortion.Lifetime = NumberRange.new(1, 1.5)
		distortion.Rate = 15
		distortion.Speed = NumberRange.new(2, 4)

		task.delay(telegraphDelay, function()
			if not platform or not platform.Parent then return end

			createDustEffect(platform.Position, platform.Size)

			local tweenInfo = TweenInfo.new(upheavalConfig.Duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local tween = TweenService:Create(platform, tweenInfo, {Position = targetPosition})
			tween:Play()
			tween.Completed:Wait()

			if not platform or not platform.Parent then return end

			local pillarOrb = Instance.new("Part", Workspace)
			pillarOrb.Shape = Enum.PartType.Ball
			pillarOrb.Size = Vector3.new(0,0,0)
			pillarOrb.Material = Enum.Material.Neon
			pillarOrb.Color = Color3.fromRGB(130, 40, 180)
			pillarOrb.Anchored = true
			pillarOrb.CanCollide = false
			pillarOrb.Position = platform.Position + Vector3.new(0, pillarOrbHeight, 0)
			table.insert(pillarOrbs, pillarOrb)

			local pillarAttachment = Instance.new("Attachment", pillarOrb)

			TweenService:Create(pillarOrb, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(3,3,3)}):Play()

			if targetAttachment then
				local beam = Instance.new("Beam", pillarOrb)
				beam.Color = ColorSequence.new(Color3.fromRGB(200, 150, 255))
				beam.Width0 = 0.5
				beam.Width1 = 0.2
				beam.Transparency = NumberSequence.new(0.4)
				beam.CurveSize0 = 10
				beam.CurveSize1 = -10
				beam.Texture = "rbxassetid://159997576"
				beam.TextureMode = Enum.TextureMode.Wrap
				beam.TextureSpeed = 1
				beam.Attachment0 = pillarAttachment
				beam.Attachment1 = targetAttachment
			end
		end)
	end

	return {platforms = platforms, pillarOrbs = pillarOrbs}
end

return PhaseVFX
