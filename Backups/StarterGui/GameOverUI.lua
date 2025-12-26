-- GameOverUI.lua (LocalScript)
-- Path: StarterGui/GameOverUI.lua
-- Theme: Morgue / Death Certificate (Bureaucratic Horror)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local ExitGameEvent = RemoteEvents:WaitForChild("ExitGameEvent")

-- Config & Constants
local THEME = {
	Paper = Color3.fromRGB(245, 245, 240),
	Ink = Color3.fromRGB(30, 30, 35),
	StampRed = Color3.fromRGB(180, 20, 20),
	Clipboard = Color3.fromRGB(80, 60, 40),
	Steel = Color3.fromRGB(100, 110, 115),
	Background = Color3.fromRGB(20, 25, 30),
}

-- Safe Font Retrieval
local function getFont(name, fallback)
	local success, result = pcall(function() return Enum.Font[name] end)
	return success and result or fallback
end

local FONTS = {
	Typewriter = getFont("SpecialElite", Enum.Font.Code),
	Stamp = getFont("BlackOpsOne", Enum.Font.SourceSansBold), -- Fallback safe
	Label = Enum.Font.Garamond, -- Formal
}

-- Create Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameOverUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = gui

-- --- UI Helper Functions ---

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Ink
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- --- Layout Construction ---

-- 1. Background (Cold Steel / Morgue)
local bgFrame = Instance.new("Frame")
bgFrame.Name = "Background"
bgFrame.Size = UDim2.fromScale(1, 1)
bgFrame.BackgroundColor3 = THEME.Background
bgFrame.Parent = screenGui

-- Tiled Floor Texture
local tiles = Instance.new("ImageLabel")
tiles.Size = UDim2.fromScale(1, 1)
tiles.BackgroundTransparency = 1
tiles.Image = "rbxassetid://4800392095" -- Tile pattern
tiles.TileSize = UDim2.new(0, 100, 0, 100)
tiles.ScaleType = Enum.ScaleType.Tile
tiles.ImageColor3 = Color3.fromRGB(40, 45, 50)
tiles.Parent = bgFrame

local vignette = Instance.new("ImageLabel")
vignette.Size = UDim2.fromScale(1, 1)
vignette.BackgroundTransparency = 1
vignette.Image = "rbxassetid://4576475446"
vignette.ImageColor3 = Color3.new(0,0,0)
vignette.ImageTransparency = 0.3
vignette.Parent = bgFrame

-- 2. Clipboard Container
local clipboard = Instance.new("Frame")
clipboard.Name = "Clipboard"
clipboard.Size = UDim2.new(0, 600, 0, 800)
clipboard.AnchorPoint = Vector2.new(0.5, 0.5)
clipboard.Position = UDim2.new(0.5, 0, 2, 0) -- Start offscreen bottom
clipboard.BackgroundColor3 = THEME.Clipboard
clipboard.Parent = screenGui
createCorner(clipboard, 12)

-- Metal Clip
local clip = Instance.new("Frame")
clip.Size = UDim2.new(0, 400, 0, 80)
clip.Position = UDim2.new(0.5, -200, 0, -20)
clip.BackgroundColor3 = THEME.Steel
clip.ZIndex = 3
clip.Parent = clipboard
createCorner(clip, 8)
createStroke(clip, Color3.fromRGB(50, 50, 50), 2)

-- 3. Death Certificate Paper
local paper = Instance.new("Frame")
paper.Name = "Paper"
paper.Size = UDim2.new(0.9, 0, 0.9, 0)
paper.Position = UDim2.new(0.05, 0, 0.05, 0)
paper.BackgroundColor3 = THEME.Paper
paper.ZIndex = 2
paper.Parent = clipboard
createStroke(paper, Color3.fromRGB(200, 200, 200), 1)

-- Paper Header
local header = Instance.new("TextLabel")
header.Text = "CERTIFICATE OF DEATH"
header.Font = FONTS.Label
header.TextSize = 32
header.TextColor3 = THEME.Ink
header.Size = UDim2.new(1, 0, 0, 60)
header.Position = UDim2.new(0, 0, 0, 60) -- Below clip
header.BackgroundTransparency = 1
header.ZIndex = 2
header.Parent = paper

local subHeader = Instance.new("TextLabel")
subHeader.Text = "DEPARTMENT OF VITAL STATISTICS - ZONE ZERO"
subHeader.Font = FONTS.Typewriter
subHeader.TextSize = 14
subHeader.TextColor3 = THEME.Ink
subHeader.Size = UDim2.new(1, 0, 0, 20)
subHeader.Position = UDim2.new(0, 0, 0, 95)
subHeader.BackgroundTransparency = 1
subHeader.ZIndex = 2
subHeader.Parent = paper

-- Form Fields Container
local form = Instance.new("Frame")
form.Size = UDim2.new(0.8, 0, 0.6, 0)
form.Position = UDim2.new(0.1, 0, 0.18, 0)
form.BackgroundTransparency = 1
form.ZIndex = 2
form.Parent = paper

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 25)
listLayout.Parent = form

local function createFormField(label, valueID)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	row.Parent = form

	local lbl = Instance.new("TextLabel")
	lbl.Text = label .. ":"
	lbl.Font = FONTS.Typewriter
	lbl.TextSize = 18
	lbl.TextColor3 = THEME.Ink
	lbl.Size = UDim2.new(0.4, 0, 1, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1
	lbl.ZIndex = 2
	lbl.Parent = row

	-- Dotted Line
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0.6, 0, 0, 1)
	line.Position = UDim2.new(0.4, 0, 1, -5)
	line.BackgroundColor3 = THEME.Ink
	line.BackgroundTransparency = 0.5
	line.ZIndex = 2
	line.Parent = row

	local val = Instance.new("TextLabel")
	val.Name = "Val"
	val.Text = "" -- Filled later
	val.Font = FONTS.Typewriter
	val.TextSize = 20
	val.TextColor3 = Color3.fromRGB(0, 0, 150) -- Blue Pen
	val.Size = UDim2.new(0.6, 0, 1, 0)
	val.Position = UDim2.new(0.4, 0, 0, -5)
	val.BackgroundTransparency = 1
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.ZIndex = 2
	val.Parent = row

	return val
end

local nameVal = createFormField("DECEASED NAME")
local dateVal = createFormField("DATE OF EXPIRY")
local timeVal = createFormField("TIME SURVIVED")
local waveVal = createFormField("WAVE REACHED")
local causeVal = createFormField("CAUSE OF DEATH") -- Kills/Damage summary
local assetsVal = createFormField("ASSETS RECOVERED") -- Coins

-- Photo Attachment
local photo = Instance.new("ImageLabel")
photo.Size = UDim2.fromOffset(120, 120)
photo.Position = UDim2.new(0.75, 0, 0.05, 0)
photo.BackgroundColor3 = Color3.new(0.9, 0.9, 0.9)
photo.ZIndex = 3
photo.Parent = paper
createStroke(photo, THEME.Ink, 1)

local staple = Instance.new("Frame")
staple.Size = UDim2.new(0, 40, 0, 2)
staple.Position = UDim2.new(0, 10, 0, 10)
staple.BackgroundColor3 = THEME.Steel
staple.Rotation = -15
staple.ZIndex = 4
staple.Parent = photo

-- Stamp (Big Red)
local stamp = Instance.new("TextLabel")
stamp.Text = "TERMINATED"
stamp.Font = FONTS.Stamp
stamp.TextSize = 58
stamp.TextColor3 = THEME.StampRed
stamp.Size = UDim2.new(1, 0, 0, 100)
stamp.Position = UDim2.new(0, 0, 0.5, 0)
stamp.BackgroundTransparency = 1
stamp.Rotation = -20
stamp.TextTransparency = 1 -- Start invisible
stamp.ZIndex = 5
stamp.Parent = paper
createStroke(stamp, THEME.StampRed, 2, 0.5)

-- Footer Button
local archiveBtn = Instance.new("TextButton")
archiveBtn.Text = "ARCHIVE CASE FILE (EXIT)"
archiveBtn.Font = FONTS.Typewriter
archiveBtn.TextSize = 18
archiveBtn.TextColor3 = THEME.Paper
archiveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
archiveBtn.Size = UDim2.new(0.6, 0, 0, 50)
archiveBtn.Position = UDim2.new(0.2, 0, 0.85, 0)
archiveBtn.ZIndex = 3
archiveBtn.Parent = paper
createCorner(archiveBtn, 4)

-- --- Logic ---

local function typewrite(label, text)
	label.Text = ""
	for i = 1, #text do
		label.Text = string.sub(text, 1, i)
		task.wait(0.03)
	end
end

local function showGameOver(data)
	screenGui.Enabled = true
	photo.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

	-- Reset
	stamp.TextTransparency = 1
	stamp.Size = UDim2.new(2, 0, 0, 200) -- Start big for slam effect
	clipboard.Position = UDim2.new(0.5, 0, 1.5, 0)

	-- Slide Up
	TweenService:Create(clipboard, TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

	task.wait(1)

	-- Fill Form
	local now = os.date("*t")
	typewrite(nameVal, player.Name)
	typewrite(dateVal, string.format("%02d/%02d/%04d", now.month, now.day, now.year))

	local m = math.floor((data.TimeAlive or 0) / 60)
	local s = (data.TimeAlive or 0) % 60
	typewrite(timeVal, string.format("%02d MIN %02d SEC", m, s))

	typewrite(waveVal, "WAVE " .. (data.Wave or 0))
	typewrite(causeVal, (data.Kills or 0) .. " CONFIRMED KILLS")
	typewrite(assetsVal, "$" .. (data.CoinsEarned or 0))

	task.wait(0.5)

	-- STAMP SLAM
	stamp.Size = UDim2.new(2, 0, 0, 200)
	stamp.TextTransparency = 0.5
	local slam = TweenService:Create(stamp, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 100), TextTransparency = 0})
	slam:Play()
end

GameOverEvent.OnClientEvent:Connect(function(data)
	data = data or {}
	local mockData = {
		Wave = data.Wave or "??",
		Kills = data.Kills or 0,
		Damage = data.Damage or 0,
		TimeAlive = data.TimeAlive or 0,
		CoinsEarned = data.CoinsEarned or 0,
	}
	showGameOver(mockData)
end)

archiveBtn.MouseButton1Click:Connect(function()
	archiveBtn.Text = "ARCHIVING..."
	task.wait(0.5)
	ExitGameEvent:FireServer()
end)
