-- BoosterShopUI.lua (LocalScript)
-- Path: StarterGui/BoosterShopUI.lua
-- Script Place: Lobby
-- Theme: Zombie Apocalypse // Field Supply Case (Military, Rugged, & Industrial)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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
	CaseColor = Color3.fromHex("#263238"),     -- Gunmetal Grey
	FoamColor = Color3.fromHex("#1c1c1c"),     -- Dark Foam
	AccentYellow = Color3.fromHex("#fbc02d"),  -- Hazard Yellow
	AccentRed = Color3.fromHex("#d32f2f"),     -- Danger Red
	ScreenBG = Color3.fromHex("#002200"),      -- Dark LCD Green
	ScreenText = Color3.fromHex("#69f0ae"),    -- Bright LCD Green
	Metal = Color3.fromHex("#455a64"),         -- Steel
	TextLight = Color3.fromHex("#cfd8dc"),     -- Off-White
}

local FONTS = {
	Stencil = Enum.Font.Sarpanch,      -- Military Stencil look
	Tech = Enum.Font.RobotoMono,       -- LCD Readout
	Label = Enum.Font.GothamBold       -- Clear Labels
}

local ICONS = {
	SelfRevive = "✚",
	StarterPoints = "💲",
	CouponDiscount = "🏷",
	StartingShield = "🛡",
	LegionsLegacy = "⚔",
	Default = "📦",
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

local function addBolt(parent, pos)
	create("Frame", {
		Name = "Bolt",
		Size = UDim2.fromOffset(12, 12),
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#546e7a"),
		Parent = parent
	}, {create("UICorner", {CornerRadius = UDim.new(1, 0)})})
end

local function addCautionStripes(parent)
	local stripes = create("ImageLabel", {
		Name = "Stripes",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, -20),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6008328148", -- Placeholder noise, simulated stripes via tiling/color usually
		ImageColor3 = THEME.AccentYellow,
		Parent = parent
	})
	-- Simulating stripes with a frame + texture is hard without a specific asset, 
	-- so we use a yellow bar with a pattern or just a solid hazard bar.
	stripes.BackgroundColor3 = THEME.AccentYellow
	stripes.BackgroundTransparency = 0
	stripes.BorderSizePixel = 0

	-- Add text "CAUTION: LIVE ORDNANCE"
	create("TextLabel", {
		Text = "/// CAUTION: CLASS-4 SUPPLIES ///",
		Font = FONTS.Tech,
		TextSize = 14,
		TextColor3 = Color3.new(0,0,0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = stripes
	})
	return stripes
end

-- ==================================
-- ======== STATE MANAGEMENT ========
-- ==================================
local state = {
	isOpen = false,
	selectedId = nil,
	config = {},
	playerData = { coins = 0, inventory = {} },
	elements = {}
}

-- ==================================
-- ======== UI CONSTRUCTION =========
-- ==================================

local screenGui = create("ScreenGui", {
	Name = "BoosterShopUI_FieldCase",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Enabled = false
})

-- 1. Dark Vignette / Blur
local blurEffect = create("BlurEffect", {
	Size = 0,
	Parent = Lighting
})

-- 2. The Hard Case
local mainCase = create("Frame", {
	Name = "SupplyCase",
	Size = UDim2.fromOffset(900, 600),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.CaseColor,
	BorderSizePixel = 0,
	Parent = screenGui
})
create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = mainCase})
create("UIStroke", {Color = Color3.new(0,0,0), Thickness = 4, Parent = mainCase})

-- Bolts in corners
addBolt(mainCase, UDim2.new(0, 15, 0, 15))
addBolt(mainCase, UDim2.new(1, -15, 0, 15))
addBolt(mainCase, UDim2.new(0, 15, 1, -15))
addBolt(mainCase, UDim2.new(1, -15, 1, -15))

-- Hazard Strip at bottom
addCautionStripes(mainCase)

-- Header Stencil
create("TextLabel", {
	Text = "FIELD SUPPLY // UNIT 734",
	Font = FONTS.Stencil,
	TextSize = 36,
	TextColor3 = Color3.new(1,1,1),
	TextTransparency = 0.5,
	Size = UDim2.new(0.5, 0, 0.1, 0),
	Position = UDim2.new(0.05, 0, 0.02, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Parent = mainCase
})

-- Content Area (Foam Insert + Control Panel)
local contentFrame = create("Frame", {
	Size = UDim2.new(0.94, 0, 0.8, 0),
	Position = UDim2.new(0.03, 0, 0.12, 0),
	BackgroundTransparency = 1,
	Parent = mainCase
})

-- Left: Foam Grid
local foamInsert = create("Frame", {
	Name = "FoamInsert",
	Size = UDim2.new(0.6, 0, 1, 0),
	BackgroundColor3 = THEME.FoamColor,
	Parent = contentFrame
}, {create("UICorner", {CornerRadius = UDim.new(0, 8)})})

-- Inner Shadow for Foam effect
create("UIStroke", {
	Color = Color3.new(0,0,0),
	Thickness = 2,
	Transparency = 0.5,
	Parent = foamInsert
})

local grid = create("ScrollingFrame", {
	Name = "Grid",
	Size = UDim2.new(0.9, 0, 0.9, 0),
	Position = UDim2.new(0.05, 0, 0.05, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.Metal,
	Parent = foamInsert
})
create("UIGridLayout", {
	Parent = grid,
	CellSize = UDim2.new(0.3, 0, 0, 130),
	CellPadding = UDim2.new(0.03, 0, 0.03, 0),
	SortOrder = Enum.SortOrder.LayoutOrder
})

-- Right: Control Panel / Readout
local controlPanel = create("Frame", {
	Name = "ControlPanel",
	Size = UDim2.new(0.38, 0, 1, 0),
	Position = UDim2.new(0.62, 0, 0, 0),
	BackgroundColor3 = THEME.Metal,
	Parent = contentFrame
}, {create("UICorner", {CornerRadius = UDim.new(0, 8)})})

-- LCD Screen
local lcdScreen = create("Frame", {
	Name = "LCD",
	Size = UDim2.new(0.9, 0, 0.5, 0),
	Position = UDim2.new(0.05, 0, 0.05, 0),
	BackgroundColor3 = THEME.ScreenBG,
	Parent = controlPanel
}, {create("UICorner", {CornerRadius = UDim.new(0, 4)}), create("UIStroke", {Color=Color3.new(0,0,0), Thickness=3})})

state.elements.dTitle = create("TextLabel", {
	Text = "NO SELECTION",
	Font = FONTS.Tech,
	TextSize = 22,
	TextColor3 = THEME.ScreenText,
	Size = UDim2.new(0.9, 0, 0.15, 0),
	Position = UDim2.new(0.05, 0, 0.05, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Parent = lcdScreen
})

create("Frame", { -- Separator Line
	Size = UDim2.new(0.9, 0, 0, 2),
	Position = UDim2.new(0.05, 0, 0.2, 0),
	BackgroundColor3 = THEME.ScreenText,
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	Parent = lcdScreen
})

state.elements.dDesc = create("TextLabel", {
	Text = "Select an item from the containment unit.",
	Font = FONTS.Tech,
	TextSize = 16,
	TextColor3 = THEME.ScreenText,
	TextTransparency = 0.2,
	Size = UDim2.new(0.9, 0, 0.5, 0),
	Position = UDim2.new(0.05, 0, 0.25, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	BackgroundTransparency = 1,
	Parent = lcdScreen
})

state.elements.dCost = create("TextLabel", {
	Text = "COST: ---",
	Font = FONTS.Tech,
	TextSize = 20,
	TextColor3 = THEME.AccentYellow,
	Size = UDim2.new(0.9, 0, 0.1, 0),
	Position = UDim2.new(0.05, 0, 0.85, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
	BackgroundTransparency = 1,
	Parent = lcdScreen
})

-- Big Physical Button
state.elements.btnBuy = create("TextButton", {
	Text = "DISPENSE",
	Font = FONTS.Stencil,
	TextSize = 28,
	TextColor3 = Color3.new(0,0,0),
	BackgroundColor3 = THEME.AccentYellow,
	Size = UDim2.new(0.9, 0, 0.2, 0),
	Position = UDim2.new(0.05, 0, 0.6, 0),
	Parent = controlPanel
}, {create("UICorner", {CornerRadius = UDim.new(0, 6)})})

-- Button Bevel Shadow
create("Frame", {
	Size = UDim2.new(1, 0, 0, 5),
	Position = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromHex("#c6a700"),
	Parent = state.elements.btnBuy
}, {create("UICorner", {CornerRadius = UDim.new(0, 6)})})

-- Wallet Plate
local walletPlate = create("Frame", {
	Size = UDim2.new(0.9, 0, 0.1, 0),
	Position = UDim2.new(0.05, 0, 0.85, 0),
	BackgroundColor3 = Color3.new(0,0,0),
	Parent = controlPanel
}, {create("UICorner", {CornerRadius = UDim.new(0, 4)})})

state.elements.balanceLabel = create("TextLabel", {
	Text = "FUNDS: 0",
	Font = FONTS.Tech,
	TextSize = 18,
	TextColor3 = THEME.TextLight,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = walletPlate
})

-- Close Button (Tactical Switch)
local closeBtn = create("TextButton", {
	Text = "X",
	Font = FONTS.Stencil,
	TextSize = 24,
	TextColor3 = THEME.TextLight,
	BackgroundColor3 = THEME.AccentRed,
	Size = UDim2.fromOffset(40, 40),
	Position = UDim2.new(1, -10, 0, 10),
	AnchorPoint = Vector2.new(1, 0),
	Parent = mainCase
}, {create("UICorner", {CornerRadius = UDim.new(0, 4)})})


-- ==================================
-- ======== LOGIC FUNCTIONS =========
-- ==================================

local function populateList()
	for _, c in ipairs(grid:GetChildren()) do
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

		-- Slot Button
		local slot = create("TextButton", {
			Name = id,
			BackgroundColor3 = Color3.fromHex("#111111"), -- Deep recess
			Text = "",
			AutoButtonColor = false,
			Parent = grid
		}, {create("UICorner", {CornerRadius = UDim.new(0, 6)}), create("UIStroke", {Color=Color3.new(0,0,0), Thickness=1})})

		-- LED Indicator
		local led = create("Frame", {
			Name = "LED",
			Size = UDim2.new(0, 8, 0, 8),
			Position = UDim2.new(0.9, 0, 0.1, 0),
			BackgroundColor3 = Color3.fromHex("#222222"), -- Off
			Parent = slot
		}, {create("UICorner", {CornerRadius = UDim.new(1,0)})})

		-- Icon
		create("TextLabel", {
			Text = ICONS[id] or ICONS.Default,
			TextSize = 40,
			Size = UDim2.new(1, 0, 0.6, 0),
			Position = UDim2.new(0, 0, 0.1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromHex("#555555"), -- Dimmed
			Parent = slot
		})

		-- Name Label
		create("TextLabel", {
			Text = cfg.Name,
			Font = FONTS.Label,
			TextSize = 12,
			TextColor3 = THEME.TextLight,
			TextTransparency = 0.5,
			Size = UDim2.new(0.9, 0, 0.2, 0),
			Position = UDim2.new(0.05, 0, 0.75, 0),
			BackgroundTransparency = 1,
			Parent = slot
		})

		-- Owned Counter (Stamped on top)
		local owned = (state.playerData.inventory and state.playerData.inventory[id]) or 0
		if owned > 0 then
			create("TextLabel", {
				Text = "x" .. owned,
				Font = FONTS.Stencil,
				TextSize = 14,
				TextColor3 = THEME.AccentYellow,
				Size = UDim2.new(0.3, 0, 0.2, 0),
				Position = UDim2.new(0.05, 0, 0.05, 0),
				BackgroundTransparency = 1,
				Parent = slot
			})
		end

		slot.MouseButton1Click:Connect(function()
			state.selectedId = id

			-- Update visual selection (Lights on)
			for _, c in ipairs(grid:GetChildren()) do
				if c:IsA("TextButton") then
					local l = c:FindFirstChild("LED")
					local i = c:FindFirstChildOfClass("TextLabel") -- Icon
					if l then l.BackgroundColor3 = Color3.fromHex("#222222") end
					if i then i.TextColor3 = Color3.fromHex("#555555") end
					c.BackgroundColor3 = Color3.fromHex("#111111")
				end
			end

			led.BackgroundColor3 = THEME.AccentYellow -- Active LED
			slot.BackgroundColor3 = Color3.fromHex("#1a1a1a") -- Slightly lighter recess
			local icon = slot:FindFirstChildOfClass("TextLabel")
			if icon then icon.TextColor3 = Color3.new(1,1,1) end

			-- Screen Update
			state.elements.dTitle.Text = string.upper(cfg.Name)
			state.elements.dDesc.Text = cfg.Description

			local price = cfg.Price
			local canAfford = state.playerData.coins >= price

			state.elements.dCost.Text = "COST: " .. price

			if canAfford then
				state.elements.btnBuy.Text = "DISPENSE"
				state.elements.btnBuy.BackgroundColor3 = THEME.AccentYellow
				state.elements.btnBuy.TextColor3 = Color3.new(0,0,0)
				state.elements.btnBuy.Interactable = true
			else
				state.elements.btnBuy.Text = "NO FUNDS"
				state.elements.btnBuy.BackgroundColor3 = Color3.fromHex("#550000")
				state.elements.btnBuy.TextColor3 = Color3.fromHex("#aa0000")
				state.elements.btnBuy.Interactable = false
			end
		end)
	end
end

local function openShop(data)
	state.isOpen = true
	screenGui.Enabled = true
	state.playerData = data
	state.elements.balanceLabel.Text = "FUNDS: " .. state.playerData.coins

	TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 15}):Play()

	-- Open Animation: Fold open or slide up
	mainCase.Position = UDim2.new(0.5, 0, 1.5, 0)
	mainCase.Rotation = 10
	local t = TweenService:Create(mainCase, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 0
	})
	t:Play()

	if not next(state.config) then
		state.config = GetBoosterConfig:InvokeServer()
	end

	populateList()
end

local function closeShop()
	local t = TweenService:Create(mainCase, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0),
		Rotation = -10
	})
	t:Play()
	t.Completed:Wait()

	blurEffect.Size = 0
	state.isOpen = false
	screenGui.Enabled = false
end

state.elements.btnBuy.MouseButton1Click:Connect(function()
	if not state.selectedId then return end

	local result = PurchaseBoosterFunction:InvokeServer(state.selectedId)
	if result.success then
		state.elements.btnBuy.Text = "DISPENSED"

		-- Flash
		local t1 = TweenService:Create(state.elements.btnBuy, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromHex("#69f0ae")})
		t1:Play()
		t1.Completed:Wait()
		TweenService:Create(state.elements.btnBuy, TweenInfo.new(0.2), {BackgroundColor3 = THEME.AccentYellow}):Play()

		-- Update Data
		local price = state.config[state.selectedId].Price
		state.playerData.coins = state.playerData.coins - price
		state.playerData.inventory[state.selectedId] = (state.playerData.inventory[state.selectedId] or 0) + 1
		state.elements.balanceLabel.Text = "FUNDS: " .. state.playerData.coins

		populateList() -- Refresh inventory counts
	else
		state.elements.btnBuy.Text = "ERROR"
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
