-- ProfileUI.lua (LocalScript)
-- Path: StarterGui/ProfileUI.lua
-- Script Place: Lobby
-- Theme: "Survivor's Dossier" (Zombie Apocalypse)
-- Re-designed for immersion and character.

--[[ SERVICES ]]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--[[ LOCAL PLAYER ]]--
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--[[ CONSTANTS ]]--
-- Only run this script in the Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then
	script:Destroy()
	return
end

--[[ ASSETS & REMOTE EVENTS ]]--
local profileRemoteFunction = ReplicatedStorage:WaitForChild("GetProfileData")
local getTitleDataFunc = ReplicatedStorage:WaitForChild("GetTitleData")
local setEquippedTitleEvent = ReplicatedStorage:WaitForChild("SetEquippedTitle")
local getWeaponStatsFunc = ReplicatedStorage:WaitForChild("GetWeaponStats")
local LevelUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("LevelUpdateEvent")

--[[ THEME CONFIGURATION ]]--
local THEME = {
	Colors = {
		Folder = Color3.fromRGB(235, 225, 195),    -- Manila Folder
		Paper = Color3.fromRGB(250, 248, 240),     -- Fresh Paper
		Ink = Color3.fromRGB(25, 25, 30),          -- Typewriter Ink
		RedInk = Color3.fromRGB(180, 40, 40),      -- Stamp Ink
		Pencil = Color3.fromRGB(80, 80, 85),       -- Graphite
		Tape = Color3.fromRGB(220, 210, 160),      -- Masking Tape
		DarkBg = Color3.fromRGB(30, 30, 35),       -- Background Overlay
		Highlight = Color3.fromRGB(240, 180, 50),  -- Highlighter Yellow/Orange
	},
	Fonts = {
		Header = Enum.Font.SpecialElite,   -- Typewriter (Headers)
		Body = Enum.Font.SpecialElite,     -- Typewriter (Body)
		Hand = Enum.Font.AmaticSC,         -- Handwritten Notes
		Stamp = Enum.Font.Bangers,         -- Stamps
		Digital = Enum.Font.Code,          -- Tech bits if any
	},
	Sizes = {
		Header = 32,
		SubHeader = 24,
		Body = 18,
		Note = 28
	}
}

-- Fallback font check
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

--================================================================================--
--[[ HELPER FUNCTIONS (VISUALS) ]]--
--================================================================================--

local function create(instanceType, properties)
	local obj = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		obj[prop] = value
	end
	return obj
end

local function formatNumber(n)
	n = tonumber(n) or 0
	if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
	if n >= 1000 then return string.format("%.1fK", n / 1000) end
	return tostring(n)
end

-- Adds a rough, hand-drawn style border
local function addRoughBorder(parent, color, thickness)
	local stroke = create("UIStroke", {
		Parent = parent,
		Color = color or THEME.Colors.Ink,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0.3
	})
	return stroke
end

-- Adds a piece of masking tape
local function addTape(parent, positionUDim2, rotation, color)
	local tape = create("Frame", {
		Name = "Tape",
		Parent = parent,
		Size = UDim2.new(0, 60, 0, 18),
		Position = positionUDim2,
		BackgroundColor3 = color or THEME.Colors.Tape,
		BorderSizePixel = 0,
		Rotation = rotation or math.random(-15, 15),
		ZIndex = (parent.ZIndex or 1) + 1
	})
	tape.BackgroundTransparency = 0.1
	create("UICorner", {Parent = tape, CornerRadius = UDim.new(0, 2)})
	-- Crinkle texture simulation (optional, kept simple for now)
	return tape
end

-- Creates a "Polaroid" photo frame
local function createPolaroid(parent, size, pos)
	local frame = create("Frame", {
		Name = "Polaroid",
		Parent = parent,
		Size = size,
		Position = pos,
		BackgroundColor3 = Color3.fromRGB(245, 245, 250), -- Photo paper white
		BorderSizePixel = 0,
		Rotation = math.random(-3, 3)
	})
	-- Drop Shadow
	local shadow = create("Frame", {
		Parent = frame, ZIndex = frame.ZIndex - 1,
		Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, 2, 0, 4),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.7
	})
	create("UICorner", {Parent=shadow, CornerRadius=UDim.new(0, 2)})

	-- Inner Photo Area
	local photoArea = create("ImageLabel", {
		Name = "PhotoArea",
		Parent = frame,
		Size = UDim2.new(0.9, 0, 0.75, 0),
		Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 25),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(200, 200, 200),
		Image = "",
		ScaleType = Enum.ScaleType.Crop
	})

	return frame, photoArea
end

-- Creates a "Stamp" effect
local function addStamp(parent, text, position, color, rotation)
	local stamp = create("TextLabel", {
		Name = "Stamp_"..text,
		Parent = parent,
		Size = UDim2.new(0, 120, 0, 40),
		Position = position,
		Rotation = rotation or math.random(-20, -10),
		BackgroundTransparency = 1,
		Text = text,
		Font = getFont("Stamp"),
		TextSize = THEME.Sizes.Note,
		TextColor3 = color or THEME.Colors.RedInk,
		TextTransparency = 0.15
	})
	create("UIStroke", {
		Parent = stamp, Color = color or THEME.Colors.RedInk, 
		Thickness = 2, Transparency = 0.15
	})
	-- Rough border for the stamp box visual
	local box = create("Frame", {
		Parent = stamp, Size = UDim2.new(1, 10, 1, 0), Position = UDim2.new(0, -5, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = -1
	})
	addRoughBorder(box, color or THEME.Colors.RedInk, 3)
	return stamp
end

--================================================================================--
--[[ UI GENERATION ]]--
--================================================================================--

local profileScreenGui = create("ScreenGui", {
	Name = "ProfileUI_Dossier",
	Parent = playerGui,
	Enabled = true,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
})

-- Dark overlay background
local backgroundOverlay = create("Frame", {
	Name = "Overlay",
	Parent = profileScreenGui,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = THEME.Colors.DarkBg,
	BackgroundTransparency = 1, -- Start hidden
	Visible = false
})

-- Main Dossier Folder
local mainFolder = create("Frame", {
	Name = "DossierFolder",
	Parent = backgroundOverlay,
	Size = UDim2.new(0, 850, 0, 550),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 1.5, 0), -- Start off-screen bottom
	BackgroundColor3 = THEME.Colors.Folder,
	BorderSizePixel = 0
})
create("UICorner", {Parent = mainFolder, CornerRadius = UDim.new(0, 4)})
-- Folder Shadow
local folderShadow = create("Frame", {
	Parent = mainFolder, ZIndex = -1,
	Size = UDim2.new(1, 20, 1, 20), Position = UDim2.new(0, -10, 0, 10),
	BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.6
})
create("UICorner", {Parent = folderShadow, CornerRadius = UDim.new(0, 16)})

-- Inner Folder Content (Paper)
local innerPaper = create("Frame", {
	Name = "InnerPaper",
	Parent = mainFolder,
	Size = UDim2.new(0.96, 0, 0.94, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = THEME.Colors.Paper,
})
-- Subtle texture or aging
addRoughBorder(innerPaper, Color3.fromRGB(200, 190, 170), 1)

-- Close Button (Red 'X' drawn in corner)
local closeButton = create("TextButton", {
	Parent = mainFolder,
	Size = UDim2.new(0, 40, 0, 40),
	Position = UDim2.new(1, -30, 0, -20),
	BackgroundTransparency = 1,
	Text = "X",
	Font = getFont("Hand"), -- Handwritten X
	TextSize = 48,
	TextColor3 = THEME.Colors.RedInk,
	Rotation = math.random(-10, 10),
	ZIndex = 10
})

--[[ LEFT SIDE: IDENTITY & PHOTO ]]--
local leftPanel = create("Frame", {
	Name = "LeftPanel",
	Parent = innerPaper,
	Size = UDim2.new(0.35, 0, 1, 0),
	BackgroundTransparency = 1
})
create("UIListLayout", {
	Parent = leftPanel, HorizontalAlignment = Enum.HorizontalAlignment.Center, 
	Padding = UDim.new(0, 20), SortOrder = Enum.SortOrder.LayoutOrder
})
create("UIPadding", {Parent = leftPanel, PaddingTop = UDim.new(0, 30)})

-- 1. Polaroid Photo
local polaroidFrame, avatarImage = createPolaroid(leftPanel, UDim2.new(0, 200, 0, 240), UDim2.new(0,0,0,0))
polaroidFrame.LayoutOrder = 1
addTape(polaroidFrame, UDim2.new(0.5, -30, 0, -8), -5) -- Tape at top

-- 2. Identity Card (Name & Title)
local idCard = create("Frame", {
	Name = "IDCard",
	Parent = leftPanel,
	Size = UDim2.new(0.85, 0, 0, 120),
	BackgroundColor3 = Color3.fromRGB(240, 240, 240),
	LayoutOrder = 2
})
addRoughBorder(idCard, THEME.Colors.Ink, 2)
addTape(idCard, UDim2.new(0, -10, 0, 10), 45) -- Tape corner
addTape(idCard, UDim2.new(1, -20, 1, -10), -45) -- Tape corner

-- Name Text
local nameHeader = create("TextLabel", {
	Parent = idCard, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 10),
	BackgroundTransparency = 1, Text = "SUBJECT NAME:",
	Font = getFont("Body"), TextSize = 14, TextColor3 = THEME.Colors.Pencil, TextXAlignment = Enum.TextXAlignment.Left
})
local nameLabel = create("TextLabel", {
	Parent = idCard, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 25),
	BackgroundTransparency = 1, Text = "SURVIVOR",
	Font = getFont("Header"), TextSize = 24, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Left
})

-- Title Text
local titleHeader = create("TextLabel", {
	Parent = idCard, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 60),
	BackgroundTransparency = 1, Text = "DESIGNATION:",
	Font = getFont("Body"), TextSize = 14, TextColor3 = THEME.Colors.Pencil, TextXAlignment = Enum.TextXAlignment.Left
})
local titleLabel = create("TextLabel", {
	Parent = idCard, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 75),
	BackgroundTransparency = 1, Text = "NONE",
	Font = getFont("Hand"), TextSize = 28, TextColor3 = THEME.Colors.RedInk, TextXAlignment = Enum.TextXAlignment.Left
})

-- 3. Clearance Level (Level & XP)
local levelFrame = create("Frame", {
	Name = "LevelFrame",
	Parent = leftPanel, Size = UDim2.new(0.85, 0, 0, 60),
	BackgroundTransparency = 1, LayoutOrder = 3
})
local levelText = create("TextLabel", {
	Parent = levelFrame, Size = UDim2.new(1, 0, 0, 25),
	BackgroundTransparency = 1, Text = "CLEARANCE LEVEL: 0",
	Font = getFont("Body"), TextSize = 20, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Left
})
-- XP Bar (Hand-drawn style)
local xpBarBg = create("Frame", {
	Parent = levelFrame, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(220, 220, 220), BorderSizePixel = 0
})
addRoughBorder(xpBarBg, THEME.Colors.Ink, 1)
local xpBarFill = create("Frame", {
	Parent = xpBarBg, Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = THEME.Colors.Highlight, BorderSizePixel = 0
})
local xpText = create("TextLabel", {
	Parent = xpBarBg, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 5, 0, 0),
	BackgroundTransparency = 1, Text = "0/0",
	Font = getFont("Digital"), TextSize = 12, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Right
})


--[[ RIGHT SIDE: DATA TABS ]]--
local rightPanel = create("Frame", {
	Name = "RightPanel",
	Parent = innerPaper,
	Size = UDim2.new(0.65, 0, 1, 0), Position = UDim2.new(0.35, 0, 0, 0),
	BackgroundTransparency = 1
})

-- Tab Container (Tabs stick out of the top/right)
local tabContainer = create("Frame", {
	Name = "Tabs",
	Parent = rightPanel,
	Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 20),
	BackgroundTransparency = 1
})
local tabLayout = create("UIListLayout", {
	Parent = tabContainer, FillDirection = Enum.FillDirection.Horizontal, 
	Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder
})

-- Content Pages Container
local pagesContainer = create("Frame", {
	Name = "Pages",
	Parent = rightPanel,
	Size = UDim2.new(1, -20, 0.85, 0), Position = UDim2.new(0, 10, 0, 70),
	BackgroundTransparency = 1
})
-- Add a separator line
local separator = create("Frame", {
	Parent = rightPanel, Size = UDim2.new(0.95, 0, 0, 2), Position = UDim2.new(0.025, 0, 0, 65),
	BackgroundColor3 = THEME.Colors.Pencil, BackgroundTransparency = 0.5, BorderSizePixel = 0
})

-- PAGE 1: SERVICE RECORD (Stats)
local statsPage = create("ScrollingFrame", {
	Name = "StatsPage", Parent = pagesContainer, Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.Pencil, Visible = true
})
create("UIListLayout", {Parent = statsPage, Padding = UDim.new(0, 10)})

local function createStatRow(iconId, name, value)
	local row = create("Frame", {
		Parent = statsPage, Size = UDim2.new(1, -10, 0, 40), BackgroundTransparency = 1
	})
	-- Dotted line bottom
	local line = create("Frame", {
		Parent = row, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.Colors.Pencil, BackgroundTransparency = 0.7, BorderSizePixel = 0
	})

	local label = create("TextLabel", {
		Parent = row, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, Text = name .. ":",
		Font = getFont("Body"), TextSize = 18, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Left
	})
	local valLabel = create("TextLabel", {
		Parent = row, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
		BackgroundTransparency = 1, Text = value,
		Font = getFont("Header"), TextSize = 22, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Right
	})
	return row
end

-- PAGE 2: WEAPON PROFICIENCY
local weaponPage = create("ScrollingFrame", {
	Name = "WeaponPage", Parent = pagesContainer, Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.Pencil, Visible = false
})
create("UIListLayout", {Parent = weaponPage, Padding = UDim.new(0, 15)})

-- PAGE 3: TITLES & MEDALS
local titlesPage = create("ScrollingFrame", {
	Name = "TitlesPage", Parent = pagesContainer, Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.Pencil, Visible = false
})
create("UIListLayout", {Parent = titlesPage, Padding = UDim.new(0, 10)})
create("UIPadding", {Parent = titlesPage, PaddingRight = UDim.new(0, 10)})

local unequipTitleBtn = create("TextButton", {
	Name = "UnequipTitle",
	Parent = titlesPage, Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = THEME.Colors.Ink, Text = "REVOKE DESIGNATION",
	Font = getFont("Stamp"), TextSize = 20, TextColor3 = THEME.Colors.Paper, LayoutOrder = 0
})
create("UICorner", {Parent = unequipTitleBtn, CornerRadius = UDim.new(0, 4)})


-- TAB LOGIC
local tabs = {
	{name = "SERVICE RECORD", page = statsPage},
	{name = "WEAPONRY", page = weaponPage},
	{name = "DESIGNATIONS", page = titlesPage},
}

local activeTabBtn = nil

for i, t in ipairs(tabs) do
	local btn = create("TextButton", {
		Name = "Tab_"..t.name,
		Parent = tabContainer,
		Size = UDim2.new(0.32, 0, 1, 0),
		BackgroundColor3 = THEME.Colors.Folder, -- Same as folder color to look attached
		Text = t.name,
		Font = getFont("Header"),
		TextSize = 16,
		TextColor3 = THEME.Colors.Pencil,
		ZIndex = 2
	})
	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

	-- Cover bottom to blend with folder
	local cover = create("Frame", {
		Parent = btn, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.9, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0, ZIndex = 3, Visible = false
	})

	btn.MouseButton1Click:Connect(function()
		-- Reset all
		for _, child in ipairs(tabContainer:GetChildren()) do
			if child:IsA("TextButton") then
				child.TextColor3 = THEME.Colors.Pencil
				child.BackgroundColor3 = THEME.Colors.Folder
				local c = child:FindFirstChild("Frame")
				if c then c.Visible = false end
				-- Lower visual position
				child:TweenPosition(UDim2.new(child.Position.X.Scale, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
			end
		end

		-- Activate this
		btn.TextColor3 = THEME.Colors.Ink
		btn.BackgroundColor3 = THEME.Colors.Paper -- Blend with inner paper
		cover.Visible = true
		-- Pop up visual position
		btn:TweenPosition(UDim2.new(btn.Position.X.Scale, 0, -0.1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.2, true)

		-- Show Page
		for _, tab in ipairs(tabs) do
			tab.page.Visible = (tab.name == t.name)
		end
	end)

	if i == 1 then
		-- Default active
		btn.TextColor3 = THEME.Colors.Ink
		btn.BackgroundColor3 = THEME.Colors.Paper
		cover.Visible = true
		btn.Position = UDim2.new(btn.Position.X.Scale, 0, -0.1, 0)
	end
end


--================================================================================--
--[[ PROFILE BUTTON ]]--
--================================================================================--

local profileButton = create("TextButton", {
	Name = "ViewDossierBtn",
	Parent = profileScreenGui,
	Size = UDim2.new(0, 200, 0, 50),
	Position = UDim2.new(0.02, 0, 0.5, 0),
	BackgroundColor3 = THEME.Colors.Folder,
	Text = "PERSONNEL FILE",
	Font = getFont("Stamp"),
	TextSize = 24,
	TextColor3 = THEME.Colors.Ink
})
addRoughBorder(profileButton, THEME.Colors.Ink, 2)
addTape(profileButton, UDim2.new(0.5, -30, -0.2, 0), 2)


--================================================================================--
--[[ LOGIC & DATA HANDLING ]]--
--================================================================================--

local function updateData()
	local success, profileData = pcall(function() return profileRemoteFunction:InvokeServer() end)
	if success and profileData then
		-- Identity
		nameLabel.Text = string.upper(profileData.Name or player.Name)
		levelText.Text = "CLEARANCE LEVEL: " .. (profileData.Level or 0)

		local xp = profileData.XP or 0
		local needed = profileData.XPForNextLevel or 1000
		local ratio = math.clamp(xp / needed, 0, 1)
		xpBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		xpText.Text = string.format("%s / %s", formatNumber(xp), formatNumber(needed))

		-- Stats Page
		for _, c in ipairs(statsPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

		local statList = {
			{"CONFIRMED KILLS", profileData.TotalKills},
			{"DAMAGE OUTPUT", profileData.TotalDamageDealt},
			{"MISSION WINS", profileData.TotalWins or 0}, -- If available
			{"TIMES KNOCKED", profileData.TotalKnocks},
			{"REVIVES PERFORMED", profileData.TotalRevives},
			{"COINS ACCUMULATED", profileData.TotalCoins},
			{"ACHIEVEMENT PTS", profileData.LifetimeAP},
		}

		for _, s in ipairs(statList) do
			createStatRow(nil, s[1], formatNumber(s[2]))
		end

		-- Add a stamp if high level
		if (profileData.Level or 0) > 50 then
			if not leftPanel:FindFirstChild("Stamp_VETERAN") then
				addStamp(leftPanel, "VETERAN", UDim2.new(0.5, -60, 0.4, 0), THEME.Colors.RedInk, -15)
			end
		end
	end
end

local function updateTitles()
	-- Clean
	for _, c in ipairs(titlesPage:GetChildren()) do if c.Name ~= "UnequipTitle" and c:IsA("TextButton") then c:Destroy() end end

	local success, titleData = pcall(function() return getTitleDataFunc:InvokeServer() end)
	if not success then return end

	local current = titleData.EquippedTitle or ""
	titleLabel.Text = current ~= "" and current or "NONE"

	for _, t in ipairs(titleData.UnlockedTitles or {}) do
		local btn = create("TextButton", {
			Name = t, Parent = titlesPage, Size = UDim2.new(1, -10, 0, 35),
			BackgroundColor3 = (t == current) and THEME.Colors.Highlight or Color3.fromRGB(240, 240, 240),
			Text = t, Font = getFont("Body"), TextSize = 18, TextColor3 = THEME.Colors.Ink
		})
		create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})

		btn.MouseButton1Click:Connect(function()
			setEquippedTitleEvent:FireServer(t)
			updateTitles()
		end)
	end
end

unequipTitleBtn.MouseButton1Click:Connect(function()
	setEquippedTitleEvent:FireServer("")
	updateTitles()
end)

local function updateWeapons()
	for _, c in ipairs(weaponPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	local success, wStats = pcall(function() return getWeaponStatsFunc:InvokeServer() end)
	if not success or not wStats then 
		local empty = create("TextLabel", {
			Parent = weaponPage, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1,
			Text = "NO DATA AVAILABLE", Font = getFont("Hand"), TextSize = 24, TextColor3 = THEME.Colors.Pencil
		})
		return 
	end

	-- Sort by kills
	table.sort(wStats, function(a,b) return (a.Kills or 0) > (b.Kills or 0) end)

	for _, w in ipairs(wStats) do
		local row = create("Frame", {
			Parent = weaponPage, Size = UDim2.new(1, -10, 0, 50), BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		})
		create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 4)})

		local name = create("TextLabel", {
			Parent = row, Size = UDim2.new(0.5, 0, 0.6, 0), Position = UDim2.new(0.05, 0, 0.1, 0),
			BackgroundTransparency = 1, Text = w.Name, Font = getFont("Header"), TextSize = 20, TextColor3 = THEME.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Left
		})
		local kills = create("TextLabel", {
			Parent = row, Size = UDim2.new(0.4, 0, 0.6, 0), Position = UDim2.new(0.55, 0, 0.1, 0),
			BackgroundTransparency = 1, Text = formatNumber(w.Kills).." KILLS", Font = getFont("Body"), TextSize = 18, TextColor3 = THEME.Colors.RedInk, TextXAlignment = Enum.TextXAlignment.Right
		})
		local dmg = create("TextLabel", {
			Parent = row, Size = UDim2.new(0.9, 0, 0.3, 0), Position = UDim2.new(0.05, 0, 0.6, 0),
			BackgroundTransparency = 1, Text = "TOTAL DAMAGE: "..formatNumber(w.Damage), Font = getFont("Body"), TextSize = 12, TextColor3 = THEME.Colors.Pencil, TextXAlignment = Enum.TextXAlignment.Left
		})
	end
end

local function updateAvatar()
	local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	if isReady then avatarImage.Image = content end
end

-- ANIMATION CONTROLS
local isOpen = false

local function toggleUI()
	isOpen = not isOpen

	if isOpen then
		updateData()
		updateTitles()
		updateWeapons()
		updateAvatar()

		backgroundOverlay.Visible = true
		TweenService:Create(backgroundOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()

		mainFolder.Position = UDim2.new(0.5, 0, 1.5, 0)
		mainFolder.Rotation = math.random(-5, 5)
		TweenService:Create(mainFolder, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = math.random(-2, 2)
		}):Play()
	else
		TweenService:Create(backgroundOverlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		TweenService:Create(mainFolder, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1.5, 0)
		}):Play()
		task.wait(0.5)
		backgroundOverlay.Visible = false
	end
end

profileButton.MouseButton1Click:Connect(toggleUI)
closeButton.MouseButton1Click:Connect(toggleUI)

print("ProfileUI (Dossier Theme) Loaded")
