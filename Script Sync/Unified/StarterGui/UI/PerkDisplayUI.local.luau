-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- PerkDisplayUI.lua (LocalScript)
-- Path: StarterGui/PerkDisplayUI.lua
-- Script Place: ACT 1: Village & Lobby
-- Theme: Survivor Camp (Vibrant Scavenger - Fortnite/Overwatch Style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local perkUpdateEv = RemoteEvents:WaitForChild("PerkUpdate")

-- ============================================================================
-- THEME: VIBRANT SCAVENGER (Fortnite/Overwatch Style)
-- ============================================================================

local THEME = {
	-- Primary Materials
	WOOD_DARK = Color3.fromRGB(101, 67, 33),     -- Dark Wood Plank
	WOOD_LIGHT = Color3.fromRGB(160, 120, 80),   -- Light Wood
	CANVAS = Color3.fromRGB(205, 190, 160),      -- Beige Canvas/Tape
	METAL = Color3.fromRGB(120, 120, 130),       -- Clean Metal Plate

	-- Accent Colors (Vibrant)
	ACCENT_ORANGE = Color3.fromRGB(255, 140, 0),  -- Sunset Orange
	ACCENT_YELLOW = Color3.fromRGB(255, 200, 50), -- Caution Tape Yellow
	ACCENT_GREEN = Color3.fromRGB(100, 200, 80),  -- Lime Green
	ACCENT_RED = Color3.fromRGB(230, 80, 80),     -- Vibrant Red
	ACCENT_CYAN = Color3.fromRGB(80, 200, 220),   -- Turquoise

	-- Text
	TEXT_DARK = Color3.fromRGB(50, 40, 30),       -- Ink Brown
	TEXT_LIGHT = Color3.fromRGB(255, 255, 255),   -- Pure White

	-- Fonts (Rule Compliant)
	FONT_HEAVY = Enum.Font.FredokaOne,            -- Chunky Cartoony
	FONT_BODY = Enum.Font.GothamBold,             -- Clean Bold
}

-- ============================================================================
-- PERK CONFIGURATION
-- ============================================================================

local PerkConfig = {
	HPPlus = {
		Name = "IRON WILL",
		Description = "Strong will increases Max Health by 30%.",
		Color = THEME.ACCENT_RED,
		Icon = "❤️",
		Material = "wood"
	},
	StaminaPlus = {
		Name = "SECOND WIND",
		Description = "Second wind increases Max Stamina by 30%.",
		Color = THEME.ACCENT_YELLOW,
		Icon = "🏃",
		Material = "metal"
	},
	ReloadPlus = {
		Name = "DEXTERITY",
		Description = "Trained hands Reload 30% faster.",
		Color = THEME.ACCENT_GREEN,
		Icon = "✋",
		Material = "canvas"
	},
	RevivePlus = {
		Name = "HUMANITY",
		Description = "Sense of humanity speeds up Ally Revive by 50%.",
		Color = THEME.ACCENT_CYAN,
		Icon = "🤝",
		Material = "wood"
	},
	RateBoost = {
		Name = "ADRENALINE",
		Description = "Adrenaline boosts Fire Rate by 30%.",
		Color = THEME.ACCENT_ORANGE,
		Icon = "🔥",
		Material = "metal"
	},
	Medic = {
		Name = "FIELD MEDIC",
		Description = "First aid grants 30% HP upon revive.",
		Color = THEME.ACCENT_GREEN,
		Icon = "💚",
		Material = "canvas"
	},
	Default = {
		Name = "UNKNOWN",
		Description = "This perk has not been identified.",
		Color = THEME.METAL,
		Icon = "❓",
		Material = "metal"
	}
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		instance[k] = v
	end
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0,0,0)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addTextConstraint(parent, minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize or 10
	constraint.MaxTextSize = maxSize or 24
	constraint.Parent = parent
	return constraint
end

local function GetConfig(perkName)
	return PerkConfig[perkName] or PerkConfig.Default
end

local function GetMaterialColor(material)
	if material == "wood" then
		return THEME.WOOD_DARK
	elseif material == "canvas" then
		return THEME.CANVAS
	elseif material == "metal" then
		return THEME.METAL
	end
	return THEME.WOOD_DARK
end

-- ============================================================================
-- UI SETUP
-- ============================================================================

local existingGui = gui:FindFirstChild("PerkDisplayUI")
if existingGui then existingGui:Destroy() end

local screenGui = create("ScreenGui", {
	Name = "PerkDisplayUI",
	ResetOnSpawn = true,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = gui
})

-- Mobile Detection
local isMobile = UserInputService.TouchEnabled

-- Container (Left Side)
local container = create("Frame", {
	Name = "fr_PerkContainer",
	Size = UDim2.new(0.08, 0, 0.4, 0), -- Scale: 8% width, 40% height
	Position = UDim2.new(0.01, 0, 0.5, 0), -- 1% from left, centered vertically
	AnchorPoint = Vector2.new(0, 0.5),
	BackgroundTransparency = 1,
	Parent = screenGui
})

local listLayout = create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0.05, 0), -- Scale padding
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Parent = container
})

local activePerkFrames = {}

-- ============================================================================
-- CREATE PERK ENTRY (Vibrant Scavenger Style)
-- ============================================================================

local function CreateTooltip(parent, config)
	-- Tooltip (Wooden Sign Style)
	local tooltip = create("Frame", {
		Name = "Tooltip",
		Size = UDim2.new(0, 200, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = THEME.WOOD_LIGHT,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 50,
		Parent = parent
	})
	addCorner(tooltip, 8)
	addStroke(tooltip, THEME.WOOD_DARK, 3)

	-- Padding
	create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = tooltip
	})

	-- Layout
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = tooltip
	})

	-- Title
	local title = create("TextLabel", {
		Name = "lbl_Title",
		Text = config.Name,
		Font = THEME.FONT_HEAVY,
		TextScaled = true,
		TextColor3 = THEME.TEXT_DARK,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = 51,
		Parent = tooltip
	})
	addTextConstraint(title, 12, 20)

	-- Accent Line
	local line = create("Frame", {
		Name = "AccentLine",
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = config.Color,
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ZIndex = 51,
		Parent = tooltip
	})
	addCorner(line, 2)

	-- Description
	local desc = create("TextLabel", {
		Name = "lbl_Desc",
		Text = config.Description,
		Font = THEME.FONT_BODY,
		TextScaled = true,
		TextColor3 = THEME.TEXT_DARK,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
		ZIndex = 51,
		Parent = tooltip
	})
	addTextConstraint(desc, 10, 14)

	return tooltip
end

local function CreatePerkEntry(perkName)
	local config = GetConfig(perkName)
	local materialColor = GetMaterialColor(config.Material)

	-- Card Frame (Chunky Rounded)
	local frame = create("Frame", {
		Name = "Perk_" .. perkName,
		Size = UDim2.new(1, 0, 0.2, 0), -- 20% of container height
		BackgroundColor3 = materialColor,
		BorderSizePixel = 0,
		ZIndex = 10
	})
	addCorner(frame, 12) -- Chunky rounded
	addStroke(frame, THEME.WOOD_DARK, 3)

	-- Aspect Ratio to keep it square-ish
	local aspect = create("UIAspectRatioConstraint", {
		AspectRatio = 1.2, -- Slightly wider than tall
		Parent = frame
	})

	-- Accent Bar (Left Side - Colored Stripe)
	local accent = create("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(0.08, 0, 0.8, 0), -- 8% width, 80% height
		Position = UDim2.new(0.05, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = config.Color,
		BorderSizePixel = 0,
		ZIndex = 11,
		Parent = frame
	})
	addCorner(accent, 4)

	-- Icon Container
	local iconContainer = create("Frame", {
		Name = "IconContainer",
		Size = UDim2.new(0.7, 0, 0.8, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 12,
		Parent = frame
	})

	-- Icon (Emoji - Centered)
	local icon = create("TextLabel", {
		Name = "lbl_Icon",
		Text = config.Icon,
		Font = Enum.Font.Gotham,
		TextScaled = true,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		TextColor3 = THEME.TEXT_LIGHT,
		ZIndex = 13,
		Parent = iconContainer
	})

	-- Tooltip
	local tooltip = CreateTooltip(frame, config)

	-- =========================================
	-- ANIMATIONS
	-- =========================================

	-- Float Animation (Gentle Up-Down)
	local floatTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local floatTween = TweenService:Create(iconContainer, floatTweenInfo, {
		Position = UDim2.new(0.5, 0, 0.45, 0) -- Slight up
	})
	floatTween:Play()

	-- Hover Logic
	frame.MouseEnter:Connect(function()
		tooltip.Visible = true
		-- Scale Up
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Size = UDim2.new(1.1, 0, 0.22, 0)
		}):Play()
		-- Brighten Accent
		TweenService:Create(accent, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.new(
				math.min(config.Color.R * 1.3, 1),
				math.min(config.Color.G * 1.3, 1),
				math.min(config.Color.B * 1.3, 1)
			)
		}):Play()
	end)

	frame.MouseLeave:Connect(function()
		tooltip.Visible = false
		-- Scale Back
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
			Size = UDim2.new(1, 0, 0.2, 0)
		}):Play()
		-- Reset Accent
		TweenService:Create(accent, TweenInfo.new(0.2), {
			BackgroundColor3 = config.Color
		}):Play()
	end)

	-- Entry Animation (Slide In from Left)
	frame.Position = UDim2.new(-0.5, 0, 0, 0)
	frame.BackgroundTransparency = 1
	accent.BackgroundTransparency = 1
	icon.TextTransparency = 1

	local entryInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(frame, entryInfo, {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0
	}):Play()
	TweenService:Create(accent, entryInfo, {BackgroundTransparency = 0}):Play()
	TweenService:Create(icon, entryInfo, {TextTransparency = 0}):Play()

	return frame
end

-- ============================================================================
-- UPDATE PERKS
-- ============================================================================

local function UpdatePerks(perkList)
	local currentPerks = {}
	for name, _ in pairs(activePerkFrames) do
		currentPerks[name] = false
	end

	for i, perkName in ipairs(perkList) do
		if activePerkFrames[perkName] then
			currentPerks[perkName] = true
			activePerkFrames[perkName].LayoutOrder = i
		else
			local newFrame = CreatePerkEntry(perkName)
			newFrame.LayoutOrder = i
			newFrame.Parent = container
			activePerkFrames[perkName] = newFrame
			currentPerks[perkName] = true
		end
	end

	for name, kept in pairs(currentPerks) do
		if not kept then
			local frame = activePerkFrames[name]
			if frame then
				-- Exit Animation
				local exitInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				TweenService:Create(frame, exitInfo, {
					Position = UDim2.new(-0.5, 0, 0, 0),
					BackgroundTransparency = 1
				}):Play()
				task.delay(0.3, function()
					if frame then frame:Destroy() end
				end)
			end
			activePerkFrames[name] = nil
		end
	end
end

-- ============================================================================
-- EVENTS
-- ============================================================================

perkUpdateEv.OnClientEvent:Connect(function(perks)
	UpdatePerks(perks or {})
end)

-- Initial empty state
UpdatePerks({})

return {}
