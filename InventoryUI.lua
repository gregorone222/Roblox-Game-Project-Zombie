-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby
-- Theme: Survival Backpack (Grid Canvas, Fabric Texture, Straps)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer

-- Module & Event References
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))
local inventoryRemote = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetInventoryData")
local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent")

-- Booster-related events
local BoosterUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("BoosterUpdateEvent")
local ActivateBoosterEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ActivateBoosterEvent")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")

-- --- THEME CONFIGURATION ---
local THEME = {
	COLORS = {
		CANVAS_MAIN = Color3.fromRGB(60, 55, 50),   -- Dark Canvas
		CANVAS_LIGHT = Color3.fromRGB(80, 75, 70),  -- Lighter Canvas
		STRAP       = Color3.fromRGB(40, 35, 30),   -- Dark Strap
		STITCH      = Color3.fromRGB(120, 110, 100),-- Thread

		POCKET_BG   = Color3.fromRGB(50, 45, 40),   -- Inner Pocket
		POCKET_DARK = Color3.fromRGB(35, 30, 25),   -- Deep Pocket

		ACCENT_ZIP  = Color3.fromRGB(180, 140, 60), -- Brass/Gold Zipper
		HIGHLIGHT   = Color3.fromRGB(200, 180, 120), -- Highlight Tan

		TEXT_MAIN   = Color3.fromRGB(230, 230, 220), -- Cloth White
		TEXT_DARK   = Color3.fromRGB(30, 30, 30),    -- Ink Black
	},
	FONTS = {
		TITLE   = Enum.Font.SpecialElite,
		HEADER  = Enum.Font.GothamBold,
		BODY    = Enum.Font.GothamMedium,
	}
}

-- --- UI STATE ---
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil
local selectedCategory = "All"
local currentTab = "Weapons"
local currentPreview = nil
local boosterConfig = nil
local boosterData = nil

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

-- Helper: Create Stitching Effect
local function addStitching(parent)
	local stitch = Instance.new("UIStroke")
	stitch.Color = THEME.COLORS.STITCH
	stitch.Thickness = 2
	stitch.Transparency = 0.5
	stitch.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stitch.Parent = parent

	-- Dashed effect is hard without textures, assuming solid stitch line for now
	return stitch
end

-- Helper: Create Canvas Texture
local function addCanvasTexture(parent)
	local texture = Instance.new("ImageLabel")
	texture.Name = "CanvasTexture"
	texture.Size = UDim2.new(1,0,1,0)
	texture.BackgroundTransparency = 1
	texture.Image = "rbxassetid://6008328148" -- Noise/Fabric texture
	texture.ImageTransparency = 0.92
	texture.ImageColor3 = Color3.new(0,0,0)
	texture.ScaleType = Enum.ScaleType.Tile
	texture.TileSize = UDim2.new(0, 64, 0, 64)
	texture.ZIndex = parent.ZIndex + 1
	texture.Parent = parent
	return texture
end

-- Helper: Create Rounded Corner
local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
	return c
end

-- Open Button (Backpack Icon)
local openButton = Instance.new("TextButton")
openButton.Name = "OpenBtn"
openButton.Size = UDim2.new(0, 80, 0, 80)
openButton.Position = UDim2.new(0, 20, 0.5, 0)
openButton.AnchorPoint = Vector2.new(0, 0.5)
openButton.BackgroundColor3 = THEME.COLORS.CANVAS_MAIN
openButton.Text = ""
openButton.AutoButtonColor = false
openButton.Parent = screenGui
addCorner(openButton, 20)
addStitching(openButton)
addCanvasTexture(openButton)

local icon = Instance.new("TextLabel")
icon.Text = "🎒"
icon.Size = UDim2.new(1,0,1,0)
icon.BackgroundTransparency = 1
icon.TextSize = 40
icon.Parent = openButton

-- Main Backpack Panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "BackpackPanel"
mainPanel.Size = UDim2.new(0.85, 0, 0.85, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = THEME.COLORS.CANVAS_MAIN
mainPanel.Visible = false
mainPanel.Parent = screenGui
addCorner(mainPanel, 16)
addStitching(mainPanel)
addCanvasTexture(mainPanel)

-- Zipper Top
local zipper = Instance.new("Frame")
zipper.Size = UDim2.new(1, 0, 0, 10)
zipper.Position = UDim2.new(0, 0, 0.12, -5)
zipper.BackgroundColor3 = Color3.new(0.1,0.1,0.1)
zipper.BorderSizePixel = 0
zipper.ZIndex = 5
zipper.Parent = mainPanel
-- Zipper Teeth
local teeth = Instance.new("ImageLabel")
teeth.Size = UDim2.new(1,0,1,0)
teeth.BackgroundTransparency = 1
teeth.Image = "rbxassetid://130424513" -- Placeholder pattern
teeth.ImageColor3 = THEME.COLORS.ACCENT_ZIP
teeth.ScaleType = Enum.ScaleType.Tile
teeth.TileSize = UDim2.new(0, 10, 0, 10)
teeth.Parent = zipper

-- Close Button (Zipper Pull)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 60)
closeBtn.Position = UDim2.new(0.95, 0, 0, -20)
closeBtn.BackgroundColor3 = THEME.COLORS.ACCENT_ZIP
closeBtn.Text = ""
closeBtn.ZIndex = 6
closeBtn.Parent = zipper
addCorner(closeBtn, 15)

-- Content Container
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -100)
content.Position = UDim2.new(0, 20, 0, 80)
content.BackgroundTransparency = 1
content.Parent = mainPanel

-- 1. Sidebar (Straps)
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 200, 1, 0)
sidebar.BackgroundTransparency = 1
sidebar.Parent = content

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = sidebar

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = THEME.COLORS.STRAP
	btn.Text = name:upper()
	btn.TextColor3 = THEME.COLORS.TEXT_MAIN
	btn.Font = THEME.FONTS.HEADER
	btn.TextSize = 18
	btn.Parent = sidebar
	addCorner(btn, 8)
	addStitching(btn)
	return btn
end

local tWeapons = createTab("Weapons")
local tBoosters = createTab("Boosters")

-- 2. Grid Area (Pockets)
local gridArea = Instance.new("Frame")
gridArea.Size = UDim2.new(1, -220, 1, 0)
gridArea.Position = UDim2.new(0, 220, 0, 0)
gridArea.BackgroundTransparency = 1
gridArea.Parent = content

-- Filter Pockets
local filterRow = Instance.new("ScrollingFrame")
filterRow.Size = UDim2.new(1, 0, 0, 40)
filterRow.BackgroundTransparency = 1
filterRow.ScrollBarThickness = 0
filterRow.ScrollingDirection = Enum.ScrollingDirection.X
filterRow.CanvasSize = UDim2.new(2,0,0,0) -- Expandable
filterRow.Parent = gridArea

local fl = Instance.new("UIListLayout")
fl.FillDirection = Enum.FillDirection.Horizontal
fl.Padding = UDim.new(0, 5)
fl.Parent = filterRow

-- Item Grid (Mesh Mesh Pockets)
local itemGrid = Instance.new("ScrollingFrame")
itemGrid.Size = UDim2.new(0.6, 0, 1, -50)
itemGrid.Position = UDim2.new(0, 0, 0, 50)
itemGrid.BackgroundColor3 = THEME.COLORS.POCKET_BG
itemGrid.BackgroundTransparency = 0.5
itemGrid.BorderSizePixel = 0
itemGrid.Parent = gridArea
addCorner(itemGrid, 8)

local igl = Instance.new("UIGridLayout")
igl.CellSize = UDim2.new(0, 100, 0, 100)
igl.CellPadding = UDim2.new(0, 10, 0, 10)
igl.Parent = itemGrid
local igp = Instance.new("UIPadding")
igp.PaddingTop = UDim.new(0, 10)
igp.PaddingLeft = UDim.new(0, 10)
igp.Parent = itemGrid

-- 3. Inspector Panel (Detailed Pocket)
local inspector = Instance.new("Frame")
inspector.Size = UDim2.new(0.38, 0, 1, -50)
inspector.Position = UDim2.new(0.62, 0, 0, 50)
inspector.BackgroundColor3 = THEME.COLORS.POCKET_DARK
inspector.Parent = gridArea
addCorner(inspector, 8)
addStitching(inspector)

local vp = Instance.new("ViewportFrame")
vp.Size = UDim2.new(1, 0, 0.5, 0)
vp.BackgroundTransparency = 1
vp.Parent = inspector

local info = Instance.new("Frame")
info.Size = UDim2.new(1, -20, 0.5, -20)
info.Position = UDim2.new(0, 10, 0.5, 10)
info.BackgroundTransparency = 1
info.Parent = inspector

local iName = Instance.new("TextLabel")
iName.Size = UDim2.new(1,0,0,30)
iName.BackgroundTransparency = 1
iName.Text = "SELECT ITEM"
iName.TextColor3 = THEME.COLORS.TEXT_MAIN
iName.Font = THEME.FONTS.TITLE
iName.TextSize = 24
iName.TextXAlignment = Enum.TextXAlignment.Left
iName.Parent = info

local equipBtn = Instance.new("TextButton")
equipBtn.Size = UDim2.new(1, 0, 0, 50)
equipBtn.Position = UDim2.new(0, 0, 1, 0)
equipBtn.AnchorPoint = Vector2.new(0, 1)
equipBtn.BackgroundColor3 = THEME.COLORS.ACCENT_ZIP
equipBtn.Text = "EQUIP"
equipBtn.Font = THEME.FONTS.HEADER
equipBtn.TextSize = 20
equipBtn.TextColor3 = THEME.COLORS.TEXT_DARK
equipBtn.Parent = info
addCorner(equipBtn, 8)


-- --- LOGIC ---

local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol"}

local function updateFilters()
	for _, c in ipairs(filterRow:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, cat in ipairs(CATEGORIES) do
		local b = Instance.new("TextButton")
		b.Text = cat
		b.Size = UDim2.new(0, 80, 1, 0)
		b.BackgroundColor3 = (selectedCategory == cat) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.STRAP
		b.TextColor3 = (selectedCategory == cat) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		b.Parent = filterRow
		addCorner(b, 4)
		b.MouseButton1Click:Connect(function()
			selectedCategory = cat
			updateFilters()
			if currentTab == "Weapons" then updateWeaponList() end
		end)
	end
end

function updateWeaponList()
	for _, c in ipairs(itemGrid:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	local list = {}
	for id, data in pairs(WeaponModule.Weapons) do
		if selectedCategory == "All" or data.Category == selectedCategory then
			table.insert(list, {id=id, name=data.DisplayName or id})
		end
	end
	table.sort(list, function(a,b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = (w.id == selectedWeapon) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.POCKET_BG
		btn.Text = "" -- Icon here ideally
		btn.Parent = itemGrid
		addCorner(btn, 6)
		addStitching(btn)

		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.new(1,0,1,0)
		lb.BackgroundTransparency = 1
		lb.Text = string.sub(w.name, 1, 2)
		lb.TextSize = 30
		lb.TextColor3 = (w.id == selectedWeapon) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		lb.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			updateWeaponList()
			updateDetails(w.id)
		end)
	end
end

function updateDetails(id)
	local data = WeaponModule.Weapons[id]
	if not data then return end
	iName.Text = data.DisplayName or id

	if currentPreview then ModelPreviewModule.destroy(currentPreview) end
	-- Default skin preview
	local sData = nil
	if data.Skins then
		local k,v = next(data.Skins)
		sData = v
	end
	currentPreview = ModelPreviewModule.create(vp, data, sData)
	ModelPreviewModule.startRotation(currentPreview, 1)
end

-- --- MAIN EVENTS ---
openButton.MouseButton1Click:Connect(function()
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0.5,0,0.5,0)
	mainPanel:TweenSize(UDim2.new(0.85,0,0.85,0), "Out", "Back", 0.3, true)
	openButton.Visible = false
	updateFilters()
	updateWeaponList()
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	openButton.Visible = true
end)

tWeapons.MouseButton1Click:Connect(function()
	currentTab="Weapons"
	itemGrid.Visible=true
	inspector.Visible=true
	updateWeaponList()
end)

tBoosters.MouseButton1Click:Connect(function()
	currentTab="Boosters"
	-- Booster logic would go here, simplified for this overhaul scope
end)

-- Initial Load
task.spawn(function()
	local s, d = pcall(function() return inventoryRemote:InvokeServer() end)
	if s then inventoryData = d end
end)

return {}
