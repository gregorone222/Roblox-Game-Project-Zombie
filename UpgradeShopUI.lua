-- UpgradeShopUI.lua (LocalScript)
-- Path: StarterGui/UpgradeShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))

local upgradeEvent = RemoteEvents:WaitForChild("UpgradeUIOpen")
local confirmUpgradeEvent = RemoteEvents:WaitForChild("ConfirmUpgrade")

local upgradeRF = RemoteFunctions:WaitForChild("UpgradeWeaponRF")
local getLevelRF = RemoteFunctions:WaitForChild("GetWeaponLevelRF")

local upgradePart = workspace:WaitForChild("Upgrade")

-- Create modern UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false -- Hidden by default

-- Constants for Colors
local COLORS = {
	Background = Color3.fromRGB(15, 23, 42), -- Slate 900
	Panel = Color3.fromRGB(30, 41, 59),      -- Slate 800
	PanelBorder = Color3.fromRGB(51, 65, 85),-- Slate 700
	TextMain = Color3.fromRGB(241, 245, 249),-- Slate 100
	TextDim = Color3.fromRGB(148, 163, 184), -- Slate 400
	Accent = Color3.fromRGB(234, 179, 8),    -- Yellow 500
	Success = Color3.fromRGB(34, 197, 94),   -- Green 500
	Danger = Color3.fromRGB(239, 68, 68),    -- Red 500
	Blue = Color3.fromRGB(59, 130, 246),     -- Blue 500
	Orange = Color3.fromRGB(249, 115, 22),   -- Orange 500
}

local FONTS = {
	Heading = Enum.Font.Michroma, -- Close to prototype (Rajdhani substitute)
	Body = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
}

-- Background overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.BorderSizePixel = 0
overlay.Parent = screenGui

-- Main Container (Glass Panel)
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.new(0, 800, 0, 500)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundColor3 = COLORS.Panel
mainContainer.BackgroundTransparency = 0.1
mainContainer.BorderSizePixel = 0
mainContainer.Parent = overlay

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = mainContainer

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = COLORS.PanelBorder
containerStroke.Thickness = 1
containerStroke.Parent = mainContainer

-- HEADER
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
header.BackgroundTransparency = 0.5
header.BorderSizePixel = 0
header.Parent = mainContainer

local headerPadding = Instance.new("UIPadding")
headerPadding.PaddingLeft = UDim.new(0, 24)
headerPadding.PaddingRight = UDim.new(0, 24)
headerPadding.Parent = header

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
headerLayout.Padding = UDim.new(0, 12)
headerLayout.Parent = header

local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 32, 0, 32)
headerIcon.BackgroundTransparency = 1
headerIcon.Text = "⚡" -- Icon
headerIcon.TextSize = 24
headerIcon.TextColor3 = COLORS.Accent
headerIcon.Font = FONTS.Heading
headerIcon.Parent = header

local headerTitle = Instance.new("TextLabel")
headerTitle.AutomaticSize = Enum.AutomaticSize.X
headerTitle.Size = UDim2.new(0, 0, 1, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "WEAPON UPGRADE"
headerTitle.TextSize = 20
headerTitle.TextColor3 = COLORS.TextMain
headerTitle.Font = FONTS.Bold
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.Parent = header

local headerSub = Instance.new("TextLabel")
headerSub.AutomaticSize = Enum.AutomaticSize.X
headerSub.Size = UDim2.new(0, 0, 1, 0)
headerSub.BackgroundTransparency = 1
headerSub.Text = "STATION TERMINAL V2.0"
headerSub.TextSize = 12
headerSub.TextColor3 = COLORS.TextDim
headerSub.Font = FONTS.Body
headerSub.TextXAlignment = Enum.TextXAlignment.Left
headerSub.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -32, 0.5, -16) -- Manually positioning close button relative to container, not layout
closeButton.AnchorPoint = Vector2.new(0, 0) -- Reset anchor
closeButton.BackgroundTransparency = 1
closeButton.Text = "✕"
closeButton.TextSize = 20
closeButton.TextColor3 = COLORS.TextDim
closeButton.Font = FONTS.Bold
closeButton.Parent = mainContainer -- Parent to container so it ignores header layout

-- Reposition Close Button manually
closeButton.Position = UDim2.new(1, -44, 0, 14)

-- GRID CONTENT
local contentGrid = Instance.new("Frame")
contentGrid.Name = "ContentGrid"
contentGrid.Size = UDim2.new(1, 0, 1, -60)
contentGrid.Position = UDim2.new(0, 0, 0, 60)
contentGrid.BackgroundTransparency = 1
contentGrid.Parent = mainContainer

-- LEFT PANEL (Visuals)
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0.4, 0, 1, 0)
leftPanel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
leftPanel.BackgroundTransparency = 0.5
leftPanel.BorderSizePixel = 0
leftPanel.Parent = contentGrid

local leftStroke = Instance.new("Frame") -- Border right
leftStroke.Size = UDim2.new(0, 1, 1, 0)
leftStroke.Position = UDim2.new(1, -1, 0, 0)
leftStroke.BackgroundColor3 = COLORS.PanelBorder
leftStroke.BorderSizePixel = 0
leftStroke.Parent = leftPanel

local weaponNameDisplay = Instance.new("TextLabel")
weaponNameDisplay.Size = UDim2.new(1, 0, 0, 40)
weaponNameDisplay.Position = UDim2.new(0, 0, 0.1, 0)
weaponNameDisplay.BackgroundTransparency = 1
weaponNameDisplay.Text = "AK-47"
weaponNameDisplay.TextColor3 = COLORS.TextMain
weaponNameDisplay.TextSize = 32
weaponNameDisplay.Font = FONTS.Heading
weaponNameDisplay.Parent = leftPanel

local weaponTypeContainer = Instance.new("Frame")
weaponTypeContainer.Size = UDim2.new(0, 120, 0, 24)
weaponTypeContainer.Position = UDim2.new(0.5, -60, 0.2, 0)
weaponTypeContainer.BackgroundColor3 = COLORS.Panel
weaponTypeContainer.BorderSizePixel = 0
weaponTypeContainer.Parent = leftPanel

local typeCorner = Instance.new("UICorner")
typeCorner.CornerRadius = UDim.new(1, 0)
typeCorner.Parent = weaponTypeContainer

local typeStroke = Instance.new("UIStroke")
typeStroke.Color = COLORS.PanelBorder
typeStroke.Parent = weaponTypeContainer

local weaponTypeLabel = Instance.new("TextLabel")
weaponTypeLabel.Size = UDim2.new(1, 0, 1, 0)
weaponTypeLabel.BackgroundTransparency = 1
weaponTypeLabel.Text = "ASSAULT RIFLE"
weaponTypeLabel.TextColor3 = COLORS.Accent
weaponTypeLabel.TextSize = 10
weaponTypeLabel.Font = FONTS.Bold
weaponTypeLabel.Parent = weaponTypeContainer

local weaponViewport = Instance.new("ViewportFrame")
weaponViewport.Name = "WeaponViewport"
weaponViewport.Size = UDim2.new(1, 0, 0.6, 0)
weaponViewport.Position = UDim2.new(0, 0, 0.25, 0)
weaponViewport.BackgroundTransparency = 1
weaponViewport.Parent = leftPanel

-- Rotation Animation for Viewport
local rotationAngle = 0
RunService.RenderStepped:Connect(function(dt)
	if screenGui.Enabled and weaponViewport.CurrentCamera then
		rotationAngle = rotationAngle + dt * 0.5 -- Rotate speed
		local cam = weaponViewport.CurrentCamera
		-- Assume model is at 0,0,0. Rotate camera around it.
		local distance = 4 -- Adjust distance as needed
		local x = math.sin(rotationAngle) * distance
		local z = math.cos(rotationAngle) * distance
		cam.CFrame = CFrame.lookAt(Vector3.new(x, 1, z), Vector3.new(0, 0, 0))
	end
end)

-- Level Transition
local levelContainer = Instance.new("Frame")
levelContainer.Size = UDim2.new(1, 0, 0, 50)
levelContainer.Position = UDim2.new(0, 0, 0.8, 0)
levelContainer.BackgroundTransparency = 1
levelContainer.Parent = leftPanel

local levelLayout = Instance.new("UIListLayout")
levelLayout.FillDirection = Enum.FillDirection.Horizontal
levelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
levelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
levelLayout.Padding = UDim.new(0, 20)
levelLayout.Parent = levelContainer

local function createLevelDisplay(label, color)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 80, 0, 50)
	f.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 15)
	lbl.BackgroundTransparency = 1
	lbl.Text = label:upper()
	lbl.TextColor3 = COLORS.TextDim
	lbl.TextSize = 10
	lbl.Font = FONTS.Bold
	lbl.Parent = f

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, 0, 0, 30)
	val.Position = UDim2.new(0, 0, 0, 15)
	val.BackgroundTransparency = 1
	val.Text = "LV. 5"
	val.TextColor3 = color
	val.TextSize = 24
	val.Font = FONTS.Heading
	val.Parent = f
	return f, val
end

local currentLvlFrame, currentLvlVal = createLevelDisplay("Current", COLORS.TextMain)
currentLvlFrame.Parent = levelContainer

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(0, 20, 0, 20)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "→"
arrowLabel.TextColor3 = COLORS.TextDim
arrowLabel.TextSize = 24
arrowLabel.Parent = levelContainer

local nextLvlFrame, nextLvlVal = createLevelDisplay("Next", COLORS.Success)
nextLvlFrame.Parent = levelContainer


-- RIGHT PANEL (Stats & Action)
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.6, 0, 1, 0)
rightPanel.Position = UDim2.new(0.4, 0, 0, 0)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = contentGrid

local rightPadding = Instance.new("UIPadding")
rightPadding.PaddingTop = UDim.new(0, 24)
rightPadding.PaddingBottom = UDim.new(0, 24)
rightPadding.PaddingLeft = UDim.new(0, 32)
rightPadding.PaddingRight = UDim.new(0, 32)
rightPadding.Parent = rightPanel

local sectionTitle = Instance.new("TextLabel")
sectionTitle.Size = UDim2.new(1, 0, 0, 20)
sectionTitle.BackgroundTransparency = 1
sectionTitle.Text = "PERFORMANCE ANALYSIS"
sectionTitle.TextColor3 = COLORS.TextDim
sectionTitle.TextSize = 12
sectionTitle.Font = FONTS.Bold
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.Parent = rightPanel

local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 1)
separator.Position = UDim2.new(0, 0, 0, 25)
separator.BackgroundColor3 = COLORS.PanelBorder
separator.BorderSizePixel = 0
separator.Parent = rightPanel

-- Stats Container
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, 0, 0, 200)
statsContainer.Position = UDim2.new(0, 0, 0, 40)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = rightPanel

local statsLayout = Instance.new("UIListLayout")
statsLayout.Padding = UDim.new(0, 16)
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Parent = statsContainer

local function createStatRow(icon, name, barColor, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundTransparency = 1

	-- Header: Icon + Name ... Values
	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 24)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = row

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 20, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = icon
	iconLbl.TextColor3 = barColor
	iconLbl.TextSize = 14
	iconLbl.Parent = headerRow

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 100, 1, 0)
	nameLbl.Position = UDim2.new(0, 24, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = COLORS.TextDim
	nameLbl.TextSize = 14
	nameLbl.Font = FONTS.Bold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = headerRow

	local valContainer = Instance.new("Frame")
	valContainer.Size = UDim2.new(0, 150, 1, 0)
	valContainer.AnchorPoint = Vector2.new(1, 0)
	valContainer.Position = UDim2.new(1, 0, 0, 0)
	valContainer.BackgroundTransparency = 1
	valContainer.Parent = headerRow

	local currentVal = Instance.new("TextLabel")
	currentVal.Size = UDim2.new(0, 40, 1, 0)
	currentVal.Position = UDim2.new(0, 0, 0, 0)
	currentVal.BackgroundTransparency = 1
	currentVal.Text = "28"
	currentVal.TextColor3 = COLORS.TextMain
	currentVal.TextSize = 16
	currentVal.Font = FONTS.Heading
	currentVal.Parent = valContainer

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(0, 45, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "→"
	arrow.TextColor3 = COLORS.TextDim
	arrow.TextSize = 14
	arrow.Parent = valContainer

	local nextVal = Instance.new("TextLabel")
	nextVal.Size = UDim2.new(0, 40, 1, 0)
	nextVal.Position = UDim2.new(0, 70, 0, 0)
	nextVal.BackgroundTransparency = 1
	nextVal.Text = "32"
	nextVal.TextColor3 = COLORS.Success
	nextVal.TextSize = 16
	nextVal.Font = FONTS.Bold
	nextVal.Parent = valContainer

	local diff = Instance.new("TextLabel")
	diff.Size = UDim2.new(0, 40, 1, 0)
	diff.Position = UDim2.new(0, 115, 0, 0)
	diff.BackgroundTransparency = 1
	diff.Text = "(+4)"
	diff.TextColor3 = COLORS.Success
	diff.TextSize = 12
	diff.Parent = valContainer

	-- Bar
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 1, -6)
	barBg.BackgroundColor3 = COLORS.PanelBorder
	barBg.BorderSizePixel = 0
	barBg.Parent = row

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0) -- 50% default
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order or 0

	-- Header: Icon + Name ... Values
	local headerRow = Instance.new("Frame")
	headerRow.Size = UDim2.new(1, 0, 0, 24)
	headerRow.BackgroundTransparency = 1
	headerRow.Parent = row

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 20, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = icon
	iconLbl.TextColor3 = barColor
	iconLbl.TextSize = 14
	iconLbl.Parent = headerRow

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 100, 1, 0)
	nameLbl.Position = UDim2.new(0, 24, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = COLORS.TextDim
	nameLbl.TextSize = 14
	nameLbl.Font = FONTS.Bold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = headerRow

	local valContainer = Instance.new("Frame")
	valContainer.Size = UDim2.new(0, 150, 1, 0)
	valContainer.AnchorPoint = Vector2.new(1, 0)
	valContainer.Position = UDim2.new(1, 0, 0, 0)
	valContainer.BackgroundTransparency = 1
	valContainer.Parent = headerRow

	local currentVal = Instance.new("TextLabel")
	currentVal.Size = UDim2.new(0, 40, 1, 0)
	currentVal.Position = UDim2.new(0, 0, 0, 0)
	currentVal.BackgroundTransparency = 1
	currentVal.Text = "28"
	currentVal.TextColor3 = COLORS.TextMain
	currentVal.TextSize = 16
	currentVal.Font = FONTS.Heading
	currentVal.Parent = valContainer

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(0, 45, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "→"
	arrow.TextColor3 = COLORS.TextDim
	arrow.TextSize = 14
	arrow.Parent = valContainer

	local nextVal = Instance.new("TextLabel")
	nextVal.Size = UDim2.new(0, 40, 1, 0)
	nextVal.Position = UDim2.new(0, 70, 0, 0)
	nextVal.BackgroundTransparency = 1
	nextVal.Text = "32"
	nextVal.TextColor3 = COLORS.Success
	nextVal.TextSize = 16
	nextVal.Font = FONTS.Bold
	nextVal.Parent = valContainer

	local diff = Instance.new("TextLabel")
	diff.Size = UDim2.new(0, 40, 1, 0)
	diff.Position = UDim2.new(0, 115, 0, 0)
	diff.BackgroundTransparency = 1
	diff.Text = "(+4)"
	diff.TextColor3 = COLORS.Success
	diff.TextSize = 12
	diff.Parent = valContainer

	-- Bar
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 1, -6)
	barBg.BackgroundColor3 = COLORS.PanelBorder
	barBg.BorderSizePixel = 0
	barBg.Parent = row

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0) -- 50% default
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	return row, currentVal, nextVal, diff, fill
end

local damageRow, currDmg, nextDmg, diffDmg, barDmg = createStatRow("⚔", "Damage", COLORS.Danger, 1)
damageRow.Parent = statsContainer

local ammoRow, currAmmo, nextAmmo, diffAmmo, barAmmo = createStatRow("🔋", "Ammo Capacity", COLORS.Blue, 2)
ammoRow.Parent = statsContainer

local reloadRow, currRel, nextRel, diffRel, barRel = createStatRow("🔄", "Reload Speed", COLORS.Orange, 3)
reloadRow.Parent = statsContainer

-- Cost & Action
local actionArea = Instance.new("Frame")
actionArea.Size = UDim2.new(1, 0, 0, 140)
actionArea.AnchorPoint = Vector2.new(0, 1)
actionArea.Position = UDim2.new(0, 0, 1, 0)
actionArea.BackgroundTransparency = 1
actionArea.Parent = rightPanel

local costFrame = Instance.new("Frame")
costFrame.Size = UDim2.new(1, 0, 0, 60)
costFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
costFrame.BorderSizePixel = 0
costFrame.Parent = actionArea

local costCorner = Instance.new("UICorner")
costCorner.CornerRadius = UDim.new(0, 12)
costCorner.Parent = costFrame

local costStroke = Instance.new("UIStroke")
costStroke.Color = COLORS.PanelBorder
costStroke.Parent = costFrame

local costLabel = Instance.new("TextLabel")
costLabel.Size = UDim2.new(0.5, 0, 1, 0)
costLabel.Position = UDim2.new(0, 16, 0, 0)
costLabel.BackgroundTransparency = 1
costLabel.Text = "UPGRADE COST\nPOINTS (BP)"
costLabel.TextColor3 = COLORS.TextDim
costLabel.TextSize = 10
costLabel.Font = FONTS.Bold
costLabel.TextXAlignment = Enum.TextXAlignment.Left
costLabel.Parent = costFrame

local costValue = Instance.new("TextLabel")
costValue.Size = UDim2.new(0.5, 0, 1, 0)
costValue.Position = UDim2.new(0.5, -16, 0, 0)
costValue.BackgroundTransparency = 1
costValue.Text = "1,500 BP"
costValue.TextColor3 = COLORS.Accent
costValue.TextSize = 24
costValue.Font = FONTS.Heading
costValue.TextXAlignment = Enum.TextXAlignment.Right
costValue.Parent = costFrame

local buttonsGrid = Instance.new("Frame")
buttonsGrid.Size = UDim2.new(1, 0, 0, 50)
buttonsGrid.Position = UDim2.new(0, 0, 1, -50)
buttonsGrid.BackgroundTransparency = 1
buttonsGrid.Parent = actionArea

local cancelButton = Instance.new("TextButton")
cancelButton.Size = UDim2.new(0.48, 0, 1, 0)
cancelButton.BackgroundColor3 = COLORS.PanelBorder
cancelButton.Text = "CANCEL"
cancelButton.TextColor3 = COLORS.TextMain
cancelButton.Font = FONTS.Bold
cancelButton.TextSize = 14
cancelButton.Parent = buttonsGrid

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 12)
cancelCorner.Parent = cancelButton

local confirmButton = Instance.new("TextButton")
confirmButton.Size = UDim2.new(0.48, 0, 1, 0)
confirmButton.Position = UDim2.new(0.52, 0, 0, 0)
confirmButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Green 500 (Brighter)
confirmButton.Text = "CONFIRM UPGRADE"
confirmButton.TextColor3 = COLORS.TextMain
confirmButton.Font = FONTS.Bold
confirmButton.TextSize = 14
confirmButton.Parent = buttonsGrid

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 12)
confirmCorner.Parent = confirmButton

local confirmGradient = Instance.new("UIGradient")
confirmGradient.Color = ColorSequence.new(Color3.fromRGB(34, 197, 94), Color3.fromRGB(52, 211, 153)) -- Brighter gradient
confirmGradient.Parent = confirmButton

-- Progress Bar Overlay (Inside Action Area)
local progressOverlay = Instance.new("Frame")
progressOverlay.Name = "ProgressOverlay"
progressOverlay.Size = UDim2.new(1, 0, 1, 0)
progressOverlay.BackgroundTransparency = 1
progressOverlay.Visible = false
progressOverlay.Parent = buttonsGrid

local progLabel = Instance.new("TextLabel")
progLabel.Size = UDim2.new(1, 0, 0, 20)
progLabel.Position = UDim2.new(0, 0, -0.5, 0)
progLabel.BackgroundTransparency = 1
progLabel.Text = "INSTALLING UPGRADE..."
progLabel.TextColor3 = COLORS.TextDim
progLabel.TextSize = 12
progLabel.Font = FONTS.Bold
progLabel.Parent = progressOverlay

local progBarBg = Instance.new("Frame")
progBarBg.Size = UDim2.new(1, 0, 0, 20)
progBarBg.Position = UDim2.new(0, 0, 0.2, 0)
progBarBg.BackgroundColor3 = COLORS.PanelBorder
progBarBg.BorderSizePixel = 0
progBarBg.Parent = progressOverlay

local progBarCorner = Instance.new("UICorner")
progBarCorner.CornerRadius = UDim.new(1, 0)
progBarCorner.Parent = progBarBg

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = COLORS.Success
progFill.BorderSizePixel = 0
progFill.Parent = progBarBg

local progFillCorner = Instance.new("UICorner")
progFillCorner.CornerRadius = UDim.new(1, 0)
progFillCorner.Parent = progFill


-- Logic Variables
local currentTool = nil
local upgradeData = nil
local isUIOpen = false

-- Functions

local function calculateDamage(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local baseDamage = weaponStats.Damage or 0
	local cfg = weaponStats.UpgradeConfig or {}
	local damagePerLevel = cfg.DamagePerLevel or 5
	return baseDamage + (damagePerLevel * level)
end

local function calculateAmmo(weaponName, level)
	-- Assumes weapon has base ammo. Logic might need tweaking if level affects ammo.
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	return weaponStats.MaxAmmo or 30
end

local function calculateReload(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	return weaponStats.ReloadTime or 2
end

local function updateStats(weaponName, currentLevel, nextLevel)
	-- Damage
	local cDmg = calculateDamage(weaponName, currentLevel)
	local nDmg = calculateDamage(weaponName, nextLevel)
	currDmg.Text = tostring(cDmg)
	nextDmg.Text = tostring(nDmg)
	diffDmg.Text = "(+" .. (nDmg - cDmg) .. ")"
	-- Visual Bar (Assuming 100 max damage for visual scaling)
	barDmg.Size = UDim2.new(math.clamp(cDmg / 100, 0.1, 1), 0, 1, 0)

	-- Ammo
	-- Currently ammo doesn't scale with level in previous logic except a +50% conditional
	-- I will use static values for now unless logic exists
	local cAmmo = calculateAmmo(weaponName, currentLevel)
	currAmmo.Text = tostring(cAmmo)
	nextAmmo.Text = tostring(cAmmo) -- Placeholder if no change
	diffAmmo.Text = ""
	barAmmo.Size = UDim2.new(math.clamp(cAmmo / 100, 0.1, 1), 0, 1, 0)

	if currentLevel == 0 then -- Logic from old script: level 0 -> 1 might give ammo?
		-- Old script said: calculateAmmoIncrease(level) -> if level == 0 then return 50 end
		-- So if current is 0, next is 1, so +50% ammo?
		-- Visualizing that might be complex if dynamic. I will keep it simple.
		nextAmmo.Text = tostring(math.floor(cAmmo * 1.5))
		diffAmmo.Text = "(+50%)"
	end

	-- Reload
	local cRel = calculateReload(weaponName, currentLevel)
	currRel.Text = cRel .. "s"
	nextRel.Text = cRel .. "s"
	diffRel.Text = ""
	barRel.Size = UDim2.new(math.clamp(1 - (cRel / 5), 0.1, 1), 0, 1, 0) -- Inverse bar (faster is better)
end

local function setBackpackVisible(visible)
	-- Only for mobile usually
	if UserInputService.TouchEnabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
	end
end

local function closeUpgradeUI()
	if not isUIOpen then return end
	setBackpackVisible(true)

	-- Animation
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.6, 0),
		BackgroundTransparency = 1
	})
	tween:Play()
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	overlayTween:Play()

	task.wait(0.3)
	screenGui.Enabled = false
	isUIOpen = false
end

local function performUpgrade()
	if not currentTool or not upgradeData then return end

	-- UI State
	cancelButton.Visible = false
	confirmButton.Visible = false
	progressOverlay.Visible = true
	progFill.Size = UDim2.new(0, 0, 1, 0)
	progLabel.Text = "INSTALLING UPGRADE... 0%"

	-- Custom loop for progress bar and percentage text
	local duration = 1.5
	local startTime = tick()
	while tick() - startTime < duration do
		local alpha = (tick() - startTime) / duration
		alpha = math.clamp(alpha, 0, 1)

		progFill.Size = UDim2.new(alpha, 0, 1, 0)
		progLabel.Text = "INSTALLING UPGRADE... " .. math.floor(alpha * 100) .. "%"

		RunService.RenderStepped:Wait()
	end

	-- Ensure 100% at the end
	progFill.Size = UDim2.new(1, 0, 1, 0)
	progLabel.Text = "INSTALLING UPGRADE... 100%"
	task.wait(0.2)

	confirmUpgradeEvent:FireServer(currentTool, true)

	-- Reset State
	progressOverlay.Visible = false
	cancelButton.Visible = true
	confirmButton.Visible = true

	closeUpgradeUI()
end

local function updateWeaponPreview(tool)
	weaponViewport:ClearAllChildren()
	if not tool then return end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = weaponViewport

	local model = tool:Clone()
	model.Parent = worldModel

	-- Strip scripts and unrelated parts for the preview
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") then
			v:Destroy()
		end
		if v:IsA("BasePart") then
			v.Anchored = true -- Fix for invisible model
		end
	end

	local handle = model:FindFirstChild("Handle") or model:FindFirstChild("PrimaryPart")
	if not handle then
		-- Fallback to finding any part
		handle = model:FindFirstChildWhichIsA("BasePart")
	end

	if handle then
		-- Setup Camera
		local cam = Instance.new("Camera")
		cam.Parent = weaponViewport
		weaponViewport.CurrentCamera = cam

		-- Position Model at 0,0,0
		if model:IsA("Model") then
			if not model.PrimaryPart then
				model.PrimaryPart = handle
			end
			if model.PrimaryPart then
				model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
			else
				-- Last resort if PrimaryPart can't be set
				handle.CFrame = CFrame.new(0, 0, 0)
			end
		elseif model:IsA("BasePart") then
			model.CFrame = CFrame.new(0, 0, 0)
		end

		-- Initial Camera Pos
		cam.CFrame = CFrame.lookAt(Vector3.new(3, 1, 3), Vector3.new(0, 0, 0))
	end
end

local function showUpgradeUI(tool, data)
	if isUIOpen then return end
	isUIOpen = true
	screenGui.Enabled = true
	setBackpackVisible(false)

	currentTool = tool
	upgradeData = data

	-- Update Info
	weaponNameDisplay.Text = data.weaponName:upper()

	updateWeaponPreview(tool)

	-- Try to get weapon type
	local weaponStats = WeaponModule.Weapons[data.weaponName]
	local wType = "WEAPON"
	if weaponStats and weaponStats.Category then
		wType = weaponStats.Category:upper()
	end
	weaponTypeLabel.Text = wType

	-- Update Levels
	currentLvlVal.Text = "LV. " .. data.currentLevel
	nextLvlVal.Text = "LV. " .. data.nextLevel

	-- Update Stats
	updateStats(data.weaponName, data.currentLevel, data.nextLevel)

	-- Update Cost
	costValue.Text = tostring(data.cost) .. " BP"
	if data.hasDiscount then
		costValue.TextColor3 = COLORS.Success
	else
		costValue.TextColor3 = COLORS.Accent
	end

	-- Animation In
	mainContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
	mainContainer.BackgroundTransparency = 1
	overlay.BackgroundTransparency = 1

	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.1
	})
	tween:Play()

	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.6})
	overlayTween:Play()
end

-- Event Connections
closeButton.MouseButton1Click:Connect(closeUpgradeUI)
cancelButton.MouseButton1Click:Connect(closeUpgradeUI)
confirmButton.MouseButton1Click:Connect(performUpgrade)

upgradeEvent.OnClientEvent:Connect(function(weaponName, newLevel)
	-- Notification logic could go here
	-- For now we just close UI on successful upgrade in performUpgrade,
	-- but this event is for confirmation.
end)

-- Interaction Logic (Proximity Prompt)
local ProximityPromptService = game:GetService("ProximityPromptService")
-- Assuming the prompt exists in workspace
task.spawn(function()
	local upgradePrompt = nil
	-- Wait for it safely
	local upgPart = workspace:WaitForChild("Upgrade", 10)
	if upgPart then
		local att = upgPart:WaitForChild("Attachment", 10)
		if att then
			upgradePrompt = att:WaitForChild("UpgradePrompt", 10)
		end
	end

	if upgradePrompt then
		ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
			if prompt ~= upgradePrompt or plr ~= player then return end
			if isUIOpen then return end

			local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
			if not equippedTool then
				-- Notification: "Equip a weapon first!"
				return
			end

			local ok, result = pcall(function()
				return upgradeRF:InvokeServer(equippedTool)
			end)

			if ok and result.success then
				showUpgradeUI(equippedTool, result)
			end
		end)
	end
end)

-- Mobile/Responsive check
local function updateLayout()
	if screenGui.AbsoluteSize.X < 600 then
		-- Mobile layout adjustments
		mainContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
		-- Stack columns
		contentGrid.Position = UDim2.new(0, 0, 0, 50)
		leftPanel.Size = UDim2.new(1, 0, 0.3, 0)
		rightPanel.Size = UDim2.new(1, 0, 0.7, 0)
		rightPanel.Position = UDim2.new(0, 0, 0.3, 0)

		weaponViewport.Visible = false -- Hide icon to save space
		weaponNameDisplay.TextSize = 24

		leftStroke.Visible = false -- Remove divider
	else
		-- Desktop layout
		mainContainer.Size = UDim2.new(0, 800, 0, 500)
		leftPanel.Size = UDim2.new(0.4, 0, 1, 0)
		rightPanel.Size = UDim2.new(0.6, 0, 1, 0)
		rightPanel.Position = UDim2.new(0.4, 0, 0, 0)

		weaponViewport.Visible = true
		weaponNameDisplay.TextSize = 32
		leftStroke.Visible = true
	end
end

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout() -- Initial call
