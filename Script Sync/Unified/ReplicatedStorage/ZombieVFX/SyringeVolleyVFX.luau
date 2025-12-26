-- SyringeVolleyVFX.lua (ModuleScript)
-- Path: ReplicatedStorage/ZombieVFX/SyringeVolleyVFX.lua
-- Script Place: ACT 1: Village
-- Deskripsi: Menangani efek visual untuk serangan Syringe Volley Boss 3.
-- DIREVISI TOTAL berdasarkan prototipe web: Menggunakan proyektil fisika
-- dengan jejak partikel, dan dampak (impact) multi-efek (splash, goo, puddle).
-- PERBAIKAN v4: Memperbaiki bug NaN (Not a Number) saat target berada tepat di atas bos.

local SyringeVolleyVFX = {}

-- Dependencies
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Warna yang diinspirasi dari prototipe
local LIME_BRIGHT = Color3.fromRGB(190, 242, 100) -- #BEF264
local LIME_CORE = Color3.fromRGB(132, 204, 22)   -- #84CC16
local LIME_DARK = Color3.fromRGB(77, 124, 15)    -- #4D7C0F
local SMOKE_GAS_COLOR = Color3.fromRGB(100, 116, 139) -- slate-500

-- Helper untuk Raycast (menemukan tanah)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {} -- Akan diisi oleh boss

--[[
	Fungsi baru untuk menangani VFX dampak (Impact)
	Menciptakan ledakan, cipratan lendir, dan genangan beracun.
]]
function SyringeVolleyVFX.CreateImpactVFX(position, config)
	-- Part induk untuk semua partikel instan (splash, goo)
	local impactPart = Instance.new("Part")
	impactPart.Name = "SyringeImpactVFX"
	impactPart.Size = Vector3.new(1, 1, 1)
	impactPart.Position = position
	impactPart.Anchored = true
	impactPart.CanCollide = false
	impactPart.Transparency = 1
	impactPart.Parent = Workspace
	Debris:AddItem(impactPart, 5.0) -- Waktu untuk partikel selesai

	-- 1. Cipratan (Splash) - Semburan vertikal cepat
	local splashEmitter = Instance.new("ParticleEmitter")
	splashEmitter.Color = ColorSequence.new(LIME_BRIGHT)
	splashEmitter.LightEmission = 0.5
	splashEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 4)
	})
	splashEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	splashEmitter.Speed = NumberRange.new(15, 25) -- Ke atas
	splashEmitter.Lifetime = NumberRange.new(0.5, 0.8)
	splashEmitter.Rotation = NumberRange.new(0, 360)
	splashEmitter.SpreadAngle = Vector2.new(30, 30) -- Kerucut sempit
	splashEmitter.EmissionDirection = Enum.NormalId.Top
	splashEmitter.Parent = impactPart
	splashEmitter:Emit(30) -- Semburan 30 partikel

	-- 2. Lendir (Goo Splatter) - Semburan melengkung ke luar
	local gooEmitter = Instance.new("ParticleEmitter")
	gooEmitter.Color = ColorSequence.new(LIME_DARK)
	gooEmitter.Size = NumberSequence.new(1.5, 0.5) -- Mengecil
	gooEmitter.Transparency = NumberSequence.new(0.4, 0.8)
	gooEmitter.Speed = NumberRange.new(10, 18)
	gooEmitter.Lifetime = NumberRange.new(1.0, 1.5)
	gooEmitter.Rotation = NumberRange.new(0, 360)
	gooEmitter.SpreadAngle = Vector2.new(80, 80) -- Menyebar lebar
	gooEmitter.EmissionDirection = Enum.NormalId.Top
	gooEmitter.Drag = 1.5 -- Melengkung (seperti gravitasi)
	gooEmitter.Acceleration = Vector3.new(0, -Workspace.Gravity / 2, 0)
	gooEmitter.Parent = impactPart
	gooEmitter:Emit(15) -- Semburan 15 partikel

	-- 3. Genangan (Puddle) - Efek di tanah yang bertahan lama
	local puddle = Instance.new("Part")
	puddle.Name = "ToxicPuddle"
	puddle.Shape = Enum.PartType.Cylinder
	puddle.Size = Vector3.new(0.2, 12, 12) -- Ukuran awal (akan di-tween)
	puddle.Position = position + Vector3.new(0, 0.1, 0) -- Sedikit di atas tanah
	puddle.Material = Enum.Material.ForceField
	puddle.Color = LIME_CORE
	puddle.CanCollide = false
	puddle.Anchored = true
	puddle.Transparency = 1 -- Mulai transparan
	puddle.Orientation = Vector3.new(0, 0, 90) -- Rata dengan tanah
	puddle.Parent = Workspace
	Debris:AddItem(puddle, 8.0) -- Bertahan 8 detik

	-- Tween genangan agar mengembang dan memudar
	TweenService:Create(puddle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 0.7,
		Size = Vector3.new(0.2, 18, 18)
	}):Play()
	task.delay(7.0, function()
		if puddle.Parent then
			TweenService:Create(puddle, TweenInfo.new(1.0, Enum.EasingStyle.Linear), {Transparency = 1}):Play()
		end
	end)

	-- 3a. Gelembung Genangan (Puddle Bubbles)
	local bubbleEmitter = Instance.new("ParticleEmitter")
	bubbleEmitter.Color = ColorSequence.new(LIME_CORE)
	bubbleEmitter.LightEmission = 0.2
	bubbleEmitter.Size = NumberSequence.new(0.5, 0.1) -- Meletus (mengecil)
	bubbleEmitter.Transparency = NumberSequence.new(0.6, 1)
	bubbleEmitter.Lifetime = NumberRange.new(0.5, 1.2)
	bubbleEmitter.Speed = NumberRange.new(0.5, 1) -- Naik perlahan
	bubbleEmitter.Rate = 20 -- Terus menerus
	bubbleEmitter.Shape = Enum.ParticleEmitterShape.Cylinder
	bubbleEmitter.EmissionDirection = Enum.NormalId.Top
	bubbleEmitter.SpreadAngle = Vector2.new(10, 10)
	bubbleEmitter.Parent = puddle
	Debris:AddItem(bubbleEmitter, 8.0)

	-- 3b. Asap Beracun (Toxic Gas)
	local gasEmitter = Instance.new("ParticleEmitter")
	gasEmitter.Color = ColorSequence.new(SMOKE_GAS_COLOR)
	gasEmitter.Transparency = NumberSequence.new(0.8, 1)
	gasEmitter.Size = NumberSequence.new(5, 10) -- Mengembang
	gasEmitter.Lifetime = NumberRange.new(2.0, 3.0)
	gasEmitter.Speed = NumberRange.new(0.5, 1) -- Naik perlahan
	gasEmitter.Rate = 10 -- Terus menerus
	gasEmitter.Shape = Enum.ParticleEmitterShape.Cylinder
	gasEmitter.EmissionDirection = Enum.NormalId.Top
	gasEmitter.SpreadAngle = Vector2.new(20, 20)
	gasEmitter.Acceleration = Vector3.new(0.1, 0.2, 0) -- Sedikit tertiup
	gasEmitter.Parent = puddle
	Debris:AddItem(gasEmitter, 8.0)
end

--[[
	Fungsi baru untuk membuat proyektil bertenaga fisika
	Menghitung lengkungan balistik dan meluncurkannya.
]]
function SyringeVolleyVFX.CreateSyringeVolleyProjectile(startPos, endPos, config, bossModel)
	local projectile = Instance.new("Part")
	projectile.Name = "SyringeProjectile"
	projectile.Shape = Enum.PartType.Ball
	projectile.Size = Vector3.new(2.5, 2.5, 2.5) -- Inti komet yang terlihat
	projectile.Material = Enum.Material.Neon
	projectile.Color = LIME_CORE
	projectile.CanCollide = false
	projectile.Anchored = false -- PENTING: Gunakan fisika
	projectile.CFrame = CFrame.new(startPos)
	projectile.Parent = Workspace

	-- Efek cahaya pada proyektil
	local glow = Instance.new("PointLight")
	glow.Color = LIME_BRIGHT
	glow.Brightness = 2
	glow.Range = 12
	glow.Parent = projectile

	-- Jejak partikel (ekor komet)
	local tailEmitter = Instance.new("ParticleEmitter")
	tailEmitter.Color = ColorSequence.new(LIME_BRIGHT)
	tailEmitter.LightEmission = 0.5
	tailEmitter.Size = NumberSequence.new(2, 0) -- Mengecil
	tailEmitter.Transparency = NumberSequence.new(0.5, 1)
	tailEmitter.Lifetime = NumberRange.new(0.3, 0.6)
	tailEmitter.Rate = 50 -- Jejak padat
	tailEmitter.Speed = NumberRange.new(0, 0) -- Partikel lahir di tempat
	tailEmitter.Parent = projectile

	-- [[ PERBAIKAN BALISTIK ]]: Gunakan peluncuran melengkung (lob) yang lebih sederhana
	local horizontalSpeed = config.ProjectileSpeed or 80
	local verticalSpeed = 20 -- Dorongan ke atas yang konstan untuk lengkungan

	local startPos_flat = Vector3.new(startPos.X, 0, startPos.Z)
	local endPos_flat = Vector3.new(endPos.X, 0, endPos.Z)

	-- [[ PERBAIKAN BUG NaN (Not a Number) ]]
	local horizontalDir_vector = (endPos_flat - startPos_flat)
	local horizontalDir

	if horizontalDir_vector.Magnitude < 0.1 then
		-- Target berada tepat di atas bos. Hindari NaN dengan memilih arah acak.
		local randomAngle = math.random() * 2 * math.pi
		horizontalDir = Vector3.new(math.cos(randomAngle), 0, math.sin(randomAngle))
	else
		-- Target berada di lokasi normal, gunakan arah yang dihitung.
		horizontalDir = horizontalDir_vector.Unit
	end

	-- Terapkan kecepatan awal
	projectile.AssemblyLinearVelocity = (horizontalDir * horizontalSpeed) + Vector3.new(0, verticalSpeed, 0)

	-- Atur agar proyektil hancur setelah 5 detik (waktu aman)
	Debris:AddItem(projectile, 5.0)

	-- Deteksi tabrakan
	local connection
	connection = projectile.Touched:Connect(function(hit)
		--[[ PERBAIKAN BUG: Filter tabrakan baru yang lebih ketat ]]

		-- 1. Abaikan tabrakan dengan boss yang menembak
		if bossModel and hit:IsDescendantOf(bossModel) then
			return 
		end

		-- 2. Abaikan tabrakan dengan proyektil lain atau genangan
		if hit.Name == "SyringeProjectile" or hit.Name == "ToxicPuddle" then
			return
		end

		-- 3. Abaikan tabrakan dengan 'Drop' (item pickup)
		if hit:GetAttribute("IsDrop") == true then
			return
		end

		-- 4. Meledak pada hal lain (Tanah, Pemain, Zombi Lain)
		connection:Disconnect() 

		-- Tampilkan VFX dampak di posisi tabrakan
		SyringeVolleyVFX.CreateImpactVFX(projectile.Position, config)

		-- Hancurkan proyektil
		if projectile and projectile.Parent then
			projectile:Destroy()
		end
	end)
end

--[[
	FungSI UTAMA: Menembakkan rentetan proyektil
	DIPERBARUI: Menggunakan proyektil balistik dan pencarian tanah (raycast).
]]
function SyringeVolleyVFX.FireSyringeVolley(bossModel, targetPosition, config)
	-- Cek apakah bossModel adalah Model dan memiliki PrimaryPart
	if not bossModel or not bossModel:IsA("Model") or not bossModel.PrimaryPart then
		warn("SyringeVolleyVFX: bossModel tidak valid atau tidak memiliki PrimaryPart.")
		return
	end

	local bossPosition = bossModel.PrimaryPart.Position

	-- 1. Tentukan posisi tanah di bawah target
	raycastParams.FilterDescendantsInstances = {bossModel} -- Abaikan model bos
	local ray = Workspace:Raycast(targetPosition + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0), raycastParams)
	local groundPos = ray and ray.Position or targetPosition

	-- 2. Tentukan posisi peluncuran (sedikit di atas bos)
	local projectileStartPos = bossPosition + Vector3.new(0, 8, 0)

	-- 3. Tembakkan rentetan
	for i = 1, config.ProjectileCount or 15 do
		-- Tunda setiap tembakan
		task.wait(config.Interval or 0.05) 

		-- Terapkan sebaran (spread) pada posisi target di tanah
		local spreadRadius = 40 -- Sesuai prototipe (80 / 2)
		local targetPosWithSpread = groundPos + Vector3.new(
			math.random(-spreadRadius, spreadRadius), 
			0, 
			math.random(-spreadRadius, spreadRadius)
		)

		-- Luncurkan proyektil balistik
		SyringeVolleyVFX.CreateSyringeVolleyProjectile(
			projectileStartPos, 
			targetPosWithSpread, 
			config,
			bossModel -- Teruskan bossModel
		)
	end
end

return SyringeVolleyVFX		