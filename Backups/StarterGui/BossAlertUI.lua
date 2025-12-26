-- BossAlertUI.lua (LocalScript)
-- Path: StarterGui/BossAlertUI.lua
-- Script Place: ACT 1: Village
-- Aesthetic: Analog Horror / Corrupted Emergency Broadcast (Procedural Only)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local bossIncoming = RemoteEvents and RemoteEvents:WaitForChild("BossIncoming", 10)

-- CONSTANTS --
local COLORS = {
	PHOSPHOR_RED = Color3.fromRGB(255, 50, 50),
	PHOSPHOR_AMBER = Color3.fromRGB(255, 180, 0),
	CRT_BLACK = Color3.fromRGB(10, 5, 5),
	STATIC_WHITE = Color3.fromRGB(240, 240, 255)
}

local FONTS = {
	PRIMARY = Enum.Font.SpecialElite, -- Typewriter/Analog
	DIGITAL = Enum.Font.Code, -- Computer
	HEADER = Enum.Font.Michroma -- Modern Block
}

-- UI STATE --
local activeTweens = {}
local activeEffects = {}
local connections = {}

-- UTILITY --
local function cleanUp()
	for _, conn in ipairs(connections) do conn:Disconnect() end
	connections = {}
	for _, t in ipairs(activeTweens) do t:Cancel() end
	activeTweens = {}
	for _, eff in ipairs(activeEffects) do eff:Destroy() end
	activeEffects = {}

	-- Robust Cleanup: Check for lingering effects by name (fixes persistence on respawn)
	local existingCC = Lighting:FindFirstChild("AnalogFX")
	if existingCC then existingCC:Destroy() end
	local existingBlur = Lighting:FindFirstChild("AnalogBlur")
	if existingBlur then existingBlur:Destroy() end

	local existing = gui:FindFirstChild("BossAlertScreen")
	if existing then existing:Destroy() end
end

-- Init Cleanup (in case of respawn during effect)
cleanUp()

local function playTween(instance, info, props)
	local t = TweenService:Create(instance, info, props)
	table.insert(activeTweens, t)
	t:Play()
	return t
end

-- PROCEDURAL VISUALS --

local function createScanlines(parent)
	-- Creates a faux-scanline effect using UIGradient transparency
	-- Roblox allows max 20 keypoints. We can make ~10 lines.
	local scanFrame = Instance.new("Frame")
	scanFrame.Name = "Scanlines"
	scanFrame.Size = UDim2.new(1, 0, 1, 0)
	scanFrame.BackgroundTransparency = 0
	scanFrame.BackgroundColor3 = COLORS.CRT_BLACK
	scanFrame.ZIndex = 50
	scanFrame.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90

	-- Hardcoded bands for stability
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.1, 0.8),
		NumberSequenceKeypoint.new(0.2, 0.2),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(0.4, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(0.6, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(0.9, 0.8),
		NumberSequenceKeypoint.new(1.0, 0.2)
	})

	grad.Parent = scanFrame

	return scanFrame
end

local function createVignette(parent)
	local v = Instance.new("ImageLabel") -- No assets? Use Frames.
	-- Using the 4-frame method again as it's reliable for no-asset vignettes
	local thickness = 0.1
	local color = COLORS.CRT_BLACK

	local function makeSide(name, size, pos, rot)
		local f = Instance.new("Frame")
		f.Name = name
		f.Size = size
		f.Position = pos
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.ZIndex = 40
		f.Parent = parent
		local g = Instance.new("UIGradient")
		g.Rotation = rot
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		g.Parent = f
	end

	makeSide("Top", UDim2.new(1,0,thickness,0), UDim2.new(0,0,0,0), 90)
	makeSide("Bot", UDim2.new(1,0,thickness,0), UDim2.new(0,0,1-thickness,0), -90)
	makeSide("Left", UDim2.new(thickness*0.6,0,1,0), UDim2.new(0,0,0,0), 0)
	makeSide("Right", UDim2.new(thickness*0.6,0,1,0), UDim2.new(1-thickness*0.6,0,0,0), 180)
end

local function applyGlitchText(label, originalText)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	local duration = 0.15
	local nextGlitch = tick() + duration

	local conn = RunService.RenderStepped:Connect(function()
		if tick() >= nextGlitch then
			nextGlitch = tick() + math.random(0.05, 0.2)

			local r = math.random()
			if r > 0.7 then
				-- Swap a char
				local idx = math.random(1, #originalText)
				local sub = string.sub(chars, math.random(1, #chars), math.random(1, #chars))
				label.Text = string.sub(originalText, 1, idx-1) .. sub .. string.sub(originalText, idx+1)
			else
				label.Text = originalText
			end

			-- Position Jitter
			if r > 0.8 then
				label.Position = UDim2.new(
					label.Position.X.Scale, math.random(-2, 2),
					label.Position.Y.Scale, math.random(-2, 2)
				)
			end
		end
	end)
	table.insert(connections, conn)
end

-- MAIN ANIMATION --

local function playAnalogAlert(bossName)
	cleanUp()
	bossName = string.upper(bossName or "UNKNOWN")

	-- 1. SCREEN FX
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "AnalogFX"
	cc.TintColor = Color3.fromRGB(255, 220, 220)
	cc.Contrast = 0.5 -- High contrast
	cc.Saturation = -0.6 -- Desaturated
	cc.Parent = Lighting
	table.insert(activeEffects, cc)

	local blur = Instance.new("BlurEffect")
	blur.Name = "AnalogBlur"
	blur.Size = 0
	blur.Parent = Lighting
	table.insert(activeEffects, blur)

	-- 2. GUI SETUP
	local screen = Instance.new("ScreenGui")
	screen.Name = "BossAlertScreen"
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 100
	screen.ResetOnSpawn = false
	screen.Parent = gui

	-- CRT Turn-On Animation (Scale Y from center)
	local contentRoot = Instance.new("Frame")
	contentRoot.Name = "ContentRoot"
	contentRoot.Size = UDim2.new(1, 0, 0, 2) -- Start thin
	contentRoot.Position = UDim2.new(0, 0, 0.5, 0)
	contentRoot.AnchorPoint = Vector2.new(0, 0.5)
	contentRoot.BackgroundColor3 = COLORS.CRT_BLACK
	contentRoot.BorderSizePixel = 0
	contentRoot.ClipsDescendants = true
	contentRoot.Parent = screen

	-- White Flash
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = COLORS.STATIC_WHITE
	flash.ZIndex = 100
	flash.Parent = contentRoot

	-- 3. ANIMATION: TURN ON
	playTween(contentRoot, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Size = UDim2.new(1, 0, 1, 0)})
	playTween(flash, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	playTween(blur, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, true), {Size = 20}) -- Blur pulse

	-- 4. VISUAL ELEMENTS
	createScanlines(contentRoot)
	createVignette(contentRoot)

	-- Main Box
	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 600, 0, 300)
	box.Position = UDim2.new(0.5, 0, 0.5, 0)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundTransparency = 1
	box.ZIndex = 10
	box.Parent = contentRoot

	-- Borders (Top/Bottom)
	local borderTop = Instance.new("Frame")
	borderTop.Size = UDim2.new(1, 0, 0, 4)
	borderTop.BackgroundColor3 = COLORS.PHOSPHOR_RED
	borderTop.BorderSizePixel = 0
	borderTop.Parent = box

	local borderBot = borderTop:Clone()
	borderBot.Position = UDim2.new(0, 0, 1, -4)
	borderBot.Parent = box

	-- Header
	local header = Instance.new("TextLabel")
	header.Text = "EMERGENCY BROADCAST SYSTEM"
	header.Font = FONTS.HEADER
	header.TextSize = 24
	header.TextColor3 = COLORS.PHOSPHOR_RED
	header.Size = UDim2.new(1, 0, 0, 30)
	header.Position = UDim2.new(0, 0, 0.1, 0)
	header.BackgroundTransparency = 1
	header.Parent = box

	-- Sub Header
	local sub = Instance.new("TextLabel")
	sub.Text = "THREAT DETECTED IN SECTOR 7"
	sub.Font = FONTS.DIGITAL
	sub.TextSize = 18
	sub.TextColor3 = COLORS.STATIC_WHITE
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Position = UDim2.new(0, 0, 0.2, 0)
	sub.BackgroundTransparency = 1
	sub.Parent = box

	-- BOSS NAME (Big)
	local bossLbl = Instance.new("TextLabel")
	bossLbl.Text = bossName
	bossLbl.Font = FONTS.PRIMARY
	bossLbl.TextSize = 60
	bossLbl.TextColor3 = COLORS.PHOSPHOR_RED
	bossLbl.Size = UDim2.new(1, 0, 0, 100)
	bossLbl.Position = UDim2.new(0, 0, 0.4, 0)
	bossLbl.BackgroundTransparency = 1
	bossLbl.TextScaled = false
	bossLbl.Parent = box

	applyGlitchText(bossLbl, bossName)

	-- Footer (Blinking)
	local footer = Instance.new("TextLabel")
	footer.Text = "SEEK SHELTER IMMEDIATELY"
	footer.Font = FONTS.PRIMARY
	footer.TextSize = 24
	footer.TextColor3 = COLORS.PHOSPHOR_AMBER
	footer.Size = UDim2.new(1, 0, 0, 30)
	footer.Position = UDim2.new(0, 0, 0.8, 0)
	footer.BackgroundTransparency = 1
	footer.Parent = box

	local blinkTween = playTween(footer, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 1})

	-- 5. NOISE OVERLAY
	local noise = Instance.new("Frame")
	noise.Size = UDim2.new(1, 0, 1, 0)
	noise.BackgroundColor3 = COLORS.STATIC_WHITE
	noise.BackgroundTransparency = 0.95
	noise.ZIndex = 60
	noise.Parent = contentRoot

	-- Shake Screen Loop
	local shakeConn = RunService.RenderStepped:Connect(function()
		local offsetX = math.random(-2, 2)
		local offsetY = math.random(-2, 2)
		contentRoot.Position = UDim2.new(0, offsetX, 0.5, offsetY)

		-- Random Noise Bar
		if math.random() > 0.9 then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(1, 0, 0, math.random(2, 10))
			bar.Position = UDim2.new(0, 0, math.random(), 0)
			bar.BackgroundColor3 = COLORS.STATIC_WHITE
			bar.BorderSizePixel = 0
			bar.BackgroundTransparency = 0.8
			bar.ZIndex = 55
			bar.Parent = contentRoot
			game.Debris:AddItem(bar, 0.05)
		end
	end)
	table.insert(connections, shakeConn)

	-- 6. EXIT SEQUENCE
	task.delay(6, function()
		-- Turn Off Animation (Collapse Y)
		playTween(contentRoot, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Size = UDim2.new(1, 0, 0, 2)})
		playTween(cc, TweenInfo.new(0.5), {Contrast = 0, Saturation = 0})

		task.wait(0.3)
		cleanUp()
	end)
end

if bossIncoming then
	bossIncoming.OnClientEvent:Connect(playAnalogAlert)
end

-- TEST (Uncomment to test)
-- task.delay(3, function() playAnalogAlert("PLAGUE TITAN") end)
