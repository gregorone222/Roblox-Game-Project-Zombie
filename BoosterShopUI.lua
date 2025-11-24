-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- New "Armory" UI/UX Overhaul

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
-- ======== UI SETUP ================
-- ==================================
-- UI creation based on the new prototype.

-- Helper functions for creating UI elements
local function create(instanceType, properties)
	local obj = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		obj[prop] = value
	end
	return obj
end

local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

-- Main container that dims the background
local boosterShopContainer = create("Frame", {
	Name = "BoosterShopContainer",
	Parent = screenGui,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.8,
	Visible = false,
	ZIndex = 40,
})

-- Main shop window
local shopWindow = create("Frame", {
	Name = "ShopWindow",
	Parent = boosterShopContainer,
	Size = UDim2.new(0.9, 0, 0.9, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 1.5, 0), -- Start off-screen for entry animation
	BackgroundColor3 = Color3.fromRGB(15, 23, 42), -- slate-900
	BorderSizePixel = 0,
})
create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = shopWindow })
create("UIStroke", { Color = Color3.fromRGB(51, 65, 85), Thickness = 2, Parent = shopWindow })

-- Header
local header = create("Frame", {
	Name = "Header",
	Parent = shopWindow,
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = Color3.fromRGB(30, 41, 59), -- slate-800
	BorderSizePixel = 0,
})
create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Color = Color3.fromRGB(51, 65, 85), Thickness = 1, Parent = header })


local title = create("TextLabel", {
	Name = "Title",
	Parent = header,
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	Text = "GUDANG BOOSTER",
	Font = Enum.Font.GothamBlack,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Center,
	BackgroundTransparency = 1,
})

local closeShopButton = create("TextButton", {
	Name = "CloseShopButton",
	Parent = header,
	Size = UDim2.new(0, 40, 0, 40),
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Text = "×",
	Font = Enum.Font.GothamBold,
	TextSize = 32,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundColor3 = Color3.fromRGB(220, 38, 38), -- red-600
})
create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = closeShopButton })

-- Main content area
local mainContent = create("Frame", {
	Name = "MainContent",
	Parent = shopWindow,
	Size = UDim2.new(1, -48, 1, -84), -- Padding applied
	Position = UDim2.new(0.5, 0, 0.5, 30),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 24),
	Parent = mainContent,
})

-- Left panel: Item List
local itemListContainer = create("Frame", {
	Name = "ItemListContainer",
	Parent = mainContent,
	Size = UDim2.new(0.35, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(30, 41, 59), -- slate-800
	BorderSizePixel = 0,
	LayoutOrder = 1,
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = itemListContainer })
create("UIStroke", { Color = Color3.fromRGB(51, 65, 85), Thickness = 1, Parent = itemListContainer })
create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingBottom = UDim.new(0,16), Parent = itemListContainer })
local itemListLayout = create("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Parent = itemListContainer})

local itemListHeader = create("TextLabel", {
	Name = "ItemListHeader",
	Parent = itemListContainer,
	Size = UDim2.new(1, 0, 0, 30),
	Text = "Item Tersedia",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(241, 245, 249), -- slate-100
	TextXAlignment = Enum.TextXAlignment.Center,
	BackgroundTransparency = 1,
	LayoutOrder = 1,
})
itemListLayout.Padding = UDim.new(0,10)

local itemList = create("ScrollingFrame", {
	Name = "ItemList",
	Parent = itemListContainer,
	Size = UDim2.new(1, 0, 1, -40),
	BackgroundColor3 = Color3.fromRGB(30, 41, 59),
	BorderSizePixel = 0,
	ScrollBarImageColor3 = Color3.fromRGB(79, 70, 229), -- indigo-600
	ScrollBarThickness = 6,
	LayoutOrder = 2,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0,0,0,0),
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	SortOrder = Enum.SortOrder.Name,
	Padding = UDim.new(0, 12),
	Parent = itemList,
})
create("UIPadding", {PaddingRight = UDim.new(0,8), Parent=itemList})


-- Right panel: Detail View
local detailPanel = create("Frame", {
	Name = "DetailPanel",
	Parent = mainContent,
	Size = UDim2.new(0.65, -24, 1, 0),
	BackgroundColor3 = Color3.fromRGB(30, 41, 59), -- slate-800
	BorderSizePixel = 0,
	LayoutOrder = 2,
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = detailPanel })
create("UIStroke", { Color = Color3.fromRGB(51, 65, 85), Thickness = 1, Parent = detailPanel })
create("UIPadding", { PaddingTop = UDim.new(0, 32), PaddingLeft = UDim.new(0, 32), PaddingRight = UDim.new(0, 32), PaddingBottom = UDim.new(0,32), Parent = detailPanel })

-- Detail Panel Placeholder
local detailPlaceholder = create("Frame", {
	Name = "DetailPlaceholder",
	Parent = detailPanel,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible = true,
})
local placeholderLayout = create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 16),
	Parent = detailPlaceholder,
})
local placeholderIcon = create("ImageLabel", {
	Name = "PlaceholderIcon",
	Parent = detailPlaceholder,
	Size = UDim2.new(0, 96, 0, 96),
	Image = "rbxassetid://10621421113", -- A shield/check icon
	ImageColor3 = Color3.fromRGB(129, 140, 153), -- slate-500
	BackgroundTransparency = 1,
	LayoutOrder = 1,
})
local placeholderTitle = create("TextLabel", {
	Name = "PlaceholderTitle",
	Parent = detailPlaceholder,
	Size = UDim2.new(1, 0, 0, 30),
	Text = "Pilih Booster",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(100, 116, 139), -- slate-500
	BackgroundTransparency = 1,
	LayoutOrder = 2,
})
local placeholderDesc = create("TextLabel", {
	Name = "PlaceholderDesc",
	Parent = detailPlaceholder,
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Pilih item dari daftar di sebelah kiri untuk melihat detailnya.",
	Font = Enum.Font.Gotham,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(100, 116, 139), -- slate-500
	BackgroundTransparency = 1,
	LayoutOrder = 3,
})


-- Detail Panel Content
local detailContent = create("Frame", {
	Name = "DetailContent",
	Parent = detailPanel,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible = false,
})

-- Bottom container for purchase info and button (anchored to bottom)
local bottomContainer = create("Frame", {
	Name = "BottomContainer",
	Parent = detailContent,
	Size = UDim2.new(1, 0, 0, 140),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	BackgroundTransparency = 1,
})
local bottomLayout = create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 12),
	Parent = bottomContainer,
})

-- Top container for scrollable content
local topContainer = create("Frame", {
	Name = "TopContainer",
	Parent = detailContent,
	Size = UDim2.new(1, 0, 1, -152), -- Fill space above bottom container
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
local topLayout = create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
	Parent = topContainer,
})
create("UIPadding", {PaddingTop = UDim.new(0, 16), Parent = topContainer})


local detailIconContainer = create("Frame", {
	Name = "DetailIconContainer",
	Parent = topContainer,
	Size = UDim2.new(0, 160, 0, 160), -- Smaller size
	BackgroundColor3 = Color3.fromRGB(15, 23, 42), -- slate-900
	LayoutOrder = 1,
})
create("UICorner", {CornerRadius=UDim.new(0,16), Parent=detailIconContainer})
create("UIStroke", {Color=Color3.fromRGB(99, 102, 241), Thickness=2, Parent=detailIconContainer})

local detailIcon = create("TextLabel", {
	Name = "DetailIcon",
	Parent = detailIconContainer,
	Size = UDim2.new(1, 0, 1, 0),
	Text = "SR",
	Font = Enum.Font.GothamBlack,
	TextSize = 80, -- Smaller text
	TextColor3 = Color3.fromRGB(129, 140, 248), -- indigo-400
	BackgroundTransparency = 1,
})

local detailName = create("TextLabel", {
	Name = "DetailName",
	Parent = topContainer,
	Size = UDim2.new(1, 0, 0, 60),
	Text = "Self Revive",
	Font = Enum.Font.GothamBlack,
	TextSize = 48,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	LayoutOrder = 2,
})

local detailDesc = create("TextLabel", {
	Name = "DetailDesc",
	Parent = topContainer,
	Size = UDim2.new(1, 0, 0, 0), -- Use AutomaticSize
	AutomaticSize = Enum.AutomaticSize.Y,
	Text = "Memberi Anda kemampuan untuk hidup kembali (self-revive) saat Anda terjatuh (knocked).",
	Font = Enum.Font.Gotham,
	TextSize = 18, -- Smaller text
	TextColor3 = Color3.fromRGB(156, 163, 175), -- gray-400
	BackgroundTransparency = 1,
	TextWrapped = true,
	LayoutOrder = 3,
})


local purchaseInfo = create("Frame", {
	Name = "PurchaseInfo",
	Parent = bottomContainer,
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = Color3.fromRGB(15, 23, 42), -- slate-900
	LayoutOrder = 1,
})
create("UICorner", {CornerRadius=UDim.new(0,8), Parent=purchaseInfo})
create("UIStroke", {Color=Color3.fromRGB(51, 65, 85), Parent=purchaseInfo})
create("UIPadding", {PaddingLeft=UDim.new(0,16), PaddingRight=UDim.new(0,16), Parent=purchaseInfo})

local priceLabel = create("TextLabel", {
	Name = "PriceLabel",
	Parent = purchaseInfo,
	Size = UDim2.new(0.5, 0, 1, 0),
	Text = "2,500 ??",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(250, 204, 21), -- yellow-400
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
})

local ownedLabel = create("TextLabel", {
	Name = "OwnedLabel",
	Parent = purchaseInfo,
	Size = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	Text = "x0",
	Font = Enum.Font.GothamBold,
	TextSize = 24,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Right,
	BackgroundTransparency = 1,
})

local purchaseButton = create("TextButton", {
	Name = "PurchaseButton",
	Parent = bottomContainer,
	Size = UDim2.new(1, 0, 0, 60),
	Text = "BELI",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundColor3 = Color3.fromRGB(79, 70, 229), -- indigo-600
	LayoutOrder = 2,
})
create("UICorner", {CornerRadius = UDim.new(0,8), Parent=purchaseButton})

-- Toast Notification Container
local toastContainer = create("Frame", {
	Name = "ToastContainer",
	Parent = screenGui,
	Size = UDim2.new(0, 320, 0, 300),
	Position = UDim2.new(1, -20, 0, 20),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	ZIndex = 50,
})
create("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 12),
	Parent = toastContainer,
})


-- ==================================
-- ====== UI LOGIC ==================
-- ==================================
local boosterConfigCache = nil
local currentPlayerData = nil
local selectedBoosterId = nil

local function showToast(message, isSuccess)
	local toastId = "toast-" .. os.clock()
	local bgColor = isSuccess and Color3.fromRGB(22, 163, 74) or Color3.fromRGB(220, 38, 38)
	local icon = isSuccess and "?" or "?"

	local toast = create("Frame", {
		Name = toastId,
		Parent = toastContainer,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = bgColor,
		Position = UDim2.new(1, 400, 0, 0), -- Start off-screen
	})
	create("UICorner", {CornerRadius = UDim.new(0, 8), Parent = toast})
	create("UIStroke", {Color = Color3.fromRGB(255,255,255), Transparency = 0.8, Thickness = 1, Parent = toast})
	create("UIPadding", {PaddingLeft=UDim.new(0,16), Parent=toast})

	local toastIcon = create("TextLabel", {
		Name = "ToastIcon",
		Parent = toast,
		Size = UDim2.new(0, 30, 1, 0),
		Text = icon,
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(255,255,255),
		BackgroundTransparency = 1,
	})

	local toastMessage = create("TextLabel", {
		Name = "ToastMessage",
		Parent = toast,
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		Text = message,
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(255,255,255),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
	})

	local tweenInfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tweenIn = TweenService:Create(toast, tweenInfoIn, {Position = UDim2.new(0, 0, 0, 0)})
	tweenIn:Play()

	task.delay(3, function()
		if toast and toast.Parent then
			local tweenInfoOut = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			local tweenOut = TweenService:Create(toast, tweenInfoOut, {Position = UDim2.new(1, 400, 0, 0)})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end

local function createItemCard(boosterId, config, ownedCount)
	local card = create("TextButton", {
		Name = boosterId,
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = Color3.fromRGB(51, 65, 85), -- slate-700
		AutoButtonColor = false,
		Text = "",
	})
	local stroke = create("UIStroke", { Parent = card, Color = Color3.fromRGB(71, 85, 105), Thickness = 2 }) -- slate-600
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
	create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = card })

	local iconBg = create("Frame", {
		Name = "IconBg",
		Parent = card,
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 23, 42), -- slate-900
	})
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = iconBg })

	local icon = create("TextLabel", {
		Name = "Icon",
		Parent = iconBg,
		Size = UDim2.new(1, 0, 1, 0),
		Text = config.Icon,
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextColor3 = Color3.fromRGB(129, 140, 248), -- indigo-400
		BackgroundTransparency = 1,
	})

	local name = create("TextLabel", {
		Name = "Name",
		Parent = card,
		Size = UDim2.new(1, -120, 0.5, 0),
		Position = UDim2.new(0, 60, 0, 0),
		Text = config.Name,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
	})

	local price = create("TextLabel", {
		Name = "Price",
		Parent = card,
		Size = UDim2.new(1, -120, 0.5, 0),
		Position = UDim2.new(0, 60, 0.5, 0),
		Text = config.Price .. " ??",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(250, 204, 21), -- yellow-400
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
	})

	local owned = create("TextLabel", {
		Name = "Owned",
		Parent = card,
		Size = UDim2.new(0, 50, 1, 0),
		Position = UDim2.new(1, -50, 0, 0),
		Text = "x" .. ownedCount,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = ownedCount > 0 and Color3.fromRGB(34, 211, 238) or Color3.fromRGB(100, 116, 139), -- cyan-400 or slate-500
		BackgroundTransparency = 1,
	})

	-- Hover Logic
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(71, 85, 105) }):Play() -- slate-600
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(51, 65, 85) }):Play() -- slate-700
	end)

	return card
end

local function updateDetailsPanel(boosterId)
	selectedBoosterId = boosterId

	if not boosterId or not boosterConfigCache[boosterId] then
		detailPlaceholder.Visible = true
		detailContent.Visible = false
		return
	end

	detailPlaceholder.Visible = false
	detailContent.Visible = true

	local item = boosterConfigCache[boosterId]
	local ownedCount = (currentPlayerData and currentPlayerData.inventory and currentPlayerData.inventory[boosterId]) or 0
	local canAfford = currentPlayerData and currentPlayerData.coins >= item.Price

	detailIcon.Text = item.Icon
	detailName.Text = item.Name
	detailDesc.Text = item.Description
	priceLabel.Text = item.Price .. " ??"
	ownedLabel.Text = "x" .. ownedCount

	purchaseButton.Text = canAfford and "BELI" or "KOIN TIDAK CUKUP"
	purchaseButton.BackgroundColor3 = canAfford and Color3.fromRGB(79, 70, 229) or Color3.fromRGB(51, 65, 85)
	purchaseButton.Enabled = canAfford
end

local function populateShop()
	if not boosterConfigCache or not currentPlayerData then return end

	for _, child in ipairs(itemList:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for boosterId, config in pairs(boosterConfigCache) do
		local ownedCount = (currentPlayerData.inventory and currentPlayerData.inventory[boosterId]) or 0
		local card = createItemCard(boosterId, config, ownedCount)
		card.Parent = itemList

		card.MouseButton1Click:Connect(function()
			updateDetailsPanel(boosterId)
		end)
	end
end

local function handlePurchase()
	if not selectedBoosterId or not purchaseButton.Enabled then return end

	local itemInfo = boosterConfigCache[selectedBoosterId]
	local result = PurchaseBoosterFunction:InvokeServer(selectedBoosterId)

	if result.success then
		-- Manually update local data for immediate feedback
		currentPlayerData.coins = result.newCoins
		currentPlayerData.inventory[selectedBoosterId] = result.newAmount

		showToast("Pembelian " .. itemInfo.Name .. " berhasil!", true)

		-- Refresh the UI
		populateShop()
		updateDetailsPanel(selectedBoosterId)
	else
		showToast(result.message or "Pembelian gagal.", false)
	end
end

local isShopVisible = false
function toggleShop(visible, data)
	if isShopVisible == visible then return end
	isShopVisible = visible

	if visible then
		currentPlayerData = data
		if not currentPlayerData.inventory then
			currentPlayerData.inventory = {}
		end
		populateShop()
		updateDetailsPanel(nil)
	end

	local targetPosition = visible and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 1.5, 0)
	local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(shopWindow, tweenInfo, {Position = targetPosition})

	if visible then boosterShopContainer.Visible = true end
	tween:Play()

	if not visible then
		tween.Completed:Wait()
		boosterShopContainer.Visible = false
	end
end

-- ==================================
-- ====== EVENT CONNECTIONS =========
-- ==================================
closeShopButton.MouseButton1Click:Connect(function() toggleShop(false) end)
purchaseButton.MouseButton1Click:Connect(handlePurchase)

ToggleBoosterShopEvent.OnClientEvent:Connect(function(data)
	toggleShop(not isShopVisible, data)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and isShopVisible then
		toggleShop(false)
	end
end)


-- Add hover effects
local function addHoverEffect(button, hoverColor, defaultColor)
	button.MouseEnter:Connect(function()
		if button.Enabled then
			TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if button.Enabled then
			TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = defaultColor}):Play()
		end
	end)
end

addHoverEffect(closeShopButton, Color3.fromRGB(248, 113, 113), Color3.fromRGB(220, 38, 38)) -- red-400, red-600
addHoverEffect(purchaseButton, Color3.fromRGB(99, 102, 241), Color3.fromRGB(79, 70, 229)) -- indigo-500, indigo-600

-- ==================================
-- ======== INITIALIZATION ========
-- ==================================
local function initialize()
	boosterConfigCache = GetBoosterConfig:InvokeServer()
	print("BoosterShopUI Overhaul Loaded. Config cached.")
end

initialize()
