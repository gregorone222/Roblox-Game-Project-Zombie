-- KnockUI.lua (LocalScript)
-- Path: StarterGui/KnockUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local KnockEvent = RemoteEvents:WaitForChild("KnockEvent", 10)
local PingKnockedPlayerEvent = RemoteEvents:WaitForChild("PingKnockedPlayerEvent", 10)
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent", 10)

-- Optional Event (Feature Flag)
local ReviveProgressEvent = RemoteEvents:FindFirstChild("ReviveProgressEvent")
if not ReviveProgressEvent then
	warn("KnockUI: ReviveProgressEvent not found. Revive UI hints will be disabled.")
end

if not KnockEvent then
	warn("KnockUI: Critical KnockEvent missing! UI will not function.")
	return
end

-- Constants & Config
local PING_COOLDOWN = 15

-- Assets
local ASSETS = {
	HEART_ICON = "rbxassetid://10151249576", -- Heart from GlobalKnockNotification
	SKULL_ICON = "rbxassetid://9176098815", -- Original Skull
	VIGNETTE = "rbxassetid://4576475446",
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KnockUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui
screenGui.Enabled = false

-- 1. Vignette (Red Pulsing)
local vignette = Instance.new("ImageLabel")
vignette.Name = "Vignette"
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.Image = ASSETS.VIGNETTE
vignette.ImageColor3 = Color3.fromRGB(220, 38, 38) -- Red-600
vignette.ImageTransparency = 0.2
vignette.ZIndex = 1
vignette.Parent = screenGui

-- 1b. Full Screen Pulse Overlay (Added per request)
local pulseOverlay = Instance.new("Frame")
pulseOverlay.Name = "PulseOverlay"
pulseOverlay.Size = UDim2.new(1, 0, 1, 0)
pulseOverlay.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
pulseOverlay.BackgroundTransparency = 1
pulseOverlay.BorderSizePixel = 0
pulseOverlay.ZIndex = 0 -- Behind everything else
pulseOverlay.Parent = screenGui

-- 2. Main Container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 600, 0, 500)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.ZIndex = 10
mainContainer.Parent = screenGui

-- Status Header
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 150)
headerFrame.BackgroundTransparency = 1
headerFrame.LayoutOrder = 1
headerFrame.Parent = mainContainer

local headerLayout = Instance.new("UIListLayout")
headerLayout.Parent = headerFrame
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
headerLayout.Padding = UDim.new(0, 5)

-- Heart Icon
local heartIcon = Instance.new("ImageLabel")
heartIcon.Name = "HeartIcon"
heartIcon.Size = UDim2.new(0, 64, 0, 64)
heartIcon.BackgroundTransparency = 1
heartIcon.Image = ASSETS.HEART_ICON
heartIcon.ImageColor3 = Color3.fromRGB(239, 68, 68) -- Red-500
heartIcon.LayoutOrder = 1
heartIcon.Parent = headerFrame

-- CRITICAL Text
local criticalText = Instance.new("TextLabel")
criticalText.Name = "CriticalText"
criticalText.Size = UDim2.new(1, 0, 0, 70)
criticalText.BackgroundTransparency = 1
criticalText.Text = "CRITICAL"
criticalText.Font = Enum.Font.GothamBlack
criticalText.TextColor3 = Color3.fromRGB(239, 68, 68)
criticalText.TextSize = 72
criticalText.TextStrokeColor3 = Color3.fromRGB(153, 27, 27)
criticalText.TextStrokeTransparency = 0.5
criticalText.LayoutOrder = 2
criticalText.Parent = headerFrame

-- Subtext
local vitalText = Instance.new("TextLabel")
vitalText.Name = "VitalText"
vitalText.Size = UDim2.new(1, 0, 0, 30)
vitalText.BackgroundTransparency = 1
vitalText.Text = "VITAL SIGNS FAILING"
vitalText.Font = Enum.Font.Michroma
vitalText.TextColor3 = Color3.fromRGB(254, 202, 202) -- Red-200
vitalText.TextSize = 20
vitalText.LayoutOrder = 3
vitalText.Parent = headerFrame

-- Bleedout Section (Renamed/Repurposed to just hold medic label if needed, or removed)
-- User requested removing the bar and timer. We keep the medic label.
local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoFrame"
infoFrame.Size = UDim2.new(0.8, 0, 0, 40)
infoFrame.Position = UDim2.new(0.1, 0, 0.55, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = mainContainer

local medicLabel = Instance.new("TextLabel")
medicLabel.Name = "MedicLabel"
medicLabel.Size = UDim2.new(1, 0, 1, 0)
medicLabel.BackgroundTransparency = 1
medicLabel.Text = "Menunggu bantuan tim... Player terdekat: --"
medicLabel.Font = Enum.Font.Code
medicLabel.TextColor3 = Color3.fromRGB(148, 163, 184) -- Slate-400
medicLabel.TextSize = 14
medicLabel.TextXAlignment = Enum.TextXAlignment.Center
medicLabel.RichText = true
medicLabel.Parent = infoFrame

-- Interaction Area
local interactionFrame = Instance.new("Frame")
interactionFrame.Name = "InteractionFrame"
interactionFrame.Size = UDim2.new(0.8, 0, 0, 120)
interactionFrame.Position = UDim2.new(0.1, 0, 0.7, 0)
interactionFrame.BackgroundTransparency = 1
interactionFrame.Parent = mainContainer

local pingButton = Instance.new("TextButton")
pingButton.Name = "PingButton"
pingButton.Size = UDim2.new(0, 250, 0, 60)
pingButton.AnchorPoint = Vector2.new(0.5, 0)
pingButton.Position = UDim2.new(0.5, 0, 0, 0)
pingButton.BackgroundColor3 = Color3.fromRGB(59, 130, 246) -- Blue-500
pingButton.BackgroundTransparency = 0.2
pingButton.Text = "SOS SIGNAL (H)"
pingButton.Font = Enum.Font.GothamBlack
pingButton.TextColor3 = Color3.fromRGB(219, 234, 254) -- Blue-100
pingButton.TextSize = 20
pingButton.AutoButtonColor = false
pingButton.Parent = interactionFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = pingButton

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(59, 130, 246)
btnStroke.Thickness = 2
btnStroke.Transparency = 0.3
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
btnStroke.Parent = pingButton

local cooldownOverlay = Instance.new("Frame")
cooldownOverlay.Name = "CooldownOverlay"
cooldownOverlay.Size = UDim2.new(0, 0, 1, 0)
cooldownOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
cooldownOverlay.BackgroundTransparency = 0.8
cooldownOverlay.BorderSizePixel = 0
cooldownOverlay.Parent = pingButton

local helpText = Instance.new("TextLabel")
helpText.Size = UDim2.new(1, 0, 0, 20)
helpText.Position = UDim2.new(0, 0, 1, 5)
helpText.BackgroundTransparency = 1
helpText.Text = "Tekan 'H' atau klik tombol untuk mengirim lokasi"
helpText.Font = Enum.Font.Michroma
helpText.TextColor3 = Color3.fromRGB(100, 116, 139)
helpText.TextSize = 12
helpText.Parent = pingButton

-- Revive Hint
local reviveHint = Instance.new("Frame")
reviveHint.Name = "ReviveHint"
reviveHint.Size = UDim2.new(0, 280, 0, 60)
reviveHint.Position = UDim2.new(0.5, 0, 1.1, 0)
reviveHint.AnchorPoint = Vector2.new(0.5, 0)
reviveHint.BackgroundColor3 = Color3.fromRGB(20, 83, 45) -- Green-900
reviveHint.BackgroundTransparency = 0.4
reviveHint.BorderSizePixel = 0
reviveHint.Visible = false
reviveHint.Parent = interactionFrame

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 8)
hintCorner.Parent = reviveHint

local hintStroke = Instance.new("UIStroke")
hintStroke.Color = Color3.fromRGB(34, 197, 94) -- Green-500
hintStroke.Thickness = 1
hintStroke.Parent = reviveHint

local hintIcon = Instance.new("ImageLabel")
hintIcon.Size = UDim2.new(0, 30, 0, 30)
hintIcon.Position = UDim2.new(0, 15, 0.5, 0)
hintIcon.AnchorPoint = Vector2.new(0, 0.5)
hintIcon.BackgroundTransparency = 1
hintIcon.Image = ASSETS.HEART_ICON -- Reusing heart icon as nurse/health icon
hintIcon.ImageColor3 = Color3.fromRGB(74, 222, 128) -- Green-400
hintIcon.Parent = reviveHint

local hintTitle = Instance.new("TextLabel")
hintTitle.Size = UDim2.new(0.6, 0, 0.5, 0)
hintTitle.Position = UDim2.new(0, 60, 0, 10)
hintTitle.BackgroundTransparency = 1
hintTitle.Text = "BEING REVIVED"
hintTitle.Font = Enum.Font.Michroma
hintTitle.TextColor3 = Color3.fromRGB(134, 239, 172) -- Green-300
hintTitle.TextSize = 16
hintTitle.TextXAlignment = Enum.TextXAlignment.Left
hintTitle.Parent = reviveHint

local hintSub = Instance.new("TextLabel")
hintSub.Size = UDim2.new(0.6, 0, 0.3, 0)
hintSub.Position = UDim2.new(0, 60, 0.5, 5)
hintSub.BackgroundTransparency = 1
hintSub.Text = "JANGAN BERGERAK"
hintSub.Font = Enum.Font.Code
hintSub.TextColor3 = Color3.fromRGB(34, 197, 94)
hintSub.TextSize = 12
hintSub.TextXAlignment = Enum.TextXAlignment.Left
hintSub.Parent = reviveHint

local spinner = Instance.new("Frame")
spinner.Size = UDim2.new(0, 20, 0, 20)
spinner.Position = UDim2.new(1, -35, 0.5, 0)
spinner.AnchorPoint = Vector2.new(0, 0.5)
spinner.BackgroundColor3 = Color3.fromRGB(0,0,0)
spinner.BackgroundTransparency = 1
spinner.Parent = reviveHint

local spinnerIcon = Instance.new("ImageLabel")
spinnerIcon.Size = UDim2.new(1,0,1,0)
spinnerIcon.BackgroundTransparency = 1
spinnerIcon.Image = ASSETS.HEART_ICON -- Reusing heart as spinner, can be rotated
spinnerIcon.ImageColor3 = Color3.fromRGB(74, 222, 128)
spinnerIcon.Parent = spinner

-- Logic Variables
local isKnockedState = false
local isReviving = false
local lastPingTime = 0
local isPingOnCooldown = false
local heartbeatTween
local pulseTween
local overlayPulseTween -- New tween for full screen overlay
local loops = {}
local camera = workspace.CurrentCamera
local shakeConnection

-- Screen Shake Logic
local function startScreenShake()
	if shakeConnection then shakeConnection:Disconnect() end
	local originalCFrame = camera.CFrame

	shakeConnection = RunService.RenderStepped:Connect(function()
		if isKnockedState then
			local shakeIntensity = 0.05
			local offset = Vector3.new(
				(math.random() - 0.5) * shakeIntensity,
				(math.random() - 0.5) * shakeIntensity,
				(math.random() - 0.5) * shakeIntensity
			)
			-- Only apply slight offset without locking camera completely
			camera.CFrame = camera.CFrame * CFrame.new(offset)
		else
			if shakeConnection then shakeConnection:Disconnect() end
		end
	end)
end

-- Animations
local function startAnimations()
	local heartInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1)
	heartbeatTween = TweenService:Create(heartIcon, heartInfo, {Size = UDim2.new(0, 72, 0, 72)})
	heartbeatTween:Play()

	local vigInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	pulseTween = TweenService:Create(vignette, vigInfo, {ImageTransparency = 0, ImageColor3 = Color3.fromRGB(153, 27, 27)})
	pulseTween:Play()

	local textTween = TweenService:Create(vitalText, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.5})
	textTween:Play()

	-- New Overlay Pulse
	local overlayInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	overlayPulseTween = TweenService:Create(pulseOverlay, overlayInfo, {BackgroundTransparency = 0.7})
	overlayPulseTween:Play()

	startScreenShake()
end

local function stopAnimations()
	if heartbeatTween then heartbeatTween:Cancel() end
	if pulseTween then pulseTween:Cancel() end
	if overlayPulseTween then overlayPulseTween:Cancel() end
	if shakeConnection then shakeConnection:Disconnect() end

	heartIcon.Size = UDim2.new(0, 64, 0, 64)
	vignette.ImageTransparency = 0.2
	pulseOverlay.BackgroundTransparency = 1 -- Reset overlay
end

-- Updates
local function updateMedicDistance()
	local closestDist = 999
	local myChar = player.Character
	if not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart")
			local isKnocked = p.Character:FindFirstChild("Knocked")
			if root and not isKnocked then
				local dist = (root.Position - myRoot.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
				end
			end
		end
	end

	if closestDist < 999 then
		medicLabel.Text = string.format("Menunggu bantuan tim... <font color='#22d3ee'><b>Player terdekat: %dm</b></font>", math.floor(closestDist))
	else
		medicLabel.Text = "Menunggu bantuan tim... <font color='#ef4444'><b>Player terdekat: --</b></font>"
	end
end

local function updateSpinner(dt)
	-- Smooth Spinner for Revive
	if isReviving then
		spinner.Rotation = spinner.Rotation + (180 * dt) -- 180 deg/sec
	end
end

-- Ping Logic
local function onPing()
	if isPingOnCooldown then return end
	isPingOnCooldown = true

	-- Use Safe Event Call
	if PingKnockedPlayerEvent then
		PingKnockedPlayerEvent:FireServer()
	end

	pingButton.Text = "SIGNAL SENT..."
	pingButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129) -- Greenish feedback

	local cd = PING_COOLDOWN
	cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
	cooldownOverlay.Visible = true

	local cdTween = TweenService:Create(cooldownOverlay, TweenInfo.new(PING_COOLDOWN, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
	cdTween:Play()

	task.spawn(function()
		while cd > 0 do
			pingButton.Text = string.format("COOLDOWN (%d)", math.ceil(cd))
			task.wait(0.1)
			cd = cd - 0.1
		end
		isPingOnCooldown = false
		pingButton.Text = "SOS SIGNAL (H)"
		pingButton.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
	end)
end

pingButton.MouseButton1Click:Connect(onPing)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.H and isKnockedState then
		onPing()
	end
end)

-- Event Handlers
KnockEvent.OnClientEvent:Connect(function(isKnocked)
	isKnockedState = isKnocked
	screenGui.Enabled = isKnocked

	if isKnocked then
		reviveHint.Visible = false
		startAnimations()

		loops.medic = RunService.Heartbeat:Connect(updateMedicDistance)
		loops.spinner = RunService.RenderStepped:Connect(updateSpinner)
	else
		stopAnimations()
		for _, conn in pairs(loops) do
			conn:Disconnect()
		end
		loops = {}
	end
end)

if ReviveProgressEvent then
	ReviveProgressEvent.OnClientEvent:Connect(function(progress, isCancelled)
		if not isKnockedState then return end

		if isCancelled or progress <= 0 then
			reviveHint.Visible = false
			isReviving = false
		else
			reviveHint.Visible = true
			isReviving = true
		end
	end)
end

-- Game Over Handler
if GameOverEvent then
	GameOverEvent.OnClientEvent:Connect(function()
		isKnockedState = false
		screenGui.Enabled = false
		stopAnimations()
		for _, conn in pairs(loops) do
			conn:Disconnect()
		end
		loops = {}
	end)
end
