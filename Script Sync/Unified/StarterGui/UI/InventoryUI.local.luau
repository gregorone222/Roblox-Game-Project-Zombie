-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Theme: "Apocalypse Survival" (Gritty/Amber)
-- Compliant with Rule.md (Scale-based, Mobile Support)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- --- MODULES & REMOTES ---
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
local inventoryRemote = RemoteFunctions and RemoteFunctions:WaitForChild("GetInventoryData", 5)

-- --- THEME CONSTANTS (Matching UI Master Guide - Makeshift Survivor Camp) ---
local THEME = {
	Colors = {
		-- Core Colors
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel = Color3.fromRGB(35, 28, 22),           -- Warm brown panel
		PanelGlass = Color3.fromRGB(45, 38, 30),      -- Lighter warm brown
		
		-- Accent Colors
		AccentMain = Color3.fromRGB(218, 165, 32),    -- Golden (Sunset Orange)
		AccentSec = Color3.fromRGB(139, 90, 43),      -- Forest Brown
		AccentHighlight = Color3.fromRGB(255, 200, 80), -- Bright Yellow
		
		-- Text Colors
		TextHigh = Color3.fromRGB(255, 248, 230),     -- Warm white
		TextMid = Color3.fromRGB(180, 160, 130),      -- Muted gold
		TextLow = Color3.fromRGB(100, 85, 65),        -- Dark warm
		
		-- Status Colors
		Success = Color3.fromRGB(46, 204, 113),       -- Green #2ecc71
		Error = Color3.fromRGB(231, 76, 60),          -- Red #e74c3c
		Warning = Color3.fromRGB(241, 196, 15),       -- Yellow #f1c40f
		
		-- Rarity Colors (from UI Master Guide)
		Common = Color3.fromRGB(180, 180, 180),       -- Grey #b4b4b4
		Uncommon = Color3.fromRGB(0, 200, 0),         -- Green #00c800
		Rare = Color3.fromRGB(0, 150, 255),           -- Blue #0096ff
		Epic = Color3.fromRGB(150, 0, 200),           -- Purple #9600c8
		Legendary = Color3.fromRGB(255, 200, 0)       -- Gold #ffc800
	},
	Fonts = {
		Header = Enum.Font.GothamBold,                -- Per UI Master Guide
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.Code
	},
	Sizes = {
		CornerRadius = UDim.new(0, 8),                -- 8-12px per guide
		BorderThickness = 2
	}
}

-- Check Mobile
local IS_MOBILE = UserInputService.TouchEnabled

-- Adaptive Text Sizing (Mobile: 12-20, Desktop: 20-32)
local TEXT_MIN = IS_MOBILE and 12 or 20
local TEXT_MAX = IS_MOBILE and 20 or 32

-- --- HELPER UTILS ---
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radiusScale)
	-- Using udim scale for corners usually looks bad, stick to offset for small radius or use extremely small scale
	-- Rule.md allows offset for border/padding/small elements.
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radiusScale or 4)})
end

local function addStroke(parent, color)
	create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.AccentMain,
		Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

-- --- STATE ---
local State = {
	CurrentTab = "Weapons", -- Main tab: Weapons, FieldKit
	SelectedCategory = "All",
	SelectedWeapon = nil,
	CurrentPreview = nil,
	SelectedFieldKit = nil
}

-- Main Tabs Configuration (Skills/Achievements are in ProfileUI)
local MAIN_TABS = {
	{Id = "Weapons", Label = "WEAPONS", Icon = "🔫", Order = 1},
	{Id = "FieldKit", Label = "F. KIT", Icon = "🎒", Order = 2}
}

-- --- UI CONSTRUCTION ---
local screenGui = create("ScreenGui", {
	Name = "InventoryUI", Parent = playerGui,
	IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 20
})

local blur = create("BlurEffect", {Name = "InvBlur", Parent = workspace.CurrentCamera, Size = 0, Enabled = false})

-- MAIN CONTAINER
local mainContainer = create("CanvasGroup", {
	Name = "MainContainer", Parent = screenGui,
	-- Rule: Use Scale.
	Size = UDim2.fromScale(0.85, 0.8), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.02, GroupTransparency = 1, Visible = false
})
addCorner(mainContainer, 12)
addStroke(mainContainer, THEME.Colors.AccentMain)

-- Top Bar / Header
local topBar = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(1, 0.1),
	BackgroundColor3 = THEME.Colors.Panel, BorderSizePixel = 0
})
addCorner(topBar, 12)
-- Golden accent line at bottom of header
create("Frame", {
	Parent = topBar, Size = UDim2.new(0.98, 0, 0, 3), Position = UDim2.new(0.01, 0, 1, -3),
	BackgroundColor3 = THEME.Colors.AccentMain, BorderSizePixel = 0
})

local headerLabel = create("TextLabel", {
	Parent = topBar, Text = "📦 SURVIVAL CACHE",
	Size = UDim2.fromScale(0.5, 0.8), Position = UDim2.fromScale(0.03, 0.1),
	BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Font = THEME.Fonts.Header, TextScaled = true, TextColor3 = THEME.Colors.AccentMain
})
-- Constraints for text to not look huge
create("UITextSizeConstraint", {Parent = headerLabel, MaxTextSize = 32})

local closeBtn = create("TextButton", {
	Parent = topBar, Size = UDim2.fromScale(0.06, 0.6), Position = UDim2.fromScale(0.97, 0.5),
	AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = THEME.Colors.Error, Text = "✕",
	Font = THEME.Fonts.Header, TextColor3 = THEME.Colors.TextHigh, TextScaled = true
})
create("UIAspectRatioConstraint", {Parent = closeBtn, AspectRatio = 1})
addCorner(closeBtn, 6)

-- --- LAYOUT ---
-- 1. Sidebar (Main Tabs + Sub-Categories)
local sideBar = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(0.2, 0.88), Position = UDim2.fromScale(0, 0.12),
	BackgroundColor3 = THEME.Colors.Panel, BackgroundTransparency = 0.5
})

-- Main Tab Buttons (Top of Sidebar)
local mainTabContainer = create("Frame", {
	Parent = sideBar, Size = UDim2.fromScale(1, 0.35), Position = UDim2.fromScale(0, 0),
	BackgroundTransparency = 1
})
create("UIListLayout", {Parent = mainTabContainer, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder})
create("UIPadding", {Parent = mainTabContainer, PaddingTop = UDim.new(0.02, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0)})

-- Divider Line
local divider = create("Frame", {
	Parent = sideBar, Size = UDim2.fromScale(0.9, 0.003), Position = UDim2.fromScale(0.05, 0.36),
	BackgroundColor3 = THEME.Colors.AccentMain, BorderSizePixel = 0
})

-- Sub-Category List (Bottom of Sidebar)
local sideList = create("ScrollingFrame", {
	Parent = sideBar, Size = UDim2.fromScale(0.9, 0.6), Position = UDim2.fromScale(0.05, 0.38),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.AccentSec
})
create("UIListLayout", {Parent = sideList, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder})

-- 2. Content Area Container (holds all tab content)
local contentArea = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(0.8, 0.88), Position = UDim2.fromScale(0.2, 0.12),
	BackgroundTransparency = 1
})

-- 2a. Weapons Content (Grid + Detail)
local weaponsContent = create("Frame", {
	Name = "WeaponsContent", Parent = contentArea, Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1, Visible = true
})

local gridArea = create("Frame", {
	Parent = weaponsContent, Size = UDim2.fromScale(0.625, 1), Position = UDim2.fromScale(0, 0),
	BackgroundColor3 = THEME.Colors.Background, BackgroundTransparency = 1
})
create("UIPadding", {
	Parent = gridArea, PaddingTop = UDim.new(0.02, 0), PaddingLeft = UDim.new(0.02, 0), PaddingRight = UDim.new(0.02, 0)
})

local gridScroll = create("ScrollingFrame", {
	Parent = gridArea, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	ScrollBarThickness = 6, ScrollBarImageColor3 = THEME.Colors.AccentMain
})
local gridLayout = create("UIGridLayout", {
	Parent = gridScroll, CellSize = UDim2.fromScale(0.3, 0.25), -- Scale based cells
	CellPadding = UDim2.fromScale(0.03, 0.02)
})

local detailArea = create("Frame", {
	Parent = weaponsContent, Size = UDim2.fromScale(0.375, 1), Position = UDim2.fromScale(0.625, 0),
	BackgroundColor3 = THEME.Colors.PanelGlass, BackgroundTransparency = 0.1
})
create("UIStroke", {Parent = detailArea, Color = THEME.Colors.AccentSec, Thickness = 2, Transparency = 0.5})

-- 2b. Field Kit Content (Skills and Achievements moved to ProfileUI)
local fieldKitContent = create("Frame", {
	Name = "FieldKitContent", Parent = contentArea, Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1, Visible = false
})
local fieldKitGrid = create("ScrollingFrame", {
	Parent = fieldKitContent, Size = UDim2.fromScale(0.65, 0.95), Position = UDim2.fromScale(0.02, 0.02),
	BackgroundTransparency = 1, ScrollBarThickness = 6, ScrollBarImageColor3 = THEME.Colors.AccentMain
})
create("UIGridLayout", {Parent = fieldKitGrid, CellSize = UDim2.fromScale(0.3, 0.3), CellPadding = UDim2.fromScale(0.02, 0.02)})

local fieldKitDetailArea = create("Frame", {
	Parent = fieldKitContent, Size = UDim2.fromScale(0.3, 0.95), Position = UDim2.fromScale(0.68, 0.02),
	BackgroundColor3 = THEME.Colors.PanelGlass, BackgroundTransparency = 0.1
})
addCorner(fieldKitDetailArea, 4)
create("UIStroke", {Parent = fieldKitDetailArea, Color = THEME.Colors.AccentSec, Thickness = 2, Transparency = 0.5})

-- Content Reference Map
local ContentPanels = {
	Weapons = weaponsContent,
	FieldKit = fieldKitContent
}

-- --- COMPONENT BUILDERS ---

-- Forward declarations
local SetupCategories
local createCategoryBtn

local mainTabButtons = {} -- Store references to main tab buttons

local function createMainTabBtn(tabData)
	local btn = create("TextButton", {
		Name = tabData.Id, Parent = mainTabContainer, Size = UDim2.fromScale(1, 0.22),
		BackgroundColor3 = THEME.Colors.Background, AutoButtonColor = false,
		Text = "", LayoutOrder = tabData.Order
	})
	addCorner(btn, 4)
	
	local iconLabel = create("TextLabel", {
		Parent = btn, Text = tabData.Icon, Size = UDim2.fromScale(0.25, 0.8),
		Position = UDim2.fromScale(0.05, 0.1), BackgroundTransparency = 1,
		TextScaled = true
	})
	
	local textLabel = create("TextLabel", {
		Parent = btn, Text = tabData.Label, Size = UDim2.fromScale(0.65, 0.8),
		Position = UDim2.fromScale(0.3, 0.1), BackgroundTransparency = 1,
		Font = THEME.Fonts.Body, TextScaled = true, TextColor3 = THEME.Colors.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", {Parent = textLabel, MaxTextSize = 14})
	
	local marker = create("Frame", {
		Name = "Marker", Parent = btn, Size = UDim2.fromScale(0.02, 0.8),
		Position = UDim2.fromScale(0, 0.1), BackgroundColor3 = THEME.Colors.AccentMain,
		Visible = false
	})
	addCorner(marker, 2)
	
	mainTabButtons[tabData.Id] = {Button = btn, Text = textLabel, Marker = marker}
	return btn
end

-- Sub-category configurations per main tab (Skills/Achievements in ProfileUI)
local SUB_CATEGORIES = {
	Weapons = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Melee"},
	FieldKit = {"All", "Owned"}
}

local function SwitchTab(tabId)
	State.CurrentTab = tabId
	
	-- Hide all content panels
	for id, panel in pairs(ContentPanels) do
		panel.Visible = (id == tabId)
	end
	
	-- Update main tab button visuals
	for id, refs in pairs(mainTabButtons) do
		local isActive = (id == tabId)
		refs.Marker.Visible = isActive
		TweenService:Create(refs.Button, TweenInfo.new(0.2), {
			BackgroundColor3 = isActive and THEME.Colors.Panel or THEME.Colors.Background
		}):Play()
		TweenService:Create(refs.Text, TweenInfo.new(0.2), {
			TextColor3 = isActive and THEME.Colors.AccentMain or THEME.Colors.TextMid
		}):Play()
	end
	
	-- Clear and populate sub-categories based on tab
	for _, c in ipairs(sideList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	
	local cats = SUB_CATEGORIES[tabId] or {}
	if tabId == "Weapons" then
		SetupCategories() -- Use existing weapon category setup
	else
		for i, catName in ipairs(cats) do
			local btn, lbl, mark = createCategoryBtn(catName, i)
			-- Basic click handler for sub-categories (placeholder for now)
			btn.MouseButton1Click:Connect(function()
				-- Update visual
				for _, b in ipairs(sideList:GetChildren()) do
					if b:IsA("TextButton") then
						TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Colors.Background}):Play()
						TweenService:Create(b.TextLabel, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextMid}):Play()
						b.Mark.Visible = false
					end
				end
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Colors.Panel}):Play()
				TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.AccentMain}):Play()
				mark.Visible = true
			end)
		end
	end
end

createCategoryBtn = function(name, order)
	local btn = create("TextButton", {
		Name = name, Parent = sideList, Size = UDim2.fromScale(1, 0.08), -- Scale Size
		BackgroundColor3 = THEME.Colors.Background, AutoButtonColor = false,
		Text = "", LayoutOrder = order
	})
	addCorner(btn, 0)
	addStroke(btn, THEME.Colors.TextLow)

	local label = create("TextLabel", {
		Parent = btn, Text = name:upper(), Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1),
		BackgroundTransparency = 1, Font = THEME.Fonts.Body, TextScaled = true,
		TextColor3 = THEME.Colors.TextMid, TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", {Parent = label, MaxTextSize = 18})

	local mark = create("Frame", {
		Name = "Mark", Parent = btn, Size = UDim2.fromScale(0.05, 1),
		BackgroundColor3 = THEME.Colors.AccentMain, Visible = false
	})

	return btn, label, mark
end

local function createGridItem(data)
	local btn = create("TextButton", {
		Name = data.Id, Parent = gridScroll, BackgroundColor3 = THEME.Colors.PanelGlass,
		AutoButtonColor = false, Text = ""
	})
	addCorner(btn, 2)
	local stroke = create("UIStroke", {
		Parent = btn, Color = THEME.Colors.TextLow, Thickness = 2, Transparency = 0.5
	})

	create("TextLabel", {
		Parent = btn, Text = data.Name, Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.75),
		BackgroundTransparency = 1, Font = THEME.Fonts.Body, TextScaled = true,
		TextColor3 = THEME.Colors.TextHigh, TextXAlignment = Enum.TextXAlignment.Left,
	})

	create("TextLabel", {
		Parent = btn, Text = string.sub(data.Name, 1, 1), Size = UDim2.fromScale(0.8, 0.6),
		Position = UDim2.fromScale(0.1, 0.1), BackgroundTransparency = 1,
		Font = THEME.Fonts.Header, TextScaled = true, TextColor3 = THEME.Colors.TextLow,
		TextTransparency = 0.7
	})

	return btn, stroke
end

local function buildDetailPanel()
	local previewBox = create("Frame", {
		Parent = detailArea, Size = UDim2.fromScale(0.9, 0.45), Position = UDim2.fromScale(0.05, 0.05),
		BackgroundColor3 = Color3.fromRGB(5, 5, 5), BackgroundTransparency = 0
	})
	addCorner(previewBox, 4)
	addStroke(previewBox, THEME.Colors.AccentMain)

	local vp = create("ViewportFrame", {
		Name = "WeaponPreview", Parent = previewBox, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, LightColor = Color3.fromRGB(255, 200, 150)
	})

	local infoFrame = create("Frame", {
		Parent = detailArea, Size = UDim2.fromScale(0.9, 0.4), Position = UDim2.fromScale(0.05, 0.52),
		BackgroundTransparency = 1
	})

	local title = create("TextLabel", {
		Name = "Title", Parent = infoFrame, Text = "SELECT ITEM",
		Size = UDim2.fromScale(1, 0.15), BackgroundTransparency = 1,
		Font = THEME.Fonts.Header, TextScaled = true, TextColor3 = THEME.Colors.AccentMain,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", {Parent = title, MaxTextSize = 22})

	local desc = create("TextLabel", {
		Name = "Desc", Parent = infoFrame, Text = "Waiting for selection...",
		Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.2),
		BackgroundTransparency = 1, Font = THEME.Fonts.Mono, TextScaled = true,
		TextColor3 = THEME.Colors.TextMid, TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top
	})
	create("UITextSizeConstraint", {Parent = desc, MaxTextSize = 14})

	local equipBtn = create("TextButton", {
		Name = "EquipBtn", Parent = detailArea, Size = UDim2.fromScale(0.9, 0.1),
		Position = UDim2.fromScale(0.05, 0.88), BackgroundColor3 = THEME.Colors.AccentSec,
		Text = "TAKE ITEM", Font = THEME.Fonts.Header, TextScaled = true,
		TextColor3 = Color3.fromRGB(0,0,0)
	})
	addCorner(equipBtn, 4)

	return {Viewport = vp, Title = title, Desc = desc, EquipBtn = equipBtn}
end

local DetailRefs = buildDetailPanel()

-- --- LOGIC ---
local function UpdatePreview(id)
	if not WeaponModule or not WeaponModule.Weapons then return end
	local data = WeaponModule.Weapons[id]
	if not data then return end

	State.SelectedWeapon = id
	DetailRefs.Title.Text = string.upper(data.DisplayName or id)
	DetailRefs.Desc.Text = data.Description or "Survival gear found in the wasteland."

	if State.CurrentPreview then ModelPreviewModule.destroy(State.CurrentPreview) end
	local sData = nil
	if data.Skins then for _,v in pairs(data.Skins) do sData = v break end end
	if sData then
		State.CurrentPreview = ModelPreviewModule.create(DetailRefs.Viewport, data, sData)
		ModelPreviewModule.startRotation(State.CurrentPreview, 0.8)
	end

	DetailRefs.EquipBtn.Text = "TAKE"
	DetailRefs.EquipBtn.BackgroundColor3 = THEME.Colors.AccentSec
end

local function PopulateGrid()
	for _, c in ipairs(gridScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	local list = {}
	if WeaponModule and WeaponModule.Weapons then
		for id, d in pairs(WeaponModule.Weapons) do
			local catMatch = State.SelectedCategory == "All" or (d.Category and string.match(d.Category, State.SelectedCategory))
			if catMatch then table.insert(list, {Id = id, Name = d.DisplayName or id}) end
		end
		table.sort(list, function(a,b) return a.Name < b.Name end)
	end

	for _, item in ipairs(list) do
		local btn, stroke = createGridItem(item)
		btn.MouseButton1Click:Connect(function()
			UpdatePreview(item.Id)
			for _, b in ipairs(gridScroll:GetChildren()) do
				if b:IsA("TextButton") then
					TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = THEME.Colors.PanelGlass}):Play()
					b:FindFirstChild("UIStroke").Color = THEME.Colors.TextLow
				end
			end
			TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = THEME.Colors.AccentSec}):Play()
			stroke.Color = THEME.Colors.AccentMain
		end)
	end
end

SetupCategories = function()
	local cats = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Melee"}
	for i, c in ipairs(cats) do
		local btn, lbl, mark = createCategoryBtn(c, i)
		btn.MouseButton1Click:Connect(function()
			State.SelectedCategory = c
			PopulateGrid()
			for _, b in ipairs(sideList:GetChildren()) do
				if b:IsA("TextButton") then
					TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Colors.Background}):Play()
					TweenService:Create(b.TextLabel, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextMid}):Play()
					b.Mark.Visible = false
				end
			end
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Colors.Panel}):Play()
			TweenService:Create(lbl, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.AccentMain}):Play()
			mark.Visible = true
		end)
	end
end

-- --- HUD / MOBILE SCALING ---
local safeScale = IS_MOBILE and 0.15 or 0.1 -- Larger for mobile (Rule.md)
local hudBtn = create("TextButton", {
	Name = "OpenInv", Parent = screenGui, Size = UDim2.fromScale(safeScale, safeScale),
	Position = UDim2.fromScale(0.02, 0.95), AnchorPoint = Vector2.new(0, 1),
	BackgroundColor3 = THEME.Colors.Panel, AutoButtonColor = false,
	Text = ""
})
create("UIAspectRatioConstraint", {Parent = hudBtn, AspectRatio = 1})
addCorner(hudBtn, 100)
addStroke(hudBtn, THEME.Colors.AccentSec)
create("TextLabel", {
	Parent = hudBtn, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
	Text = "🎒", Font = Enum.Font.Gotham, TextScaled = true,
	TextColor3 = THEME.Colors.TextHigh
})

local function ToggleUI(forceState)
	local target = forceState ~= nil and forceState or not mainContainer.Visible
	if target then
		mainContainer.Visible = true
		hudBtn.Visible = false
		blur.Enabled = true
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 25}):Play()
		PopulateGrid()
	else
		hudBtn.Visible = true
		blur.Enabled = false
		mainContainer.Visible = false
	end
end

hudBtn.MouseButton1Click:Connect(function() ToggleUI(true) end)
closeBtn.MouseButton1Click:Connect(function() ToggleUI(false) end)
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.Tab then ToggleUI() end
end)

DetailRefs.EquipBtn.MouseButton1Click:Connect(function()
	if State.SelectedWeapon then
		DetailRefs.EquipBtn.Text = "TAKEN"
		DetailRefs.EquipBtn.BackgroundColor3 = THEME.Colors.Success
		task.wait(1)
		DetailRefs.EquipBtn.Text = "TAKE"
		DetailRefs.EquipBtn.BackgroundColor3 = THEME.Colors.AccentSec
	end
end)

-- Initialize Main Tabs
local function SetupMainTabs()
	for _, tabData in ipairs(MAIN_TABS) do
		local btn = createMainTabBtn(tabData)
		btn.MouseButton1Click:Connect(function()
			SwitchTab(tabData.Id)
		end)
	end
	-- Set initial active tab
	SwitchTab("Weapons")
end

SetupMainTabs()
