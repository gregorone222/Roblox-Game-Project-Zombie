-- BossTimerUI.lua (LocalScript)
-- Path: StarterGui/BossTimerUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local BossTimerEvent = RemoteEvents:WaitForChild("BossTimerEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BossTimerUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

local timerContainer = nil
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Colors (Based on Prototype)
local C_DARK_BG = Color3.fromRGB(15, 23, 42) -- Slate 900
local C_BORDER_NORMAL = Color3.fromRGB(51, 65, 85) -- Slate 700
local C_BORDER_DANGER = Color3.fromRGB(239, 68, 68) -- Red 500
local C_TEXT_WHITE = Color3.fromRGB(248, 250, 252)
local C_TEXT_SUB = Color3.fromRGB(148, 163, 184) -- Slate 400

-- Gradients
local C_BAR_NORMAL_A = Color3.fromRGB(59, 130, 246) -- Blue 500
local C_BAR_NORMAL_B = Color3.fromRGB(96, 165, 250) -- Blue 400
local C_BAR_WARN_A = Color3.fromRGB(249, 115, 22) -- Orange 500
local C_BAR_WARN_B = Color3.fromRGB(251, 191, 36) -- Amber 400
local C_BAR_CRIT_A = Color3.fromRGB(239, 68, 68) -- Red 500
local C_BAR_CRIT_B = Color3.fromRGB(255, 0, 0)   -- Red Bright

local function createTimerUI()
	if timerContainer then return end

	local isMobile = UserInputService.TouchEnabled

	-- Main Container (The Widget)
	timerContainer = Instance.new("Frame")
	timerContainer.Name = "BossWidget"
	-- Adjust size for mobile/desktop
	timerContainer.Size = isMobile and UDim2.new(0.6, 0, 0, 130) or UDim2.new(0, 400, 0, 140)
	timerContainer.Position = UDim2.new(0.5, 0, 0.08, 0)
	timerContainer.AnchorPoint = Vector2.new(0.5, 0)
	timerContainer.BackgroundColor3 = C_DARK_BG
	timerContainer.BackgroundTransparency = 0.1
	timerContainer.BorderSizePixel = 0
	timerContainer.Visible = true
	timerContainer.Parent = screenGui

	-- Stroke (Border)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "BorderStroke"
	uiStroke.Color = C_BORDER_NORMAL
	uiStroke.Thickness = 2
	uiStroke.Parent = timerContainer

	-- Corner
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = timerContainer

	-- Padding
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 12)
	uiPadding.PaddingBottom = UDim.new(0, 15)
	uiPadding.PaddingLeft = UDim.new(0, 20)
	uiPadding.PaddingRight = UDim.new(0, 20)
	uiPadding.Parent = timerContainer

	-- === HEADER SECTION ===
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 40)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = timerContainer

	-- Icon Box
	local iconBox = Instance.new("Frame")
	iconBox.Name = "IconBox"
	iconBox.Size = UDim2.new(0, 36, 0, 36)
	iconBox.BackgroundColor3 = Color3.fromRGB(69, 10, 10) -- Dark Red
	iconBox.BackgroundTransparency = 0.5
	iconBox.Parent = headerFrame

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(239, 68, 68)
	iconStroke.Thickness = 1
	iconStroke.Parent = iconBox

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 6)
	iconCorner.Parent = iconBox

	local iconText = Instance.new("TextLabel")
	iconText.Text = "☠" -- Unicode Skull
	iconText.Font = Enum.Font.GothamBold
	iconText.TextSize = 20
	iconText.TextColor3 = Color3.fromRGB(248, 113, 113) -- Red 400
	iconText.BackgroundTransparency = 1
	iconText.Size = UDim2.new(1, 0, 1, 0)
	iconText.Parent = iconBox

	-- Boss Info
	local infoFrame = Instance.new("Frame")
	infoFrame.Name = "Info"
	infoFrame.Position = UDim2.new(0, 46, 0, 0)
	infoFrame.Size = UDim2.new(1, -120, 1, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Parent = headerFrame

	local subLabel = Instance.new("TextLabel")
	subLabel.Text = "TARGET PRIORITY"
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextSize = 10
	subLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Size = UDim2.new(1, 0, 0, 12)
	subLabel.BackgroundTransparency = 1
	subLabel.Parent = infoFrame

	local bossName = Instance.new("TextLabel")
	bossName.Name = "BossName"
	bossName.Text = "BOSS TARGET"
	bossName.Font = Enum.Font.GothamBlack
	bossName.TextSize = 20
	bossName.TextColor3 = C_TEXT_WHITE
	bossName.TextXAlignment = Enum.TextXAlignment.Left
	bossName.Position = UDim2.new(0, 0, 0, 14)
	bossName.Size = UDim2.new(1, 0, 0, 22)
	bossName.BackgroundTransparency = 1
	bossName.Parent = infoFrame

	-- Phase Tag (Right Side)
	local phaseFrame = Instance.new("Frame")
	phaseFrame.Name = "PhaseFrame"
	phaseFrame.Size = UDim2.new(0, 60, 0, 20)
	phaseFrame.Position = UDim2.new(1, -60, 0, 8)
	phaseFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	phaseFrame.Parent = headerFrame

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 4)
	pCorner.Parent = phaseFrame

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(71, 85, 105)
	pStroke.Thickness = 1
	pStroke.Parent = phaseFrame

	local phaseText = Instance.new("TextLabel")
	phaseText.Name = "PhaseText"
	phaseText.Text = "ACTIVE"
	phaseText.Font = Enum.Font.GothamBold
	phaseText.TextSize = 10
	phaseText.TextColor3 = C_TEXT_SUB
	phaseText.Size = UDim2.new(1, 0, 1, 0)
	phaseText.BackgroundTransparency = 1
	phaseText.Parent = phaseFrame

	-- Separator
	local sep = Instance.new("Frame")
	sep.Name = "Separator"
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Position = UDim2.new(0, 0, 0, 48)
	sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sep.BorderSizePixel = 0
	sep.Parent = timerContainer

	local sepGrad = Instance.new("UIGradient")
	sepGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.5),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	sepGrad.Parent = sep

	-- === TIMER SECTION ===
	local timerSection = Instance.new("Frame")
	timerSection.Name = "TimerSection"
	timerSection.Size = UDim2.new(1, 0, 0, 60)
	timerSection.Position = UDim2.new(0, 0, 0, 55)
	timerSection.BackgroundTransparency = 1
	timerSection.Parent = timerContainer

	-- Label
	local tLabel = Instance.new("TextLabel")
	tLabel.Text = "TIME REMAINING"
	tLabel.Font = Enum.Font.GothamBold
	tLabel.TextSize = 10
	tLabel.TextColor3 = C_TEXT_SUB
	tLabel.Size = UDim2.new(1, 0, 0, 12)
	tLabel.BackgroundTransparency = 1
	tLabel.Parent = timerSection

	-- Big Timer
	local bigTimer = Instance.new("TextLabel")
	bigTimer.Name = "BigTimer"
	bigTimer.Text = "00:00"
	bigTimer.Font = Enum.Font.Code -- Monospace
	bigTimer.TextSize = 36
	bigTimer.TextColor3 = C_TEXT_WHITE
	bigTimer.Size = UDim2.new(1, 0, 0, 40)
	bigTimer.Position = UDim2.new(0, 0, 0, 12)
	bigTimer.BackgroundTransparency = 1
	bigTimer.Parent = timerSection

	-- Progress Bar BG
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBG"
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.Position = UDim2.new(0, 0, 1, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	barBg.BorderSizePixel = 0
	barBg.Parent = timerSection

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = barBg

	-- Progress Bar Fill
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill

	local barGrad = Instance.new("UIGradient")
	barGrad.Color = ColorSequence.new(C_BAR_NORMAL_A, C_BAR_NORMAL_B)
	barGrad.Parent = barFill
end

local function destroyTimerUI()
	if timerContainer then
		timerContainer:Destroy()
		timerContainer = nil
	end
end

local function updateTimerUI(remainingTime, totalTime, bossName, phase)
	if not timerContainer then return end

	if bossName then
		local header = timerContainer:FindFirstChild("Header")
		local info = header and header:FindFirstChild("Info")
		local nameLabel = info and info:FindFirstChild("BossName")
		if nameLabel then nameLabel.Text = string.upper(tostring(bossName)) end
	end

	if phase then
		local header = timerContainer:FindFirstChild("Header")
		local phaseFrame = header and header:FindFirstChild("PhaseFrame")
		local phaseText = phaseFrame and phaseFrame:FindFirstChild("PhaseText")
		if phaseText then phaseText.Text = string.upper(tostring(phase)) end
	end

	local timerSection = timerContainer:FindFirstChild("TimerSection")
	if not timerSection then return end

	local bigTimer = timerSection:FindFirstChild("BigTimer")
	local barBg = timerSection:FindFirstChild("BarBG")
	local barFill = barBg and barBg:FindFirstChild("BarFill")
	local uiStroke = timerContainer:FindFirstChild("BorderStroke")

	if not bigTimer or not barFill then return end

	-- Timer Text
	local minutes = math.floor(remainingTime / 60)
	local seconds = math.floor(remainingTime % 60)
	bigTimer.Text = string.format("%02d:%02d", minutes, seconds)

	-- Bar Width
	local pct = math.clamp(remainingTime / totalTime, 0, 1)
	local tween = TweenService:Create(barFill, tweenInfo, {Size = UDim2.new(pct, 0, 1, 0)})
	tween:Play()

	-- Visual States
	local currentState = "Normal"
	if remainingTime <= 30 then
		currentState = "Critical"
	elseif remainingTime <= 120 then
		currentState = "Warning"
	end

	local barGrad = barFill:FindFirstChildWhichIsA("UIGradient")

	if currentState == "Critical" then
		if uiStroke then uiStroke.Color = C_BORDER_DANGER end
		bigTimer.TextColor3 = C_BAR_CRIT_B
		if barGrad then
			barGrad.Color = ColorSequence.new(C_BAR_CRIT_A, C_BAR_CRIT_B)
		end

		-- Pulse
		local pulse = (math.sin(tick() * 10) + 1) / 2
		bigTimer.TextTransparency = pulse * 0.5

	elseif currentState == "Warning" then
		if uiStroke then uiStroke.Color = C_BORDER_NORMAL end
		bigTimer.TextColor3 = C_BAR_WARN_B
		bigTimer.TextTransparency = 0
		if barGrad then
			barGrad.Color = ColorSequence.new(C_BAR_WARN_A, C_BAR_WARN_B)
		end

	else
		if uiStroke then uiStroke.Color = C_BORDER_NORMAL end
		bigTimer.TextColor3 = C_TEXT_WHITE
		bigTimer.TextTransparency = 0
		if barGrad then
			barGrad.Color = ColorSequence.new(C_BAR_NORMAL_A, C_BAR_NORMAL_B)
		end
	end
end

BossTimerEvent.OnClientEvent:Connect(function(remainingTime, totalTime, bossName, phase)
	if remainingTime <= 0 then
		destroyTimerUI()
	else
		if not timerContainer then
			createTimerUI()
		end
		updateTimerUI(remainingTime, totalTime, bossName, phase)
	end
end)
