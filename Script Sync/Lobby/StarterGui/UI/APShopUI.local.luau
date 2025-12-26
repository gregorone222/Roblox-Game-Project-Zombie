-- APShopUI.lua (LocalScript)
-- Path: StarterGui/APShopUI.lua
-- Script Place: Lobby
-- Theme: Military Record / Medal Case (Tactical, Dark Metal, Stencils)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULES & REMOTES
-- ============================================================================

local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

-- Config Item Spesial
local SpecialItemsConfig = {
	SKILL_RESET_TOKEN = {
		Name = "Skill Reset Token",
		Description = "Official authorization to re-specialize field operative skills.",
		APCost = 7500,
		Rarity = "Common",
		Type = "Utility",
		Unicode = "💉"
	},
	EXCLUSIVE_TITLE_COLLECTOR = {
		Name = "Title: The Collector",
		Description = "Awarded for exceptional resource gathering capabilities.",
		APCost = 10000,
		Rarity = "Epic",
		Type = "Titles",
		Unicode = "👑"
	},
	TITLE_SLAYER = {
		Name = "Title: Zombie Slayer",
		Description = "Commendation for high hostile neutralization count.",
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
-- CONSTANTS & THEME (REVISED: MILITARY RECORD)
-- ============================================================================

local COLORS = {
	BG_ROOT = Color3.fromRGB(20, 20, 20),      -- Deep Dark Grey
	BG_PANEL = Color3.fromRGB(35, 35, 40),     -- Steel Blue-Grey
	BG_HEADER = Color3.fromRGB(45, 45, 50),    -- Lighter Steel

	TEXT_MAIN = Color3.fromRGB(240, 240, 230), -- Off-White
	TEXT_DIM = Color3.fromRGB(160, 160, 165),  -- Grey Text
	TEXT_STENCIL = Color3.fromRGB(200, 180, 100), -- Faded Gold (Medal text)

	ACCENT_GOLD = Color3.fromRGB(218, 165, 32), -- Gold Medal
	ACCENT_SILVER = Color3.fromRGB(192, 192, 192), -- Silver
	ACCENT_BRONZE = Color3.fromRGB(205, 127, 50), -- Bronze

	ACCENT_SUCCESS = Color3.fromRGB(100, 200, 100),
	ACCENT_FAIL = Color3.fromRGB(200, 80, 80),

	RARITY_COMMON = Color3.fromRGB(180, 180, 180),
	RARITY_RARE = Color3.fromRGB(100, 150, 255),
	RARITY_EPIC = Color3.fromRGB(200, 80, 255),
	RARITY_LEGENDARY = Color3.fromRGB(255, 215, 0)
}

local FONTS = {
	Header = Enum.Font.SpecialElite, -- Stencil style
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code
}

local UNICODE_ICONS = {
	Close = "X",
	AP = "★", -- Star for Achievement
	Shop = "🎖️",
	Lock = "🔒",
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
local state = {
	currentTab = "All",
	currentAP = 0,
	selectedItem = nil,
	activePreview = nil,
	allItemsList = {},
	isUIOpen = false,
	blurEffect = nil -- Blur Effect Reference
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
					Desc = string.format("Commendation Paint: %s. Authorized for %s.", tostring(skinName), tostring(weaponName)),
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

	local card = create("TextButton", {
		Name = item.Id,
		Size = UDim2.new(1, 0, 0, 80), -- Taller cards for "Medal Case" look
		BackgroundColor3 = isSelected and COLORS.BG_HEADER or COLORS.BG_PANEL,
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = listContainer
	})

	addCorner(card, 4)
	if isSelected then
		addStroke(card, COLORS.ACCENT_GOLD, 2)
	else
		addStroke(card, COLORS.TEXT_DIM, 1)
	end

	-- Icon / Medal Display
	local iconBox = create("Frame", {
		Size = UDim2.new(0, 60, 0, 60),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = card
	})
	addCorner(iconBox, 30) -- Circular
	addStroke(iconBox, getRarityColor(item.Rarity), 2)

	create("TextLabel", {
		Text = item.Unicode,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 30,
		Parent = iconBox
	})

	-- Info
	local nameLabel = create("TextLabel", {
		Text = item.Name:upper(),
		Size = UDim2.new(0.6, 0, 0.4, 0),
		Position = UDim2.new(0, 80, 0.1, 0),
		Font = FONTS.Header,
		TextSize = 18,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = card
	})

	local typeLabel = create("TextLabel", {
		Text = "CLASS: " .. item.Type:upper(),
		Size = UDim2.new(0.6, 0, 0.3, 0),
		Position = UDim2.new(0, 80, 0.5, 0),
		Font = FONTS.Mono,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = card
	})

	-- Price Tag (Medal Ribbon Style)
	local ribbon = create("Frame", {
		Size = UDim2.new(0.3, 0, 0.4, 0),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = card
	})
	-- Diagonal cut visual could be added here, simplified for now
	addCorner(ribbon, 4)

	local priceColor = (state.currentAP >= item.Cost) and COLORS.ACCENT_GOLD or COLORS.ACCENT_FAIL
	if item.Owned then priceColor = COLORS.ACCENT_SUCCESS end

	create("TextLabel", {
		Text = item.Owned and "AWARDED" or (formatNumber(item.Cost) .. " AP"),
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = priceColor,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = ribbon
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

	-- Safe element access using FindFirstChild
	if not detailsPanel then return end

	local title = detailsPanel:FindFirstChild("Title")
	if title then title.Text = item.Name:upper() end

	local description = detailsPanel:FindFirstChild("Description")
	if description then description.Text = item.Desc end

	local buySection = detailsPanel:FindFirstChild("BuySection")
	if buySection then
		local priceFrame = buySection:FindFirstChild("PriceFrame")
		if priceFrame then
			local amount = priceFrame:FindFirstChild("Amount")
			if amount then
				amount.Text = formatNumber(item.Cost) .. " AP"
			end
		end
	end

	-- Rarity
	local metaFrame = detailsPanel:FindFirstChild("MetaFrame")
	if metaFrame then
		local rarityLabel = metaFrame:FindFirstChild("RarityLabel")
		if rarityLabel then
			rarityLabel.Text = "GRADE: " .. item.Rarity:upper()
			rarityLabel.TextColor3 = getRarityColor(item.Rarity)
		end
	end

	-- Preview
	if state.activePreview then
		ModelPreviewModule.destroy(state.activePreview)
		state.activePreview = nil
	end

	if item.Type == "Skins" and item.Data then
		if previewViewport then previewViewport.Visible = true end
		if previewIconLabel then previewIconLabel.Visible = false end

		if previewViewport then
			local weaponDef = WeaponModule.Weapons[item.Weapon]
			state.activePreview = ModelPreviewModule.create(previewViewport, weaponDef, item.Data)
			ModelPreviewModule.startRotation(state.activePreview, 2.0)
		end
	else
		if previewViewport then previewViewport.Visible = false end
		if previewIconLabel then
			previewIconLabel.Visible = true
			previewIconLabel.Text = item.Unicode
			previewIconLabel.TextColor3 = getRarityColor(item.Rarity)
		end
	end

	-- Button
	if buySection then
		local btn = buySection:FindFirstChild("BuyButton")
		if btn then
			-- Assuming Label is a child of the Button based on creation logic
			local btnText = btn:FindFirstChild("Label")
			if btnText then
				if item.Owned then
					btnText.Text = "ALREADY AWARDED"
					btn.BackgroundColor3 = COLORS.BG_PANEL
					btn.AutoButtonColor = false
				elseif state.currentAP < item.Cost then
					btnText.Text = "INSUFFICIENT MERIT"
					btn.BackgroundColor3 = COLORS.ACCENT_FAIL
					btn.AutoButtonColor = false
				else
					btnText.Text = "EXCHANGE POINTS"
					btn.BackgroundColor3 = COLORS.ACCENT_GOLD
					btn.AutoButtonColor = true
				end
			end
		end
	end
end

-- ============================================================================
-- MAIN CREATION (MILITARY RECORD STYLE)
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

	local camera = workspace.CurrentCamera
	-- Check for existing blur first to avoid duplicates
	local existingBlur = camera:FindFirstChild("APShopBlur")
	if existingBlur then
		state.blurEffect = existingBlur
	else
		state.blurEffect = create("BlurEffect", {Name = "APShopBlur", Parent = camera, Size = 15, Enabled = false})
	end

	-- Background Dim
	local dim = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.5,
		Parent = screenGui
	})

	-- Main Case
	local mainCase = create("Frame", {
		Name = "MainCase",
		Size = UDim2.new(0, 900, 0, 600),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = screenGui
	})
	addStroke(mainCase, COLORS.BG_HEADER, 4)
	addCorner(mainCase, 8)

	-- Header
	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = COLORS.BG_HEADER,
		Parent = mainCase
	})
	addCorner(header, 8)
	-- Flatten bottom corners
	local filler = create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = COLORS.BG_HEADER,
		BorderSizePixel = 0,
		Parent = header
	})

	create("TextLabel", {
		Text = "ACHIEVEMENT RECORD // EXCHANGE",
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = FONTS.Header,
		TextSize = 24,
		TextColor3 = COLORS.ACCENT_GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = header
	})

	-- Points Badge
	local pointsBadge = create("Frame", {
		Size = UDim2.new(0, 200, 0, 40),
		Position = UDim2.new(1, -220, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = header
	})
	addCorner(pointsBadge, 20)
	addStroke(pointsBadge, COLORS.ACCENT_GOLD, 1)

	apValueLabel = create("TextLabel", {
		Text = "0",
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Font = FONTS.Mono,
		TextSize = 20,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = pointsBadge
	})

	create("TextLabel", {
		Text = "★",
		Size = UDim2.new(0, 30, 1, 0),
		Position = UDim2.new(1, -30, 0, 0),
		TextColor3 = COLORS.ACCENT_GOLD,
		TextSize = 20,
		BackgroundTransparency = 1,
		Parent = pointsBadge
	})

	-- Close Button
	local closeBtn = create("TextButton", {
		Text = "X",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -15, 0, -15),
		BackgroundColor3 = COLORS.ACCENT_FAIL,
		TextColor3 = COLORS.TEXT_MAIN,
		Font = FONTS.Body,
		Parent = mainCase
	})
	addCorner(closeBtn, 15)
	addStroke(closeBtn, COLORS.TEXT_MAIN, 2)
	closeBtn.MouseButton1Click:Connect(function() apShopUI:Hide() end)

	-- Content Area
	local content = create("Frame", {
		Size = UDim2.new(1, -20, 1, -80),
		Position = UDim2.new(0, 10, 0, 70),
		BackgroundTransparency = 1,
		Parent = mainCase
	})

	-- LEFT: Filter Tabs & List
	local leftPanel = create("Frame", {
		Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = content
	})

	local tabContainer = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Parent = leftPanel
	})
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), Parent = tabContainer })

	local function createTab(name)
		local btn = create("TextButton", {
			Name = name,
			Text = name:upper(),
			Size = UDim2.new(0.25, -5, 1, 0),
			BackgroundColor3 = (state.currentTab == name) and COLORS.ACCENT_GOLD or COLORS.BG_PANEL,
			TextColor3 = (state.currentTab == name) and COLORS.BG_ROOT or COLORS.TEXT_DIM,
			Font = FONTS.Header,
			Parent = tabContainer
		})
		addCorner(btn, 4)
		btn.MouseButton1Click:Connect(function()
			state.currentTab = name
			self:RefreshList()
			-- Update visual
			for _, c in ipairs(tabContainer:GetChildren()) do
				if c:IsA("TextButton") then
					local active = (c.Name == state.currentTab)
					c.BackgroundColor3 = active and COLORS.ACCENT_GOLD or COLORS.BG_PANEL
					c.TextColor3 = active and COLORS.BG_ROOT or COLORS.TEXT_DIM
				end
			end
		end)
	end

	createTab("All")
	createTab("Skins")
	createTab("Titles")
	createTab("Utility")

	listContainer = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.ACCENT_GOLD,
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = leftPanel
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), Parent = listContainer })

	-- RIGHT: Showcase & Details
	local rightPanel = create("Frame", {
		Size = UDim2.new(0.58, 0, 1, 0),
		Position = UDim2.new(0.42, 0, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = content
	})
	addCorner(rightPanel, 8)
	addStroke(rightPanel, COLORS.TEXT_DIM, 1)

	-- Showcase Viewport
	local showcase = create("Frame", {
		Size = UDim2.new(1, -20, 0.5, 0),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = rightPanel
	})
	addCorner(showcase, 8)
	addStroke(showcase, COLORS.ACCENT_GOLD, 1)

	previewViewport = create("ViewportFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = showcase
	})

	previewIconLabel = create("TextLabel", {
		Text = "★",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 100,
		TextColor3 = COLORS.TEXT_DIM,
		Parent = showcase
	})

	-- Details Below
	detailsPanel = create("Frame", {
		Name = "Details",
		Size = UDim2.new(1, -20, 0.45, -20),
		Position = UDim2.new(0, 10, 0.55, 0),
		BackgroundTransparency = 1,
		Parent = rightPanel
	})

	create("TextLabel", {
		Name = "Title",
		Text = "SELECT RECORD",
		Size = UDim2.new(1, 0, 0, 30),
		Font = FONTS.Header,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local metaFrame = create("Frame", {
		Name = "MetaFrame",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})
	create("TextLabel", { Name = "RarityLabel", Text = "---", Size = UDim2.new(1, 0, 1, 0), Font = FONTS.Mono, TextSize = 14, TextColor3 = COLORS.TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = metaFrame })

	create("TextLabel", {
		Name = "Description",
		Text = "Review service records to exchange points.",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.new(0, 0, 0, 60),
		Font = FONTS.Body,
		TextSize = 14,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local buySection = create("Frame", {
		Name = "BuySection",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -50),
		BackgroundTransparency = 1,
		Parent = detailsPanel
	})

	local priceFrame = create("Frame", { Name = "PriceFrame", Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Parent = buySection })
	create("TextLabel", { Text = "REQ. POINTS:", Size = UDim2.new(1, 0, 0, 15), Font = FONTS.Mono, TextSize = 10, TextColor3 = COLORS.TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = priceFrame })
	create("TextLabel", { Name = "Amount", Text = "0 AP", Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 15), Font = FONTS.Header, TextSize = 28, TextColor3 = COLORS.ACCENT_GOLD, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = priceFrame })

	local buyBtn = create("TextButton", {
		Name = "BuyButton",
		Text = "",
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = COLORS.ACCENT_GOLD,
		Parent = buySection
	})
	addCorner(buyBtn, 4)
	create("TextLabel", { Name = "Label", Text = "EXCHANGE", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = FONTS.Header, TextSize = 18, TextColor3 = COLORS.BG_ROOT, Parent = buyBtn })

	buyBtn.MouseButton1Click:Connect(function() self:PurchaseItem() end)

	self:RefreshList()
end


function apShopUI:PurchaseItem()
	if not state.selectedItem then return end
	if state.selectedItem.Owned then return end
	if state.currentAP < state.selectedItem.Cost then return end

	-- Safe access
	if not detailsPanel then return end
	local buySection = detailsPanel:FindFirstChild("BuySection")
	if not buySection then return end
	local btn = buySection:FindFirstChild("BuyButton")
	if not btn then return end

	local lbl = btn:FindFirstChild("Label")
	if not lbl then return end

	lbl.Text = "PROCESSING..."

	local result
	if state.selectedItem.Type == "Skins" then
		result = purchaseSkinFunc:InvokeServer(state.selectedItem.Weapon, state.selectedItem.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(state.selectedItem.Id)
	end

	if result.Success then
		state.selectedItem.Owned = true
		lbl.Text = "APPROVED"
		btn.BackgroundColor3 = COLORS.ACCENT_SUCCESS
		self:UpdateAP()
		task.delay(1, function()
			self:UpdateDetails()
			self:RefreshList()
		end)
	else
		lbl.Text = "DENIED"
		btn.BackgroundColor3 = COLORS.ACCENT_FAIL
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

		-- Enable Blur
		if state.blurEffect then state.blurEffect.Enabled = true end

		self:LoadData()
		self:RefreshList()
		self:UpdateAP()

		-- Anim: Slide up case
		if screenGui:FindFirstChild("MainCase") then
			screenGui.MainCase.Position = UDim2.new(0.5, 0, 0.6, 0)
			screenGui.MainCase.BackgroundTransparency = 1
			TweenService:Create(screenGui.MainCase, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 0
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

		-- Disable Blur
		if state.blurEffect then 
			state.blurEffect.Enabled = false 
		end
	end
	if state.activePreview then 
		ModelPreviewModule.destroy(state.activePreview) 
		state.activePreview = nil 
	end
	-- Proximity logic removed
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

-- Replaced ProximityUIHandler with manual logic
local function setupPrompt()
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment", 10)
	if not lobbyEnv then return end

	local shopPart = lobbyEnv:WaitForChild("APShop", 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if screenGui.Enabled then
					apShopUI:Hide()
				else
					apShopUI:Show()
				end
			end)
		end
	end
end

task.spawn(setupPrompt)

return apShopUI
