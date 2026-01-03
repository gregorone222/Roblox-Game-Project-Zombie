-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- WaveCounterUI.lua (LocalScript)
-- Path: StarterGui/WaveCounterUI.lua
-- Script Place: ACT 1: Village
-- Theme: Apocalypse Survival (Matched to HUDs)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local WaveUpdateEvent = RemoteEvents:WaitForChild("WaveUpdateEvent")
local WaveCountdownEvent = RemoteEvents:WaitForChild("WaveCountdownEvent")

-- Note: GameConfig is server-side, so we use defaults here or rely on events
local ZOMBIES_PER_PLAYER_DEFAULT = 5

-- --- CONFIGURATION & CONSTANTS ---
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel      = Color3.fromRGB(35, 28, 22),      -- Warm brown panel
		Border     = Color3.fromRGB(139, 90, 43),     -- Forest Brown
		Accent     = Color3.fromRGB(218, 165, 32),    -- Golden
		
		TextMain   = Color3.fromRGB(255, 248, 230),   -- Warm white
		TextDim    = Color3.fromRGB(180, 160, 130),   -- Muted gold
		
		PulsingRed = Color3.fromRGB(200, 60, 60),     -- Deep Red (Combat)
		SafeGreen  = Color3.fromRGB(46, 204, 113),    -- Green (Safe)
		SafeAmber  = Color3.fromRGB(241, 196, 15),    -- Amber (Safe Warning)
		
		BarFill    = Color3.fromRGB(231, 76, 60),     -- Red Bar
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body   = Enum.Font.GothamMedium,
		Digital = Enum.Font.Code,
	}
}

-- --- HELPER FUNCTIONS ---
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius or 8)})
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.Border,
		Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0
	})
end

-- --- UI CREATION ---
local screenGui = create("ScreenGui", {
	Name = "WaveCounterUI",
	IgnoreGuiInset = true, ResetOnSpawn = true, Parent = playerGui
})

-- 1. Main Container (Top Center)
local container = create("Frame", {
	Name = "Container",
	Size = UDim2.new(0, 320, 0, 70),
	Position = UDim2.new(0.5, 0, 0.02, 0),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = screenGui
})

-- 1a. Wave Badge (Left - Square)
local waveBadge = create("Frame", {
	Name = "WaveBadge",
	Size = UDim2.new(0, 70, 0, 70),
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.2,
	Parent = container
})
addCorner(waveBadge, 12)
addStroke(waveBadge, THEME.Colors.Accent, 2)

local waveTitle = create("TextLabel", {
	Parent = waveBadge,
	Text = "WAVE",
	Font = THEME.Fonts.Body,
	TextSize = 10,
	TextColor3 = THEME.Colors.Accent,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 8),
	BackgroundTransparency = 1
})

local waveNumber = create("TextLabel", {
	Parent = waveBadge,
	Text = "1",
	Font = THEME.Fonts.Header,
	TextSize = 36,
	TextColor3 = THEME.Colors.TextMain,
	Size = UDim2.new(1, 0, 1, -20),
	Position = UDim2.new(0, 0, 0, 15),
	BackgroundTransparency = 1
})

-- 1b. Status Panel (Right - Extended)
local statusPanel = create("Frame", {
	Name = "StatusPanel",
	Size = UDim2.new(1, -60, 0, 40),
	Position = UDim2.new(0, 60, 0, 15), -- Overlap nicely
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.3,
	ZIndex = -1, -- Behind badge
	Parent = container
})
addCorner(statusPanel, 8)
addStroke(statusPanel, THEME.Colors.Border, 2)

-- 2. Combat Content (Infection Density)
local combatContent = create("Frame", {
	Name = "CombatContent", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Parent = statusPanel
})

local infLabel = create("TextLabel", {
	Parent = combatContent,
	Text = "THREAT LEVEL",
	Font = THEME.Fonts.Body,
	TextSize = 10,
	TextColor3 = THEME.Colors.TextDim,
	Size = UDim2.new(0, 100, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1
})

-- Bar
local barContainer = create("Frame", {
	Parent = combatContent,
	Size = UDim2.new(0.4, 0, 0.15, 0),
	Position = UDim2.new(0.4, 0, 0.42, 0),
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.5
})
addCorner(barContainer, 2)

local barFill = create("Frame", {
	Parent = barContainer,
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = THEME.Colors.PulsingRed
})
addCorner(barFill, 2)

local pctLabel = create("TextLabel", {
	Parent = combatContent,
	Text = "100%",
	Font = THEME.Fonts.Digital,
	TextSize = 14,
	TextColor3 = THEME.Colors.PulsingRed,
	Size = UDim2.new(0, 40, 1, 0),
	Position = UDim2.new(0.82, 0, 0, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
	BackgroundTransparency = 1
})


-- 3. Intermission Content (Safe Zone)
local safeContent = create("Frame", {
	Name = "SafeContent", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false, Parent = statusPanel
})

local safeLabel = create("TextLabel", {
	Parent = safeContent,
	Text = "SECURED",
	Font = THEME.Fonts.Header,
	TextSize = 14,
	TextColor3 = THEME.Colors.SafeGreen,
	Size = UDim2.new(0.6, 0, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1
})

local safeTimer = create("TextLabel", {
	Parent = safeContent,
	Text = "00:10",
	Font = THEME.Fonts.Digital,
	TextSize = 20,
	TextColor3 = THEME.Colors.TextMain,
	Size = UDim2.new(0.3, 0, 1, 0),
	Position = UDim2.new(0.65, 0, 0, 0),
	TextXAlignment = Enum.TextXAlignment.Right,
	BackgroundTransparency = 1
})


-- 4. Splash Text (Center Screen)
local splashContainer = create("Frame", {
	Size = UDim2.new(1, 0, 0, 100),
	Position = UDim2.new(0, 0, 0.35, 0),
	BackgroundTransparency = 1, Visible = false, Parent = screenGui
})

local splashText = create("TextLabel", {
	Parent = splashContainer,
	Text = "WAVE CLEARED",
	Font = THEME.Fonts.Header,
	TextSize = 42,
	TextColor3 = THEME.Colors.Accent,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	TextStrokeTransparency = 0.5,
	TextStrokeColor3 = Color3.new(0,0,0)
})

-- --- LOGIC ---

local currentWave = 0
local totalZombies = 0
local currentZombies = 0
local activePlayersCount = 1
local isIntermission = false

local function triggerSplash(text, color)
	splashContainer.Visible = true
	splashText.Text = text
	splashText.TextColor3 = color
	splashText.TextTransparency = 1
	splashText.TextSize = 20

	-- Zoom In + Fade In
	local t1 = TweenService:Create(splashText, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		TextSize = 48
	})
	t1:Play()
	t1.Completed:Wait()

	task.wait(1.5)

	-- Fade Out
	local t2 = TweenService:Create(splashText, TweenInfo.new(0.5), {
		TextTransparency = 1,
		TextSize = 56
	})
	t2:Play()
	t2.Completed:Connect(function()
		splashContainer.Visible = false
	end)
end

-- Wave Update
WaveUpdateEvent.OnClientEvent:Connect(function(wave, activePlayers)
	currentWave = wave
	activePlayersCount = activePlayers or 1
	isIntermission = false

	-- Reset UI State
	container.Visible = true
	combatContent.Visible = true
	safeContent.Visible = false

	-- Update Badge
	waveNumber.Text = tostring(wave)
	
	-- Colors: Combat Mode
	create("UIStroke", {Parent = waveBadge, Color = THEME.Colors.PulsingRed}) -- Force update stroke
	waveBadge.UIStroke.Color = THEME.Colors.PulsingRed
	waveTitle.TextColor3 = THEME.Colors.PulsingRed

	statusPanel.UIStroke.Color = THEME.Colors.Border

	-- Reset Bar
	barFill.Size = UDim2.new(0, 0, 1, 0)
	pctLabel.Text = "0%"

	-- Stats Logic
	local multiplier = ZOMBIES_PER_PLAYER_DEFAULT
	totalZombies = wave * multiplier * activePlayersCount
	if totalZombies < 1 then totalZombies = 1 end

	-- Shake
	local origin = UDim2.new(0.5, 0, 0.02, 0)
	for i = 1, 6 do
		container.Position = origin + UDim2.new(0, math.random(-3,3), 0, math.random(-3,3))
		task.wait(0.04)
	end
	container.Position = origin
end)

-- Wave Countdown
WaveCountdownEvent.OnClientEvent:Connect(function(seconds)
	if seconds > 0 then
		if not isIntermission then
			isIntermission = true
			combatContent.Visible = false
			safeContent.Visible = true

			-- Visuals: Safe Mode
			waveBadge.UIStroke.Color = THEME.Colors.SafeGreen
			waveTitle.TextColor3 = THEME.Colors.SafeGreen
			statusPanel.UIStroke.Color = THEME.Colors.SafeGreen

			triggerSplash("AREA SECURED", THEME.Colors.SafeGreen)
		end

		container.Visible = true
		safeTimer.Text = string.format("00:%02d", seconds)

		if seconds <= 5 then
			safeTimer.TextColor3 = THEME.Colors.SafeAmber
		else
			safeTimer.TextColor3 = THEME.Colors.TextMain
		end
	else
		isIntermission = false
		safeContent.Visible = false
	end
end)

-- Stats Loop
local lastCheck = 0
RunService.Heartbeat:Connect(function(dt)
	if not container.Visible or isIntermission then return end

	lastCheck += dt
	if lastCheck >= 0.5 then
		lastCheck = 0

		local count = 0
		for _, child in ipairs(workspace:GetChildren()) do
			if child:FindFirstChild("IsZombie") or child:GetAttribute("IsZombie") then
				local hum = child:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					count += 1
				end
			end
		end
		currentZombies = count
		-- Cap max to known total if count exceeds (e.g. spawns happen mid wave)
		if currentZombies > totalZombies then totalZombies = currentZombies end

		local pct = 0
		if totalZombies > 0 then
			pct = math.clamp(currentZombies / totalZombies, 0, 1)
		end

		-- Update Bar
		TweenService:Create(barFill, TweenInfo.new(0.3), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
		pctLabel.Text = string.format("%d%%", math.floor(pct * 100))

		-- Color Logic
		if pct < 0.2 then
			barFill.BackgroundColor3 = THEME.Colors.SafeAmber
			pctLabel.TextColor3 = THEME.Colors.SafeAmber
		else
			barFill.BackgroundColor3 = THEME.Colors.PulsingRed
			pctLabel.TextColor3 = THEME.Colors.PulsingRed
		end
	end
end)
