-- PerkShopUI.lua (LocalScript)
-- Path: PerkShopUI.lua (Repository Root -> StarterGui in-game)
-- Script Place: ACT 1: Village
-- Theme: Wasteland Workshop (Scrap Metal, Rust, Industrial, Mad Max)

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

local perksPart = workspace:WaitForChild("Perks", 10)

local isMobile = UserInputService.TouchEnabled

-- State for CoreGui
local originalCoreGuiStates = {}
local hasStoredCoreGuiStates = false

-- State for UI
local currentPerksConfig = {}
local hasActiveDiscount = false
local selectedPerkIndex = 0
local perkList = {}
local ownedPerksCache = {}
local currentPlayerPoints = 0

-- THEME: WASTELAND WORKSHOP
local THEME = {
	METAL_DARK = Color3.fromRGB(40, 40, 45),    -- Gunmetal
	METAL_LIGHT = Color3.fromRGB(100, 100, 105),-- Steel
	RUST_BASE = Color3.fromRGB(100, 50, 30),    -- Deep Rust
	RUST_LIGHT = Color3.fromRGB(160, 80, 40),   -- Fresh Rust

	PAINT_YELLOW = Color3.fromRGB(220, 180, 20),-- Caution Yellow
	PAINT_RED = Color3.fromRGB(180, 40, 40),    -- Danger Red

	TEXT_STAMP = Color3.fromRGB(20, 10, 10),    -- Stamped Black
	TEXT_CHALK = Color3.fromRGB(220, 220, 220), -- Chalk White

	FONT_HEAVY = Enum.Font.Bangers,         -- Big Impact
	FONT_TECH = Enum.Font.Sarpanch,         -- Industrial
	FONT_SCRIBBLE = Enum.Font.PermanentMarker, -- Notes
}

local PERK_VISUALS = {
	HPPlus = { Icon = "🛡️", Name = "ARMOR PLATING", Metal = "Iron" },
	StaminaPlus = { Icon = "⚙️", Name = "TURBO GEARS", Metal = "Aluminum" },
	ReloadPlus = { Icon = "🔧", Name = "QUICK FEED", Metal = "Steel" },
	RevivePlus = { Icon = "🔋", Name = "JUMP STARTER", Metal = "Copper" },
	RateBoost = { Icon = "🔥", Name = "NITRO INJECTOR", Metal = "Chrome" },
	Medic = { Icon = "🩹", Name = "PATCH KIT", Metal = "Tin" },
	ExplosiveRounds = { Icon = "🧨", Name = "BOOM POWDER", Metal = "Lead" },
}

-- UI Objects
local screenGui
local mainFrame
local plateGrid
local detailPlate

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

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0,0,0)
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addBolts(parent)
	local corners = {
		UDim2.new(0, 5, 0, 5),
		UDim2.new(1, -15, 0, 5),
		UDim2.new(0, 5, 1, -15),
		UDim2.new(1, -15, 1, -15)
	}
	for _, pos in ipairs(corners) do
		local bolt = create("Frame", {
			Size = UDim2.new(0, 10, 0, 10),
			Position = pos,
			BackgroundColor3 = Color3.fromRGB(150, 150, 160),
			Parent = parent
		})
		addCorner(bolt, 5)
		local inner = create("Frame", {
			Size = UDim2.new(0, 4, 0, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundColor3 = Color3.fromRGB(80, 80, 90),
			Parent = bolt
		})
		addCorner(inner, 2)
	end
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

-- Forward Declarations
local closeShop, selectPerk, buildShop, attemptPurchase, updateState

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

	-- Background Mesh (Chainlink Fence)
	local fence = create("ImageLabel", {
		Name = "Fence",
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://6522339596", -- Wire mesh texture
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 64, 0, 64),
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.new(0,0,0),
		Parent = screenGui
	})

	-- Main Frame (Heavy Steel Door)
	mainFrame = create("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, 950, 0, 650),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = THEME.METAL_DARK,
		BorderSizePixel = 0,
		Parent = screenGui
	})
	addStroke(mainFrame, THEME.RUST_BASE, 6)

	if isMobile then
		mainFrame.Size = UDim2.new(0.98, 0, 0.95, 0)
	end

	-- Header Plate
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 20, 0, 80),
		Position = UDim2.new(0, -10, 0, -20),
		BackgroundColor3 = THEME.PAINT_YELLOW,
		Rotation = -1,
		Parent = mainFrame
	})
	addBolts(header)
	addStroke(header, Color3.new(0,0,0), 3)

	-- Hazard Stripes on Header
	local stripes = create("ImageLabel", {
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://181249911",
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.8,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 40, 0, 80),
		Parent = header
	})

	create("TextLabel", {
		Text = "THE SCRAP YARD",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HEAVY,
		TextSize = 48,
		TextColor3 = THEME.TEXT_STAMP,
		Parent = header
	})

	-- Close Lever (Button)
	local closeBtn = create("TextButton", {
		Text = "EXIT",
		Size = UDim2.new(0, 80, 0, 50),
		Position = UDim2.new(1, -70, 0, 0),
		BackgroundColor3 = THEME.PAINT_RED,
		TextColor3 = THEME.TEXT_CHALK,
		Font = THEME.FONT_HEAVY,
		TextSize = 24,
		Rotation = 5,
		Parent = mainFrame
	})
	addBolts(closeBtn)
	closeBtn.MouseButton1Click:Connect(closeShop)

	-- Points Counter (Duct Tape)
	local pointsTape = create("Frame", {
		Size = UDim2.new(0, 200, 0, 40),
		Position = UDim2.new(0, 20, 0, 70),
		BackgroundColor3 = Color3.fromRGB(180, 180, 180),
		Rotation = 2,
		Parent = mainFrame
	})
	create("TextLabel", {
		Name = "Value",
		Text = "SCRAP: 0",
		Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_SCRIBBLE,
		TextSize = 24,
		TextColor3 = Color3.new(0,0,0),
		Parent = pointsTape
	})

	-- Left: Grid of Metal Plates
	plateGrid = create("ScrollingFrame", {
		Name = "Grid",
		Size = UDim2.new(0.6, 0, 0.8, 0),
		Position = UDim2.new(0, 20, 0.18, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = THEME.RUST_LIGHT,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0,0,0,0),
		Parent = mainFrame
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0, 160, 0, 140),
		CellPadding = UDim2.new(0, 15, 0, 15),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = plateGrid
	})

	-- Right: Detail Plate (Welded)
	detailPlate = create("Frame", {
		Name = "DetailPlate",
		Size = UDim2.new(0.35, 0, 0.8, 0),
		Position = UDim2.new(0.63, 0, 0.15, 0),
		BackgroundColor3 = THEME.METAL_LIGHT,
		Parent = mainFrame
	})
	addStroke(detailPlate, THEME.RUST_BASE, 4)
	addBolts(detailPlate)

	-- Welds visual
	local weld = create("Frame", {
		Size = UDim2.new(1.05, 0, 0.02, 0),
		Position = UDim2.new(-0.025, 0, 0.3, 0),
		BackgroundColor3 = Color3.fromRGB(60, 60, 60),
		Parent = detailPlate
	})

	-- Detail Content
	local dTitle = create("TextLabel", {
		Name = "Title",
		Text = "SELECT MOD",
		Size = UDim2.new(1, 0, 0.2, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_TECH,
		TextSize = 28,
		TextColor3 = THEME.TEXT_STAMP,
		Parent = detailPlate
	})

	local dDesc = create("TextLabel", {
		Name = "Desc",
		Text = "Choose an upgrade to weld onto your gear.",
		Size = UDim2.new(0.9, 0, 0.4, 0),
		Position = UDim2.new(0.05, 0, 0.35, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_SCRIBBLE,
		TextSize = 20,
		TextColor3 = Color3.new(0,0,0),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = detailPlate
	})

	local dCost = create("TextLabel", {
		Name = "Cost",
		Text = "COST: 0",
		Size = UDim2.new(0.9, 0, 0.1, 0),
		Position = UDim2.new(0.05, 0, 0.75, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HEAVY,
		TextSize = 24,
		TextColor3 = THEME.RUST_BASE,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = detailPlate
	})

	local actionBtn = create("TextButton", {
		Name = "ActionBtn",
		Text = "FORGE",
		Size = UDim2.new(0.8, 0, 0.12, 0),
		Position = UDim2.new(0.1, 0, 0.85, 0),
		BackgroundColor3 = THEME.PAINT_YELLOW,
		TextColor3 = THEME.TEXT_STAMP,
		Font = THEME.FONT_HEAVY,
		TextSize = 24,
		Parent = detailPlate
	})
	addBolts(actionBtn)
	actionBtn.MouseButton1Click:Connect(attemptPurchase)
end

function buildShop()
	plateGrid:ClearAllChildren()
	create("UIGridLayout", {
		CellSize = UDim2.new(0, 160, 0, 140),
		CellPadding = UDim2.new(0, 15, 0, 15),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = plateGrid
	})

	perkList = {}
	for key, data in pairs(currentPerksConfig) do
		table.insert(perkList, {Key = key, Data = data})
	end
	table.sort(perkList, function(a,b) return (a.Data.Cost or 0) < (b.Data.Cost or 0) end)

	for i, item in ipairs(perkList) do
		local key = item.Key
		local vis = PERK_VISUALS[key] or { Icon = "?", Name = key, Metal = "Scrap" }
		local cost = item.Data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end

		local plate = create("TextButton", {
			Name = key,
			Text = "",
			BackgroundColor3 = THEME.METAL_LIGHT,
			LayoutOrder = i,
			Parent = plateGrid
		})
		addBolts(plate)
		addStroke(plate, Color3.new(0,0,0), 2)

		-- Icon (Spray Painted)
		create("TextLabel", {
			Text = vis.Icon,
			Size = UDim2.new(1, 0, 0.6, 0),
			BackgroundTransparency = 1,
			TextSize = 50,
			Parent = plate
		})

		-- Name (Stamped)
		create("TextLabel", {
			Text = vis.Name,
			Size = UDim2.new(1, -10, 0.3, 0),
			Position = UDim2.new(0, 5, 0.6, 0),
			BackgroundTransparency = 1,
			Font = THEME.FONT_HEAVY,
			TextColor3 = THEME.TEXT_STAMP,
			TextSize = 16,
			TextWrapped = true,
			Parent = plate
		})

		-- Logic
		plate.MouseButton1Click:Connect(function()
			selectPerk(i)
		end)

		item.Button = plate
	end
	updateState()
end

function selectPerk(index)
	selectedPerkIndex = index
	if not perkList[index] then return end
	local item = perkList[index]
	local key = item.Key
	local config = item.Data
	local vis = PERK_VISUALS[key] or { Name = key }

	local cost = config.Cost or 0
	if hasActiveDiscount then cost = math.floor(cost / 2) end
	local isOwned = table.find(ownedPerksCache, key) ~= nil
	local canAfford = currentPlayerPoints >= cost

	-- Update Detail
	local detail = detailPlate
	detail.Title.Text = vis.Name
	detail.Desc.Text = config.Description or "No schematics found."
	detail.Cost.Text = "COST: " .. formatNumber(cost)

	local btn = detail.ActionBtn
	if isOwned then
		btn.Text = "EQUIPPED"
		btn.BackgroundColor3 = THEME.METAL_DARK
		btn.TextColor3 = THEME.TEXT_CHALK
		btn.Active = false
	else
		if canAfford then
			btn.Text = "FORGE"
			btn.BackgroundColor3 = THEME.PAINT_YELLOW
			btn.TextColor3 = THEME.TEXT_STAMP
		else
			btn.Text = "NO SCRAP"
			btn.BackgroundColor3 = THEME.RUST_BASE
			btn.TextColor3 = THEME.TEXT_CHALK
		end
		btn.Active = true
	end

	-- Highlight
	for i, perk in ipairs(perkList) do
		if i == index then
			perk.Button.BackgroundColor3 = Color3.fromRGB(200, 200, 200) -- Shiny
			perk.Button.UIStroke.Color = THEME.PAINT_YELLOW
			perk.Button.UIStroke.Thickness = 3
		else
			perk.Button.BackgroundColor3 = THEME.METAL_LIGHT
			perk.Button.UIStroke.Color = Color3.new(0,0,0)
			perk.Button.UIStroke.Thickness = 2
		end
	end
end

function updateState()
	if mainFrame then
		-- Update Points Tape
		-- Find PointsTape via children (since we didn't name it explicitly in CreateUI, referencing by order or scanning is tricky if not named)
		-- Let's assume we can find it by text child
		for _, c in ipairs(mainFrame:GetChildren()) do
			if c:FindFirstChild("Value") then
				c.Value.Text = "SCRAP: " .. formatNumber(currentPlayerPoints)
			end
		end
	end

	if selectedPerkIndex > 0 then
		selectPerk(selectedPerkIndex)
	end

	-- Mark owned
	for _, item in ipairs(perkList) do
		local key = item.Key
		local isOwned = table.find(ownedPerksCache, key) ~= nil
		if isOwned then
			item.Button.BackgroundColor3 = THEME.METAL_DARK -- Darker
			-- Add "Rust" overlay if not present
			if not item.Button:FindFirstChild("RustOverlay") then
				local rust = create("ImageLabel", {
					Name = "RustOverlay",
					Size = UDim2.new(1,0,1,0),
					BackgroundTransparency = 1,
					Image = "rbxassetid://133292723", -- Rust/Dirt
					ImageColor3 = THEME.RUST_BASE,
					ImageTransparency = 0.5,
					Parent = item.Button
				})
			end
		end
	end
end

function attemptPurchase()
	if not selectedPerkIndex or not perkList[selectedPerkIndex] then return end
	local item = perkList[selectedPerkIndex]
	local btn = detailPlate.ActionBtn

	if btn.Text == "EQUIPPED" or btn.Text == "NO SCRAP" then return end

	btn.Text = "WELDING..."
	local success, result = pcall(function()
		return purchaseRF:InvokeServer(item.Key)
	end)

	if success and result.Success then
		table.insert(ownedPerksCache, item.Key)
		local cost = item.Data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end
		currentPlayerPoints = math.max(0, currentPlayerPoints - cost)
		updateState()
	else
		btn.Text = "JAMMED"
		task.wait(1)
		updateState()
	end
end

-- Events
openEv.OnClientEvent:Connect(function(config, hasDiscount)
	currentPerksConfig = config or {}
	hasActiveDiscount = hasDiscount
	createUI()
	screenGui.Enabled = true
	hideCoreGuiOnMobile()

	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("BP") then
		currentPlayerPoints = player.leaderstats.BP.Value
	end
	buildShop()
	if #perkList > 0 then selectPerk(1) end
end)

perkUpdateEv.OnClientEvent:Connect(function(owned)
	ownedPerksCache = owned or {}
	if screenGui and screenGui.Enabled then
		updateState()
	end
end)

pointsUpdateEv.OnClientEvent:Connect(function(points)
	currentPlayerPoints = points
	if screenGui and screenGui.Enabled then
		updateState()
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

function closeShop()
	if screenGui then screenGui.Enabled = false end
	restoreCoreGuiOnMobile()
	closeShopEvent:FireServer()
end

if perksPart then
	ProximityUIHandler.Register({
		name = "PerkShop",
		partName = "Perks",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			requestOpenEvent:FireServer()
		end
	})
end
