-- UpgradeShopUI.lua (LocalScript)
-- Path: StarterGui/UpgradeShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ProximityUIHandler = require(ModuleScriptReplicatedStorage:WaitForChild("ProximityUIHandler"))

local proximityHandler -- Forward declaration

local upgradeEvent = RemoteEvents:WaitForChild("UpgradeUIOpen")
local confirmUpgradeEvent = RemoteEvents:WaitForChild("ConfirmUpgrade")

local upgradeRF = RemoteFunctions:WaitForChild("UpgradeWeaponRF")

-- Create modern UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false -- Hidden by default

-- Blur Effect
local camera = workspace.CurrentCamera
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "UpgradeBlur"
blurEffect.Size = 0
blurEffect.Enabled = false
blurEffect.Parent = camera

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
	Heading = Enum.Font.Michroma, -- Sci-fi heading
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
mainContainer.Size = UDim2.new(0, 500, 0, 600) -- Taller and narrower for a unified card look
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.BackgroundColor3 = COLORS.Panel
mainContainer.BackgroundTransparency = 0.05
mainContainer.BorderSizePixel = 0
mainContainer.Parent = overlay

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = mainContainer

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = COLORS.PanelBorder
containerStroke.Thickness = 2
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

-- REMOVED headerLayout and headerIcon

local headerTitle = Instance.new("TextLabel")
headerTitle.AutomaticSize = Enum.AutomaticSize.None -- Changed
headerTitle.Size = UDim2.new(1, 0, 1, 0) -- Fill header
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "WEAPON UPGRADE"
headerTitle.TextSize = 20
headerTitle.TextColor3 = COLORS.TextMain
headerTitle.Font = FONTS.Bold
headerTitle.TextXAlignment = Enum.TextXAlignment.Center -- Centered
headerTitle.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -44, 0, 14)
closeButton.BackgroundTransparency = 1
closeButton.Text = "X"
closeButton.TextSize = 24
closeButton.TextColor3 = COLORS.TextDim
closeButton.Font = FONTS.Bold
closeButton.Parent = mainContainer

-- CONTENT GRID (Unified Vertical Flow)
local contentGrid = Instance.new("Frame")
contentGrid.Name = "ContentGrid"
contentGrid.Size = UDim2.new(1, 0, 1, -60)
contentGrid.Position = UDim2.new(0, 0, 0, 60)
contentGrid.BackgroundTransparency = 1
contentGrid.Parent = mainContainer

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 24)
contentPadding.PaddingBottom = UDim.new(0, 24)
contentPadding.PaddingLeft = UDim.new(0, 32)
contentPadding.PaddingRight = UDim.new(0, 32)
contentPadding.Parent = contentGrid

local contentLayout = Instance.new("UIListLayout")
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.Padding = UDim.new(0, 16)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentGrid

-- 1. WEAPON INFO SECTION (Centered)
local weaponInfoFrame = Instance.new("Frame")
weaponInfoFrame.Name = "WeaponInfo"
weaponInfoFrame.LayoutOrder = 1
weaponInfoFrame.Size = UDim2.new(1, 0, 0, 80)
weaponInfoFrame.BackgroundTransparency = 1
weaponInfoFrame.Parent = contentGrid

local weaponNameDisplay = Instance.new("TextLabel")
weaponNameDisplay.Size = UDim2.new(1, 0, 0, 40)
weaponNameDisplay.Position = UDim2.new(0, 0, 0, 0)
weaponNameDisplay.BackgroundTransparency = 1
weaponNameDisplay.Text = "AK-47"
weaponNameDisplay.TextColor3 = COLORS.TextMain
weaponNameDisplay.TextSize = 36
weaponNameDisplay.Font = FONTS.Heading
weaponNameDisplay.Parent = weaponInfoFrame

local weaponTypeContainer = Instance.new("Frame")
weaponTypeContainer.Size = UDim2.new(0, 140, 0, 24)
weaponTypeContainer.AnchorPoint = Vector2.new(0.5, 0)
weaponTypeContainer.Position = UDim2.new(0.5, 0, 0, 48)
weaponTypeContainer.BackgroundColor3 = COLORS.Panel
weaponTypeContainer.BorderSizePixel = 0
weaponTypeContainer.Parent = weaponInfoFrame

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
weaponTypeLabel.TextSize = 11
weaponTypeLabel.Font = FONTS.Bold
weaponTypeLabel.Parent = weaponTypeContainer

-- 2. LEVEL TRANSITION SECTION
local levelContainer = Instance.new("Frame")
levelContainer.Name = "LevelInfo"
levelContainer.LayoutOrder = 2
levelContainer.Size = UDim2.new(1, 0, 0, 60)
levelContainer.BackgroundTransparency = 1
levelContainer.Parent = contentGrid

local levelLayout = Instance.new("UIListLayout")
levelLayout.FillDirection = Enum.FillDirection.Horizontal
levelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
levelLayout.VerticalAlignment = Enum.VerticalAlignment.Center
levelLayout.Padding = UDim.new(0, 30)
levelLayout.SortOrder = Enum.SortOrder.LayoutOrder -- Added
levelLayout.Parent = levelContainer

local function createLevelDisplay(label, color)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 100, 0, 50)
	f.BackgroundTransparency = 1

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 15)
	lbl.BackgroundTransparency = 1
	lbl.Text = label:upper()
	lbl.TextColor3 = COLORS.TextDim
	lbl.TextSize = 11
	lbl.Font = FONTS.Bold
	lbl.Parent = f

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(1, 0, 0, 35)
	val.Position = UDim2.new(0, 0, 0, 15)
	val.BackgroundTransparency = 1
	val.Text = "LV. 5"
	val.TextColor3 = color
	val.TextSize = 28
	val.Font = FONTS.Heading
	val.Parent = f
	return f, val
end

local currentLvlFrame, currentLvlVal = createLevelDisplay("Current", COLORS.TextMain)
currentLvlFrame.LayoutOrder = 1
currentLvlFrame.Parent = levelContainer

local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(0, 20, 0, 20)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "→"
arrowLabel.TextColor3 = COLORS.TextDim
arrowLabel.TextSize = 24
arrowLabel.LayoutOrder = 2
arrowLabel.Parent = levelContainer

local nextLvlFrame, nextLvlVal = createLevelDisplay("Next", COLORS.Success)
nextLvlFrame.LayoutOrder = 3
nextLvlFrame.Parent = levelContainer

-- 3. STATS SECTION
local statsContainer = Instance.new("Frame")
statsContainer.Name = "Stats"
statsContainer.LayoutOrder = 3
statsContainer.Size = UDim2.new(1, 0, 0, 200)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = contentGrid

-- Background for Stats (Parented to container, not affected by list layout inside content)
local statsBg = Instance.new("Frame")
statsBg.Size = UDim2.new(1, 40, 1, 20) -- Negative margins visual
statsBg.Position = UDim2.new(0, -20, 0, -10)
statsBg.BackgroundColor3 = Color3.new(0,0,0)
statsBg.BackgroundTransparency = 0.8
statsBg.BorderSizePixel = 0
statsBg.ZIndex = 1
statsBg.Parent = statsContainer

local statsBgCorner = Instance.new("UICorner")
statsBgCorner.CornerRadius = UDim.new(0, 8)
statsBgCorner.Parent = statsBg

-- Inner frame for ListLayout to avoid affecting the background
local statsListFrame = Instance.new("Frame")
statsListFrame.Name = "StatsList"
statsListFrame.Size = UDim2.new(1, 0, 1, 0)
statsListFrame.BackgroundTransparency = 1
statsListFrame.ZIndex = 2
statsListFrame.Parent = statsContainer

local statsLayoutList = Instance.new("UIListLayout")
statsLayoutList.Padding = UDim.new(0, 12)
statsLayoutList.SortOrder = Enum.SortOrder.LayoutOrder
statsLayoutList.VerticalAlignment = Enum.VerticalAlignment.Center
statsLayoutList.Parent = statsListFrame

local function createStatRow(icon, name, barColor, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.ZIndex = 2

	-- Header: Icon + Name ... Values
	-- Removed intermediate headerRow to simplify layout calculation

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 24, 0, 24)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = icon
	iconLbl.TextColor3 = barColor
	iconLbl.TextSize = 16
	iconLbl.ZIndex = 3
	iconLbl.Parent = row

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0, 120, 0, 24)
	nameLbl.Position = UDim2.new(0, 30, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = COLORS.TextDim
	nameLbl.TextSize = 14
	nameLbl.Font = FONTS.Bold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 3
	nameLbl.Parent = row

	local valContainer = Instance.new("Frame")
	valContainer.Size = UDim2.new(0, 150, 0, 24)
	valContainer.AnchorPoint = Vector2.new(1, 0)
	valContainer.Position = UDim2.new(1, 0, 0, 0) -- Right aligned to the row (width 100%)
	valContainer.BackgroundTransparency = 1
	valContainer.ZIndex = 3
	valContainer.Parent = row

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

	return row, currentVal, nextVal, diff, fill, nameLbl
end

local damageRow, currDmg, nextDmg, diffDmg, barDmg = createStatRow("⚔", "Damage", COLORS.Danger, 1)
damageRow.Parent = statsListFrame

local ammoRow, currAmmo, nextAmmo, diffAmmo, barAmmo, ammoLbl = createStatRow("🔋", "Ammo Capacity", COLORS.Blue, 2)
ammoRow.Parent = statsListFrame

local reloadRow, currRel, nextRel, diffRel, barRel = createStatRow("🎯", "Recoil", COLORS.Orange, 3)
reloadRow.Parent = statsListFrame


-- 4. ACTION AREA
local actionArea = Instance.new("Frame")
actionArea.Name = "ActionArea"
actionArea.LayoutOrder = 4
actionArea.Size = UDim2.new(1, 0, 0, 120)
actionArea.BackgroundTransparency = 1
actionArea.Parent = contentGrid

local costFrame = Instance.new("Frame")
costFrame.Size = UDim2.new(1, 0, 0, 50)
costFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
costFrame.BorderSizePixel = 0
costFrame.Parent = actionArea

local costCorner = Instance.new("UICorner")
costCorner.CornerRadius = UDim.new(0, 8)
costCorner.Parent = costFrame

local costStroke = Instance.new("UIStroke")
costStroke.Color = COLORS.PanelBorder
costStroke.Parent = costFrame

local costLabel = Instance.new("TextLabel")
costLabel.Size = UDim2.new(0.5, 0, 1, 0)
costLabel.Position = UDim2.new(0, 16, 0, 0)
costLabel.BackgroundTransparency = 1
costLabel.Text = "UPGRADE COST (BP)"
costLabel.TextColor3 = COLORS.TextDim
costLabel.TextSize = 10
costLabel.Font = FONTS.Bold
costLabel.TextXAlignment = Enum.TextXAlignment.Left
costLabel.Parent = costFrame

local costValue = Instance.new("TextLabel")
costValue.Size = UDim2.new(0.5, 0, 1, 0)
costValue.Position = UDim2.new(0.5, -16, 0, 0)
costValue.BackgroundTransparency = 1
costValue.Text = "1,500"
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
cancelButton.Size = UDim2.new(0.4, 0, 1, 0)
cancelButton.BackgroundColor3 = COLORS.PanelBorder
cancelButton.Text = "CANCEL"
cancelButton.TextColor3 = COLORS.TextMain
cancelButton.Font = FONTS.Bold
cancelButton.TextSize = 14
cancelButton.Parent = buttonsGrid

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 8)
cancelCorner.Parent = cancelButton

local cancelStroke = Instance.new("UIStroke")
cancelStroke.Thickness = 3
cancelStroke.Color = COLORS.Accent
cancelStroke.Transparency = 1
cancelStroke.Parent = cancelButton

local confirmButton = Instance.new("TextButton")
confirmButton.Size = UDim2.new(0.55, 0, 1, 0)
confirmButton.Position = UDim2.new(0.45, 0, 0, 0)
confirmButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Reverted to Green 500
confirmButton.Text = "UPGRADE"
confirmButton.TextColor3 = COLORS.TextMain
confirmButton.Font = FONTS.Bold
confirmButton.TextSize = 14
confirmButton.Parent = buttonsGrid

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 8)
confirmCorner.Parent = confirmButton

local confirmStroke = Instance.new("UIStroke")
confirmStroke.Thickness = 3
confirmStroke.Color = COLORS.Accent
confirmStroke.Transparency = 1
confirmStroke.Parent = confirmButton

local confirmGradient = Instance.new("UIGradient")
confirmGradient.Color = ColorSequence.new(Color3.fromRGB(34, 197, 94), Color3.fromRGB(52, 211, 153)) -- Reverted Gradient
confirmGradient.Parent = confirmButton

-- Progress Bar Overlay (Inside Action Area)
local progressOverlay = Instance.new("Frame")
progressOverlay.Name = "ProgressOverlay"
progressOverlay.Size = UDim2.new(1, 0, 1, 0)
progressOverlay.Position = UDim2.new(0,0,0,-10) -- Shift up slightly
progressOverlay.BackgroundTransparency = 1
progressOverlay.Visible = false
progressOverlay.Parent = buttonsGrid

local progLabel = Instance.new("TextLabel")
progLabel.Size = UDim2.new(1, 0, 0, 20)
progLabel.Position = UDim2.new(0, 0, 0, 0) -- Align to top of container
progLabel.BackgroundTransparency = 1
progLabel.Text = "INSTALLING UPGRADE..."
progLabel.TextColor3 = COLORS.TextDim
progLabel.TextSize = 12
progLabel.Font = FONTS.Bold
progLabel.Parent = progressOverlay

local progBarBg = Instance.new("Frame")
progBarBg.Size = UDim2.new(1, 0, 0, 20)
progBarBg.AnchorPoint = Vector2.new(0, 1)
progBarBg.Position = UDim2.new(0, 0, 1, 0) -- Align to bottom of container
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
local distanceConnection = nil
local selectedButtonIndex = 2 -- 1=Cancel, 2=Upgrade
local isUpgrading = false
local feedbackToken = 0

-- Functions

local function calculateDamage(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local baseDamage = weaponStats.Damage or 0
	local cfg = weaponStats.UpgradeConfig or {}
	local damagePerLevel = cfg.DamagePerLevel or 5
	return baseDamage + (damagePerLevel * level)
end

local function calculateMag(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local baseAmmo = weaponStats.MaxAmmo or 30
	if level >= 1 then
		return math.floor(baseAmmo * 1.5)
	end
	return baseAmmo
end

local function calculateReserve(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local baseReserve = weaponStats.ReserveAmmo or 120

	local cfg = weaponStats.UpgradeConfig
	local ammoPerLevel = cfg and cfg.AmmoPerLevel or 0

	-- Reserve increases starting from level 2 (upgrade from 1->2)
	-- So level 0 and 1 have base reserve.
	-- Level 2 has base + 1*inc
	local bonus = math.max(0, level - 1) * ammoPerLevel
	return baseReserve + bonus
end

local function calculateRecoil(weaponName, level)
	local weaponStats = WeaponModule.Weapons[weaponName]
	if not weaponStats then return 0 end
	local base = weaponStats.Recoil or 1
	local final = base - (level * 0.1)
	return math.max(0, final)
end

local function updateStats(weaponName, currentLevel, nextLevel)
	-- Damage
	local cDmg = calculateDamage(weaponName, currentLevel)
	local nDmg = calculateDamage(weaponName, nextLevel)
	currDmg.Text = tostring(cDmg)
	nextDmg.Text = tostring(nDmg)
	diffDmg.Text = "(+" .. (nDmg - cDmg) .. ")"
	-- Visual Bar (Assuming 150 max damage for visual scaling)
	barDmg.Size = UDim2.new(math.clamp(cDmg / 150, 0.1, 1), 0, 1, 0)

	-- Ammo
	if currentLevel == 0 then
		ammoLbl.Text = "Ammo Capacity"
		local cMag = calculateMag(weaponName, currentLevel)
		local nMag = calculateMag(weaponName, nextLevel)
		currAmmo.Text = tostring(cMag)
		nextAmmo.Text = tostring(nMag)
		diffAmmo.Text = "(+50%)"
		barAmmo.Size = UDim2.new(math.clamp(cMag / 100, 0.1, 1), 0, 1, 0)
	else
		ammoLbl.Text = "Ammo Reserve"
		local cRes = calculateReserve(weaponName, currentLevel)
		local nRes = calculateReserve(weaponName, nextLevel)
		currAmmo.Text = tostring(cRes)
		nextAmmo.Text = tostring(nRes)
		local diff = nRes - cRes
		if diff > 0 then
			diffAmmo.Text = "(+" .. diff .. ")"
		else
			diffAmmo.Text = ""
		end
		-- Scale reserve bar differently (assuming max ~500)
		barAmmo.Size = UDim2.new(math.clamp(cRes / 500, 0.1, 1), 0, 1, 0)
	end

	-- Recoil
	local cRec = calculateRecoil(weaponName, currentLevel)
	local nRec = calculateRecoil(weaponName, nextLevel)

	-- Format with 1 decimal place
	currRel.Text = string.format("%.1f", cRec)
	nextRel.Text = string.format("%.1f", nRec)
	diffRel.Text = ""

	-- Visual Bar for Recoil (Lower is better, so 1 - (recoil / max_recoil))
	-- Assuming max recoil around 10 for visualization scaling
	barRel.Size = UDim2.new(math.clamp(1 - (cRec / 10), 0.1, 1), 0, 1, 0)
end

local function setBackpackVisible(visible)
	if UserInputService.TouchEnabled then
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
		end)
	end
end

local function closeUpgradeUI()
	if not isUIOpen then return end

	if distanceConnection then
		distanceConnection:Disconnect()
		distanceConnection = nil
	end

	setBackpackVisible(true)

	isUpgrading = false

	-- Animation Out
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.6, 0),
		BackgroundTransparency = 1
	})
	tween:Play()
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	overlayTween:Play()

	-- Disable Blur
	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.3, function() blurEffect.Enabled = false end)
	end

	task.wait(0.3)
	screenGui.Enabled = false
	isUIOpen = false

	-- Sync handler state
	if proximityHandler then
		proximityHandler:SetOpen(false)
	end
end

local function startDistanceCheck()
	if distanceConnection then distanceConnection:Disconnect() end
	local upgPart = workspace:WaitForChild("Upgrade", 2) -- Short timeout
	if not upgPart then return end -- Should exist if prompt triggered

	distanceConnection = RunService.RenderStepped:Connect(function()
		if not isUIOpen or not player.Character then return end
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local dist = (root.Position - upgPart.Position).Magnitude
		if dist > 5 then -- 5 stud limit
			closeUpgradeUI()
		end
	end)
end

local function refreshUpgradeData()
	if not currentTool then return end

	-- Silent fetch
	task.spawn(function()
		local ok, result = pcall(function()
			return upgradeRF:InvokeServer(currentTool)
		end)

		if ok and result.success then
			upgradeData = result
			-- Refresh UI elements
			currentLvlVal.Text = "LV. " .. result.currentLevel
			nextLvlVal.Text = "LV. " .. result.nextLevel
			updateStats(result.weaponName, result.currentLevel, result.nextLevel)

			costValue.Text = tostring(result.cost)
			if result.hasDiscount then
				costValue.TextColor3 = COLORS.Success
			else
				costValue.TextColor3 = COLORS.Accent
			end
		else
			-- If max level or error, close
			if result and result.message == "Sudah level maksimal" then
				closeUpgradeUI()
			end
		end
	end)
end

local function updateButtonSelection()
	if not isUIOpen then return end
	cancelStroke.Transparency = (selectedButtonIndex == 1) and 0 or 1
	confirmStroke.Transparency = (selectedButtonIndex == 2) and 0 or 1
end

local function performUpgrade()
	if not currentTool or not upgradeData then return end
	if isUpgrading then return end

	-- Check BP
	local currentBP = 0
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("BP") then
		currentBP = player.leaderstats.BP.Value
	end

	if currentBP < upgradeData.cost then
		-- Feedback
		feedbackToken = feedbackToken + 1
		local myToken = feedbackToken

		confirmButton.Text = "NOT ENOUGH BP"
		confirmButton.TextColor3 = COLORS.Danger
		confirmButton.BackgroundColor3 = Color3.fromRGB(50, 20, 20)

		task.delay(3, function()
			if feedbackToken == myToken then
				if confirmButton then
					confirmButton.Text = "UPGRADE"
					confirmButton.TextColor3 = COLORS.TextMain
					confirmButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Reverted
				end
			end
		end)
		return
	end

	isUpgrading = true

	-- UI State
	cancelButton.Visible = false
	confirmButton.Visible = false
	progressOverlay.Visible = true
	progFill.Size = UDim2.new(0, 0, 1, 0)
	progLabel.Text = "INSTALLING UPGRADE... 0%"

	-- Progress Animation
	local duration = 1.0
	local startTime = tick()
	while tick() - startTime < duration do
		local alpha = (tick() - startTime) / duration
		alpha = math.clamp(alpha, 0, 1)

		progFill.Size = UDim2.new(alpha, 0, 1, 0)
		progLabel.Text = "INSTALLING UPGRADE... " .. math.floor(alpha * 100) .. "%"

		RunService.RenderStepped:Wait()
	end

	-- Check if still open
	if not isUIOpen then
		isUpgrading = false
		return
	end

	-- Finish
	progFill.Size = UDim2.new(1, 0, 1, 0)
	progLabel.Text = "INSTALLING UPGRADE... 100%"
	task.wait(0.2)

	confirmUpgradeEvent:FireServer(currentTool, true)
	-- DO NOT CLOSE UI HERE
end

local function showUpgradeUI(tool, data)
	if isUIOpen then return end

	feedbackToken = feedbackToken + 1 -- Cancel any pending feedback reset

	isUIOpen = true
	isUpgrading = false

	startDistanceCheck() -- Start monitoring

	screenGui.Enabled = true
	setBackpackVisible(false)

	-- Enable Blur
	if blurEffect then
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(0.4), {Size = 15}):Play()
	end

	currentTool = tool
	upgradeData = data

	-- Reset button selection
	selectedButtonIndex = 2
	updateButtonSelection()

	-- Reset feedback state immediately
	confirmButton.Text = "UPGRADE"
	confirmButton.TextColor3 = COLORS.TextMain
	confirmButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Reverted
	confirmButton.Visible = true
	cancelButton.Visible = true
	progressOverlay.Visible = false

	-- Update Info
	weaponNameDisplay.Text = data.weaponName:upper()

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
	costValue.Text = tostring(data.cost)
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
		BackgroundTransparency = 0.05
	})
	tween:Play()

	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 0.6})
	overlayTween:Play()
end

-- Event Connections
closeButton.MouseButton1Click:Connect(closeUpgradeUI)
cancelButton.MouseButton1Click:Connect(closeUpgradeUI)
confirmButton.MouseButton1Click:Connect(performUpgrade)

UserInputService.InputBegan:Connect(function(input, gpe)
	if not isUIOpen then return end

	if input.KeyCode == Enum.KeyCode.Left then
		selectedButtonIndex = 1
		updateButtonSelection()
	elseif input.KeyCode == Enum.KeyCode.Right then
		selectedButtonIndex = 2
		updateButtonSelection()
	elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		if selectedButtonIndex == 1 then
			closeUpgradeUI()
		elseif selectedButtonIndex == 2 then
			performUpgrade()
		end
	elseif input.KeyCode == Enum.KeyCode.Escape then
		closeUpgradeUI()
	end
end)

upgradeEvent.OnClientEvent:Connect(function(weaponName, newLevel)
	-- Upgrade successful. Reset UI state and refresh.
	isUpgrading = false
	progressOverlay.Visible = false
	cancelButton.Visible = true
	confirmButton.Visible = true

	refreshUpgradeData()
end)

-- Register Proximity Interaction via Module
local upgPart = workspace:WaitForChild("Upgrade")
if upgPart then
	-- Perbaikan: Kita register Part induk ("Upgrade"), lalu modul akan mencari ProximityPrompt
	-- searchRecursive=true akan mencari "UpgradePrompt" atau ProximityPrompt apapun di dalamnya
	proximityHandler = ProximityUIHandler.Register({
		name = "UpgradeShop",
		partName = "Upgrade",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			if isOpen then
				if isUIOpen then return end -- Already open

				local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
				if not equippedTool then
					-- Auto-close if requirements not met
					if proximityHandler then proximityHandler:SetOpen(false) end
					return
				end
				-- Check if weapon is valid
				if not WeaponModule.Weapons[equippedTool.Name] then
					if proximityHandler then proximityHandler:SetOpen(false) end
					return
				end

				local ok, result = pcall(function()
					return upgradeRF:InvokeServer(equippedTool)
				end)

				if ok and result.success then
					showUpgradeUI(equippedTool, result)
				else
					if proximityHandler then proximityHandler:SetOpen(false) end
				end
			else
				closeUpgradeUI()
			end
		end
	})
end

-- Mobile/Responsive Layout Check
local function updateLayout()
	if screenGui.AbsoluteSize.X < 600 then
		-- Mobile layout
		mainContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
		contentPadding.PaddingLeft = UDim.new(0, 16)
		contentPadding.PaddingRight = UDim.new(0, 16)
		weaponNameDisplay.TextSize = 28
	else
		-- Desktop layout
		mainContainer.Size = UDim2.new(0, 500, 0, 600)
		contentPadding.PaddingLeft = UDim.new(0, 32)
		contentPadding.PaddingRight = UDim.new(0, 32)
		weaponNameDisplay.TextSize = 36
	end
end

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout() -- Default call

return {}
