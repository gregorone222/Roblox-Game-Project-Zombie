-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- AmmoUI.lua (LocalScript)
-- Path: StarterGui/AmmoUI.lua
-- Script Place: ACT 1: Village
-- Theme: Apocalypse Survival (Matched to InventoryUI)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local AmmoUpdateEvent = RemoteEvents:WaitForChild("AmmoUpdateEvent")

-- Remove existing UI
if playerGui:FindFirstChild("AmmoUI") then
	playerGui.AmmoUI:Destroy()
end

-- ============================================================================
-- THEME CONFIGURATION (Matches InventoryUI)
-- ============================================================================
local THEME = {
	Colors = {
		-- Core Colors
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel = Color3.fromRGB(35, 28, 22),           -- Warm brown panel
		PanelGlass = Color3.fromRGB(45, 38, 30),      -- Lighter warm brown

		-- Accent Colors
		AccentMain = Color3.fromRGB(218, 165, 32),    -- Golden (Sunset Orange)
		AccentSec = Color3.fromRGB(139, 90, 43),      -- Forest Brown
		AccentHighlight = Color3.fromRGB(255, 200, 80), -- Bright Yellow

		-- Text Colors
		TextHigh = Color3.fromRGB(255, 248, 230),     -- Warm white
		TextMid = Color3.fromRGB(180, 160, 130),      -- Muted gold
		TextLow = Color3.fromRGB(100, 85, 65),        -- Dark warm

		-- Status Colors
		Success = Color3.fromRGB(46, 204, 113),       -- Green
		Error = Color3.fromRGB(231, 76, 60),          -- Red
		Warning = Color3.fromRGB(241, 196, 15),       -- Yellow
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.Code
	},
	Sizes = {
		CornerRadius = UDim.new(0, 8),
		BorderThickness = 2
	}
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
	stroke.Color = color or THEME.Colors.AccentMain
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
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
			BackgroundColor3 = THEME.Colors.AccentMain,
			BackgroundTransparency = 0.8,
			LayoutOrder = i,
			Parent = container
		})
		addCorner(seg, 2)
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
	Size = UDim2.new(0, 260, 0, 110),
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	Parent = screenGui
})

addCorner(monitorFrame, 8)
local mainStroke = addStroke(monitorFrame, THEME.Colors.AccentSec, 2)

-- Inner Panel (Glass effect)
local innerPanel = create("Frame", {
	Name = "InnerPanel",
	Size = UDim2.new(0.95, 0, 0.9, 0),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = THEME.Colors.PanelGlass,
	BackgroundTransparency = 0.5,
	Parent = monitorFrame
})
addCorner(innerPanel, 6)

-- 1. Status Header
local headerBar = create("Frame", {
	Name = "HeaderBar",
	Size = UDim2.new(1, 0, 0.25, 0),
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	Parent = innerPanel
})
addCorner(headerBar, 6) -- Will clip bottom corners with a cover frame if needed, but rounding all is fine for now

-- Fix header bottom rounded corners visually by covering them or just using top corners?
-- Simpler: Just round all and let it look like a capsule top
local headerCover = create("Frame", { -- Covers bottom corners of header
	Parent = headerBar,
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0,0,0.5,0),
	BackgroundColor3 = THEME.Colors.Panel,
	BorderSizePixel = 0
})

local weaponLabel = create("TextLabel", {
	Name = "WeaponName",
	Size = UDim2.new(0.7, 0, 1, 0),
	Position = UDim2.new(0.05, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "RIFLE",
	TextColor3 = THEME.Colors.AccentMain,
	Font = THEME.Fonts.Header,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 2,
	Parent = headerBar
})

local levelBadge = create("TextLabel", {
	Name = "Level",
	Size = UDim2.new(0.25, 0, 1, 0),
	Position = UDim2.new(0.75, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "LVL 01",
	TextColor3 = THEME.Colors.TextMid,
	Font = THEME.Fonts.Body,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 2,
	Parent = headerBar
})

-- Divider Line
local divider = create("Frame", {
	Parent = innerPanel,
	Size = UDim2.new(0.9, 0, 0, 2),
	Position = UDim2.new(0.5, 0, 0.25, 0),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = THEME.Colors.AccentSec,
	BorderSizePixel = 0
})

-- 2. Digital Ammo Count
local ammoCountLabel = create("TextLabel", {
	Name = "AmmoCount",
	Size = UDim2.new(0.5, 0, 0.55, 0),
	Position = UDim2.new(0.05, 0, 0.3, 0),
	BackgroundTransparency = 1,
	Text = "30",
	TextColor3 = THEME.Colors.TextHigh,
	Font = THEME.Fonts.Header,
	TextSize = 52,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = innerPanel
})

-- 3. Reserve (Small Stack)
local reserveContainer = create("Frame", {
	Name = "ReserveContainer",
	Size = UDim2.new(0.4, 0, 0.55, 0),
	Position = UDim2.new(0.55, 0, 0.3, 0),
	BackgroundTransparency = 1,
	Parent = innerPanel
})

local reserveLabel = create("TextLabel", {
	Name = "Reserve",
	Size = UDim2.new(1, 0, 0.5, 0),
	Position = UDim2.new(0, 0, 0.1, 0),
	BackgroundTransparency = 1,
	Text = "120",
	TextColor3 = THEME.Colors.TextMid,
	Font = THEME.Fonts.Body,
	TextSize = 24,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = reserveContainer
})

local reserveTitle = create("TextLabel", {
	Name = "ReserveTitle",
	Size = UDim2.new(1, 0, 0.3, 0),
	Position = UDim2.new(0, 0, 0.55, 0),
	BackgroundTransparency = 1,
	Text = "RESERVE",
	TextColor3 = THEME.Colors.TextLow,
	Font = THEME.Fonts.Body,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = reserveContainer
})


-- 4. Segmented Reload Bar (Bottom)
local reloadBarFrame = create("Frame", {
	Name = "ReloadBarFrame",
	Size = UDim2.new(0.9, 0, 0.06, 0),
	Position = UDim2.new(0.05, 0, 0.88, 0),
	BackgroundTransparency = 1,
	Parent = innerPanel
})
local reloadSegments = createSegmentedBar(reloadBarFrame, 12)

-- Status Text (Overlay on reload)
local statusLabel = create("TextLabel", {
	Name = "Status",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	Text = "RELOADING",
	TextColor3 = THEME.Colors.AccentMain,
	Font = THEME.Fonts.Body,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Center,
	Visible = false, -- Only show when reloading or critical
	ZIndex = 5,
	Parent = reloadBarFrame
})


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
		monitorFrame.Size = UDim2.new(0, 180, 0, 80)
		monitorFrame.AnchorPoint = Vector2.new(1, 0)
		monitorFrame.Position = UDim2.new(0.98, 0, 0, 60)

		ammoCountLabel.TextSize = 36
		weaponLabel.TextSize = 12
		reserveLabel.TextSize = 18
		reserveTitle.Visible = false
	else
		-- Desktop Full Mode
		monitorFrame.Size = UDim2.new(0, 260, 0, 110)
		monitorFrame.AnchorPoint = Vector2.new(1, 1)
		monitorFrame.Position = UDim2.new(0.98, 0, 0.98, 0)

		ammoCountLabel.TextSize = 52
		weaponLabel.TextSize = 16
		reserveLabel.TextSize = 24
		reserveTitle.Visible = true
	end
end

updateLayout()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayout)

-- Apply Status Color to elements
local function applyStatusColor(color)
	mainStroke.Color = color
	ammoCountLabel.TextColor3 = color
	
	-- Update segment active color
	for _, seg in ipairs(reloadSegments) do
		if seg.BackgroundTransparency < 0.5 then -- Active
			seg.BackgroundColor3 = color
		end
	end
end

-- Glitch Effect (Retained but styled)
local function triggerGlitch(duration)
	if isGlitching then return end
	isGlitching = true
	task.spawn(function()
		local startTime = tick()
		local originalPos = ammoCountLabel.Position
		local originalColor = ammoCountLabel.TextColor3

		while tick() - startTime < duration do
			-- Random offset
			ammoCountLabel.Position = originalPos + UDim2.new(0, math.random(-2,2), 0, math.random(-2,2))
			-- Slight color shift
			if math.random() > 0.5 then
				ammoCountLabel.TextColor3 = THEME.Colors.AccentHighlight
			else
				ammoCountLabel.TextColor3 = originalColor
			end
			task.wait(0.05)
		end

		-- Reset
		ammoCountLabel.Position = originalPos
		ammoCountLabel.TextColor3 = originalColor
		isGlitching = false
	end)
end

AmmoUpdateEvent.OnClientEvent:Connect(function(weaponName, ammo, reserveAmmo, isVisible, isReloading)
	monitorFrame.Visible = isVisible

	if not isVisible then 
		activeWeapon = nil
		return 
	end

	-- Weapon Change Logic
	-- Fix: Allow update if name changed OR if we are still in "SCANNING..." mode
	if activeWeapon ~= weaponName or weaponLabel.Text == "SCANNING..." then
		activeWeapon = weaponName
		weaponLabel.Text = string.upper(weaponName)
		
		-- Flash effect on equip
		local flash = TweenService:Create(monitorFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
			BackgroundColor3 = THEME.Colors.AccentSec
		})
		flash:Play()
	end

	-- Get Weapon Data
	local currentTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local level = 0
	local maxAmmo = 30

	if currentTool and currentTool.Name == weaponName then
		level = currentTool:GetAttribute("UpgradeLevel") or 0
		maxAmmo = currentTool:GetAttribute("CustomMaxAmmo") or 30
	end

	levelBadge.Text = string.format("LVL %02d", level)

	if isReloading then
		-- Reload UX: Fill Segments
		local progress = ammo / 100 -- Assuming 0-100 logic from previous script, or standard ratio
		-- Better logic: Create visual fill based on time if we had duration, but here we likely get 0-100 updates
		-- If input is actual ammo count during partial reload, adapt.
		-- Assuming input 'ammo' is 0-100 percentage during reload based on typical Roblox reload scripts
		
		local activeSegments = math.floor((ammo / 100) * #reloadSegments)

		for i, seg in ipairs(reloadSegments) do
			if i <= activeSegments then
				seg.BackgroundTransparency = 0 -- Lit
				seg.BackgroundColor3 = THEME.Colors.AccentHighlight
			else
				seg.BackgroundTransparency = 0.8 -- Dim
				seg.BackgroundColor3 = THEME.Colors.AccentMain
			end
		end

		statusLabel.Text = "RELOADING"
		statusLabel.Visible = true
		statusLabel.TextColor3 = THEME.Colors.AccentHighlight
		applyStatusColor(THEME.Colors.AccentHighlight)
		
		ammoCountLabel.Text = "--"

	else
		statusLabel.Visible = false
		-- Normal State
		ammoCountLabel.Text = string.format("%02d", ammo)
		reserveLabel.Text = tostring(reserveAmmo)

		-- Reset segments to full bar representing mag capacity? Or just hidden?
		-- Let's make it a capacity bar
		local fillPct = math.clamp(ammo / maxAmmo, 0, 1)
		local activeSegments = math.floor(fillPct * #reloadSegments)
		
		for i, seg in ipairs(reloadSegments) do
			if i <= activeSegments then
				seg.BackgroundTransparency = 0.2
				seg.BackgroundColor3 = THEME.Colors.AccentMain
			else
				seg.BackgroundTransparency = 0.9
				seg.BackgroundColor3 = THEME.Colors.TextLow
			end
		end

		-- Fire Glitch on shoot (ammo decrease)
		local lastAmmo = tonumber(monitorFrame:GetAttribute("LastAmmo")) or ammo
		if ammo < lastAmmo then
			triggerGlitch(0.1)
		end
		monitorFrame:SetAttribute("LastAmmo", ammo)

		-- Color Logic
		if ammo == 0 then
			applyStatusColor(THEME.Colors.Error)
			-- Pulse Red
			if not currentTweens.Pulse then
				local t = TweenService:Create(mainStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5})
				t:Play()
				currentTweens.Pulse = t
			end
		elseif (ammo / maxAmmo) <= LOW_AMMO_PERCENT then
			applyStatusColor(THEME.Colors.Error)
			if currentTweens.Pulse then currentTweens.Pulse:Cancel() currentTweens.Pulse = nil end
			mainStroke.Transparency = 0
		else
			applyStatusColor(THEME.Colors.AccentMain)
			if currentTweens.Pulse then currentTweens.Pulse:Cancel() currentTweens.Pulse = nil end
			mainStroke.Transparency = 0
		end
	end
end)

-- Character Handling
local function setupCharacter(char)
	local function onChildAdded(child)
		if child:IsA("Tool") then
			activeWeapon = child.Name
			monitorFrame.Visible = true
			weaponLabel.Text = "SCANNING..."
			
			-- Pop-in Animation
			monitorFrame.Size = UDim2.new(0.1, 0, 0.1, 0)
			monitorFrame.BackgroundTransparency = 1
			
			local targetSize = (isMobile() and UDim2.new(0, 180, 0, 80) or UDim2.new(0, 260, 0, 110))
			
			local openInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			TweenService:Create(monitorFrame, openInfo, {
				Size = targetSize,
				BackgroundTransparency = 0.1
			}):Play()
			
			-- Force sync request to server
			local RequestAmmoSync = RemoteEvents:FindFirstChild("RequestAmmoSync")
			if RequestAmmoSync then
				RequestAmmoSync:FireServer(child)
			end
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
