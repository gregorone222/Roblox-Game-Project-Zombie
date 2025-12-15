-- ProfileUI.lua (LocalScript)
-- Path: StarterGui/ProfileUI.lua
-- Script Place: Lobby
-- Theme: "Confidential Field Dossier" (AAA Quality)
-- Description: Immersive UI resembling a top-secret survival file with 3D character visualization.

--[[ SERVICES ]]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

--[[ LOCAL PLAYER ]]--
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--[[ CONSTANTS & CONFIG ]]--
local LOBBY_PLACE_ID = 101319079083908
-- Check place ID if strict, otherwise loose for testing
-- if game.PlaceId ~= LOBBY_PLACE_ID then script:Destroy() return end

local THEME = {
	Colors = {
		FolderDark = Color3.fromRGB(55, 45, 35),     -- Old Leather/Dark Paper
		FolderLight = Color3.fromRGB(210, 195, 170), -- Manila Folder
		Paper = Color3.fromRGB(245, 240, 230),       -- Off-white Paper
		InkPrimary = Color3.fromRGB(30, 30, 35),     -- Main Text
		InkSecondary = Color3.fromRGB(80, 70, 60),   -- Sub Text
		AccentRed = Color3.fromRGB(180, 50, 50),     -- Stamps/Alerts
		AccentHighlight = Color3.fromRGB(255, 200, 50), -- Marker/Highlight
		TechBlue = Color3.fromRGB(50, 80, 100),      -- Blueprint lines
	},
	Fonts = {
		Typewriter = Enum.Font.SpecialElite,
		Handwritten = Enum.Font.PermanentMarker, -- Verified Handwritten
		Stamp = Enum.Font.Michroma, -- Verified Military/Stamp
		Tech = Enum.Font.Code,
	},
	Assets = {
		-- Texture IDs (Standard Roblox Assets or placeholders)
		Noise = "rbxassetid://6008328723", -- Grain texture
		PaperTexture = "rbxassetid://6008328723", -- Reusing grain for now, ideally specific paper texture
		Clip = "rbxassetid://16467339739", -- Hypothetical asset, we will draw it with Frames if needed
	}
}

--[[ REMOTES ]]--
local function getRemote(name, type)
	local folder = ReplicatedStorage:FindFirstChild(type == "Function" and "RemoteFunctions" or "RemoteEvents")
	if not folder then
		-- Fallback search
		return ReplicatedStorage:FindFirstChild(name, true)
	end
	return folder:FindFirstChild(name)
end

local profileFunc = getRemote("GetProfileData", "Function")
local titleFunc = getRemote("GetTitleData", "Function")
local equipTitleEvent = getRemote("SetEquippedTitle", "Event")
local weaponStatsFunc = getRemote("GetWeaponStats", "Function")

--================================================================================--
--[[ UI ENGINE ]]--
--================================================================================--

local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {Parent = parent, Color = color, Thickness = thickness, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

local function addPadding(parent, px)
	create("UIPadding", {Parent = parent, PaddingTop = UDim.new(0,px), PaddingBottom = UDim.new(0,px), PaddingLeft = UDim.new(0,px), PaddingRight = UDim.new(0,px)})
end

local function playSound(id, parent)
	local s = create("Sound", {Parent = parent or playerGui, SoundId = id, Volume = 0.5})
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

-- --- 3D VIEWPORT UTILS ---
local function createCharacterViewport(parent, size, pos)
	local frame = create("Frame", {
		Name = "PhotoFrame", Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), Rotation = math.random(-2, 2)
	})
	-- Photo Border
	addStroke(frame, Color3.fromRGB(200, 200, 200), 1)
	create("UIStroke", {Parent = frame, Color = Color3.fromRGB(20, 20, 20), Thickness = 2, Transparency = 0.8}) -- Shadow hint

	-- The Viewport
	local vp = create("ViewportFrame", {
		Name = "Viewport", Parent = frame, Size = UDim2.new(0.92, 0, 0.92, 0), Position = UDim2.new(0.04, 0, 0.04, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 45), BorderSizePixel = 0,
		LightColor = Color3.fromRGB(255, 240, 200), LightDirection = Vector3.new(-1, -1, 1)
	})

	-- Camera
	local cam = create("Camera", {Parent = vp, FieldOfView = 25})
	vp.CurrentCamera = cam

	-- WorldModel for Physics/Animation
	local worldModel = create("WorldModel", {Parent = vp})

	-- Gloss Overlay
	create("ImageLabel", {
		Parent = frame, Size = UDim2.new(1,0,0.5,0), BackgroundTransparency = 1,
		Image = "rbxassetid://13475253246", ImageTransparency = 0.8, Rotation = 180 -- Gradient reflection
	})

	-- Paperclip
	local clip = create("Frame", {
		Parent = frame, Size = UDim2.new(0, 15, 0, 40), Position = UDim2.new(0.5, -7, 0, -15),
		BackgroundColor3 = Color3.fromRGB(150, 150, 150), ZIndex = 5
	})
	addCorner(clip, 8)

	return vp, worldModel, cam
end

local function setupCharacterModel(worldModel)
	-- Clear old
	for _, c in pairs(worldModel:GetChildren()) do c:Destroy() end

	local character = player.Character or player.CharacterAdded:Wait()
	local archivable = character.Archivable
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = archivable

	clone.Parent = worldModel

	-- Cleanup Scripts/Effects
	for _, child in pairs(clone:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("Sound") then
			child:Destroy()
		end
	end

	-- Pose
	local hum = clone:FindFirstChild("Humanoid")
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if hum and hrp then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(0, 0, 0)

		-- Simple Idle Animation via CFrame manipulation in RenderStepped or just static pose
		-- For simplicity in this script, static pose with slight rotation
	end

	return clone
end

--================================================================================--
--[[ CORE UI ]]--
--================================================================================--

local gui = create("ScreenGui", {Name = "ProfileUI", Parent = playerGui, ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false})

-- Blur Effect
local camera = workspace.CurrentCamera
local blurEffect = create("BlurEffect", {Parent = camera, Size = 15, Enabled = false})

local overlay = create("Frame", {
	Name = "DarkOverlay", Parent = gui, Size = UDim2.new(1,0,1,0),
	BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, ZIndex = 0
})

local mainFolder = create("Frame", {
	Name = "Dossier", Parent = gui, Size = UDim2.new(0, 900, 0, 600), Position = UDim2.new(0.5, 0, 1.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.FolderLight
})
addCorner(mainFolder, 6)
-- Folder Tab at Top
local folderTab = create("Frame", {
	Parent = mainFolder, Size = UDim2.new(0.3, 0, 0.05, 0), Position = UDim2.new(0.05, 0, -0.04, 0),
	BackgroundColor3 = THEME.Colors.FolderLight
})
create("UICorner", {Parent = folderTab, CornerRadius = UDim.new(0, 6)})
create("Frame", { -- Cover bottom rounded corners
	Parent = folderTab, Size = UDim2.new(1,0,0.5,0), Position = UDim2.new(0,0,0.5,0),
	BackgroundColor3 = THEME.Colors.FolderLight, BorderSizePixel = 0
})
create("TextLabel", {
	Parent = folderTab, Size = UDim2.new(1,0,1,0), Text = "CONFIDENTIAL // SURVIVOR DATA",
	Font = THEME.Fonts.Stamp, TextSize = 14, TextColor3 = Color3.new(0,0,0), TextTransparency = 0.6
})

-- Inner Content Area (The Paper)
local paperSheet = create("Frame", {
	Name = "Paper", Parent = mainFolder, Size = UDim2.new(0.96, 0, 0.94, 0), Position = UDim2.new(0.02, 0, 0.03, 0),
	BackgroundColor3 = THEME.Colors.Paper
})
-- Texture Overlay
local texture = create("ImageLabel", {
	Parent = paperSheet, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	Image = THEME.Assets.Noise, ImageTransparency = 0.95, ImageColor3 = Color3.new(0,0,0), ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 256, 0, 256)
})

-- Close "Stamp" Button
local closeBtn = create("TextButton", {
	Parent = paperSheet, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(1, -60, 0, 10),
	BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1,
	Text = "X", Font = THEME.Fonts.Handwritten, TextSize = 40, TextColor3 = THEME.Colors.AccentRed,
	Rotation = math.random(-15, 15)
})
-- Circle around X
create("UIStroke", {Parent = closeBtn, Color = THEME.Colors.AccentRed, Thickness = 3, Transparency = 0.2})
create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(1,0)})


-- [[ LEFT COLUMN: IDENTITY ]]
local leftCol = create("Frame", {
	Parent = paperSheet, Size = UDim2.new(0.35, 0, 1, 0), BackgroundTransparency = 1
})
create("UIListLayout", {Parent = leftCol, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 20), SortOrder = Enum.SortOrder.LayoutOrder})
create("UIPadding", {Parent = leftCol, PaddingTop = UDim.new(0, 40)})

-- Photo
local vpFrame, worldModel, cam = createCharacterViewport(leftCol, UDim2.new(0, 220, 0, 280), UDim2.new(0,0,0,0))
vpFrame.Parent.LayoutOrder = 1

-- Info Block
local infoBlock = create("Frame", {
	Parent = leftCol, Size = UDim2.new(0.85, 0, 0, 150), BackgroundTransparency = 1, LayoutOrder = 2
})
-- Name
local nameLabel = create("TextLabel", {
	Parent = infoBlock, Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1, Text = "SUBJECT: " .. string.upper(player.Name),
	Font = THEME.Fonts.Typewriter, TextSize = 18, TextColor3 = THEME.Colors.InkPrimary, TextXAlignment = Enum.TextXAlignment.Left
})
-- Title
local titleLabel = create("TextLabel", {
	Parent = infoBlock, Size = UDim2.new(1,0,0,40), Position = UDim2.new(0,0,0,30),
	BackgroundTransparency = 1, Text = "NO TITLE",
	Font = THEME.Fonts.Stamp, TextSize = 32, TextColor3 = THEME.Colors.AccentRed, TextXAlignment = Enum.TextXAlignment.Left,
	Rotation = -2
})
-- Level
local levelLabel = create("TextLabel", {
	Parent = infoBlock, Size = UDim2.new(1,0,0,25), Position = UDim2.new(0,0,0,80),
	BackgroundTransparency = 1, Text = "CLEARANCE LEVEL 0",
	Font = THEME.Fonts.Typewriter, TextSize = 16, TextColor3 = THEME.Colors.InkSecondary, TextXAlignment = Enum.TextXAlignment.Left
})
-- XP Bar
local xpBg = create("Frame", {
	Parent = infoBlock, Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,0,105),
	BackgroundColor3 = Color3.fromRGB(200,200,200), BorderSizePixel = 1, BorderColor3 = THEME.Colors.InkSecondary
})
local xpFill = create("Frame", {
	Parent = xpBg, Size = UDim2.new(0,0,1,0), BackgroundColor3 = THEME.Colors.AccentHighlight, BorderSizePixel = 0
})

-- [[ RIGHT COLUMN: DATA TABS ]]
local rightCol = create("Frame", {
	Parent = paperSheet, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0.38, 0, 0, 0), BackgroundTransparency = 1
})

-- Sticky Note Tabs
local tabContainer = create("Frame", {
	Parent = rightCol, Size = UDim2.new(1,0,0,50), Position = UDim2.new(0,0,0,20), BackgroundTransparency = 1
})
local tabLayout = create("UIListLayout", {Parent = tabContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)})

local contentContainer = create("Frame", {
	Parent = rightCol, Size = UDim2.new(1,0,0.85,0), Position = UDim2.new(0,0,0,80), BackgroundTransparency = 1
})
-- Divider Line
create("Frame", {
	Parent = rightCol, Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,0,75),
	BackgroundColor3 = THEME.Colors.InkSecondary, BackgroundTransparency = 0.5, BorderSizePixel = 0
})

local pages = {} -- Store page frames

local function createPage(name)
	local page = create("ScrollingFrame", {
		Name = name, Parent = contentContainer, Size = UDim2.new(1,0,1,0),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.InkSecondary, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIListLayout", {Parent = page, Padding = UDim.new(0, 5)})
	create("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 20)})
	pages[name] = page
	return page
end

local statPage = createPage("Stats")
local weaponPage = createPage("Weapons")
local titlePage = createPage("Titles")

-- Tabs Logic
local function switchTab(name)
	for pname, p in pairs(pages) do
		p.Visible = (pname == name)
	end
	-- Visual updates for tabs (active vs inactive) handled in loop below
end

local tabsDef = {
	{id = "Stats", label = "SERVICE RECORD", color = Color3.fromRGB(240, 230, 140)}, -- Yellow Note
	{id = "Weapons", label = "ARSENAL", color = Color3.fromRGB(255, 180, 180)}, -- Pink Note
	{id = "Titles", label = "DESIGNATIONS", color = Color3.fromRGB(180, 220, 255)}, -- Blue Note
}

for _, t in ipairs(tabsDef) do
	local btn = create("TextButton", {
		Parent = tabContainer, Size = UDim2.new(0.3, 0, 1, 0), BackgroundColor3 = t.color,
		Text = t.label, Font = THEME.Fonts.Handwritten, TextSize = 18, TextColor3 = THEME.Colors.InkPrimary
	})
	-- Sticky note look
	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 0)}) -- Sharp corners usually, maybe slightly curl?
	-- Shadow
	create("Frame", {
		Parent = btn, Size = UDim2.new(1,2,1,2), Position = UDim2.new(0,1,0,1), ZIndex = -1,
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.7
	})

	btn.MouseButton1Click:Connect(function()
		switchTab(t.id)
		-- Simple pop animation
		btn:TweenPosition(UDim2.new(btn.Position.X.Scale, 0, -0.1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true, function()
			btn:TweenPosition(UDim2.new(btn.Position.X.Scale, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1)
		end)
	end)
end
switchTab("Stats") -- Default

--================================================================================--
--[[ DATA POPULATION ]]--
--================================================================================--

local function createStatRow(parent, label, value)
	local row = create("Frame", {Parent = parent, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
	create("TextLabel", {
		Parent = row, Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1,
		Text = label, Font = THEME.Fonts.Typewriter, TextSize = 16, TextColor3 = THEME.Colors.InkPrimary, TextXAlignment = Enum.TextXAlignment.Left
	})
	create("TextLabel", {
		Parent = row, Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0.6,0,0,0), BackgroundTransparency = 1,
		Text = tostring(value), Font = THEME.Fonts.Handwritten, TextSize = 20, TextColor3 = THEME.Colors.InkSecondary, TextXAlignment = Enum.TextXAlignment.Right
	})
	create("Frame", { -- Dotted line
		Parent = row, Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0),
		BackgroundColor3 = THEME.Colors.InkSecondary, BackgroundTransparency = 0.8
	})
end

local function updateStats()
	-- Clear
	for _, c in pairs(statPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	if not profileFunc then return end
	local success, data = pcall(function() return profileFunc:InvokeServer() end)
	if not success then data = {} end

	-- Update Left Info
	levelLabel.Text = "CLEARANCE LEVEL: " .. (data.Level or 1)
	local xp = data.XP or 0
	local req = data.XPForNextLevel or 1000
	xpFill.Size = UDim2.new(math.clamp(xp/req, 0, 1), 0, 1, 0)

	-- Stats List
	local map = {
		{"CONFIRMED KILLS", data.TotalKills},
		{"TOTAL DAMAGE", data.TotalDamageDealt},
		{"MISSIONS COMPLETED", data.TotalWins},
		{"TIMES INCAPACITATED", data.TotalKnocks},
		{"SQUAD REVIVES", data.TotalRevives},
		{"COINS SECURED", data.TotalCoins},
	}

	for _, item in ipairs(map) do
		createStatRow(statPage, item[1], item[2] or 0)
	end

	-- Radar Chart Simulation (Visual Only - Skill Graph)
	-- Ideally we draw lines, but for now let's add a visual "Evaluation" stamp
	local kills = data.TotalKills or 0
	local rating = "ROOKIE"
	if kills > 1000 then rating = "SURVIVOR" end
	if kills > 5000 then rating = "VETERAN" end
	if kills > 10000 then rating = "ELITE" end

	local stamp = create("TextLabel", {
		Parent = statPage, Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1,
		Text = "RATING: " .. rating, Font = THEME.Fonts.Stamp, TextSize = 28, TextColor3 = THEME.Colors.AccentRed,
		Rotation = -5
	})
	create("UIStroke", {Parent = stamp, Color = THEME.Colors.AccentRed, Thickness = 2, Transparency = 0.5})
end

local function updateWeapons()
	for _, c in pairs(weaponPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	if not weaponStatsFunc then return end
	local success, stats = pcall(function() return weaponStatsFunc:InvokeServer() end)
	if not success or type(stats) ~= "table" then stats = {} end

	table.sort(stats, function(a,b) return (a.Kills or 0) > (b.Kills or 0) end)

	for _, w in ipairs(stats) do
		local row = create("Frame", {
			Parent = weaponPage, Size = UDim2.new(1,0,0,45), BackgroundColor3 = Color3.fromRGB(240,240,240)
		})
		addCorner(row, 4)
		addStroke(row, Color3.fromRGB(200,200,200), 1)

		create("TextLabel", {
			Parent = row, Size = UDim2.new(0.5,0,0.5,0), Position = UDim2.new(0.05,0,0.1,0), BackgroundTransparency = 1,
			Text = w.Name, Font = THEME.Fonts.Typewriter, TextSize = 16, TextColor3 = THEME.Colors.InkPrimary, TextXAlignment = Enum.TextXAlignment.Left
		})
		create("TextLabel", {
			Parent = row, Size = UDim2.new(0.4,0,1,0), Position = UDim2.new(0.55,0,0,0), BackgroundTransparency = 1,
			Text = (w.Kills or 0) .. " KILLS", Font = THEME.Fonts.Handwritten, TextSize = 18, TextColor3 = THEME.Colors.AccentRed, TextXAlignment = Enum.TextXAlignment.Right
		})
		create("TextLabel", {
			Parent = row, Size = UDim2.new(0.5,0,0.4,0), Position = UDim2.new(0.05,0,0.5,0), BackgroundTransparency = 1,
			Text = "DMG: " .. (w.Damage or 0), Font = THEME.Fonts.Tech, TextSize = 12, TextColor3 = THEME.Colors.InkSecondary, TextXAlignment = Enum.TextXAlignment.Left
		})
	end
end

local function updateTitles()
	for _, c in pairs(titlePage:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	if not titleFunc then return end
	local success, data = pcall(function() return titleFunc:InvokeServer() end)
	if not success then data = {} end

	local current = data.EquippedTitle or ""
	titleLabel.Text = current ~= "" and current or "NO DESIGNATION"

	local unequip = create("TextButton", {
		Parent = titlePage, Size = UDim2.new(1,0,0,30), BackgroundColor3 = THEME.Colors.InkSecondary,
		Text = "REVOKE CURRENT", Font = THEME.Fonts.Typewriter, TextSize = 14, TextColor3 = Color3.new(1,1,1)
	})
	addCorner(unequip, 4)
	unequip.MouseButton1Click:Connect(function()
		if equipTitleEvent then equipTitleEvent:FireServer("") end
		task.wait(0.1)
		updateTitles()
	end)

	for _, t in ipairs(data.UnlockedTitles or {}) do
		local isActive = (t == current)
		local btn = create("TextButton", {
			Parent = titlePage, Size = UDim2.new(1,0,0,35),
			BackgroundColor3 = isActive and THEME.Colors.AccentHighlight or Color3.fromRGB(240,240,240),
			Text = t, Font = THEME.Fonts.Typewriter, TextSize = 16, TextColor3 = THEME.Colors.InkPrimary
		})
		addCorner(btn, 4)
		btn.MouseButton1Click:Connect(function()
			if equipTitleEvent then equipTitleEvent:FireServer(t) end
			task.wait(0.1)
			updateTitles()
		end)
	end
end

--================================================================================--
--[[ ANIMATION & CONTROL ]]--
--================================================================================--
local isOpen = false
local charClone = nil

local function updateViewport()
	if charClone then charClone:Destroy() end
	if worldModel then
		charClone = setupCharacterModel(worldModel)
		-- Adjust Camera
		local hrp = charClone:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Frontal view
			local cf = hrp.CFrame * CFrame.new(0, 1.5, -4.5) * CFrame.Angles(0, math.pi, 0)
			cam.CFrame = cf
		end
	end
end

local function toggle()
	isOpen = not isOpen

	if isOpen then
		gui.Enabled = true
		overlay.Visible = true
		if blurEffect then blurEffect.Enabled = true end

		TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.3}):Play()

		updateViewport()
		updateStats()
		updateWeapons()
		updateTitles()

		-- Slide Up Animation
		mainFolder.Position = UDim2.new(0.5, 0, 1.5, 0)
		mainFolder.Rotation = math.random(-5, 5)

		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(mainFolder, tweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = math.random(-1, 1)}):Play()

	else
		-- Slide Down
		local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		TweenService:Create(mainFolder, tweenInfo, {Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
		TweenService:Create(overlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()

		task.wait(0.4)
		overlay.Visible = false
		if blurEffect then blurEffect.Enabled = false end
		-- Do NOT disable GUI, otherwise the HUD button disappears
	end
end

closeBtn.MouseButton1Click:Connect(toggle)

-- HUD Button (Folder Icon on Screen)
local hudBtn = create("TextButton", {
	Name = "ProfileHUD", Parent = gui, Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0.5, -30),
	BackgroundColor3 = THEME.Colors.FolderDark, Text = ""
})
addCorner(hudBtn, 8)
addStroke(hudBtn, THEME.Colors.Paper, 2)
create("TextLabel", {
	Parent = hudBtn, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
	Text = "FILE", Font = THEME.Fonts.Stamp, TextSize = 14, TextColor3 = THEME.Colors.Paper
})
-- Paper sticking out
create("Frame", {
	Parent = hudBtn, Size = UDim2.new(0.8,0,0.8,0), Position = UDim2.new(0.1,0,-0.1,0), ZIndex = 0,
	BackgroundColor3 = THEME.Colors.Paper
})

hudBtn.MouseButton1Click:Connect(toggle)
gui.Enabled = true -- Ensure HUD is visible, main folder starts off-screen/hidden logic

print("ProfileUI (Confidential Dossier) Loaded")
