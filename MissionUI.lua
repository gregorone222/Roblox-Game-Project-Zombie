-- MissionUI.lua (LocalScript)
-- Path: StarterGui/MissionUI.client.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cleanup
if playerGui:FindFirstChild("MissionUI") then
	playerGui.MissionUI:Destroy()
end
if playerGui:FindFirstChild("MissionButton") then
	playerGui.MissionButton:Destroy()
end

-- ======================================================
-- CONFIGURATION & ASSETS
-- ======================================================

local THEME = {
	Slate950 = Color3.fromRGB(2, 6, 23),
	Slate900 = Color3.fromRGB(15, 23, 42),
	Slate800 = Color3.fromRGB(30, 41, 59),
	Slate700 = Color3.fromRGB(51, 65, 85),
	Slate400 = Color3.fromRGB(148, 163, 184),
	Cyan600 = Color3.fromRGB(8, 145, 178),
	Cyan500 = Color3.fromRGB(6, 182, 212),
	Green600 = Color3.fromRGB(22, 163, 74),
	Indigo600 = Color3.fromRGB(79, 70, 229),
	Red600 = Color3.fromRGB(220, 38, 38),
	Amber400 = Color3.fromRGB(251, 191, 36),
	White = Color3.fromRGB(255, 255, 255),
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

-- ======================================================
-- UI CONSTRUCTION
-- ======================================================

-- 1. ScreenGui & Button
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MissionUI"
screenGui.Enabled = false
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.DisplayOrder = 10

local buttonGui = Instance.new("ScreenGui")
buttonGui.Name = "MissionButton"
buttonGui.ResetOnSpawn = false
buttonGui.Parent = playerGui

local openButton = Instance.new("TextButton")
openButton.Name = "OpenMission"
openButton.Text = "?? Open Missions" -- ENGLISH
openButton.AnchorPoint = Vector2.new(0, 0)
openButton.Size = UDim2.fromOffset(140, 50)
openButton.Position = UDim2.new(0, 20, 0, 20)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 16
openButton.BackgroundColor3 = THEME.Amber400
openButton.TextColor3 = THEME.Slate900
openButton.Parent = buttonGui
Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 8)

-- 2. Modal Main Frame
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = workspace.CurrentCamera

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(700, 500)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Slate900
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", mainFrame).Color = THEME.Slate700
mainFrame.UIStroke.Thickness = 2

-- 3. Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = THEME.Slate800
header.BorderSizePixel = 0
header.Parent = mainFrame
local headerCorner = Instance.new("UICorner", header)
headerCorner.CornerRadius = UDim.new(0, 16)

local titleContainer = Instance.new("Frame")
titleContainer.BackgroundTransparency = 1
titleContainer.Size = UDim2.fromScale(1, 1) -- Full Width
titleContainer.Position = UDim2.fromOffset(0, 0)
titleContainer.Parent = header

-- Removed Icon Construction as requested

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "MISSIONS" -- ENGLISH & UPPERCASE
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 24
titleLabel.TextColor3 = THEME.White
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -20, 0.5, 0)
closeBtn.BackgroundColor3 = THEME.Slate700
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = THEME.White
closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- 4. Tabs
local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "Tabs"
tabsContainer.Size = UDim2.new(1, 0, 0, 60)
tabsContainer.Position = UDim2.new(0, 0, 0, 70)
tabsContainer.BackgroundColor3 = THEME.Slate800
tabsContainer.BorderSizePixel = 0
tabsContainer.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabsLayout.Padding = UDim.new(0, 10)
tabsLayout.Parent = tabsContainer

local function createTabButton(name, text)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.45, 0, 0.7, 0)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.BackgroundColor3 = THEME.Slate700
	btn.TextColor3 = THEME.Slate400
	btn.Parent = tabsContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	return btn
end

local dailyTabBtn = createTabButton("DailyTab", "Daily") -- ENGLISH
local weeklyTabBtn = createTabButton("WeeklyTab", "Weekly") -- ENGLISH

-- 5. Content Area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -40, 1, -150)
contentArea.Position = UDim2.new(0, 20, 0, 140)
contentArea.BackgroundColor3 = THEME.Slate800
contentArea.Parent = mainFrame
Instance.new("UICorner", contentArea).CornerRadius = UDim.new(0, 8)

local contentHeader = Instance.new("Frame")
contentHeader.Name = "ContentHeader"
contentHeader.Size = UDim2.new(1, 0, 0, 50)
contentHeader.BackgroundTransparency = 1
contentHeader.Parent = contentArea

local contentTitle = Instance.new("TextLabel")
contentTitle.Name = "Title"
contentTitle.Text = "Daily Missions" -- ENGLISH
contentTitle.Font = Enum.Font.GothamBold
contentTitle.TextSize = 18
contentTitle.TextColor3 = THEME.White
contentTitle.BackgroundTransparency = 1
contentTitle.Size = UDim2.new(0.5, 0, 1, 0)
contentTitle.Position = UDim2.new(0, 20, 0, 0)
contentTitle.TextXAlignment = Enum.TextXAlignment.Left
contentTitle.Parent = contentHeader

local rerollStatus = Instance.new("TextLabel")
rerollStatus.Name = "RerollStatus"
rerollStatus.Text = "Rerolls Left: 1" -- ENGLISH
rerollStatus.Font = Enum.Font.Gotham
rerollStatus.TextSize = 14
rerollStatus.TextColor3 = THEME.Slate400
rerollStatus.BackgroundTransparency = 1
rerollStatus.Size = UDim2.new(0.5, 0, 1, 0)
rerollStatus.Position = UDim2.new(0.5, -20, 0, 0)
rerollStatus.TextXAlignment = Enum.TextXAlignment.Right
rerollStatus.Parent = contentHeader

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 1, -1)
separator.BackgroundColor3 = THEME.Slate700
separator.BorderSizePixel = 0
separator.Parent = contentHeader

local missionsScroll = Instance.new("ScrollingFrame")
missionsScroll.Name = "MissionsList"
missionsScroll.Size = UDim2.new(1, -20, 1, -60)
missionsScroll.Position = UDim2.new(0, 10, 0, 55)
missionsScroll.BackgroundTransparency = 1
missionsScroll.BorderSizePixel = 0
missionsScroll.ScrollBarThickness = 6
missionsScroll.ScrollBarImageColor3 = THEME.Slate700
missionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
missionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
missionsScroll.Parent = contentArea

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = missionsScroll

-- 6. Toast Container
local toastContainer = Instance.new("Frame")
toastContainer.Name = "ToastContainer"
toastContainer.Size = UDim2.new(0, 300, 1, 0)
toastContainer.Position = UDim2.new(1, -320, 0, 0)
toastContainer.AnchorPoint = Vector2.new(0, 0)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = screenGui

local toastListLayout = Instance.new("UIListLayout")
toastListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastListLayout.Padding = UDim.new(0, 10)
toastListLayout.Parent = toastContainer
Instance.new("UIPadding", toastContainer).PaddingBottom = UDim.new(0, 20)

-- 7. Confirmation Dialog
local confirmOverlay = Instance.new("Frame")
confirmOverlay.Name = "ConfirmOverlay"
confirmOverlay.Size = UDim2.fromScale(1, 1)
confirmOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
confirmOverlay.BackgroundTransparency = 0.5
confirmOverlay.Visible = false
confirmOverlay.ZIndex = 20
confirmOverlay.Parent = screenGui

local confirmFrame = Instance.new("Frame")
confirmFrame.Size = UDim2.fromOffset(320, 180)
confirmFrame.AnchorPoint = Vector2.new(0.5, 0.5)
confirmFrame.Position = UDim2.fromScale(0.5, 0.5)
confirmFrame.BackgroundColor3 = THEME.Slate900
confirmFrame.Parent = confirmOverlay
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", confirmFrame).Color = THEME.Slate700
confirmFrame.UIStroke.Thickness = 2

local confirmTitle = Instance.new("TextLabel")
confirmTitle.Text = "Confirm Reroll" -- ENGLISH
confirmTitle.Font = Enum.Font.GothamBold
confirmTitle.TextSize = 18
confirmTitle.TextColor3 = THEME.White
confirmTitle.BackgroundTransparency = 1
confirmTitle.Size = UDim2.new(1, 0, 0, 40)
confirmTitle.Parent = confirmFrame

local confirmDesc = Instance.new("TextLabel")
confirmDesc.Text = "Are you sure you want to reroll this mission?" -- ENGLISH
confirmDesc.Font = Enum.Font.Gotham
confirmDesc.TextSize = 14
confirmDesc.TextColor3 = THEME.Slate400
confirmDesc.BackgroundTransparency = 1
confirmDesc.Size = UDim2.new(1, -40, 0, 60)
confirmDesc.Position = UDim2.new(0, 20, 0, 40)
confirmDesc.TextWrapped = true
confirmDesc.Parent = confirmFrame

local confirmBtnContainer = Instance.new("Frame")
confirmBtnContainer.Size = UDim2.new(1, -40, 0, 40)
confirmBtnContainer.Position = UDim2.new(0, 20, 1, -60)
confirmBtnContainer.BackgroundTransparency = 1
confirmBtnContainer.Parent = confirmFrame

local confirmListLayout = Instance.new("UIListLayout")
confirmListLayout.FillDirection = Enum.FillDirection.Horizontal
confirmListLayout.Padding = UDim.new(0, 10)
confirmListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
confirmListLayout.Parent = confirmBtnContainer

local btnCancel = Instance.new("TextButton")
btnCancel.Name = "Cancel"
btnCancel.Text = "No" -- ENGLISH
btnCancel.Size = UDim2.new(0.45, 0, 1, 0)
btnCancel.Font = Enum.Font.GothamBold
btnCancel.TextSize = 14
btnCancel.BackgroundColor3 = THEME.Slate700
btnCancel.TextColor3 = THEME.White
btnCancel.Parent = confirmBtnContainer
Instance.new("UICorner", btnCancel).CornerRadius = UDim.new(0, 6)

local btnConfirm = Instance.new("TextButton")
btnConfirm.Name = "Confirm"
btnConfirm.Text = "Yes" -- ENGLISH
btnConfirm.Size = UDim2.new(0.45, 0, 1, 0)
btnConfirm.Font = Enum.Font.GothamBold
btnConfirm.TextSize = 14
btnConfirm.BackgroundColor3 = THEME.Indigo600
btnConfirm.TextColor3 = THEME.White
btnConfirm.Parent = confirmBtnContainer
Instance.new("UICorner", btnConfirm).CornerRadius = UDim.new(0, 6)

-- ======================================================
-- HELPER FUNCTIONS
-- ======================================================

local function createMissionCard(id, missionInfo, type)
	local card = Instance.new("Frame")
	card.Name = id
	card.Size = UDim2.new(1, -10, 0, 100)
	card.BackgroundColor3 = THEME.Slate900
	card.BorderSizePixel = 1
	card.BorderColor3 = THEME.Slate800

	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", card).Color = THEME.Slate800
	card.UIStroke.Thickness = 1

	-- Left Side Info
	local infoContainer = Instance.new("Frame")
	infoContainer.BackgroundTransparency = 1
	infoContainer.Size = UDim2.new(0.65, 0, 1, 0)
	infoContainer.Position = UDim2.new(0, 15, 0, 0)
	infoContainer.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Text = missionInfo.Description
	descLabel.Font = Enum.Font.GothamBold
	descLabel.TextSize = 16
	descLabel.TextColor3 = THEME.White
	descLabel.BackgroundTransparency = 1
	descLabel.Size = UDim2.new(1, 0, 0, 30)
	descLabel.Position = UDim2.new(0, 0, 0, 10)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	descLabel.TextScaled = true
	descLabel.Parent = infoContainer

	local descConstraint = Instance.new("UITextSizeConstraint")
	descConstraint.MaxTextSize = 16
	descConstraint.Parent = descLabel

	local rewardContainer = Instance.new("Frame")
	rewardContainer.BackgroundTransparency = 1
	rewardContainer.Size = UDim2.new(1, 0, 0, 20)
	rewardContainer.Position = UDim2.new(0, 0, 0, 40)
	rewardContainer.Parent = infoContainer

	local mpIcon = Instance.new("ImageLabel")
	mpIcon.BackgroundTransparency = 1
	mpIcon.Size = UDim2.fromOffset(16, 16)
	mpIcon.Image = "rbxassetid://6031243319"
	mpIcon.ImageColor3 = THEME.Amber400
	mpIcon.Parent = rewardContainer

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Text = missionInfo.Reward.Value .. " MP"
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextSize = 14
	rewardLabel.TextColor3 = THEME.Amber400
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Size = UDim2.new(1, -20, 1, 0)
	rewardLabel.Position = UDim2.new(0, 20, 0, 0)
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.Parent = rewardContainer

	-- Progress Bar
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(0.9, 0, 0, 10)
	progressBg.Position = UDim2.new(0, 0, 0, 65)
	progressBg.BackgroundColor3 = THEME.Slate700
	progressBg.Parent = infoContainer
	Instance.new("UICorner", progressBg).CornerRadius = UDim.new(1, 0)

	local progressFill = Instance.new("Frame")
	local pct = math.clamp(missionInfo.Progress / missionInfo.Target, 0, 1)
	progressFill.Size = UDim2.new(pct, 0, 1, 0)
	progressFill.BackgroundColor3 = THEME.Cyan500
	progressFill.Parent = progressBg
	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)

	local progressText = Instance.new("TextLabel")
	progressText.Text = missionInfo.Progress .. " / " .. missionInfo.Target
	progressText.Font = Enum.Font.Gotham
	progressText.TextSize = 12
	progressText.TextColor3 = THEME.Slate400
	progressText.BackgroundTransparency = 1
	progressText.Size = UDim2.new(1, 0, 0, 15)
	progressText.Position = UDim2.new(0, 0, 0, 80)
	progressText.TextXAlignment = Enum.TextXAlignment.Left
	progressText.Parent = infoContainer

	-- Right Side Buttons
	local btnContainer = Instance.new("Frame")
	btnContainer.BackgroundTransparency = 1
	btnContainer.Size = UDim2.new(0.3, 0, 1, 0)
	btnContainer.Position = UDim2.new(0.7, -10, 0, 0)
	btnContainer.Parent = card

	local listLayoutBtn = Instance.new("UIListLayout")
	listLayoutBtn.FillDirection = Enum.FillDirection.Vertical
	listLayoutBtn.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayoutBtn.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayoutBtn.Padding = UDim.new(0, 8)
	listLayoutBtn.Parent = btnContainer

	-- Claim Button Logic
	local claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(1, 0, 0, 35)
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.TextSize = 14
	claimBtn.Parent = btnContainer
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 8)

	if missionInfo.Claimed then
		claimBtn.Text = "? Claimed" -- ENGLISH
		claimBtn.BackgroundColor3 = THEME.Slate700
		claimBtn.TextColor3 = THEME.Slate400
		claimBtn.AutoButtonColor = false
	elseif missionInfo.Completed then
		claimBtn.Text = "Claim" -- ENGLISH
		claimBtn.BackgroundColor3 = THEME.Green600
		claimBtn.TextColor3 = THEME.White
	else
		claimBtn.Text = "In Progress" -- ENGLISH
		claimBtn.BackgroundColor3 = THEME.Slate700
		claimBtn.TextColor3 = THEME.Slate400
		claimBtn.AutoButtonColor = false
	end

	-- Reroll Button Logic
	local rerollUsed = (type == "Daily") and currentMissionData.Daily.RerollUsed or currentMissionData.Weekly.RerollUsed

	local rerollBtn = Instance.new("TextButton")
	rerollBtn.Size = UDim2.new(1, 0, 0, 30)
	rerollBtn.Font = Enum.Font.GothamBold
	rerollBtn.TextSize = 12
	rerollBtn.Text = " ?? Reroll"
	rerollBtn.Parent = btnContainer
	Instance.new("UICorner", rerollBtn).CornerRadius = UDim.new(0, 8)

	if missionInfo.Claimed or rerollUsed then
		rerollBtn.BackgroundColor3 = THEME.Slate700
		rerollBtn.TextColor3 = THEME.Slate400
		rerollBtn.AutoButtonColor = false
	else
		rerollBtn.BackgroundColor3 = THEME.Indigo600
		rerollBtn.TextColor3 = THEME.White
	end

	-- EVENTS
	claimBtn.MouseButton1Click:Connect(function()
		if missionInfo.Completed and not missionInfo.Claimed then
			local success, result = pcall(function() return claimMissionReward:InvokeServer(id) end)
			if success and result.Success then
				-- Optimistic update
				missionInfo.Claimed = true
				claimBtn.Text = "? Claimed" -- ENGLISH
				claimBtn.BackgroundColor3 = THEME.Slate700
				claimBtn.TextColor3 = THEME.Slate400
				claimBtn.AutoButtonColor = false

				rerollBtn.BackgroundColor3 = THEME.Slate700
				rerollBtn.TextColor3 = THEME.Slate400
				rerollBtn.AutoButtonColor = false

				showToast("Success", "You received " .. result.Reward.Value .. " Mission Points!") -- ENGLISH
			else
				warn("Failed to claim: " .. (result and result.Reason or "Unknown"))
			end
		end
	end)

	rerollBtn.MouseButton1Click:Connect(function()
		if not missionInfo.Claimed and not rerollUsed then
			-- Show Confirmation Dialog
			missionToRerollId = id
			missionToRerollType = type
			confirmOverlay.Visible = true
		end
	end)

	return card
end

function showToast(title, message)
	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, 80)
	toast.BackgroundColor3 = (title == "Error") and THEME.Red600 or THEME.Green600
	toast.Parent = toastContainer
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

	local tLabel = Instance.new("TextLabel")
	tLabel.Text = title
	tLabel.Font = Enum.Font.GothamBlack
	tLabel.TextSize = 16
	tLabel.TextColor3 = THEME.White
	tLabel.BackgroundTransparency = 1
	tLabel.Size = UDim2.new(1, -20, 0, 25)
	tLabel.Position = UDim2.new(0, 10, 0, 5)
	tLabel.TextXAlignment = Enum.TextXAlignment.Left
	tLabel.Parent = toast

	local mLabel = Instance.new("TextLabel")
	mLabel.Text = message
	mLabel.Font = Enum.Font.Gotham
	mLabel.TextSize = 14
	mLabel.TextColor3 = THEME.White
	mLabel.BackgroundTransparency = 1
	mLabel.Size = UDim2.new(1, -20, 0, 40)
	mLabel.Position = UDim2.new(0, 10, 0, 30)
	mLabel.TextXAlignment = Enum.TextXAlignment.Left
	mLabel.TextWrapped = true
	mLabel.Parent = toast

	-- Animation
	toast.BackgroundTransparency = 1
	tLabel.TextTransparency = 1
	mLabel.TextTransparency = 1

	local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(toast, ti, {BackgroundTransparency = 0}):Play()
	TweenService:Create(tLabel, ti, {TextTransparency = 0}):Play()
	TweenService:Create(mLabel, ti, {TextTransparency = 0}):Play()

	task.delay(3, function()
		local out = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(toast, out, {BackgroundTransparency = 1}):Play()
		TweenService:Create(tLabel, out, {TextTransparency = 1}):Play()
		TweenService:Create(mLabel, out, {TextTransparency = 1}):Play()
		task.wait(0.5)
		toast:Destroy()
	end)
end

local function populateList()
	if not currentMissionData then return end

	for _, child in ipairs(missionsScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local data = (currentTab == "Daily") and currentMissionData.Daily or currentMissionData.Weekly

	contentTitle.Text = (currentTab == "Daily") and "Daily Missions" or "Weekly Missions" -- ENGLISH
	rerollStatus.Text = "Rerolls Left: " .. (data.RerollUsed and "0" or "1") -- ENGLISH

	local sortedMissions = {}
	for id, info in pairs(data.Missions) do
		table.insert(sortedMissions, {id = id, info = info})
	end

	table.sort(sortedMissions, function(a, b)
		local aState = a.info.Claimed and 3 or (a.info.Completed and 1 or 2)
		local bState = b.info.Claimed and 3 or (b.info.Completed and 1 or 2)
		return aState < bState
	end)

	for _, item in ipairs(sortedMissions) do
		local card = createMissionCard(item.id, item.info, currentTab)
		card.Parent = missionsScroll
	end
end

local function updateTabVisuals()
	if currentTab == "Daily" then
		dailyTabBtn.BackgroundColor3 = THEME.Cyan600
		dailyTabBtn.TextColor3 = THEME.White
		weeklyTabBtn.BackgroundColor3 = THEME.Slate700
		weeklyTabBtn.TextColor3 = THEME.Slate400
	else
		weeklyTabBtn.BackgroundColor3 = THEME.Cyan600
		weeklyTabBtn.TextColor3 = THEME.White
		dailyTabBtn.BackgroundColor3 = THEME.Slate700
		dailyTabBtn.TextColor3 = THEME.Slate400
	end
end

-- ======================================================
-- CONFIRMATION LOGIC
-- ======================================================

btnCancel.MouseButton1Click:Connect(function()
	confirmOverlay.Visible = false
	missionToRerollId = nil
	missionToRerollType = nil
end)

btnConfirm.MouseButton1Click:Connect(function()
	if missionToRerollId and missionToRerollType then
		local success, msg = rerollMission:InvokeServer(missionToRerollType, missionToRerollId)
		if success then
			showToast("Info", "Mission successfully swapped!") -- ENGLISH
		else
			showToast("Error", msg or "Reroll failed.")
		end
	end
	confirmOverlay.Visible = false
	missionToRerollId = nil
	missionToRerollType = nil
end)

-- ======================================================
-- MAIN LOGIC
-- ======================================================

local function openUI()
	local success, result = pcall(function() return getMissionData:InvokeServer() end)
	if not success then
		warn("Failed to fetch mission data")
		return
	end
	currentMissionData = result

	screenGui.Enabled = true
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 20}):Play()

	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 50)
	mainFrame.BackgroundTransparency = 1
	for _, c in ipairs(mainFrame:GetDescendants()) do
		if c:IsA("GuiObject") then c.Visible = false end
	end

	local ti = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local fade = TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0})
	local slide = TweenService:Create(mainFrame, ti, {Position = UDim2.fromScale(0.5, 0.5)})

	fade:Play()
	slide:Play()

	task.wait(0.1)
	for _, c in ipairs(mainFrame:GetDescendants()) do
		if c:IsA("GuiObject") then c.Visible = true end
	end

	updateTabVisuals()
	populateList()
end

local function closeUI()
	local ti = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(blur, ti, {Size = 0}):Play()
	TweenService:Create(mainFrame, ti, {Position = UDim2.new(0.5, 0, 0.5, 50), BackgroundTransparency = 1}):Play()

	task.wait(0.3)
	screenGui.Enabled = false
end

openButton.MouseButton1Click:Connect(openUI)
closeBtn.MouseButton1Click:Connect(closeUI)

dailyTabBtn.MouseButton1Click:Connect(function()
	currentTab = "Daily"
	updateTabVisuals()
	populateList()
end)

weeklyTabBtn.MouseButton1Click:Connect(function()
	currentTab = "Weekly"
	updateTabVisuals()
	populateList()
end)

missionsReset.OnClientEvent:Connect(function()
	if screenGui.Enabled then
		local success, result = pcall(function() return getMissionData:InvokeServer() end)
		if success then
			currentMissionData = result
			populateList()
		end
	end
end)

missionProgressUpdated.OnClientEvent:Connect(function(updateData)
	if screenGui.Enabled and currentMissionData then
		local data = currentMissionData.Daily.Missions[updateData.missionID] and currentMissionData.Daily or currentMissionData.Weekly
		if data.Missions[updateData.missionID] then
			data.Missions[updateData.missionID].Progress = updateData.newProgress
			data.Missions[updateData.missionID].Completed = updateData.completed

			if updateData.justCompleted then
				showToast("Mission Complete!", "Check mission menu to claim reward.") -- ENGLISH
			end

			populateList()
		end
	end
end)

print("MissionUI V2 Loaded")