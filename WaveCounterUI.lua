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

-- Note: GameConfig is server-side, so we use defaults here or rely on events
local ZOMBIES_PER_PLAYER_DEFAULT = 5

-- --- CONFIGURATION & CONSTANTS ---
local COLORS = {
	BG_DARK = Color3.fromRGB(15, 23, 42), -- Slate 900
	STROKE = Color3.fromRGB(51, 65, 85), -- Slate 700
	TEXT_WHITE = Color3.fromRGB(248, 250, 252),
	TEXT_GRAY = Color3.fromRGB(148, 163, 184), -- Slate 400
	RED_DANGER = Color3.fromRGB(239, 68, 68), -- Red 500
	GREEN_SAFE = Color3.fromRGB(16, 185, 129), -- Emerald 500
	YELLOW_WARN = Color3.fromRGB(250, 204, 21),
	GOLD_SPLASH = Color3.fromRGB(251, 191, 36), -- Amber 400
}

local FONTS = {
	HEADER = Enum.Font.Michroma, -- Tech/Sci-fi look
	BODY = Enum.Font.GothamBold,
	LABEL = Enum.Font.GothamMedium,
}

local ICONS = {
	TIMER = "⏱",
}

-- --- UI CREATION ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveCounterUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- 1. Main Container (Glassmorphism)
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 300, 0, 100)
container.Position = UDim2.new(0.5, 0, 0.02, 0) -- Top Center
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundColor3 = COLORS.BG_DARK
container.BackgroundTransparency = 0.15
container.BorderSizePixel = 0
container.ClipsDescendants = true
container.Visible = false -- Default Hidden
container.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = container

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = COLORS.STROKE
uiStroke.Thickness = 1.5
uiStroke.Transparency = 0.5
uiStroke.Parent = container

-- 2. Wave Content Area (Active Wave)
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -30, 1, -10) -- Padding
content.Position = UDim2.new(0.5, 0, 0.5, 0)
content.AnchorPoint = Vector2.new(0.5, 0.5)
content.BackgroundTransparency = 1
content.Parent = container

-- Wave Label
local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveLabel"
waveLabel.Text = "GELOMBANG"
waveLabel.Font = FONTS.LABEL
waveLabel.TextSize = 12
waveLabel.TextColor3 = COLORS.TEXT_GRAY
waveLabel.Size = UDim2.new(1, 0, 0, 15)
waveLabel.BackgroundTransparency = 1
waveLabel.Parent = content

-- Wave Number
local waveNumber = Instance.new("TextLabel")
waveNumber.Name = "WaveNumber"
waveNumber.Text = "1"
waveNumber.Font = FONTS.HEADER
waveNumber.TextSize = 42
waveNumber.TextColor3 = COLORS.TEXT_WHITE
waveNumber.Size = UDim2.new(1, 0, 0, 45)
waveNumber.Position = UDim2.new(0, 0, 0, 12)
waveNumber.BackgroundTransparency = 1
waveNumber.Parent = content

-- Progress Section
local progressGroup = Instance.new("Frame")
progressGroup.Name = "ProgressGroup"
progressGroup.Size = UDim2.new(1, 0, 0, 30)
progressGroup.Position = UDim2.new(0, 0, 1, -30)
progressGroup.BackgroundTransparency = 1
progressGroup.Parent = content

-- Progress Track
local track = Instance.new("Frame")
track.Name = "Track"
track.Size = UDim2.new(1, 0, 0, 6)
track.BackgroundColor3 = COLORS.TEXT_WHITE
track.BackgroundTransparency = 0.9
track.BorderSizePixel = 0
track.Parent = progressGroup

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

-- Progress Fill
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(1, 0, 1, 0) -- Starts full
fill.BackgroundColor3 = COLORS.RED_DANGER
fill.BorderSizePixel = 0
fill.Parent = track

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

-- Percentage Text (Centered)
local infoContainer = Instance.new("Frame")
infoContainer.Name = "Info"
infoContainer.Size = UDim2.new(1, 0, 0, 20)
infoContainer.Position = UDim2.new(0, 0, 0, 8)
infoContainer.BackgroundTransparency = 1
infoContainer.Parent = progressGroup

local percentText = Instance.new("TextLabel")
percentText.Name = "Percent"
percentText.Text = "100%"
percentText.Font = FONTS.BODY
percentText.TextSize = 12
percentText.TextColor3 = COLORS.TEXT_GRAY
percentText.Size = UDim2.new(1, 0, 1, 0) -- Full width
percentText.TextXAlignment = Enum.TextXAlignment.Center -- Centered
percentText.BackgroundTransparency = 1
percentText.Parent = infoContainer

-- 3. Intermission Content (Countdown)
local intermissionContent = Instance.new("Frame")
intermissionContent.Name = "IntermissionContent"
intermissionContent.Size = UDim2.new(1, 0, 1, 0)
intermissionContent.BackgroundTransparency = 1
intermissionContent.Visible = false -- Initially hidden
intermissionContent.Parent = container

local ovList = Instance.new("UIListLayout")
ovList.HorizontalAlignment = Enum.HorizontalAlignment.Center
ovList.VerticalAlignment = Enum.VerticalAlignment.Center
ovList.Padding = UDim.new(0, 2)
ovList.Parent = intermissionContent

local ovTimer = Instance.new("TextLabel")
ovTimer.Text = "10"
ovTimer.Font = FONTS.HEADER
ovTimer.TextSize = 42
ovTimer.TextColor3 = COLORS.TEXT_WHITE
ovTimer.Size = UDim2.new(1, 0, 0, 50)
ovTimer.BackgroundTransparency = 1
ovTimer.Parent = intermissionContent

local ovSub = Instance.new("TextLabel")
ovSub.Text = "BERSIAPLAH..."
ovSub.Font = FONTS.LABEL
ovSub.TextSize = 14
ovSub.TextColor3 = COLORS.GREEN_SAFE
ovSub.Size = UDim2.new(1, 0, 0, 20)
ovSub.BackgroundTransparency = 1
ovSub.Parent = intermissionContent


-- 4. Splash Text (Gelombang Selesai)
local splashLabel = Instance.new("TextLabel")
splashLabel.Name = "SplashLabel"
splashLabel.Text = "GELOMBANG SELESAI"
splashLabel.Font = FONTS.HEADER
splashLabel.TextSize = 32
splashLabel.TextColor3 = COLORS.GOLD_SPLASH
splashLabel.Size = UDim2.new(1, 0, 0, 50)
splashLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
splashLabel.AnchorPoint = Vector2.new(0.5, 0.5)
splashLabel.BackgroundTransparency = 1
splashLabel.Visible = false
splashLabel.Parent = screenGui

local splashStroke = Instance.new("UIStroke")
splashStroke.Thickness = 2
splashStroke.Color = Color3.new(0,0,0)
splashStroke.Parent = splashLabel


-- --- LOGIC ---

local currentWave = 0
local totalZombies = 0
local currentZombies = 0
local activePlayersCount = 1
local isIntermission = false

local function animateSplash()
	splashLabel.Visible = true
	splashLabel.TextTransparency = 0
	splashLabel.Position = UDim2.new(0.5, 0, 0.4, 0)

	-- Pop in
	local t1 = TweenService:Create(splashLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 48
	})
	t1:Play()
	t1.Completed:Wait()

	task.wait(1.5)

	-- Fade out and float up
	local t2 = TweenService:Create(splashLabel, TweenInfo.new(0.5), {
		TextTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.3, 0)
	})
	t2:Play()
	t2.Completed:Connect(function()
		splashLabel.Visible = false
		splashLabel.TextSize = 32 -- Reset
	end)
end

local function bumpAnimation(guiObject)
	local t1 = TweenService:Create(guiObject, TweenInfo.new(0.1), {TextSize = 52}) -- Scale up
	t1:Play()
	t1.Completed:Wait()
	TweenService:Create(guiObject, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), {TextSize = 42}):Play()
end

-- Wave Update Event (Start of Wave)
WaveUpdateEvent.OnClientEvent:Connect(function(wave, activePlayers)
	currentWave = wave
	activePlayersCount = activePlayers or 1
	isIntermission = false

	-- Toggle UI Modes
	container.Visible = true 
	content.Visible = true
	intermissionContent.Visible = false
	splashLabel.Visible = false

	waveNumber.Text = tostring(wave)
	fill.BackgroundColor3 = COLORS.RED_DANGER

	-- Animate Bump
	task.spawn(function() bumpAnimation(waveNumber) end)

	-- Calculate estimated total zombies
	local multiplier = ZOMBIES_PER_PLAYER_DEFAULT
	totalZombies = wave * multiplier * activePlayersCount
	if totalZombies < 1 then totalZombies = 1 end

	-- Start at 0% (Activity/Intensity Meter behavior)
	fill.Size = UDim2.new(0, 0, 1, 0)
	percentText.Text = "0%"
end)

-- Wave Countdown Event (Intermission)
WaveCountdownEvent.OnClientEvent:Connect(function(seconds)
	if seconds > 0 then
		if not isIntermission then
			isIntermission = true

			-- Show Splash on first second of intermission
			task.spawn(animateSplash)

			-- Toggle UI Modes
			content.Visible = false
			intermissionContent.Visible = true
		end

		container.Visible = true
		ovTimer.Text = tostring(seconds)

		-- Pulse timer
		local t = TweenService:Create(ovTimer, TweenInfo.new(0.1), {TextTransparency = 0.5})
		t:Play()
		t.Completed:Connect(function()
			TweenService:Create(ovTimer, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
		end)
	else
		-- End of intermission
		intermissionContent.Visible = false
		isIntermission = false
	end
end)

-- Zombie Tracking Loop
local lastCheck = 0
local checkInterval = 0.5

RunService.Heartbeat:Connect(function(dt)
	-- Only run if UI is visible and in combat mode
	if not container.Visible or isIntermission then return end

	lastCheck += dt
	if lastCheck >= checkInterval then
		lastCheck = 0

		-- Count Zombies in Workspace
		local count = 0
		for _, child in ipairs(workspace:GetChildren()) do
			-- FIX: Check for BoolValue named "IsZombie" (Not Attribute)
			if child:FindFirstChild("IsZombie") then
				local hum = child:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					count += 1
				end
			end
		end

		currentZombies = count

		-- Adjust Total if Current exceeds estimate
		if currentZombies > totalZombies then
			totalZombies = currentZombies
		end

		-- Update UI
		local pct = 0
		if totalZombies > 0 then
			pct = math.clamp(currentZombies / totalZombies, 0, 1)
		end

		-- Smooth bar update
		TweenService:Create(fill, TweenInfo.new(0.4), {Size = UDim2.new(pct, 0, 1, 0)}):Play()

		percentText.Text = string.format("%d%%", math.floor(pct * 100))

		-- Low enemy warning color
		if pct < 0.25 and pct > 0 then
			fill.BackgroundColor3 = COLORS.YELLOW_WARN
		else
			fill.BackgroundColor3 = COLORS.RED_DANGER
		end
	end
end)
