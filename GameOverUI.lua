-- GameOverUI.lua (LocalScript)
-- Path: StarterGui/GameOverUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Remote Events and Functions
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
-- Try to find events, if not exist, wait.
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")

-- Create the ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameOverUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = gui

-- Colors based on the prototype
local THEME = {
	Background = Color3.fromRGB(2, 6, 23),
	Panel = Color3.fromRGB(15, 23, 42),
	PanelLight = Color3.fromRGB(30, 41, 59),
	Border = Color3.fromRGB(51, 65, 85),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(148, 163, 184),
	Primary = Color3.fromRGB(14, 165, 233),
	Danger = Color3.fromRGB(239, 68, 68),
	Warning = Color3.fromRGB(245, 158, 11),
	Success = Color3.fromRGB(34, 197, 94),
	Pink = Color3.fromRGB(236, 72, 153),
}

-- Helper Functions
local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Border
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, color1, color2)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	}
	gradient.Parent = parent
	return gradient
end

-- --- UI Construction ---
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = THEME.Background
background.BackgroundTransparency = 0.1
background.Parent = screenGui

local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 0.2
vignette.BackgroundColor3 = Color3.new(0,0,0)
vignette.Parent = background
local vigGradient = Instance.new("UIGradient")
vigGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.4, 1),
	NumberSequenceKeypoint.new(0.6, 1),
	NumberSequenceKeypoint.new(1, 0)
}
vigGradient.Rotation = 90
vigGradient.Parent = vignette

local bloodOverlay = Instance.new("Frame")
bloodOverlay.Name = "BloodOverlay"
bloodOverlay.Size = UDim2.fromScale(1, 1)
bloodOverlay.BackgroundColor3 = THEME.Danger
bloodOverlay.BackgroundTransparency = 1
bloodOverlay.Parent = background

local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 900, 1, 0)
mainContainer.Position = UDim2.fromScale(0.5, 0.5)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundTransparency = 1
mainContainer.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 20)
layout.Parent = mainContainer

-- 1. HEADER
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.LayoutOrder = 1
headerFrame.Size = UDim2.new(1, 0, 0, 150)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = mainContainer

local missionStatus = Instance.new("TextLabel")
missionStatus.Name = "MissionStatus"
missionStatus.Size = UDim2.new(1, 0, 0, 80)
missionStatus.BackgroundTransparency = 1
missionStatus.Text = "MISSION FAILED"
missionStatus.Font = Enum.Font.FredokaOne
missionStatus.TextSize = 80
missionStatus.TextColor3 = THEME.Danger
missionStatus.TextStrokeTransparency = 0.5
missionStatus.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
missionStatus.Parent = headerFrame

local waveReached = Instance.new("Frame")
waveReached.Name = "WaveReached"
waveReached.Size = UDim2.new(0, 400, 0, 40)
waveReached.Position = UDim2.new(0.5, -200, 0, 90)
waveReached.BackgroundColor3 = Color3.new(0,0,0)
waveReached.BackgroundTransparency = 0.5
waveReached.Parent = headerFrame
createCorner(waveReached, 20)
createStroke(waveReached, THEME.Danger, 1)

local waveText = Instance.new("TextLabel")
waveText.Size = UDim2.fromScale(1, 1)
waveText.BackgroundTransparency = 1
waveText.Text = "SURVIVED UNTIL WAVE"
waveText.Font = Enum.Font.GothamBold
waveText.TextSize = 18
waveText.TextColor3 = Color3.fromRGB(252, 165, 165)
waveText.Parent = waveReached

local waveNum = Instance.new("TextLabel")
waveNum.Name = "Value"
waveNum.Size = UDim2.new(0, 50, 1, 0)
waveNum.Position = UDim2.new(1, -60, 0, 0)
waveNum.AnchorPoint = Vector2.new(0,0)
waveNum.BackgroundTransparency = 1
waveNum.Text = "0"
waveNum.Font = Enum.Font.GothamBlack
waveNum.TextSize = 24
waveNum.TextColor3 = THEME.Danger
waveNum.Parent = waveReached

-- 2. STATS GRID
local statsGrid = Instance.new("Frame")
statsGrid.Name = "StatsGrid"
statsGrid.LayoutOrder = 2
statsGrid.Size = UDim2.new(1, 0, 0, 300)
statsGrid.BackgroundTransparency = 1
statsGrid.Parent = mainContainer

local charCard = Instance.new("Frame")
charCard.Name = "CharCard"
charCard.Size = UDim2.new(0, 300, 1, 0)
charCard.BackgroundColor3 = THEME.PanelLight
charCard.BackgroundTransparency = 0.2
charCard.Parent = statsGrid
createCorner(charCard, 16)
createStroke(charCard, Color3.fromRGB(255,255,255), 1).Transparency = 0.9

local charContent = Instance.new("Frame")
charContent.Size = UDim2.new(1, -40, 1, -40)
charContent.Position = UDim2.new(0, 20, 0, 20)
charContent.BackgroundTransparency = 1
charContent.Parent = charCard

local avatarCircle = Instance.new("ImageLabel")
avatarCircle.Name = "Avatar"
avatarCircle.Size = UDim2.new(0, 100, 0, 100)
avatarCircle.Position = UDim2.new(0.5, -50, 0, 0)
avatarCircle.BackgroundColor3 = THEME.Panel
avatarCircle.Parent = charContent
createCorner(avatarCircle, 50)
createStroke(avatarCircle, THEME.Primary, 3)

local playerName = Instance.new("TextLabel")
playerName.Name = "PlayerName"
playerName.Size = UDim2.new(1, 0, 0, 30)
playerName.Position = UDim2.new(0, 0, 0, 110)
playerName.BackgroundTransparency = 1
playerName.Text = player.Name
playerName.Font = Enum.Font.GothamBold
playerName.TextSize = 22
playerName.TextColor3 = THEME.TextMain
playerName.Parent = charContent

local playerTitle = Instance.new("TextLabel")
playerTitle.Size = UDim2.new(1, 0, 0, 20)
playerTitle.Position = UDim2.new(0, 0, 0, 140)
playerTitle.BackgroundTransparency = 1
playerTitle.Text = "The Survivor"
playerTitle.Font = Enum.Font.Gotham
playerTitle.TextSize = 14
playerTitle.TextColor3 = THEME.TextDim
playerTitle.Parent = charContent

local xpSection = Instance.new("Frame")
xpSection.Size = UDim2.new(1, 0, 0, 60)
xpSection.Position = UDim2.new(0, 0, 1, -60)
xpSection.BackgroundTransparency = 1
xpSection.Parent = charContent

local lvlLabel = Instance.new("TextLabel")
lvlLabel.Size = UDim2.new(0.5, 0, 0, 20)
lvlLabel.BackgroundTransparency = 1
lvlLabel.Text = "LVL 1"
lvlLabel.TextColor3 = THEME.Primary
lvlLabel.Font = Enum.Font.GothamBold
lvlLabel.TextXAlignment = Enum.TextXAlignment.Left
lvlLabel.TextSize = 14
lvlLabel.Parent = xpSection

local xpGainLabel = Instance.new("TextLabel")
xpGainLabel.Name = "XPGain"
xpGainLabel.Size = UDim2.new(0.5, 0, 0, 20)
xpGainLabel.Position = UDim2.new(0.5, 0, 0, 0)
xpGainLabel.BackgroundTransparency = 1
xpGainLabel.Text = "+0 XP"
xpGainLabel.TextColor3 = THEME.TextDim
xpGainLabel.Font = Enum.Font.GothamBold
xpGainLabel.TextXAlignment = Enum.TextXAlignment.Right
xpGainLabel.TextSize = 14
xpGainLabel.Parent = xpSection

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, 0, 0, 6)
barBg.Position = UDim2.new(0, 0, 0, 25)
barBg.BackgroundColor3 = THEME.Panel
barBg.Parent = xpSection
createCorner(barBg, 3)

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = THEME.Primary
barFill.Parent = barBg
createCorner(barFill, 3)
createGradient(barFill, THEME.Primary, Color3.fromRGB(99, 102, 241))

local xpProgressText = Instance.new("TextLabel")
xpProgressText.Name = "Values"
xpProgressText.Size = UDim2.new(1, 0, 0, 20)
xpProgressText.Position = UDim2.new(0, 0, 0, 35)
xpProgressText.BackgroundTransparency = 1
xpProgressText.Text = "0 / 100 XP"
xpProgressText.TextColor3 = THEME.TextDim
xpProgressText.Font = Enum.Font.Gotham
xpProgressText.TextSize = 12
xpProgressText.TextXAlignment = Enum.TextXAlignment.Right
xpProgressText.Parent = xpSection

local detailsCard = Instance.new("Frame")
detailsCard.Name = "DetailsCard"
detailsCard.Size = UDim2.new(1, -320, 1, 0)
detailsCard.Position = UDim2.new(0, 320, 0, 0)
detailsCard.BackgroundColor3 = THEME.Panel
detailsCard.BackgroundTransparency = 0.1
detailsCard.Parent = statsGrid
createCorner(detailsCard, 16)
local topBorder = Instance.new("Frame")
topBorder.Size = UDim2.new(1, 0, 0, 2)
topBorder.BackgroundColor3 = THEME.Danger
topBorder.Parent = detailsCard
topBorder.BorderSizePixel = 0
local dcPad = Instance.new("UIPadding")
dcPad.PaddingTop = UDim.new(0, 25)
dcPad.PaddingBottom = UDim.new(0, 25)
dcPad.PaddingLeft = UDim.new(0, 25)
dcPad.PaddingRight = UDim.new(0, 25)
dcPad.Parent = detailsCard

local detailsList = Instance.new("UIListLayout")
detailsList.SortOrder = Enum.SortOrder.LayoutOrder
detailsList.Padding = UDim.new(0, 15)
detailsList.Parent = detailsCard

local function createStatRow(icon, labelText, color, layoutOrder)
	local row = Instance.new("Frame")
	row.Name = labelText
	row.LayoutOrder = layoutOrder
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.97
	row.Parent = detailsCard
	createCorner(row, 8)

	local leftBorder = Instance.new("Frame")
	leftBorder.Size = UDim2.new(0, 3, 1, 0)
	leftBorder.BackgroundColor3 = THEME.Border
	leftBorder.BorderSizePixel = 0
	leftBorder.Parent = row
	createCorner(leftBorder, 2)

	local ico = Instance.new("TextLabel")
	ico.Size = UDim2.new(0, 30, 0.5, 0)
	ico.Position = UDim2.new(0, 10, 0, 5)
	ico.BackgroundTransparency = 1
	ico.Text = icon
	ico.TextColor3 = color
	ico.TextSize = 18
	ico.Parent = row

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 100, 0.5, 0)
	lbl.Position = UDim2.new(0, 40, 0, 5)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = THEME.TextDim
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.Parent = row

	local val = Instance.new("TextLabel")
	val.Name = "Value"
	val.Size = UDim2.new(1, -20, 0.5, 0)
	val.Position = UDim2.new(0, 10, 0.5, 0)
	val.BackgroundTransparency = 1
	val.Text = "0"
	val.TextColor3 = THEME.TextMain
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.Font = Enum.Font.GothamBlack
	val.TextSize = 22
	val.Parent = row

	return val, leftBorder
end

local killsVal, killsBorder = createStatRow("☠", "KILLS", THEME.Danger, 1)
killsBorder.BackgroundColor3 = THEME.Danger

local headshotsVal, hsBorder = createStatRow("⌖", "HEADSHOTS", THEME.Warning, 2)
hsBorder.BackgroundColor3 = THEME.Warning

local dmgVal, dmgBorder = createStatRow("⚡", "DAMAGE", THEME.Pink, 3)
dmgBorder.BackgroundColor3 = THEME.Pink

local timeVal, timeBorder = createStatRow("⏱", "TIME ALIVE", THEME.Success, 4)
timeBorder.BackgroundColor3 = THEME.Success

local row1Frame = Instance.new("Frame")
row1Frame.Name = "Row1"
row1Frame.LayoutOrder = 1
row1Frame.Size = UDim2.new(1, 0, 0, 60)
row1Frame.BackgroundTransparency = 1
row1Frame.Parent = detailsCard

killsVal.Parent.Parent = row1Frame
killsVal.Parent.Size = UDim2.new(0.48, 0, 1, 0)

headshotsVal.Parent.Parent = row1Frame
headshotsVal.Parent.Size = UDim2.new(0.48, 0, 1, 0)
headshotsVal.Parent.Position = UDim2.new(0.52, 0, 0, 0)

local row2Frame = Instance.new("Frame")
row2Frame.Name = "Row2"
row2Frame.LayoutOrder = 2
row2Frame.Size = UDim2.new(1, 0, 0, 60)
row2Frame.BackgroundTransparency = 1
row2Frame.Parent = detailsCard

dmgVal.Parent.Parent = row2Frame
dmgVal.Parent.Size = UDim2.new(0.48, 0, 1, 0)

timeVal.Parent.Parent = row2Frame
timeVal.Parent.Size = UDim2.new(0.48, 0, 1, 0)
timeVal.Parent.Position = UDim2.new(0.52, 0, 0, 0)

local mvpFrame = Instance.new("Frame")
mvpFrame.LayoutOrder = 3
mvpFrame.Size = UDim2.new(1, 0, 0, 60)
mvpFrame.BackgroundColor3 = THEME.PanelLight
mvpFrame.BackgroundTransparency = 0.5
mvpFrame.Parent = detailsCard
createCorner(mvpFrame, 8)

local mvpIconBox = Instance.new("Frame")
mvpIconBox.Size = UDim2.new(0, 40, 0, 40)
mvpIconBox.Position = UDim2.new(0, 10, 0.5, -20)
mvpIconBox.BackgroundColor3 = THEME.Border
mvpIconBox.Parent = mvpFrame
createCorner(mvpIconBox, 4)

local mvpIcon = Instance.new("TextLabel")
mvpIcon.Size = UDim2.fromScale(1, 1)
mvpIcon.BackgroundTransparency = 1
mvpIcon.Text = "★"
mvpIcon.TextColor3 = THEME.Warning
mvpIcon.TextSize = 24
mvpIcon.Parent = mvpIconBox

local mvpTitle = Instance.new("TextLabel")
mvpTitle.Position = UDim2.new(0, 60, 0, 10)
mvpTitle.Size = UDim2.new(0, 200, 0, 15)
mvpTitle.BackgroundTransparency = 1
mvpTitle.Text = "MVP ACHIEVEMENT"
mvpTitle.Font = Enum.Font.GothamBold
mvpTitle.TextSize = 10
mvpTitle.TextColor3 = THEME.TextDim
mvpTitle.TextXAlignment = Enum.TextXAlignment.Left
mvpTitle.Parent = mvpFrame

local mvpDesc = Instance.new("TextLabel")
mvpDesc.Position = UDim2.new(0, 60, 0, 25)
mvpDesc.Size = UDim2.new(0, 200, 0, 20)
mvpDesc.BackgroundTransparency = 1
mvpDesc.Text = "Coming Soon" -- Placeholder
mvpDesc.Font = Enum.Font.GothamBold
mvpDesc.TextSize = 14
mvpDesc.TextColor3 = THEME.TextMain
mvpDesc.TextXAlignment = Enum.TextXAlignment.Left
mvpDesc.Parent = mvpFrame

local rewardStrip = Instance.new("Frame")
rewardStrip.Name = "RewardStrip"
rewardStrip.LayoutOrder = 3
rewardStrip.Size = UDim2.new(1, 0, 0, 80)
rewardStrip.BackgroundColor3 = THEME.Panel
rewardStrip.BackgroundTransparency = 0.1
rewardStrip.Parent = mainContainer
createCorner(rewardStrip, 12)
createStroke(rewardStrip, Color3.new(1,1,1), 1).Transparency = 0.9

local rewardPad = Instance.new("UIPadding")
rewardPad.PaddingLeft = UDim.new(0, 30)
rewardPad.PaddingRight = UDim.new(0, 30)
rewardPad.Parent = rewardStrip

local rewardLayout = Instance.new("UIListLayout")
rewardLayout.FillDirection = Enum.FillDirection.Horizontal
rewardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rewardLayout.SortOrder = Enum.SortOrder.LayoutOrder
rewardLayout.Padding = UDim.new(0, 40)
rewardLayout.Parent = rewardStrip

local rewardsLabel = Instance.new("TextLabel")
rewardsLabel.Text = "REWARDS EARNED"
rewardsLabel.TextColor3 = THEME.TextDim
rewardsLabel.Font = Enum.Font.GothamBold
rewardsLabel.TextSize = 14
rewardsLabel.Size = UDim2.new(0, 150, 1, 0)
rewardsLabel.BackgroundTransparency = 1
rewardsLabel.TextXAlignment = Enum.TextXAlignment.Left
rewardsLabel.Parent = rewardStrip

local function createRewardItem(icon, val, name, color, layoutOrder)
	local container = Instance.new("Frame")
	container.LayoutOrder = layoutOrder or 0
	container.Size = UDim2.new(0, 150, 0, 50)
	container.BackgroundTransparency = 1
	container.Parent = rewardStrip

	local ico = Instance.new("TextLabel")
	ico.Text = icon
	ico.TextColor3 = color
	ico.TextSize = 24
	ico.Size = UDim2.new(0, 30, 1, 0)
	ico.BackgroundTransparency = 1
	ico.Parent = container

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = "Value"
	valLabel.Text = tostring(val)
	valLabel.TextColor3 = THEME.TextMain
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextSize = 24
	valLabel.Size = UDim2.new(0, 100, 0, 30)
	valLabel.Position = UDim2.new(0, 35, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.TextXAlignment = Enum.TextXAlignment.Left
	valLabel.Parent = container

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = name
	nameLabel.TextColor3 = THEME.TextDim
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 10
	nameLabel.Size = UDim2.new(0, 100, 0, 15)
	nameLabel.Position = UDim2.new(0, 35, 0, 25)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	return valLabel
end

local coinsRewardVal = createRewardItem("●", "0", "BLOOD COINS", THEME.Warning, 1)
local pointsRewardVal = createRewardItem("♦", "0", "MISSION PTS", THEME.Primary, 2)

local actionFrame = Instance.new("Frame")
actionFrame.Name = "Actions"
actionFrame.LayoutOrder = 4
actionFrame.Size = UDim2.new(1, 0, 0, 60)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = mainContainer

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.Padding = UDim.new(0, 20)
actionLayout.Parent = actionFrame

local function createButton(text, primary, layoutOrder)
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = layoutOrder or 0
	btn.Size = UDim2.new(0, 200, 1, 0)
	btn.BackgroundColor3 = primary and THEME.Primary or Color3.new(0,0,0)
	btn.BackgroundTransparency = primary and 0 or 1
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.TextColor3 = primary and Color3.new(0,0,0) or THEME.TextDim
	btn.Parent = actionFrame
	createCorner(btn, 8)
	if not primary then
		createStroke(btn, THEME.Border, 2)
	end
	return btn
end

local lobbyBtn = createButton("RETURN TO LOBBY", false, 1)
local replayBtn = createButton("PLAY AGAIN", true, 2)

local function animateNumber(label, targetVal, duration)
	-- Use parens around gsub to only get the first result (the string), 
	-- otherwise the substitution count is passed as the second arg (base) to tonumber.
	local startVal = tonumber((label.Text:gsub(",", ""))) or 0
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			local current = math.floor(startVal + (targetVal - startVal) * alpha)
			local formatted = tostring(current):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
			label.Text = formatted
			RunService.RenderStepped:Wait()
		end
		local formatted = tostring(targetVal):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
		label.Text = formatted
	end)
end

local function populateData(data)
	avatarCircle.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	playerName.Text = player.Name

	local level = data.Level or 1
	local xp = data.XP or 0
	local xpMax = data.XPMax or 1000
	lvlLabel.Text = "LVL " .. level
	xpProgressText.Text = xp .. " / " .. xpMax .. " XP"
	xpGainLabel.Text = "+" .. (data.XPGained or 0) .. " XP"

	waveText.Text = "SURVIVED UNTIL WAVE"
	waveNum.Text = tostring(data.Wave or 1)

	animateNumber(killsVal, data.Kills or 0, 2)
	animateNumber(headshotsVal, data.Headshots or 0, 2)
	animateNumber(dmgVal, data.Damage or 0, 2)

	local timeAlive = data.TimeAlive or 0
	local m = math.floor(timeAlive / 60)
	local s = timeAlive % 60
	timeVal.Text = string.format("%02d:%02d", m, s)

	animateNumber(coinsRewardVal, data.CoinsEarned or 0, 2)
	animateNumber(pointsRewardVal, data.PointsEarned or 0, 2)

	local pct = math.clamp(xp / xpMax, 0, 1)
	TweenService:Create(barFill, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end

local function showGameOver(data)
	screenGui.Enabled = true
	mainContainer.Visible = true
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 50)
	mainContainer.BackgroundTransparency = 1
	bloodOverlay.BackgroundTransparency = 1

	populateData(data or {})

	local tInfo = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(mainContainer, tInfo, {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1}):Play()
	TweenService:Create(bloodOverlay, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.8}):Play()
end

GameOverEvent.OnClientEvent:Connect(function(data)
	local mockData = {
		Wave = 0,
		Kills = 0,
		Headshots = 0,
		Damage = 0,
		TimeAlive = 0,
		CoinsEarned = 0,
		PointsEarned = 0,
		Level = 1,
		XP = 0,
		XPMax = 100,
		XPGained = 0
	}
	showGameOver(data or mockData)
end)

-- Function to handle return to lobby
local function returnToLobby()
	TweenService:Create(mainContainer, TweenInfo.new(0.5), {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -50)}):Play()
	task.wait(0.5)
	ExitGameEvent:FireServer()
end

lobbyBtn.MouseButton1Click:Connect(returnToLobby)
replayBtn.MouseButton1Click:Connect(returnToLobby)
