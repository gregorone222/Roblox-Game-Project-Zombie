-- StartUI.lua (LocalScript)
-- Path: StarterGui/StartUI.lua
-- Script Place: ACT 1: Village

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

-- Constants & Colors (Cyberpunk/Sci-Fi Palette)
local COLORS = {
	BG_DARK = Color3.fromRGB(15, 23, 42), -- Slate 900
	BG_LIGHT = Color3.fromRGB(30, 41, 59), -- Slate 800
	BG_LIGHTER = Color3.fromRGB(51, 65, 85), -- Slate 700 (For borders/keycaps)
	ACCENT_INDIGO = Color3.fromRGB(99, 102, 241),
	ACCENT_PURPLE = Color3.fromRGB(147, 51, 234),
	TEXT_WHITE = Color3.fromRGB(248, 250, 252),
	TEXT_GRAY = Color3.fromRGB(148, 163, 184),
	BTN_GREEN = Color3.fromRGB(0, 170, 0), -- Dark Green
	BTN_RED = Color3.fromRGB(170, 0, 0), -- Dark Red
	BTN_GREEN_BORDER = Color3.fromRGB(34, 197, 94),
	BTN_RED_BORDER = Color3.fromRGB(220, 38, 38),
	STROKE = Color3.fromRGB(51, 65, 85),
	PULSE_GREEN = Color3.fromRGB(34, 197, 94)
}

local ASSETS = {
	GLOW_IMAGE = "rbxassetid://4996891970",
	SCANLINE_TEXTURE = "rbxassetid://13065783540" -- Generic scanline texture if available, otherwise we simulate or skip
	-- Note: Using a known glow ID. Scanline might need a placeholder if ID fails, but we can try a tiled line.
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

-- --- UI CREATION ---

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = true
screenGui.Parent = playerGui

-- Background blur
local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Parent = game:GetService("Lighting")

local tweenBlurIn = TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 16})
local tweenBlurOut = TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 0})

-- Scanlines Overlay (Fullscreen)
local scanlines = Instance.new("ImageLabel")
scanlines.Name = "Scanlines"
scanlines.Size = UDim2.new(1, 0, 1, 0)
scanlines.BackgroundTransparency = 1
scanlines.Image = "rbxassetid://2743169888" -- A common scanline/grid texture
scanlines.ImageColor3 = Color3.new(0, 0, 0)
scanlines.ImageTransparency = 0.8
scanlines.ScaleType = Enum.ScaleType.Tile
scanlines.TileSize = UDim2.new(0, 4, 0, 4)
scanlines.Visible = false
scanlines.Parent = screenGui

-- Main Container Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 520, 0, 420)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = COLORS.BG_DARK
mainFrame.BackgroundTransparency = 0.05 -- High opacity like prototype
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Glow Behind Main Frame
local mainGlow = Instance.new("ImageLabel")
mainGlow.Name = "MainGlow"
mainGlow.Image = ASSETS.GLOW_IMAGE
mainGlow.ImageColor3 = COLORS.ACCENT_INDIGO
mainGlow.ImageTransparency = 0.6
mainGlow.ScaleType = Enum.ScaleType.Slice
mainGlow.SliceCenter = Rect.new(49, 49, 450, 450)
mainGlow.Size = UDim2.new(1, 100, 1, 100)
mainGlow.Position = UDim2.new(0, -50, 0, -50)
mainGlow.BackgroundTransparency = 1
mainGlow.ZIndex = -1
mainGlow.Parent = mainFrame

-- Main Corner & Stroke
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.BG_LIGHTER
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

-- HEADER
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = COLORS.BG_LIGHT
header.BackgroundTransparency = 0.5
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

-- Hide bottom corners of header to look flat joined
local headerCover = Instance.new("Frame")
headerCover.Size = UDim2.new(1, 0, 0.5, 0)
headerCover.Position = UDim2.new(0, 0, 0.5, 0)
headerCover.BackgroundColor3 = COLORS.BG_LIGHT
headerCover.BackgroundTransparency = 1 -- Actually, transparency mismatch might show seams. 
-- Better approach: Border on mainFrame handles outline. Header just sits inside.
-- Let's rely on the MainFrame clipping mostly, or just let it be rounded top.
-- Prototype has a line separator.
local headerLine = Instance.new("Frame")
headerLine.Name = "HeaderLine"
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, 0)
headerLine.BackgroundColor3 = COLORS.STROKE
headerLine.BorderSizePixel = 0
headerLine.Parent = header

-- Header Centering Container
local headerCenter = Instance.new("Frame")
headerCenter.Name = "HeaderCenter"
headerCenter.Size = UDim2.new(0, 0, 1, 0)
headerCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
headerCenter.AnchorPoint = Vector2.new(0.5, 0.5)
headerCenter.BackgroundTransparency = 1
headerCenter.AutomaticSize = Enum.AutomaticSize.X
headerCenter.Parent = header

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Padding = UDim.new(0, 10)
headerLayout.Parent = headerCenter

-- Pulse Dot
local pulseDot = Instance.new("Frame")
pulseDot.Name = "PulseDot"
pulseDot.Size = UDim2.new(0, 12, 0, 12)
pulseDot.BackgroundColor3 = COLORS.PULSE_GREEN
pulseDot.Parent = headerCenter

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = pulseDot

-- Pulse Animation Ring
local pulseRing = Instance.new("Frame")
pulseRing.Name = "PulseRing"
pulseRing.Size = UDim2.new(1, 0, 1, 0)
pulseRing.Position = UDim2.new(0.5, 0, 0.5, 0)
pulseRing.AnchorPoint = Vector2.new(0.5, 0.5)
pulseRing.BackgroundColor3 = COLORS.PULSE_GREEN
pulseRing.BackgroundTransparency = 0.4
pulseRing.Parent = pulseDot

local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = pulseRing

-- Pulse Script
task.spawn(function()
	while pulseRing.Parent do
		pulseRing.Size = UDim2.new(1, 0, 1, 0)
		pulseRing.BackgroundTransparency = 0.4
		local tween = TweenService:Create(pulseRing, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(3, 0, 3, 0),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Wait()
		task.wait(0.2)
	end
end)

-- Header Title
local headerTitle = Instance.new("TextLabel")
headerTitle.Name = "Title"
headerTitle.Text = "MISI DIMULAI"
headerTitle.Font = Enum.Font.GothamBlack -- Nearest sturdy font
headerTitle.TextSize = 22
headerTitle.TextColor3 = COLORS.TEXT_WHITE
headerTitle.AutomaticSize = Enum.AutomaticSize.XY
headerTitle.Size = UDim2.new(0, 0, 1, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = headerCenter

-- Header Badge
-- Header Badge (Removed as per request)
-- local badgeContainer = Instance.new("Frame")

-- CONTENT AREA
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -40, 1, -80) -- Padding sides 20
contentFrame.Position = UDim2.new(0, 20, 0, 80)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- 3-COLUMN STATS GRID
local gridFrame = Instance.new("Frame")
gridFrame.Name = "GridStats"
gridFrame.Size = UDim2.new(1, 0, 0, 85)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = contentFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.31, 0, 1, 0) 
gridLayout.CellPadding = UDim2.new(0.035, 0, 0, 0)
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = gridFrame

local function createStatCard(label, val, valColor)
	local card = Instance.new("Frame")
	card.BackgroundColor3 = COLORS.BG_LIGHT
	card.BackgroundTransparency = 0.6

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 8)
	cCorner.Parent = card

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = COLORS.STROKE
	cStroke.Thickness = 1
	cStroke.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Text = label:upper()
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 11
	lbl.TextColor3 = COLORS.TEXT_GRAY
	lbl.Size = UDim2.new(1, 0, 0.4, 0)
	lbl.BackgroundTransparency = 1
	lbl.Parent = card

	local vLbl = Instance.new("TextLabel")
	vLbl.Name = "Value"
	vLbl.Text = val
	vLbl.Font = Enum.Font.GothamBold
	vLbl.TextSize = 20
	vLbl.TextColor3 = valColor
	vLbl.Size = UDim2.new(1, 0, 0.6, 0)
	vLbl.Position = UDim2.new(0, 0, 0.3, 0)
	vLbl.BackgroundTransparency = 1
	vLbl.Parent = card

	return card, vLbl
end

local modeCard, modeVal = createStatCard("Mode", "STORY", COLORS.ACCENT_INDIGO)
modeCard.Parent = gridFrame
local diffCard, diffVal = createStatCard("Kesulitan", "HARD", Color3.fromRGB(250, 204, 21))
diffCard.Parent = gridFrame
local playCard, playVal = createStatCard("Pemain", "1/4", COLORS.TEXT_WHITE)
playCard.Parent = gridFrame

-- TIMER
local timerGroup = Instance.new("Frame")
timerGroup.Name = "TimerGroup"
timerGroup.Size = UDim2.new(1, 0, 0, 50)
timerGroup.Position = UDim2.new(0, 0, 0, 105)
timerGroup.BackgroundTransparency = 1
timerGroup.Parent = contentFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Text = "Menunggu Keputusan..."
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 14
timerLabel.TextColor3 = COLORS.TEXT_GRAY
timerLabel.Size = UDim2.new(0.7, 0, 0, 20)
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.BackgroundTransparency = 1
timerLabel.Parent = timerGroup

local timerClock = Instance.new("TextLabel")
timerClock.Text = "00:30"
timerClock.Font = Enum.Font.Code
timerClock.TextSize = 16
timerClock.TextColor3 = Color3.fromRGB(248, 113, 113) -- Red-400
timerClock.Size = UDim2.new(0.3, 0, 0, 20)
timerClock.Position = UDim2.new(0.7, 0, 0, 0)
timerClock.TextXAlignment = Enum.TextXAlignment.Right
timerClock.BackgroundTransparency = 1
timerClock.Parent = timerGroup

local barBg = Instance.new("Frame")
barBg.Size = UDim2.new(1, 0, 0, 8)
barBg.Position = UDim2.new(0, 0, 0, 28)
barBg.BackgroundColor3 = COLORS.BG_LIGHT
barBg.BorderSizePixel = 0
barBg.Parent = timerGroup

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barFill = Instance.new("Frame")
barFill.Name = "Fill"
barFill.Size = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = COLORS.ACCENT_INDIGO
barFill.BorderSizePixel = 0
barFill.Parent = barBg

local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = barFill

local barGrad = Instance.new("UIGradient")
barGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, COLORS.ACCENT_INDIGO),
	ColorSequenceKeypoint.new(1, COLORS.ACCENT_PURPLE)
}
barGrad.Parent = barFill

-- BUTTONS
local btnGroup = Instance.new("Frame")
btnGroup.Name = "ButtonGroup"
btnGroup.Size = UDim2.new(1, 0, 0, 80)
btnGroup.Position = UDim2.new(0, 0, 0, 170)
btnGroup.BackgroundTransparency = 1
btnGroup.Parent = contentFrame

-- Cancel Button
local cancelBtn = Instance.new("TextButton")
cancelBtn.Name = "CancelBtn"
cancelBtn.Size = UDim2.new(0.48, 0, 1, 0)
cancelBtn.BackgroundColor3 = COLORS.BTN_RED
cancelBtn.BackgroundTransparency = 0.3
cancelBtn.Text = "" -- Clear text
cancelBtn.Parent = btnGroup

local cBtnCorner = Instance.new("UICorner")
cBtnCorner.CornerRadius = UDim.new(0, 10)
cBtnCorner.Parent = cancelBtn

local cBtnStroke = Instance.new("UIStroke")
cBtnStroke.Color = COLORS.BTN_RED_BORDER
cBtnStroke.Thickness = 1
cBtnStroke.Parent = cancelBtn

-- Center Container for Cancel
local cCenter = Instance.new("Frame")
cCenter.Name = "CenterContainer"
cCenter.Size = UDim2.new(0, 0, 1, 0)
cCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
cCenter.AnchorPoint = Vector2.new(0.5, 0.5)
cCenter.BackgroundTransparency = 1
cCenter.AutomaticSize = Enum.AutomaticSize.X
cCenter.Parent = cancelBtn

local cLayout = Instance.new("UIListLayout")
cLayout.FillDirection = Enum.FillDirection.Horizontal
cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cLayout.VerticalAlignment = Enum.VerticalAlignment.Center
cLayout.Padding = UDim.new(0, 8)
cLayout.Parent = cCenter

local cText = Instance.new("TextLabel")
cText.Text = "BATAL"
cText.Font = Enum.Font.GothamBlack
cText.TextSize = 20
cText.TextColor3 = Color3.fromRGB(254, 202, 202)
cText.BackgroundTransparency = 1
cText.AutomaticSize = Enum.AutomaticSize.XY
cText.Size = UDim2.new(0, 0, 1, 0)
cText.Parent = cCenter

-- Removed "X" icon as requested

-- Ready Button
local readyBtn = Instance.new("TextButton")
readyBtn.Name = "ReadyBtn"
readyBtn.Size = UDim2.new(0.48, 0, 1, 0)
readyBtn.Position = UDim2.new(0.52, 0, 0, 0)
readyBtn.BackgroundColor3 = COLORS.BTN_GREEN
readyBtn.BackgroundTransparency = 0.3
readyBtn.Text = "" -- Clear text
readyBtn.Parent = btnGroup

local rBtnCorner = Instance.new("UICorner")
rBtnCorner.CornerRadius = UDim.new(0, 10)
rBtnCorner.Parent = readyBtn

local rBtnStroke = Instance.new("UIStroke")
rBtnStroke.Color = COLORS.BTN_GREEN_BORDER
rBtnStroke.Thickness = 1
rBtnStroke.Parent = readyBtn

-- Ready Button GLOW (Green Shadow)
local readyGlow = Instance.new("ImageLabel")
readyGlow.Name = "Glow"
readyGlow.Image = ASSETS.GLOW_IMAGE
readyGlow.ImageColor3 = COLORS.BTN_GREEN_BORDER
readyGlow.ImageTransparency = 0.7
readyGlow.ScaleType = Enum.ScaleType.Slice
readyGlow.SliceCenter = Rect.new(49, 49, 450, 450)
readyGlow.Size = UDim2.new(1, 50, 1, 50)
readyGlow.Position = UDim2.new(0, -25, 0, -25)
readyGlow.BackgroundTransparency = 1
readyGlow.ZIndex = 0
readyGlow.Parent = readyBtn

-- Center Container for Ready
local rCenter = Instance.new("Frame")
rCenter.Name = "CenterContainer"
rCenter.Size = UDim2.new(0, 0, 1, 0)
rCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
rCenter.AnchorPoint = Vector2.new(0.5, 0.5)
rCenter.BackgroundTransparency = 1
rCenter.AutomaticSize = Enum.AutomaticSize.X
rCenter.Parent = readyBtn

local rLayout = Instance.new("UIListLayout")
rLayout.FillDirection = Enum.FillDirection.Horizontal
rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rLayout.VerticalAlignment = Enum.VerticalAlignment.Center
rLayout.Padding = UDim.new(0, 8)
rLayout.Parent = rCenter

local rText = Instance.new("TextLabel")
rText.Text = "SIAP"
rText.Font = Enum.Font.GothamBlack
rText.TextSize = 20
rText.TextColor3 = Color3.fromRGB(220, 252, 231)
rText.BackgroundTransparency = 1
rText.AutomaticSize = Enum.AutomaticSize.XY
rText.Size = UDim2.new(0, 0, 1, 0)
rText.Parent = rCenter

-- Removed "Check" icon as requested

-- FOOTER (Keycaps)
local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, 40)
footer.Position = UDim2.new(0, 0, 1, -40)
footer.BackgroundColor3 = Color3.fromRGB(2, 6, 23) -- Slate 950
footer.BorderSizePixel = 0
footer.Parent = mainFrame

local footerTopLine = Instance.new("Frame")
footerTopLine.Size = UDim2.new(1, 0, 0, 1)
footerTopLine.BackgroundColor3 = COLORS.STROKE
footerTopLine.BorderSizePixel = 0
footerTopLine.Parent = footer

local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 16)
footerCorner.Parent = footer
-- Clip bottom only? Hard with UICorner. We just round whole frame. 
-- But Footer sits at bottom. We need to cover top corners of footer or use ClipsDescendants on main frame.
mainFrame.ClipsDescendants = true -- Ensures footer respects main rounding

-- Keycaps Layout
local footerContent = Instance.new("Frame")
footerContent.Size = UDim2.new(1, 0, 1, 0)
footerContent.BackgroundTransparency = 1
footerContent.Parent = footer

local footerList = Instance.new("UIListLayout")
footerList.FillDirection = Enum.FillDirection.Horizontal
footerList.HorizontalAlignment = Enum.HorizontalAlignment.Center
footerList.VerticalAlignment = Enum.VerticalAlignment.Center
footerList.Padding = UDim.new(0, 10)
footerList.Parent = footerContent

local function createKeycap(text)
	local cap = Instance.new("TextLabel")
	cap.Text = text
	cap.Font = Enum.Font.GothamBold
	cap.TextSize = 12
	cap.TextColor3 = COLORS.TEXT_WHITE
	cap.BackgroundColor3 = COLORS.BG_LIGHTER
	cap.Size = UDim2.new(0, 24, 0, 24)
	if #text > 1 then cap.Size = UDim2.new(0, 50, 0, 24) end

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 4)
	cc.Parent = cap
	return cap
end

local function createHintText(text)
	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextColor3 = COLORS.TEXT_GRAY
	lbl.BackgroundTransparency = 1
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.new(0, 0, 1, 0)
	return lbl
end

-- Desktop Footer
local desktopFooter = Instance.new("Frame")
desktopFooter.Size = UDim2.new(1, 0, 1, 0)
desktopFooter.BackgroundTransparency = 1
desktopFooter.Visible = not UIS.TouchEnabled
desktopFooter.Parent = footerContent
local dfList = footerList:Clone()
dfList.Parent = desktopFooter

createHintText("Gunakan ").Parent = desktopFooter
createKeycap("?").Parent = desktopFooter
createKeycap("?").Parent = desktopFooter
createHintText(" untuk memilih dan ").Parent = desktopFooter
createKeycap("ENTER").Parent = desktopFooter
createHintText(" untuk konfirmasi").Parent = desktopFooter

-- Mobile Footer (Simple Hint)
local mobileFooter = Instance.new("TextLabel")
mobileFooter.Text = "Ketuk opsi untuk memilih"
mobileFooter.Font = Enum.Font.Gotham
mobileFooter.TextSize = 12
mobileFooter.TextColor3 = COLORS.TEXT_GRAY
mobileFooter.BackgroundTransparency = 1
mobileFooter.Size = UDim2.new(1, 0, 1, 0)
mobileFooter.Visible = UIS.TouchEnabled
mobileFooter.Parent = footerContent

-- --- EXTERNAL PROMPTS ---

-- Desktop E Prompt (Styled)
local promptFrame = Instance.new("Frame")
promptFrame.Name = "PromptE"
promptFrame.Size = UDim2.new(0, 64, 0, 64)
promptFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
promptFrame.BackgroundTransparency = 1
promptFrame.Visible = false
promptFrame.Parent = screenGui

local promptGlow = Instance.new("ImageLabel")
promptGlow.Image = ASSETS.GLOW_IMAGE
promptGlow.ImageColor3 = Color3.fromRGB(250, 204, 21) -- Yellow Glow
promptGlow.ImageTransparency = 0.8
promptGlow.Size = UDim2.new(2, 0, 2, 0)
promptGlow.Position = UDim2.new(-0.5, 0, -0.5, 0)
promptGlow.BackgroundTransparency = 1
promptGlow.Parent = promptFrame

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 48, 0, 48)
keyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
keyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
keyFrame.BackgroundColor3 = Color3.new(0,0,0)
keyFrame.BorderSizePixel = 0
keyFrame.Parent = promptFrame

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 12)
kCorner.Parent = keyFrame

local kStroke = Instance.new("UIStroke")
kStroke.Color = COLORS.TEXT_WHITE
kStroke.Thickness = 2
kStroke.Parent = keyFrame

local kText = Instance.new("TextLabel")
kText.Text = "E"
kText.Font = Enum.Font.GothamBlack
kText.TextSize = 28
kText.TextColor3 = COLORS.TEXT_WHITE
kText.Size = UDim2.new(1,0,1,0)
kText.BackgroundTransparency = 1
kText.Parent = keyFrame

local kLabel = Instance.new("TextLabel")
kLabel.Text = "BUKA MENU"
kLabel.Font = Enum.Font.GothamBold
kLabel.TextSize = 12
kLabel.TextColor3 = COLORS.TEXT_WHITE
kLabel.Position = UDim2.new(0.5, 0, 1.3, 0)
kLabel.AnchorPoint = Vector2.new(0.5, 0)
kLabel.BackgroundTransparency = 1
kLabel.Size = UDim2.new(0, 100, 0, 20)
kLabel.TextStrokeTransparency = 0.8
kLabel.Parent = promptFrame

-- Mobile Start Button (Circular)
local mStartBtn = Instance.new("TextButton")
mStartBtn.Name = "MobileStart"
mStartBtn.Size = UDim2.new(0, 80, 0, 80)
mStartBtn.Position = UDim2.new(0.9, -20, 0.8, 0)
mStartBtn.AnchorPoint = Vector2.new(1, 0.5)
mStartBtn.BackgroundColor3 = COLORS.ACCENT_INDIGO
mStartBtn.Text = "START"
mStartBtn.Font = Enum.Font.GothamBlack
mStartBtn.TextColor3 = COLORS.TEXT_WHITE
mStartBtn.TextSize = 16
mStartBtn.Visible = false
mStartBtn.Parent = screenGui

local msCorner = Instance.new("UICorner")
msCorner.CornerRadius = UDim.new(1, 0) -- Circle
msCorner.Parent = mStartBtn

local msStroke = Instance.new("UIStroke")
msStroke.Color = Color3.fromRGB(165, 180, 252)
msStroke.Thickness = 4
msStroke.Parent = mStartBtn

-- LOGIC

local gameStarted = false
local startPart = workspace:WaitForChild("StartPart")
local selectedIdx = 2 -- Default to Ready

-- Scale for mobile
if UIS.TouchEnabled then
	mainFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
end

local function updateSelectionVisuals()
	-- Reset
	cBtnStroke.Thickness = 1
	cancelBtn.BackgroundTransparency = 0.3
	cBtnStroke.Color = COLORS.BTN_RED_BORDER

	rBtnStroke.Thickness = 1
	readyBtn.BackgroundTransparency = 0.3
	rBtnStroke.Color = COLORS.BTN_GREEN_BORDER
	readyGlow.ImageTransparency = 0.7

	if selectedIdx == 1 then -- Cancel
		cBtnStroke.Thickness = 3
		cancelBtn.BackgroundTransparency = 0.1
		cBtnStroke.Color = Color3.new(1,1,1)
		TweenService:Create(cancelBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1.05, 0)}):Play()
		TweenService:Create(readyBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1, 0)}):Play()
	else -- Ready
		rBtnStroke.Thickness = 3
		readyBtn.BackgroundTransparency = 0.1
		rBtnStroke.Color = Color3.new(1,1,1)
		readyGlow.ImageTransparency = 0.4
		TweenService:Create(readyBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1.05, 0)}):Play()
		TweenService:Create(cancelBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.48, 0, 1, 0)}):Play()
	end
end

local function handleInput(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

	if input.KeyCode == Enum.KeyCode.Left then
		selectedIdx = 1
		updateSelectionVisuals()
		return Enum.ContextActionResult.Sink
	elseif input.KeyCode == Enum.KeyCode.Right then
		selectedIdx = 2
		updateSelectionVisuals()
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
	mainFrame.Visible = true
	scanlines.Visible = true
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.BackgroundTransparency = 1

	local targetSize = UIS.TouchEnabled and UDim2.new(0.8, 0, 0.6, 0) or UDim2.new(0, 520, 0, 420)

	tweenBlurIn:Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		BackgroundTransparency = 0.05
	}):Play()

	promptFrame.Visible = false
	mStartBtn.Visible = false

	if not UIS.TouchEnabled then
		selectedIdx = 2
		updateSelectionVisuals()
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
	tweenBlurOut:Play()
	local t = TweenService:Create(mainFrame, TweenInfo.new(0.3), {
		Size = UDim2.new(0, 200, 0, 200),
		BackgroundTransparency = 1
	})
	t:Play()
	ContextActionService:UnbindAction(SELECT_ACTION)
	t.Completed:Connect(function()
		mainFrame.Visible = false
		scanlines.Visible = false
	end)
end

-- EVENTS

OpenStartUIEvent.OnClientEvent:Connect(function()
	if not gameStarted then showUI() end
end)

StartVoteCanceledEvent.OnClientEvent:Connect(function(name)
	hideUI()
	if name then
		game.StarterGui:SetCore("SendNotification", {Title = "Cancelled", Text = name.." cancelled."})
	end
end)

ReadyCountEvent.OnClientEvent:Connect(function(ready, total)
	playVal.Text = string.format("%d/%d", ready, total)
	if ready >= total and total > 0 then
		gameStarted = true
		hideUI()
	end
end)

StartVoteCountdownEvent.OnClientEvent:Connect(function(time)
	timerClock.Text = string.format("00:%02d", time)
	local pct = math.clamp(time/30, 0, 1)
	TweenService:Create(barFill, TweenInfo.new(1, Enum.EasingStyle.Linear), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end)

GameSettingsUpdateEvent.OnClientEvent:Connect(function(settings)
	if settings.gameMode then modeVal.Text = string.upper(tostring(settings.gameMode)) end
	if settings.difficulty then diffVal.Text = string.upper(tostring(settings.difficulty)) end
end)

-- Interactions
cancelBtn.MouseButton1Click:Connect(function() CancelStartVoteEvent:FireServer() hideUI() end)
readyBtn.MouseButton1Click:Connect(function() StartGameEvent:FireServer() end)
mStartBtn.MouseButton1Click:Connect(function() OpenStartUIEvent:FireServer() end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.E and not gameStarted and not mainFrame.Visible and promptFrame.Visible then
		OpenStartUIEvent:FireServer()
	end
end)

RunService.RenderStepped:Connect(function()
	if not gameStarted then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local dist = (char.HumanoidRootPart.Position - startPart.Position).Magnitude
			if dist < 15 and not mainFrame.Visible then
				if UIS.TouchEnabled then mStartBtn.Visible = true else promptFrame.Visible = true end
			else
				mStartBtn.Visible = false
				promptFrame.Visible = false
			end
		end
	end
end)
