-- MPShopUI.lua (LocalScript)
-- Path: StarterGui/MPShopUI.lua
-- Script Place: Lobby
-- Theme: Tactical Dossier / Blueprint (Night Vision Green, Grid Lines, Secret Documents)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- MODULES & REMOTES
-- ============================================================================

local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

local SpecialItemsConfig = {
	XP_BOOSTER_30MIN = {
		ID = "XP_BOOSTER_30MIN",
		Name = "XP Booster (30m)",
		Description = "Authorized stim-pack to enhance learning capability for 30 minutes.",
		MPCost = 2000,
		Icon = "rbxassetid://11419722678"
	},
	COIN_BOOSTER_1GAME = {
		ID = "COIN_BOOSTER_1GAME",
		Name = "Coin Booster (1 Game)",
		Description = "Priority requisition status for the next operation.",
		MPCost = 3000,
		Icon = "rbxassetid://11419708237"
	},
	DAILY_MISSION_REROLL = {
		ID = "DAILY_MISSION_REROLL",
		Name = "Daily Mission Reroll",
		Description = "Request new operational directives from command.",
		MPCost = 500,
		Icon = "rbxassetid://11419715729"
	}
}

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local purchaseSkinFunc = RemoteFunctions:WaitForChild("PurchaseSkin")
local purchaseItemFunc = RemoteFunctions:WaitForChild("PurchaseGenericItem")
local getMPFunc = ReplicatedStorage:WaitForChild("GetInitialMissionPoints")
local mpChangedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("MissionPointsChanged")

-- ============================================================================
-- CONSTANTS & THEME
-- ============================================================================

local COLORS = {
	BG_ROOT = Color3.fromRGB(10, 20, 15),       -- Dark NVG Background
	BG_PANEL = Color3.fromRGB(15, 30, 20),      -- Slightly lighter

	TEXT_MAIN = Color3.fromRGB(50, 255, 50),    -- Phosphor Green
	TEXT_DIM = Color3.fromRGB(20, 100, 20),     -- Dim Green

	BORDER = Color3.fromRGB(50, 255, 50),       -- Bright Green Lines
	GRID = Color3.fromRGB(20, 60, 20),          -- Faint Grid

	ACCENT_ALERT = Color3.fromRGB(255, 50, 50), -- Red Alert
	ACCENT_SCAN = Color3.fromRGB(100, 255, 100) -- Scanline
}

local FONTS = {
	Main = Enum.Font.Code,     -- Monospace
	Header = Enum.Font.RobotoMono -- Clean Monospace
}

local mpShopUI = {}

-- UI References
local screenGui = nil
local mainFrame = nil
local gridContainer = nil
local detailContainer = nil
local activePreview = nil

-- State
local currentTab = "Skins"
local currentMP = 0
local selectedItem = nil
local holdConnection = nil

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		if k == "BackgroundColor" then
			inst.BackgroundColor3 = v
		else
			inst[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.BORDER
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addScanline(parent)
	local scan = create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://7357494639", -- Scanline texture
		ImageTransparency = 0.9,
		ImageColor3 = COLORS.TEXT_MAIN,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 0, 0, 4),
		Parent = parent,
		ZIndex = 10
	})
	return scan
end

local function formatNumber(n)
	return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ============================================================================
-- UI LOGIC
-- ============================================================================

function mpShopUI:UpdateMP()
	task.spawn(function()
		local s, points = pcall(function() return getMPFunc:InvokeServer() end)
		if s then
			currentMP = points
			if mainFrame then
				local header = mainFrame:FindFirstChild("Header")
				if header and header:FindFirstChild("PointsDisplay") then
					header.PointsDisplay.Text = "MP_BALANCE: " .. formatNumber(currentMP)
				end
				if selectedItem then
					self:UpdatePurchaseButton(selectedItem)
				end
			end
		end
	end)
end

function mpShopUI:CreateTabs(sidebar)
	local function createTabBtn(name, text)
		local btn = create("TextButton", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = COLORS.BG_ROOT,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		})

		-- Tab Visual: Folder Tab shape
		local tabShape = create("Frame", {
			Size = UDim2.new(1, -10, 1, -4),
			Position = UDim2.new(0, 5, 0, 2),
			BackgroundColor3 = (currentTab == name) and COLORS.TEXT_MAIN or COLORS.BG_PANEL,
			BackgroundTransparency = (currentTab == name) and 0.8 or 1,
			Parent = btn
		})
		addStroke(tabShape, COLORS.TEXT_MAIN, 1)

		local lbl = create("TextLabel", {
			Text = "> " .. text,
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),
			BackgroundTransparency = 1,
			Font = FONTS.Main,
			TextSize = 14,
			TextColor3 = (currentTab == name) and COLORS.TEXT_MAIN or COLORS.TEXT_DIM,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn
		})

		btn.MouseButton1Click:Connect(function()
			if currentTab == name then return end
			currentTab = name
			for _, child in ipairs(sidebar:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			self:CreateTabs(sidebar)
			self:RefreshGrid()
		end)

		btn.Parent = sidebar
	end

	createTabBtn("Skins", "WEAPON_SKINS")
	createTabBtn("Items", "SPECIAL_REQUISITION")
end

function mpShopUI:CreateGridItem(data)
	local btn = create("TextButton", {
		Name = data.Id,
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		BackgroundTransparency = 0.5,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true
	})
	local stroke = addStroke(btn, COLORS.TEXT_DIM, 1)

	-- Grid Line decor
	create("Frame", {Size = UDim2.new(0, 10, 0, 1), Position = UDim2.new(0,0,0,0), BackgroundColor3 = COLORS.TEXT_MAIN, Parent = btn})
	create("Frame", {Size = UDim2.new(0, 1, 0, 10), Position = UDim2.new(0,0,0,0), BackgroundColor3 = COLORS.TEXT_MAIN, Parent = btn})
	create("Frame", {Size = UDim2.new(0, 10, 0, 1), Position = UDim2.new(1,-10,1,-1), BackgroundColor3 = COLORS.TEXT_MAIN, Parent = btn})
	create("Frame", {Size = UDim2.new(0, 1, 0, 10), Position = UDim2.new(1,-1,1,-10), BackgroundColor3 = COLORS.TEXT_MAIN, Parent = btn})

	local icon = create("ImageLabel", {
		Size = UDim2.new(0.6, 0, 0.6, 0),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = data.Icon,
		ImageColor3 = COLORS.TEXT_MAIN,
		ScaleType = Enum.ScaleType.Fit,
		Parent = btn
	})

	local name = create("TextLabel", {
		Text = data.Name:upper(),
		Size = UDim2.new(1, -10, 0, 15),
		Position = UDim2.new(0, 5, 0.75, 0),
		BackgroundTransparency = 1,
		Font = FONTS.Main,
		TextSize = 11,
		TextColor3 = COLORS.TEXT_MAIN,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn
	})

	local cost = create("TextLabel", {
		Text = formatNumber(data.Cost) .. " MP",
		Size = UDim2.new(1, -10, 0, 15),
		Position = UDim2.new(0, 5, 0.88, 0),
		BackgroundTransparency = 1,
		Font = FONTS.Main,
		TextSize = 10,
		TextColor3 = COLORS.TEXT_DIM,
		Parent = btn
	})

	if data.Owned then
		cost.Text = "[ OWNED ]"
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.TEXT_MAIN}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
	end)

	btn.MouseLeave:Connect(function()
		if selectedItem and selectedItem.Id == data.Id then return end
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.TEXT_DIM}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		self:SelectItem(data)
	end)

	return btn
end

function mpShopUI:RefreshGrid()
	for _, c in ipairs(gridContainer:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local items = {}

	if currentTab == "Skins" then
		for weaponName, weaponData in pairs(WeaponModule.Weapons) do
			for skinName, skinData in pairs(weaponData.Skins) do
				if skinData.MPCost and skinData.MPCost > 0 then
					table.insert(items, {
						Id = weaponName .. "_" .. skinName,
						Type = "Skin",
						Name = skinName,
						SubText = weaponName,
						Cost = skinData.MPCost,
						Icon = skinData.TextureId or "rbxassetid://0",
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
				SubText = "Special",
				Cost = itemData.MPCost,
				Icon = itemData.Icon,
				Description = itemData.Description,
				Owned = false
			})
		end
	end

	table.sort(items, function(a, b) return a.Cost < b.Cost end)

	for _, item in ipairs(items) do
		local card = self:CreateGridItem(item)
		card.Parent = gridContainer
	end

	self:SelectItem(nil)
end

function mpShopUI:SelectItem(data)
	selectedItem = data

	for _, btn in ipairs(gridContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			local isSel = data and (btn.Name == data.Id)
			local stroke = btn:FindFirstChild("UIStroke")

			if isSel then
				stroke.Color = COLORS.TEXT_MAIN
				stroke.Thickness = 2
				btn.BackgroundTransparency = 0.2
			else
				stroke.Color = COLORS.TEXT_DIM
				stroke.Thickness = 1
				btn.BackgroundTransparency = 0.5
			end
		end
	end

	if not data then
		detailContainer.Visible = false
		return
	end
	detailContainer.Visible = true

	local content = detailContainer.Content
	content.Header.Title.Text = data.Name:upper()
	content.Header.Subtitle.Text = "REF: " .. data.SubText:upper()

	local desc = ""
	if data.Type == "Skin" then
		desc = string.format("DESIGNATION: %s Skin\nWEAPON: %s\n\nPRICE: %s MP\nSTATUS: AVAILABLE", data.Name, data.Weapon, formatNumber(data.Cost))
	else
		desc = data.Description .. "\n\nPRICE: " .. formatNumber(data.Cost) .. " MP"
	end
	content.DescContainer.DescLabel.Text = desc

	-- Typewriter effect for desc
	content.DescContainer.DescLabel.MaxVisibleGraphemes = 0
	TweenService:Create(content.DescContainer.DescLabel, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {MaxVisibleGraphemes = #desc}):Play()

	local previewFrame = content.PreviewFrame
	if activePreview then ModelPreviewModule.destroy(activePreview) activePreview = nil end

	if data.Type == "Skin" and data.Data then
		previewFrame.Viewport.Visible = true
		previewFrame.Image.Visible = false

		local weaponDef = WeaponModule.Weapons[data.Weapon]
		activePreview = ModelPreviewModule.create(previewFrame.Viewport, weaponDef, data.Data)
		ModelPreviewModule.startRotation(activePreview, 2)
	else
		previewFrame.Viewport.Visible = false
		previewFrame.Image.Visible = true
		previewFrame.Image.Image = data.Icon
	end

	self:UpdatePurchaseButton(data)
end

function mpShopUI:UpdatePurchaseButton(data)
	local btn = detailContainer.Content.BuyButton
	local bar = btn.ProgressBar
	local label = btn.Label

	if holdConnection then holdConnection:Disconnect() holdConnection = nil end
	bar.Size = UDim2.new(0, 0, 1, 0)

	if data.Type == "Skin" and data.Owned then
		label.Text = "ACQUIRED"
		btn.BackgroundColor3 = COLORS.BG_PANEL
		btn.AutoButtonColor = false
		return
	end

	if currentMP < data.Cost then
		label.Text = "INSUFFICIENT_MP"
		btn.BackgroundColor3 = COLORS.ACCENT_ALERT
		btn.AutoButtonColor = false
		return
	end

	label.Text = "AUTHORIZE_PURCHASE"
	btn.BackgroundColor3 = COLORS.TEXT_MAIN
	btn.AutoButtonColor = true
end

function mpShopUI:PerformPurchase(item)
	-- No hold, instant buy for tactical feel
	local btn = detailContainer.Content.BuyButton
	btn.Label.Text = "AUTHORIZING..."
	btn.BackgroundColor3 = COLORS.TEXT_DIM

	local result
	if item.Type == "Skin" then
		result = purchaseSkinFunc:InvokeServer(item.Weapon, item.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(item.Id)
	end

	if result.Success then
		btn.Label.Text = "APPROVED"
		btn.BackgroundColor3 = COLORS.TEXT_MAIN
		task.wait(1)
		if item.Type == "Skin" then item.Owned = true end
		self:RefreshGrid()
		self:SelectItem(item)
	else
		btn.Label.Text = "DENIED"
		btn.BackgroundColor3 = COLORS.ACCENT_ALERT
		task.wait(1.5)
		self:UpdatePurchaseButton(item)
	end
	self:UpdateMP()
end

-- ============================================================================
-- UI CONSTRUCTION
-- ============================================================================

function mpShopUI:CreateUI()
	if playerGui:FindFirstChild("MPShopUI") then playerGui.MPShopUI:Destroy() end

	screenGui = create("ScreenGui", {
		Name = "MPShopUI",
		Parent = playerGui,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Enabled = false
	})

	-- Background with Grid
	local bg = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BackgroundTransparency = 0.1,
		Parent = screenGui
	})
	-- Grid lines
	local grid = create("ImageLabel", {
		Size = UDim2.new(1,0,1,0),
		Image = "rbxassetid://4801088331",
		ImageColor3 = COLORS.TEXT_MAIN,
		ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 32, 0, 32),
		BackgroundTransparency = 1,
		Parent = bg
	})
	addScanline(bg)

	mainFrame = create("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, 900, 0, 600),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = screenGui
	})

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = COLORS.BG_PANEL,
		BackgroundTransparency = 0.2,
		Parent = mainFrame
	})
	addStroke(header, COLORS.TEXT_MAIN, 1)

	create("TextLabel", {
		Text = "MISSION_CONTROL // PROCUREMENT",
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Font = FONTS.Header,
		TextSize = 24,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header
	})

	create("TextLabel", {
		Name = "PointsDisplay",
		Text = "MP_BALANCE: 0",
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = FONTS.Main,
		TextSize = 18,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header
	})

	local closeBtn = create("TextButton", {
		Text = "[ X ]",
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(1, -50, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.ACCENT_ALERT,
		Font = FONTS.Main,
		TextSize = 18,
		Parent = header
	})
	closeBtn.MouseButton1Click:Connect(function() self:Toggle(false) end)

	local body = create("Frame", {
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = mainFrame
	})

	-- LEFT: Sidebar
	local sidebar = create("Frame", {
		Size = UDim2.new(0, 220, 1, 0),
		BackgroundTransparency = 1,
		Parent = body
	})
	create("UIListLayout", {Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sidebar})
	self:CreateTabs(sidebar)

	-- CENTER: Grid
	local gridArea = create("Frame", {
		Size = UDim2.new(1, -540, 1, 0),
		Position = UDim2.new(0, 230, 0, 0),
		BackgroundTransparency = 1,
		Parent = body
	})

	gridContainer = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.TEXT_MAIN,
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = gridArea
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0, 100, 0, 120),
		CellPadding = UDim2.new(0, 10, 0, 10),
		Parent = gridContainer
	})

	-- RIGHT: Details (Dossier)
	detailContainer = create("Frame", {
		Name = "DetailContainer",
		Size = UDim2.new(0, 300, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		BackgroundTransparency = 0.1,
		Parent = body,
		Visible = false
	})
	addStroke(detailContainer, COLORS.TEXT_MAIN, 1)

	local content = create("Frame", { Name = "Content", Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, Parent = detailContainer })

	local dHeader = create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = content })
	create("TextLabel", { Name = "Title", Text = "ITEM", Size = UDim2.new(1, 0, 0, 20), Font = FONTS.Header, TextSize = 18, TextColor3 = COLORS.TEXT_MAIN, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = dHeader })
	create("TextLabel", { Name = "Subtitle", Text = "SUB", Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0,0,0,25), Font = FONTS.Main, TextSize = 12, TextColor3 = COLORS.TEXT_DIM, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = dHeader })

	local pFrame = create("Frame", { Name = "PreviewFrame", Size = UDim2.new(1, 0, 0, 200), Position = UDim2.new(0, 0, 0, 60), BackgroundColor3 = COLORS.BG_ROOT, Parent = content })
	addStroke(pFrame, COLORS.TEXT_DIM, 1)
	create("ViewportFrame", {Name = "Viewport", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Parent = pFrame})
	create("ImageLabel", {Name = "Image", Size = UDim2.new(0.8,0,0.8,0), Position = UDim2.new(0.1,0,0.1,0), BackgroundTransparency = 1, ImageColor3 = COLORS.TEXT_MAIN, ScaleType = Enum.ScaleType.Fit, Parent = pFrame})

	local descBox = create("Frame", { Name = "DescContainer", Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 270), BackgroundTransparency = 1, Parent = content })
	create("TextLabel", { Name = "DescLabel", Text = "...", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = FONTS.Main, TextSize = 12, TextColor3 = COLORS.TEXT_MAIN, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = descBox })

	local buyBtn = create("TextButton", {
		Name = "BuyButton",
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -40),
		BackgroundColor3 = COLORS.TEXT_MAIN,
		Text = "AUTHORIZE",
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = COLORS.BG_ROOT,
		Parent = content
	})
	create("Frame", {Name="ProgressBar", Parent=buyBtn}) -- Placeholder to avoid error
	create("TextLabel", {Name="Label", Parent=buyBtn, Text=""}) -- Placeholder

	-- Wire button manually since layout changed
	buyBtn.MouseButton1Click:Connect(function()
		if selectedItem then self:PerformPurchase(selectedItem) end
	end)
end

function mpShopUI:Toggle(state)
	if not screenGui then self:CreateUI() end
	local blur = game.Lighting:FindFirstChild("MPShopBlur") or Instance.new("BlurEffect", game.Lighting)
	blur.Name = "MPShopBlur"
	blur.Size = 0

	if state then
		self:UpdateMP()
		self:RefreshGrid()
		screenGui.Enabled = true
		mainFrame.Visible = true
		mainFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 24}):Play()
	else
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
		mainFrame.Visible = false
		screenGui.Enabled = false
		if activePreview then ModelPreviewModule.destroy(activePreview) activePreview = nil end
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

mpChangedEvent.OnClientEvent:Connect(function(newMP)
	currentMP = newMP
	if mainFrame and screenGui.Enabled then
		-- Update text
		local h = mainFrame:FindFirstChild("Header")
		if h then h.PointsDisplay.Text = "MP_BALANCE: " .. formatNumber(newMP) end
		if selectedItem then mpShopUI:UpdatePurchaseButton(selectedItem) end
	end
end)

local function setupPrompt()
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment", 10)
	if not lobbyEnv then return end

	local shopPart = lobbyEnv:WaitForChild("MPShop", 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if screenGui.Enabled then
					mpShopUI:Toggle(false)
				else
					mpShopUI:Toggle(true)
				end
			end)
		end
	end
end

task.spawn(setupPrompt)

mpShopUI:CreateUI()

return mpShopUI
