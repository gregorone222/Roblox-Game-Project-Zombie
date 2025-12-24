-- ViewmodelEditorPlugin.lua
-- A Roblox Studio Plugin for editing Viewmodel Position, Rotation, and ADS in real-time
-- Save this file to: %localappdata%\Roblox\Plugins\ViewmodelEditorPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Viewmodel Editor")
local toggleButton = toolbar:CreateButton(
	"Viewmodel Editor",
	"Edit viewmodel position, rotation, and ADS in real-time",
	"rbxassetid://6031071053"
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	420,
	900,
	350,
	600
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("ViewmodelEditorWidget", widgetInfo)
widget.Title = "Viewmodel Editor"

-- State
local isActive = false
local currentWeaponName = nil
local targetWeaponName = nil -- Target weapon to apply settings to
local currentSkinName = "Default Skin"
local currentTool = nil
local previewModel = nil
local renderConnection = nil
local selectedAnimState = "Idle" -- Current animation being edited (Idle, Run, ADS, Reload)
local isMobilePreview = false
local showHitmarker = false
local hitmarkerGui = nil
local currentWeaponAnimations = nil
local currentAnimTrack = nil

-- Handles for visual positioning
local showHandles = false
local moveHandles = nil
local rotateHandles = nil
local handlesPart = nil -- Invisible part for handles to attach

-- ViewportFrame Preview
local viewportFrame = nil
local viewportCamera = nil
local viewportModel = nil
local viewportAnimator = nil
local viewportAnimTrack = nil

-- Mobile Aspect Ratio Overlay
local mobileOverlayGui = nil
local mobileOverlayConnection = nil
local selectedDeviceRatio = "16:9" -- Default: Phone Landscape
local DEVICE_RATIOS = {
	["Full"] = nil, -- No overlay
	["16:9"] = 16/9,  -- Standard Phone Landscape
	["19.5:9"] = 19.5/9,  -- Modern Wide Phone
	["4:3"] = 4/3,  -- Tablet
}

-- Animation list for selector
local ANIM_STATES = {"Idle", "Run", "ADS", "Reload"}
local currentAnimIndex = 1

-- Values (single set for current animation)
local posX, posY, posZ = 1.5, -1, -2.5
local rotX, rotY, rotZ = 0, 0, 0

-- Presets
local PRESETS_KEY = "ViewmodelEditor_Presets"
local presets = plugin:GetSetting(PRESETS_KEY) or {}

-- UI Creation
local function createUI()
	local statusLabel -- Forward declaration for anim logic
	-- Main ScrollingFrame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "MainScroll"
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = widget

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder -- Ensure sorting by order
	layout.Parent = scrollFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = scrollFrame

	-- Section Header Helper
	local function createSectionHeader(text, parent, order)
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 25)
		header.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		header.Text = text
		header.TextColor3 = Color3.new(1, 1, 1)
		header.TextSize = 14
		header.Font = Enum.Font.GothamBold
		header.LayoutOrder = order -- Set order
		header.Parent = parent
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = header
		
		return header
	end

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "Viewmodel & ADS Editor"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.LayoutOrder = 1
	title.Parent = scrollFrame

	-- Selected Weapon Display
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 22)
	selectedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	selectedLabel.TextSize = 13
	selectedLabel.Font = Enum.Font.GothamMedium
	selectedLabel.LayoutOrder = 2
	selectedLabel.Parent = scrollFrame
	
	-- ViewportFrame Preview Container
	local viewportContainer = Instance.new("Frame")
	viewportContainer.Name = "ViewportContainer"
	viewportContainer.Size = UDim2.new(1, -10, 0, 220)
	viewportContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	viewportContainer.LayoutOrder = 2.5
	viewportContainer.Parent = scrollFrame
	Instance.new("UICorner", viewportContainer).CornerRadius = UDim.new(0, 6)
	
	local viewportHeader = Instance.new("TextLabel")
	viewportHeader.Size = UDim2.new(1, 0, 0, 20)
	viewportHeader.BackgroundTransparency = 1
	viewportHeader.Text = "🔍 First-Person Preview"
	viewportHeader.TextColor3 = Color3.fromRGB(180, 180, 180)
	viewportHeader.TextSize = 11
	viewportHeader.Font = Enum.Font.GothamMedium
	viewportHeader.Parent = viewportContainer
	
	local vpFrame = Instance.new("ViewportFrame")
	vpFrame.Name = "ViewportPreview"
	vpFrame.Size = UDim2.new(1, -10, 1, -25)
	vpFrame.Position = UDim2.new(0, 5, 0, 22)
	vpFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	vpFrame.BorderSizePixel = 0
	vpFrame.Ambient = Color3.fromRGB(150, 150, 150)
	vpFrame.LightColor = Color3.fromRGB(255, 255, 255)
	vpFrame.LightDirection = Vector3.new(-1, -1, -1)
	vpFrame.Parent = viewportContainer
	Instance.new("UICorner", vpFrame).CornerRadius = UDim.new(0, 4)
	
	-- Add WorldModel for animation support (required for Motor6D animations!)
	local vpWorldModel = Instance.new("WorldModel")
	vpWorldModel.Name = "WorldModel"
	vpWorldModel.Parent = vpFrame
	
	-- Add Crosshair to Viewport
	local crosshairContainer = Instance.new("Frame")
	crosshairContainer.Name = "Crosshair"
	crosshairContainer.Size = UDim2.new(1, 0, 1, 0)
	crosshairContainer.BackgroundTransparency = 1
	crosshairContainer.Parent = vpFrame
	
	local crosshairColor = Color3.new(1, 1, 1)
	local lineThickness = 2
	local lineLength = 12
	local gap = 5
	
	-- Top line
	local topLine = Instance.new("Frame")
	topLine.Size = UDim2.new(0, lineThickness, 0, lineLength)
	topLine.Position = UDim2.new(0.5, -1, 0.5, -lineLength - gap)
	topLine.BackgroundColor3 = crosshairColor
	topLine.BorderSizePixel = 0
	topLine.Parent = crosshairContainer
	
	-- Bottom line
	local bottomLine = Instance.new("Frame")
	bottomLine.Size = UDim2.new(0, lineThickness, 0, lineLength)
	bottomLine.Position = UDim2.new(0.5, -1, 0.5, gap)
	bottomLine.BackgroundColor3 = crosshairColor
	bottomLine.BorderSizePixel = 0
	bottomLine.Parent = crosshairContainer
	
	-- Left line
	local leftLine = Instance.new("Frame")
	leftLine.Size = UDim2.new(0, lineLength, 0, lineThickness)
	leftLine.Position = UDim2.new(0.5, -lineLength - gap, 0.5, -1)
	leftLine.BackgroundColor3 = crosshairColor
	leftLine.BorderSizePixel = 0
	leftLine.Parent = crosshairContainer
	
	-- Right line
	local rightLine = Instance.new("Frame")
	rightLine.Size = UDim2.new(0, lineLength, 0, lineThickness)
	rightLine.Position = UDim2.new(0.5, gap, 0.5, -1)
	rightLine.BackgroundColor3 = crosshairColor
	rightLine.BorderSizePixel = 0
	rightLine.Parent = crosshairContainer
	
	-- Create camera for viewport
	local vpCamera = Instance.new("Camera")
	vpCamera.FieldOfView = 70
	vpCamera.CFrame = CFrame.new(0, 0, 0)
	vpCamera.Parent = vpFrame
	vpFrame.CurrentCamera = vpCamera
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, 0, 0, 35)
	toggleFrame.BackgroundTransparency = 1
	toggleFrame.LayoutOrder = 3
	toggleFrame.Parent = scrollFrame

	local toggleLayout = Instance.new("UIListLayout")
	toggleLayout.FillDirection = Enum.FillDirection.Horizontal
	toggleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toggleLayout.Padding = UDim.new(0, 10)
	toggleLayout.Parent = toggleFrame

	-- Animation Selector (replaces ADS Toggle)
	local animSelector = Instance.new("TextButton")
	animSelector.Name = "AnimSelector"
	animSelector.Size = UDim2.new(0, 100, 0, 30)
	animSelector.BackgroundColor3 = Color3.fromRGB(70, 100, 150)
	animSelector.Text = "Anim: Idle"
	animSelector.TextColor3 = Color3.new(1, 1, 1)
	animSelector.TextSize = 11
	animSelector.Font = Enum.Font.GothamMedium
	animSelector.Parent = toggleFrame
	Instance.new("UICorner", animSelector).CornerRadius = UDim.new(0, 4)

	local mobileToggle = Instance.new("TextButton")
	mobileToggle.Name = "MobileToggle"
	mobileToggle.Size = UDim2.new(0, 100, 0, 30)
	mobileToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	mobileToggle.Text = "Mode: Desktop"
	mobileToggle.TextColor3 = Color3.new(1, 1, 1)
	mobileToggle.TextSize = 11
	mobileToggle.Font = Enum.Font.GothamMedium
	mobileToggle.Parent = toggleFrame
	Instance.new("UICorner", mobileToggle).CornerRadius = UDim.new(0, 4)

	local hitmarkerToggle = Instance.new("TextButton")
	hitmarkerToggle.Name = "HitmarkerToggle"
	hitmarkerToggle.Size = UDim2.new(0, 80, 0, 30)
	hitmarkerToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	hitmarkerToggle.Text = "Crosshair"
	hitmarkerToggle.TextColor3 = Color3.new(1, 1, 1)
	hitmarkerToggle.TextSize = 11
	hitmarkerToggle.Font = Enum.Font.GothamMedium
	hitmarkerToggle.Parent = toggleFrame
	Instance.new("UICorner", hitmarkerToggle).CornerRadius = UDim.new(0, 4)
	
	-- Handles Toggle Button
	local handlesToggle = Instance.new("TextButton")
	handlesToggle.Name = "HandlesToggle"
	handlesToggle.Size = UDim2.new(0, 70, 0, 30)
	handlesToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	handlesToggle.Text = "📐 Handles"
	handlesToggle.TextColor3 = Color3.new(1, 1, 1)
	handlesToggle.TextSize = 10
	handlesToggle.Font = Enum.Font.GothamMedium
	handlesToggle.Parent = toggleFrame
	Instance.new("UICorner", handlesToggle).CornerRadius = UDim.new(0, 4)

	-- Device Ratio Frame (Second Row)
	local deviceFrame = Instance.new("Frame")
	deviceFrame.Size = UDim2.new(1, 0, 0, 35)
	deviceFrame.BackgroundTransparency = 1
	deviceFrame.LayoutOrder = 4
	deviceFrame.Parent = scrollFrame
	
	local deviceLayout = Instance.new("UIListLayout")
	deviceLayout.FillDirection = Enum.FillDirection.Horizontal
	deviceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	deviceLayout.Padding = UDim.new(0, 8)
	deviceLayout.Parent = deviceFrame
	
	local deviceLabel = Instance.new("TextLabel")
	deviceLabel.Size = UDim2.new(0, 80, 0, 30)
	deviceLabel.BackgroundTransparency = 1
	deviceLabel.Text = "📱 Device:"
	deviceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	deviceLabel.TextSize = 11
	deviceLabel.Font = Enum.Font.Gotham
	deviceLabel.Parent = deviceFrame
	
	local deviceButtons = {}
	local deviceOrder = {"Full", "16:9", "19.5:9", "4:3"}
	local deviceNames = {["Full"] = "Full", ["16:9"] = "Phone", ["19.5:9"] = "Wide", ["4:3"] = "Tablet"}
	
	local function updateDeviceButtons()
		for ratio, btn in pairs(deviceButtons) do
			if ratio == selectedDeviceRatio then
				btn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
			else
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			end
		end
	end
	
	for _, ratio in ipairs(deviceOrder) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 55, 0, 28)
		btn.BackgroundColor3 = ratio == selectedDeviceRatio and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 60)
		btn.Text = deviceNames[ratio]
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 10
		btn.Font = Enum.Font.GothamMedium
		btn.Parent = deviceFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		deviceButtons[ratio] = btn
	end

	-- Slider Helper
	-- Animation Section
	createSectionHeader("🎬 Animations", scrollFrame, 5)
	
	local animFrame = Instance.new("Frame")
	animFrame.Size = UDim2.new(1, 0, 0, 35)
	animFrame.BackgroundTransparency = 1
	animFrame.LayoutOrder = 6
	animFrame.Parent = scrollFrame
	
	local animLayout = Instance.new("UIListLayout")
	animLayout.FillDirection = Enum.FillDirection.Horizontal
	animLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	animLayout.Padding = UDim.new(0, 5)
	animLayout.Parent = animFrame
	
	local function playPreviewAnim(animKey)
		print("[ViewmodelEditor] playPreviewAnim called with key:", animKey)
		
		if currentAnimTrack then
			currentAnimTrack:Stop()
			currentAnimTrack = nil
		end
		
		if animKey == "Stop" then 
			if statusLabel then statusLabel.Text = "Stopped Animation" end
			return 
		end
		
		if not viewportModel then 
			print("[ViewmodelEditor] ERROR: viewportModel is nil")
			if statusLabel then statusLabel.Text = "No preview model! Select a weapon." end
			return 
		end
		
		if not currentWeaponAnimations then 
			print("[ViewmodelEditor] ERROR: currentWeaponAnimations is nil")
			if statusLabel then statusLabel.Text = "Select weapon first!" end
			return 
		end
		
		local animData = (animKey == "Aim") and currentWeaponAnimations.ADS or currentWeaponAnimations[animKey]
		
		-- Extract animation ID from new per-animation structure (table with Id) or legacy format (string)
		local animId
		if type(animData) == "table" then
			animId = animData.Id
		elseif type(animData) == "string" then
			animId = animData
		end
		
		print("[ViewmodelEditor] Animation ID for", animKey, ":", animId)
		
		if not animId then
			if statusLabel then statusLabel.Text = "No " .. animKey .. " animation!" end
			return
		end
		
		-- Use viewport animator
		if not viewportAnimator then
			local animController = viewportModel:FindFirstChildOfClass("AnimationController")
			if animController then
				viewportAnimator = animController:FindFirstChildOfClass("Animator")
				if not viewportAnimator then
					viewportAnimator = Instance.new("Animator")
					viewportAnimator.Parent = animController
				end
			end
		end
		
		if not viewportAnimator then
			print("[ViewmodelEditor] ERROR: No animator available")
			return
		end
		
		-- Create Animation object
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		
		-- Preload animation asset (important for Edit Mode!)
		if statusLabel then statusLabel.Text = "Preloading animation..." end
		local ContentProvider = game:GetService("ContentProvider")
		local preloadSuccess, preloadErr = pcall(function()
			ContentProvider:PreloadAsync({anim})
		end)
		if not preloadSuccess then
			print("[ViewmodelEditor] Preload warning:", preloadErr)
		else
			print("[ViewmodelEditor] Animation preloaded successfully")
		end
		
		-- Stop any existing tracks on this animator
		for _, t in pairs(viewportAnimator:GetPlayingAnimationTracks()) do 
			t:Stop() 
		end
		
		-- Load and play animation
		local success, track = pcall(function()
			return viewportAnimator:LoadAnimation(anim)
		end)
		
		if not success then
			print("[ViewmodelEditor] ERROR loading animation:", track)
			if statusLabel then statusLabel.Text = "Error: " .. tostring(track) end
			return
		end
		
		-- Debug: Check track validity
		print("[ViewmodelEditor] Animation Track loaded successfully")
		print("[ViewmodelEditor] Track.Length:", track.Length)
		
		-- If track length is 0, it might mean the rig doesn't match the animation
		if track.Length == 0 then
			print("[ViewmodelEditor] ============================================")
			print("[ViewmodelEditor] WARNING: Track.Length is 0!")
			print("[ViewmodelEditor] Possible causes:")
			print("  1. Animation bone names don't match rig bone names")
			print("  2. Animation was made for R15 but rig is custom arms-only")
			print("  3. Animation asset not accessible (ownership/permissions)")
			print("  4. Running in Edit Mode - try Play Solo instead")
			print("[ViewmodelEditor] ============================================")
			print("[ViewmodelEditor] TIP: Try running Play Solo (F5) and test animation")
			print("[ViewmodelEditor] in-game instead of in Edit Mode plugin.")
			if statusLabel then 
				statusLabel.Text = "⚠️ Anim may not work in Edit Mode. Try Play Solo (F5)" 
			end
		end
		
		track.Looped = true
		track:Play()
		currentAnimTrack = track
		print("[ViewmodelEditor] Animation playing!")
		if track.Length > 0 then
			if statusLabel then statusLabel.Text = "Playing: " .. animKey .. " (Length: " .. string.format("%.2f", track.Length) .. "s)" end
		end
	end
	
	local function createAnimBtn(text, key)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 55, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 10
		btn.Parent = animFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		
		btn.MouseButton1Click:Connect(function()
			playPreviewAnim(key)
		end)
	end
	
	createAnimBtn("Idle", "Idle")
	createAnimBtn("Run", "Run")
	createAnimBtn("Aim", "Aim") 
	createAnimBtn("Stop", "Stop")

	local function getAllWeaponNames()
		local names = {}
		local mod = game.ReplicatedStorage:FindFirstChild("ModuleScript")
		if mod then mod = mod:FindFirstChild("WeaponModule") end
		if not mod then mod = game.ReplicatedStorage:FindFirstChild("WeaponModule", true) end
		
		if mod then
			local success, res = pcall(function() return require(mod) end)
			if success and res and res.Weapons then
				for k in pairs(res.Weapons) do table.insert(names, k) end
				table.sort(names)
			end
		end
		return names
	end

	local function createDropdown(name, label, textCallback, parent, order)
		local group = Instance.new("Frame")
		group.Name = name .. "Group"
		group.Size = UDim2.new(1, 0, 0, 40)
		group.BackgroundTransparency = 1
		group.LayoutOrder = order
		group.Parent = parent

		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.new(1, 0, 0, 14)
		labelText.BackgroundTransparency = 1
		labelText.Text = label
		labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
		labelText.TextSize = 11
		labelText.Font = Enum.Font.Gotham
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Parent = group

		local mainBtn = Instance.new("TextButton")
		mainBtn.Size = UDim2.new(1, 0, 0, 24)
		mainBtn.Position = UDim2.new(0, 0, 0, 16)
		mainBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		mainBtn.TextColor3 = Color3.new(1, 1, 1)
		mainBtn.Text = targetWeaponName or "Select Weapon..."
		mainBtn.TextSize = 12
		mainBtn.Font = Enum.Font.Gotham
		mainBtn.Parent = group
		Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)
		
		local dropdownList = nil
		local isOpen = false
		
		local function closeDropdown()
			if dropdownList then dropdownList:Destroy() dropdownList = nil end
			isOpen = false
		end
		
		mainBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			if isOpen then
				local weapons = getAllWeaponNames()
				-- Create overlay list
				dropdownList = Instance.new("ScrollingFrame")
				dropdownList.Name = "DropdownList"
				dropdownList.Size = UDim2.new(1, 0, 0, 150)
				dropdownList.Position = UDim2.new(0, 0, 1, 2)
				dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				dropdownList.BorderSizePixel = 0
				dropdownList.ZIndex = 10
				dropdownList.Parent = mainBtn
				
				local listLayout = Instance.new("UIListLayout")
				listLayout.Parent = dropdownList
				listLayout.Padding = UDim.new(0, 2)
				
				local count = 0
				for _, wName in ipairs(weapons) do
					count = count + 1
					local item = Instance.new("TextButton")
					item.Size = UDim2.new(1, 0, 0, 25)
					item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					item.Text = wName
					item.TextColor3 = Color3.new(1,1,1)
					item.ZIndex = 11
					item.Parent = dropdownList
					
					item.MouseButton1Click:Connect(function()
						targetWeaponName = wName
						mainBtn.Text = wName
						textCallback(wName)
						closeDropdown()
					end)
				end
				dropdownList.CanvasSize = UDim2.new(0,0,0, count * 27)
			else
				closeDropdown()
			end
		end)
		
		return {
			UpdateText = function(txt)
				mainBtn.Text = txt
			end
		}
	end

	local function createSliderGroup(name, label, min, max, default, step, callback, parent, order)
		local group = Instance.new("Frame")
		group.Name = name .. "Group"
		group.Size = UDim2.new(1, 0, 0, 40)
		group.BackgroundTransparency = 1
		group.LayoutOrder = order -- Set order
		group.Parent = parent

		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.new(1, 0, 0, 14)
		labelText.BackgroundTransparency = 1
		labelText.Text = label
		labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
		labelText.TextSize = 11
		labelText.Font = Enum.Font.Gotham
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Parent = group

		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, 0, 0, 22)
		sliderFrame.Position = UDim2.new(0, 0, 0, 16)
		sliderFrame.BackgroundTransparency = 1
		sliderFrame.Parent = group

		local slider = Instance.new("Frame")
		slider.Name = "SliderTrack"
		slider.Size = UDim2.new(0.7, 0, 0, 6)
		slider.Position = UDim2.new(0, 0, 0.5, -3)
		slider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		slider.BorderSizePixel = 0
		slider.Parent = sliderFrame
		Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 3)

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		fill.BorderSizePixel = 0
		fill.Parent = slider
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

		local inputBox = Instance.new("TextBox")
		inputBox.Name = "ValueInput"
		inputBox.Size = UDim2.new(0.25, -5, 1, 0)
		inputBox.Position = UDim2.new(0.75, 5, 0, 0)
		inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		inputBox.TextColor3 = Color3.new(1, 1, 1)
		inputBox.Text = string.format("%.3f", default)
		inputBox.TextSize = 12
		inputBox.Font = Enum.Font.Gotham
		inputBox.Parent = sliderFrame
		Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 3)

		local dragging = false

		slider.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
			end
		end)

		slider.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		slider.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local relativeX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
				local value = min + relativeX * (max - min)
				value = math.floor(value / step + 0.5) * step
				fill.Size = UDim2.new(relativeX, 0, 1, 0)
				inputBox.Text = string.format("%.3f", value)
				callback(value)
			end
		end)

		inputBox.FocusLost:Connect(function()
			local value = tonumber(inputBox.Text)
			if value then
				value = math.clamp(value, min, max)
				value = math.floor(value / step + 0.5) * step
				inputBox.Text = string.format("%.3f", value)
				fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
				callback(value)
			else
				inputBox.Text = string.format("%.3f", default)
			end
		end)

		return {
			SetValue = function(val)
				val = math.clamp(val, min, max)
				inputBox.Text = string.format("%.3f", val)
				fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
			end
		}
	end

	-- ===== VIEWMODEL SECTION =====
	createSectionHeader("📍 Viewmodel Position", scrollFrame, 10)
	local posXSlider = createSliderGroup("PosX", "X", -5, 5, posX, 0.001, function(v) posX = v end, scrollFrame, 11)
	local posYSlider = createSliderGroup("PosY", "Y", -5, 5, posY, 0.001, function(v) posY = v end, scrollFrame, 12)
	local posZSlider = createSliderGroup("PosZ", "Z", -10, 0, posZ, 0.001, function(v) posZ = v end, scrollFrame, 13)

	createSectionHeader("🔄 Viewmodel Rotation", scrollFrame, 20)
	local rotXSlider = createSliderGroup("RotX", "X (deg)", -180, 180, rotX, 1, function(v) rotX = v end, scrollFrame, 21)
	local rotYSlider = createSliderGroup("RotY", "Y (deg)", -180, 180, rotY, 1, function(v) rotY = v end, scrollFrame, 22)
	local rotZSlider = createSliderGroup("RotZ", "Z (deg)", -180, 180, rotZ, 1, function(v) rotZ = v end, scrollFrame, 23)

	-- ADS sliders REMOVED - positions are now per-animation
	-- Use Animation Selector to switch between animation positions

	-- ===== BUTTONS =====
	createSectionHeader("💾 Presets", scrollFrame, 70)
	
	local itemsFrame = Instance.new("Frame")
	itemsFrame.Name = "PresetsFrame"
	itemsFrame.Size = UDim2.new(1, 0, 0, 140)
	itemsFrame.BackgroundTransparency = 1
	itemsFrame.LayoutOrder = 71
	itemsFrame.Parent = scrollFrame
	
	local itemsLayout = Instance.new("UIListLayout")
	itemsLayout.FillDirection = Enum.FillDirection.Vertical
	itemsLayout.Padding = UDim.new(0, 4)
	itemsLayout.Parent = itemsFrame
	
	-- Input New Preset
	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, 0, 0, 30)
	inputFrame.BackgroundTransparency = 1
	inputFrame.Parent = itemsFrame
	
	local nameInput = Instance.new("TextBox")
	nameInput.Name = "NewPresetName"
	nameInput.Size = UDim2.new(0.7, -4, 1, 0)
	nameInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	nameInput.PlaceholderText = "Preset Name..."
	nameInput.Text = ""
	nameInput.TextColor3 = Color3.new(1, 1, 1)
	nameInput.TextSize = 12
	nameInput.Font = Enum.Font.Gotham
	nameInput.Parent = inputFrame
	Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 4)
	
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SavePresetButton"
	saveButton.Size = UDim2.new(0.3, 0, 1, 0)
	saveButton.Position = UDim2.new(0.7, 4, 0, 0)
	saveButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	saveButton.Text = "Save"
	saveButton.TextColor3 = Color3.new(1, 1, 1)
	saveButton.TextSize = 12
	saveButton.Font = Enum.Font.GothamBold
	saveButton.Parent = inputFrame
	Instance.new("UICorner", saveButton).CornerRadius = UDim.new(0, 4)
	
	-- Presets List
	local presetsList = Instance.new("ScrollingFrame")
	presetsList.Name = "PresetsList"
	presetsList.Size = UDim2.new(1, 0, 1, -34)
	presetsList.Position = UDim2.new(0, 0, 0, 34)
	presetsList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	presetsList.BorderSizePixel = 0
	presetsList.ScrollBarThickness = 4
	presetsList.Parent = itemsFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = presetsList

	createSectionHeader("💾 Actions", scrollFrame, 80)
	
	local targetSelector = createDropdown("TargetWeapon", "Target Weapon (Apply To)", function(val)
		targetWeaponName = val
	end, scrollFrame, 80) -- Order 80, same as header, will be after it due to list layout logic usually

	local applyButton = Instance.new("TextButton")
	applyButton.Name = "ApplyButton"
	applyButton.Size = UDim2.new(1, 0, 0, 35)
	applyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
	applyButton.Text = "Apply to Selected Target"
	applyButton.TextColor3 = Color3.new(1, 1, 1)
	applyButton.TextSize = 14
	applyButton.Font = Enum.Font.GothamBold
	applyButton.LayoutOrder = 81
	applyButton.Parent = scrollFrame
	Instance.new("UICorner", applyButton).CornerRadius = UDim.new(0, 6)

	local copyButton = Instance.new("TextButton")
	copyButton.Name = "CopyButton"
	copyButton.Size = UDim2.new(1, 0, 0, 30)
	copyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
	copyButton.Text = "Print Values to Output"
	copyButton.TextColor3 = Color3.new(1, 1, 1)
	copyButton.TextSize = 12
	copyButton.Font = Enum.Font.GothamMedium
	copyButton.LayoutOrder = 82
	copyButton.Parent = scrollFrame
	Instance.new("UICorner", copyButton).CornerRadius = UDim.new(0, 6)

	statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextWrapped = true
	statusLabel.LayoutOrder = 83
	statusLabel.Parent = scrollFrame

	return {
		ScrollFrame = scrollFrame,
		SelectedLabel = selectedLabel,
		StatusLabel = statusLabel,
		PresetsList = presetsList,
		PresetNameInput = nameInput,
		SavePresetButton = saveButton,
		AnimSelector = animSelector,
		MobileToggle = mobileToggle,
		ApplyButton = applyButton,
		CopyButton = copyButton,
		-- Viewmodel Position/Rotation (now per-animation)
		PosX = posXSlider, PosY = posYSlider, PosZ = posZSlider,
		RotX = rotXSlider, RotY = rotYSlider, RotZ = rotZSlider,
		HitmarkerToggle = hitmarkerToggle,
		HandlesToggle = handlesToggle,
		TargetSelector = targetSelector,
		-- ViewportFrame Preview
		ViewportFrame = vpFrame,
		ViewportCamera = vpCamera,
		ViewportWorldModel = vpWorldModel, -- For animation support
		-- Mobile Overlay
		DeviceButtons = deviceButtons,
		UpdateDeviceButtons = updateDeviceButtons
	}
end

local ui = createUI()

-- ViewportFrame Model Functions
local function clearViewportModel()
	if viewportAnimTrack then
		viewportAnimTrack:Stop()
		viewportAnimTrack = nil
	end
	if viewportModel then
		viewportModel:Destroy()
		viewportModel = nil
	end
	viewportAnimator = nil
end

local function updateViewportPosition()
	if not viewportModel then return end
	
	local offset = CFrame.new(posX, posY, posZ)
	local rotation = CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
	
	-- Position model in front of camera
	local targetCFrame = CFrame.new(0, 0, 0) * offset * rotation
	if viewportModel.PrimaryPart then
		viewportModel:PivotTo(targetCFrame)
	end
end

-- Workspace Rig System (for 3D editing)
local workspaceRig = nil
local cameraRefPart = nil
local workspaceHandles = nil
local workspaceArcHandles = nil

local function clearWorkspaceRig()
	if workspaceHandles then workspaceHandles:Destroy(); workspaceHandles = nil end
	if workspaceArcHandles then workspaceArcHandles:Destroy(); workspaceArcHandles = nil end
	if workspaceRig then workspaceRig:Destroy(); workspaceRig = nil end
	if cameraRefPart then cameraRefPart:Destroy(); cameraRefPart = nil end
end

local function loadWorkspaceRig(tool)
	clearWorkspaceRig()
	clearViewportModel()
	
	if not tool then return end
	
	-- Find ViewmodelBase
	local viewmodelBase = game.ReplicatedStorage:FindFirstChild("Assets")
	if viewmodelBase then viewmodelBase = viewmodelBase:FindFirstChild("Viewmodel") end
	if viewmodelBase then viewmodelBase = viewmodelBase:FindFirstChild("ViewmodelBase") end
	
	if not viewmodelBase then
		print("[ViewmodelEditor] ViewmodelBase not found!")
		return
	end
	
	-- Create Camera Reference Part (represents player eye)
	-- Spawn at current Studio camera position
	local studioCamera = workspace.CurrentCamera
	local spawnCFrame = CFrame.new(0, 5, 0) -- Default fallback
	if studioCamera then
		spawnCFrame = studioCamera.CFrame
	end
	
	cameraRefPart = Instance.new("Part")
	cameraRefPart.Name = "CameraRefPoint"
	cameraRefPart.Size = Vector3.new(0.5, 0.5, 0.5)
	cameraRefPart.Transparency = 0.5
	cameraRefPart.BrickColor = BrickColor.new("Bright green")
	cameraRefPart.Anchored = true
	cameraRefPart.CanCollide = false
	cameraRefPart.CFrame = spawnCFrame
	cameraRefPart.Parent = workspace
	
	-- Add label
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 100, 0, 30)
	bb.StudsOffset = Vector3.new(0, 1, 0)
	bb.AlwaysOnTop = true
	bb.Parent = cameraRefPart
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "👁 Camera"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = bb
	
	-- Clone viewmodel rig into workspace
	workspaceRig = viewmodelBase:Clone()
	workspaceRig.Name = "ViewmodelEditorRig"
	
	-- Clone weapon and attach
	local weaponClone = tool:Clone()
	weaponClone.Parent = workspaceRig
	
	local rightHand = workspaceRig:FindFirstChild("RightHand")
	local handle = weaponClone:FindFirstChild("Handle")
	
	if rightHand and handle then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rightHand
		weld.Part1 = handle
		weld.Parent = handle
		
		local gripAtt = rightHand:FindFirstChild("RightGripAttachment")
		if gripAtt then
			handle.CFrame = gripAtt.WorldCFrame
		else
			handle.CFrame = rightHand.CFrame
		end
	end
	
	-- Setup rig (remove scripts)
	for _, desc in pairs(workspaceRig:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CastShadow = true
			desc.Anchored = false
		elseif desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") then
			desc:Destroy()
		end
	end
	
	-- Destroy humanoid, use AnimationController
	local humanoid = workspaceRig:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:Destroy() end
	
	local animController = workspaceRig:FindFirstChildOfClass("AnimationController")
	if not animController then
		animController = Instance.new("AnimationController")
		animController.Parent = workspaceRig
	end
	
	viewportAnimator = animController:FindFirstChildOfClass("Animator")
	if not viewportAnimator then
		viewportAnimator = Instance.new("Animator")
		viewportAnimator.Parent = animController
	end
	
	-- Set primary part and anchor root
	local root = workspaceRig:FindFirstChild("HumanoidRootPart") or workspaceRig:FindFirstChild("Handle")
	if root then
		workspaceRig.PrimaryPart = root
		root.Anchored = true
	end
	
	-- Position rig relative to camera ref
	local offset = CFrame.new(posX, posY, posZ)
	local rotation = CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
	workspaceRig:PivotTo(cameraRefPart.CFrame * offset * rotation)
	workspaceRig.Parent = workspace
	
	-- Create Handles attached to rig
	workspaceHandles = Instance.new("Handles")
	workspaceHandles.Adornee = root
	workspaceHandles.Color3 = Color3.fromRGB(100, 200, 255)
	workspaceHandles.Style = Enum.HandlesStyle.Movement
	workspaceHandles.Parent = CoreGui
	
	-- Handle drag
	local isDragging = false
	local startCFrame = nil
	
	workspaceHandles.MouseButton1Down:Connect(function()
		isDragging = true
		startCFrame = workspaceRig:GetPivot()
	end)
	
	workspaceHandles.MouseDrag:Connect(function(face, distance)
		if not isDragging or not workspaceRig.PrimaryPart then return end
		
		local delta = Vector3.new(0, 0, 0)
		if face == Enum.NormalId.Right then delta = Vector3.new(distance, 0, 0)
		elseif face == Enum.NormalId.Left then delta = Vector3.new(-distance, 0, 0)
		elseif face == Enum.NormalId.Top then delta = Vector3.new(0, distance, 0)
		elseif face == Enum.NormalId.Bottom then delta = Vector3.new(0, -distance, 0)
		elseif face == Enum.NormalId.Front then delta = Vector3.new(0, 0, -distance)
		elseif face == Enum.NormalId.Back then delta = Vector3.new(0, 0, distance)
		end
		
		-- Calculate new position relative to camera ref
		local newCFrame = startCFrame * CFrame.new(delta)
		workspaceRig:PivotTo(newCFrame)
		
		-- Update position variables from relative offset
		local relCFrame = cameraRefPart.CFrame:ToObjectSpace(newCFrame)
		posX, posY, posZ = relCFrame.Position.X, relCFrame.Position.Y, relCFrame.Position.Z
		ui.PosX.SetValue(posX); ui.PosY.SetValue(posY); ui.PosZ.SetValue(posZ)
	end)
	
	workspaceHandles.MouseButton1Up:Connect(function()
		isDragging = false
	end)
	
	-- Create ArcHandles for rotation
	workspaceArcHandles = Instance.new("ArcHandles")
	workspaceArcHandles.Adornee = root
	workspaceArcHandles.Color3 = Color3.fromRGB(255, 150, 100)
	workspaceArcHandles.Parent = CoreGui
	
	local rotDragging = false
	local startRotCFrame = nil
	
	workspaceArcHandles.MouseButton1Down:Connect(function()
		rotDragging = true
		startRotCFrame = workspaceRig:GetPivot()
	end)
	
	workspaceArcHandles.MouseDrag:Connect(function(axis, relativeAngle)
		if not rotDragging or not workspaceRig.PrimaryPart then return end
		
		local angleDeg = math.deg(relativeAngle)
		local rotCFrame
		
		if axis == Enum.Axis.X then
			rotCFrame = startRotCFrame * CFrame.Angles(relativeAngle, 0, 0)
			rotX = angleDeg
		elseif axis == Enum.Axis.Y then
			rotCFrame = startRotCFrame * CFrame.Angles(0, relativeAngle, 0)
			rotY = angleDeg
		elseif axis == Enum.Axis.Z then
			rotCFrame = startRotCFrame * CFrame.Angles(0, 0, relativeAngle)
			rotZ = angleDeg
		end
		
		if rotCFrame then
			workspaceRig:PivotTo(rotCFrame)
		end
		
		ui.RotX.SetValue(rotX); ui.RotY.SetValue(rotY); ui.RotZ.SetValue(rotZ)
	end)
	
	workspaceArcHandles.MouseButton1Up:Connect(function()
		rotDragging = false
	end)
	
	-- Also clone to ViewportFrame for FPS preview
	viewportModel = workspaceRig:Clone()
	viewportModel.Name = "FPSPreviewModel"
	
	-- REMOVE Animator/AnimationController from Viewport Model
	-- We are manually syncing Motor6D transforms from workspace rig
	-- An inactive Animator will reset transforms to default, fighting our manual sync!
	for _, desc in pairs(viewportModel:GetDescendants()) do
		if desc:IsA("Animator") or desc:IsA("AnimationController") then
			desc:Destroy()
		end
	end
	
	-- Set root anchored
	local vpRoot = viewportModel:FindFirstChild("HumanoidRootPart")
	if vpRoot then
		vpRoot.Anchored = true
		viewportModel.PrimaryPart = vpRoot
	end
	
	-- Parent to WorldModel for animation support (not directly to ViewportFrame!)
	viewportModel.Parent = ui.ViewportWorldModel
	
	-- Position viewport model
	updateViewportPosition()
	
	print("[ViewmodelEditor] Workspace rig and FPS preview loaded!")
	print("[ViewmodelEditor] Use handles in 3D viewport to position, see preview in plugin!")
end

local function loadViewportModel(tool)
	-- Now just calls loadWorkspaceRig
	loadWorkspaceRig(tool)
end

local function playViewportAnimation(animId)
	-- Play on workspace rig, sync loop will copy to viewport
	if not viewportAnimator or not animId then return end
	
	if viewportAnimTrack then
		viewportAnimTrack:Stop()
		viewportAnimTrack = nil
	end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	
	-- We use the animator we captured from workspaceRig
	local success, track = pcall(function()
		return viewportAnimator:LoadAnimation(anim)
	end)
	
	if success and track then
		track.Looped = true
		track:Play()
		viewportAnimTrack = track
	end
end

-- Helper function to load position from current animation
local function loadAnimationPosition()
	if not currentWeaponAnimations then return end
	
	local animData = currentWeaponAnimations[selectedAnimState]
	if type(animData) == "table" and animData.Position then
		posX, posY, posZ = animData.Position.X, animData.Position.Y, animData.Position.Z
		ui.PosX.SetValue(posX); ui.PosY.SetValue(posY); ui.PosZ.SetValue(posZ)
		
		if animData.Rotation then
			rotX, rotY, rotZ = animData.Rotation.X, animData.Rotation.Y, animData.Rotation.Z
			ui.RotX.SetValue(rotX); ui.RotY.SetValue(rotY); ui.RotZ.SetValue(rotZ)
		end
	end
	
	-- Play the animation
	if currentAnimTrack then currentAnimTrack:Stop(); currentAnimTrack = nil end
	if previewModel then
		local animId = type(animData) == "table" and animData.Id or animData
		if animId then
			local animController = previewModel:FindFirstChildOfClass("AnimationController")
			if animController then
				local animator = animController:FindFirstChildOfClass("Animator")
				if animator then
					local anim = Instance.new("Animation")
					anim.AnimationId = animId
					local success, track = pcall(function()
						return animator:LoadAnimation(anim)
					end)
					if success and track then
						track.Looped = true
						track:Play()
						currentAnimTrack = track
					end
				end
			end
		end
	end
	
	ui.StatusLabel.Text = "Editing: " .. selectedAnimState
end

-- Animation Selector - cycle through animations
ui.AnimSelector.MouseButton1Click:Connect(function()
	currentAnimIndex = currentAnimIndex + 1
	if currentAnimIndex > #ANIM_STATES then currentAnimIndex = 1 end
	selectedAnimState = ANIM_STATES[currentAnimIndex]
	ui.AnimSelector.Text = "Anim: " .. selectedAnimState
	loadAnimationPosition()
	
	-- Play animation in viewport
	if currentWeaponAnimations and currentWeaponAnimations[selectedAnimState] then
		local animId = type(currentWeaponAnimations[selectedAnimState]) == "table" 
			and currentWeaponAnimations[selectedAnimState].Id 
			or currentWeaponAnimations[selectedAnimState]
		playViewportAnimation(animId)
	end
end)

-- Mobile Overlay Functions (defined before use)
local function updateMobileOverlay()
	if not mobileOverlayGui then return end
	
	local targetRatio = DEVICE_RATIOS[selectedDeviceRatio]
	if not targetRatio then
		-- Full mode - hide all bars
		mobileOverlayGui.TopBar.Size = UDim2.new(0, 0, 0, 0)
		mobileOverlayGui.BottomBar.Size = UDim2.new(0, 0, 0, 0)
		mobileOverlayGui.LeftBar.Size = UDim2.new(0, 0, 0, 0)
		mobileOverlayGui.RightBar.Size = UDim2.new(0, 0, 0, 0)
		return
	end
	
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local screenW, screenH = viewportSize.X, viewportSize.Y
	local currentRatio = screenW / screenH
	
	-- Calculate safe zone
	local safeW, safeH, offsetX, offsetY
	
	if currentRatio > targetRatio then
		-- Screen is wider than target - add left/right bars (pillarbox)
		safeH = screenH
		safeW = screenH * targetRatio
		offsetX = (screenW - safeW) / 2
		offsetY = 0
	else
		-- Screen is taller than target - add top/bottom bars (letterbox)
		safeW = screenW
		safeH = screenW / targetRatio
		offsetX = 0
		offsetY = (screenH - safeH) / 2
	end
	
	-- Position bars
	mobileOverlayGui.TopBar.Position = UDim2.new(0, 0, 0, 0)
	mobileOverlayGui.TopBar.Size = UDim2.new(1, 0, 0, offsetY)
	
	mobileOverlayGui.BottomBar.Position = UDim2.new(0, 0, 1, -offsetY)
	mobileOverlayGui.BottomBar.Size = UDim2.new(1, 0, 0, offsetY)
	
	mobileOverlayGui.LeftBar.Position = UDim2.new(0, 0, 0, 0)
	mobileOverlayGui.LeftBar.Size = UDim2.new(0, offsetX, 1, 0)
	
	mobileOverlayGui.RightBar.Position = UDim2.new(1, -offsetX, 0, 0)
	mobileOverlayGui.RightBar.Size = UDim2.new(0, offsetX, 1, 0)
end

local function createMobileOverlay()
	if mobileOverlayGui then return end
	
	mobileOverlayGui = Instance.new("ScreenGui")
	mobileOverlayGui.Name = "ViewmodelMobileOverlay"
	mobileOverlayGui.DisplayOrder = 999
	mobileOverlayGui.IgnoreGuiInset = true
	
	pcall(function() mobileOverlayGui.Parent = game:GetService("CoreGui") end)
	if not mobileOverlayGui.Parent then
		mobileOverlayGui.Parent = widget.Parent -- Fallback
	end
	
	-- Create 4 black bars (Top, Bottom, Left, Right)
	local barColor = Color3.fromRGB(0, 0, 0)
	
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.BackgroundColor3 = barColor
	topBar.BorderSizePixel = 0
	topBar.Parent = mobileOverlayGui
	
	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.BackgroundColor3 = barColor
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = mobileOverlayGui
	
	local leftBar = Instance.new("Frame")
	leftBar.Name = "LeftBar"
	leftBar.BackgroundColor3 = barColor
	leftBar.BorderSizePixel = 0
	leftBar.Parent = mobileOverlayGui
	
	local rightBar = Instance.new("Frame")
	rightBar.Name = "RightBar"
	rightBar.BackgroundColor3 = barColor
	rightBar.BorderSizePixel = 0
	rightBar.Parent = mobileOverlayGui
	
	-- Update Connection
	mobileOverlayConnection = RunService.Heartbeat:Connect(function()
		updateMobileOverlay()
	end)
	
	updateMobileOverlay()
end

local function cleanupMobileOverlay()
	if mobileOverlayConnection then
		mobileOverlayConnection:Disconnect()
		mobileOverlayConnection = nil
	end
	if mobileOverlayGui then
		mobileOverlayGui:Destroy()
		mobileOverlayGui = nil
	end
end

ui.MobileToggle.MouseButton1Click:Connect(function()
	isMobilePreview = not isMobilePreview
	ui.MobileToggle.Text = isMobilePreview and "Mode: Mobile" or "Mode: Desktop"
	ui.MobileToggle.BackgroundColor3 = isMobilePreview and Color3.fromRGB(150, 100, 0) or Color3.fromRGB(80, 80, 80)
	
	-- Toggle Mobile Overlay
	if isMobilePreview then
		createMobileOverlay()
	else
		cleanupMobileOverlay()
	end
end)

-- Device Button Click Handlers
for ratio, btn in pairs(ui.DeviceButtons) do
	btn.MouseButton1Click:Connect(function()
		selectedDeviceRatio = ratio
		ui.UpdateDeviceButtons()
		if mobileOverlayGui then
			updateMobileOverlay()
		end
	end)
end

ui.HitmarkerToggle.MouseButton1Click:Connect(function()
	showHitmarker = not showHitmarker
	ui.HitmarkerToggle.BackgroundColor3 = showHitmarker and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(80, 80, 80)
	
	if showHitmarker then
		if not hitmarkerGui then
			hitmarkerGui = Instance.new("ScreenGui")
			hitmarkerGui.Name = "ViewmodelEditorCrosshair"
			hitmarkerGui.DisplayOrder = 1000
			
			-- Try to parent to CoreGui for overlay (requires plugin permissions usually), fallback to PlayerGui
			pcall(function() hitmarkerGui.Parent = game:GetService("CoreGui") end)
			if not hitmarkerGui.Parent then
				hitmarkerGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
			end
			
			local container = Instance.new("Frame")
			container.Name = "Container"
			container.Size = UDim2.new(0, 50, 0, 50)
			container.AnchorPoint = Vector2.new(0.5, 0.5)
			container.Position = UDim2.new(0.5, 0, 0.5, 0)
			container.BackgroundTransparency = 1
			container.Parent = hitmarkerGui
			
			local lineThickness = 2
			local lineLength = 15
			local color = Color3.fromRGB(255, 255, 255)
			
			local function createLine(name, size, pos)
				local line = Instance.new("Frame")
				line.Name = name
				line.Size = size
				line.Position = pos
				line.BackgroundColor3 = color
				line.BorderSizePixel = 0
				line.Parent = container
			end
			
			createLine("TopLine", UDim2.new(0, lineThickness, 0, lineLength), UDim2.new(0.5, -1, 0.5, -lineLength - 5))
			createLine("BottomLine", UDim2.new(0, lineThickness, 0, lineLength), UDim2.new(0.5, -1, 0.5, 5))
			createLine("LeftLine", UDim2.new(0, lineLength, 0, lineThickness), UDim2.new(0.5, -lineLength - 5, 0.5, -1))
			createLine("RightLine", UDim2.new(0, lineLength, 0, lineThickness), UDim2.new(0.5, 5, 0.5, -1))
		end
		hitmarkerGui.Enabled = true
	else
		if hitmarkerGui then
			hitmarkerGui.Enabled = false
			hitmarkerGui:Destroy()
			hitmarkerGui = nil
		end
	end
end)

-- Handles Functions for Visual Positioning
local function destroyHandles()
	if moveHandles then
		moveHandles:Destroy()
		moveHandles = nil
	end
	if rotateHandles then
		rotateHandles:Destroy()
		rotateHandles = nil
	end
	if handlesPart then
		handlesPart:Destroy()
		handlesPart = nil
	end
end

local function createHandles()
	destroyHandles()
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- Create invisible part for handles to attach to
	handlesPart = Instance.new("Part")
	handlesPart.Name = "ViewmodelHandlesPart"
	handlesPart.Size = Vector3.new(0.5, 0.5, 0.5)
	handlesPart.Transparency = 0.8
	handlesPart.Anchored = true
	handlesPart.CanCollide = false
	handlesPart.Parent = camera
	
	-- Position it at current viewmodel offset
	local offset = CFrame.new(posX, posY, posZ)
	handlesPart.CFrame = camera.CFrame * offset
	
	-- Create Move Handles (Arrows for X, Y, Z)
	moveHandles = Instance.new("Handles")
	moveHandles.Adornee = handlesPart
	moveHandles.Color3 = Color3.fromRGB(100, 200, 255)
	moveHandles.Style = Enum.HandlesStyle.Movement
	moveHandles.Parent = CoreGui
	
	-- Handle Move Drag
	local isDragging = false
	local dragStart = nil
	local startPos = nil
	
	moveHandles.MouseButton1Down:Connect(function(face)
		isDragging = true
		dragStart = handlesPart.CFrame
		startPos = Vector3.new(posX, posY, posZ)
	end)
	
	moveHandles.MouseDrag:Connect(function(face, distance)
		if not isDragging then return end
		
		-- Calculate new position based on face and distance
		local delta = Vector3.new(0, 0, 0)
		if face == Enum.NormalId.Right then
			delta = Vector3.new(distance, 0, 0)
		elseif face == Enum.NormalId.Left then
			delta = Vector3.new(-distance, 0, 0)
		elseif face == Enum.NormalId.Top then
			delta = Vector3.new(0, distance, 0)
		elseif face == Enum.NormalId.Bottom then
			delta = Vector3.new(0, -distance, 0)
		elseif face == Enum.NormalId.Front then
			delta = Vector3.new(0, 0, -distance)
		elseif face == Enum.NormalId.Back then
			delta = Vector3.new(0, 0, distance)
		end
		
		-- Update position values
		posX = startPos.X + delta.X
		posY = startPos.Y + delta.Y
		posZ = startPos.Z + delta.Z
		
		-- Update sliders
		ui.PosX.SetValue(posX)
		ui.PosY.SetValue(posY)
		ui.PosZ.SetValue(posZ)
		
		-- Update handles part position
		handlesPart.CFrame = camera.CFrame * CFrame.new(posX, posY, posZ)
	end)
	
	moveHandles.MouseButton1Up:Connect(function()
		isDragging = false
	end)
	
	-- Create Rotate Handles (Arcs)
	rotateHandles = Instance.new("ArcHandles")
	rotateHandles.Adornee = handlesPart
	rotateHandles.Color3 = Color3.fromRGB(255, 150, 100)
	rotateHandles.Parent = CoreGui
	
	local rotDragging = false
	local startRot = nil
	
	rotateHandles.MouseButton1Down:Connect(function(axis)
		rotDragging = true
		startRot = Vector3.new(rotX, rotY, rotZ)
	end)
	
	rotateHandles.MouseDrag:Connect(function(axis, relativeAngle, deltaRadius)
		if not rotDragging then return end
		
		local angleDeg = math.deg(relativeAngle)
		
		if axis == Enum.Axis.X then
			rotX = startRot.X + angleDeg
		elseif axis == Enum.Axis.Y then
			rotY = startRot.Y + angleDeg
		elseif axis == Enum.Axis.Z then
			rotZ = startRot.Z + angleDeg
		end
		
		-- Update sliders
		ui.RotX.SetValue(rotX)
		ui.RotY.SetValue(rotY)
		ui.RotZ.SetValue(rotZ)
		
		-- Update handles part rotation
		handlesPart.CFrame = camera.CFrame * CFrame.new(posX, posY, posZ) * CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
	end)
	
	rotateHandles.MouseButton1Up:Connect(function()
		rotDragging = false
	end)
	
	print("[ViewmodelEditor] Handles created - drag to adjust position/rotation!")
end

-- Handles Toggle Handler
ui.HandlesToggle.MouseButton1Click:Connect(function()
	showHandles = not showHandles
	
	if showHandles then
		ui.HandlesToggle.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
		ui.HandlesToggle.Text = "📐 ON"
		createHandles()
	else
		ui.HandlesToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		ui.HandlesToggle.Text = "📐 Handles"
		destroyHandles()
	end
end)

-- Helper to sync animation poses from Workspace Rig to Viewport Rig
local function syncViewportAnimation()
	if not workspaceRig or not viewportModel then return end
	
	-- Sync every Motor6D transform
	for _, desc in pairs(workspaceRig:GetDescendants()) do
		if desc:IsA("Motor6D") then
			local viewportMotor = viewportModel:FindFirstChild(desc.Name, true)
			if viewportMotor and viewportMotor:IsA("Motor6D") then
				viewportMotor.Transform = desc.Transform
			end
		end
	end
end

-- Update handles position every frame when active
RunService.RenderStepped:Connect(function()
	if showHandles and handlesPart then
		local camera = workspace.CurrentCamera
		if camera then
			handlesPart.CFrame = camera.CFrame * CFrame.new(posX, posY, posZ) * CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
		end
	end
	
	-- Update viewport preview position
	updateViewportPosition()
	
	-- Sync animation pose manually (guaranteed to work)
	syncViewportAnimation()
end)
-- Find game viewmodel from camera (created by HybridViewmodel)
local function findGameViewmodel()
	local camera = workspace.CurrentCamera
	if not camera then return nil end
	
	for _, child in pairs(camera:GetChildren()) do
		if child:GetAttribute("IsHybridViewmodel") or child.Name == "HybridViewmodel" or child.Name == "FirstPersonViewmodel" then
			return child
		end
	end
	return nil
end

local function cleanupPreview()
	-- Don't destroy the game viewmodel, just disconnect render connection
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	currentAnimTrack = nil
	previewModel = nil -- Just clear reference, don't destroy
end

local function createPreview(tool)
	cleanupPreview()
	
	if not tool or not tool:IsA("Tool") then return end
	
	-- Find existing game viewmodel (created by HybridViewmodel)
	previewModel = findGameViewmodel()
	
	if not previewModel then
		print("[ViewmodelEditor] No game viewmodel found. Make sure you're in Play mode with weapon equipped.")
		return
	end
	
	print("[ViewmodelEditor] Using game viewmodel:", previewModel.Name)
	
	-- Render Loop - Apply position/rotation from sliders to game viewmodel
	renderConnection = RunService.RenderStepped:Connect(function()
		if not previewModel or not previewModel.Parent then 
			previewModel = findGameViewmodel() -- Try to re-find if lost
			return 
		end
		
		-- Set Editor attributes on the game viewmodel
		-- HybridViewmodel will read these and use them to override position
		previewModel:SetAttribute("Editor_AnimPos", Vector3.new(posX, posY, posZ))
		previewModel:SetAttribute("Editor_AnimRot", Vector3.new(rotX, rotY, rotZ))
		previewModel:SetAttribute("Editor_AnimState", selectedAnimState)
	end)
end



-- Selection handling
local function onSelectionChanged()
	local selected = Selection:Get()
	if #selected == 1 and selected[1]:IsA("Tool") then
		currentTool = selected[1]
		currentWeaponName = currentTool.Name
		if not targetWeaponName then
			targetWeaponName = currentWeaponName
			ui.TargetSelector.UpdateText(targetWeaponName)
		end
		ui.SelectedLabel.Text = "Selected: " .. currentWeaponName
		
		local weaponModule = game.ReplicatedStorage:FindFirstChild("ModuleScript")
		if weaponModule then
			weaponModule = weaponModule:FindFirstChild("WeaponModule")
		end
		
		if weaponModule then
			local success, result = pcall(function()
				return require(weaponModule)
			end)
			
			if success and result and result.Weapons and result.Weapons[currentWeaponName] then
				local stats = result.Weapons[currentWeaponName]
				
				-- Capture Animations (new per-animation format)
				currentWeaponAnimations = stats.Animations
				
				-- Load position for current selected animation state
				loadAnimationPosition()
				
				-- Reset animation selector to Idle
				currentAnimIndex = 1
				selectedAnimState = "Idle"
				ui.AnimSelector.Text = "Anim: " .. selectedAnimState
				
				-- Load viewport model for preview
				loadViewportModel(currentTool)
				
				-- Play animation in viewport
				if currentWeaponAnimations and currentWeaponAnimations[selectedAnimState] then
					local animId = type(currentWeaponAnimations[selectedAnimState]) == "table" 
						and currentWeaponAnimations[selectedAnimState].Id 
						or currentWeaponAnimations[selectedAnimState]
					playViewportAnimation(animId)
				end
			end
		end
		
		if isActive then
			createPreview(currentTool)
		end
	else
		currentTool = nil
		currentWeaponName = nil
		ui.SelectedLabel.Text = "Selected: None"
		cleanupPreview()
	end
end

Selection.SelectionChanged:Connect(onSelectionChanged)

-- Apply Button
ui.ApplyButton.MouseButton1Click:Connect(function()
	if not targetWeaponName then
		ui.StatusLabel.Text = "Error: No target weapon selected!"
		return
	end
	
	local weaponModuleScript = game.ReplicatedStorage:FindFirstChild("ModuleScript")
	if weaponModuleScript then
		weaponModuleScript = weaponModuleScript:FindFirstChild("WeaponModule")
	end
	
	if not weaponModuleScript then
		ui.StatusLabel.Text = "Error: WeaponModule not found!"
		return
	end
	
	local source = weaponModuleScript.Source
	local replaced = 0
	
	local escapedWeaponName = targetWeaponName:gsub("%-", "%%-")
	
	-- Helper function to replace a property value
	local function replaceVector3(src, propName, x, y, z, isInteger)
		local pattern = propName .. "%s*=%s*Vector3%.new%([^%)]+%)"
		local format = isInteger and "%.0f, %.0f, %.0f" or "%.3f, %.3f, %.3f"
		local replacement = propName .. " = Vector3.new(" .. string.format(format, x, y, z) .. ")"
		
		local newSrc, count = src:gsub(pattern, replacement)
		return newSrc, count
	end
	
	-- Find the weapon block
	local weaponPattern = '%["' .. escapedWeaponName .. '"%]%s*=%s*{'
	local weaponStart, weaponEnd = source:find(weaponPattern)
	
	if not weaponStart then
		ui.StatusLabel.Text = "Error: Weapon '" .. targetWeaponName .. "' not found!"
		return
	end
	
	-- Find the end of this weapon's block
	local depth = 1
	local pos = weaponEnd + 1
	while depth > 0 and pos <= #source do
		local char = source:sub(pos, pos)
		if char == "{" then
			depth = depth + 1
		elseif char == "}" then
			depth = depth - 1
		end
		pos = pos + 1
	end
	local weaponBlockEnd = pos - 1
	
	-- Extract weapon block
	local beforeWeapon = source:sub(1, weaponStart - 1)
	local weaponBlock = source:sub(weaponStart, weaponBlockEnd)
	local afterWeapon = source:sub(weaponBlockEnd + 1)
	
	-- Find the animation block for selected animation state (e.g., Idle = { ... })
	local animPattern = selectedAnimState .. "%s*=%s*{"
	local animStart, animEnd = weaponBlock:find(animPattern)
	
	print("[ViewmodelEditor] Looking for animation:", selectedAnimState)
	print("[ViewmodelEditor] Animation pattern:", animPattern)
	print("[ViewmodelEditor] Found animStart:", animStart, "animEnd:", animEnd)
	
	if animStart then
		-- Find end of animation block
		local animDepth = 1
		local animPos = animEnd + 1
		while animDepth > 0 and animPos <= #weaponBlock do
			local char = weaponBlock:sub(animPos, animPos)
			if char == "{" then
				animDepth = animDepth + 1
			elseif char == "}" then
				animDepth = animDepth - 1
			end
			animPos = animPos + 1
		end
		local animBlockEnd = animPos - 1
		
		-- Extract animation block
		local beforeAnim = weaponBlock:sub(1, animStart - 1)
		local animBlock = weaponBlock:sub(animStart, animBlockEnd)
		local afterAnim = weaponBlock:sub(animBlockEnd + 1)
		
		print("[ViewmodelEditor] animBlock length:", #animBlock)
		print("[ViewmodelEditor] animBlock content:", animBlock:sub(1, 200)) -- First 200 chars
		
		-- Replace Position and Rotation in animation block
		local newBlock, count
		
		newBlock, count = replaceVector3(animBlock, "Position", posX, posY, posZ, false)
		print("[ViewmodelEditor] Position replacement count:", count)
		if count > 0 then animBlock = newBlock; replaced = replaced + count end
		
		newBlock, count = replaceVector3(animBlock, "Rotation", rotX, rotY, rotZ, true)
		print("[ViewmodelEditor] Rotation replacement count:", count)
		if count > 0 then animBlock = newBlock; replaced = replaced + count end
		
		print("[ViewmodelEditor] Total replaced:", replaced)
		
		weaponBlock = beforeAnim .. animBlock .. afterAnim
	else
		ui.StatusLabel.Text = "Warning: Animation '" .. selectedAnimState .. "' not found in Animations!"
	end
	
	source = beforeWeapon .. weaponBlock .. afterWeapon
	
	if replaced > 0 then
		ChangeHistoryService:SetWaypoint("Viewmodel Edit: " .. targetWeaponName .. " " .. selectedAnimState)
		weaponModuleScript.Source = source
		ChangeHistoryService:SetWaypoint("Viewmodel Edit Applied")
		
		-- PRINT COPYABLE CODE for file-sync workflows (Rojo)
		print("==============================================")
		print("[ViewmodelEditor] COPY THIS TO WeaponModule.lua:")
		print("==============================================")
		print(string.format([[
%s = {
	Id = "%s",
	Position = Vector3.new(%.3f, %.3f, %.3f),
	Rotation = Vector3.new(%.0f, %.0f, %.0f)
},]], 
			selectedAnimState,
			currentWeaponAnimations and currentWeaponAnimations[selectedAnimState] and 
				(type(currentWeaponAnimations[selectedAnimState]) == "table" and currentWeaponAnimations[selectedAnimState].Id or currentWeaponAnimations[selectedAnimState]) or "rbxassetid://",
			posX, posY, posZ, rotX, rotY, rotZ))
		print("==============================================")
		
		ui.StatusLabel.Text = "Updated! See Output for copyable code"
	else
		ui.StatusLabel.Text = "Warning: No changes for " .. selectedAnimState .. " in " .. targetWeaponName
	end
end)

-- Helper to render preset item
local function renderPresets()
	-- Clear list
	for _, child in ipairs(ui.PresetsList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	-- Calculate canvas size
	local count = 0
	for _ in pairs(presets) do count = count + 1 end
	ui.PresetsList.CanvasSize = UDim2.new(0, 0, 0, count * 26)
	
	-- Render items
	for name, data in pairs(presets) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, 0, 0, 24)
		item.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		item.BorderSizePixel = 0
		item.Parent = ui.PresetsList
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 1, 0)
		label.Position = UDim2.new(0, 4, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 11
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = item
		
		local loadBtn = Instance.new("TextButton")
		loadBtn.Size = UDim2.new(0.15, 0, 1, 0)
		loadBtn.Position = UDim2.new(0.65, 0, 0, 0)
		loadBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
		loadBtn.Text = "Load"
		loadBtn.TextColor3 = Color3.new(1, 1, 1)
		loadBtn.TextSize = 10
		loadBtn.Font = Enum.Font.GothamBold
		loadBtn.Parent = item
		Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
		
		loadBtn.MouseButton1Click:Connect(function()
			-- Load data
			if data.Pos then
				posX, posY, posZ = data.Pos.X, data.Pos.Y, data.Pos.Z
				ui.PosX.SetValue(posX); ui.PosY.SetValue(posY); ui.PosZ.SetValue(posZ)
			end
			if data.Rot then
				rotX, rotY, rotZ = data.Rot.X, data.Rot.Y, data.Rot.Z
				ui.RotX.SetValue(rotX); ui.RotY.SetValue(rotY); ui.RotZ.SetValue(rotZ)
			end
			
			-- Note: ADS presets removed - positions are now per-animation
			
			ui.StatusLabel.Text = "Loaded Preset: " .. name
		end)
		
		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0.15, 0, 1, 0)
		delBtn.Position = UDim2.new(0.82, 0, 0, 0)
		delBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
		delBtn.Text = "Del"
		delBtn.TextColor3 = Color3.new(1, 1, 1)
		delBtn.TextSize = 10
		delBtn.Font = Enum.Font.GothamBold
		delBtn.Parent = item
		Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
		
		delBtn.MouseButton1Click:Connect(function()
			presets[name] = nil
			plugin:SetSetting(PRESETS_KEY, presets)
			renderPresets()
			ui.StatusLabel.Text = "Deleted Preset: " .. name
		end)
	end
end

-- Init list
renderPresets()

-- Save Handler
ui.SavePresetButton.MouseButton1Click:Connect(function()
	local name = ui.PresetNameInput.Text
	if not name or name == "" then
		ui.StatusLabel.Text = "Error: Enter preset name!"
		return
	end
	
	-- Save current values (per-animation - saves current position)
	presets[name] = {
		AnimState = selectedAnimState,
		Pos = {X=posX, Y=posY, Z=posZ},
		Rot = {X=rotX, Y=rotY, Z=rotZ},
	}
	
	plugin:SetSetting(PRESETS_KEY, presets)
	renderPresets()
	ui.StatusLabel.Text = "Saved Preset: " .. name .. " (" .. selectedAnimState .. ")"
	ui.PresetNameInput.Text = ""
end)

-- Print Output (per-animation format)
ui.CopyButton.MouseButton1Click:Connect(function()
	local code = string.format([[
-- Animation: %s
%s = {
	Id = "%s",
	Position = Vector3.new(%.3f, %.3f, %.3f),
	Rotation = Vector3.new(%.0f, %.0f, %.0f)
}
]], selectedAnimState, selectedAnimState, 
	currentWeaponAnimations and currentWeaponAnimations[selectedAnimState] and 
		(type(currentWeaponAnimations[selectedAnimState]) == "table" and currentWeaponAnimations[selectedAnimState].Id or currentWeaponAnimations[selectedAnimState]) or "rbxassetid://",
	posX, posY, posZ, rotX, rotY, rotZ)
	
	print("=== VIEWMODEL VALUES ===")
	print(code)
	print("========================")
	ui.StatusLabel.Text = "Values printed to Output!"
end)

-- FOV Handling
local originalFOV = 70
local camera = workspace.CurrentCamera

local function updateFOV()
	-- Update FOV when ADS animation is selected
	if selectedAnimState == "ADS" and currentWeaponName then
		local weaponModule = game.ReplicatedStorage:FindFirstChild("ModuleScript")
		if weaponModule then weaponModule = weaponModule:FindFirstChild("WeaponModule") end
		if weaponModule then
			local success, result = pcall(function() return require(weaponModule) end)
			if success and result and result.Weapons and result.Weapons[currentWeaponName] then
				local stats = result.Weapons[currentWeaponName]
				if stats.ADSFoV then
					camera.FieldOfView = stats.ADSFoV
				end
			end
		end
	else
		camera.FieldOfView = originalFOV
	end
end

-- Hook into Animation Selector for FOV change
ui.AnimSelector.MouseButton1Click:Connect(function()
	-- The animation is already changed by the first connection
	-- We just need to update FOV after animation change
	if selectedAnimState == "ADS" then
		originalFOV = camera.FieldOfView
		if originalFOV < 60 then originalFOV = 70 end 
	end
	updateFOV()
end)

-- Hook into Selection Check to update FOV if we switch weapons while ADS is active
local function onSelectionChangedFOVWrapper()
	if isActive then
		updateFOV()
	else
		camera.FieldOfView = 70 -- Reset if plugin inactive
	end
end
Selection.SelectionChanged:Connect(onSelectionChangedFOVWrapper)


-- Toggle Button (Main Plugin Toggle)
toggleButton.Click:Connect(function()
	isActive = not isActive
	widget.Enabled = isActive
	toggleButton:SetActive(isActive)
	
	if isActive then
		originalFOV = camera.FieldOfView
		onSelectionChanged()
		updateFOV()
	else
		cleanupPreview()
		camera.FieldOfView = 70 -- Reset to default on close
		if hitmarkerGui then hitmarkerGui:Destroy() hitmarkerGui = nil end
		cleanupMobileOverlay()
	end
end)

-- Cleanup
plugin.Unloading:Connect(function()
	cleanupPreview()
	workspace.CurrentCamera.FieldOfView = 70 -- Force reset
	if hitmarkerGui then
		hitmarkerGui:Destroy()
	end
	cleanupMobileOverlay()
end)

-- [NEW] Live Edit Loop for HybridViewmodel
RunService.RenderStepped:Connect(function()
	if not isActive then return end
	
	-- Try to find live viewmodel in camera
	local cam = workspace.CurrentCamera
	if not cam then return end
	
	local vm = cam:FindFirstChild("HybridViewmodel")
	
	if vm then
		-- Sync Editor Values to Attributes
		-- HybridViewmodel will read these attributes to override its position
		
		-- Set current animation position for game viewmodel sync
		vm:SetAttribute("Editor_AnimPos", Vector3.new(posX, posY, posZ))
		vm:SetAttribute("Editor_AnimRot", Vector3.new(rotX, rotY, rotZ))
		vm:SetAttribute("Editor_AnimState", selectedAnimState)
	end
end)

print("[Viewmodel Editor] Plugin loaded with per-animation position support!")
