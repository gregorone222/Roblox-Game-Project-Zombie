-- MissionUI.lua (LocalScript)
-- Path: StarterGui/MissionUI.client.lua
-- Script Place: Lobby
-- Theme: SCAVENGER TECH (DIY, Rusted Metal, Duct Tape, Graffiti)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

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
-- 1. CONFIGURATION & THEME (Scavenger Tech)
-- ======================================================

local THEME = {
	-- Materials
	RustedMetal = Color3.fromRGB(60, 55, 50),   -- Main Body
	DarkIron = Color3.fromRGB(35, 35, 35),      -- Inner Screen/Recess
	DuctTape = Color3.fromRGB(180, 180, 190),   -- Tape Accents

	-- Spray Paint Colors
	SprayRed = Color3.fromRGB(220, 50, 40),     -- Warning / Cancel
	SprayGreen = Color3.fromRGB(80, 200, 60),   -- Success
	SprayOrange = Color3.fromRGB(255, 140, 20), -- Highlight
	SprayWhite = Color3.fromRGB(240, 240, 235), -- Text

	-- Text
	TextDark = Color3.fromRGB(30, 30, 30),
}

local FONTS = {
	Graffiti = Enum.Font.AmaticSC,     -- Handwritten headers (Marker on metal)
	Industrial = Enum.Font.Oswald,     -- Sturdy labels
	Body = Enum.Font.GothamBold,       -- Readable data
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
local screenGui, mainTablet
local missionsScroll
local dailyTabBtn, weeklyTabBtn
local toastContainer

-- ======================================================
-- 2. UI UTILITIES
-- ======================================================

local function addStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0,0,0)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

-- Create a "Duct Tape" visual
local function createTape(parent, rotation)
	local tape = Instance.new("Frame")
	tape.Name = "DuctTape"
	tape.Size = UDim2.fromOffset(60, 20)
	tape.BackgroundColor3 = THEME.DuctTape
	tape.BorderSizePixel = 0
	tape.Rotation = rotation or math.random(-25, 25)
	tape.ZIndex = parent.ZIndex + 5
	tape.Parent = parent

	-- Texture for tape (wrinkles)
	local tex = Instance.new("ImageLabel")
	tex.BackgroundTransparency = 1
	tex.Image = "rbxassetid://15541607567" -- Noise overlay
	tex.ImageTransparency = 0.8
	tex.Size = UDim2.fromScale(1,1)
	tex.Parent = tape

	return tape
end

-- Create a "Bolt" visual
local function createBolt(parent, position)
	local bolt = Instance.new("Frame")
	bolt.Size = UDim2.fromOffset(12, 12)
	bolt.Position = position
	bolt.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	bolt.Parent = parent
	addCorner(bolt, 6)
	addStroke(bolt, Color3.new(0,0,0), 1)

	local shine = Instance.new("Frame")
	shine.Size = UDim2.fromOffset(4, 4)
	shine.Position = UDim2.fromOffset(2, 2)
	shine.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	shine.BorderSizePixel = 0
	shine.Parent = bolt
	addCorner(shine, 2)
end

-- Sounds (Rough, Industrial)
local SOUNDS = {
	Clunk = 6052554659, -- Heavy
	Static = 6052554472, -- Noise
	Spray = 6052553974, -- Hiss (reused placeholder, ideally spray can)
	Click = 6895079853,
}

local function playSound(soundId, pitch)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. soundId
	s.Volume = 0.6
	s.Pitch = pitch or math.random(90, 110)/100
	s.Parent = playerGui
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

-- ======================================================
-- 3. UI CONSTRUCTION
-- ======================================================

screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.DisplayOrder = 10

-- >>> HUD BUTTON (Scrap Metal Plate) <<<
local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "MissionButton"
buttonGui.ResetOnSpawn = false
buttonGui.Parent = playerGui

local hudContainer = Instance.new("Frame")
hudContainer.Name = "HUD"
hudContainer.Size = UDim2.fromOffset(80, 80)
hudContainer.Position = UDim2.new(0, 20, 0, 20)
hudContainer.BackgroundColor3 = THEME.RustedMetal
hudContainer.Rotation = 2
hudContainer.Parent = buttonGui
addCorner(hudContainer, 8)
addStroke(hudContainer, Color3.new(0,0,0), 3)

-- Bolts
createBolt(hudContainer, UDim2.new(0, 5, 0, 5))
createBolt(hudContainer, UDim2.new(1, -17, 0, 5))
createBolt(hudContainer, UDim2.new(0, 5, 1, -17))
createBolt(hudContainer, UDim2.new(1, -17, 1, -17))

-- Graffiti
local hudText = Instance.new("TextLabel")
hudText.Text = "JOBS"
hudText.Font = FONTS.Graffiti
hudText.TextSize = 42
hudText.TextColor3 = THEME.SprayWhite
hudText.Rotation = -10
hudText.Size = UDim2.fromScale(1, 1)
hudText.BackgroundTransparency = 1
hudText.Parent = hudContainer

local hudBtn = Instance.new("TextButton")
hudBtn.Size = UDim2.fromScale(1, 1)
hudBtn.BackgroundTransparency = 1
hudBtn.Text = ""
hudBtn.Parent = hudContainer

hudBtn.MouseEnter:Connect(function()
	TweenService:Create(hudContainer, TweenInfo.new(0.1), {Rotation = -2, Size = UDim2.fromOffset(85, 85)}):Play()
	playSound(SOUNDS.Static)
end)
hudBtn.MouseLeave:Connect(function()
	TweenService:Create(hudContainer, TweenInfo.new(0.2), {Rotation = 2, Size = UDim2.fromOffset(80, 80)}):Play()
end)

-- >>> MAIN TABLET (Rugged Device) <<<
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = workspace.CurrentCamera

mainTablet = Instance.new("Frame")
mainTablet.Name = "Tablet"
mainTablet.Size = UDim2.fromOffset(750, 520)
mainTablet.AnchorPoint = Vector2.new(0.5, 0.5)
mainTablet.Position = UDim2.fromScale(0.5, 0.5)
mainTablet.BackgroundColor3 = THEME.RustedMetal
mainTablet.Parent = screenGui
addCorner(mainTablet, 12)
addStroke(mainTablet, Color3.new(0.1,0.1,0.1), 4)

-- Tablet Details
local screenBezel = Instance.new("Frame")
screenBezel.Size = UDim2.new(1, -30, 1, -30)
screenBezel.Position = UDim2.new(0, 15, 0, 15)
screenBezel.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Rubber gasket
screenBezel.Parent = mainTablet
addCorner(screenBezel, 8)

-- The "Screen" (Dirty glass look)
local innerScreen = Instance.new("Frame")
innerScreen.Name = "Screen"
innerScreen.Size = UDim2.new(1, -20, 1, -20)
innerScreen.Position = UDim2.new(0, 10, 0, 10)
innerScreen.BackgroundColor3 = THEME.DarkIron
innerScreen.Parent = screenBezel
addCorner(innerScreen, 4)

-- Crack/Dirt overlay
local dirt = Instance.new("ImageLabel")
dirt.Size = UDim2.fromScale(1, 1)
dirt.BackgroundTransparency = 1
dirt.Image = "rbxassetid://15541607567" -- Dirt noise
dirt.ImageColor3 = Color3.new(0,0,0)
dirt.ImageTransparency = 0.6
dirt.Parent = innerScreen

-- HEADER (Painted on metal)
local headerText = Instance.new("TextLabel")
headerText.Text = "SCAVENGER LOG"
headerText.Font = FONTS.Graffiti
headerText.TextSize = 48
headerText.TextColor3 = THEME.SprayOrange
headerText.Size = UDim2.new(1, 0, 0, 60)
headerText.Position = UDim2.new(0, 20, 0, 0)
headerText.BackgroundTransparency = 1
headerText.TextXAlignment = Enum.TextXAlignment.Left
headerText.Rotation = -1
headerText.Parent = innerScreen

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = THEME.SprayRed
closeBtn.Text = "X"
closeBtn.Font = FONTS.Graffiti
closeBtn.TextSize = 32
closeBtn.TextColor3 = THEME.SprayWhite
closeBtn.Rotation = 5
closeBtn.Parent = innerScreen
addCorner(closeBtn, 8)
local tape = createTape(innerScreen, 45)
tape.Position = UDim2.new(1, -50, 0, 0) -- Tape holding the button

-- TABS (Taped Notes)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -40, 0, 50)
tabContainer.Position = UDim2.new(0, 20, 0, 60)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = innerScreen

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 30)
tabLayout.Parent = tabContainer

local function createTab(text, color)
	local btn = Instance.new("TextButton")
	btn.Name = text
	btn.Size = UDim2.new(0, 160, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(240, 230, 200) -- Paper note
	btn.Rotation = math.random(-2, 2)
	btn.Text = ""
	btn.Parent = tabContainer
	addStroke(btn, Color3.new(0,0,0), 1)

	-- Tape it
	local t = createTape(btn, 0)
	t.Size = UDim2.new(0, 40, 0, 15)
	t.Position = UDim2.new(0.5, -20, 0, -5)

	local lbl = Instance.new("TextLabel")
	lbl.Text = text
	lbl.Font = FONTS.Graffiti
	lbl.TextSize = 28
	lbl.TextColor3 = Color3.new(0,0,0)
	lbl.Size = UDim2.fromScale(1,1)
	lbl.BackgroundTransparency = 1
	lbl.Parent = btn

	-- Marker underline
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0.8, 0, 0, 3)
	line.Position = UDim2.new(0.1, 0, 0.8, 0)
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Visible = false
	line.Parent = btn

	return btn, line
end

local dailyTabBtnRef, dailyLine = createTab("DAILY", THEME.SprayRed)
local weeklyTabBtnRef, weeklyLine = createTab("WEEKLY", THEME.SprayGreen)

dailyTabBtn = dailyTabBtnRef
weeklyTabBtn = weeklyTabBtnRef

-- CONTENT SCROLL
missionsScroll = Instance.new("ScrollingFrame")
missionsScroll.Size = UDim2.new(1, -40, 1, -140)
missionsScroll.Position = UDim2.new(0, 20, 0, 130)
missionsScroll.BackgroundTransparency = 1
missionsScroll.BorderSizePixel = 0
missionsScroll.ScrollBarThickness = 8
missionsScroll.ScrollBarImageColor3 = THEME.RustedMetal
missionsScroll.Parent = innerScreen

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 15)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = missionsScroll

-- TOASTS (Spray Paint Stencil)
toastContainer = Instance.new("Frame")
toastContainer.Size = UDim2.new(0, 400, 1, -20)
toastContainer.Position = UDim2.new(1, -420, 0, 20)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = screenGui

local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 5)
toastLayout.Parent = toastContainer

-- DIALOG (Scrap Metal Modal)
local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Visible = false
overlay.ZIndex = 200
overlay.Parent = screenGui

local dialog = Instance.new("Frame")
dialog.Size = UDim2.fromOffset(400, 220)
dialog.AnchorPoint = Vector2.new(0.5, 0.5)
dialog.Position = UDim2.fromScale(0.5, 0.5)
dialog.BackgroundColor3 = THEME.RustedMetal
dialog.Parent = overlay
addCorner(dialog, 4)
addStroke(dialog, Color3.new(0,0,0), 3)
createBolt(dialog, UDim2.new(0, 5, 0, 5))
createBolt(dialog, UDim2.new(1, -17, 0, 5))
createBolt(dialog, UDim2.new(0, 5, 1, -17))
createBolt(dialog, UDim2.new(1, -17, 1, -17))

local dialogTitle = Instance.new("TextLabel")
dialogTitle.Text = "SCRAP MISSION?"
dialogTitle.Font = FONTS.Graffiti
dialogTitle.TextSize = 36
dialogTitle.TextColor3 = THEME.SprayWhite
dialogTitle.Size = UDim2.new(1, 0, 0, 50)
dialogTitle.BackgroundTransparency = 1
dialogTitle.Parent = dialog

local dialogText = Instance.new("TextLabel")
dialogText.Text = "Toss this job and look for another?\n(No going back)"
dialogText.Font = FONTS.Body
dialogText.TextSize = 16
dialogText.TextColor3 = Color3.new(0.9,0.9,0.9)
dialogText.Size = UDim2.new(1, -40, 0, 80)
dialogText.Position = UDim2.new(0, 20, 0, 50)
dialogText.BackgroundTransparency = 1
dialogText.TextWrapped = true
dialogText.Parent = dialog

local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(1, -40, 0, 60)
btnContainer.Position = UDim2.new(0, 20, 1, -70)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = dialog

local function createDialogBtn(text, color, pos, rotation)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Font = FONTS.Graffiti
	b.TextSize = 28
	b.BackgroundColor3 = Color3.fromRGB(20,20,20)
	b.TextColor3 = color
	b.Size = UDim2.new(0.45, 0, 1, 0)
	b.Position = UDim2.new(pos, 0, 0, 0)
	b.Rotation = rotation
	b.Parent = btnContainer
	addStroke(b, color, 2)
	-- Tape corners
	local t = createTape(b, -45)
	t.Size = UDim2.fromOffset(20, 10)
	t.Position = UDim2.new(0, -5, 0, -5)
	return b
end

local cancelBtn = createDialogBtn("NAH", THEME.SprayRed, 0, -2)
local confirmBtn = createDialogBtn("DO IT", THEME.SprayGreen, 0.55, 2)


-- ======================================================
-- 4. HELPER FUNCTIONS
-- ======================================================

local function showToast(title, msg, isError)
	local t = Instance.new("Frame")
	t.Size = UDim2.new(1, 0, 0, 60)
	t.BackgroundColor3 = Color3.new(0,0,0)
	t.BackgroundTransparency = 0.3
	t.Parent = toastContainer

	-- Paint Splatter effect (Simulated with rotation/color)
	local paint = Instance.new("Frame")
	paint.Size = UDim2.new(0, 10, 1, 0)
	paint.BackgroundColor3 = isError and THEME.SprayRed or THEME.SprayGreen
	paint.Parent = t

	local tl = Instance.new("TextLabel")
	tl.Text = title
	tl.Font = FONTS.Graffiti
	tl.TextSize = 24
	tl.TextColor3 = isError and THEME.SprayRed or THEME.SprayGreen
	tl.Size = UDim2.new(1, -20, 0, 25)
	tl.Position = UDim2.new(0, 20, 0, 5)
	tl.BackgroundTransparency = 1
	tl.TextXAlignment = Enum.TextXAlignment.Left
	tl.Parent = t

	local ml = Instance.new("TextLabel")
	ml.Text = msg
	ml.Font = FONTS.Body
	ml.TextSize = 14
	ml.TextColor3 = THEME.SprayWhite
	ml.Size = UDim2.new(1, -20, 0, 25)
	ml.Position = UDim2.new(0, 20, 0, 30)
	ml.BackgroundTransparency = 1
	ml.TextXAlignment = Enum.TextXAlignment.Left
	ml.Parent = t

	playSound(SOUNDS.Spray)

	task.delay(4, function() t:Destroy() end)
end

local function createEntry(id, info, type)
	local frame = Instance.new("Frame")
	frame.Name = id
	frame.Size = UDim2.new(1, 0, 0, 90)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Dark metal plate
	frame.LayoutOrder = info.Completed and 2 or (info.Claimed and 3 or 1)
	addStroke(frame, Color3.new(0,0,0), 2)

	-- Rivets
	createBolt(frame, UDim2.new(0, 5, 0, 5))
	createBolt(frame, UDim2.new(1, -17, 0, 5))

	local statusColor = THEME.SprayWhite
	if info.Claimed then statusColor = Color3.fromRGB(100,100,100) end
	if info.Completed and not info.Claimed then statusColor = THEME.SprayGreen end

	local desc = Instance.new("TextLabel")
	desc.Text = info.Description
	desc.Font = FONTS.Industrial
	desc.TextSize = 18
	desc.TextColor3 = statusColor
	desc.Size = UDim2.new(0.65, 0, 0, 50)
	desc.Position = UDim2.new(0, 20, 0, 10)
	desc.BackgroundTransparency = 1
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = frame

	local reward = Instance.new("TextLabel")
	reward.Text = "+"..info.Reward.Value.." MP"
	reward.Font = FONTS.Graffiti
	reward.TextSize = 24
	reward.TextColor3 = THEME.SprayOrange
	reward.Size = UDim2.new(0.3, 0, 0, 30)
	reward.Position = UDim2.new(0.65, 0, 0, 10)
	reward.BackgroundTransparency = 1
	reward.TextXAlignment = Enum.TextXAlignment.Right
	reward.Rotation = -2
	reward.Parent = frame

	local prog = Instance.new("TextLabel")
	prog.Text = info.Progress .. "/" .. info.Target
	prog.Font = FONTS.Body
	prog.TextSize = 14
	prog.TextColor3 = Color3.fromRGB(150,150,150)
	prog.Size = UDim2.new(0.3, 0, 0, 20)
	prog.Position = UDim2.new(0.65, 0, 0, 35)
	prog.BackgroundTransparency = 1
	prog.TextXAlignment = Enum.TextXAlignment.Right
	prog.Parent = frame

	-- Button Area
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, 0, 0, 30)
	btn.Position = UDim2.new(0.7, 0, 1, -40)
	btn.Font = FONTS.Industrial
	btn.TextSize = 16
	btn.Parent = frame
	addCorner(btn, 4)

	local rerollUsed = (type == "Daily") and currentMissionData.Daily.RerollUsed or currentMissionData.Weekly.RerollUsed

	if info.Claimed then
		btn.Text = "DONE"
		btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		btn.TextColor3 = Color3.fromRGB(80,80,80)
		btn.AutoButtonColor = false
		-- Crossed out with "Tape"
		local t = createTape(frame, math.random(-10, 10))
		t.Position = UDim2.new(0.5, -30, 0.5, -10)
		t.Size = UDim2.new(0.8, 0, 0, 10)
		t.BackgroundColor3 = Color3.new(0,0,0)
		t.BackgroundTransparency = 0.5

	elseif info.Completed then
		btn.Text = "TAKE IT"
		btn.BackgroundColor3 = THEME.SprayGreen
		btn.TextColor3 = Color3.new(0,0,0)

		btn.MouseButton1Click:Connect(function()
			local success, result = pcall(function() return claimMissionReward:InvokeServer(id) end)
			if success and result.Success then
				info.Claimed = true
				showToast("SCORED", "+"..result.Reward.Value.." MP", false)
				populateList()
			else
				showToast("JAMMED", "Try again.", true)
			end
		end)
	else
		-- In Progress
		if rerollUsed then
			btn.Visible = false
		else
			btn.Text = "SWAP"
			btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
			btn.TextColor3 = THEME.SprayWhite
			addStroke(btn, Color3.new(0,0,0), 1)

			btn.MouseButton1Click:Connect(function()
				missionToRerollId = id
				missionToRerollType = type
				overlay.Visible = true
				playSound(SOUNDS.Clunk)
			end)
		end
	end

	return frame
end


function populateList()
	if not currentMissionData then return end
	for _, c in ipairs(missionsScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local data = (currentTab == "Daily") and currentMissionData.Daily or currentMissionData.Weekly

	local sorted = {}
	for id, info in pairs(data.Missions) do table.insert(sorted, {id=id, info=info}) end
	table.sort(sorted, function(a, b)
		local function sc(i) if i.Claimed then return 3 elseif i.Completed then return 1 else return 2 end end
		return sc(a.info) < sc(b.info)
	end)

	for _, item in ipairs(sorted) do
		local c = createEntry(item.id, item.info, currentTab)
		c.Parent = missionsScroll
	end
end

local function updateTabs()
	if currentTab == "Daily" then
		dailyLine.Visible = true
		weeklyLine.Visible = false
	else
		dailyLine.Visible = false
		weeklyLine.Visible = true
	end
end

-- ======================================================
-- 5. INTERACTION LOGIC
-- ======================================================

local function openUI()
	local s, r = pcall(function() return getMissionData:InvokeServer() end)
	if not s then return end
	currentMissionData = r
	populateList()
	updateTabs()

	screenGui.Enabled = true
	playSound(SOUNDS.Clunk)

	-- Heavy bounce
	mainTablet.Position = UDim2.new(0.5, 0, -0.5, 0)
	TweenService:Create(mainTablet, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 15}):Play()
end

local function closeUI()
	playSound(SOUNDS.Clunk)
	TweenService:Create(blur, TweenInfo.new(0.2), {Size = 0}):Play()
	local t = TweenService:Create(mainTablet, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)})
	t:Play()
	t.Completed:Wait()
	screenGui.Enabled = false
end

hudBtn.MouseButton1Click:Connect(openUI)
closeBtn.MouseButton1Click:Connect(closeUI)

dailyTabBtnRef.MouseButton1Click:Connect(function()
	if currentTab ~= "Daily" then
		currentTab = "Daily"
		playSound(SOUNDS.Click)
		updateTabs()
		populateList()
	end
end)

weeklyTabBtnRef.MouseButton1Click:Connect(function()
	if currentTab ~= "Weekly" then
		currentTab = "Weekly"
		playSound(SOUNDS.Click)
		updateTabs()
		populateList()
	end
end)

cancelBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
	missionToRerollId = nil
	playSound(SOUNDS.Click)
end)

confirmBtn.MouseButton1Click:Connect(function()
	overlay.Visible = false
	if missionToRerollId and missionToRerollType then
		local s, msg = rerollMission:InvokeServer(missionToRerollType, missionToRerollId)
		if s then
			showToast("DONE", "Job scrapped.", false)
			currentMissionData = getMissionData:InvokeServer()
			populateList()
		else
			showToast("NOPE", "Can't swap.", true)
		end
	end
	missionToRerollId = nil
	playSound(SOUNDS.Static)
end)

missionsReset.OnClientEvent:Connect(function()
	if screenGui.Enabled then
		currentMissionData = getMissionData:InvokeServer()
		populateList()
		showToast("NEW JOBS", "Board updated.", false)
	end
end)

missionProgressUpdated.OnClientEvent:Connect(function(ud)
	if currentMissionData then
		local dc = currentMissionData.Daily.Missions[ud.missionID] and currentMissionData.Daily or currentMissionData.Weekly
		if dc and dc.Missions[ud.missionID] then
			local m = dc.Missions[ud.missionID]
			m.Progress = ud.newProgress
			m.Completed = ud.completed
			if screenGui.Enabled then populateList() end
			if ud.justCompleted then
				showToast("GOOD WORK", "Job done.", false)
				playSound(SOUNDS.Spray)
			end
		end
	end
end)

print("MissionUI: Scavenger Tech Loaded")
