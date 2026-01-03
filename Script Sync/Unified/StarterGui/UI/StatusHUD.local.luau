-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- StatusHUD.lua (LocalScript)
-- Path: StarterGui/StatusHUD.lua
-- Script Place: ACT 1: Village
-- Theme: Apocalypse Survival (Matched to Inventory & AmmoUI)

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui 		 = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- === REMOTE EVENTS ===
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local ModuleScriptReplicatedStorage = ReplicatedStorage:WaitForChild("ModuleScript")

local KnockEvent = RemoteEvents:WaitForChild("KnockEvent")
local ShieldUpdateEvent = RemoteEvents:WaitForChild("ShieldUpdateEvent")
local UpdateWalkSpeedModifierEvent = RemoteEvents:WaitForChild("UpdateWalkSpeedModifierEvent")
local StaminaUpdateEvent  = RemoteEvents:WaitForChild("StaminaUpdate")
local JumpEvent      = RemoteEvents:WaitForChild("JumpEvent")
local DebuffStatusEvent = RemoteEvents:WaitForChild("DebuffStatusEvent")
local SprintEvent = RemoteEvents:WaitForChild("SprintEvent")

-- === MODULES ===
local DebuffInfo = require(ModuleScriptReplicatedStorage:WaitForChild("DebuffInfo"))

DebuffStatusEvent.OnClientEvent:Connect(function(isSlowed)
	DebuffInfo.isSlowed = isSlowed
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

-- === THEME CONFIGURATION ===
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel      = Color3.fromRGB(35, 28, 22),      -- Warm brown panel
		Border     = Color3.fromRGB(139, 90, 43),     -- Forest Brown
		
		Health     = Color3.fromRGB(200, 60, 60),     -- Deep Red
		Shield     = Color3.fromRGB(60, 160, 220),    -- Blue (Warmer cyan if possible, but keep distinct)
		Stamina    = Color3.fromRGB(255, 200, 80),    -- Bright Amber
		Accent     = Color3.fromRGB(218, 165, 32),    -- Golden

		TextMain   = Color3.fromRGB(255, 248, 230),   -- Warm white
		TextDim    = Color3.fromRGB(180, 160, 130),   -- Muted gold
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body   = Enum.Font.GothamMedium,
	},
	Anim = {
		Spring = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		Linear = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Pulse  = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	}
}

-- Adaptive Text Sizing (Mobile: 12-20, Desktop: 20-32)
local IS_MOBILE = UserInputService.TouchEnabled
local TEXT_MIN = IS_MOBILE and 12 or 20
local TEXT_MAX = IS_MOBILE and 20 or 32

-- === STATE ===
local currentHealth = 100
local maxHealth = 100
local currentShield = 0
local currentStamina = 100
local maxStamina = 100
local isSprinting = false
local isShiftHeld = false

-- Constants
local CLIENT_DRAIN_PER_SEC = 20
local CLIENT_REGEN_PER_SEC = 3
local MIN_TO_SPRINT        = 10
local MIN_TO_JUMP          = 5
local REGEN_DELAY          = 1.0
local SPRINT_SPEED_BONUS   = 6

-- === UI CONSTRUCTION ===
local hudScreen = Instance.new("ScreenGui")
hudScreen.Name = "StatusHUD_Survival"
hudScreen.IgnoreGuiInset = true
hudScreen.ResetOnSpawn = false
hudScreen.Parent = playerGui

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Helper Functions
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, r)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, r or 8)})
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.Accent,
		Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end

-- Main Container
local mainFrame = create("Frame", {
	Name = "MainFrame",
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.2,
	Parent = hudScreen
})
addCorner(mainFrame, 12)
addStroke(mainFrame, THEME.Colors.Border, 2)

if isMobile() then
	mainFrame.Size = UDim2.new(0, 220, 0, 80)
	mainFrame.Position = UDim2.new(0, 20, 0, 20) -- Top-left
	mainFrame.AnchorPoint = Vector2.new(0, 0)
else
	mainFrame.Size = UDim2.new(0, 300, 0, 90)
	mainFrame.Position = UDim2.new(0, 30, 1, -30) -- Bottom-left
	mainFrame.AnchorPoint = Vector2.new(0, 1)
end

-- Inner Gradient for depth
local grad = create("UIGradient", {
	Parent = mainFrame,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
	}),
	Rotation = 90
})

-- == HEALTH SECTION ==
local hpLabel = create("TextLabel", {
	Parent = mainFrame,
	Text = "VITALS",
	Size = UDim2.new(0.3, 0, 0.25, 0),
	Position = UDim2.new(0.05, 0, 0.05, 0),
	BackgroundTransparency = 1,
	TextColor3 = THEME.Colors.Accent,
	Font = THEME.Fonts.Header,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left
})

local hpVal = create("TextLabel", {
	Parent = mainFrame,
	Text = "100",
	Size = UDim2.new(0.3, 0, 0.35, 0),
	Position = UDim2.new(0.95, 0, 0.05, 0),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	TextColor3 = THEME.Colors.TextMain,
	Font = THEME.Fonts.Header,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Right
})

local hpBarBg = create("Frame", {
	Parent = mainFrame,
	Name = "HP_BG",
	Size = UDim2.new(0.9, 0, 0.15, 0),
	Position = UDim2.new(0.05, 0, 0.4, 0),
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.5
})
addCorner(hpBarBg, 4)

local hpFill = create("Frame", {
	Parent = hpBarBg,
	Name = "HP_Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = THEME.Colors.Health
})
addCorner(hpFill, 4)

-- Shield Overlay (Thin line on top of HP Fill)
local shieldBar = create("Frame", {
	Parent = hpBarBg,
	Name = "Shield",
	Size = UDim2.new(0, 0, 0.3, 0), -- 30% height of HP bar
	Position = UDim2.new(0, 0, 0, 0), -- Top aligned
	BackgroundColor3 = THEME.Colors.Shield,
	ZIndex = 5
})
addCorner(shieldBar, 2)

-- == STAMINA SECTION ==
local stamBarBg = create("Frame", {
	Parent = mainFrame,
	Name = "Stam_BG",
	Size = UDim2.new(0.9, 0, 0.08, 0),
	Position = UDim2.new(0.05, 0, 0.65, 0),
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.5
})
addCorner(stamBarBg, 2)

local stamFill = create("Frame", {
	Parent = stamBarBg,
	Name = "Stam_Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = THEME.Colors.Stamina
})
addCorner(stamFill, 2)

local stamIcon = create("TextLabel", {
	Parent = mainFrame,
	Text = "⚡",
	Size = UDim2.new(0.1, 0, 0.2, 0),
	Position = UDim2.new(0.05, 0, 0.75, 0),
	BackgroundTransparency = 1,
	TextColor3 = THEME.Colors.Stamina,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left
})

local stamVal = create("TextLabel", {
	Parent = mainFrame,
	Name = "StamVal",
	Text = "RUN",
	Size = UDim2.new(0.2, 0, 0.2, 0),
	Position = UDim2.new(0.15, 0, 0.75, 0),
	BackgroundTransparency = 1,
	TextColor3 = THEME.Colors.TextDim,
	Font = THEME.Fonts.Body,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left
})

-- === MOBILE BUTTON ===
local mobileBtn = nil
if isMobile() then
	local btnFrame = create("Frame", {
		Parent = hudScreen,
		Size = UDim2.new(0, 64, 0, 64),
		Position = UDim2.new(0.85, 0, 0.6, 0), -- Right side thumb area
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = THEME.Colors.Panel,
		BackgroundTransparency = 0.2
	})
	addCorner(btnFrame, 32) -- Circle
	local mStroke = create("UIStroke", {
		Parent = btnFrame, Thickness = 3, Color = THEME.Colors.Border,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})

	local icon = create("TextLabel", {
		Parent = btnFrame, Text = "🏃", Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.2, 0.2), BackgroundTransparency = 1,
		TextScaled = true
	})

	local button = create("TextButton", {
		Parent = btnFrame, Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1, Text = ""
	})

	mobileBtn = {Frame = btnFrame, Icon = icon, Stroke = mStroke}
end


-- === ANIMATIONS & UPDATES ===
local pulseTween = nil

local function updateHealthVis()
	local pct = math.clamp(currentHealth / maxHealth, 0, 1)

	-- Tween Bar
	TweenService:Create(hpFill, THEME.Anim.Linear, {Size = UDim2.new(pct, 0, 1, 0)}):Play()

	-- Text Update & Color
	if localPlayer.Character and localPlayer.Character:FindFirstChild("Knocked") then
		hpVal.Text = "DOWN"
		hpVal.TextColor3 = THEME.Colors.Health
	else
		hpVal.Text = string.format("%d", math.floor(currentHealth))
		hpVal.TextColor3 = THEME.Colors.TextMain
	end

	-- Critical Health Pulse
	if pct < 0.3 then
		if not pulseTween then
			local stroke = mainFrame:FindFirstChild("UIStroke")
			if stroke then
				pulseTween = TweenService:Create(stroke, THEME.Anim.Pulse, {Color = THEME.Colors.Health})
				pulseTween:Play()
			end
		end
	else
		if pulseTween then
			pulseTween:Cancel()
			pulseTween = nil
			local stroke = mainFrame:FindFirstChild("UIStroke")
			if stroke then stroke.Color = THEME.Colors.Border end
		end
	end
end

local function updateShieldVis()
	local pct = math.clamp(currentShield / maxHealth, 0, 1)
	TweenService:Create(shieldBar, THEME.Anim.Linear, {Size = UDim2.new(pct, 0, 0.3, 0)}):Play()
end

local function updateStaminaVis()
	local pct = math.clamp(currentStamina / maxStamina, 0, 1)
	TweenService:Create(stamFill, THEME.Anim.Linear, {Size = UDim2.new(pct, 0, 1, 0)}):Play()

	if mobileBtn then
		if isSprinting then
			mobileBtn.Stroke.Color = THEME.Colors.Stamina
			mobileBtn.Frame.BackgroundColor3 = THEME.Colors.Accent
		else
			mobileBtn.Stroke.Color = THEME.Colors.Border
			mobileBtn.Frame.BackgroundColor3 = THEME.Colors.Panel
		end
	end
end

-- === LOGIC (SPRINT & INPUT) - COPIED FROM OLD SCRIPT ===

local function isToolAiming()
	local character = localPlayer.Character
	if not character then return false end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool or not tool.GetAttribute then return false end
	local ok, val = pcall(function() return tool:GetAttribute("IsAiming") end)
	return ok and (val == true)
end

local function isReloading()
	local character = localPlayer.Character
	if not character then return false end
	return character:GetAttribute("IsReloading") == true
end

local function stopSprint()
	if not isSprinting then return end
	isSprinting = false
	if localPlayer.Character then localPlayer.Character:SetAttribute("IsSprinting", false) end

	UpdateWalkSpeedModifierEvent:FireServer("sprint", nil)
	SprintEvent:FireServer("Stop")
	updateStaminaVis()
end

local function startSprint()
	if isToolAiming() or isReloading() or DebuffInfo.isSlowed then return end
	if currentStamina <= MIN_TO_SPRINT then return end

	local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.MoveDirection.Magnitude <= 0.1 then return end

	isSprinting = true
	if localPlayer.Character then localPlayer.Character:SetAttribute("IsSprinting", true) end

	UpdateWalkSpeedModifierEvent:FireServer("sprint", SPRINT_SPEED_BONUS)
	SprintEvent:FireServer("Start")
	updateStaminaVis()
end

local function toggleSprint()
	if isSprinting then stopSprint() else startSprint() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = true
		startSprint()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
		isShiftHeld = false
		stopSprint()
	end
end)

if mobileBtn then
	mobileBtn.Frame.TextButton.MouseButton1Click:Connect(toggleSprint)
end

-- === INIT & LOOP ===
local lastSprintStop = 0

local function onCharacterAdded(char)
	local human = char:WaitForChild("Humanoid")
	currentHealth = human.Health
	maxHealth = human.MaxHealth
	currentShield = 0
	isSprinting = false

	updateHealthVis()
	updateShieldVis()
	updateStaminaVis()

	human.HealthChanged:Connect(function(newH)
		currentHealth = newH
		updateHealthVis()
	end)

	human:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		maxHealth = human.MaxHealth
		updateHealthVis()
	end)

	human.StateChanged:Connect(function(old, new)
		if new == Enum.HumanoidStateType.Jumping and currentStamina >= MIN_TO_JUMP then
			pcall(function() JumpEvent:FireServer() end)
		end
	end)
end

KnockEvent.OnClientEvent:Connect(function() updateHealthVis() end)
ShieldUpdateEvent.OnClientEvent:Connect(function(val) currentShield = val; updateShieldVis() end)
StaminaUpdateEvent.OnClientEvent:Connect(function(val) currentStamina = tonumber(val) or currentStamina; updateStaminaVis() end)

RunService.RenderStepped:Connect(function(dt)
	if not localPlayer.Character then return end
	local human = localPlayer.Character:FindFirstChild("Humanoid")
	if not human then return end

	if localPlayer.Character:GetAttribute("RequestStopSprint") == true then
		stopSprint()
		localPlayer.Character:SetAttribute("RequestStopSprint", nil)
	end

	if isShiftHeld and not isSprinting then
		local canStart = (not isToolAiming()) and (not isReloading()) and currentStamina > MIN_TO_SPRINT
		if canStart and human.MoveDirection.Magnitude > 0.1 then startSprint() end
	end

	if isSprinting and (isReloading() or isToolAiming()) then stopSprint() end

	if isSprinting and currentStamina > 0 then
		local moving = human.MoveDirection.Magnitude > 0.1
		if not moving then
			currentStamina = math.min(maxStamina, currentStamina + CLIENT_REGEN_PER_SEC * dt)
		else
			currentStamina = math.max(0, currentStamina - CLIENT_DRAIN_PER_SEC * dt)
			if currentStamina <= 0 then stopSprint(); lastSprintStop = tick() end
		end
	else
		if not isSprinting and (tick() - lastSprintStop > REGEN_DELAY) then
			currentStamina = math.min(maxStamina, currentStamina + CLIENT_REGEN_PER_SEC * dt)
			local moving = human.MoveDirection.Magnitude > 0.1
			if isShiftHeld and moving and currentStamina >= MIN_TO_SPRINT and not isReloading() and not isToolAiming() then
				startSprint()
			end
		end
	end

	-- Restore Logic: Jump Constraint
	local originalJumpPower = localPlayer.Character:GetAttribute("OriginalJumpPower") or 30
	if currentStamina < MIN_TO_JUMP then
		if human.JumpPower > 0 then
			localPlayer.Character:SetAttribute("OriginalJumpPower", human.JumpPower)
			human.JumpPower = 0
		end
	else
		if human.JumpPower == 0 then
			human.JumpPower = originalJumpPower
		end
	end

	localPlayer.Character:SetAttribute("ClientStamina", currentStamina)
	updateStaminaVis()
end)

if localPlayer.Character then onCharacterAdded(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
