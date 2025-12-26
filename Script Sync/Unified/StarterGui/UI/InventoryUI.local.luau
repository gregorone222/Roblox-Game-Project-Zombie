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

-- --- THEME CONSTANTS ---
local THEME = {
	Colors = {
		Background = Color3.fromRGB(15, 12, 10),
		Panel = Color3.fromRGB(28, 24, 20),
		PanelGlass = Color3.fromRGB(35, 30, 25),
		AccentMain = Color3.fromRGB(255, 140, 0),      -- AMBER
		AccentSec = Color3.fromRGB(160, 40, 30),       -- RUST
		TextHigh = Color3.fromRGB(230, 220, 200),
		TextMid = Color3.fromRGB(150, 140, 120),
		TextLow = Color3.fromRGB(80, 70, 60),
		Success = Color3.fromRGB(100, 180, 80),
		Error = Color3.fromRGB(200, 60, 60)
	},
	Fonts = {
		Header = Enum.Font.Michroma,
		Body = Enum.Font.Oswald,
		Mono = Enum.Font.Code
	}
}

-- Check Mobile
local IS_MOBILE = UserInputService.TouchEnabled

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
	SelectedCategory = "All",
	SelectedWeapon = nil,
	CurrentPreview = nil
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
	BackgroundTransparency = 0.05, GroupTransparency = 1, Visible = false
})
addCorner(mainContainer, 8)
addStroke(mainContainer, THEME.Colors.AccentSec)

-- Top Bar / Header
local topBar = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(1, 0.12), -- Scale-based height
	BackgroundColor3 = THEME.Colors.Panel
})
create("Frame", {
	Parent = topBar, Size = UDim2.new(1, 0, 0, 4), -- Hazard stripe (small detail allowed offset)
	BackgroundColor3 = THEME.Colors.AccentMain, BorderSizePixel = 0
})

create("TextLabel", {
	Parent = topBar, Text = "SURVIVAL CACHE // RESTRICTED",
	Size = UDim2.fromScale(0.6, 1), Position = UDim2.fromScale(0.02, 0),
	BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
	Font = THEME.Fonts.Header, TextScaled = true, TextColor3 = THEME.Colors.AccentMain
})
-- Constraints for text to not look huge
create("UITextSizeConstraint", {Parent = topBar:FindFirstChild("TextLabel"), MaxTextSize = 28})

local closeBtn = create("TextButton", {
	Parent = topBar, Size = UDim2.fromScale(0.08, 0.6), Position = UDim2.fromScale(0.98, 0.5),
	AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = THEME.Colors.Error, Text = "X",
	Font = THEME.Fonts.Header, TextColor3 = Color3.new(0,0,0), TextScaled = true
})
create("UIAspectRatioConstraint", {Parent = closeBtn, AspectRatio = 1}) -- Keep Keypad square
addCorner(closeBtn, 4)

-- --- LAYOUT ---
-- 1. Sidebar (Categories)
local sideBar = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(0.2, 0.88), Position = UDim2.fromScale(0, 0.12),
	BackgroundColor3 = THEME.Colors.Panel, BackgroundTransparency = 0.5
})
local sideList = create("ScrollingFrame", {
	Parent = sideBar, Size = UDim2.fromScale(0.9, 0.95), Position = UDim2.fromScale(0.05, 0.025),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.AccentSec
})
create("UIListLayout", {Parent = sideList, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder})

-- 2. Grid Area (Weapons)
local gridArea = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(0.5, 0.88), Position = UDim2.fromScale(0.2, 0.12),
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

-- 3. Detail Area (Preview)
local detailArea = create("Frame", {
	Parent = mainContainer, Size = UDim2.fromScale(0.3, 0.88), Position = UDim2.fromScale(0.7, 0.12),
	BackgroundColor3 = THEME.Colors.PanelGlass, BackgroundTransparency = 0.1
})
create("UIStroke", {Parent = detailArea, Color = THEME.Colors.AccentSec, Thickness = 2, Transparency = 0.5})

-- --- COMPONENT BUILDERS ---

local function createCategoryBtn(name, order)
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

local function SetupCategories()
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

SetupCategories()
-- print removed
