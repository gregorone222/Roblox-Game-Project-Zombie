-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- DailyRewardUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DailyRewardUI.lua
-- Script Place: Lobby
-- Theme: "Field Calendar" (Paper/Corkboard - Matches ProfileUI Dossier Style)
-- Redesigned by Lead Game Developer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== THEME CONSTANTS (Matching ProfileUI Dossier) ==================
local THEME = {
	Colors = {
		CorkBoard = Color3.fromRGB(160, 120, 80),    -- Cork background
		BoardFrame = Color3.fromRGB(90, 65, 45),     -- Dark wood frame
		Paper = Color3.fromRGB(245, 240, 230),       -- Off-white paper
		PaperAged = Color3.fromRGB(235, 225, 200),   -- Slightly aged paper
		InkPrimary = Color3.fromRGB(30, 30, 35),     -- Main text
		InkSecondary = Color3.fromRGB(80, 70, 60),   -- Sub text
		AccentRed = Color3.fromRGB(180, 50, 50),     -- Red marker/stamps
		AccentHighlight = Color3.fromRGB(255, 200, 50), -- Yellow marker
		PinRed = Color3.fromRGB(200, 60, 60),        -- Pushpin
		PinGold = Color3.fromRGB(200, 180, 100),     -- Gold pin
		CheckMark = Color3.fromRGB(50, 150, 50),     -- Green check
	},
	Fonts = {
		Typewriter = Enum.Font.SpecialElite,
		Handwritten = Enum.Font.PermanentMarker,
		Stamp = Enum.Font.Michroma,
		Body = Enum.Font.Gotham,
	},
	Assets = {
		Noise = "rbxassetid://6008328723",
	}
}

-- ================== HELPER FUNCTIONS ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

local function addCorner(parent, radius)
	return create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius)})
end

local function addStroke(parent, color, thickness)
	return create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.InkPrimary, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0
	})
end

local function addPaperTexture(parent)
	create("ImageLabel", {
		Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
		Image = THEME.Assets.Noise, ImageTransparency = 0.92, ImageColor3 = Color3.new(0,0,0),
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 128, 0, 128), ZIndex = 10
	})
end

local function playSound(soundId, parent)
	local s = create("Sound", {
		Parent = parent or playerGui, SoundId = soundId, Volume = 0.5
	})
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	return s
end

-- ================== UI CREATION ==================

local gui
local mainContainer
local calendarPage
local isOpening = false
local currentSelection = 1
local blurEffect = nil

-- Initialize Blur Effect Once
local camera = workspace.CurrentCamera
blurEffect = create("BlurEffect", {Parent = camera, Size = 0, Enabled = false})

-- Remotes
local getRewardInfo
local claimRewardEvent
local rewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))

local function resolveRemotes()
	local rfFolder = ReplicatedStorage:WaitForChild("RemoteFunctions", 1)
	if rfFolder then
		getRewardInfo = rfFolder:FindFirstChild("GetDailyRewardInfo")
		claimRewardEvent = rfFolder:FindFirstChild("ClaimDailyReward")
	end
	if not getRewardInfo or not claimRewardEvent then
		local reFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 1)
		if reFolder then
			getRewardInfo = getRewardInfo or reFolder:FindFirstChild("GetDailyRewardInfo")
			claimRewardEvent = claimRewardEvent or reFolder:FindFirstChild("ClaimDailyReward")
		end
	end
end
resolveRemotes()

-- ------------------------------------------------------
-- CALENDAR VISUALS (Paper Theme)
-- ------------------------------------------------------

local function closeUI()
	if not gui then return end

	-- Animation: Paper slide down
	TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0)
	}):Play()

	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.4, function() blurEffect.Enabled = false end)
	end

	task.wait(0.4)
	gui.Enabled = false
	isOpening = false
end

local function createCalendarUI()
	if gui then gui:Destroy() end

	gui = create("ScreenGui", {
		Name = "DailyRewardUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false, IgnoreGuiInset = true
	})

	-- Dark Backdrop
	local backdrop = create("Frame", {
		Name = "Backdrop", Parent = gui, Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.4, ZIndex = 0
	})

	-- === CORKBOARD FRAME ===
	mainContainer = create("Frame", {
		Name = "CorkBoard", Parent = gui,
		Size = UDim2.new(0, 750, 0, 500), Position = UDim2.new(0.5, 0, 1.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.CorkBoard
	})
	addCorner(mainContainer, 8)
	-- Wood Frame Border
	create("UIStroke", {Parent = mainContainer, Color = THEME.Colors.BoardFrame, Thickness = 8})

	-- Cork Texture
	create("ImageLabel", {
		Parent = mainContainer, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
		Image = THEME.Assets.Noise, ImageTransparency = 0.7, ImageColor3 = Color3.fromRGB(100, 70, 40),
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 64, 0, 64), ZIndex = 1
	})

	-- === CALENDAR PAPER (Pinned to Board) ===
	calendarPage = create("Frame", {
		Name = "CalendarPage", Parent = mainContainer,
		Size = UDim2.new(0.92, 0, 0.88, 0), Position = UDim2.new(0.04, 0, 0.08, 0),
		BackgroundColor3 = THEME.Colors.Paper, Rotation = math.random(-2, 2), ZIndex = 2
	})
	addCorner(calendarPage, 4)
	addPaperTexture(calendarPage)
	-- Paper shadow
	create("Frame", {
		Parent = mainContainer, Size = UDim2.new(0.92, 4, 0.88, 4),
		Position = UDim2.new(0.04, 2, 0.08, 2), BackgroundColor3 = Color3.new(0,0,0),
		BackgroundTransparency = 0.7, ZIndex = 1
	})

	-- Pushpin at top
	local pin = create("Frame", {
		Parent = calendarPage, Size = UDim2.new(0, 24, 0, 24),
		Position = UDim2.new(0.5, -12, 0, -12), BackgroundColor3 = THEME.Colors.PinRed, ZIndex = 15
	})
	addCorner(pin, 12)
	create("Frame", { -- Pin highlight
		Parent = pin, Size = UDim2.new(0.3, 0, 0.3, 0), Position = UDim2.new(0.2, 0, 0.15, 0),
		BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.5, ZIndex = 16
	})

	-- === HEADER ===
	local header = create("Frame", {
		Parent = calendarPage, Size = UDim2.new(1, 0, 0.12, 0), BackgroundTransparency = 1, ZIndex = 3
	})
	-- Title
	create("TextLabel", {
		Parent = header, Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0.02, 0, 0, 0),
		Text = "SUPPLY CALENDAR", Font = THEME.Fonts.Stamp, TextSize = 22,
		TextColor3 = THEME.Colors.InkPrimary, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, ZIndex = 3
	})
	-- Divider
	create("Frame", {
		Parent = header, Size = UDim2.new(0.96, 0, 0, 2), Position = UDim2.new(0.02, 0, 1, -2),
		BackgroundColor3 = THEME.Colors.InkSecondary, BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 3
	})

	-- === GRID AREA ===
	local gridArea = create("Frame", {
		Name = "GridArea", Parent = calendarPage, Size = UDim2.new(0.6, 0, 0.82, 0), Position = UDim2.new(0.02, 0, 0.14, 0),
		BackgroundTransparency = 1, ZIndex = 3
	})
	create("UIGridLayout", {
		Parent = gridArea, CellSize = UDim2.new(0.14, 0, 0.22, 0), CellPadding = UDim2.new(0.01, 0, 0.02, 0)
	})

	-- === INFO PANEL (Right Side - Like a note) ===
	local infoPanel = create("Frame", {
		Name = "InfoPanel", Parent = calendarPage, Size = UDim2.new(0.34, 0, 0.82, 0), Position = UDim2.new(0.64, 0, 0.14, 0),
		BackgroundColor3 = THEME.Colors.PaperAged, Rotation = math.random(-1, 1), ZIndex = 4
	})
	addCorner(infoPanel, 4)
	addPaperTexture(infoPanel)
	addStroke(infoPanel, THEME.Colors.InkSecondary, 1)

	-- Sticky note effect (tape at top)
	local tape = create("Frame", {
		Parent = infoPanel, Size = UDim2.new(0.5, 0, 0.06, 0), Position = UDim2.new(0.25, 0, -0.03, 0),
		BackgroundColor3 = Color3.fromRGB(200, 200, 150), BackgroundTransparency = 0.3, ZIndex = 5
	})
	addCorner(tape, 2)

	-- Info Content
	create("TextLabel", {
		Name = "RewardTitle", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.12, 0), Position = UDim2.new(0.05, 0, 0.08, 0),
		Text = "SELECT A DAY", Font = THEME.Fonts.Handwritten, TextSize = 20, TextColor3 = THEME.Colors.InkPrimary,
		BackgroundTransparency = 1, TextWrapped = true, ZIndex = 5
	})

	local previewBox = create("Frame", {
		Parent = infoPanel, Size = UDim2.new(0.7, 0, 0.35, 0), Position = UDim2.new(0.15, 0, 0.22, 0),
		BackgroundColor3 = Color3.new(1,1,1), ZIndex = 5
	})
	addCorner(previewBox, 4)
	addStroke(previewBox, THEME.Colors.InkSecondary, 2)

	create("ImageLabel", {
		Name = "RewardPreview", Parent = previewBox, Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.1, 0, 0.1, 0),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 6
	})

	create("TextLabel", {
		Name = "RewardDesc", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.18, 0), Position = UDim2.new(0.05, 0, 0.6, 0),
		Text = "---", Font = THEME.Fonts.Typewriter, TextSize = 14, TextColor3 = THEME.Colors.InkSecondary,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 5
	})

	-- Action Button
	local actionBtn = create("TextButton", {
		Name = "ActionBtn", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.12, 0), Position = UDim2.new(0.05, 0, 0.82, 0),
		BackgroundColor3 = THEME.Colors.InkSecondary, Text = "LOCKED", Font = THEME.Fonts.Stamp, TextSize = 14,
		TextColor3 = THEME.Colors.Paper, ZIndex = 5
	})
	addCorner(actionBtn, 4)

	-- Close Button (X drawn on paper corner)
	local closeBtn = create("TextButton", {
		Parent = calendarPage, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.94, 0, 0.02, 0),
		BackgroundTransparency = 1, Text = "X", Font = THEME.Fonts.Handwritten, TextSize = 28,
		TextColor3 = THEME.Colors.AccentRed, Rotation = math.random(-10, 10), ZIndex = 10
	})
	create("UIStroke", {Parent = closeBtn, Color = THEME.Colors.AccentRed, Thickness = 2, Transparency = 0.3})
	create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(1,0)})
	closeBtn.MouseButton1Click:Connect(closeUI)
end

-- ------------------------------------------------------
-- LOGIC & UPDATES
-- ------------------------------------------------------

local function guideToCrate()
	closeUI()

	local lobby = workspace:FindFirstChild("LobbyEnvironment")
	local crate = lobby and lobby:FindFirstChild("SupplyCrate", true)

	if crate then
		local beam = Instance.new("SelectionBox")
		beam.Adornee = crate
		beam.Color3 = THEME.Colors.AccentHighlight
		beam.LineThickness = 0.1
		beam.Parent = crate
		game.Debris:AddItem(beam, 5)

		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "SUPPLY DROP";
			Text = "Marked on your map. Proceed to the crate.";
			Duration = 5;
		})
	end
end

local function updateInfoPanel(day, stateInfo)
	if not gui then return end
	local panel = calendarPage:FindFirstChild("InfoPanel")
	if not panel then return end

	local title = panel:FindFirstChild("RewardTitle")
	local desc = panel:FindFirstChild("RewardDesc")
	local img = panel:FindFirstChild("RewardPreview", true)
	local btn = panel:FindFirstChild("ActionBtn")

	local reward = rewardConfig.Rewards[day]
	if not reward then return end

	title.Text = "DAY " .. day
	desc.Text = string.format("Reward: %s\nValue: %s", reward.Type, tostring(reward.Value))

	-- Icons
	local iconId = "rbxassetid://497939460"
	if reward.Type == "Coins" then iconId = "rbxassetid://281938327" end
	if img then img.Image = iconId end

	-- Button State
	if btn:GetAttribute("Conn") then
		local new = btn:Clone()
		new.Parent = panel
		btn:Destroy()
		btn = new
	end
	btn:SetAttribute("Conn", true)

	if day < stateInfo.CurrentDay then
		btn.Text = "COLLECTED"
		btn.BackgroundColor3 = THEME.Colors.CheckMark
		btn.TextColor3 = THEME.Colors.Paper
		btn.AutoButtonColor = false
	elseif day == stateInfo.CurrentDay then
		if stateInfo.CanClaim then
			btn.Text = "LOCATE CRATE"
			btn.BackgroundColor3 = THEME.Colors.AccentHighlight
			btn.TextColor3 = THEME.Colors.InkPrimary
			btn.AutoButtonColor = true

			task.spawn(function()
				while btn.Parent and btn.Text == "LOCATE CRATE" do
					TweenService:Create(btn, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
						BackgroundColor3 = THEME.Colors.AccentRed
					}):Play()
					task.wait(1.2)
				end
			end)

			btn.MouseButton1Click:Connect(guideToCrate)
		else
			btn.Text = "COME BACK LATER"
			btn.BackgroundColor3 = THEME.Colors.AccentRed
			btn.TextColor3 = THEME.Colors.Paper
			btn.AutoButtonColor = false
		end
	else
		btn.Text = "LOCKED"
		btn.BackgroundColor3 = THEME.Colors.InkSecondary
		btn.TextColor3 = THEME.Colors.Paper
		btn.AutoButtonColor = false
	end
end

function populateGrid(currentDay, canClaim)
	local gridArea = calendarPage:FindFirstChild("GridArea")

	-- Clear existing
	for _, c in ipairs(gridArea:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for i = 1, #rewardConfig.Rewards do
		local cell = create("TextButton", {
			Parent = gridArea, BackgroundColor3 = THEME.Colors.Paper,
			Text = "", AutoButtonColor = true, ZIndex = 3
		})
		addCorner(cell, 4)
		addStroke(cell, THEME.Colors.InkSecondary, 1)

		-- Day Number
		create("TextLabel", {
			Parent = cell, Size = UDim2.new(1,0,0.4,0), Position = UDim2.new(0,0,0,0),
			Text = tostring(i), Font = THEME.Fonts.Handwritten, TextSize = 18,
			TextColor3 = THEME.Colors.InkPrimary, BackgroundTransparency = 1, ZIndex = 4
		})

		-- Icon (Mini)
		local reward = rewardConfig.Rewards[i]
		local iconId = "rbxassetid://497939460"
		if reward.Type == "Coins" then iconId = "rbxassetid://281938327" end

		create("ImageLabel", {
			Parent = cell, Size = UDim2.new(0.5,0,0.4,0), Position = UDim2.new(0.25,0,0.4,0),
			BackgroundTransparency = 1, Image = iconId, ZIndex = 4
		})

		-- State visuals
		if i < currentDay then
			-- Claimed - Green checkmark overlay
			cell.BackgroundColor3 = Color3.fromRGB(230, 245, 230)
			cell.UIStroke.Color = THEME.Colors.CheckMark

			local check = create("TextLabel", {
				Parent = cell, Size = UDim2.new(1,0,1,0), Text = "✓",
				Font = THEME.Fonts.Handwritten, TextSize = 40, TextColor3 = THEME.Colors.CheckMark,
				BackgroundTransparency = 1, Rotation = math.random(-10, 10), ZIndex = 5
			})
		elseif i == currentDay then
			-- Today - Red circle highlight
			cell.BackgroundColor3 = THEME.Colors.Paper
			cell.UIStroke.Color = THEME.Colors.AccentRed
			cell.UIStroke.Thickness = 3

			if canClaim then
				-- Pulsing effect
				TweenService:Create(cell.UIStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
					Color = THEME.Colors.AccentHighlight
				}):Play()
			end
		else
			-- Locked - Faded
			cell.BackgroundColor3 = Color3.fromRGB(220, 215, 205)
			cell.UIStroke.Color = Color3.fromRGB(180, 175, 165)
			cell.TextLabel.TextColor3 = Color3.fromRGB(150, 145, 135)
			cell.ImageLabel.ImageTransparency = 0.6
		end

		cell.MouseButton1Click:Connect(function()
			updateInfoPanel(i, {CurrentDay = currentDay, CanClaim = canClaim})
		end)
	end
end

local function loadData()
	if isOpening then return end
	isOpening = true

	resolveRemotes()
	if not getRewardInfo then
		warn("DailyReward Remotes not found!")
		isOpening = false
		return
	end

	local success, result = pcall(function() return getRewardInfo:InvokeServer() end)

	if success and result then
		createCalendarUI()
		gui.Enabled = true

		-- Enable Blur
		if blurEffect then
			blurEffect.Enabled = true
			TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 15}):Play()
		end

		populateGrid(result.CurrentDay, result.CanClaim)
		updateInfoPanel(result.CurrentDay, result)

		-- Animation: Slide Up + Slight rotation settle
		mainContainer.Position = UDim2.new(0.5, 0, 1.5, 0)
		mainContainer.Rotation = math.random(-5, 5)
		TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Rotation = 0
		}):Play()

		playSound("rbxassetid://9114102853") -- Paper rustle sound

	else
		warn("Failed to fetch reward data")
		isOpening = false
	end
end

-- ================== HUD TRIGGER ==================
local function createHUD()
	if playerGui:FindFirstChild("DailyRewardHUD") then playerGui.DailyRewardHUD:Destroy() end

	local hud = create("ScreenGui", {Name = "DailyRewardHUD", Parent = playerGui, ResetOnSpawn = false})

	-- Calendar Icon Button (Looks like a small paper calendar)
	local openBtn = create("TextButton", {
		Parent = hud, Size = UDim2.new(0, 55, 0, 65), Position = UDim2.new(0, 20, 0.5, -32),
		BackgroundColor3 = THEME.Colors.Paper, Text = ""
	})
	addCorner(openBtn, 6)
	addStroke(openBtn, THEME.Colors.BoardFrame, 3)

	-- Calendar header bar
	create("Frame", {
		Parent = openBtn, Size = UDim2.new(1,0,0.25,0), BackgroundColor3 = THEME.Colors.AccentRed
	})
	create("UICorner", {Parent = openBtn:FindFirstChild("Frame"), CornerRadius = UDim.new(0, 6)})

	-- Day text
	create("TextLabel", {
		Parent = openBtn, Size = UDim2.new(1,0,0.6,0), Position = UDim2.new(0,0,0.35,0),
		Text = os.date("%d"), Font = THEME.Fonts.Handwritten, TextSize = 28,
		TextColor3 = THEME.Colors.InkPrimary, BackgroundTransparency = 1
	})

	openBtn.MouseButton1Click:Connect(loadData)

	-- Listen for Server Open Request
	local remoteEvt = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("ShowDailyRewardUI")
	if remoteEvt then
		remoteEvt.OnClientEvent:Connect(loadData)
	end
end

createHUD()
-- print removed
