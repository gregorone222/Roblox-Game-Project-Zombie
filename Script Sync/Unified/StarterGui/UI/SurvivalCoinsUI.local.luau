-- SurvivalCoinsUI.local.luau (LocalScript)
-- Path: StarterGui/UI/SurvivalCoinsUI.local.luau
-- Script Place: Lobby
-- Revisi: Peningkatan Visual

-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Tambahkan TweenService

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SurvivalCoinsUpdateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SurvivalCoinsUpdateEvent")

-- Hapus UI lama jika ada untuk mencegah duplikasi
if playerGui:FindFirstChild("SurvivalCoinsUI") then
	playerGui.SurvivalCoinsUI:Destroy()
end

-- ======================================================
-- CONFIGURATION - Warm "Cozy Apocalypse" Theme
-- ======================================================
local COLORS = {
	Background = Color3.fromRGB(25, 18, 12), -- Warm dark brown
	Border = Color3.fromRGB(218, 165, 32), -- Golden
	IconBg = Color3.fromRGB(45, 32, 20), -- Dark warm brown
	TextLabel = Color3.fromRGB(180, 160, 130), -- Muted gold
	TextValue = Color3.fromRGB(255, 223, 128), -- Bright gold
	Highlight = Color3.fromRGB(255, 200, 80) -- Gold highlight
}

local ICON_ASSET_ID = "rbxassetid://89004651637769" -- Survival Coin icon

-- ======================================================
-- PEMBUATAN UI
-- ======================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SurvivalCoinsUI"
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Card Container
local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0, 0)
container.Position = UDim2.new(0.5, 10, 0, 10)
container.Size = UDim2.new(0, 220, 0, 55)
container.BackgroundColor3 = COLORS.Background
container.BackgroundTransparency = 0.15
container.BorderSizePixel = 0
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = container

local stroke = Instance.new("UIStroke")
stroke.Color = COLORS.Border
stroke.Thickness = 1.5
stroke.Transparency = 0.6
stroke.Parent = container

-- Icon Container (Circle)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.BackgroundColor3 = COLORS.IconBg
iconContainer.BackgroundTransparency = 0.3
iconContainer.Size = UDim2.new(0, 40, 0, 40)
iconContainer.Position = UDim2.new(0, 8, 0.5, 0)
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.Parent = container

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconContainer

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = COLORS.Border
iconStroke.Transparency = 0.5
iconStroke.Thickness = 1.5
iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
iconStroke.Parent = iconContainer

-- Icon Image (Using Asset ID)
local iconImage = Instance.new("ImageLabel")
iconImage.Name = "Icon"
iconImage.Size = UDim2.new(0.8, 0, 0.8, 0)
iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
iconImage.BackgroundTransparency = 1
iconImage.Image = ICON_ASSET_ID
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.Parent = iconContainer

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.BackgroundTransparency = 1
contentFrame.Size = UDim2.new(1, -58, 1, -8)
contentFrame.Position = UDim2.new(0, 55, 0, 4)
contentFrame.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, -2)
listLayout.Parent = contentFrame

-- Label "SURVIVAL COINS"
local labelText = Instance.new("TextLabel")
labelText.Name = "Label"
labelText.BackgroundTransparency = 1
labelText.Size = UDim2.new(1, 0, 0, 12)
labelText.Text = "SURVIVAL COINS"
labelText.TextColor3 = COLORS.TextLabel
labelText.TextXAlignment = Enum.TextXAlignment.Left
labelText.Font = Enum.Font.GothamBold
labelText.TextSize = 10
labelText.LayoutOrder = 1
labelText.Parent = contentFrame

-- Value Number
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.BackgroundTransparency = 1
coinsLabel.Size = UDim2.new(1, 0, 0, 28)
coinsLabel.Text = "..."
coinsLabel.TextColor3 = COLORS.TextValue
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 26
coinsLabel.LayoutOrder = 2
coinsLabel.ZIndex = 2
coinsLabel.Parent = contentFrame

-- Gradient for value text
local valueGradient = Instance.new("UIGradient")
valueGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 223, 128)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(218, 165, 32))
})
valueGradient.Rotation = 90
valueGradient.Parent = coinsLabel

-- ======================================================
-- LOGIKA UI
-- ======================================================

local currentCoins = 0 -- Untuk animasi hitung

-- Fungsi untuk memperbarui UI dengan animasi
local function updateCoinsUI(newCoins)
	if not newCoins then return end

	-- Hentikan tween yang sedang berjalan jika ada
	if container:FindFirstChild("CountTween") then
		container.CountTween:Cancel()
		container.CountTween:Destroy()
	end

	local startValue = currentCoins
	local diff = newCoins - startValue

	-- Buat NumberValue sementara untuk di-tween
	local tweenValue = Instance.new("NumberValue")
	tweenValue.Name = "CountTween"
	tweenValue.Value = startValue
	tweenValue.Parent = container

	-- Animasi hitung angka
	local countTween = TweenService:Create(tweenValue, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = newCoins})
	countTween:Play()

	-- Update teks label setiap frame selama tween berjalan
	local connection
	-- Format number with dots for thousands
	local function formatNumber(n)
		local formatted = tostring(n)
		while true do
			local k
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
			if (k==0) then break end
		end
		return formatted
	end

	connection = tweenValue:GetPropertyChangedSignal("Value"):Connect(function()
		coinsLabel.Text = formatNumber(math.floor(tweenValue.Value + 0.5))
	end)

	-- Setelah tween selesai
	countTween.Completed:Connect(function()
		if connection then connection:Disconnect() end
		coinsLabel.Text = formatNumber(newCoins) -- Pastikan nilai akhir benar
		currentCoins = newCoins -- Update nilai saat ini
		tweenValue:Destroy() -- Hapus NumberValue sementara
	end)

	-- Animasi highlight singkat saat koin bertambah
	if diff > 0 then
		local highlightTween = TweenService:Create(container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {BackgroundColor3 = COLORS.Highlight})
		highlightTween:Play()
		-- Efek suara (opsional)
		-- local sound = Instance.new("Sound", container)
		-- sound.SoundId = "rbxassetid://YOUR_SOUND_ID" -- Ganti dengan ID suara
		-- sound.Volume = 0.5
		-- sound:Play()
		-- game:GetService("Debris"):AddItem(sound, 2)
	end
end

-- Dengarkan event dari server
SurvivalCoinsUpdateEvent.OnClientEvent:Connect(updateCoinsUI)

-- Muat nilai awal (jika diperlukan)
-- Anda bisa menggunakan RemoteFunction untuk meminta nilai awal saat pemain masuk
-- Contoh:
-- local getInitialCoins = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetInitialCoins")
-- local initialCoins = getInitialCoins:InvokeServer()
-- updateCoinsUI(initialCoins)
-- Note: Pastikan RemoteFunction GetInitialCoins dibuat di server.
-- Untuk saat ini, kita anggap nilai awal akan dikirim oleh server via SurvivalCoinsUpdateEvent.