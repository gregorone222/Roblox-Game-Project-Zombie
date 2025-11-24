-- BossAlertUI.lua (LocalScript)
-- Path: StarterGui/BossAlertUI.lua
-- Script Place: ACT 1: Village
-- Based on PrototypeBossAlertUI.html (Tailwind/CSS Style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local bossIncoming = nil
if RemoteEvents then
	bossIncoming = RemoteEvents:WaitForChild("BossIncoming", 10)
end

-- Fallback for testing if RemoteEvent doesn't exist
-- CONFIGURATION --
local BOSS_THEMES = {
	["Plague Titan"] = {
		Color = Color3.fromHex("#ef4444"), -- Red-500
		Class = "BIOLOGICAL",
		Icon = "?"
	},
	["Void Ascendant"] = {
		Color = Color3.fromHex("#a855f7"), -- Purple-500
		Class = "DIMENSIONAL",
		Icon = "??"
	},
	["Blighted Alchemist"] = {
		Color = Color3.fromHex("#84cc16"), -- Lime-500
		Class = "CHEMICAL",
		Icon = "?"
	},
	["Default"] = {
		Color = Color3.fromHex("#ef4444"),
		Class = "UNKNOWN",
		Icon = "?"
	}
}

local function GetTheme(name)
	return BOSS_THEMES[name] or BOSS_THEMES["Default"]
end

-- UTILITY FUNCTIONS --

local function CreateStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function CreateCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- UI CREATION --

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossAlertUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 20 -- Ensure it renders ON TOP of other HUDs
screenGui.Parent = gui

-- Hazard Strip Generator (Striped Pattern)
local function CreateHazardStrip(themeColor, positionY)
	-- Container for the strip
	local stripContainer = Instance.new("Frame")
	stripContainer.Name = "HazardStrip"
	stripContainer.Size = UDim2.new(0.7, 0, 0, 24) -- Slightly taller
	stripContainer.Position = UDim2.new(0.5, 0, 0, positionY)
	stripContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	stripContainer.BackgroundColor3 = Color3.new(0,0,0)
	stripContainer.BackgroundTransparency = 0.5
	stripContainer.ClipsDescendants = true -- CRITICAL: Keeps stripes inside
	stripContainer.ZIndex = 5 -- Behind text (which will be 10)

	CreateCorner(stripContainer, 4)
	CreateStroke(stripContainer, themeColor, 2)

	-- Holder for the stripes
	local patternHolder = Instance.new("Frame")
	patternHolder.Name = "PatternHolder"
	patternHolder.Size = UDim2.new(1.5, 0, 1, 0) -- No rotation needed, just wider for scroll
	patternHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
	patternHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	patternHolder.BackgroundTransparency = 1
	patternHolder.ZIndex = 5
	patternHolder.Parent = stripContainer

	-- Generate Stripes
	local numStripes = 60
	local stripeWidth = 8
	local gap = 20 

	for i = 0, numStripes do
		local bar = Instance.new("Frame")
		bar.Name = "Stripe"
		bar.Size = UDim2.new(0, stripeWidth, 1, 0)
		bar.Position = UDim2.new(0, (i * gap) - (numStripes * gap / 2), 0, 0) -- Center distribution
		bar.BackgroundColor3 = themeColor
		bar.BorderSizePixel = 0
		bar.ZIndex = 5
		bar.Parent = patternHolder
	end

	-- Animate Scroll
	task.spawn(function()
		local t = 0
		while stripContainer.Parent do
			t = t + 1
			-- Reset every gap distance (approximate visual loop)
			local offset = math.fmod(t, gap) 
			patternHolder.Position = UDim2.new(0.5, offset, 0.5, 0) 
			task.wait(0.03)
		end
	end)

	return stripContainer
end

-- MAIN LOGIC --

local function OnBossIncoming(bossName)
	-- 1. Cleanup Old
	for _, child in pairs(screenGui:GetChildren()) do child:Destroy() end

	local theme = GetTheme(bossName)
	local sound = game:GetService("SoundService"):FindFirstChild("BossAlertSound") or Instance.new("Sound", workspace)

	-- 2. Cinematic Bars (Black Bars)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.new(0,0,0)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 1
	topBar.Parent = screenGui

	local botBar = Instance.new("Frame")
	botBar.Size = UDim2.new(1, 0, 0, 0)
	botBar.Position = UDim2.new(0, 0, 1, 0)
	botBar.AnchorPoint = Vector2.new(0, 1)
	botBar.BackgroundColor3 = Color3.new(0,0,0)
	botBar.BorderSizePixel = 0
	botBar.ZIndex = 1
	botBar.Parent = screenGui

	TweenService:Create(topBar, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
	TweenService:Create(botBar, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()

	-- 3. Screen Overlay (Vignette/Darken)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(15, 23, 42) -- Dark Slate
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 2
	overlay.Parent = screenGui
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.4}):Play()

	-- 4. Main Container (Centered)
	local centerFrame = Instance.new("Frame")
	centerFrame.Size = UDim2.new(0, 700, 0, 450)
	centerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	centerFrame.BackgroundTransparency = 1
	centerFrame.ZIndex = 10
	centerFrame.Parent = screenGui

	-- Hazard Strips (Top/Bottom of Center Frame)
	-- Placed BEFORE text in code, but we also set ZIndex explicitly.
	-- Relative Y positions for strips inside the 450px high frame
	local hTop = CreateHazardStrip(theme.Color, 40) -- Top of frame
	hTop.Parent = centerFrame
	local hBot = CreateHazardStrip(theme.Color, 410) -- Bottom of frame
	hBot.Parent = centerFrame

	-- Icon Background
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 90, 0, 90)
	iconBg.Position = UDim2.new(0.5, 0, 0.25, 0)
	iconBg.AnchorPoint = Vector2.new(0.5, 0.5)
	iconBg.BackgroundColor3 = Color3.new(0,0,0)
	iconBg.BackgroundTransparency = 0.4
	iconBg.ZIndex = 15
	iconBg.Parent = centerFrame
	CreateCorner(iconBg, 100)
	local iconStroke = CreateStroke(iconBg, theme.Color, 3)

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Text = theme.Icon
	iconLbl.Size = UDim2.new(1,0,1,0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.TextSize = 50
	iconLbl.TextColor3 = Color3.new(1,1,1)
	iconLbl.ZIndex = 16
	iconLbl.Parent = iconBg

	-- Pulse Animation
	TweenService:Create(iconBg, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 110)}):Play()

	-- "MASSIVE SIGNAL" Warning
	local signalLbl = Instance.new("TextLabel")
	signalLbl.Text = "? MASSIVE SIGNAL DETECTED ?"
	signalLbl.Font = Enum.Font.GothamBold
	signalLbl.TextSize = 18
	signalLbl.TextColor3 = Color3.fromHex("#22d3ee") -- Cyan-400
	signalLbl.Size = UDim2.new(1, 0, 0, 25)
	signalLbl.Position = UDim2.new(0, 0, 0.40, 0)
	signalLbl.BackgroundTransparency = 1
	signalLbl.TextTransparency = 1
	signalLbl.ZIndex = 20
	signalLbl.Parent = centerFrame

	TweenService:Create(signalLbl, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.3), {TextTransparency = 0}):Play()

	-- BOSS NAME Container
	local titleContainer = Instance.new("Frame")
	titleContainer.Size = UDim2.new(1, 0, 0, 90)
	titleContainer.Position = UDim2.new(0, 0, 0.5, 0) -- Center
	titleContainer.BackgroundTransparency = 1
	titleContainer.ZIndex = 20
	titleContainer.Parent = centerFrame

	local function CreateGlitchText(color, z, offset, transparency)
		local t = Instance.new("TextLabel")
		t.Text = string.upper(bossName)
		t.Font = Enum.Font.GothamBlack
		t.TextSize = 65
		t.TextColor3 = color
		t.Size = UDim2.new(1, 0, 1, 0)
		t.Position = UDim2.new(0, offset, 0, offset)
		t.BackgroundTransparency = 1
		t.TextTransparency = transparency or 1
		t.ZIndex = z
		t.Parent = titleContainer
		return t
	end

	local mainTitle = CreateGlitchText(Color3.new(1,1,1), 22, 0)
	local glitch1 = CreateGlitchText(Color3.fromHex("#00ffff"), 21, 2, 0.8)
	local glitch2 = CreateGlitchText(Color3.fromHex("#ff00ff"), 21, -2, 0.8)

	-- Enter Anim
	TweenService:Create(mainTitle, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0.5), {TextTransparency = 0}):Play()

	-- Shake Glitch
	task.spawn(function()
		while titleContainer.Parent do
			local offset = math.random(-3, 3)
			glitch1.Position = UDim2.new(0, offset, 0, 0)
			glitch2.Position = UDim2.new(0, -offset, 0, 0)
			task.wait(0.05)
		end
	end)

	-- Subtitle
	local subContainer = Instance.new("Frame")
	subContainer.Size = UDim2.new(0, 450, 0, 30)
	subContainer.Position = UDim2.new(0.5, 0, 0.75, 0)
	subContainer.AnchorPoint = Vector2.new(0.5, 0)
	subContainer.BackgroundColor3 = Color3.new(0,0,0)
	subContainer.BackgroundTransparency = 1
	subContainer.BorderSizePixel = 0
	subContainer.ZIndex = 15
	subContainer.Parent = centerFrame

	local subLbl = Instance.new("TextLabel")
	subLbl.Text = string.format("CLASS: %s CONSTRUCT // THREAT: EXTREME", theme.Class)
	subLbl.Font = Enum.Font.Gotham
	subLbl.TextSize = 14
	subLbl.TextColor3 = Color3.fromHex("#94a3b8") -- Slate-400
	subLbl.Size = UDim2.new(1, 0, 1, 0)
	subLbl.BackgroundTransparency = 1
	subLbl.TextTransparency = 1
	subLbl.ZIndex = 16
	subLbl.Parent = subContainer

	TweenService:Create(subContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.8), {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(subLbl, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.8), {TextTransparency = 0}):Play()

	-- CLEANUP --
	task.delay(6, function()
		-- Animate Out
		TweenService:Create(topBar, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()
		TweenService:Create(botBar, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0, 0)}):Play()

		for _, d in pairs(screenGui:GetDescendants()) do
			if d:IsA("Frame") or d:IsA("TextLabel") then
				TweenService:Create(d, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
				if d:IsA("TextLabel") then TweenService:Create(d, TweenInfo.new(0.5), {TextTransparency = 1}):Play() end
			end
			if d:IsA("UIStroke") then
				TweenService:Create(d, TweenInfo.new(0.5), {Transparency = 1}):Play()
			end
		end
		task.wait(0.5)
		screenGui:ClearAllChildren()
	end)
end

-- Connect Event
bossIncoming.OnClientEvent:Connect(OnBossIncoming)

-- Testing for sandbox (uncomment to self-test in studio)
-- task.spawn(function() task.wait(2); OnBossIncoming("Plague Titan"); end)
