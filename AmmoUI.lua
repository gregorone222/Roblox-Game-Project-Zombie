-- AmmoUI.lua (LocalScript)
-- Path: StarterGui/AmmoUI.lua
-- Script Place: ACT 1: Village
-- Theme: Zombie Apocalypse (Bio-Tactical HUD / Military Tech)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")

-- Remove existing UI
if playerGui:FindFirstChild("AmmoUI") then
	playerGui.AmmoUI:Destroy()
end

-- ============================================================================
-- THEME CONFIGURATION
-- ============================================================================
local THEME = {
	ScreenBg = Color3.fromRGB(10, 15, 10),         -- Deep Dark Green/Black

	ToxicGreen = Color3.fromRGB(50, 255, 100),     -- Main HUD Color
	WarningYellow = Color3.fromRGB(255, 200, 0),   -- Mid Ammo
	AlertRed = Color3.fromRGB(255, 50, 50),        -- Low Ammo/Crit

	ScanlineColor = Color3.fromRGB(0, 0, 0),

	FontHeader = Enum.Font.Michroma,               -- Tech Header
	FontDigital = Enum.Font.Code,                  -- Digital Numbers
	FontDetail = Enum.Font.RobotoMono,             -- Small Data
}

local LOW_AMMO_PERCENT = 0.25

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0,0,0)
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Create a "Segmented" Bar for reload
local function createSegmentedBar(parent, count)
	local segments = {}
	local container = create("Frame", {
		Name = "SegmentContainer",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = parent
	})

	local layout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = container
	})

	for i = 1, count do
		local seg = create("Frame", {
			Name = "Seg"..i,
			Size = UDim2.new(1/count, -2, 1, 0), -- Rough calc
			BackgroundColor3 = THEME.ToxicGreen,
			BackgroundTransparency = 0.8,
			LayoutOrder = i,
			Parent = container
		})
		table.insert(segments, seg)
	end
	return segments
end

-- ============================================================================
-- UI CONSTRUCTION
-- ============================================================================
local screenGui = create("ScreenGui", {
	Name = "AmmoUI",
	IgnoreGuiInset = false,
	ResetOnSpawn = true,
	Parent = playerGui
})

-- Main Monitor Frame
local monitorFrame = create("Frame", {
	Name = "MonitorFrame",
	Size = UDim2.new(0, 280, 0, 100),
	BackgroundColor3 = THEME.ScreenBg,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ClipsDescendants = true, -- For scanlines
	Parent = screenGui
})
-- Tech Border
addStroke(monitorFrame, THEME.ToxicGreen, 2)
-- Cut Corners
addCorner(monitorFrame, 8)

-- Scanlines (Striped Gradient Overlay)
local scanlineOverlay = create("Frame", {
	Name = "Scanlines",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 0.5,
	BackgroundColor3 = THEME.ScanlineColor,
	ZIndex = 10,
	Parent = monitorFrame
})
local scanGradient = create("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	}),
	Parent = scanlineOverlay
})
-- Animate scanlines later

-- 1. Status Header
local headerBar = create("Frame", {
	Name = "HeaderBar",
	Size = UDim2.new(1, 0, 0.2, 0),
	BackgroundColor3 = THEME.ToxicGreen,
	BackgroundTransparency = 0.8,
	BorderSizePixel = 0,
	Parent = monitorFrame
})

local weaponLabel = create("TextLabel", {
	Name = "WeaponName",
	Size = UDim2.new(0.7, 0, 1, 0),
	Position = UDim2.new(0.05, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "SYSTEM::RIFLE",
	TextColor3 = THEME.ToxicGreen,
	Font = THEME.FontHeader,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = headerBar
})

local levelBadge = create("TextLabel", {
	Name = "Level",
	Size = UDim2.new(0.25, 0, 1, 0),
	Position = UDim2.new(0.75, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "[LVL:01]",
	TextColor3 = THEME.ToxicGreen,
	Font = THEME.FontDetail,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = headerBar
})

-- 2. Digital Ammo Count
local ammoCountLabel = create("TextLabel", {
	Name = "AmmoCount",
	Size = UDim2.new(0.5, 0, 0.6, 0),
	Position = UDim2.new(0.05, 0, 0.25, 0),
	BackgroundTransparency = 1,
	Text = "30",
	TextColor3 = THEME.ToxicGreen,
	Font = THEME.FontDigital,
	TextSize = 60,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = monitorFrame
})

-- 3. Reserve (Vertical Data Stack)
local reserveLabel = create("TextLabel", {
	Name = "Reserve",
	Size = UDim2.new(0.3, 0, 0.2, 0),
	Position = UDim2.new(0.65, 0, 0.35, 0),
	BackgroundTransparency = 1,
	Text = "RES: 120",
	TextColor3 = THEME.ToxicGreen,
	Font = THEME.FontDetail,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = monitorFrame
})

-- 4. Status Indicator (Text)
local statusLabel = create("TextLabel", {
	Name = "Status",
	Size = UDim2.new(0.3, 0, 0.2, 0),
	Position = UDim2.new(0.65, 0, 0.55, 0),
	BackgroundTransparency = 1,
	Text = "STATUS: OK",
	TextColor3 = THEME.ToxicGreen,
	Font = THEME.FontDetail,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = monitorFrame
})

-- 5. Segmented Reload Bar (Bottom)
local reloadBarFrame = create("Frame", {
	Name = "ReloadBarFrame",
	Size = UDim2.new(0.9, 0, 0.08, 0),
	Position = UDim2.new(0.05, 0, 0.85, 0),
	BackgroundTransparency = 1,
	Parent = monitorFrame
})
local reloadSegments = createSegmentedBar(reloadBarFrame, 10)

-- 6. Glitch Overlay (Invisible normally)

-- ============================================================================
-- LOGIC & ANIMATION
-- ============================================================================

local currentTweens = {}
local activeWeapon = nil
local isGlitching = false

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function updateLayout()
	if isMobile() then
		-- Mobile Compact Mode
		monitorFrame.Size = UDim2.new(0, 200, 0, 80)
		monitorFrame.AnchorPoint = Vector2.new(1, 0)
		monitorFrame.Position = UDim2.new(0.98, 0, 0, 60)

		ammoCountLabel.TextSize = 45
		weaponLabel.TextSize = 12
		reserveLabel.TextSize = 14
		statusLabel.Visible = false -- Hide non-essential
	else
		-- Desktop Full Mode
		monitorFrame.Size = UDim2.new(0, 280, 0, 100)
		monitorFrame.AnchorPoint = Vector2.new(1, 1)
		monitorFrame.Position = UDim2.new(0.98, 0, 0.98, 0)

		ammoCountLabel.TextSize = 60
		weaponLabel.TextSize = 14
		reserveLabel.TextSize = 16
		statusLabel.Visible = true
	end
end

updateLayout()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)

-- Apply Color Theme to all elements
local function applyColor(color)
	monitorFrame.UIStroke.Color = color
	weaponLabel.TextColor3 = color
	levelBadge.TextColor3 = color
	ammoCountLabel.TextColor3 = color
	reserveLabel.TextColor3 = color
	statusLabel.TextColor3 = color

	-- Update segment backgrounds
	for _, seg in ipairs(reloadSegments) do
		seg.BackgroundColor3 = color
	end
end

-- Glitch Effect (Random transparency/offset)
local function triggerGlitch(duration)
	if isGlitching then return end
	isGlitching = true
	task.spawn(function()
		local startTime = tick()
		local originalPos = ammoCountLabel.Position

		while tick() - startTime < duration do
			-- Random offset
			ammoCountLabel.Position = originalPos + UDim2.new(0, math.random(-3,3), 0, math.random(-3,3))
			-- Random text corruption visual (transparency flickering)
			ammoCountLabel.TextTransparency = math.random(0, 5) / 10

			monitorFrame.BackgroundTransparency = math.clamp(math.random(1, 5) / 10, 0, 0.5) -- Glitchy background

			task.wait(0.03)
		end

		-- Reset
		ammoCountLabel.Position = originalPos
		ammoCountLabel.TextTransparency = 0
		isGlitching = false
	end)
end

AmmoUpdateEvent.OnClientEvent:Connect(function(weaponName, ammo, reserveAmmo, isVisible, isReloading)
	monitorFrame.Visible = isVisible

	if not isVisible then 
		activeWeapon = nil
		return 
	end

	-- Equip Sound / Effect Logic could go here
	if activeWeapon ~= weaponName then
		-- New weapon equipped, maybe boot up effect?
		activeWeapon = weaponName
		-- "Boot Sequence" text
		weaponLabel.Text = "INIT::" .. string.upper(weaponName)
		task.delay(0.5, function()
			if activeWeapon == weaponName then
				weaponLabel.Text = "SYSTEM::" .. string.upper(weaponName)
			end
		end)
	end

	-- Get Weapon Data
	local currentTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local level = 0
	local maxAmmo = 30

	if currentTool and currentTool.Name == weaponName then
		level = currentTool:GetAttribute("UpgradeLevel") or 0
		maxAmmo = currentTool:GetAttribute("CustomMaxAmmo") or 30
	end

	levelBadge.Text = string.format("[LVL:%02d]", level)

	if isReloading then
		-- Reload UX: Fill Segments
		local progress = ammo / 100 -- 0 to 1
		local activeSegments = math.floor(progress * #reloadSegments)

		for i, seg in ipairs(reloadSegments) do
			if i <= activeSegments then
				seg.BackgroundTransparency = 0 -- Lit
			else
				seg.BackgroundTransparency = 0.8 -- Dim
			end
		end

		statusLabel.Text = "STATUS: RECHARGING..."
		statusLabel.TextColor3 = THEME.WarningYellow
		applyColor(THEME.WarningYellow)

		-- "Scrambling" numbers effect for ammo count during reload
		local randomChars = {"#", "%", "0", "1", "X"}
		ammoCountLabel.Text = randomChars[math.random(1, #randomChars)] .. randomChars[math.random(1, #randomChars)]

	else
		-- Normal State
		ammoCountLabel.Text = string.format("%02d", ammo) -- Digital padding
		reserveLabel.Text = "RES: " .. tostring(reserveAmmo)

		-- Reset segments
		for _, seg in ipairs(reloadSegments) do
			seg.BackgroundTransparency = 0.8
		end

		-- Fire Glitch
		local lastAmmo = tonumber(monitorFrame:GetAttribute("LastAmmo")) or ammo
		if ammo < lastAmmo then
			triggerGlitch(0.1)
		end
		monitorFrame:SetAttribute("LastAmmo", ammo)

		-- Color Logic
		if ammo == 0 then
			applyColor(THEME.AlertRed)
			statusLabel.Text = "STATUS: CRITICAL"
			-- Pulse Red
			if not currentTweens.Pulse then
				local t = TweenService:Create(monitorFrame.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5})
				t:Play()
				currentTweens.Pulse = t
			end
		elseif (ammo / maxAmmo) <= LOW_AMMO_PERCENT then
			applyColor(THEME.AlertRed)
			statusLabel.Text = "STATUS: LOW AMMO"
			if currentTweens.Pulse then currentTweens.Pulse:Cancel() currentTweens.Pulse = nil end
			monitorFrame.UIStroke.Transparency = 0
		else
			applyColor(THEME.ToxicGreen)
			statusLabel.Text = "STATUS: OPTIMAL"
			if currentTweens.Pulse then currentTweens.Pulse:Cancel() currentTweens.Pulse = nil end
			monitorFrame.UIStroke.Transparency = 0
		end
	end
end)

-- Character Handling
local function setupCharacter(char)
	local function onChildAdded(child)
		if child:IsA("Tool") then
			activeWeapon = child.Name
			monitorFrame.Visible = true
			weaponLabel.Text = "DETECTING..."
			-- "Turn On" Effect (Scale Y from 0 to 1)
			monitorFrame.Size = UDim2.new(monitorFrame.Size.X.Scale, monitorFrame.Size.X.Offset, 0, 0)
			local open = TweenService:Create(monitorFrame, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				Size = (isMobile() and UDim2.new(0, 200, 0, 80) or UDim2.new(0, 280, 0, 100))
			})
			open:Play()
		end
	end

	char.ChildAdded:Connect(onChildAdded)
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Tool") then onChildAdded(c) end
	end

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and activeWeapon == child.Name then
			monitorFrame.Visible = false
			activeWeapon = nil
		end
	end)
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

if not activeWeapon then monitorFrame.Visible = false end
