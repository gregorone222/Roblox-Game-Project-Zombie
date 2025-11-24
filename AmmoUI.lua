-- AmmoUI.lua (LocalScript)
-- Path: StarterGui/AmmoUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")

-- Hapus UI lama jika ada
if playerGui:FindFirstChild("AmmoUI") then
	playerGui.AmmoUI:Destroy()
end

-- ============================================================================
-- KONFIGURASI & STYLE
-- ============================================================================
local COLORS = {
	Cyan = Color3.fromRGB(6, 182, 212),      -- Cyan-500 (Aksen Utama)
	SlateDark = Color3.fromRGB(15, 23, 42),  -- Slate-900 (Background)
	SlateLight = Color3.fromRGB(51, 65, 85), -- Slate-700
	Amber = Color3.fromRGB(245, 158, 11),    -- Amber-500 (Level Badge)
	Red = Color3.fromRGB(239, 68, 68),       -- Red-500 (Low Ammo)
	White = Color3.fromRGB(255, 255, 255),
	TextGray = Color3.fromRGB(148, 163, 184) -- Slate-400
}

local FONTS = {
	Main = Enum.Font.GothamBlack,
	Secondary = Enum.Font.GothamBold,
	Detail = Enum.Font.GothamMedium
}

-- Ambang batas peluru rendah (persentase)
local LOW_AMMO_PERCENT = 0.25

-- ============================================================================
-- HELPER UI
-- ============================================================================
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

-- ============================================================================
-- PEMBUATAN UI
-- ============================================================================
local screenGui = create("ScreenGui", {
	Name = "AmmoUI",
	IgnoreGuiInset = false,
	ResetOnSpawn = true,
	Parent = playerGui
})

-- Container Utama (Posisi akan diatur ulang oleh script resize)
local mainContainer = create("Frame", {
	Name = "MainContainer",
	Size = UDim2.new(0.35, 0, 0.18, 0),
	BackgroundTransparency = 1,
	Parent = screenGui
})

-- 1. Header: Level & Nama Senjata
local headerFrame = create("Frame", {
	Name = "HeaderFrame",
	Size = UDim2.new(1, 0, 0.27, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	Parent = mainContainer
})

-- Lencana Level (Kuning/Amber)
local levelBadge = create("Frame", {
	Name = "LevelBadge",
	Size = UDim2.new(0.19, 0, 0.6, 0),
	Position = UDim2.new(0.65, 0, 0, 0), -- Sedikit offset ke kiri
	BackgroundColor3 = COLORS.Amber,
	Parent = headerFrame
})
create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = levelBadge })

local levelText = create("TextLabel", {
	Name = "LevelText",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "LV.1",
	TextColor3 = COLORS.SlateDark,
	Font = FONTS.Main,
	TextSize = 16,
	Parent = levelBadge
})

-- Nama Senjata
local weaponNameLabel = create("TextLabel", {
	Name = "WeaponName",
	Size = UDim2.new(1, 0, 0.75, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "ASSAULT RIFLE",
	TextColor3 = COLORS.White,
	Font = FONTS.Main,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = headerFrame
})

-- Garis Bawah (Gradient Line)
local underline = create("Frame", {
	Name = "Underline",
	Size = UDim2.new(1, 0, 0.075, 0),
	Position = UDim2.new(0, 0, 0.8, 0),
	BorderSizePixel = 0,
	BackgroundColor3 = COLORS.White,
	Parent = headerFrame
})
local underlineGradient = create("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, COLORS.SlateDark),
		ColorSequenceKeypoint.new(0.5, COLORS.Cyan),
		ColorSequenceKeypoint.new(1, COLORS.Cyan)
	},
	Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	},
	Parent = underline
})

-- 2. Kotak Utama (Ammo Count & Bar)
local ammoBox = create("Frame", {
	Name = "AmmoBox",
	Size = UDim2.new(1, 0, 0.67, 0),
	Position = UDim2.new(0, 0, 0.27, 0),
	BackgroundColor3 = COLORS.SlateDark,
	BackgroundTransparency = 0.2, -- Sedikit transparan
	BorderSizePixel = 0,
	Parent = mainContainer
})
-- Gradient Latar Belakang (Kiri transparan ke Kanan gelap)
local boxGradient = create("UIGradient", {
	Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(1, 0.1)
	},
	Parent = ammoBox
})

-- Aksen Kanan (Cyan Border)
local rightAccent = create("Frame", {
	Name = "RightAccent",
	Size = UDim2.new(0.01, 0, 1, 0),
	Position = UDim2.new(0.99, 0, 0, 0),
	BackgroundColor3 = COLORS.Cyan,
	BorderSizePixel = 0,
	Parent = ammoBox
})

-- Teks Ammo Saat Ini (Besar)
local currentAmmoLabel = create("TextLabel", {
	Name = "CurrentAmmo",
	Size = UDim2.new(0.5, 0, 0.8, 0),
	Position = UDim2.new(0.15, 0, 0.1, 0),
	BackgroundTransparency = 1,
	Text = "30",
	TextColor3 = COLORS.White,
	Font = FONTS.Main,
	TextSize = 70,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = ammoBox
})

-- Pemisah Slash
local slashLabel = create("TextLabel", {
	Name = "Slash",
	Size = UDim2.new(0.1, 0, 0.8, 0),
	Position = UDim2.new(0.66, 0, 0.1, 0),
	BackgroundTransparency = 1,
	Text = "/",
	TextColor3 = COLORS.TextGray,
	Font = FONTS.Detail,
	TextSize = 30,
	Parent = ammoBox
})

-- Teks Ammo Cadangan (Kecil)
local reserveAmmoLabel = create("TextLabel", {
	Name = "ReserveAmmo",
	Size = UDim2.new(0.2, 0, 0.8, 0),
	Position = UDim2.new(0.76, 0, 0.15, 0), -- Sedikit turun agar sejajar dasar angka
	BackgroundTransparency = 1,
	Text = "120",
	TextColor3 = COLORS.TextGray,
	Font = FONTS.Secondary,
	TextSize = 30,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = ammoBox
})

-- Peringatan Low Ammo (Awalnya tidak terlihat)
local lowAmmoLabel = create("TextLabel", {
	Name = "LowAmmoWarning",
	Size = UDim2.new(0.97, 0, 0.2, 0),
	Position = UDim2.new(0, 0, 0.025, 0),
	BackgroundTransparency = 1,
	Text = "LOW AMMO",
	TextColor3 = COLORS.Red,
	Font = FONTS.Secondary,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false,
	Parent = ammoBox
})

-- Container Reload Bar (Di bawah kotak utama)
local reloadContainer = create("Frame", {
	Name = "ReloadContainer",
	Size = UDim2.new(1, 0, 0.04, 0),
	Position = UDim2.new(0, 0, 0.96, 0),
	BackgroundColor3 = COLORS.SlateLight,
	BorderSizePixel = 0,
	BackgroundTransparency = 0.5,
	Visible = false, -- Hanya muncul saat reload
	Parent = ammoBox
})

local reloadFill = create("Frame", {
	Name = "ReloadFill",
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = COLORS.Cyan,
	BorderSizePixel = 0,
	Parent = reloadContainer
})
-- Efek kilau pada bar reload
create("UIGradient", {
	Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, COLORS.Cyan),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 220, 255))
	},
	Parent = reloadFill
})

-- Hint Reload (Di luar kotak utama)
local reloadHint = create("TextLabel", {
	Name = "ReloadHint",
	Size = UDim2.new(1, 0, 0.13, 0),
	Position = UDim2.new(0, 0, 1, 0.03), -- Di bawah mainContainer
	BackgroundTransparency = 1,
	Text = "TEKAN [R] UNTUK RELOAD",
	TextColor3 = COLORS.TextGray,
	Font = FONTS.Detail,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
	Visible = false,
	Parent = mainContainer
})

-- ============================================================================
-- LOGIKA & ANIMASI
-- ============================================================================

local currentTweens = {}

-- Fungsi untuk mendeteksi perangkat mobile
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Update Posisi berdasarkan perangkat
local function updateLayout()
	if isMobile() then
		-- Mobile: Kanan Atas (di bawah minimap biasanya, atau sesuaikan)
		-- Ukuran lebih kecil
		mainContainer.Size = UDim2.new(0.24, 0, 0.12, 0)
		mainContainer.AnchorPoint = Vector2.new(1, 0)
		mainContainer.Position = UDim2.new(0.99, 0, 0, 0.12) -- Sesuaikan Y agar tidak menabrak kontrol lain

		currentAmmoLabel.TextSize = 50
		reserveAmmoLabel.TextSize = 24
		reloadHint.Visible = false -- Mobile tidak butuh hint tombol R
	else
		-- Desktop: Kanan Bawah
		mainContainer.Size = UDim2.new(0.35, 0, 0.17, 0)
		mainContainer.AnchorPoint = Vector2.new(1, 1)
		mainContainer.Position = UDim2.new(0.99, 0, 0.99, 0)

		currentAmmoLabel.TextSize = 70
		reserveAmmoLabel.TextSize = 30
	end
end

-- Jalankan layout awal
updateLayout()
-- Perbarui jika ukuran layar berubah
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)

-- Animasi Low Ammo Pulse
local function setLowAmmoState(isLow)
	if isLow then
		lowAmmoLabel.Visible = true
		rightAccent.BackgroundColor3 = COLORS.Red
		currentAmmoLabel.TextColor3 = COLORS.Red

		if not currentTweens.Pulse then
			local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local tween = TweenService:Create(currentAmmoLabel, tweenInfo, {TextTransparency = 0.4})
			tween:Play()
			currentTweens.Pulse = tween
		end
	else
		lowAmmoLabel.Visible = false
		rightAccent.BackgroundColor3 = COLORS.Cyan
		currentAmmoLabel.TextColor3 = COLORS.White

		if currentTweens.Pulse then
			currentTweens.Pulse:Cancel()
			currentTweens.Pulse = nil
			currentAmmoLabel.TextTransparency = 0
		end
	end
end

-- Logika update utama dari event
AmmoUpdateEvent.OnClientEvent:Connect(function(weaponName, ammo, reserveAmmo, isVisible, isReloading)
	mainContainer.Visible = isVisible

	if not isVisible then return end

	-- Cek Tool yang sedang dipegang untuk update Level
	local currentTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local level = 0

	if currentTool and currentTool.Name == weaponName then
		level = currentTool:GetAttribute("UpgradeLevel") or 0
	end

	-- Update Teks
	weaponNameLabel.Text = string.upper(weaponName)
	levelText.Text = "LV." .. tostring(level)

	-- Logika Reloading
	if isReloading then
		-- Mode Reload
		reloadContainer.Visible = true
		reloadHint.Visible = false
		lowAmmoLabel.Visible = false

		-- Matikan pulse jika ada
		if currentTweens.Pulse then
			currentTweens.Pulse:Cancel()
			currentTweens.Pulse = nil
			currentAmmoLabel.TextTransparency = 0.5 -- Redupkan teks saat reload
		end

		-- Animasi bar reload
		local progress = ammo / 100 -- Ammo dikirim sebagai persentase 0-100 saat reload
		currentAmmoLabel.Text = "..." -- Atau tampilkan persentase

		-- Tween Bar
		if not currentTweens.Reload then
			-- Reset bar jika baru mulai
			if progress < 0.1 then reloadFill.Size = UDim2.new(0,0,1,0) end
		end

		local tween = TweenService:Create(reloadFill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { Size = UDim2.new(progress, 0, 1, 0) })
		tween:Play()
		currentTweens.Reload = tween

	else
		-- Mode Normal
		reloadContainer.Visible = false
		currentAmmoLabel.TextTransparency = 0
		currentAmmoLabel.Text = tostring(ammo)
		reserveAmmoLabel.Text = tostring(reserveAmmo)

		-- Cek Low Ammo
		local maxAmmo = currentTool and currentTool:GetAttribute("CustomMaxAmmo") or 30 -- Fallback
		local isLow = (ammo / maxAmmo) <= LOW_AMMO_PERCENT and ammo > 0

		setLowAmmoState(isLow)

		-- Cek Hint Reload (hanya desktop, jika peluru tidak penuh dan ada cadangan)
		if not isMobile() then
			if ammo < maxAmmo and reserveAmmo > 0 then
				reloadHint.Visible = true
				-- Animasi fade in hint
				if reloadHint.TextTransparency == 1 then
					TweenService:Create(reloadHint, TweenInfo.new(0.3), {TextTransparency = 0.5}):Play()
				end
			else
				reloadHint.Visible = false
				reloadHint.TextTransparency = 1
			end
		end

		-- Efek 'Kick' visual pada container saat menembak (ammo berkurang)
		-- Kita simpan ammo sebelumnya untuk mendeteksi pengurangan
		local lastAmmo = tonumber(mainContainer:GetAttribute("LastAmmo")) or ammo
		if ammo < lastAmmo then
			local kickTween = TweenService:Create(mainContainer, TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true), {
				Position = mainContainer.Position + UDim2.new(0.005, 0, 0, 0) -- Geser sedikit ke kanan
			})
			kickTween:Play()
		end
		mainContainer:SetAttribute("LastAmmo", ammo)
	end
end)

-- Inisialisasi awal (sembunyikan sampai ada event)
mainContainer.Visible = false