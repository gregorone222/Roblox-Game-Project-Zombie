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
local playerGui = player:WaitForChild("PlayerGui")

-- --- THEME CONFIGURATION ---
local THEME = {
	COLORS = {
		CANVAS_BG = Color3.fromRGB(80, 70, 55),       -- Backpack fabric
		POCKET_BG = Color3.fromRGB(60, 55, 45),       -- Pocket inner
		POCKET_DARK = Color3.fromRGB(45, 40, 35),     -- Darker pocket
		STRAP = Color3.fromRGB(100, 85, 60),          -- Leather straps
		ACCENT_ZIP = Color3.fromRGB(200, 180, 100),   -- Zipper/Gold
		HIGHLIGHT = Color3.fromRGB(255, 200, 80),     -- Selection highlight
		TEXT_MAIN = Color3.fromRGB(240, 230, 210),    -- Light text
		TEXT_DARK = Color3.fromRGB(30, 25, 20),       -- Dark text
		STITCH = Color3.fromRGB(150, 140, 120),       -- Stitching color
	},
	FONTS = {
		TITLE = Enum.Font.PermanentMarker,
		HEADER = Enum.Font.GothamBold,
		BODY = Enum.Font.Gotham,
	}
}

-- --- HELPER FUNCTIONS ---
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function addStitching(parent)
	create("UIStroke", {
		Parent = parent,
		Color = THEME.COLORS.STITCH,
		Thickness = 2,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

-- --- UI CREATION ---
local screenGui = create("ScreenGui", {
	Name = "InventoryUI",
	Parent = playerGui,
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 10
})

-- Initialize Blur Effect
local camera = workspace.CurrentCamera
local blurEffect = create("BlurEffect", {
	Name = "InventoryBlur",
	Size = 0,
	Enabled = false,
	Parent = camera
})

-- Module & Event References
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

-- Safe Remote Retrieval
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
local inventoryRemote
if RemoteFunctions then
	inventoryRemote = RemoteFunctions:WaitForChild("GetInventoryData", 5)
else
	warn("InventoryUI: RemoteFunctions folder not found!")
end

local skinEvent = ReplicatedStorage.RemoteEvents:WaitForChild("SkinManagementEvent", 5)

-- --- STATE VARIABLES ---
local selectedCategory = "All"
local selectedWeapon = nil
local currentTab = "Weapons"
local currentPreview = nil
local inventoryData = nil

-- --- MAIN PANEL ---
local mainPanel = create("Frame", {
	Name = "MainPanel",
	Parent = screenGui,
	Size = UDim2.new(0.85, 0, 0.85, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.COLORS.CANVAS_BG,
	Visible = false,
	ZIndex = 100
})
addCorner(mainPanel, 12)
addStitching(mainPanel)

-- Zipper Top
local zipper = create("Frame", {
	Parent = mainPanel,
	Size = UDim2.new(1, 0, 0, 10),
	Position = UDim2.new(0, 0, 0.12, -5),
	BackgroundColor3 = Color3.new(0.1, 0.1, 0.1),
	BorderSizePixel = 0,
	ZIndex = 105
})

-- Close Button (Zipper Pull)
local closeBtn = create("TextButton", {
	Parent = zipper,
	Size = UDim2.new(0, 30, 0, 60),
	Position = UDim2.new(0.95, 0, 0, -20),
	BackgroundColor3 = THEME.COLORS.ACCENT_ZIP,
	Text = "X",
	TextColor3 = Color3.new(0, 0, 0),
	TextSize = 18,
	Font = Enum.Font.GothamBold,
	ZIndex = 110
})
addCorner(closeBtn, 15)

-- Content Container
local content = create("Frame", {
	Parent = mainPanel,
	Size = UDim2.new(1, -40, 1, -100),
	Position = UDim2.new(0, 20, 0, 80),
	BackgroundTransparency = 1,
	ZIndex = 102
})

-- 1. Sidebar (Straps)
local sidebar = create("Frame", {
	Parent = content,
	Size = UDim2.new(0, 200, 1, 0),
	BackgroundTransparency = 1
})

create("UIListLayout", {
	Parent = sidebar,
	Padding = UDim.new(0, 10)
})

local function createTab(name)
	local btn = create("TextButton", {
		Name = name,
		Parent = sidebar,
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = THEME.COLORS.STRAP,
		Text = name:upper(),
		TextColor3 = THEME.COLORS.TEXT_MAIN,
		Font = THEME.FONTS.HEADER,
		TextSize = 18
	})
	addCorner(btn, 8)
	addStitching(btn)
	return btn
end

local tWeapons = createTab("Weapons")

-- 2. Grid Area (Pockets)
local gridArea = create("Frame", {
	Parent = content,
	Size = UDim2.new(1, -220, 1, 0),
	Position = UDim2.new(0, 220, 0, 0),
	BackgroundTransparency = 1
})

-- Filter Pockets
local filterRow = create("ScrollingFrame", {
	Parent = gridArea,
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundTransparency = 1,
	ScrollBarThickness = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	CanvasSize = UDim2.new(2, 0, 0, 0)
})

create("UIListLayout", {
	Parent = filterRow,
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 5)
})

-- Item Grid
local itemGrid = create("ScrollingFrame", {
	Parent = gridArea,
	Size = UDim2.new(0.6, 0, 1, -50),
	Position = UDim2.new(0, 0, 0, 50),
	BackgroundColor3 = THEME.COLORS.POCKET_BG,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0
})
addCorner(itemGrid, 8)

create("UIGridLayout", {
	Parent = itemGrid,
	CellSize = UDim2.new(0, 100, 0, 100),
	CellPadding = UDim2.new(0, 10, 0, 10)
})

create("UIPadding", {
	Parent = itemGrid,
	PaddingTop = UDim.new(0, 10),
	PaddingLeft = UDim.new(0, 10)
})

-- 3. Inspector Panel
local inspector = create("Frame", {
	Parent = gridArea,
	Size = UDim2.new(0.38, 0, 1, -50),
	Position = UDim2.new(0.62, 0, 0, 50),
	BackgroundColor3 = THEME.COLORS.POCKET_DARK
})
addCorner(inspector, 8)
addStitching(inspector)

local vp = create("ViewportFrame", {
	Parent = inspector,
	Size = UDim2.new(1, 0, 0.5, 0),
	BackgroundTransparency = 1
})

local info = create("Frame", {
	Parent = inspector,
	Size = UDim2.new(1, -20, 0.5, -20),
	Position = UDim2.new(0, 10, 0.5, 10),
	BackgroundTransparency = 1
})

local iName = create("TextLabel", {
	Parent = info,
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundTransparency = 1,
	Text = "SELECT ITEM",
	TextColor3 = THEME.COLORS.TEXT_MAIN,
	Font = THEME.FONTS.TITLE,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Left
})

local equipBtn = create("TextButton", {
	Parent = info,
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 1, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = THEME.COLORS.ACCENT_ZIP,
	Text = "EQUIP",
	Font = THEME.FONTS.HEADER,
	TextSize = 20,
	TextColor3 = THEME.COLORS.TEXT_DARK
})
addCorner(equipBtn, 8)

-- --- OPEN BUTTON (HUD) ---
local openButton = create("TextButton", {
	Name = "OpenInventoryBtn",
	Parent = screenGui,
	Size = UDim2.new(0, 60, 0, 60),
	Position = UDim2.new(0.02, 0, 0.55, 0),
	BackgroundColor3 = THEME.COLORS.CANVAS_BG,
	Text = "BAG",
	TextColor3 = THEME.COLORS.TEXT_MAIN,
	Font = THEME.FONTS.HEADER,
	TextSize = 14
})
addCorner(openButton, 8)
addStitching(openButton)

-- --- LOGIC ---
local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol", "LMG"}

local function updateDetails(id)
	if not WeaponModule or not WeaponModule.Weapons then return end
	local data = WeaponModule.Weapons[id]
	if not data then return end
	iName.Text = data.DisplayName or id

	if currentPreview then ModelPreviewModule.destroy(currentPreview) end

	-- Default skin preview
	local sData = nil
	if data.Skins then
		for k, v in pairs(data.Skins) do
			if k == "Default Skin" then sData = v break end
		end
		if not sData then
			local k, v = next(data.Skins)
			sData = v
		end
	end

	if sData then
		currentPreview = ModelPreviewModule.create(vp, data, sData)
		ModelPreviewModule.startRotation(currentPreview, 1)
	end
end

local function updateWeaponList()
	-- Clean grid
	for _, c in ipairs(itemGrid:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	if not WeaponModule or not WeaponModule.Weapons then
		warn("InventoryUI: WeaponModule not loaded correctly.")
		return
	end

	local list = {}
	for id, data in pairs(WeaponModule.Weapons) do
		local match = false
		if selectedCategory == "All" then
			match = true
		elseif data.Category then
			if string.find(string.lower(data.Category), string.lower(selectedCategory)) then
				match = true
			end
		end

		if match then
			table.insert(list, {id = id, name = data.DisplayName or id})
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local btn = create("TextButton", {
			Parent = itemGrid,
			BackgroundColor3 = (w.id == selectedWeapon) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.POCKET_BG,
			Text = ""
		})
		addCorner(btn, 6)
		addStitching(btn)

		create("TextLabel", {
			Parent = btn,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = string.sub(w.name, 1, 2),
			TextSize = 30,
			Font = THEME.FONTS.HEADER,
			TextColor3 = (w.id == selectedWeapon) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		})

		create("TextLabel", {
			Parent = btn,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 1, -20),
			BackgroundTransparency = 1,
			Text = w.name,
			TextSize = 10,
			Font = THEME.FONTS.BODY,
			TextColor3 = (w.id == selectedWeapon) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN
		})

		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			updateWeaponList()
			updateDetails(w.id)
		end)
	end
end

local function updateFilters()
	for _, c in ipairs(filterRow:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for _, cat in ipairs(CATEGORIES) do
		local b = create("TextButton", {
			Parent = filterRow,
			Text = cat,
			Size = UDim2.new(0, 80, 1, 0),
			BackgroundColor3 = (selectedCategory == cat) and THEME.COLORS.HIGHLIGHT or THEME.COLORS.STRAP,
			TextColor3 = (selectedCategory == cat) and THEME.COLORS.TEXT_DARK or THEME.COLORS.TEXT_MAIN,
			Font = THEME.FONTS.BODY
		})
		addCorner(b, 4)

		b.MouseButton1Click:Connect(function()
			selectedCategory = cat
			updateFilters()
			if currentTab == "Weapons" then updateWeaponList() end
		end)
	end
end

-- --- MAIN EVENTS ---
openButton.MouseButton1Click:Connect(function()
	print("InventoryUI: Open Button Clicked")
	mainPanel.Visible = true
	mainPanel.Size = UDim2.new(0.5, 0, 0.5, 0)
	mainPanel:TweenSize(UDim2.new(0.85, 0, 0.85, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
	openButton.Visible = false

	-- Enable Blur
	if blurEffect then
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 15}):Play()
	end

	updateFilters()
	updateWeaponList()
end)

closeBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = false
	openButton.Visible = true

	-- Disable Blur
	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.3, function() blurEffect.Enabled = false end)
	end
end)

tWeapons.MouseButton1Click:Connect(function()
	currentTab = "Weapons"
	itemGrid.Visible = true
	inspector.Visible = true
	updateWeaponList()
end)

-- Initial Data Load
task.spawn(function()
	if inventoryRemote then
		local s, d = pcall(function() return inventoryRemote:InvokeServer() end)
		if s then
			inventoryData = d
		else
			warn("InventoryUI: Failed to fetch data from server.")
		end
	end
end)

print("InventoryUI Loaded")
