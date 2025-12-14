-- MissionUI.lua (LocalScript)
-- Path: StarterGui/MissionUI.client.lua
-- Script Place: Lobby
-- Theme: Notice Board / Clipboard (Paper Texture, Pushpins, Polaroid Photos)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cleanup existing
if playerGui:FindFirstChild("MissionUI") then
	playerGui.MissionUI:Destroy()
end
if playerGui:FindFirstChild("MissionButton") then
	playerGui.MissionButton:Destroy()
end

-- ======================================================
-- 1. CONFIGURATION & THEME (Paperwork)
-- ======================================================

local THEME = {
	BoardWood = Color3.fromRGB(139, 69, 19),    -- Corkboard/Wood
	PaperWhite = Color3.fromRGB(240, 235, 225), -- Aged Paper
	PaperYellow = Color3.fromRGB(245, 230, 160),-- Note Paper

	InkBlue = Color3.fromRGB(20, 20, 100),      -- Pen Ink
	InkBlack = Color3.fromRGB(20, 20, 20),      -- Printed Text
	InkRed = Color3.fromRGB(200, 30, 30),       -- Stamp Ink

	PinRed = Color3.fromRGB(200, 50, 50),
	PinGreen = Color3.fromRGB(50, 150, 50),
	PinMetal = Color3.fromRGB(200, 200, 200),
}

local FONTS = {
	Hand = Enum.Font.IndieFlower,        -- Handwritten notes
	Type = Enum.Font.SpecialElite,       -- Typewritten docs
	Stamp = Enum.Font.Bangers,           -- Rubber stamps
}

-- Remote Functions/Events
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local getMissionData = RemoteFunctions:WaitForChild("GetMissionData")
local claimMissionReward = RemoteFunctions:WaitForChild("ClaimMissionReward")
local rerollMission = RemoteFunctions:WaitForChild("RerollMission")

local missionProgressUpdated = RemoteEvents:WaitForChild("MissionProgressUpdated")
local missionsReset = RemoteEvents:WaitForChild("MissionsReset")

-- State
local currentMissionData = nil
local currentTab = "Daily"
local missionToRerollId = nil
local missionToRerollType = nil

-- UI References
local screenGui, mainBoard
local contentArea
local dailyPaper, weeklyPaper
local toastContainer

-- ======================================================
-- 2. UI UTILITIES
-- ======================================================

local function addShadow(instance)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "DropShadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 5, 0.5, 5)
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.ZIndex = instance.ZIndex - 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0,0,0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Parent = instance
end

local function addPin(parent, pos)
	local pin = Instance.new("Frame")
	pin.Size = UDim2.fromOffset(12, 12)
	pin.Position = pos
	pin.AnchorPoint = Vector2.new(0.5, 0.5)
	pin.BackgroundColor3 = THEME.PinRed
	pin.ZIndex = parent.ZIndex + 5
	pin.Parent = parent

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1,0)
	c.Parent = pin

	-- Shine
	local s = Instance.new("Frame")
	s.Size = UDim2.fromOffset(4,4)
	s.Position = UDim2.fromOffset(2,2)
	s.BackgroundColor3 = Color3.new(1,1,1)
	s.BorderSizePixel = 0
	s.ZIndex = pin.ZIndex
	s.Parent = pin
	local sc = Instance.new("UICorner"); sc.CornerRadius=UDim.new(1,0); sc.Parent=s

	-- Needle shadow implied
end

local function createPaper(parent, size, pos, color)
	local paper = Instance.new("Frame")
	paper.Size = size
	paper.Position = pos
	paper.BackgroundColor3 = color or THEME.PaperWhite
	paper.Parent = parent
	-- slight rotation for messy look
	paper.Rotation = math.random(-2, 2)
	addShadow(paper)
	return paper
end

-- ======================================================
-- 3. UI CONSTRUCTION
-- ======================================================

screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- HUD Button (Clipboard Icon)
local hud = Instance.new("TextButton")
hud.Name = "OpenBtn"
hud.Size = UDim2.fromOffset(60, 80)
hud.Position = UDim2.new(0, 20, 0, 120)
hud.BackgroundColor3 = THEME.BoardWood
hud.Text = ""
hud.Parent = screenGui
-- Clipboard Clip
local clip = Instance.new("Frame")
clip.Size = UDim2.new(0.8, 0, 0.2, 0)
clip.Position = UDim2.new(0.1, 0, 0, 0)
clip.BackgroundColor3 = Color3.new(0.5,0.5,0.5)
clip.Parent = hud
-- Paper
local p = Instance.new("Frame")
p.Size = UDim2.new(0.8, 0, 0.7, 0)
p.Position = UDim2.new(0.1, 0, 0.2, 0)
p.BackgroundColor3 = THEME.PaperWhite
p.Parent = hud
-- Text
local t = Instance.new("TextLabel")
t.Text = "JOBS"
t.Size = UDim2.fromScale(1,1)
t.BackgroundTransparency = 1
t.Font = FONTS.Stamp
t.TextSize = 18
t.TextColor3 = THEME.InkBlack
t.Parent = p

local function toggleUI()
	if screenGui.Enabled and mainBoard.Visible then
		mainBoard.Visible = false
	else
		screenGui.Enabled = true
		mainBoard.Visible = true
		-- Refresh logic
		local s, r = pcall(function() return getMissionData:InvokeServer() end)
		if s then currentMissionData = r; populateBoard() end
	end
end

hud.MouseButton1Click:Connect(toggleUI)

-- Main Board (Corkboard)
mainBoard = Instance.new("Frame")
mainBoard.Name = "Board"
mainBoard.Size = UDim2.fromOffset(900, 600)
mainBoard.Position = UDim2.new(0.5, 0, 0.5, 0)
mainBoard.AnchorPoint = Vector2.new(0.5, 0.5)
mainBoard.BackgroundColor3 = THEME.BoardWood
mainBoard.Visible = false
mainBoard.Parent = screenGui

-- Wood Texture
local woodTex = Instance.new("ImageLabel")
woodTex.Size = UDim2.fromScale(1,1)
woodTex.BackgroundTransparency = 1
woodTex.Image = "rbxassetid://6008328148" -- Noise
woodTex.ImageColor3 = Color3.fromRGB(100, 50, 0)
woodTex.Parent = mainBoard

-- Close Button (Pinned note)
local closeNote = createPaper(mainBoard, UDim2.fromOffset(50, 50), UDim2.new(1, -60, 0, 10), THEME.PaperYellow)
addPin(closeNote, UDim2.fromScale(0.5, 0.1))
local cb = Instance.new("TextButton")
cb.Size = UDim2.fromScale(1,1)
cb.BackgroundTransparency = 1
cb.Text = "X"
cb.Font = FONTS.Hand
cb.TextSize = 40
cb.TextColor3 = THEME.InkRed
cb.Parent = closeNote
cb.MouseButton1Click:Connect(function() mainBoard.Visible = false end)

-- Header Note
local headerNote = createPaper(mainBoard, UDim2.new(0, 300, 0, 60), UDim2.new(0.5, -150, 0, 20))
addPin(headerNote, UDim2.fromScale(0.1, 0.5))
addPin(headerNote, UDim2.fromScale(0.9, 0.5))
local ht = Instance.new("TextLabel")
ht.Size = UDim2.fromScale(1,1)
ht.BackgroundTransparency = 1
ht.Text = "NOTICE BOARD"
ht.Font = FONTS.Stamp
ht.TextSize = 36
ht.TextColor3 = THEME.InkBlack
ht.Parent = headerNote

-- Tabs (Folders on the bottom left/right)
-- We'll use two large papers for Daily/Weekly lists

-- DAILY PAPER (Left)
dailyPaper = createPaper(mainBoard, UDim2.new(0.45, 0, 0.75, 0), UDim2.new(0.03, 0, 0.2, 0), THEME.PaperWhite)
addPin(dailyPaper, UDim2.fromScale(0.5, 0.05))

local dHeader = Instance.new("TextLabel")
dHeader.Text = "DAILY ORDERS"
dHeader.Font = FONTS.Type
dHeader.TextSize = 24
dHeader.TextColor3 = THEME.InkBlack
dHeader.Size = UDim2.new(1, 0, 0, 40)
dHeader.BackgroundTransparency = 1
dHeader.Parent = dailyPaper

local dList = Instance.new("ScrollingFrame")
dList.Size = UDim2.new(0.9, 0, 0.85, 0)
dList.Position = UDim2.new(0.05, 0, 0.15, 0)
dList.BackgroundTransparency = 1
dList.ScrollBarThickness = 4
dList.ScrollBarImageColor3 = Color3.new(0,0,0)
dList.Parent = dailyPaper
local dlLayout = Instance.new("UIListLayout")
dlLayout.Padding = UDim.new(0, 10)
dlLayout.Parent = dList

-- WEEKLY PAPER (Right)
weeklyPaper = createPaper(mainBoard, UDim2.new(0.45, 0, 0.75, 0), UDim2.new(0.52, 0, 0.2, 0), THEME.PaperYellow)
addPin(weeklyPaper, UDim2.fromScale(0.5, 0.05))

local wHeader = Instance.new("TextLabel")
wHeader.Text = "WEEKLY GOALS"
wHeader.Font = FONTS.Hand
wHeader.TextSize = 28
wHeader.TextColor3 = THEME.InkBlue
wHeader.Size = UDim2.new(1, 0, 0, 40)
wHeader.BackgroundTransparency = 1
wHeader.Parent = weeklyPaper

local wList = Instance.new("ScrollingFrame")
wList.Size = UDim2.new(0.9, 0, 0.85, 0)
wList.Position = UDim2.new(0.05, 0, 0.15, 0)
wList.BackgroundTransparency = 1
wList.ScrollBarThickness = 4
wList.ScrollBarImageColor3 = THEME.InkBlue
wList.Parent = weeklyPaper
local wlLayout = Instance.new("UIListLayout")
wlLayout.Padding = UDim.new(0, 10)
wlLayout.Parent = wList


-- ======================================================
-- 4. LOGIC
-- ======================================================

local function createMissionItem(id, info, listParent, isWeekly)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 80)
	frame.BackgroundColor3 = Color3.new(1,1,1)
	frame.BackgroundTransparency = 0.5 -- See paper texture
	frame.BorderSizePixel = 0

	-- Underline
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 1, -1)
	line.BackgroundColor3 = isWeekly and THEME.InkBlue or THEME.InkBlack
	line.BorderSizePixel = 0
	line.Parent = frame

	-- Text
	local desc = Instance.new("TextLabel")
	desc.Text = "- " .. info.Description
	desc.Size = UDim2.new(0.7, 0, 0.6, 0)
	desc.BackgroundTransparency = 1
	desc.Font = isWeekly and FONTS.Hand or FONTS.Type
	desc.TextColor3 = isWeekly and THEME.InkBlue or THEME.InkBlack
	desc.TextSize = 18
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = frame

	local progress = Instance.new("TextLabel")
	progress.Text = "(" .. info.Progress .. "/" .. info.Target .. ")"
	progress.Size = UDim2.new(0.7, 0, 0.3, 0)
	progress.Position = UDim2.new(0, 0, 0.6, 0)
	progress.BackgroundTransparency = 1
	progress.Font = FONTS.Type
	progress.TextColor3 = Color3.fromRGB(100,100,100)
	progress.TextSize = 14
	progress.TextXAlignment = Enum.TextXAlignment.Left
	progress.Parent = frame

	-- Stamp / Button
	local stamp = Instance.new("TextButton")
	stamp.Size = UDim2.new(0.25, 0, 0.6, 0)
	stamp.Position = UDim2.new(0.75, 0, 0.2, 0)
	stamp.BackgroundTransparency = 1
	stamp.Font = FONTS.Stamp
	stamp.TextSize = 24
	stamp.Rotation = math.random(-15, 15)
	stamp.Parent = frame

	if info.Claimed then
		stamp.Text = "DONE"
		stamp.TextColor3 = THEME.InkBlack
		stamp.AutoButtonColor = false
	elseif info.Completed then
		stamp.Text = "CLAIM!"
		stamp.TextColor3 = THEME.InkRed

		-- Box around stamp
		local border = Instance.new("UIStroke")
		border.Color = THEME.InkRed
		border.Thickness = 2
		border.Parent = stamp

		stamp.MouseButton1Click:Connect(function()
			local s, r = pcall(function() return claimMissionReward:InvokeServer(id) end)
			if s and r.Success then
				info.Claimed = true
				populateBoard()
			end
		end)
	else
		-- In progress, show reward
		stamp.Text = "+"..info.Reward.Value.." MP"
		stamp.TextColor3 = Color3.fromRGB(100, 100, 100)
		stamp.TextSize = 18
		stamp.Rotation = 0
		stamp.AutoButtonColor = false

		-- Reroll (Eraser?)
		if not isWeekly and not currentMissionData.Daily.RerollUsed then
			local reroll = Instance.new("TextButton")
			reroll.Text = "X"
			reroll.Size = UDim2.new(0, 20, 0, 20)
			reroll.Position = UDim2.new(1, -20, 0, 0)
			reroll.BackgroundTransparency = 1
			reroll.TextColor3 = THEME.InkRed
			reroll.Parent = frame
			reroll.MouseButton1Click:Connect(function()
				local s = rerollMission:InvokeServer("Daily", id)
				if s then
					currentMissionData = getMissionData:InvokeServer()
					populateBoard()
				end
			end)
		end
	end

	frame.Parent = listParent
end

function populateBoard()
	if not currentMissionData then return end

	-- Clear Lists
	for _, c in ipairs(dList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, c in ipairs(wList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	-- Daily
	for id, info in pairs(currentMissionData.Daily.Missions) do
		createMissionItem(id, info, dList, false)
	end

	-- Weekly
	for id, info in pairs(currentMissionData.Weekly.Missions) do
		createMissionItem(id, info, wList, true)
	end
end

missionProgressUpdated.OnClientEvent:Connect(function()
	if mainBoard.Visible then
		currentMissionData = getMissionData:InvokeServer()
		populateBoard()
	end
end)

local function setupPrompt()
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment", 10)
	if not lobbyEnv then return end

	-- Matches LobbyBuilder name ("LobbyRoom" interaction near Alexander)
	local shopPart = lobbyEnv:WaitForChild("LobbyRoom", 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				toggleUI()
			end)
		end
	end
end

task.spawn(setupPrompt)

return {}
