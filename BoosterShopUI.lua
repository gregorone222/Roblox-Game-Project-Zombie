-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- Theme: Prototype Match (Slate/Indigo Theme), No Image Assets (Unicode Only)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ==================================
-- ======== SERVICE SETUP ===========
-- ==================================
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local ToggleBoosterShopEvent = RemoteEvents:WaitForChild("ToggleBoosterShopEvent")
local PurchaseBoosterFunction = RemoteFunctions:WaitForChild("PurchaseBoosterFunction")
local GetBoosterConfig = RemoteFunctions:WaitForChild("GetBoosterConfig")

-- ==================================
-- ======== THEME CONSTANTS =========
-- ==================================
local THEME = {
	BgDark = Color3.fromHex("#0f172a"),      -- Slate-900 (Main BG)
	PanelBg = Color3.fromHex("#1e293b"),     -- Slate-800 (Panels)
	Accent = Color3.fromHex("#6366f1"),      -- Indigo-500 (Primary Action)
	AccentHover = Color3.fromHex("#4f46e5"), -- Indigo-600
	TextMain = Color3.fromHex("#f8fafc"),    -- Slate-50
	TextDim = Color3.fromHex("#94a3b8"),     -- Slate-400
	Border = Color3.fromHex("#334155"),      -- Slate-700
	Success = Color3.fromHex("#10b981"),     -- Emerald-500
	Error = Color3.fromHex("#ef4444"),       -- Red-500
	Gold = Color3.fromHex("#fbbf24"),        -- Amber-400 (Currency)
}

local FONTS = {
	Header = Enum.Font.GothamBlack,
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code
}

-- Unicode Icons Mapping (Pengganti Asset ID)
local ICONS = {
	SelfRevive = "💗",       -- Heart Pulse
	StarterPoints = "💰",    -- Money Bag
	CouponDiscount = "🏷️",   -- Tag
	StartingShield = "🛡️",   -- Shield
	LegionsLegacy = "⚔️",    -- Crossed Swords
	Default = "📦",          -- Box
	Currency = "🩸",         -- Blood Drop (Currency)
	Shop = "🏪"
}

local CATEGORIES = {
	SelfRevive = "SURVIVAL",
	StarterPoints = "ECONOMY",
	CouponDiscount = "ECONOMY",
	StartingShield = "DEFENSE",
	LegionsLegacy = "WEAPON"
}

-- ==================================
-- ======== UI UTILITIES ============
-- ==================================

local function create(className, properties, children)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addPadding(parent, padding)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, padding)
	pad.PaddingBottom = UDim.new(0, padding)
	pad.PaddingLeft = UDim.new(0, padding)
	pad.PaddingRight = UDim.new(0, padding)
	pad.Parent = parent
	return pad
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- ==================================
-- ======== STATE MANAGEMENT ========
-- ==================================
local state = {
	isOpen = false,
	selectedId = nil,
	config = {},
	playerData = { coins = 0, inventory = {} },
	itemButtons = {} -- Cache for sidebar buttons
}

-- ==================================
-- ======== UI CONSTRUCTION =========
-- ==================================

local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false
})

-- 1. Dark Overlay
local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.6,
	Parent = screenGui
})

-- 2. Main Window (Glass Panel)
local mainWindow = create("Frame", {
	Name = "MainWindow",
	Size = UDim2.fromOffset(900, 600),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.BgDark,
	BorderSizePixel = 0,
	Parent = overlay
})
addCorner(mainWindow, 24)
addStroke(mainWindow, Color3.new(1, 1, 1), 1, 0.9) -- Subtle white border

-- 3. Sidebar (Left)
local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 320, 1, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.2,
	Parent = mainWindow
})
addCorner(sidebar, 24)
-- Masking fix: Add a frame to cover right corners so it looks attached
local sidebarMask = create("Frame", {
	Size = UDim2.new(0, 20, 1, 0),
	Position = UDim2.new(1, -20, 0, 0),
	BackgroundColor3 = THEME.BgDark, -- Match BG
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	ZIndex = 1,
	Parent = sidebar
})

local sidebarContent = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = sidebar
})
addPadding(sidebarContent, 24)

-- Sidebar Header
local headerFrame = create("Frame", {
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundTransparency = 1,
	Parent = sidebarContent
})
local headerTitle = create("TextLabel", {
	Text = ICONS.Shop .. " BOOSTER SHOP",
	Font = FONTS.Header,
	TextSize = 22,
	TextColor3 = THEME.TextMain,
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = headerFrame
})
create("TextLabel", {
	Text = "Tingkatkan kemampuan tempurmu.",
	Font = FONTS.Body,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 0, 0, 26),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = headerFrame
})

-- Balance Display
local balanceContainer = create("Frame", {
	Size = UDim2.new(1, 0, 0, 45),
	Position = UDim2.new(0, 0, 0, 70),
	BackgroundColor3 = THEME.PanelBg,
	BackgroundTransparency = 0.5,
	Parent = sidebarContent
})
addCorner(balanceContainer, 12)
addStroke(balanceContainer, THEME.Border, 1)
addPadding(balanceContainer, 10)

create("TextLabel", {
	Text = "SALDO ANDA",
	Font = FONTS.Header,
	TextSize = 10,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = balanceContainer
})

local balanceLabel = create("TextLabel", {
	Text = "0 " .. ICONS.Currency,
	Font = FONTS.Mono,
	TextSize = 18,
	TextColor3 = THEME.Gold,
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = balanceContainer
})

-- Item List (Scroll)
local itemList = create("ScrollingFrame", {
	Name = "ItemList",
	Size = UDim2.new(1, 0, 1, -130),
	Position = UDim2.new(0, 0, 0, 130),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.TextDim,
	CanvasSize = UDim2.new(0, 0, 0, 0), -- Auto
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = sidebarContent
})
create("UIListLayout", {
	Parent = itemList,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8)
})

-- 4. Detail Panel (Right)
local detailPanel = create("Frame", {
	Name = "DetailPanel",
	Size = UDim2.new(1, -320, 1, 0),
	Position = UDim2.new(0, 320, 0, 0),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	Parent = mainWindow
})
-- Background gradient for detail panel
local detailBg = create("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0.95,
	ZIndex = 0,
	Parent = detailPanel
})
local detailContent = create("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = detailPanel
})
addPadding(detailContent, 32)

-- Close Button
local closeBtn = create("TextButton", {
	Text = "×",
	Font = FONTS.Header,
	TextSize = 24,
	TextColor3 = THEME.TextMain,
	Size = UDim2.fromOffset(32, 32),
	Position = UDim2.new(1, 0, 0, 0),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = THEME.PanelBg,
	AutoButtonColor = true,
	Parent = detailContent
})
addCorner(closeBtn, 16)

-- Preview Area (Center)
local previewArea = create("Frame", {
	Name = "Preview",
	Size = UDim2.new(1, 0, 1, -90), -- Minus Action Bar
	BackgroundTransparency = 1,
	Parent = detailContent
})
create("UIListLayout", {
	Parent = previewArea,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 20)
})

-- Large Icon
local largeIconContainer = create("Frame", {
	Size = UDim2.fromOffset(140, 140),
	BackgroundColor3 = THEME.BgDark,
	LayoutOrder = 1,
	Parent = previewArea
})
addCorner(largeIconContainer, 30)
addStroke(largeIconContainer, Color3.new(1,1,1), 2, 0.9)
local largeIconLabel = create("TextLabel", {
	Text = ICONS.Default,
	TextSize = 80,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Parent = largeIconContainer
})

-- Detail Text
local dName = create("TextLabel", {
	Text = "Pilih Item",
	Font = FONTS.Header,
	TextSize = 32,
	TextColor3 = THEME.TextMain,
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.XY,
	LayoutOrder = 2,
	Parent = previewArea
})
local dType = create("TextLabel", {
	Text = "SYSTEM",
	Font = FONTS.Header,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	BackgroundColor3 = THEME.PanelBg,
	Size = UDim2.fromOffset(100, 24),
	LayoutOrder = 3,
	Parent = previewArea
})
addCorner(dType, 12)

local dDesc = create("TextLabel", {
	Text = "Pilih booster dari daftar di sebelah kiri untuk melihat detail.",
	Font = FONTS.Body,
	TextSize = 16,
	TextColor3 = THEME.TextDim,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 400, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	TextWrapped = true,
	TextTransparency = 0.2,
	LayoutOrder = 4,
	Parent = previewArea
})

-- Action Bar (Bottom)
local actionBar = create("Frame", {
	Size = UDim2.new(1, 0, 0, 80),
	Position = UDim2.new(0, 0, 1, 0),
	AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.6,
	Parent = detailContent
})
addCorner(actionBar, 16)
addStroke(actionBar, Color3.new(1,1,1), 1, 0.9)
addPadding(actionBar, 16)

-- Price Section
local priceSection = create("Frame", {
	Size = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = actionBar
})
create("UIListLayout", { Parent = priceSection, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2)})
create("TextLabel", {
	Text = "HARGA",
	Font = FONTS.Header,
	TextSize = 10,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 12),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = priceSection
})
local dPrice = create("TextLabel", {
	Text = "- " .. ICONS.Currency,
	Font = FONTS.Header,
	TextSize = 24,
	TextColor3 = THEME.TextMain,
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = priceSection
})
local dOwned = create("TextLabel", {
	Text = "Dimiliki: 0",
	Font = FONTS.Body,
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = priceSection
})

-- Buy Button
local btnBuy = create("TextButton", {
	Text = "BELI SEKARANG",
	Font = FONTS.Header,
	TextSize = 14,
	TextColor3 = THEME.TextMain,
	BackgroundColor3 = THEME.Accent,
	Size = UDim2.new(0, 180, 1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	AnchorPoint = Vector2.new(1, 0),
	AutoButtonColor = true,
	Parent = actionBar
})
addCorner(btnBuy, 12)

-- Toast Notification (Overlay)
local toast = create("Frame", {
	Name = "Toast",
	Size = UDim2.new(0, 0, 0, 40), -- Auto X
	Position = UDim2.new(0.5, 0, 1, -40),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = THEME.Success,
	AutomaticSize = Enum.AutomaticSize.X,
	Visible = false,
	ZIndex = 100,
	Parent = overlay
})
addCorner(toast, 20)
addPadding(toast, 12)
local toastLabel = create("TextLabel", {
	Text = "Berhasil!",
	Font = FONTS.Header,
	TextSize = 14,
	TextColor3 = THEME.TextMain,
	BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.new(0, 0, 1, 0),
	Parent = toast
})

-- ==================================
-- ======== LOGIC FUNCTIONS =========
-- ==================================

local function showToast(message, isError)
	toastLabel.Text = message
	toast.BackgroundColor3 = isError and THEME.Error or THEME.Success

	toast.Visible = true
	toast.BackgroundTransparency = 0
	toastLabel.TextTransparency = 0
	toast.Position = UDim2.new(0.5, 0, 1, -40)

	-- Slide up animation
	local t1 = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -100)
	})
	t1:Play()

	task.delay(2.5, function()
		-- Fade out
		local t2 = TweenService:Create(toast, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		local t3 = TweenService:Create(toastLabel, TweenInfo.new(0.3), {TextTransparency = 1})
		t2:Play(); t3:Play()
		t2.Completed:Wait()
		toast.Visible = false
	end)
end

-- Animation Loop for Large Icon Float
task.spawn(function()
	while true do
		if state.isOpen then
			local t = tick()
			local offset = math.sin(t * 2) * 5
			largeIconContainer.Position = UDim2.new(0.5, 0, 0.45, offset) -- Center vertical anchor is complex here due to list layout, using margin/padding logic is safer but layout order simplifies position.
			-- Actually since it's in a UIListLayout, Position property is ignored. 
			-- We need to wrap it or animate Padding in Layout?
			-- Simpler: Use rotation or size pulse for List items, or just ignore float for now.
			-- Let's animate size slightly instead to simulate breathing.
			local scale = 1 + (math.sin(t * 3) * 0.02)
			largeIconContainer.Size = UDim2.fromOffset(140 * scale, 140 * scale)
		end
		task.wait(0.03)
	end
end)

local function updateDetailPanel(boosterId)
	state.selectedId = boosterId
	local config = state.config[boosterId]

	if not config then return end

	-- Update Text
	dName.Text = config.Name
	dDesc.Text = config.Description
	dType.Text = CATEGORIES[boosterId] or "ITEM"

	local price = config.Price
	dPrice.Text = string.format("%s %s", price, ICONS.Currency)

	local owned = (state.playerData.inventory and state.playerData.inventory[boosterId]) or 0
	dOwned.Text = "Dimiliki: " .. owned

	-- Update Icon
	largeIconLabel.Text = ICONS[boosterId] or ICONS.Default

	-- Update Button
	local canAfford = state.playerData.coins >= price
	if canAfford then
		btnBuy.Text = "BELI SEKARANG"
		btnBuy.BackgroundColor3 = THEME.Accent
		btnBuy.Active = true
		btnBuy.AutoButtonColor = true
	else
		btnBuy.Text = "SALDO KURANG"
		btnBuy.BackgroundColor3 = THEME.Border
		btnBuy.Active = false
		btnBuy.AutoButtonColor = false
	end

	-- Update Sidebar Selection Highlight
	for id, btn in pairs(state.itemButtons) do
		local isSelected = (id == boosterId)
		local stroke = btn:FindFirstChild("UIStroke")
		local bg = btn:FindFirstChild("Bg")

		if isSelected then
			TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Color = THEME.Accent}):Play()
			TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundTransparency = 0.85}):Play()
		else
			TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
			TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundTransparency = 0.97}):Play()
		end
	end
end

local function populateSidebar()
	-- Clear list
	for _, c in ipairs(itemList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	state.itemButtons = {}

	-- Sort items by price
	local sorted = {}
	for id, cfg in pairs(state.config) do
		table.insert(sorted, {id = id, cfg = cfg})
	end
	table.sort(sorted, function(a,b) return a.cfg.Price < b.cfg.Price end)

	for _, item in ipairs(sorted) do
		local id = item.id
		local cfg = item.cfg
		local owned = (state.playerData.inventory and state.playerData.inventory[id]) or 0

		-- Card Button
		local btn = create("TextButton", {
			Name = id,
			Size = UDim2.new(1, -8, 0, 70),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = itemList
		})

		-- Background Layer
		local bg = create("Frame", {
			Name = "Bg",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.new(1,1,1),
			BackgroundTransparency = 0.97,
			Parent = btn
		})
		addCorner(bg, 12)

		-- Stroke
		addStroke(btn, THEME.Border, 1, 1) -- Hidden by default

		-- Small Icon
		local iconBox = create("Frame", {
			Size = UDim2.fromOffset(48, 48),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = THEME.BgDark,
			Parent = btn
		})
		addCorner(iconBox, 8)
		addStroke(iconBox, Color3.new(1,1,1), 1, 0.9)

		create("TextLabel", {
			Text = ICONS[id] or ICONS.Default,
			TextSize = 24,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = iconBox
		})

		-- Title & Owned
		create("TextLabel", {
			Text = cfg.Name,
			Font = FONTS.Header,
			TextSize = 14,
			TextColor3 = THEME.TextMain,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 72, 0, 14),
			Size = UDim2.new(1, -140, 0, 14),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn
		})

		create("TextLabel", {
			Text = "Owned: " .. owned,
			Font = FONTS.Mono,
			TextSize = 11,
			TextColor3 = THEME.TextDim,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 72, 0, 32),
			Size = UDim2.new(1, -140, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn
		})

		-- Price
		create("TextLabel", {
			Text = cfg.Price,
			Font = FONTS.Header,
			TextSize = 14,
			TextColor3 = THEME.Gold,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.new(0, 60, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = btn
		})

		-- Logic
		btn.MouseButton1Click:Connect(function()
			updateDetailPanel(id)
		end)

		btn.MouseEnter:Connect(function()
			if state.selectedId ~= id then
				TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundTransparency = 0.92}):Play()
			end
		end)

		btn.MouseLeave:Connect(function()
			if state.selectedId ~= id then
				TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundTransparency = 0.97}):Play()
			end
		end)

		state.itemButtons[id] = btn
	end
end

local function openShop(data)
	state.isOpen = true
	screenGui.Enabled = true
	overlay.Visible = true

	state.playerData = data -- Sync coins & inventory
	balanceLabel.Text = string.format("%s %s", state.playerData.coins, ICONS.Currency)

	-- Fetch Config if empty
	if not next(state.config) then
		state.config = GetBoosterConfig:InvokeServer()
	end

	populateSidebar()

	-- Select first
	local firstId = next(state.config)
	updateDetailPanel(state.selectedId or firstId)

	-- Animate In
	mainWindow.Position = UDim2.new(0.5, 0, 0.55, 0)
	mainWindow.BackgroundTransparency = 1
	for _, c in pairs(mainWindow:GetChildren()) do
		if c:IsA("GuiObject") then c.Visible = false end
	end

	local t = TweenService:Create(mainWindow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0
	})
	t:Play()

	task.wait(0.1)
	for _, c in pairs(mainWindow:GetChildren()) do
		if c:IsA("GuiObject") then c.Visible = true end
	end
end

local function closeShop()
	-- Animate Out
	local t = TweenService:Create(mainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.6, 0),
		BackgroundTransparency = 1
	})
	t:Play()
	t.Completed:Wait()

	screenGui.Enabled = false
	state.isOpen = false
end

-- Buy Action
btnBuy.MouseButton1Click:Connect(function()
	if not state.selectedId or not btnBuy.Active then return end

	local result = PurchaseBoosterFunction:InvokeServer(state.selectedId)

	if result.success then
		showToast("Pembelian Berhasil!", false)
		-- Mock update local data for instant feedback (server will authoritative sync later if needed)
		state.playerData.coins = state.playerData.coins - state.config[state.selectedId].Price
		state.playerData.inventory[state.selectedId] = (state.playerData.inventory[state.selectedId] or 0) + 1

		balanceLabel.Text = string.format("%s %s", state.playerData.coins, ICONS.Currency)
		populateSidebar() -- Update owned count in list
		updateDetailPanel(state.selectedId)
	else
		showToast(result.message or "Gagal", true)
	end
end)

closeBtn.MouseButton1Click:Connect(closeShop)

-- Global Toggle Event
ToggleBoosterShopEvent.OnClientEvent:Connect(function(data)
	openShop(data)
end)

-- Close on Escape
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and state.isOpen then
		closeShop()
	end
end)
