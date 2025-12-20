-- PerkShopUI.lua (LocalScript)
-- Path: StarterGui/PerkShopUI.lua
-- Script Place: ACT 1: Village
-- Theme: Survivor Camp (Makeshift, Warm, Cozy Apocalypse)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")


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
local blurEffect = nil

-- THEME: SURVIVOR CAMP (Warm, Makeshift, Cozy Apocalypse)
local THEME = {
	WOOD_DARK = Color3.fromRGB(101, 67, 33),    -- Dark Wood
	WOOD_LIGHT = Color3.fromRGB(160, 120, 80),  -- Light Wood
	CANVAS = Color3.fromRGB(205, 190, 160),     -- Tent Canvas
	FABRIC_GREEN = Color3.fromRGB(85, 107, 47), -- Olive Drab

	ACCENT_YELLOW = Color3.fromRGB(255, 200, 50),-- Lantern Yellow
	ACCENT_ORANGE = Color3.fromRGB(255, 140, 0), -- Sunset Orange

	TEXT_DARK = Color3.fromRGB(50, 40, 30),     -- Ink Brown
	TEXT_LIGHT = Color3.fromRGB(250, 245, 230), -- Cream White

	FONT_HEAVY = Enum.Font.FredokaOne,          -- Friendly Bold (Valid)
	FONT_BODY = Enum.Font.GothamMedium,         -- Clean (Valid)
	FONT_HANDWRITTEN = Enum.Font.PatrickHand,   -- Handwritten (Valid Replacement for Caveat)
}

local PERK_VISUALS = {
	HPPlus = { Icon = "❤️", Name = "IRON WILL" },
	StaminaPlus = { Icon = "🏃", Name = "SECOND WIND" },
	ReloadPlus = { Icon = "✋", Name = "DEXTERITY" },
	RevivePlus = { Icon = "🤝", Name = "HUMANITY" },
	RateBoost = { Icon = "🔥", Name = "ADRENALINE" },
	Medic = { Icon = "💚", Name = "FIELD MEDIC" },
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
	return tostring(n):reverse():gsub("%d%d%d", "%0,"):reverse():gsub("^,", "")
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

	-- Initialize Blur Effect
	local camera = workspace.CurrentCamera
	blurEffect = create("BlurEffect", {Parent = camera, Size = 0, Enabled = false})

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

	-- Main Frame (Wooden Board)
	mainFrame = create("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0.7, 0, 0.7, 0), -- Converted to Scale (70% screen)
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = THEME.WOOD_DARK,
		BorderSizePixel = 0,
		Parent = screenGui
	})
	addStroke(mainFrame, THEME.WOOD_LIGHT, 6)
	
	-- Aspect Ratio Constraint to keep it board-like
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.4 -- Approx 950/650
	aspect.Parent = mainFrame

	if isMobile then
		mainFrame.Size = UDim2.new(0.95, 0, 0.9, 0)
		aspect.AspectRatio = 1.6 -- Wider on mobile landscape
	end

	-- Header (Canvas Banner)
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 20, 0, 80),
		Position = UDim2.new(0, -10, 0, -20),
		BackgroundColor3 = THEME.CANVAS,
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
		TileSize = UDim2.new(0.05, 0, 1, 0), -- Scale tile
		Parent = header
	})

	create("TextLabel", {
		Text = "SURVIVOR SUPPLY",
		Size = UDim2.new(1, 0, 0.8, 0),
		Position = UDim2.new(0,0,0.1,0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HEAVY,
		TextScaled = true, -- Rule Compliant
		TextColor3 = THEME.TEXT_DARK,
		Parent = header
	})

	-- Close Button
	local closeBtn = create("TextButton", {
		Text = "CLOSE",
		Size = UDim2.new(0.1, 0, 0.08, 0), -- Scale
		Position = UDim2.new(0.92, 0, 0, 0),
		BackgroundColor3 = THEME.ACCENT_ORANGE,
		TextColor3 = THEME.TEXT_LIGHT,
		Font = THEME.FONT_HEAVY,
		TextScaled = true,
		Rotation = 5,
		Parent = mainFrame
	})
	addBolts(closeBtn)
	closeBtn.MouseButton1Click:Connect(closeShop)

	-- Points Counter (Wooden Tag)
	local pointsTape = create("Frame", {
		Size = UDim2.new(0.25, 0, 0.06, 0), -- Scale
		Position = UDim2.new(0.02, 0, 0.1, 0),
		BackgroundColor3 = THEME.WOOD_LIGHT,
		Rotation = 2,
		Parent = mainFrame
	})
	create("TextLabel", {
		Name = "Value",
		Text = "POINTS: 0",
		Size = UDim2.new(0.9,0,0.8,0),
		Position = UDim2.new(0.05,0,0.1,0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HANDWRITTEN,
		TextScaled = true,
		TextColor3 = THEME.TEXT_DARK,
		Parent = pointsTape
	})

	-- Left: Grid of Supply Cards
	plateGrid = create("ScrollingFrame", {
		Name = "Grid",
		Size = UDim2.new(0.6, 0, 0.8, 0),
		Position = UDim2.new(0, 20, 0.18, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = THEME.WOOD_LIGHT,
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

	-- Right: Detail Card (Canvas)
	detailPlate = create("Frame", {
		Name = "DetailPlate",
		Size = UDim2.new(0.35, 0, 0.8, 0),
		Position = UDim2.new(0.63, 0, 0.15, 0),
		BackgroundColor3 = THEME.CANVAS,
		Parent = mainFrame
	})
	addStroke(detailPlate, THEME.WOOD_LIGHT, 4)
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
		Text = "SELECT UPGRADE",
		Size = UDim2.new(1, 0, 0.15, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HEAVY,
		TextScaled = true,
		TextColor3 = THEME.TEXT_DARK,
		Parent = detailPlate
	})

	local dDesc = create("TextLabel", {
		Name = "Desc",
		Text = "Pick an upgrade to boost your survival.",
		Size = UDim2.new(0.9, 0, 0.45, 0),
		Position = UDim2.new(0.05, 0, 0.25, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HANDWRITTEN,
		TextScaled = true,
		TextColor3 = THEME.TEXT_DARK,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = detailPlate
	})

	local dCost = create("TextLabel", {
		Name = "Cost",
		Text = "COST: 0",
		Size = UDim2.new(0.9, 0, 0.1, 0),
		Position = UDim2.new(0.05, 0, 0.72, 0),
		BackgroundTransparency = 1,
		Font = THEME.FONT_HEAVY,
		TextScaled = true,
		TextColor3 = THEME.ACCENT_ORANGE,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = detailPlate
	})

	local actionBtn = create("TextButton", {
		Name = "ActionBtn",
		Text = "GET",
		Size = UDim2.new(0.8, 0, 0.12, 0),
		Position = UDim2.new(0.1, 0, 0.85, 0),
		BackgroundColor3 = THEME.ACCENT_YELLOW,
		TextColor3 = THEME.TEXT_DARK,
		Font = THEME.FONT_HEAVY,
		TextScaled = true,
		Parent = detailPlate
	})
	addBolts(actionBtn)
	actionBtn.MouseButton1Click:Connect(attemptPurchase)
end

function buildShop()
	plateGrid:ClearAllChildren()
	create("UIGridLayout", {
		CellSize = UDim2.new(0.3, 0, 0.25, 0), -- Scale cells
		CellPadding = UDim2.new(0.02, 0, 0.02, 0),
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
		local vis = PERK_VISUALS[key] or { Icon = "?", Name = key }
		local cost = item.Data.Cost or 0
		if hasActiveDiscount then cost = math.floor(cost / 2) end

		local plate = create("TextButton", {
			Name = key,
			Text = "",
			BackgroundColor3 = THEME.CANVAS,
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
			TextScaled = true,
			Parent = plate
		})

		-- Name (Label)
		create("TextLabel", {
			Text = vis.Name,
			Size = UDim2.new(1, -10, 0.25, 0),
			Position = UDim2.new(0, 5, 0.65, 0),
			BackgroundTransparency = 1,
			Font = THEME.FONT_HEAVY,
			TextColor3 = THEME.TEXT_DARK,
			TextScaled = true, -- Rule Compliant
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
		btn.Text = "OWNED"
		btn.BackgroundColor3 = THEME.WOOD_DARK
		btn.TextColor3 = THEME.TEXT_LIGHT
		btn.Active = false
	else
		if canAfford then
			btn.Text = "GET"
			btn.BackgroundColor3 = THEME.ACCENT_YELLOW
			btn.TextColor3 = THEME.TEXT_DARK
		else
			btn.Text = "NOT ENOUGH"
			btn.BackgroundColor3 = THEME.FABRIC_GREEN
			btn.TextColor3 = THEME.TEXT_LIGHT
		end
		btn.Active = true
	end

	-- Highlight
	for i, perk in ipairs(perkList) do
		if i == index then
			perk.Button.BackgroundColor3 = THEME.ACCENT_YELLOW -- Selected
			perk.Button.UIStroke.Color = THEME.ACCENT_ORANGE
			perk.Button.UIStroke.Thickness = 3
		else
			perk.Button.BackgroundColor3 = THEME.CANVAS
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
				c.Value.Text = "POINTS: " .. formatNumber(currentPlayerPoints)
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
			item.Button.BackgroundColor3 = THEME.WOOD_DARK -- Darker
			-- Add checkmark overlay if not present
			if not item.Button:FindFirstChild("OwnedOverlay") then
				local owned = create("TextLabel", {
					Name = "OwnedOverlay",
					Size = UDim2.new(1,0,1,0),
					BackgroundTransparency = 0.7,
					BackgroundColor3 = THEME.FABRIC_GREEN,
					Text = "✓",
					TextSize = 50,
					TextColor3 = THEME.TEXT_LIGHT,
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

	-- Enable Blur
	if blurEffect then
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 15}):Play()
	end

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
			local targetPos = perksPart:IsA("Model") and perksPart:GetPivot().Position or perksPart.Position
			if (char.HumanoidRootPart.Position - targetPos).Magnitude > 15 then
				closeShop()
			end
		end
	end
end)

function closeShop()
	if screenGui then
		screenGui.Enabled = false

		-- Disable Blur
		if blurEffect then
			TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 0}):Play()
			task.delay(0.5, function() blurEffect.Enabled = false end)
		end
	end
	restoreCoreGuiOnMobile()
	closeShopEvent:FireServer()
end

if perksPart then
	local prompt = perksPart:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Perk Shop"
		prompt.ActionText = "Trade" 
		prompt.Parent = perksPart
	end

	prompt.Triggered:Connect(function()
		requestOpenEvent:FireServer()
	end)
end

return {}
