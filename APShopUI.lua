-- APShopUI.lua (LocalScript)
-- Path: StarterGui/APShopUI.lua
-- Script Place: Lobby
-- Theme: Prototype Match (Dark Glassmorphism, Cyan/Amber Accents)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULES & REMOTES
-- ============================================================================

local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

-- Config Item Spesial (Hardcoded fallback + Extended for prototype matching)
local SpecialItemsConfig = {
	SKILL_RESET_TOKEN = {
		Name = "Skill Reset Token",
		Description = "A one-time use token that allows you to reset all your skill points. Perfect for trying new builds.",
		APCost = 7500,
		Rarity = "Common",
		Type = "Utility",
		Unicode = "🔄"
	},
	EXCLUSIVE_TITLE_COLLECTOR = {
		Name = "Title: The Collector",
		Description = "An exclusive golden title displayed above your head. Shows everyone your dedication to the grind.",
		APCost = 10000,
		Rarity = "Epic",
		Type = "Titles",
		Unicode = "👑"
	},
	TITLE_SLAYER = {
		Name = "Title: Zombie Slayer",
		Description = "Unlocks the 'Zombie Slayer' prefix for your nametag.",
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
	BG_ROOT = Color3.fromRGB(15, 23, 42),       -- Slate 900
	BG_PANEL = Color3.fromRGB(30, 41, 59),      -- Slate 800
	BG_HOVER = Color3.fromRGB(51, 65, 85),      -- Slate 700
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(148, 163, 184),   -- Slate 400

	ACCENT_CYAN = Color3.fromRGB(6, 182, 212),  -- Cyan 500
	ACCENT_AMBER = Color3.fromRGB(245, 158, 11),-- Amber 500
	ACCENT_RED = Color3.fromRGB(239, 68, 68),   -- Red 500
	ACCENT_GREEN = Color3.fromRGB(34, 197, 94), -- Green 500

	RARITY_COMMON = Color3.fromRGB(148, 163, 184), -- Slate
	RARITY_RARE = Color3.fromRGB(59, 130, 246),    -- Blue
	RARITY_EPIC = Color3.fromRGB(168, 85, 247),    -- Purple
	RARITY_LEGENDARY = Color3.fromRGB(234, 179, 8) -- Gold
}

local UNICODE_ICONS = {
	Search = "🔍",
	Close = "X",
	AP = "🏆",
	Shop = "🏪",
	Check = "✓",
	Lock = "🔒",
	Cart = "🛒",
	Fire = "🔥",
	Snow = "❄️",
	Skull = "💀",
	Crown = "👑",
	Rotate = "🔄",
	Gun = "🔫"
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
local currentTab = "All"
local currentAP = 0
local selectedItem = nil
local activePreview = nil
local allItemsList = {} 
local isVisible = false

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

local function addPadding(parent, amount)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, amount)
	pad.PaddingBottom = UDim.new(0, amount)
	pad.PaddingLeft = UDim.new(0, amount)
	pad.PaddingRight = UDim.new(0, amount)
	pad.Parent = parent
	return pad
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.TEXT_DIM
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Transparency = 0.8
	stroke.Parent = parent
	return stroke
end

local function addGradient(parent, color1, color2, rotation)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	}
	grad.Rotation = rotation or 0
	grad.Parent = parent
	return grad
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
	allItemsList = {}

	-- 1. Load Skins
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.APCost and skinData.APCost > 0 then
				local rarity = "Rare"
				if skinData.APCost >= 20000 then rarity = "Legendary"
				elseif skinData.APCost >= 10000 then rarity = "Epic"
				end

				table.insert(allItemsList, {
					Id = weaponName .. "_" .. skinName,
					Name = skinName,
					Type = "Skins",
					Rarity = rarity,
					Cost = skinData.APCost,
					Desc = string.format("%s skin for %s.", tostring(rarity), tostring(weaponName)),
					Unicode = UNICODE_ICONS.Gun, -- Fallback icon
					Weapon = weaponName,
					SkinName = skinName,
					Data = skinData,
					Owned = false -- Updated dynamically
				})
			end
		end
	end

	-- 2. Load Special Items
	for id, itemData in pairs(SpecialItemsConfig) do
		table.insert(allItemsList, {
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

	-- Sort by cost
	table.sort(allItemsList, function(a, b) return a.Cost < b.Cost end)
end

function apShopUI:RefreshList()
	if not listContainer then return end

	-- Clear
	for _, c in ipairs(listContainer:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end

	local searchTerm = searchInput and searchInput.Text:lower() or ""

	for _, item in ipairs(allItemsList) do
		-- Filter Logic
		local matchesTab = (currentTab == "All") or (item.Type == currentTab)
		local matchesSearch = false
		if searchTerm == "" then
			matchesSearch = true
		else
			local itemNameLower = tostring(item.Name):lower()
			if string.find(itemNameLower, tostring(searchTerm)) then
				matchesSearch = true
			end
		end

		if matchesTab and matchesSearch then
			self:CreateItemCard(item)
		end
	end
end

-- ============================================================================
-- UI COMPONENTS
-- ============================================================================

function apShopUI:CreateItemCard(item)
	local isSelected = (selectedItem and selectedItem.Id == item.Id)
	local rarityColor = getRarityColor(item.Rarity)

	local card = create("TextButton", {
		Name = item.Id,
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = isSelected and COLORS.BG_HOVER or COLORS.BG_PANEL,
		BackgroundTransparency = isSelected and 0.5 or 0.6,
		AutoButtonColor = false,
		Text = "",
		Parent = listContainer
	})
	addCorner(card, 12)
	local stroke = addStroke(card, isSelected and COLORS.ACCENT_CYAN or COLORS.TEXT_DIM, 1)
	stroke.Transparency = isSelected and 0.5 or 0.9

	-- Gradient highlight for active
	if isSelected then
		-- local grad = addGradient(card, Color3.fromRGB(6, 182, 212), COLORS.BG_PANEL, 0)
		-- grad.Transparency = NumberSequence.new(0.85, 1)
	end

	-- Icon Box
	local iconBox = create("Frame", {
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = card
	})
	addCorner(iconBox, 8)
	addStroke(iconBox, rarityColor, 1).Transparency = 0.5

	create("TextLabel", {
		Text = item.Unicode,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 24,
		TextColor3 = rarityColor,
		Parent = iconBox
	})

	-- Info Group
	local infoGroup = create("Frame", {
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.new(0, 70, 0, 0),
		BackgroundTransparency = 1,
		Parent = card
	})

	-- Name & Owned Check
	local nameLabel = create("TextLabel", {
		Text = item.Name,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0.2, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = infoGroup
	})

	-- Type & Price Row
	local metaRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0.55, 0),
		BackgroundTransparency = 1,
		Parent = infoGroup
	})

	create("TextLabel", {
		Text = item.Type:upper(),
		Size = UDim2.new(0.5, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = metaRow
	})

	local priceColor = (currentAP >= item.Cost) and COLORS.ACCENT_AMBER or COLORS.ACCENT_RED
	if item.Owned then priceColor = COLORS.ACCENT_GREEN end

	create("TextLabel", {
		Text = item.Owned and "OWNED" or (formatNumber(item.Cost) .. " AP"),
		Size = UDim2.new(1, -10, 1, 0),
		AnchorPoint = Vector2.new(0, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = priceColor,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = metaRow
	})

	-- Selection Logic
	card.MouseButton1Click:Connect(function()
		self:SelectItem(item)
	end)
end

function apShopUI:SelectItem(item)
	selectedItem = item
	self:RefreshList() -- Refresh to update selection highlight
	self:UpdateDetails()
end

function apShopUI:UpdateDetails()
	if not selectedItem then return end
	local item = selectedItem

	-- Update Text
	detailsPanel.InfoGroup.Title.Text = item.Name
	detailsPanel.InfoGroup.Description.Text = item.Desc
	detailsPanel.ActionGroup.PriceContainer.Price.Text = formatNumber(item.Cost) .. " AP"

	-- Rarity Tag
	local rarityTag = detailsPanel.InfoGroup.MetaRow.RarityTag.TextLabel
	rarityTag.Text = item.Rarity:upper()
	rarityTag.TextColor3 = getRarityColor(item.Rarity)

	local rarityBg = detailsPanel.InfoGroup.MetaRow.RarityTag
	rarityBg.BackgroundColor3 = getRarityColor(item.Rarity)
	rarityBg.UIStroke.Color = getRarityColor(item.Rarity)

	-- Icon Preview
	if activePreview then
		ModelPreviewModule.destroy(activePreview)
		activePreview = nil
	end

	if item.Type == "Skins" and item.Data then
		previewViewport.Visible = true
		previewIconLabel.Visible = false
		local weaponDef = WeaponModule.Weapons[item.Weapon]
		activePreview = ModelPreviewModule.create(previewViewport, weaponDef, item.Data)
		ModelPreviewModule.startRotation(activePreview, 3.5) -- Zoom adjusted per request
	else
		previewViewport.Visible = false
		previewIconLabel.Visible = true
		previewIconLabel.Text = item.Unicode
		previewIconLabel.TextColor3 = getRarityColor(item.Rarity)
	end

	-- Button State
	local btn = detailsPanel.ActionGroup.BuyButton
	local btnText = btn.TextLabel
	if item.Owned then
		btnText.Text = "OWNED " .. UNICODE_ICONS.Check
		btn.BackgroundColor3 = COLORS.BG_HOVER
		btn.AutoButtonColor = false
	elseif currentAP < item.Cost then
		btnText.Text = "NOT ENOUGH AP " .. UNICODE_ICONS.Lock
		btn.BackgroundColor3 = COLORS.BG_HOVER
		btn.AutoButtonColor = false
	else
		btnText.Text = "PURCHASE " .. UNICODE_ICONS.Cart
		btn.BackgroundColor3 = COLORS.ACCENT_CYAN
		btn.AutoButtonColor = true
	end
end

-- ============================================================================
-- MAIN CREATION
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
		IgnoreGuiInset = false, -- Adjusted per request
		Enabled = false
	})

	-- Main Interface Container (Glassmorphism Mockup)
	local mainInterface = create("Frame", {
		Name = "MainInterface",
		Size = UDim2.new(0, 1000, 0, 650),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BackgroundTransparency = 0, -- Solid background
		BorderSizePixel = 0,
		Parent = screenGui
	})
	addCorner(mainInterface, 24)
	addStroke(mainInterface, Color3.new(1,1,1), 1).Transparency = 0.9

	-- Header
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Parent = mainInterface
	})
	local headPad = addPadding(header, 24)

	local titleGroup = create("Frame", {
		Size = UDim2.new(0, 300, 1, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), -- Centered Header
		BackgroundTransparency = 1,
		Parent = header
	})
	create("TextLabel", {
		Text = "AP STORE",
		Size = UDim2.new(1, 0, 0, 24),
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Center, -- Centered Text
		BackgroundTransparency = 1,
		Parent = titleGroup
	})
	create("TextLabel", {
		Text = "Spend your hard-earned points",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 24),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Center, -- Centered Text
		BackgroundTransparency = 1,
		Parent = titleGroup
	})

	-- Close Button
	local closeBtn = create("TextButton", {
		Text = UNICODE_ICONS.Close,
		Size = UDim2.new(0, 40, 0, 40),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = COLORS.BG_HOVER,
		BackgroundTransparency = 0.5,
		TextColor3 = COLORS.TEXT_DIM,
		TextSize = 20,
		Parent = header
	})
	addCorner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(function() apShopUI:Hide() end)


	-- Content Area
	local content = create("Frame", {
		Size = UDim2.new(1, 0, 1, -80),
		Position = UDim2.new(0, 0, 0, 80),
		BackgroundTransparency = 1,
		Parent = mainInterface
	})

	-- Sidebar
	local sidebar = create("Frame", {
		Size = UDim2.new(0, 380, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = content
	})
	create("Frame", { -- Divider
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = COLORS.TEXT_DIM,
		BackgroundTransparency = 0.9,
		Parent = sidebar
	})

	-- Search & Tabs
	local sidebarPad = create("Frame", {
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	addPadding(sidebarPad, 16)

	-- Search Input
	local searchContainer = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = COLORS.BG_PANEL,
		BackgroundTransparency = 0.5,
		Parent = sidebarPad
	})
	addCorner(searchContainer, 8)
	addStroke(searchContainer, COLORS.TEXT_DIM, 1).Transparency = 0.8

	create("TextLabel", {
		Text = UNICODE_ICONS.Search,
		Size = UDim2.new(0, 40, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_DIM,
		Parent = searchContainer
	})
	searchInput = create("TextBox", {
		Text = "",
		PlaceholderText = "Search items...",
		PlaceholderColor3 = COLORS.TEXT_DIM,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.TEXT_MAIN,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = searchContainer
	})
	searchInput:GetPropertyChangedSignal("Text"):Connect(function() self:RefreshList() end)

	-- Tabs
	local tabContainer = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = sidebarPad
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		Parent = tabContainer
	})

	local function createTab(name)
		local btn = create("TextButton", {
			Name = name,
			Text = name,
			Size = UDim2.new(0.23, 0, 1, 0),
			BackgroundColor3 = (currentTab == name) and Color3.fromRGB(6, 182, 212) or COLORS.BG_HOVER,
			BackgroundTransparency = (currentTab == name) and 0.85 or 0.95,
			TextColor3 = (currentTab == name) and COLORS.ACCENT_CYAN or COLORS.TEXT_DIM,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			Parent = tabContainer
		})
		addCorner(btn, 6)
		if currentTab == name then
			addStroke(btn, COLORS.ACCENT_CYAN, 1).Transparency = 0.7
		end
		btn.MouseButton1Click:Connect(function()
			currentTab = name
			-- Refresh Tab Styles
			for _, c in ipairs(tabContainer:GetChildren()) do
				if c:IsA("TextButton") then
					local isActive = (c.Name == currentTab)
					c.BackgroundColor3 = isActive and Color3.fromRGB(6, 182, 212) or COLORS.BG_HOVER
					c.BackgroundTransparency = isActive and 0.85 or 0.95
					c.TextColor3 = isActive and COLORS.ACCENT_CYAN or COLORS.TEXT_DIM
					if c:FindFirstChild("UIStroke") then c.UIStroke:Destroy() end
					if isActive then addStroke(c, COLORS.ACCENT_CYAN, 1).Transparency = 0.7 end
				end
			end
			self:RefreshList()
		end)
	end

	createTab("All")
	createTab("Skins")
	createTab("Titles")
	createTab("Utility")

	-- Item List
	listContainer = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -120),
		Position = UDim2.new(0, 0, 0, 120),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.TEXT_DIM,
		ScrollBarImageTransparency = 0.8,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebar
	})
	addPadding(listContainer, 16)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listContainer })

	-- RIGHT SIDE: Preview & Details
	local rightSide = create("Frame", {
		Size = UDim2.new(1, -380, 1, 0),
		Position = UDim2.new(0, 380, 0, 0),
		BackgroundTransparency = 1,
		Parent = content
	})

	-- Preview Area (Top)
	local previewArea = create("Frame", {
		Size = UDim2.new(1, 0, 1, -220),
		BackgroundTransparency = 1,
		Parent = rightSide
	})

	previewViewport = create("ViewportFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = previewArea
	})

	previewIconLabel = create("TextLabel", {
		Text = "📦",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 120,
		TextColor3 = COLORS.TEXT_DIM,
		Visible = true,
		Parent = previewArea
	})

	-- Details Panel (Bottom)
	detailsPanel = create("Frame", {
		Name = "DetailsPanel",
		Size = UDim2.new(1, 0, 0, 220),
		Position = UDim2.new(0, 0, 1, -220),
		BackgroundColor3 = COLORS.BG_PANEL,
		BackgroundTransparency = 0.2,
		Parent = rightSide
	})
	addStroke(detailsPanel, Color3.new(1,1,1), 1).Transparency = 0.9
	local detPad = addPadding(detailsPanel, 32)

	-- Info Group
	local infoGroup = create("Frame", {
		Name = "InfoGroup",
		Size = UDim2.new(1, 0, 0, 100),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	-- Rarity Tag
	local metaRow = create("Frame", { Name = "MetaRow", Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = infoGroup })
	local rarityTag = create("Frame", {
		Name = "RarityTag",
		Size = UDim2.new(0, 80, 0, 20),
		BackgroundColor3 = COLORS.RARITY_COMMON,
		BackgroundTransparency = 0.85,
		Parent = metaRow
	})
	addCorner(rarityTag, 4)
	local rStroke = addStroke(rarityTag, COLORS.RARITY_COMMON, 1)
	create("TextLabel", {
		Name = "TextLabel",
		Text = "COMMON",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 10,
		TextColor3 = COLORS.RARITY_COMMON,
		Parent = rarityTag
	})

	create("TextLabel", {
		Name = "Title",
		Text = "Select an item",
		Size = UDim2.new(1, 0, 0, 32),
		Position = UDim2.new(0, 0, 0, 24),
		Font = Enum.Font.GothamBlack,
		TextSize = 32,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = infoGroup
	})

	create("TextLabel", {
		Name = "Description",
		Text = "Select an item from the list to view details.",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 60),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		BackgroundTransparency = 1,
		Parent = infoGroup
	})

	-- Action Group (Price & Buy)
	local actionGroup = create("Frame", {
		Name = "ActionGroup",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 1, -60),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local priceCol = create("Frame", { Name = "PriceContainer", Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0), BackgroundTransparency = 1, Parent = actionGroup })
	create("TextLabel", { Text = "PRICE", Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = COLORS.TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Parent = priceCol })
	create("TextLabel", { Name = "Price", Text = "0 AP", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 20), Font = Enum.Font.GothamBlack, TextSize = 28, TextColor3 = COLORS.ACCENT_AMBER, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1, Parent = priceCol })

	local buyBtn = create("TextButton", {
		Name = "BuyButton",
		Text = "",
		Size = UDim2.new(0.6, 0, 1, 0),
		BackgroundColor3 = COLORS.ACCENT_CYAN,
		AutoButtonColor = true,
		Parent = actionGroup
	})
	addCorner(buyBtn, 12)

	-- Gradient for button
	local btnGrad = addGradient(buyBtn, Color3.fromRGB(36, 95, 230), Color3.fromRGB(34, 211, 238), 45)

	create("TextLabel", {
		Name = "TextLabel",
		Text = "PURCHASE " .. UNICODE_ICONS.Cart,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.new(1,1,1),
		Parent = buyBtn
	})

	buyBtn.MouseButton1Click:Connect(function()
		self:PurchaseItem()
	end)

end

function apShopUI:PurchaseItem()
	if not selectedItem then return end
	if selectedItem.Owned then return end
	if currentAP < selectedItem.Cost then return end

	local btn = detailsPanel.ActionGroup.BuyButton
	local originalText = btn.TextLabel.Text
	btn.TextLabel.Text = "PROCESSING..."

	local result
	if selectedItem.Type == "Skins" then
		result = purchaseSkinFunc:InvokeServer(selectedItem.Weapon, selectedItem.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(selectedItem.Id)
	end

	if result.Success then
		selectedItem.Owned = true
		btn.TextLabel.Text = "SUCCESS!"
		btn.BackgroundColor3 = COLORS.ACCENT_GREEN
		self:UpdateAP() -- Update AP visually
		task.delay(1, function()
			self:UpdateDetails()
			self:RefreshList()
		end)
	else
		btn.TextLabel.Text = "FAILED"
		btn.BackgroundColor3 = COLORS.ACCENT_RED
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
			currentAP = points
			if apValueLabel then apValueLabel.Text = formatNumber(points) end
			self:UpdateDetails()
		end
	end)
end

function apShopUI:Show()
	if not screenGui then self:Create() end
	screenGui.Enabled = true
	self:LoadData()
	self:RefreshList()
	self:UpdateAP()

	-- Intro Animation
	local main = screenGui.MainInterface
	main.Size = UDim2.new(0, 950, 0, 600)
	-- main.BackgroundTransparency = 1 -- Removed to keep solid background
	TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 1000, 0, 650)
		-- BackgroundTransparency = 0.1
	}):Play()

	if #allItemsList > 0 then
		self:SelectItem(allItemsList[1])
	end
end

function apShopUI:Hide()
	if screenGui then
		screenGui.Enabled = false
	end
	if activePreview then 
		ModelPreviewModule.destroy(activePreview) 
		activePreview = nil 
	end
end

-- Event Listeners
apChangedEvent.OnClientEvent:Connect(function(newAP)
	currentAP = newAP
	if apValueLabel then apValueLabel.Text = formatNumber(newAP) end
	if screenGui and screenGui.Enabled then
		apShopUI:UpdateDetails()
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeredBy)
	if triggeredBy ~= player then return end
	if prompt.Parent and prompt.Parent.Name == "APShop" then
		apShopUI:Show()
	end
end)

return apShopUI
