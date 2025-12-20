-- ArsenalForgePlugin.lua
-- A unified Roblox Studio Plugin for weapon balancing, stats editing, and testing
-- Merges: WeaponEditorPlugin + ArsenalForgePlugin (UI/UX from ArsenalForge)
-- Save this file to: %localappdata%\Roblox\Plugins\ArsenalForgePlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Arsenal Forge")
local toggleButton = toolbar:CreateButton(
	"Arsenal Forge",
	"Balance weapon stats, edit data, and test weapons",
	"rbxassetid://6031280882"
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	1200, -- Initial Width (increased)
	700,  -- Initial Height
	1100, -- Min Width (increased)
	550   -- Min Height
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("ArsenalForgeWidget", widgetInfo)
widget.Title = "⚒️ Arsenal Forge"

-- ==================== THEME: Industrial Forge ====================
local Theme = {
	Background = Color3.fromRGB(28, 25, 23),
	Surface = Color3.fromRGB(41, 37, 33),
	SurfaceHover = Color3.fromRGB(55, 50, 45),
	Accent = Color3.fromRGB(217, 119, 6),
	AccentHover = Color3.fromRGB(245, 158, 11),
	Combat = Color3.fromRGB(220, 38, 38),
	Economy = Color3.fromRGB(34, 197, 94),
	Simulation = Color3.fromRGB(59, 130, 246),
	Text = Color3.fromRGB(250, 250, 249),
	TextMuted = Color3.fromRGB(168, 162, 158),
	Border = Color3.fromRGB(68, 64, 60),

	CategoryColors = {
		Pistol = Color3.fromRGB(156, 163, 175),
		SMG = Color3.fromRGB(251, 191, 36),
		["Assault Rifle"] = Color3.fromRGB(239, 68, 68),
		Shotgun = Color3.fromRGB(249, 115, 22),
		Sniper = Color3.fromRGB(139, 92, 246),
		LMG = Color3.fromRGB(20, 184, 166),
	}
}

local STAT_COLUMNS = {
	{Key = "Damage", Label = "DMG", Width = 80, Color = Theme.Combat},
	{Key = "HeadshotMultiplier", Label = "HS×", Width = 55, Color = Color3.fromRGB(255, 150, 150)},
	{Key = "FireRate", Label = "Rate", Width = 70, Color = Theme.Economy},
	{Key = "MaxAmmo", Label = "Mag", Width = 80, Color = Theme.Simulation},
	{Key = "ReserveAmmo", Label = "Rsv", Width = 80, Color = Color3.fromRGB(100, 150, 200)},
	{Key = "ReloadTime", Label = "RLD", Width = 60, Color = Color3.fromRGB(150, 200, 100)},
	{Key = "Recoil", Label = "Rcl", Width = 60, Color = Theme.Accent},
	{Key = "Spread", Label = "Spd", Width = 60, Color = Color3.fromRGB(255, 200, 100)},
}

-- ==================== STATE ====================
local weaponData = {}
local selectedWeapon = nil
local currentTab = "forge" -- "forge", "spreadsheet"
local mainFrame = nil

-- ==================== HELPERS ====================
local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function tweenHover(button, hoverColor, normalColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
	end)
end

local function escape(s)
	return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
end

-- ==================== DATA PARSING ====================
local function getWeaponModuleScript()
	local modFolder = ReplicatedStorage:FindFirstChild("ModuleScript")
	if modFolder then
		return modFolder:FindFirstChild("WeaponModule")
	end
	return nil
end

local function parseWeaponModule()
	local script = getWeaponModuleScript()
	if not script then
		warn("[ArsenalForge] WeaponModule not found!")
		return false, "WeaponModule not found in ReplicatedStorage/ModuleScript/"
	end

	weaponData = {}
	local source = script.Source

	local weaponsBlock = source:match("WeaponModule%.Weapons%s*=%s*(%b{})")
	if not weaponsBlock then
		warn("[ArsenalForge] Could not find WeaponModule.Weapons table")
		return false, "Could not find 'WeaponModule.Weapons' table"
	end

	for weaponName, block in weaponsBlock:gmatch('%[\"([^\"]+)\"%]%s*=%s*(%b{})') do
		local data = {
			Name = weaponName,
			DisplayName = block:match('DisplayName%s*=%s*"([^"]+)"') or weaponName,
			Category = block:match('Category%s*=%s*"([^"]+)"') or "Unknown",
			Damage = tonumber(block:match("Damage%s*=%s*(%d+)")) or 0,
			FireRate = tonumber(block:match("FireRate%s*=%s*([%d%.]+)")) or 1,
			MaxAmmo = tonumber(block:match("MaxAmmo%s*=%s*(%d+)")) or 0,
			ReserveAmmo = tonumber(block:match("ReserveAmmo%s*=%s*(%d+)")) or 0,
			ReloadTime = tonumber(block:match("ReloadTime%s*=%s*([%d%.]+)")) or 1,
			HeadshotMultiplier = tonumber(block:match("HeadshotMultiplier%s*=%s*([%d%.]+)")) or 1,
			Recoil = tonumber(block:match("Recoil%s*=%s*([%d%.]+)")) or 0,
			Spread = tonumber(block:match("Spread%s*=%s*([%d%.]+)")) or 0,
			Pellets = tonumber(block:match("Pellets%s*=%s*(%d+)")) or 1,
		}

		local upgradeBlock = block:match("UpgradeConfig%s*=%s*(%b{})")
		if upgradeBlock then
			data.BaseCost = tonumber(upgradeBlock:match("BaseCost%s*=%s*(%d+)")) or 100
			data.CostMultiplier = tonumber(upgradeBlock:match("CostMultiplier%s*=%s*([%d%.]+)")) or 1.5
			data.CostExpo = tonumber(upgradeBlock:match("CostExpo%s*=%s*([%d%.]+)")) or 1.3
			data.DamagePerLevel = tonumber(upgradeBlock:match("DamagePerLevel%s*=%s*(%d+)")) or 5
			data.AmmoPerLevel = tonumber(upgradeBlock:match("AmmoPerLevel%s*=%s*(%d+)")) or 0
			data.MaxLevel = tonumber(upgradeBlock:match("MaxLevel%s*=%s*(%d+)")) or 10
		else
			data.BaseCost = 100
			data.CostMultiplier = 1.5
			data.CostExpo = 1.3
			data.DamagePerLevel = 5
			data.AmmoPerLevel = 0
			data.MaxLevel = 10
		end

		table.insert(weaponData, data)
	end

	table.sort(weaponData, function(a, b) return a.Name < b.Name end)
	print("[ArsenalForge] Parsed " .. #weaponData .. " weapons.")
	return true
end

-- ==================== CALCULATIONS ====================
local function calculateDPS(weapon, level)
	level = level or 1
	local damage = weapon.Damage + (weapon.DamagePerLevel * (level - 1))
	local pellets = weapon.Pellets or 1
	local fireRate = weapon.FireRate
	if fireRate <= 0 then fireRate = 0.1 end
	return math.floor(damage * pellets * (1 / fireRate))
end

local function calculateUpgradeCost(weapon, level)
	if level <= 1 then return 0 end
	return math.floor(weapon.BaseCost * (weapon.CostMultiplier ^ (weapon.CostExpo * (level - 1))))
end

local function calculateTotalCostToMax(weapon)
	local total = 0
	for i = 2, weapon.MaxLevel do
		total = total + calculateUpgradeCost(weapon, i)
	end
	return total
end

-- ==================== TEST WEAPON (from WeaponEditorPlugin) ====================
local function testWeapon(weaponName)
	if not RunService:IsRunning() then
		warn("[ArsenalForge] You must activate 'Play' mode to test weapons!")
		return
	end

	local plr = Players.LocalPlayer
	if not plr or not plr.Character then return end

	local TEST_Y = 500
	local testRoom = workspace:FindFirstChild("TestRoom")
	if not testRoom then
		testRoom = Instance.new("Folder")
		testRoom.Name = "TestRoom"
		testRoom.Parent = workspace

		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(100, 1, 100)
		floor.Position = Vector3.new(0, TEST_Y, 0)
		floor.Anchored = true
		floor.BrickColor = BrickColor.new("Dark stone grey")
		floor.Material = Enum.Material.Concrete
		floor.Parent = testRoom

		local light = Instance.new("PointLight")
		light.Range = 60
		light.Brightness = 2
		light.Parent = floor

		local dummy = Instance.new("Model")
		dummy.Name = "Target Dummy"
		dummy.Parent = testRoom

		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 100
		hum.Health = 100
		hum.Parent = dummy

		local torso = Instance.new("Part")
		torso.Name = "HumanoidRootPart"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = Vector3.new(0, TEST_Y + 3, -20)
		torso.Anchored = true
		torso.BrickColor = BrickColor.new("Bright red")
		torso.Parent = dummy

		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1, 1, 1)
		head.Position = Vector3.new(0, TEST_Y + 4.5, -20)
		head.Anchored = true
		head.BrickColor = BrickColor.new("Bright yellow")
		head.Parent = dummy
	end

	plr.Character:PivotTo(CFrame.new(0, TEST_Y + 5, 0))

	local tool = nil
	for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
		if child:IsA("Tool") and child.Name == weaponName then
			tool = child
			break
		end
	end

	if tool then
		local clone = tool:Clone()
		clone.Parent = plr.Backpack
		plr.Character.Humanoid:EquipTool(clone)
	else
		warn("[ArsenalForge] Weapon Tool '" .. weaponName .. "' not found!")
	end
end

-- ==================== SAVE LOGIC ====================
local function applyChangesToSource(statusLabel)
	local script = getWeaponModuleScript()
	if not script then
		if statusLabel then
			statusLabel.Text = "❌ Module not found!"
			statusLabel.TextColor3 = Theme.Combat
		end
		return false
	end

	ChangeHistoryService:SetWaypoint("Pre-ArsenalForge Edit")

	local source = script.Source
	local totalReplaced = 0

	for _, weapon in ipairs(weaponData) do
		local safeName = escape(weapon.Name)

		for _, col in ipairs(STAT_COLUMNS) do
			local val = weapon[col.Key]
			if val then
				local pattern = '(%["' .. safeName .. '"%][%s%S]-' .. col.Key .. '%s*=%s*)([%d%.%-]+)'
				if source:find(pattern) then
					local newSource, count = source:gsub(pattern, "%1" .. tostring(val), 1)
					if count > 0 then
						source = newSource
						totalReplaced = totalReplaced + count
					end
				end
			end
		end

		-- Also update UpgradeConfig values
		local upgradeKeys = {"BaseCost", "CostMultiplier", "DamagePerLevel", "MaxLevel"}
		for _, key in ipairs(upgradeKeys) do
			local val = weapon[key]
			if val then
				local pattern = '(%["' .. safeName .. '"%][%s%S]-' .. key .. '%s*=%s*)([%d%.%-]+)'
				if source:find(pattern) then
					local newSource, count = source:gsub(pattern, "%1" .. tostring(val), 1)
					if count > 0 then
						source = newSource
						totalReplaced = totalReplaced + count
					end
				end
			end
		end
	end

	if totalReplaced > 0 then
		script.Source = source
		ChangeHistoryService:SetWaypoint("ArsenalForge: Updated " .. totalReplaced .. " values")
		if statusLabel then
			statusLabel.Text = "✅ Forged " .. totalReplaced .. " values!"
			statusLabel.TextColor3 = Theme.Economy
		end
		return true
	else
		if statusLabel then
			statusLabel.Text = "⚠️ No changes detected"
			statusLabel.TextColor3 = Theme.Accent
		end
		return false
	end
end

-- ==================== UI CREATION ====================
local function createUI(errorMsg)
	if mainFrame then mainFrame:Destroy() end

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Theme.Background
	mainFrame.Parent = widget

	-- Error State
	if errorMsg then
		local errLabel = Instance.new("TextLabel")
		errLabel.Size = UDim2.new(1, -40, 1, -40)
		errLabel.Position = UDim2.new(0, 20, 0, 20)
		errLabel.BackgroundTransparency = 1
		errLabel.Text = "⚠️ Plugin Start Error:\n\n" .. errorMsg .. "\n\nPlease check Output window for details."
		errLabel.TextColor3 = Theme.Combat
		errLabel.TextSize = 14
		errLabel.Font = Enum.Font.GothamBold
		errLabel.TextWrapped = true
		errLabel.Parent = mainFrame
		return
	end

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 55)
	header.BackgroundColor3 = Theme.Surface
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerAccent = Instance.new("Frame")
	headerAccent.Size = UDim2.new(1, 0, 0, 3)
	headerAccent.Position = UDim2.new(0, 0, 1, -3)
	headerAccent.BackgroundColor3 = Theme.Accent
	headerAccent.BorderSizePixel = 0
	headerAccent.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.5, 0, 0, 28)
	title.Position = UDim2.new(0, 15, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "⚒️ Arsenal Forge"
	title.TextColor3 = Theme.Text
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.5, 0, 0, 16)
	subtitle.Position = UDim2.new(0, 15, 0, 33)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Unified Weapon Balancing Tool"
	subtitle.TextColor3 = Theme.TextMuted
	subtitle.TextSize = 11
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	-- Tab Buttons in header
	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(0, 280, 0, 36)
	tabFrame.Position = UDim2.new(1, -290, 0, 10)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = header

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabFrame

	local forgeTabBtn = Instance.new("TextButton")
	forgeTabBtn.Size = UDim2.new(0, 130, 1, 0)
	forgeTabBtn.BackgroundColor3 = currentTab == "forge" and Theme.Accent or Theme.SurfaceHover
	forgeTabBtn.Text = "🔨 Forge View"
	forgeTabBtn.TextColor3 = Theme.Text
	forgeTabBtn.TextSize = 12
	forgeTabBtn.Font = Enum.Font.GothamBold
	forgeTabBtn.Parent = tabFrame
	createCorner(forgeTabBtn, 6)

	local sheetTabBtn = Instance.new("TextButton")
	sheetTabBtn.Size = UDim2.new(0, 130, 1, 0)
	sheetTabBtn.BackgroundColor3 = currentTab == "spreadsheet" and Theme.Accent or Theme.SurfaceHover
	sheetTabBtn.Text = "📊 Spreadsheet"
	sheetTabBtn.TextColor3 = Theme.Text
	sheetTabBtn.TextSize = 12
	sheetTabBtn.Font = Enum.Font.GothamBold
	sheetTabBtn.Parent = tabFrame
	createCorner(sheetTabBtn, 6)

	-- Content containers
	local forgeContent = Instance.new("Frame")
	forgeContent.Name = "ForgeContent"
	forgeContent.Size = UDim2.new(1, 0, 1, -55)
	forgeContent.Position = UDim2.new(0, 0, 0, 55)
	forgeContent.BackgroundTransparency = 1
	forgeContent.Visible = currentTab == "forge"
	forgeContent.Parent = mainFrame

	local sheetContent = Instance.new("Frame")
	sheetContent.Name = "SheetContent"
	sheetContent.Size = UDim2.new(1, 0, 1, -55)
	sheetContent.Position = UDim2.new(0, 0, 0, 55)
	sheetContent.BackgroundTransparency = 1
	sheetContent.Visible = currentTab == "spreadsheet"
	sheetContent.Parent = mainFrame

	-- ==================== FORGE VIEW (Original ArsenalForge UI) ====================
	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Size = UDim2.new(0, 180, 1, -10)
	sidebar.Position = UDim2.new(0, 5, 0, 5)
	sidebar.BackgroundColor3 = Theme.Surface
	sidebar.ScrollBarThickness = 4
	sidebar.ScrollBarImageColor3 = Theme.Accent
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sidebar.Parent = forgeContent
	createCorner(sidebar, 10)
	createStroke(sidebar, Theme.Border, 1)

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 4)
	sidebarLayout.Parent = sidebar

	local sidebarPadding = Instance.new("UIPadding")
	sidebarPadding.PaddingTop = UDim.new(0, 8)
	sidebarPadding.PaddingBottom = UDim.new(0, 8)
	sidebarPadding.PaddingLeft = UDim.new(0, 6)
	sidebarPadding.PaddingRight = UDim.new(0, 6)
	sidebarPadding.Parent = sidebar

	local forgeDetailArea = Instance.new("Frame")
	forgeDetailArea.Size = UDim2.new(1, -200, 1, -10)
	forgeDetailArea.Position = UDim2.new(0, 195, 0, 5)
	forgeDetailArea.BackgroundTransparency = 1
	forgeDetailArea.Parent = forgeContent

	local detailLayout = Instance.new("UIListLayout")
	detailLayout.Padding = UDim.new(0, 10)
	detailLayout.Parent = forgeDetailArea

	local placeholderLabel = Instance.new("TextLabel")
	placeholderLabel.Name = "Placeholder"
	placeholderLabel.Size = UDim2.new(1, 0, 0, 100)
	placeholderLabel.BackgroundTransparency = 1
	placeholderLabel.Text = "⬅️ Select a weapon to forge"
	placeholderLabel.TextColor3 = Theme.TextMuted
	placeholderLabel.TextSize = 16
	placeholderLabel.Font = Enum.Font.Gotham
	placeholderLabel.Parent = forgeDetailArea

	-- Function to build weapon detail panel
	local function buildWeaponDetailPanel(weapon)
		selectedWeapon = weapon
		for _, child in ipairs(forgeDetailArea:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end

		-- Header
		local weaponHeader = Instance.new("Frame")
		weaponHeader.Size = UDim2.new(1, 0, 0, 50)
		weaponHeader.BackgroundColor3 = Theme.Surface
		weaponHeader.Parent = forgeDetailArea
		createCorner(weaponHeader, 10)

		local weaponTitle = Instance.new("TextLabel")
		weaponTitle.Size = UDim2.new(0.6, 0, 0, 28)
		weaponTitle.Position = UDim2.new(0, 12, 0, 6)
		weaponTitle.BackgroundTransparency = 1
		weaponTitle.Text = "🔫 " .. weapon.DisplayName
		weaponTitle.TextColor3 = Theme.Text
		weaponTitle.TextSize = 18
		weaponTitle.Font = Enum.Font.GothamBold
		weaponTitle.TextXAlignment = Enum.TextXAlignment.Left
		weaponTitle.Parent = weaponHeader

		local weaponCat = Instance.new("TextLabel")
		weaponCat.Size = UDim2.new(0.4, 0, 0, 16)
		weaponCat.Position = UDim2.new(0, 12, 0, 30)
		weaponCat.BackgroundTransparency = 1
		weaponCat.Text = weapon.Category
		weaponCat.TextColor3 = Theme.CategoryColors[weapon.Category] or Theme.TextMuted
		weaponCat.TextSize = 12
		weaponCat.Font = Enum.Font.Gotham
		weaponCat.TextXAlignment = Enum.TextXAlignment.Left
		weaponCat.Parent = weaponHeader

		-- Test Button in header
		local testBtn = Instance.new("TextButton")
		testBtn.Size = UDim2.new(0, 80, 0, 30)
		testBtn.Position = UDim2.new(1, -90, 0, 10)
		testBtn.BackgroundColor3 = Theme.Simulation
		testBtn.Text = "🎯 TEST"
		testBtn.TextColor3 = Theme.Text
		testBtn.TextSize = 12
		testBtn.Font = Enum.Font.GothamBold
		testBtn.Parent = weaponHeader
		createCorner(testBtn, 6)
		tweenHover(testBtn, Color3.fromRGB(80, 150, 255), Theme.Simulation)

		testBtn.MouseButton1Click:Connect(function()
			testWeapon(weapon.Name)
		end)

		-- Combat Panel
		local combatPanel = Instance.new("Frame")
		combatPanel.Size = UDim2.new(1, 0, 0, 140)
		combatPanel.BackgroundColor3 = Theme.Surface
		combatPanel.Parent = forgeDetailArea
		createCorner(combatPanel, 10)

		local combatBar = Instance.new("Frame")
		combatBar.Size = UDim2.new(0, 4, 1, -16)
		combatBar.Position = UDim2.new(0, 8, 0, 8)
		combatBar.BackgroundColor3 = Theme.Combat
		combatBar.Parent = combatPanel
		createCorner(combatBar, 2)

		local combatTitle = Instance.new("TextLabel")
		combatTitle.Size = UDim2.new(0.5, 0, 0, 22)
		combatTitle.Position = UDim2.new(0, 20, 0, 8)
		combatTitle.BackgroundTransparency = 1
		combatTitle.Text = "⚔️ Combat Stats"
		combatTitle.TextColor3 = Theme.Combat
		combatTitle.TextSize = 14
		combatTitle.Font = Enum.Font.GothamBold
		combatTitle.TextXAlignment = Enum.TextXAlignment.Left
		combatTitle.Parent = combatPanel

		local dpsLabel = Instance.new("TextLabel")
		dpsLabel.Size = UDim2.new(0.5, 0, 0, 30)
		dpsLabel.Position = UDim2.new(0.5, 0, 0, 8)
		dpsLabel.BackgroundTransparency = 1
		dpsLabel.Text = "DPS: " .. calculateDPS(weapon, 1)
		dpsLabel.TextColor3 = Theme.Accent
		dpsLabel.TextSize = 18
		dpsLabel.Font = Enum.Font.GothamBold
		dpsLabel.TextXAlignment = Enum.TextXAlignment.Right
		dpsLabel.Parent = combatPanel

		local function createStatInput(parent, label, value, yPos, xOffset, onChange)
			local container = Instance.new("Frame")
			container.Size = UDim2.new(0.45, 0, 0, 35)
			container.Position = UDim2.new(xOffset, 10, 0, yPos)
			container.BackgroundTransparency = 1
			container.Parent = parent

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 14)
			lbl.BackgroundTransparency = 1
			lbl.Text = label
			lbl.TextColor3 = Theme.TextMuted
			lbl.TextSize = 10
			lbl.Font = Enum.Font.Gotham
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = container

			local input = Instance.new("TextBox")
			input.Size = UDim2.new(1, 0, 0, 22)
			input.Position = UDim2.new(0, 0, 0, 14)
			input.BackgroundColor3 = Theme.Background
			input.Text = tostring(value)
			input.TextColor3 = Theme.Text
			input.TextSize = 12
			input.Font = Enum.Font.GothamBold
			input.Parent = container
			createCorner(input, 5)
			createStroke(input, Theme.Border, 1)

			input.FocusLost:Connect(function()
				local val = tonumber(input.Text)
				if val then
					onChange(val)
					dpsLabel.Text = "DPS: " .. calculateDPS(weapon, 1)
				end
			end)
			return input
		end

		createStatInput(combatPanel, "Damage", weapon.Damage, 38, 0, function(v) weapon.Damage = v end)
		createStatInput(combatPanel, "Fire Rate (s)", weapon.FireRate, 38, 0.5, function(v) weapon.FireRate = v end)
		createStatInput(combatPanel, "Max Ammo", weapon.MaxAmmo, 78, 0, function(v) weapon.MaxAmmo = v end)
		createStatInput(combatPanel, "Reload Time (s)", weapon.ReloadTime, 78, 0.5, function(v) weapon.ReloadTime = v end)

		-- Economy Panel
		local economyPanel = Instance.new("Frame")
		economyPanel.Size = UDim2.new(1, 0, 0, 140)
		economyPanel.BackgroundColor3 = Theme.Surface
		economyPanel.Parent = forgeDetailArea
		createCorner(economyPanel, 10)

		local economyBar = Instance.new("Frame")
		economyBar.Size = UDim2.new(0, 4, 1, -16)
		economyBar.Position = UDim2.new(0, 8, 0, 8)
		economyBar.BackgroundColor3 = Theme.Economy
		economyBar.Parent = economyPanel
		createCorner(economyBar, 2)

		local economyTitle = Instance.new("TextLabel")
		economyTitle.Size = UDim2.new(0.5, 0, 0, 22)
		economyTitle.Position = UDim2.new(0, 20, 0, 8)
		economyTitle.BackgroundTransparency = 1
		economyTitle.Text = "💰 Economy & Upgrades"
		economyTitle.TextColor3 = Theme.Economy
		economyTitle.TextSize = 14
		economyTitle.Font = Enum.Font.GothamBold
		economyTitle.TextXAlignment = Enum.TextXAlignment.Left
		economyTitle.Parent = economyPanel

		local totalCostLabel = Instance.new("TextLabel")
		totalCostLabel.Size = UDim2.new(0.5, 0, 0, 30)
		totalCostLabel.Position = UDim2.new(0.5, 0, 0, 8)
		totalCostLabel.BackgroundTransparency = 1
		totalCostLabel.Text = "Max: $" .. calculateTotalCostToMax(weapon)
		totalCostLabel.TextColor3 = Theme.Economy
		totalCostLabel.TextSize = 16
		totalCostLabel.Font = Enum.Font.GothamBold
		totalCostLabel.TextXAlignment = Enum.TextXAlignment.Right
		totalCostLabel.Parent = economyPanel

		createStatInput(economyPanel, "Base Cost", weapon.BaseCost, 38, 0, function(v) 
			weapon.BaseCost = v 
			totalCostLabel.Text = "Max: $" .. calculateTotalCostToMax(weapon)
		end)
		createStatInput(economyPanel, "Cost Multiplier", weapon.CostMultiplier, 38, 0.5, function(v) 
			weapon.CostMultiplier = v 
			totalCostLabel.Text = "Max: $" .. calculateTotalCostToMax(weapon)
		end)
		createStatInput(economyPanel, "Damage/Level", weapon.DamagePerLevel, 78, 0, function(v) weapon.DamagePerLevel = v end)
		createStatInput(economyPanel, "Max Level", weapon.MaxLevel, 78, 0.5, function(v) 
			weapon.MaxLevel = v 
			totalCostLabel.Text = "Max: $" .. calculateTotalCostToMax(weapon)
		end)

		-- Action Bar
		local actionBar = Instance.new("Frame")
		actionBar.Size = UDim2.new(1, 0, 0, 50)
		actionBar.BackgroundTransparency = 1
		actionBar.Parent = forgeDetailArea

		local applyBtn = Instance.new("TextButton")
		applyBtn.Size = UDim2.new(0.5, 0, 0, 40)
		applyBtn.Position = UDim2.new(0.25, 0, 0, 5)
		applyBtn.BackgroundColor3 = Theme.Accent
		applyBtn.Text = "⚒️ Apply Forge"
		applyBtn.TextColor3 = Theme.Background
		applyBtn.TextSize = 16
		applyBtn.Font = Enum.Font.GothamBold
		applyBtn.Parent = actionBar
		createCorner(applyBtn, 10)
		tweenHover(applyBtn, Theme.AccentHover, Theme.Accent)

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(1, 0, 0, 20)
		statusLabel.Position = UDim2.new(0, 0, 0, 50)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = ""
		statusLabel.TextColor3 = Theme.TextMuted
		statusLabel.TextSize = 12
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.Parent = actionBar

		applyBtn.MouseButton1Click:Connect(function()
			applyChangesToSource(statusLabel)
		end)
	end

	-- Create weapon buttons in sidebar
	for _, weapon in ipairs(weaponData) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 38)
		btn.BackgroundColor3 = Theme.SurfaceHover
		btn.Text = ""
		btn.Parent = sidebar
		createCorner(btn, 6)

		local catBar = Instance.new("Frame")
		catBar.Size = UDim2.new(0, 4, 1, -8)
		catBar.Position = UDim2.new(0, 4, 0, 4)
		catBar.BackgroundColor3 = Theme.CategoryColors[weapon.Category] or Theme.Accent
		catBar.Parent = btn
		createCorner(catBar, 2)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -20, 0, 20)
		nameLabel.Position = UDim2.new(0, 14, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = weapon.DisplayName
		nameLabel.TextColor3 = Theme.Text
		nameLabel.TextSize = 12
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = btn

		local catLabel = Instance.new("TextLabel")
		catLabel.Size = UDim2.new(1, -20, 0, 14)
		catLabel.Position = UDim2.new(0, 14, 0, 22)
		catLabel.BackgroundTransparency = 1
		catLabel.Text = weapon.Category
		catLabel.TextColor3 = Theme.TextMuted
		catLabel.TextSize = 10
		catLabel.Font = Enum.Font.Gotham
		catLabel.TextXAlignment = Enum.TextXAlignment.Left
		catLabel.Parent = btn

		tweenHover(btn, Theme.Accent, Theme.SurfaceHover)

		btn.MouseButton1Click:Connect(function()
			buildWeaponDetailPanel(weapon)
		end)
	end

	-- ==================== SPREADSHEET VIEW ====================
	local sheetHeader = Instance.new("Frame")
	sheetHeader.Size = UDim2.new(1, -20, 0, 35)
	sheetHeader.Position = UDim2.new(0, 10, 0, 5)
	sheetHeader.BackgroundColor3 = Theme.Surface
	sheetHeader.Parent = sheetContent
	createCorner(sheetHeader, 6)

	-- Header columns
	local nameHeader = Instance.new("TextLabel")
	nameHeader.Size = UDim2.new(0, 120, 1, 0)
	nameHeader.Position = UDim2.new(0, 5, 0, 0)
	nameHeader.BackgroundTransparency = 1
	nameHeader.Text = "Weapon"
	nameHeader.TextColor3 = Theme.Text
	nameHeader.TextSize = 11
	nameHeader.Font = Enum.Font.GothamBold
	nameHeader.TextXAlignment = Enum.TextXAlignment.Left
	nameHeader.Parent = sheetHeader

	local headerX = 125
	for _, col in ipairs(STAT_COLUMNS) do
		local h = Instance.new("TextLabel")
		h.Size = UDim2.new(0, col.Width, 1, 0)
		h.Position = UDim2.new(0, headerX, 0, 0)
		h.BackgroundTransparency = 1
		h.Text = col.Label
		h.TextColor3 = col.Color
		h.TextSize = 10
		h.Font = Enum.Font.GothamBold
		h.Parent = sheetHeader
		headerX = headerX + col.Width + 4
	end

	local actionHeader = Instance.new("TextLabel")
	actionHeader.Size = UDim2.new(0, 60, 1, 0)
	actionHeader.Position = UDim2.new(0, headerX, 0, 0)
	actionHeader.BackgroundTransparency = 1
	actionHeader.Text = "Action"
	actionHeader.TextColor3 = Theme.Text
	actionHeader.TextSize = 10
	actionHeader.Font = Enum.Font.GothamBold
	actionHeader.Parent = sheetHeader

	-- Grid
	local sheetGrid = Instance.new("ScrollingFrame")
	sheetGrid.Size = UDim2.new(1, -20, 1, -100)
	sheetGrid.Position = UDim2.new(0, 10, 0, 45)
	sheetGrid.BackgroundColor3 = Theme.Surface
	sheetGrid.ScrollBarThickness = 6
	sheetGrid.ScrollBarImageColor3 = Theme.Accent
	sheetGrid.AutomaticCanvasSize = Enum.AutomaticSize.XY
	sheetGrid.Parent = sheetContent
	createCorner(sheetGrid, 10)

	local gridLayout = Instance.new("UIListLayout")
	gridLayout.Padding = UDim.new(0, 2)
	gridLayout.Parent = sheetGrid

	local gridPadding = Instance.new("UIPadding")
	gridPadding.PaddingTop = UDim.new(0, 5)
	gridPadding.PaddingLeft = UDim.new(0, 5)
	gridPadding.PaddingRight = UDim.new(0, 5)
	gridPadding.Parent = sheetGrid

	for _, weapon in ipairs(weaponData) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 30)
		row.BackgroundColor3 = Theme.SurfaceHover
		row.Parent = sheetGrid
		createCorner(row, 4)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0, 115, 1, 0)
		nameLabel.Position = UDim2.new(0, 5, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = weapon.DisplayName
		nameLabel.TextColor3 = Theme.Text
		nameLabel.TextSize = 11
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.Parent = row

		local colX = 120
		for _, col in ipairs(STAT_COLUMNS) do
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0, col.Width, 0, 22)
			box.Position = UDim2.new(0, colX, 0, 4)
			box.BackgroundColor3 = Theme.Background
			box.TextColor3 = Theme.Text
			box.Text = tostring(weapon[col.Key] or 0)
			box.TextSize = 10
			box.Font = Enum.Font.Gotham
			box.Parent = row
			createCorner(box, 3)

			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if n then
					weapon[col.Key] = n
				else
					box.Text = tostring(weapon[col.Key] or 0)
				end
			end)

			colX = colX + col.Width + 4
		end

		local testBtn = Instance.new("TextButton")
		testBtn.Size = UDim2.new(0, 50, 0, 22)
		testBtn.Position = UDim2.new(0, colX, 0, 4)
		testBtn.BackgroundColor3 = Theme.Simulation
		testBtn.Text = "TEST"
		testBtn.TextColor3 = Theme.Text
		testBtn.TextSize = 9
		testBtn.Font = Enum.Font.GothamBold
		testBtn.Parent = row
		createCorner(testBtn, 4)

		testBtn.MouseButton1Click:Connect(function()
			testWeapon(weapon.Name)
		end)
	end

	-- Spreadsheet action bar
	local sheetActionBar = Instance.new("Frame")
	sheetActionBar.Size = UDim2.new(1, -20, 0, 45)
	sheetActionBar.Position = UDim2.new(0, 10, 1, -50)
	sheetActionBar.BackgroundTransparency = 1
	sheetActionBar.Parent = sheetContent

	local sheetApplyBtn = Instance.new("TextButton")
	sheetApplyBtn.Size = UDim2.new(0, 160, 0, 38)
	sheetApplyBtn.Position = UDim2.new(0.5, -80, 0, 0)
	sheetApplyBtn.BackgroundColor3 = Theme.Accent
	sheetApplyBtn.Text = "⚒️ Apply All Changes"
	sheetApplyBtn.TextColor3 = Theme.Background
	sheetApplyBtn.TextSize = 14
	sheetApplyBtn.Font = Enum.Font.GothamBold
	sheetApplyBtn.Parent = sheetActionBar
	createCorner(sheetApplyBtn, 8)
	tweenHover(sheetApplyBtn, Theme.AccentHover, Theme.Accent)

	local sheetStatus = Instance.new("TextLabel")
	sheetStatus.Size = UDim2.new(0, 200, 0, 38)
	sheetStatus.Position = UDim2.new(0.5, 90, 0, 0)
	sheetStatus.BackgroundTransparency = 1
	sheetStatus.Text = ""
	sheetStatus.TextColor3 = Theme.TextMuted
	sheetStatus.TextSize = 12
	sheetStatus.Font = Enum.Font.Gotham
	sheetStatus.TextXAlignment = Enum.TextXAlignment.Left
	sheetStatus.Parent = sheetActionBar

	sheetApplyBtn.MouseButton1Click:Connect(function()
		applyChangesToSource(sheetStatus)
	end)

	-- Tab switching logic
	local function switchTab(tab)
		currentTab = tab
		forgeContent.Visible = tab == "forge"
		sheetContent.Visible = tab == "spreadsheet"
		forgeTabBtn.BackgroundColor3 = tab == "forge" and Theme.Accent or Theme.SurfaceHover
		sheetTabBtn.BackgroundColor3 = tab == "spreadsheet" and Theme.Accent or Theme.SurfaceHover
	end

	forgeTabBtn.MouseButton1Click:Connect(function() switchTab("forge") end)
	sheetTabBtn.MouseButton1Click:Connect(function() switchTab("spreadsheet") end)
end

-- ==================== PLUGIN INIT ====================
plugin.Unloading:Connect(function()
	if mainFrame then mainFrame:Destroy() end
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		local success, err = parseWeaponModule()
		if success then
			createUI()
		else
			createUI("Failed to parse WeaponModule. " .. (err or ""))
		end
	end
end)

print("[Arsenal Forge] Unified Plugin Loaded! ⚒️")
	