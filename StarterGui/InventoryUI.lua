-- InventoryUI.lua (LocalScript)
-- Path: StarterGui/InventoryUI.lua
-- Script Place: Lobby
-- Theme: "Procedural Military Case" (No External Assets/Textures)
-- Redesigned by Lead Game Developer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- --- THEME CONFIGURATION (No Assets) ---
local THEME = {
	COLORS = {
		CaseOuter = Color3.fromRGB(35, 35, 40),        -- Outer shell plastic
		CaseInner = Color3.fromRGB(25, 25, 28),        -- Inner void
		FoamSurface = Color3.fromRGB(40, 40, 45),      -- Foam surface
		FoamDeep = Color3.fromRGB(15, 15, 18),         -- Cutout holes
		AccentYellow = Color3.fromRGB(255, 180, 0),    -- Warning/Caution
		AccentCyan = Color3.fromRGB(0, 200, 255),      -- Hologram/highlight
		TextLight = Color3.fromRGB(220, 220, 230),     -- Main Text
		TextDark = Color3.fromRGB(120, 120, 130),      -- Label Text
		Metal = Color3.fromRGB(80, 80, 85),            -- Hinges/Mechanical
	},
	FONTS = {
		Header = Enum.Font.Michroma,    -- Tech/Industrial
		Label = Enum.Font.Oswald,       -- Legible
		Data = Enum.Font.Code,          -- Coding style
	}
}

-- --- HELPER FUNCTIONS ---
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {
		Parent = parent, Color = color or THEME.COLORS.CaseOuter, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

local function addGradient(parent, rotation, transparencyKeypoints)
	local g = create("UIGradient", {
		Parent = parent, Rotation = rotation or 90
	})
	if transparencyKeypoints then
		g.Transparency = NumberSequence.new(transparencyKeypoints)
	else
		-- Default subtle vertical shadow
		g.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.2)
		}
	end
	return g
end

-- --- UI CREATION ---
local screenGui = create("ScreenGui", {
	Name = "InventoryUI", Parent = playerGui, IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 10
})

local camera = workspace.CurrentCamera
local blurEffect = create("BlurEffect", {Name = "InventoryBlur", Size = 0, Enabled = false, Parent = camera})

-- Modules
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
local inventoryRemote = RemoteFunctions and RemoteFunctions:WaitForChild("GetInventoryData", 5)

-- State
local selectedCategory = "All"
local selectedWeapon = nil
local currentPreview = nil

-- --- MAIN PANEL (Pure Shapes) ---
local mainPanel = create("Frame", {
	Name = "MainPanel", Parent = screenGui, Size = UDim2.new(0.85, 0, 0.8, 0),
	Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.COLORS.CaseInner, Visible = false, ZIndex = 100
})
addCorner(mainPanel, 24)
addStroke(mainPanel, THEME.COLORS.CaseOuter, 8)

-- Decoration: "Corner Bumpers" (Pure Frames)
for _, pos in ipairs({
	UDim2.new(0,0,0,0), UDim2.new(1,-40,0,0), 
	UDim2.new(0,0,1,-40), UDim2.new(1,-40,1,-40)
}) do
	local bumper = create("Frame", {
		Parent = mainPanel, Size = UDim2.new(0, 40, 0, 40), Position = pos,
		BackgroundColor3 = THEME.COLORS.CaseOuter, ZIndex = 101, BorderSizePixel = 0
	})
	addCorner(bumper, 12)
end

-- 1. LEFT SIDE: CONTROL PLATE
local sidePanel = create("Frame", {
	Parent = mainPanel, Size = UDim2.new(0.22, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0),
	BackgroundColor3 = THEME.COLORS.CaseOuter, ZIndex = 102
})
addCorner(sidePanel, 8)
-- Subtle gradient for metallic look
addGradient(sidePanel, 45, {
	NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.1)
})

-- Header Block
local headerBox = create("Frame", {
	Parent = sidePanel, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.03, 0),
	BackgroundColor3 = THEME.COLORS.AccentYellow, ZIndex = 103
})
addCorner(headerBox, 4)
create("TextLabel", {
	Parent = headerBox, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	Text = "TACTICAL LOADOUT", Font = THEME.FONTS.Header, TextSize = 16,
	TextColor3 = Color3.new(0,0,0), ZIndex = 104
})

-- Categories
local catList = create("Frame", {
	Parent = sidePanel, Size = UDim2.new(0.9, 0, 0.8, 0), Position = UDim2.new(0.05, 0, 0.16, 0),
	BackgroundTransparency = 1, ZIndex = 103
})
create("UIListLayout", {Parent = catList, Padding = UDim.new(0, 6)})

local CATEGORIES = {"All", "Rifle", "SMG", "Shotgun", "Sniper", "Pistol", "LMG"}
local catBtns = {}

local function createCatBtn(name)
	local btn = create("TextButton", {
		Parent = catList, Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = THEME.COLORS.CaseInner, AutoButtonColor = false,
		Text = "", ZIndex = 104
	})
	addCorner(btn, 6)
	
	local txt = create("TextLabel", {
		Parent = btn, Size = UDim2.new(0.8, 0, 1, 0), Position = UDim2.new(0.1, 0, 0, 0),
		BackgroundTransparency = 1, Text = name:upper(),
		Font = THEME.FONTS.Label, TextSize = 16, TextColor3 = THEME.COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 105
	})
	
	-- "Light" Indicator (Pure Frame)
	local led = create("Frame", {
		Parent = btn, Size = UDim2.new(0, 4, 0, 20), Position = UDim2.new(0, 4, 0.5, -10),
		BackgroundColor3 = THEME.COLORS.Metal, ZIndex = 105
	})
	addCorner(led, 2)
	
	catBtns[name] = {Btn = btn, Txt = txt, Led = led}
	return btn
end

for _, c in ipairs(CATEGORIES) do createCatBtn(c) end

-- 2. CENTER: ITEM GRID
local gridFrame = create("Frame", {
	Parent = mainPanel, Size = UDim2.new(0.48, 0, 0.9, 0), Position = UDim2.new(0.26, 0, 0.05, 0),
	BackgroundColor3 = THEME.COLORS.FoamSurface, ZIndex = 102
})
addCorner(gridFrame, 8)
-- Inset Shadow effect using UIStroke
create("UIStroke", {
	Parent = gridFrame, Color = Color3.new(0,0,0), Thickness = 2, Transparency = 0.5
})

local itemScroll = create("ScrollingFrame", {
	Parent = gridFrame, Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.COLORS.AccentYellow,
	ZIndex = 103
})
create("UIGridLayout", {
	Parent = itemScroll, CellSize = UDim2.new(0.31, 0, 0.35, 0), CellPadding = UDim2.new(0.02, 0, 0.02, 0)
})

-- 3. RIGHT: DETAIL PREVIEW (Holographic Style)
local detailFrame = create("Frame", {
	Parent = mainPanel, Size = UDim2.new(0.22, 0, 0.9, 0), Position = UDim2.new(0.76, 0, 0.05, 0),
	BackgroundColor3 = THEME.COLORS.CaseInner, ZIndex = 102,
    BorderSizePixel = 0
})
addCorner(detailFrame, 8)
-- Border stroke
addStroke(detailFrame, THEME.COLORS.Metal, 1)

-- Scanner/Holo Box
local holoBox = create("Frame", {
	Parent = detailFrame, Size = UDim2.new(0.9, 0, 0.5, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
	BackgroundColor3 = Color3.fromRGB(15, 20, 25), ZIndex = 103
})
addCorner(holoBox, 4)
addStroke(holoBox, THEME.COLORS.AccentCyan, 1)

-- Viewport
local vp = create("ViewportFrame", {
	Parent = holoBox, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	LightColor = Color3.fromRGB(200, 255, 255), LightDirection = Vector3.new(-1, -1, 1),
	Ambient = Color3.fromRGB(100, 100, 100), ZIndex = 104
})

-- Scan line (Pure Frame)
local scanLine = create("Frame", {
	Parent = holoBox, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = THEME.COLORS.AccentCyan, BorderSizePixel = 0, ZIndex = 105
})
-- Animate scan line
task.spawn(function()
    while detailFrame.Parent do -- Only animate while UI exists
        TweenService:Create(scanLine, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = UDim2.new(0,0,1,0)
        }):Play()
        task.wait(4.1)
    end
end)


-- Info Text
local infoName = create("TextLabel", {
	Parent = detailFrame, Size = UDim2.new(0.9, 0, 0, 30), Position = UDim2.new(0.05, 0, 0.58, 0),
	BackgroundTransparency = 1, Text = "SELECT MODULE",
	Font = THEME.FONTS.Header, TextSize = 16, TextColor3 = THEME.COLORS.AccentCyan,
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 104
})
local infoDesc = create("TextLabel", {
	Parent = detailFrame, Size = UDim2.new(0.9, 0, 0.2, 0), Position = UDim2.new(0.05, 0, 0.65, 0),
	BackgroundTransparency = 1, Text = "Awaiting input...",
	Font = THEME.FONTS.Data, TextSize = 12, TextColor3 = THEME.COLORS.TextDark,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true, ZIndex = 104
})

-- Equip
local equipBtn = create("TextButton", {
	Parent = detailFrame, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.88, 0),
	BackgroundColor3 = THEME.COLORS.AccentYellow, Text = "EQUIP",
	Font = THEME.FONTS.Header, TextSize = 18, TextColor3 = Color3.new(0,0,0), ZIndex = 104
})
addCorner(equipBtn, 4)


-- --- LOGIC ---
local function updatePreview(id)
	if not WeaponModule or not WeaponModule.Weapons then return end
	local data = WeaponModule.Weapons[id]
	infoName.Text = string.upper(data.DisplayName or id)
    infoDesc.Text = data.Description or "Standard issue equipment."

	if currentPreview then ModelPreviewModule.destroy(currentPreview) end
	local sData = nil
	if data.Skins then for _,v in pairs(data.Skins) do sData = v break end end

	if sData then
		currentPreview = ModelPreviewModule.create(vp, data, sData)
		ModelPreviewModule.startRotation(currentPreview, 1)
		local cam = vp.CurrentCamera
		if cam then cam.CFrame = cam.CFrame * CFrame.new(0, 0, 1.5) end
	end
end

local function updateList()
	for _,c in ipairs(itemScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	if not WeaponModule or not WeaponModule.Weapons then return end
	local list = {}
	for id,d in pairs(WeaponModule.Weapons) do
		local match = selectedCategory == "All" or (d.Category and string.find(d.Category, selectedCategory))
		if match then table.insert(list, {id=id, name=d.DisplayName or id}) end
	end
	table.sort(list, function(a,b) return a.name < b.name end)

	for _, w in ipairs(list) do
		local isSel = (w.id == selectedWeapon)
		
		-- Cutout Style Button
		local btn = create("TextButton", {
			Parent = itemScroll, BackgroundColor3 = THEME.COLORS.FoamDeep,
			Text = "", AutoButtonColor = false, ZIndex = 104
		})
		addCorner(btn, 6)
		
		if isSel then
			-- Highlight Border
			addStroke(btn, THEME.COLORS.AccentCyan, 2)
			-- Inner glow frame
			local glow = create("Frame", {
				Parent = btn, Size = UDim2.new(1,0,1,0), BackgroundColor3 = THEME.COLORS.AccentCyan,
				BackgroundTransparency = 0.8, ZIndex = 103
			})
			addCorner(glow, 6)
		else
			-- Subtle Inset Border
			create("UIStroke", {
				Parent = btn, Color = Color3.fromRGB(50,50,55), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			})
		end

		create("TextLabel", {
			Parent = btn, Size = UDim2.new(1, -10, 0.4, 0), Position = UDim2.new(0,5,0.6,0),
			BackgroundTransparency = 1, Text = w.name, Font = THEME.FONTS.Label,
			TextColor3 = isSel and THEME.COLORS.AccentCyan or THEME.COLORS.TextDark,
			TextScaled = true, ZIndex = 105
		})

		btn.MouseButton1Click:Connect(function()
			selectedWeapon = w.id
			updateList()
			updatePreview(w.id)
		end)
	end
end

local function updateTabs()
	for name, obj in pairs(catBtns) do
		local active = (name == selectedCategory)
		if active then
			obj.Btn.BackgroundColor3 = THEME.COLORS.FoamSurface
			obj.Txt.TextColor3 = THEME.COLORS.AccentYellow
			obj.Led.BackgroundColor3 = THEME.COLORS.AccentYellow
			-- Add glow effect
            if not obj.Led:FindFirstChild("Glow") then
                create("UIStroke", {
                    Name = "Glow", Parent = obj.Led, Thickness = 2,
                    Color = THEME.COLORS.AccentYellow, Transparency = 0.5
                })
            end
		else
			obj.Btn.BackgroundColor3 = THEME.COLORS.CaseInner
			obj.Txt.TextColor3 = THEME.COLORS.TextDark
			obj.Led.BackgroundColor3 = THEME.COLORS.Metal
			if obj.Led:FindFirstChild("Glow") then obj.Led.Glow:Destroy() end
		end
	end
end
for name, obj in pairs(catBtns) do obj.Btn.MouseButton1Click:Connect(function() selectedCategory = name; updateTabs(); updateList() end) end
updateTabs()

-- HUD
local hudBtn = create("TextButton", {
	Name = "OpenInv", Parent = screenGui, Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.02, 0, 0.7, 0),
	BackgroundColor3 = THEME.COLORS.CaseOuter, Text = "", ZIndex = 50
})
addCorner(hudBtn, 12)
addStroke(hudBtn, THEME.COLORS.AccentYellow, 2)
create("TextLabel", {Parent=hudBtn, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="GEAR", Font=THEME.FONTS.Header, TextSize=14, TextColor3=THEME.COLORS.AccentYellow, ZIndex=51})

hudBtn.MouseButton1Click:Connect(function()
	mainPanel.Visible = true; hudBtn.Visible = false; blurEffect.Enabled = true
	TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 25}):Play()
	updateList()
end)

local close = create("TextButton", {
	Parent = mainPanel, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0.97, 0, 0.02, 0),
	BackgroundColor3 = Color3.fromRGB(180, 50, 50), Text = "X", Font = THEME.FONTS.Header, TextColor3 = Color3.new(1,1,1), ZIndex = 110
})
addCorner(close, 6)
close.MouseButton1Click:Connect(function()
	mainPanel.Visible = false; hudBtn.Visible = true; blurEffect.Enabled = false
end)

task.spawn(function()
	if inventoryRemote then pcall(function() inventoryRemote:InvokeServer() end) end
end)
print("InventoryUI (Procedural Case) Loaded")
