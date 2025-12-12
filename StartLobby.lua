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
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- CINEMATIC BARS
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.BackgroundColor3 = THEME.COLORS.BAR_BLACK
topBar.BorderSizePixel = 0
topBar.Size = UDim2.new(1, 0, 0, 0) -- Start hidden
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.ZIndex = 10
topBar.Parent = screenGui

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.BackgroundColor3 = THEME.COLORS.BAR_BLACK
bottomBar.BorderSizePixel = 0
bottomBar.Size = UDim2.new(1, 0, 0, 0) -- Start hidden
bottomBar.Position = UDim2.new(0, 0, 1, 0)
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
titleLabel.TextSize = 80
titleLabel.TextColor3 = THEME.COLORS.TEXT_GHOST
titleLabel.Size = UDim2.new(1, 0, 0, 100)
titleLabel.Position = UDim2.fromScale(0.5, 0.4)
titleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
titleLabel.BackgroundTransparency = 1
titleLabel.TextTransparency = 1
titleLabel.Parent = cinematicFrame

local subTitle = Instance.new("TextLabel")
subTitle.Text = "LOBBY: THE SHELTER"
subTitle.Font = THEME.FONTS.MONO
subTitle.TextSize = 16
subTitle.TextColor3 = THEME.COLORS.TEXT_BLOOD
subTitle.Size = UDim2.new(1, 0, 0, 20)
subTitle.Position = UDim2.fromScale(0.5, 0.5)
subTitle.AnchorPoint = Vector2.new(0.5, 0.5)
subTitle.BackgroundTransparency = 1
subTitle.TextTransparency = 1
subTitle.Parent = cinematicFrame

local playBtn = Instance.new("TextButton")
playBtn.Name = "PlayButton"
playBtn.Text = "ENTER"
playBtn.Font = THEME.FONTS.BODY
playBtn.TextSize = 24
playBtn.TextColor3 = THEME.COLORS.TEXT_DIM
playBtn.Size = UDim2.new(0, 200, 0, 50)
playBtn.Position = UDim2.fromScale(0.5, 0.8)
playBtn.AnchorPoint = Vector2.new(0.5, 0.5)
playBtn.BackgroundTransparency = 1
playBtn.TextTransparency = 1
playBtn.Parent = cinematicFrame

-- 2. NOTIFICATION HUD (Daily Reward)
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.new(0, 250, 0, 40)
notifFrame.Position = UDim2.new(1, -20, 0, 20)
notifFrame.AnchorPoint = Vector2.new(1, 0)
notifFrame.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
notifFrame.BackgroundTransparency = 0.5
notifFrame.Visible = false
notifFrame.ZIndex = 12
notifFrame.Parent = screenGui
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 4)

local notifText = Instance.new("TextLabel")
notifText.Text = "SUPPLY DROP AVAILABLE"
notifText.Size = UDim2.fromScale(1, 1)
notifText.BackgroundTransparency = 1
notifText.TextColor3 = Color3.new(1,1,1)
notifText.Font = THEME.FONTS.MONO
notifText.TextSize = 14
notifText.Parent = notifFrame

-- --- LOGIC ---
local isTitleMode = false
local cameraTween = nil
local hideCharactersConnection = nil

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

local function enterTitleMode()
	isTitleMode = true
	cinematicFrame.Visible = true

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
	TweenService:Create(topBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0.12, 0)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0.12, 0)}):Play()

	-- UI Fade In
	TweenService:Create(titleLabel, TweenInfo.new(2), {TextTransparency = 0}):Play()
	task.delay(1, function()
		TweenService:Create(subTitle, TweenInfo.new(2), {TextTransparency = 0}):Play()
	end)
	task.delay(2, function()
		TweenService:Create(playBtn, TweenInfo.new(1), {TextTransparency = 0}):Play()
	end)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end

local function exitTitleMode()
	isTitleMode = false
	if cameraTween then cameraTween:Cancel() end
	if hideCharactersConnection then
		hideCharactersConnection:Disconnect()
		hideCharactersConnection = nil
	end

	togglePlayerVisibility(true)

	-- ANIMATION: BARS OUT
	TweenService:Create(topBar, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0)}):Play()

	-- UI Fade Out
	local tInfo = TweenInfo.new(1)
	TweenService:Create(titleLabel, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(subTitle, tInfo, {TextTransparency = 1}):Play()
	TweenService:Create(playBtn, tInfo, {TextTransparency = 1}):Play()
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

				-- FORCE FIRST PERSON
				player.CameraMode = Enum.CameraMode.LockFirstPerson
				camera.CameraType = Enum.CameraType.Custom
			end
		end

		camera.CameraType = Enum.CameraType.Custom
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

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
