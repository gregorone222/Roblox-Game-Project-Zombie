-- MPShopUI.lua (LocalScript)
-- Path: StarterGui/MPShopUI.lua
-- Script Place: Lobby
-- Theme: Modern Slate (Dark Blue-Grey) & Cyan (Mission Points)
-- Redesigned for better UX/UI

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
		Description = "Gandakan perolehan XP Anda dari semua sumber selama 30 menit.",
		MPCost = 2000,
		Icon = "rbxassetid://11419722678"
	},
	COIN_BOOSTER_1GAME = {
		ID = "COIN_BOOSTER_1GAME",
		Name = "Coin Booster (1 Game)",
		Description = "Tingkatkan perolehan Koin Anda sebesar 50% untuk satu permainan berikutnya.",
		MPCost = 3000,
		Icon = "rbxassetid://11419708237"
	},
	DAILY_MISSION_REROLL = {
		ID = "DAILY_MISSION_REROLL",
		Name = "Daily Mission Reroll",
		Description = "Ganti salah satu misi harian Anda saat ini dengan yang baru secara acak.",
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
	BG_ROOT = Color3.fromRGB(15, 23, 42),    -- Slate 900
	BG_PANEL = Color3.fromRGB(30, 41, 59),   -- Slate 800
	BG_HOVER = Color3.fromRGB(51, 65, 85),   -- Slate 700
	ACCENT = Color3.fromRGB(6, 182, 212),    -- Cyan 500
	ACCENT_DIM = Color3.fromRGB(21, 94, 117),-- Cyan 900
	TEXT_MAIN = Color3.fromRGB(241, 245, 249),
	TEXT_SUB = Color3.fromRGB(148, 163, 184),
	BORDER = Color3.fromRGB(71, 85, 105),    -- Slate 600
	SUCCESS = Color3.fromRGB(34, 197, 94),
	ERROR = Color3.fromRGB(239, 68, 68),
}

local mpShopUI = {}

-- UI References
local screenGui = nil
local mainFrame = nil
local gridContainer = nil
local detailContainer = nil
local activePreview = nil

-- State
local currentTab = "Skins" -- "Skins", "Items"
local currentMP = 0
local selectedItem = nil
local holdConnection = nil

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function create(className, props, children)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
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

local function addPadding(parent, x, y)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, x or 0)
	pad.PaddingRight = UDim.new(0, x or 0)
	pad.PaddingTop = UDim.new(0, y or 0)
	pad.PaddingBottom = UDim.new(0, y or 0)
	pad.Parent = parent
	return pad
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
				-- Navigate carefully to avoid errors if structure changed
				local header = mainFrame:FindFirstChild("Header")
				if header then
					local badge = header:FindFirstChild("MPBadge")
					if badge then
						local lbl = badge:FindFirstChild("MPLabel")
						if lbl then lbl.Text = formatNumber(currentMP) end
					end
				end

				if selectedItem then
					self:UpdatePurchaseButton(selectedItem)
				end
			end
		end
	end)
end

function mpShopUI:CreateTabs(sidebar)
	local function createTabBtn(name, text, iconId)
		local btn = create("TextButton", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundColor3 = COLORS.BG_ROOT,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		})

		local content = create("Frame", {
			Size = UDim2.new(1, -20, 1, -10),
			Position = UDim2.new(0, 10, 0, 5),
			BackgroundColor3 = (currentTab == name) and COLORS.BG_HOVER or COLORS.BG_ROOT,
			BackgroundTransparency = (currentTab == name) and 0 or 1,
		}, {
			addCorner(btn, 8) -- Corner attached to btn for shape
		})
		addCorner(content, 8)
		content.Parent = btn

		local icon = create("ImageLabel", {
			Image = iconId,
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			ImageColor3 = (currentTab == name) and COLORS.ACCENT or COLORS.TEXT_SUB,
			Parent = content
		})

		local lbl = create("TextLabel", {
			Text = text,
			Size = UDim2.new(1, -50, 1, 0),
			Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = (currentTab == name) and COLORS.TEXT_MAIN or COLORS.TEXT_SUB,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = content
		})

		btn.MouseEnter:Connect(function()
			if currentTab ~= name then
				TweenService:Create(content, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
				TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = COLORS.TEXT_MAIN}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if currentTab ~= name then
				TweenService:Create(content, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = COLORS.TEXT_SUB}):Play()
			end
		end)

		btn.MouseButton1Click:Connect(function()
			if currentTab == name then return end
			currentTab = name
			-- Re-render sidebar to update active state
			for _, child in ipairs(sidebar:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			self:CreateTabs(sidebar) 
			self:RefreshGrid()
		end)

		btn.Parent = sidebar
	end

	createTabBtn("Skins", "Weapon Skins", "rbxassetid://11422142913") 
	createTabBtn("Items", "Special Items", "rbxassetid://11422155687") 
end

function mpShopUI:CreateGridItem(data)
	local btn = create("TextButton", {
		Name = data.Id,
		Size = UDim2.new(0, 0, 0, 0), 
		BackgroundColor3 = COLORS.BG_PANEL,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true
	})
	addCorner(btn, 10)
	local stroke = addStroke(btn, COLORS.BORDER, 1)

	local bgPattern = create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxassetid://13065783540", 
		ImageTransparency = 0.95,
		ImageColor3 = COLORS.ACCENT,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 50, 0, 50),
		Parent = btn
	})

	local icon = create("ImageLabel", {
		Size = UDim2.new(0.7, 0, 0.7, 0),
		Position = UDim2.new(0.5, 0, 0.4, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Image = data.Icon,
		ScaleType = Enum.ScaleType.Fit,
		Parent = btn
	})

	local name = create("TextLabel", {
		Text = data.Name,
		Size = UDim2.new(1, -10, 0, 20),
		Position = UDim2.new(0, 5, 0.75, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = COLORS.TEXT_MAIN,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn
	})

	local cost = create("TextLabel", {
		Text = formatNumber(data.Cost),
		Size = UDim2.new(1, -10, 0, 15),
		Position = UDim2.new(0, 5, 0.88, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = COLORS.ACCENT,
		Parent = btn
	})

	if data.Owned then
		cost.Text = "OWNED"
		cost.TextColor3 = COLORS.SUCCESS
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BG_HOVER}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.ACCENT}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), {Size = UDim2.new(0.8, 0, 0.8, 0)}):Play()
	end)

	btn.MouseLeave:Connect(function()
		if selectedItem and selectedItem.Id == data.Id then return end
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BG_PANEL}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.BORDER}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), {Size = UDim2.new(0.7, 0, 0.7, 0)}):Play()
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
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BG_HOVER}):Play()
				TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.ACCENT, Thickness = 2}):Play()
			else
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BG_PANEL}):Play()
				TweenService:Create(stroke, TweenInfo.new(0.2), {Color = COLORS.BORDER, Thickness = 1}):Play()
			end
		end
	end

	if not data then
		detailContainer.Empty.Visible = true
		detailContainer.Content.Visible = false
		return
	end

	detailContainer.Empty.Visible = false
	detailContainer.Content.Visible = true

	local content = detailContainer.Content
	content.Header.Title.Text = data.Name
	content.Header.Subtitle.Text = data.SubText

	local desc = ""
	if data.Type == "Skin" then
		desc = string.format("A premium skin for the %s. Can be equipped in the Inventory.\n\nPrice: %s MP", data.Weapon, formatNumber(data.Cost))
	else
		desc = data.Description .. "\n\nPrice: " .. formatNumber(data.Cost) .. " MP"
	end
	content.DescContainer.DescLabel.Text = desc

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
		label.Text = "OWNED"
		btn.BackgroundColor3 = COLORS.BG_PANEL
		btn.AutoButtonColor = false
		return
	end

	if currentMP < data.Cost then
		label.Text = "INSUFFICIENT MP"
		btn.BackgroundColor3 = COLORS.ERROR
		btn.AutoButtonColor = false
		return
	end

	label.Text = "HOLD TO BUY (" .. formatNumber(data.Cost) .. ")"
	btn.BackgroundColor3 = COLORS.ACCENT
	btn.AutoButtonColor = true

	local isHolding = false
	local holdTime = 0
	local REQUIRED_HOLD = 1.0

	btn.MouseButton1Down:Connect(function()
		if currentMP < data.Cost then return end
		isHolding = true
		holdTime = 0

		holdConnection = RunService.Heartbeat:Connect(function(dt)
			if not isHolding then return end
			holdTime = holdTime + dt
			local pct = math.clamp(holdTime / REQUIRED_HOLD, 0, 1)
			bar.Size = UDim2.new(pct, 0, 1, 0)

			if holdTime >= REQUIRED_HOLD then
				isHolding = false
				if holdConnection then holdConnection:Disconnect() end
				self:PerformPurchase(data)
			end
		end)
	end)

	local function cancelHold()
		isHolding = false
		if holdConnection then holdConnection:Disconnect() end
		TweenService:Create(bar, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	end

	btn.MouseButton1Up:Connect(cancelHold)
	btn.MouseLeave:Connect(cancelHold)
end

function mpShopUI:PerformPurchase(item)
	local btn = detailContainer.Content.BuyButton
	btn.Label.Text = "PROCESSING..."

	local result
	if item.Type == "Skin" then
		result = purchaseSkinFunc:InvokeServer(item.Weapon, item.SkinName)
	else
		result = purchaseItemFunc:InvokeServer(item.Id)
	end

	if result.Success then
		btn.Label.Text = "SUCCESS!"
		btn.BackgroundColor3 = COLORS.SUCCESS
		task.wait(1)
		if item.Type == "Skin" then item.Owned = true end 
		self:RefreshGrid()
		self:SelectItem(item)
	else
		btn.Label.Text = "FAILED: " .. tostring(result.Reason)
		btn.BackgroundColor3 = COLORS.ERROR
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

	local blur = Instance.new("BlurEffect", game.Lighting)
	blur.Size = 0
	blur.Name = "MPShopBlur"

	mainFrame = create("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, 900, 0, 600),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui
	}, {
		addCorner(nil, 12),
		addStroke(nil, COLORS.BORDER, 2)
	})

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = mainFrame
	})

	create("TextLabel", {
		Text = "MISSION SHOP",
		Size = UDim2.new(0, 200, 1, 0),
		Position = UDim2.new(0, 24, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header
	})

	local mpBadge = create("Frame", {
		Name = "MPBadge",
		Size = UDim2.new(0, 140, 0, 36),
		Position = UDim2.new(1, -80, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = header
	}, {
		addCorner(nil, 18),
		addStroke(nil, COLORS.ACCENT_DIM, 1)
	})

	create("ImageLabel", {
		Image = "rbxassetid://11419717444", 
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ImageColor3 = COLORS.ACCENT,
		Parent = mpBadge
	})

	create("TextLabel", {
		Name = "MPLabel",
		Text = "0",
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 36, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = COLORS.ACCENT,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = mpBadge
	})

	local closeBtn = create("TextButton", {
		Text = "?",
		Size = UDim2.new(0, 40, 0, 40),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -20, 0.5, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.TEXT_SUB,
		TextSize = 20,
		Font = Enum.Font.GothamBold,
		Parent = header
	})
	closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = COLORS.ERROR end)
	closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = COLORS.TEXT_SUB end)
	closeBtn.MouseButton1Click:Connect(function() self:Toggle(false) end)

	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = COLORS.BORDER,
		Parent = header
	})

	local body = create("Frame", {
		Size = UDim2.new(1, 0, 1, -60),
		Position = UDim2.new(0, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = mainFrame
	})

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 200, 1, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = body
	}, {
		create("UIListLayout", {Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center}),
		addPadding(nil, 0, 20)
	})

	create("Frame", { 
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = COLORS.BORDER,
		Parent = sidebar
	})

	self:CreateTabs(sidebar)

	local middle = create("Frame", {
		Name = "GridArea",
		Size = UDim2.new(1, -500, 1, 0), 
		Position = UDim2.new(0, 200, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = body
	})

	gridContainer = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.BORDER,
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = middle
	}, {
		addPadding(nil, 20, 20),
		create("UIGridLayout", {
			CellSize = UDim2.new(0, 110, 0, 140),
			CellPadding = UDim2.new(0, 15, 0, 15),
			SortOrder = Enum.SortOrder.LayoutOrder
		})
	})

	detailContainer = create("Frame", {
		Name = "Details",
		Size = UDim2.new(0, 300, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = body
	})

	create("Frame", { 
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = COLORS.BORDER,
		Parent = detailContainer
	})

	create("Frame", {
		Name = "Empty",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = detailContainer
	}, {
		create("TextLabel", {
			Text = "Select an item to view details",
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.new(0, 20, 0, 0),
			BackgroundTransparency = 1,
			TextColor3 = COLORS.TEXT_SUB,
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextWrapped = true
		})
	})

	local content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = detailContainer
	}, {
		addPadding(nil, 20, 20)
	})

	local detHeader = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		Parent = content
	})

	create("TextLabel", {
		Name = "Title",
		Text = "Item Name",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.TEXT_MAIN,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = detHeader
	})

	create("TextLabel", {
		Name = "Subtitle",
		Text = "Item Subtype",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 30),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.ACCENT,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = detHeader
	})

	local prevFrame = create("Frame", {
		Name = "PreviewFrame",
		Size = UDim2.new(1, 0, 0, 200),
		Position = UDim2.new(0, 0, 0, 70),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = content
	}, {
		addCorner(nil, 8),
		addStroke(nil, COLORS.BORDER, 1)
	})

	create("ViewportFrame", {Name = "Viewport", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Parent = prevFrame})
	create("ImageLabel", {Name = "Image", Size = UDim2.new(0.8,0,0.8,0), Position = UDim2.new(0.1,0,0.1,0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Parent = prevFrame})

	local descCont = create("ScrollingFrame", {
		Name = "DescContainer",
		Size = UDim2.new(1, 0, 1, -350), 
		Position = UDim2.new(0, 0, 0, 290),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		CanvasSize = UDim2.new(0,0,0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = content
	})

	create("TextLabel", {
		Name = "DescLabel",
		Text = "Description...",
		Size = UDim2.new(1, -5, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.TEXT_SUB,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = descCont
	})

	local buyBtn = create("TextButton", {
		Name = "BuyButton",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.new(0, 0, 1, -50),
		BackgroundColor3 = COLORS.ACCENT,
		AutoButtonColor = true,
		Text = "",
		Parent = content
	}, {
		addCorner(nil, 8)
	})

	create("Frame", { 
		Name = "ProgressBar",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1,1,1),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = buyBtn
	})

	create("TextLabel", {
		Name = "Label",
		Text = "BUY",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = COLORS.BG_ROOT,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		Parent = buyBtn
	})
end

function mpShopUI:Toggle(state)
	if not screenGui then self:CreateUI() end

	local blur = game.Lighting:FindFirstChild("MPShopBlur")

	if state then
		self:UpdateMP()
		self:RefreshGrid()
		screenGui.Enabled = true
		mainFrame.Size = UDim2.new(0, 850, 0, 550)
		mainFrame.BackgroundTransparency = 1
		TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 900, 0, 600), BackgroundTransparency = 0}):Play()
		if blur then TweenService:Create(blur, TweenInfo.new(0.5), {Size = 16}):Play() end
	else
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 850, 0, 550), BackgroundTransparency = 1}):Play()
		if blur then TweenService:Create(blur, TweenInfo.new(0.3), {Size = 0}):Play() end
		task.delay(0.3, function()
			screenGui.Enabled = false
			if activePreview then ModelPreviewModule.destroy(activePreview) activePreview = nil end
		end)
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function connectPrompt()
	local shopPart = Workspace:WaitForChild("Shop", 10)
	if not shopPart then return end
	local mpShopPart = shopPart:WaitForChild("MPShop", 10)
	if not mpShopPart then return end

	local prompt = mpShopPart:WaitForChild("ProximityPrompt", 10)
	if prompt then
		if mpShopUI._promptConnection then mpShopUI._promptConnection:Disconnect() end

		mpShopUI._promptConnection = prompt.Triggered:Connect(function(plr)
			if plr == player then
				mpShopUI:Toggle(true)
			end
		end)
	end
end

mpChangedEvent.OnClientEvent:Connect(function(newMP)
	currentMP = newMP
	if mainFrame and screenGui.Enabled then
		mainFrame.Header.MPBadge.MPLabel.Text = formatNumber(newMP)
		if selectedItem then mpShopUI:UpdatePurchaseButton(selectedItem) end
	end
end)

task.spawn(connectPrompt)
mpShopUI:CreateUI()

return mpShopUI
