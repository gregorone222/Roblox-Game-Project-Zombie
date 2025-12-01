-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterPlayerScripts/LobbyRoomUI.lua
-- Script Place: Lobby
-- Theme: Zombie Apocalypse "Safehouse Mission Board"
-- Redesigned for immersion and character.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")
local ProximityUIHandler = require(ReplicatedStorage.ModuleScript:WaitForChild("ProximityUIHandler"))

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		BoardBg = Color3.fromRGB(45, 45, 50),       -- Dark Slate/Blackboard
		Paper = Color3.fromRGB(245, 240, 225),      -- Aged Paper
		PaperDark = Color3.fromRGB(220, 210, 190),  -- Wet/Dark Paper
		Blood = Color3.fromRGB(160, 20, 20),        -- Red Marker/Blood
		Ink = Color3.fromRGB(20, 20, 25),           -- Black Ink
		Chalk = Color3.fromRGB(230, 230, 235),      -- White Chalk
		Pencil = Color3.fromRGB(80, 80, 90),        -- Graphite
		Hazard = Color3.fromRGB(240, 180, 40),      -- Caution Tape Yellow
		HazardBlack = Color3.fromRGB(20, 20, 20),   -- Caution Tape Black
		Tape = Color3.fromRGB(200, 190, 150),       -- Masking Tape
		Success = Color3.fromRGB(40, 140, 40),      -- Green Stamp
	},
	Fonts = {
		Header = Enum.Font.AmaticSC,      -- Handwriting (Large)
		Body = Enum.Font.SpecialElite,    -- Typewriter
		Stamp = Enum.Font.Bangers,        -- Bold/Stamp
		UI = Enum.Font.GothamMedium       -- Fallback/Clear
	},
	Sizes = {
		Header = 42,
		SubHeader = 28,
		Body = 18,
		Stamp = 24
	}
}

-- Fallback font check (just in case)
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

-- ================== STATE MANAGEMENT ==================
local state = {
	currentScreenContainer = "main-hub",
	currentContentPanel = "solo-options",
	isHost = true,
	isReady = false,
	settings = {
		visibility = "public",
		mode = "Story",
		difficulty = "Easy",
		playerCount = 4
	},
	currentRoom = nil,
	publicRooms = {},
	isUIOpen = false,
	proximityHandler = nil
}

-- UI References
local gui
local screenContainers = {}
local contentPanels = {}
local navButtons = {}

-- ================== HELPER FUNCTIONS (VISUALS) ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

-- Adds a "Hand-drawn" or rough border
local function addRoughBorder(parent, color, thickness)
	local stroke = create("UIStroke", {
		Parent = parent,
		Color = color or THEME.Colors.Ink,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0.2
	})
	return stroke
end

-- Adds a piece of tape to a corner
local function addTape(parent, positionUDim2, rotation, color)
	local tape = create("Frame", {
		Name = "Tape",
		Parent = parent,
		Size = UDim2.new(0, 50, 0, 15),
		Position = positionUDim2,
		BackgroundColor3 = color or THEME.Colors.Tape,
		BorderSizePixel = 0,
		Rotation = rotation or math.random(-20, 20),
		ZIndex = (parent.ZIndex or 1) + 1
	})
	-- Rough opacity for tape
	tape.BackgroundTransparency = 0.1
	-- Crinkled edges (Corner)
	create("UICorner", {Parent = tape, CornerRadius = UDim.new(0, 2)})
	return tape
end

-- Creates a "Paper" style frame
local function createPaperFrame(parent, size, pos)
	local frame = create("Frame", {
		Name = "PaperNote",
		Parent = parent,
		Size = size,
		Position = pos,
		BackgroundColor3 = THEME.Colors.Paper,
		BorderSizePixel = 0
	})
	create("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 2)})
	addRoughBorder(frame, Color3.fromRGB(0,0,0), 1)
	-- Subtle gradient for aging
	local grad = create("UIGradient", {
		Parent = frame,
		Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, THEME.Colors.Paper),
			ColorSequenceKeypoint.new(1, THEME.Colors.PaperDark)
		},
		Rotation = 45
	})
	return frame
end

-- Creates a "Polaroid" style frame
local function createPolaroid(parent, size, pos)
	local frame = create("Frame", {
		Name = "Polaroid",
		Parent = parent,
		Size = size,
		Position = pos,
		BackgroundColor3 = Color3.fromRGB(250, 250, 250), -- Photo border white
		BorderSizePixel = 0
	})
	-- Shadow
	local shadow = create("Frame", {
		Parent = frame,
		ZIndex = -1,
		Size = UDim2.new(1, 4, 1, 4),
		Position = UDim2.new(0, -2, 0, 2),
		BackgroundColor3 = Color3.fromRGB(0,0,0),
		BackgroundTransparency = 0.7
	})
	create("UICorner", {Parent=shadow, CornerRadius=UDim.new(0, 4)})

	-- Inner Photo Area
	local photoArea = create("Frame", {
		Name = "PhotoArea",
		Parent = frame,
		Size = UDim2.new(0.9, 0, 0.75, 0),
		Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0
	})

	return frame, photoArea
end

-- ================== UI CONTROL FUNCTIONS ==================

local function showLobbyUI()
	if gui and gui.Parent then
		gui.Enabled = true
		state.isUIOpen = true

		-- Intro Animation: Board Slides Down or Zooms In
		local main = gui:FindFirstChild("MainContainer")
		if main then
			main.Position = UDim2.new(0.5, 0, 1.5, 0)
			main:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.6, true)
		end
	end
end

local function hideLobbyUI()
	if gui and gui.Parent then
		gui.Enabled = false
		state.isUIOpen = false

		if state.proximityHandler then
			state.proximityHandler:SetOpen(false)
		end
	end
end

-- ================== PANEL & SECTION CREATION ==================

local function createSelectionGrid(parent, groupName, items, currentSelection, onSelect)
	local grid = create("Frame", {
		Name = groupName.."Grid",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 0), -- Auto size Y
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1
	})

	local layout = create("UIGridLayout", {
		Parent = grid,
		CellSize = UDim2.new(0, 80, 0, 40),
		CellPadding = UDim2.new(0, 10, 0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	for i, item in ipairs(items) do
		local val = item.value or item
		local label = item.label or tostring(val)

		local btn = create("TextButton", {
			Name = "Btn_"..label,
			Parent = grid,
			BackgroundColor3 = (val == currentSelection) and THEME.Colors.Blood or THEME.Colors.Paper,
			Text = label,
			Font = getFont("Stamp"),
			TextSize = 18,
			TextColor3 = (val == currentSelection) and THEME.Colors.Paper or THEME.Colors.Ink,
			LayoutOrder = i
		})
		addRoughBorder(btn, THEME.Colors.Ink, 2)
		create("UICorner", {Parent=btn, CornerRadius=UDim.new(0, 4)})

		btn.MouseButton1Click:Connect(function()
			onSelect(val)
			-- Visual Update
			for _, child in ipairs(grid:GetChildren()) do
				if child:IsA("TextButton") then
					local isSelected = (child == btn)
					child.BackgroundColor3 = isSelected and THEME.Colors.Blood or THEME.Colors.Paper
					child.TextColor3 = isSelected and THEME.Colors.Paper or THEME.Colors.Ink

					-- Pop effect
					if isSelected then
						local t = TweenService:Create(child, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 45)})
						t:Play()
						t.Completed:Connect(function() 
							child.Size = UDim2.new(0, 80, 0, 40) -- Reset by layout, but tween looks nice
						end)
					end
				end
			end
		end)
	end
	return grid
end

-- ================== CONTENT PANELS ==================

local function createSoloOptionsPanel(parent)
	local panel = create("Frame", {
		Name = "SoloPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	contentPanels["solo-options"] = panel

	-- Paper Background for this section
	local paper = createPaperFrame(panel, UDim2.new(0.9, 0, 0.9, 0), UDim2.new(0.05, 0, 0.05, 0))
	addTape(paper, UDim2.new(0.5, -25, 0, -8), 0)

	local title = create("TextLabel", {
		Parent = paper, Size = UDim2.new(1,0,0.15,0), BackgroundTransparency = 1,
		Text = "LONE WOLF OPERATION", Font = getFont("Header"), TextSize = THEME.Sizes.Header,
		TextColor3 = THEME.Colors.Blood
	})

	local container = create("Frame", {
		Parent = paper, Size = UDim2.new(0.9,0,0.7,0), Position = UDim2.new(0.05,0,0.15,0), BackgroundTransparency = 1
	})
	local list = create("UIListLayout", {Parent=container, Padding=UDim.new(0,15), SortOrder=Enum.SortOrder.LayoutOrder})

	-- Difficulty Selector
	create("TextLabel", {
		Parent = container, Size=UDim2.new(1,0,0,30), Text="THREAT LEVEL:", 
		Font=getFont("Body"), TextSize=THEME.Sizes.SubHeader, TextColor3=THEME.Colors.Ink, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1
	})

	local diffItems = {
		{label="EASY", value="Easy"}, {label="NORMAL", value="Normal"}, 
		{label="HARD", value="Hard"}, {label="EXPERT", value="Expert"}, 
		{label="HELL", value="Hell"}, {label="CRAZY", value="Crazy"}
	}
	local diffGrid = createSelectionGrid(container, "Diff", diffItems, state.settings.difficulty, function(v) state.settings.difficulty = v end)
	diffGrid.LayoutOrder = 2

	-- Start Button (Stamp Style)
	local startBtn = create("TextButton", {
		Parent = paper, Size = UDim2.new(0.6,0,0.15,0), Position = UDim2.new(0.2,0,0.8,0),
		BackgroundColor3 = THEME.Colors.Ink, Text = "DEPLOY MISSION",
		Font = getFont("Stamp"), TextSize = 28, TextColor3 = THEME.Colors.Chalk
	})
	create("UICorner", {Parent=startBtn, CornerRadius=UDim.new(0, 4)})

	startBtn.MouseButton1Click:Connect(function()
		lobbyRemote:FireServer("startSoloGame", {
			gameMode = state.settings.mode, -- Default Story
			difficulty = state.settings.difficulty
		})
	end)
end

local function createCreateOptionsPanel(parent)
	local panel = create("Frame", {
		Name = "CreatePanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	contentPanels["create-options"] = panel

	local paper = createPaperFrame(panel, UDim2.new(0.9, 0, 0.95, 0), UDim2.new(0.05, 0, 0.025, 0))
	addTape(paper, UDim2.new(0, -10, 0, 20), -45)
	addTape(paper, UDim2.new(1, -40, 0, 20), 45)

	local title = create("TextLabel", {
		Parent = paper, Size = UDim2.new(1,0,0.1,0), BackgroundTransparency = 1,
		Text = "SQUAD MANIFEST", Font = getFont("Header"), TextSize = THEME.Sizes.Header,
		TextColor3 = THEME.Colors.Ink
	})

	local scroll = create("ScrollingFrame", {
		Parent = paper, Size = UDim2.new(0.9,0,0.7,0), Position = UDim2.new(0.05,0,0.1,0),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.Pencil
	})
	local layout = create("UIListLayout", {Parent=scroll, Padding=UDim.new(0,10), SortOrder=Enum.SortOrder.LayoutOrder})

	-- Room Name
	create("TextLabel", {
		Parent = scroll, Size=UDim2.new(1,0,0,25), Text="OPERATION NAME:", LayoutOrder=1,
		Font=getFont("Body"), TextSize=THEME.Sizes.Body, TextColor3=THEME.Colors.Pencil, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
	})
	local nameInput = create("TextBox", {
		Name = "RoomNameInput", Parent = scroll, Size=UDim2.new(1,0,0,40), LayoutOrder=2,
		BackgroundColor3 = Color3.fromRGB(250,250,250), Text = "", PlaceholderText = "Enter Squad Name...",
		Font=getFont("Header"), TextSize=24, TextColor3=THEME.Colors.Ink
	})
	addRoughBorder(nameInput)

	-- Player Count
	create("TextLabel", {
		Parent = scroll, Size=UDim2.new(1,0,0,25), Text="SQUAD SIZE:", LayoutOrder=3,
		Font=getFont("Body"), TextSize=THEME.Sizes.Body, TextColor3=THEME.Colors.Pencil, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
	})
	local countItems = {}
	for i=1,8 do table.insert(countItems, {label=tostring(i), value=i}) end
	local countGrid = createSelectionGrid(scroll, "Count", countItems, state.settings.playerCount, function(v) state.settings.playerCount = v end)
	countGrid.LayoutOrder = 4

	-- Difficulty
	create("TextLabel", {
		Parent = scroll, Size=UDim2.new(1,0,0,25), Text="THREAT LEVEL:", LayoutOrder=5,
		Font=getFont("Body"), TextSize=THEME.Sizes.Body, TextColor3=THEME.Colors.Pencil, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
	})
	local diffItems = {
		{label="EASY", value="Easy"}, {label="NORMAL", value="Normal"}, 
		{label="HARD", value="Hard"}, {label="EXPERT", value="Expert"}, 
		{label="HELL", value="Hell"}, {label="CRAZY", value="Crazy"}
	}
	local diffGrid = createSelectionGrid(scroll, "Diff", diffItems, state.settings.difficulty, function(v) state.settings.difficulty = v end)
	diffGrid.LayoutOrder = 6

	-- Create Button
	local createBtn = create("TextButton", {
		Parent = paper, Size = UDim2.new(0.5,0,0.12,0), Position = UDim2.new(0.25,0,0.85,0),
		BackgroundColor3 = THEME.Colors.Blood, Text = "ESTABLISH BASE",
		Font = getFont("Stamp"), TextSize = 24, TextColor3 = THEME.Colors.Paper
	})
	addRoughBorder(createBtn, Color3.new(0,0,0), 2)

	createBtn.MouseButton1Click:Connect(function()
		lobbyRemote:FireServer("createRoom", {
			roomName = nameInput.Text,
			isPrivate = false, -- Default public for now
			maxPlayers = state.settings.playerCount,
			gameMode = state.settings.mode,
			difficulty = state.settings.difficulty
		})
	end)
end

local function createJoinOptionsPanel(parent)
	local panel = create("Frame", {
		Name = "JoinPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	contentPanels["join-options"] = panel

	-- Board Header
	create("TextLabel", {
		Parent = panel, Size = UDim2.new(1,0,0.1,0), Text = "ACTIVE DISTRESS SIGNALS",
		Font = getFont("Header"), TextSize = THEME.Sizes.Header, TextColor3 = THEME.Colors.Chalk, BackgroundTransparency = 1
	})

	-- Code Input (Sticky Note style)
	local sticky = createPaperFrame(panel, UDim2.new(0.9,0,0.15,0), UDim2.new(0.05,0,0.12,0))
	sticky.BackgroundColor3 = THEME.Colors.Hazard -- Yellow sticky note
	addTape(sticky, UDim2.new(0.5,-20,-0.2,0), 0)

	local codeInput = create("TextBox", {
		Parent = sticky, Size = UDim2.new(0.7,0,0.6,0), Position = UDim2.new(0.05,0,0.2,0),
		BackgroundColor3 = Color3.new(1,1,1), Text = "", PlaceholderText = "ENTER CODE",
		Font = getFont("Body"), TextSize = 18
	})
	local joinCodeBtn = create("TextButton", {
		Parent = sticky, Size = UDim2.new(0.2,0,0.6,0), Position = UDim2.new(0.78,0,0.2,0),
		BackgroundColor3 = THEME.Colors.Ink, Text = "JOIN", TextColor3 = THEME.Colors.Paper,
		Font = getFont("Stamp")
	})
	joinCodeBtn.MouseButton1Click:Connect(function()
		lobbyRemote:FireServer("joinRoom", {roomCode = codeInput.Text})
	end)

	-- Room List (Grid of notes)
	local scroll = create("ScrollingFrame", {
		Name = "RoomsList", Parent = panel, Size = UDim2.new(0.95,0,0.65,0), Position = UDim2.new(0.025,0,0.3,0),
		BackgroundTransparency = 1, BorderSizePixel = 0
	})
	local grid = create("UIGridLayout", {
		Parent = scroll, CellSize = UDim2.new(0.45, 0, 0, 100), CellPadding = UDim2.new(0.05, 0, 0.05, 0)
	})

	-- Function to populate room list
	local function updateRooms(roomsData)
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

		for id, data in pairs(roomsData) do
			local card = create("TextButton", {
				Parent = scroll, BackgroundColor3 = THEME.Colors.Paper, Text = ""
			})
			-- Style the card
			addTape(card, UDim2.new(0.5,-15,-0.1,0), math.random(-5,5))
			addRoughBorder(card)

			local name = create("TextLabel", {
				Parent = card, Size=UDim2.new(0.9,0,0.3,0), Position=UDim2.new(0.05,0,0.1,0),
				Text = data.roomName, Font=getFont("Header"), TextSize=22, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
			})

			local info = create("TextLabel", {
				Parent = card, Size=UDim2.new(0.9,0,0.5,0), Position=UDim2.new(0.05,0,0.4,0),
				Text = string.format("HOST: %s\nSIZE: %d/%d\nDIFF: %s", data.hostName, data.playerCount, data.maxPlayers, data.difficulty or "?"),
				Font=getFont("Body"), TextSize=14, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextColor3=THEME.Colors.Pencil
			})

			card.MouseButton1Click:Connect(function()
				lobbyRemote:FireServer("joinRoom", {roomId = data.roomId})
			end)
		end
	end

	-- Expose update function to state or global hook if needed
	panel:SetAttribute("UpdateFunction", true)
	-- We'll call update logic from the main update handler
end

local function createLobbyPanel(parent)
	-- Pre-Game Lobby (When inside a room)
	local panel = create("Frame", {
		Name = "LobbyPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	screenContainers["pre-game-lobby"] = panel

	-- Back/Leave Button (Top Left Sticky)
	local leaveBtn = create("TextButton", {
		Parent = panel, Size = UDim2.new(0, 100, 0, 40), Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = THEME.Colors.Hazard, Text = "ABORT", Font = getFont("Stamp"), TextSize = 20
	})
	addTape(leaveBtn, UDim2.new(0, -5, 0, -5), -15, THEME.Colors.Tape)
	leaveBtn.MouseButton1Click:Connect(function() lobbyRemote:FireServer("leaveRoom") end)

	-- Room Info Note
	local infoNote = createPaperFrame(panel, UDim2.new(0.4, 0, 0.3, 0), UDim2.new(0.05, 0, 0.15, 0))
	addTape(infoNote, UDim2.new(0.5,-20,-0.1,0), 2)

	-- Use 'Header' instead of 'TextLabel' to avoid confusion if children order changes
	local roomTitle = create("TextLabel", {
		Name = "RoomTitle",
		Parent=infoNote, Size=UDim2.new(0.9,0,0.3,0), Position=UDim2.new(0.05,0,0.05,0),
		Text="ROOM NAME", Font=getFont("Header"), TextSize=32, BackgroundTransparency=1
	})
	local roomCode = create("TextLabel", {
		Name = "RoomCode",
		Parent=infoNote, Size=UDim2.new(0.9,0,0.2,0), Position=UDim2.new(0.05,0,0.35,0),
		Text="CODE: ----", Font=getFont("Body"), TextSize=24, BackgroundTransparency=1, TextColor3=THEME.Colors.Blood
	})
	local roomSettings = create("TextLabel", {
		Name = "RoomSettings",
		Parent=infoNote, Size=UDim2.new(0.9,0,0.4,0), Position=UDim2.new(0.05,0,0.55,0),
		Text="Diff: Easy\nMode: Story", Font=getFont("Body"), TextSize=18, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
	})

	-- Player Roster (Polaroids)
	local rosterFrame = create("Frame", {
		Name = "RosterFrame",
		Parent = panel, Size=UDim2.new(0.5, 0, 0.8, 0), Position=UDim2.new(0.48, 0, 0.1, 0), BackgroundTransparency=1
	})
	local grid = create("UIGridLayout", {
		Parent=rosterFrame, CellSize=UDim2.new(0.45,0,0.4,0), CellPadding=UDim2.new(0.05,0,0.05,0)
	})

	-- Controls (Start/Ready)
	local controlsFrame = create("Frame", {
		Name = "ControlsFrame",
		Parent = panel, Size=UDim2.new(0.4, 0, 0.2, 0), Position=UDim2.new(0.05, 0, 0.7, 0), BackgroundTransparency=1
	})

	local actionBtn = create("TextButton", {
		Name="ActionBtn", Parent=controlsFrame, Size=UDim2.new(0.9,0,0.8,0), Position=UDim2.new(0.05,0,0.1,0),
		BackgroundColor3 = THEME.Colors.Success, Text="READY UP", Font=getFont("Stamp"), TextSize=32, TextColor3=THEME.Colors.Paper
	})
	addRoughBorder(actionBtn, Color3.new(0,0,0), 3)

	actionBtn.MouseButton1Click:Connect(function()
		if state.isHost then
			lobbyRemote:FireServer("forceStartGame")
		else
			state.isReady = not state.isReady
			actionBtn.Text = state.isReady and "UNREADY" or "READY UP"
			actionBtn.BackgroundColor3 = state.isReady and THEME.Colors.Pencil or THEME.Colors.Success
		end
	end)

	-- Countdown Overlay
	local countdownLabel = create("TextLabel", {
		Name="Countdown", Parent=panel, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,0.4,0),
		Text="DEPLOYING IN 5...", Font=getFont("Stamp"), TextSize=60, TextColor3=THEME.Colors.Hazard,
		BackgroundTransparency=1, Visible=false
	})
	create("UIStroke", {Parent=countdownLabel, Color=Color3.new(0,0,0), Thickness=3})
end


-- ================== MAIN GUI SETUP ==================

local function createGUI()
	gui = create("ScreenGui", {
		Name = "LobbyRoomUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false, IgnoreGuiInset = true
	})

	-- Main Container (The Corkboard)
	local board = create("Frame", {
		Name = "MainContainer", Parent = gui,
		Size = UDim2.new(0.85, 0, 0.85, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Colors.BoardBg, BorderSizePixel = 0
	})
	-- Wooden Frame Border
	local border = create("UIStroke", {
		Parent = board, Color = Color3.fromRGB(60, 40, 20), Thickness = 10
	})

	-- Close Button (X Doodle)
	local closeBtn = create("TextButton", {
		Parent = board, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -20, 0, -20),
		BackgroundTransparency = 1, Text = "X", TextColor3 = THEME.Colors.Blood, Font = getFont("Stamp"), TextSize = 40
	})
	closeBtn.MouseButton1Click:Connect(hideLobbyUI)

	-- Navigation Area (Left Side Folders)
	local navFrame = create("Frame", {
		Name = "NavFrame", Parent = board, Size = UDim2.new(0.25, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0), BackgroundTransparency = 1
	})
	local navList = create("UIListLayout", {Parent=navFrame, Padding=UDim.new(0,10)})

	local function addNavButton(id, text, color)
		local btn = create("TextButton", {
			Parent = navFrame, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = color or THEME.Colors.Paper,
			Text = text, Font = getFont("Header"), TextSize = 28, TextColor3 = THEME.Colors.Ink
		})
		-- Tab shape
		create("UICorner", {Parent=btn, CornerRadius=UDim.new(0, 8)})
		navButtons[id] = btn

		btn.MouseButton1Click:Connect(function()
			-- Switch Panel Logic
			for pid, panel in pairs(contentPanels) do
				panel.Visible = (pid == id)
			end
			-- Highlight Active Tab
			for nid, nbtn in pairs(navButtons) do
				nbtn.Position = (nid == id) and UDim2.new(0, 10, 0, 0) or UDim2.new(0, 0, 0, 0) -- Pop out effect
			end
			-- Reset main container view
			screenContainers["main-hub"].Visible = true
			if screenContainers["pre-game-lobby"] then screenContainers["pre-game-lobby"].Visible = false end
		end)
	end

	addNavButton("solo-options", "SOLO MISSION", THEME.Colors.Paper)
	addNavButton("create-options", "NEW SQUAD", THEME.Colors.Paper)
	addNavButton("join-options", "FIND SQUAD", THEME.Colors.Paper)

	-- Content Area (Right Side)
	local contentFrame = create("Frame", {
		Name = "ContentFrame", Parent = board, Size = UDim2.new(0.7, 0, 0.9, 0), Position = UDim2.new(0.28, 0, 0.05, 0), BackgroundTransparency = 1
	})

	-- Initialize Panels
	createSoloOptionsPanel(contentFrame)
	createCreateOptionsPanel(contentFrame)
	createJoinOptionsPanel(contentFrame)
	createLobbyPanel(board) -- This sits on top of everything when active

	-- Default View
	screenContainers["main-hub"] = contentFrame
	contentPanels["solo-options"].Visible = true
end

-- ================== UPDATE LOGIC ==================

local function updateRoomUI(roomData)
	state.currentRoom = roomData
	state.isHost = (roomData.hostName == player.Name)

	-- Switch to Lobby Panel
	if screenContainers["main-hub"] then screenContainers["main-hub"].Visible = false end
	local panel = screenContainers["pre-game-lobby"]
	if panel then 
		panel.Visible = true 

		-- Update Text Info
		local infoNote = panel:FindFirstChild("PaperNote")
		if infoNote then
			local title = infoNote:FindFirstChild("RoomTitle")
			local code = infoNote:FindFirstChild("RoomCode")
			local settings = infoNote:FindFirstChild("RoomSettings")

			if title then title.Text = roomData.roomName end
			if code then code.Text = "CODE: " .. (roomData.roomCode or "NONE") end
			if settings then settings.Text = string.format("Diff: %s\nMode: %s", roomData.difficulty, roomData.gameMode) end
		end

		-- Update Roster
		local roster = panel:FindFirstChild("RosterFrame") 
		if roster then
			for _, c in ipairs(roster:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for _, pData in ipairs(roomData.players) do
				local polaroid, area = createPolaroid(roster, UDim2.new(0,0,0,0), UDim2.new(0,0,0,0))
				-- Name
				create("TextLabel", {
					Parent = polaroid, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,0.8,0),
					Text = pData.Name, Font=getFont("Header"), TextSize=18, BackgroundTransparency=1
				})
				-- Avatar (Placeholder or real)
				local img = create("ImageLabel", {
					Parent = area, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
					Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" 
				})
				-- Add host star if applicable
				if pData.Name == roomData.hostName then
					addTape(polaroid, UDim2.new(0, -5, 0, -5), -20, THEME.Colors.Hazard)
				end
			end
		end

		-- Update Button Text
		local controls = panel:FindFirstChild("ControlsFrame") 
		local actionBtn = controls and controls:FindFirstChild("ActionBtn")
		if actionBtn then
			if state.isHost then
				actionBtn.Text = "START GAME"
				actionBtn.BackgroundColor3 = THEME.Colors.Hazard
				actionBtn.TextColor3 = THEME.Colors.HazardBlack
			else
				actionBtn.Text = state.isReady and "UNREADY" or "READY UP"
				actionBtn.BackgroundColor3 = state.isReady and THEME.Colors.Pencil or THEME.Colors.Success
				actionBtn.TextColor3 = THEME.Colors.Paper
			end
		end
	end
end

-- ================== SERVER EVENTS ==================

lobbyRemote.OnClientEvent:Connect(function(action, data)
	if action == "roomCreated" or action == "joinSuccess" or action == "matchFound" then
		-- Switch to lobby view handled by roomUpdate usually, but we ensure visibility here
		if screenContainers["pre-game-lobby"] then screenContainers["pre-game-lobby"].Visible = true end
		if screenContainers["main-hub"] then screenContainers["main-hub"].Visible = false end

	elseif action == "roomUpdate" then
		updateRoomUI(data)

	elseif action == "publicRoomsUpdate" then
		state.publicRooms = data
		-- Update the Join Panel list if it exists
		if contentPanels["join-options"] then
			-- Re-run the list population logic. 
			local scroll = contentPanels["join-options"]:FindFirstChild("RoomsList")
			if scroll then
				for _, c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				for id, room in pairs(data) do
					local card = create("TextButton", {
						Parent = scroll, BackgroundColor3 = THEME.Colors.Paper, Text = ""
					})
					addRoughBorder(card)
					create("TextLabel", {
						Parent = card, Size=UDim2.new(0.9,0,0.3,0), Position=UDim2.new(0.05,0,0.1,0),
						Text = room.roomName, Font=getFont("Header"), TextSize=22, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
					})
					create("TextLabel", {
						Parent = card, Size=UDim2.new(0.9,0,0.5,0), Position=UDim2.new(0.05,0,0.4,0),
						Text = string.format("HOST: %s\nSIZE: %d/%d", room.hostName, room.playerCount, room.maxPlayers),
						Font=getFont("Body"), TextSize=14, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
					})
					card.MouseButton1Click:Connect(function()
						lobbyRemote:FireServer("joinRoom", {roomId = room.roomId})
					end)
				end
			end
		end

	elseif action == "leftRoomSuccess" then
		if screenContainers["pre-game-lobby"] then screenContainers["pre-game-lobby"].Visible = false end
		if screenContainers["main-hub"] then screenContainers["main-hub"].Visible = true end

	elseif action == "countdownUpdate" then
		local lbl = screenContainers["pre-game-lobby"] and screenContainers["pre-game-lobby"]:FindFirstChild("Countdown")
		if lbl then
			lbl.Visible = true
			lbl.Text = "DEPLOYING IN " .. tostring(data.value) .. "..."
		end

	elseif action == "countdownCancelled" then
		local lbl = screenContainers["pre-game-lobby"] and screenContainers["pre-game-lobby"]:FindFirstChild("Countdown")
		if lbl then lbl.Visible = false end
	end
end)

-- ================== INIT ==================

createGUI()
lobbyRemote:FireServer("getPublicRooms")

-- Register Proximity
state.proximityHandler = ProximityUIHandler.Register({
	name = "LobbyRoom",
	partName = "LobbyRoom",
	onToggle = function(isOpen)
		if isOpen then showLobbyUI() else hideLobbyUI() end
	end
})

print("LobbyRoomUI (Safehouse Theme) Initialized")
