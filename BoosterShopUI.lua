-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================================
-- ======== SERVICE SETUP ===========
-- ==================================
local ToggleBoosterShopEvent = ReplicatedStorage.RemoteEvents:WaitForChild("ToggleBoosterShopEvent")
local PurchaseBoosterFunction = ReplicatedStorage.RemoteFunctions:WaitForChild("PurchaseBoosterFunction")
local GetBoosterConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetBoosterConfig")

-- ==================================
-- ======== THEME CONSTANTS =========
-- ==================================
local THEME = {
	BgDark = Color3.fromHex("#0f172a"),      -- Slate-900
	PanelBg = Color3.fromHex("#1e293b"),     -- Slate-800
	Accent = Color3.fromHex("#6366f1"),      -- Indigo-500
	AccentHover = Color3.fromHex("#4f46e5"), -- Indigo-600
	TextMain = Color3.fromHex("#f8fafc"),    -- Slate-50
	TextDim = Color3.fromHex("#94a3b8"),     -- Slate-400
	TextDark = Color3.fromHex("#334155"),    -- Slate-700
	Border = Color3.fromHex("#334155"),      -- Slate-700
	Success = Color3.fromHex("#10b981"),     -- Emerald-500
	Error = Color3.fromHex("#ef4444"),       -- Red-500
	Gold = Color3.fromHex("#fbbf24"),        -- Amber-400
	CardBg = Color3.fromHex("#1e293b"),      -- Slate-800 (Base)
	CardHover = Color3.fromHex("#334155"),   -- Slate-700
}

-- Unicode Icon Mapping based on BoosterConfig keys
local ICONS = {
	SelfRevive = "💗",
	StarterPoints = "💰",
	CouponDiscount = "🏷️",
	StartingShield = "🛡️",
	LegionsLegacy = "⚔️",
	Default = "📦"
}

-- Category Mapping (Inferred)
local CATEGORIES = {
	SelfRevive = "SURVIVAL",
	StarterPoints = "ECONOMY",
	CouponDiscount = "ECONOMY",
	StartingShield = "DEFENSE",
	LegionsLegacy = "WEAPON"
}

-- ==================================
-- ======== UI CONSTRUCTION =========
-- ==================================

local function create(instanceType, properties, children)
	local obj = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		obj[prop] = value
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = obj
		end
	end
	return obj
end

local function createUICorner(radius, parent)
	create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function createPadding(px, parent)
	create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent
	})
end

-- Create ScreenGui
local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
})

-- Background Overlay (Glass Effect)
local overlay = create("Frame", {
	Name = "Overlay",
	Parent = screenGui,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.6,
	Visible = false,
	ZIndex = 100,
})

-- Main Window
local mainWindow = create("Frame", {
	Name = "MainWindow",
	Parent = overlay,
	Size = UDim2.fromOffset(900, 600),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 1.5, 0), -- Start off-screen
	BackgroundColor3 = THEME.BgDark,
	BorderSizePixel = 0,
})
createUICorner(24, mainWindow)
create("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.9, Thickness = 1, Parent = mainWindow })

-- ==================================
-- ======== SIDEBAR (LEFT) ==========
-- ==================================
local sidebar = create("Frame", {
	Name = "Sidebar",
	Parent = mainWindow,
	Size = UDim2.new(0, 320, 1, 0),
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
})
createUICorner(24, sidebar)
local sidebarMask = create("Frame", { -- To handle corner clipping properly
	Name = "SidebarMask",
	Parent = sidebar,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
})
create("UICorner", { CornerRadius = UDim.new(0, 24), Parent = sidebar })
-- Cover the right side corners so it looks attached
local sidebarCover = create("Frame", {
	Parent = sidebar,
	Size = UDim2.new(0, 20, 1, 0),
	Position = UDim2.new(1, -20, 0, 0),
	BackgroundColor3 = THEME.BgDark, -- Match background
	BackgroundTransparency = 0.2, -- Match sidebar transparency
	BorderSizePixel = 0,
	ZIndex = 0
})

-- Sidebar Content Container
local sidebarContent = create("Frame", {
	Name = "Content",
	Parent = sidebar,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
})
createPadding(24, sidebarContent)

-- Header
local headerFrame = create("Frame", {
	Parent = sidebarContent,
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundTransparency = 1,
})
local headerIcon = create("TextLabel", {
	Parent = headerFrame,
	Text = "📦",
	TextSize = 24,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 30, 0, 30),
	TextColor3 = THEME.Accent,
})
local headerTitle = create("TextLabel", {
	Parent = headerFrame,
	Text = "BOOSTER SHOP",
	Font = Enum.Font.GothamBlack,
	TextSize = 22,
	TextColor3 = THEME.TextMain,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 36, 0, 0),
	Size = UDim2.new(1, -36, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local headerSubtitle = create("TextLabel", {
	Parent = headerFrame,
	Text = "Tingkatkan kemampuan tempurmu.",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 30),
	Size = UDim2.new(1, 0, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Separator
local separator = create("Frame", {
	Parent = sidebarContent,
	Size = UDim2.new(1, 0, 0, 1),
	Position = UDim2.new(0, 0, 0, 65),
	BackgroundColor3 = THEME.Border,
	BorderSizePixel = 0,
})

-- Balance Display
local balanceFrame = create("Frame", {
	Parent = sidebarContent,
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0, 80),
	BackgroundColor3 = THEME.PanelBg,
	BorderSizePixel = 0,
})
createUICorner(12, balanceFrame)
create("UIStroke", { Color = THEME.Border, Thickness = 1, Parent = balanceFrame })
createPadding(12, balanceFrame)

local balanceLabel = create("TextLabel", {
	Parent = balanceFrame,
	Text = "SALDO ANDA",
	Font = Enum.Font.GothamBold,
	TextSize = 10,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 80, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local balanceValue = create("TextLabel", {
	Name = "Value",
	Parent = balanceFrame,
	Text = "0 🩸",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = THEME.Gold,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -80, 1, 0),
	Position = UDim2.new(0, 80, 0, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
})

-- Item List (ScrollingFrame)
local itemList = create("ScrollingFrame", {
	Name = "ItemList",
	Parent = sidebarContent,
	Size = UDim2.new(1, 0, 1, -150), -- Fill remaining space
	Position = UDim2.new(0, 0, 0, 145),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.TextDim,
	CanvasSize = UDim2.new(0, 0, 0, 0), -- Automatic
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
})
create("UIListLayout", {
	Parent = itemList,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
})

-- ==================================
-- ======== DETAIL PANEL (RIGHT) ====
-- ==================================
local detailPanel = create("Frame", {
	Name = "DetailPanel",
	Parent = mainWindow,
	Size = UDim2.new(1, -320, 1, 0),
	Position = UDim2.new(0, 320, 0, 0),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
})
-- Gradient Background for Detail Panel
local detailBg = create("Frame", {
	Parent = detailPanel,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0.95,
	ZIndex = 0,
})
createUICorner(24, detailBg)
-- Fix corner overlap: Left side should be square to join with sidebar
local detailBgCover = create("Frame", {
	Parent = detailBg,
	Size = UDim2.new(0, 20, 1, 0),
	BackgroundColor3 = THEME.Accent, 
	Visible = false
})

local detailContent = create("Frame", {
	Parent = detailPanel,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
})
createPadding(32, detailContent)

-- Close Button
local closeButton = create("TextButton", {
	Parent = detailContent,
	Size = UDim2.fromOffset(32, 32),
	Position = UDim2.new(1, 0, 0, 0),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = THEME.PanelBg,
	Text = "×",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = THEME.TextMain,
	AutoButtonColor = false,
})
createUICorner(16, closeButton)
closeButton.MouseButton1Click:Connect(function()
	toggleShop(false)
end)

-- Preview Container (Center content)
local previewContainer = create("Frame", {
	Name = "PreviewContainer",
	Parent = detailContent,
	Size = UDim2.new(1, 0, 1, -100), -- Leave room for action bar
	BackgroundTransparency = 1,
})
create("UIListLayout", {
	Parent = previewContainer,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 16),
})

-- Large Icon Wrapper
local iconWrapper = create("Frame", {
	Name = "IconWrapper",
	Parent = previewContainer,
	Size = UDim2.fromOffset(140, 140),
	BackgroundColor3 = THEME.BgDark,
	LayoutOrder = 1,
})
createUICorner(30, iconWrapper)
create("UIStroke", {
	Name = "Stroke",
	Parent = iconWrapper,
	Color = Color3.new(1,1,1),
	Transparency = 0.9,
	Thickness = 2,
})
local largeIcon = create("TextLabel", {
	Parent = iconWrapper,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "📦",
	TextSize = 80,
	TextColor3 = THEME.TextMain,
})

-- Detail Text
local detailName = create("TextLabel", {
	Parent = previewContainer,
	LayoutOrder = 2,
	Text = "Pilih Item",
	Font = Enum.Font.GothamBlack,
	TextSize = 36,
	TextColor3 = THEME.TextMain,
	AutomaticSize = Enum.AutomaticSize.XY,
	BackgroundTransparency = 1,
})

local detailTypeBadge = create("TextLabel", {
	Parent = previewContainer,
	LayoutOrder = 3,
	Text = "SYSTEM",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	BackgroundColor3 = THEME.PanelBg,
	Size = UDim2.fromOffset(80, 24),
	BorderSizePixel = 0,
})
createUICorner(12, detailTypeBadge)

local detailDesc = create("TextLabel", {
	Parent = previewContainer,
	LayoutOrder = 4,
	Text = "Pilih booster dari daftar di sebelah kiri.",
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 400, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextWrapped = true,
	TextTransparency = 0.2,
})

-- Action Bar (Bottom)
local actionBar = create("Frame", {
	Name = "ActionBar",
	Parent = detailContent,
	Size = UDim2.new(1, 0, 0, 80),
	Position = UDim2.new(0, 0, 1, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.4,
})
createUICorner(16, actionBar)
create("UIStroke", { Color = Color3.new(1,1,1), Transparency = 0.9, Parent = actionBar })
createPadding(16, actionBar)

-- Price Info (Left of Action Bar)
local priceContainer = create("Frame", {
	Parent = actionBar,
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
})
create("UIListLayout", { Parent = priceContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) })

local priceHeader = create("TextLabel", {
	Parent = priceContainer,
	LayoutOrder = 1,
	Text = "HARGA",
	Font = Enum.Font.GothamBold,
	TextSize = 10,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 12),
	TextXAlignment = Enum.TextXAlignment.Left,
})
local detailPrice = create("TextLabel", {
	Parent = priceContainer,
	LayoutOrder = 2,
	Text = "- 🩸",
	Font = Enum.Font.GothamBlack,
	TextSize = 24,
	TextColor3 = THEME.TextMain,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 28),
	TextXAlignment = Enum.TextXAlignment.Left,
	RichText = true,
})
local detailOwned = create("TextLabel", {
	Parent = priceContainer,
	LayoutOrder = 3,
	Text = "Dimiliki: 0",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 16),
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- Buy Button (Right of Action Bar)
local buyButton = create("TextButton", {
	Parent = actionBar,
	Size = UDim2.new(0, 180, 1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = THEME.Accent,
	Text = "BELI SEKARANG",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.TextMain,
	AutoButtonColor = false,
})
createUICorner(12, buyButton)

-- Toast Notification
local toastFrame = create("Frame", {
	Name = "Toast",
	Parent = overlay,
	Size = UDim2.new(0, 0, 0, 40),
	Position = UDim2.new(0.5, 0, 1, -80),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = THEME.Success,
	AutomaticSize = Enum.AutomaticSize.X,
	Visible = false,
})
createUICorner(20, toastFrame)
local toastLabel = create("TextLabel", {
	Parent = toastFrame,
	Text = "Pembelian Berhasil!",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.TextMain,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 0, 1, 0),
	AutomaticSize = Enum.AutomaticSize.X,
})
createPadding(12, toastFrame) -- horizontal padding for toast

-- ==================================
-- ======== LOGIC & STATE ===========
-- ==================================
local boosterConfigCache = nil
local currentPlayerData = nil
local selectedBoosterId = nil
local itemButtons = {} -- Cache for button instances

local function showToast(message, isError)
	toastLabel.Text = message
	toastFrame.BackgroundColor3 = isError and THEME.Error or THEME.Success

	toastFrame.Visible = true
	toastFrame.Position = UDim2.new(0.5, 0, 1, -40)
	toastFrame.BackgroundTransparency = 0
	toastLabel.TextTransparency = 0

	-- Pop up animation
	TweenService:Create(toastFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -100)
	}):Play()

	task.delay(3, function()
		local fadeInfo = TweenInfo.new(0.5)
		TweenService:Create(toastFrame, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(toastLabel, fadeInfo, { TextTransparency = 1 }):Play()
		task.wait(0.5)
		toastFrame.Visible = false
	end)
end

local function updateDetailView(boosterId)
	selectedBoosterId = boosterId
	local config = boosterConfigCache and boosterConfigCache[boosterId]

	if not config then
		detailName.Text = "Pilih Item"
		detailDesc.Text = "Pilih booster dari daftar di sebelah kiri untuk melihat detail."
		largeIcon.Text = "📦"
		detailPrice.Text = "- 🩸"
		detailOwned.Text = "Dimiliki: -"
		buyButton.Visible = false
		detailTypeBadge.Visible = false
		return
	end

	local ownedCount = (currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory[boosterId]) or 0
	local canAfford = currentPlayerData and currentPlayerData.coins >= config.Price
	local iconChar = ICONS[boosterId] or ICONS.Default
	local category = CATEGORIES[boosterId] or "ITEM"

	-- Update Text
	detailName.Text = config.Name
	detailDesc.Text = config.Description
	largeIcon.Text = iconChar
	detailPrice.Text = config.Price .. " <font color='#fbbf24'>🩸</font>"
	detailOwned.Text = "Dimiliki: " .. ownedCount
	detailTypeBadge.Text = category
	detailTypeBadge.Visible = true

	-- Update Buy Button
	buyButton.Visible = true
	if canAfford then
		buyButton.Text = "BELI SEKARANG"
		buyButton.BackgroundColor3 = THEME.Accent
		buyButton.AutoButtonColor = true
		buyButton.Active = true
	else
		buyButton.Text = "SALDO KURANG"
		buyButton.BackgroundColor3 = THEME.Border
		buyButton.AutoButtonColor = false
		buyButton.Active = false
	end

	-- Update active state in sidebar
	for id, btn in pairs(itemButtons) do
		local isSelected = (id == boosterId)
		local bg = btn:FindFirstChild("Bg")
		local stroke = btn:FindFirstChild("UIStroke")
		local iconContainer = btn:FindFirstChild("IconContainer")
		local iconStroke = iconContainer and iconContainer:FindFirstChild("UIStroke")

		if isSelected then
			TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.85 }):Play() -- Slightly lighter
			TweenService:Create(stroke, TweenInfo.new(0.2), { Color = THEME.Accent, Transparency = 0 }):Play()
			if iconStroke then
				TweenService:Create(iconStroke, TweenInfo.new(0.2), { Color = THEME.Accent }):Play()
			end
		else
			TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.97 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.new(1,1,1), Transparency = 1 }):Play()
			if iconStroke then
				TweenService:Create(iconStroke, TweenInfo.new(0.2), { Color = Color3.new(1,1,1) }):Play()
			end
		end
	end
end

local function populateSidebar()
	if not boosterConfigCache then return end

	-- Clear old items
	for _, child in ipairs(itemList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	itemButtons = {}

	-- Sort items by price (or name if you prefer)
	local sortedItems = {}
	for id, cfg in pairs(boosterConfigCache) do
		table.insert(sortedItems, { id = id, cfg = cfg })
	end
	table.sort(sortedItems, function(a, b) return a.cfg.Price < b.cfg.Price end)

	for _, item in ipairs(sortedItems) do
		local id = item.id
		local cfg = item.cfg
		local owned = (currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory[id]) or 0
		local iconChar = ICONS[id] or ICONS.Default

		-- Card Button
		local btn = create("TextButton", {
			Name = id,
			Parent = itemList,
			Size = UDim2.new(1, -8, 0, 70), -- -8 for padding
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		})

		-- Background
		local bg = create("Frame", {
			Name = "Bg",
			Parent = btn,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.97, -- Very subtle default
		})
		createUICorner(12, bg)
		create("UIStroke", {
			Parent = btn,
			Color = Color3.new(1,1,1),
			Transparency = 1, -- Invisible by default
			Thickness = 1,
		})

		-- Icon Container
		local iconContainer = create("Frame", {
			Name = "IconContainer",
			Parent = btn,
			Size = UDim2.fromOffset(48, 48),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = THEME.BgDark,
		})
		createUICorner(8, iconContainer)
		create("UIStroke", {
			Parent = iconContainer,
			Color = Color3.new(1,1,1),
			Transparency = 0.9,
			Thickness = 1,
		})
		local iconLabel = create("TextLabel", {
			Parent = iconContainer,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = iconChar,
			TextSize = 24,
		})

		-- Text Content
		local nameLabel = create("TextLabel", {
			Parent = btn,
			Text = cfg.Name,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = THEME.TextMain,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 72, 0, 14),
			Size = UDim2.new(1, -140, 0, 14),
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local ownedLabel = create("TextLabel", {
			Parent = btn,
			Text = "Dimiliki: " .. owned,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = THEME.TextDim,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 72, 0, 32),
			Size = UDim2.new(1, -140, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- Price
		local priceLabel = create("TextLabel", {
			Parent = btn,
			Text = cfg.Price,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = THEME.Gold,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.new(0, 60, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
		})

		-- Interaction
		btn.MouseEnter:Connect(function()
			if selectedBoosterId ~= id then
				TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.92 }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if selectedBoosterId ~= id then
				TweenService:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 0.97 }):Play()
			end
		end)
		btn.MouseButton1Click:Connect(function()
			updateDetailView(id)
		end)

		itemButtons[id] = btn
	end
end

-- ==================================
-- ======== MAIN FUNCTIONS ==========
-- ==================================

function toggleShop(visible, data)
	overlay.Visible = true

	if visible then
		if data then
			currentPlayerData = data
		end

		-- Update Balance
		if currentPlayerData and currentPlayerData.coins then
			balanceValue.Text = currentPlayerData.coins .. " 🩸"
		end

		-- Re-populate to update "Owned" counts
		populateSidebar()

		-- Select first item if nothing selected or select cached
		local firstId = next(boosterConfigCache)
		updateDetailView(selectedBoosterId or firstId)

		-- Animate In
		mainWindow.Position = UDim2.new(0.5, 0, 0.55, 0) -- Start slightly lower
		mainWindow.BackgroundTransparency = 1
		for _, c in ipairs(mainWindow:GetChildren()) do
			if c:IsA("GuiObject") then c.GroupTransparency = 1 end -- Not supported in standard Luau yet, assume manual fade or simple move
		end

		local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(mainWindow, tweenInfo, { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
		-- Since we can't group transparency easily, we just rely on slide-in.
	else
		-- Animate Out
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t = TweenService:Create(mainWindow, tweenInfo, { Position = UDim2.new(0.5, 0, 1.5, 0) })
		t:Play()
		t.Completed:Wait()
		overlay.Visible = false
	end
end

buyButton.MouseButton1Click:Connect(function()
	if not selectedBoosterId or not buyButton.Active then return end

	local result = PurchaseBoosterFunction:InvokeServer(selectedBoosterId)

	if result.success then
		showToast("Pembelian Berhasil!", false)
		-- Update Local Data
		currentPlayerData.coins = result.newCoins
		currentPlayerData.inventory[selectedBoosterId] = result.newAmount

		-- Update UI
		balanceValue.Text = result.newCoins .. " 🩸"
		updateDetailView(selectedBoosterId)
		populateSidebar() -- To update list owned counts
	else
		showToast(result.message or "Pembelian Gagal", true)
	end
end)

-- Initialize
task.spawn(function()
	boosterConfigCache = GetBoosterConfig:InvokeServer()
	-- Initial population
end)

ToggleBoosterShopEvent.OnClientEvent:Connect(function(data)
	toggleShop(true, data)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and overlay.Visible then
		toggleShop(false)
	end
end)

-- Hover effects for close/buy buttons
closeButton.MouseEnter:Connect(function() TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = THEME.Error }):Play() end)
closeButton.MouseLeave:Connect(function() TweenService:Create(closeButton, TweenInfo.new(0.2), { BackgroundColor3 = THEME.PanelBg }):Play() end)

buyButton.MouseEnter:Connect(function() 
	if buyButton.Active then TweenService:Create(buyButton, TweenInfo.new(0.2), { BackgroundColor3 = THEME.AccentHover }):Play() end 
end)
buyButton.MouseLeave:Connect(function() 
	if buyButton.Active then TweenService:Create(buyButton, TweenInfo.new(0.2), { BackgroundColor3 = THEME.Accent }):Play() end 
end)

