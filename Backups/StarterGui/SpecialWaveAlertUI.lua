-- SpecialWaveAlertUI.lua (LocalScript)
-- Path: StarterGui/SpecialWaveAlertUI.lua
-- Script Place: ACT 1: Village
-- Theme: Zombie Apocalypse (Analog Horror / EBS Broadcast)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local specialWaveAlertEvent = RemoteEvents:WaitForChild("SpecialWaveAlertEvent")

-- --- THEME CONFIGURATION ---
local THEME = {
	FONTS = {
		MAIN = Enum.Font.SpecialElite, -- Typewriter / Analog Horror
		WARNING = Enum.Font.Michroma,  -- Cold / Mechanical
	},
	COLORS = {
		WHITE = Color3.fromRGB(240, 240, 240),
		BLACK = Color3.fromRGB(10, 10, 10),
		RED_CHANNEL = Color3.fromRGB(255, 0, 0),
		BLUE_CHANNEL = Color3.fromRGB(0, 255, 255),
		DARK_RED = Color3.fromRGB(50, 0, 0)
	}
}

-- Wave Configuration
local waveConfigs = {
	["Blood Moon"] = {
		Title = "BLOOD MOON",
		Message = "DO NOT LOOK AT THE SKY.",
		Severity = "CRITICAL"
	},
	["Fast Wave"] = {
		Title = "FAST WAVE",
		Message = "THEY ARE RUNNING.",
		Severity = "HIGH"
	},
	["Special Wave"] = {
		Title = "SPECIAL WAVE",
		Message = "UNKNOWN SIGNAL RECEIVED.",
		Severity = "UNKNOWN"
	}
}

-- --- HELPER FUNCTIONS ---

-- Create a text label with Chromatic Aberration (RGB Split)
local function createChromaticText(parent, text, pos, size, font)
	local container = Instance.new("Frame")
	container.Name = "ChromaticContainer"
	container.Size = size
	container.Position = pos
	container.BackgroundTransparency = 1
	container.Parent = parent

	-- Layers: Red, Blue, Main
	local layers = {}

	-- Red Channel (Left Offset)
	local red = Instance.new("TextLabel")
	red.Text = text
	red.Font = font
	red.TextColor3 = THEME.COLORS.RED_CHANNEL
	red.TextTransparency = 0.5
	red.BackgroundTransparency = 1
	red.Size = UDim2.new(1, 0, 1, 0)
	red.Position = UDim2.new(0, -2, 0, 0) -- Initial Offset
	red.TextSize = 60
	red.ZIndex = 1
	red.Parent = container
	table.insert(layers, red)

	-- Blue Channel (Right Offset)
	local blue = red:Clone()
	blue.TextColor3 = THEME.COLORS.BLUE_CHANNEL
	blue.Position = UDim2.new(0, 2, 0, 0)
	blue.ZIndex = 1
	blue.Parent = container
	table.insert(layers, blue)

	-- Main Channel (White/Top)
	local main = red:Clone()
	main.Name = "MainText"
	main.TextColor3 = THEME.COLORS.WHITE
	main.TextTransparency = 0
	main.Position = UDim2.new(0, 0, 0, 0)
	main.ZIndex = 2
	main.Parent = container
	table.insert(layers, main)

	return container, layers
end

-- Simulate CRT Flickering
local function applyCRTFlicker(frame, intensity)
	task.spawn(function()
		while frame.Parent do
			-- Random transparency flickers (Target TextTransparency if it's a label)
			local targetProp = frame:IsA("TextLabel") and "TextTransparency" or "BackgroundTransparency"
			if math.random() > 0.8 then
				frame[targetProp] = math.random(2, 8) / 10 -- 0.2 to 0.8 (Dimming)
			else
				frame[targetProp] = 0 -- Visible
			end
			task.wait(math.random(1, 5) / 60)
		end
	end)
end

-- Main Alert Function
local function showAlert(waveType)
	local config = waveConfigs[waveType]
	if not config then return end

	-- 1. ScreenGui Setup
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AnalogHorrorUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = gui
	Debris:AddItem(screenGui, 8) -- Longer duration for slow horror build-up

	-- 2. Cinematic Bars (Letterbox)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 0) -- Start height 0
	topBar.Position = UDim2.new(0, 0, 0, 0)
	topBar.BackgroundColor3 = THEME.COLORS.BLACK
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 10
	topBar.Parent = screenGui

	local botBar = topBar:Clone()
	botBar.Position = UDim2.new(0, 0, 1, 0)
	botBar.AnchorPoint = Vector2.new(0, 1)
	botBar.Parent = screenGui

	-- 3. Main Background (Static)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0,0,0)
	bg.BackgroundTransparency = 1 -- Start transparent
	bg.ZIndex = 0
	bg.Parent = screenGui

	-- 4. Text Content (Centered)
	local textGroup = Instance.new("Frame")
	textGroup.Size = UDim2.new(0.8, 0, 0.4, 0)
	textGroup.Position = UDim2.new(0.5, 0, 0.5, 0)
	textGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	textGroup.BackgroundTransparency = 1
	textGroup.Parent = screenGui

	-- Emergency Header
	local headerLbl = Instance.new("TextLabel")
	headerLbl.Text = "- EMERGENCY BROADCAST SYSTEM -"
	headerLbl.Font = THEME.FONTS.WARNING
	headerLbl.TextColor3 = THEME.COLORS.WHITE
	headerLbl.TextSize = 18
	headerLbl.Size = UDim2.new(1, 0, 0, 20)
	headerLbl.Position = UDim2.new(0, 0, 0, 0)
	headerLbl.BackgroundTransparency = 1
	headerLbl.TextTransparency = 1
	headerLbl.Parent = textGroup

	-- Main Title with Chromatic Aberration
	local titleContainer, titleLayers = createChromaticText(
		textGroup, 
		config.Title, 
		UDim2.new(0, 0, 0.3, 0), 
		UDim2.new(1, 0, 0.4, 0), 
		THEME.FONTS.MAIN
	)
	-- Hide initially
	for _, l in pairs(titleLayers) do l.TextTransparency = 1 end

	-- Message Subtitle
	local msgLbl = Instance.new("TextLabel")
	msgLbl.Text = config.Message
	msgLbl.Font = THEME.FONTS.MAIN
	msgLbl.TextColor3 = THEME.COLORS.RED_CHANNEL
	msgLbl.TextSize = 24
	msgLbl.Size = UDim2.new(1, 0, 0, 30)
	msgLbl.Position = UDim2.new(0, 0, 0.8, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.TextTransparency = 1
	msgLbl.Parent = textGroup

	-- Severity Indicator
	local sevLbl = Instance.new("TextLabel")
	sevLbl.Text = "SEVERITY: " .. config.Severity
	sevLbl.Font = THEME.FONTS.WARNING
	sevLbl.TextColor3 = THEME.COLORS.WHITE
	sevLbl.TextSize = 14
	sevLbl.Size = UDim2.new(1, 0, 0, 20)
	sevLbl.Position = UDim2.new(0, 0, 1, 0)
	sevLbl.BackgroundTransparency = 1
	sevLbl.TextTransparency = 1
	sevLbl.Parent = textGroup

	-- 5. Audio Simulation (Visual Only)
	-- A small blinking "REC" circle
	local recDot = Instance.new("Frame")
	recDot.Size = UDim2.new(0, 15, 0, 15)
	recDot.Position = UDim2.new(0.95, 0, 0.05, 0)
	recDot.BackgroundColor3 = THEME.COLORS.RED_CHANNEL
	recDot.BackgroundTransparency = 1
	recDot.Parent = screenGui
	local recCorner = Instance.new("UICorner")
	recCorner.CornerRadius = UDim.new(1, 0)
	recCorner.Parent = recDot

	-- ANIMATION LOGIC
	task.spawn(function()
		-- A. Intro: Cinematic Bars & Fade to Black
		TweenService:Create(topBar, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
		TweenService:Create(botBar, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
		TweenService:Create(bg, TweenInfo.new(2), {BackgroundTransparency = 0.5}):Play()

		task.wait(1)

		-- B. Signal Interruption (Flickering Header)
		headerLbl.TextTransparency = 0
		applyCRTFlicker(headerLbl, 1) -- Blinking text

		task.wait(0.5)

		-- C. Main Title Aberration Event
		-- Reveal text
		for _, l in pairs(titleLayers) do 
			l.TextTransparency = (l.Name == "MainText") and 0 or 0.5 
		end

		-- Run Chromatic Glitch Loop
		local startTime = tick()
		local connection = RunService.RenderStepped:Connect(function()
			if not titleContainer.Parent then return end

			-- Oscillate offset based on time + random jitter
			local time = tick()
			local shiftX = math.sin(time * 20) * 3 + math.random(-2, 2)
			local shiftY = math.cos(time * 15) * 2 + math.random(-1, 1)

			titleLayers[1].Position = UDim2.new(0, -shiftX, 0, -shiftY) -- Red
			titleLayers[2].Position = UDim2.new(0, shiftX, 0, shiftY)  -- Blue

			-- Shake main text slightly
			titleLayers[3].Position = UDim2.new(0, math.random(-1,1), 0, math.random(-1,1))
		end)

		-- "REC" blinking
		task.spawn(function()
			while recDot.Parent do
				recDot.BackgroundTransparency = 0
				task.wait(0.8)
				recDot.BackgroundTransparency = 1
				task.wait(0.4)
			end
		end)

		task.wait(0.5)

		-- D. Typewriter Subtitles
		sevLbl.TextTransparency = 0
		msgLbl.TextTransparency = 0
		local fullMsg = config.Message
		msgLbl.Text = ""
		for i=1, #fullMsg do
			if not msgLbl.Parent then break end
			msgLbl.Text = string.sub(fullMsg, 1, i)
			task.wait(0.05)
		end

		-- E. Hold
		task.wait(3)

		-- F. Cut to Black (End)
		if connection then connection:Disconnect() end

		local exitInfo = TweenInfo.new(0.5)
		TweenService:Create(topBar, exitInfo, {Size = UDim2.new(1, 0, 0.5, 0)}):Play() -- Bars close completely
		TweenService:Create(botBar, exitInfo, {Size = UDim2.new(1, 0, 0.5, 0)}):Play()

		for _, v in pairs(screenGui:GetDescendants()) do
			if v:IsA("TextLabel") then
				TweenService:Create(v, exitInfo, {TextTransparency = 1}):Play()
			end
		end

		task.wait(0.5)
		screenGui:Destroy()
	end)
end

specialWaveAlertEvent.OnClientEvent:Connect(showAlert)
