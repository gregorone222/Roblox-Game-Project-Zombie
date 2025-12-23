-- ViewmodelEditorPlugin.lua
-- A Roblox Studio Plugin for editing Viewmodel Position, Rotation, and ADS in real-time
-- Save this file to: %localappdata%\Roblox\Plugins\ViewmodelEditorPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

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
local isADSPreview = false
local isMobilePreview = false
local showHitmarker = false
local hitmarkerGui = nil
local currentWeaponAnimations = nil
local currentAnimTrack = nil

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

-- Values
local posX, posY, posZ = 1.5, -1, -2.5
local rotX, rotY, rotZ = 0, 0, 0

local adsX, adsY, adsZ = 0.15, -0.37, -1
local adsRotX, adsRotY, adsRotZ = 0, 0, 0

local adsMobileX, adsMobileY, adsMobileZ = 0.15, -0.37, -1
local adsMobileRotX, adsMobileRotY, adsMobileRotZ = 0, 0, 0

-- Presets
local PRESETS_KEY = "ViewmodelEditor_Presets"
local presets = plugin:GetSetting(PRESETS_KEY) or {}

-- Values
local adsRotX, adsRotY, adsRotZ = 0, 0, 0

local adsMobileX, adsMobileY, adsMobileZ = 0.15, -0.37, -1
local adsMobileRotX, adsMobileRotY, adsMobileRotZ = 0, 0, 0

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

	-- Toggle Buttons Frame
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

	local adsToggle = Instance.new("TextButton")
	adsToggle.Name = "ADSToggle"
	adsToggle.Size = UDim2.new(0, 100, 0, 30)
	adsToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	adsToggle.Text = "Preview: HIP"
	adsToggle.TextColor3 = Color3.new(1, 1, 1)
	adsToggle.TextSize = 11
	adsToggle.Font = Enum.Font.GothamMedium
	adsToggle.Parent = toggleFrame
	Instance.new("UICorner", adsToggle).CornerRadius = UDim.new(0, 4)

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
		
		if not previewModel then 
			print("[ViewmodelEditor] ERROR: previewModel is nil")
			if statusLabel then statusLabel.Text = "No preview model!" end
			return 
		end
		
		if not currentWeaponAnimations then 
			print("[ViewmodelEditor] ERROR: currentWeaponAnimations is nil")
			if statusLabel then statusLabel.Text = "Select weapon first!" end
			return 
		end
		
		local animId = (animKey == "Aim") and currentWeaponAnimations.ADS or currentWeaponAnimations[animKey]
		print("[ViewmodelEditor] Animation ID for", animKey, ":", animId)
		
		if not animId then
			if statusLabel then statusLabel.Text = "No " .. animKey .. " animation!" end
			return
		end
		
		-- Find Controller
		local animController = previewModel:FindFirstChildOfClass("AnimationController")
		if not animController then
			local hum = previewModel:FindFirstChildOfClass("Humanoid")
			if hum then 
				animController = hum
				print("[ViewmodelEditor] Using Humanoid as controller")
			end
		end
		
		if not animController then
			animController = Instance.new("AnimationController")
			animController.Parent = previewModel
			print("[ViewmodelEditor] Created new AnimationController")
		end
		
		local animator = animController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animController
			print("[ViewmodelEditor] Created new Animator")
		end
		
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		
		-- Stop any existing tracks on this animator too
		for _, t in pairs(animator:GetPlayingAnimationTracks()) do t:Stop() end
		
		local success, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		
		if not success then
			print("[ViewmodelEditor] ERROR loading animation:", track)
			if statusLabel then statusLabel.Text = "Error: " .. tostring(track) end
			return
		end
		
		track.Looped = true
		track:Play()
		currentAnimTrack = track
		print("[ViewmodelEditor] Animation playing!")
		if statusLabel then statusLabel.Text = "Playing: " .. animKey end
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

	-- ===== ADS DESKTOP SECTION =====
	createSectionHeader("🎯 ADS Position (Desktop)", scrollFrame, 30)
	local adsXSlider = createSliderGroup("AdsX", "X", -2, 2, adsX, 0.001, function(v) adsX = v end, scrollFrame, 31)
	local adsYSlider = createSliderGroup("AdsY", "Y", -2, 2, adsY, 0.001, function(v) adsY = v end, scrollFrame, 32)
	local adsZSlider = createSliderGroup("AdsZ", "Z", -5, 0, adsZ, 0.001, function(v) adsZ = v end, scrollFrame, 33)

	createSectionHeader("🔄 ADS Rotation (Desktop)", scrollFrame, 40)
	local adsRotXSlider = createSliderGroup("AdsRotX", "X (deg)", -45, 45, adsRotX, 1, function(v) adsRotX = v end, scrollFrame, 41)
	local adsRotYSlider = createSliderGroup("AdsRotY", "Y (deg)", -45, 45, adsRotY, 1, function(v) adsRotY = v end, scrollFrame, 42)
	local adsRotZSlider = createSliderGroup("AdsRotZ", "Z (deg)", -45, 45, adsRotZ, 1, function(v) adsRotZ = v end, scrollFrame, 43)

	-- ===== ADS MOBILE SECTION =====
	createSectionHeader("📱 ADS Position (Mobile)", scrollFrame, 50)
	local adsMobileXSlider = createSliderGroup("AdsMobileX", "X", -2, 2, adsMobileX, 0.001, function(v) adsMobileX = v end, scrollFrame, 51)
	local adsMobileYSlider = createSliderGroup("AdsMobileY", "Y", -2, 2, adsMobileY, 0.001, function(v) adsMobileY = v end, scrollFrame, 52)
	local adsMobileZSlider = createSliderGroup("AdsMobileZ", "Z", -5, 0, adsMobileZ, 0.001, function(v) adsMobileZ = v end, scrollFrame, 53)

	createSectionHeader("🔄 ADS Rotation (Mobile)", scrollFrame, 60)
	local adsMobileRotXSlider = createSliderGroup("AdsMobileRotX", "X (deg)", -45, 45, adsMobileRotX, 1, function(v) adsMobileRotX = v end, scrollFrame, 61)
	local adsMobileRotYSlider = createSliderGroup("AdsMobileRotY", "Y (deg)", -45, 45, adsMobileRotY, 1, function(v) adsMobileRotY = v end, scrollFrame, 62)
	local adsMobileRotZSlider = createSliderGroup("AdsMobileRotZ", "Z (deg)", -45, 45, adsMobileRotZ, 1, function(v) adsMobileRotZ = v end, scrollFrame, 63)

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
		ADSToggle = adsToggle,
		MobileToggle = mobileToggle,
		ApplyButton = applyButton,
		CopyButton = copyButton,
		-- Viewmodel
		PosX = posXSlider, PosY = posYSlider, PosZ = posZSlider,
		RotX = rotXSlider, RotY = rotYSlider, RotZ = rotZSlider,
		-- ADS Desktop
		AdsX = adsXSlider, AdsY = adsYSlider, AdsZ = adsZSlider,
		AdsRotX = adsRotXSlider, AdsRotY = adsRotYSlider, AdsRotZ = adsRotZSlider,
		-- ADS Mobile
		AdsMobileX = adsMobileXSlider, AdsMobileY = adsMobileYSlider, AdsMobileZ = adsMobileZSlider,
		AdsMobileRotX = adsMobileRotXSlider, AdsMobileRotY = adsMobileRotYSlider, AdsMobileRotZ = adsMobileRotZSlider,
		HitmarkerToggle = hitmarkerToggle,
		TargetSelector = targetSelector,
		-- Mobile Overlay
		DeviceButtons = deviceButtons,
		UpdateDeviceButtons = updateDeviceButtons
	}
end

local ui = createUI()

-- Toggle Handlers
ui.ADSToggle.MouseButton1Click:Connect(function()
	isADSPreview = not isADSPreview
	ui.ADSToggle.Text = isADSPreview and "Preview: ADS" or "Preview: HIP"
	ui.ADSToggle.BackgroundColor3 = isADSPreview and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(80, 80, 80)
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


-- Preview Functions
local function cleanupPreview()
	if previewModel then
		previewModel:Destroy()
		previewModel = nil
	end
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	currentAnimTrack = nil -- Clear anim track reference
end

local function createPreview(tool)
	cleanupPreview()
	
	if not tool or not tool:IsA("Tool") then return end
	
	-- 1. Try to find ViewmodelBase
	local viewmodelBase = game.ReplicatedStorage:FindFirstChild("Assets")
	if viewmodelBase then viewmodelBase = viewmodelBase:FindFirstChild("Viewmodel") end
	if viewmodelBase then viewmodelBase = viewmodelBase:FindFirstChild("ViewmodelBase") end
	
	-- 2. Setup Preview Model
	if viewmodelBase then
		-- HYBRID MODE: Clone Arms
		previewModel = viewmodelBase:Clone()
		previewModel.Name = "ViewmodelPreview"
		
		-- Clone Weapon
		local weaponClone = tool:Clone()
		weaponClone.Parent = previewModel
		
		local rightHand = previewModel:FindFirstChild("RightHand")
		local handle = weaponClone:FindFirstChild("Handle")
		
		if rightHand and handle then
			-- Weld Weapon to Hand
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rightHand
			weld.Part1 = handle
			weld.Parent = handle
			
			-- Position Handle at Hand (approximate reset)
			-- Ideally we match RightGripAttachment if exists
			local gripAtt = rightHand:FindFirstChild("RightGripAttachment")
			if gripAtt then
				handle.CFrame = gripAtt.WorldCFrame
			else
				handle.CFrame = rightHand.CFrame
			end
		end
		
		-- Cleanup Weapon Scripts/Physics
		for _, desc in pairs(weaponClone:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CanCollide = false
				desc.CastShadow = false
				desc.Anchored = false
			elseif desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") then
				desc:Destroy()
			end
		end
	else
		-- LEGACY MODE: Just Weapon
		previewModel = tool:Clone()
		previewModel.Name = "ViewmodelPreview"
	end

	-- 3. Cleanup ViewmodelBase Physics
	for _, desc in pairs(previewModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CastShadow = false
			desc.Anchored = false -- Root will be anchored later or controlled by CF
		elseif desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") then
			desc:Destroy()
		end
	end
	
	-- Anchor Root for control
	local root = previewModel:FindFirstChild("HumanoidRootPart") or previewModel:FindFirstChild("Handle")
	if root then root.Anchored = true end
	
	previewModel.Parent = workspace.CurrentCamera
	
	-- [DEBUG] Print rig structure
	print("[ViewmodelEditor] === RIG DIAGNOSTIC ===")
	local motor6dCount = 0
	for _, desc in pairs(previewModel:GetDescendants()) do
		if desc:IsA("Motor6D") then
			motor6dCount = motor6dCount + 1
			print("[ViewmodelEditor] Motor6D:", desc.Name, "| Part0:", desc.Part0 and desc.Part0.Name or "nil", "| Part1:", desc.Part1 and desc.Part1.Name or "nil")
		end
	end
	print("[ViewmodelEditor] Total Motor6D found:", motor6dCount)
	if motor6dCount == 0 then
		print("[ViewmodelEditor] WARNING: No Motor6D found! Animations will NOT work on this rig.")
		print("[ViewmodelEditor] ViewmodelBase must be a proper R15 rig with Motor6D joints.")
	end
	print("[ViewmodelEditor] === END DIAGNOSTIC ===")
	
	-- 4. Render Loop
	renderConnection = RunService.RenderStepped:Connect(function()
		if not previewModel or not previewModel.Parent then return end
		
		local mobileOffset = if isMobilePreview then CFrame.new(0,0,0) else CFrame.new(0,0,0)
		
		local offset, rotation
		if isADSPreview then
			if isMobilePreview then
				offset = CFrame.new(adsMobileX, adsMobileY, adsMobileZ)
				rotation = CFrame.Angles(math.rad(adsMobileRotX), math.rad(adsMobileRotY), math.rad(adsMobileRotZ))
			else
				offset = CFrame.new(adsX, adsY, adsZ)
				rotation = CFrame.Angles(math.rad(adsRotX), math.rad(adsRotY), math.rad(adsRotZ))
			end
		else
			offset = CFrame.new(posX, posY, posZ)
			rotation = CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
		end
		
		-- Apply to RootPart (Hybrid) or Handle (Legacy)
		local mainPart = previewModel:FindFirstChild("HumanoidRootPart") or previewModel:FindFirstChild("Handle")
		
		if mainPart then
			mainPart.CFrame = workspace.CurrentCamera.CFrame * offset * rotation
		end
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
				
				-- Capture Animations
				currentWeaponAnimations = stats.Animations
				
				-- Load Viewmodel
				if stats.ViewmodelPosition then
					posX, posY, posZ = stats.ViewmodelPosition.X, stats.ViewmodelPosition.Y, stats.ViewmodelPosition.Z
					ui.PosX.SetValue(posX); ui.PosY.SetValue(posY); ui.PosZ.SetValue(posZ)
				end
				if stats.ViewmodelRotation then
					rotX, rotY, rotZ = stats.ViewmodelRotation.X, stats.ViewmodelRotation.Y, stats.ViewmodelRotation.Z
					ui.RotX.SetValue(rotX); ui.RotY.SetValue(rotY); ui.RotZ.SetValue(rotZ)
				end
				
				-- Load ADS from Default Skin
				currentSkinName = stats.Use_Skin or "Default Skin"
				if stats.Skins and stats.Skins[currentSkinName] then
					local skin = stats.Skins[currentSkinName]
					if skin.ADS_Position then
						adsX, adsY, adsZ = skin.ADS_Position.X, skin.ADS_Position.Y, skin.ADS_Position.Z
						ui.AdsX.SetValue(adsX); ui.AdsY.SetValue(adsY); ui.AdsZ.SetValue(adsZ)
					end
					if skin.ADS_Rotation then
						adsRotX, adsRotY, adsRotZ = skin.ADS_Rotation.X, skin.ADS_Rotation.Y, skin.ADS_Rotation.Z
						ui.AdsRotX.SetValue(adsRotX); ui.AdsRotY.SetValue(adsRotY); ui.AdsRotZ.SetValue(adsRotZ)
					end
					if skin.ADS_Position_Mobile then
						adsMobileX, adsMobileY, adsMobileZ = skin.ADS_Position_Mobile.X, skin.ADS_Position_Mobile.Y, skin.ADS_Position_Mobile.Z
						ui.AdsMobileX.SetValue(adsMobileX); ui.AdsMobileY.SetValue(adsMobileY); ui.AdsMobileZ.SetValue(adsMobileZ)
					end
					if skin.ADS_Rotation_Mobile then
						adsMobileRotX, adsMobileRotY, adsMobileRotZ = skin.ADS_Rotation_Mobile.X, skin.ADS_Rotation_Mobile.Y, skin.ADS_Rotation_Mobile.Z
						ui.AdsMobileRotX.SetValue(adsMobileRotX); ui.AdsMobileRotY.SetValue(adsMobileRotY); ui.AdsMobileRotZ.SetValue(adsMobileRotZ)
					end
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
	local originalLength = #source
	local replaced = 0
	
	-- Simple approach: gsub directly on the source
	-- For ViewmodelPosition, we need to find the one inside the specific weapon's block
	
	-- Step 1: Find and replace ViewmodelPosition within weapon block
	-- We'll use a more unique pattern that includes the weapon name context
	
	local escapedWeaponName = targetWeaponName:gsub("%-", "%%-")
	local skinName = currentSkinName or "Default Skin"
	local escapedSkinName = skinName:gsub("%-", "%%-"):gsub("'", "")
	
	-- Helper function to replace a property value
	local function replaceVector3(src, propName, x, y, z, isInteger)
		local pattern = propName .. "%s*=%s*Vector3%.new%([^%)]+%)"
		local format = isInteger and "%.0f, %.0f, %.0f" or "%.3f, %.3f, %.3f"
		local replacement = propName .. " = Vector3.new(" .. string.format(format, x, y, z) .. ")"
		
		local newSrc, count = src:gsub(pattern, replacement)
		return newSrc, count
	end
	
	-- Find the weapon block first to ensure it exists
	local weaponPattern = '%["' .. escapedWeaponName .. '"%]%s*=%s*{'
	local weaponStart, weaponEnd = source:find(weaponPattern)
	
	if not weaponStart then
		ui.StatusLabel.Text = "Error: Weapon '" .. targetWeaponName .. "' not found in source!"
		return
	end
	
	-- Find the end of this weapon's block (next weapon or end)
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
	
	-- Extract the weapon block
	local beforeWeapon = source:sub(1, weaponStart - 1)
	local weaponBlock = source:sub(weaponStart, weaponBlockEnd)
	local afterWeapon = source:sub(weaponBlockEnd + 1)
	
	-- Replace ViewmodelPosition and ViewmodelRotation in this block
	local newBlock, count
	
	newBlock, count = replaceVector3(weaponBlock, "ViewmodelPosition", posX, posY, posZ, false)
	if count > 0 then weaponBlock = newBlock; replaced = replaced + count end
	
	newBlock, count = replaceVector3(weaponBlock, "ViewmodelRotation", rotX, rotY, rotZ, true)
	if count > 0 then weaponBlock = newBlock; replaced = replaced + count end
	
	-- Now find the skin block within the weapon block for ADS properties
	local skinPattern = '%["' .. escapedSkinName .. '"%]%s*=%s*{'
	local skinStart, skinEnd = weaponBlock:find(skinPattern)
	
	if skinStart then
		
		-- Find skin block end
		local skinDepth = 1
		local skinPos = skinEnd + 1
		while skinDepth > 0 and skinPos <= #weaponBlock do
			local char = weaponBlock:sub(skinPos, skinPos)
			if char == "{" then
				skinDepth = skinDepth + 1
			elseif char == "}" then
				skinDepth = skinDepth - 1
			end
			skinPos = skinPos + 1
		end
		local skinBlockEnd = skinPos - 1
		
		-- Extract skin block
		local beforeSkin = weaponBlock:sub(1, skinStart - 1)
		local skinBlock = weaponBlock:sub(skinStart, skinBlockEnd)
		local afterSkin = weaponBlock:sub(skinBlockEnd + 1)
		
		-- Replace ADS properties in skin block
		newBlock, count = replaceVector3(skinBlock, "ADS_Position", adsX, adsY, adsZ, false)
		if count > 0 then skinBlock = newBlock; replaced = replaced + count end
		
		newBlock, count = replaceVector3(skinBlock, "ADS_Rotation", adsRotX, adsRotY, adsRotZ, true)
		if count > 0 then skinBlock = newBlock; replaced = replaced + count end
		
		newBlock, count = replaceVector3(skinBlock, "ADS_Position_Mobile", adsMobileX, adsMobileY, adsMobileZ, false)
		if count > 0 then skinBlock = newBlock; replaced = replaced + count end
		
		newBlock, count = replaceVector3(skinBlock, "ADS_Rotation_Mobile", adsMobileRotX, adsMobileRotY, adsMobileRotZ, true)
		if count > 0 then skinBlock = newBlock; replaced = replaced + count end
		
		weaponBlock = beforeSkin .. skinBlock .. afterSkin
	else
		ui.StatusLabel.Text = "Warning: Skin '" .. skinName .. "' not found"
	end
	
	source = beforeWeapon .. weaponBlock .. afterWeapon
	
	if replaced > 0 then
		ChangeHistoryService:SetWaypoint("Viewmodel Edit: " .. targetWeaponName)
		weaponModuleScript.Source = source
		ChangeHistoryService:SetWaypoint("Viewmodel Edit Applied")
		ui.StatusLabel.Text = "Success! " .. replaced .. " values updated for " .. targetWeaponName
	else
		ui.StatusLabel.Text = "Warning: No patterns matched for " .. targetWeaponName
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
			
			-- Load ADS (check if exists in preset)
			if data.AdsPos then
				adsX, adsY, adsZ = data.AdsPos.X, data.AdsPos.Y, data.AdsPos.Z
				ui.AdsX.SetValue(adsX); ui.AdsY.SetValue(adsY); ui.AdsZ.SetValue(adsZ)
			end
			if data.AdsRot then
				adsRotX, adsRotY, adsRotZ = data.AdsRot.X, data.AdsRot.Y, data.AdsRot.Z
				ui.AdsRotX.SetValue(adsRotX); ui.AdsRotY.SetValue(adsRotY); ui.AdsRotZ.SetValue(adsRotZ)
			end
			if data.AdsMobPos then
				adsMobileX, adsMobileY, adsMobileZ = data.AdsMobPos.X, data.AdsMobPos.Y, data.AdsMobPos.Z
				ui.AdsMobileX.SetValue(adsMobileX); ui.AdsMobileY.SetValue(adsMobileY); ui.AdsMobileZ.SetValue(adsMobileZ)
			end
			if data.AdsMobRot then
				adsMobileRotX, adsMobileRotY, adsMobileRotZ = data.AdsMobRot.X, data.AdsMobRot.Y, data.AdsMobRot.Z
				ui.AdsMobileRotX.SetValue(adsMobileRotX); ui.AdsMobileRotY.SetValue(adsMobileRotY); ui.AdsMobileRotZ.SetValue(adsMobileRotZ)
			end
			
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
	
	-- Save current values
	presets[name] = {
		Pos = {X=posX, Y=posY, Z=posZ},
		Rot = {X=rotX, Y=rotY, Z=rotZ},
		AdsPos = {X=adsX, Y=adsY, Z=adsZ},
		AdsRot = {X=adsRotX, Y=adsRotY, Z=adsRotZ},
		AdsMobPos = {X=adsMobileX, Y=adsMobileY, Z=adsMobileZ},
		AdsMobRot = {X=adsMobileRotX, Y=adsMobileRotY, Z=adsMobileRotZ},
	}
	
	plugin:SetSetting(PRESETS_KEY, presets)
	renderPresets()
	ui.StatusLabel.Text = "Saved Preset: " .. name
	ui.PresetNameInput.Text = ""
end)

-- Print Output
ui.CopyButton.MouseButton1Click:Connect(function()
	local code = string.format([[
-- Viewmodel
ViewmodelPosition = Vector3.new(%.3f, %.3f, %.3f),
ViewmodelRotation = Vector3.new(%.0f, %.0f, %.0f),

-- Skin: %s
ADS_Position = Vector3.new(%.3f, %.3f, %.3f),
ADS_Rotation = Vector3.new(%.0f, %.0f, %.0f),
ADS_Position_Mobile = Vector3.new(%.3f, %.3f, %.3f),
ADS_Rotation_Mobile = Vector3.new(%.0f, %.0f, %.0f),
]], posX, posY, posZ, rotX, rotY, rotZ, currentSkinName or "Default Skin",
	adsX, adsY, adsZ, adsRotX, adsRotY, adsRotZ,
	adsMobileX, adsMobileY, adsMobileZ, adsMobileRotX, adsMobileRotY, adsMobileRotZ)
	
	print("=== VIEWMODEL VALUES ===")
	print(code)
	print("========================")
	ui.StatusLabel.Text = "Values printed to Output!"
end)

-- FOV Handling
local originalFOV = 70
local camera = workspace.CurrentCamera

local function updateFOV()
	if isADSPreview and currentWeaponName then
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

-- Hook into Toggle Button
local originalToggleADS = ui.ADSToggle.MouseButton1Click
-- We can't really "hook" the existing event without modifying the connection variable which we don't have access to easily if it's anonymous.
-- However, we can just ADD a new connection since they run in order/parallel.
-- Actually, the previous connection just toggles the boolean. We can add another one.

ui.ADSToggle.MouseButton1Click:Connect(function()
	-- The boolean is already toggled by the first connection above (lines 546)
	-- We just need to update FOV
	if isADSPreview then
		originalFOV = camera.FieldOfView -- Capture current FOV before switching (usually 70)
		-- Safety check: if we are already zoomed in from previous glitch, maybe reset to default
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
		
		vm:SetAttribute("Editor_HipPos", Vector3.new(posX, posY, posZ))
		vm:SetAttribute("Editor_HipRot", Vector3.new(rotX, rotY, rotZ))
		
		if isMobilePreview then
			vm:SetAttribute("Editor_AdsPos", Vector3.new(adsMobileX, adsMobileY, adsMobileZ))
			vm:SetAttribute("Editor_AdsRot", Vector3.new(adsMobileRotX, adsMobileRotY, adsMobileRotZ))
		else
			vm:SetAttribute("Editor_AdsPos", Vector3.new(adsX, adsY, adsZ))
			vm:SetAttribute("Editor_AdsRot", Vector3.new(adsRotX, adsRotY, adsRotZ))
		end
		
		-- Optional: Force ADS state from plugin toggle
		-- vm:SetAttribute("Editor_ForceADS", isADSPreview) 
		-- (For now we let game logic handle ADS state, unless we want to debug specific pose)
	end
end)

print("[Viewmodel Editor] Plugin loaded with ADS support & FOV Preview!")
