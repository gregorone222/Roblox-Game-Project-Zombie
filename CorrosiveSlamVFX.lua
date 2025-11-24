-- CorrosiveSlamVFX.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CorrosiveSlamVFX.lua
-- Script Place: ACT 1: Village

local CorrosiveSlamVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX_FOLDER_NAME = "VFX_CorrosiveSlam"

local function getVfxFolder()
	local folder = workspace:FindFirstChild(VFX_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder", workspace)
		folder.Name = VFX_FOLDER_NAME
	end
	return folder
end

-- Fungsi efek ledakan yang dapat digunakan kembali
local function createExplosionEffect(position, radius, color, duration)
	local vfxFolder = getVfxFolder()
	local explosionPart = Instance.new("Part")
	explosionPart.Anchored = true
	explosionPart.CanCollide = false
	explosionPart.Material = Enum.Material.ForceField
	explosionPart.Color = color
	explosionPart.Shape = Enum.PartType.Ball
	explosionPart.Size = Vector3.new(0.1, 0.1, 0.1)
	explosionPart.Position = position
	explosionPart.Transparency = 0.6
	explosionPart.Parent = vfxFolder

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local goal = {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
		Transparency = 1
	}
	TweenService:Create(explosionPart, tweenInfo, goal):Play()
	Debris:AddItem(explosionPart, duration + 0.1)

	-- Partikel cipratan
	local particleEmitter = Instance.new("ParticleEmitter", explosionPart)
	particleEmitter.Color = ColorSequence.new(color)
	particleEmitter.LightEmission = 0.5
	particleEmitter.Size = NumberSequence.new(1, 4)
	particleEmitter.Speed = NumberRange.new(20, 30)
	particleEmitter.Lifetime = NumberRange.new(0.5, 1.0)
	particleEmitter:Emit(50)
end

-- Fungsi untuk membuat titik nexus yang berdenyut
local function createNexusPoint(position, config)
	local vfxFolder = getVfxFolder()
	local nexusPart = Instance.new("Part")
	nexusPart.Anchored = true
	nexusPart.CanCollide = false
	nexusPart.Material = Enum.Material.Neon
	nexusPart.Color = Color3.fromRGB(175, 255, 0) -- Hijau-limau neon
	nexusPart.Shape = Enum.PartType.Ball
	nexusPart.Size = Vector3.new(0.1, 0.1, 0.1) -- Mulai kecil
	nexusPart.Position = position
	nexusPart.Parent = vfxFolder
	nexusPart.Transparency = 0

	local attachment = Instance.new("Attachment", nexusPart)
	attachment.Name = "BeamAttachment"

	-- Spawn animation: scale dari 0 ke 1 dalam 0.3s
	local spawnTween = TweenService:Create(nexusPart, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = Vector3.new(1, 1, 1)})
	spawnTween:Play()

	-- Pulse animation: scale antara 1 dan 1.3 setiap 0.7s, mulai setelah web travel time
	local pulseTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(nexusPart, pulseTweenInfo, {Size = Vector3.new(1.3, 1.3, 1.3)})
	task.delay(config.WebTravelTime, function()
		pulseTween:Play()
	end)

	-- Tidak menggunakan Debris di sini, akan dibersihkan secara manual saat impact
	return nexusPart, pulseTween
end

-- Fungsi utama
function CorrosiveSlamVFX.createTelegraph(bossModel, config)
	local vfxFolder = getVfxFolder()
	local initialBossPos = bossModel.PrimaryPart.Position
	local groundY = initialBossPos.Y

	local telegraphAssets = {}
	telegraphAssets.nexusPoints = {}
	telegraphAssets.nexusTweens = {}
	telegraphAssets.beams = {}

	local centerPosition = Vector3.new(initialBossPos.X, groundY, initialBossPos.Z)
	local centerNexus, centerTween = createNexusPoint(centerPosition, config)
	table.insert(telegraphAssets.nexusPoints, centerNexus)
	table.insert(telegraphAssets.nexusTweens, centerTween)

	for i = 1, config.NexusPointCount do
		local angle = (i / config.NexusPointCount) * 2 * math.pi
		local x = centerPosition.X + config.NexusRadius * math.cos(angle)
		local z = centerPosition.Z + config.NexusRadius * math.sin(angle)
		local nexusPosition = Vector3.new(x, groundY, z)

		local nexusPart, nexusTween = createNexusPoint(nexusPosition, config)
		table.insert(telegraphAssets.nexusPoints, nexusPart)
		table.insert(telegraphAssets.nexusTweens, nexusTween)

		local beam = Instance.new("Beam")
		beam.Attachment0 = centerNexus:FindFirstChild("BeamAttachment")
		beam.Attachment1 = nexusPart:FindFirstChild("BeamAttachment")
		beam.Color = ColorSequence.new(Color3.fromRGB(158, 255, 0)) -- Beam color
		beam.FaceCamera = true
		beam.LightEmission = 0.5
		beam.Width0 = 0
		beam.Width1 = 0
		beam.Parent = vfxFolder
		table.insert(telegraphAssets.beams, beam)

		-- Beam stretches over WebTravelTime (1.2s)
		local beamTween = TweenService:Create(beam, TweenInfo.new(config.WebTravelTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Width0 = 0.2, Width1 = 0.2})
		beamTween:Play()
	end

	-- Position tracking loop for nexus points during TelegraphDuration
	local updateCoroutine = task.spawn(function()
		local startTime = tick()
		while tick() - startTime < config.TelegraphDuration do
			local currentBossPos = bossModel.PrimaryPart.Position
			-- Update center nexus
			telegraphAssets.nexusPoints[1].Position = Vector3.new(currentBossPos.X, groundY, currentBossPos.Z)
			-- Update peripheral nexus points
			for i = 2, #telegraphAssets.nexusPoints do
				local angle = ((i - 1) / config.NexusPointCount) * 2 * math.pi
				local x = currentBossPos.X + config.NexusRadius * math.cos(angle)
				local z = currentBossPos.Z + config.NexusRadius * math.sin(angle)
				telegraphAssets.nexusPoints[i].Position = Vector3.new(x, groundY, z)
			end
			task.wait(0.1)
		end
	end)
	telegraphAssets.updateCoroutine = updateCoroutine

	return telegraphAssets
end

function CorrosiveSlamVFX.triggerImpact(bossModel, config, telegraphAssets)
	local vfxFolder = getVfxFolder()
	local initialBossPos = bossModel.PrimaryPart.Position

	-- Ledakan utama
	local mainExplosion = createExplosionEffect(initialBossPos, config.Radius, Color3.fromRGB(207, 255, 80), 0.4) -- Explosion color

	-- Buat bekas hangus utama
	local mainScorchMark = Instance.new("Part", vfxFolder)
	mainScorchMark.Anchored = true
	mainScorchMark.CanCollide = false
	mainScorchMark.Material = Enum.Material.Plastic
	mainScorchMark.Color = Color3.fromRGB(17, 17, 17) -- Scorch color
	mainScorchMark.Shape = Enum.PartType.Ball
	mainScorchMark.Size = Vector3.new(config.Radius * 2, 0.1, config.Radius * 2)
	mainScorchMark.Position = initialBossPos - Vector3.new(0, 0.05, 0) -- Slightly below ground
	mainScorchMark.Transparency = 0.3

	-- Hapus beam setelah ledakan utama
	if telegraphAssets then
		for _, beam in ipairs(telegraphAssets.beams) do
			beam:Destroy()
		end
		-- Cancel the position tracking coroutine
		if telegraphAssets.updateCoroutine then
			task.cancel(telegraphAssets.updateCoroutine)
		end
	end

	-- Ledakan sekunder di setiap titik nexus dengan delay 0.25s
	if telegraphAssets and telegraphAssets.nexusPoints then
		task.delay(config.SecondaryExplosionDelay, function()
			local scorchMarks = {mainScorchMark} -- Include main scorch for cleanup

			for i, nexusPart in ipairs(telegraphAssets.nexusPoints) do
				if nexusPart and nexusPart.Parent then
					-- Secondary explosion
					createExplosionEffect(nexusPart.Position, 7.5, Color3.fromRGB(207, 255, 80), 0.4)

					-- Secondary scorch marks (except for center)
					if i > 1 then
						local secondaryScorch = Instance.new("Part", vfxFolder)
						secondaryScorch.Anchored = true
						secondaryScorch.CanCollide = false
						secondaryScorch.Material = Enum.Material.Plastic
						secondaryScorch.Color = Color3.fromRGB(17, 17, 17)
						secondaryScorch.Shape = Enum.PartType.Ball
						secondaryScorch.Size = Vector3.new(15, 0.1, 15)
						secondaryScorch.Position = nexusPart.Position - Vector3.new(0, 0.05, 0)
						secondaryScorch.Transparency = 0.3
						table.insert(scorchMarks, secondaryScorch)
					end

					-- Remove nexus point
					nexusPart:Destroy()
				end
			end

			-- Position tracking for scorch marks during fade-out
			local scorchUpdateCoroutine = task.spawn(function()
				local startTime = tick()
				while tick() - startTime < 1 do
					local currentBossPos = bossModel.PrimaryPart.Position
					-- Update main scorch mark position
					mainScorchMark.Position = currentBossPos - Vector3.new(0, 0.05, 0)
					-- Update secondary scorch marks relative to boss position
					for i = 2, #scorchMarks do
						local scorch = scorchMarks[i]
						if scorch and scorch.Parent then
							local angle = ((i - 1) / config.NexusPointCount) * 2 * math.pi
							local x = currentBossPos.X + config.NexusRadius * math.cos(angle)
							local z = currentBossPos.Z + config.NexusRadius * math.sin(angle)
							scorch.Position = Vector3.new(x, currentBossPos.Y - 0.05, z)
						end
					end
					task.wait(0.1)
				end
			end)

			-- Cleanup scorch marks with fade-out after 1s
			task.delay(1, function()
				task.cancel(scorchUpdateCoroutine)
				for _, scorch in ipairs(scorchMarks) do
					if scorch and scorch.Parent then
						local fadeTween = TweenService:Create(scorch, TweenInfo.new(1, Enum.EasingStyle.Linear), {Transparency = 1})
						fadeTween:Play()
						fadeTween.Completed:Connect(function()
							scorch:Destroy()
						end)
					end
				end
			end)
		end)
	end
end

return CorrosiveSlamVFX
