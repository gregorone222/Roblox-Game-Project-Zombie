-- APShopUI.lua (LocalScript)
-- Path: StarterGui/APShopUI.lua
-- Script Place: Lobby
-- Theme: Zombie Apocalypse (Grunge, Industrial, Survival)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULES & REMOTES
-- ============================================================================

local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))
local ProximityUIHandler = require(ModuleScriptReplicated:WaitForChild("ProximityUIHandler"))

local proximityHandler -- Forward declaration

-- Config Item Spesial
local SpecialItemsConfig = {
	SKILL_RESET_TOKEN = {
		Name = "Skill Reset Token",
		Description = "Reset your survival skills. Adapt or die.",
		APCost = 7500,
		Rarity = "Common",
		Type = "Utility",
		Unicode = "💉"
	},
	EXCLUSIVE_TITLE_COLLECTOR = {
		Name = "Title: The Collector",
		Description = "Golden mark of a true scavenger.",
		APCost = 10000,
		Rarity = "Epic",
		Type = "Titles",
		Unicode = "👑"
	},
	TITLE_SLAYER = {
		Name = "Title: Zombie Slayer",
		Description = "Let them know who the predator is.",
		APCost = 2500,
		Rarity = "Common",
		Type = "Titles",
		Unicode = "💀"
	}
}

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local purchaseSkinFunc = RemoteFunctions:WaitForChild("PurchaseSkinWithAP")
local purchaseItemFunc = RemoteFunctions:WaitForChild("PurchaseGenericItemWithAP")
local getAPFunc = ReplicatedStorage:WaitForChild("GetInitialAchievementPoints")
local apChangedEvent = ReplicatedStorage:WaitForChild("AchievementPointsChanged")

-- ============================================================================
-- CONSTANTS & THEME
-- ============================================================================

local COLORS = {
	BG_ROOT = Color3.fromRGB(25, 20, 15),       -- Muddy Brown/Black
	BG_PANEL = Color3.fromRGB(40, 35, 30),      -- Worn Metal
	BG_HOVER = Color3.fromRGB(60, 50, 40),      -- Lighter Grunge

	TEXT_MAIN = Color3.fromRGB(220, 210, 190),  -- Old Paper White
	TEXT_DIM = Color3.fromRGB(140, 130, 110),   -- Faded Ink

	ACCENT_TOXIC = Color3.fromRGB(120, 255, 50), -- Radioactive Green
	ACCENT_HAZARD = Color3.fromRGB(255, 140, 0), -- Caution Orange
	ACCENT_BLOOD = Color3.fromRGB(180, 20, 20),  -- Dried Blood

	RARITY_COMMON = Color3.fromRGB(140, 140, 140),
	RARITY_RARE = Color3.fromRGB(50, 150, 255),
	RARITY_EPIC = Color3.fromRGB(180, 50, 255),
	RARITY_LEGENDARY = Color3.fromRGB(255, 200, 50)
}

local FONTS = {
	Header = Enum.Font.SpecialElite, -- Typewriter style
	Body = Enum.Font.GothamMedium,
	Tech = Enum.Font.Code
}

local UNICODE_ICONS = {
	Search = "🔍",
	Close = "✖",
	AP = "☣️", -- Biohazard for points
	Shop = "⛺",
	Check = "✓",
	Lock = "🔒",
	Cart = "🛒",
	Gun = "🔫"
}

local TEXTURES = {
	Grunge = "rbxassetid://15264388636", -- Generic grunge/scratch texture if available, fallback to noise
	Noise = "rbxassetid://130424513"
}

local apShopUI = {}

-- UI References
local screenGui = nil
local listContainer = nil
local detailsPanel = nil
local searchInput = nil
local apValueLabel = nil
local previewViewport = nil
local previewIconLabel = nil

-- State
local state = {
	currentTab = "All",
	currentAP = 0,
	selectedItem = nil,
	activePreview = nil,
	allItemsList = {},
	isUIOpen = false
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.TEXT_DIM
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addGrunge(parent, transparency)
	local texture = create("ImageLabel", {
		Name = "GrungeOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = TEXTURES.Noise,
		ImageTransparency = transparency or 0.92,
		ImageColor3 = Color3.new(0,0,0),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 128, 0, 128),
		ZIndex = 0,
		Parent = parent
	})
	return texture
end

local function formatNumber(n)
	return tostring(math.floor(n or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function getRarityColor(rarity)
	if rarity == "Legendary" then return COLORS.RARITY_LEGENDARY end
	if rarity == "Epic" then return COLORS.RARITY_EPIC end
	if rarity == "Rare" then return COLORS.RARITY_RARE end
	return COLORS.RARITY_COMMON
end

-- ============================================================================
-- DATA HANDLING
-- ============================================================================

function apShopUI:LoadData()
	state.allItemsList = {}

	-- Load Skins
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.APCost and skinData.APCost > 0 then
				local rarity = "Rare"
				if skinData.APCost >= 20000 then rarity = "Legendary"
				elseif skinData.APCost >= 10000 then rarity = "Epic"
				end

				table.insert(state.allItemsList, {
					Id = weaponName .. "_" .. skinName,
					Name = skinName,
					Type = "Skins",
					Rarity = rarity,
					Cost = skinData.APCost,
					Desc = string.format("Paint job for %s. Grade: %s.", tostring(weaponName), tostring(rarity)),
					Unicode = UNICODE_ICONS.Gun,
					Weapon = weaponName,
					SkinName = skinName,
					Data = skinData,
					Owned = false
				})
			end
		end
	end

	-- Load Special Items
	for id, itemData in pairs(SpecialItemsConfig) do
		table.insert(state.allItemsList, {
			Id = id,
			Name = itemData.Name,
			Type = itemData.Type or "Utility",
			Rarity = itemData.Rarity or "Common",
			Cost = itemData.APCost,
			Desc = itemData.Description,
			Unicode = itemData.Unicode or "📦",
			Owned = false
		})
	end

	table.sort(state.allItemsList, function(a, b) return a.Cost < b.Cost end)
end

function apShopUI:RefreshList()
	if not listContainer then return end

	for _, c in ipairs(listContainer:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end

	local searchTerm = searchInput and searchInput.Text:lower() or ""

	for _, item in ipairs(state.allItemsList) do
		local matchesTab = (state.currentTab == "All") or (item.Type == state.currentTab)
		local matchesSearch = false
		if searchTerm == "" then
			matchesSearch = true
		else
			if string.find(tostring(item.Name):lower(), searchTerm) then matchesSearch = true end
		end

		if matchesTab and matchesSearch then
			self:CreateItemCard(item)
		end
	end
end

-- ============================================================================
-- UI COMPONENTS (THEME APPLIED)
-- ============================================================================

function apShopUI:CreateItemCard(item)
	local isSelected = (state.selectedItem and state.selectedItem.Id == item.Id)
	local rarityColor = getRarityColor(item.Rarity)

	local card = create("TextButton", {
		Name = item.Id,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = isSelected and COLORS.BG_HOVER or COLORS.BG_PANEL,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = listContainer
	})

	-- Grunge texture
	addGrunge(card, 0.95)

	-- Border
	local border = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = COLORS.TEXT_DIM,
		BackgroundTransparency = 0.5,
		Parent = card
	})

	-- Selection Indicator (Left Bar)
	if isSelected then
		local bar = create("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = COLORS.ACCENT_HAZARD,
			BorderSizePixel = 0,
			Parent = card
		})
		-- Glow
		local g = create("ImageLabel", {
			Image = "rbxassetid://130424513",
			ImageColor3 = COLORS.ACCENT_HAZARD,
			ImageTransparency = 0.5,
			Size = UDim2.new(4, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = bar
		})
	end

	-- Icon Box (Rough looking)
	local iconBox = create("Frame", {
		Size = UDim2.new(0, 44, 0, 44),
		Position = UDim2.new(0, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = card
	})
	addStroke(iconBox, rarityColor, 1)

	create("TextLabel", {
		Text = item.Unicode,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 20,
		Parent = iconBox
	})

	-- Info
	local nameLabel = create("TextLabel", {
		Text = item.Name:upper(),
		Size = UDim2.new(0.6, 0, 0.4, 0),
		Position = UDim2.new(0, 68, 0.15, 0),
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = card
	})

	local typeLabel = create("TextLabel", {
		Text = item.Type:upper(),
		Size = UDim2.new(0.6, 0, 0.3, 0),
		Position = UDim2.new(0, 68, 0.55, 0),
		Font = FONTS.Tech,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = card
	})

	-- Price
	local priceColor = (state.currentAP >= item.Cost) and COLORS.ACCENT_TOXIC or COLORS.ACCENT_BLOOD
	if item.Owned then priceColor = COLORS.TEXT_MAIN end

	create("TextLabel", {
		Text = item.Owned and "ACQUIRED" or (formatNumber(item.Cost) .. " AP"),
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, -10, 0, 0),
		Font = FONTS.Body,
		TextSize = 14,
		TextColor3 = priceColor,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = card
	})

	card.MouseButton1Click:Connect(function()
		self:SelectItem(item)
	end)
end

function apShopUI:SelectItem(item)
	state.selectedItem = item
	self:RefreshList()
	self:UpdateDetails()
end

function apShopUI:UpdateDetails()
	if not state.selectedItem then return end
	local item = state.selectedItem

	-- Update Info
	detailsPanel.Title.Text = item.Name:upper()
	detailsPanel.Description.Text = "\"" .. item.Desc .. "\""
	detailsPanel.PriceFrame.Amount.Text = formatNumber(item.Cost) .. " AP"

	-- Rarity
	local rarityLabel = detailsPanel.MetaFrame.RarityLabel
	rarityLabel.Text = item.Rarity:upper()
	rarityLabel.TextColor3 = getRarityColor(item.Rarity)

	-- Preview
	if state.activePreview then
		ModelPreviewModule.destroy(state.activePreview)
		state.activePreview = nil
	end

	if item.Type == "Skins" and item.Data then
		previewViewport.Visible = true
		previewIconLabel.Visible = false
		local weaponDef = WeaponModule.Weapons[item.Weapon]
		state.activePreview = ModelPreviewModule.create(previewViewport, weaponDef, item.Data)
		ModelPreviewModule.startRotation(state.activePreview, 2.0)
	else
		previewViewport.Visible = false
		previewIconLabel.Visible = true
		previewIconLabel.Text = item.Unicode
		previewIconLabel.TextColor3 = getRarityColor(item.Rarity)
	end

	-- Button
	local btn = detailsPanel.BuySection.BuyButton
	local btnText = btn.Label

	if item.Owned then
		btnText.Text = "INVENTORY"
		btn.BackgroundColor3 = COLORS.BG_HOVER
		btn.AutoButtonColor = false
	elseif state.currentAP < item.Cost then
		btnText.Text = "INSUFFICIENT FUNDS"
		btn.BackgroundColor3 = COLORS.ACCENT_BLOOD
		btn.AutoButtonColor = false
	else
		btnText.Text = "PURCHASE SUPPLY"
		btn.BackgroundColor3 = COLORS.ACCENT_HAZARD
		btn.AutoButtonColor = true
	end
end

-- ============================================================================
-- MAIN CREATION (REDESIGNED)
-- ============================================================================

function apShopUI:Create()
	if playerGui:FindFirstChild("APShopUI") then
		screenGui = playerGui.APShopUI
		screenGui:Destroy()
	end

	screenGui = create("ScreenGui", {
		Name = "APShopUI",
		Parent = playerGui,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		Enabled = false
	})

	-- Dark Overlay
	local overlay = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.3,
		Parent = screenGui
	})
	addGrunge(overlay, 0.8)

	-- Main Crate Container
	local mainCrate = create("Frame", {
		Name = "MainCrate",
		Size = UDim2.new(0, 900, 0, 600),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = screenGui
	})
	addStroke(mainCrate, Color3.fromRGB(60, 55, 50), 3) -- Thick metal border
	addGrunge(mainCrate, 0.9)

	-- Decor: Bolts in corners
	local function createBolt(pos)
		local b = create("Frame", {
			Size = UDim2.new(0, 8, 0, 8),
			Position = pos,
			BackgroundColor3 = Color3.new(0.3, 0.3, 0.3),
			Parent = mainCrate
		})
		addCorner(b, 4)
	end
	createBolt(UDim2.new(0, 6, 0, 6))
	createBolt(UDim2.new(1, -14, 0, 6))
	createBolt(UDim2.new(0, 6, 1, -14))
	createBolt(UDim2.new(1, -14, 1, -14))

	-- Top Bar / Header
	local topBar = create("Frame", {
		Size = UDim2.new(1, -40, 0, 50),
		Position = UDim2.new(0, 20, 0, 20),
		BackgroundTransparency = 1,
		Parent = mainCrate
	})

	create("TextLabel", {
		Text = "SUPPLY DEPOT // AP EXCHANGE",
		Size = UDim2.new(0.7, 0, 1, 0),
		Font = FONTS.Header,
		TextSize = 28,
		TextColor3 = COLORS.ACCENT_HAZARD,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = topBar
	})

	-- AP Balance Display (Stenciled)
	local balanceFrame = create("Frame", {
		Size = UDim2.new(0, 160, 1, 0),
		Position = UDim2.new(1, -160, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = topBar
	})
	addStroke(balanceFrame, COLORS.TEXT_DIM, 1)

	apValueLabel = create("TextLabel", {
		Text = "0",
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Font = FONTS.Tech,
		TextSize = 20,
		TextColor3 = COLORS.ACCENT_TOXIC,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = balanceFrame
	})
	create("TextLabel", {
		Text = UNICODE_ICONS.AP,
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		TextSize = 18,
		BackgroundTransparency = 1,
		Parent = balanceFrame
	})

	-- Close Button (Red Tape Style)
	local closeBtn = create("TextButton", {
		Text = "✖",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, 15, 0, -15), -- Hanging off the edge
		BackgroundColor3 = COLORS.ACCENT_BLOOD,
		TextColor3 = COLORS.TEXT_MAIN,
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = mainCrate
	})
	addCorner(closeBtn, 4)
	closeBtn.MouseButton1Click:Connect(function() apShopUI:Hide() end)

	-- Content Split
	local contentFrame = create("Frame", {
		Size = UDim2.new(1, -40, 1, -90),
		Position = UDim2.new(0, 20, 0, 80),
		BackgroundTransparency = 1,
		Parent = mainCrate
	})

	-- LEFT SIDE: Navigation & List
	local leftCol = create("Frame", {
		Size = UDim2.new(0, 340, 1, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = contentFrame
	})
	addStroke(leftCol, Color3.new(0,0,0), 2)
	addGrunge(leftCol, 0.96)

	-- Tabs Row
	local tabRow = create("Frame", {
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		Parent = leftCol
	})
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), Parent = tabRow })

	local function createTab(name, label)
		local btn = create("TextButton", {
			Name = name,
			Text = label or name,
			Size = UDim2.new(0.23, 0, 1, 0),
			BackgroundColor3 = (state.currentTab == name) and COLORS.ACCENT_HAZARD or COLORS.BG_ROOT,
			TextColor3 = (state.currentTab == name) and COLORS.BG_ROOT or COLORS.TEXT_DIM,
			Font = FONTS.Body,
			TextSize = 12,
			Parent = tabRow
		})
		btn.MouseButton1Click:Connect(function()
			state.currentTab = name
			self:RefreshList()
			-- Refresh visual state of tabs (simple redraw approach for simplicity)
			for _, c in ipairs(tabRow:GetChildren()) do
				if c:IsA("TextButton") then
					local active = (c.Name == state.currentTab)
					c.BackgroundColor3 = active and COLORS.ACCENT_HAZARD or COLORS.BG_ROOT
					c.TextColor3 = active and COLORS.BG_ROOT or COLORS.TEXT_DIM
				end
			end
		end)
	end

	createTab("All", "ALL")
	createTab("Skins", "CAMO")
	createTab("Titles", "TAGS")
	createTab("Utility", "GEAR")

	-- Search Bar
	local searchFrame = create("Frame", {
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.new(0, 10, 0, 50),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = leftCol
	})
	addStroke(searchFrame, COLORS.TEXT_DIM, 1)

	searchInput = create("TextBox", {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 5, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "SEARCH MANIFEST...",
		PlaceholderColor3 = COLORS.TEXT_DIM,
		TextColor3 = COLORS.ACCENT_TOXIC,
		Font = FONTS.Tech,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = searchFrame
	})
	searchInput:GetPropertyChangedSignal("Text"):Connect(function() self:RefreshList() end)

	-- List Container
	listContainer = create("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -90),
		Position = UDim2.new(0, 5, 0, 90),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = COLORS.ACCENT_HAZARD,
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = leftCol
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), Parent = listContainer })


	-- RIGHT SIDE: Details View
	local rightCol = create("Frame", {
		Size = UDim2.new(1, -360, 1, 0),
		Position = UDim2.new(0, 360, 0, 0),
		BackgroundTransparency = 1,
		Parent = contentFrame
	})

	-- Preview Monitor
	local monitorFrame = create("Frame", {
		Size = UDim2.new(1, 0, 0.6, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		Parent = rightCol
	})
	addStroke(monitorFrame, COLORS.TEXT_DIM, 2)

	-- Grid Background for Monitor
	local grid = create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://4801088331", -- Grid texture
		ImageTransparency = 0.8,
		ImageColor3 = COLORS.ACCENT_TOXIC,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 64, 0, 64),
		Parent = monitorFrame
	})

	previewViewport = create("ViewportFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = monitorFrame
	})

	previewIconLabel = create("TextLabel", {
		Text = "📦",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 100,
		TextColor3 = COLORS.TEXT_DIM,
		Parent = monitorFrame
	})

	create("TextLabel", { -- Monitor Scanline Text
		Text = "SCANNING OBJECT...",
		Size = UDim2.new(1, -10, 0, 20),
		Position = UDim2.new(0, 10, 0, 10),
		Font = FONTS.Tech,
		TextSize = 12,
		TextColor3 = COLORS.ACCENT_TOXIC,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = monitorFrame
	})

	-- Details Panel
	detailsPanel = create("Frame", {
		Name = "Details",
		Size = UDim2.new(1, 0, 0.38, 0),
		Position = UDim2.new(0, 0, 0.62, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = rightCol
	})
	addStroke(detailsPanel, COLORS.TEXT_DIM, 1)
	addGrunge(detailsPanel, 0.95)

	-- Info Area
	local titleLabel = create("TextLabel", {
		Name = "Title",
		Text = "SELECT ITEM",
		Size = UDim2.new(1, -20, 0, 30),
		Position = UDim2.new(0, 10, 0, 10),
		Font = FONTS.Header,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local metaFrame = create("Frame", {
		Name = "MetaFrame",
		Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.new(0, 10, 0, 40),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	create("TextLabel", { Name = "RarityLabel", Text = "---", Size = UDim2.new(0, 100, 1, 0), Font = FONTS.Tech, TextSize = 14, TextColor3 = COLORS.TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = metaFrame })

	create("TextLabel", {
		Name = "Description",
		Text = "Waiting for input...",
		Size = UDim2.new(1, -20, 0, 50),
		Position = UDim2.new(0, 10, 0, 65),
		Font = FONTS.Body,
		TextSize = 14,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = detailsPanel
	})

	-- Buy Section (Bottom Right of Details)
	local buySection = create("Frame", {
		Name = "BuySection",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -50),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local priceFrame = create("Frame", { Name = "PriceFrame", Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Parent = buySection })
	create("TextLabel", { Text = "COST:", Size = UDim2.new(1, 0, 0, 15), Font = FONTS.Tech, TextSize = 10, TextColor3 = COLORS.TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = priceFrame })
	create("TextLabel", { Name = "Amount", Text = "0 AP", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 15), Font = FONTS.Header, TextSize = 24, TextColor3 = COLORS.ACCENT_HAZARD, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = priceFrame })

	local buyBtn = create("TextButton", {
		Name = "BuyButton",
		Text = "",
		Size = UDim2.new(0.5, 0, 1, -10),
		Position = UDim2.new(0.5, -10, 0, 0),
		BackgroundColor3 = COLORS.ACCENT_HAZARD,
		Parent = buySection
	})
	create("TextLabel", { Name = "Label", Text = "PURCHASE", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = FONTS.Body, TextSize = 16, TextColor3 = COLORS.BG_ROOT, Parent = buyBtn })

	-- Hazard Stripes on Button
	local stripes = create("ImageLabel", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.new(0, 0, 1, -5),
		Image = "rbxassetid://15264388636", -- Grunge fallback
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = buyBtn
	})

	buyBtn.MouseButton1Click:Connect(function() self:PurchaseItem() end)

	self:RefreshList()
end


function apShopUI:PurchaseItem()
	if not state.selectedItem then return end
	if state.selectedItem.Owned then return end
	if state.currentAP < state.selectedItem.Cost then return end

	local btn = detailsPanel.BuySection.BuyButton
	local lbl = btn.Label
	lbl.Text = "PROCESSING..."

	local result
	if state.selectedItem.Type == "Skins" then
		result = purchaseSkinFunc:InvokeServer(state.selectedItem.Weapon, state.selectedItem.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(state.selectedItem.Id)
	end

	if result.Success then
		state.selectedItem.Owned = true
		lbl.Text = "ACQUIRED"
		btn.BackgroundColor3 = COLORS.ACCENT_TOXIC
		self:UpdateAP()
		task.delay(1, function()
			self:UpdateDetails()
			self:RefreshList()
		end)
	else
		lbl.Text = "ERROR"
		btn.BackgroundColor3 = COLORS.ACCENT_BLOOD
		task.delay(1, function()
			self:UpdateDetails()
		end)
	end
end

-- ============================================================================
-- MAIN LOGIC
-- ============================================================================

function apShopUI:UpdateAP()
	task.spawn(function()
		local success, points = pcall(function() return getAPFunc:InvokeServer() end)
		if success then
			state.currentAP = points
			if apValueLabel then apValueLabel.Text = formatNumber(points) end
			self:UpdateDetails()
		end
	end)
end

function apShopUI:Show()
	if screenGui then
		screenGui.Enabled = true
		state.isUIOpen = true

		self:LoadData()
		self:RefreshList()
		self:UpdateAP()

		-- Simple pop in
		if screenGui:FindFirstChild("MainCrate") then
			screenGui.MainCrate.Size = UDim2.new(0, 850, 0, 550)
			TweenService:Create(screenGui.MainCrate, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 900, 0, 600)
			}):Play()
		end

		if #state.allItemsList > 0 then
			self:SelectItem(state.allItemsList[1])
		end
	end
end

function apShopUI:Hide()
	if screenGui then
		screenGui.Enabled = false
		state.isUIOpen = false
	end
	if state.activePreview then 
		ModelPreviewModule.destroy(state.activePreview) 
		state.activePreview = nil 
	end
	if proximityHandler then
		proximityHandler:SetOpen(false)
	end
end

apChangedEvent.OnClientEvent:Connect(function(newAP)
	state.currentAP = newAP
	if apValueLabel then apValueLabel.Text = formatNumber(newAP) end
	if screenGui and screenGui.Enabled then
		apShopUI:UpdateDetails()
	end
end)

local function initialize()
	apShopUI:Create()
	apShopUI:Hide()
end

if playerGui.Parent then
	initialize()
else
	playerGui.AncestryChanged:Connect(function()
		if playerGui.Parent then
			initialize()
		end
	end)
end

-- Proximity Registration
local ShopFolder = Workspace:WaitForChild("Shop", 10) or Workspace

proximityHandler = ProximityUIHandler.Register({
	name = "APShop",
	partName = "APShop",
	parent = ShopFolder,
	onToggle = function(isOpen)
		if isOpen then
			apShopUI:Show()
		else
			apShopUI:Hide()
		end
	end
})

return apShopUI
