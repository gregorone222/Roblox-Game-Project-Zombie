-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- MissionPointsUI.lua (LocalScript)
-- Path: StarterGui/MissionPointsUI.lua
-- Script Place: Lobby
-- Theme: Cozy Apocalypse

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus UI lama jika ada untuk mencegah duplikasi saat respawn
if playerGui:FindFirstChild("MissionPointsUI") then
	playerGui.MissionPointsUI:Destroy()
end

-- ======================================================
-- THEME CONSTANTS (Matching UI Master Guide)
-- ======================================================
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),
		Panel = Color3.fromRGB(35, 28, 22),
		AccentMain = Color3.fromRGB(218, 165, 32),
		AccentSecondary = Color3.fromRGB(139, 90, 43),
		TextHigh = Color3.fromRGB(255, 248, 230),
		TextMid = Color3.fromRGB(180, 160, 130),
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
	}
}

local ASSETS = {
	MissionPointIcon = "rbxassetid://126182178056637"
}

-- ======================================================
-- HELPER FUNCTIONS
-- ======================================================
local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

-- ======================================================
-- PEMBUATAN UI
-- ======================================================
local screenGui = create("ScreenGui", {
	Name = "MissionPointsUI", Parent = playerGui,
	ResetOnSpawn = false, IgnoreGuiInset = true
})

-- Main Container
local container = create("Frame", {
	Name = "MPContainer", Parent = screenGui,
	Size = UDim2.fromScale(0.12, 0.045),
	Position = UDim2.fromScale(0.74, 0.01),
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.2
})
create("UICorner", {Parent = container, CornerRadius = UDim.new(0.3, 0)})
create("UIStroke", {Parent = container, Color = THEME.Colors.AccentSecondary, Thickness = 2, Transparency = 0.5})

-- Icon Container
local iconContainer = create("Frame", {
	Parent = container,
	Size = UDim2.fromScale(0.25, 0.8),
	Position = UDim2.fromScale(0.02, 0.1),
	BackgroundColor3 = THEME.Colors.AccentSecondary,
	BackgroundTransparency = 0.7
})
create("UICorner", {Parent = iconContainer, CornerRadius = UDim.new(0.3, 0)})
create("UIAspectRatioConstraint", {Parent = iconContainer, AspectRatio = 1})

-- Icon Image
local iconImage = create("ImageLabel", {
	Parent = iconContainer,
	Size = UDim2.fromScale(0.8, 0.8),
	Position = UDim2.fromScale(0.1, 0.1),
	BackgroundTransparency = 1,
	Image = ASSETS.MissionPointIcon,
	ScaleType = Enum.ScaleType.Fit
})

-- Points Label
local pointsLabel = create("TextLabel", {
	Name = "PointsLabel", Parent = container,
	Size = UDim2.fromScale(0.65, 0.8),
	Position = UDim2.fromScale(0.32, 0.1),
	BackgroundTransparency = 1,
	Font = THEME.Fonts.Header,
	TextColor3 = THEME.Colors.TextHigh,
	TextScaled = true,
	Text = "...",
	TextXAlignment = Enum.TextXAlignment.Right
})
create("UITextSizeConstraint", {Parent = pointsLabel, MaxTextSize = 24, MinTextSize = 10})
create("UIPadding", {Parent = pointsLabel, PaddingRight = UDim.new(0.05, 0)})

-- ======================================================
-- LOGIKA UI
-- ======================================================
local getInitialMissionPoints = ReplicatedStorage:WaitForChild("GetInitialMissionPoints")
local missionPointsChanged = ReplicatedStorage:WaitForChild("MissionPointsChanged")

local function animateUpdate()
	local originalColor = pointsLabel.TextColor3
	pointsLabel.TextColor3 = THEME.Colors.AccentMain
	TweenService:Create(pointsLabel, TweenInfo.new(0.5), {TextColor3 = originalColor}):Play()
end

local function updatePointsLabel(points)
	pointsLabel.Text = tostring(points)
	animateUpdate()
end

local function loadInitialPoints()
	local success, initialPoints = pcall(function()
		return getInitialMissionPoints:InvokeServer()
	end)
	if success then
		pointsLabel.Text = tostring(initialPoints)
	else
		warn("Gagal mendapatkan Mission Points awal:", initialPoints)
		pointsLabel.Text = "?"
	end
end

missionPointsChanged.OnClientEvent:Connect(function(newPoints)
	updatePointsLabel(newPoints)
end)

loadInitialPoints()