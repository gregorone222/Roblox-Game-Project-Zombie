-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- Theme: Frutiger Aero / Y2K (Glossy, Glass, & Sky Blue)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

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
	SkyBlue = Color3.fromHex("#87ceeb"),      -- Main Aero Blue
	WhiteGloss = Color3.fromHex("#ffffff"),   -- Gloss highlights
	GlassTint = Color3.fromHex("#e0f7fa"),    -- Semi-transparent fill
	LimePop = Color3.fromHex("#76ff03"),      -- Action Green
	PinkPop = Color3.fromHex("#ff4081"),      -- Alert Pink
	TextDark = Color3.fromHex("#455a64"),     -- Slate Grey Text
	TextLight = Color3.fromHex("#eceff1"),    -- Light Grey Text
}

local FONTS = {
	Header = Enum.Font.FredokaOne, -- Soft & Round
	Body = Enum.Font.GothamMedium, -- Clean Sans
	Num = Enum.Font.GothamBold     -- Strong Numbers
}

local ICONS = {
	SelfRevive = "💚",
	StarterPoints = "💎",
	CouponDiscount = "🏷️",
	StartingShield = "🛡️",
	LegionsLegacy = "⚔️",
	Default = "📦",
	Currency = "✨",
	Shop = "🛒"
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

local function addRoundCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addGloss(parent)
	local gloss = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#defbff"))
		}),
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.2),
			NumberSequenceKeypoint.new(1, 0.5)
		}),
		Parent = parent
	})
	return gloss
end

local function addSoftShadow(parent)
	local shadow = create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 6),
		Size = UDim2.new(1, 10, 1, 10),
		ZIndex = parent.ZIndex - 1,
		Image = "rbxassetid://1316045217", -- Blur circle
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.6,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(10, 10, 118, 118),
		Parent = parent.Parent -- Hacky shadow parenting
	})
	return shadow
end

-- ==================================
-- ======== STATE MANAGEMENT ========
-- ==================================
local state = {
	isOpen = false,
	selectedId = nil,
	config = {},
	playerData = { coins = 0, inventory = {} },
	bubbles = {} -- For floating animation
}

-- ==================================
-- ======== UI CONSTRUCTION =========
-- ==================================

local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI_Aero",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false
})

-- 1. Blur Effect Overlay
local blurEffect = create("BlurEffect", {
	Size = 0,
	Parent = Lighting
})

local overlay = create("Frame", {
	Name = "Overlay",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromHex("#ffffff"),
	BackgroundTransparency = 1,
	Parent = screenGui
})

-- 2. Floating Window (Aero Glass)
local mainWindow = create("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(850, 550),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1, -- Transparent container for tweening
	Parent = overlay
})

-- 2a. Inner Float Container (For looping animation)
local floatContainer = create("Frame", {
	Name = "FloatContainer",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = THEME.GlassTint,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Parent = mainWindow
})
addRoundCorner(floatContainer, 24)
addGloss(floatContainer)
-- Glass Border
local stroke = create("UIStroke", {
	Color = THEME.WhiteGloss,
	Thickness = 4,
	Transparency = 0.3,
	Parent = floatContainer
})

-- Header Bar (Pill)
local headerBar = create("Frame", {
	Size = UDim2.new(0.8, 0, 0, 60),
	Position = UDim2.new(0.5, 0, 0, 20),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = THEME.WhiteGloss,
	Parent = floatContainer
})
addRoundCorner(headerBar, 30)

local titleLabel = create("TextLabel", {
	Text = "Boosts & Upgrades",
	Font = FONTS.Header,
	TextSize = 28,
	TextColor3 = THEME.SkyBlue,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = headerBar
})

-- Currency Bubble (Top Right)
local coinBubble = create("Frame", {
	Size = UDim2.new(0, 180, 0, 50),
	Position = UDim2.new(1, -20, 0, 25),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = THEME.LimePop,
	Parent = floatContainer
})
addRoundCorner(coinBubble, 25)
local balanceLabel = create("TextLabel", {
	Text = "0 ✨",
	Font = FONTS.Num,
	TextSize = 22,
	TextColor3 = THEME.WhiteGloss,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = coinBubble
})

-- Content Area: Horizontal Scroll of Bubbles
local scrollContainer = create("Frame", {
	Size = UDim2.new(1, -40, 0, 220),
	Position = UDim2.new(0, 20, 0.25, 0),
	BackgroundTransparency = 1,
	Parent = floatContainer
})

local scrollFrame = create("ScrollingFrame", {
	Name = "Scroll",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.SkyBlue,
	CanvasSize = UDim2.new(0,0,0,0),
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	Parent = scrollContainer
})
local listLayout = create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 20),
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = scrollFrame
})

-- Details Pod (Bottom Center)
local detailPod = create("Frame", {
	Name = "Details",
	Size = UDim2.new(0.7, 0, 0.3, 0),
	Position = UDim2.new(0.5, 0, 0.9, 0),
	AnchorPoint = Vector2.new(0.5, 1),
	BackgroundColor3 = THEME.WhiteGloss,
	Parent = floatContainer
})
addRoundCorner(detailPod, 20)
-- Info text
local dName = create("TextLabel", {
	Text = "Select Item",
	Font = FONTS.Header,
	TextSize = 24,
	TextColor3 = THEME.TextDark,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0.1, 0),
	BackgroundTransparency = 1,
	Parent = detailPod
})
local dDesc = create("TextLabel", {
	Text = "Click a bubble to view details.",
	Font = FONTS.Body,
	TextSize = 16,
	TextColor3 = THEME.TextDark,
	Size = UDim2.new(0.8, 0, 0.4, 0),
	Position = UDim2.new(0.1, 0, 0.4, 0),
	BackgroundTransparency = 1,
	TextWrapped = true,
	Parent = detailPod
})

-- Buy Button (Gel Button)
local btnBuy = create("TextButton", {
	Text = "PURCHASE",
	Font = FONTS.Num,
	TextSize = 18,
	TextColor3 = THEME.WhiteGloss,
	BackgroundColor3 = THEME.SkyBlue,
	Size = UDim2.fromOffset(180, 50),
	Position = UDim2.new(0.5, 0, 1, 15), -- Hanging off bottom
	AnchorPoint = Vector2.new(0.5, 0),
	Parent = detailPod
})
addRoundCorner(btnBuy, 25)
-- Button Gloss
create("Frame", {
	Size = UDim2.new(0.9, 0, 0.4, 0),
	Position = UDim2.new(0.05, 0, 0.05, 0),
	BackgroundColor3 = Color3.new(1,1,1),
	BackgroundTransparency = 0.6,
	Parent = btnBuy
}, {create("UICorner", {CornerRadius=UDim.new(1,0)})})


-- Close Button (Red Sphere)
local closeBtn = create("TextButton", {
	Text = "×",
	Font = FONTS.Header,
	TextSize = 30,
	TextColor3 = THEME.WhiteGloss,
	BackgroundColor3 = THEME.PinkPop,
	Size = UDim2.fromOffset(44, 44),
	Position = UDim2.new(1, -15, 0, 15),
	AnchorPoint = Vector2.new(1, 0),
	Parent = floatContainer
})
addRoundCorner(closeBtn, 22) -- Circle

-- Toast (Bubble Popup)
local toast = create("Frame", {
	Name = "Toast",
	Size = UDim2.fromOffset(0, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.LimePop,
	Visible = false,
	ZIndex = 50,
	Parent = overlay
})
addRoundCorner(toast, 100) -- Circle
local toastMsg = create("TextLabel", {
	Text = "OK!",
	Font = FONTS.Header,
	TextSize = 20,
	TextColor3 = THEME.WhiteGloss,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = toast
})

-- ==================================
-- ======== LOGIC FUNCTIONS =========
-- ==================================

-- Floating Animation
task.spawn(function()
	while true do
		local t = tick()
		if state.isOpen then
			-- Animate the inner container instead of the main window to allow entrance tweens to work
			floatContainer.Position = UDim2.new(0, 0, 0, math.sin(t * 1.5) * 5)
		end
		task.wait(0.03)
	end
end)

local function showToast(msg, isError)
	toastMsg.Text = msg
	toast.BackgroundColor3 = isError and THEME.PinkPop or THEME.LimePop

	toast.Visible = true
	toast.Size = UDim2.fromOffset(0, 0)

	-- Bubble pop in
	local t1 = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(150, 150)
	})
	t1:Play()

	task.delay(1.5, function()
		local t2 = TweenService:Create(toast, TweenInfo.new(0.2), {Size = UDim2.fromOffset(0, 0)})
		t2:Play()
		t2.Completed:Wait()
		toast.Visible = false
	end)
end

local function updatePanel(boosterId)
	state.selectedId = boosterId
	local config = state.config[boosterId]
	if not config then return end

	dName.Text = config.Name
	dDesc.Text = config.Description

	local price = config.Price
	local canAfford = state.playerData.coins >= price

	if canAfford then
		btnBuy.Text = price .. " ✨ PURCHASE"
		btnBuy.BackgroundColor3 = THEME.SkyBlue
	else
		btnBuy.Text = "NEED " .. price .. " ✨"
		btnBuy.BackgroundColor3 = Color3.fromHex("#b0bec5")
	end
end

local function populateList()
	for _, c in ipairs(scrollFrame:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local sorted = {}
	for id, cfg in pairs(state.config) do
		table.insert(sorted, {id = id, cfg = cfg})
	end
	table.sort(sorted, function(a,b) return a.cfg.Price < b.cfg.Price end)

	for _, item in ipairs(sorted) do
		local id = item.id
		local cfg = item.cfg

		-- Bubble Container
		local bubble = create("TextButton", {
			Name = id,
			BackgroundColor3 = THEME.WhiteGloss,
			Size = UDim2.fromOffset(160, 160),
			Text = "",
			AutoButtonColor = false,
			Parent = scrollFrame
		})
		addRoundCorner(bubble, 80) -- Circle

		-- Icon
		create("TextLabel", {
			Text = ICONS[id] or ICONS.Default,
			TextSize = 60,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, -0.1, 0),
			BackgroundTransparency = 1,
			Parent = bubble
		})

		-- Label
		create("TextLabel", {
			Text = cfg.Name,
			Font = FONTS.Body,
			TextSize = 14,
			TextColor3 = THEME.TextDark,
			Size = UDim2.new(1, 0, 0.3, 0),
			Position = UDim2.new(0, 0, 0.6, 0),
			BackgroundTransparency = 1,
			Parent = bubble
		})

		-- Owned Pill
		local owned = (state.playerData.inventory and state.playerData.inventory[id]) or 0
		local ownedPill = create("Frame", {
			Size = UDim2.new(0.6, 0, 0.15, 0),
			Position = UDim2.new(0.5, 0, 0.85, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = THEME.SkyBlue,
			Parent = bubble
		})
		addRoundCorner(ownedPill, 10)
		create("TextLabel", {
			Text = "x" .. owned,
			Font = FONTS.Num,
			TextSize = 12,
			TextColor3 = THEME.WhiteGloss,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = ownedPill
		})

		bubble.MouseButton1Click:Connect(function()
			updatePanel(id)
			-- Squash animation
			local t = TweenService:Create(bubble, TweenInfo.new(0.1), {Size = UDim2.fromOffset(140, 140)})
			t:Play()
			t.Completed:Wait()
			TweenService:Create(bubble, TweenInfo.new(0.3, Enum.EasingStyle.Elastic), {Size = UDim2.fromOffset(160, 160)}):Play()
		end)
	end
end

local function openShop(data)
	state.isOpen = true
	screenGui.Enabled = true
	state.playerData = data
	balanceLabel.Text = state.playerData.coins .. " ✨"

	-- Blur in
	local tBlur = TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 15})
	tBlur:Play()

	if not next(state.config) then
		state.config = GetBoosterConfig:InvokeServer()
	end

	populateList()

	local firstId = next(state.config)
	if firstId then updatePanel(firstId) end

	-- Fade/Slide Up
	mainWindow.Position = UDim2.new(0.5, 0, 0.6, 0)
	overlay.BackgroundTransparency = 1
	-- Make sure we don't accidentally hide the container logic
	for _, c in pairs(floatContainer:GetChildren()) do if c:IsA("GuiObject") then c.Visible = false end end

	local t1 = TweenService:Create(mainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	t1:Play()
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()

	task.wait(0.2)
	for _, c in pairs(floatContainer:GetChildren()) do if c:IsA("GuiObject") then c.Visible = true end end
end

local function closeShop()
	local tBlur = TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0})
	tBlur:Play()

	local t1 = TweenService:Create(mainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.6, 0)
	})
	t1:Play()
	t1.Completed:Wait()
	state.isOpen = false
	screenGui.Enabled = false
end

btnBuy.MouseButton1Click:Connect(function()
	if not state.selectedId then return end

	local result = PurchaseBoosterFunction:InvokeServer(state.selectedId)
	if result.success then
		showToast("Awesome!", false)
		local price = state.config[state.selectedId].Price
		state.playerData.coins = state.playerData.coins - price
		state.playerData.inventory[state.selectedId] = (state.playerData.inventory[state.selectedId] or 0) + 1
		balanceLabel.Text = state.playerData.coins .. " ✨"
		updatePanel(state.selectedId)
		populateList()
	else
		showToast("Oh no!", true)
	end
end)

closeBtn.MouseButton1Click:Connect(closeShop)
ToggleBoosterShopEvent.OnClientEvent:Connect(openShop)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and state.isOpen then
		closeShop()
	end
end)
