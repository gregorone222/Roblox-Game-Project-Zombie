-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- StatusHUD.lua (LocalScript)
-- Path: StarterGui/StatusHUD.lua
-- Script Place: ACT 1: Village

--[[
    STATUS HUD - TACTICAL SURVIVAL THEME
    A rugged, military-grade interface.
    Features: Modular layout, stencil fonts, and functional data displays.
]]

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
		HealthGood   = Color3.fromRGB(110, 200, 110), -- Muted Green
		HealthLow    = Color3.fromRGB(220, 180, 50),  -- Warning Yellow
		HealthCrit   = Color3.fromRGB(200, 60, 60),   -- Alert Red
		Shield       = Color3.fromRGB(60, 140, 220),  -- Tactical Blue
		Stamina      = Color3.fromRGB(220, 160, 60),  -- Orange
		BgSolid      = Color3.fromRGB(30, 35, 35),    -- Gunmetal
		BgDark       = Color3.fromRGB(15, 20, 20),    -- Dark Grey
		Border       = Color3.fromRGB(180, 185, 180), -- Steel
		TextMain     = Color3.fromRGB(240, 240, 240), -- White
		TextDim      = Color3.fromRGB(150, 160, 160), -- Grey text
	},
	Fonts = {
		Stencil = Enum.Font.Sarpanch,    -- Military Stencil
		Data    = Enum.Font.RobotoMono,  -- Monospace Data
	},
	Layout = {
		Desktop = UDim2.new(0, 40, 1, -40),
		Mobile  = UDim2.new(0, 20, 0, 20),
	},
	Anim = {
		Spring = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		Linear = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	}
}

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
hudScreen.Name = "StatusHUD_Tactical"
hudScreen.IgnoreGuiInset = true
hudScreen.ResetOnSpawn = false
hudScreen.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainUnit"
mainFrame.Size = UDim2.new(0, 320, 0, 90)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = hudScreen

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

if isMobile() then
	mainFrame.Size = UDim2.new(0, 240, 0, 70)
	mainFrame.Position = THEME.Layout.Mobile
	mainFrame.AnchorPoint = Vector2.new(0, 0)
else
	mainFrame.Position = THEME.Layout.Desktop
	mainFrame.AnchorPoint = Vector2.new(0, 1)
end

-- === COMPONENT CREATION ===

-- 1. Main Backplate (The Device)
local plate = Instance.new("Frame")
plate.Name = "Plate"
plate.Size = UDim2.new(1, 0, 1, 0)
plate.BackgroundColor3 = THEME.Colors.BgDark
plate.BackgroundTransparency = 0.2
plate.BorderSizePixel = 0
plate.Parent = mainFrame

local plateCorner = Instance.new("UICorner")
plateCorner.CornerRadius = UDim.new(0, 4)
plateCorner.Parent = plate

local plateStroke = Instance.new("UIStroke")
plateStroke.Thickness = 2
plateStroke.Color = THEME.Colors.BgSolid
plateStroke.Parent = plate

-- Decorative "Bolts" or "Status Lights"
local function createBolt(x, y)
	local b = Instance.new("Frame")
	b.Size = UDim2.new(0, 4, 0, 4)
	b.Position = UDim2.new(x, 0, y, 0)
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = THEME.Colors.Border
	b.BorderSizePixel = 0
	b.Parent = plate
	Instance.new("UICorner", b).CornerRadius = UDim.new(1,0)
end
createBolt(0.03, 0.1); createBolt(0.97, 0.1); createBolt(0.03, 0.9); createBolt(0.97, 0.9)

-- 2. Health Module
local hpLabel = Instance.new("TextLabel")
hpLabel.Text = "VITALS"
hpLabel.Size = UDim2.new(0.2, 0, 0, 15)
hpLabel.Position = UDim2.new(0.08, 0, 0.1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.TextColor3 = THEME.Colors.TextDim
hpLabel.Font = THEME.Fonts.Stencil
hpLabel.TextSize = 14
hpLabel.TextXAlignment = Enum.TextXAlignment.Left
hpLabel.Parent = plate

local hpVal = Instance.new("TextLabel")
hpVal.Name = "HP_Val"
hpVal.Text = "100%"
hpVal.Size = UDim2.new(0.2, 0, 0, 20)
hpVal.Position = UDim2.new(0.88, 0, 0.1, 0)
hpVal.AnchorPoint = Vector2.new(1, 0)
hpVal.BackgroundTransparency = 1
hpVal.TextColor3 = THEME.Colors.HealthGood
hpVal.Font = THEME.Fonts.Data
hpVal.TextSize = 18
hpVal.TextXAlignment = Enum.TextXAlignment.Right
hpVal.Parent = plate

-- The Bar Container
local hpContainer = Instance.new("Frame")
hpContainer.Size = UDim2.new(0.84, 0, 0, 16)
hpContainer.Position = UDim2.new(0.08, 0, 0.35, 0)
hpContainer.BackgroundColor3 = Color3.new(0,0,0)
hpContainer.BorderSizePixel = 0
hpContainer.Parent = plate

-- The Grid Overlay for the bar
local hpGrid = Instance.new("ImageLabel")
hpGrid.Size = UDim2.fromScale(1,1)
hpGrid.BackgroundTransparency = 1
hpGrid.Image = "rbxassetid://2736224329" -- Generic grid texture
hpGrid.ImageColor3 = Color3.new(0,0,0)
hpGrid.ImageTransparency = 0.7
hpGrid.ScaleType = Enum.ScaleType.Tile
hpGrid.TileSize = UDim2.new(0, 10, 0, 16)
hpGrid.ZIndex = 3
hpGrid.Parent = hpContainer

-- The Fill
local hpFill = Instance.new("Frame")
hpFill.Name = "HP_Fill"
hpFill.Size = UDim2.fromScale(1,1)
hpFill.BackgroundColor3 = THEME.Colors.HealthGood
hpFill.BorderSizePixel = 0
hpFill.ZIndex = 2
hpFill.Parent = hpContainer

-- Shield Overlay (Thin line on top of HP)
local shieldBar = Instance.new("Frame")
shieldBar.Name = "Shield"
shieldBar.Size = UDim2.new(0, 0, 0, 4)
shieldBar.Position = UDim2.new(0.08, 0, 0.3, 0) -- Sit on top of HP container
shieldBar.BackgroundColor3 = THEME.Colors.Shield
shieldBar.BorderSizePixel = 0
shieldBar.ZIndex = 4
shieldBar.Parent = plate

-- 3. Stamina Module
local stamLabel = Instance.new("TextLabel")
stamLabel.Text = "STAMINA"
stamLabel.Size = UDim2.new(0.2, 0, 0, 15)
stamLabel.Position = UDim2.new(0.08, 0, 0.6, 0)
stamLabel.BackgroundTransparency = 1
stamLabel.TextColor3 = THEME.Colors.TextDim
stamLabel.Font = THEME.Fonts.Stencil
stamLabel.TextSize = 12
stamLabel.TextXAlignment = Enum.TextXAlignment.Left
stamLabel.Parent = plate

local stamContainer = Instance.new("Frame")
stamContainer.Size = UDim2.new(0.84, 0, 0, 8)
stamContainer.Position = UDim2.new(0.08, 0, 0.8, 0)
stamContainer.BackgroundColor3 = Color3.new(0,0,0)
stamContainer.BorderSizePixel = 0
stamContainer.Parent = plate

local stamFill = Instance.new("Frame")
stamFill.Name = "Stam_Fill"
stamFill.Size = UDim2.fromScale(1,1)
stamFill.BackgroundColor3 = THEME.Colors.Stamina
stamFill.BorderSizePixel = 0
stamFill.Parent = stamContainer

-- === MOBILE BUTTON (Tactical Toggle) ===
local mobileBtn = nil
if isMobile() then
	local btnFrame = Instance.new("Frame")
	btnFrame.Size = UDim2.new(0, 60, 0, 60)
	btnFrame.Position = UDim2.new(0.8, 0, 0.45, 0)
	btnFrame.BackgroundColor3 = THEME.Colors.BgSolid
	btnFrame.BackgroundTransparency = 0.2
	btnFrame.BorderSizePixel = 0
	btnFrame.Parent = hudScreen

	local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(1,0); btnCorner.Parent = btnFrame
	local btnStroke = Instance.new("UIStroke"); btnStroke.Thickness = 2; btnStroke.Color = THEME.Colors.Border; btnStroke.Parent = btnFrame

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://13460867865" -- Run icon
	icon.ImageColor3 = THEME.Colors.TextMain
	icon.Parent = btnFrame

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromScale(1,1)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = btnFrame

	mobileBtn = {Frame = btnFrame, Icon = icon, Stroke = btnStroke}
end

-- === VIGNETTE (Warning Light) ===
local vignette = Instance.new("Frame")
vignette.Size = UDim2.fromScale(1,1)
vignette.BackgroundTransparency = 1
vignette.Parent = hudScreen

local vStroke = Instance.new("UIStroke")
vStroke.Thickness = 0
vStroke.Color = THEME.Colors.HealthCrit
vStroke.Transparency = 1
vStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
vStroke.Parent = vignette

-- === ANIMATIONS ===

local function updateHealthVis()
	local pct = math.clamp(currentHealth / maxHealth, 0, 1)

	-- Tween Bar
	TweenService:Create(hpFill, THEME.Anim.Linear, {Size = UDim2.new(pct, 0, 1, 0)}):Play()

	-- Color Logic
	local targetCol = THEME.Colors.HealthGood
	if pct < 0.3 then targetCol = THEME.Colors.HealthCrit
	elseif pct < 0.6 then targetCol = THEME.Colors.HealthLow end

	TweenService:Create(hpFill, THEME.Anim.Linear, {BackgroundColor3 = targetCol}):Play()
	TweenService:Create(hpVal, THEME.Anim.Linear, {TextColor3 = targetCol}):Play()

	-- Text Update
	if localPlayer.Character and localPlayer.Character:FindFirstChild("Knocked") then
		hpVal.Text = "ERR"
	else
		hpVal.Text = string.format("%d%%", math.floor(currentHealth))
	end

	-- Warning Flash
	if pct < 0.3 then
		-- Flash border
		vStroke.Thickness = 50
		TweenService:Create(vStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true), {Transparency = 0.5}):Play()
	else
		TweenService:Create(vStroke, THEME.Anim.Linear, {Transparency = 1}):Play()
	end
end

local function updateShieldVis()
	local pct = math.clamp(currentShield / maxHealth, 0, 1)
	TweenService:Create(shieldBar, THEME.Anim.Linear, {Size = UDim2.new(0.84 * pct, 0, 0, 4)}):Play()
end

local function updateStaminaVis()
	local pct = math.clamp(currentStamina / maxStamina, 0, 1)
	TweenService:Create(stamFill, THEME.Anim.Linear, {Size = UDim2.new(pct, 0, 1, 0)}):Play()

	if mobileBtn then
		if isSprinting then
			TweenService:Create(mobileBtn.Stroke, THEME.Anim.Linear, {Color = THEME.Colors.Stamina}):Play()
			mobileBtn.Icon.ImageColor3 = THEME.Colors.Stamina
		else
			TweenService:Create(mobileBtn.Stroke, THEME.Anim.Linear, {Color = THEME.Colors.Border}):Play()
			mobileBtn.Icon.ImageColor3 = THEME.Colors.TextMain
		end
	end
end

-- === LOGIC (SPRINT & INPUT) ===

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

-- === INIT ===
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

	-- Restore Logic: Client Attribute for other scripts
	localPlayer.Character:SetAttribute("ClientStamina", currentStamina)

	updateStaminaVis()
end)

if localPlayer.Character then onCharacterAdded(localPlayer.Character) end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
