-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- AchievementUI.local.luau (LocalScript)
-- Path: StarterGui/UI/AchievementUI.local.luau
-- Script Place: Lobby
-- Theme: Apocalypse Survival (Matching InventoryUI)
-- Compliant with rules.md (Scale-based, TextScaled, English only)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

-- Forward declaration
local initialize

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),
		Panel = Color3.fromRGB(35, 28, 22),
		PanelGlass = Color3.fromRGB(45, 38, 30),
		AccentMain = Color3.fromRGB(218, 165, 32),
		AccentSec = Color3.fromRGB(139, 90, 43),
		TextHigh = Color3.fromRGB(255, 248, 230),
		TextMid = Color3.fromRGB(180, 160, 130),
		TextLow = Color3.fromRGB(100, 85, 65),
		Success = Color3.fromRGB(46, 204, 113),
		Error = Color3.fromRGB(231, 76, 60),
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
	}
}

-- ================== STATE ==================
local state = {
	allAchievements = {},
	categorized = {},
	currentCategory = "All",
	currentCategoryButton = nil,
	blurEffect = nil
}

-- Adaptive Text Sizing (Mobile: 12-20, Desktop: 20-32)
local IS_MOBILE = UserInputService.TouchEnabled
local TEXT_MIN = IS_MOBILE and 12 or 20
local TEXT_MAX = IS_MOBILE and 20 or 32

-- ================== HELPERS ==================
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius or 8) })
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {
		Parent = parent,
		Color = color or THEME.Colors.AccentMain,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

-- ================== UI CONSTRUCTION ==================
local screenGui = create("ScreenGui", {
	Name = "AchievementUI",
	Parent = playerGui,
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})

-- BlurEffect (NO dark overlay per rules.md)
state.blurEffect = create("BlurEffect", {
	Name = "AchievementBlur",
	Parent = workspace.CurrentCamera,
	Size = 0,
	Enabled = false
})

-- Main Container (Scale-based)
local mainContainer = create("CanvasGroup", {
	Name = "MainContainer",
	Parent = screenGui,
	Size = UDim2.fromScale(0.75, 0.8),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.02,
	GroupTransparency = 1,
	Visible = false
})
addCorner(mainContainer, 12)
addStroke(mainContainer, THEME.Colors.AccentMain)

-- Header
local header = create("Frame", {
	Parent = mainContainer,
	Size = UDim2.fromScale(1, 0.1),
	BackgroundColor3 = THEME.Colors.Panel,
	BorderSizePixel = 0
})
addCorner(header, 12)

-- Golden accent line
create("Frame", {
	Parent = header,
	Size = UDim2.new(0.98, 0, 0, 3),
	Position = UDim2.new(0.01, 0, 1, -3),
	BackgroundColor3 = THEME.Colors.AccentMain,
	BorderSizePixel = 0
})

local titleLabel = create("TextLabel", {
	Parent = header,
	Text = "🏆 ACHIEVEMENTS",
	Size = UDim2.fromScale(0.5, 0.8),
	Position = UDim2.fromScale(0.03, 0.1),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = THEME.Fonts.Header,
	TextScaled = true,
	TextColor3 = THEME.Colors.AccentMain
})
create("UITextSizeConstraint", { Parent = titleLabel, MaxTextSize = 28 })

local closeBtn = create("TextButton", {
	Parent = header,
	Size = UDim2.fromScale(0.05, 0.6),
	Position = UDim2.fromScale(0.97, 0.5),
	AnchorPoint = Vector2.new(1, 0.5),
	BackgroundColor3 = THEME.Colors.Error,
	Text = "✕",
	Font = THEME.Fonts.Header,
	TextColor3 = THEME.Colors.TextHigh,
	TextScaled = true
})
create("UIAspectRatioConstraint", { Parent = closeBtn, AspectRatio = 1 })
addCorner(closeBtn, 6)

-- Categories Sidebar
local sidebar = create("Frame", {
	Parent = mainContainer,
	Size = UDim2.fromScale(0.22, 0.88),
	Position = UDim2.fromScale(0.01, 0.11),
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.3
})
addCorner(sidebar, 8)

-- Search Box
local searchBox = create("TextBox", {
	Parent = sidebar,
	Size = UDim2.fromScale(0.9, 0.08),
	Position = UDim2.fromScale(0.05, 0.02),
	BackgroundColor3 = THEME.Colors.Background,
	Text = "",
	PlaceholderText = "Search...",
	PlaceholderColor3 = THEME.Colors.TextLow,
	TextColor3 = THEME.Colors.TextHigh,
	Font = THEME.Fonts.Body,
	TextScaled = true,
	ClearTextOnFocus = false
})
addCorner(searchBox, 6)
create("UITextSizeConstraint", { Parent = searchBox, MaxTextSize = 16 })

-- Category List
local categoryList = create("ScrollingFrame", {
	Parent = sidebar,
	Size = UDim2.fromScale(0.9, 0.85),
	Position = UDim2.fromScale(0.05, 0.12),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.Colors.AccentSec,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0)
})
create("UIListLayout", { Parent = categoryList, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder })

-- Achievements List
local achievementsList = create("ScrollingFrame", {
	Parent = mainContainer,
	Size = UDim2.fromScale(0.75, 0.88),
	Position = UDim2.fromScale(0.24, 0.11),
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.5,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = THEME.Colors.AccentMain,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0)
})
addCorner(achievementsList, 8)
create("UIListLayout", { Parent = achievementsList, Padding = UDim.new(0.01, 0), SortOrder = Enum.SortOrder.LayoutOrder })
create("UIPadding", { Parent = achievementsList, PaddingTop = UDim.new(0.01, 0), PaddingLeft = UDim.new(0.01, 0), PaddingRight = UDim.new(0.01, 0) })

-- ================== COMPONENT BUILDERS ==================

local function createCategoryButton(name, layoutOrder)
	local displayName = name == "All" and "All" or name
	local btn = create("TextButton", {
		Name = name,
		Parent = categoryList,
		Size = UDim2.fromScale(1, 0.12),
		BackgroundColor3 = THEME.Colors.Background,
		AutoButtonColor = false,
		Text = displayName:upper(),
		Font = THEME.Fonts.Body,
		TextScaled = true,
		TextColor3 = THEME.Colors.TextMid,
		LayoutOrder = layoutOrder or 1
	})
	addCorner(btn, 4)
	create("UITextSizeConstraint", { Parent = btn, MaxTextSize = 16 })
	
	local marker = create("Frame", {
		Name = "Marker",
		Parent = btn,
		Size = UDim2.fromScale(0.03, 0.8),
		Position = UDim2.fromScale(0, 0.1),
		BackgroundColor3 = THEME.Colors.AccentMain,
		Visible = false
	})
	addCorner(marker, 2)
	
	return btn, marker
end

local function createAchievementCard(data)
	local card = create("Frame", {
		Name = "Card_" .. (data.Id or data.Name),
		Parent = achievementsList,
		Size = UDim2.fromScale(0.98, 0.12),
		BackgroundColor3 = THEME.Colors.PanelGlass,
		BorderSizePixel = 0
	})
	addCorner(card, 6)
	
	local borderColor = data.Completed and THEME.Colors.Success or THEME.Colors.TextLow
	addStroke(card, borderColor, 1)
	
	-- Status Icon
	local statusIcon = create("TextLabel", {
		Parent = card,
		Size = UDim2.fromScale(0.06, 0.6),
		Position = UDim2.fromScale(0.02, 0.2),
		BackgroundTransparency = 1,
		Text = data.Completed and "✅" or "🔒",
		TextScaled = true
	})
	create("UIAspectRatioConstraint", { Parent = statusIcon, AspectRatio = 1 })
	
	-- Name
	local nameLabel = create("TextLabel", {
		Parent = card,
		Size = UDim2.fromScale(0.5, 0.35),
		Position = UDim2.fromScale(0.1, 0.1),
		BackgroundTransparency = 1,
		Text = data.Name,
		Font = THEME.Fonts.Header,
		TextScaled = true,
		TextColor3 = THEME.Colors.TextHigh,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", { Parent = nameLabel, MaxTextSize = 18 })
	
	-- Description
	local descLabel = create("TextLabel", {
		Parent = card,
		Size = UDim2.fromScale(0.55, 0.25),
		Position = UDim2.fromScale(0.1, 0.45),
		BackgroundTransparency = 1,
		Text = data.Desc or "",
		Font = THEME.Fonts.Body,
		TextScaled = true,
		TextColor3 = THEME.Colors.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true
	})
	create("UITextSizeConstraint", { Parent = descLabel, MaxTextSize = 14 })
	
	-- AP Reward
	local apLabel = create("TextLabel", {
		Parent = card,
		Size = UDim2.fromScale(0.15, 0.3),
		Position = UDim2.fromScale(0.83, 0.1),
		BackgroundTransparency = 1,
		Text = "+" .. tostring(data.APReward or 0) .. " AP",
		Font = THEME.Fonts.Header,
		TextScaled = true,
		TextColor3 = THEME.Colors.AccentMain,
		TextXAlignment = Enum.TextXAlignment.Right
	})
	create("UITextSizeConstraint", { Parent = apLabel, MaxTextSize = 16 })
	
	-- Progress Bar
	local progressBg = create("Frame", {
		Parent = card,
		Size = UDim2.fromScale(0.55, 0.15),
		Position = UDim2.fromScale(0.1, 0.75),
		BackgroundColor3 = THEME.Colors.Background
	})
	addCorner(progressBg, 4)
	
	local progress = (data.Target and data.Target > 0) and math.min(data.Progress / data.Target, 1) or (data.Completed and 1 or 0)
	local progressFill = create("Frame", {
		Parent = progressBg,
		Size = UDim2.fromScale(progress, 1),
		BackgroundColor3 = data.Completed and THEME.Colors.Success or THEME.Colors.AccentMain
	})
	addCorner(progressFill, 4)
	
	local progressText = create("TextLabel", {
		Parent = progressBg,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = string.format("%d / %d", data.Progress or 0, data.Target or 0),
		Font = THEME.Fonts.Body,
		TextScaled = true,
		TextColor3 = THEME.Colors.TextHigh
	})
	create("UITextSizeConstraint", { Parent = progressText, MaxTextSize = 12 })
	
	return card
end

-- ================== LOGIC ==================

local function populateAchievements(searchQuery)
	searchQuery = searchQuery and searchQuery:lower() or ""
	
	-- Clear existing
	for _, child in ipairs(achievementsList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	local toShow = {}
	if state.currentCategory == "All" then
		toShow = state.allAchievements
	else
		toShow = state.categorized[state.currentCategory] or {}
	end
	
	-- Filter by search
	local filtered = {}
	if searchQuery ~= "" then
		for _, ach in ipairs(toShow) do
			if ach.Name:lower():find(searchQuery) then
				table.insert(filtered, ach)
			end
		end
	else
		filtered = toShow
	end
	
	-- Sort: Uncompleted first, then by progress
	table.sort(filtered, function(a, b)
		if a.Completed ~= b.Completed then
			return not a.Completed
		end
		if not a.Completed then
			local pA = (a.Target and a.Target > 0) and a.Progress / a.Target or 0
			local pB = (b.Target and b.Target > 0) and b.Progress / b.Target or 0
			if pA ~= pB then return pA > pB end
		end
		return a.Name < b.Name
	end)
	
	for _, data in ipairs(filtered) do
		createAchievementCard(data)
	end
end

local function setupCategories()
	-- Clear old
	for _, c in ipairs(categoryList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	
	-- Create "All" button
	local allBtn, allMarker = createCategoryButton("All", 0)
	allBtn.BackgroundColor3 = THEME.Colors.Panel
	allBtn.TextColor3 = THEME.Colors.AccentMain
	allMarker.Visible = true
	state.currentCategoryButton = allBtn
	
	allBtn.MouseButton1Click:Connect(function()
		if state.currentCategoryButton then
			state.currentCategoryButton.BackgroundColor3 = THEME.Colors.Background
			state.currentCategoryButton.TextColor3 = THEME.Colors.TextMid
			state.currentCategoryButton.Marker.Visible = false
		end
		allBtn.BackgroundColor3 = THEME.Colors.Panel
		allBtn.TextColor3 = THEME.Colors.AccentMain
		allMarker.Visible = true
		state.currentCategoryButton = allBtn
		state.currentCategory = "All"
		populateAchievements(searchBox.Text)
	end)
	
	-- Create category buttons
	local catNames = {}
	for name in pairs(state.categorized) do
		table.insert(catNames, name)
	end
	table.sort(catNames)
	
	for i, catName in ipairs(catNames) do
		local btn, marker = createCategoryButton(catName, i)
		btn.MouseButton1Click:Connect(function()
			if state.currentCategoryButton then
				state.currentCategoryButton.BackgroundColor3 = THEME.Colors.Background
				state.currentCategoryButton.TextColor3 = THEME.Colors.TextMid
				state.currentCategoryButton.Marker.Visible = false
			end
			btn.BackgroundColor3 = THEME.Colors.Panel
			btn.TextColor3 = THEME.Colors.AccentMain
			marker.Visible = true
			state.currentCategoryButton = btn
			state.currentCategory = catName
			populateAchievements(searchBox.Text)
		end)
	end
end

initialize = function()
	local getAchievements = ReplicatedStorage:WaitForChild("GetAchievementsFunc", 5)
	if getAchievements then
		state.allAchievements = getAchievements:InvokeServer() or {}
	end
	
	-- Group by category
	state.categorized = {}
	for _, data in ipairs(state.allAchievements) do
		local cat = data.Category or "Other"
		if not state.categorized[cat] then
			state.categorized[cat] = {}
		end
		table.insert(state.categorized[cat], data)
	end
	
	setupCategories()
	populateAchievements("")
end

-- ================== TOGGLE ==================

local function toggleUI(visible)
	if visible then
		initialize()
		mainContainer.Visible = true
		state.blurEffect.Enabled = true
		TweenService:Create(state.blurEffect, TweenInfo.new(0.3), { Size = 20 }):Play()
		TweenService:Create(mainContainer, TweenInfo.new(0.3), { GroupTransparency = 0 }):Play()
	else
		TweenService:Create(state.blurEffect, TweenInfo.new(0.3), { Size = 0 }):Play()
		TweenService:Create(mainContainer, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
		task.delay(0.3, function()
			mainContainer.Visible = false
			state.blurEffect.Enabled = false
		end)
	end
end

-- ================== CONNECTIONS ==================

closeBtn.MouseButton1Click:Connect(function()
	toggleUI(false)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	populateAchievements(searchBox.Text)
end)

-- Listen for toggle event from ProfileUI
local bindableEvents = ReplicatedStorage:WaitForChild("BindableEvents", 5)
if bindableEvents then
	local toggleEvent = bindableEvents:WaitForChild("ToggleAchievementUIEvent", 5)
	if toggleEvent then
		toggleEvent.Event:Connect(function(visible)
			toggleUI(visible)
		end)
	end
end

-- Achievement unlock notification
local achievementEvent = ReplicatedStorage:WaitForChild("AchievementUnlocked", 5)
if achievementEvent then
	achievementEvent.OnClientEvent:Connect(function(achievement)
		-- Simple notification (no overlay, just top banner)
		local notif = create("Frame", {
			Parent = screenGui,
			Size = UDim2.fromScale(0.3, 0.08),
			Position = UDim2.fromScale(0.5, -0.1),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = THEME.Colors.Panel
		})
		addCorner(notif, 8)
		addStroke(notif, THEME.Colors.Success, 2)
		
		create("TextLabel", {
			Parent = notif,
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromScale(0, 0.05),
			BackgroundTransparency = 1,
			Text = "ACHIEVEMENT UNLOCKED",
			Font = THEME.Fonts.Header,
			TextScaled = true,
			TextColor3 = THEME.Colors.Success
		})
		
		create("TextLabel", {
			Parent = notif,
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromScale(0, 0.5),
			BackgroundTransparency = 1,
			Text = string.format("%s (+%d AP)", achievement.Name, achievement.APReward or 0),
			Font = THEME.Fonts.Body,
			TextScaled = true,
			TextColor3 = THEME.Colors.TextHigh
		})
		
		-- Animate in
		TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.05) }):Play()
		task.wait(4)
		TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, -0.1) }):Play()
		task.delay(0.5, function() notif:Destroy() end)
		
		if mainContainer.Visible then
			initialize()
		end
	end)
end