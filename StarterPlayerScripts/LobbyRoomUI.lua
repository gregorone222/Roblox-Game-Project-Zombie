-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterPlayerScripts/LobbyRoomUI.lua
-- Script Place: Lobby
-- Theme: Modern Tactical Investigation (Clean Folder/Clipboard Style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		Background   = Color3.fromRGB(40, 40, 45),       -- Dark surrounding
		FolderMain   = Color3.fromRGB(210, 180, 140),    -- Manila Folder
		FolderDark   = Color3.fromRGB(180, 150, 110),    -- Tab darker shade
		Paper        = Color3.fromRGB(245, 245, 240),    -- Clean Paper
		PaperDark    = Color3.fromRGB(230, 230, 225),    -- Alt Paper
		TextMain     = Color3.fromRGB(30, 30, 35),       -- Ink
		TextDim      = Color3.fromRGB(100, 100, 100),    -- Pencil/Faded
		AccentRed    = Color3.fromRGB(200, 60, 60),      -- Alert/Cancel
		AccentGreen  = Color3.fromRGB(60, 160, 80),      -- Success/Go
		Highlight    = Color3.fromRGB(255, 230, 100),    -- Sticky Note
	},
	Fonts = {
		Header = Enum.Font.SpecialElite,   -- Typewriter (Narrative feel)
		Body   = Enum.Font.GothamMedium,   -- Clean Sans-Serif (Readability)
		Label  = Enum.Font.GothamBold,     -- UI Labels
		Stamp  = Enum.Font.GothamBlack     -- Stamped status (Fallback to generic if needed)
	},
	Sizes = {
		MainFrame = UDim2.new(0.85, 0, 0.8, 0), -- Reduced size for mobile safety
	}
}

-- Fallback for specific fonts if not available
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

-- ================== STATE MANAGEMENT ==================
local state = {
	isUIOpen = false,
	activeTab = "OPS",
	currentRoom = nil,
	settings = {
		gameMode = "Story",
		difficulty = "Easy"
	},
	blurEffect = nil
}

-- UI References
local gui
local mainFrame
local contentContainer
local tabs = {}
local panels = {}

-- ================== HELPER FUNCTIONS ==================

local function create(className, properties, children)
	local inst = Instance.new(className)
	for k, v in pairs(properties) do
		inst[k] = v
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

local function addAspectRatio(parent, ratio)
	create("UIAspectRatioConstraint", {
		Parent = parent, AspectRatio = ratio, AspectType = Enum.AspectType.FitWithinMaxSize, DominantAxis = Enum.DominantAxis.Width
	})
end

local function playSound(id)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Parent = playerGui
	sound:Play()
	Debris:AddItem(sound, 2)
end

-- ================== COMPONENT FACTORY ==================

-- Standard "Paper" Button
local function createButton(parent, text, size, pos, color, callback)
	local btn = create("TextButton", {
		Name = "Btn_"..text, Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = color or THEME.Colors.Paper, AutoButtonColor = true,
		BorderSizePixel = 0
	})

	-- Shadow
	create("Frame", {
		Parent = btn, ZIndex = btn.ZIndex - 1, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.02, 0, 0.05, 0),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.8, BorderSizePixel = 0
	})

	-- Text
	create("TextLabel", {
		Parent = btn, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = text, Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextMain
	})

	-- Constraint text size
	create("UITextSizeConstraint", {Parent = btn.TextLabel, MaxTextSize = 24})

	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0.1, 0)})

	btn.MouseButton1Click:Connect(function()
		-- playSound(SOUNDS.Click)
		if callback then callback() end
	end)

	return btn
end

-- Tab Button
local function createTab(parent, id, text, layoutOrder)
	local isActive = (state.activeTab == id)
	-- Use Scale for size
	local btn = create("TextButton", {
		Name = "Tab_"..id, Parent = parent, Size = UDim2.new(0.3, 0, 1, 0),
		BackgroundColor3 = isActive and THEME.Colors.FolderMain or THEME.Colors.FolderDark,
		BorderSizePixel = 0, LayoutOrder = layoutOrder, AutoButtonColor = false,
		ZIndex = isActive and 2 or 1
	})

	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0.2, 0)})
	-- Hide bottom corners to blend with folder
	create("Frame", {
		Parent = btn, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = isActive and THEME.Colors.FolderMain or THEME.Colors.FolderDark,
		BorderSizePixel = 0, ZIndex = isActive and 2 or 1
	})

	create("TextLabel", {
		Parent = btn, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0,0,0,0),
		BackgroundTransparency = 1, Text = text, Font = getFont("Header"), TextScaled = true,
		TextColor3 = THEME.Colors.TextMain, ZIndex = isActive and 3 or 2
	})
	create("UITextSizeConstraint", {Parent = btn.TextLabel, MaxTextSize = 18})

	btn.MouseButton1Click:Connect(function()
		if state.activeTab == id then return end
		state.activeTab = id

		-- Update Visuals
		for tid, tabBtn in pairs(tabs) do
			local active = (tid == id)
			tabBtn.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.ZIndex = active and 2 or 1
			tabBtn.Frame.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.Frame.ZIndex = active and 2 or 1
			tabBtn.TextLabel.ZIndex = active and 3 or 2
		end

		-- Switch Panels
		for pid, panel in pairs(panels) do
			panel.Visible = (pid == id)
		end
	end)

	tabs[id] = btn
	return btn
end

-- ================== PANELS ==================

local function createOpsPanel(parent)
	local panel = create("Frame", {
		Name = "OpsPanel", Parent = parent, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Visible = false
	})
	panels["OPS"] = panel

	-- LEFT COLUMN: Mission Config
	local leftCol = create("Frame", {
		Parent = panel, Size = UDim2.new(0.4, 0, 0.95, 0), Position = UDim2.new(0.02, 0, 0.025, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0
	})
	create("UICorner", {Parent = leftCol, CornerRadius = UDim.new(0.05, 0)})

	-- Header
	local header = create("TextLabel", {
		Parent = leftCol, Size = UDim2.new(1, 0, 0.1, 0), BackgroundTransparency = 1,
		Text = "MISSION PARAMETERS", Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain
	})
	create("UITextSizeConstraint", {Parent = header, MaxTextSize = 22})

	create("Frame", { -- Divider
		Parent = leftCol, Size = UDim2.new(0.9, 0, 0.005, 0), Position = UDim2.new(0.05, 0, 0.1, 0),
		BackgroundColor3 = THEME.Colors.TextDim, BackgroundTransparency = 0.8, BorderSizePixel = 0
	})

	local formList = create("UIListLayout", {
		Parent = leftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.03, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center
	})

	-- Padding Frame
	create("Frame", {Parent = leftCol, Size = UDim2.new(1,0,0.1,0), LayoutOrder = 0, BackgroundTransparency = 1})

	-- Helper for Options
	local function createOption(label, options, key, layout)
		local container = create("Frame", {
			Parent = leftCol, Size = UDim2.new(0.9, 0, 0.15, 0), BackgroundTransparency = 1, LayoutOrder = layout
		})
		local lbl = create("TextLabel", {
			Parent = container, Size = UDim2.new(1, 0, 0.3, 0), Text = label,
			Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = lbl, MaxTextSize = 14})

		local btnContainer = create("Frame", {
			Parent = container, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.new(0, 0, 0.4, 0), BackgroundTransparency = 1
		})
		create("UIListLayout", {
			Parent = btnContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.05, 0)
		})

		local optionBtns = {}

		for _, opt in ipairs(options) do
			local btn = create("TextButton", {
				Parent = btnContainer, Size = UDim2.new(1/#options - 0.05, 0, 1, 0),
				BackgroundColor3 = (state.settings[key] == opt) and THEME.Colors.TextMain or THEME.Colors.PaperDark,
				BorderSizePixel = 0, Text = opt, Font = getFont("Body"), TextScaled = true,
				TextColor3 = (state.settings[key] == opt) and THEME.Colors.Paper or THEME.Colors.TextMain
			})
			create("UICorner", {Parent = btn, CornerRadius = UDim.new(0.2, 0)})
			-- TextButton native text logic fix
			create("UITextSizeConstraint", {Parent = btn, MaxTextSize = 14})

			btn.MouseButton1Click:Connect(function()
				state.settings[key] = opt
				-- Refresh visuals
				for _, b in ipairs(optionBtns) do
					local isSel = (b.Text == opt)
					b.BackgroundColor3 = isSel and THEME.Colors.TextMain or THEME.Colors.PaperDark
					b.TextColor3 = isSel and THEME.Colors.Paper or THEME.Colors.TextMain
				end
			end)
			table.insert(optionBtns, btn)
		end
	end

	createOption("OPERATION MODE", {"Story", "Crazy"}, "gameMode", 1)
	createOption("THREAT LEVEL", {"Easy", "Normal", "Hard"}, "difficulty", 2)

	-- Solo Start Button (Bottom)
	-- Using LayoutOrder to push it down
	local spacer = create("Frame", {Parent = leftCol, Size = UDim2.new(1,0,0.1,0), LayoutOrder = 3, BackgroundTransparency = 1})

	local soloBtn = createButton(leftCol, "DEPLOY SOLO", UDim2.new(0.9, 0, 0.12, 0), UDim2.new(0,0,0,0), THEME.Colors.TextMain, function()
		local btn = leftCol:FindFirstChild("Btn_DEPLOY SOLO")
		if btn then
			btn.TextLabel.Text = "INITIALIZING..."
			btn.BackgroundColor3 = THEME.Colors.TextDim
		end
		lobbyRemote:FireServer("startSoloGame", {gameMode = state.settings.gameMode, difficulty = state.settings.difficulty})
	end)
	soloBtn.LayoutOrder = 4
	soloBtn.TextLabel.TextColor3 = THEME.Colors.Paper

	-- RIGHT COLUMN: Public Rooms
	local rightCol = create("Frame", {
		Name = "RightCol",
		Parent = panel, Size = UDim2.new(0.55, 0, 0.95, 0), Position = UDim2.new(0.44, 0, 0.025, 0),
		BackgroundTransparency = 1
	})

	local listHeader = create("TextLabel", {
		Parent = rightCol, Size = UDim2.new(1, 0, 0.08, 0), Text = "DISTRESS SIGNALS (PUBLIC LOBBIES)",
		Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = listHeader, MaxTextSize = 18})

	local scroll = create("ScrollingFrame", {
		Name = "RoomList", Parent = rightCol, Size = UDim2.new(1, 0, 0.9, 0), Position = UDim2.new(0, 0, 0.1, 0),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.TextMain,
		CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIGridLayout", {
		Parent = scroll, CellSize = UDim2.new(1, 0, 0.15, 0), CellPadding = UDim2.new(0, 0, 0.02, 0)
	})
end

local function createLobbyPanel(parent)
	local panel = create("Frame", {
		Name = "LobbyPanel", Parent = parent, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Visible = false
	})
	panels["LOBBY"] = panel

	-- Info Card (Left)
	local infoCard = create("Frame", {
		Parent = panel, Size = UDim2.new(0.3, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0
	})
	create("UICorner", {Parent = infoCard, CornerRadius = UDim.new(0.05, 0)})

	-- Adjusted positions for Title and Details to prevent overlap
	local roomTitle = create("TextLabel", {
		Name = "RoomTitle", Parent = infoCard, Size = UDim2.new(0.9, 0, 0.12, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		Text = "ROOM NAME", Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", {Parent = roomTitle, MaxTextSize = 20})

	local roomDetails = create("TextLabel", {
		Name = "RoomDetails", Parent = infoCard, Size = UDim2.new(0.9, 0, 0.3, 0), Position = UDim2.new(0.05, 0, 0.20, 0), -- Moved down
		Text = "Mode: Story\nDiff: Easy", Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextDim, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
	})
	create("UITextSizeConstraint", {Parent = roomDetails, MaxTextSize = 16})

	-- Leave Button
	createButton(infoCard, "LEAVE SQUAD", UDim2.new(0.9, 0, 0.1, 0), UDim2.new(0.05, 0, 0.88, 0), THEME.Colors.AccentRed, function()
		lobbyRemote:FireServer("leaveRoom")
	end).TextLabel.TextColor3 = THEME.Colors.Paper

	-- Roster Area (Right)
	local rosterArea = create("Frame", {
		Parent = panel, Size = UDim2.new(0.65, 0, 0.9, 0), Position = UDim2.new(0.34, 0, 0.05, 0),
		BackgroundTransparency = 1
	})

	local rosterHeader = create("TextLabel", {
		Parent = rosterArea, Size = UDim2.new(1, 0, 0.08, 0), Text = "PERSONNEL ROSTER",
		Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextDim, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = rosterHeader, MaxTextSize = 14})

	local rosterGrid = create("ScrollingFrame", {
		Name = "RosterGrid", Parent = rosterArea, Size = UDim2.new(1, 0, 0.65, 0), Position = UDim2.new(0, 0, 0.1, 0), -- Shrunk height
		BackgroundTransparency = 1, ScrollBarThickness = 0
	})
	create("UIGridLayout", {
		Parent = rosterGrid, CellSize = UDim2.new(0.3, 0, 0.4, 0), CellPadding = UDim2.new(0.03, 0, 0.03, 0)
	})

	-- Action Button (Host) - Moved UP significantly
	local actionBtn = createButton(rosterArea, "START MISSION", UDim2.new(0.4, 0, 0.15, 0), UDim2.new(0.6, 0, 0.8, 0), THEME.Colors.AccentGreen, function()
		if state.currentRoom and state.currentRoom.hostName == player.Name then
			lobbyRemote:FireServer("forceStartGame")
		end
	end)
	actionBtn.Name = "ActionBtn"
	actionBtn.TextLabel.TextColor3 = THEME.Colors.Paper
	actionBtn.TextLabel.Font = getFont("Stamp")
end

local function createIntelPanel(parent)
	local panel = create("Frame", {
		Name = "IntelPanel", Parent = parent, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Visible = false
	})
	panels["INTEL"] = panel

	-- Split View: Map/Photo (Left) and Dossier (Right)
	local mapContainer = create("Frame", {
		Parent = panel, Size = UDim2.new(0.45, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0
	})
	create("UICorner", {Parent = mapContainer, CornerRadius = UDim.new(0.05, 0)})

	-- Map Photo
	local photoFrame = create("Frame", {
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.5, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundColor3 = Color3.new(0,0,0)
	})
	create("ImageLabel", {
		Parent = photoFrame, Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ScaleType = Enum.ScaleType.Crop
	})

	-- Map Stats
	local sectorLbl = create("TextLabel", {
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.08, 0), Position = UDim2.new(0.05, 0, 0.6, 0),
		Text = "SECTOR: VILLAGE [GROUND ZERO]", Font = getFont("Header"), TextScaled = true,
		TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = sectorLbl, MaxTextSize = 18})

	local hazardLbl = create("TextLabel", {
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.15, 0), Position = UDim2.new(0.05, 0, 0.7, 0),
		Text = "HAZARD: EXTREME RADIATION\nSTATUS: ACTIVE HOSTILES\nENTRY: PERMITTED", Font = getFont("Body"), TextScaled = true,
		TextColor3 = THEME.Colors.AccentRed, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = hazardLbl, MaxTextSize = 14})

	-- Right Side: Dossier / Objectives
	local dossier = create("Frame", {
		Parent = panel, Size = UDim2.new(0.5, 0, 0.9, 0), Position = UDim2.new(0.48, 0, 0.05, 0),
		BackgroundTransparency = 1
	})

	local actTitle = create("TextLabel", {
		Parent = dossier, Size = UDim2.new(1, 0, 0.1, 0), Text = "ACT 1: THE CURSED VILLAGE",
		Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = actTitle, MaxTextSize = 24})

	create("Frame", { -- Divider
		Parent = dossier, Size = UDim2.new(1, 0, 0.005, 0), Position = UDim2.new(0, 0, 0.11, 0),
		BackgroundColor3 = THEME.Colors.TextDim, BackgroundTransparency = 0.5, BorderSizePixel = 0
	})

	local descLbl = create("TextLabel", {
		Parent = dossier, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.14, 0),
		Text = "High energy readings detected. Source is located beneath the village square. Investigate the anomaly and neutralize any biological threats.",
		Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = descLbl, MaxTextSize = 14})

	-- Objectives List
	local objList = create("Frame", {
		Parent = dossier, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.new(0, 0, 0.35, 0), BackgroundTransparency = 1
	})

	local objLbl = create("TextLabel", {
		Parent = objList, Size = UDim2.new(1, 0, 1, 0),
		Text = "MISSION OBJECTIVES ARE CLASSIFIED.\n\nPROCEED TO DEPLOYMENT ZONE FOR BRIEFING.",
		Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.AccentRed,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = objLbl, MaxTextSize = 14})
end

-- ================== MAIN UI STRUCTURE ==================

local function createGUI()
	gui = create("ScreenGui", {
		Name = "LobbyRoomUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false,
		IgnoreGuiInset = false -- User Request: false
	})

	local camera = workspace.CurrentCamera
	state.blurEffect = create("BlurEffect", {Parent = camera, Size = 15, Enabled = false})

	-- Main Container (The Folder)
	mainFrame = create("Frame", {
		Name = "MainFrame", Parent = gui,
		Size = THEME.Sizes.MainFrame, -- 0.85/0.8
		Position = UDim2.new(0.5, 0, 0.55, 0), -- Moved slightly down (0.55) to clear top bar for Tabs
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Colors.FolderMain, BorderSizePixel = 0
	})
	create("UICorner", {Parent = mainFrame, CornerRadius = UDim.new(0.02, 0)})
	create("UIAspectRatioConstraint", {Parent = mainFrame, AspectRatio = 1.6, AspectType = Enum.AspectType.FitWithinMaxSize}) -- Widen aspect ratio

	-- Shadow behind main frame
	create("Frame", {
		Name = "Shadow", Parent = mainFrame, ZIndex = -1,
		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 10), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.6
	})
	create("UICorner", {Parent = mainFrame.Shadow, CornerRadius = UDim.new(0.02, 0)})

	-- Tab Container (Top)
	local tabContainer = create("Frame", {
		Parent = mainFrame, Size = UDim2.new(0.95, 0, 0.1, 0), Position = UDim2.new(0.025, 0, -0.09, 0),
		BackgroundTransparency = 1
	})
	local tabLayout = create("UIListLayout", {
		Parent = tabContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.01, 0)
	})

	createTab(tabContainer, "OPS", "OPS", 1)
	createTab(tabContainer, "LOBBY", "SQUAD", 2)
	createTab(tabContainer, "INTEL", "INTEL", 3)

	-- Content Container (Paper Sheet inside Folder)
	contentContainer = create("Frame", {
		Name = "Content", Parent = mainFrame,
		Size = UDim2.new(0.96, 0, 0.92, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5,0.5),
		BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0
	})
	create("UICorner", {Parent = contentContainer, CornerRadius = UDim.new(0.02, 0)})

	-- Close Button (Top Right of MainFrame)
	local closeBtn = create("TextButton", {
		Parent = mainFrame, Size = UDim2.new(0.05, 0, 0.08, 0), Position = UDim2.new(0.98, 0, 0.01, 0), AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1, Text = "X", Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextMain
	})
	create("UITextSizeConstraint", {Parent = closeBtn, MaxTextSize = 24})

	closeBtn.MouseButton1Click:Connect(function()
		state.isUIOpen = false
		gui.Enabled = false
		if state.blurEffect then state.blurEffect.Enabled = false end
	end)

	-- Initialize Panels
	createOpsPanel(contentContainer)
	createLobbyPanel(contentContainer)
	createIntelPanel(contentContainer)

	panels["OPS"].Visible = true
end

-- ================== VISUAL LOGIC ==================

function updateRoomList(roomsData)
	local panel = panels["OPS"]
	if not panel then return end
	local rightCol = panel:FindFirstChild("RightCol")
	local scroll = rightCol and rightCol:FindFirstChild("RoomList")
	if not scroll then return end

	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

	for _, room in pairs(roomsData) do
		local card = create("TextButton", {
			Parent = scroll, Size = UDim2.new(1, 0, 0.15, 0), BackgroundColor3 = THEME.Colors.Paper,
			AutoButtonColor = true, BorderSizePixel = 0
		})
		create("UICorner", {Parent = card, CornerRadius = UDim.new(0.1, 0)})
		-- Border via Frame
		create("Frame", {
			Parent = card, Size = UDim2.new(0.98, 0, 0.9, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 1, BorderColor3 = THEME.Colors.TextDim, ZIndex = 0
		})

		local title = create("TextLabel", {
			Parent = card, Size = UDim2.new(0.9, 0, 0.35, 0), Position = UDim2.new(0.05, 0, 0.1, 0),
			Text = room.roomName, Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = title, MaxTextSize = 16})

		local details = create("TextLabel", {
			Parent = card, Size = UDim2.new(0.9, 0, 0.3, 0), Position = UDim2.new(0.05, 0, 0.5, 0),
			Text = string.format("Host: %s | Mode: %s", room.hostName, room.gameMode),
			Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = details, MaxTextSize = 14})

		local count = create("TextLabel", {
			Parent = card, Size = UDim2.new(0.3, 0, 0.3, 0), Position = UDim2.new(0.65, 0, 0.4, 0),
			Text = room.playerCount.."/"..room.maxPlayers,
			Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
			TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = count, MaxTextSize = 20})

		card.MouseButton1Click:Connect(function()
			lobbyRemote:FireServer("joinRoom", {roomId = room.roomId})
		end)
	end
end

function updateLobbyView(roomData)
	local panel = panels["LOBBY"]
	if not panel then return end

	state.activeTab = "LOBBY"
	for pid, p in pairs(panels) do p.Visible = (pid == "LOBBY") end
	-- Update Tabs Visuals
	for tid, tabBtn in pairs(tabs) do
		local active = (tid == "LOBBY")
		tabBtn.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
		tabBtn.ZIndex = active and 2 or 1
		tabBtn.Frame.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
		tabBtn.Frame.ZIndex = active and 2 or 1
	end

	state.currentRoom = roomData
	local isHost = (roomData.hostName == player.Name)
	local infoCard = panel:FindFirstChild("Frame") -- Info Card
	local rosterArea = panel:FindFirstChild("Frame", true) -- Assuming second frame, better lookup needed
	-- Safer lookup:
	for _, c in ipairs(panel:GetChildren()) do
		if c:FindFirstChild("RoomTitle") then infoCard = c end
		if c:FindFirstChild("RosterGrid") then rosterArea = c end
	end

	if infoCard then
		infoCard.RoomTitle.Text = string.upper(roomData.roomName)
		infoCard.RoomDetails.Text = string.format("HOST: %s\nMODE: %s\nDIFF: %s", roomData.hostName, roomData.gameMode, roomData.difficulty)
	end

	if rosterArea then
		local actionBtn = rosterArea:FindFirstChild("ActionBtn")
		if actionBtn then
			local lbl = actionBtn:FindFirstChild("TextLabel")
			if isHost then
				lbl.Text = "START MISSION"
				actionBtn.BackgroundColor3 = THEME.Colors.AccentGreen
				actionBtn.AutoButtonColor = true
			else
				lbl.Text = "WAITING FOR HOST..."
				actionBtn.BackgroundColor3 = THEME.Colors.PaperDark
				actionBtn.AutoButtonColor = false
			end
		end

		local grid = rosterArea:FindFirstChild("RosterGrid")
		if grid then
			for _, c in ipairs(grid:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for _, pData in ipairs(roomData.players) do
				local polaroid = create("Frame", {
					Parent = grid, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
				})
				-- Shadow
				create("Frame", {
					Parent = polaroid, Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, 2, 0, 2), ZIndex = -1,
					BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.8
				})

				-- Photo (Placeholder)
				create("ImageLabel", {
					Parent = polaroid, Size = UDim2.new(0.9, 0, 0.75, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
					BackgroundColor3 = Color3.fromRGB(50, 50, 50), Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
				})

				create("TextLabel", {
					Parent = polaroid, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.8, 0),
					Text = pData.Name, Font = getFont("Hand"), TextScaled = true, TextColor3 = Color3.new(0,0,0),
					BackgroundTransparency = 1
				})
			end
		end
	end
end

-- ================== INIT & LISTENERS ==================

lobbyRemote.OnClientEvent:Connect(function(action, data)
	if action == "roomCreated" or action == "joinSuccess" then
		updateLobbyView(data)
	elseif action == "roomUpdate" then
		updateLobbyView(data)
	elseif action == "publicRoomsUpdate" then
		updateRoomList(data)
	elseif action == "leftRoomSuccess" then
		state.activeTab = "OPS"
		for pid, p in pairs(panels) do p.Visible = (pid == "OPS") end
		-- Reset Tab Visuals
		for tid, tabBtn in pairs(tabs) do
			local active = (tid == "OPS")
			tabBtn.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.ZIndex = active and 2 or 1
			tabBtn.Frame.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.Frame.ZIndex = active and 2 or 1
		end
	end
end)

createGUI()
lobbyRemote:FireServer("getPublicRooms")

-- Part Interaction Logic
task.spawn(function()
	local part = nil
	while not part do
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant.Name == "LobbyRoom" and descendant:IsA("BasePart") then
				part = descendant
				break
			end
		end
		if not part then task.wait(1) end
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(triggeredBy)
			if triggeredBy == player then
				state.isUIOpen = not state.isUIOpen
				gui.Enabled = state.isUIOpen
				if state.blurEffect then state.blurEffect.Enabled = state.isUIOpen end

				if state.isUIOpen then
					-- Pop-in animation
					local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = THEME.Sizes.MainFrame})
					-- Start slightly smaller? No, scale 0 to 1 is better
					mainFrame.Size = UDim2.new(0,0,0,0)
					tween:Play()
				end
			end
		end)
	end
end)

print("LobbyRoomUI (Modern Folder) Initialized.")
