-- PerkShopUI.lua (LocalScript)
-- Path: StarterGui/PerkShopUI.lua
-- Script Place: ACT 1: Village
-- Design: Modern Slate & Amber (Prototype Style) - No Images/AssetIDs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- CONFIGURATION & THEME
-- ============================================================================

local COLORS = {
	BG_ROOT = Color3.fromRGB(15, 23, 42),     -- Slate 950
	BG_SIDEBAR = Color3.fromRGB(10, 15, 25),  -- Darker Slate
	BG_CARD = Color3.fromRGB(30, 41, 59),     -- Slate 800
	BG_HOVER = Color3.fromRGB(51, 65, 85),    -- Slate 700
	ACCENT = Color3.fromRGB(245, 158, 11),    -- Amber 500
	ACCENT_DIM = Color3.fromRGB(180, 83, 9),  -- Amber 700
	TEXT_MAIN = Color3.fromRGB(248, 250, 252),-- Slate 50
	TEXT_DIM = Color3.fromRGB(148, 163, 184), -- Slate 400
	SUCCESS = Color3.fromRGB(34, 197, 94),    -- Green 500
	LOCKED = Color3.fromRGB(100, 116, 139),   -- Slate 500
	RED = Color3.fromRGB(239, 68, 68)         -- Red 500
}

local FONTS = {
	Display = Enum.Font.GothamBlack, -- Using GothamBlack to simulate 'Teko'/'Black Ops' feel
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code
}

-- Visual Mapping for Perks (Updated Names & Colors to match Project)
local PERK_VISUALS = {
	HPPlus = { Icon = "✚", Color = Color3.fromRGB(239, 68, 68), Sub = "Juggernaut Vitality" },
	StaminaPlus = { Icon = "⚡", Color = Color3.fromRGB(234, 179, 8), Sub = "Adrenaline Rush" },
	ReloadPlus = { Icon = "↻", Color = Color3.fromRGB(59, 130, 246), Sub = "Speed Loader" },
	RevivePlus = { Icon = "🤝", Color = Color3.fromRGB(6, 182, 212), Sub = "Quick Revive" },
	RateBoost = { Icon = "⚔", Color = Color3.fromRGB(249, 115, 22), Sub = "Rapid Fire" },
	Medic = { Icon = "⚕", Color = Color3.fromRGB(34, 197, 94), Sub = "Field Medic" },
	ExplosiveRounds = { Icon = "💥", Color = Color3.fromRGB(168, 85, 247), Sub = "Explosive Rounds" },
	Default = { Icon = "★", Color = COLORS.ACCENT, Sub = "Unknown Perk" }
}

-- ============================================================================
-- SERVICES & REMOTES
-- ============================================================================

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local openEv = RemoteEvents:WaitForChild("OpenPerkShop")
local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")
local requestOpenEvent = RemoteEvents:WaitForChild("RequestOpenPerkShop")
-- local closeShopEvent = RemoteEvents:WaitForChild("ClosePerkShop") -- Optional

local purchaseRF = RemoteFunctions:WaitForChild("PurchasePerk")

local perksPart = workspace:WaitForChild("Perks")
local perksPrompt = perksPart:WaitForChild("Attachment"):WaitForChild("PerksPrompt")

-- ============================================================================
-- UI STATE
-- ============================================================================

local shopData = {
	perks = {}, -- {ID = {Cost, Desc, ...}}
	owned = {}, -- List of owned perk IDs
	hasDiscount = false,
	selectedID = nil
}

local ui = {} -- Holds UI references

-- ============================================================================
-- UI CREATION FUNCTIONS
-- ============================================================================

local function create(className, properties, children)
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		inst[k] = v
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function addPadding(parent, px)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
	return p
end

local function createShopUI()
	-- Cleanup old UI
	if playerGui:FindFirstChild("PerkShopUI") then
		playerGui.PerkShopUI:Destroy()
	end

	local screenGui = create("ScreenGui", {
		Name = "PerkShopUI",
		Parent = playerGui,
		IgnoreGuiInset = true,
		Enabled = false,
		ResetOnSpawn = false
	})
	ui.ScreenGui = screenGui

	-- [REMOVED] Background Overlay (Frame gelap dihapus sesuai permintaan)

	-- 2. Main Container
	local mainContainer = create("Frame", {
		Name = "MainContainer",
		Size = UDim2.new(0, 900, 0, 600),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	})
	addCorner(mainContainer, 16)
	addStroke(mainContainer, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.8

	-- 3. Layout: Sidebar (Left) & Detail (Right)
	local layoutContainer = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = mainContainer
	})
	local layout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = layoutContainer
	})

	-- === LEFT SIDEBAR ===
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 320, 1, 0),
		BackgroundColor3 = COLORS.BG_SIDEBAR,
		BorderSizePixel = 0,
		Parent = layoutContainer,
		LayoutOrder = 1
	})
	create("Frame", { -- Right Border
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = COLORS.BG_HOVER,
		BorderSizePixel = 0,
		Parent = sidebar
	})

	-- Sidebar Header
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	addPadding(header, 20)

	-- Title
	local titleLbl = create("TextLabel", {
		Text = "PERK STATION",
		Font = FONTS.Display,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header
	})
	-- Accent Line (Left Border simulation)
	local accentLine = create("Frame", {
		Size = UDim2.new(0, 4, 1, 0),
		Position = UDim2.new(0, -10, 0, 0),
		BackgroundColor3 = COLORS.ACCENT,
		BorderSizePixel = 0,
		Parent = titleLbl
	})

	local subTitle = create("TextLabel", {
		Text = "Enhance Biological Capabilities",
		Font = FONTS.Body,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 32),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header
	})

	-- Sidebar List Container
	local listScroll = create("ScrollingFrame", {
		Name = "ListScroll",
		Size = UDim2.new(1, 0, 1, -80),
		Position = UDim2.new(0, 0, 0, 80),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.BG_HOVER,
		Parent = sidebar
	})
	addPadding(listScroll, 15)
	local listLayout = create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listScroll
	})
	ui.ListScroll = listScroll

	-- === RIGHT DETAIL PANEL ===
	local detailPanel = create("Frame", {
		Name = "DetailPanel",
		Size = UDim2.new(1, -320, 1, 0),
		BackgroundColor3 = COLORS.BG_ROOT, -- Transparent or same as root
		BackgroundTransparency = 1,
		Parent = layoutContainer,
		LayoutOrder = 2
	})

	-- Background Pattern (Radial Gradient simulation using ImageLabel)
	local bgPattern = create("ImageLabel", {
		Size = UDim2.new(1.5, 0, 1.5, 0),
		Position = UDim2.new(-0.2, 0, -0.2, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://146197114", -- Standard Roblox radial gradient
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ImageTransparency = 0.97,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100,100,100,100),
		Parent = detailPanel
	})

	-- [VISUAL BP DI KANAN ATAS SUDAH DIHAPUS]

	-- Detail Content (Icon, Title, Desc)
	local previewArea = create("Frame", {
		Size = UDim2.new(1, 0, 0.6, 0),
		Position = UDim2.new(0, 0, 0.1, 0),
		BackgroundTransparency = 1,
		Parent = detailPanel
	})

	-- Large Icon Circle
	local circleSize = 200
	local largeIconContainer = create("Frame", {
		Name = "IconContainer",
		Size = UDim2.new(0, circleSize, 0, circleSize),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		BackgroundColor3 = COLORS.BG_HOVER,
		BackgroundTransparency = 0.8,
		Parent = previewArea
	})
	addCorner(largeIconContainer, circleSize/2)
	ui.DetailIconStroke = addStroke(largeIconContainer, COLORS.ACCENT, 1) -- Dynamic Color

	ui.DetailIcon = create("TextLabel", {
		Text = "★",
		Font = FONTS.Display,
		TextSize = 100,
		TextColor3 = COLORS.ACCENT, -- Dynamic
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = largeIconContainer
	})

	-- Title & Desc
	ui.DetailTitle = create("TextLabel", {
		Text = "SELECT A PERK",
		Font = FONTS.Display,
		TextSize = 48,
		TextColor3 = COLORS.TEXT_MAIN, -- Dynamic
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0.7, 0),
		BackgroundTransparency = 1,
		Parent = previewArea
	})

	ui.DetailDesc = create("TextLabel", {
		Text = "Choose a perk from the left to view details.",
		Font = FONTS.Body,
		TextSize = 18,
		TextColor3 = COLORS.TEXT_DIM,
		Size = UDim2.new(0.8, 0, 0, 60),
		Position = UDim2.new(0.1, 0, 0.85, 0),
		BackgroundTransparency = 1,
		TextWrapped = true,
		Parent = previewArea
	})

	-- Action Bar (Bottom)
	local actionBar = create("Frame", {
		Size = UDim2.new(1, 0, 0, 100),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.8,
		Parent = detailPanel
	})
	create("Frame", { -- Top Border
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = COLORS.BG_HOVER,
		BorderSizePixel = 0,
		Parent = actionBar
	})
	addPadding(actionBar, 30)

	-- Cost Display
	local costContainer = create("Frame", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = actionBar
	})
	create("TextLabel", {
		Text = "UPGRADE COST",
		Font = FONTS.Mono,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = costContainer
	})
	ui.DetailCost = create("TextLabel", {
		Text = "0 BP",
		Font = FONTS.Display,
		TextSize = 36,
		TextColor3 = COLORS.ACCENT,
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = costContainer
	})

	-- Buy Button
	ui.BuyButton = create("TextButton", {
		Text = "PURCHASE",
		Font = FONTS.Display,
		TextSize = 24,
		TextColor3 = Color3.new(0,0,0),
		BackgroundColor3 = COLORS.ACCENT, -- Dynamic
		Size = UDim2.new(0, 200, 1, -10), -- height - padding
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Parent = actionBar
	})
	addCorner(ui.BuyButton, 8)

	-- Close Button (Top Right of Main Container)
	local closeBtn = create("TextButton", {
		Text = "✕",
		Font = FONTS.Display,
		TextSize = 20,
		TextColor3 = COLORS.TEXT_DIM,
		BackgroundColor3 = COLORS.BG_HOVER,
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -50, 0, 10),
		Parent = mainContainer
	})
	addCorner(closeBtn, 8)

	closeBtn.MouseButton1Click:Connect(function()
		closeUI()
	end)

end

-- ============================================================================
-- LOGIC FUNCTIONS
-- ============================================================================

local function getVisualData(perkID)
	return PERK_VISUALS[perkID] or PERK_VISUALS.Default
end

local function updateDetailPanel(perkID)
	if not perkID then return end

	local data = shopData.perks[perkID]
	if not data then return end

	local visual = getVisualData(perkID)
	local isOwned = table.find(shopData.owned, perkID) ~= nil

	-- Update Visuals
	ui.DetailIcon.Text = visual.Icon
	ui.DetailIcon.TextColor3 = visual.Color
	ui.DetailIconStroke.Color = visual.Color

	ui.DetailTitle.Text = visual.Sub -- Use updated Name from PERK_VISUALS
	ui.DetailTitle.TextColor3 = visual.Color

	ui.DetailDesc.Text = data.Description or "No description."

	-- Update Cost & Button
	if isOwned then
		ui.DetailCost.Text = "OWNED"
		ui.DetailCost.TextColor3 = COLORS.SUCCESS

		ui.BuyButton.Text = "EQUIPPED"
		ui.BuyButton.BackgroundColor3 = COLORS.BG_HOVER
		ui.BuyButton.TextColor3 = COLORS.TEXT_DIM
		ui.BuyButton.Active = false
		ui.BuyButton.AutoButtonColor = false
	else
		local cost = data.Cost or 0
		if shopData.hasDiscount then cost = math.floor(cost / 2) end

		ui.DetailCost.Text = tostring(cost) .. " BP"
		ui.DetailCost.TextColor3 = COLORS.ACCENT

		ui.BuyButton.Text = "PURCHASE"
		ui.BuyButton.BackgroundColor3 = visual.Color
		ui.BuyButton.TextColor3 = Color3.new(0,0,0) -- Black text on colored button
		ui.BuyButton.Active = true
		ui.BuyButton.AutoButtonColor = true
	end

	-- Float Animation for Icon
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local floatTween = TweenService:Create(ui.DetailIcon.Parent, tweenInfo, { Position = UDim2.new(0.5, 0, 0.38, 0) })
	floatTween:Play()
end

local function renderPerkList()
	-- Clear list
	for _, child in ipairs(ui.ListScroll:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
	end

	local sortedPerks = {}
	for id, info in pairs(shopData.perks) do
		table.insert(sortedPerks, {ID = id, Info = info})
	end
	-- Sort logic: Owned first, then by Cost
	table.sort(sortedPerks, function(a, b)
		return a.Info.Cost < b.Info.Cost
	end)

	-- Track unique perks to avoid duplicates
	local addedPerks = {}

	for _, item in ipairs(sortedPerks) do
		local id = item.ID

		-- Cek duplikasi
		if not addedPerks[id] then
			addedPerks[id] = true

			local info = item.Info
			local visual = getVisualData(id)
			local isOwned = table.find(shopData.owned, id) ~= nil
			local isSelected = (shopData.selectedID == id)

			-- Perk Card Item
			local card = create("TextButton", { -- Use TextButton for click
				Name = id,
				Size = UDim2.new(1, 0, 0, 70),
				BackgroundColor3 = isSelected and Color3.fromRGB(255,255,255) or COLORS.BG_CARD,
				BackgroundTransparency = isSelected and 0.95 or 0,
				AutoButtonColor = false,
				Text = "",
				Parent = ui.ListScroll
			})
			addCorner(card, 12)
			if isSelected then
				addStroke(card, visual.Color, 2)
			else
				addStroke(card, COLORS.BG_HOVER, 1)
			end

			-- Icon Box
			local iconBox = create("Frame", {
				Size = UDim2.new(0, 48, 0, 48),
				Position = UDim2.new(0, 12, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.new(0,0,0),
				BackgroundTransparency = 0.5,
				Parent = card
			})
			addCorner(iconBox, 8)
			addStroke(iconBox, COLORS.BG_HOVER, 1)

			local iconLbl = create("TextLabel", {
				Text = visual.Icon,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = visual.Color,
				Font = Enum.Font.Gotham,
				TextSize = 24,
				Parent = iconBox
			})

			-- Text Content
			local contentFrame = create("Frame", {
				Size = UDim2.new(1, -160, 1, 0),
				Position = UDim2.new(0, 72, 0, 0),
				BackgroundTransparency = 1,
				Parent = card
			})

			local nameLbl = create("TextLabel", {
				Text = visual.Sub, -- Using updated Name
				Font = FONTS.Display,
				TextSize = 14,
				TextColor3 = COLORS.TEXT_MAIN,
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.new(0, 0, 0.15, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Parent = contentFrame
			})

			local costVal = info.Cost
			if shopData.hasDiscount then costVal = math.floor(costVal/2) end

			local costLbl = create("TextLabel", {
				Text = isOwned and "Active" or (tostring(costVal) .. " BP"),
				Font = FONTS.Mono,
				TextSize = 12,
				TextColor3 = isOwned and COLORS.SUCCESS or COLORS.TEXT_DIM,
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.new(0, 0, 0.5, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Parent = contentFrame
			})

			-- Status Badge (Right)
			local statusFrame = create("Frame", {
				Size = UDim2.new(0, 80, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = isOwned and Color3.fromRGB(22, 163, 74) or COLORS.BG_HOVER,
				BackgroundTransparency = isOwned and 0.8 or 0.5,
				Parent = card
			})
			addCorner(statusFrame, 4)

			local statusText = create("TextLabel", {
				Text = isOwned and "OWNED" or "LOCKED",
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = isOwned and COLORS.SUCCESS or COLORS.LOCKED,
				Font = FONTS.Display,
				TextSize = 10,
				Parent = statusFrame
			})

			-- Click Event
			card.MouseButton1Click:Connect(function()
				shopData.selectedID = id
				renderPerkList() -- Re-render to update selection visuals
				updateDetailPanel(id)
			end)
		end
	end
end

-- ============================================================================
-- LOGIC & INTERACTION
-- ============================================================================

local function openShop(perks, hasDiscount)
	-- Initialize UI
	if not ui.ScreenGui then createShopUI() end

	ui.ScreenGui.Enabled = true
	shopData.perks = perks
	shopData.hasDiscount = hasDiscount
	shopData.owned = {} -- Reset owned list, will be updated via events usually

	-- Select first perk
	local firstID = next(perks)
	shopData.selectedID = firstID

	renderPerkList()
	updateDetailPanel(firstID)

	-- Animation Entry
	ui.ScreenGui.MainContainer.Size = UDim2.new(0, 850, 0, 550)
	ui.ScreenGui.MainContainer.BackgroundTransparency = 1
	local tween = TweenService:Create(ui.ScreenGui.MainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 900, 0, 600),
		BackgroundTransparency = 0
	})
	tween:Play()
end

function closeUI()
	if not ui.ScreenGui then return end

	local tween = TweenService:Create(ui.ScreenGui.MainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 850, 0, 550),
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		ui.ScreenGui.Enabled = false
	end)
end

-- Purchase Logic
local function performPurchase()
	if not shopData.selectedID then return end

	local btn = ui.BuyButton
	local originalText = btn.Text
	local originalColor = btn.BackgroundColor3

	btn.Text = "..."
	btn.Interactable = false

	local success, result = pcall(function()
		return purchaseRF:InvokeServer(shopData.selectedID)
	end)

	if success and result and result.Success then
		btn.Text = "SUCCESS"
		btn.BackgroundColor3 = COLORS.SUCCESS

		-- Optimistic Update
		table.insert(shopData.owned, shopData.selectedID)
		renderPerkList()
		updateDetailPanel(shopData.selectedID)

	else
		btn.Text = result.Message or "FAILED"
		btn.BackgroundColor3 = COLORS.RED
	end

	task.wait(1)
	btn.Interactable = true
	-- UI updates from updateDetailPanel will reset text/color if still selected
	updateDetailPanel(shopData.selectedID)
end

-- ============================================================================
-- EVENT BINDINGS
-- ============================================================================

-- Initial Create
createShopUI()

-- Connect Remotes
openEv.OnClientEvent:Connect(openShop)

perkUpdateEv.OnClientEvent:Connect(function(ownedPerks)
	-- ownedPerks is list of strings
	shopData.owned = ownedPerks or {}
	if ui.ScreenGui and ui.ScreenGui.Enabled then
		renderPerkList()
		updateDetailPanel(shopData.selectedID)
	end
end)

-- Button Binds
ui.BuyButton.MouseButton1Click:Connect(performPurchase)

-- Proximity Prompt (Fallback if not handled by server script)
perksPrompt.Triggered:Connect(function()
	requestOpenEvent:FireServer()
end)

-- Distance Check Close
RunService.Stepped:Connect(function()
	if ui.ScreenGui.Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local dist = (player.Character.HumanoidRootPart.Position - perksPart.Position).Magnitude
		if dist > 15 then
			closeUI()
		end
	end
end)

print("PerkShopUI (Modern Prototype Style) Loaded.")
