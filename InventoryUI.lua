-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
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

-- --- RESPONSIVE DESIGN SYSTEM ---
local COLORS = {
	BG_DARK = Color3.fromRGB(5, 8, 20),      -- Slate 950 (More Opaque feel)
	PANEL_BG = Color3.fromRGB(15, 23, 42),   -- Slate 900
	PANEL_BORDER = Color3.fromRGB(30, 41, 59), -- Slate 800
	PRIMARY = Color3.fromRGB(6, 182, 212),   -- Cyan 500
	PRIMARY_GLOW = Color3.fromRGB(34, 211, 238), -- Cyan 400
	TEXT_WHITE = Color3.fromRGB(241, 245, 249), -- Slate 100
	TEXT_GRAY = Color3.fromRGB(148, 163, 184),  -- Slate 400
	ACCENT_AMBER = Color3.fromRGB(245, 158, 11), -- Amber 500
	ACCENT_RED = Color3.fromRGB(239, 68, 68),    -- Red 500
	ACCENT_GREEN = Color3.fromRGB(34, 197, 94),  -- Green 500
	ITEM_HOVER = Color3.fromRGB(30, 41, 59),
	ITEM_ACTIVE = Color3.fromRGB(51, 65, 85)
}

local FONTS = {
	TITLE = Enum.Font.GothamBlack,
	HEADER = Enum.Font.GothamBold,
	BODY = Enum.Font.GothamMedium,
	MONO = Enum.Font.Code
}

-- --- UI STATE ---
local inventoryData = nil
local selectedWeapon = nil
local selectedSkin = nil
selectedCategory = "All"
local currentTab = "Weapons" -- "Weapons" or "Boosters"
local currentPreview = nil
local boosterConfig = nil
local boosterData = nil
local assetCache = {}

-- --- RESPONSIVE VARIABLES ---
local isMobile = UserInputService.TouchEnabled
local isTablet = false
local isDesktop = not isMobile
local screenSize = Vector2.new(1920, 1080) -- Default size

-- --- FIXED: SAFE SCREEN SIZE GETTER ---
local function getScreenSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	else
		-- Fallback to PlayerGui if camera not available
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			return playerGui.AbsoluteSize
		else
			return Vector2.new(1920, 1080) -- Final fallback
		end
	end
end

-- --- RESPONSIVE FUNCTIONS ---
local function updateDeviceType()
	local success, result = pcall(function()
		screenSize = getScreenSize()
		isMobile = UserInputService.TouchEnabled

		-- Deteksi tablet berdasarkan aspect ratio dan screen size
		local aspectRatio = screenSize.X / screenSize.Y
		isTablet = isMobile and (aspectRatio > 1.2 and aspectRatio < 1.8) and math.min(screenSize.X, screenSize.Y) > 700
		isDesktop = not isMobile
	end)

	if not success then
		-- Fallback values jika ada error
		isMobile = UserInputService.TouchEnabled
		isTablet = false
		isDesktop = not isMobile
	end
end

local function getResponsiveSize(desktopSize, mobileSize, tabletSize)
	if isDesktop then
		return desktopSize
	elseif isTablet then
		return tabletSize or ((desktopSize + mobileSize) / 2)
	else
		return mobileSize
	end
end

local function setupResponsiveSizes()
	local success, result = pcall(function()
		updateDeviceType()

		-- Main Panel Size
		local panelWidth = getResponsiveSize(0.9, 0.98, 0.95)
		local panelHeight = getResponsiveSize(0.85, 0.95, 0.9)
		mainPanel.Size = UDim2.new(panelWidth, 0, panelHeight, 0)

		-- Open Button
		local openBtnWidth = getResponsiveSize(200, 280, 240)
		local openBtnHeight = getResponsiveSize(50, 60, 55)
		openButton.Size = UDim2.new(0, openBtnWidth, 0, openBtnHeight)

		-- Layout untuk mobile/tablet
		if isMobile then
			-- Header adjustments
			headerFrame.Size = UDim2.new(1, 0, 0, 60)
			titleLabel.TextSize = 24
			titleLabel.Position = UDim2.new(0, 20, 0, 0)

			-- Tab container mobile
			tabContainer.Size = UDim2.new(1, -100, 0, 35)
			tabContainer.Position = UDim2.new(0, 50, 0.5, 0)

			-- Tab buttons mobile
			tabWeaponsBtn.Size = UDim2.new(0, 120, 1, 0)
			tabBoostersBtn.Size = UDim2.new(0, 120, 1, 0)

			-- Weapons Content Layout
			if currentTab == "Weapons" then
				-- Mobile vertical layout
				leftSidebar.Size = UDim2.new(1, 0, 0.4, 0)
				leftSidebar.Position = UDim2.new(0, 0, 0, 0)

				centerPreview.Size = UDim2.new(1, 0, 0.35, 0)
				centerPreview.Position = UDim2.new(0, 0, 0.4, 0)

				rightSidebar.Size = UDim2.new(1, 0, 0.25, 0)
				rightSidebar.Position = UDim2.new(0, 0, 0.75, 0)
				rightSidebar.AnchorPoint = Vector2.new(0, 0)

				-- Adjust weapon list height
				weaponListScroll.Size = UDim2.new(1, 0, 1, -80)

				-- Smaller preview slider for mobile
				sliderContainer.Size = UDim2.new(0, 150, 0, 30)
				sliderLabel.TextSize = 8

				-- Adjust search and filter for mobile
				filterContainer.Size = UDim2.new(1, 0, 0, 80)
				searchBox.Size = UDim2.new(1, -20, 0, 32)
				categoryScroll.Size = UDim2.new(1, 0, 0, 35)
				categoryScroll.Position = UDim2.new(0, 0, 0, 45)
			else
				-- Boosters grid mobile
				bgLayout.CellSize = UDim2.new(0, 170, 0, 200)
			end

			-- Font size adjustments for mobile
			weaponNameLabel.TextSize = 28
			weaponTypeLabel.TextSize = 10
			weaponDescLabel.TextSize = 12
			ebLabel.TextSize = 14

			-- Stats container mobile
			statsContainer.Position = UDim2.new(0, 0, 0, 90)
			statsContainer.Size = UDim2.new(1, 0, 0, 120)

			-- Skins grid mobile
			skinsHeader.Position = UDim2.new(0, 0, 1, -120)
			skinsGrid.Size = UDim2.new(1, 0, 0, 60)
			skinsGrid.Position = UDim2.new(0, 0, 1, -95)
			sgLayout.CellSize = UDim2.new(0, 50, 0, 50)

		else
			-- Desktop layout (default)
			headerFrame.Size = UDim2.new(1, 0, 0, 70)
			titleLabel.TextSize = 28
			titleLabel.Position = UDim2.new(0, 30, 0, 0)

			tabContainer.Size = UDim2.new(0, 300, 0, 40)
			tabContainer.Position = UDim2.new(0, 250, 0.5, 0)

			tabWeaponsBtn.Size = UDim2.new(0, 140, 1, 0)
			tabBoostersBtn.Size = UDim2.new(0, 140, 1, 0)

			-- Weapons Content Desktop
			leftSidebar.Size = UDim2.new(0, 300, 1, 0)
			centerPreview.Size = UDim2.new(1, -650, 1, 0)
			rightSidebar.Size = UDim2.new(0, 350, 1, 0)
			rightSidebar.Position = UDim2.new(1, 0, 0, 0)
			rightSidebar.AnchorPoint = Vector2.new(1, 0)

			weaponListScroll.Size = UDim2.new(1, 0, 1, -100)

			sliderContainer.Size = UDim2.new(0, 200, 0, 40)
			sliderLabel.TextSize = 10

			-- Boosters grid desktop
			bgLayout.CellSize = UDim2.new(0, 200, 0, 250)

			-- Font sizes desktop
			weaponNameLabel.TextSize = 36
			weaponTypeLabel.TextSize = 12
			weaponDescLabel.TextSize = 14
			ebLabel.TextSize = 16

			statsContainer.Position = UDim2.new(0, 0, 0, 110)
			statsContainer.Size = UDim2.new(1, 0, 0, 150)

			-- Skins grid desktop
			skinsHeader.Position = UDim2.new(0, 0, 1, -150)
			skinsGrid.Size = UDim2.new(1, 0, 0, 70)
			skinsGrid.Position = UDim2.new(0, 0, 1, -125)
			sgLayout.CellSize = UDim2.new(0, 60, 0, 60)
		end
	end)

	if not success then
		warn("Responsive setup failed, using default desktop layout")
		-- Fallback to desktop layout
		isMobile = false
		isTablet = false
		isDesktop = true
	end
end

-- --- UI CREATION ---

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Open Button (Retained functionality, updated style)
local openButton = Instance.new("TextButton")
openButton.Name = "OpenInventoryBtn"
openButton.Size = UDim2.new(0, 200, 0, 50)
openButton.Position = UDim2.new(0.5, 0, 0.92, 0)
openButton.AnchorPoint = Vector2.new(0.5, 1)
openButton.BackgroundColor3 = COLORS.PANEL_BG
openButton.BackgroundTransparency = 0
openButton.Text = ""
openButton.AutoButtonColor = false
openButton.Parent = screenGui

local obCorner = Instance.new("UICorner")
obCorner.CornerRadius = UDim.new(0, 12)
obCorner.Parent = openButton

local obStroke = Instance.new("UIStroke")
obStroke.Color = COLORS.PRIMARY
obStroke.Thickness = 2
obStroke.Parent = openButton

local obLabel = Instance.new("TextLabel")
obLabel.Size = UDim2.new(1, 0, 1, 0)
obLabel.BackgroundTransparency = 1
obLabel.Text = "🎒 INVENTORY"
obLabel.Font = FONTS.HEADER
obLabel.TextSize = 18
obLabel.TextColor3 = COLORS.TEXT_WHITE
obLabel.Parent = openButton

-- Main Container (The "Glass Panel")
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0.9, 0, 0.85, 0)
mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.BackgroundColor3 = COLORS.BG_DARK
mainPanel.BackgroundTransparency = 0 -- Opaque
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.ClipsDescendants = true
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainPanel

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = COLORS.PANEL_BORDER
mainStroke.Thickness = 1
mainStroke.Parent = mainPanel

-- 1. HEADER
local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 70)
headerFrame.BackgroundColor3 = COLORS.PANEL_BG
headerFrame.BackgroundTransparency = 0 -- Opaque
headerFrame.BorderSizePixel = 0
headerFrame.Parent = mainPanel

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 1)
headerLine.Position = UDim2.new(0, 0, 1, 0)
headerLine.BackgroundColor3 = COLORS.PANEL_BORDER
headerLine.BorderSizePixel = 0
headerLine.Parent = headerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "ARSENAL"
titleLabel.Font = FONTS.TITLE
titleLabel.TextSize = 28
titleLabel.TextColor3 = COLORS.TEXT_WHITE
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

-- Tab Container
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 300, 0, 40)
tabContainer.Position = UDim2.new(0, 250, 0.5, 0)
tabContainer.AnchorPoint = Vector2.new(0, 0.5)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = headerFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabContainer

local function createTabButton(id, text, icon, isActive)
	local btn = Instance.new("TextButton")
	btn.Name = id
	btn.Size = UDim2.new(0, 140, 1, 0)
	btn.BackgroundColor3 = isActive and COLORS.PRIMARY or COLORS.PANEL_BG
	btn.BackgroundTransparency = isActive and 0 or 0.8
	btn.Text = ""
	btn.Parent = tabContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = icon .. "  " .. text
	label.Font = FONTS.HEADER
	label.TextSize = 14
	label.TextColor3 = isActive and Color3.new(1,1,1) or COLORS.TEXT_GRAY
	label.Parent = btn

	return btn, label
end

local tabWeaponsBtn, tabWeaponsLbl = createTabButton("Weapons", "WEAPONS", "🔫", true)
local tabBoostersBtn, tabBoostersLbl = createTabButton("Boosters", "BOOSTERS", "⚡", false)

-- Right Header Area (Currency & Close)
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -30, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.BackgroundColor3 = COLORS.ACCENT_RED
closeButton.BackgroundTransparency = 0.8
closeButton.Text = "✕"
closeButton.TextColor3 = COLORS.ACCENT_RED
closeButton.Font = FONTS.HEADER
closeButton.TextSize = 20
closeButton.Parent = headerFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = COLORS.ACCENT_RED
closeStroke.Thickness = 1
closeStroke.Transparency = 0.5
closeStroke.Parent = closeButton


-- 2. CONTENT AREAS
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -70)
contentContainer.Position = UDim2.new(0, 0, 0, 70)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainPanel

-- A. WEAPONS TAB CONTENT
local weaponsContent = Instance.new("Frame")
weaponsContent.Name = "WeaponsContent"
weaponsContent.Size = UDim2.new(1, 0, 1, 0)
weaponsContent.BackgroundTransparency = 1
weaponsContent.Visible = true
weaponsContent.Parent = contentContainer

-- Left Sidebar (List)
local leftSidebar = Instance.new("Frame")
leftSidebar.Size = UDim2.new(0, 300, 1, 0)
leftSidebar.BackgroundColor3 = COLORS.PANEL_BG
leftSidebar.BackgroundTransparency = 0 -- Opaque
leftSidebar.BorderSizePixel = 0
leftSidebar.Parent = weaponsContent

local leftBorder = Instance.new("Frame")
leftBorder.Size = UDim2.new(0, 1, 1, 0)
leftBorder.Position = UDim2.new(1, -1, 0, 0)
leftBorder.BackgroundColor3 = COLORS.PANEL_BORDER
leftBorder.BorderSizePixel = 0
leftBorder.Parent = leftSidebar

-- Search & Filter
local filterContainer = Instance.new("Frame")
filterContainer.Size = UDim2.new(1, 0, 0, 100)
filterContainer.BackgroundTransparency = 1
filterContainer.Parent = leftSidebar

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -30, 0, 36)
searchBox.Position = UDim2.new(0.5, 0, 0, 15)
searchBox.AnchorPoint = Vector2.new(0.5, 0)
searchBox.BackgroundColor3 = Color3.new(0,0,0)
searchBox.BackgroundTransparency = 0.6
searchBox.TextColor3 = COLORS.TEXT_WHITE
searchBox.PlaceholderText = "🔍 Search weapon..."
searchBox.PlaceholderColor3 = COLORS.TEXT_GRAY
searchBox.Font = FONTS.BODY
searchBox.TextSize = 14
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = filterContainer

local sbPad = Instance.new("UIPadding")
sbPad.PaddingLeft = UDim.new(0, 12)
sbPad.Parent = searchBox

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 8)
sbCorner.Parent = searchBox

local sbStroke = Instance.new("UIStroke")
sbStroke.Color = COLORS.PANEL_BORDER
sbStroke.Thickness = 1
sbStroke.Parent = searchBox

local categoryScroll = Instance.new("ScrollingFrame")
categoryScroll.Size = UDim2.new(1, 0, 0, 40)
categoryScroll.Position = UDim2.new(0, 0, 0, 60)
categoryScroll.BackgroundTransparency = 1
categoryScroll.ScrollBarThickness = 0
categoryScroll.CanvasSize = UDim2.new(2, 0, 0, 0)
categoryScroll.ScrollingDirection = Enum.ScrollingDirection.X
categoryScroll.Parent = filterContainer

local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 8)
catLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
catLayout.VerticalAlignment = Enum.VerticalAlignment.Center
catLayout.Parent = categoryScroll

local catPadding = Instance.new("UIPadding")
catPadding.PaddingLeft = UDim.new(0, 15)
catPadding.Parent = categoryScroll

local categoryButtons = {}
local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol", "LMG"}

local weaponListScroll = Instance.new("ScrollingFrame")
weaponListScroll.Name = "WeaponList"
weaponListScroll.Size = UDim2.new(1, 0, 1, -100)
weaponListScroll.Position = UDim2.new(0, 0, 0, 100)
weaponListScroll.BackgroundTransparency = 1
weaponListScroll.BorderSizePixel = 0
weaponListScroll.ScrollBarThickness = 4
weaponListScroll.ScrollBarImageColor3 = COLORS.PANEL_BORDER
weaponListScroll.Parent = leftSidebar

local wlLayout = Instance.new("UIListLayout")
wlLayout.Padding = UDim.new(0, 4)
wlLayout.SortOrder = Enum.SortOrder.Name
wlLayout.Parent = weaponListScroll

-- Center (Preview)
local centerPreview = Instance.new("Frame")
centerPreview.Size = UDim2.new(1, -650, 1, 0) -- 300 left + 350 right = 650
centerPreview.Position = UDim2.new(0, 300, 0, 0)
centerPreview.BackgroundTransparency = 1
centerPreview.ClipsDescendants = true
centerPreview.Parent = weaponsContent

-- Grid Background
local gridBg = Instance.new("ImageLabel")
gridBg.Size = UDim2.new(2, 0, 2, 0)
gridBg.Position = UDim2.new(-0.5, 0, -0.5, 0)
gridBg.Image = "rbxassetid://2743169888" -- Generic grid texture
gridBg.ImageColor3 = COLORS.PRIMARY
gridBg.ImageTransparency = 0.95
gridBg.ScaleType = Enum.ScaleType.Tile
gridBg.TileSize = UDim2.new(0, 50, 0, 50)
gridBg.BackgroundTransparency = 1
gridBg.Parent = centerPreview

-- Viewport Frame
local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Size = UDim2.new(1, 0, 1, 0)
viewportFrame.BackgroundTransparency = 1
viewportFrame.LightColor = Color3.new(1, 1, 1)
viewportFrame.LightDirection = Vector3.new(-1, -1, -1)
viewportFrame.Parent = centerPreview

local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0, 50)
loadingLabel.Position = UDim2.new(0, 0, 0.5, 0)
loadingLabel.BackgroundTransparency = 1
loadingLabel.Text = "LOADING MODEL..."
loadingLabel.Font = FONTS.MONO
loadingLabel.TextColor3 = COLORS.TEXT_GRAY
loadingLabel.Visible = false
loadingLabel.Parent = centerPreview

-- Rotation Slider
local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(0, 200, 0, 40)
sliderContainer.Position = UDim2.new(0.5, 0, 0.9, 0)
sliderContainer.AnchorPoint = Vector2.new(0.5, 1)
sliderContainer.BackgroundTransparency = 1
sliderContainer.Visible = false -- Hidden until preview loaded
sliderContainer.Parent = centerPreview

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Text = "ROTATE VIEW"
sliderLabel.Font = FONTS.MONO
sliderLabel.TextSize = 10
sliderLabel.TextColor3 = COLORS.TEXT_GRAY
sliderLabel.Size = UDim2.new(1, 0, 0, 15)
sliderLabel.Position = UDim2.new(0, 0, 1, 0)
sliderLabel.BackgroundTransparency = 1
sliderLabel.Parent = sliderContainer

local sliderTrack = Instance.new("Frame")
sliderTrack.Size = UDim2.new(1, 0, 0, 4)
sliderTrack.Position = UDim2.new(0, 0, 0.5, 0)
sliderTrack.BackgroundColor3 = COLORS.PANEL_BORDER
sliderTrack.BorderSizePixel = 0
sliderTrack.Parent = sliderContainer

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = COLORS.PRIMARY
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderTrack

local sliderKnob = Instance.new("ImageButton")
sliderKnob.Size = UDim2.new(0, 16, 0, 16)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
sliderKnob.BackgroundColor3 = COLORS.TEXT_WHITE
sliderKnob.Parent = sliderTrack
local knobCorner = Instance.new("UICorner")
knobCorner.CornerRadius = UDim.new(1, 0)
knobCorner.Parent = sliderKnob

-- Right Sidebar (Details)
local rightSidebar = Instance.new("Frame")
rightSidebar.Size = UDim2.new(0, 350, 1, 0)
rightSidebar.Position = UDim2.new(1, 0, 0, 0)
rightSidebar.AnchorPoint = Vector2.new(1, 0)
rightSidebar.BackgroundColor3 = COLORS.PANEL_BG
rightSidebar.BackgroundTransparency = 0 -- Opaque
rightSidebar.BorderSizePixel = 0
rightSidebar.Parent = weaponsContent

local rightBorder = Instance.new("Frame")
rightBorder.Size = UDim2.new(0, 1, 1, 0)
rightBorder.BackgroundColor3 = COLORS.PANEL_BORDER
rightBorder.BorderSizePixel = 0
rightBorder.Parent = rightSidebar

local rightPadding = Instance.new("UIPadding")
rightPadding.PaddingTop = UDim.new(0, 20)
rightPadding.PaddingBottom = UDim.new(0, 20)
rightPadding.PaddingLeft = UDim.new(0, 20)
rightPadding.PaddingRight = UDim.new(0, 20)
rightPadding.Parent = rightSidebar

-- Weapon Info
local weaponTypeLabel = Instance.new("TextLabel")
weaponTypeLabel.Text = "ASSAULT RIFLE"
weaponTypeLabel.Font = FONTS.MONO
weaponTypeLabel.TextSize = 12
weaponTypeLabel.TextColor3 = COLORS.PRIMARY
weaponTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponTypeLabel.Size = UDim2.new(1, 0, 0, 20)
weaponTypeLabel.BackgroundTransparency = 1
weaponTypeLabel.Parent = rightSidebar

local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Text = "AK-47"
weaponNameLabel.Font = FONTS.TITLE
weaponNameLabel.TextSize = 36
weaponNameLabel.TextColor3 = COLORS.TEXT_WHITE
weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponNameLabel.Size = UDim2.new(1, 0, 0, 40)
weaponNameLabel.Position = UDim2.new(0, 0, 0, 20)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.Parent = rightSidebar

local weaponDescLabel = Instance.new("TextLabel")
weaponDescLabel.Text = "Senjata damage tinggi, efektif jarak menengah."
weaponDescLabel.Font = FONTS.BODY
weaponDescLabel.TextSize = 14
weaponDescLabel.TextColor3 = COLORS.TEXT_GRAY
weaponDescLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponDescLabel.TextWrapped = true
weaponDescLabel.Size = UDim2.new(1, 0, 0, 40)
weaponDescLabel.Position = UDim2.new(0, 0, 0, 60)
weaponDescLabel.BackgroundTransparency = 1
weaponDescLabel.Parent = rightSidebar

-- Stats
local statsContainer = Instance.new("Frame")
statsContainer.Size = UDim2.new(1, 0, 0, 150)
statsContainer.Position = UDim2.new(0, 0, 0, 110)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = rightSidebar

local statsLayout = Instance.new("UIListLayout")
statsLayout.Padding = UDim.new(0, 15)
statsLayout.Parent = statsContainer

local function createStatRow(name, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 35)
	frame.BackgroundTransparency = 1
	frame.Parent = statsContainer

	local label = Instance.new("TextLabel")
	label.Text = name
	label.Font = FONTS.HEADER
	label.TextSize = 12
	label.TextColor3 = COLORS.TEXT_GRAY
	label.Size = UDim2.new(0.5, 0, 0, 15)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = "Val"
	valLabel.Text = "0"
	valLabel.Font = FONTS.HEADER
	valLabel.TextSize = 12
	valLabel.TextColor3 = COLORS.TEXT_WHITE
	valLabel.Size = UDim2.new(0.5, 0, 0, 15)
	valLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valLabel.BackgroundTransparency = 1
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = frame

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 0, 20)
	barBg.BackgroundColor3 = Color3.new(0,0,0)
	barBg.BackgroundTransparency = 0.5
	barBg.BorderSizePixel = 0
	barBg.Parent = frame

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barFill

	return barFill, valLabel
end

local statDmgBar, statDmgVal = createStatRow("DAMAGE", COLORS.ACCENT_RED)
local statRpmBar, statRpmVal = createStatRow("FIRE RATE", COLORS.PRIMARY)
local statRecoilBar, statRecoilVal = createStatRow("RECOIL", COLORS.ACCENT_AMBER)

-- Skins
local skinsHeader = Instance.new("TextLabel")
skinsHeader.Text = "AVAILABLE SKINS"
skinsHeader.Font = FONTS.MONO
skinsHeader.TextSize = 10
skinsHeader.TextColor3 = COLORS.TEXT_GRAY
skinsHeader.Size = UDim2.new(1, 0, 0, 20)
skinsHeader.Position = UDim2.new(0, 0, 1, -150)
skinsHeader.TextXAlignment = Enum.TextXAlignment.Left
skinsHeader.BackgroundTransparency = 1
skinsHeader.Parent = rightSidebar

local skinsGrid = Instance.new("ScrollingFrame")
skinsGrid.Size = UDim2.new(1, 0, 0, 70)
skinsGrid.Position = UDim2.new(0, 0, 1, -125)
skinsGrid.BackgroundTransparency = 1
skinsGrid.BorderSizePixel = 0
skinsGrid.ScrollBarThickness = 4
skinsGrid.Parent = rightSidebar

local sgLayout = Instance.new("UIGridLayout")
sgLayout.CellSize = UDim2.new(0, 60, 0, 60)
sgLayout.CellPadding = UDim2.new(0, 10, 0, 10)
sgLayout.Parent = skinsGrid

-- Equip Button
local equipButton = Instance.new("TextButton")
equipButton.Size = UDim2.new(1, 0, 0, 50)
equipButton.Position = UDim2.new(0, 0, 1, 0)
equipButton.AnchorPoint = Vector2.new(0, 1)
equipButton.BackgroundColor3 = COLORS.PRIMARY
equipButton.Text = ""
equipButton.AutoButtonColor = false
equipButton.Parent = rightSidebar

local ebCorner = Instance.new("UICorner")
ebCorner.CornerRadius = UDim.new(0, 10)
ebCorner.Parent = equipButton

local ebLabel = Instance.new("TextLabel")
ebLabel.Size = UDim2.new(1, 0, 1, 0)
ebLabel.BackgroundTransparency = 1
ebLabel.Text = "EQUIP WEAPON  ›"
ebLabel.Font = FONTS.HEADER
ebLabel.TextSize = 16
ebLabel.TextColor3 = COLORS.TEXT_WHITE
ebLabel.Parent = equipButton

local ebGlow = Instance.new("ImageLabel")
ebGlow.Image = "rbxassetid://4996891970" -- Glow texture
ebGlow.ImageColor3 = COLORS.PRIMARY
ebGlow.ImageTransparency = 0.6
ebGlow.Size = UDim2.new(1, 40, 1, 40)
ebGlow.Position = UDim2.new(0, -20, 0, -20)
ebGlow.BackgroundTransparency = 1
ebGlow.ZIndex = 0
ebGlow.Parent = equipButton

-- B. BOOSTERS TAB CONTENT
local boostersContent = Instance.new("Frame")
boostersContent.Name = "BoostersContent"
boostersContent.Size = UDim2.new(1, 0, 1, 0)
boostersContent.BackgroundTransparency = 1
boostersContent.Visible = false
boostersContent.Parent = contentContainer

local boostersGrid = Instance.new("ScrollingFrame")
boostersGrid.Size = UDim2.new(1, -60, 1, -60)
boostersGrid.Position = UDim2.new(0, 30, 0, 30)
boostersGrid.BackgroundTransparency = 1
boostersGrid.BorderSizePixel = 0
boostersGrid.ScrollBarThickness = 4
boostersGrid.Parent = boostersContent

local bgLayout = Instance.new("UIGridLayout")
bgLayout.CellSize = UDim2.new(0, 200, 0, 250)
bgLayout.CellPadding = UDim2.new(0, 20, 0, 20)
bgLayout.Parent = boostersGrid

-- --- LOGIC FUNCTIONS ---

-- Helper: Create Category Filter Buttons
local function createCategoryButtons()
	for _, child in ipairs(categoryScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	categoryButtons = {}

	for _, cat in ipairs(CATEGORIES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 0, 0, 30) -- Auto width
		btn.AutomaticSize = Enum.AutomaticSize.X
		btn.BackgroundColor3 = (cat == selectedCategory) and COLORS.PRIMARY or COLORS.PANEL_BORDER
		btn.BackgroundTransparency = (cat == selectedCategory) and 0.8 or 0.8
		btn.Text = "  " .. cat .. "  "
		btn.Font = FONTS.HEADER
		btn.TextSize = 12
		btn.TextColor3 = (cat == selectedCategory) and COLORS.PRIMARY or COLORS.TEXT_GRAY
		btn.Parent = categoryScroll

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = btn

		local s = Instance.new("UIStroke")
		s.Color = (cat == selectedCategory) and COLORS.PRIMARY or COLORS.PANEL_BORDER
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedCategory = cat
			createCategoryButtons() -- Refresh visual state
			updateWeaponList()
		end)
	end
end

-- Helper: Stat Bar Animation
local function updateStat(bar, valLabel, value, max, suffix)
	valLabel.Text = tostring(value) .. (suffix or "")
	local pct = math.clamp(value / max, 0, 1)
	TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end

-- Core: Update Details Panel
local function updateDetails(weaponName)
	if not weaponName then 
		rightSidebar.Visible = false 
		return 
	end
	rightSidebar.Visible = true

	local data = WeaponModule.Weapons[weaponName]
	if not data then return end

	weaponTypeLabel.Text = string.upper(data.Category or "WEAPON")
	weaponNameLabel.Text = data.DisplayName or weaponName
	weaponDescLabel.Text = "High power " .. string.lower(data.Category or "weapon") .. " with balanced stats."

	updateStat(statDmgBar, statDmgVal, data.Damage, 100)
	updateStat(statRpmBar, statRpmVal, math.floor(60 / data.FireRate), 1000, " RPM")
	updateStat(statRecoilBar, statRecoilVal, data.Recoil, 5, "")

	-- Update Skins Grid
	for _, c in ipairs(skinsGrid:GetChildren()) do
		if not c:IsA("UIGridLayout") then c:Destroy() end
	end

	if inventoryData and inventoryData.Skins then
		local owned = inventoryData.Skins.Owned[weaponName] or {}
		local equipped = inventoryData.Skins.Equipped[weaponName]

		-- Ensure Default Skin is always there
		local allSkins = {}
		if data.Skins then
			for sName, _ in pairs(data.Skins) do
				table.insert(allSkins, sName)
			end
		end
		table.sort(allSkins)

		for _, sName in ipairs(allSkins) do
			local sData = data.Skins[sName]
			local isOwned = false
			for _, o in ipairs(owned) do if o == sName then isOwned = true break end end
			if sName == "Default Skin" then isOwned = true end

			local item = Instance.new("Frame")
			item.BackgroundColor3 = isOwned and COLORS.PANEL_BORDER or Color3.new(0,0,0)
			item.BorderSizePixel = 0
			item.Parent = skinsGrid
			local ic = Instance.new("UICorner"); ic.Parent = item

			-- Selection/Equip Status
			if sName == selectedSkin then
				local stroke = Instance.new("UIStroke")
				stroke.Color = COLORS.PRIMARY
				stroke.Thickness = 2
				stroke.Parent = item
			end

			-- Button interaction
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1,0,1,0)
			btn.BackgroundTransparency = 1
			btn.Text = ""
			btn.Parent = item
			btn.MouseButton1Click:Connect(function()
				selectedSkin = sName
				updateDetails(selectedWeapon) -- Refresh UI
				-- Update Preview
				updatePreview(selectedWeapon, selectedSkin)

				-- Update Equip Button Text
				if isOwned then
					if selectedSkin == equipped then
						ebLabel.Text = "EQUIPPED"
						equipButton.BackgroundColor3 = COLORS.ITEM_ACTIVE
						equipButton.AutoButtonColor = false
					else
						ebLabel.Text = "EQUIP SKIN"
						equipButton.BackgroundColor3 = COLORS.PRIMARY
						equipButton.AutoButtonColor = true
					end
				else
					ebLabel.Text = "LOCKED"
					equipButton.BackgroundColor3 = COLORS.ACCENT_RED
					equipButton.AutoButtonColor = false
				end
			end)

			-- Skin Preview (Texture)
			if sData.TextureId then
				local img = Instance.new("ImageLabel")
				img.Size = UDim2.new(0.8,0,0.8,0)
				img.Position = UDim2.new(0.1,0,0.1,0)
				img.BackgroundTransparency = 1
				img.Image = sData.TextureId
				img.ImageTransparency = isOwned and 0 or 0.7
				img.Parent = item
			end

			-- Lock Icon
			if not isOwned then
				local lock = Instance.new("TextLabel")
				lock.Text = "🔒"
				lock.Size = UDim2.new(1,0,1,0)
				lock.BackgroundTransparency = 1
				lock.Parent = item
			end
		end

		-- Initial Button State logic
		local isSelectedOwned = false
		if inventoryData.Skins.Owned[weaponName] then
			for _, o in ipairs(inventoryData.Skins.Owned[weaponName]) do 
				if o == selectedSkin then isSelectedOwned = true break end 
			end
		end
		if selectedSkin == "Default Skin" then isSelectedOwned = true end

		if not isSelectedOwned then
			ebLabel.Text = "LOCKED"
			equipButton.BackgroundColor3 = COLORS.ACCENT_RED
			equipButton.AutoButtonColor = false
		elseif selectedSkin == equipped then
			ebLabel.Text = "EQUIPPED"
			equipButton.BackgroundColor3 = COLORS.ITEM_ACTIVE
			equipButton.AutoButtonColor = false
		else
			ebLabel.Text = "EQUIP SKIN"
			equipButton.BackgroundColor3 = COLORS.PRIMARY
			equipButton.AutoButtonColor = true
		end
	end
end

-- Core: Update Weapon List
function updateWeaponList()
	for _, c in ipairs(weaponListScroll:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end

	local term = searchBox.Text:lower()
	local list = {}

	for id, data in pairs(WeaponModule.Weapons) do
		local catMatch = (selectedCategory == "All") or (data.Category == selectedCategory)
		-- Handle short names in category logic
		if selectedCategory == "Rifle" and data.Category == "Assault Rifle" then catMatch = true end

		local searchMatch = false
		if term == "" then
			searchMatch = true
		elseif string.find(id:lower(), term, 1, true) then
			searchMatch = true
		end

		if catMatch and searchMatch then
			table.insert(list, {id=id, name=data.DisplayName})
		end
	end

	table.sort(list, function(a,b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 50)
		btn.BackgroundColor3 = (w.id == selectedWeapon) and COLORS.ITEM_ACTIVE or Color3.new(0,0,0)
		btn.BackgroundTransparency = (w.id == selectedWeapon) and 0.0 or 0.6
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = weaponListScroll

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = btn

		-- Active Indicator
		if w.id == selectedWeapon then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0, 4, 1, 0)
			bar.BackgroundColor3 = COLORS.PRIMARY
			bar.BorderSizePixel = 0
			bar.Parent = btn
		end

		-- Icon Placeholder (or Text initials)
		local iconBox = Instance.new("Frame")
		iconBox.Size = UDim2.new(0, 34, 0, 34)
		iconBox.Position = UDim2.new(0, 12, 0.5, 0)
		iconBox.AnchorPoint = Vector2.new(0, 0.5)
		iconBox.BackgroundColor3 = COLORS.PANEL_BORDER
		iconBox.Parent = btn
		local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = iconBox

		local initials = Instance.new("TextLabel")
		initials.Size = UDim2.new(1,0,1,0)
		initials.BackgroundTransparency = 1
		initials.Text = string.sub(w.name, 1, 2)
		initials.Font = FONTS.MONO
		initials.TextColor3 = COLORS.TEXT_GRAY
		initials.Parent = iconBox

		-- Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Text = w.name
		nameLbl.Font = FONTS.HEADER
		nameLbl.TextSize = 16
		nameLbl.TextColor3 = (w.id == selectedWeapon) and COLORS.TEXT_WHITE or COLORS.TEXT_GRAY
		nameLbl.Size = UDim2.new(1, -60, 1, 0)
		nameLbl.Position = UDim2.new(0, 60, 0, 0)
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.BackgroundTransparency = 1
		nameLbl.Parent = btn

		-- Interaction
		btn.MouseEnter:Connect(function()
			if w.id ~= selectedWeapon then
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
				nameLbl.TextColor3 = COLORS.TEXT_WHITE
			end
		end)
		btn.MouseLeave:Connect(function()
			if w.id ~= selectedWeapon then
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
				nameLbl.TextColor3 = COLORS.TEXT_GRAY
			end
		end)
		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			-- Default skin selection logic
			if inventoryData and inventoryData.Skins then
				selectedSkin = inventoryData.Skins.Equipped[selectedWeapon] or "Default Skin"
			end
			updateWeaponList() -- Refresh list highlights
			updateDetails(selectedWeapon)
			updatePreview(selectedWeapon, selectedSkin)
		end)
	end
end

-- Core: Update Preview
function updatePreview(weaponName, skinName)
	if currentPreview then
		ModelPreviewModule.destroy(currentPreview)
		currentPreview = nil
	end

	if not weaponName or not skinName then
		sliderContainer.Visible = false
		loadingLabel.Visible = false
		return
	end

	local weaponData = WeaponModule.Weapons[weaponName]
	local skinData = weaponData and weaponData.Skins[skinName]
	if not weaponData or not skinData then return end

	local cacheKey = weaponName .. "_" .. skinName
	local isCached = assetCache[cacheKey]

	if not isCached then
		loadingLabel.Visible = true
	end

	currentPreview = ModelPreviewModule.create(viewportFrame, weaponData, skinData, function(loadedPreview)
		assetCache[cacheKey] = true
		loadingLabel.Visible = false

		if loadedPreview == currentPreview then
			ModelPreviewModule.startRotation(currentPreview, 2.5)
			sliderContainer.Visible = true
			ModelPreviewModule.connectZoomSlider(currentPreview, sliderTrack, sliderKnob, sliderFill, 2.5, 10)
		end
	end)
end

-- Core: Update Boosters List
function updateBoosterList()
	for _, c in ipairs(boostersGrid:GetChildren()) do
		if not c:IsA("UIGridLayout") then c:Destroy() end
	end

	if not boosterData or not boosterConfig then return end

	for id, info in pairs(boosterConfig) do
		local count = boosterData.Owned[id] or 0

		local card = Instance.new("Frame")
		card.BackgroundColor3 = COLORS.PANEL_BG
		card.BackgroundTransparency = 0.4
		card.BorderSizePixel = 0
		card.Parent = boostersGrid

		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 12); cc.Parent = card
		local cs = Instance.new("UIStroke"); cs.Color = COLORS.PANEL_BORDER; cs.Parent = card

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Text = info.Icon or "⚡"
		icon.TextSize = 40
		icon.Size = UDim2.new(1, 0, 0.4, 0)
		icon.BackgroundTransparency = 1
		icon.Parent = card

		-- Name
		local name = Instance.new("TextLabel")
		name.Text = info.Name or id
		name.Font = FONTS.HEADER
		name.TextSize = 14
		name.TextColor3 = COLORS.TEXT_WHITE
		name.Size = UDim2.new(1, 0, 0, 20)
		name.Position = UDim2.new(0, 0, 0.4, 0)
		name.BackgroundTransparency = 1
		name.Parent = card

		-- Count
		local countLbl = Instance.new("TextLabel")
		countLbl.Text = "Owned: " .. count
		countLbl.Font = FONTS.MONO
		countLbl.TextSize = 10
		countLbl.TextColor3 = (count > 0) and COLORS.PRIMARY or COLORS.TEXT_GRAY
		countLbl.Size = UDim2.new(1, 0, 0, 15)
		countLbl.Position = UDim2.new(0, 0, 0.5, 0)
		countLbl.BackgroundTransparency = 1
		countLbl.Parent = card

		-- Desc
		local desc = Instance.new("TextLabel")
		desc.Text = info.Description or ""
		desc.Font = FONTS.BODY
		desc.TextSize = 10
		desc.TextColor3 = COLORS.TEXT_GRAY
		desc.TextWrapped = true
		desc.Size = UDim2.new(0.9, 0, 0.25, 0)
		desc.Position = UDim2.new(0.05, 0, 0.55, 0)
		desc.BackgroundTransparency = 1
		desc.Parent = card

		-- Action Button
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.9, 0, 0, 30)
		btn.Position = UDim2.new(0.05, 0, 0.85, 0)
		btn.BackgroundColor3 = (count > 0) and COLORS.PRIMARY or COLORS.ACCENT_AMBER
		btn.Text = (count > 0) and "ACTIVATE" or "BUY"
		if boosterData.Active == id then 
			btn.Text = "ACTIVE"
			btn.BackgroundColor3 = COLORS.ACCENT_GREEN
		end
		btn.Font = FONTS.HEADER
		btn.TextColor3 = COLORS.TEXT_WHITE
		btn.TextSize = 12
		btn.Parent = card
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if count > 0 then
				ActivateBoosterEvent:FireServer(id)
			else
				-- Shop logic placeholder
			end
		end)
	end
end

-- --- MAIN LOGIC ---

local function switchTab(tabName)
	currentTab = tabName
	if tabName == "Weapons" then
		weaponsContent.Visible = true
		boostersContent.Visible = false

		tabWeaponsBtn.BackgroundColor3 = COLORS.PRIMARY
		tabWeaponsBtn.BackgroundTransparency = 0
		tabWeaponsLbl.TextColor3 = Color3.new(1,1,1)

		tabBoostersBtn.BackgroundColor3 = COLORS.PANEL_BG
		tabBoostersBtn.BackgroundTransparency = 0.8
		tabBoostersLbl.TextColor3 = COLORS.TEXT_GRAY
	else
		weaponsContent.Visible = false
		boostersContent.Visible = true

		tabWeaponsBtn.BackgroundColor3 = COLORS.PANEL_BG
		tabWeaponsBtn.BackgroundTransparency = 0.8
		tabWeaponsLbl.TextColor3 = COLORS.TEXT_GRAY

		tabBoostersBtn.BackgroundColor3 = COLORS.PRIMARY
		tabBoostersBtn.BackgroundTransparency = 0
		tabBoostersLbl.TextColor3 = Color3.new(1,1,1)

		if not boosterData then
			BoosterUpdateEvent:FireServer()
		else
			updateBoosterList()
		end
	end
	setupResponsiveSizes() -- Update layout when switching tabs
end

local function openUI()
	if not inventoryData then
		inventoryData = inventoryRemote:InvokeServer()
	end

	mainPanel.Visible = true
	openButton.Visible = false

	-- Apply responsive sizing before animation
	setupResponsiveSizes()

	-- Animation
	mainPanel.Size = UDim2.new(0.85, 0, 0.8, 0)
	mainPanel.BackgroundTransparency = 1

	local info = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(mainPanel, info, {Size = mainPanel.Size, BackgroundTransparency = 0}):Play()

	createCategoryButtons()
	updateWeaponList()

	-- Select first weapon if none
	if not selectedWeapon then
		-- Find AK-47 or first
		for id, _ in pairs(WeaponModule.Weapons) do
			selectedWeapon = id
			break
		end
		if WeaponModule.Weapons["AK-47"] then selectedWeapon = "AK-47" end
	end

	if inventoryData and inventoryData.Skins then
		selectedSkin = inventoryData.Skins.Equipped[selectedWeapon] or "Default Skin"
	end

	updateDetails(selectedWeapon)
	updatePreview(selectedWeapon, selectedSkin)

	switchTab("Weapons")
end

local function closeUI()
	local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(mainPanel, info, {Size = UDim2.new(0.85, 0, 0.8, 0), BackgroundTransparency = 1}):Play()

	task.delay(0.2, function()
		mainPanel.Visible = false
		openButton.Visible = true
		updatePreview(nil, nil) -- Cleanup viewport
	end)
end

-- --- MOBILE GESTURES ---
local function setupMobileGestures()
	if not isMobile then return end

	local touchStartPos = nil
	local touchStartTime = 0
	local isDragging = false

	UserInputService.TouchStarted:Connect(function(touch)
		touchStartPos = touch.Position
		touchStartTime = tick()
		isDragging = true
	end)

	UserInputService.TouchEnded:Connect(function(touch)
		if not touchStartPos or not isDragging then return end

		local touchEndPos = touch.Position
		local delta = touchEndPos - touchStartPos
		local timeDelta = tick() - touchStartTime

		-- Swipe detection
		if timeDelta < 0.5 and delta.Magnitude > 50 then
			if math.abs(delta.X) > math.abs(delta.Y) then
				-- Horizontal swipe - switch tabs
				if delta.X > 0 then
					-- Swipe right
					switchTab("Weapons")
				else
					-- Swipe left  
					switchTab("Boosters")
				end
			end
		end

		isDragging = false
		touchStartPos = nil
	end)
end

-- --- SAFE AREA SUPPORT ---
local function updateSafeArea()
	if not isMobile then return end

	local success, result = pcall(function()
		local safeArea = GuiService:GetSafeZoneInsets()

		-- Apply safe area padding to main panel
		mainPanel.Position = UDim2.new(
			0.5, 
			(safeArea.Left - safeArea.Right) / 2, 
			0.5, 
			(safeArea.Top - safeArea.Bottom) / 2
		)
	end)
end

-- --- PERFORMANCE OPTIMIZATION ---
local function optimizeForMobile()
	if isMobile then
		-- Reduce rendering quality for better performance
		settings().Rendering.QualityLevel = 1
		-- Enable frame rate throttling
		RunService:SetThrottleFramerateEnabled(true)
	end
end

-- --- CONNECTIONS ---
openButton.MouseButton1Click:Connect(openUI)
closeButton.MouseButton1Click:Connect(closeUI)

tabWeaponsBtn.MouseButton1Click:Connect(function() switchTab("Weapons") end)
tabBoostersBtn.MouseButton1Click:Connect(function() switchTab("Boosters") end)

searchBox:GetPropertyChangedSignal("Text"):Connect(updateWeaponList)

equipButton.MouseButton1Click:Connect(function()
	if selectedWeapon and selectedSkin then
		-- Double check ownership locally
		local owned = inventoryData.Skins.Owned[selectedWeapon] or {}
		local isOwned = (selectedSkin == "Default Skin")
		for _, s in ipairs(owned) do if s == selectedSkin then isOwned = true break end end

		if isOwned then
			skinEvent:FireServer("EquipSkin", selectedWeapon, selectedSkin)
			-- Optimistic update
			inventoryData.Skins.Equipped[selectedWeapon] = selectedSkin
			updateDetails(selectedWeapon) -- Refresh UI state
		end
	end
end)

BoosterUpdateEvent.OnClientEvent:Connect(function(newData)
	boosterData = newData
	if currentTab == "Boosters" then updateBoosterList() end
end)

-- Screen resize handler dengan error handling
local function handleScreenResize()
	local success, result = pcall(function()
		updateDeviceType()
		setupResponsiveSizes()
		updateSafeArea()
	end)

	if not success then
		warn("Screen resize handler failed")
	end
end

-- Gunakan PlayerGui untuk mendeteksi perubahan ukuran layar
local playerGui = player:WaitForChild("PlayerGui")
playerGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(handleScreenResize)

-- Safe area changes
GuiService:GetPropertyChangedSignal("SafeZoneCompatibility"):Connect(updateSafeArea)

-- Fetch booster config once
task.spawn(function()
	local success, result = pcall(function() return GetBoosterConfig:InvokeServer() end)
	if success then boosterConfig = result end
end)

-- Initialize responsive features dengan delay untuk memastikan semua komponen siap
task.delay(0.5, function()
	local success, result = pcall(function()
		updateDeviceType()
		setupResponsiveSizes()
		setupMobileGestures()
		updateSafeArea()
		optimizeForMobile()
	end)

	if not success then
		warn("Responsive features initialization failed, using default layout")
	end
end)
