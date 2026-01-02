-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- GameSettingsUI.lua (LocalScript)
-- StarterGui/GameSettingsUI.lua
-- Script Place: Lobby and ACT 1: Village

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local UpdateSettingsEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("UpdateSettingsEvent")
local LoadSettingsEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("LoadSettingsEvent")
local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")

-- ============================================================================
-- 1. CONSTANTS & THEME (Matching UI Master Guide - Cozy Apocalypse)
-- ============================================================================
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel = Color3.fromRGB(35, 28, 22),           -- Warm brown panel
		Accent = Color3.fromRGB(218, 165, 32),        -- Golden (Sunset Orange)
		AccentHover = Color3.fromRGB(255, 200, 80),   -- Bright Yellow
		TextMain = Color3.fromRGB(255, 248, 230),     -- Warm white
		TextDim = Color3.fromRGB(180, 160, 130),      -- Muted gold
		Border = Color3.fromRGB(100, 85, 65),         -- Dark warm border
		Success = Color3.fromRGB(46, 204, 113),       -- Green #2ecc71
		Danger = Color3.fromRGB(231, 76, 60),         -- Red #e74c3c
		Overlay = Color3.new(0, 0, 0)
	},
	Fonts = {
		Display = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.Code
	},
	Sizes = {
		CornerRadius = UDim.new(0, 12),
		Padding = UDim.new(0, 16)
	}
}

local SETTINGS_ICONS = {
	Gameplay = "rbxassetid://101433749620162", -- Gamepad Icon
	Controls = "rbxassetid://125439200583530", -- Keyboard Icon
	Audio = "rbxassetid://132503771043130", -- Speaker Icon
	HUD = "rbxassetid://128958363484246", -- Layer/Layout Icon
	Close = "rbxassetid://7743878857", -- X Icon
	Check = "rbxassetid://7733658504", -- Checkmark
	Gear = "rbxassetid://128019335135588" -- Gear
}

local TARGET_BUTTON_NAMES = {
	"MobileReloadButton", "MobileAimButton", "MobileSprintButton", "HPContainer", "StaminaContainer",
	"AmmoContainer", "TacticalBoostActivatePrompt", "PerkDisplayContainer", "WaveContainer", "ValorContainer", "BossTimerContainer"
}

-- ============================================================================
-- 2. STATE
-- ============================================================================
local currentSettings = {
	sound = { enabled = true, sfxVolume = 0.8, musicVolume = 0.5 },
	controls = { fireControlType = "FireButton" },
	gameplay = { shadows = true, tracers = true },
	hud = {}
}
local temporarySettings = {}
local defaultHudSettings = {} 
local hudElements = {}
local activeEditors = {}
local layoutEditorOriginalVisibility = {}

-- ============================================================================
-- 3. SETUP UI HOLDERS
-- ============================================================================
local screenGui = Instance.new("ScreenGui", playerGui); screenGui.Name = "GameSettingsUI"; screenGui.ResetOnSpawn = false; screenGui.IgnoreGuiInset = false
local screenGui2 = Instance.new("ScreenGui", playerGui); screenGui2.Name = "GameSettingsUI2"; screenGui2.ResetOnSpawn = false; screenGui2.IgnoreGuiInset = false; screenGui2.DisplayOrder = 100; screenGui2.ScreenInsets= Enum.ScreenInsets.TopbarSafeInsets


-- Open Button (Gear) - Using Scale for responsive sizing
local gearBtn = Instance.new("TextButton", screenGui2)
gearBtn.Name = "GameSettingsButton"
gearBtn.AnchorPoint = Vector2.new(0.0, 0.5)
gearBtn.Size = UDim2.fromScale(0.08, 0.05) -- Scale-based
gearBtn.Position = UDim2.fromScale(0.01, 0.5)
gearBtn.BackgroundColor3 = THEME.Colors.Panel
gearBtn.BackgroundTransparency = 0.2
gearBtn.Text = "⚙ SETTINGS"
gearBtn.Font = THEME.Fonts.Display
gearBtn.TextColor3 = THEME.Colors.TextMain
gearBtn.TextScaled = true
gearBtn.ZIndex = 100
Instance.new("UICorner", gearBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", gearBtn).Color = THEME.Colors.Border
Instance.new("UITextSizeConstraint", gearBtn).MaxTextSize = 16

-- Main Panel - Using Scale for responsive sizing
local mainPanel = Instance.new("Frame", screenGui)
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.fromScale(0.85, 0.8) -- Scale-based (85% width, 80% height)
mainPanel.Visible = false
mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
mainPanel.Position = UDim2.fromScale(0.5, 0.5)
mainPanel.BackgroundColor3 = THEME.Colors.Background
mainPanel.BackgroundTransparency = 0.02
mainPanel.BorderSizePixel = 0
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)

local panelStroke = Instance.new("UIStroke", mainPanel)
panelStroke.Color = THEME.Colors.Accent
panelStroke.Transparency = 0.5
panelStroke.Thickness = 2

-- ============================================================================
-- 4. HELPER FUNCTIONS
-- ============================================================================
local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then copy[k] = deepCopy(v)
		elseif typeof(v) == "UDim2" then copy[k] = UDim2.new(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
		else copy[k] = v end
	end
	return copy
end

local AudioManager = {}
AudioManager.CurrentVolume = 0.8 -- Default

function AudioManager:ApplyVolume(sound)
	if sound and sound:IsA("Sound") then
		sound.Volume = self.CurrentVolume
	end
end

function AudioManager:Init()
	self.CurrentVolume = (currentSettings.sound.sfxVolume or 0.8) * (currentSettings.sound.enabled and 1 or 0)

	local function onSoundAdded(descendant)
		if descendant:IsA("Sound") then
			-- Apply volume immediately to new sounds
			-- Use task.defer to allow any initial property setting by the creator script to happen first, then override
			task.defer(function()
				self:ApplyVolume(descendant)
			end)
		end
	end

	game:GetService("SoundService").DescendantAdded:Connect(onSoundAdded)
	workspace.DescendantAdded:Connect(onSoundAdded) -- Catch 3D sounds in Workspace

	-- Initial scan
	task.spawn(function()
		for _, sound in ipairs(game:GetService("SoundService"):GetDescendants()) do
			if sound:IsA("Sound") then self:ApplyVolume(sound) end
		end
		for _, sound in ipairs(workspace:GetDescendants()) do
			if sound:IsA("Sound") then self:ApplyVolume(sound) end
		end
	end)
end
AudioManager:Init()

function AudioManager:UpdateVolumes(settings)
	local globalMult = settings.sound.enabled and 1 or 0
	self.CurrentVolume = (settings.sound.sfxVolume or 0.8) * globalMult

	for _, sound in ipairs(game:GetService("SoundService"):GetDescendants()) do
		if sound:IsA("Sound") then sound.Volume = self.CurrentVolume end
	end
	for _, sound in ipairs(workspace:GetDescendants()) do
		if sound:IsA("Sound") then sound.Volume = self.CurrentVolume end
	end
end

-- UI Component Creators
local function createTabButton(parent, id, text, iconId, isActive)
	local btn = Instance.new("TextButton", parent)
	btn.Name = "Tab_" .. id
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = isActive and THEME.Colors.Accent or Color3.new(1,1,1)
	btn.BackgroundTransparency = isActive and 0 or 1
	btn.AutoButtonColor = false
	btn.Text = ""
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local content = Instance.new("Frame", btn)
	content.Size = UDim2.new(1, 0, 1, 0); content.BackgroundTransparency = 1
	local pad = Instance.new("UIPadding", content); pad.PaddingLeft = UDim.new(0, 15)
	local layout = Instance.new("UIListLayout", content); layout.FillDirection = Enum.FillDirection.Horizontal; layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 12)

	local icon = Instance.new("ImageLabel", content)
	icon.Size = UDim2.new(0, 24, 0, 24)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = isActive and THEME.Colors.TextMain or THEME.Colors.TextDim

	local label = Instance.new("TextLabel", content)
	label.Size = UDim2.new(0, 0, 0, 20)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Font = THEME.Fonts.Body
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = isActive and THEME.Colors.TextMain or THEME.Colors.TextDim
	Instance.new("UITextSizeConstraint", label).MaxTextSize = 16

	-- Hover Effect
	btn.MouseEnter:Connect(function()
		if not btn:GetAttribute("Active") then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.95, BackgroundColor3 = THEME.Colors.TextDim}):Play()
			TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextMain}):Play()
			TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = THEME.Colors.TextMain}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if not btn:GetAttribute("Active") then
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = THEME.Colors.TextDim}):Play()
			TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = THEME.Colors.TextDim}):Play()
		end
	end)

	btn:SetAttribute("Active", isActive)
	return btn, label, icon
end

local function createToggle(parent, title, desc, isOn, callback)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 70)
	container.BackgroundColor3 = THEME.Colors.Panel
	container.BackgroundTransparency = 0.5
	container.BorderSizePixel = 0
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", container).Color = THEME.Colors.Border; Instance.new("UIStroke", container).Transparency = 0.5

	local textContainer = Instance.new("Frame", container)
	textContainer.Size = UDim2.new(0.7, 0, 1, 0)
	textContainer.Position = UDim2.new(0, 16, 0, 0)
	textContainer.BackgroundTransparency = 1

	local titleLbl = Instance.new("TextLabel", textContainer)
	titleLbl.Size = UDim2.new(1, 0, 0.4, 0)
	titleLbl.Position = UDim2.fromScale(0, 0.15)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = THEME.Fonts.Display
	titleLbl.TextScaled = true
	titleLbl.TextColor3 = THEME.Colors.TextMain
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Text = title
	Instance.new("UITextSizeConstraint", titleLbl).MaxTextSize = 18

	local descLbl = Instance.new("TextLabel", textContainer)
	descLbl.Size = UDim2.new(1, 0, 0.3, 0)
	descLbl.Position = UDim2.fromScale(0, 0.55)
	descLbl.BackgroundTransparency = 1
	descLbl.Font = THEME.Fonts.Body
	descLbl.TextScaled = true
	descLbl.TextColor3 = THEME.Colors.TextDim
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.Text = desc
	Instance.new("UITextSizeConstraint", descLbl).MaxTextSize = 14

	-- Toggle Switch
	local switchBtn = Instance.new("TextButton", container)
	switchBtn.Text = ""
	switchBtn.Size = UDim2.new(0, 48, 0, 24)
	switchBtn.AnchorPoint = Vector2.new(1, 0.5)
	switchBtn.Position = UDim2.new(1, -16, 0.5, 0)
	switchBtn.BackgroundColor3 = isOn and THEME.Colors.Accent or THEME.Colors.Border
	Instance.new("UICorner", switchBtn).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", switchBtn)
	knob.Size = UDim2.new(0, 20, 0, 20)
	knob.Position = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	knob.BackgroundColor3 = THEME.Colors.TextMain
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	switchBtn.MouseButton1Click:Connect(function()
		isOn = not isOn
		callback(isOn)
		-- Animate
		TweenService:Create(switchBtn, TweenInfo.new(0.2), {BackgroundColor3 = isOn and THEME.Colors.Accent or THEME.Colors.Border}):Play()
		TweenService:Create(knob, TweenInfo.new(0.2), {Position = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play()
	end)

	return container, function(newState) -- update visual manually
		isOn = newState
		switchBtn.BackgroundColor3 = isOn and THEME.Colors.Accent or THEME.Colors.Border
		knob.Position = isOn and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
	end
end

local function createSlider(parent, title, iconId, value, callback)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 80)
	container.BackgroundColor3 = THEME.Colors.Panel
	container.BackgroundTransparency = 0.5
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
	Instance.new("UIStroke", container).Color = THEME.Colors.Border; Instance.new("UIStroke", container).Transparency = 0.5

	local topBar = Instance.new("Frame", container)
	topBar.Size = UDim2.new(1, -32, 0, 20)
	topBar.Position = UDim2.new(0, 16, 0, 14)
	topBar.BackgroundTransparency = 1

	local icon = Instance.new("ImageLabel", topBar)
	icon.Size = UDim2.new(0, 16, 0, 16)
	icon.Image = iconId or ""
	icon.BackgroundTransparency = 1
	icon.ImageColor3 = THEME.Colors.TextDim

	local titleLbl = Instance.new("TextLabel", topBar)
	titleLbl.Size = UDim2.new(0.7, 0, 1, 0)
	titleLbl.Position = UDim2.new(0, 24, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = THEME.Fonts.Display
	titleLbl.TextScaled = true
	titleLbl.TextColor3 = THEME.Colors.TextMain
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Text = title
	Instance.new("UITextSizeConstraint", titleLbl).MaxTextSize = 16

	local valLbl = Instance.new("TextLabel", topBar)
	valLbl.Size = UDim2.new(0.2, 0, 1, 0)
	valLbl.Position = UDim2.new(0.8, 0, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = THEME.Fonts.Mono
	valLbl.TextScaled = true
	valLbl.TextColor3 = THEME.Colors.Accent
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = math.floor(value * 100) .. "%"
	Instance.new("UITextSizeConstraint", valLbl).MaxTextSize = 16

	local sliderTrack = Instance.new("TextButton", container) -- Button for easy input
	sliderTrack.Text = ""
	sliderTrack.Size = UDim2.new(1, -32, 0, 6)
	sliderTrack.Position = UDim2.new(0, 16, 0, 50)
	sliderTrack.BackgroundColor3 = THEME.Colors.Border
	sliderTrack.AutoButtonColor = false
	Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", sliderTrack)
	fill.Size = UDim2.new(value, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Colors.Accent
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local thumb = Instance.new("Frame", sliderTrack)
	thumb.Size = UDim2.new(0, 16, 0, 16)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(value, 0, 0.5, 0)
	thumb.BackgroundColor3 = THEME.Colors.Accent
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
	local glow = Instance.new("ImageLabel", thumb)
	glow.Size = UDim2.new(2, 0, 2, 0); glow.Position = UDim2.new(-0.5, 0, -0.5, 0); glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://130424513"; glow.ImageColor3 = THEME.Colors.Accent; glow.ImageTransparency = 0.5

	local dragging = false
	local function update(input)
		local pos = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(pos, 0, 1, 0)
		thumb.Position = UDim2.new(pos, 0, 0.5, 0)
		valLbl.Text = math.floor(pos * 100) .. "%"
		callback(pos)
	end

	sliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container, function(newVal) -- Manual update visual
		local p = math.clamp(newVal, 0, 1)
		fill.Size = UDim2.new(p, 0, 1, 0)
		thumb.Position = UDim2.new(p, 0, 0.5, 0)
		valLbl.Text = math.floor(p * 100) .. "%"
	end
end

-- ============================================================================
-- 5. LAYOUT CONSTRUCTION
-- ============================================================================
-- Header
local header = Instance.new("Frame", mainPanel)
header.Size = UDim2.fromScale(1, 0.1)
header.BackgroundColor3 = THEME.Colors.Panel
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
local headerLine = Instance.new("Frame", header); headerLine.Size = UDim2.new(0.98, 0, 0, 2); headerLine.Position = UDim2.new(0.01, 0, 1, -2); headerLine.BackgroundColor3 = THEME.Colors.Accent; headerLine.BorderSizePixel = 0

local titleArea = Instance.new("Frame", header)
titleArea.Size = UDim2.fromScale(0.4, 1); titleArea.BackgroundTransparency = 1; titleArea.Position = UDim2.fromScale(0.02, 0)
local icon = Instance.new("ImageLabel", titleArea); icon.Size = UDim2.fromScale(0.1, 0.5); icon.Position = UDim2.fromScale(0, 0.25); icon.Image = SETTINGS_ICONS.Gear; icon.ImageColor3 = THEME.Colors.Accent; icon.BackgroundTransparency = 1
Instance.new("UIAspectRatioConstraint", icon).AspectRatio = 1
local titleTxt = Instance.new("TextLabel", titleArea)
titleTxt.Text = "⚙ PENGATURAN"; titleTxt.Font = THEME.Fonts.Display; titleTxt.TextScaled = true; titleTxt.TextColor3 = THEME.Colors.Accent; titleTxt.BackgroundTransparency = 1; titleTxt.Size = UDim2.fromScale(0.85, 0.6); titleTxt.Position = UDim2.fromScale(0.12, 0.2); titleTxt.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UITextSizeConstraint", titleTxt).MaxTextSize = 28

local closeBtn = Instance.new("ImageButton", header)
closeBtn.Size = UDim2.fromScale(0.05, 0.5); closeBtn.Position = UDim2.fromScale(0.94, 0.25); closeBtn.BackgroundColor3 = THEME.Colors.Panel; closeBtn.Image = SETTINGS_ICONS.Close; closeBtn.ImageColor3 = THEME.Colors.TextDim
Instance.new("UIAspectRatioConstraint", closeBtn).AspectRatio = 1
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundColor3 = THEME.Colors.Danger; closeBtn.ImageColor3 = THEME.Colors.TextMain end)
closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundColor3 = THEME.Colors.Panel; closeBtn.ImageColor3 = THEME.Colors.TextDim end)

-- Sidebar
local sidebar = Instance.new("Frame", mainPanel)
sidebar.Size = UDim2.fromScale(0.25, 0.78) -- Scale-based
sidebar.Position = UDim2.fromScale(0, 0.1)
sidebar.BackgroundColor3 = THEME.Colors.Panel
sidebar.BackgroundTransparency = 0.5
sidebar.BorderSizePixel = 0
local sidebarBorder = Instance.new("Frame", sidebar); sidebarBorder.Size = UDim2.new(0, 2, 1, 0); sidebarBorder.Position = UDim2.new(1, -2, 0, 0); sidebarBorder.BackgroundColor3 = THEME.Colors.Accent; sidebarBorder.BorderSizePixel = 0

local sidebarList = Instance.new("Frame", sidebar)
sidebarList.Size = UDim2.new(1, -32, 1, -32)
sidebarList.Position = UDim2.new(0, 16, 0, 16)
sidebarList.BackgroundTransparency = 1
local sbLayout = Instance.new("UIListLayout", sidebarList); sbLayout.Padding = UDim.new(0, 8)

-- Content Area
local contentArea = Instance.new("ScrollingFrame", mainPanel)
contentArea.Size = UDim2.fromScale(0.75, 0.78) -- Scale-based
contentArea.Position = UDim2.fromScale(0.25, 0.1)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.ScrollBarThickness = 4
contentArea.ScrollBarImageColor3 = THEME.Colors.Accent

-- Footer
local footer = Instance.new("Frame", mainPanel)
footer.Size = UDim2.fromScale(1, 0.12) -- Scale-based
footer.Position = UDim2.fromScale(0, 0.88)
footer.BackgroundColor3 = THEME.Colors.Panel
footer.BackgroundTransparency = 0.3
footer.BorderSizePixel = 0
Instance.new("UICorner", footer).CornerRadius = UDim.new(0, 12)
local footerLine = Instance.new("Frame", footer); footerLine.Size = UDim2.new(0.98, 0, 0, 2); footerLine.Position = UDim2.new(0.01, 0, 0, 0); footerLine.BackgroundColor3 = THEME.Colors.Accent; footerLine.BorderSizePixel = 0

local footerBtns = Instance.new("Frame", footer)
footerBtns.Size = UDim2.new(1, -48, 1, 0); footerBtns.Position = UDim2.new(0, 24, 0, 0); footerBtns.BackgroundTransparency = 1
local fLayout = Instance.new("UIListLayout", footerBtns); fLayout.FillDirection = Enum.FillDirection.Horizontal; fLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; fLayout.Padding = UDim.new(0, 16); fLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function createFooterBtn(text, isPrimary, callback)
	local btn = Instance.new("TextButton", footerBtns)
	btn.Size = UDim2.fromScale(0.15, 0.6) -- Scale-based
	btn.BackgroundColor3 = isPrimary and THEME.Colors.Success or Color3.new(0,0,0)
	btn.BackgroundTransparency = isPrimary and 0 or 1
	btn.Text = text
	btn.Font = THEME.Fonts.Display
	btn.TextColor3 = isPrimary and THEME.Colors.TextMain or THEME.Colors.TextDim
	btn.TextScaled = true
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	Instance.new("UITextSizeConstraint", btn).MaxTextSize = 16
	if not isPrimary then
		local s = Instance.new("UIStroke", btn); s.Color = THEME.Colors.Border; s.Thickness = 1
	end
	btn.MouseButton1Click:Connect(callback)
end

-- ============================================================================
-- 6. TAB CONTENT GENERATION
-- ============================================================================
local tabs = {}
local tabContents = {}
local currentTab = "Gameplay"

local function switchTab(id)
	currentTab = id
	-- Update Buttons
	for tid, btnData in pairs(tabs) do
		local isActive = (tid == id)
		local btn, label, icon = btnData.btn, btnData.label, btnData.icon
		btn:SetAttribute("Active", isActive)

		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = isActive and 0 or 1, BackgroundColor3 = isActive and THEME.Colors.Accent or Color3.new(1,1,1)}):Play()
		TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = isActive and THEME.Colors.TextMain or THEME.Colors.TextDim}):Play()
		TweenService:Create(icon, TweenInfo.new(0.2), {ImageColor3 = isActive and THEME.Colors.TextMain or THEME.Colors.TextDim}):Play()
	end
	-- Update Content
	contentArea:ClearAllChildren()
	local layout = Instance.new("UIListLayout", contentArea); layout.Padding = UDim.new(0, 16); layout.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", contentArea); pad.PaddingTop = UDim.new(0, 24); pad.PaddingLeft = UDim.new(0, 32); pad.PaddingRight = UDim.new(0, 32); pad.PaddingBottom = UDim.new(0, 24)

	if tabContents[id] then
		tabContents[id]()
	end
end

-- Define Tabs
local function defineTabs()
	-- 1. Gameplay
	tabContents["Gameplay"] = function()
		local header = Instance.new("TextLabel", contentArea)
		header.Text = "Visual & Performance"
		header.Font = THEME.Fonts.Display
		header.TextSize = 20
		header.TextColor3 = THEME.Colors.Accent
		header.Size = UDim2.new(1, 0, 0, 30)
		header.BackgroundTransparency = 1
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.LayoutOrder = 1

		local t1, _ = createToggle(contentArea, "Global Shadows", "Enable realistic shadows. Disable for better performance.", temporarySettings.gameplay.shadows, function(v) temporarySettings.gameplay.shadows = v end)
		t1.LayoutOrder = 2

		local t2, _ = createToggle(contentArea, "Tracer Effects", "Show bullet trails.", temporarySettings.gameplay.tracers, function(v) temporarySettings.gameplay.tracers = v end)
		t2.LayoutOrder = 3
	end

	-- 2. Controls
	tabContents["Controls"] = function()
		local header = Instance.new("TextLabel", contentArea)
		header.Text = "Mobile Controls"
		header.Font = THEME.Fonts.Display; header.TextSize = 20; header.TextColor3 = THEME.Colors.Accent; header.Size = UDim2.new(1, 0, 0, 30); header.BackgroundTransparency = 1; header.TextXAlignment = Enum.TextXAlignment.Left

		local card = Instance.new("Frame", contentArea)
		card.Size = UDim2.new(1, 0, 0, 150)
		card.BackgroundColor3 = THEME.Colors.Panel; card.BackgroundTransparency = 0.5
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		Instance.new("UIStroke", card).Color = THEME.Colors.Border; Instance.new("UIStroke", card).Transparency = 0.5

		local title = Instance.new("TextLabel", card); title.Text = "Fire Mode"; title.Font = THEME.Fonts.Display; title.TextColor3 = THEME.Colors.TextMain; title.Size = UDim2.new(1, -32, 0, 20); title.Position = UDim2.new(0, 16, 0, 16); title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left

		local grid = Instance.new("Frame", card); grid.Size = UDim2.new(1, -32, 0, 80); grid.Position = UDim2.new(0, 16, 0, 50); grid.BackgroundTransparency = 1
		local gl = Instance.new("UIGridLayout", grid); gl.CellSize = UDim2.new(0.48, 0, 1, 0); gl.CellPadding = UDim2.new(0.04, 0, 0, 0)

		local function createModeBtn(name, iconStr, desc, modeKey)
			local btn = Instance.new("TextButton", grid)
			btn.BackgroundColor3 = (temporarySettings.controls.fireControlType == modeKey) and Color3.new(0.03, 0.57, 0.7) or THEME.Colors.Border
			btn.BackgroundTransparency = (temporarySettings.controls.fireControlType == modeKey) and 0.8 or 0.7
			btn.Text = ""
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			local stroke = Instance.new("UIStroke", btn); stroke.Color = (temporarySettings.controls.fireControlType == modeKey) and THEME.Colors.Accent or Color3.new(0,0,0); stroke.Thickness = 2; stroke.Transparency = (temporarySettings.controls.fireControlType == modeKey) and 0 or 1

			local i = Instance.new("ImageLabel", btn); i.Image = iconStr; i.Size = UDim2.new(0, 32, 0, 32); i.Position = UDim2.new(0.5, -16, 0, 10); i.BackgroundTransparency = 1; i.ImageColor3 = (temporarySettings.controls.fireControlType == modeKey) and THEME.Colors.Accent or THEME.Colors.TextDim
			local t = Instance.new("TextLabel", btn); t.Text = name; t.Position = UDim2.new(0,0,0,45); t.Size = UDim2.new(1,0,0,20); t.BackgroundTransparency = 1; t.Font = THEME.Fonts.Display; t.TextColor3 = THEME.Colors.TextMain
			local d = Instance.new("TextLabel", btn); d.Text = desc; d.Position = UDim2.new(0,0,0,65); d.Size = UDim2.new(1,0,0,15); d.BackgroundTransparency = 1; d.Font = THEME.Fonts.Body; d.TextColor3 = THEME.Colors.TextDim; d.TextSize = 10

			btn.MouseButton1Click:Connect(function()
				temporarySettings.controls.fireControlType = modeKey
				switchTab("Controls") -- Refresh
			end)
		end

		createModeBtn("Dedicated Button", "rbxassetid://130160602597512", "Tombol tembak khusus", "FireButton")
		createModeBtn("Double Tap", "rbxassetid://113293314787010", "Ketuk layar 2x", "DoubleTap")
	end

	-- 3. Audio
	tabContents["Audio"] = function()
		local header = Instance.new("TextLabel", contentArea)
		header.Text = "Volume Settings"
		header.Font = THEME.Fonts.Display; header.TextSize = 20; header.TextColor3 = THEME.Colors.Accent; header.Size = UDim2.new(1, 0, 0, 30); header.BackgroundTransparency = 1; header.TextXAlignment = Enum.TextXAlignment.Left; header.LayoutOrder = 1

		local s1, _ = createSlider(contentArea, "Sound Effects (SFX)", SETTINGS_ICONS.Audio, temporarySettings.sound.sfxVolume, function(v) temporarySettings.sound.sfxVolume = v end)
		s1.LayoutOrder = 2
	end

	-- 4. HUD
	tabContents["HUD"] = function()
		local header = Instance.new("TextLabel", contentArea)
		header.Text = "Interface Layout"
		header.Font = THEME.Fonts.Display; header.TextSize = 20; header.TextColor3 = THEME.Colors.Accent; header.Size = UDim2.new(1, 0, 0, 30); header.BackgroundTransparency = 1; header.TextXAlignment = Enum.TextXAlignment.Left; header.LayoutOrder = 1

		local card = Instance.new("Frame", contentArea)
		card.Size = UDim2.new(1, 0, 0, 200)
		card.BackgroundColor3 = THEME.Colors.Panel; card.BackgroundTransparency = 0.5
		card.LayoutOrder = 2
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		Instance.new("UIStroke", card).Color = THEME.Colors.Border; Instance.new("UIStroke", card).Transparency = 0.5

		local icon = Instance.new("ImageLabel", card); icon.Image = SETTINGS_ICONS.HUD; icon.Size = UDim2.new(0, 64, 0, 64); icon.AnchorPoint = Vector2.new(0.5, 0); icon.Position = UDim2.new(0.5, 0, 0, 20); icon.BackgroundTransparency = 1; icon.ImageColor3 = THEME.Colors.Accent
		local title = Instance.new("TextLabel", card); title.Text = "Custom HUD Layout"; title.Font = THEME.Fonts.Display; title.TextSize = 20; title.TextColor3 = THEME.Colors.TextMain; title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 90); title.BackgroundTransparency = 1
		local desc = Instance.new("TextLabel", card); desc.Text = "Ubah posisi dan ukuran tombol kontrol, health bar, dan elemen lainnya."; desc.Font = THEME.Fonts.Body; desc.TextSize = 14; desc.TextColor3 = THEME.Colors.TextDim; desc.Size = UDim2.new(0.8, 0, 0, 40); desc.Position = UDim2.new(0.1, 0, 0, 120); desc.BackgroundTransparency = 1; desc.TextWrapped = true

		local btn = Instance.new("TextButton", card)
		btn.Text = "EDIT LAYOUT"
		btn.Font = THEME.Fonts.Display
		btn.TextSize = 16
		btn.TextColor3 = THEME.Colors.TextMain
		btn.BackgroundColor3 = THEME.Colors.Accent
		btn.Size = UDim2.new(0, 150, 0, 40)
		btn.AnchorPoint = Vector2.new(0.5, 0)
		btn.Position = UDim2.new(0.5, 0, 1, -50)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		btn.MouseButton1Click:Connect(function()
			setSettingsMode(false) -- Hide main panel
			setLayoutEditorMode(true)
		end)
	end

	-- Init Sidebar Buttons
	local function addTab(id, text, icon)
		local btn, label, iconObj = createTabButton(sidebarList, id, text, icon, false)
		tabs[id] = { btn = btn, label = label, icon = iconObj }
		btn.MouseButton1Click:Connect(function() switchTab(id) end)
	end

	addTab("Gameplay", "Gameplay", SETTINGS_ICONS.Gameplay)
	if UserInputService.TouchEnabled then
		addTab("Controls", "Controls", SETTINGS_ICONS.Controls)
	end
	addTab("Audio", "Audio", SETTINGS_ICONS.Audio)
	addTab("HUD", "Interface / HUD", SETTINGS_ICONS.HUD)
end

createFooterBtn("BATAL", false, function() 
	applySettings(currentSettings) -- Revert
	setSettingsMode(false)
end)

createFooterBtn("SIMPAN", true, function()
	currentSettings = deepCopy(temporarySettings)
	UpdateSettingsEvent:FireServer(currentSettings)
	applySettings(currentSettings)
	setSettingsMode(false)
	-- Show Toast (Simplified)
	local toast = Instance.new("Frame", screenGui)
	toast.Size = UDim2.new(0, 200, 0, 50); toast.Position = UDim2.new(1, 20, 0, 80); toast.BackgroundColor3 = THEME.Colors.Success
	Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
	local t = Instance.new("TextLabel", toast); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.Text = "Settings Saved!"; t.TextColor3 = Color3.new(1,1,1); t.Font = THEME.Fonts.Display
	TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Position = UDim2.new(1, -220, 0, 80)}):Play()
	task.delay(2, function() 
		TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 20, 0, 80)}):Play() 
		task.wait(0.5) toast:Destroy()
	end)
end)

closeBtn.MouseButton1Click:Connect(function() setSettingsMode(false) end)

-- ============================================================================
-- 7. LAYOUT EDITOR OVERLAY
-- ============================================================================
local leOverlay = Instance.new("Frame", screenGui)
leOverlay.Name = "LayoutEditor"
leOverlay.BackgroundColor3 = Color3.new(0,0,0)
leOverlay.BackgroundTransparency = 0.3
leOverlay.Size = UDim2.new(1, 0, 1, 0)
leOverlay.Visible = false
leOverlay.ZIndex = 200

-- Grid Background
local gridImg = Instance.new("ImageLabel", leOverlay)
gridImg.Size = UDim2.new(1, 0, 1, 0)
gridImg.BackgroundTransparency = 1
gridImg.Image = "rbxassetid://6444531044" -- Grid pattern
gridImg.ImageTransparency = 0.8
gridImg.ScaleType = Enum.ScaleType.Tile
gridImg.TileSize = UDim2.new(0, 40, 0, 40)

local leControls = Instance.new("Frame", leOverlay)
leControls.Size = UDim2.new(0, 400, 0, 60)
leControls.AnchorPoint = Vector2.new(0.5, 1)
leControls.Position = UDim2.new(0.5, 0, 1, -40)
leControls.BackgroundColor3 = THEME.Colors.Background
leControls.BackgroundTransparency = 0.1
Instance.new("UICorner", leControls).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", leControls).Color = THEME.Colors.Border

local leList = Instance.new("UIListLayout", leControls); leList.FillDirection = Enum.FillDirection.Horizontal; leList.HorizontalAlignment = Enum.HorizontalAlignment.Center; leList.VerticalAlignment = Enum.VerticalAlignment.Center; leList.Padding = UDim.new(0, 10)

local function createLeBtn(text, color, callback)
	local btn = Instance.new("TextButton", leControls)
	btn.Size = UDim2.new(0, 100, 0, 36)
	btn.BackgroundColor3 = color
	btn.Text = text
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = THEME.Fonts.Display
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(callback)
end

createLeBtn("RESET", THEME.Colors.Danger, function()
	for name, element in pairs(hudElements) do
		if defaultHudSettings[name] then
			element.Position = defaultHudSettings[name].pos
			element.Size = defaultHudSettings[name].size
		end
	end
end)

createLeBtn("BATAL", THEME.Colors.Border, function()
	for name, element in pairs(hudElements) do
		if temporarySettings.hud[name] then
			element.Position = temporarySettings.hud[name].pos
			element.Size = temporarySettings.hud[name].size
		end
	end
	setLayoutEditorMode(false)
	setSettingsMode(true, false) -- Kembali ke menu, jangan simpan perubahan layout ke temp
end)

createLeBtn("SIMPAN", THEME.Colors.Success, function()
	for name, element in pairs(hudElements) do
		temporarySettings.hud[name] = { pos = element.Position, size = element.Size }
	end
	setLayoutEditorMode(false)
	setSettingsMode(true, true) -- Kembali ke menu, simpan perubahan layout di temp
end)

-- ============================================================================
-- 8. LOGIC IMPLEMENTATION
-- ============================================================================
function setSettingsMode(enabled, preserveTemp)
	mainPanel.Visible = enabled
	gearBtn.Visible = not enabled

	if enabled then
		-- Jika preserveTemp true, jangan overwrite temporarySettings dengan currentSettings.
		-- Ini berguna saat kembali dari Layout Editor agar perubahan yang belum disave (ke server) tidak hilang.
		if not preserveTemp then
			temporarySettings = deepCopy(currentSettings)
		end

		switchTab(currentTab) -- Refresh current tab
		-- Animation
		mainPanel.Position = UDim2.new(0.5, 0, 0.5, 10)
		mainPanel.BackgroundTransparency = 1
		TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0.05}):Play()
	end
end

function makeDraggable(frame)
	local dragging, dragStart, startPos, conn
	frame.InputBegan:Connect(function(input)
		if frame:GetAttribute("IsResizing") then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = Vector2.new(input.Position.X, input.Position.Y); startPos = frame.Position
			conn = UserInputService.InputChanged:Connect(function(cInput)
				if dragging and (cInput.UserInputType == Enum.UserInputType.MouseMovement or cInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = Vector2.new(cInput.Position.X, cInput.Position.Y) - dragStart
					frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end)
		end
	end)
	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false; if conn then conn:Disconnect() end
		end
	end)
end

function makeResizable(frame)
	local handle = Instance.new("Frame", frame); handle.Name = "ResizeHandle"; handle.AnchorPoint = Vector2.new(1, 1); handle.Size = UDim2.new(0, 16, 0, 16); handle.Position = UDim2.new(1, 4, 1, 4); handle.BackgroundColor3 = THEME.Colors.Accent; handle.ZIndex = frame.ZIndex + 2; Instance.new("UICorner", handle).CornerRadius = UDim.new(0, 4)
	local resizing, startSize, startInputPos, conn
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true; frame:SetAttribute("IsResizing", true); startInputPos = Vector2.new(input.Position.X, input.Position.Y); startSize = frame.Size
			conn = UserInputService.InputChanged:Connect(function(cInput)
				if resizing and (cInput.UserInputType == Enum.UserInputType.MouseMovement or cInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = Vector2.new(cInput.Position.X, cInput.Position.Y) - startInputPos
					frame.Size = UDim2.new(startSize.X.Scale, startSize.X.Offset + delta.X, startSize.Y.Scale, startSize.Y.Offset + delta.Y)
				end
			end)
		end
	end)
	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false; frame:SetAttribute("IsResizing", false); if conn then conn:Disconnect() end
		end
	end)
	return handle
end

function setLayoutEditorMode(enabled)
	leOverlay.Visible = enabled
	if enabled then layoutEditorOriginalVisibility = {} end

	for name, element in pairs(hudElements) do
		if enabled then
			layoutEditorOriginalVisibility[name] = element.Visible
			element.Visible = true

			local ghost = Instance.new("Frame", element)
			ghost.Name = "EditGhost"
			ghost.BackgroundTransparency = 0.8
			ghost.BackgroundColor3 = THEME.Colors.Accent
			ghost.Size = UDim2.new(1,0,1,0)
			ghost.ZIndex = element.ZIndex + 1

			local stroke = Instance.new("UIStroke", ghost)
			stroke.Thickness = 2
			stroke.Color = THEME.Colors.Accent
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			makeDraggable(element)
			local handle = makeResizable(element)
			activeEditors[name] = { ghost = ghost, handle = handle }
		else
			if activeEditors[name] then
				activeEditors[name].ghost:Destroy()
				activeEditors[name].handle:Destroy()
				activeEditors[name] = nil
			end
			if layoutEditorOriginalVisibility[name] ~= nil then
				element.Visible = layoutEditorOriginalVisibility[name]
			end
		end
	end
end

function applySettings(settings)
	local sound = settings.sound
	local controls = settings.controls
	local gameplay = settings.gameplay

	-- Gameplay
	if gameplay then
		if gameplay.shadows ~= nil then game.Lighting.GlobalShadows = gameplay.shadows end
		-- Tracers stored in settings, used by TracerClient
		if gameplay.tracers ~= nil then
			player:SetAttribute("ShowTracers", gameplay.tracers)
		end
	end

	-- Audio
	AudioManager:UpdateVolumes(settings)

	-- Controls
	if controls then
		player:SetAttribute("FireControlType", controls.fireControlType)
	end

	-- HUD
	if settings.hud then
		for name, hudSetting in pairs(settings.hud) do
			local element = hudElements[name]
			if element and hudSetting and hudSetting.pos and hudSetting.size then
				element.Position = hudSetting.pos
				element.Size = hudSetting.size
			end
		end
	end

	local refreshMobileButtonsEvent = BindableEvents:FindFirstChild("RefreshMobileButtons")
	if refreshMobileButtonsEvent then refreshMobileButtonsEvent:Fire() end
end

local function initializeHudDefaults()
	for _, name in ipairs(TARGET_BUTTON_NAMES) do
		local element = playerGui:FindFirstChild(name, true)
		if element then
			hudElements[name] = element
			if not defaultHudSettings[name] then
				defaultHudSettings[name] = { pos = element.Position, size = element.Size }
			end
			if not currentSettings.hud[name] then
				currentSettings.hud[name] = { pos = element.Position, size = element.Size }
			end
		end
	end
end

-- ============================================================================
-- 9. EVENTS
-- ============================================================================
gearBtn.MouseButton1Click:Connect(function() setSettingsMode(true) end)

LoadSettingsEvent.OnClientEvent:Connect(function(serverSettings)
	initializeHudDefaults()
	-- Merge settings safely
	if serverSettings then
		if serverSettings.sound then for k,v in pairs(serverSettings.sound) do currentSettings.sound[k] = v end end
		if serverSettings.controls then currentSettings.controls = serverSettings.controls end
		if serverSettings.gameplay then currentSettings.gameplay = serverSettings.gameplay end
		if serverSettings.hud then
			for name, data in pairs(serverSettings.hud) do
				if currentSettings.hud[name] then
					currentSettings.hud[name].pos = data.pos
					currentSettings.hud[name].size = data.size
				end
			end
		end
	end
	applySettings(currentSettings)
end)

-- ============================================================================
-- 10. INITIALIZATION
-- ============================================================================
defineTabs()
task.spawn(function()
	task.wait(2)
	initializeHudDefaults()
	applySettings(currentSettings)
end)