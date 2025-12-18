-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/LobbyRoomUI.lua
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

-- ================== THEME CONSTANTS (Tactical Dossier Style) ==================
local THEME = {
	Colors = {
		-- Background & Atmosphere
		Background   = Color3.fromRGB(25, 28, 30),       -- Dark tactical
		Overlay      = Color3.fromRGB(15, 18, 20),       -- Darker overlay
		
		-- Dossier/Folder Colors
		FolderMain   = Color3.fromRGB(195, 165, 120),    -- Aged Manila Folder
		FolderDark   = Color3.fromRGB(160, 130, 90),     -- Tab darker shade
		FolderEdge   = Color3.fromRGB(140, 110, 70),     -- Edge worn color
		
		-- Paper & Document
		Paper        = Color3.fromRGB(248, 245, 235),    -- Aged Paper (slightly yellow)
		PaperDark    = Color3.fromRGB(235, 230, 218),    -- Alt Paper
		PaperLines   = Color3.fromRGB(200, 195, 185),    -- Faint lines
		
		-- Text & Ink
		TextMain     = Color3.fromRGB(25, 25, 30),       -- Dark Ink
		TextDim      = Color3.fromRGB(90, 85, 80),       -- Pencil/Faded
		TextType     = Color3.fromRGB(40, 45, 55),       -- Typewriter ink
		
		-- Stamps & Accents
		StampRed     = Color3.fromRGB(180, 45, 45),      -- CLASSIFIED stamp
		StampGreen   = Color3.fromRGB(45, 140, 65),      -- AUTHORIZED stamp
		StampBlue    = Color3.fromRGB(45, 80, 140),      -- INFO stamp
		Highlight    = Color3.fromRGB(255, 240, 120),    -- Sticky Note Yellow
		HighlightAlt = Color3.fromRGB(255, 180, 100),    -- Orange highlight
		
		-- Tactical Accents
		TacticalGreen = Color3.fromRGB(60, 180, 90),     -- Go/Success
		TacticalRed   = Color3.fromRGB(200, 55, 55),     -- Cancel/Alert
		BorderDark    = Color3.fromRGB(80, 70, 55),      -- Border
        
        -- Aliases for compatibility
        AccentRed     = Color3.fromRGB(200, 55, 55),
        AccentGreen   = Color3.fromRGB(60, 180, 90),
	},
	Fonts = {
		Header    = Enum.Font.SpecialElite,   -- Typewriter (Narrative feel)
		Body      = Enum.Font.SourceSans,     -- Clean Sans-Serif (Readability)
		Label     = Enum.Font.GothamBold,     -- UI Labels
		Stamp     = Enum.Font.Sarpanch,       -- Military stamp style
		Typewriter = Enum.Font.Code,          -- Code/Typewriter
	},
	Sizes = {
		MainFrame = UDim2.new(0.85, 0, 0.85, 0), -- Default PC
	}
}

-- Adaptive Sizing (Mobile Check)
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    -- On mobile, use 95% width, but limit height to 85% to allow room for Tabs on top
    THEME.Sizes.MainFrame = UDim2.new(0.95, 0, 0.85, 0)
end

-- Fallback for specific fonts if not available
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

-- ================== STATE MANAGEMENT ==================
	state = {
	isUIOpen = false,
	activeTab = "OPS",
	activeView = "MENU", -- MENU, CONFIG_SOLO, CONFIG_SQUAD, LIST, CONFIG_QUICK, MATCHMAKING
	currentRoom = nil,
	settings = {
		gameMode = "Story",
		difficulty = "Easy",
		roomName = "",
		maxPlayers = 4,
		visibility = "Public",
        map = "ACT 1: Village" -- Default Map
	},
	blurEffect = nil
}



-- UI References
local gui
local mainFrame
local contentContainer
local tabs = {}
local panels = {}
local opsViews = {} -- Sub-views for OPS panel

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

-- Standard "Dossier Document" Button (Stamp Style)
local function createButton(parent, text, size, pos, color, callback)
	local isStampStyle = (color == THEME.Colors.StampRed or color == THEME.Colors.StampGreen or color == THEME.Colors.FolderDark)
	local bgColor = color or THEME.Colors.Paper
	
	local btn = create("TextButton", {
		Name = "Btn_"..text, Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = bgColor, AutoButtonColor = false,
		BorderSizePixel = 0, Text = ""
	})

	-- Shadow (offset like paper on desk)
	local shadow = create("Frame", {
		Name = "Shadow",
		Parent = btn, ZIndex = btn.ZIndex - 1, Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0.01, 0, 0.02, 0),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.7, BorderSizePixel = 0
	})
	create("UICorner", {Parent = shadow, CornerRadius = UDim.new(0, 6)})

	-- Border (Document edge)
	local border = create("UIStroke", {
		Parent = btn, Color = THEME.Colors.BorderDark, Thickness = 2, Transparency = 0.3
	})

	-- Text
	local textLabel = create("TextLabel", {
		Name = "TextLabel",
		Parent = btn, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
		Text = text:upper(), Font = isStampStyle and getFont("Stamp") or getFont("Label"),
		TextScaled = true, TextColor3 = isStampStyle and THEME.Colors.Paper or THEME.Colors.TextMain
	})
    -- Padding to keep text away from borders
    create("UIPadding", {Parent = textLabel, PaddingTop = UDim.new(0.12, 0), PaddingBottom = UDim.new(0.12, 0), PaddingLeft = UDim.new(0.08, 0), PaddingRight = UDim.new(0.08, 0)})

	-- Constraint text size
	create("UITextSizeConstraint", {Parent = textLabel, MaxTextSize = 22})

	create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})

	-- Hover Effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.15)}):Play()
		TweenService:Create(border, TweenInfo.new(0.15), {Transparency = 0, Color = THEME.Colors.TacticalGreen}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = bgColor}):Play()
		TweenService:Create(border, TweenInfo.new(0.15), {Transparency = 0.3, Color = THEME.Colors.BorderDark}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
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
		ZIndex = isActive and 2 or 1, Text = ""
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

	-- === SUB-VIEW: MENU (Main Navigation) ===
	local menuView = create("Frame", {
		Name = "MenuView", Parent = panel, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = true
	})
	opsViews["MENU"] = menuView

	local menuGrid = create("UIGridLayout", {
		Parent = menuView, CellSize = UDim2.new(0.42, 0, 0.38, 0), CellPadding = UDim2.new(0.05, 0, 0.06, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center
	})

	-- Primary Action (Stamp Green) - Solo Deploy
	createButton(menuView, "DEPLOY SOLO", UDim2.new(0,0,0,0), UDim2.new(0,0,0,0), THEME.Colors.StampGreen, function()
		state.activeView = "CONFIG_SOLO"
		updateOpsView()
	end)

	-- Secondary Action (Folder Dark) - Create Squad
	createButton(menuView, "CREATE SQUAD", UDim2.new(0,0,0,0), UDim2.new(0,0,0,0), THEME.Colors.FolderDark, function()
		state.activeView = "CONFIG_SQUAD"
		updateOpsView()
	end)

	-- Tertiary Action (Stamp Blue) - Quick Match
	createButton(menuView, "QUICK MATCH", UDim2.new(0,0,0,0), UDim2.new(0,0,0,0), THEME.Colors.StampBlue, function()
		state.activeView = "CONFIG_QUICK"
		updateOpsView()
	end)

	-- Neutral Action (Paper) - Find Squad
	createButton(menuView, "FIND SQUAD", UDim2.new(0,0,0,0), UDim2.new(0,0,0,0), THEME.Colors.Paper, function()
		state.activeView = "LIST"
		updateOpsView()
	end)


	-- === SUB-VIEW: CONFIG (For Solo/Squad) ===
	local configView = create("Frame", {
		Name = "ConfigView", Parent = panel, Size = UDim2.new(0.95, 0, 0.9, 0), Position = UDim2.new(0.025, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper, Visible = false
	})
	create("UICorner", {Parent = configView, CornerRadius = UDim.new(0.05, 0)})
	opsViews["CONFIG"] = configView

	-- Top Container (Fixed)
	local topContainer = create("Frame", {
		Name = "TopContainer", Parent = configView, Size = UDim2.new(1, 0, 0.15, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	})
    -- Removed UIListLayout to allow manual positioning for valid "Left Back, Center Title" layout

	-- Back Button (Top Left) - Tactical Red
	local backBtn = createButton(topContainer, "< BACK", UDim2.new(0.2, 0, 0.6, 0), UDim2.new(0.005, 0, 0.5, 0), THEME.Colors.TacticalRed, function()
		state.activeView = "MENU"
		updateOpsView()
	end)
    backBtn.AnchorPoint = Vector2.new(0, 0.5) -- Anchor Left-Center
	backBtn.LayoutOrder = 1

	local header = create("TextLabel", {
		Parent = topContainer, Size = UDim2.new(0.5, 0, 0.6, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "MISSION PARAMETERS", Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
		LayoutOrder = 2
	})
	create("UITextSizeConstraint", {Parent = header, MaxTextSize = 24})

	-- Scroll Container (Middle)
	local scrollContainer = create("ScrollingFrame", {
		Name = "OptionsScroll", Parent = configView, Size = UDim2.new(1, 0, 0.7, 0), Position = UDim2.new(0, 0, 0.15, 0),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.TextMain,
		CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIListLayout", {
		Parent = scrollContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.05, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center
	})
	create("UIPadding", {Parent = scrollContainer, PaddingTop = UDim.new(0.02, 0), PaddingBottom = UDim.new(0.02, 0)})

	-- Bottom Container (Fixed)
	local bottomContainer = create("Frame", {
		Name = "BottomContainer", Parent = configView, Size = UDim2.new(1, 0, 0.15, 0), Position = UDim2.new(0, 0, 0.85, 0),
		BackgroundTransparency = 1
	})
	create("UIListLayout", {
		Parent = bottomContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center
	})

	-- Helper for Options
	local function createOption(label, options, key, layout)
		local container = create("Frame", {
			Parent = scrollContainer, Size = UDim2.new(0.9, 0, 0.15, 0), BackgroundTransparency = 1, LayoutOrder = layout
		})
		local lbl = create("TextLabel", {
			Parent = container, Size = UDim2.new(1, 0, 0.35, 0), Text = label,
			Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = lbl, MaxTextSize = 14})

		local btnContainer = create("Frame", {
			Parent = container, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.new(0, 0, 0.4, 0), BackgroundTransparency = 1
		})
		create("UIListLayout", {
			Parent = btnContainer, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0)
		})

		local optionBtns = {}

		for _, opt in ipairs(options) do
			local optStr = tostring(opt)
            local isSelected = (state.settings[key] == opt)
            
			local btn = create("TextButton", {
				Parent = btnContainer, Size = UDim2.new(1/#options - 0.02, 0, 1, 0), -- Reduced gap
				BackgroundColor3 = isSelected and THEME.Colors.Paper or THEME.Colors.PaperDark,
                BackgroundTransparency = isSelected and 1 or 0, -- Transparent when stamped
				BorderSizePixel = 0, Text = optStr, 
                Font = isSelected and getFont("Stamp") or getFont("Body"), 
                TextScaled = true,
				TextColor3 = isSelected and THEME.Colors.AccentRed or THEME.Colors.TextMain,
                Rotation = isSelected and math.random(-3, 3) or 0 -- Stamp Tilt
			})
			create("UICorner", {Parent = btn, CornerRadius = UDim.new(0.2, 0)})
            create("UIPadding", {Parent = btn, PaddingTop = UDim.new(0.1, 0), PaddingBottom = UDim.new(0.1, 0), PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0)})
			-- TextButton native text logic fix
			create("UITextSizeConstraint", {Parent = btn, MaxTextSize = 12})
            
            -- Stamp Box Border (Only Visible when selected)
            local border = create("UIStroke", {
                Parent = btn, Thickness = 2, Color = THEME.Colors.AccentRed, 
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Enabled = isSelected
            })

			btn.MouseButton1Click:Connect(function()
				state.settings[key] = opt
				-- Refresh visuals
				for _, b in ipairs(optionBtns) do
					local isSel = (b.Text == optStr)
                    -- Stamp Effect Logic
					b.BackgroundTransparency = isSel and 1 or 0
                    b.BackgroundColor3 = isSel and THEME.Colors.Paper or THEME.Colors.PaperDark
					b.TextColor3 = isSel and THEME.Colors.AccentRed or THEME.Colors.TextMain
                    b.Font = isSel and getFont("Stamp") or getFont("Body")
                    b.Rotation = isSel and math.random(-3, 3) or 0
                    
                    local str = b:FindFirstChildOfClass("UIStroke")
                    if str then str.Enabled = isSel end
				end
			end)
			table.insert(optionBtns, btn)
		end
	end

	-- Room Name Input
	local function createInput(label, key, layout)
		local container = create("Frame", {
			Name = "Input_"..key,
			Parent = scrollContainer, Size = UDim2.new(0.9, 0, 0.15, 0), BackgroundTransparency = 1, LayoutOrder = layout
		})
		local lbl = create("TextLabel", {
			Parent = container, Size = UDim2.new(1, 0, 0.4, 0), Text = label,
			Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
		})
		create("UITextSizeConstraint", {Parent = lbl, MaxTextSize = 14})

		local textBox = create("TextBox", {
			Parent = container, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = THEME.Colors.PaperDark, Text = "", PlaceholderText = "ENTER ROOM NAME...",
			Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
			PlaceholderColor3 = THEME.Colors.TextDim
		})
		create("UICorner", {Parent = textBox, CornerRadius = UDim.new(0.2, 0)})
		create("UITextSizeConstraint", {Parent = textBox, MaxTextSize = 14})

		textBox.FocusLost:Connect(function()
			state.settings[key] = textBox.Text
		end)
	end

	createInput("SQUAD SIGNATURE", "roomName", 0)
    createOption("DESTINATION", {"ACT 1: Village"}, "map", 1)
	createOption("OPERATION MODE", {"Story", "Endless"}, "gameMode", 2)
	createOption("THREAT LEVEL", {"Easy", "Normal", "Hard", "Expert", "Crazy", "Hell"}, "difficulty", 3)
	createOption("SQUAD SIZE", {2, 3, 4, 5, 6, 7, 8}, "maxPlayers", 4)
	createOption("VISIBILITY", {"Public", "Private"}, "visibility", 5)

	-- Action Button (Context Sensitive)
	local actionBtn = createButton(bottomContainer, "ACTION", UDim2.new(0.9, 0, 0.8, 0), UDim2.new(0,0,0,0), THEME.Colors.AccentGreen, function()
		if state.activeView == "CONFIG_SOLO" then
			lobbyRemote:FireServer("startSoloGame", {gameMode = state.settings.gameMode, difficulty = state.settings.difficulty})
		elseif state.activeView == "CONFIG_SQUAD" then
			lobbyRemote:FireServer("createRoom", {
				gameMode = state.settings.gameMode,
				difficulty = state.settings.difficulty,
				roomName = state.settings.roomName,
				maxPlayers = state.settings.maxPlayers,
				isPrivate = (state.settings.visibility == "Private")
			})
		elseif state.activeView == "CONFIG_QUICK" then
			startMatchmaking()
		end
	end)
	actionBtn.Name = "ActionBtn"
	actionBtn.LayoutOrder = 100
	actionBtn.TextLabel.TextColor3 = THEME.Colors.Paper

	-- === SUB-VIEW: LIST (Public Lobbies) ===
	local listView = create("Frame", {
		Name = "ListView", Parent = panel, Size = UDim2.new(0.7, 0, 0.9, 0), Position = UDim2.new(0.15, 0, 0.05, 0),
		BackgroundTransparency = 1, Visible = false
	})
	opsViews["LIST"] = listView

	-- Back Button (List)
	local backBtnList = createButton(listView, "< BACK", UDim2.new(0.25, 0, 0.08, 0), UDim2.new(0,0,0,0), THEME.Colors.AccentRed, function()
		state.activeView = "MENU"
		updateOpsView()
	end)
	backBtnList.TextLabel.TextColor3 = THEME.Colors.Paper

	local listHeader = create("TextLabel", {
		Parent = listView, Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.new(0, 0, 0.1, 0),
		Text = "DISTRESS SIGNALS (PUBLIC LOBBIES)",
		Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = listHeader, MaxTextSize = 18})

	-- Private Room Input Area (New Addition)
	local privateFrame = create("Frame", {
		Parent = listView, Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.20, 0),
		BackgroundTransparency = 1
	})

	local privateInput = create("TextBox", {
		Parent = privateFrame, Size = UDim2.new(0.7, 0, 1, 0), 
		BackgroundColor3 = THEME.Colors.Overlay, Text = "", PlaceholderText = "ENTER ENCRYPTED KEY...", -- Darker bg
		Font = getFont("Typewriter"), TextScaled = true, TextColor3 = THEME.Colors.Paper,
		PlaceholderColor3 = THEME.Colors.TextDim
	})
	create("UICorner", {Parent = privateInput, CornerRadius = UDim.new(0.1, 0)})
    
    -- Add Stroke for better visibility
    create("UIStroke", {
        Parent = privateInput, Color = THEME.Colors.BorderDark, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

	create("UITextSizeConstraint", {Parent = privateInput, MaxTextSize = 14})

	local joinPrivateBtn = createButton(privateFrame, "JOIN", UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0), THEME.Colors.FolderDark, function()
		if privateInput.Text ~= "" then
			lobbyRemote:FireServer("joinRoom", {roomCode = privateInput.Text})
		end
	end)
	joinPrivateBtn.TextLabel.TextColor3 = THEME.Colors.TextMain

	local scroll = create("ScrollingFrame", {
		Name = "RoomList", Parent = listView, Size = UDim2.new(1, 0, 0.65, 0), Position = UDim2.new(0, 0, 0.35, 0),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.TextMain,
		CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIGridLayout", {
		Parent = scroll, CellSize = UDim2.new(1, 0, 0.15, 0), CellPadding = UDim2.new(0, 0, 0.02, 0)
	})

	-- === SUB-VIEW: SQUAD ROOM (Replaces old LobbyPanel) ===
	local squadView = create("Frame", {
		Name = "SquadView", Parent = panel, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Visible = false
	})
	opsViews["SQUAD_ROOM"] = squadView

	-- Info Card (Left)
	local infoCard = create("Frame", {
		Parent = squadView, Size = UDim2.new(0.3, 0, 0.9, 0), Position = UDim2.new(0.02, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0
	})
	create("UICorner", {Parent = infoCard, CornerRadius = UDim.new(0.05, 0)})

	-- Header Strip
	local headerFrame = create("Frame", {
		Name = "HeaderFrame", Parent = infoCard, Size = UDim2.new(1, 0, 0.15, 0), BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0
	})
	create("UICorner", {Parent = headerFrame, CornerRadius = UDim.new(0.05, 0)})
	create("Frame", { -- Flatten bottom corners
		Parent = headerFrame, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0,0,0.5,0), BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0
	})

	local roomTitle = create("TextLabel", {
		Name = "RoomTitle", Parent = headerFrame, Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.new(0.05, 0, 0, 0),
		Text = "ROOM NAME", Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center
	})
	create("UITextSizeConstraint", {Parent = roomTitle, MaxTextSize = 24})

	-- Details
	local roomDetails = create("TextLabel", {
		Name = "RoomDetails", Parent = infoCard, Size = UDim2.new(0.9, 0, 0.4, 0), Position = UDim2.new(0.05, 0, 0.20, 0),
		Text = "Mode: Story\nDiff: Easy", Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextDim, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
	})
	create("UITextSizeConstraint", {Parent = roomDetails, MaxTextSize = 18})

	-- Leave Button
	createButton(infoCard, "LEAVE SQUAD", UDim2.new(0.9, 0, 0.12, 0), UDim2.new(0.05, 0, 0.85, 0), THEME.Colors.AccentRed, function()
		lobbyRemote:FireServer("leaveRoom")
	end).TextLabel.TextColor3 = THEME.Colors.Paper

	-- Roster Area (Right)
	local rosterArea = create("Frame", {
		Parent = squadView, Size = UDim2.new(0.65, 0, 0.9, 0), Position = UDim2.new(0.34, 0, 0.05, 0),
		BackgroundTransparency = 1
	})

	local rosterHeaderBg = create("Frame", {
		Parent = rosterArea, Size = UDim2.new(1, 0, 0.1, 0), BackgroundColor3 = THEME.Colors.FolderDark, BackgroundTransparency = 0.5
	})
	create("UICorner", {Parent = rosterHeaderBg, CornerRadius = UDim.new(0.2, 0)})

	local rosterHeader = create("TextLabel", {
		Parent = rosterHeaderBg, Size = UDim2.new(1, 0, 1, 0), Text = "PERSONNEL ROSTER",
		Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = rosterHeader, MaxTextSize = 18})

	local rosterGrid = create("ScrollingFrame", {
		Name = "RosterGrid", Parent = rosterArea, Size = UDim2.new(1, 0, 0.72, 0), Position = UDim2.new(0, 0, 0.12, 0),
		BackgroundTransparency = 1, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	create("UIGridLayout", {
		Parent = rosterGrid, CellSize = UDim2.new(0.23, 0, 0.45, 0), CellPadding = UDim2.new(0.02, 0, 0.02, 0)
	})

	-- Action Button (Host) - Full Width at Bottom
	local actionBtn = createButton(rosterArea, "START MISSION", UDim2.new(1, 0, 0.12, 0), UDim2.new(0, 0, 0.85, 0), THEME.Colors.AccentGreen, function()
		if state.currentRoom and state.currentRoom.hostName == player.Name then
			lobbyRemote:FireServer("forceStartGame")
		end
	end)
	actionBtn.Name = "ActionBtn"
	actionBtn.TextLabel.TextColor3 = THEME.Colors.Paper
	actionBtn.TextLabel.Font = getFont("Stamp")
	-- === SUB-VIEW: MATCHMAKING (New) ===
	local matchmakingView = create("Frame", {
		Name = "MatchmakingView", Parent = panel, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Visible = false
	})
	opsViews["MATCHMAKING"] = matchmakingView

	local mmHeader = create("TextLabel", {
		Parent = matchmakingView, Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.new(0, 0, 0.05, 0),
		Text = "ESTABLISHING UPLINK...", Font = getFont("Header"), TextScaled = true,
		TextColor3 = THEME.Colors.AccentGreen, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = mmHeader, MaxTextSize = 24})

	-- Blinking Text Effect
	task.spawn(function()
		while matchmakingView.Parent do
			for i = 1, 0, -0.1 do mmHeader.TextTransparency = i task.wait(0.05) end
			for i = 0, 1, 0.1 do mmHeader.TextTransparency = i task.wait(0.05) end
		end
	end)

    -- Info Container (Threat Level & Destination)
    local infoContainer = create("Frame", {
        Name = "InfoContainer", Parent = matchmakingView, Size = UDim2.new(0.8, 0, 0.15, 0), Position = UDim2.new(0.5, 0, 0.15, 0),
        AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1
    })

    local destLabel = create("TextLabel", {
        Name = "DestinationLabel", Parent = infoContainer, Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 0, 0),
        Text = "DESTINATION: VILLAGE", Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
        TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1
    })
    create("UITextSizeConstraint", {Parent = destLabel, MaxTextSize = 18})

    local threatLabel = create("TextLabel", {
        Name = "ThreatLabel", Parent = infoContainer, Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 0.5, 0),
        Text = "THREAT LEVEL: NORMAL", Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.AccentRed,
        TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1
    })
    create("UITextSizeConstraint", {Parent = threatLabel, MaxTextSize = 18})


	local slotsContainer = create("Frame", {
		Name = "SlotsContainer", Parent = matchmakingView, Size = UDim2.new(0.9, 0, 0.45, 0),
		Position = UDim2.new(0.5, 0, 0.45, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1
	})
	-- Grid layout will be set dynamically in startMatchmaking to center slots

	local cancelMMBtn = createButton(matchmakingView, "ABORT SEQUENCE", UDim2.new(0.4, 0, 0.1, 0), UDim2.new(0.3, 0, 0.85, 0), THEME.Colors.AccentRed, function()
		-- Send cancel request to server before returning to menu
		lobbyRemote:FireServer("cancelMatchmaking")
		state.activeView = "MENU"
		updateOpsView()
	end)
	cancelMMBtn.TextLabel.TextColor3 = THEME.Colors.Paper

end -- End of createOpsPanel

function startMatchmaking()
	state.activeView = "MATCHMAKING"
	updateOpsView()

	local view = opsViews["MATCHMAKING"]
	local container = view:FindFirstChild("SlotsContainer")
    local infoContainer = view:FindFirstChild("InfoContainer")
	if not container or not infoContainer then return end

    -- Update Info Labels
    local diff = state.settings.difficulty or "NORMAL"
    local map = state.settings.map or "ACT 1: Village"
    
    infoContainer.DestinationLabel.Text = string.upper(map)
    infoContainer.ThreatLabel.Text = "THREAT LEVEL: " .. string.upper(diff)

	-- Clear old slots
	for _, c in ipairs(container:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	
	-- Remove old layout if exists
	local oldLayout = container:FindFirstChildOfClass("UIGridLayout")
	if oldLayout then oldLayout:Destroy() end

	local playerCount = state.settings.maxPlayers or 4
	
	-- Create Dynamic Grid Layout
	create("UIGridLayout", {
		Parent = container, 
		CellSize = UDim2.new(1/playerCount - 0.02, 0, 0.8, 0), 
		CellPadding = UDim2.new(0.02, 0, 0, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center
	})

	-- Create Slots - Local player ALWAYS first (left), rest are empty/searching
	for i = 1, playerCount do
		local slot = create("Frame", {
			Parent = container, BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0,
			Name = "Slot_" .. i, LayoutOrder = i
		})
        create("UICorner", {Parent = slot, CornerRadius = UDim.new(0.1, 0)})
        slot.BackgroundTransparency = 1

		-- Only local player in first slot, rest are empty
        local isLocalPlayer = (i == 1)
		
        -- Icon/Profile
		local icon = create("ImageLabel", {
			Parent = slot, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0.5, 0, 0.4, 0), AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", BackgroundTransparency = 1, 
            ImageColor3 = isLocalPlayer and Color3.new(1,1,1) or THEME.Colors.TextDim,
            ScaleType = Enum.ScaleType.Crop, Name = "Icon"
		})
        create("UIAspectRatioConstraint", {Parent = icon, AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize})
        create("UICorner", {Parent = icon, CornerRadius = UDim.new(1, 0)})
        create("UIStroke", {Parent = icon, Thickness = 3, Color = THEME.Colors.TextMain, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
        
        -- Name Label
        local nameLbl = create("TextLabel", {
            Parent = slot, Size = UDim2.new(1.2, 0, 0.2, 0), Position = UDim2.new(0.5, 0, 0.75, 0), AnchorPoint = Vector2.new(0.5, 0.5),
            Text = isLocalPlayer and player.Name or "", 
            Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, BackgroundTransparency = 1,
			Name = "NameLabel"
        })
        create("UITextSizeConstraint", {Parent = nameLbl, MaxTextSize = 14})
		
		-- Status Text
		local statusLbl = create("TextLabel", {
			Parent = slot, Size = UDim2.new(1, 0, 0.15, 0), Position = UDim2.new(0, 0, 0.9, 0),
			Text = isLocalPlayer and "LINKED" or "SEARCHING...", 
            Font = getFont("Body"), TextScaled = true, 
            TextColor3 = isLocalPlayer and THEME.Colors.AccentGreen or THEME.Colors.TextDim, 
            BackgroundTransparency = 1, Name = "StatusLabel"
		})

        if isLocalPlayer then
            -- Load local player's avatar
            task.spawn(function()
                local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150)
                if content then icon.Image = content end
            end)
        else
            -- Pulse Effect for Searching slots
             task.spawn(function()
                 local t = 0
                 while slot.Parent and statusLbl.Text == "SEARCHING..." do
                     t = t + 0.1
                     local alpha = 0.5 + 0.5 * math.sin(t)
                     statusLbl.TextTransparency = 0.2 + 0.5 * alpha
                     task.wait(0.05)
                 end
             end)
        end
	end

	-- Send matchmaking request to server
	lobbyRemote:FireServer("startMatchmaking", {
		playerCount = state.settings.maxPlayers or 4,
		gameMode = state.settings.gameMode or "Story",
		difficulty = state.settings.difficulty or "Easy",
		map = state.settings.map or "ACT 1: Village"
	})
end

-- Function to update matchmaking slots when server sends queue update
function updateMatchmakingSlots(queuedPlayers, countdownValue)
	local view = opsViews["MATCHMAKING"]
	if not view or not view.Visible then return end
	
	local container = view:FindFirstChild("SlotsContainer")
	local header = view:FindFirstChild("TextLabel") -- The header label
	if not container then return end
	
	-- Update header if countdown is active
	if countdownValue and countdownValue > 0 then
		if header then
			header.Text = "DEPLOYING IN " .. countdownValue .. "..."
		end
	elseif countdownValue == 0 then
		if header then
			header.Text = "DEPLOYING NOW!"
		end
	end
	
	local playerCount = state.settings.maxPlayers or 4
	
	-- Update each slot based on queued players
	for i = 1, playerCount do
		local slot = container:FindFirstChild("Slot_" .. i)
		if not slot then continue end
		
		local icon = slot:FindFirstChild("Icon")
		local nameLbl = slot:FindFirstChild("NameLabel")
		local statusLbl = slot:FindFirstChild("StatusLabel")
		
		-- Find player data for this slot
		-- Local player is always slot 1, others fill in order
		local pData = nil
		if i == 1 then
			pData = player -- Local player always first
		elseif queuedPlayers then
			-- Find other players (excluding local player)
			local otherIndex = 1
			for _, qp in ipairs(queuedPlayers) do
				if qp.UserId ~= player.UserId then
					if otherIndex == (i - 1) then
						pData = qp
						break
					end
					otherIndex = otherIndex + 1
				end
			end
		end
		
		if pData then
			if nameLbl then nameLbl.Text = pData.Name or pData.name or "" end
			if statusLbl then 
				statusLbl.Text = "LINKED"
				statusLbl.TextColor3 = THEME.Colors.AccentGreen
				statusLbl.TextTransparency = 0
			end
			if icon then
				icon.ImageColor3 = Color3.new(1,1,1)
				-- Load avatar if we have UserId
				if pData.UserId then
					task.spawn(function()
						local content = Players:GetUserThumbnailAsync(pData.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150)
						if content and icon.Parent then icon.Image = content end
					end)
				end
			end
		else
			if nameLbl then nameLbl.Text = "" end
			if statusLbl then 
				statusLbl.Text = "SEARCHING..."
				statusLbl.TextColor3 = THEME.Colors.TextDim
			end
			if icon then 
				icon.ImageColor3 = THEME.Colors.TextDim
				icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
			end
		end
	end
end

function updateOpsView()
	-- Hide all first
	for _, v in pairs(opsViews) do v.Visible = false end

	if state.activeView == "MENU" then
		opsViews["MENU"].Visible = true
	elseif state.activeView == "MATCHMAKING" then
		opsViews["MATCHMAKING"].Visible = true
	elseif state.activeView == "CONFIG_SOLO" or state.activeView == "CONFIG_SQUAD" or state.activeView == "CONFIG_QUICK" then
		local v = opsViews["CONFIG"]
		v.Visible = true

		-- Toggle Input Fields based on mode
		local scroll = v:FindFirstChild("OptionsScroll")
		if scroll then
			for _, c in ipairs(scroll:GetChildren()) do
				if c.Name == "Input_roomName" then
					c.Visible = (state.activeView == "CONFIG_SQUAD")
				elseif c:IsA("Frame") and c:FindFirstChild("TextLabel") then
					local label = c.TextLabel.Text
					if label == "SQUAD SIZE" then
						-- Visible for Squad AND Quick Match
						c.Visible = (state.activeView == "CONFIG_SQUAD" or state.activeView == "CONFIG_QUICK")
					elseif label == "VISIBILITY" then
						-- Only for Squad
						c.Visible = (state.activeView == "CONFIG_SQUAD")
					elseif label == "SQUAD SIGNATURE" then
						c.Visible = (state.activeView == "CONFIG_SQUAD")
					end
				end
			end
		end

		local bottomContainer = v:FindFirstChild("BottomContainer")
		local btn = bottomContainer and bottomContainer:FindFirstChild("ActionBtn")
		if btn then
			if state.activeView == "CONFIG_SOLO" then
				btn.TextLabel.Text = "DEPLOY SOLO"
			elseif state.activeView == "CONFIG_QUICK" then
				btn.TextLabel.Text = "SEARCH COMMS"
			else
				btn.TextLabel.Text = "ESTABLISH LINK"
			end
		end
	elseif state.activeView == "LIST" then
		opsViews["LIST"].Visible = true
		lobbyRemote:FireServer("getPublicRooms") -- Refresh
	elseif state.activeView == "SQUAD_ROOM" then
		opsViews["SQUAD_ROOM"].Visible = true
	end
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
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.6, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundColor3 = Color3.new(0,0,0)
	})
	create("ImageLabel", {
		Parent = photoFrame, Size = UDim2.new(1, 0, 1, 0),
		Image = "rbxasset://textures/ui/GuiImagePlaceholder.png", ScaleType = Enum.ScaleType.Crop
	})

	-- Map Stats
	local sectorLbl = create("TextLabel", {
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.08, 0), Position = UDim2.new(0.05, 0, 0.7, 0),
		Text = "SECTOR: VILLAGE [GROUND ZERO]", Font = getFont("Header"), TextScaled = true,
		TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = sectorLbl, MaxTextSize = 18})

	local hazardLbl = create("TextLabel", {
		Parent = mapContainer, Size = UDim2.new(0.9, 0, 0.15, 0), Position = UDim2.new(0.05, 0, 0.8, 0),
		Text = "HAZARD: EXTREME RADIATION\nSTATUS: ACTIVE HOSTILES\nENTRY: PERMITTED", Font = getFont("Body"), TextScaled = true,
		TextColor3 = THEME.Colors.AccentRed, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = hazardLbl, MaxTextSize = 14})

	-- Right Side: Dossier / Objectives
	local dossier = create("Frame", {
		Parent = panel, Size = UDim2.new(0.5, 0, 0.9, 0), Position = UDim2.new(0.48, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.Paper, BorderSizePixel = 0
	})
	create("UICorner", {Parent = dossier, CornerRadius = UDim.new(0.05, 0)})

	-- Header Strip for Dossier
	local headerFrame = create("Frame", {
		Name = "HeaderFrame", Parent = dossier, Size = UDim2.new(1, 0, 0.15, 0), BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0
	})
	create("UICorner", {Parent = headerFrame, CornerRadius = UDim.new(0.05, 0)})
	create("Frame", { -- Flatten bottom corners
		Parent = headerFrame, Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0,0,0.5,0), BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0
	})

	local actTitle = create("TextLabel", {
		Parent = headerFrame, Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.new(0.05, 0, 0, 0),
		Text = "ACT 1: Village", Font = getFont("Header"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
	})
	create("UITextSizeConstraint", {Parent = actTitle, MaxTextSize = 24})

	-- Description
	local descLbl = create("TextLabel", {
		Parent = dossier, Size = UDim2.new(0.9, 0, 0.25, 0), Position = UDim2.new(0.05, 0, 0.20, 0),
		Text = "High energy readings detected. Source is located beneath the village square. Investigate the anomaly and neutralize any biological threats.",
		Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.TextMain, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, BackgroundTransparency = 1,
		TextYAlignment = Enum.TextYAlignment.Top
	})
	create("UITextSizeConstraint", {Parent = descLbl, MaxTextSize = 16})

	-- Divider
	create("Frame", {
		Parent = dossier, Size = UDim2.new(0.9, 0, 0.005, 0), Position = UDim2.new(0.05, 0, 0.45, 0),
		BackgroundColor3 = THEME.Colors.TextDim, BackgroundTransparency = 0.5, BorderSizePixel = 0
	})

	-- Objectives Header
	local objHeader = create("TextLabel", {
		Parent = dossier, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.47, 0),
		Text = "PRIMARY OBJECTIVES", Font = getFont("Label"), TextScaled = true, TextColor3 = THEME.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = objHeader, MaxTextSize = 14})

	-- Objectives List
	local objList = create("Frame", {
		Parent = dossier, Size = UDim2.new(0.9, 0, 0.4, 0), Position = UDim2.new(0.05, 0, 0.55, 0), BackgroundTransparency = 1
	})

	local objLbl = create("TextLabel", {
		Parent = objList, Size = UDim2.new(1, 0, 1, 0),
		Text = "> Locate the Source\n> Eliminate Hostiles\n> Survive until Extraction\n\n[CLASSIFIED INTEL ENCRYPTED]",
		Font = getFont("Body"), TextScaled = true, TextColor3 = THEME.Colors.AccentRed,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundTransparency = 1
	})
	create("UITextSizeConstraint", {Parent = objLbl, MaxTextSize = 16})
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

    -- Paper Texture Overlay
    create("ImageLabel", {
        Name = "PaperTexture", Parent = mainFrame, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Image = "rbxassetid://6071575925", -- Grunge/Paper Texture
        ImageTransparency = 0.9, -- Subtle effect
        ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0.5, 0, 0.5, 0)
    })
    create("UICorner", {Parent = mainFrame.PaperTexture, CornerRadius = UDim.new(0.02, 0)})

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
	createTab(tabContainer, "INTEL", "INTEL", 2)

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
	createIntelPanel(contentContainer)

	panels["OPS"].Visible = true
end

-- ================== VISUAL LOGIC ==================

function updateRoomList(roomsData)
	local listView = opsViews["LIST"]
	if not listView then return end
	local scroll = listView:FindFirstChild("RoomList")
	if not scroll then return end

	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end

	for _, room in pairs(roomsData) do
		local card = create("TextButton", {
			Parent = scroll, Size = UDim2.new(1, 0, 0.15, 0), BackgroundColor3 = THEME.Colors.Paper,
			AutoButtonColor = true, BorderSizePixel = 0, Text = ""
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
	-- Switch to OPS tab and SQUAD_ROOM view
	if state.activeTab ~= "OPS" then
		state.activeTab = "OPS"
		for tid, tabBtn in pairs(tabs) do
			local active = (tid == "OPS")
			tabBtn.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.ZIndex = active and 2 or 1
			tabBtn.Frame.BackgroundColor3 = active and THEME.Colors.FolderMain or THEME.Colors.FolderDark
			tabBtn.Frame.ZIndex = active and 2 or 1
			if tabBtn:FindFirstChild("TextLabel") then
				tabBtn.TextLabel.ZIndex = active and 3 or 2
			end
		end
		for pid, p in pairs(panels) do p.Visible = (pid == "OPS") end
	end

	state.activeView = "SQUAD_ROOM"
	updateOpsView()

	local squadView = opsViews["SQUAD_ROOM"]
	if not squadView then return end

	state.currentRoom = roomData
	local isHost = (roomData.hostName == player.Name)

	-- Find components inside squadView
	local infoCard = squadView:FindFirstChild("Frame") -- Info Card
	local rosterArea = nil
	for _, c in ipairs(squadView:GetChildren()) do
		if c:FindFirstChild("RosterGrid") then rosterArea = c end
	end
	-- Fallback if infoCard wasn't first child
	if not infoCard then
		for _, c in ipairs(squadView:GetChildren()) do
			if c:FindFirstChild("HeaderFrame") then infoCard = c break end
		end
	end

	if infoCard then
		local rName = roomData.roomName or "UNKNOWN ROOM"
		local rHost = roomData.hostName or "Unknown"
		local rMode = roomData.gameMode or "Story"
		local rDiff = roomData.difficulty or "Normal"

		local headerFrame = infoCard:FindFirstChild("HeaderFrame")
		if headerFrame and headerFrame:FindFirstChild("RoomTitle") then
			headerFrame.RoomTitle.Text = string.upper(rName)
		elseif infoCard:FindFirstChild("RoomTitle") then
			-- Fallback for legacy layout
			infoCard.RoomTitle.Text = string.upper(rName)
		end

		if infoCard:FindFirstChild("RoomDetails") then
			infoCard.RoomDetails.Text = string.format("HOST: %s\nMODE: %s\nDIFF: %s", rHost, rMode, rDiff)
		end

		-- Room Code Display (If Private)
		if roomData.roomCode then
			local codeLbl = infoCard:FindFirstChild("RoomCodeLbl") or create("TextLabel", {
				Name = "RoomCodeLbl", Parent = infoCard, Size = UDim2.new(0.9, 0, 0.12, 0), Position = UDim2.new(0.05, 0, 0.72, 0),
				Font = getFont("Stamp"), TextScaled = true, TextColor3 = THEME.Colors.AccentRed,
				BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Center, Rotation = -2
			})
			codeLbl.Text = "ACCESS KEY: " .. roomData.roomCode
			create("UITextSizeConstraint", {Parent = codeLbl, MaxTextSize = 18})
		else
			local existing = infoCard:FindFirstChild("RoomCodeLbl")
			if existing then existing:Destroy() end
		end
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
					Parent = grid, BackgroundTransparency = 1, BorderSizePixel = 0
				})

				-- Photo (Async Load) - Circular Style
				local photo = create("ImageLabel", {
					Parent = polaroid, Size = UDim2.new(0.9, 0, 0.70, 0), Position = UDim2.new(0.5, 0, 0.05, 0), AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(50, 50, 50), Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
					ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0
				})
				create("UIAspectRatioConstraint", {Parent = photo, AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize})
				create("UICorner", {Parent = photo, CornerRadius = UDim.new(1, 0)})
				create("UIStroke", {Parent = photo, Thickness = 3, Color = THEME.Colors.TextMain, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})

				-- Async load profile picture
				task.spawn(function()
					local content, isReady = Players:GetUserThumbnailAsync(pData.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
					if content then
						photo.Image = content
					end
				end)

				-- Booster Display (Overlay on bottom of circle)
				if pData.ActiveBooster then
					local boosterLbl = create("TextLabel", {
						Parent = photo, Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.new(0, 0, 0.75, 0),
						Text = pData.ActiveBooster, Font = getFont("Label"), TextScaled = true,
						TextColor3 = THEME.Colors.Highlight, BackgroundTransparency = 0.5, BackgroundColor3 = Color3.new(0,0,0),
						ZIndex = 2
					})
					create("UICorner", {Parent = boosterLbl, CornerRadius = UDim.new(0.5, 0)})
				end

				create("TextLabel", {
					Parent = polaroid, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.8, 0),
					Text = pData.Name, Font = getFont("Hand"), TextScaled = true, TextColor3 = THEME.Colors.TextMain,
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
		state.activeView = "MENU" -- Return to Menu on leave
		updateOpsView()
		-- Panels logic is already simple, just ensure OPS is visible
		for pid, p in pairs(panels) do p.Visible = (pid == "OPS") end
	-- ===== QUICK MATCH EVENT HANDLERS =====
	elseif action == "matchmakingStarted" then
		-- Server confirmed matchmaking started
		print("Matchmaking started - waiting for other players...")
	elseif action == "matchmakingCancelled" then
		-- Matchmaking was cancelled (by us or server), return to menu
		print("Matchmaking cancelled.")
		state.activeView = "MENU"
		updateOpsView()
	elseif action == "queueUpdate" then
		-- Server sent updated queue info (other players joined/left)
		print("Queue update received. Players in queue: " .. tostring(data.playerCount))
		updateMatchmakingSlots(data.players, nil)
	elseif action == "matchmakingCountdown" then
		-- Countdown is happening (queue is full)
		print("Matchmaking countdown: " .. tostring(data.countdown))
		updateMatchmakingSlots(data.players, data.countdown)
	elseif action == "matchmakingReset" then
		-- Someone left during countdown, reset to waiting
		print("Matchmaking reset - player left during countdown")
		updateMatchmakingSlots(data.players, nil)
		-- Reset header text
		local view = opsViews["MATCHMAKING"]
		if view then
			local header = view:FindFirstChild("TextLabel")
			if header then header.Text = "ESTABLISHING UPLINK..." end
		end
	end
end)

-- Bindable Event for Client-Client communication
local openLobbyEvent = ReplicatedStorage:FindFirstChild("OpenLobbyUI")
if not openLobbyEvent then
    openLobbyEvent = Instance.new("BindableEvent")
    openLobbyEvent.Name = "OpenLobbyUI"
    openLobbyEvent.Parent = ReplicatedStorage
end

-- NEW LISTENER: OpenLobbyRoomUI (Triggered by NPC Dialogue)
local openLobbyRoomEvent = ReplicatedStorage:FindFirstChild("OpenLobbyRoomUI")
if not openLobbyRoomEvent then
    openLobbyRoomEvent = Instance.new("BindableEvent")
    openLobbyRoomEvent.Name = "OpenLobbyRoomUI"
    openLobbyRoomEvent.Parent = ReplicatedStorage
end

openLobbyRoomEvent.Event:Connect(function()
    if state.isUIOpen then return end
    state.isUIOpen = true
    gui.Enabled = true
    if state.blurEffect then state.blurEffect.Enabled = true end
    
    mainFrame.Size = UDim2.new(0,0,0,0)
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = THEME.Sizes.MainFrame})
    tween:Play()
end)



createGUI()
lobbyRemote:FireServer("getPublicRooms")

-- Part Interaction LogicLogic
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
