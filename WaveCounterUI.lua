-- WaveCounterUI.lua (LocalScript)
-- Path: StarterGui/WaveCounterUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local WaveUpdateEvent = RemoteEvents:WaitForChild("WaveUpdateEvent")
local WaveCountdownEvent = RemoteEvents:WaitForChild("WaveCountdownEvent")
local ObjectiveUpdateEvent = RemoteEvents:WaitForChild("ObjectiveUpdateEvent")

-- Note: GameConfig is server-side, so we use defaults here or rely on events
local ZOMBIES_PER_PLAYER_DEFAULT = 5

-- --- CONFIGURATION & CONSTANTS (HAZARD MONITOR THEME) ---
local COLORS = {
	BG_METAL = Color3.fromRGB(25, 25, 30), -- Dark Metal
	ACCENT_HAZARD = Color3.fromRGB(255, 180, 0), -- Warning Yellow/Orange
	ACCENT_TOXIC = Color3.fromRGB(100, 255, 50), -- Toxic Green
	ACCENT_CRITICAL = Color3.fromRGB(255, 40, 40), -- Critical Red
	TEXT_DARK = Color3.fromRGB(10, 10, 10),
	TEXT_LIGHT = Color3.fromRGB(240, 240, 240),
	BAR_FILL = Color3.fromRGB(200, 30, 30), -- Deep Red for Infection
}

local FONTS = {
	TECH = Enum.Font.Sarpanch, -- Scavenged Tech look
	HORROR = Enum.Font.Creepster, -- The horror element
	DIGITAL = Enum.Font.Code, -- Countdown timer
}

-- --- UI CREATION ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveCounterUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- 1. Main Container (Asymmetrical "Field Monitor")
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 350, 0, 80)
container.Position = UDim2.new(0.5, 0, 0.02, 0)
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = screenGui

-- 1a. Wave Badge (Left Side - Hexagon/Blocky)
local waveBadge = Instance.new("Frame")
waveBadge.Name = "WaveBadge"
waveBadge.Size = UDim2.new(0, 80, 0, 80)
waveBadge.Position = UDim2.new(0, 0, 0, 0)
waveBadge.BackgroundColor3 = COLORS.BG_METAL
waveBadge.BorderSizePixel = 0
waveBadge.ZIndex = 2
waveBadge.Parent = container

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = COLORS.ACCENT_HAZARD
badgeStroke.Thickness = 3
badgeStroke.Parent = waveBadge

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0.2, 0) -- Slightly rounded square
badgeCorner.Parent = waveBadge

local waveTitle = Instance.new("TextLabel")
waveTitle.Name = "Title"
waveTitle.Text = "WAVE"
waveTitle.Font = FONTS.TECH
waveTitle.TextSize = 14
waveTitle.TextColor3 = COLORS.ACCENT_HAZARD
waveTitle.Size = UDim2.new(1, 0, 0, 20)
waveTitle.Position = UDim2.new(0, 0, 0, 5)
waveTitle.BackgroundTransparency = 1
waveTitle.ZIndex = 3
waveTitle.Parent = waveBadge

local waveNumber = Instance.new("TextLabel")
waveNumber.Name = "Number"
waveNumber.Text = "1"
waveNumber.Font = FONTS.HORROR
waveNumber.TextSize = 52
waveNumber.TextColor3 = COLORS.TEXT_LIGHT
waveNumber.Size = UDim2.new(1, 0, 1, -15)
waveNumber.Position = UDim2.new(0, 0, 0, 15)
waveNumber.BackgroundTransparency = 1
waveNumber.ZIndex = 3
waveNumber.Parent = waveBadge

-- 1b. Status Bar Container (Extending Right)
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.Size = UDim2.new(1, -70, 0, 50) -- Overlap slightly
statusPanel.Position = UDim2.new(0, 70, 0, 15)
statusPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statusPanel.BackgroundTransparency = 0.2
statusPanel.BorderSizePixel = 0
statusPanel.ZIndex = 1
statusPanel.Parent = container

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusPanel

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(60, 60, 60)
statusStroke.Thickness = 2
statusStroke.Parent = statusPanel

-- Hazard Stripes (Top Decoration)
local hazardStrip = Instance.new("Frame")
hazardStrip.Name = "HazardStrip"
hazardStrip.Size = UDim2.new(1, -10, 0, 4)
hazardStrip.Position = UDim2.new(0, 5, 0, 0)
hazardStrip.BackgroundColor3 = COLORS.ACCENT_HAZARD
hazardStrip.BorderSizePixel = 0
hazardStrip.Parent = statusPanel

-- 2. Combat Content
local combatContent = Instance.new("Frame")
combatContent.Name = "CombatContent"
combatContent.Size = UDim2.new(1, 0, 1, 0)
combatContent.BackgroundTransparency = 1
combatContent.Parent = statusPanel

-- Label "INFECTION DENSITY"
local infLabel = Instance.new("TextLabel")
infLabel.Text = "INFECTION DENSITY"
infLabel.Font = FONTS.TECH
infLabel.TextSize = 12
infLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infLabel.Size = UDim2.new(1, -20, 0, 20)
infLabel.Position = UDim2.new(0, 15, 0, 8)
infLabel.TextXAlignment = Enum.TextXAlignment.Left
infLabel.BackgroundTransparency = 1
infLabel.Parent = combatContent

-- The Bar
local barContainer = Instance.new("Frame")
barContainer.Name = "BarContainer"
barContainer.Size = UDim2.new(1, -30, 0, 10)
barContainer.Position = UDim2.new(0, 15, 0, 30)
barContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
barContainer.BorderSizePixel = 0
barContainer.Parent = combatContent

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = COLORS.BAR_FILL
barFill.BorderSizePixel = 0
barFill.Parent = barContainer

-- Percentage
local pctLabel = Instance.new("TextLabel")
pctLabel.Name = "Percent"
pctLabel.Text = "100%"
pctLabel.Font = FONTS.DIGITAL
pctLabel.TextSize = 14
pctLabel.TextColor3 = COLORS.ACCENT_CRITICAL
pctLabel.Size = UDim2.new(0, 50, 0, 20)
pctLabel.Position = UDim2.new(1, -55, 0, 8)
pctLabel.TextXAlignment = Enum.TextXAlignment.Right
pctLabel.BackgroundTransparency = 1
pctLabel.Parent = combatContent


-- 3. Intermission Content (Safe Zone)
local safeContent = Instance.new("Frame")
safeContent.Name = "SafeContent"
safeContent.Size = UDim2.new(1, 0, 1, 0)
safeContent.BackgroundTransparency = 1
safeContent.Visible = false
safeContent.Parent = statusPanel

-- "SAFE ZONE" Label
local safeLabel = Instance.new("TextLabel")
safeLabel.Text = "/// SAFE ZONE ///"
safeLabel.Font = FONTS.TECH
safeLabel.TextSize = 16
safeLabel.TextColor3 = COLORS.ACCENT_TOXIC
safeLabel.Size = UDim2.new(0.6, 0, 1, 0)
safeLabel.Position = UDim2.new(0, 15, 0, 0)
safeLabel.TextXAlignment = Enum.TextXAlignment.Left
safeLabel.BackgroundTransparency = 1
safeLabel.Parent = safeContent

-- Timer (Digital Style)
local safeTimer = Instance.new("TextLabel")
safeTimer.Text = "00:10"
safeTimer.Font = FONTS.DIGITAL
safeTimer.TextSize = 28
safeTimer.TextColor3 = COLORS.TEXT_LIGHT
safeTimer.Size = UDim2.new(0.4, 0, 1, 0)
safeTimer.Position = UDim2.new(0.6, -10, 0, 0)
safeTimer.TextXAlignment = Enum.TextXAlignment.Right
safeTimer.BackgroundTransparency = 1
safeTimer.Parent = safeContent


-- 4. Objective Content (Lower Panel)
local objContainer = Instance.new("Frame")
objContainer.Name = "ObjectiveContainer"
objContainer.Size = UDim2.new(1, -20, 0, 25)
objContainer.Position = UDim2.new(0, 20, 1, 5) -- Below StatusPanel
objContainer.BackgroundColor3 = COLORS.BG_METAL
objContainer.BackgroundTransparency = 0.3
objContainer.BorderSizePixel = 0
objContainer.Visible = false
objContainer.Parent = statusPanel

local objStroke = Instance.new("UIStroke")
objStroke.Color = COLORS.ACCENT_HAZARD
objStroke.Thickness = 1
objStroke.Parent = objContainer

local objText = Instance.new("TextLabel")
objText.Name = "ObjText"
objText.Text = "OBJECTIVE: FIND FUEL"
objText.Font = FONTS.TECH
objText.TextSize = 14
objText.TextColor3 = COLORS.ACCENT_HAZARD
objText.Size = UDim2.new(0.7, 0, 1, 0)
objText.Position = UDim2.new(0, 5, 0, 0)
objText.TextXAlignment = Enum.TextXAlignment.Left
objText.BackgroundTransparency = 1
objText.Parent = objContainer

local objCounter = Instance.new("TextLabel")
objCounter.Name = "ObjCounter"
objCounter.Text = "0/3"
objCounter.Font = FONTS.DIGITAL
objCounter.TextSize = 16
objCounter.TextColor3 = COLORS.TEXT_LIGHT
objCounter.Size = UDim2.new(0.3, -5, 1, 0)
objCounter.Position = UDim2.new(0.7, 0, 0, 0)
objCounter.TextXAlignment = Enum.TextXAlignment.Right
objCounter.BackgroundTransparency = 1
objCounter.Parent = objContainer


-- 5. Splash Text (Center Screen)
local splashContainer = Instance.new("Frame")
splashContainer.Size = UDim2.new(1, 0, 0, 100)
splashContainer.Position = UDim2.new(0, 0, 0.35, 0)
splashContainer.BackgroundTransparency = 1
splashContainer.Visible = false
splashContainer.Parent = screenGui

local splashText = Instance.new("TextLabel")
splashText.Text = "WAVE CLEARED"
splashText.Font = FONTS.TECH
splashText.TextSize = 42
splashText.TextColor3 = COLORS.ACCENT_HAZARD
splashText.Size = UDim2.new(1, 0, 1, 0)
splashText.BackgroundTransparency = 1
splashText.TextStrokeTransparency = 0.5
splashText.Parent = splashContainer

-- --- LOGIC ---

local currentWave = 0
local totalZombies = 0
local currentZombies = 0
local activePlayersCount = 1
local isIntermission = false

local function animatePulse(guiObject, color)
	local t = TweenService:Create(guiObject, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = color})
	t:Play()
	return t
end

local function triggerSplash(text, color)
	splashContainer.Visible = true
	splashText.Text = text
	splashText.TextColor3 = color
	splashText.TextTransparency = 1
	splashText.TextSize = 20

	-- Zoom In + Fade In
	local t1 = TweenService:Create(splashText, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextSize = 52
	})
	t1:Play()
	t1.Completed:Wait()

	task.wait(1.5)

	-- Fade Out
	local t2 = TweenService:Create(splashText, TweenInfo.new(0.5), {
		TextTransparency = 1,
		TextSize = 60
	})
	t2:Play()
	t2.Completed:Connect(function()
		splashContainer.Visible = false
	end)
end

-- Wave Update
WaveUpdateEvent.OnClientEvent:Connect(function(wave, activePlayers)
	currentWave = wave
	activePlayersCount = activePlayers or 1
	isIntermission = false

	-- Reset UI State
	container.Visible = true
	combatContent.Visible = true
	safeContent.Visible = false
	objContainer.Visible = false -- Hide objective initially

	-- Update Badge
	waveNumber.Text = tostring(wave)
	badgeStroke.Color = COLORS.ACCENT_CRITICAL -- Red for combat
	waveTitle.TextColor3 = COLORS.ACCENT_CRITICAL

	-- Update Status Panel
	statusStroke.Color = COLORS.ACCENT_CRITICAL
	hazardStrip.BackgroundColor3 = COLORS.ACCENT_CRITICAL

	-- Reset Bar
	barFill.Size = UDim2.new(0, 0, 1, 0)
	pctLabel.Text = "0%"

	-- Logic Stats
	local multiplier = ZOMBIES_PER_PLAYER_DEFAULT
	totalZombies = wave * multiplier * activePlayersCount
	if totalZombies < 1 then totalZombies = 1 end

	-- Animate Badge Shake
	local origin = UDim2.new(0, 0, 0, 0)
	for i = 1, 6 do
		waveBadge.Position = origin + UDim2.new(0, math.random(-3,3), 0, math.random(-3,3))
		task.wait(0.04)
	end
	waveBadge.Position = origin
end)

-- Wave Countdown
WaveCountdownEvent.OnClientEvent:Connect(function(seconds)
	if seconds > 0 then
		if not isIntermission then
			isIntermission = true

			-- Switch UI Mode
			combatContent.Visible = false
			safeContent.Visible = true

			-- Visuals: Safe Mode
			badgeStroke.Color = COLORS.ACCENT_TOXIC
			waveTitle.TextColor3 = COLORS.ACCENT_TOXIC
			statusStroke.Color = COLORS.ACCENT_TOXIC
			hazardStrip.BackgroundColor3 = COLORS.ACCENT_TOXIC

			triggerSplash("AREA SECURED", COLORS.ACCENT_TOXIC)
		end

		container.Visible = true
		safeTimer.Text = string.format("00:%02d", seconds)

		-- Red alert if low time
		if seconds <= 3 then
			safeTimer.TextColor3 = COLORS.ACCENT_CRITICAL
		else
			safeTimer.TextColor3 = COLORS.TEXT_LIGHT
		end

	else
		isIntermission = false
		safeContent.Visible = false
	end
end)

ObjectiveUpdateEvent.OnClientEvent:Connect(function(type, data)
	if type == "START" then
		objContainer.Visible = true
		objText.Text = data.Desc
		objCounter.Text = string.format("%d/%d", data.Progress, data.Target)
		triggerSplash("OBJECTIVE UPDATE", COLORS.ACCENT_HAZARD)

	elseif type == "UPDATE" then
		objContainer.Visible = true
		objText.Text = data.Desc
		objCounter.Text = string.format("%d/%d", data.Progress, data.Target)

		if data.IsCritical then
			objText.TextColor3 = COLORS.ACCENT_CRITICAL
		else
			objText.TextColor3 = COLORS.ACCENT_HAZARD
		end

	elseif type == "COMPLETE" then
		objContainer.Visible = false
		triggerSplash("OBJECTIVE SECURED", COLORS.ACCENT_TOXIC)

	elseif type == "ALERT" then
		-- Just a quick subtitle alert (reuse splash logic or add a new one, keeping it simple)
		triggerSplash(data, COLORS.ACCENT_HAZARD)
	end
end)

-- Stats Loop
local lastCheck = 0
RunService.Heartbeat:Connect(function(dt)
	if not container.Visible or isIntermission then return end

	lastCheck += dt
	if lastCheck >= 0.5 then
		lastCheck = 0

		local count = 0
		for _, child in ipairs(workspace:GetChildren()) do
			if child:FindFirstChild("IsZombie") or child:GetAttribute("IsZombie") then
				local hum = child:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					count += 1
				end
			end
		end
		currentZombies = count
		if currentZombies > totalZombies then totalZombies = currentZombies end

		local pct = 0
		if totalZombies > 0 then
			pct = math.clamp(currentZombies / totalZombies, 0, 1)
		end

		-- Update Bar
		TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
		pctLabel.Text = string.format("%d%%", math.floor(pct * 100))

		-- Color Logic
		if pct < 0.2 then
			barFill.BackgroundColor3 = COLORS.ACCENT_HAZARD
			pctLabel.TextColor3 = COLORS.ACCENT_HAZARD
		else
			barFill.BackgroundColor3 = COLORS.BAR_FILL
			pctLabel.TextColor3 = COLORS.ACCENT_CRITICAL
		end
	end
end)
