-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- LobbyRoomUI.local.luau
-- Path: StarterGui/UI/LobbyRoomUI.local.luau
-- Theme: Apocalypse Survival (Dark Brown, Gold, Glass)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")
local kickPlayerEvent = ReplicatedStorage:WaitForChild("KickPlayerFromLobby")

-- --- THEME CONFIGURATION ---
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),      -- Deep Warm Dark
		Panel = Color3.fromRGB(35, 28, 22),           -- Main Panel Brown
		PanelGlass = Color3.fromRGB(45, 38, 30),      -- Slightly lighter glass
		AccentMain = Color3.fromRGB(218, 165, 32),    -- Golden
		AccentSec = Color3.fromRGB(139, 90, 43),      -- Bronze/Copper
		TextHigh = Color3.fromRGB(255, 248, 230),     -- Warm White
		TextMid = Color3.fromRGB(180, 160, 130),      -- Beige
		TextLow = Color3.fromRGB(100, 85, 65),        -- Dark Beige
		Success = Color3.fromRGB(46, 204, 113),       -- Green
		Error = Color3.fromRGB(231, 76, 60),          -- Red
		ButtonStart = Color3.fromRGB(50, 150, 50),
		ButtonStop = Color3.fromRGB(150, 50, 50),
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Data = Enum.Font.Code,
	},
	CornerRadius = UDim.new(0, 8),
	Padding = UDim.new(0, 10),
}

-- --- UI CREATION HELPERS ---
local function create(className, props, children)
	local instance = Instance.new(className)
	for k, v in pairs(props) do
		instance[k] = v
	end
	if children then
		for _, child in pairs(children) do
			child.Parent = instance
		end
	end
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or THEME.CornerRadius
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Colors.AccentMain
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, px)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, px or 10)
	pad.PaddingBottom = UDim.new(0, px or 10)
	pad.PaddingLeft = UDim.new(0, px or 10)
	pad.PaddingRight = UDim.new(0, px or 10)
	pad.Parent = parent
	return pad
end

-- --- MAIN UI SETUP ---
local screenGui = create("ScreenGui", {
	Name = "LobbyRoomUI",
	Parent = player.PlayerGui,
	ResetOnSpawn = false,
	Enabled = false -- Hidden by default, toggled by button or event
})

-- Main Container (Glass Panel)
local mainFrame = create("Frame", {
	Name = "MainFrame",
	Size = UDim2.fromScale(0.6, 0.7),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Visible = false, -- Hidden by default until triggered
	Parent = screenGui
})
addCorner(mainFrame, UDim.new(0, 12))
addStroke(mainFrame, THEME.Colors.AccentMain, 2)

-- Blur Effect
local blur = Instance.new("BlurEffect")
blur.Size = 15
blur.Enabled = false
blur.Parent = game.Lighting

-- Header
local headerFrame = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.5,
	Parent = mainFrame
})
addCorner(headerFrame, UDim.new(0, 12))

local titleLabel = create("TextLabel", {
	Name = "Title",
	Text = "MISSION BRIEFING",
	Font = THEME.Fonts.Header,
	TextSize = 24,
	TextColor3 = THEME.Colors.AccentMain,
	Size = UDim2.fromScale(0.5, 1),
	Position = UDim2.fromScale(0.05, 0),
	BackgroundTransparency = 1,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = headerFrame
})

local closeBtn = create("TextButton", {
	Name = "CloseButton",
	Text = "X",
	Font = THEME.Fonts.Header,
	TextSize = 20,
	TextColor3 = THEME.Colors.TextLow,
	BackgroundColor3 = THEME.Colors.PanelGlass,
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -40, 0.5, 0),
	AnchorPoint = Vector2.new(0, 0.5),
	Parent = headerFrame
})
addCorner(closeBtn, UDim.new(0, 6))

-- Content Area
local contentFrame = create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, 0, 1, -60),
	Position = UDim2.new(0, 0, 0, 60),
	BackgroundTransparency = 1,
	Parent = mainFrame
})

-- Sidebar (Tabs)
local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0.25, -10, 1, 0),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.5,
	Parent = contentFrame
})
addCorner(sidebar, UDim.new(0, 8))
addStroke(sidebar, THEME.Colors.AccentSec, 1)

local tabLayout = create("UIListLayout", {
	Parent = sidebar,
	Padding = UDim.new(0, 5),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top
})
addPadding(sidebar, 10)

-- Pages Container
local pagesContainer = create("Frame", {
	Name = "Pages",
	Size = UDim2.new(0.75, -20, 1, 0),
	Position = UDim2.new(0.25, 10, 0, 0),
	BackgroundTransparency = 1,
	Parent = contentFrame
})

-- --- STATE VARIABLES ---
local currentTab = "Public" -- Public, Create, Room
local activeRoomId = nil
local isHost = false

-- --- FUNCTIONAL COMPONENTS ---

-- 1. BUTTON FACTORY
local function createTabButton(text, pageName)
	local btn = create("TextButton", {
		Name = pageName .. "Btn",
		Text = text,
		Font = THEME.Fonts.Body,
		TextSize = 16,
		TextColor3 = THEME.Colors.TextMid,
		BackgroundColor3 = THEME.Colors.PanelGlass,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = sidebar,
		AutoButtonColor = false
	})
	addCorner(btn, UDim.new(0, 6))
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextHigh, BackgroundColor3 = THEME.Colors.AccentSec}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		if currentTab ~= pageName then
			TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextMid, BackgroundColor3 = THEME.Colors.PanelGlass}):Play()
		end
	end)
	
	return btn
end

local btnPublic = createTabButton("BROWSE ROOMS", "Public")
local btnCreate = createTabButton("CREATE ROOM", "Create")
-- "Current Room" tab - visible only when in a room
local btnRoom = createTabButton("MY SQUAD", "Room")
btnRoom.Visible = false

-- --- PAGES ---

-- PAGE 1: PUBLIC ROOMS
local pagePublic = create("ScrollingFrame", {
	Name = "PublicPage",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ScrollBarThickness = 4,
	Parent = pagesContainer,
	Visible = true
})
create("UIListLayout", {
	Parent = pagePublic,
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center
})

local function createRoomCard(roomData)
	local card = create("Frame", {
		Name = "RoomCard_" .. roomData.roomId,
		Size = UDim2.new(1, -10, 0, 60),
		BackgroundColor3 = THEME.Colors.PanelGlass,
		Parent = pagePublic
	})
	addCorner(card, UDim.new(0, 8))
	addStroke(card, THEME.Colors.AccentSec, 1)
	
	create("TextLabel", {
		Text = roomData.roomName,
		Font = THEME.Fonts.Body,
		TextSize = 18,
		TextColor3 = THEME.Colors.TextHigh,
		Size = UDim2.new(0.6, 0, 0.5, 0),
		Position = UDim2.new(0, 15, 0, 5),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card
	})
	
	create("TextLabel", {
		Text = string.format("HOST: %s | MODE: %s", roomData.hostName, roomData.gameMode or "Story"),
		Font = THEME.Fonts.Data,
		TextSize = 12,
		TextColor3 = THEME.Colors.TextMid,
		Size = UDim2.new(0.6, 0, 0.5, 0),
		Position = UDim2.new(0, 15, 0.5, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card
	})
	
	create("TextLabel", {
		Text = string.format("%d / %d", roomData.playerCount, roomData.maxPlayers),
		Font = THEME.Fonts.Data,
		TextSize = 20,
		TextColor3 = THEME.Colors.AccentMain,
		Size = UDim2.new(0.2, 0, 1, 0),
		Position = UDim2.new(0.6, 0, 0, 0),
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card
	})
	
	local joinBtn = create("TextButton", {
		Text = "JOIN",
		Font = THEME.Fonts.Body,
		TextColor3 = THEME.Colors.Background,
		BackgroundColor3 = THEME.Colors.AccentMain,
		Size = UDim2.new(0.2, -10, 0.6, 0),
		Position = UDim2.new(0.8, 0, 0.2, 0),
		Parent = card
	})
	addCorner(joinBtn, UDim.new(0, 6))
	
	joinBtn.MouseButton1Click:Connect(function()
		lobbyRemote:FireServer("joinRoom", { roomId = roomData.roomId })
	end)
end

-- PAGE 2: CREATE ROOM
local pageCreate = create("Frame", {
	Name = "CreatePage",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = pagesContainer,
	Visible = false
})

create("UIListLayout", { Parent = pageCreate, Padding = UDim.new(0, 15), HorizontalAlignment = Enum.HorizontalAlignment.Center })

local function createInputGroup(label, placeholder)
	local group = create("Frame", { Size = UDim2.new(0.9, 0, 0, 60), BackgroundTransparency = 1, Parent = pageCreate })
	create("TextLabel", {
		Text = label, Font = THEME.Fonts.Body, TextSize = 14, TextColor3 = THEME.Colors.TextMid,
		Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = group
	})
	local input = create("TextBox", {
		PlaceholderText = placeholder, Text = "", Font = THEME.Fonts.Body, TextSize = 16,
		TextColor3 = THEME.Colors.TextHigh, BackgroundColor3 = THEME.Colors.Background,
		Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 25), Parent = group,
		ClearTextOnFocus = false
	})
	addCorner(input, UDim.new(0, 6))
	addPadding(input, 8)
	return input
end

local nameInput = createInputGroup("ROOM NAME", "Enter room name...")

-- Difficulty Dropdown (Simplified as Buttons for now)
local diffFrame = create("Frame", { Size = UDim2.new(0.9, 0, 0, 60), BackgroundTransparency = 1, Parent = pageCreate })
create("TextLabel", {
	Text = "DIFFICULTY", Font = THEME.Fonts.Body, TextSize = 14, TextColor3 = THEME.Colors.TextMid,
	Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = diffFrame
})

local selectedDiff = "Easy"
local diffsVec = {"Easy", "Normal", "Hard"}
local diffBtns = {}

local diffContainer = create("Frame", { Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 25), BackgroundTransparency = 1, Parent = diffFrame })
create("UIListLayout", { Parent = diffContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) })

for _, d in ipairs(diffsVec) do
	local btn = create("TextButton", {
		Text = d, Font = THEME.Fonts.Body, TextSize = 14,
		TextColor3 = d == "Easy" and THEME.Colors.TextHigh or THEME.Colors.TextMid,
		BackgroundColor3 = d == "Easy" and THEME.Colors.AccentSec or THEME.Colors.PanelGlass,
		Size = UDim2.new(0.3, 0, 1, 0), Parent = diffContainer
	})
	addCorner(btn, UDim.new(0, 6))
	
	btn.MouseButton1Click:Connect(function()
		selectedDiff = d
		for _, b in ipairs(diffContainer:GetChildren()) do
			if b:IsA("TextButton") then
				b.BackgroundColor3 = THEME.Colors.PanelGlass
				b.TextColor3 = THEME.Colors.TextMid
			end
		end
		btn.BackgroundColor3 = THEME.Colors.AccentSec
		btn.TextColor3 = THEME.Colors.TextHigh
	end)
end

local createActionBtn = create("TextButton", {
	Text = "ESTABLISH SQUAD",
	Font = THEME.Fonts.Header, TextSize = 18, TextColor3 = THEME.Colors.Background,
	BackgroundColor3 = THEME.Colors.AccentMain, Size = UDim2.new(0.5, 0, 0, 50),
	Parent = pageCreate
})
addCorner(createActionBtn, UDim.new(0, 8))

createActionBtn.MouseButton1Click:Connect(function()
	lobbyRemote:FireServer("createRoom", {
		roomName = nameInput.Text,
		difficulty = selectedDiff,
		maxPlayers = 4,
		gameMode = "Story"
	})
end)

-- PAGE 3: ROOM LOBBY (Active Room)
local pageRoom = create("Frame", {
	Name = "RoomPage",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = pagesContainer,
	Visible = false
})

local roomHeader = create("Frame", {
	Name = "Info", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Parent = pageRoom
})
local roomTitle = create("TextLabel", {
	Text = "ALPHA SQUAD", Font = THEME.Fonts.Header, TextSize = 24, TextColor3 = THEME.Colors.AccentMain,
	Size = UDim2.new(1, 0, 0.5, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = roomHeader
})
local roomCode = create("TextLabel", {
	Text = "CODE: 123456", Font = THEME.Fonts.Data, TextSize = 16, TextColor3 = THEME.Colors.TextMid,
	Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = roomHeader
})

local playerList = create("ScrollingFrame", {
	Name = "PlayerList", Size = UDim2.new(1, 0, 1, -120), Position = UDim2.new(0, 0, 0, 70),
	BackgroundColor3 = THEME.Colors.Background, BackgroundTransparency = 0.5, Parent = pageRoom
})
addCorner(playerList, UDim.new(0, 8))
create("UIListLayout", { Parent = playerList, Padding = UDim.new(0, 5) })
addPadding(playerList, 5)

local actionContainer = create("Frame", {
	Size = UDim2.new(1, 0, 0, 40), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Parent = pageRoom
})

local startBtn = create("TextButton", {
	Text = "DEPLOY SQUAD", Font = THEME.Fonts.Header, TextSize = 16, TextColor3 = THEME.Colors.TextHigh,
	BackgroundColor3 = THEME.Colors.ButtonStart, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0.4, 0, 0, 0), Parent = actionContainer, Visible = false
})
addCorner(startBtn, UDim.new(0, 6))

local leaveBtn = create("TextButton", {
	Text = "LEAVE", Font = THEME.Fonts.Body, TextSize = 14, TextColor3 = THEME.Colors.TextHigh,
	BackgroundColor3 = THEME.Colors.ButtonStop, Size = UDim2.new(0.35, 0, 1, 0), Parent = actionContainer
})
addCorner(leaveBtn, UDim.new(0, 6))

startBtn.MouseButton1Click:Connect(function()
	lobbyRemote:FireServer("forceStartGame")
end)

leaveBtn.MouseButton1Click:Connect(function()
	lobbyRemote:FireServer("leaveRoom")
end)

-- --- LOGIC ---

local function switchTab(tabName)
	currentTab = tabName
	
	-- Update Buttons
	btnPublic.BackgroundColor3 = THEME.Colors.PanelGlass
	btnPublic.TextColor3 = THEME.Colors.TextMid
	btnCreate.BackgroundColor3 = THEME.Colors.PanelGlass
	btnCreate.TextColor3 = THEME.Colors.TextMid
	btnRoom.BackgroundColor3 = THEME.Colors.PanelGlass
	btnRoom.TextColor3 = THEME.Colors.TextMid
	
	if tabName == "Public" then
		btnPublic.BackgroundColor3 = THEME.Colors.AccentSec
		btnPublic.TextColor3 = THEME.Colors.TextHigh
		pagePublic.Visible = true
		pageCreate.Visible = false
		pageRoom.Visible = false
		-- Refresh public rooms
		lobbyRemote:FireServer("getPublicRooms")
	elseif tabName == "Create" then
		btnCreate.BackgroundColor3 = THEME.Colors.AccentSec
		btnCreate.TextColor3 = THEME.Colors.TextHigh
		pagePublic.Visible = false
		pageCreate.Visible = true
		pageRoom.Visible = false
	elseif tabName == "Room" then
		btnRoom.BackgroundColor3 = THEME.Colors.AccentSec
		btnRoom.TextColor3 = THEME.Colors.TextHigh
		pagePublic.Visible = false
		pageCreate.Visible = false
		pageRoom.Visible = true
	end
end

-- Close UI
closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	screenGui.Enabled = false -- Disable GUI on close
	blur.Enabled = false
end)

-- --- REMOTE CONNECTORS ---

-- Update list of public rooms
lobbyRemote.OnClientEvent:Connect(function(action, data)
	if action == "publicRoomsUpdate" then
		-- Clear old list
		for _, child in ipairs(pagePublic:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		
		-- Sort by player count
		local roomsList = {}
		for id, room in pairs(data) do
			table.insert(roomsList, room)
		end
		table.sort(roomsList, function(a,b) return a.playerCount > b.playerCount end)
		
		for _, room in ipairs(roomsList) do
			createRoomCard(room)
		end
		
	elseif action == "roomUpdate" then
		-- Player joined/created a room. Switch to Room Tab.
		if not activeRoomId then
			btnRoom.Visible = true
			switchTab("Room")
			screenGui.Enabled = true -- Auto open UI on join
			mainFrame.Visible = true
			blur.Enabled = true
		end
		
		activeRoomId = data.roomId
		roomTitle.Text = string.upper(data.roomName)
		roomCode.Text = "DIFFICULTY: " .. string.upper(data.difficulty or "Normal")
		
		-- Host Logic
		isHost = (data.hostName == player.Name)
		startBtn.Visible = isHost
		
		-- Rebuild Player List
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
		
		for _, pData in ipairs(data.players) do
			local pRow = create("Frame", {
				Name = pData.Name, Size = UDim2.new(1, -5, 0, 40), BackgroundColor3 = THEME.Colors.PanelGlass, Parent = playerList
			})
			addCorner(pRow, UDim.new(0, 6))
			
			create("TextLabel", {
				Text = pData.Name, Font = THEME.Fonts.Body, TextSize = 14, TextColor3 = THEME.Colors.TextHigh,
				Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = pRow
			})
			
			create("TextLabel", {
				Text = "LVL " .. (pData.Level or 1), Font = THEME.Fonts.Data, TextSize = 14, TextColor3 = THEME.Colors.AccentMain,
				Size = UDim2.new(0.2, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Parent = pRow
			})
			
			if isHost and pData.UserId ~= player.UserId then
				local kickBtn = create("TextButton", {
					Text = "KICK", Font = THEME.Fonts.Data, TextSize = 10, TextColor3 = THEME.Colors.TextHigh,
					BackgroundColor3 = THEME.Colors.Error, Size = UDim2.new(0, 50, 0, 25), Position = UDim2.new(1, -60, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = pRow
				})
				addCorner(kickBtn, UDim.new(0, 4))
				kickBtn.MouseButton1Click:Connect(function()
					kickPlayerEvent:FireServer(pData.UserId)
				end)
			end
		end
		
	elseif action == "leftRoomSuccess" or action == "joinFailed" then
		activeRoomId = nil
		btnRoom.Visible = false
		if currentTab == "Room" then
			switchTab("Public")
		end
	end
end)

-- --- ProximityPrompt TRIGGER (Mission Briefing Table) ---
-- Listen for the MissionBriefingPrompt on CommandTable
local ProximityPromptService = game:GetService("ProximityPromptService")

ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	if playerWhoTriggered ~= player then return end
	if prompt.Name == "MissionBriefingPrompt" then
		mainFrame.Visible = true
		screenGui.Enabled = true -- Enable GUI when triggered
		blur.Enabled = true
		switchTab("Public")
	end
end)

-- Initial State: Force Hidden
mainFrame.Visible = false
screenGui.Enabled = false -- NUCLEAR OPTION: Entire GUI disabled until triggered
print("LobbyRoomUI: Initialized (Hidden)")
