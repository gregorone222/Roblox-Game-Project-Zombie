-- UTCClockUI.lua (LocalScript)
-- Path: StarterGui/UTCClockUI
-- Displays UTC time in top-left corner of screen

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === CREATE UI ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UTCClockUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false  -- Respects top bar area
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Container frame
local container = Instance.new("Frame")
container.Name = "ClockContainer"
container.Size = UDim2.new(0, 150, 0, 50)
container.Position = UDim2.new(0, 10, 0, 10)  -- Top-left with padding
container.BackgroundColor3 = Color3.fromRGB(20, 25, 20)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 0
container.Parent = screenGui

-- Rounded corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

-- Stroke border
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 150, 100)
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = container

-- Clock icon (optional decorative)
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.new(0, 30, 1, 0)
icon.Position = UDim2.new(0, 5, 0, 0)
icon.BackgroundTransparency = 1
icon.Font = Enum.Font.GothamBold
icon.TextColor3 = Color3.fromRGB(100, 200, 100)
icon.TextSize = 20
icon.Text = "🕐"
icon.Parent = container

-- Time label
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "TimeLabel"
timeLabel.Size = UDim2.new(1, -40, 0.6, 0)
timeLabel.Position = UDim2.new(0, 35, 0, 2)
timeLabel.BackgroundTransparency = 1
timeLabel.Font = Enum.Font.Code
timeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
timeLabel.TextSize = 18
timeLabel.TextXAlignment = Enum.TextXAlignment.Left
timeLabel.Text = "00:00:00"
timeLabel.Parent = container

-- UTC label
local utcLabel = Instance.new("TextLabel")
utcLabel.Name = "UTCLabel"
utcLabel.Size = UDim2.new(1, -40, 0.4, 0)
utcLabel.Position = UDim2.new(0, 35, 0.6, -2)
utcLabel.BackgroundTransparency = 1
utcLabel.Font = Enum.Font.SourceSans
utcLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
utcLabel.TextSize = 12
utcLabel.TextXAlignment = Enum.TextXAlignment.Left
utcLabel.Text = "UTC Time"
utcLabel.Parent = container

-- === UPDATE LOOP ===

local function getUTCTime()
	local utcTime = os.time(os.date("!*t"))
	return os.date("!*t", utcTime)
end

local function formatTime(hours, minutes, seconds)
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function updateClock()
	local utc = getUTCTime()
	timeLabel.Text = formatTime(utc.hour, utc.min, utc.sec)
end

-- Update every second
RunService.Heartbeat:Connect(function()
	updateClock()
end)

-- Initial update
updateClock()

print("UTCClockUI: Clock display initialized")
