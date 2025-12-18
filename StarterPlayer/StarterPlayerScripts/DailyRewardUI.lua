-- DailyRewardUI.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DailyRewardUI.lua
-- Script Place: Lobby
-- Theme: Zombie Apocalypse "Tactical Tablet" (Military/Digital)
-- Redesigned by Lead Game Developer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		CaseDark = Color3.fromRGB(25, 25, 25),      -- Tablet Body
		CaseLight = Color3.fromRGB(45, 45, 50),     -- Edges
		ScreenBg = Color3.fromRGB(10, 15, 10),      -- CRT Black
		Phosphor = Color3.fromRGB(50, 255, 100),    -- Primary Green
		PhosphorDim = Color3.fromRGB(20, 100, 40),  -- Dimmed Green
		Alert = Color3.fromRGB(255, 50, 50),        -- Red Alert
		Amber = Color3.fromRGB(255, 180, 50),       -- Warning/Gold
		Scanline = Color3.fromRGB(0, 0, 0)          -- Scanline Color
	},
	Fonts = {
		Digital = Enum.Font.Code,         -- Monospace/Code
		Header = Enum.Font.Michroma,      -- Sci-fi Header
		System = Enum.Font.RobotoMono     -- Readable Info
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
		Parent = parent, Color = color or THEME.Colors.Phosphor, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0
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
local screenGroup
local isOpening = false
local currentSelection = 1 -- Currently selected day in the grid
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
-- TABLET VISUALS
-- ------------------------------------------------------

local function closeUI()
	if not gui then return end

	-- Animation: Screen Off
	TweenService:Create(screenGroup, TweenInfo.new(0.2), {Size = UDim2.new(0.92, 0, 0, 2), Position = UDim2.new(0.04, 0, 0.5, 0)}):Play()

	if blurEffect then
		TweenService:Create(blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
		task.delay(0.3, function() blurEffect.Enabled = false end)
	end

	task.wait(0.2)
	gui.Enabled = false
	isOpening = false
end

local function createTabletUI()
	if gui then gui:Destroy() end

	gui = create("ScreenGui", {
		Name = "DailyRewardUI", Parent = playerGui, ResetOnSpawn = false, Enabled = false, IgnoreGuiInset = true
	})

	local backdrop = create("Frame", {
		Name = "Backdrop", Parent = gui, Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.3, ZIndex = 0
	})

	-- === TABLET CASE ===
	mainContainer = create("Frame", {
		Name = "TabletCase", Parent = gui,
		Size = UDim2.new(0, 800, 0, 500), Position = UDim2.new(0.5, 0, 1.5, 0), -- Start off-screen
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.CaseDark
	})
	addCorner(mainContainer, 16)
	addStroke(mainContainer, Color3.new(0.1, 0.1, 0.1), 4)

	-- Industrial details (screws/lines)
	local decoTop = create("Frame", {
		Parent = mainContainer, Size = UDim2.new(0.4, 0, 0.02, 0), Position = UDim2.new(0.3, 0, 0.02, 0),
		BackgroundColor3 = THEME.Colors.CaseLight, BorderSizePixel = 0
	})
	addCorner(decoTop, 2)

	-- === DIGITAL SCREEN (CANVAS GROUP) ===
	screenGroup = create("CanvasGroup", {
		Name = "ScreenGroup", Parent = mainContainer,
		Size = UDim2.new(0.92, 0, 0.88, 0), Position = UDim2.new(0.04, 0, 0.08, 0),
		BackgroundColor3 = THEME.Colors.ScreenBg, BorderSizePixel = 0
	})
	addCorner(screenGroup, 4)
	-- Screen Glow
	create("UIStroke", {
		Parent = screenGroup, Color = THEME.Colors.Phosphor, Transparency = 0.8, Thickness = 2
	})

	-- Scanlines (Tiled Image or simple lines)
	local scanline = create("ImageLabel", {
		Name = "Scanlines", Parent = screenGroup, Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Image = "rbxassetid://7200216447", -- Generic scanline texture
		ImageTransparency = 0.9, ImageColor3 = THEME.Colors.Scanline,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 4, 0, 4), ZIndex = 10
	})

	-- === HEADER ===
	local headerBar = create("Frame", {
		Parent = screenGroup, Size = UDim2.new(1, 0, 0.1, 0), BackgroundTransparency = 1
	})
	create("Frame", { -- Divider
		Parent = headerBar, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = THEME.Colors.Phosphor, BackgroundTransparency = 0.5
	})
	create("TextLabel", {
		Parent = headerBar, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.02, 0, 0, 0),
		Text = "SUPPLY LOG // MIL-NET", Font = THEME.Fonts.Header, TextSize = 18,
		TextColor3 = THEME.Colors.Phosphor, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})
	create("TextLabel", { -- Battery
		Parent = headerBar, Size = UDim2.new(0.2, 0, 1, 0), Position = UDim2.new(0.78, 0, 0, 0),
		Text = "PWR: 87% [ONLINE]", Font = THEME.Fonts.Digital, TextSize = 14,
		TextColor3 = THEME.Colors.PhosphorDim, TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1
	})

	-- === CONTENT GRID ===
	local gridArea = create("Frame", {
		Name = "GridArea", Parent = screenGroup, Size = UDim2.new(0.65, 0, 0.85, 0), Position = UDim2.new(0.02, 0, 0.12, 0),
		BackgroundTransparency = 1
	})
	local gridLayout = create("UIGridLayout", {
		Parent = gridArea, CellSize = UDim2.new(0.13, 0, 0.22, 0), CellPadding = UDim2.new(0.01, 0, 0.01, 0)
	})

	-- === INFO PANEL ===
	local infoPanel = create("Frame", {
		Name = "InfoPanel", Parent = screenGroup, Size = UDim2.new(0.3, 0, 0.85, 0), Position = UDim2.new(0.68, 0, 0.12, 0),
		BackgroundColor3 = Color3.fromRGB(15, 20, 15), BorderSizePixel = 0
	})
	addCorner(infoPanel, 4)
	addStroke(infoPanel, THEME.Colors.PhosphorDim, 1)

	-- Info Content
	create("TextLabel", {
		Name = "RewardTitle", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		Text = "SELECT DAY", Font = THEME.Fonts.Header, TextSize = 20, TextColor3 = THEME.Colors.Phosphor,
		BackgroundTransparency = 1, TextWrapped = true
	})

	local previewBox = create("Frame", {
		Parent = infoPanel, Size = UDim2.new(0.8, 0, 0.35, 0), Position = UDim2.new(0.1, 0, 0.2, 0),
		BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0
	})
	addStroke(previewBox, THEME.Colors.PhosphorDim, 1)

	create("ImageLabel", {
		Name = "RewardPreview", Parent = previewBox, Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.1, 0, 0.1, 0),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageColor3 = THEME.Colors.Phosphor
	})

	create("TextLabel", {
		Name = "RewardDesc", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.2, 0), Position = UDim2.new(0.05, 0, 0.6, 0),
		Text = "---", Font = THEME.Fonts.System, TextSize = 14, TextColor3 = THEME.Colors.PhosphorDim,
		BackgroundTransparency = 1, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
	})

	-- Action Button
	local actionBtn = create("TextButton", {
		Name = "ActionBtn", Parent = infoPanel, Size = UDim2.new(0.9, 0, 0.12, 0), Position = UDim2.new(0.05, 0, 0.85, 0),
		BackgroundColor3 = THEME.Colors.PhosphorDim, Text = "LOCKED", Font = THEME.Fonts.Header, TextSize = 16,
		TextColor3 = THEME.Colors.ScreenBg
	})
	addCorner(actionBtn, 4)

	-- Close 'Button' (Physical button on tablet bezel)
	local powerBtn = create("TextButton", {
		Parent = mainContainer, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0.94, 0, 0.08, 0),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40), Text = "", AutoButtonColor = true
	})
	addCorner(powerBtn, 20)
	create("ImageLabel", {
		Parent = powerBtn, Size = UDim2.new(0.6, 0, 0.6, 0), Position = UDim2.new(0.2, 0, 0.2, 0),
		BackgroundTransparency = 1, Image = "rbxassetid://7072718266", ImageColor3 = Color3.fromRGB(200, 50, 50) -- Power icon
	})
	powerBtn.MouseButton1Click:Connect(closeUI)
end

-- ------------------------------------------------------
-- LOGIC & UPDATES
-- ------------------------------------------------------



-- --- MODIFIED: GUIDE LOGIC ---
local function guideToCrate()
	closeUI()

	-- Find the crate
	local lobby = workspace:FindFirstChild("LobbyEnvironment")
	local crate = lobby and lobby:FindFirstChild("SupplyCrate", true)

	if crate then
		-- Add Beam/Guide
		local beam = Instance.new("SelectionBox")
		beam.Adornee = crate
		beam.Color3 = THEME.Colors.Phosphor
		beam.LineThickness = 0.1
		beam.Parent = crate

		game.Debris:AddItem(beam, 5)

		-- Notify
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "DROP ZONE";
			Text = "Coordinates received. Proceed to the Supply Crate.";
			Duration = 5;
		})
	end
end

local function updateInfoPanel(day, stateInfo)
	if not gui then return end
	local panel = screenGroup:FindFirstChild("InfoPanel")
	if not panel then return end

	local title = panel:FindFirstChild("RewardTitle")
	local desc = panel:FindFirstChild("RewardDesc")
	local img = panel:FindFirstChild("RewardPreview", true)
	local btn = panel:FindFirstChild("ActionBtn")

	local reward = rewardConfig.Rewards[day]
	if not reward then return end

	title.Text = "DAY " .. day
	desc.Text = string.format("REWARD: %s\nVAL: %s", reward.Type, tostring(reward.Value))

	-- Icons
	local iconId = "rbxassetid://497939460" -- Default Crate
	if reward.Type == "Coins" then iconId = "rbxassetid://281938327" end
	if img then img.Image = iconId end

	-- Button State
	if btn:GetAttribute("Conn") then
		-- In a real scenario, disconnect nicely. Here we clone to clear.
		local new = btn:Clone()
		new.Parent = panel
		btn:Destroy()
		btn = new
	end
	btn:SetAttribute("Conn", true)

	if day < stateInfo.CurrentDay then
		btn.Text = "CLAIMED"
		btn.BackgroundColor3 = THEME.Colors.PhosphorDim
		btn.TextColor3 = THEME.Colors.ScreenBg
		btn.AutoButtonColor = false
	elseif day == stateInfo.CurrentDay then
		if stateInfo.CanClaim then
			-- --- MODIFIED: REDIRECT TO CRATE ---
			btn.Text = "LOCATE DROP"
			btn.BackgroundColor3 = THEME.Colors.Phosphor
			btn.TextColor3 = THEME.Colors.ScreenBg
			btn.AutoButtonColor = true

			-- Pulse Effect
			task.spawn(function()
				while btn.Parent and btn.Text == "LOCATE DROP" do
					TweenService:Create(btn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundColor3 = THEME.Colors.Amber}):Play()
					task.wait(1.6)
				end
			end)

			btn.MouseButton1Click:Connect(guideToCrate)
		else
			btn.Text = "WAIT..."
			btn.BackgroundColor3 = THEME.Colors.Alert
			btn.TextColor3 = THEME.Colors.ScreenBg
			btn.AutoButtonColor = false
		end
	else
		btn.Text = "LOCKED"
		btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
		btn.TextColor3 = Color3.fromRGB(100,100,100)
		btn.AutoButtonColor = false
	end
end

function populateGrid(currentDay, canClaim)
	local gridArea = screenGroup:FindFirstChild("GridArea")

	-- Clear existing
	for _, c in ipairs(gridArea:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for i = 1, #rewardConfig.Rewards do
		local cell = create("TextButton", {
			Parent = gridArea, BackgroundColor3 = THEME.Colors.ScreenBg,
			Text = "", AutoButtonColor = true
		})
		addStroke(cell, THEME.Colors.PhosphorDim, 1)
		addCorner(cell, 4)

		-- Day Number
		create("TextLabel", {
			Parent = cell, Size = UDim2.new(1,0,0.4,0), Position = UDim2.new(0,0,0,0),
			Text = tostring(i), Font = THEME.Fonts.Digital, TextSize = 16,
			TextColor3 = THEME.Colors.PhosphorDim, BackgroundTransparency = 1
		})

		-- Icon (Mini)
		local reward = rewardConfig.Rewards[i]
		local iconId = "rbxassetid://497939460"
		if reward.Type == "Coins" then iconId = "rbxassetid://281938327" end

		create("ImageLabel", {
			Parent = cell, Size = UDim2.new(0.5,0,0.5,0), Position = UDim2.new(0.25,0,0.35,0),
			BackgroundTransparency = 1, Image = iconId, ImageColor3 = THEME.Colors.PhosphorDim
		})

		-- Logic State
		if i < currentDay then
			-- Claimed
			cell.BackgroundColor3 = Color3.fromRGB(15, 30, 15)
			cell.UIStroke.Color = THEME.Colors.PhosphorDim
			cell.UIStroke.Transparency = 0.5
			cell.ImageLabel.ImageColor3 = Color3.fromRGB(50, 80, 50)
		elseif i == currentDay then
			-- Today
			cell.BackgroundColor3 = Color3.fromRGB(10, 25, 10)
			cell.UIStroke.Color = canClaim and THEME.Colors.Phosphor or THEME.Colors.Amber
			cell.UIStroke.Thickness = 2
			cell.ImageLabel.ImageColor3 = canClaim and THEME.Colors.Phosphor or THEME.Colors.Amber
			cell.TextLabel.TextColor3 = canClaim and THEME.Colors.Phosphor or THEME.Colors.Amber

			if canClaim then
				-- Blink
				TweenService:Create(cell.UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5}):Play()
			end
		else
			-- Locked
			cell.UIStroke.Color = Color3.fromRGB(30, 30, 30)
			cell.ImageLabel.ImageColor3 = Color3.fromRGB(40, 40, 40)
			cell.TextLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
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
		createTabletUI()
		gui.Enabled = true

		-- Enable Blur
		if blurEffect then
			blurEffect.Enabled = true
			TweenService:Create(blurEffect, TweenInfo.new(0.5), {Size = 15}):Play()
		end

		populateGrid(result.CurrentDay, result.CanClaim)
		updateInfoPanel(result.CurrentDay, result) -- Select current day by default

		-- Animation: Slide Up + Boot
		mainContainer.Position = UDim2.new(0.5, 0, 1.5, 0)
		TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

		-- Screen boot effect (Vertical expand)
		screenGroup.Size = UDim2.new(0.92, 0, 0, 2)
		screenGroup.Position = UDim2.new(0.04, 0, 0.5, 0)
		task.wait(0.4)
		TweenService:Create(screenGroup, TweenInfo.new(0.3), {Size = UDim2.new(0.92, 0, 0.88, 0), Position = UDim2.new(0.04, 0, 0.08, 0)}):Play()

		playSound("rbxassetid://4501579366") -- Sci-fi boot sound

	else
		warn("Failed to fetch reward data")
		isOpening = false
	end
end

-- ================== HUD TRIGGER ==================
-- Replaces/Creates the HUD button to open this menu
local function createHUD()
	if playerGui:FindFirstChild("DailyRewardHUD") then playerGui.DailyRewardHUD:Destroy() end

	local hud = create("ScreenGui", {Name = "DailyRewardHUD", Parent = playerGui, ResetOnSpawn = false})

	-- Tablet Icon Button
	local openBtn = create("TextButton", {
		Parent = hud, Size = UDim2.new(0, 60, 0, 80), Position = UDim2.new(0, 20, 0.5, -40),
		BackgroundColor3 = THEME.Colors.CaseDark, Text = ""
	})
	addCorner(openBtn, 8)
	addStroke(openBtn, THEME.Colors.PhosphorDim, 2)

	local screen = create("Frame", {
		Parent = openBtn, Size = UDim2.new(0.8,0,0.8,0), Position = UDim2.new(0.1,0,0.1,0),
		BackgroundColor3 = THEME.Colors.ScreenBg
	})
	addCorner(screen, 4)

	create("TextLabel", {
		Parent = screen, Size = UDim2.new(1,0,1,0), Text = "LOG",
		Font = THEME.Fonts.Digital, TextSize = 14, TextColor3 = THEME.Colors.Phosphor
	})

	openBtn.MouseButton1Click:Connect(loadData)

	-- Listen for Server Open Request (e.g. on join)
	local remoteEvt = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("ShowDailyRewardUI")
	if remoteEvt then
		remoteEvt.OnClientEvent:Connect(loadData)
	end
end

createHUD()
print("DailyRewardUI (Tactical Tablet) Initialized")
