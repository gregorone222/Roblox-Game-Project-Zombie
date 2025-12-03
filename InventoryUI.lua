-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby
-- Theme: Zombie Apocalypse / Industrial Survival

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

-- Module & Event References
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage.ModuleScript:WaitForChild("ModelPreviewModule"))
local inventoryRemote = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetInventoryData")
local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent")

-- Booster-related events
local BoosterUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BoosterUpdateEvent")
local ActivateBoosterEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ActivateBoosterEvent")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")

-- --- THEME CONFIGURATION ---
local THEME = {
	COLORS = {
		BG_MAIN     = Color3.fromRGB(18, 16, 16),    -- Deep dark grunge
		BG_PANEL    = Color3.fromRGB(30, 28, 28),    -- Panel background
		BORDER      = Color3.fromRGB(70, 60, 55),    -- Rusted metal
		PRIMARY     = Color3.fromRGB(210, 120, 60),  -- Hazard Orange / Rust
		PRIMARY_DIM = Color3.fromRGB(140, 80, 40),
		ACCENT_RED  = Color3.fromRGB(180, 50, 50),   -- Blood Red
		ACCENT_GREEN= Color3.fromRGB(100, 180, 80),  -- Toxic Green
		TEXT_MAIN   = Color3.fromRGB(230, 225, 220), -- Bone White
		TEXT_DIM    = Color3.fromRGB(150, 140, 130), -- Dust Gray
		ITEM_BG     = Color3.fromRGB(40, 38, 38),
		ITEM_HOVER  = Color3.fromRGB(50, 48, 48),
	},
	FONTS = {
		TITLE   = Enum.Font.GothamBlack,
		HEADER  = Enum.Font.GothamBold,
		BODY    = Enum.Font.GothamMedium,
		TECH    = Enum.Font.Code, -- For stats
	}
}

-- --- UI STATE ---
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil
selectedCategory = "All"
local currentTab = "Weapons"
local currentPreview = nil
local boosterConfig = nil
local boosterData = nil
local assetCache = {}

-- --- RESPONSIVE VARIABLES ---
local isMobile = UserInputService.TouchEnabled
local screenSize = Vector2.new(1920, 1080)

local function getScreenSize()
	local camera = workspace.CurrentCamera
	if camera then return camera.ViewportSize end
	return player:WaitForChild("PlayerGui").AbsoluteSize
end

local function updateDeviceType()
	screenSize = getScreenSize()
	isMobile = (screenSize.X < 800) or UserInputService.TouchEnabled
end

-- --- UI CREATION ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Helper: Create stylized panel
local function createPanel(name, size, pos, parent)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = THEME.COLORS.BG_PANEL
	frame.BorderSizePixel = 0
	frame.Parent = parent

	-- "Plating" effect (Top/Bottom borders)
	local borderTop = Instance.new("Frame")
	borderTop.Size = UDim2.new(1, 0, 0, 2)
	borderTop.BackgroundColor3 = THEME.COLORS.BORDER
	borderTop.BorderSizePixel = 0
	borderTop.Parent = frame

	local borderBot = Instance.new("Frame")
	borderBot.Size = UDim2.new(1, 0, 0, 2)
	borderBot.Position = UDim2.new(0, 0, 1, -2)
	borderBot.BackgroundColor3 = THEME.COLORS.BORDER
	borderBot.BorderSizePixel = 0
	borderBot.Parent = frame

	return frame
end

-- Open Button
local openButton = Instance.new("TextButton")
openButton.Name = "OpenBtn"
openButton.Size = UDim2.new(0, 80, 0, 80) -- Circle button on mobile? Or box on desktop
openButton.Position = UDim2.new(0, 20, 0.5, 0)
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.BackgroundColor3 = THEME.COLORS.BG_PANEL
openButton.Text = ""
openButton.AutoButtonColor = false
openButton.Parent = screenGui

local obStroke = Instance.new("UIStroke")
obStroke.Color = THEME.COLORS.PRIMARY
obStroke.Thickness = 3
obStroke.Parent = openButton

local obCorner = Instance.new("UICorner")
obCorner.CornerRadius = UDim.new(0, 12)
obCorner.Parent = openButton

local obIcon = Instance.new("TextLabel")
obIcon.Size = UDim2.new(1,0,1,0)
obIcon.BackgroundTransparency = 1
obIcon.Text = "🎒"
obIcon.TextSize = 32
obIcon.Parent = openButton

local obLabel = Instance.new("TextLabel")
obLabel.Size = UDim2.new(2, 0, 0, 20)
obLabel.Position = UDim2.new(0.5, 0, 1, 5)
obLabel.AnchorPoint = Vector2.new(0.5, 0)
obLabel.BackgroundTransparency = 1
obLabel.Text = "INVENTORY"
obLabel.Font = THEME.FONTS.HEADER
obLabel.TextSize = 12
obLabel.TextColor3 = THEME.COLORS.TEXT_MAIN
obLabel.TextStrokeTransparency = 0.5
obLabel.Parent = openButton

-- Main Container (The "Tablet")
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0.9, 0, 0.85, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = THEME.COLORS.BG_MAIN
mainPanel.BackgroundTransparency = 0.05
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

-- Grunge Texture Overlay (Procedural scratches using Frame lines if needed, or simple gradient)
local grungeGrad = Instance.new("UIGradient")
grungeGrad.Rotation = 45
grungeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(0.8,0.8,0.8)),
	ColorSequenceKeypoint.new(1, Color3.new(0.5,0.5,0.5))
})
grungeGrad.Parent = mainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = THEME.COLORS.BORDER
mainStroke.Thickness = 2
mainStroke.Parent = mainPanel

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 4) -- Sharp industrial corners
mainCorner.Parent = mainPanel

-- 1. LEFT SIDEBAR (Navigation)
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 80, 1, 0)
sidebar.BackgroundColor3 = THEME.COLORS.BG_PANEL
sidebar.BorderSizePixel = 0
sidebar.Parent = mainPanel

local sbDiv = Instance.new("Frame")
sbDiv.Size = UDim2.new(0, 1, 1, 0)
sbDiv.Position = UDim2.new(1, 0, 0, 0)
sbDiv.BackgroundColor3 = THEME.COLORS.BORDER
sbDiv.BorderSizePixel = 0
sbDiv.Parent = sidebar

local navContainer = Instance.new("Frame")
navContainer.Size = UDim2.new(1, 0, 0.6, 0)
navContainer.Position = UDim2.new(0, 0, 0.2, 0)
navContainer.BackgroundTransparency = 1
navContainer.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 20)
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.Parent = navContainer

local function createNavBtn(id, icon, isActive)
	local btn = Instance.new("TextButton")
	btn.Name = id
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.BackgroundColor3 = isActive and THEME.COLORS.PRIMARY or THEME.COLORS.ITEM_BG
	btn.BackgroundTransparency = isActive and 0.8 or 1
	btn.Text = ""
	btn.Parent = navContainer

	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = btn

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = icon
	lbl.TextSize = 28
	lbl.Parent = btn

	-- Selection Indicator line
	if isActive then
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 4, 0.6, 0)
		line.Position = UDim2.new(0, 0, 0.2, 0)
		line.BackgroundColor3 = THEME.COLORS.PRIMARY
		line.BorderSizePixel = 0
		line.Parent = btn
	end

	return btn
end

local navWeapons = createNavBtn("Weapons", "🔫", true)
local navBoosters = createNavBtn("Boosters", "⚡", false)

-- 2. CONTENT AREA
local contentArea = Instance.new("Frame")
contentArea.Name = "Content"
contentArea.Size = UDim2.new(1, -80, 1, 0)
contentArea.Position = UDim2.new(0, 80, 0, 0)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainPanel

-- HEADER
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundTransparency = 1
header.Parent = contentArea

local title = Instance.new("TextLabel")
title.Text = "SURVIVOR'S CACHE"
title.Font = THEME.FONTS.TITLE
title.TextSize = 24
title.TextColor3 = THEME.COLORS.TEXT_MAIN
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -20, 0.5, 0)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.BackgroundColor3 = THEME.COLORS.ACCENT_RED
closeBtn.BackgroundTransparency = 0.8
closeBtn.Text = "✕"
closeBtn.TextColor3 = THEME.COLORS.ACCENT_RED
closeBtn.Font = THEME.FONTS.HEADER
closeBtn.TextSize = 20
closeBtn.Parent = header
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = closeBtn
local cs = Instance.new("UIStroke"); cs.Color = THEME.COLORS.ACCENT_RED; cs.Transparency=0.5; cs.Parent = closeBtn

-- SPLIT VIEW (Grid vs Inspector)
local splitContainer = Instance.new("Frame")
splitContainer.Size = UDim2.new(1, 0, 1, -60)
splitContainer.Position = UDim2.new(0, 0, 0, 60)
splitContainer.BackgroundTransparency = 1
splitContainer.Parent = contentArea

-- A. GRID SIDE
local gridSide = Instance.new("Frame")
gridSide.Name = "GridSide"
gridSide.Size = UDim2.new(0.6, 0, 1, 0) -- 60% Width
gridSide.BackgroundTransparency = 1
gridSide.Parent = splitContainer

-- Filter Bar
local filterBar = Instance.new("Frame")
filterBar.Size = UDim2.new(1, -40, 0, 50)
filterBar.Position = UDim2.new(0, 20, 0, 0)
filterBar.BackgroundTransparency = 1
filterBar.Parent = gridSide

local search = Instance.new("TextBox")
search.Size = UDim2.new(0.4, 0, 0.7, 0)
search.Position = UDim2.new(0, 0, 0.15, 0)
search.BackgroundColor3 = THEME.COLORS.ITEM_BG
search.TextColor3 = THEME.COLORS.TEXT_MAIN
search.PlaceholderText = "SEARCH..."
search.PlaceholderColor3 = THEME.COLORS.TEXT_DIM
search.Font = THEME.FONTS.BODY
search.TextSize = 12
search.Parent = filterBar
local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = search
local ss = Instance.new("UIStroke"); ss.Color = THEME.COLORS.BORDER; ss.Parent = search
local sp = Instance.new("UIPadding"); sp.PaddingLeft = UDim.new(0,10); sp.Parent = search

local catScroll = Instance.new("ScrollingFrame")
catScroll.Size = UDim2.new(0.55, 0, 0.7, 0)
catScroll.Position = UDim2.new(0.45, 0, 0.15, 0)
catScroll.BackgroundTransparency = 1
catScroll.ScrollBarThickness = 0
catScroll.ScrollingDirection = Enum.ScrollingDirection.X
catScroll.Parent = filterBar

local cl = Instance.new("UIListLayout")
cl.FillDirection = Enum.FillDirection.Horizontal
cl.Padding = UDim.new(0, 5)
cl.Parent = catScroll

-- Grid
local itemScroll = Instance.new("ScrollingFrame")
itemScroll.Name = "ItemGrid"
itemScroll.Size = UDim2.new(1, -20, 1, -60)
itemScroll.Position = UDim2.new(0, 20, 0, 60)
itemScroll.BackgroundTransparency = 1
itemScroll.ScrollBarThickness = 4
itemScroll.ScrollBarImageColor3 = THEME.COLORS.PRIMARY_DIM
itemScroll.Parent = gridSide

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 140, 0, 160)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.Parent = itemScroll

-- B. INSPECTOR SIDE
local inspectorSide = Instance.new("Frame")
inspectorSide.Name = "Inspector"
inspectorSide.Size = UDim2.new(0.4, 0, 1, 0)
inspectorSide.Position = UDim2.new(0.6, 0, 0, 0)
inspectorSide.BackgroundColor3 = THEME.COLORS.BG_PANEL
inspectorSide.BorderSizePixel = 0
inspectorSide.Parent = splitContainer

local inspBorder = Instance.new("Frame")
inspBorder.Size = UDim2.new(0, 1, 1, 0)
inspBorder.BackgroundColor3 = THEME.COLORS.BORDER
inspBorder.BorderSizePixel = 0
inspBorder.Parent = inspectorSide

-- Viewport (Top half)
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, 0, 0.45, 0)
viewport.BackgroundTransparency = 1
viewport.LightColor = Color3.fromRGB(255, 240, 220)
viewport.LightDirection = Vector3.new(-1, -0.5, -1)
viewport.Parent = inspectorSide

-- Viewport "Scanline" animation (Purely visual)
local scanLine = Instance.new("Frame")
scanLine.Size = UDim2.new(1, 0, 0, 2)
scanLine.BackgroundColor3 = THEME.COLORS.PRIMARY
scanLine.BackgroundTransparency = 0.5
scanLine.Parent = viewport
task.spawn(function()
	while viewport.Parent do
		scanLine.Position = UDim2.new(0,0,0,0)
		TweenService:Create(scanLine, TweenInfo.new(2, Enum.EasingStyle.Linear), {Position = UDim2.new(0,0,1,0)}):Play()
		task.wait(2.5)
	end
end)

-- Details (Bottom half)
local detailsFrame = Instance.new("Frame")
detailsFrame.Size = UDim2.new(1, -30, 0.55, -20)
detailsFrame.Position = UDim2.new(0, 15, 0.45, 10)
detailsFrame.BackgroundTransparency = 1
detailsFrame.Parent = inspectorSide

local dName = Instance.new("TextLabel")
dName.Text = "WEAPON NAME"
dName.Font = THEME.FONTS.TITLE
dName.TextSize = 26
dName.TextColor3 = THEME.COLORS.TEXT_MAIN
dName.Size = UDim2.new(1, 0, 0, 30)
dName.TextXAlignment = Enum.TextXAlignment.Left
dName.BackgroundTransparency = 1
dName.Parent = detailsFrame

local dType = Instance.new("TextLabel")
dType.Text = "RIFLE // AUTOMATIC"
dType.Font = THEME.FONTS.TECH
dType.TextSize = 12
dType.TextColor3 = THEME.COLORS.PRIMARY
dType.Size = UDim2.new(1, 0, 0, 15)
dType.Position = UDim2.new(0, 0, 0, 30)
dType.TextXAlignment = Enum.TextXAlignment.Left
dType.BackgroundTransparency = 1
dType.Parent = detailsFrame

-- Stats Grid
local statsGrid = Instance.new("Frame")
statsGrid.Size = UDim2.new(1, 0, 0, 100)
statsGrid.Position = UDim2.new(0, 0, 0, 60)
statsGrid.BackgroundTransparency = 1
statsGrid.Parent = detailsFrame

local sl = Instance.new("UIListLayout")
sl.Padding = UDim.new(0, 8)
sl.Parent = statsGrid

-- Equip Button
local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(1, 0, 0, 50)
equipBtn.Position = UDim2.new(0, 0, 1, 0)
equipBtn.AnchorPoint = Vector2.new(0, 1)
equipBtn.BackgroundColor3 = THEME.COLORS.PRIMARY
equipBtn.Text = ""
equipBtn.AutoButtonColor = false
equipBtn.Parent = detailsFrame

local ec = Instance.new("UICorner"); ec.CornerRadius = UDim.new(0, 4); ec.Parent = equipBtn
local el = Instance.new("TextLabel")
el.Text = "EQUIP ITEM"
el.Font = THEME.FONTS.HEADER
el.TextSize = 16
el.TextColor3 = THEME.COLORS.TEXT_MAIN
el.Size = UDim2.new(1,0,1,0)
el.BackgroundTransparency = 1
el.Parent = equipBtn

-- SKINS DROPDOWN (Mini grid inside details)
local skinsLabel = Instance.new("TextLabel")
skinsLabel.Text = "VARIANTS / SKINS"
skinsLabel.Font = THEME.FONTS.TECH
skinsLabel.TextSize = 10
skinsLabel.TextColor3 = THEME.COLORS.TEXT_DIM
skinsLabel.Size = UDim2.new(1, 0, 0, 15)
skinsLabel.Position = UDim2.new(0, 0, 1, -110)
skinsLabel.TextXAlignment = Enum.TextXAlignment.Left
skinsLabel.BackgroundTransparency = 1
skinsLabel.Parent = detailsFrame

local skinsArea = Instance.new("ScrollingFrame")
skinsArea.Size = UDim2.new(1, 0, 0, 50)
skinsArea.Position = UDim2.new(0, 0, 1, -60)
skinsArea.BackgroundTransparency = 1
skinsArea.BorderSizePixel = 0
skinsArea.ScrollingDirection = Enum.ScrollingDirection.X
skinsArea.Parent = detailsFrame

local sal = Instance.new("UIListLayout")
sal.FillDirection = Enum.FillDirection.Horizontal
sal.Padding = UDim.new(0, 5)
sal.Parent = skinsArea


-- --- LOGIC HELPERS ---

local categoryButtons = {}
local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol"}

local function createStatBar(name, color, parent)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 24)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Text = name
	lbl.Font = THEME.FONTS.TECH
	lbl.TextSize = 10
	lbl.TextColor3 = THEME.COLORS.TEXT_DIM
	lbl.Size = UDim2.new(0.3, 0, 1, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.BackgroundTransparency = 1
	lbl.Parent = f

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0.5, 0, 0.3, 0)
	bg.Position = UDim2.new(0.3, 0, 0.35, 0)
	bg.BackgroundColor3 = Color3.new(0,0,0)
	bg.BackgroundTransparency = 0.5
	bg.BorderSizePixel = 0
	bg.Parent = f

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local val = Instance.new("TextLabel")
	val.Text = "0"
	val.Font = THEME.FONTS.TECH
	val.TextSize = 10
	val.TextColor3 = THEME.COLORS.TEXT_MAIN
	val.Size = UDim2.new(0.2, 0, 1, 0)
	val.Position = UDim2.new(0.8, 0, 0, 0)
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.BackgroundTransparency = 1
	val.Parent = f

	return fill, val
end

local statDmg, valDmg = createStatBar("DMG", THEME.COLORS.ACCENT_RED, statsGrid)
local statRpm, valRpm = createStatBar("RPM", THEME.COLORS.PRIMARY, statsGrid)
local statRec, valRec = createStatBar("STAB", THEME.COLORS.ACCENT_GREEN, statsGrid)

local function updateNavState(tab)
	currentTab = tab
	-- Reset styles
	navWeapons.BackgroundTransparency = 1
	navBoosters.BackgroundTransparency = 1

	-- Highlight active
	if tab == "Weapons" then
		navWeapons.BackgroundTransparency = 0.8
		itemScroll.Visible = true
		inspectorSide.Visible = true
		-- Rebuild grid
		updateWeaponList()
	else
		navBoosters.BackgroundTransparency = 0.8
		itemScroll.Visible = true
		-- Hide inspector for boosters (or different inspector)
		inspectorSide.Visible = false
		updateBoosterList()
	end
end

-- --- CORE UPDATE FUNCTIONS ---

function updateWeaponList()
	-- Clear Grid
	for _, c in ipairs(itemScroll:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
	end

	local term = search.Text:lower()
	local list = {}

	for id, data in pairs(WeaponModule.Weapons) do
		local catMatch = (selectedCategory == "All") or (data.Category == selectedCategory)
		if selectedCategory == "Rifle" and data.Category == "Assault Rifle" then catMatch = true end

		local searchMatch = (term == "") or string.find(id:lower(), term, 1, true) or string.find((data.DisplayName or ""):lower(), term, 1, true)

		if catMatch and searchMatch then
			table.insert(list, {id=id, name=data.DisplayName or id})
		end
	end
	table.sort(list, function(a,b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = (w.id == selectedWeapon) and THEME.COLORS.ITEM_HOVER or THEME.COLORS.ITEM_BG
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = itemScroll

		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
		if w.id == selectedWeapon then
			local bs = Instance.new("UIStroke")
			bs.Color = THEME.COLORS.PRIMARY
			bs.Thickness = 2
			bs.Parent = btn
		end

		-- Weapon Name
		local n = Instance.new("TextLabel")
		n.Text = w.name
		n.Font = THEME.FONTS.HEADER
		n.TextSize = 14
		n.TextColor3 = THEME.COLORS.TEXT_MAIN
		n.Size = UDim2.new(1, -10, 0, 20)
		n.Position = UDim2.new(0, 5, 0, 5)
		n.BackgroundTransparency = 1
		n.Parent = btn

		-- Image Placeholder (Ideally we'd have icons)
		local ph = Instance.new("TextLabel")
		ph.Text = string.sub(w.name, 1, 2)
		ph.Font = THEME.FONTS.TITLE
		ph.TextSize = 30
		ph.TextColor3 = THEME.COLORS.TEXT_DIM
		ph.Size = UDim2.new(1, 0, 1, -20)
		ph.Position = UDim2.new(0, 0, 0, 20)
		ph.BackgroundTransparency = 1
		ph.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			if inventoryData and inventoryData.Skins then
				selectedSkin = inventoryData.Skins.Equipped[selectedWeapon] or "Default Skin"
			end
			updateWeaponList()
			updateDetails(selectedWeapon)
		end)
	end
end

function updateDetails(weaponName)
	if not weaponName then return end
	local data = WeaponModule.Weapons[weaponName]
	if not data then return end

	dName.Text = string.upper(data.DisplayName or weaponName)
	dType.Text = string.upper(data.Category or "UNKNOWN CLASS")

	-- Update Stats
	local function animStat(bar, label, val, max)
		label.Text = tostring(val)
		local pct = math.clamp(val/max, 0, 1)
		TweenService:Create(bar, TweenInfo.new(0.4), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
	end

	animStat(statDmg, valDmg, data.Damage or 0, 100)
	animStat(statRpm, valRpm, math.floor(60 / (data.FireRate or 1)), 1000)
	animStat(statRec, valRec, 5 - (data.Recoil or 0), 5) -- Inverse recoil for stability

	-- Update Skins
	for _, c in ipairs(skinsArea:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
	end

	if inventoryData and inventoryData.Skins then
		local owned = inventoryData.Skins.Owned[weaponName] or {}
		local equipped = inventoryData.Skins.Equipped[weaponName]

		local allSkins = {}
		if data.Skins then for k,_ in pairs(data.Skins) do table.insert(allSkins, k) end end
		table.sort(allSkins)

		-- Always add Default
		local hasDefault = false
		for _,s in ipairs(allSkins) do if s == "Default Skin" then hasDefault=true end end
		if not hasDefault then table.insert(allSkins, 1, "Default Skin") end

		for _, sName in ipairs(allSkins) do
			local sData = data.Skins and data.Skins[sName]
			local isOwned = (sName == "Default Skin")
			for _, o in ipairs(owned) do if o == sName then isOwned = true break end end

			local item = Instance.new("TextButton")
			item.Size = UDim2.new(0, 40, 0, 40)
			item.BackgroundColor3 = (sName == selectedSkin) and THEME.COLORS.PRIMARY or THEME.COLORS.ITEM_BG
			item.Text = ""
			item.Parent = skinsArea
			local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 4); ic.Parent = item

			-- Color swatch if possible, or just icon
			if sData and sData.TextureId then
				-- simplified for now
			end

			if not isOwned then
				local l = Instance.new("TextLabel")
				l.Text = "🔒"
				l.Size = UDim2.new(1,0,1,0)
				l.BackgroundTransparency = 1
				l.Parent = item
			end

			item.MouseButton1Click:Connect(function()
				selectedSkin = sName
				updateDetails(weaponName) -- refresh highlights
				updatePreview(weaponName, sName)
			end)
		end

		-- Equip Button State
		local isCurrentOwned = (selectedSkin == "Default Skin")
		for _, o in ipairs(owned) do if o == selectedSkin then isCurrentOwned = true end end

		if selectedSkin == equipped then
			el.Text = "EQUIPPED"
			equipBtn.BackgroundColor3 = THEME.COLORS.ITEM_BG
		elseif isCurrentOwned then
			el.Text = "EQUIP"
			equipBtn.BackgroundColor3 = THEME.COLORS.PRIMARY
		else
			el.Text = "LOCKED"
			equipBtn.BackgroundColor3 = THEME.COLORS.BORDER
		end
	end

	updatePreview(weaponName, selectedSkin)
end

function updatePreview(weaponName, skinName)
	if currentPreview then
		ModelPreviewModule.destroy(currentPreview)
		currentPreview = nil
	end
	if not weaponName then return end

	local wData = WeaponModule.Weapons[weaponName]
	local sData = wData and wData.Skins and wData.Skins[skinName]

	currentPreview = ModelPreviewModule.create(viewport, wData, sData, function(prev)
		if prev == currentPreview then
			ModelPreviewModule.startRotation(prev, 1.0)
		end
	end)
end

function updateBoosterList()
	-- Simple grid for boosters
	for _, c in ipairs(itemScroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

	if not boosterData or not boosterConfig then return end

	for id, info in pairs(boosterConfig) do
		local count = boosterData.Owned[id] or 0

		local card = Instance.new("Frame")
		card.BackgroundColor3 = THEME.COLORS.ITEM_BG
		card.Parent = itemScroll
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = card

		local name = Instance.new("TextLabel")
		name.Text = info.Name or id
		name.Font = THEME.FONTS.HEADER
		name.TextColor3 = THEME.COLORS.TEXT_MAIN
		name.Size = UDim2.new(1,0,0,20)
		name.BackgroundTransparency = 1
		name.Parent = card

		local qty = Instance.new("TextLabel")
		qty.Text = "x"..count
		qty.Font = THEME.FONTS.TECH
		qty.TextColor3 = THEME.COLORS.PRIMARY
		qty.Position = UDim2.new(0,0,0.5,0)
		qty.Size = UDim2.new(1,0,0,20)
		qty.BackgroundTransparency = 1
		qty.Parent = card

		local useBtn = Instance.new("TextButton")
		useBtn.Size = UDim2.new(0.8, 0, 0, 30)
		useBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
		useBtn.BackgroundColor3 = (count > 0) and THEME.COLORS.PRIMARY or THEME.COLORS.BORDER
		useBtn.Text = "USE"
		useBtn.Font = THEME.FONTS.HEADER
		useBtn.TextColor3 = THEME.COLORS.TEXT_MAIN
		useBtn.Parent = card
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = useBtn

		useBtn.MouseButton1Click:Connect(function()
			if count > 0 then ActivateBoosterEvent:FireServer(id) end
		end)
	end
end

-- --- CATEGORY TABS ---
local function setupCats()
	for _, c in ipairs(catScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, cat in ipairs(CATEGORIES) do
		local b = Instance.new("TextButton")
		b.Text = cat
		b.Size = UDim2.new(0, 60, 1, 0)
		b.BackgroundColor3 = (cat == selectedCategory) and THEME.COLORS.PRIMARY or THEME.COLORS.ITEM_BG
		b.TextColor3 = THEME.COLORS.TEXT_MAIN
		b.Parent = catScroll
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = b
		b.MouseButton1Click:Connect(function()
			selectedCategory = cat
			setupCats()
			updateWeaponList()
		end)
	end
end

-- --- CONNECTIONS ---
openButton.MouseButton1Click:Connect(function()
	if not inventoryData then inventoryData = inventoryRemote:InvokeServer() end
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0.8, 0, 0.8, 0) -- pop effect
	openButton.Visible = false
	TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0.9, 0, 0.85, 0)}):Play()

	updateNavState("Weapons")
	setupCats()

	if not selectedWeapon then
		for k,_ in pairs(WeaponModule.Weapons) do selectedWeapon = k break end
	end
	updateDetails(selectedWeapon)
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	openButton.Visible = true
	if currentPreview then ModelPreviewModule.destroy(currentPreview) currentPreview=nil end
end)

navWeapons.MouseButton1Click:Connect(function() updateNavState("Weapons") end)
navBoosters.MouseButton1Click:Connect(function() updateNavState("Boosters") end)

search:GetPropertyChangedSignal("Text"):Connect(updateWeaponList)

equipBtn.MouseButton1Click:Connect(function()
	if selectedWeapon and selectedSkin then
		skinEvent:FireServer("EquipSkin", selectedWeapon, selectedSkin)
		inventoryData.Skins.Equipped[selectedWeapon] = selectedSkin
		updateDetails(selectedWeapon)
	end
end)

BoosterUpdateEvent.OnClientEvent:Connect(function(d)
	boosterData = d
	if currentTab == "Boosters" then updateBoosterList() end
end)

-- Responsive Handler
local function handleResize()
	updateDeviceType()
	if isMobile then
		-- Mobile Layout Shifts
		openButton.Size = UDim2.new(0, 60, 0, 60)
		sidebar.Size = UDim2.new(0, 60, 1, 0)
		contentArea.Size = UDim2.new(1, -60, 1, 0)
		contentArea.Position = UDim2.new(0, 60, 0, 0)

		-- On mobile, make grid full width and inspector a modal popup?
		-- For simplicity in this iteration: Stack them 50/50 vertically
		gridSide.Size = UDim2.new(1, 0, 0.5, 0)
		inspectorSide.Size = UDim2.new(1, 0, 0.5, 0)
		inspectorSide.Position = UDim2.new(0, 0, 0.5, 0)

		gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
	else
		-- Desktop
		openButton.Size = UDim2.new(0, 120, 0, 50)
		sidebar.Size = UDim2.new(0, 80, 1, 0)
		contentArea.Size = UDim2.new(1, -80, 1, 0)
		contentArea.Position = UDim2.new(0, 80, 0, 0)

		gridSide.Size = UDim2.new(0.6, 0, 1, 0)
		inspectorSide.Size = UDim2.new(0.4, 0, 1, 0)
		inspectorSide.Position = UDim2.new(0.6, 0, 0, 0)

		gridLayout.CellSize = UDim2.new(0, 140, 0, 160)
	end
end

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(handleResize)
task.spawn(function()
	local s, r = pcall(function() return GetBoosterConfig:InvokeServer() end)
	if s then boosterConfig = r end
end)

task.wait(0.1)
handleResize()
