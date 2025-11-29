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
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage:WaitForChild("ModuleScript")

-- Require WeaponModule for stats
local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ProximityUIHandler = require(ModuleScriptReplicatedStorage:WaitForChild("ProximityUIHandler"))

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")
local getCostRF = RemoteFunctions:WaitForChild("GetRandomWeaponCost")

local isUIOpen = false

-- Modern UI Elements
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RandomWeaponShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Notification System
local notificationFrame = Instance.new("Frame")
notificationFrame.Size = UDim2.new(0, 350, 0, 70)
notificationFrame.Position = UDim2.new(0.5, -175, 0.2, 0)
notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
notificationFrame.BackgroundTransparency = 0.2
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.ZIndex = 20
notificationFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 12)
notifCorner.Parent = notificationFrame

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = Color3.fromRGB(80, 80, 120)
notifStroke.Thickness = 2
notifStroke.Parent = notificationFrame

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = ""
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamBold
notifLabel.ZIndex = 21
notifLabel.Parent = notificationFrame

-- Variables for UI elements
local replaceUIOverlay = nil
local crateUIFrame = nil
local cardButtons = {} -- List of card buttons for keyboard nav
local currentSelectionIndex = -1 -- For keyboard nav
local replaceBtnRef = nil -- Reference to replace button
local discardBtnRef = nil -- Reference to discard button

-- Helper function to toggle backpack
local function setBackpackVisible(visible)
	if UserInputService.TouchEnabled then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, visible)
	end
end

-- Input Handling Keys
local ACTION_NAV_UP = "ShopNavUp"
local ACTION_NAV_DOWN = "ShopNavDown"
local ACTION_SELECT = "ShopSelect"
local ACTION_DISCARD = "ShopDiscard"

local function unbindInput()
	ContextActionService:UnbindAction(ACTION_NAV_UP)
	ContextActionService:UnbindAction(ACTION_NAV_DOWN)
	ContextActionService:UnbindAction(ACTION_SELECT)
	ContextActionService:UnbindAction(ACTION_DISCARD)
end

-- Helper: Close UI
local function closeReplaceUI(wasCancelled)
	unbindInput()

	if wasCancelled then
		replaceChoiceEv:FireServer(-1)
	end

	if UserInputService.TouchEnabled then
		setBackpackVisible(true)
	end

	if replaceUIOverlay then
		replaceUIOverlay:Destroy()
		replaceUIOverlay = nil
	end

	if crateUIFrame then
		crateUIFrame:Destroy()
		crateUIFrame = nil
	end

	-- Cleanup Blur
	for _, v in pairs(game.Lighting:GetChildren()) do
		if v:IsA("BlurEffect") and v.Name == "ShopBlur" then
			v:Destroy()
		end
	end

	isUIOpen = false
	cardButtons = {}
	currentSelectionIndex = -1
	replaceBtnRef = nil
	discardBtnRef = nil
end

-- Helper: Show Notification
local function showNotification(message, color, duration)
	notifLabel.Text = message
	notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)

	notificationFrame.Visible = true
	notificationFrame.Position = UDim2.new(0.5, -175, 0.15, 0)

	local tweenIn = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
		Position = UDim2.new(0.5, -175, 0.2, 0)
	})
	tweenIn:Play()

	task.delay(duration or 3, function()
		local tweenOut = TweenService:Create(notificationFrame, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -175, 0.15, 0)
		})
		tweenOut:Play()
		task.wait(0.3)
		notificationFrame.Visible = false
	end)
end

-- Helper: Create 3D Viewport
local function createWeaponViewport(weaponName, parentFrame)
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.new(1, 0, 1, 0)
	vp.BackgroundTransparency = 1
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(1, 1, 1)
	vp.Ambient = Color3.fromRGB(150, 150, 150)
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
	part.Color = Color3.new(1, 1, 1)
	part.Parent = worldModel

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh

	local data = WeaponModule.Weapons[weaponName]
	if data and data.Skins and data.Skins["Default Skin"] then
		mesh.MeshId = data.Skins["Default Skin"].MeshId
		mesh.TextureId = data.Skins["Default Skin"].TextureId
		-- Scale adjustment might be needed depending on raw mesh size
		mesh.Scale = Vector3.new(1, 1, 1)
	else
		mesh.MeshType = Enum.MeshType.Brick
	end
	mesh.Parent = part

	-- Centering
	part.Position = Vector3.new(0, 0, 0)

	-- Position camera CLOSER (Fix: 3DPreview too small)
	-- Moved from (3,1,3) to (1.5, 0.5, 1.5) to zoom in significantly.
	cam.CFrame = CFrame.new(Vector3.new(1.5, 0.5, 1.5), Vector3.new(0, 0, 0))

	-- Rotation Loop
	local rot = 0
	local conn 
	conn = RunService.RenderStepped:Connect(function(dt)
		if not vp:IsDescendantOf(game) then
			conn:Disconnect()
			return
		end
		rot = rot + dt * 1
		part.CFrame = CFrame.Angles(0, rot, 0) * CFrame.Angles(math.rad(-15), 0, 0)
	end)

	return vp
end

-- Helper: Create Stat Bar
local function createStatBar(parent, name, value, maxValue, color)
	local frame = Instance.new("Frame")
	frame.Name = "Stat_" .. name
	frame.Size = UDim2.new(1, 0, 0, 30)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 15)
	label.BackgroundTransparency = 1
	label.Text = name .. "  " .. tostring(value)
	label.TextColor3 = Color3.fromRGB(150, 160, 180)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.Gotham
	label.TextSize = 10
	label.Parent = frame

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 18)
	track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = 0.5
	track.BorderSizePixel = 0
	track.Parent = frame

	local trackCorner = Instance.new("UICorner", track)
	trackCorner.CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	local pct = math.clamp(value / maxValue, 0, 1)
	fill.Size = UDim2.new(0, 0, 1, 0) -- Start at 0 for animation
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner", fill)
	fillCorner.CornerRadius = UDim.new(1, 0)

	TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
end

-- Helper: Create Weapon Card
local function createWeaponCard(parent, weaponName, index, newWeaponStats, onSelect)
	local stats = WeaponModule.Weapons[weaponName] or {}
	local dmg = stats.Damage or 0
	local rpm = (stats.FireRate and stats.FireRate > 0) and math.floor(60 / stats.FireRate) or 0

	local btn = Instance.new("TextButton")
	btn.Name = "Card_" .. index
	btn.Size = UDim2.new(1, 0, 0, 80)
	btn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = parent

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(71, 85, 105)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Name = "UIStroke"

	-- Icon Viewport
	local iconBg = Instance.new("Frame", btn)
	iconBg.Size = UDim2.new(0, 60, 0, 60)
	iconBg.Position = UDim2.new(0, 10, 0.5, -30)
	iconBg.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	iconBg.BorderSizePixel = 0

	local iconCorner = Instance.new("UICorner", iconBg)
	iconCorner.CornerRadius = UDim.new(0, 8)

	createWeaponViewport(weaponName, iconBg)

	-- Name
	local nameLabel = Instance.new("TextLabel", btn)
	nameLabel.Size = UDim2.new(0, 200, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = stats.DisplayName or weaponName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Stats Row
	local statsRow = Instance.new("Frame", btn)
	statsRow.Size = UDim2.new(0, 200, 0, 20)
	statsRow.Position = UDim2.new(0, 80, 0, 40)
	statsRow.BackgroundTransparency = 1

	local function addStatDiff(text, val, newVal, xPos)
		local diff = val - newVal
		local color = Color3.fromRGB(148, 163, 184) -- Gray
		local arrow = "-"

		if diff > 0 then
			color = Color3.fromRGB(74, 222, 128) -- Green
			arrow = "?"
		elseif diff < 0 then
			color = Color3.fromRGB(248, 113, 113) -- Red
			arrow = "?"
		end

		local lbl = Instance.new("TextLabel", statsRow)
		lbl.Size = UDim2.new(0, 100, 1, 0)
		lbl.Position = UDim2.new(0, xPos, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = string.format("%s: %d <font color=\"rgb(%d,%d,%d)\">%s</font>", text, val, color.R*255, color.G*255, color.B*255, arrow)
		lbl.RichText = true
		lbl.TextColor3 = Color3.fromRGB(148, 163, 184)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end

	addStatDiff("DMG", dmg, newWeaponStats.Damage or 0, 0)
	-- Assuming newWeaponStats also has proper FireRate
	local newRpm = (newWeaponStats.FireRate and newWeaponStats.FireRate > 0) and math.floor(60 / newWeaponStats.FireRate) or 0
	addStatDiff("RPM", rpm, newRpm, 100)

	-- Selection Logic
	btn.MouseButton1Click:Connect(function()
		onSelect(index, btn)
	end)

	return btn
end

-- MAIN UI FUNCTION
local function showReplaceUI(currentNames, newName, cost, hasDiscount)
	if UserInputService.TouchEnabled then
		setBackpackVisible(false)
	end

	isUIOpen = true

	-- 1. Crate UI (Animation)
	crateUIFrame = Instance.new("Frame")
	crateUIFrame.Name = "CrateUI"
	crateUIFrame.Size = UDim2.new(1, 0, 1, 0)
	crateUIFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	crateUIFrame.BackgroundTransparency = 0.2
	crateUIFrame.ZIndex = 50
	crateUIFrame.Parent = screenGui

	local blur = Instance.new("BlurEffect", game.Lighting)
	blur.Name = "ShopBlur"
	blur.Size = 0
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 24}):Play()

	local crateBox = Instance.new("Frame", crateUIFrame)
	crateBox.Size = UDim2.new(0, 200, 0, 200)
	crateBox.Position = UDim2.new(0.5, -100, 0.5, -100)
	crateBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	crateBox.BorderSizePixel = 0

	local crateStroke = Instance.new("UIStroke", crateBox)
	crateStroke.Color = Color3.fromRGB(245, 158, 11) -- Amber
	crateStroke.Thickness = 4

	local crateCorner = Instance.new("UICorner", crateBox)
	crateCorner.CornerRadius = UDim.new(0, 20)

	local qMark = Instance.new("TextLabel", crateBox)
	qMark.Size = UDim2.new(1, 0, 1, 0)
	qMark.BackgroundTransparency = 1
	qMark.Text = "?"
	qMark.Font = Enum.Font.GothamBold
	qMark.TextSize = 100
	qMark.TextColor3 = Color3.fromRGB(255, 255, 255)

	local openingText = Instance.new("TextLabel", crateUIFrame)
	openingText.Size = UDim2.new(1, 0, 0, 50)
	openingText.Position = UDim2.new(0, 0, 0.5, 120)
	openingText.BackgroundTransparency = 1
	openingText.Text = "MEMBUKA..."
	openingText.Font = Enum.Font.GothamBlack
	openingText.TextSize = 24
	openingText.TextColor3 = Color3.fromRGB(245, 158, 11)

	-- 2. Main Replace UI Setup
	replaceUIOverlay = Instance.new("Frame")
	replaceUIOverlay.Name = "ReplaceUIOverlay"
	replaceUIOverlay.Size = UDim2.new(1, 0, 1, 0)
	replaceUIOverlay.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	replaceUIOverlay.BackgroundTransparency = 1 -- REMOVED OVERLAY
	replaceUIOverlay.Visible = false
	replaceUIOverlay.ZIndex = 10
	replaceUIOverlay.Parent = screenGui

	local container = Instance.new("Frame")
	container.Name = "MainContainer"
	container.Size = UDim2.new(0.85, 0, 0.8, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = replaceUIOverlay

	local containerCorner = Instance.new("UICorner", container)
	containerCorner.CornerRadius = UDim.new(0, 24)

	local containerStroke = Instance.new("UIStroke", container)
	containerStroke.Color = Color3.fromRGB(255, 255, 255)
	containerStroke.Transparency = 0.9
	containerStroke.Thickness = 1

	local header = Instance.new("Frame", container)
	header.Size = UDim2.new(1, 0, 0, 80)
	header.BackgroundTransparency = 1

	local titleIcon = Instance.new("ImageLabel", header)
	titleIcon.Size = UDim2.new(0, 40, 0, 40)
	titleIcon.Position = UDim2.new(0, 30, 0.5, -20)
	titleIcon.BackgroundTransparency = 1
	titleIcon.Image = "rbxassetid://0" -- Placeholder

	local titleText = Instance.new("TextLabel", header)
	titleText.Text = "INVENTARIS PENUH"
	titleText.Position = UDim2.new(0, 30, 0, 15)
	titleText.Size = UDim2.new(0, 300, 0, 30)
	titleText.Font = Enum.Font.GothamBlack
	titleText.TextSize = 24
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText.BackgroundTransparency = 1
	titleText.TextXAlignment = Enum.TextXAlignment.Left

	local subText = Instance.new("TextLabel", header)
	subText.Text = "Anda harus membuang senjata baru atau mengganti salah satu senjata lama."
	subText.Position = UDim2.new(0, 30, 0, 45)
	subText.Size = UDim2.new(0, 500, 0, 20)
	subText.Font = Enum.Font.Gotham
	subText.TextSize = 14
	subText.TextColor3 = Color3.fromRGB(148, 163, 184)
	subText.BackgroundTransparency = 1
	subText.TextXAlignment = Enum.TextXAlignment.Left

	local line = Instance.new("Frame", header)
	line.Size = UDim2.new(1, -60, 0, 1)
	line.Position = UDim2.new(0, 30, 1, 0)
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BackgroundTransparency = 0.9

	local contentFrame = Instance.new("Frame", container)
	contentFrame.Size = UDim2.new(1, 0, 1, -80)
	contentFrame.Position = UDim2.new(0, 0, 0, 80)
	contentFrame.BackgroundTransparency = 1

	-- Left Column
	local leftCol = Instance.new("Frame", contentFrame)
	leftCol.Size = UDim2.new(0.4, 0, 1, 0)
	leftCol.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	leftCol.BackgroundTransparency = 0.8
	leftCol.BorderSizePixel = 0

	local newTag = Instance.new("TextLabel", leftCol)
	newTag.Text = "BARU"
	newTag.Size = UDim2.new(0, 60, 0, 24)
	newTag.Position = UDim2.new(1, -80, 0, 20)
	newTag.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	newTag.TextColor3 = Color3.fromRGB(0, 0, 0)
	newTag.Font = Enum.Font.GothamBold
	newTag.TextSize = 12

	local newTagCorner = Instance.new("UICorner", newTag)
	newTagCorner.CornerRadius = UDim.new(0, 6)

	local newWepName = Instance.new("TextLabel", leftCol)
	newWepName.Text = newName:upper()
	newWepName.Size = UDim2.new(0.8, 0, 0, 40)
	newWepName.Position = UDim2.new(0.1, 0, 0.4, 0)
	newWepName.BackgroundTransparency = 1
	newWepName.TextColor3 = Color3.fromRGB(255, 255, 255)
	newWepName.Font = Enum.Font.GothamBlack
	newWepName.TextSize = 32
	newWepName.TextXAlignment = Enum.TextXAlignment.Left

	-- 3D Preview for New Weapon
	local previewFrame = Instance.new("Frame", leftCol)
	previewFrame.Size = UDim2.new(0.8, 0, 0.3, 0)
	previewFrame.Position = UDim2.new(0.1, 0, 0.05, 0)
	previewFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	previewFrame.BackgroundTransparency = 0.95

	local previewCorner = Instance.new("UICorner", previewFrame)
	previewCorner.CornerRadius = UDim.new(0, 16)

	createWeaponViewport(newName, previewFrame)

	-- Stats Panel
	local statsPanel = Instance.new("Frame", leftCol)
	statsPanel.Size = UDim2.new(0.8, 0, 0.35, 0)
	statsPanel.Position = UDim2.new(0.1, 0, 0.55, 0)
	statsPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	statsPanel.BackgroundTransparency = 0.6

	local statsCorner = Instance.new("UICorner", statsPanel)
	statsCorner.CornerRadius = UDim.new(0, 12)

	local statsList = Instance.new("UIListLayout", statsPanel)
	statsList.Padding = UDim.new(0, 10)
	statsList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsList.VerticalAlignment = Enum.VerticalAlignment.Center

	local statsPadding = Instance.new("UIPadding", statsPanel)
	statsPadding.PaddingTop = UDim.new(0, 15)
	statsPadding.PaddingBottom = UDim.new(0, 15)
	statsPadding.PaddingLeft = UDim.new(0, 15)
	statsPadding.PaddingRight = UDim.new(0, 15)

	local newStats = WeaponModule.Weapons[newName] or {}
	local nDmg = newStats.Damage or 0
	local nRpm = (newStats.FireRate and newStats.FireRate > 0) and math.floor(60 / newStats.FireRate) or 0
	local nAmmo = newStats.MaxAmmo or 0

	createStatBar(statsPanel, "DAMAGE", nDmg, 150, Color3.fromRGB(248, 113, 113))
	createStatBar(statsPanel, "FIRE RATE", nRpm, 1200, Color3.fromRGB(96, 165, 250))
	createStatBar(statsPanel, "MAGAZINE", nAmmo, 100, Color3.fromRGB(74, 222, 128))

	-- Right Column
	local rightCol = Instance.new("Frame", contentFrame)
	rightCol.Size = UDim2.new(0.6, 0, 1, 0)
	rightCol.Position = UDim2.new(0.4, 0, 0, 0)
	rightCol.BackgroundTransparency = 1

	local rightPadding = Instance.new("UIPadding", rightCol)
	rightPadding.PaddingTop = UDim.new(0, 20)
	rightPadding.PaddingLeft = UDim.new(0, 30)
	rightPadding.PaddingRight = UDim.new(0, 30)
	rightPadding.PaddingBottom = UDim.new(0, 20)

	local chooseLabel = Instance.new("TextLabel", rightCol)
	chooseLabel.Text = "PILIH SENJATA UNTUK DIGANTI"
	chooseLabel.Size = UDim2.new(1, 0, 0, 20)
	chooseLabel.Font = Enum.Font.GothamBold
	chooseLabel.TextSize = 14
	chooseLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	chooseLabel.BackgroundTransparency = 1
	chooseLabel.TextXAlignment = Enum.TextXAlignment.Left

	local scroll = Instance.new("ScrollingFrame", rightCol)
	scroll.Size = UDim2.new(1, 0, 1, -100)
	scroll.Position = UDim2.new(0, 0, 0, 40)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

	local scrollLayout = Instance.new("UIListLayout", scroll)
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

	cardButtons = {} -- Reset

	-- Buttons Container
	local btnContainer = Instance.new("Frame", rightCol)
	btnContainer.Size = UDim2.new(1, 0, 0, 50)
	btnContainer.Position = UDim2.new(0, 0, 1, -50)
	btnContainer.BackgroundTransparency = 1

	local discardBtn = Instance.new("TextButton", btnContainer)
	discardBtn.Text = "BUANG BARU"
	discardBtn.Size = UDim2.new(0.48, 0, 1, 0)
	discardBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	discardBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	discardBtn.Font = Enum.Font.GothamBold
	discardBtn.TextSize = 16
	discardBtnRef = discardBtn

	local discardCorner = Instance.new("UICorner", discardBtn)
	discardCorner.CornerRadius = UDim.new(0, 12)
	local discardStroke = Instance.new("UIStroke", discardBtn)
	discardStroke.Color = Color3.fromRGB(71, 85, 105)
	discardStroke.Thickness = 1

	discardBtn.MouseButton1Click:Connect(function()
		blur:Destroy()
		closeReplaceUI(true)
	end)

	local replaceBtn = Instance.new("TextButton", btnContainer)
	replaceBtn.Text = "GANTI TERPILIH"
	replaceBtn.Size = UDim2.new(0.48, 0, 1, 0)
	replaceBtn.Position = UDim2.new(0.52, 0, 0, 0)
	replaceBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	replaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	replaceBtn.Font = Enum.Font.GothamBold
	replaceBtn.TextSize = 16
	replaceBtn.AutoButtonColor = true
	replaceBtn.BackgroundTransparency = 0.5
	replaceBtn.TextTransparency = 0.5
	replaceBtn.Active = false
	replaceBtnRef = replaceBtn

	local replaceCorner = Instance.new("UICorner", replaceBtn)
	replaceCorner.CornerRadius = UDim.new(0, 12)

	-- Update Selection Function
	local function updateSelection(idx, clickedBtn)
		currentSelectionIndex = idx

		for _, btn in ipairs(cardButtons) do
			local isSelected = (btn == clickedBtn)
			local s = btn:FindFirstChild("UIStroke")
			if s then
				s.Color = isSelected and Color3.fromRGB(239, 68, 68) or Color3.fromRGB(71, 85, 105)
				s.Thickness = isSelected and 2 or 1
				s.Transparency = isSelected and 0 or 0.5
			end
			btn.BackgroundColor3 = isSelected and Color3.fromRGB(60, 20, 20) or Color3.fromRGB(30, 41, 59)
		end

		replaceBtn.BackgroundTransparency = 0
		replaceBtn.TextTransparency = 0
		replaceBtn.Active = true
	end

	replaceBtn.MouseButton1Click:Connect(function()
		if currentSelectionIndex ~= -1 then
			replaceChoiceEv:FireServer(currentSelectionIndex)
			blur:Destroy()
			closeReplaceUI(false)
		end
	end)

	-- Keyboard Input Handling
	local function handleInput(actionName, inputState, inputObject)
		if inputState ~= Enum.UserInputState.Begin then return end

		if actionName == ACTION_NAV_UP then
			if #cardButtons == 0 then return end
			local nextIdx = -1
			-- Find current visual index
			local visualIndex = 0
			for i, btn in ipairs(cardButtons) do
				local idx = btn:GetAttribute("ItemIndex")
				if idx == currentSelectionIndex then
					visualIndex = i
					break
				end
			end

			if visualIndex <= 1 then
				visualIndex = #cardButtons
			elseif visualIndex == 0 then
				visualIndex = 1
			else
				visualIndex = visualIndex - 1
			end

			local targetBtn = cardButtons[visualIndex]
			if targetBtn then
				updateSelection(targetBtn:GetAttribute("ItemIndex"), targetBtn)
			end

		elseif actionName == ACTION_NAV_DOWN then
			if #cardButtons == 0 then return end
			local visualIndex = 0
			for i, btn in ipairs(cardButtons) do
				local idx = btn:GetAttribute("ItemIndex")
				if idx == currentSelectionIndex then
					visualIndex = i
					break
				end
			end

			if visualIndex >= #cardButtons then
				visualIndex = 1
			elseif visualIndex == 0 then
				visualIndex = 1
			else
				visualIndex = visualIndex + 1
			end

			local targetBtn = cardButtons[visualIndex]
			if targetBtn then
				updateSelection(targetBtn:GetAttribute("ItemIndex"), targetBtn)
			end

		elseif actionName == ACTION_SELECT then
			if replaceBtn.Active and currentSelectionIndex ~= -1 then
				replaceChoiceEv:FireServer(currentSelectionIndex)
				blur:Destroy()
				closeReplaceUI(false)
			end

		elseif actionName == ACTION_DISCARD then
			blur:Destroy()
			closeReplaceUI(true)
		end
	end

	local function bindInput()
		-- Fix: Use BindActionAtPriority to ensure we capture input over movement controls
		ContextActionService:BindActionAtPriority(ACTION_NAV_UP, handleInput, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Up, Enum.KeyCode.W)
		ContextActionService:BindActionAtPriority(ACTION_NAV_DOWN, handleInput, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Down, Enum.KeyCode.S)
		ContextActionService:BindActionAtPriority(ACTION_SELECT, handleInput, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Return, Enum.KeyCode.Space, Enum.KeyCode.KeypadEnter)
		ContextActionService:BindActionAtPriority(ACTION_DISCARD, handleInput, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Backspace, Enum.KeyCode.Delete)
	end

	-- Generate Cards
	local newWeaponOriginalIndex = -1
	for i = #currentNames, 1, -1 do
		if currentNames[i] == newName then
			newWeaponOriginalIndex = i
			break
		end
	end

	for i, name in ipairs(currentNames) do
		if i ~= newWeaponOriginalIndex then
			local btn = createWeaponCard(scroll, name, i, newStats, updateSelection)
			btn:SetAttribute("ItemIndex", i)
			table.insert(cardButtons, btn)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, #cardButtons * 90)

	-- Animation Sequence
	task.spawn(function()
		-- Shake
		local originalPos = crateBox.Position
		for i = 1, 20 do
			local offset = Vector2.new(math.random(-5, 5), math.random(-5, 5))
			crateBox.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + offset.X, originalPos.Y.Scale, originalPos.Y.Offset + offset.Y)
			task.wait(0.05)
		end
		crateBox.Position = originalPos

		-- Reveal
		TweenService:Create(crateBox, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1}):Play()
		TweenService:Create(qMark, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		TweenService:Create(openingText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		task.wait(0.3)

		crateUIFrame.Visible = false

		-- Show Overlay
		replaceUIOverlay.Visible = true
		replaceUIOverlay.Size = UDim2.new(0.9, 0, 0.9, 0)
		TweenService:Create(replaceUIOverlay, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()

		-- Bind keys now that UI is visible
		bindInput()

		-- Auto-select first card if available
		if #cardButtons > 0 then
			updateSelection(cardButtons[1]:GetAttribute("ItemIndex"), cardButtons[1])
		end
	end)
end

openReplaceUI.OnClientEvent:Connect(function(currentNames, newName, cost, hasDiscount)
	if isUIOpen then return end
	showReplaceUI(currentNames, newName, cost, hasDiscount)
end)

local function purchaseRandomWeapon()
	if isUIOpen then return end
	local ok, result = pcall(function() return purchaseRF:InvokeServer() end)
	if not ok then
		showNotification("Purchase error", Color3.fromRGB(255, 100, 100), 2)
		return
	end

	if type(result) == "table" then
		if result.success == true then
			showNotification("You got: " .. (result.weaponName or "Weapon"), Color3.fromRGB(100, 255, 100), 3)
		elseif result.success == false and result.message == "Not enough points" then
			showNotification("Poin tidak cukup", Color3.fromRGB(255, 100, 100), 3)
		elseif result.success == false and result.message == "choose" then
			-- Handled by event
		else
			showNotification(result.message or "Purchase failed", Color3.fromRGB(255, 100, 100), 3)
		end
	end
end

-- Register Proximity Interaction via Module
local randomPart = workspace:WaitForChild("Random", 5)
local promptHandler = nil

if randomPart then
	promptHandler = ProximityUIHandler.Register({
		name = "RandomWeaponShop",
		partName = "Random",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			purchaseRandomWeapon()
			-- Reset the handler state because this isn't a persistent UI toggle
			-- The function executes an action and finishes.
			if promptHandler then promptHandler:SetOpen(false) end
		end
	})

	-- Cost Updater
	task.spawn(function()
		local attachment = randomPart:WaitForChild("Attachment", 10)
		if attachment then
			local prompt = attachment:WaitForChild("RandomPrompt", 10)
			if not prompt then return end

			while task.wait(1) do
				local success, cost = pcall(function()
					return getCostRF:InvokeServer()
				end)
				if success and cost then
					prompt.ObjectText = "Beli Senjata Acak (Harga: " .. cost .. ")"
				else
					prompt.ObjectText = "Beli Senjata Acak"
				end
			end
		end
	end)
end

-- Close on distance
RunService.RenderStepped:Connect(function()
	if isUIOpen then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and randomPart then
			local dist = (char.HumanoidRootPart.Position - randomPart.Position).Magnitude
			if dist > 10 then
				if replaceUIOverlay then
					closeReplaceUI(true)
				end
			end
		end
	end
end)

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
