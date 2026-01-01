-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- StartLobby.lua (LocalScript)
-- Path: StarterGui/StartLobby.lua
-- Script Place: Lobby Only
-- Description: Handles Cinematic Title Screen and Diegetic Daily Reward Notification upon Player Entry.

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- --- CONFIG ---
local THEME = {
	COLORS = {
		TEXT_GHOST = Color3.fromRGB(200, 200, 200),
		TEXT_BLOOD = Color3.fromRGB(160, 0, 0),
		TEXT_DIM = Color3.fromRGB(80, 80, 80),
		BAR_BLACK = Color3.new(0, 0, 0)
	},
	FONTS = {
		TITLE = Enum.Font.Merriweather,
		BODY = Enum.Font.Gotham,
		MONO = Enum.Font.Code
	}
}

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local GetDailyRewardInfo = RemoteFunctions:WaitForChild("GetDailyRewardInfo")

-- --- UI ELEMENTS ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyEntryInterface"
screenGui.IgnoreGuiInset = true -- Covers top bar
screenGui.ScreenInsets = Enum.ScreenInsets.None -- Force full screen ignoring safe areas
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- CINEMATIC BARS
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundColor3 = THEME.COLORS.BAR_BLACK
topBar.BorderSizePixel = 0
topBar.Size = UDim2.fromScale(1, 0) -- Start hidden
topBar.Position = UDim2.fromScale(0, 0)
topBar.ZIndex = 10
topBar.Parent = screenGui

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.BackgroundColor3 = THEME.COLORS.BAR_BLACK
bottomBar.BorderSizePixel = 0
bottomBar.Size = UDim2.fromScale(1, 0) -- Start hidden
bottomBar.Position = UDim2.fromScale(0, 1)
bottomBar.AnchorPoint = Vector2.new(0, 1)
bottomBar.ZIndex = 10
bottomBar.Parent = screenGui

-- 1. CINEMATIC TITLE CONTENT
local cinematicFrame = Instance.new("Frame")
cinematicFrame.Name = "CinematicFrame"
cinematicFrame.Size = UDim2.fromScale(1, 1)
cinematicFrame.BackgroundColor3 = Color3.new(0,0,0)
cinematicFrame.BackgroundTransparency = 1
cinematicFrame.Visible = false
cinematicFrame.ZIndex = 11 -- Above bars
cinematicFrame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "GameTitle"
titleLabel.Text = "ZOMBIE?"
titleLabel.Font = THEME.FONTS.TITLE
titleLabel.TextScaled = true -- RESPONSIVE UPDATE
titleLabel.TextColor3 = THEME.COLORS.TEXT_GHOST
titleLabel.Size = UDim2.fromScale(0.6, 0.15) -- RESPONSIVE UPDATE: Scale
titleLabel.Position = UDim2.fromScale(0.5, 0.4)
titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextTransparency = 1
titleLabel.Parent = cinematicFrame

-- Constraint for Title to not get too huge
local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 100
titleConstraint.Parent = titleLabel

local subTitle = Instance.new("TextLabel")
subTitle.Text = "LOBBY: THE SHELTER"
subTitle.Font = THEME.FONTS.MONO
subTitle.TextScaled = true -- RESPONSIVE UPDATE
subTitle.TextColor3 = THEME.COLORS.TEXT_BLOOD
subTitle.Size = UDim2.fromScale(0.4, 0.03) -- RESPONSIVE UPDATE: Scale
subTitle.Position = UDim2.fromScale(0.5, 0.5)
subTitle.AnchorPoint = Vector2.new(0.5, 0.5)
subTitle.BackgroundTransparency = 1
subTitle.TextTransparency = 1
subTitle.Parent = cinematicFrame

local subTitleConstraint = Instance.new("UITextSizeConstraint")
subTitleConstraint.MaxTextSize = 20
subTitleConstraint.Parent = subTitle

local playBtn = Instance.new("TextButton")
playBtn.Name = "PlayButton"
playBtn.Text = "ENTER"
playBtn.Font = THEME.FONTS.BODY
playBtn.TextScaled = true -- RESPONSIVE UPDATE
playBtn.TextColor3 = THEME.COLORS.TEXT_DIM
playBtn.Size = UDim2.fromScale(0.2, 0.08) -- RESPONSIVE UPDATE: Scale
playBtn.Position = UDim2.fromScale(0.5, 0.8)
playBtn.AnchorPoint = Vector2.new(0.5, 0.5)
playBtn.BackgroundTransparency = 1
playBtn.TextTransparency = 1
playBtn.Parent = cinematicFrame

-- Aspect Ratio for Button
local btnAspect = Instance.new("UIAspectRatioConstraint")
btnAspect.AspectRatio = 4 -- Keep 4:1 ratio like 200:50
btnAspect.Parent = playBtn

local promptIndicator = Instance.new("TextLabel")
promptIndicator.Name = "PromptIndicator"
promptIndicator.Text = "- PRESS ENTER TO START -"
promptIndicator.Font = THEME.FONTS.MONO
promptIndicator.TextScaled = true -- RESPONSIVE UPDATE
promptIndicator.TextColor3 = THEME.COLORS.TEXT_GHOST
promptIndicator.Size = UDim2.fromScale(0.3, 0.025) -- RESPONSIVE UPDATE: Scale
promptIndicator.Position = UDim2.fromScale(0.5, 0.86) -- RESPONSIVE UPDATE: Relative Scale
promptIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
promptIndicator.BackgroundTransparency = 1
promptIndicator.TextTransparency = 1
promptIndicator.Parent = cinematicFrame

-- 2. NOTIFICATION HUD (Daily Reward)
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.fromScale(0.25, 0.06) -- RESPONSIVE UPDATE: Scale
notifFrame.Position = UDim2.fromScale(0.98, 0.05) -- RESPONSIVE UPDATE: Scale Position
notifFrame.AnchorPoint = Vector2.new(1, 0)
notifFrame.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
notifFrame.BackgroundTransparency = 0.5
notifFrame.Visible = false
notifFrame.ZIndex = 12
notifFrame.Parent = screenGui
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0.2, 0) -- Relative Corner

-- Aspect Ratio for Notif to prevent squishing
local notifAspect = Instance.new("UIAspectRatioConstraint")
notifAspect.AspectRatio = 6 -- Approx 250:40
notifAspect.Parent = notifFrame

local notifText = Instance.new("TextLabel")
notifText.Text = "SUPPLY DROP AVAILABLE"
notifText.Size = UDim2.fromScale(0.9, 0.8)
notifText.Position = UDim2.fromScale(0.5, 0.5)
notifText.AnchorPoint = Vector2.new(0.5, 0.5)
notifText.BackgroundTransparency = 1
notifText.TextColor3 = Color3.new(1,1,1)
notifText.Font = THEME.FONTS.MONO
notifText.TextScaled = true -- RESPONSIVE UPDATE
notifText.Parent = notifFrame

-- --- LOGIC ---
local isTitleMode = false
local cameraTween = nil
local hideCharactersConnection = nil
local inputConnection = nil
local uiEnforcerConnection = nil
local uiPropertyConnections = {} -- Store property change connections for clean disconnect
local blinkTweens = {} -- Store blink tweens to cancel them properly

-- List of Lobby UIs to hide during cinematic
-- Note: Popup UIs (like DailyRewardUI) are excluded because they're created on-demand
local LOBBY_UIS = {
	"SurvivalCoinsUI", "UTCClockUI", "MissionPointsUI", "AchievementPointsUI",
	"ProfileUI", "DailyRewardHUD", "InventoryUI", "MissionUI"
}

-- Helper: Find ScreenGui by name (handles case where LocalScript has same name)
local function findScreenGuiByName(name)
	for _, child in ipairs(playerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == name then
			return child
		end
	end
	return nil
end

local function setLobbyUIVisibility(visible)
	print("StartLobby: Setting Lobby UI Visibility to", visible)

	if not visible then
		-- When hiding, just iterate once (UIs that don't exist yet will be caught by ChildAdded)
		for _, name in ipairs(LOBBY_UIS) do
			local ui = findScreenGuiByName(name)
			if ui then
				ui.Enabled = false
			end
		end
		return
	end

	-- When showing, use retry mechanism for each UI that doesn't exist yet
	local pendingUIs = {}
	for _, name in ipairs(LOBBY_UIS) do
		pendingUIs[name] = true
	end

	-- Retry for up to 5 seconds
	local maxAttempts = 10
	local attemptDelay = 0.5

	for attempt = 1, maxAttempts do
		for name, _ in pairs(pendingUIs) do
			local ui = findScreenGuiByName(name)
			if ui then
				ui.Enabled = true
				if ui.DisplayOrder < 1 then
					ui.DisplayOrder = 10
				end
				print("StartLobby: Successfully set", name, "Enabled = true (attempt", attempt..")")
				pendingUIs[name] = nil -- Remove from pending
			end
		end

		-- If all UIs found, exit early
		if next(pendingUIs) == nil then
			print("StartLobby: All UIs found and enabled!")
			return
		end

		-- Wait before next attempt (except on last attempt)
		if attempt < maxAttempts then
			task.wait(attemptDelay)
		end
	end

	-- Log UIs that were never found
	for name, _ in pairs(pendingUIs) do
		warn("StartLobby: UI '"..name.."' not found after", maxAttempts, "attempts")
	end
end

-- Helper function to enforce UI disabled state via event (not polling)
local function enforceUIDisabled(ui)
	if not ui:IsA("ScreenGui") then return end

	-- Set initial state
	ui.Enabled = false

	-- Hook to property change (fires only when something tries to change it)
	local conn = ui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if isTitleMode and ui.Enabled then
			ui.Enabled = false
		end
	end)
	table.insert(uiPropertyConnections, conn)
end

local uiEnforcerHeartbeat = nil -- Heartbeat backup loop

local function startUIEnforcer()
	-- 1. Hook new UIs that load later FIRST (before iterating existing)
	if uiEnforcerConnection then uiEnforcerConnection:Disconnect() end
	uiEnforcerConnection = playerGui.ChildAdded:Connect(function(child)
		if table.find(LOBBY_UIS, child.Name) then
			print("StartLobby: ChildAdded caught -", child.Name, "- disabling")
			enforceUIDisabled(child)
		end
	end)

	-- 2. Hook existing UIs immediately
	for _, name in ipairs(LOBBY_UIS) do
		local ui = findScreenGuiByName(name)
		if ui then
			print("StartLobby: Found existing UI -", name, "- disabling")
			enforceUIDisabled(ui)
		end
	end

	-- 3. Heartbeat backup: periodically check and disable UIs (handles race conditions)
	if uiEnforcerHeartbeat then uiEnforcerHeartbeat:Disconnect() end
	local lastCheck = 0
	uiEnforcerHeartbeat = RunService.Heartbeat:Connect(function()
		if not isTitleMode then return end

		-- Check every 0.1 seconds for faster response
		local now = tick()
		if now - lastCheck < 0.1 then return end
		lastCheck = now

		for _, name in ipairs(LOBBY_UIS) do
			local ui = findScreenGuiByName(name)
			if ui and ui.Enabled then
				print("StartLobby Heartbeat: Force disabling", name)
				ui.Enabled = false
			end
		end
	end)

	print("StartLobby: UI Enforcer started, isTitleMode =", isTitleMode)
end

local function stopUIEnforcer()
	-- Disconnect Heartbeat backup
	if uiEnforcerHeartbeat then
		uiEnforcerHeartbeat:Disconnect()
		uiEnforcerHeartbeat = nil
	end

	-- Disconnect all property change connections
	for _, conn in ipairs(uiPropertyConnections) do
		if conn then conn:Disconnect() end
	end
	uiPropertyConnections = {}

	if uiEnforcerConnection then
		uiEnforcerConnection:Disconnect()
		uiEnforcerConnection = nil
	end
end

-- Helper to find interesting things to look at
local function getInterestingTargets()
	local targets = {}
	local lobby = workspace:FindFirstChild("LobbyEnvironment")
	if lobby then
		local interestNames = {
			"CampfireBase", "TrainCar_0", "CommandTable",
			"TubeLight", "SupplyCrate", "StartPart"
		}
		for _, desc in ipairs(lobby:GetDescendants()) do
			if desc:IsA("BasePart") then
				for _, name in ipairs(interestNames) do
					if string.find(desc.Name, name) then
						table.insert(targets, desc)
						break
					end
				end
			end
		end
	end

	-- Fallback
	if #targets == 0 then table.insert(targets, {Position = Vector3.new(0, 5, 0)}) end
	return targets
end

local function getCameraWaypoints()
	local points = {}
	local camFolder = workspace:FindFirstChild("CameraPos")
	if camFolder then
		local children = camFolder:GetChildren()
		table.sort(children, function(a, b) return a.Name < b.Name end)
		for _, p in ipairs(children) do
			if p:IsA("BasePart") then table.insert(points, p) end
		end
	end

	-- If no folder, use simple offset points
	if #points == 0 then
		local p1 = {Position = Vector3.new(40, 20, 40)}
		local p2 = {Position = Vector3.new(-40, 15, 30)}
		table.insert(points, p1)
		table.insert(points, p2)
	end
	return points
end

local function togglePlayerVisibility(visible)
	-- Target ALL players, including LocalPlayer
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer.Character then
			-- Hide Parts & Decals
			for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") or part:IsA("Decal") then
					part.LocalTransparencyModifier = visible and 0 or 1
				end
				-- Hide NameTags or UI overhead
				if part:IsA("BillboardGui") or part:IsA("SurfaceGui") then
					part.Enabled = visible
				end
			end
		end
	end
end

local function startCameraLoop()
	local waypoints = getCameraWaypoints()
	local targets = getInterestingTargets()
	local index = 1

	-- Initial Setup: Set camera to FIRST waypoint instantly
	if #waypoints > 0 then
		local startTarget = targets[math.random(1, #targets)]
		camera.CFrame = CFrame.lookAt(waypoints[1].Position, startTarget.Position)
	end

	task.spawn(function()
		while isTitleMode and #waypoints > 0 do
			-- Calculate NEXT target state
			local nextIndex = index + 1
			if nextIndex > #waypoints then nextIndex = 1 end

			local nextWaypoint = waypoints[nextIndex]
			local nextLookTarget = targets[math.random(1, #targets)]

			-- Ensure target changes for variety
			if #targets > 1 and (nextLookTarget.Position - camera.CFrame.Position).Magnitude < 10 then
				nextLookTarget = targets[(math.random(1, #targets) % #targets) + 1]
			end

			-- Goal CFrame: Position of Next Waypoint, Looking at Next Target
			local goalCFrame = CFrame.lookAt(nextWaypoint.Position, nextLookTarget.Position)

			-- Tween from CURRENT CFrame to GOAL
			local duration = 12
			local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			cameraTween = TweenService:Create(camera, tweenInfo, {CFrame = goalCFrame})
			cameraTween:Play()

			cameraTween.Completed:Wait()

			index = nextIndex
		end
	end)
end

local function exitTitleMode()
	if not isTitleMode then return end
	isTitleMode = false
	stopUIEnforcer()
	task.wait(0.1) -- Small delay to ensure all connections are fully disconnected

	-- RESTORE CONTROLS
	-- [DEPRECATED] UIS.ModalEnabled = false
	game:GetService("GuiService").TouchControlsEnabled = true

	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end

	-- Stop Blink Tweens
	for _, t in ipairs(blinkTweens) do
		if t then t:Cancel() end
	end
	blinkTweens = {}

	if cameraTween then cameraTween:Cancel() end
	if hideCharactersConnection then
		hideCharactersConnection:Disconnect()
		hideCharactersConnection = nil
	end

	togglePlayerVisibility(true)

	-- ANIMATION: BARS OUT
	TweenService:Create(topBar, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0)}):Play()

	-- UI Fade Out
	local tInfo = TweenInfo.new(1)
	TweenService:Create(titleLabel, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(subTitle, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(playBtn, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(promptIndicator, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(cinematicFrame, tInfo, {BackgroundTransparency = 1}):Play()

	task.delay(1, function()
		cinematicFrame.Visible = false

		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.Anchored = false end

			local head = char:FindFirstChild("Head")
			if head then
				local camTween = TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = head.CFrame})
				camTween:Play()
				camTween.Completed:Wait()

				-- FORCE FIRST PERSON but ALLOW UNLOCK
				player.CameraMode = Enum.CameraMode.Classic
				player.CameraMinZoomDistance = 0.5
				player.CameraMaxZoomDistance = 0.5 -- Clamp tight first

				camera.CameraType = Enum.CameraType.Custom

				-- Yield slightly to ensure the clamp takes effect
				task.wait()

				-- RELEASE LOCK
				player.CameraMaxZoomDistance = 50
			end
		end

		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		setLobbyUIVisibility(true)

		-- SIGNAL MISSION UI TO OPEN
		local openLobbyEvent = ReplicatedStorage:FindFirstChild("OpenLobbyUI")
		if openLobbyEvent then openLobbyEvent:Fire() end

		-- Check Daily Reward
		task.spawn(function()
			local success, data = pcall(function() return GetDailyRewardInfo:InvokeServer() end)
			if success and data and data.CanClaim then
				notifFrame.Visible = true
				local lobby = workspace:FindFirstChild("LobbyEnvironment")
				local crate = lobby and lobby:FindFirstChild("SupplyCrate", true)
				if crate then
					local highlight = Instance.new("Highlight")
					highlight.FillColor = Color3.fromRGB(0, 255, 0)
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
					highlight.FillTransparency = 0.5
					highlight.OutlineTransparency = 0
					highlight.Parent = crate
				end
				task.wait(5)
				notifFrame.Visible = false
			end
		end)
	end)
end

local function enterTitleMode()
	-- RESET / CLEANUP FIRST
	exitTitleMode()

	isTitleMode = true
	cinematicFrame.Visible = true

	-- Hide Mobile Controls (Analog/Jump)
	-- [DEPRECATED] UIS.ModalEnabled = true
	game:GetService("GuiService").TouchControlsEnabled = false

	-- Freeze Character
	local char = player.Character or player.CharacterAdded:Wait()
	if char then
		local hrp = char:WaitForChild("HumanoidRootPart")
		hrp.Anchored = true
	end

	-- FORCE Hide ALL characters loop (Aggressive)
	hideCharactersConnection = RunService.RenderStepped:Connect(function()
		togglePlayerVisibility(false)
	end)

	-- Camera Setup
	camera.CameraType = Enum.CameraType.Scriptable
	startCameraLoop()

	-- ANIMATION: BARS IN
	TweenService:Create(topBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0.12)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(1, 0.12)}):Play()

	-- UI Fade In
	TweenService:Create(titleLabel, TweenInfo.new(2), {TextTransparency = 0}):Play()
	task.delay(1, function()
		TweenService:Create(subTitle, TweenInfo.new(2), {TextTransparency = 0}):Play()
	end)
	task.delay(2, function()
		-- Initial Fade In for Button
		local btnFade = TweenService:Create(playBtn, TweenInfo.new(1), {TextTransparency = 0})
		btnFade:Play()

		-- Initial Fade In for Prompt
		local promptFade = TweenService:Create(promptIndicator, TweenInfo.new(1), {TextTransparency = 0.5})
		promptFade:Play()

		-- Once fade is complete, START BLINK LOOP
		btnFade.Completed:Connect(function()
			if not isTitleMode then return end
			local btnBlink = TweenService:Create(playBtn, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.4})
			btnBlink:Play()
			table.insert(blinkTweens, btnBlink)
		end)

		promptFade.Completed:Connect(function()
			if not isTitleMode then return end
			local promptBlink = TweenService:Create(promptIndicator, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.3})
			promptBlink:Play()
			table.insert(blinkTweens, promptBlink)
		end)
	end)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	setLobbyUIVisibility(false)
	startUIEnforcer()

	-- Enable Input Listener
	if inputConnection then inputConnection:Disconnect() end
	inputConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
		if isTitleMode and not gameProcessed then
			-- ONLY Allow Enter Key globally. Mobile/Mouse must click the button.
			if input.KeyCode == Enum.KeyCode.Return then
				exitTitleMode()
			end
		end
	end)
end

-- Button handles MouseClick and TouchTap automatically
playBtn.MouseButton1Click:Connect(exitTitleMode)

-- INITIALIZE
task.spawn(function()
	if not game:IsLoaded() then game.Loaded:Wait() end
	task.wait(1)

	if workspace:FindFirstChild("Map_Village") then
		isTitleMode = false
		cinematicFrame.Visible = false
		screenGui:Destroy()
	else
		enterTitleMode()
	end
end)
