-- StartUI.lua (LocalScript)
-- Path: StarterGui/StartUI.lua
-- Script Place: ACT 1: Village
-- Theme: Cinematic Horror (Minimalist, Dark, Atmospheric)

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- --- THEME CONFIGURATION ---
local THEME = {
	COLORS = {
		BG_BLACK = Color3.fromRGB(0, 0, 0),
		TEXT_GHOST = Color3.fromRGB(200, 200, 200), -- Pale white
		TEXT_BLOOD = Color3.fromRGB(160, 0, 0),     -- Deep red
		TEXT_DIM = Color3.fromRGB(80, 80, 80),      -- Dark grey
		GLOW_RED = Color3.fromRGB(100, 0, 0)
	},
	FONTS = {
		TITLE = Enum.Font.Merriweather,   -- Classic Serif (Horror feel)
		BODY = Enum.Font.Gotham,          -- Clean modern
		MONO = Enum.Font.Code             -- Technical data
	}
}

local SELECT_ACTION = "StartConfirm_Arrows"
local RemoteEvents = game.ReplicatedStorage.RemoteEvents

local StartGameEvent = RemoteEvents:WaitForChild("StartGameEvent")
local PlayerCountEvent = RemoteEvents:WaitForChild("PlayerCountEvent")
local OpenStartUIEvent = RemoteEvents:WaitForChild("OpenStartUIEvent")
local ReadyCountEvent = RemoteEvents:WaitForChild("ReadyCountEvent")
local StartVoteCountdownEvent = RemoteEvents:WaitForChild("StartVoteCountdownEvent")
local StartVoteCanceledEvent  = RemoteEvents:WaitForChild("StartVoteCanceledEvent")
local CancelStartVoteEvent = RemoteEvents:WaitForChild("CancelStartVoteEvent")
local GameSettingsUpdateEvent = RemoteEvents:WaitForChild("GameSettingsUpdateEvent")

-- --- UTILITY: LIGHTING FX MANAGER ---
local EFFECT_NAME = "StartUI_Cinematic_Effects"
local function setupLightingEffects()
	local existing = Lighting:FindFirstChild(EFFECT_NAME)
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = EFFECT_NAME
	folder.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Cinematic_CC"
	cc.Saturation = -0.8 -- Almost B&W
	cc.Contrast = 0.4    -- High contrast
	cc.Brightness = -0.2
	cc.TintColor = Color3.fromRGB(255, 230, 230) -- Slight red tint
	cc.Enabled = false -- Start disabled
	cc.Parent = folder

	local blur = Instance.new("BlurEffect")
	blur.Name = "Cinematic_Blur"
	blur.Size = 0
	blur.Enabled = false -- Start disabled
	blur.Parent = folder

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "Cinematic_Bloom"
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.8
	bloom.Enabled = false -- Start disabled
	bloom.Parent = folder

	return folder, cc, blur, bloom
end

-- --- UI CREATION ---

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartUI_Cinematic"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

local effectsFolder, ccEffect, blurEffect, bloomEffect = setupLightingEffects()

screenGui.Destroying:Connect(function()
	if effectsFolder then effectsFolder:Destroy() end
end)

-- 1. BACKGROUND (Void)
local bgFrame = Instance.new("Frame")
bgFrame.Name = "Background"
bgFrame.Size = UDim2.new(1, 0, 1, 0)
bgFrame.BackgroundColor3 = THEME.COLORS.BG_BLACK
bgFrame.Visible = false
bgFrame.BackgroundTransparency = 0 -- Fully opaque for isolation
bgFrame.Parent = screenGui

-- Film Grain / Noise
local noise = Instance.new("ImageLabel")
noise.Size = UDim2.new(1, 0, 1, 0)
noise.BackgroundTransparency = 1
noise.Image = "rbxassetid://13449340960" -- Noise texture
-- Fallback if texture fails:
noise.Image = "rbxassetid://2743169888" -- Grid pattern (will look like noise if tiled small)
noise.ImageColor3 = Color3.new(1,1,1)
noise.ImageTransparency = 0.95
noise.ScaleType = Enum.ScaleType.Tile
noise.TileSize = UDim2.new(0, 128, 0, 128)
noise.Parent = bgFrame

-- Animated Noise Position
task.spawn(function()
	while bgFrame.Parent do
		noise.TileSize = UDim2.new(0, math.random(120, 136), 0, math.random(120, 136))
		noise.Position = UDim2.new(0, math.random(-10, 10), 0, math.random(-10, 10))
		task.wait(0.05)
	end
end)

-- Vignette (Heavy)
local vignette = Instance.new("ImageLabel")
vignette.Size = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
vignette.Image = "rbxassetid://4576475446"
vignette.ImageColor3 = Color3.new(0,0,0)
vignette.ImageTransparency = 0.05
vignette.Parent = bgFrame


-- 2. MAIN TITLE (Center)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Text = "THE  VILLAGE" -- Or game name
titleLabel.Font = THEME.FONTS.TITLE
titleLabel.TextSize = 64
titleLabel.TextColor3 = THEME.COLORS.TEXT_GHOST
titleLabel.Size = UDim2.new(1, 0, 0, 100)
titleLabel.Position = UDim2.new(0, 0, 0.4, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextTransparency = 1 -- Start hidden
titleLabel.Parent = bgFrame

local subTitle = Instance.new("TextLabel")
subTitle.Text = "CHAPTER 1: ISOLATION"
subTitle.Font = THEME.FONTS.BODY
subTitle.TextSize = 14
subTitle.TextColor3 = THEME.COLORS.TEXT_BLOOD
subTitle.Size = UDim2.new(1, 0, 0, 20)
subTitle.Position = UDim2.new(0, 0, 1, 10)
subTitle.BackgroundTransparency = 1
subTitle.TextTransparency = 1
subTitle.Parent = titleLabel


-- 3. MENU OPTIONS (Bottom Center, Minimal)
local menuContainer = Instance.new("CanvasGroup") -- Changed to CanvasGroup for GroupTransparency
menuContainer.Size = UDim2.new(0, 400, 0, 100)
menuContainer.Position = UDim2.new(0.5, 0, 0.8, 0)
menuContainer.AnchorPoint = Vector2.new(0.5, 0.5)
menuContainer.BackgroundTransparency = 1
menuContainer.GroupTransparency = 1 -- Start hidden
menuContainer.Parent = bgFrame

local function createMinimalButton(text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.4, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = text
	btn.Font = THEME.FONTS.BODY
	btn.TextSize = 16
	btn.TextColor3 = THEME.COLORS.TEXT_DIM
	btn.AutoButtonColor = false

	-- Line indicator
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.Size = UDim2.new(0, 0, 0, 1) -- Start width 0
	line.Position = UDim2.new(0.5, 0, 1.2, 0)
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.BackgroundColor3 = THEME.COLORS.TEXT_BLOOD
	line.BorderSizePixel = 0
	line.Parent = btn

	return btn, line
end

local cancelBtn, cancelLine = createMinimalButton("ABORT")
cancelBtn.Position = UDim2.new(0.1, 0, 0, 0)
cancelBtn.Parent = menuContainer

local readyBtn, readyLine = createMinimalButton("INITIATE")
readyBtn.Position = UDim2.new(0.5, 0, 0, 0)
readyBtn.TextColor3 = THEME.COLORS.TEXT_GHOST -- Default selected
readyBtn.Parent = menuContainer
readyLine.Size = UDim2.new(0.6, 0, 0, 1) -- Default selected line


-- 4. CORNER DATA (Technical/Creepy)
local dataTL = Instance.new("TextLabel")
dataTL.Position = UDim2.new(0.05, 0, 0.05, 0)
dataTL.Size = UDim2.new(0, 200, 0, 20)
dataTL.BackgroundTransparency = 1
dataTL.Text = "SIGNAL: UNSTABLE"
dataTL.Font = THEME.FONTS.MONO
dataTL.TextSize = 12
dataTL.TextColor3 = THEME.COLORS.TEXT_DIM
dataTL.TextXAlignment = Enum.TextXAlignment.Left
dataTL.Parent = bgFrame

local dataBR = Instance.new("TextLabel")
dataBR.Position = UDim2.new(0.95, 0, 0.95, 0)
dataBR.AnchorPoint = Vector2.new(1, 1)
dataBR.Size = UDim2.new(0, 200, 0, 20)
dataBR.BackgroundTransparency = 1
dataBR.Text = "SURVIVORS: 1/4"
dataBR.Font = THEME.FONTS.MONO
dataBR.TextSize = 12
dataBR.TextColor3 = THEME.COLORS.TEXT_DIM
dataBR.TextXAlignment = Enum.TextXAlignment.Right
dataBR.Parent = bgFrame

local dataBL = Instance.new("TextLabel")
dataBL.Position = UDim2.new(0.05, 0, 0.95, 0)
dataBL.AnchorPoint = Vector2.new(0, 1)
dataBL.Size = UDim2.new(0, 200, 0, 50)
dataBL.BackgroundTransparency = 1
dataBL.Text = "DIFFICULTY: HARD\nMODE: STORY"
dataBL.Font = THEME.FONTS.MONO
dataBL.TextSize = 12
dataBL.TextColor3 = THEME.COLORS.TEXT_DIM
dataBL.TextXAlignment = Enum.TextXAlignment.Left
dataBL.Parent = bgFrame

-- Timer (Integrated into Title?)
local timerLabel = Instance.new("TextLabel")
timerLabel.Text = ""
timerLabel.Font = THEME.FONTS.MONO
timerLabel.TextSize = 12
timerLabel.TextColor3 = THEME.COLORS.TEXT_BLOOD
timerLabel.Size = UDim2.new(1, 0, 0, 20)
timerLabel.Position = UDim2.new(0, 0, 0.55, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Parent = bgFrame


-- INTERACTION PROMPT (Minimal)
local promptLabel = Instance.new("TextLabel")
promptLabel.Name = "Prompt"
promptLabel.Text = "[ E ]"
promptLabel.Font = THEME.FONTS.BODY
promptLabel.TextSize = 18
promptLabel.TextColor3 = THEME.COLORS.TEXT_GHOST
promptLabel.Size = UDim2.new(0, 50, 0, 50)
promptLabel.Position = UDim2.new(0.5, 0, 0.6, 0)
promptLabel.AnchorPoint = Vector2.new(0.5, 0.5)
promptLabel.BackgroundTransparency = 1
promptLabel.Visible = false
promptLabel.Parent = screenGui

-- Mobile Start
local mStartBtn = Instance.new("TextButton")
mStartBtn.Size = UDim2.new(0, 200, 0, 60)
mStartBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
mStartBtn.AnchorPoint = Vector2.new(0.5, 0.5)
mStartBtn.BackgroundColor3 = Color3.new(0,0,0)
mStartBtn.BackgroundTransparency = 0.5
mStartBtn.Text = "BEGIN"
mStartBtn.Font = THEME.FONTS.TITLE
mStartBtn.TextColor3 = THEME.COLORS.TEXT_GHOST
mStartBtn.TextSize = 24
mStartBtn.Visible = false
mStartBtn.Parent = screenGui
Instance.new("UIStroke", mStartBtn).Color = THEME.COLORS.TEXT_DIM


-- LOGIC
local gameStarted = false
local startPart = nil
local selectedIdx = 2 -- 2 = Ready, 1 = Cancel

local function updateSelection()
	-- Clean fade transitions
	local tInfo = TweenInfo.new(0.3)

	if selectedIdx == 2 then -- Ready
		TweenService:Create(readyBtn, tInfo, {TextColor3 = THEME.COLORS.TEXT_GHOST}):Play()
		TweenService:Create(readyLine, tInfo, {Size = UDim2.new(0.6, 0, 0, 1)}):Play()

		TweenService:Create(cancelBtn, tInfo, {TextColor3 = THEME.COLORS.TEXT_DIM}):Play()
		TweenService:Create(cancelLine, tInfo, {Size = UDim2.new(0, 0, 0, 1)}):Play()
	else
		TweenService:Create(readyBtn, tInfo, {TextColor3 = THEME.COLORS.TEXT_DIM}):Play()
		TweenService:Create(readyLine, tInfo, {Size = UDim2.new(0, 0, 0, 1)}):Play()

		TweenService:Create(cancelBtn, tInfo, {TextColor3 = THEME.COLORS.TEXT_BLOOD}):Play() -- Red for cancel
		TweenService:Create(cancelLine, tInfo, {Size = UDim2.new(0.6, 0, 0, 1)}):Play()
	end
end

local function handleInput(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	if input.KeyCode == Enum.KeyCode.Left then
		selectedIdx = 1
		updateSelection()
		return Enum.ContextActionResult.Sink
	elseif input.KeyCode == Enum.KeyCode.Right then
		selectedIdx = 2
		updateSelection()
		return Enum.ContextActionResult.Sink
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		if selectedIdx == 1 then
			CancelStartVoteEvent:FireServer()
		else
			StartGameEvent:FireServer()
		end
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

local function showUI()
	bgFrame.Visible = true

	-- Enable Effects
	if ccEffect then ccEffect.Enabled = true end
	if blurEffect then blurEffect.Enabled = true end
	if bloomEffect then bloomEffect.Enabled = true end

	-- Cinematic Entrance
	bgFrame.BackgroundTransparency = 1 -- Start transparent
	titleLabel.TextTransparency = 1
	subTitle.TextTransparency = 1
	menuContainer.GroupTransparency = 1

	-- Fade BG to Black
	TweenService:Create(bgFrame, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()

	-- Blur In
	TweenService:Create(blurEffect, TweenInfo.new(2), {Size = 20}):Play()

	-- Slow Title Reveal
	task.delay(0.5, function()
		TweenService:Create(titleLabel, TweenInfo.new(2), {TextTransparency = 0}):Play()
	end)

	task.delay(1.5, function()
		TweenService:Create(subTitle, TweenInfo.new(2), {TextTransparency = 0}):Play()
	end)

	-- Reveal Menu after Title
	task.delay(2.5, function()
		TweenService:Create(menuContainer, TweenInfo.new(1.5), {GroupTransparency = 0}):Play()
	end)

	promptLabel.Visible = false
	mStartBtn.Visible = false

	if not UIS.TouchEnabled then
		selectedIdx = 2
		updateSelection()
		ContextActionService:BindActionAtPriority(
			SELECT_ACTION,
			handleInput,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left, Enum.KeyCode.Right, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter
		)
	end
end

local function hideUI()
	-- Fade out everything
	TweenService:Create(bgFrame, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(subTitle, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	TweenService:Create(blurEffect, TweenInfo.new(1), {Size = 0}):Play()

	-- Disable Effects after fade
	task.delay(1, function()
		if ccEffect then ccEffect.Enabled = false end
		if blurEffect then blurEffect.Enabled = false end
		if bloomEffect then bloomEffect.Enabled = false end
		bgFrame.Visible = false
	end)

	ContextActionService:UnbindAction(SELECT_ACTION)
end

-- EVENTS
OpenStartUIEvent.OnClientEvent:Connect(function()
	if not gameStarted then showUI() end
end)

StartVoteCanceledEvent.OnClientEvent:Connect(function()
	hideUI()
end)

ReadyCountEvent.OnClientEvent:Connect(function(ready, total)
	dataBR.Text = string.format("SURVIVORS: %d/%d", ready, total)
	if ready >= total and total > 0 then
		gameStarted = true
		hideUI()
	end
end)

StartVoteCountdownEvent.OnClientEvent:Connect(function(time)
	if time <= 10 then
		timerLabel.Text = "AUTO-SEQUENCE: " .. time
	else
		timerLabel.Text = ""
	end
end)

GameSettingsUpdateEvent.OnClientEvent:Connect(function(settings)
	if settings.gameMode then
		local diff = settings.difficulty and tostring(settings.difficulty) or "UNKNOWN"
		local mode = settings.gameMode and tostring(settings.gameMode) or "UNKNOWN"
		dataBL.Text = "DIFFICULTY: " .. string.upper(diff) .. "\nMODE: " .. string.upper(mode)
	end
end)

-- BUTTONS
readyBtn.MouseButton1Click:Connect(function() StartGameEvent:FireServer() end)
cancelBtn.MouseButton1Click:Connect(function() CancelStartVoteEvent:FireServer() hideUI() end)
mStartBtn.MouseButton1Click:Connect(function() OpenStartUIEvent:FireServer() end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.E and not gameStarted and not bgFrame.Visible and promptLabel.Visible then
		OpenStartUIEvent:FireServer()
	end
end)

RunService.RenderStepped:Connect(function()
	if not gameStarted then
		local char = player.Character
		if not startPart then startPart = workspace:FindFirstChild("StartPart") end

		if char and char:FindFirstChild("HumanoidRootPart") and startPart then
			local dist = (char.HumanoidRootPart.Position - startPart.Position).Magnitude
			if dist < 15 and not bgFrame.Visible then
				if UIS.TouchEnabled then mStartBtn.Visible = true else promptLabel.Visible = true end
			else
				mStartBtn.Visible = false
				promptLabel.Visible = false
			end
		end
	end
end)

if UIS.TouchEnabled then
	-- Mobile adjustments
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	menuContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
end
