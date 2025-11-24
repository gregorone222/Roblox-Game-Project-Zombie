-- Boss1TimeoutVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/Boss1TimeoutVFX.lua
-- Script Place: ACT 1: Village

local Boss1TimeoutVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote Event Khusus untuk Guncangan Ini
local ShakeEvent = Instance.new("RemoteEvent")
ShakeEvent.Name = "Boss1TimeoutShakeEvent_v2"
ShakeEvent.Parent = ReplicatedStorage.RemoteEvents

-- Logika sisi klien untuk guncangan & efek layar
if RunService:IsClient() then
	local camera = Workspace.CurrentCamera
	ShakeEvent.OnClientEvent:Connect(function(duration)
		local startTime = tick()
		local shakeConnection
		shakeConnection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			if elapsed >= duration then
				shakeConnection:Disconnect()
				return
			end
			-- Guncangan berirama frekuensi rendah
			local intensity = 0.5 * math.pow(elapsed / duration, 2) -- Semakin kuat
			local frequency = 10
			local shake = math.sin(elapsed * frequency) * intensity
			camera.CFrame = camera.CFrame * CFrame.Angles(0, shake, 0)
		end)
	end)
end

-- Konstanta
local SOUL_COLOR = Color3.fromRGB(180, 220, 255)
local BLACK_HOLE_COLOR = Color3.fromRGB(10, 0, 20)

function Boss1TimeoutVFX.Play(bossModel, position)
	-- Fase 1: Penuaian (1.5 detik)

	-- Efek Pasca-pemrosesan
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor = Color3.fromRGB(255, 150, 150) -- Merah darah
	cc.Saturation = -0.5
	cc.Contrast = 0.3
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 2
	bloom.Threshold = 0.8
	bloom.Size = 56
	bloom.Parent = Lighting

	-- Partikel "jiwa"
	local soulContainer = Instance.new("Part", Workspace)
	soulContainer.Size, soulContainer.Position, soulContainer.Shape = Vector3.new(300, 100, 300), position, Enum.PartType.Ball
	soulContainer.Anchored, soulContainer.CanCollide, soulContainer.Transparency = true, false, 1
	Debris:AddItem(soulContainer, 3)

	local souls = Instance.new("ParticleEmitter", soulContainer)
	souls.Color = ColorSequence.new(SOUL_COLOR)
	souls.LightEmission, souls.Size = 1, NumberSequence.new(2, 0.5)
	souls.Lifetime, souls.Speed = NumberRange.new(1.5), NumberRange.new(-200)
	souls.Rate, souls.Shape = 500, Enum.ParticleEmitterShape.Sphere
	souls.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward

	task.wait(1.5)

	-- Fase 2: Penghakiman (1 detik)
	ShakeEvent:FireAllClients(1.0)

	-- Lubang hitam dengan distorsi
	local blackHole = Instance.new("Part", Workspace)
	blackHole.Shape, blackHole.Size = Enum.PartType.Ball, Vector3.new(0.1, 0.1, 0.1)
	blackHole.CFrame = CFrame.new(position + Vector3.new(0, 20, 0))
	blackHole.Material, blackHole.Color = Enum.Material.ForceField, BLACK_HOLE_COLOR
	blackHole.Anchored, blackHole.CanCollide = true, false
	Debris:AddItem(blackHole, 1.5)
	TweenService:Create(blackHole, TweenInfo.new(1), {Size = Vector3.new(40, 40, 40)}):Play()

	local distortion = Instance.new("Part", Workspace)
	distortion.Shape, distortion.Size = Enum.PartType.Ball, blackHole.Size
	distortion.CFrame, distortion.Material = blackHole.CFrame, Enum.Material.Glass
	distortion.Reflectance = 1
	distortion.Anchored, distortion.CanCollide = true, false
	Debris:AddItem(distortion, 1.5)
	TweenService:Create(distortion, TweenInfo.new(1), {Size = Vector3.new(60, 60, 60), Transparency = 1}):Play()

	task.wait(1)

	-- Fase 3: Penghapusan (0.5 detik)
	-- Kilatan putih
	local flash = Instance.new("ColorCorrectionEffect", Lighting)
	flash.Brightness = 2
	Debris:AddItem(flash, 0.1)

	task.wait(0.1)

	-- Hapus efek lama
	cc:Destroy()
	bloom:Destroy()

	-- Kubah kehampaan
	local void = Instance.new("Part", Workspace)
	void.Shape, void.Size = Enum.PartType.Ball, Vector3.new(1, 1, 1)
	void.CFrame, void.Material = CFrame.new(position), Enum.Material.ForceField
	void.Color, void.Anchored = Color3.fromRGB(0,0,0), true
	void.CanCollide = false
	Debris:AddItem(void, 0.4)
	TweenService:Create(void, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {Size = Vector3.new(1000, 1000, 1000)}):Play()

	-- Gelombang Distorsi Realitas
	local distortionWave = Instance.new("Part", Workspace)
	distortionWave.Shape = Enum.PartType.Cylinder
	distortionWave.Size = Vector3.new(4, 1, 1)
	distortionWave.CFrame = CFrame.new(position) * CFrame.Angles(0,0,math.rad(90))
	distortionWave.Material = Enum.Material.ForceField
	distortionWave.Transparency = 0.8
	distortionWave.Anchored = true
	distortionWave.CanCollide = false
	Debris:AddItem(distortionWave, 0.5)
	TweenService:Create(distortionWave, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {Size = Vector3.new(4, 1000, 1000), Transparency = 1}):Play()

	-- Debu yang ditendang
	local dust = Instance.new("ParticleEmitter", distortionWave)
	dust.Color = ColorSequence.new(Color3.fromRGB(50,50,50))
	dust.Size = NumberSequence.new(2, 5)
	dust.Lifetime = NumberRange.new(1, 2)
	dust.Speed = NumberRange.new(20, 30)
	dust.Rate = 2000
	task.delay(0.5, function() dust.Rate = 0 end)
end

return Boss1TimeoutVFX
