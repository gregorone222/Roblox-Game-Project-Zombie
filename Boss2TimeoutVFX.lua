-- Boss2TimeoutVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss2TimeoutVFX.lua
-- Script Place: ACT 1: Village

local Boss2TimeoutVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HardWipeVFXEvent = ReplicatedStorage.RemoteEvents:WaitForChild("HardWipeVFXEvent")
local Camera = workspace.CurrentCamera

-- Durasi
local IMPLOSION_DURATION = 1.0
local SUPERNOVA_DURATION = 0.4
local VOID_WAVE_DURATION = 2.0
local LINGER_DURATION = 5.0

-- Intensitas
local SHAKE_DURATION = 3.5
local SHAKE_INTENSITY = 2.0

-- Fungsi guncangan kamera (tetap sama)
local function shakeCamera()
	local startTime = tick()
	local connection

	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > SHAKE_DURATION then
			connection:Disconnect()
			return
		end

		local intensity = SHAKE_INTENSITY * (1 - (elapsed / SHAKE_DURATION)) -- Guncangan mereda
		local x = (math.random() * 2 - 1) * intensity
		local y = (math.random() * 2 - 1) * intensity

		Camera.CFrame = Camera.CFrame * CFrame.new(x, y, 0)
	end)
end

-- Rangkaian Efek "True Singularity Collapse"
local function triggerWipeVFX(wipeOrigin)
	shakeCamera()

	-- Tahap 1: Implosion
	local singularityCore = workspace:FindFirstChild("SingularityCore")
	if singularityCore and singularityCore.PrimaryPart then
		-- Partikel disedot masuk
		local implosionEmitter = Instance.new("ParticleEmitter")
		implosionEmitter.Color = ColorSequence.new(Color3.fromRGB(20, 0, 30))
		implosionEmitter.LightEmission = 0.5
		implosionEmitter.Size = NumberSequence.new(8, 0)
		implosionEmitter.Speed = NumberRange.new(-100, -80) -- Kecepatan negatif (ke dalam)
		implosionEmitter.Lifetime = NumberRange.new(0.5, 0.8)
		implosionEmitter.Rate = 500
		implosionEmitter.Parent = singularityCore.PrimaryPart
		Debris:AddItem(implosionEmitter, IMPLOSION_DURATION)

		-- Inti menyusut
		local innerCore = singularityCore:FindFirstChild("InnerCore")
		local outerShell = singularityCore:FindFirstChild("OuterShell")
		if innerCore and outerShell then
			TweenService:Create(innerCore, TweenInfo.new(IMPLOSION_DURATION), {Size = Vector3.new(0.1, 0.1, 0.1)}):Play()
			TweenService:Create(outerShell, TweenInfo.new(IMPLOSION_DURATION), {Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1}):Play()
		end
	end

	task.wait(IMPLOSION_DURATION)

	-- Tahap 2: Supernova
	local originalAmbient = Lighting.Ambient
	local originalOutdoorAmbient = Lighting.OutdoorAmbient
	local originalBrightness = Lighting.Brightness

	-- Efek Bloom
	local bloom = Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0
	bloom.Size = 24
	bloom.Threshold = 0.95
	TweenService:Create(bloom, TweenInfo.new(SUPERNOVA_DURATION / 2), {Intensity = 2}):Play()
	task.delay(SUPERNOVA_DURATION, function()
		TweenService:Create(bloom, TweenInfo.new(0.5), {Intensity = 0}):Play()
		Debris:AddItem(bloom, 1)
	end)

	-- Kilatan Cahaya
	TweenService:Create(Lighting, TweenInfo.new(0.1), {Brightness = 5, Ambient = Color3.new(1,1,1), OutdoorAmbient = Color3.new(1,1,1)}):Play()

	local supernovaFlash = Instance.new("Part", workspace)
	supernovaFlash.Material = Enum.Material.Neon
	supernovaFlash.Color = Color3.new(1,1,1)
	supernovaFlash.Anchored = true
	supernovaFlash.CanCollide = false
	supernovaFlash.Position = wipeOrigin
	supernovaFlash.Shape = Enum.PartType.Ball
	supernovaFlash.Size = Vector3.new(1,1,1)
	TweenService:Create(supernovaFlash, TweenInfo.new(SUPERNOVA_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = Vector3.new(1200, 1200, 1200), Transparency = 1}):Play()
	Debris:AddItem(supernovaFlash, SUPERNOVA_DURATION)

	-- Percikan energi
	local sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Color = ColorSequence.new(Color3.new(1,1,1))
	sparkEmitter.LightEmission = 1
	sparkEmitter.Size = NumberSequence.new(2, 0)
	sparkEmitter.Speed = NumberRange.new(150, 200)
	sparkEmitter.Lifetime = NumberRange.new(1, 2)
	sparkEmitter.Parent = supernovaFlash
	sparkEmitter:Emit(200)

	task.wait(SUPERNOVA_DURATION)

	-- Tahap 3: Void Wave
	TweenService:Create(Lighting, TweenInfo.new(VOID_WAVE_DURATION), {Brightness = 0, Ambient = Color3.new(0,0,0), OutdoorAmbient = Color3.new(0,0,0)}):Play()

	local shockwave = Instance.new("Part", workspace)
	shockwave.Material = Enum.Material.ForceField
	shockwave.Color = Color3.fromRGB(80, 0, 120)
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Position = wipeOrigin - Vector3.new(0, wipeOrigin.Y, 0) -- Di tanah
	shockwave.Size = Vector3.new(0, 8, 0)
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Orientation = Vector3.new(0,0,90)
	shockwave.Transparency = 0.5
	TweenService:Create(shockwave, TweenInfo.new(1.0, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = Vector3.new(400, 8, 400), Transparency = 1}):Play()
	Debris:AddItem(shockwave, 1.1)

	local voidWave = Instance.new("Part", workspace)
	voidWave.Material = Enum.Material.ForceField
	voidWave.Color = Color3.new(0,0,0)
	voidWave.Anchored = true
	voidWave.CanCollide = false
	voidWave.Position = wipeOrigin
	voidWave.Shape = Enum.PartType.Ball
	voidWave.Size = Vector3.new(1,1,1)
	voidWave.Transparency = 0
	TweenService:Create(voidWave, TweenInfo.new(VOID_WAVE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(1200, 1200, 1200), Transparency = 1}):Play()
	Debris:AddItem(voidWave, VOID_WAVE_DURATION)

	task.wait(VOID_WAVE_DURATION)

	-- Tahap 4: Lingering Echo
	local vortexPart = Instance.new("Part", workspace)
	vortexPart.Anchored = true
	vortexPart.CanCollide = false
	vortexPart.Transparency = 1
	vortexPart.Position = wipeOrigin

	local vortexEmitter = Instance.new("ParticleEmitter", vortexPart)
	vortexEmitter.Color = ColorSequence.new(Color3.fromRGB(20, 0, 30))
	vortexEmitter.LightEmission = 0.2
	vortexEmitter.Size = NumberSequence.new(10, 0)
	vortexEmitter.Speed = NumberRange.new(5)
	vortexEmitter.Lifetime = NumberRange.new(2, 3)
	vortexEmitter.Rate = 20
	vortexEmitter.Drag = 5
	vortexEmitter.Acceleration = Vector3.new(0, 0, 20) -- Awalnya mendorong ke samping

	Debris:AddItem(vortexPart, LINGER_DURATION)

	local vortexConnection
	vortexConnection = RunService.Heartbeat:Connect(function(dt)
		if not vortexEmitter or not vortexEmitter.Parent then
			vortexConnection:Disconnect()
			return
		end
		-- Memutar akselerasi untuk menciptakan pusaran
		vortexEmitter.Acceleration = CFrame.Angles(0, dt * 5, 0):VectorToWorldSpace(vortexEmitter.Acceleration)
	end)

	-- Pulihkan pencahayaan
	task.delay(LINGER_DURATION, function()
		TweenService:Create(Lighting, TweenInfo.new(1.0), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			OutdoorAmbient = originalOutdoorAmbient
		}):Play()
	end)
end

function Boss2TimeoutVFX.init()
	HardWipeVFXEvent.OnClientEvent:Connect(triggerWipeVFX)
end

return Boss2TimeoutVFX
