-- PerkDisplayUI.lua (LocalScript)
-- Path: StarterGui/PerkDisplayUI.lua
-- Script Place: ACT 1: Village & Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local PerkConfig = {
	HPPlus = {
		Name = "IRON WILL",
		Description = "Strong will increases Max Health by 30%.",
		Color = Color3.fromRGB(139, 90, 43), -- Warm Brown
		Icon = "❤️" 
	},
	StaminaPlus = {
		Name = "SECOND WIND",
		Description = "Second wind increases Max Stamina by 30%.",
		Color = Color3.fromRGB(234, 179, 8), -- Golden Yellow
		Icon = "🏃"
	},
	ReloadPlus = {
		Name = "DEXTERITY",
		Description = "Trained hands Reload 30% faster.",
		Color = Color3.fromRGB(34, 139, 34), -- Forest Green
		Icon = "✋"
	},
	RevivePlus = {
		Name = "HUMANITY",
		Description = "Sense of humanity speeds up Ally Revive by 50%.",
		Color = Color3.fromRGB(64, 224, 208), -- Turquoise
		Icon = "🤝"
	},
	RateBoost = {
		Name = "ADRENALINE",
		Description = "Adrenaline boosts Fire Rate by 30%.",
		Color = Color3.fromRGB(255, 140, 0), -- Sunset Orange
		Icon = "🔥"
	},
	Medic = {
		Name = "FIELD MEDIC",
		Description = "First aid grants 30% HP upon revive.",
		Color = Color3.fromRGB(50, 205, 50), -- Lime Green
		Icon = "💚"
	},

	Default = {
		Name = "UNKNOWN PERK",
		Description = "This perk has not been identified.",
		Color = Color3.fromRGB(148, 163, 184), -- Slate-400
		Icon = "❓"
	}
}

-- ============================================================================
-- UI SETUP
-- ============================================================================

local existingGui = gui:FindFirstChild("PerkDisplayUI")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PerkDisplayUI"
screenGui.ResetOnSpawn = true
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gui

local container = Instance.new("Frame")
container.Name = "PerkContainer"
container.Size = UDim2.new(0.05, 0, 0.5, 0) -- Scale height
container.Position = UDim2.new(0, 24, 0.5, 0)
container.AnchorPoint = Vector2.new(0, 0.5)
container.BackgroundTransparency = 1
container.Parent = screenGui

-- Aspect Ratio for container items could be enforced if needed
-- For now we rely on UIListLayout stacking them.

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 12)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Parent = container

local activePerkFrames = {}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function GetConfig(perkName)
	return PerkConfig[perkName] or PerkConfig.Default
end

local function CreateTooltip(parent, config)
	-- Tooltip Container
	local tooltip = Instance.new("Frame")
	tooltip.Name = "Tooltip"
	tooltip.Size = UDim2.new(0, 220, 0, 0) -- Height automatic
	tooltip.AutomaticSize = Enum.AutomaticSize.Y
	tooltip.Position = UDim2.new(1, 16, 0.5, 0) -- To the right
	tooltip.AnchorPoint = Vector2.new(0, 0.5)
	tooltip.BackgroundColor3 = Color3.fromRGB(30, 41, 59) -- Slate-800 (matches CSS bg-slate-800)
	tooltip.BorderSizePixel = 0
	tooltip.Visible = false
	tooltip.ZIndex = 20
	tooltip.Parent = parent

	-- Border Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(71, 85, 105) -- Slate-600
	stroke.Thickness = 1
	stroke.Parent = tooltip

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = tooltip

	-- Padding
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = tooltip

	-- List Layout for Text
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = tooltip

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = config.Name
	title.Font = Enum.Font.GothamBold -- Uppercase bold
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 18)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = tooltip

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Name = "Description"
	desc.Text = config.Description
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 12
	desc.TextColor3 = Color3.fromRGB(148, 163, 184) -- Slate-400
	desc.BackgroundTransparency = 1
	desc.Size = UDim2.new(1, 0, 0, 0)
	desc.AutomaticSize = Enum.AutomaticSize.Y
	desc.TextWrapped = true
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.LayoutOrder = 2
	desc.Parent = tooltip

	-- Gradient Line
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.Size = UDim2.new(1, 0, 0, 2)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BorderSizePixel = 0
	line.LayoutOrder = 4 -- After spacer
	line.Parent = tooltip

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, config.Color),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 41, 59)) -- Fade to BG color
	})
	grad.Parent = line

	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1,0,0,4)
	spacer.BackgroundTransparency = 1
	spacer.LayoutOrder = 3
	spacer.Parent = tooltip

	return tooltip
end

local function CreatePerkEntry(perkName)
	local config = GetConfig(perkName)

	-- 1. The Card Frame
	local frame = Instance.new("Frame")
	frame.Name = "Perk_" .. perkName
	-- Use Scale for size. Assuming the container handles layout, we want it to be wide and some height.
	-- Actually, since container width is 0.05 (5% screen width), we can use Scale 1, and AspectRatio.
	frame.Size = UDim2.new(1, 0, 0.6, 0) -- This might be too relative. Let's use specific scale relative to height.
	-- Better approach: Size relative to screen height? No, container.
	-- Let's stick to a Scale size.
	frame.Size = UDim2.new(1.2, 0, 0.08, 0) -- Wider than container, 8% screen height approx
	
	-- Constraint to keep it pill shaped not stretched weirdly
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1.6 -- 64/40 = 1.6
	aspect.Parent = frame
	frame.BackgroundColor3 = Color3.fromRGB(15, 23, 42) -- Slate-900
	frame.BackgroundTransparency = 0.4 -- Glass feel
	frame.BorderSizePixel = 0
	-- Rounded Right corners mainly
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8) 
	corner.Parent = frame

	-- 2. Subtle Global Border (White/Slate, low opacity)
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 255, 255)
	border.Transparency = 0.9
	border.Thickness = 1
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = frame

	-- 3. Left Accent Bar (The "Glow" indicator)
	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 3, 1, -8) -- 3px wide, slightly padded vertically? CSS says border-left.
	-- Actually CSS says: border-left: 3px solid [color].
	-- To mimic border-left on a rounded object in Roblox, we place a Frame on the left.
	accent.Size = UDim2.new(0, 3, 1, 0)
	accent.Position = UDim2.new(0, 0, 0, 0)
	accent.BackgroundColor3 = config.Color
	accent.BorderSizePixel = 0
	accent.ZIndex = 2
	accent.Parent = frame

	-- Fix accent rounding: We want it to follow the left corners.
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accent

	-- Cover the right side of the accent so it looks like a straight line? 
	-- No, let's just leave it rounded, it looks like a pill cap.

	-- 4. Inner Glow (Box Shadow) - REMOVED per user request
	-- local glow = Instance.new("ImageLabel")
	-- glow.Name = "Glow"
	-- ...

	-- 5. Icon (Centered)
	local iconContainer = Instance.new("Frame")
	iconContainer.Size = UDim2.new(1, 0, 1, 0)
	iconContainer.BackgroundTransparency = 1
	iconContainer.ZIndex = 5
	iconContainer.Parent = frame

	local icon = Instance.new("TextLabel")
	icon.Text = config.Icon
	icon.Font = Enum.Font.Gotham
	icon.TextScaled = true -- Rule compliant
	icon.Size = UDim2.new(0.8, 0, 0.8, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = Color3.fromRGB(255, 255, 255) -- Icon itself is colored in CSS? 
	-- CSS: text-red-400.
	icon.TextColor3 = config.Color -- Use the perk color for the icon
	-- Add drop shadow to icon
	local textStroke = Instance.new("UIStroke")
	textStroke.Thickness = 1.5 -- Subtle outline
	textStroke.Color = config.Color
	textStroke.Transparency = 0.8
	textStroke.Parent = icon
	icon.Parent = iconContainer

	-- Tooltip
	local tooltip = CreateTooltip(frame, config)

	-- Float Animation
	local floatTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local floatTween = TweenService:Create(iconContainer, floatTweenInfo, {Position = UDim2.new(0, 0, 0, -2)})
	floatTween:Play()

	-- Hover Logic
	frame.MouseEnter:Connect(function()
		tooltip.Visible = true
		tooltip.BackgroundTransparency = 1
		for _, c in pairs(tooltip:GetDescendants()) do
			if c:IsA("TextLabel") then c.TextTransparency = 1 end
			if c:IsA("UIStroke") then c.Transparency = 1 end
			-- Line
			if c:IsA("Frame") and c.Name == "Line" then c.BackgroundTransparency = 1 end
		end

		-- Fade In
		local tInfo = TweenInfo.new(0.2)
		TweenService:Create(tooltip, tInfo, {BackgroundTransparency = 0}):Play()
		for _, c in pairs(tooltip:GetDescendants()) do
			if c:IsA("TextLabel") then TweenService:Create(c, tInfo, {TextTransparency = 0}):Play() end
			if c:IsA("UIStroke") then TweenService:Create(c, tInfo, {Transparency = 0}):Play() end
			if c:IsA("Frame") and c.Name == "Line" then TweenService:Create(c, tInfo, {BackgroundTransparency = 0}):Play() end
		end

		-- Card Expand/Bounce
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 70, 0, 40)}):Play()
	end)

	frame.MouseLeave:Connect(function()
		tooltip.Visible = false -- Snap off or fade out? Snap off for responsiveness is fine, or quick fade
		-- Card Reset
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 64, 0, 40)}):Play()
	end)

	-- Entry Animation
	frame.Position = UDim2.new(0, -30, 0, 0)
	frame.BackgroundTransparency = 1
	icon.TextTransparency = 1
	accent.BackgroundTransparency = 1

	local entryInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(frame, entryInfo, {BackgroundTransparency = 0.4}):Play()
	TweenService:Create(icon, entryInfo, {TextTransparency = 0}):Play()
	TweenService:Create(accent, entryInfo, {BackgroundTransparency = 0}):Play()

	return frame
end

local function UpdatePerks(perkList)
	local currentPerks = {}
	for name, _ in pairs(activePerkFrames) do
		currentPerks[name] = false
	end

	for _, perkName in ipairs(perkList) do
		if activePerkFrames[perkName] then
			currentPerks[perkName] = true
		else
			local newFrame = CreatePerkEntry(perkName)
			newFrame.Parent = container
			activePerkFrames[perkName] = newFrame
			currentPerks[perkName] = true
		end
	end

	for name, kept in pairs(currentPerks) do
		if not kept then
			local frame = activePerkFrames[name]
			if frame then
				TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				task.delay(0.3, function() frame:Destroy() end)
			end
			activePerkFrames[name] = nil
		end
	end
end

perkUpdateEv.OnClientEvent:Connect(function(perks)
	UpdatePerks(perks or {})
end)

UpdatePerks({})
