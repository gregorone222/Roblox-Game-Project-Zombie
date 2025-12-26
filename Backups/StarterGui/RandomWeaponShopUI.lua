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
local COLORS = {
	BACKGROUND = Color3.fromRGB(20, 15, 15), -- Very dark rusty
	PANEL = Color3.fromRGB(35, 30, 30),
	ACCENT_ORANGE = Color3.fromRGB(200, 80, 40), -- Rust/Blood Orange
	ACCENT_GREEN = Color3.fromRGB(80, 160, 60), -- Toxic Green
	TEXT_MAIN = Color3.fromRGB(220, 220, 210), -- Off-white
	TEXT_DIM = Color3.fromRGB(120, 110, 110),
	BORDER = Color3.fromRGB(60, 50, 50),
	STAT_POSITIVE = Color3.fromRGB(80, 255, 80), -- Green
	STAT_NEGATIVE = Color3.fromRGB(255, 80, 80), -- Red
	STAT_NEUTRAL = Color3.fromRGB(200, 200, 200), -- Neutral
	GOLD = Color3.fromRGB(255, 215, 0), -- Gold for Victory
}

local FONT_HEADER = Enum.Font.SpecialElite
local FONT_BODY = Enum.Font.PatrickHand

local SOUNDS = {
	TICK = "rbxassetid://4612375233",
	WIN = "rbxassetid://5153734233",
}

-- Create Main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomWeaponShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Helper: Create a Grunge Background Frame
local function createPanel(parent, size, pos, name)
	local frame = Instance.new("Frame")
	frame.Name = name or "Panel"
	frame.Size = size
	frame.Position = pos
	frame.BackgroundColor3 = COLORS.PANEL
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 4)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = COLORS.BORDER
	stroke.Thickness = 2

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

-- ============================================================================
-- REPLACE UI (Inventory Full)
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

	if replaceUIOverlay then replaceUIOverlay:Destroy() replaceUIOverlay = nil end

	for _, v in pairs(game.Lighting:GetChildren()) do
		if v:IsA("BlurEffect") and v.Name == "ShopBlur" then
			v:Destroy()
		end
	end

	isUIOpen = false
	pendingReplaceData = nil
	updateStatsFunction = nil
end

-- Helper: Create a stat row for the new "Versus" layout (Center Column)
-- Format: [Value New] - [Stat Name] - [Value Old]
local function createVersusStatRow(parent, labelText, order)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 30)
	frame.LayoutOrder = order
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	-- New Value (Left)
	local newVal = Instance.new("TextLabel")
	newVal.Name = "NewValue"
	newVal.Size = UDim2.new(0.3, 0, 1, 0)
	newVal.Position = UDim2.new(0, 0, 0, 0)
	newVal.BackgroundTransparency = 1
	newVal.Text = "-"
	newVal.Font = FONT_BODY
	newVal.TextSize = 18
	newVal.TextColor3 = COLORS.TEXT_MAIN
	newVal.TextXAlignment = Enum.TextXAlignment.Right
	newVal.Parent = frame

	-- Stat Label (Center)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.Position = UDim2.new(0.3, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = FONT_HEADER
	label.TextSize = 16
	label.TextColor3 = COLORS.TEXT_DIM
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = frame

	-- Old Value (Right)
	local oldVal = Instance.new("TextLabel")
	oldVal.Name = "OldValue"
	oldVal.Size = UDim2.new(0.3, 0, 1, 0)
	oldVal.Position = UDim2.new(0.7, 0, 0, 0)
	oldVal.BackgroundTransparency = 1
	oldVal.Text = "-"
	oldVal.Font = FONT_BODY
	oldVal.TextSize = 18
	oldVal.TextColor3 = COLORS.TEXT_DIM
	oldVal.TextXAlignment = Enum.TextXAlignment.Left
	oldVal.Parent = frame

	return newVal, oldVal
end

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

local function createCard(parent, weaponName, index, onSelect)
	local stats = WeaponModule.Weapons[weaponName] or {}

	local btn = Instance.new("TextButton")
	btn.Name = "Card_" .. index
	btn.Size = UDim2.new(1, 0, 0, 80)
	btn.BackgroundColor3 = COLORS.PANEL
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parent

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = COLORS.BORDER
	stroke.Thickness = 1
	stroke.Name = "UIStroke"

	local iconBg = Instance.new("Frame", btn)
	iconBg.Size = UDim2.new(0, 60, 0, 60)
	iconBg.Position = UDim2.new(0, 10, 0.5, -30)
	iconBg.BackgroundColor3 = Color3.new(0,0,0)
	iconBg.BackgroundTransparency = 0.5
	createWeaponViewport(weaponName, iconBg)

	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(0, 200, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = stats.DisplayName or weaponName
	nameLabel.TextColor3 = COLORS.TEXT_MAIN
	nameLabel.Font = FONT_BODY
	nameLabel.TextSize = 20
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

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

	local blur = game.Lighting:FindFirstChild("ShopBlur")
	if not blur then
		blur = Instance.new("BlurEffect", game.Lighting)
		blur.Name = "ShopBlur"
		blur.Size = 16
	end

	replaceUIOverlay = Instance.new("Frame")
	replaceUIOverlay.Name = "ReplaceUI"
	replaceUIOverlay.Size = UDim2.new(1, 0, 1, 0)
	replaceUIOverlay.BackgroundTransparency = 1
	replaceUIOverlay.ZIndex = 110
	replaceUIOverlay.Parent = screenGui

	-- Redesigned Container: More compact height (0.6 instead of 0.8)
	local container = createPanel(replaceUIOverlay, UDim2.new(0.9, 0, 0.6, 0), UDim2.new(0.5, 0, 0.5, 0), "Container")
	container.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Header Area
	local headerFrame = Instance.new("Frame", container)
	headerFrame.Size = UDim2.new(1, 0, 0, 50)
	headerFrame.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", headerFrame)
	title.Text = "TACTICAL DECISION" -- More thematic title
	title.Font = FONT_HEADER
	title.TextSize = 32
	title.TextColor3 = COLORS.ACCENT_ORANGE
	title.Size = UDim2.new(1, 0, 1, 0)
	title.BackgroundTransparency = 1
	title.Parent = headerFrame

	-- Main Content: 3 Columns
	local content = Instance.new("Frame", container)
	content.Size = UDim2.new(1, -40, 1, -110) -- Less bottom padding due to smaller height
	content.Position = UDim2.new(0, 20, 0, 55)
	content.BackgroundTransparency = 1
	content.Parent = container

	-- === LEFT COLUMN: NEW WEAPON ===
	local leftCol = Instance.new("Frame", content)
	leftCol.Name = "NewWeaponCol"
	leftCol.Size = UDim2.new(0.35, -10, 1, 0)
	leftCol.BackgroundColor3 = Color3.new(0,0,0)
	leftCol.BackgroundTransparency = 0.6
	leftCol.Parent = content

	-- Label "ACQUIRED"
	local newHeader = Instance.new("TextLabel", leftCol)
	newHeader.Text = "NEW ACQUISITION"
	newHeader.Size = UDim2.new(1, 0, 0, 30)
	newHeader.Font = FONT_HEADER
	newHeader.TextColor3 = COLORS.ACCENT_GREEN
	newHeader.BackgroundTransparency = 1
	newHeader.Parent = leftCol

	-- Big Viewport (Increased size to fill empty space)
	local vpFrame = Instance.new("Frame", leftCol)
	vpFrame.Size = UDim2.new(1, 0, 0.6, 0)
	vpFrame.Position = UDim2.new(0, 0, 0.1, 0)
	vpFrame.BackgroundTransparency = 1
	vpFrame.Parent = leftCol
	createWeaponViewport(newName, vpFrame)

	-- Weapon Name (Moved up)
	local wName = (WeaponModule.Weapons[newName] and WeaponModule.Weapons[newName].DisplayName) or newName
	local nameLbl = Instance.new("TextLabel", leftCol)
	nameLbl.Text = wName
	nameLbl.Size = UDim2.new(1, 0, 0, 40)
	nameLbl.Position = UDim2.new(0, 0, 0.75, 0)
	nameLbl.Font = FONT_HEADER
	nameLbl.TextSize = 24
	nameLbl.TextColor3 = COLORS.TEXT_MAIN
	nameLbl.BackgroundTransparency = 1
	nameLbl.Parent = leftCol

	-- === CENTER COLUMN: STATS BRIDGE ===
	local centerCol = Instance.new("Frame", content)
	centerCol.Name = "StatsCol"
	centerCol.Size = UDim2.new(0.2, 0, 1, 0)
	centerCol.Position = UDim2.new(0.35, 5, 0, 0)
	centerCol.BackgroundTransparency = 1
	centerCol.Parent = content

	-- Vertical Divider Lines
	local divLeft = Instance.new("Frame", centerCol)
	divLeft.Size = UDim2.new(0, 1, 0.8, 0)
	divLeft.Position = UDim2.new(0, 0, 0.1, 0)
	divLeft.BackgroundColor3 = COLORS.BORDER
	divLeft.BorderSizePixel = 0
	divLeft.Parent = centerCol

	local divRight = Instance.new("Frame", centerCol)
	divRight.Size = UDim2.new(0, 1, 0.8, 0)
	divRight.Position = UDim2.new(1, 0, 0.1, 0)
	divRight.BackgroundColor3 = COLORS.BORDER
	divRight.BorderSizePixel = 0
	divRight.Parent = centerCol

	-- Stats Header "VS" (Centered)
	local vsLabel = Instance.new("TextLabel", centerCol)
	vsLabel.Text = "VS"
	vsLabel.Size = UDim2.new(1, 0, 0, 40)
	vsLabel.Position = UDim2.new(0, 0, 0.1, 0)
	vsLabel.Font = FONT_HEADER
	vsLabel.TextSize = 28
	vsLabel.TextColor3 = COLORS.ACCENT_ORANGE
	vsLabel.BackgroundTransparency = 1
	vsLabel.Parent = centerCol

	-- Stats List Container (Vertically Centered)
	local statsList = Instance.new("Frame", centerCol)
	statsList.Size = UDim2.new(1, -10, 0.5, 0)
	statsList.AnchorPoint = Vector2.new(0.5, 0.5)
	statsList.Position = UDim2.new(0.5, 0, 0.5, 0)
	statsList.BackgroundTransparency = 1
	statsList.Parent = centerCol

	local centerLayout = Instance.new("UIListLayout", statsList)
	centerLayout.Padding = UDim.new(0, 10)
	centerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	centerLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local dmgNew, dmgOld = createVersusStatRow(statsList, "DMG", 1)
	local rpmNew, rpmOld = createVersusStatRow(statsList, "RPM", 2)
	local magNew, magOld = createVersusStatRow(statsList, "MAG", 3)

	-- === RIGHT COLUMN: INVENTORY ===
	local rightCol = Instance.new("ScrollingFrame", content)
	rightCol.Name = "InventoryCol"
	rightCol.Size = UDim2.new(0.45, -10, 1, 0)
	rightCol.Position = UDim2.new(0.55, 10, 0, 0)
	rightCol.BackgroundTransparency = 1
	rightCol.ScrollBarThickness = 4
	rightCol.Parent = content

	local listLayout = Instance.new("UIListLayout", rightCol)
	listLayout.Padding = UDim.new(0, 10)

	-- Footer Buttons
	local footer = Instance.new("Frame", container)
	footer.Size = UDim2.new(1, -40, 0, 50)
	footer.Position = UDim2.new(0, 20, 1, -60)
	footer.BackgroundTransparency = 1
	footer.Parent = container

	local discardBtn = Instance.new("TextButton", footer)
	discardBtn.Text = "DISCARD NEW"
	discardBtn.Size = UDim2.new(0.3, 0, 1, 0)
	discardBtn.BackgroundColor3 = COLORS.PANEL
	discardBtn.TextColor3 = COLORS.STAT_NEGATIVE -- Make it Red for visibility
	discardBtn.Font = FONT_HEADER
	discardBtn.TextSize = 20
	discardBtn.Parent = footer

	-- Subtle border for Discard to make it pop
	local dStroke = Instance.new("UIStroke", discardBtn)
	dStroke.Color = COLORS.BORDER
	dStroke.Thickness = 2

	local replaceBtn = Instance.new("TextButton", footer)
	replaceBtn.Text = "SWAP SELECTED"
	replaceBtn.Size = UDim2.new(0.3, 0, 1, 0)
	replaceBtn.Position = UDim2.new(0.7, 0, 0, 0) -- Far right
	replaceBtn.BackgroundColor3 = COLORS.PANEL 
	replaceBtn.TextColor3 = COLORS.TEXT_MAIN
	replaceBtn.TextTransparency = 0.5
	replaceBtn.Font = FONT_HEADER
	replaceBtn.TextSize = 20
	replaceBtn.Parent = footer
	replaceBtnRef = replaceBtn

	-- Stylize buttons
	for _, btn in pairs({discardBtn, replaceBtn}) do
		local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
		if btn ~= discardBtn then
			local s = Instance.new("UIStroke", btn); s.Color = COLORS.BORDER; s.Thickness = 2; s.Parent = btn
		end
	end

	-- Logic Integration

	updateStatsFunction = function(oldWeaponName)
		-- Get NEW stats
		local nDmg = getWeaponStat(newName, "Damage")
		local nRPM = getWeaponStat(newName, "RPM")
		local nMag = getWeaponStat(newName, "Ammo")

		-- Set NEW labels (Left Side of Center Col)
		dmgNew.Text = tostring(nDmg)
		rpmNew.Text = tostring(nRPM)
		magNew.Text = tostring(nMag)

		if not oldWeaponName then
			-- No selection: Clear Old side and colors
			dmgOld.Text = "-"
			rpmOld.Text = "-"
			magOld.Text = "-"

			dmgNew.TextColor3 = COLORS.TEXT_MAIN
			rpmNew.TextColor3 = COLORS.TEXT_MAIN
			magNew.TextColor3 = COLORS.TEXT_MAIN
		else
			-- Selection made: Compare!
			local oDmg = getWeaponStat(oldWeaponName, "Damage")
			local oRPM = getWeaponStat(oldWeaponName, "RPM")
			local oMag = getWeaponStat(oldWeaponName, "Ammo")

			dmgOld.Text = tostring(oDmg)
			rpmOld.Text = tostring(oRPM)
			magOld.Text = tostring(oMag)

			-- Color logic for NEW value (Is it an upgrade?)
			local function setColor(label, newVal, oldVal)
				if newVal > oldVal then
					label.TextColor3 = COLORS.STAT_POSITIVE
				elseif newVal < oldVal then
					label.TextColor3 = COLORS.STAT_NEGATIVE
				else
					label.TextColor3 = COLORS.STAT_NEUTRAL
				end
			end

			setColor(dmgNew, nDmg, oDmg)
			setColor(rpmNew, nRPM, oRPM)
			setColor(magNew, nMag, oMag)
		end
	end

	-- Initialize
	updateStatsFunction(nil)

	-- Populate Inventory
	cardButtons = {}
	local function updateSelection(idx, clickedBtn, weaponName)
		currentSelectionIndex = idx
		for _, btn in ipairs(cardButtons) do
			local s = btn:FindFirstChild("UIStroke")
			if btn == clickedBtn then
				s.Color = COLORS.ACCENT_ORANGE
				s.Thickness = 2
			else
				s.Color = COLORS.BORDER
				s.Thickness = 1
			end
		end
		if replaceBtnRef then
			replaceBtnRef.BackgroundColor3 = COLORS.ACCENT_ORANGE
			replaceBtnRef.TextTransparency = 0
		end

		if updateStatsFunction then
			updateStatsFunction(weaponName)
		end
	end

	for i, name in ipairs(currentNames) do
		local btn = createCard(rightCol, name, i, updateSelection)
		table.insert(cardButtons, btn)
	end
	rightCol.CanvasSize = UDim2.new(0, 0, 0, #cardButtons * 90)

	-- === KEYBOARD NAVIGATION ===
	local function selectCardByIndex(idx)
		if idx < 1 then idx = 1 end
		if idx > #cardButtons then idx = #cardButtons end
		local btn = cardButtons[idx]
		local weaponName = currentNames[idx]
		if btn and weaponName then
			updateSelection(idx, btn, weaponName)
			-- Auto scroll
			rightCol.CanvasPosition = Vector2.new(0, (idx - 1) * 90)
		end
	end

	local function onNavAction(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

		if actionName == "ReplaceUI_Up" then
			if currentSelectionIndex <= 0 then
				selectCardByIndex(#cardButtons) -- Wrap to bottom or start
			else
				selectCardByIndex(currentSelectionIndex - 1)
			end
			return Enum.ContextActionResult.Sink
		elseif actionName == "ReplaceUI_Down" then
			if currentSelectionIndex <= 0 then
				selectCardByIndex(1)
			else
				selectCardByIndex(currentSelectionIndex + 1)
			end
			return Enum.ContextActionResult.Sink
		elseif actionName == "ReplaceUI_Select" then
			if currentSelectionIndex ~= -1 then
				replaceChoiceEv:FireServer(currentSelectionIndex)
				closeReplaceUI(false)
			end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end

	ContextActionService:BindAction("ReplaceUI_Up", onNavAction, false, Enum.KeyCode.Up, Enum.KeyCode.W)
	ContextActionService:BindAction("ReplaceUI_Down", onNavAction, false, Enum.KeyCode.Down, Enum.KeyCode.S)
	ContextActionService:BindAction("ReplaceUI_Select", onNavAction, false, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter)
	-- === END KEYBOARD NAVIGATION ===

	discardBtn.MouseButton1Click:Connect(function()
		closeReplaceUI(true)
	end)

	replaceBtn.MouseButton1Click:Connect(function()
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

	local container = createPanel(spinFrame, UDim2.new(0, 400, 0, 300), UDim2.new(0.5, -200, 0.5, -150), "Container")
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
