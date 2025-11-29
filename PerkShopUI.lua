-- PerkShopUI.lua (LocalScript)
-- Path: PerkShopUI.lua (Repository Root -> StarterGui in-game)
-- Script Place: ACT 1: Village
-- Theme: Modern Slate & Amber (Matching Prototype)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local ProximityUIHandler = require(ReplicatedStorage.ModuleScript:WaitForChild("ProximityUIHandler"))

local openEv = RemoteEvents:WaitForChild("OpenPerkShop")
local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")
local requestOpenEvent = RemoteEvents:WaitForChild("RequestOpenPerkShop")
local closeShopEvent = RemoteEvents:WaitForChild("ClosePerkShop")
local pointsUpdateEv = RemoteEvents:WaitForChild("PointsUpdate")

local purchaseRF = RemoteFunctions:WaitForChild("PurchasePerk")

local perksPart = workspace:WaitForChild("Perks", 10) -- Wait for map to load
local perksPrompt = perksPart and perksPart:WaitForChild("Attachment", 5) and perksPart.Attachment:WaitForChild("PerksPrompt", 5)

local isMobile = UserInputService.TouchEnabled

-- State for CoreGui
local originalCoreGuiStates = {}
local hasStoredCoreGuiStates = false

-- State for UI
local currentPerksConfig = {}
local hasActiveDiscount = false
local selectedPerkIndex = 0
local perkList = {} -- Array of {Key=..., Data=...}
local ownedPerksCache = {}
local currentPlayerPoints = 0

-- UI Constants
local COLORS = {
	BG_DARK = Color3.fromRGB(15, 23, 42),    -- Slate 900
	BG_PANEL = Color3.fromRGB(30, 41, 59),   -- Slate 800
	BG_HOVER = Color3.fromRGB(51, 65, 85),   -- Slate 700
	ACCENT = Color3.fromRGB(245, 158, 11),   -- Amber 500
	TEXT_MAIN = Color3.fromRGB(248, 250, 252),
	TEXT_DIM = Color3.fromRGB(100, 116, 139),
	GREEN = Color3.fromRGB(74, 222, 128),
	RED = Color3.fromRGB(239, 68, 68),
	YELLOW = Color3.fromRGB(251, 191, 36),
	LOCKED = Color3.fromRGB(148, 163, 184)
}

-- Perk Metadata (Client-Side Override for Visuals)
local PERK_VISUALS = {
	HPPlus = { Icon = "❤️", Color = Color3.fromRGB(239, 68, 68), Name = "Juggernaut" },
	StaminaPlus = { Icon = "⚡", Color = Color3.fromRGB(234, 179, 8), Name = "Adrenaline" },
	ReloadPlus = { Icon = "🔄", Color = Color3.fromRGB(59, 130, 246), Name = "Speed Loader" },
	RevivePlus = { Icon = "🚑", Color = Color3.fromRGB(6, 182, 212), Name = "Quick Revive" },
	RateBoost = { Icon = "🔥", Color = Color3.fromRGB(249, 115, 22), Name = "Rapid Fire" },
	Medic = { Icon = "💊", Color = Color3.fromRGB(34, 197, 94), Name = "Field Medic" },
	ExplosiveRounds = { Icon = "💣", Color = Color3.fromRGB(168, 85, 247), Name = "Explosive" },
}

-- UI Objects
local screenGui
local mainContainer
local listContainer
local detailPanel

-- Helper Functions
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
	stroke.Parent = parent
	return stroke
end

local function formatNumber(n)
	return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function hideCoreGuiOnMobile()
	if not isMobile then return end
	if not hasStoredCoreGuiStates then
		originalCoreGuiStates.Backpack = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
		originalCoreGuiStates.Health = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health)
		originalCoreGuiStates.PlayerList = game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		hasStoredCoreGuiStates = true
	end
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end

local function restoreCoreGuiOnMobile()
	if not isMobile or not hasStoredCoreGuiStates then return end
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, originalCoreGuiStates.Backpack)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, originalCoreGuiStates.Health)
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, originalCoreGuiStates.PlayerList)
end

-- Forward declarations
local closeShop, updateDetailPanel, selectPerk, buildList, attemptPurchase, updateListStatus

-- UI Construction
local function createUI()
	if playerGui:FindFirstChild("PerkShopUI") then
		playerGui.PerkShopUI:Destroy()
	end

	screenGui = create("ScreenGui", {
		Name = "PerkShopUI",
		Parent = playerGui,
		IgnoreGuiInset = false,
		Enabled = false,
		ResetOnSpawn = false
	})

	-- Main Container
	mainContainer = create("Frame", {
		Name = "MainContainer",
		Size = UDim2.new(0, 1000, 0, 650),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_DARK,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	})
	addCorner(mainContainer, 24)
	addStroke(mainContainer, Color3.new(1, 1, 1), 1).Transparency = 0.9

	if isMobile then
		mainContainer.Size = UDim2.new(0.95, 0, 0.9, 0)
	end

	-- Layout: Sidebar (Left) + Detail (Right)
	local contentLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = mainContainer
	})

	-- Sidebar
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0.35, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = mainContainer
	})
	local sideStroke = create("Frame", { -- Right border
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.95,
		Parent = sidebar
	})

	-- Header inside Sidebar
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 80),
		BackgroundTransparency = 1,
		Parent = sidebar
	})
	addPadding(header, 24)

	local titleLabel = create("TextLabel", {
		Text = "PERK STATION",
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = header
	})

	create("Frame", { -- Accent Line
		Size = UDim2.new(0, 4, 0, 24),
		Position = UDim2.new(0, -12, 0, 3),
		BackgroundColor3 = COLORS.ACCENT,
		Parent = titleLabel
	})

	create("TextLabel", {
		Text = "Enhance Your Biological Capabilities",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 30),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = header
	})

	-- Perk List Container
	listContainer = create("ScrollingFrame", {
		Name = "PerkList",
		Size = UDim2.new(1, 0, 1, -80),
		Position = UDim2.new(0, 0, 0, 80),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollBarImageTransparency = 0.9,
		Parent = sidebar
	})
	addPadding(listContainer, 16)
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = listContainer
	})

	-- Detail Panel (Right)
	detailPanel = create("Frame", {
		Name = "DetailPanel",
		LayoutOrder = 2,
		Size = UDim2.new(0.65, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = mainContainer
	})

	local detailGradient = create("UIGradient", {
		Color = ColorSequence.new(COLORS.BG_PANEL),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 0)
		}),
		Rotation = -45,
		Parent = detailPanel
	})


	-- Close Button
	local closeButton = create("TextButton", {
		Text = "✕",
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(1, -24, 0, 24),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.TEXT_DIM,
		TextSize = 24,
		Font = Enum.Font.GothamBold,
		Parent = detailPanel
	})
	closeButton.MouseButton1Click:Connect(function()
		closeShop()
	end)

	-- Preview Area
	local previewArea = create("Frame", {
		Name = "PreviewArea",
		Size = UDim2.new(1, 0, 0.7, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = detailPanel
	})

	local bigIconContainer = create("Frame", {
		Name = "BigIconContainer",
		Size = UDim2.new(0, 200, 0, 200),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.45, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, -- Removed background
		Parent = previewArea
	})
	-- Removed circle (addCorner)

	-- Glow Effect
	local glow = create("ImageLabel", {
		Name = "Glow",
		Image = "rbxassetid://130424513",
		ImageColor3 = COLORS.ACCENT,
		ImageTransparency = 0.5,
		Size = UDim2.new(1.5, 0, 1.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Parent = bigIconContainer
	})

	create("TextLabel", {
		Name = "BigIcon",
		Text = "❤️",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextSize = 100,
		Font = Enum.Font.Gotham,
		ZIndex = 2,
		Parent = bigIconContainer
	})

	local tInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(bigIconContainer, tInfo, {Position = UDim2.new(0.5, 0, 0.42, 0)}):Play()

	create("TextLabel", {
		Name = "DetailTitle",
		Text = "JUGGERNAUT",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 0.65, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 48,
		TextColor3 = COLORS.TEXT_MAIN,
		Parent = previewArea
	})

	create("TextLabel", {
		Name = "DetailDesc",
		Text = "Increases Max Health by 30%.",
		Size = UDim2.new(0.8, 0, 0, 60),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.75, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 18,
		TextColor3 = COLORS.TEXT_DIM,
		TextWrapped = true,
		Parent = previewArea
	})

	-- Action Bar
	local actionBar = create("Frame", {
		Name = "ActionBar",
		Size = UDim2.new(1, 0, 0.25, 0),
		Position = UDim2.new(0, 0, 0.75, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Parent = detailPanel
	})
	addPadding(actionBar, 32)
	addStroke(actionBar, Color3.new(1, 1, 1), 1).Transparency = 0.95

	local costDisplay = create("Frame", {
		Name = "CostDisplay",
		Size = UDim2.new(0.4, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = actionBar
	})

	create("TextLabel", {
		Text = "UPGRADE COST",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = COLORS.TEXT_DIM,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = costDisplay
	})

	create("TextLabel", {
		Name = "CostValue",
		Text = "4,000 BP",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 36,
		TextColor3 = COLORS.YELLOW,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = costDisplay
	})

	local buyButton = create("TextButton", {
		Name = "BuyButton",
		Text = "PURCHASE",
		Size = UDim2.new(0, 220, 0, 60),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = COLORS.ACCENT,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		TextColor3 = COLORS.BG_DARK,
		Parent = actionBar
	})
	addCorner(buyButton, 12)

	buyButton.MouseEnter:Connect(function()
		if buyButton.Active then
			TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.TEXT_MAIN}):Play()
		end
	end)
	buyButton.MouseLeave:Connect(function()
		if buyButton.Active then
			local color = COLORS.ACCENT
			if perkList[selectedPerkIndex] then
				local key = perkList[selectedPerkIndex].Key
				local vis = PERK_VISUALS[key]
				if vis then color = vis.Color end
			end
			TweenService:Create(buyButton, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
		end
	end)

	buyButton.MouseButton1Click:Connect(function() attemptPurchase() end)
end

function closeShop()
	if screenGui then
		screenGui.Enabled = false
	end
	restoreCoreGuiOnMobile()
	closeShopEvent:FireServer()

	-- Note: ProximityUIHandler handles state internally for PerkShop 
	-- because PerkShop logic is server-driven (RequestOpen -> OpenPerkShop).
	-- We don't need to sync state here because the PromptTriggered 
	-- logic was replaced by ProximityUIHandler which calls RequestOpen.
end

function updateDetailPanel(index)
	if not index or not perkList[index] then return end
	local item = perkList[index]
	local key = item.Key
	local config = item.Data
	local vis = PERK_VISUALS[key] or { Icon = "?", Color = COLORS.TEXT_MAIN, Name = key }

	local previewArea = detailPanel.PreviewArea
	local actionBar = detailPanel.ActionBar

	previewArea.DetailTitle.Text = vis.Name
	previewArea.DetailTitle.TextColor3 = vis.Color
	previewArea.DetailDesc.Text = config.Description or "No description."
	previewArea.BigIconContainer.BigIcon.Text = vis.Icon
	previewArea.BigIconContainer.BigIcon.TextColor3 = vis.Color

	-- Update Glow Color
	if previewArea.BigIconContainer:FindFirstChild("Glow") then
		previewArea.BigIconContainer.Glow.ImageColor3 = vis.Color
	end

	local cost = config.Cost or 0
	if hasActiveDiscount then cost = math.floor(cost / 2) end

	local costLabel = actionBar.CostDisplay.CostValue
	local buyButton = actionBar.BuyButton

	costLabel.Text = formatNumber(cost) .. " BP"
	costLabel.TextColor3 = COLORS.YELLOW

	local isOwned = false
	if table.find(ownedPerksCache, key) then
		isOwned = true
	end

	if isOwned then
		buyButton.Text = "EQUIPPED"
		buyButton.BackgroundColor3 = COLORS.BG_PANEL
		buyButton.TextColor3 = COLORS.TEXT_DIM
		buyButton.Active = false
		costLabel.Text = "OWNED"
		costLabel.TextColor3 = COLORS.GREEN
	else
		buyButton.Text = "PURCHASE"
		buyButton.BackgroundColor3 = vis.Color
		buyButton.TextColor3 = COLORS.BG_DARK
		buyButton.Active = true
	end
end

function selectPerk(index)
	selectedPerkIndex = index
	for i, item in ipairs(perkList) do
		local btn = item.Button
		if i == index then
			btn.BackgroundColor3 = Color3.new(1, 1, 1)
			btn.BackgroundTransparency = 0.9
			if not btn:FindFirstChild("ActiveBar") then
				local bar = Instance.new("Frame")
				bar.Name = "ActiveBar"
				bar.Size = UDim2.new(0, 4, 1, 0)
				bar.BackgroundColor3 = PERK_VISUALS[item.Key] and PERK_VISUALS[item.Key].Color or COLORS.ACCENT
				bar.Parent = btn
			end
		else
			btn.BackgroundColor3 = Color3.new(1, 1, 1)
			btn.BackgroundTransparency = 0.97
			if btn:FindFirstChild("ActiveBar") then btn.ActiveBar:Destroy() end
		end
	end
	updateDetailPanel(index)
end

function buildList()
	for _, c in ipairs(listContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	perkList = {}

	for key, data in pairs(currentPerksConfig) do
		table.insert(perkList, {Key = key, Data = data})
	end

	table.sort(perkList, function(a,b) return (a.Data.Cost or 0) < (b.Data.Cost or 0) end)

	for i, item in ipairs(perkList) do
		local key = item.Key
		local data = item.Data
		local vis = PERK_VISUALS[key] or { Icon = "?", Color = COLORS.TEXT_MAIN, Name = key }
		local cost = data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end

		local btn = create("TextButton", {
			Name = key,
			Size = UDim2.new(1, 0, 0, 72),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.97,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = i, -- Ensure explicit order
			Parent = listContainer
		})
		addCorner(btn, 12)

		local iconContainer = create("Frame", {
			Size = UDim2.new(0, 48, 0, 48),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			Parent = btn
		})
		addCorner(iconContainer, 8)
		addStroke(iconContainer, Color3.new(1, 1, 1), 1).Transparency = 0.9

		create("TextLabel", {
			Text = vis.Icon,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			TextSize = 24,
			TextColor3 = vis.Color,
			Parent = iconContainer
		})

		local infoCol = create("Frame", {
			Size = UDim2.new(1, -70, 1, 0),
			Position = UDim2.new(0, 72, 0, 0),
			BackgroundTransparency = 1,
			Parent = btn
		})

		create("TextLabel", {
			Text = vis.Name,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0.25, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = COLORS.TEXT_MAIN,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = infoCol
		})

		local priceLabel = create("TextLabel", {
			Name = "PriceLabel",
			Text = formatNumber(cost) .. " BP",
			Size = UDim2.new(1, 0, 0, 16),
			Position = UDim2.new(0, 0, 0.55, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLORS.TEXT_DIM,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = infoCol
		})

		-- STATUS LABEL (Right Side)
		local statusLabel = create("Frame", {
			Name = "StatusLabel",
			Size = UDim2.new(0, 100, 0, 24),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			BackgroundColor3 = COLORS.BG_DARK,
			Parent = btn
		})
		addCorner(statusLabel, 6)

		local statusIcon = create("ImageLabel", {
			Name = "StatusIcon",
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = "",
			Parent = statusLabel
		})

		create("TextLabel", {
			Name = "Text",
			Text = "...",
			Size = UDim2.new(1, -26, 1, 0),
			Position = UDim2.new(0, 26, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = COLORS.TEXT_MAIN,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = statusLabel
		})

		btn.MouseButton1Click:Connect(function()
			selectPerk(i)
		end)

		item.Button = btn
		item.PriceLabel = priceLabel
		item.StatusFrame = statusLabel
	end

	updateListStatus()
end

function updateListStatus()
	for _, item in ipairs(perkList) do
		local key = item.Key
		local cost = item.Data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end

		local isOwned = false
		if table.find(ownedPerksCache, key) then isOwned = true end

		local statusFrame = item.StatusFrame
		local statusText = statusFrame.Text
		local statusIcon = statusFrame:FindFirstChild("StatusIcon")
		local priceLabel = item.PriceLabel

		if isOwned then
			statusFrame.BackgroundColor3 = Color3.fromRGB(74, 222, 128, 50) -- Green tint
			statusFrame.BackgroundTransparency = 0.8
			statusText.Text = "OWNED"
			statusText.TextColor3 = COLORS.GREEN
			if statusIcon then
				statusIcon.Image = "rbxassetid://3926305518" -- Checkmark
				statusIcon.ImageColor3 = COLORS.GREEN
			end
			priceLabel.Text = "Active"
			priceLabel.TextColor3 = COLORS.GREEN
		elseif currentPlayerPoints >= cost then
			statusFrame.BackgroundColor3 = Color3.fromRGB(251, 191, 36, 50) -- Yellow tint
			statusFrame.BackgroundTransparency = 0.8
			statusText.Text = "AVAILABLE"
			statusText.TextColor3 = COLORS.YELLOW
			if statusIcon then
				statusIcon.Image = "rbxassetid://3926307971" -- Shopping Bag
				statusIcon.ImageColor3 = COLORS.YELLOW
			end
			priceLabel.Text = formatNumber(cost) .. " BP"
			priceLabel.TextColor3 = COLORS.TEXT_DIM
		else
			statusFrame.BackgroundColor3 = Color3.fromRGB(148, 163, 184, 50) -- Gray tint
			statusFrame.BackgroundTransparency = 0.8
			statusText.Text = "LOCKED"
			statusText.TextColor3 = COLORS.LOCKED
			if statusIcon then
				statusIcon.Image = "rbxassetid://3926305904" -- Lock
				statusIcon.ImageColor3 = COLORS.LOCKED
			end
			priceLabel.Text = formatNumber(cost) .. " BP"
			priceLabel.TextColor3 = COLORS.TEXT_DIM
		end
	end
end

function attemptPurchase()
	if not selectedPerkIndex or not perkList[selectedPerkIndex] then return end
	local item = perkList[selectedPerkIndex]

	local btn = detailPanel.ActionBar.BuyButton
	btn.Text = "PROCESSING..."

	local success, result = pcall(function()
		return purchaseRF:InvokeServer(item.Key)
	end)

	if success and result.Success then
		table.insert(ownedPerksCache, item.Key)

		-- Assume points deducted correctly by server, update local optimistic value?
		-- Or wait for pointsUpdateEv.
		-- Optimistic update:
		local cost = item.Data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end
		currentPlayerPoints = math.max(0, currentPlayerPoints - cost)

		updateDetailPanel(selectedPerkIndex)
		updateListStatus()
	else
		btn.Text = "FAILED"
		btn.BackgroundColor3 = COLORS.RED
		task.wait(1)
		updateDetailPanel(selectedPerkIndex)
	end
end

-- Event Connections
openEv.OnClientEvent:Connect(function(config, hasDiscount)
	createUI()
	currentPerksConfig = config or {}
	hasActiveDiscount = hasDiscount
	screenGui.Enabled = true
	hideCoreGuiOnMobile()

	-- Try to get current points from leaderstats if available
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("BP") then
		currentPlayerPoints = player.leaderstats.BP.Value
	end

	buildList()

	if #perkList > 0 then
		selectPerk(1)
	end
end)

perkUpdateEv.OnClientEvent:Connect(function(owned)
	ownedPerksCache = owned or {}
	if screenGui and screenGui.Enabled then
		updateListStatus()
		if selectedPerkIndex > 0 then
			updateDetailPanel(selectedPerkIndex)
		end
	end
end)

pointsUpdateEv.OnClientEvent:Connect(function(points)
	currentPlayerPoints = points
	if screenGui and screenGui.Enabled then
		updateListStatus()
		if selectedPerkIndex > 0 then
			updateDetailPanel(selectedPerkIndex)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape and screenGui and screenGui.Enabled then
		closeShop()
	end
end)

RunService.RenderStepped:Connect(function()
	if screenGui and screenGui.Enabled then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and perksPart then
			if (char.HumanoidRootPart.Position - perksPart.Position).Magnitude > 15 then
				closeShop()
			end
		end
	end
end)

screenGui = nil -- Will be created in openEv

-- Register Proximity Interaction via Module
if perksPart then
	ProximityUIHandler.Register({
		name = "PerkShop",
		partName = "Perks",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			-- PerkShop uses server validation to open.
			-- We just request it.
			requestOpenEvent:FireServer()

			-- Since we rely on server event to actually show UI,
			-- we don't manage local state toggle here strictly.
			-- The server will fire OpenPerkShop back.
		end
	})
end
