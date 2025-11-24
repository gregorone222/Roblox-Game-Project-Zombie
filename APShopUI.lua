-- APShopUI.lua (LocalScript)
-- Path: StarterGui/APShopUI.lua
-- Script Place: Lobby
-- Theme: Modern Slate (Dark Blue-Grey) & Amber (Gold)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULES & REMOTES
-- ============================================================================

local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

-- Config Item Spesial (Hardcoded fallback)
local SpecialItemsConfig = {
	SKILL_RESET_TOKEN = {
		Name = "Skill Reset Token",
		Description = "Token sekali pakai yang mengizinkan Anda untuk mereset semua poin skill.",
		APCost = 7500,
		Icon = "rbxassetid://11419719785"
	},
	EXCLUSIVE_TITLE_COLLECTOR = {
		Name = "Title: The Collector",
		Description = "Membuka title eksklusif 'The Collector' untuk dipamerkan.",
		APCost = 10000,
		Icon = "rbxassetid://11419713628"
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
	BG_DARK = Color3.fromRGB(15, 23, 42),    -- Slate 900
	BG_PANEL = Color3.fromRGB(30, 41, 59),   -- Slate 800
	BG_HOVER = Color3.fromRGB(51, 65, 85),   -- Slate 700
	ACCENT = Color3.fromRGB(245, 158, 11),   -- Amber 500
	ACCENT_HOVER = Color3.fromRGB(251, 191, 36), -- Amber 400
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_SUB = Color3.fromRGB(148, 163, 184), -- Slate 400
	GREEN = Color3.fromRGB(34, 197, 94),
	RED = Color3.fromRGB(239, 68, 68),
	BORDER = Color3.fromRGB(71, 85, 105)
}

local apShopUI = {}

-- UI References
local screenGui = nil
local listContainer = nil
local detailPanel = nil
local confirmModal = nil

-- State
local currentTab = "Skins"
local currentAP = 0
local selectedItem = nil
local activePreview = nil
local CurrentItemsList = {} 

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
	stroke.Color = color or COLORS.BORDER
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- Fungsi format number yang aman
local function formatNumber(n)
	local formatted = tostring(math.floor(n or 0))
	while true do  
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if k == 0 then break end
	end
	return formatted
end

-- ============================================================================
-- CORE UI FUNCTIONS (Definisi di awal agar bisa dipanggil)
-- ============================================================================

-- Update AP display
function apShopUI:UpdateAP()
	task.spawn(function()
		local success, points = pcall(function() return getAPFunc:InvokeServer() end)
		if success then
			currentAP = points
			if screenGui and screenGui:FindFirstChild("MainContainer") then
				local header = screenGui.MainContainer.Header
				header.APDisplay.Text = "AP: " .. formatNumber(points)

				-- Refresh status tombol beli jika ada item terpilih
				if selectedItem then 
					self:SelectItem(selectedItem.Id) 
				end
			end
		end
	end)
end

-- Show UI
function apShopUI:Show()
	if not screenGui then 
		self:Create() 
	end

	screenGui.Enabled = true

	-- Animasi Pop-Up
	local main = screenGui.MainContainer
	main.Size = UDim2.new(0, 950, 0, 600)
	main.BackgroundTransparency = 1

	local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 1000, 0, 650),
		BackgroundTransparency = 0
	})
	tween:Play()

	self:UpdateAP()
end

-- Hide UI
function apShopUI:Hide()
	if screenGui then
		screenGui.Enabled = false
		if activePreview then 
			ModelPreviewModule.destroy(activePreview) 
			activePreview = nil 
		end
	end
end

-- Create Item Card
function apShopUI:CreateItemCard(data)
	local btn = create("TextButton", {
		Name = data.Id,
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = COLORS.BG_PANEL,
		AutoButtonColor = false,
		Text = ""
	})
	addCorner(btn, 8)

	-- Icon Box
	local iconBox = create("Frame", {
		Size = UDim2.new(0, 54, 0, 54),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_DARK,
		Parent = btn
	})
	addCorner(iconBox, 8)

	local icon = create("ImageLabel", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = data.Icon or "",
		ScaleType = Enum.ScaleType.Fit,
		Parent = iconBox
	})

	-- Info
	local nameLabel = create("TextLabel", {
		Text = data.Name,
		Size = UDim2.new(0.6, 0, 0.4, 0),
		Position = UDim2.new(0, 72, 0.15, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn
	})

	local subLabel = create("TextLabel", {
		Text = data.SubText,
		Size = UDim2.new(0.6, 0, 0.3, 0),
		Position = UDim2.new(0, 72, 0.55, 0),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_SUB,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = btn
	})

	-- Price / Status
	local statusFrame = create("Frame", {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = btn
	})

	local priceLabel = create("TextLabel", {
		Text = formatNumber(data.Cost) .. " AP",
		Size = UDim2.new(1, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = COLORS.ACCENT,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = statusFrame
	})

	if data.Owned then
		priceLabel.Text = "DIMILIKI"
		priceLabel.TextColor3 = COLORS.GREEN
	end

	-- Selection Logic
	btn.MouseButton1Click:Connect(function()
		apShopUI:SelectItem(data.Id)
	end)

	return btn
end

-- Populate List
function apShopUI:PopulateList()
	-- Clear old items
	for _, c in ipairs(listContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local items = {}

	if currentTab == "Skins" then
		for weaponName, weaponData in pairs(WeaponModule.Weapons) do
			for skinName, skinData in pairs(weaponData.Skins) do
				if skinData.APCost and skinData.APCost > 0 then
					table.insert(items, {
						Id = weaponName .. "_" .. skinName,
						Type = "Skin",
						Name = skinName,
						SubText = weaponName .. " Skin",
						Cost = skinData.APCost,
						Icon = skinData.TextureId, 
						Weapon = weaponName,
						SkinName = skinName,
						Data = skinData, 
						Owned = false 
					})
				end
			end
		end
	else 
		for id, itemData in pairs(SpecialItemsConfig) do
			table.insert(items, {
				Id = id,
				Type = "Item",
				Name = itemData.Name,
				SubText = "Item Spesial",
				Cost = itemData.APCost,
				Icon = itemData.Icon,
				Description = itemData.Description,
				Owned = false
			})
		end
	end

	table.sort(items, function(a, b) return a.Cost < b.Cost end)
	CurrentItemsList = items 

	for _, item in ipairs(items) do
		local card = self:CreateItemCard(item)
		card.Parent = listContainer
	end
end

-- Select Item
function apShopUI:SelectItem(itemId)
	-- Reset visual selection list
	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("TextButton") then
			child.BackgroundColor3 = COLORS.BG_PANEL
		end
	end

	local placeholder = detailPanel:FindFirstChild("Placeholder")
	local content = detailPanel:FindFirstChild("Content")

	if not itemId then
		selectedItem = nil
		if activePreview then ModelPreviewModule.destroy(activePreview) activePreview = nil end
		placeholder.Visible = true
		content.Visible = false
		return
	end

	local itemData = nil
	for _, item in ipairs(CurrentItemsList or {}) do
		if item.Id == itemId then itemData = item break end
	end

	if not itemData then return end
	selectedItem = itemData

	-- Highlight
	local btn = listContainer:FindFirstChild(itemId)
	if btn then btn.BackgroundColor3 = COLORS.BG_HOVER end

	placeholder.Visible = false
	content.Visible = true

	-- Update Details
	local infoFrame = content.InfoFrame
	infoFrame.ItemName.Text = itemData.Name
	infoFrame.ItemType.Text = itemData.SubText

	if itemData.Type == "Skin" then
		infoFrame.ItemDesc.Text = string.format("Skin eksklusif untuk senjata %s. Beli menggunakan Achievement Points.", itemData.Weapon)
	else
		infoFrame.ItemDesc.Text = itemData.Description
	end

	local actionInfo = infoFrame.ActionBar
	actionInfo.CostLabel.Text = formatNumber(itemData.Cost) .. " AP"

	local buyBtn = actionInfo.BuyButton
	if itemData.Owned then
		buyBtn.Text = "DIMILIKI"
		buyBtn.BackgroundColor3 = COLORS.BG_HOVER
		buyBtn.TextColor3 = COLORS.TEXT_SUB
		buyBtn.Active = false
	elseif currentAP < itemData.Cost then
		buyBtn.Text = "AP KURANG"
		buyBtn.BackgroundColor3 = COLORS.BG_HOVER
		buyBtn.TextColor3 = COLORS.RED
		buyBtn.Active = false
	else
		buyBtn.Text = "BELI"
		buyBtn.BackgroundColor3 = COLORS.ACCENT
		buyBtn.TextColor3 = COLORS.BG_DARK
		buyBtn.Active = true
	end

	-- Preview Logic
	local previewContainer = content.PreviewContainer
	if activePreview then ModelPreviewModule.destroy(activePreview) activePreview = nil end

	if itemData.Type == "Skin" and itemData.Data then
		previewContainer.Viewport.Visible = true
		previewContainer.Image.Visible = false

		local weaponDef = WeaponModule.Weapons[itemData.Weapon]
		activePreview = ModelPreviewModule.create(previewContainer.Viewport, weaponDef, itemData.Data)
		ModelPreviewModule.startRotation(activePreview, 4)
	else
		previewContainer.Viewport.Visible = false
		previewContainer.Image.Visible = true
		previewContainer.Image.Image = itemData.Icon
	end
end

-- Purchase
function apShopUI:PerformPurchase(item)
	local result

	if item.Type == "Skin" then
		result = purchaseSkinFunc:InvokeServer(item.Weapon, item.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(item.Id)
	end

	if result.Success then
		self:SelectItem(item.Id) -- Refresh status UI
		self:PopulateList() -- Refresh list status
	else
		print("Purchase Failed:", result.Reason)
	end
	self:UpdateAP()
end

-- ============================================================================
-- MAIN CREATE FUNCTION
-- ============================================================================

function apShopUI:Create()
	if playerGui:FindFirstChild("APShopUI") then
		screenGui = playerGui.APShopUI
		if screenGui then screenGui:Destroy() end
	end

	screenGui = create("ScreenGui", {
		Name = "APShopUI",
		Parent = playerGui,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false
	})

	-- Overlay Background
	local overlay = create("Frame", {
		Name = "Overlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.4,
		Parent = screenGui
	})

	-- Main Container (Window)
	local mainContainer = create("Frame", {
		Name = "MainContainer",
		Size = UDim2.new(0, 1000, 0, 650),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	})
	addCorner(mainContainer, 16)
	addStroke(mainContainer, COLORS.BORDER, 2)

	-- 1. Header
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 70),
		BackgroundColor3 = COLORS.BG_DARK,
		BorderSizePixel = 0,
		Parent = mainContainer
	})

	create("TextLabel", {
		Name = "Title",
		Text = "TOKO ACHIEVEMENT",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		Parent = header
	})

	create("TextLabel", {
		Name = "APDisplay",
		Text = "AP: 0",
		Size = UDim2.new(0, 150, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = COLORS.ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header
	})

	local closeBtn = create("TextButton", {
		Name = "CloseButton",
		Text = "X",
		Size = UDim2.new(0, 40, 0, 40),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		BackgroundColor3 = COLORS.BG_HOVER,
		TextColor3 = COLORS.TEXT_MAIN,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		Parent = header
	})
	addCorner(closeBtn, 20)
	closeBtn.MouseButton1Click:Connect(function() apShopUI:Hide() end)

	-- 2. Body
	local body = create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 1, -70),
		Position = UDim2.new(0, 0, 0, 70),
		BackgroundTransparency = 1,
		Parent = mainContainer
	})
	local bodyPad = addPadding(body, 20)
	bodyPad.PaddingTop = UDim.new(0, 20)
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 20), Parent = body })

	-- Left Column
	local leftCol = create("Frame", { Name = "LeftColumn", Size = UDim2.new(0.35, 0, 1, 0), BackgroundColor3 = COLORS.BG_DARK, Parent = body })
	addCorner(leftCol, 8)

	local tabContainer = create("Frame", { Name = "TabContainer", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = leftCol })
	addPadding(tabContainer, 10)
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = tabContainer })

	local tabSkins = create("TextButton", { Name = "TabSkins", Text = "Skin Eksklusif", Size = UDim2.new(0.5, -5, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, BackgroundColor3 = COLORS.BG_HOVER, TextColor3 = COLORS.TEXT_SUB, Parent = tabContainer })
	addCorner(tabSkins, 6)

	local tabItems = create("TextButton", { Name = "TabItems", Text = "Item Spesial", Size = UDim2.new(0.5, -5, 1, 0), Font = Enum.Font.GothamBold, TextSize = 14, BackgroundColor3 = COLORS.BG_HOVER, TextColor3 = COLORS.TEXT_SUB, Parent = tabContainer })
	addCorner(tabItems, 6)

	listContainer = create("ScrollingFrame", {
		Name = "ListContainer",
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.BG_HOVER,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = leftCol
	})
	addPadding(listContainer, 10)
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listContainer })

	-- Right Column
	detailPanel = create("Frame", { Name = "DetailPanel", Size = UDim2.new(0.65, -20, 1, 0), BackgroundColor3 = COLORS.BG_DARK, Parent = body })
	addCorner(detailPanel, 8)
	addPadding(detailPanel, 20)

	-- Detail Content
	local detailContent = create("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = detailPanel })

	local previewContainer = create("Frame", { Name = "PreviewContainer", Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = Color3.fromRGB(10, 15, 30), Parent = detailContent })
	addCorner(previewContainer, 8)
	addStroke(previewContainer, COLORS.BG_HOVER, 1)
	create("ViewportFrame", { Name = "Viewport", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = previewContainer })
	create("ImageLabel", { Name = "Image", Size = UDim2.new(0.6, 0, 0.8, 0), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = previewContainer })

	local infoFrame = create("Frame", { Name = "InfoFrame", Size = UDim2.new(1, 0, 0.45, -10), Position = UDim2.new(0, 0, 0.55, 10), BackgroundTransparency = 1, Parent = detailContent })
	create("TextLabel", { Name = "ItemName", Text = "Name", Size = UDim2.new(1, 0, 0, 40), Font = Enum.Font.GothamBlack, TextSize = 32, TextColor3 = COLORS.TEXT_MAIN, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = infoFrame })
	create("TextLabel", { Name = "ItemType", Text = "Type", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 40), Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = COLORS.ACCENT, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = infoFrame })
	create("TextLabel", { Name = "ItemDesc", Text = "Desc", Size = UDim2.new(1, 0, 1, -120), Position = UDim2.new(0, 0, 0, 70), Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = COLORS.TEXT_SUB, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, BackgroundTransparency = 1, Parent = infoFrame })

	local actionBar = create("Frame", { Name = "ActionBar", Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 1, -60), BackgroundColor3 = COLORS.BG_PANEL, Parent = infoFrame })
	addCorner(actionBar, 8)
	local actionPad = addPadding(actionBar, 10) actionPad.PaddingLeft = UDim.new(0, 20) actionPad.PaddingRight = UDim.new(0, 10)

	create("TextLabel", { Name = "CostLabel", Text = "0 AP", Size = UDim2.new(0.5, 0, 1, 0), Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = COLORS.ACCENT, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = actionBar })
	local buyButton = create("TextButton", { Name = "BuyButton", Text = "BELI", Size = UDim2.new(0, 150, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), BackgroundColor3 = COLORS.ACCENT, TextColor3 = COLORS.BG_DARK, Font = Enum.Font.GothamBold, TextSize = 20, Parent = actionBar })
	addCorner(buyButton, 8)

	-- Placeholder
	local placeholder = create("Frame", { Name = "Placeholder", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = detailPanel })
	create("ImageLabel", { Image = "rbxassetid://10621421113", Size = UDim2.new(0, 100, 0, 100), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.4, 0), BackgroundTransparency = 1, ImageColor3 = COLORS.TEXT_SUB, Parent = placeholder })
	create("TextLabel", { Text = "Pilih item dari daftar.", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0.6, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 18, TextColor3 = COLORS.TEXT_SUB, Parent = placeholder })

	-- Tab Switching Logic
	local function updateTabs(selected)
		currentTab = selected
		if selected == "Skins" then
			tabSkins.BackgroundColor3 = COLORS.BG_PANEL; tabSkins.TextColor3 = COLORS.ACCENT; addStroke(tabSkins, COLORS.ACCENT, 2)
			tabItems.BackgroundColor3 = COLORS.BG_HOVER; tabItems.TextColor3 = COLORS.TEXT_SUB; if tabItems:FindFirstChild("UIStroke") then tabItems.UIStroke:Destroy() end
		else
			tabItems.BackgroundColor3 = COLORS.BG_PANEL; tabItems.TextColor3 = COLORS.ACCENT; addStroke(tabItems, COLORS.ACCENT, 2)
			tabSkins.BackgroundColor3 = COLORS.BG_HOVER; tabSkins.TextColor3 = COLORS.TEXT_SUB; if tabSkins:FindFirstChild("UIStroke") then tabSkins.UIStroke:Destroy() end
		end
		self:PopulateList()
		self:SelectItem(nil)
	end

	tabSkins.MouseButton1Click:Connect(function() updateTabs("Skins") end)
	tabItems.MouseButton1Click:Connect(function() updateTabs("Items") end)

	-- Confirm Modal
	confirmModal = create("Frame", { Name = "ConfirmModal", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.5, Visible = false, ZIndex = 10, Parent = screenGui })
	local modalBox = create("Frame", { Name = "Box", Size = UDim2.new(0, 400, 0, 200), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = COLORS.BG_PANEL, Parent = confirmModal })
	addCorner(modalBox, 12); addStroke(modalBox, COLORS.BORDER, 2); addPadding(modalBox, 20)

	create("TextLabel", { Text = "Konfirmasi Pembelian", Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = COLORS.TEXT_MAIN, BackgroundTransparency = 1, Parent = modalBox })
	local modalText = create("TextLabel", { Name = "Message", Text = "Beli item ini?", Size = UDim2.new(1, 0, 1, -80), Position = UDim2.new(0, 0, 0, 30), Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = COLORS.TEXT_SUB, TextWrapped = true, BackgroundTransparency = 1, Parent = modalBox })

	local btnContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 1, -40), BackgroundTransparency = 1, Parent = modalBox })
	local confirmYes = create("TextButton", { Text = "Beli", Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0.55, 0, 0, 0), BackgroundColor3 = COLORS.ACCENT, TextColor3 = COLORS.BG_DARK, Font = Enum.Font.GothamBold, TextSize = 16, Parent = btnContainer }); addCorner(confirmYes, 6)
	local confirmNo = create("TextButton", { Text = "Batal", Size = UDim2.new(0.45, 0, 1, 0), BackgroundColor3 = COLORS.BG_HOVER, TextColor3 = COLORS.TEXT_MAIN, Font = Enum.Font.GothamBold, TextSize = 16, Parent = btnContainer }); addCorner(confirmNo, 6)
	confirmNo.MouseButton1Click:Connect(function() confirmModal.Visible = false end)

	buyButton.MouseButton1Click:Connect(function()
		if not selectedItem then return end
		modalText.Text = string.format("Yakin ingin membeli '%s' seharga %s AP?", selectedItem.Name, formatNumber(selectedItem.Cost))
		confirmModal.Visible = true

		if self.ConfirmConn then self.ConfirmConn:Disconnect() end
		self.ConfirmConn = confirmYes.MouseButton1Click:Connect(function()
			confirmModal.Visible = false
			self:PerformPurchase(selectedItem)
		end)
	end)

	-- Init
	updateTabs("Skins")
	self:UpdateAP()
end

-- ============================================================================
-- EVENT LISTENERS & INITIALIZATION
-- ============================================================================

apChangedEvent.OnClientEvent:Connect(function(newAP)
	currentAP = newAP
	if screenGui and screenGui.Enabled then
		screenGui.MainContainer.Header.APDisplay.Text = "AP: " .. formatNumber(newAP)
		if selectedItem then apShopUI:SelectItem(selectedItem.Id) end
	end
end)

-- Initial creation
apShopUI:Create()

-- Connect ProximityPrompt (RELIABLE METHOD)
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeredBy)
	if triggeredBy ~= player then return end

	-- Check if this is the AP Shop prompt
	-- We assume the prompt is named "ProximityPrompt" inside a part named "APShop"
	if prompt.Parent and prompt.Parent.Name == "APShop" then
		print("AP Shop Prompt Triggered")
		apShopUI:Show()
	end
end)

return apShopUI