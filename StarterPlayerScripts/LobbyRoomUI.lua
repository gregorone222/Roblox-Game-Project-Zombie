-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterPlayerScripts/LobbyRoomUI.lua
-- Script Place: Lobby
-- Theme: Investigation Board (Corkboard/Tabletop)
-- Style: Analog, Paper, Photos, Tape, Handwritten notes

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui") -- Needed for CoreGui toggling

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")

-- Forward Declarations
local updateRoomList
local updateLobbyView
local hideUI

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		Board = Color3.fromRGB(60, 45, 35),         -- Cork/Wood
		Paper = Color3.fromRGB(245, 240, 225),      -- Off-white paper
		PaperDark = Color3.fromRGB(220, 215, 200),  -- Aged paper
		Ink = Color3.fromRGB(25, 25, 30),           -- Black ink
		RedMarker = Color3.fromRGB(200, 40, 40),    -- Red circle/text
		Highlight = Color3.fromRGB(255, 230, 100),  -- Sticky note yellow
		Tape = Color3.fromRGB(220, 220, 220),       -- Masking tape
		Stamp = Color3.fromRGB(180, 40, 40),        -- Red Stamp ink
	},
	Fonts = {
		Header = Enum.Font.SpecialElite, -- Typewriter Bold
		Body = Enum.Font.SpecialElite,   -- Typewriter
		Hand = Enum.Font.IndieFlower,    -- Handwriting (Marker)
		Stamp = Enum.Font.Bangers        -- Big Bold Stamp
	}
}

-- Fallback font safe getter
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

-- ================== STATE MANAGEMENT ==================
local state = {
	isUIOpen = false,
	activeTab = "OPS", -- Represents which "document" is on top
	currentRoom = nil,
	publicRooms = {},
	settings = {
		gameMode = "Story",
		difficulty = "Easy",
		playerCount = 4
	},
	promptConnection = nil,
	blurEffect = nil
}

-- UI References
local gui
local mainBoard
local contentArea
local tabs = {}
local panels = {}

-- ================== HELPER FUNCTIONS ==================

local function create(instanceType, properties, children)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

-- Adds a "Paper" feel with shadow and slightly rough border
local function styleAsPaper(frame)
	frame.BackgroundColor3 = THEME.Colors.Paper
	create("UICorner", {Parent=frame, CornerRadius=UDim.new(0, 2)})
	-- Shadow
	local shadow = create("Frame", {
		Name = "Shadow", Parent=frame, ZIndex=frame.ZIndex-1,
		Size=UDim2.new(1, 4, 1, 4), Position=UDim2.new(0, 2, 0, 2),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency=0.7
	})
	create("UICorner", {Parent=shadow, CornerRadius=UDim.new(0, 4)})
	return frame
end

-- Adds a "Tape" strip visual
local function addTape(parent, position, angle)
	local tape = create("Frame", {
		Name="Tape", Parent=parent,
		Size=UDim2.new(0, 40, 0, 12), Position=position, Rotation=angle or math.random(-20,20),
		BackgroundColor3 = THEME.Colors.Tape, BackgroundTransparency=0.4, BorderSizePixel=0,
		ZIndex = (parent.ZIndex or 1) + 1
	})
	return tape
end

-- Adds a "Polaroid" frame style
local function createPolaroid(parent, size, pos)
	local frame = create("Frame", {
		Name="Polaroid", Parent=parent, Size=size, Position=pos,
		BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel=0
	})
	-- Photo area
	local photo = create("ImageLabel", {
		Name="Photo", Parent=frame, Size=UDim2.new(0.9,0,0.75,0), Position=UDim2.new(0.05,0,0.05,0),
		BackgroundColor3=Color3.fromRGB(20,20,20), Image="rbxasset://textures/ui/GuiImagePlaceholder.png"
	})
	-- Shadow
	local shadow = create("Frame", {
		Parent=frame, ZIndex=frame.ZIndex-1, Size=UDim2.new(1,4,1,4), Position=UDim2.new(0,2,0,2),
		BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.7
	})
	return frame, photo
end

-- ================== COMPONENT FACTORY ==================

local function createPaperButton(parent, text, size, pos, callback, isHandwritten)
	local btn = create("TextButton", {
		Name = "Btn_"..text, Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = THEME.Colors.Paper, AutoButtonColor = true
	})
	styleAsPaper(btn)

	local font = isHandwritten and getFont("Hand") or getFont("Header")
	local col = isHandwritten and THEME.Colors.RedMarker or THEME.Colors.Ink

	local label = create("TextLabel", {
		Parent = btn, Size = UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Text = text, Font = font, TextSize = 18, TextColor3 = col
	})

	btn.MouseButton1Click:Connect(callback)
	-- Simple tilt animation on hover
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {Rotation = math.random(-2,2)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {Rotation = 0}):Play()
	end)

	return btn
end

-- ================== PANELS ==================

local function createOpsPanel(parent)
	-- A "Mission File" folder look
	local panel = create("Frame", {
		Name = "OpsPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	panels["OPS"] = panel

	-- Left Page: Configuration (Typed document)
	local docLeft = create("Frame", {
		Parent = panel, Size=UDim2.new(0.45, -10, 0.9, 0), Position=UDim2.new(0.02, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper
	})
	styleAsPaper(docLeft)
	addTape(docLeft, UDim2.new(0.5, -20, 0, -5), 0)

	create("TextLabel", {
		Parent=docLeft, Size=UDim2.new(1,0,0,40), Text="MISSION PARAMETERS",
		Font=getFont("Header"), TextSize=24, TextColor3=THEME.Colors.Ink, BackgroundTransparency=1
	})

	-- Config List
	local listLayout = create("UIListLayout", {
		Parent = docLeft, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center
	})
	-- (Padding)
	create("Frame", {Parent=docLeft, Size=UDim2.new(1,0,0,30), BackgroundTransparency=1})

	-- Selectors visualized as circled options
	local function createOptionRow(label, options, current, onSet)
		local row = create("Frame", {
			Parent=docLeft, Size=UDim2.new(0.9,0,0,40), BackgroundTransparency=1
		})
		create("TextLabel", {
			Parent=row, Size=UDim2.new(0.3,0,1,0), Text=label..":",
			Font=getFont("Body"), TextSize=16, TextColor3=THEME.Colors.Ink, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
		})

		local optsFrame = create("Frame", {
			Parent=row, Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0.3,0,0,0), BackgroundTransparency=1
		})
		local optList = create("UIListLayout", {Parent=optsFrame, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)})

		for _, opt in ipairs(options) do
			local isSel = (opt.value == current)
			local btn = create("TextButton", {
				Parent=optsFrame, Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
				BackgroundTransparency=1, Text=opt.label, Font=getFont("Hand"), TextSize=18,
				TextColor3 = isSel and THEME.Colors.RedMarker or Color3.new(0.5,0.5,0.5)
			})
			-- Circle drawing if selected
			if isSel then
				local circle = create("ImageLabel", {
					Parent=btn, Size=UDim2.new(1,10,1,10), Position=UDim2.new(0,-5,0,-5),
					BackgroundTransparency=1, Image="rbxassetid://130424513", ImageColor3=THEME.Colors.RedMarker, ImageTransparency=0.5
				}) -- Generic circle asset (replace if specific one available)
			end
			btn.MouseButton1Click:Connect(function() onSet(opt.value) end)
		end
	end

	createOptionRow("MODE", {{label="Story",value="Story"}, {label="Crazy",value="Crazy"}}, state.settings.gameMode, function(v) state.settings.gameMode=v end)
	createOptionRow("RISK", {{label="Easy",value="Easy"}, {label="Normal",value="Normal"}, {label="Hard",value="Hard"}}, state.settings.difficulty, function(v) state.settings.difficulty=v end)

	create("Frame", {Parent=docLeft, Size=UDim2.new(1,0,0,20), BackgroundTransparency=1}) -- Spacer

	-- Actions
	createPaperButton(docLeft, "SOLO DEPLOY", UDim2.new(0.8,0,0,50), UDim2.new(0,0,0,0), function()
		lobbyRemote:FireServer("startSoloGame", {gameMode = state.settings.gameMode, difficulty = state.settings.difficulty})
	end)

	-- Right Page: Distress Signals (Post-it notes on board)
	local rightArea = create("Frame", {
		Name="RightCol", Parent = panel, Size = UDim2.new(0.5, -10, 0.9, 0), Position = UDim2.new(0.5, 0, 0.05, 0),
		BackgroundTransparency = 1
	})
	create("TextLabel", {
		Parent=rightArea, Size=UDim2.new(1,0,0,40), Text="DISTRESS SIGNALS (Public)",
		Font=getFont("Hand"), TextSize=28, TextColor3=THEME.Colors.Paper, BackgroundTransparency=1 -- Chalk on board
	})

	local scroll = create("ScrollingFrame", {
		Name="RoomList", Parent=rightArea, Size=UDim2.new(1,0,0.9,0), Position=UDim2.new(0,0,0.1,0),
		BackgroundTransparency=1, ScrollBarThickness=6, ScrollBarImageColor3=THEME.Colors.Paper
	})
	create("UIGridLayout", {
		Parent=scroll, CellSize=UDim2.new(0.45,0,0,80), CellPadding=UDim2.new(0.05,0,0.02,0)
	})
end

local function createLobbyPanel(parent)
	-- A "Case File" folder open on the table
	local panel = create("Frame", {
		Name = "LobbyPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	panels["LOBBY"] = panel

	-- Folder Background
	local folder = create("Frame", {
		Name="HeaderFrame", Parent=panel, Size=UDim2.new(0.9,0,0.9,0), Position=UDim2.new(0.05,0,0.05,0),
		BackgroundColor3 = Color3.fromRGB(200, 180, 140) -- Manila folder color
	})
	create("UICorner", {Parent=folder, CornerRadius=UDim.new(0,4)})

	-- Folder Tab
	local tab = create("Frame", {
		Parent=folder, Size=UDim2.new(0.3,0,0.1,0), Position=UDim2.new(0,0,-0.1,0),
		BackgroundColor3 = Color3.fromRGB(200, 180, 140)
	})
	create("UICorner", {Parent=tab, CornerRadius=UDim.new(0,4)})
	create("TextLabel", {
		Name="RoomTitle", Parent=tab, Size=UDim2.new(1,0,0.8,0), Position=UDim2.new(0,0,0.2,0),
		Text="OPERATION ALPHA", Font=getFont("Header"), TextSize=18, TextColor3=THEME.Colors.Ink, BackgroundTransparency=1
	})

	-- Info Sheet inside folder
	local infoSheet = create("Frame", {
		Parent=folder, Size=UDim2.new(0.95,0,0.95,0), Position=UDim2.new(0.025,0,0.025,0),
		BackgroundColor3 = THEME.Colors.Paper
	})

	-- Close/Leave (Red Stamp)
	local leaveBtn = create("TextButton", {
		Parent=infoSheet, Size=UDim2.new(0,100,0,50), Position=UDim2.new(1,-110,0,10),
		BackgroundTransparency=1, Text="ABORT", Font=getFont("Stamp"), TextSize=32, TextColor3=THEME.Colors.Stamp, Rotation=-15
	})
	leaveBtn.MouseButton1Click:Connect(function() lobbyRemote:FireServer("leaveRoom") end)

	-- Info Text
	create("TextLabel", {
		Name="RoomInfo", Parent=infoSheet, Size=UDim2.new(0.6,0,0.2,0), Position=UDim2.new(0.05,0,0.05,0),
		Text="Objective: Survival\nDiff: Hard", Font=getFont("Body"), TextSize=18, TextColor3=THEME.Colors.Ink, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
	})

	-- Roster (Polaroids clipped to the paper)
	local rosterFrame = create("Frame", {
		Name="RosterFrame", Parent=infoSheet, Size=UDim2.new(0.9,0,0.5,0), Position=UDim2.new(0.05,0,0.3,0), BackgroundTransparency=1
	})
	create("UIGridLayout", {Parent=rosterFrame, CellSize=UDim2.new(0.22,0,0.8,0)})

	-- Action Stamp (Ready/Deploy)
	local actionFrame = create("Frame", {
		Name="ActionFrame", Parent=infoSheet, Size=UDim2.new(0.4,0,0.15,0), Position=UDim2.new(0.3,0,0.8,0), BackgroundTransparency=1
	})
	local statusText = create("TextLabel", {
		Name="StatusText", Parent=actionFrame, Size=UDim2.new(1,0,0.5,0), Text="Waiting...", Font=getFont("Hand"), TextSize=18, BackgroundTransparency=1, TextColor3=THEME.Colors.Ink
	})

	createPaperButton(actionFrame, "DEPLOY", UDim2.new(1,0,1,0), UDim2.new(0,0,0.5,0), function()
		if state.currentRoom and state.currentRoom.hostName == player.Name then
			lobbyRemote:FireServer("forceStartGame")
		else
			-- Toggle Ready logic if implemented server side
		end
	end)
end

local function createIntelPanel(parent)
	local panel = create("Frame", {
		Name = "IntelPanel", Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false
	})
	panels["INTEL"] = panel

	-- A big map or photo on the board
	local mapPhoto = create("Frame", {
		Parent=panel, Size=UDim2.new(0.8,0,0.8,0), Position=UDim2.new(0.1,0,0.1,0),
		BackgroundColor3 = Color3.new(1,1,1)
	})
	create("ImageLabel", {
		Parent=mapPhoto, Size=UDim2.new(0.96,0,0.96,0), Position=UDim2.new(0.02,0,0.02,0),
		BackgroundColor3=Color3.new(0,0,0), Image="rbxasset://textures/ui/GuiImagePlaceholder.png" -- Placeholder for map
	})
	addTape(mapPhoto, UDim2.new(0.5,-20,0,-10), 0)

	create("TextLabel", {
		Parent=mapPhoto, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,1,0),
		Text="TARGET: THE VILLAGE\nBeware of high radiation levels.",
		Font=getFont("Hand"), TextSize=24, TextColor3=THEME.Colors.Paper, BackgroundTransparency=1
	})
end

-- ================== MAIN UI STRUCTURE ==================

local function createGUI()
	gui = create("ScreenGui", {
		Name = "LobbyRoomUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false,
		IgnoreGuiInset = false -- CHANGED: Respect top bar area
	})

	local camera = workspace.CurrentCamera
	state.blurEffect = create("BlurEffect", {Parent = camera, Size = 20, Enabled = false})

	-- Main Background (Corkboard Texture)
	mainBoard = create("Frame", {
		Name = "Board", Parent = gui,
		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = THEME.Colors.Board, BorderSizePixel = 0
	})
	-- Texture overlay
	create("ImageLabel", {
		Parent=mainBoard, Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
		Image="rbxassetid://6372755229", ImageTransparency=0.5, ScaleType=Enum.ScaleType.Tile, TileSize=UDim2.new(0,256,0,256)
	}) -- Cork texture

	-- Content Container (Padding)
	contentArea = create("Frame", {
		Parent=mainBoard, Size=UDim2.new(0.9,0,0.85,0), Position=UDim2.new(0.05,0,0.1,0), BackgroundTransparency=1
	})

	-- Nav Tabs (Sticky Notes on top)
	local nav = create("Frame", {
		Parent=mainBoard, Size=UDim2.new(0.5,0,0.1,0), Position=UDim2.new(0.05,0,0,0), BackgroundTransparency=1
	})
	local navLayout = create("UIListLayout", {Parent=nav, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,20)})

	local function addStickyTab(id, text, color)
		local btn = create("TextButton", {
			Parent=nav, Size=UDim2.new(0, 120, 1, 10), BackgroundColor3=color,
			Text=text, Font=getFont("Hand"), TextSize=24, TextColor3=THEME.Colors.Ink
		})
		-- Shadow
		create("Frame", {Parent=btn, ZIndex=btn.ZIndex-1, Size=UDim2.new(1,0,1,0), Position=UDim2.new(0,2,0,2), BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.8})

		btn.MouseButton1Click:Connect(function()
			state.activeTab = id
			for pid, p in pairs(panels) do p.Visible = (pid == id) end
			-- Simple "Pull down" animation
			for _, b in ipairs(nav:GetChildren()) do
				if b:IsA("TextButton") then
					b:TweenPosition(UDim2.new(0,0,0,(b==btn and 0 or -20)), "Out", "Quad", 0.2, true)
				end
			end
		end)
		tabs[id] = btn
	end

	addStickyTab("OPS", "MISSIONS", THEME.Colors.Highlight)
	addStickyTab("INTEL", "INTEL", Color3.fromRGB(100, 200, 255))
	addStickyTab("LOBBY", "SQUAD", Color3.fromRGB(100, 255, 100))

	-- Initialize Panels
	createOpsPanel(contentArea)
	createLobbyPanel(contentArea)
	createIntelPanel(contentArea)

	-- Default State
	panels["OPS"].Visible = true

	-- Close Button (X drawn on corner)
	local closeBtn = create("TextButton", {
		Parent=mainBoard, Size=UDim2.new(0,50,0,50), Position=UDim2.new(1,-60,0,10),
		BackgroundTransparency=1, Text="X", Font=getFont("Hand"), TextSize=48, TextColor3=THEME.Colors.RedMarker
	})
	closeBtn.MouseButton1Click:Connect(function()
		state.isUIOpen = false
		if hideUI then hideUI() end
	end)
end

-- ================== VISUAL LOGIC ==================

function updateRoomList(roomsData)
	-- Update the sticky notes on the "OPS" board
	local panel = panels["OPS"]
	if not panel then return end
	local scroll = panel:FindFirstChild("RightCol") and panel.RightCol:FindFirstChild("RoomList")
	if not scroll then return end

	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

	for id, room in pairs(roomsData) do
		local note = create("TextButton", {
			Parent=scroll, BackgroundColor3=THEME.Colors.Highlight
		})
		-- Sticky note look
		create("UICorner", {Parent=note, CornerRadius=UDim.new(0,0)}) -- Sharp corners usually, maybe slight curl
		addTape(note, UDim2.new(0.5,-20,0,-5), 0)

		create("TextLabel", {
			Parent=note, Size=UDim2.new(0.9,0,0.3,0), Position=UDim2.new(0.05,0,0.1,0),
			Text=room.roomName, Font=getFont("Hand"), TextSize=18, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
		})
		create("TextLabel", {
			Parent=note, Size=UDim2.new(0.9,0,0.5,0), Position=UDim2.new(0.05,0,0.4,0),
			Text=string.format("Host: %s\nPlayers: %d/%d", room.hostName, room.playerCount, room.maxPlayers),
			Font=getFont("Body"), TextSize=14, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left
		})

		note.MouseButton1Click:Connect(function()
			lobbyRemote:FireServer("joinRoom", {roomId = room.roomId})
		end)
	end
end

function updateLobbyView(roomData)
	local panel = panels["LOBBY"]
	if not panel then return end

	-- We need to auto-switch tab if we joined a room
	state.activeTab = "LOBBY"
	for pid, p in pairs(panels) do p.Visible = (pid == "LOBBY") end

	state.currentRoom = roomData
	local isHost = (roomData.hostName == player.Name)
	local folder = panel:FindFirstChild("HeaderFrame")

	-- Update Title Tab
	if folder then
		local tab = folder:FindFirstChild("Frame")
		if tab and tab:FindFirstChild("RoomTitle") then
			tab.RoomTitle.Text = string.upper(roomData.roomName)
		end
		-- Update Info Sheet
		local sheet = folder:FindFirstChild("Frame") -- Info sheet
		if sheet then
			local info = sheet:FindFirstChild("RoomInfo")
			if info then
				info.Text = string.format("MISSION: %s\nTHREAT: %s", roomData.gameMode, roomData.difficulty)
			end

			-- Roster
			local roster = sheet:FindFirstChild("RosterFrame")
			if roster then
				for _, c in ipairs(roster:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
				for _, pData in ipairs(roomData.players) do
					local polaroid, photo = createPolaroid(roster, UDim2.new(0,0,0,0), UDim2.new(0,0,0,0))
					addTape(polaroid, UDim2.new(0.5,-20,0,-5), math.random(-5,5))
					-- Name on bottom of polaroid
					create("TextLabel", {
						Parent=polaroid, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,0.8,0),
						Text=pData.Name, Font=getFont("Hand"), TextSize=14, BackgroundTransparency=1
					})
				end
			end

			-- Button
			local action = sheet:FindFirstChild("ActionFrame")
			if action then
				local btn = action:FindFirstChild("Btn_DEPLOY")
				if btn then
					local lbl = btn:FindFirstChild("TextLabel")
					if isHost then
						lbl.Text = "STAMP: DEPLOY"
						lbl.TextColor3 = THEME.Colors.Stamp
					else
						lbl.Text = "WAITING..."
						lbl.TextColor3 = THEME.Colors.Ink
					end
				end
			end
		end
	end
end

function showUI()
	if gui.Parent ~= playerGui then gui.Parent = playerGui end
	gui.Enabled = true
	if state.blurEffect then state.blurEffect.Enabled = true end

	-- Removed CoreGui hiding

	-- Animation: Slide up from bottom
	mainBoard.Position = UDim2.new(0,0,1,0)
	mainBoard:TweenPosition(UDim2.new(0,0,0,0), "Out", "Back", 0.5, true)
end

function hideUI()
	if state.blurEffect then state.blurEffect.Enabled = false end

	-- Removed CoreGui restoring

	-- Slide down
	local t = TweenService:Create(mainBoard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position=UDim2.new(0,0,1,0)})
	t:Play()
	t.Completed:Connect(function()
		gui.Enabled = false
	end)
end

-- ================== INIT & LISTENERS ==================

lobbyRemote.OnClientEvent:Connect(function(action, data)
	if action == "roomCreated" or action == "joinSuccess" then
		updateLobbyView(data) -- Will switch tab automatically
	elseif action == "roomUpdate" then
		updateLobbyView(data)
	elseif action == "publicRoomsUpdate" then
		updateRoomList(data)
	elseif action == "leftRoomSuccess" then
		-- Switch back to OPS
		state.activeTab = "OPS"
		for pid, p in pairs(panels) do p.Visible = (pid == "OPS") end
	end
end)

createGUI()
lobbyRemote:FireServer("getPublicRooms")

-- Robust Part Search (Retained from previous fix)
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
				if state.isUIOpen then showUI() else hideUI() end
			end
		end)
	end
end)

print("LobbyRoomUI (Investigation Board) Initialized.")
