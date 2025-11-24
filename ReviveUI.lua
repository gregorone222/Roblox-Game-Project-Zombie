-- ReviveUI.lua (LocalScript)
-- Path: StarterGui/ReviveUI.lua
-- Script Place: ACT 1: Village

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local ReviveEvent = RemoteEvents:WaitForChild("ReviveEvent")
local CancelReviveEvent = RemoteEvents:WaitForChild("CancelReviveEvent")
local ReviveProgressEvent = RemoteEvents:WaitForChild("ReviveProgressEvent")
local GameSettingsUpdateEvent = RemoteEvents:WaitForChild("GameSettingsUpdateEvent")

local currentDifficulty = "Easy" -- Default

GameSettingsUpdateEvent.OnClientEvent:Connect(function(settings)
	if settings and settings.difficulty then
		currentDifficulty = settings.difficulty
	end
end)

-- ============================================================================
-- UI CREATION
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReviveUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- 1. WORLD MARKER (BillboardGui)
local worldMarker = Instance.new("BillboardGui")
worldMarker.Name = "WorldMarker"
worldMarker.Size = UDim2.new(0, 200, 0, 100)
worldMarker.StudsOffset = Vector3.new(0, 3, 0)
worldMarker.AlwaysOnTop = true
worldMarker.Enabled = false
worldMarker.Parent = playerGui -- Parent to PlayerGui directly

local wmContainer = Instance.new("Frame")
wmContainer.Size = UDim2.new(1, 0, 1, 0)
wmContainer.BackgroundTransparency = 1
wmContainer.Parent = worldMarker

local iconBg = Instance.new("Frame")
iconBg.Name = "IconBg"
iconBg.Size = UDim2.new(0, 40, 0, 40)
iconBg.Position = UDim2.new(0.5, -20, 0, 0)
iconBg.BackgroundColor3 = Color3.fromRGB(220, 38, 38) -- Red-600
iconBg.BackgroundTransparency = 0.1
iconBg.BorderSizePixel = 0
iconBg.Parent = wmContainer

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconBg

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(248, 113, 113) -- Red-400
iconStroke.Thickness = 2
iconStroke.Parent = iconBg

local plusIcon = Instance.new("TextLabel")
plusIcon.Text = "+"
plusIcon.Size = UDim2.new(1, 0, 1, -4) -- offset slightly
plusIcon.Position = UDim2.new(0,0,0,0)
plusIcon.BackgroundTransparency = 1
plusIcon.TextColor3 = Color3.new(1,1,1)
plusIcon.TextScaled = true
plusIcon.Font = Enum.Font.GothamBold
plusIcon.Parent = iconBg

local wmInfoBox = Instance.new("Frame")
wmInfoBox.Position = UDim2.new(0.5, 0, 0, 45)
wmInfoBox.AnchorPoint = Vector2.new(0.5, 0)
wmInfoBox.Size = UDim2.new(0, 140, 0, 36)
wmInfoBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
wmInfoBox.BackgroundTransparency = 0.4
wmInfoBox.BorderSizePixel = 0
wmInfoBox.Parent = wmContainer

local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 6)
wmCorner.Parent = wmInfoBox

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = Color3.fromRGB(239, 68, 68) -- Red-500
wmStroke.Thickness = 2 -- Border-l-4 simulation
wmStroke.Transparency = 0
wmStroke.Parent = wmInfoBox

local wmName = Instance.new("TextLabel")
wmName.Name = "PlayerName"
wmName.Size = UDim2.new(1, -10, 0, 20)
wmName.Position = UDim2.new(0, 5, 0, 0)
wmName.BackgroundTransparency = 1
wmName.Text = "PlayerName"
wmName.TextColor3 = Color3.new(1,1,1)
wmName.Font = Enum.Font.GothamBold
wmName.TextSize = 16
wmName.TextXAlignment = Enum.TextXAlignment.Center
wmName.Parent = wmInfoBox

local wmStatus = Instance.new("TextLabel")
wmStatus.Size = UDim2.new(1, -10, 0, 12)
wmStatus.Position = UDim2.new(0, 5, 0, 20)
wmStatus.BackgroundTransparency = 1
wmStatus.Text = "CRITICALLY WOUNDED"
wmStatus.TextColor3 = Color3.fromRGB(252, 165, 165) -- Red-300
wmStatus.Font = Enum.Font.Gotham
wmStatus.TextSize = 10
wmStatus.TextXAlignment = Enum.TextXAlignment.Center
wmStatus.Parent = wmInfoBox

local wmDistance = Instance.new("TextLabel")
wmDistance.Name = "DistanceLabel"
wmDistance.Size = UDim2.new(0, 80, 0, 20)
wmDistance.Position = UDim2.new(0.5, -40, 1, 2)
wmDistance.BackgroundColor3 = Color3.fromRGB(0,0,0)
wmDistance.BackgroundTransparency = 0.6
wmDistance.Text = "5m Away"
wmDistance.TextColor3 = Color3.new(1,1,1)
wmDistance.Font = Enum.Font.GothamMedium
wmDistance.TextSize = 12
wmDistance.Parent = wmContainer

local wmDistCorner = Instance.new("UICorner")
wmDistCorner.CornerRadius = UDim.new(0, 4)
wmDistCorner.Parent = wmDistance

-- "Press E" Prompt on WorldMarker
local wmPrompt = Instance.new("TextLabel")
wmPrompt.Name = "PromptLabel"
wmPrompt.Size = UDim2.new(0, 100, 0, 24)
wmPrompt.Position = UDim2.new(0.5, -50, 0.8, 0) -- Moved up to ensure visibility inside billboard
wmPrompt.BackgroundColor3 = Color3.fromRGB(22, 163, 74) -- Green-600
wmPrompt.Text = "PRESS E"
wmPrompt.TextColor3 = Color3.new(1,1,1)
wmPrompt.Font = Enum.Font.GothamBold
wmPrompt.TextSize = 14
wmPrompt.Visible = false
wmPrompt.Parent = wmContainer

local wmPromptCorner = Instance.new("UICorner")
wmPromptCorner.CornerRadius = UDim.new(0, 4)
wmPromptCorner.Parent = wmPrompt

-- Pulse Animation for WorldMarker
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseTween = TweenService:Create(iconBg, tweenInfo, {Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0.5, -22, 0, -2)})
pulseTween:Play()


-- 2. FOCUS UI (The Revive Radial Interface)
local focusUI = Instance.new("Frame")
focusUI.Name = "FocusUI"
focusUI.Size = UDim2.new(1, 0, 1, 0)
focusUI.BackgroundTransparency = 1
focusUI.Visible = false
focusUI.Parent = screenGui

local centerContainer = Instance.new("Frame")
centerContainer.Size = UDim2.new(0, 200, 0, 200)
centerContainer.Position = UDim2.new(0.5, -100, 0.4, -100)
centerContainer.BackgroundTransparency = 1
centerContainer.Parent = focusUI

-- Radial Progress Bar Construction
local radialSize = 120
local radialContainer = Instance.new("Frame")
radialContainer.Name = "RadialContainer"
radialContainer.Size = UDim2.new(0, radialSize, 0, radialSize)
radialContainer.Position = UDim2.new(0.5, -radialSize/2, 0, 0)
radialContainer.BackgroundTransparency = 1
radialContainer.Parent = centerContainer

local bgCircle = Instance.new("Frame")
bgCircle.Size = UDim2.new(1, 0, 1, 0)
bgCircle.BackgroundTransparency = 1
bgCircle.Parent = radialContainer

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = bgCircle

local bgStroke = Instance.new("UIStroke")
bgStroke.Thickness = 8
bgStroke.Color = Color3.fromRGB(30, 41, 59) -- Slate-800
bgStroke.Transparency = 0.2
bgStroke.Parent = bgCircle

-- Using UIGradient Rotation Method for Radial Bar
local progressCircle = Instance.new("Frame")
progressCircle.Size = UDim2.new(1, 0, 1, 0)
progressCircle.BackgroundTransparency = 1
progressCircle.Rotation = -90 -- Start from top
progressCircle.Parent = radialContainer

local pcCorner = Instance.new("UICorner")
pcCorner.CornerRadius = UDim.new(1, 0)
pcCorner.Parent = progressCircle

local pcStroke = Instance.new("UIStroke")
pcStroke.Thickness = 8
pcStroke.Color = Color3.fromRGB(74, 222, 128)
pcStroke.Parent = progressCircle

-- Frame 1 (First Half)
local half1 = Instance.new("Frame")
half1.Name = "Half1"
half1.Size = UDim2.new(1, 0, 1, 0)
half1.BackgroundTransparency = 1
half1.Rotation = -90 -- Top to Right
half1.Parent = radialContainer
local h1Corner = Instance.new("UICorner"); h1Corner.CornerRadius = UDim.new(1,0); h1Corner.Parent = half1
local h1Stroke = Instance.new("UIStroke"); h1Stroke.Thickness = 8; h1Stroke.Color = Color3.fromRGB(74, 222, 128); h1Stroke.Parent = half1
local h1Grad = Instance.new("UIGradient")
h1Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(0.501,1), NumberSequenceKeypoint.new(1,1)})
h1Grad.Rotation = 180 -- Starts hidden
h1Grad.Parent = h1Stroke

-- Frame 2 (Second Half)
local half2 = Instance.new("Frame")
half2.Name = "Half2"
half2.Size = UDim2.new(1, 0, 1, 0)
half2.BackgroundTransparency = 1
half2.Rotation = 90 -- Bottom to Left
half2.Parent = radialContainer
local h2Corner = Instance.new("UICorner"); h2Corner.CornerRadius = UDim.new(1,0); h2Corner.Parent = half2
local h2Stroke = Instance.new("UIStroke"); h2Stroke.Thickness = 8; h2Stroke.Color = Color3.fromRGB(74, 222, 128); h2Stroke.Parent = half2
local h2Grad = Instance.new("UIGradient")
h2Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(0.501,1), NumberSequenceKeypoint.new(1,1)})
h2Grad.Rotation = 180
h2Grad.Parent = h2Stroke


local function updateRadial(pct)
	-- pct is 0 to 1
	-- Half 1 handles 0 to 0.5
	-- Half 2 handles 0.5 to 1

	-- First Half:
	local p1 = math.clamp(pct / 0.5, 0, 1)
	local rot1 = 180 + (p1 * 180) -- 180->360
	h1Grad.Rotation = rot1

	-- Second Half:
	local p2 = math.clamp((pct - 0.5) / 0.5, 0, 1)
	local rot2 = 180 + (p2 * 180)
	h2Grad.Rotation = rot2

	-- Visibility
	if pct <= 0 then
		half1.Visible = false
		half2.Visible = false
	elseif pct < 0.5 then
		half1.Visible = true
		half2.Visible = false
	else
		half1.Visible = true
		half2.Visible = true
		h1Grad.Rotation = 0 -- Full
	end
end
updateRadial(0)


-- Center Text
local percentText = Instance.new("TextLabel")
percentText.Size = UDim2.new(1, 0, 1, 0)
percentText.BackgroundTransparency = 1
percentText.Text = "0%"
percentText.TextColor3 = Color3.fromRGB(74, 222, 128)
percentText.Font = Enum.Font.GothamBold
percentText.TextSize = 24
percentText.Parent = radialContainer

local revivingLabel = Instance.new("TextLabel")
revivingLabel.Size = UDim2.new(1, 0, 0, 20)
revivingLabel.Position = UDim2.new(0, 0, 0.65, 0)
revivingLabel.BackgroundTransparency = 1
revivingLabel.Text = "REVIVING"
revivingLabel.TextColor3 = Color3.fromRGB(187, 247, 208)
revivingLabel.Font = Enum.Font.Gotham
revivingLabel.TextSize = 10
revivingLabel.Parent = radialContainer


-- Action Text Below
local actionText = Instance.new("TextLabel")
actionText.Size = UDim2.new(1, 0, 0, 30)
actionText.Position = UDim2.new(0, 0, 1, 20)
actionText.BackgroundTransparency = 1
actionText.Text = "RESCUING JOHAN"
actionText.TextColor3 = Color3.new(1,1,1)
actionText.Font = Enum.Font.GothamBold
actionText.TextSize = 20
actionText.Parent = centerContainer

local promptContainer = Instance.new("Frame")
promptContainer.Size = UDim2.new(1, 0, 0, 40)
promptContainer.Position = UDim2.new(0, 0, 1, 60)
promptContainer.BackgroundTransparency = 1
promptContainer.Parent = centerContainer

-- PC Prompt
-- PC Prompt (Hidden, moved to billboard)
local pcPrompt = Instance.new("Frame")
pcPrompt.Visible = false -- User requested to move prompt to BillboardGui
pcPrompt.Parent = promptContainer

-- Mobile Prompt (Button)
local mobileBtn = Instance.new("TextButton")
mobileBtn.Name = "MobileReviveBtn"
mobileBtn.Size = UDim2.new(0, 180, 0, 50)
mobileBtn.Position = UDim2.new(0.5, -90, 1, 60)
mobileBtn.BackgroundColor3 = Color3.fromRGB(22, 163, 74)
mobileBtn.Text = "TAP TO REVIVE" -- Changed from TAP & HOLD
mobileBtn.Font = Enum.Font.GothamBold
mobileBtn.TextColor3 = Color3.new(1,1,1)
mobileBtn.TextSize = 16
mobileBtn.Visible = false
mobileBtn.Parent = centerContainer
local mbCorner = Instance.new("UICorner"); mbCorner.CornerRadius = UDim.new(1,0); mbCorner.Parent = mobileBtn

-- ============================================================================
-- LOGIC
-- ============================================================================

local isReviving = false
local currentTarget = nil
local totalReviveTime = 6
local lastKnownTarget = nil

-- Handle Input Type Display
local function updateInputType()
	if UIS.TouchEnabled and not UIS.MouseEnabled then
		pcPrompt.Visible = false
		mobileBtn.Visible = true
	else
		pcPrompt.Visible = true
		mobileBtn.Visible = false
	end
end
updateInputType()
UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(updateInputType)


-- Revive Event Logic
ReviveProgressEvent.OnClientEvent:Connect(function(progress, cancelled, reviveTime)
	if cancelled then
		focusUI.Visible = false
		isReviving = false
		if currentTarget then
			-- logic to show marker again handled by loop
		end
		currentTarget = nil
		updateRadial(0)
		return
	end

	if reviveTime then
		totalReviveTime = reviveTime
	end

	isReviving = true
	focusUI.Visible = true
	worldMarker.Enabled = false

	updateRadial(progress)
	percentText.Text = string.format("%d%%", math.floor(progress * 100))

	if progress >= 1 then
		percentText.Text = "100%"
		percentText.TextColor3 = Color3.fromRGB(34, 211, 238) -- Cyan-400
		h1Stroke.Color = Color3.fromRGB(34, 211, 238)
		h2Stroke.Color = Color3.fromRGB(34, 211, 238)

		task.delay(0.5, function()
			focusUI.Visible = false
			isReviving = false
			currentTarget = nil
			percentText.TextColor3 = Color3.fromRGB(74, 222, 128)
			h1Stroke.Color = Color3.fromRGB(74, 222, 128)
			h2Stroke.Color = Color3.fromRGB(74, 222, 128)
			updateRadial(0)
		end)
	end
end)

local function startRevive(target)
	if player.Character and player.Character:FindFirstChild("Knocked") then return end
	if isReviving then return end

	currentTarget = target
	actionText.Text = "RESCUING " .. string.upper(target.DisplayName or target.Name)

	ReviveEvent:FireServer(target)
end

local function cancelRevive()
	if isReviving then
		CancelReviveEvent:FireServer()
		isReviving = false
		focusUI.Visible = false
		updateRadial(0)
	end
end

-- Input Handling
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- PC Interaction (Press E 1x)
	if input.KeyCode == Enum.KeyCode.E then
		if isReviving then
			-- Optional: Toggle off if pressed again? 
			-- User said "Press 1x" to revive. Usually this implies start and forget (until move).
			-- But if they press E again, maybe cancel? Let's stick to cancelling on move only for now to prevent accidental cancels.
		else
			if lastKnownTarget then
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local dist = (char.HumanoidRootPart.Position - lastKnownTarget.Character.HumanoidRootPart.Position).Magnitude
					if dist <= 8 then
						startRevive(lastKnownTarget)
					end
				end
			end
		end
	end

	-- Handle Touch to Start Revive (Mobile "Tap Anywhere")
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if not isReviving then
			-- Try to start revive if near a target
			if lastKnownTarget then
				local char = player.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local dist = (char.HumanoidRootPart.Position - lastKnownTarget.Character.HumanoidRootPart.Position).Magnitude
					if dist <= 8 then
						startRevive(lastKnownTarget)
					end
				end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if isReviving then
		-- Cancel only on movement keys
		if UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or
			UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D) or
			UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.R) or
			UIS:IsKeyDown(Enum.KeyCode.Q) then
			cancelRevive()
		end

		-- Removed "Hold E" check as per request
	end
end)


-- Main Loop
RunService.RenderStepped:Connect(function()
	local char = player.Character

	if not char or not char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Knocked") then
		worldMarker.Enabled = false
		if isReviving then cancelRevive() end
		return
	end

	if currentDifficulty == "Crazy" then
		worldMarker.Enabled = false
		return
	end

	local nearest = nil
	local minDist = 8

	for _, other in pairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			local isKnocked = other.Character:FindFirstChild("Knocked")

			if otherRoot and isKnocked then
				local d = (char.HumanoidRootPart.Position - otherRoot.Position).Magnitude
				if d < 50 then
					if not nearest or d < (char.HumanoidRootPart.Position - nearest.Character.HumanoidRootPart.Position).Magnitude then
						nearest = other
					end
				end
			end
		end
	end

	if nearest then
		local dist = (char.HumanoidRootPart.Position - nearest.Character.HumanoidRootPart.Position).Magnitude

		if not isReviving then
			worldMarker.Adornee = nearest.Character.HumanoidRootPart
			worldMarker.Enabled = true

			wmName.Text = nearest.DisplayName
			wmDistance.Text = string.format("%dm Away", math.floor(dist))

			if dist <= 8 then
				-- In Range: Show Prompt
				wmDistance.Visible = false
				wmPrompt.Visible = true
				if UIS.TouchEnabled and not UIS.MouseEnabled then
					wmPrompt.Text = "TAP TO REVIVE"
				else
					wmPrompt.Text = "PRESS E"
				end
			else
				-- Out of Range: Show Distance
				wmDistance.Visible = true
				wmPrompt.Visible = false
				wmDistance.TextColor3 = Color3.new(1,1,1)
			end
		else
			worldMarker.Enabled = false
		end

		lastKnownTarget = nearest
	else
		worldMarker.Enabled = false
		lastKnownTarget = nil
	end

	-- "Hold E" check loop removed. Logic is now event-based in InputBegan.
end)

mobileBtn.MouseButton1Down:Connect(function()
	if lastKnownTarget and not isReviving then
		local dist = (player.Character.HumanoidRootPart.Position - lastKnownTarget.Character.HumanoidRootPart.Position).Magnitude
		if dist <= 8 then
			startRevive(lastKnownTarget)
		end
	end
end)

-- Removed MobileButton1Up to allow "Press 1x" behavior
	