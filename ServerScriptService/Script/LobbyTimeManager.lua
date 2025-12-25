-- LobbyTimeManager.lua (Script)
-- Path: ServerScriptService/Script/LobbyTimeManager.lua
-- Manages real-time UTC clock display and dynamic day/night lighting in lobby

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- === CONFIGURATION ===
local TIME_SCALE = 1  -- Real-time (1 = 1 real second = 1 game second)
local UPDATE_INTERVAL = 1  -- Update every second
local NIGHT_START_HOUR = 18  -- 6 PM
local NIGHT_END_HOUR = 6     -- 6 AM
local DAWN_DURATION = 1      -- Hour
local DUSK_DURATION = 1      -- Hour

-- Lighting presets for different times
local LIGHTING_PRESETS = {
	Dawn = {
		ClockTime = 6,
		Brightness = 1.5,
		Ambient = Color3.fromRGB(120, 100, 80),
		OutdoorAmbient = Color3.fromRGB(140, 120, 90),
		FogColor = Color3.fromRGB(180, 150, 120),
		FogEnd = 500,
	},
	Day = {
		ClockTime = 12,
		Brightness = 2.5,
		Ambient = Color3.fromRGB(150, 150, 150),
		OutdoorAmbient = Color3.fromRGB(180, 180, 180),
		FogColor = Color3.fromRGB(200, 200, 210),
		FogEnd = 800,
	},
	Dusk = {
		ClockTime = 18,
		Brightness = 2,
		Ambient = Color3.fromRGB(100, 80, 60),
		OutdoorAmbient = Color3.fromRGB(120, 100, 70),
		FogColor = Color3.fromRGB(200, 160, 130),
		FogEnd = 400,
	},
	Night = {
		ClockTime = 0,
		Brightness = 0.5,
		Ambient = Color3.fromRGB(40, 40, 60),
		OutdoorAmbient = Color3.fromRGB(30, 30, 50),
		FogColor = Color3.fromRGB(50, 50, 70),
		FogEnd = 300,
	}
}

-- === STATE ===
local lightsOn = false
local lightParts = {}
local clockDisplay = nil

-- === HELPER FUNCTIONS ===

local function getUTCTime()
	-- Get current UTC time
	local utcTime = os.time(os.date("!*t"))
	return os.date("!*t", utcTime)
end

local function formatTime(hours, minutes)
	return string.format("%02d:%02d UTC", hours, minutes)
end

local function isNightTime(hour)
	return hour >= NIGHT_START_HOUR or hour < NIGHT_END_HOUR
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
	return Color3.new(
		lerp(c1.R, c2.R, t),
		lerp(c1.G, c2.G, t),
		lerp(c1.B, c2.B, t)
	)
end

-- === CLOCK DISPLAY ===

local function createClockDisplay()
	local env = Workspace:FindFirstChild("LobbyEnvironment")
	if not env then return end
	
	-- Find or create clock
	local existing = env:FindFirstChild("UTCClock")
	if existing then existing:Destroy() end
	
	-- Create clock structure
	local clock = Instance.new("Model")
	clock.Name = "UTCClock"
	clock.Parent = env
	
	-- Clock board (near spawn/house)
	local board = Instance.new("Part")
	board.Name = "ClockBoard"
	board.Size = Vector3.new(8, 4, 0.5)
	board.CFrame = CFrame.new(20, 8, -5) * CFrame.Angles(0, math.rad(-30), 0)
	board.Anchored = true
	board.Material = Enum.Material.Wood
	board.Color = Color3.fromRGB(70, 50, 35)
	board.Parent = clock
	
	-- Surface GUI for clock display
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ClockGUI"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board
	
	-- Background frame
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 25, 20)
	bg.BorderSizePixel = 0
	bg.Parent = surfaceGui
	
	-- Time label
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, 0, 0.6, 0)
	timeLabel.Position = UDim2.new(0, 0, 0.1, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.Code
	timeLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	timeLabel.TextScaled = true
	timeLabel.Text = "00:00 UTC"
	timeLabel.Parent = bg
	
	-- Daily reset label
	local resetLabel = Instance.new("TextLabel")
	resetLabel.Name = "ResetLabel"
	resetLabel.Size = UDim2.new(1, 0, 0.25, 0)
	resetLabel.Position = UDim2.new(0, 0, 0.7, 0)
	resetLabel.BackgroundTransparency = 1
	resetLabel.Font = Enum.Font.SourceSans
	resetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
	resetLabel.TextScaled = true
	resetLabel.Text = "Daily Reset: 00:00 UTC"
	resetLabel.Parent = bg
	
	clockDisplay = timeLabel
	return clock
end

local function updateClockDisplay()
	if not clockDisplay then return end
	
	local utc = getUTCTime()
	clockDisplay.Text = formatTime(utc.hour, utc.min)
end

-- === DYNAMIC LIGHTING ===

local function getTimeOfDayPreset(hour)
	if hour >= 6 and hour < 7 then
		return "Dawn", (hour - 6) / DAWN_DURATION
	elseif hour >= 7 and hour < 17 then
		return "Day", 1
	elseif hour >= 17 and hour < 18 then
		return "Dusk", (hour - 17) / DUSK_DURATION
	else
		return "Night", 1
	end
end

local function applyLightingPreset(presetName, blend)
	local preset = LIGHTING_PRESETS[presetName]
	if not preset then return end
	
	-- For transitions, blend between current and target
	if blend < 1 then
		local prevPreset
		if presetName == "Dawn" then
			prevPreset = LIGHTING_PRESETS.Night
		elseif presetName == "Dusk" then
			prevPreset = LIGHTING_PRESETS.Day
		else
			prevPreset = preset
		end
		
		Lighting.Brightness = lerp(prevPreset.Brightness, preset.Brightness, blend)
		Lighting.Ambient = lerpColor(prevPreset.Ambient, preset.Ambient, blend)
		Lighting.OutdoorAmbient = lerpColor(prevPreset.OutdoorAmbient, preset.OutdoorAmbient, blend)
		Lighting.FogColor = lerpColor(prevPreset.FogColor, preset.FogColor, blend)
		Lighting.FogEnd = lerp(prevPreset.FogEnd, preset.FogEnd, blend)
	else
		Lighting.Brightness = preset.Brightness
		Lighting.Ambient = preset.Ambient
		Lighting.OutdoorAmbient = preset.OutdoorAmbient
		Lighting.FogColor = preset.FogColor
		Lighting.FogEnd = preset.FogEnd
	end
end

local function updateDayNightCycle()
	local utc = getUTCTime()
	local hour = utc.hour + utc.min / 60
	
	-- Set game clock to match UTC
	Lighting.ClockTime = hour
	
	-- Apply lighting preset
	local preset, blend = getTimeOfDayPreset(hour)
	applyLightingPreset(preset, blend)
	
	-- Toggle lights based on time
	local shouldLightsBeOn = isNightTime(utc.hour)
	if shouldLightsBeOn ~= lightsOn then
		toggleLights(shouldLightsBeOn)
	end
end

-- === LIGHT SOURCES (Lanterns, Torches) ===

local function findLightParts()
	lightParts = {}
	
	local env = Workspace:FindFirstChild("LobbyEnvironment")
	if not env then return end
	
	-- Find all parts with PointLight children
	for _, desc in ipairs(env:GetDescendants()) do
		if desc:IsA("PointLight") then
			table.insert(lightParts, {
				light = desc,
				originalBrightness = desc.Brightness,
				originalEnabled = desc.Enabled
			})
		end
	end
	
	print("LobbyTimeManager: Found " .. #lightParts .. " light sources")
end

function toggleLights(on)
	lightsOn = on
	
	for _, lightData in ipairs(lightParts) do
		lightData.light.Enabled = on
		if on then
			lightData.light.Brightness = lightData.originalBrightness
		end
	end
	
	-- Toggle Fire effects too
	local env = Workspace:FindFirstChild("LobbyEnvironment")
	if env then
		for _, desc in ipairs(env:GetDescendants()) do
			if desc:IsA("Fire") then
				desc.Enabled = on
			end
		end
	end
	
	print("LobbyTimeManager: Lights " .. (on and "ON" or "OFF"))
end

-- === INITIALIZATION ===

local function initialize()
	print("LobbyTimeManager: Initializing...")
	
	-- Wait for lobby to be built
	local env = Workspace:WaitForChild("LobbyEnvironment", 30)
	if not env then
		warn("LobbyTimeManager: LobbyEnvironment not found!")
		return
	end
	
	-- Create clock display
	createClockDisplay()
	
	-- Find existing lights
	task.wait(1) -- Wait for lights to be created
	findLightParts()
	
	-- Initial update
	updateDayNightCycle()
	updateClockDisplay()
	
	-- Start update loop
	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			updateDayNightCycle()
			updateClockDisplay()
		end
	end)
	
	print("LobbyTimeManager: Ready! Using real UTC time.")
end

-- Run initialization
task.spawn(initialize)
