-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- RandomWeaponShopUI.lua (LocalScript)
-- Path: StarterGui/RandomWeaponShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage:WaitForChild("ModuleScript")

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))


local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")
local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")
local getCostRF = RemoteFunctions:WaitForChild("GetRandomWeaponCost")

local isUIOpen = false
local pendingReplaceData = nil -- Stores data from server if inventory is full
local randomPrompt = nil -- Forward declaration for prompt reference

-- Theme Constants
-- Theme Constants
local COLORS = {
	-- Makeshift Palette
	WOOD_DARK = Color3.fromRGB(80, 50, 20),
	WOOD_LIGHT = Color3.fromRGB(140, 90, 40),

	METAL_DARK = Color3.fromRGB(60, 60, 65),
	METAL_LIGHT = Color3.fromRGB(180, 180, 185),
	METAL_RUST = Color3.fromRGB(160, 90, 60),

	TAPE_YELLOW = Color3.fromRGB(220, 180, 40),
	TAPE_GREEN = Color3.fromRGB(80, 160, 60),
	TAPE_RED = Color3.fromRGB(200, 60, 60),

	TEXT_MAIN = Color3.fromRGB(240, 240, 235),
	TEXT_DARK = Color3.fromRGB(50, 40, 30),

	ACCENT_GREEN = Color3.fromRGB(100, 255, 80),
	ACCENT_RED = Color3.fromRGB(255, 80, 80),
	ACCENT_ORANGE = Color3.fromRGB(255, 160, 20),

	SHADOW = Color3.fromRGB(0, 0, 0),
	GOLD = Color3.fromRGB(240, 200, 50),
}

local FONT_HEADER = Enum.Font.FredokaOne
local FONT_BODY = Enum.Font.PatrickHand

-- SOUNDS
local SOUNDS = {
	TICK = "rbxassetid://4612375233",
	WIN = "rbxassetid://5153734233",
	CLICK = "rbxassetid://4612377485", -- Added generic click
}

-- Create Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomWeaponShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ============================================================================
-- AESTHETIC HELPERS (The "Makeshift" Look)
-- ============================================================================

local function addCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
	return c
end

local function addStroke(parent, color, userThickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or COLORS.SHADOW
	s.Thickness = userThickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

-- Create a "Rivet" (Screw head)
local function createRivet(parent, pos)
	local r = Instance.new("Frame", parent)
	r.Size = UDim2.new(0, 8, 0, 8)
	r.Position = pos
	r.BackgroundColor3 = COLORS.METAL_DARK
	r.BorderSizePixel = 0
	addCorner(r, 4)
	return r
end

-- Create a piece of "Duct Tape"
local function createTape(parent, pos, color, rotation)
	local t = Instance.new("Frame", parent)
	t.Size = UDim2.new(0, 40, 0, 12)
	t.Position = pos
	t.Rotation = rotation or math.random(-20, 20)
	t.BackgroundColor3 = color or COLORS.TAPE_YELLOW
	t.BorderSizePixel = 0
	t.ZIndex = (parent.ZIndex or 1) + 1
	return t
end

-- 1. METAL PANEL (Industrial/Weapon Crate feel)
local function createMetalPanel(parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Name = "MetalPanel"
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = COLORS.METAL_LIGHT
	frame.Parent = parent

	addCorner(frame, 6)
	addStroke(frame, COLORS.METAL_DARK, 3)

	-- Rivets in corners
	createRivet(frame, UDim2.new(0, 5, 0, 5))
	createRivet(frame, UDim2.new(1, -13, 0, 5))
	createRivet(frame, UDim2.new(0, 5, 1, -13))
	createRivet(frame, UDim2.new(1, -13, 1, -13))

	return frame
end

-- 2. WOOD PANEL (Clipboard/Sign feel)
local function createWoodPanel(parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Name = "WoodPanel"
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = COLORS.WOOD_LIGHT
	frame.Parent = parent

	addCorner(frame, 4)
	-- Darker wood stroke
	addStroke(frame, COLORS.WOOD_DARK, 3)

	-- Simplified "Grain" line (Top)
	local grain = Instance.new("Frame", frame)
	grain.Size = UDim2.new(1, -10, 0, 2)
	grain.Position = UDim2.new(0, 5, 0.1, 0)
	grain.BackgroundColor3 = COLORS.WOOD_DARK
	grain.BackgroundTransparency = 0.5
	grain.BorderSizePixel = 0

	return frame
end

-- Helper: Create 3D Viewport
local function createWeaponViewport(weaponName, parentFrame)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.Parent = parentFrame

	local cam = Instance.new("Camera")
	vp.CurrentCamera = cam
	cam.Parent = vp

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = vp

	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0
	part.Parent = worldModel

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh

	local data = WeaponModule.Weapons[weaponName]
	if data and data.Skins and data.Skins["Default Skin"] then
		mesh.MeshId = data.Skins["Default Skin"].MeshId
		mesh.TextureId = data.Skins["Default Skin"].TextureId
		mesh.Scale = Vector3.new(1.5, 1.5, 1.5)
	else
		mesh.MeshType = Enum.MeshType.Brick
	end
	mesh.Parent = part
	part.Position = Vector3.new(0, 0, 0)

	cam.CFrame = CFrame.new(Vector3.new(2, 1, 2), Vector3.new(0, 0, 0))

	local rot = 0
	local conn 
	conn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then
			conn:Disconnect()
			return
		end
		rot = rot + dt * 1
		part.CFrame = CFrame.Angles(0, rot, 0) * CFrame.Angles(math.rad(-10), 0, 0)
	end)

	return vp
end

-- Helper: Get Weapon Stat safely
local function getWeaponStat(weaponName, statName)
	local data = WeaponModule.Weapons[weaponName]
	if not data then return 0 end

	if statName == "Damage" then
		return data.Damage or 0
	elseif statName == "RPM" then
		local fr = data.FireRate or 1
		if fr <= 0 then return 0 end
		return math.floor(60 / fr)
	elseif statName == "Ammo" then
		return data.MaxAmmo or 0
	end
	return 0
end

-- ============================================================================
-- REPLACE UI (Tactical Decision)
-- ============================================================================
local replaceUIOverlay = nil
local cardButtons = {}
local currentSelectionIndex = -1
local replaceBtnRef = nil
local updateStatsFunction = nil 

local function closeReplaceUI(wasCancelled)
	-- Remove bindings if they exist
	ContextActionService:UnbindAction("ReplaceUI_Up")
	ContextActionService:UnbindAction("ReplaceUI_Down")
	ContextActionService:UnbindAction("ReplaceUI_Select")

	if wasCancelled then
		replaceChoiceEv:FireServer(-1)
	end

	-- Close effect
	if replaceUIOverlay then 
		TweenService:Create(replaceUIOverlay, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
		task.wait(0.2)
		replaceUIOverlay:Destroy() 
		replaceUIOverlay = nil 
	end

	for _, v in pairs(game.Lighting:GetChildren()) do
		if v:IsA("BlurEffect") and v.Name == "ShopBlur" then
			v:Destroy()
		end
	end

	isUIOpen = false
	pendingReplaceData = nil
	updateStatsFunction = nil
end

-- Creates a row in the comparison clipboard
local function createComparisonRow(parent, iconText, labelText, order)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	-- Icon
	local icon = Instance.new("TextLabel", frame)
	icon.Text = iconText
	icon.Size = UDim2.new(0, 30, 1, 0)
	icon.BackgroundTransparency = 1
	icon.TextSize = 20
	icon.Parent = frame

	-- Stat Name
	local lbl = Instance.new("TextLabel", frame)
	lbl.Text = labelText
	lbl.Size = UDim2.new(0.3, 0, 0.5, 0)
	lbl.Position = UDim2.new(0.2, 0, 0, 0)
	lbl.TextColor3 = COLORS.TEXT_DARK
	lbl.Font = FONT_HEADER
	lbl.TextSize = 14
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	-- The "New" Value (Large)
	local valNew = Instance.new("TextLabel", frame)
	valNew.Name = "NewVal"
	valNew.Text = "0"
	valNew.Size = UDim2.new(0.3, 0, 0.8, 0)
	valNew.Position = UDim2.new(0.2, 0, 0.4, 0)
	valNew.TextColor3 = COLORS.TEXT_DARK -- Default
	valNew.Font = FONT_HEADER
	valNew.TextSize = 22
	valNew.BackgroundTransparency = 1
	valNew.TextXAlignment = Enum.TextXAlignment.Left
	valNew.Parent = frame

	-- The "Arrow" Indicator
	local arrow = Instance.new("TextLabel", frame)
	arrow.Name = "Arrow"
	arrow.Text = "➖"
	arrow.Size = UDim2.new(0, 30, 1, 0)
	arrow.Position = UDim2.new(0.6, 0, 0, 0)
	arrow.BackgroundTransparency = 1
	arrow.TextColor3 = COLORS.TEXT_DIM
	arrow.TextSize = 24
	arrow.Parent = frame

	-- The "Old" Value (Small, Dim)
	local valOld = Instance.new("TextLabel", frame)
	valOld.Name = "OldVal"
	valOld.Text = "50"
	valOld.Size = UDim2.new(0.3, 0, 1, 0)
	valOld.Position = UDim2.new(0.7, 0, 0, 0)
	valOld.TextColor3 = Color3.new(0.5, 0.5, 0.5) -- Dim
	valOld.Font = FONT_BODY
	valOld.TextSize = 18
	valOld.BackgroundTransparency = 1
	valOld.TextXAlignment = Enum.TextXAlignment.Right
	valOld.Visible = false -- Hidden until selection
	valOld.Parent = frame

	return valNew, arrow, valOld
end


local function createInventoryCard(parent, weaponName, index, onSelect)
	local stats = WeaponModule.Weapons[weaponName] or {}

	-- Cardboard Frame
	local btn = Instance.new("TextButton")
	btn.Name = "Card_" .. index
	btn.Size = UDim2.new(1, -10, 0, 70)
	btn.BackgroundColor3 = COLORS.WOOD_LIGHT -- Cardboard-ish
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parent

	addCorner(btn, 6)
	local stroke = addStroke(btn, COLORS.WOOD_DARK, 2)
	stroke.Name = "SelectionStroke"

	-- Icon Background (Dark patch)
	local iconBg = Instance.new("Frame", btn)
	iconBg.Size = UDim2.new(0, 60, 0, 50)
	iconBg.Position = UDim2.new(0, 10, 0.5, -25)
	iconBg.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
	iconBg.BackgroundTransparency = 0.2
	addCorner(iconBg, 4)
	createWeaponViewport(weaponName, iconBg)

	-- Name
	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(0, 150, 0, 20)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = stats.DisplayName or weaponName
	nameLabel.TextColor3 = COLORS.TEXT_DARK
	nameLabel.Font = FONT_HEADER
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

	-- Stats Summary (Small text below name)
	local desc = Instance.new("TextLabel", btn)
	desc.Size = UDim2.new(0, 150, 0, 14)
	desc.Position = UDim2.new(0, 80, 0, 35)
	desc.BackgroundTransparency = 1
	desc.Text = "DMG: "..(stats.Damage or "?").." | AMO: "..(stats.MaxAmmo or "?")
	desc.TextColor3 = Color3.fromRGB(80, 70, 60)
	desc.Font = FONT_BODY
	desc.TextSize = 14
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = btn

	-- Tape Accent (Random colored tape on corners)
	if math.random() > 0.5 then
		createTape(btn, UDim2.new(1, -15, 0, -5), COLORS.TAPE_YELLOW, 30)
	else
		createTape(btn, UDim2.new(0, -5, 1, -10), COLORS.TAPE_GREEN, -30)
	end

	btn.MouseButton1Click:Connect(function()
		onSelect(index, btn, weaponName)
	end)

	return btn
end

local function showReplaceUI()
	if not pendingReplaceData then return end
	local currentNames = pendingReplaceData.currentNames
	local newName = pendingReplaceData.newName
	isUIOpen = true

	-- 1. Background Blur
	local blur = game.Lighting:FindFirstChild("ShopBlur")
	if not blur then
		blur = Instance.new("BlurEffect", game.Lighting)
		blur.Name = "ShopBlur"
		blur.Size = 24
	end

	-- 2. Main Overlay
	replaceUIOverlay = Instance.new("Frame")
	replaceUIOverlay.Name = "ReplaceUI"
	replaceUIOverlay.Size = UDim2.new(1, 0, 1, 0)
	replaceUIOverlay.BackgroundTransparency = 1
	replaceUIOverlay.ZIndex = 110
	replaceUIOverlay.Parent = screenGui

	-- Darken Background slightly
	local scrim = Instance.new("Frame", replaceUIOverlay)
	scrim.Size = UDim2.new(1,0,1,0)
	scrim.BackgroundColor3 = Color3.new(0,0,0)
	scrim.BackgroundTransparency = 0.5
	scrim.BorderSizePixel = 0

	-- 3. HEADER SIGN ("Tactical Decision")
	-- Hanging from top
	local headerSign = createWoodPanel(replaceUIOverlay, UDim2.new(0, 400, 0, 60), UDim2.new(0.5, -200, 0.05, 0))
	local lbl = Instance.new("TextLabel", headerSign)
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "TACTICAL DECISION"
	lbl.Font = FONT_HEADER
	lbl.TextSize = 32
	lbl.TextColor3 = COLORS.TEXT_MAIN
	addStroke(lbl, COLORS.TEXT_DARK, 1) -- Outline for text

	-- Chains holding the sign
	local chainL = Instance.new("Frame", replaceUIOverlay)
	chainL.Size = UDim2.new(0, 4, 0, 100) -- Goes offscreen up
	chainL.Position = UDim2.new(0, 10, 0, -50)
	chainL.BackgroundColor3 = COLORS.METAL_DARK
	chainL.Parent = headerSign

	local chainR = chainL:Clone()
	chainR.Position = UDim2.new(1, -14, 0, -50)
	chainR.Parent = headerSign


	-- ================================================= Container Layout =================================================
	local container = Instance.new("Frame", replaceUIOverlay)
	container.Size = UDim2.new(0.8, 0, 0.6, 0)
	container.Position = UDim2.new(0.1, 0, 0.2, 0)
	container.BackgroundTransparency = 1

	-- COLUMN 1: NEW ACQUISITION (Left)
	local col1 = Instance.new("Frame", container)
	col1.Size = UDim2.new(0.32, 0, 1, 0)
	col1.BackgroundTransparency = 1
	col1.Parent = container

	-- Metal Panel Background
	local c1Panel = createMetalPanel(col1, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0))

	-- Header "NEW ACQUISITION"
	local newTag = Instance.new("TextLabel", c1Panel)
	newTag.Size = UDim2.new(1, 0, 0, 40)
	newTag.BackgroundTransparency = 1
	newTag.Text = "NEW ACQUISITION"
	newTag.TextColor3 = COLORS.ACCENT_GREEN
	newTag.Font = FONT_HEADER
	newTag.TextSize = 22

	-- Weapon View
	local vp = Instance.new("Frame", c1Panel)
	vp.Size = UDim2.new(0.9, 0, 0.5, 0)
	vp.Position = UDim2.new(0.05, 0, 0.2, 0)
	vp.BackgroundColor3 = Color3.new(0,0,0)
	vp.BackgroundTransparency = 0.5
	addCorner(vp, 8)
	createWeaponViewport(newName, vp)

	-- Name Label
	local wName = (WeaponModule.Weapons[newName] and WeaponModule.Weapons[newName].DisplayName) or newName
	local nameLbl = Instance.new("TextLabel", c1Panel)
	nameLbl.Text = wName
	nameLbl.Size = UDim2.new(1, 0, 0, 30)
	nameLbl.Position = UDim2.new(0, 0, 0.75, 0)
	nameLbl.TextColor3 = COLORS.TEXT_DARK
	nameLbl.Font = FONT_HEADER
	nameLbl.TextSize = 24
	nameLbl.BackgroundTransparency = 1

	-- Paint drip effect (Green tape)
	createTape(c1Panel, UDim2.new(0, -10, 0, 20), COLORS.ACCENT_GREEN, -15)


	-- COLUMN 2: STATS COMPARISON (Center)
	local col2 = Instance.new("Frame", container)
	col2.Size = UDim2.new(0.32, 0, 0.9, 0) -- Slightly shorter to look like hanging board
	col2.Position = UDim2.new(0.34, 0, 0.05, 0)
	col2.BackgroundTransparency = 1
	col2.Parent = container

	local c2Panel = createWoodPanel(col2, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0))

	local vsTitle = Instance.new("TextLabel", c2Panel)
	vsTitle.Text = "STATS COMPARISON"
	vsTitle.Size = UDim2.new(1, 0, 0, 40)
	vsTitle.TextColor3 = COLORS.WOOD_DARK
	vsTitle.Font = FONT_HEADER
	vsTitle.TextSize = 20
	vsTitle.BackgroundTransparency = 1

	-- Stats List
	local statListObj = Instance.new("Frame", c2Panel)
	statListObj.Size = UDim2.new(1, -20, 0.7, 0)
	statListObj.Position = UDim2.new(0, 10, 0.2, 0)
	statListObj.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", statListObj)
	layout.Padding = UDim.new(0, 5)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local rowDmgNew, rowDmgArrow, rowDmgOld = createComparisonRow(statListObj, "👊", "DAMAGE", 1)
	local rowRpmNew, rowRpmArrow, rowRpmOld = createComparisonRow(statListObj, "🔥", "FIRE RATE", 2)
	local rowMagNew, rowMagArrow, rowMagOld = createComparisonRow(statListObj, "🔋", "AMMO", 3)


	-- COLUMN 3: INVENTORY (Right)
	local col3 = Instance.new("Frame", container)
	col3.Size = UDim2.new(0.32, 0, 1, 0)
	col3.Position = UDim2.new(0.68, 0, 0, 0)
	col3.BackgroundTransparency = 1
	col3.Parent = container

	local invScroll = Instance.new("ScrollingFrame", col3)
	invScroll.Size = UDim2.new(1, 10, 1, 0) -- Extra width for scrollbar
	invScroll.BackgroundTransparency = 1
	invScroll.ScrollBarThickness = 6
	invScroll.ScrollBarImageColor3 = COLORS.WOOD_LIGHT

	local invLayout = Instance.new("UIListLayout", invScroll)
	invLayout.Padding = UDim.new(0, 10)
	invLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- ================================================= FOOTER BUTTONS =================================================
	local footer = Instance.new("Frame", replaceUIOverlay)
	footer.Size = UDim2.new(0.6, 0, 0, 60)
	footer.Position = UDim2.new(0.2, 0, 0.85, 0)
	footer.BackgroundTransparency = 1

	-- Discard (Left)
	local btnDiscard = Instance.new("TextButton", footer)
	btnDiscard.Text = "DISCARD"
	btnDiscard.Size = UDim2.new(0.4, 0, 1, 0)
	btnDiscard.BackgroundColor3 = COLORS.ACCENT_RED
	btnDiscard.Font = FONT_HEADER
	btnDiscard.TextSize = 24
	btnDiscard.TextColor3 = Color3.new(1,1,1)
	addCorner(btnDiscard, 8)
	addStroke(btnDiscard, Color3.new(0.5,0,0), 3)

	-- Swap (Right)
	local btnSwap = Instance.new("TextButton", footer)
	btnSwap.Text = "SWAP WEAPON"
	btnSwap.Size = UDim2.new(0.4, 0, 1, 0)
	btnSwap.Position = UDim2.new(0.6, 0, 0, 0)
	btnSwap.BackgroundColor3 = COLORS.ACCENT_GREEN
	btnSwap.Font = FONT_HEADER
	btnSwap.TextSize = 24
	btnSwap.TextColor3 = Color3.new(1,1,1)
	addCorner(btnSwap, 8)
	addStroke(btnSwap, Color3.new(0,0.5,0), 3)

	replaceBtnRef = btnSwap -- Reference for updates

	-- LOGIC INTEGRATION

	updateStatsFunction = function(oldWeaponName)
		local newStats = {
			Dmg = getWeaponStat(newName, "Damage"),
			Rpm = getWeaponStat(newName, "RPM"),
			Mag = getWeaponStat(newName, "Ammo")
		}

		rowDmgNew.Text = tostring(newStats.Dmg)
		rowRpmNew.Text = tostring(newStats.Rpm)
		rowMagNew.Text = tostring(newStats.Mag)

		if not oldWeaponName then
			-- Reset
			rowDmgOld.Visible = false
			rowRpmOld.Visible = false
			rowMagOld.Visible = false

			rowDmgArrow.Text = "➖"
			rowRpmArrow.Text = "➖"
			rowMagArrow.Text = "➖"

			rowDmgArrow.TextColor3 = COLORS.TEXT_DIM
			rowRpmArrow.TextColor3 = COLORS.TEXT_DIM
			rowMagArrow.TextColor3 = COLORS.TEXT_DIM

			btnSwap.TextTransparency = 0.5
			btnSwap.BackgroundColor3 = COLORS.METAL_DARK
		else
			-- Show Old
			local oldStats = {
				Dmg = getWeaponStat(oldWeaponName, "Damage"),
				Rpm = getWeaponStat(oldWeaponName, "RPM"),
				Mag = getWeaponStat(oldWeaponName, "Ammo")
			}

			rowDmgOld.Text = tostring(oldStats.Dmg)
			rowRpmOld.Text = tostring(oldStats.Rpm)
			rowMagOld.Text = tostring(oldStats.Mag)

			rowDmgOld.Visible = true
			rowRpmOld.Visible = true
			rowMagOld.Visible = true

			-- Compare Logic (Green Arrow UP if Better)
			local function updateArrow(arrowLbl, newVal, oldVal)
				if newVal > oldVal then
					arrowLbl.Text = "⬆"
					arrowLbl.TextColor3 = COLORS.ACCENT_GREEN
				elseif newVal < oldVal then
					arrowLbl.Text = "⬇"
					arrowLbl.TextColor3 = COLORS.ACCENT_RED
				else
					arrowLbl.Text = "➖"
					arrowLbl.TextColor3 = COLORS.WOOD_DARK
				end
			end

			updateArrow(rowDmgArrow, newStats.Dmg, oldStats.Dmg)
			updateArrow(rowRpmArrow, newStats.Rpm, oldStats.Rpm)
			updateArrow(rowMagArrow, newStats.Mag, oldStats.Mag)

			btnSwap.TextTransparency = 0
			btnSwap.BackgroundColor3 = COLORS.ACCENT_GREEN
		end
	end

	-- Init
	updateStatsFunction(nil)

	-- Populate Inventory
	cardButtons = {}
	local function updateSelection(idx, clickedBtn, weaponName)
		currentSelectionIndex = idx
		for _, btn in ipairs(cardButtons) do
			local s = btn:FindFirstChild("SelectionStroke")
			if btn == clickedBtn then
				s.Color = COLORS.ACCENT_ORANGE
				s.Thickness = 4
			else
				s.Color = COLORS.WOOD_DARK
				s.Thickness = 2
			end
		end
		if updateStatsFunction then updateStatsFunction(weaponName) end
	end

	for i, name in ipairs(currentNames) do
		local btn = createInventoryCard(invScroll, name, i, updateSelection)
		table.insert(cardButtons, btn)
	end
	invScroll.CanvasSize = UDim2.new(0, 0, 0, #cardButtons * 80)

	-- BINDINGS & EVENTS
	local function selectCardByIndex(idx)
		if idx < 1 then idx = 1 end
		if idx > #cardButtons then idx = #cardButtons end
		local btn = cardButtons[idx]
		local weaponName = currentNames[idx]
		if btn then
			updateSelection(idx, btn, weaponName)
			invScroll.CanvasPosition = Vector2.new(0, (idx-1)*80)
		end
	end

	-- Keyboard logic similar to before...
	local function onNavAction(actionName, inputState)
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if actionName == "ReplaceUI_Up" then
			selectCardByIndex(currentSelectionIndex - 1)
		elseif actionName == "ReplaceUI_Down" then
			selectCardByIndex(currentSelectionIndex + 1)
		elseif actionName == "ReplaceUI_Select" then
			if currentSelectionIndex ~= -1 then
				replaceChoiceEv:FireServer(currentSelectionIndex)
				closeReplaceUI(false)
			end
		end
		return Enum.ContextActionResult.Sink
	end

	ContextActionService:BindAction("ReplaceUI_Up", onNavAction, false, Enum.KeyCode.W, Enum.KeyCode.Up)
	ContextActionService:BindAction("ReplaceUI_Down", onNavAction, false, Enum.KeyCode.S, Enum.KeyCode.Down)
	ContextActionService:BindAction("ReplaceUI_Select", onNavAction, false, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter)

	btnDiscard.MouseButton1Click:Connect(function() closeReplaceUI(true) end)
	btnSwap.MouseButton1Click:Connect(function()
		if currentSelectionIndex ~= -1 then
			replaceChoiceEv:FireServer(currentSelectionIndex)
			closeReplaceUI(false)
		end
	end)
end

-- ============================================================================
-- MYSTERY CRATE / SPINNING UI
-- ============================================================================
local spinFrame = nil

local function playLocalSound(soundId)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 0.5
	s.Parent = SoundService
	s:Play()
	game.Debris:AddItem(s, 2)
end

local function spawnConfetti(parent)
	-- Simple 2D particles using frames
	local center = Vector2.new(parent.AbsoluteSize.X / 2, parent.AbsoluteSize.Y / 2)
	for i = 1, 20 do
		local p = Instance.new("Frame")
		p.Size = UDim2.new(0, 8, 0, 8)
		p.Position = UDim2.new(0.5, 0, 0.5, 0)
		p.BackgroundColor3 = i % 2 == 0 and COLORS.ACCENT_ORANGE or COLORS.GOLD
		p.BorderSizePixel = 0
		p.Parent = parent

		local angle = math.rad(math.random(0, 360))
		local dist = math.random(50, 200)
		local duration = math.random(5, 10) / 10

		local targetPos = UDim2.new(0.5, math.cos(angle) * dist, 0.5, math.sin(angle) * dist)

		TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos,
			Rotation = math.random(-180, 180),
			BackgroundTransparency = 1
		}):Play()

		game.Debris:AddItem(p, duration)
	end
end

local function showSpinUI(finalWeaponName, onComplete)
	if spinFrame then spinFrame:Destroy() end
	isUIOpen = true

	-- Blur Background
	local blur = Instance.new("BlurEffect", game.Lighting)
	blur.Name = "ShopBlur"
	blur.Size = 0
	TweenService:Create(blur, TweenInfo.new(0.3), {Size = 16}):Play()

	spinFrame = Instance.new("Frame")
	spinFrame.Name = "SpinUI"
	spinFrame.Size = UDim2.new(1, 0, 1, 0)
	spinFrame.BackgroundTransparency = 0.3
	spinFrame.BackgroundColor3 = Color3.new(0,0,0)
	spinFrame.ZIndex = 100
	spinFrame.Parent = screenGui

	local container = createMetalPanel(spinFrame, UDim2.new(0, 400, 0, 300), UDim2.new(0.5, -200, 0.5, -150))
	container.Name = "Container"
	container.ClipsDescendants = true

	-- Header
	local header = Instance.new("TextLabel", container)
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	header.Text = "MYSTERY CACHE"
	header.Font = FONT_HEADER
	header.TextSize = 32
	header.TextColor3 = COLORS.ACCENT_ORANGE
	header.Parent = container

	-- The "Reel"
	local reelFrame = Instance.new("Frame", container)
	reelFrame.Size = UDim2.new(0, 200, 0, 150)
	reelFrame.Position = UDim2.new(0.5, -100, 0.3, 0)
	reelFrame.BackgroundColor3 = Color3.new(0,0,0)
	reelFrame.BorderSizePixel = 2
	reelFrame.BorderColor3 = COLORS.ACCENT_GREEN

	-- Reel Glow (Hidden initially)
	local reelStroke = Instance.new("UIStroke", reelFrame)
	reelStroke.Color = COLORS.GOLD
	reelStroke.Thickness = 0
	reelStroke.Transparency = 1

	local itemLabel = Instance.new("TextLabel", container)
	itemLabel.Size = UDim2.new(1, 0, 0, 40)
	itemLabel.Position = UDim2.new(0, 0, 0.85, 0)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Font = FONT_BODY
	itemLabel.TextSize = 24
	itemLabel.TextColor3 = COLORS.TEXT_MAIN
	itemLabel.Text = "ROLLING..."
	itemLabel.Parent = container

	-- Build a pool of random weapon names for the visual spin
	local pool = {}
	for name, _ in pairs(WeaponModule.Weapons) do
		table.insert(pool, name)
	end

	-- Current VP reference
	local currentVP = nil

	local function showItem(name)
		if currentVP then currentVP:Destroy() end
		currentVP = createWeaponViewport(name, reelFrame)
		itemLabel.Text = (WeaponModule.Weapons[name] and WeaponModule.Weapons[name].DisplayName) or name
		playLocalSound(SOUNDS.TICK) -- Audio Feedback
	end

	-- Spin Logic
	task.spawn(function()
		local duration = 3.0 -- Slightly longer for effect
		local elapsed = 0
		local speed = 0.05

		-- Exponential Decay Logic
		-- We want speed (delay) to increase exponentially: speed = base * e^(k * t)
		-- To reach a final delay of roughly 0.5s at t=3.0

		while elapsed < duration do
			local randName = pool[math.random(1, #pool)]
			showItem(randName)

			-- Simple friction simulation: Increase delay
			task.wait(speed)
			elapsed = elapsed + speed
			speed = speed * 1.15 -- Increased friction factor for juicier slowdown
		end

		-- LAND ON FINAL
		showItem(finalWeaponName)
		itemLabel.Text = (WeaponModule.Weapons[finalWeaponName] and WeaponModule.Weapons[finalWeaponName].DisplayName) or finalWeaponName
		itemLabel.TextColor3 = COLORS.ACCENT_GREEN

		-- VICTORY EFFECTS
		playLocalSound(SOUNDS.WIN)
		spawnConfetti(reelFrame) -- Particles inside reel

		-- Pulse Reel Border
		reelStroke.Transparency = 0
		reelStroke.Thickness = 5
		TweenService:Create(reelStroke, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = 0, Transparency = 1}):Play()

		-- Flash Effect (White Overlay)
		local flash = Instance.new("Frame", screenGui) -- Full screen flash
		flash.Size = UDim2.new(1,0,1,0)
		flash.BackgroundColor3 = Color3.new(1,1,1)
		flash.BackgroundTransparency = 0
		flash.ZIndex = 200
		flash.Parent = screenGui
		TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		game.Debris:AddItem(flash, 0.6)

		-- Slight Scale Punch on Container
		local originalSize = container.Size
		container.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 20, originalSize.Y.Scale, originalSize.Y.Offset + 20)
		TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Size = originalSize}):Play()

		task.wait(1.5) -- Show the winner

		-- COMPLETE
		if onComplete then onComplete() end

		-- CLEANUP
		if spinFrame then spinFrame:Destroy() spinFrame = nil end

		if replaceUIOverlay and replaceUIOverlay.Parent then
			-- Replace UI is active, keep blur, keep isUIOpen
		else
			-- Done, clean up blur
			if blur then blur:Destroy() end
			isUIOpen = false
		end
	end)
end

-- ============================================================================
-- MAIN LOGIC
-- ============================================================================

local function startDistanceCheck(part)
	task.spawn(function()
		while isUIOpen and player.Character do
			task.wait(0.5)
			if not isUIOpen then break end
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and part then
				local dist = (hrp.Position - part.Position).Magnitude
				if dist > 5 then
					-- Too far, close UI
					-- If replace UI is open, we consider this a "Cancel/Discard"
					if spinFrame or replaceUIOverlay then
						closeReplaceUI(true)
					end
					-- Also ensure spin frame is killed if running
					if spinFrame then spinFrame:Destroy() spinFrame = nil end

					-- Remove blur just in case
					for _, v in pairs(game.Lighting:GetChildren()) do
						if v:IsA("BlurEffect") and v.Name == "ShopBlur" then
							v:Destroy()
						end
					end
					isUIOpen = false

					-- Re-enable prompt
					if randomPrompt then randomPrompt.Enabled = true end
				end
			end
		end
	end)
end

local function purchaseRandomWeapon()
	if isUIOpen then return end

	-- Invoke Server
	local success, result = pcall(function() return purchaseRF:InvokeServer() end)

	if not success then
		warn("Purchase failed (Server Error)")
		return
	end

	if result.success == false then
		-- Handle Errors
		if result.message == "Not enough points" then
			-- Flash red visual or sound
			local notify = Instance.new("TextLabel", screenGui)
			notify.Size = UDim2.new(1,0,0,50)
			notify.Position = UDim2.new(0,0,0.8,0)
			notify.BackgroundTransparency = 1
			notify.Text = "NOT ENOUGH CREDITS"
			notify.Font = FONT_HEADER
			notify.TextSize = 30
			notify.TextColor3 = Color3.fromRGB(255, 50, 50)
			notify.Parent = screenGui
			TweenService:Create(notify, TweenInfo.new(2), {TextTransparency = 1}):Play()
			game.Debris:AddItem(notify, 2)
		elseif result.message == "choose" then
			-- Inventory Full Case
			local newWep = result.weaponName
			-- Start Spin. When done, show Replace UI if pending data exists.
			showSpinUI(newWep, function()
				if pendingReplaceData then
					showReplaceUI()
				end
			end)
			startDistanceCheck(workspace:WaitForChild("Random"))
		end
	elseif result.success == true then
		-- Success Case (Inventory Not Full)
		local newWep = result.weaponName
		showSpinUI(newWep, nil)
		startDistanceCheck(workspace:WaitForChild("Random"))
	end
end

-- Listener for Replace UI
openReplaceUI.OnClientEvent:Connect(function(currentNames, newName, cost, hasDiscount)
	-- Store the data. DO NOT show UI yet.
	-- `purchaseRandomWeapon` will trigger `showSpinUI`, which will check this data on completion.
	pendingReplaceData = {
		currentNames = currentNames,
		newName = newName,
		cost = cost,
		hasDiscount = hasDiscount
	}
end)

-- Register Proximity Interaction via Module
local randomPart = workspace:WaitForChild("Random", 5)
local promptHandler = nil

if randomPart then
	randomPrompt = randomPart:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not randomPrompt then
		-- Create if missing, attaching to randomPart or a sub-part if needed
		-- The original code used searchRecursive, so let's try to find it again or create on Attachment
		local attach = randomPart:FindFirstChild("Attachment")
		local target = attach or randomPart

		randomPrompt = Instance.new("ProximityPrompt")
		randomPrompt.Name = "RandomPrompt" -- Matches the cost updater logic below
		randomPrompt.ObjectText = "Mystery Cache"
		randomPrompt.ActionText = "Buy"
		randomPrompt.Parent = target
	end

	randomPrompt.Triggered:Connect(function()
		purchaseRandomWeapon()
		-- We allow purchaseRandomWeapon to handle UI open/close
		-- But we should disable prompt temporarily to prevent spam
		randomPrompt.Enabled = false
		task.wait(1)
		-- Re-enable logic is actually handled by 'isOpen' toggle in previous handler
		-- Here we just re-enable it after a short delay or when UI closes?
		-- The previous logic: promptHandler:SetOpen(false) when isOpen=true
		-- which implies prompt HIDDEN when UI OPEN.
		-- purchaseRandomWeapon calls showSpinUI -> isUIOpen = true
	end)
end

-- Cost Updater (Floating Text)
if randomPart then
	task.spawn(function()
		local attachment = randomPart:WaitForChild("Attachment", 10)
		if attachment then
			local prompt = attachment:WaitForChild("RandomPrompt", 10)
			if not prompt then return end

			while task.wait(1) do
				local success, cost = pcall(function() return getCostRF:InvokeServer() end)
				if success and cost then
					prompt.ObjectText = "MYSTERY CACHE [ $" .. cost .. " ]"
				else
					prompt.ObjectText = "MYSTERY CACHE"
				end
			end
		end
	end)
end

-- Cleanup on death
local function onCharacterAdded(char)
	local hum = char:WaitForChild("Humanoid")
	hum.Died:Connect(function()
		if isUIOpen then
			closeReplaceUI(true)
		end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)
