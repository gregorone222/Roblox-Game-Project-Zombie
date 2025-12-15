-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- Theme: Field Medic Kit (White, Red Cross, Dirty Fabric, Sterile but Worn)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

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
	KitWhite = Color3.fromRGB(220, 220, 215),  -- Dirty White
	KitGrey = Color3.fromRGB(150, 150, 155),   -- Fabric Grey
	MedicalRed = Color3.fromRGB(180, 40, 40),  -- Red Cross Red
	TextDark = Color3.fromRGB(50, 50, 55),     -- Ink Black
	TextRed = Color3.fromRGB(150, 20, 20),     -- Warning Red
	StrapBrown = Color3.fromRGB(100, 70, 50),  -- Leather Strap
}

local FONTS = {
	Header = Enum.Font.SpecialElite,    -- Stamped Text
	Label = Enum.Font.GothamMedium,     -- Readable
	Mono = Enum.Font.Code               -- Technical
}

local ICONS = {
	SelfRevive = "✚",
	StarterPoints = "💉",
	CouponDiscount = "🎫",
	StartingShield = "🛡",
	LegionsLegacy = "⚔",
	Default = "💊",
	Currency = "★"
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

local function addShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageColor3 = Color3.new(0,0,0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.Parent = parent
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
	elements = {},
	blurEffect = nil -- Store reference
}

-- ==================================
-- ======== UI CONSTRUCTION =========
-- ==================================

local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI_Medic",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false
})

-- Initialize Blur Effect
local camera = workspace.CurrentCamera
state.blurEffect = create("BlurEffect", {
	Size = 0,
	Parent = camera, -- Use Camera for local effect consistency
	Enabled = false
})

-- 1. Main Bag Panel
local mainBag = create("Frame", {
	Name = "MedicalBag",
	Size = UDim2.fromOffset(800, 550),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.KitWhite,
	Parent = screenGui
}, {addCorner(nil, 16)})

addShadow(mainBag)

-- Decoration: Red Cross Patch
local crossPatch = create("Frame", {
	Size = UDim2.fromOffset(60, 60),
	Position = UDim2.new(0, 30, 0, 30),
	BackgroundColor3 = THEME.KitWhite,
	Parent = mainBag
}, {addCorner(nil, 30)})

local crossV = create("Frame", {
	Size = UDim2.new(0.3, 0, 0.7, 0),
	Position = UDim2.new(0.35, 0, 0.15, 0),
	BackgroundColor3 = THEME.MedicalRed,
	BorderSizePixel = 0,
	Parent = crossPatch
})
local crossH = create("Frame", {
	Size = UDim2.new(0.7, 0, 0.3, 0),
	Position = UDim2.new(0.15, 0, 0.35, 0),
	BackgroundColor3 = THEME.MedicalRed,
	BorderSizePixel = 0,
	Parent = crossPatch
})

-- Header Text (Stamped)
create("TextLabel", {
	Text = "EMERGENCY SUPPLY",
	Font = FONTS.Header,
	TextSize = 32,
	TextColor3 = THEME.MedicalRed,
	Size = UDim2.new(0.6, 0, 0.1, 0),
	Position = UDim2.new(0, 110, 0, 45),
	AnchorPoint = Vector2.new(0, 0.5),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Parent = mainBag
})

-- Decoration: Zipper/Strap
local zipper = create("Frame", {
	Size = UDim2.new(1, 0, 0, 8),
	Position = UDim2.new(0, 0, 0.2, 0),
	BackgroundColor3 = Color3.new(0.2, 0.2, 0.2),
	Parent = mainBag
})
-- Stitching lines
for i = 0, 1, 0.02 do
	create("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		Position = UDim2.new(i, 0, 0, 0),
		BackgroundColor3 = Color3.new(0.5, 0.5, 0.5),
		BorderSizePixel = 0,
		Parent = zipper
	})
end

-- Close Button (X Tape)
local closeBtn = create("TextButton", {
	Text = "",
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.new(1, -20, 0, 20),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundColor3 = THEME.MedicalRed,
	Parent = mainBag
}, {addCorner(nil, 20)})
create("TextLabel", { Text="X", TextColor3=Color3.new(1,1,1), Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Font=FONTS.Header, TextSize=24, Parent=closeBtn})


-- Content Area (Below Zipper)
local contentArea = create("Frame", {
	Size = UDim2.new(1, -40, 0.75, 0),
	Position = UDim2.new(0, 20, 0.22, 0),
	BackgroundTransparency = 1,
	Parent = mainBag
})

-- LEFT: Supply Slots (Grid of pouches)
local scroll = create("ScrollingFrame", {
	Size = UDim2.new(0.6, 0, 1, 0),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.MedicalRed,
	CanvasSize = UDim2.new(0,0,0,0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = contentArea
})
local grid = create("UIGridLayout", {
	CellSize = UDim2.new(0.45, 0, 0, 140),
	CellPadding = UDim2.new(0.05, 0, 0.05, 0),
	Parent = scroll
})

-- RIGHT: Details Card (Clipboard style)
local clipboard = create("Frame", {
	Size = UDim2.new(0.35, 0, 1, 0),
	Position = UDim2.new(0.65, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(139, 69, 19), -- Brown board
	Parent = contentArea
}, {addCorner(nil, 4)})

-- Paper
local paper = create("Frame", {
	Size = UDim2.new(0.9, 0, 0.9, 0),
	Position = UDim2.new(0.05, 0, 0.08, 0),
	BackgroundColor3 = Color3.fromRGB(250, 245, 230),
	Parent = clipboard
})

-- Metal Clip
create("Frame", {
	Size = UDim2.new(0.6, 0, 0.05, 0),
	Position = UDim2.new(0.2, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(150, 150, 150),
	Parent = clipboard
}, {addCorner(nil, 4)})

-- Details Content
state.elements.dTitle = create("TextLabel", {
	Text = "SELECT ITEM",
	Font = FONTS.Header,
	TextSize = 20,
	TextColor3 = THEME.TextDark,
	Size = UDim2.new(1, -10, 0, 30),
	Position = UDim2.new(0, 5, 0, 10),
	BackgroundTransparency = 1,
	Parent = paper
})

create("Frame", { -- Line
	Size = UDim2.new(0.8, 0, 0, 2),
	Position = UDim2.new(0.1, 0, 0, 45),
	BackgroundColor3 = THEME.TextDark,
	Parent = paper
})

state.elements.dDesc = create("TextLabel", {
	Text = "Select a medical supply from the kit.",
	Font = FONTS.Label,
	TextSize = 14,
	TextColor3 = THEME.TextDark,
	Size = UDim2.new(0.9, 0, 0.4, 0),
	Position = UDim2.new(0.05, 0, 0.2, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	BackgroundTransparency = 1,
	Parent = paper
})

state.elements.dPrice = create("TextLabel", {
	Text = "COST: -",
	Font = FONTS.Header,
	TextSize = 22,
	TextColor3 = THEME.MedicalRed,
	Size = UDim2.new(0.9, 0, 0.1, 0),
	Position = UDim2.new(0.05, 0, 0.7, 0),
	BackgroundTransparency = 1,
	Parent = paper
})

state.elements.buyBtn = create("TextButton", {
	Text = "TAKE",
	Font = FONTS.Header,
	TextSize = 24,
	TextColor3 = Color3.new(1,1,1),
	BackgroundColor3 = THEME.MedicalRed,
	Size = UDim2.new(0.8, 0, 0.15, 0),
	Position = UDim2.new(0.1, 0, 0.82, 0),
	Parent = paper
}, {addCorner(nil, 8)})


-- Wallet Tag hanging off clipboard
local tag = create("Frame", {
	Size = UDim2.new(0.8, 0, 0.1, 0),
	Position = UDim2.new(0.1, 0, 1.05, 0),
	BackgroundColor3 = Color3.fromRGB(240, 240, 200),
	Parent = clipboard
}, {addCorner(nil, 4)})
create("UIStroke", {Color=Color3.new(0,0,0), Thickness=1, Parent=tag})

state.elements.wallet = create("TextLabel", {
	Text = "FUNDS: 0",
	Size = UDim2.new(1,0,1,0),
	BackgroundTransparency = 1,
	Font = FONTS.Mono,
	TextColor3 = THEME.TextDark,
	TextSize = 16,
	Parent = tag
})


-- ==================================
-- ======== LOGIC ===================
-- ==================================

local function populate()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for id, cfg in pairs(state.config) do
		-- Pouch Button
		local pouch = create("TextButton", {
			Name = id,
			BackgroundColor3 = THEME.KitGrey,
			Text = "",
			AutoButtonColor = false,
			Parent = scroll
		}, {addCorner(nil, 8)})

		-- Icon
		create("TextLabel", {
			Text = ICONS[id] or ICONS.Default,
			Size = UDim2.new(1, 0, 0.6, 0),
			BackgroundTransparency = 1,
			TextSize = 50,
			Parent = pouch
		})

		-- Name Tape
		local tape = create("Frame", {
			Size = UDim2.new(0.8, 0, 0.25, 0),
			Position = UDim2.new(0.1, 0, 0.65, 0),
			BackgroundColor3 = Color3.fromRGB(240, 240, 240),
			Parent = pouch
		})
		-- Tape look
		create("ImageLabel", {
			Size = UDim2.new(1, 0, 0.2, 0),
			Position = UDim2.new(0, 0, 0, -2),
			BackgroundColor3 = Color3.new(0,0,0),
			BackgroundTransparency = 0.8, -- Shadow under tape
			BorderSizePixel = 0,
			Parent = tape
		})

		create("TextLabel", {
			Text = cfg.Name,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Font = FONTS.Label,
			TextSize = 12,
			TextColor3 = THEME.TextDark,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = tape
		})

		-- Selection Logic
		pouch.MouseButton1Click:Connect(function()
			state.selectedId = id

			-- Update Details
			state.elements.dTitle.Text = string.upper(cfg.Name)
			state.elements.dDesc.Text = cfg.Description
			state.elements.dPrice.Text = cfg.Price .. " Coins"

			if state.playerData.coins >= cfg.Price then
				state.elements.buyBtn.Text = "TAKE"
				state.elements.buyBtn.BackgroundColor3 = THEME.MedicalRed
				state.elements.buyBtn.Interactable = true
			else
				state.elements.buyBtn.Text = "NO FUNDS"
				state.elements.buyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				state.elements.buyBtn.Interactable = false
			end
		end)
	end
end

local function toggle(data)
	if state.isOpen then
		-- Close logic
		local t = TweenService:Create(mainBag, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.5, 0)})
		t:Play()

		-- Disable Blur
		if state.blurEffect then
			TweenService:Create(state.blurEffect, TweenInfo.new(0.5), {Size=0}):Play()
			task.delay(0.5, function() state.blurEffect.Enabled = false end)
		end

		t.Completed:Wait()
		screenGui.Enabled = false
		state.isOpen = false
	else
		-- Open logic
		state.isOpen = true
		screenGui.Enabled = true
		state.playerData = data or {coins=0, inventory={}}
		state.elements.wallet.Text = "COINS: " .. state.playerData.coins

		-- Enable Blur
		if state.blurEffect then
			state.blurEffect.Enabled = true
			TweenService:Create(state.blurEffect, TweenInfo.new(0.5), {Size=20}):Play()
		end

		mainBag.Position = UDim2.new(0.5, 0, 1.5, 0)
		TweenService:Create(mainBag, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

		if not next(state.config) then
			state.config = GetBoosterConfig:InvokeServer()
		end
		populate()
	end
end

local function close()
	toggle(nil) -- Use toggle logic for closing
end

state.elements.buyBtn.MouseButton1Click:Connect(function()
	if not state.selectedId then return end
	local res = PurchaseBoosterFunction:InvokeServer(state.selectedId)
	if res.success then
		state.elements.buyBtn.Text = "TAKEN"
		state.playerData.coins = state.playerData.coins - state.config[state.selectedId].Price
		state.elements.wallet.Text = "COINS: " .. state.playerData.coins
		task.wait(0.5)
		state.elements.buyBtn.Text = "TAKE"
	end
end)

closeBtn.MouseButton1Click:Connect(close)
ToggleBoosterShopEvent.OnClientEvent:Connect(toggle)

-- Manual Proximity Prompt Connection
local function setupPrompt()
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment", 10)
	if not lobbyEnv then return end

	local shopPart = lobbyEnv:WaitForChild("BoosterShop", 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				toggle({coins = 9999, inventory = {}}) -- Placeholder data call, ideally invoke server function for real data
			end)
		end
	end
end

task.spawn(setupPrompt)

return {} -- Module return
