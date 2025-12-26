-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- BossTimerUI.lua (LocalScript)
-- Path: StarterGui/BossTimerUI.lua
-- Script Place: ACT 1: Village
-- Theme: Zombie Apocalypse / Containment Breach HUD

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local BossTimerEvent = RemoteEvents:WaitForChild("BossTimerEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossTimerUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

local timerContainer = nil
local updateConnection = nil

-- State for animation loop
local currentRemainingTime = 0
local cachedElements = {}

-- Tween info for smooth bar
local barTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- --- THEME CONSTANTS ---
local THEME = {
	COLORS = {
		BG_DARK = Color3.fromRGB(15, 5, 5),       -- Almost black red
		BG_PANEL = Color3.fromRGB(30, 10, 10),    -- Deep rusted metal
		ACCENT_RED = Color3.fromRGB(200, 20, 20), -- Fresh blood
		ACCENT_YELLOW = Color3.fromRGB(220, 180, 20), -- Hazard yellow
		TEXT_PRIMARY = Color3.fromRGB(230, 230, 230),
		TEXT_DIM = Color3.fromRGB(150, 100, 100),
		GLOW_CRIT = Color3.fromRGB(255, 0, 0),
		SAFE_GREEN = Color3.fromRGB(50, 180, 80)
	},
	FONTS = {
		HEADER = Enum.Font.Sarpanch, -- Military/Sci-Fi
		DIGITAL = Enum.Font.SciFi,   -- Digital readout
		BODY = Enum.Font.SpecialElite -- Gritty typewriter
	}
}

-- --- UTILITY FUNCTIONS ---

-- Create Hazard Stripes Pattern without assets
local function createHazardPattern(parentFrame)
	local pattern = Instance.new("Frame")
	pattern.Name = "HazardPattern"
	pattern.Size = UDim2.new(1.5, 0, 1.5, 0) -- Larger to allow rotation coverage
	pattern.Position = UDim2.new(-0.25, 0, -0.25, 0)
	pattern.BackgroundColor3 = THEME.COLORS.ACCENT_YELLOW
	pattern.BackgroundTransparency = 0
	pattern.ZIndex = 1
	pattern.ClipsDescendants = true
	pattern.Parent = parentFrame

	-- Simple gradient approach for pattern look
	pattern.BackgroundColor3 = THEME.COLORS.ACCENT_YELLOW
	local grad = Instance.new("UIGradient")

	-- ColorSequence is limited to 20 keypoints.
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.125, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.126, Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(0.25, Color3.new(0,0,0)),

		ColorSequenceKeypoint.new(0.251, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.375, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.376, Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0,0,0)),

		ColorSequenceKeypoint.new(0.501, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.625, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.626, Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(0.75, Color3.new(0,0,0)),

		ColorSequenceKeypoint.new(0.751, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.875, THEME.COLORS.ACCENT_YELLOW),
		ColorSequenceKeypoint.new(0.876, Color3.new(0,0,0)),
		ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
	})

	grad.Rotation = 60
	grad.Parent = pattern

	return pattern
end

local function createGlitchText(parent, text, font, size, color, pos, zindex)
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.BackgroundTransparency = 1
	label.Position = pos
	label.Size = UDim2.new(1, 0, 1, 0) -- Fill parent usually
	label.ZIndex = zindex or 2
	label.Parent = parent

	-- Shadow/Glitch Copy
	local shadow = label:Clone()
	shadow.Name = "GlitchShadow"
	shadow.TextColor3 = Color3.fromRGB(255, 0, 0)
	shadow.TextTransparency = 0.8
	shadow.Position = UDim2.new(0, 2, 0, 2)
	shadow.ZIndex = (zindex or 2) - 1
	shadow.Parent = label

	return label
end

-- --- UI CREATION ---

local function createTimerUI()
	if timerContainer then return end

	local isMobile = UserInputService.TouchEnabled

	-- 1. Main Widget Container
	timerContainer = Instance.new("Frame")
	timerContainer.Name = "ContainmentMonitor"
	timerContainer.Size = isMobile and UDim2.new(0.7, 0, 0, 100) or UDim2.new(0, 450, 0, 120)
	timerContainer.Position = UDim2.new(0.5, 0, 0.05, 0)
	timerContainer.AnchorPoint = Vector2.new(0.5, 0)
	timerContainer.BackgroundTransparency = 1 -- Custom BG constructed below
	timerContainer.Parent = screenGui

	-- 2. Visual Structure (The "Device")
	-- Main Panel
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(1, 0, 1, 0)
	mainPanel.BackgroundColor3 = THEME.COLORS.BG_PANEL
	mainPanel.BorderSizePixel = 0
	mainPanel.Parent = timerContainer

	-- Rough Border
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(60, 20, 20)
	stroke.Parent = mainPanel

	-- Top Hazard Strip
	local hazardStrip = Instance.new("Frame")
	hazardStrip.Name = "HazardStrip"
	hazardStrip.Size = UDim2.new(1, 0, 0, 12)
	hazardStrip.Position = UDim2.new(0, 0, 0, 0)
	hazardStrip.ClipsDescendants = true
	hazardStrip.BorderSizePixel = 0
	hazardStrip.Parent = mainPanel

	createHazardPattern(hazardStrip)

	-- Dark Inner Display
	local displayScreen = Instance.new("Frame")
	displayScreen.Name = "DisplayScreen"
	displayScreen.Size = UDim2.new(0.95, 0, 0.75, 0)
	displayScreen.Position = UDim2.new(0.5, 0, 0.55, 0)
	displayScreen.AnchorPoint = Vector2.new(0.5, 0.5)
	displayScreen.BackgroundColor3 = Color3.new(0, 0, 0)
	displayScreen.BorderColor3 = Color3.fromRGB(80, 0, 0)
	displayScreen.Parent = mainPanel

	-- Scanline Effect (Fake)
	local scanlines = Instance.new("Frame")
	scanlines.Size = UDim2.new(1, 0, 1, 0)
	scanlines.BackgroundColor3 = Color3.new(1,1,1)
	scanlines.BackgroundTransparency = 0.95
	scanlines.BorderSizePixel = 0
	scanlines.ZIndex = 5
	scanlines.Parent = displayScreen

	local slGrad = Instance.new("UIGradient")
	slGrad.Rotation = 90
	slGrad.Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0))
	slGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	slGrad.Parent = scanlines

	-- 3. Content

	-- Header Label (On Hazard Strip)
	local headerLbl = Instance.new("TextLabel")
	headerLbl.Text = "⚠ CONTAINMENT BREACH DETECTED ⚠"
	headerLbl.Size = UDim2.new(1, 0, 1, 0)
	headerLbl.BackgroundTransparency = 1
	headerLbl.Font = Enum.Font.GothamBold
	headerLbl.TextSize = 10
	headerLbl.TextColor3 = Color3.new(0,0,0) -- Black on Yellow
	headerLbl.Parent = hazardStrip

	-- Boss Name (Left)
	local nameLabel = createGlitchText(
		displayScreen, 
		"TARGET: UNKNOWN", 
		THEME.FONTS.HEADER, 
		20, 
		THEME.COLORS.ACCENT_RED, 
		UDim2.new(0, 10, 0, 5)
	)
	nameLabel.Name = "BossName"
	nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Phase Label (Under Name)
	local phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "PhaseLabel"
	phaseLabel.Text = "STATUS: ACTIVE"
	phaseLabel.Font = THEME.FONTS.BODY
	phaseLabel.TextSize = 12
	phaseLabel.TextColor3 = THEME.COLORS.TEXT_DIM
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Position = UDim2.new(0, 10, 0, 30)
	phaseLabel.Size = UDim2.new(0.6, 0, 0, 15)
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
	phaseLabel.Parent = displayScreen

	-- Timer (Right)
	local timeLabel = createGlitchText(
		displayScreen,
		"00:00",
		THEME.FONTS.DIGITAL,
		32,
		THEME.COLORS.TEXT_PRIMARY,
		UDim2.new(0.65, 0, 0, 5)
	)
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0.3, 0, 0, 40)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- Integrity Meter (Bottom of Display)
	local meterFrame = Instance.new("Frame")
	meterFrame.Name = "MeterFrame"
	meterFrame.Size = UDim2.new(0.95, 0, 0, 6)
	meterFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
	meterFrame.AnchorPoint = Vector2.new(0.5, 0)
	meterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	meterFrame.BorderSizePixel = 0
	meterFrame.Parent = displayScreen

	local meterFill = Instance.new("Frame")
	meterFill.Name = "Fill"
	meterFill.Size = UDim2.new(1, 0, 1, 0)
	meterFill.BackgroundColor3 = Color3.new(1,1,1)
	meterFill.BorderSizePixel = 0
	meterFill.Parent = meterFrame

	local mGrad = Instance.new("UIGradient")
	mGrad.Color = ColorSequence.new(THEME.COLORS.SAFE_GREEN, THEME.COLORS.ACCENT_RED)
	mGrad.Parent = meterFill

	-- Small Text "INTEGRITY"
	local integLbl = Instance.new("TextLabel")
	integLbl.Text = "FAILSAFE INTEGRITY"
	integLbl.Font = Enum.Font.Code
	integLbl.TextSize = 8
	integLbl.TextColor3 = THEME.COLORS.TEXT_DIM
	integLbl.BackgroundTransparency = 1
	integLbl.Position = UDim2.new(0, 0, -1.5, 0)
	integLbl.Size = UDim2.new(1, 0, 1, 0)
	integLbl.Parent = meterFrame

	-- Cache elements for optimized loop
	cachedElements = {
		container = timerContainer,
		nameLbl = nameLabel,
		timeLbl = timeLabel,
		shadow = timeLabel:FindFirstChild("GlitchShadow"),
		fill = meterFill
	}
end

local function destroyTimerUI()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
	if timerContainer then
		timerContainer:Destroy()
		timerContainer = nil
	end
	cachedElements = {}
end


-- --- ANIMATION & LOGIC ---

local lastShakeTime = 0
local shakeIntensity = 0

local function updateEffects(dt)
	if not cachedElements.container or not cachedElements.container.Parent then return end

	-- Use file-level variable 'currentRemainingTime'
	local remTime = currentRemainingTime

	local nameLbl = cachedElements.nameLbl
	local timeLbl = cachedElements.timeLbl
	local shadow = cachedElements.shadow

	-- 1. Heartbeat Pulse (Critical Time)
	if remTime <= 30 then
		local pulseSpeed = (30 - remTime) * 0.5 + 5 -- Faster as time drops
		local scale = 1 + (math.sin(tick() * pulseSpeed) * 0.05)
		timeLbl.TextSize = 32 * scale
		timeLbl.TextColor3 = Color3.new(1, 0, 0) -- Turn red

		-- Shadow shake
		if shadow then
			shadow.Position = UDim2.new(0, math.random(-2,2), 0, math.random(-2,2))
			shadow.TextTransparency = 0.5
		end
	else
		timeLbl.TextSize = 32
		timeLbl.TextColor3 = THEME.COLORS.TEXT_PRIMARY
		if shadow then
			shadow.Position = UDim2.new(0, 2, 0, 2)
			shadow.TextTransparency = 0.8
		end
	end

	-- 2. Container Shake (Very Critical)
	if remTime <= 10 then
		shakeIntensity = (10 - remTime) * 0.5
		local ox = math.random(-1, 1) * shakeIntensity
		local oy = math.random(-1, 1) * shakeIntensity
		cachedElements.container.Position = UDim2.new(0.5, ox, 0.05, oy)
	else
		cachedElements.container.Position = UDim2.new(0.5, 0, 0.05, 0)
	end

	-- 3. Random Glitch on Name
	if math.random() > 0.98 then
		nameLbl.Position = UDim2.new(0, 10 + math.random(-2,2), 0, 5 + math.random(-2,2))
	else
		nameLbl.Position = UDim2.new(0, 10, 0, 5)
	end
end

local function updateTimerUI(remainingTime, totalTime, bossName, phase)
	if not timerContainer then return end

	-- Update state
	currentRemainingTime = remainingTime

	local display = timerContainer:FindFirstChild("MainPanel"):FindFirstChild("DisplayScreen")
	if not display then return end

	-- Update Text
	local nameLbl = cachedElements.nameLbl
	local phaseLbl = display:FindFirstChild("PhaseLabel")
	local timeLbl = cachedElements.timeLbl
	local fill = cachedElements.fill

	if bossName and nameLbl then nameLbl.Text = "TARGET: " .. string.upper(bossName) end
	if phase and phaseLbl then phaseLbl.Text = "STATUS: " .. string.upper(phase) end

	local m = math.floor(remainingTime / 60)
	local s = math.floor(remainingTime % 60)
	if timeLbl then timeLbl.Text = string.format("%02d:%02d", m, s) end

	-- Update Bar with Smooth Tween
	if fill then
		local pct = math.clamp(remainingTime / totalTime, 0, 1)

		-- Use TweenService for smooth slide
		local tween = TweenService:Create(fill, barTweenInfo, {Size = UDim2.new(pct, 0, 1, 0)})
		tween:Play()

		-- Color Shift Green -> Red based on percentage
		fill.BackgroundColor3 = THEME.COLORS.ACCENT_RED:Lerp(THEME.COLORS.SAFE_GREEN, pct)
	end
end

BossTimerEvent.OnClientEvent:Connect(function(remainingTime, totalTime, bossName, phase)
	if remainingTime <= 0 then
		destroyTimerUI()
	else
		if not timerContainer then
			createTimerUI()
			-- Start Render Loop for effects
			if not updateConnection then
				updateConnection = RunService.RenderStepped:Connect(function(dt)
					updateEffects(dt) 
				end)
			end
		end

		updateTimerUI(remainingTime, totalTime, bossName, phase)
	end
end)

-- Cleanup on respawn
player.CharacterAdded:Connect(function()
	destroyTimerUI()
end)
