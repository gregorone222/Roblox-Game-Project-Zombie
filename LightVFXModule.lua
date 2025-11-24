-- LightVFXModule.lua (ModuleScript)
-- Path: ReplicatedStorage/ElementVFX/LightVFXModule.lua
-- Script Place: ACT 1: Village

local LightVFX = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local function ensureFolder(char: Model)
	local f = char:FindFirstChild("LightVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "LightVFX"
		f.Parent = char
	end
	return f
end

function LightVFX.SpawnForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	if not hrp then return end

	-- Hapus efek lama untuk memastikan tidak ada tumpukan
	local old = char:FindFirstChild("LightVFX")
	if old then old:Destroy() end
	local folder = ensureFolder(char)

	-- == 1. EFEK DI TANAH (GROUND SIGIL) ==
	local groundPart = Instance.new("Part")
	groundPart.Name = "GroundSigil"
	groundPart.Size = Vector3.new(10, 0.1, 10)
	groundPart.Color = Color3.fromRGB(255, 255, 255)
	groundPart.Material = Enum.Material.ForceField
	groundPart.Anchored = true
	groundPart.CanCollide = false
	groundPart.CFrame = hrp.CFrame * CFrame.new(0, -hrp.Size.Y/2, 0)
	groundPart.Parent = folder

	local decal = Instance.new("Decal")
	decal.Name = "SigilDecal"
	decal.Face = Enum.NormalId.Top
	-- ASSET PLACEHOLDER: Ganti ID ini dengan decal Anda.
	-- DESKRIPSI: Sebuah gambar sigil atau rune sihir yang bercahaya. Desainnya melingkar dengan pola geometris atau surgawi.
	-- Sebaiknya dengan latar belakang transparan.
	decal.Texture = "rbxassetid://MASUKKAN_ID_DECAL_SIGIL_ANDA"
	decal.Color3 = Color3.fromRGB(255, 255, 150)
	decal.Parent = groundPart

	-- Animasi Decal
	local tweenInfoFade = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(decal, tweenInfoFade, {Transparency = 0}):Play()
	local tweenInfoSize = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(groundPart, tweenInfoSize, {Size = Vector3.new(12, 0.1, 12)}):Play()

	-- == 2. AURA & CAHAYA PEMAIN ==
	local auraSphere = Instance.new("Part")
	auraSphere.Name = "AuraSphere"
	auraSphere.Shape = Enum.PartType.Ball
	auraSphere.Size = Vector3.new(0.1, 0.1, 0.1)
	auraSphere.Material = Enum.Material.Neon
	auraSphere.Color = Color3.fromRGB(255, 255, 200)
	auraSphere.CanCollide = false
	auraSphere.Massless = true
	auraSphere.Anchored = false
	auraSphere.CFrame = hrp.CFrame
	auraSphere.Parent = folder

	local light = Instance.new("PointLight")
	light.Brightness = 10
	light.Range = 20
	light.Color = Color3.fromRGB(255, 255, 150)
	light.Parent = auraSphere

	local tweenInfoAura = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	TweenService:Create(auraSphere, tweenInfoAura, {Size = Vector3.new(8, 8, 8), Transparency = 0.8}):Play()

	-- == 3. PARTIKEL BARU (LEBIH DINAMIS) ==
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "AuraParticles"
	-- ASSET PLACEHOLDER: Ganti ID ini dengan tekstur partikel Anda.
	-- DESKRIPSI: Gambar partikel kecil yang lembut, bisa berupa titik cahaya (dot) atau percikan (spark) kecil dengan pinggiran yang halus.
	particles.Texture = "rbxassetid://MASUKKAN_ID_TEXTURE_PARTIKEL_ANDA"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 253, 186), Color3.fromRGB(255, 215, 0))
	particles.LightEmission = 1
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.1, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(1, 1.5)
	particles.Speed = NumberRange.new(0.5, 2)
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Shape = Enum.ParticleEmitterShape.Sphere
	
	particles.Rate = 50
	particles.Parent = auraSphere

	-- == 4. SINAR CAHAYA (LIGHT BEAMS) ==
	local beamPart = Instance.new("Part")
	beamPart.Name = "BeamAnchor"
	beamPart.Size = Vector3.new(1, 1, 1)
	beamPart.Transparency = 1
	beamPart.CanCollide = false
	beamPart.Anchored = false
	beamPart.CFrame = hrp.CFrame * CFrame.new(0, 20, 0) -- Anchor di atas kepala pemain
	beamPart.Parent = folder

	local attachmentPlayer = Instance.new("Attachment")
	attachmentPlayer.Parent = hrp

	local attachmentSky = Instance.new("Attachment")
	attachmentSky.Parent = beamPart

	local beam = Instance.new("Beam")
	beam.Name = "LightBeam"
	-- ASSET PLACEHOLDER: Ganti ID ini dengan tekstur beam Anda.
	-- DESKRIPSI: Gambar gradasi vertikal yang halus dari terang ke transparan. Bisa juga seperti tekstur sinar (ray) atau goresan (streak).
	beam.Texture = "rbxassetid://MASUKKAN_ID_TEXTURE_BEAM_ANDA"
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 180))
	beam.LightEmission = 1
	beam.Width0 = 3
	beam.Width1 = 5
	beam.Attachment0 = attachmentPlayer
	beam.Attachment1 = attachmentSky
	beam.FaceCamera = true
	beam.Parent = folder

	local tweenInfoBeam = TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	beam.Transparency = NumberSequence.new(1)
	TweenService:Create(beam, tweenInfoBeam, {Transparency = NumberSequence.new(0.3)}):Play()

	-- == WELDING ==
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = auraSphere
	weld.Parent = auraSphere

	local weldBeam = Instance.new("WeldConstraint")
	weldBeam.Part0 = hrp
	weldBeam.Part1 = beamPart
	weldBeam.Parent = beamPart
end

function LightVFX.RemoveForPlayer(player: Player)
	local char = player.Character
	if not char then return end
	local folder = char:FindFirstChild("LightVFX")

	if folder then
		-- Animasi menghilang yang halus
		local tweenInfoFadeOut = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("Part") or descendant:IsA("Decal") then
				TweenService:Create(descendant, tweenInfoFadeOut, {Transparency = 1}):Play()
			elseif descendant:IsA("Beam") then
				TweenService:Create(descendant, tweenInfoFadeOut, {Transparency = NumberSequence.new(1)}):Play()
			elseif descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end

		-- Hancurkan folder setelah animasi selesai
		task.delay(0.5, function()
			if folder then folder:Destroy() end
		end)
	end
end

return LightVFX
