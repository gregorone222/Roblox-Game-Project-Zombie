-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

-- ViewmodelEditorPlugin.lua
-- A Roblox Studio Plugin for editing Viewmodel Position, Rotation, and ADS in real-time
-- Save this file to: %localappdata%\Roblox\Plugins\ViewmodelEditorPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local CoreGui = game:GetService("CoreGui")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

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

-- Handles for visual positioning (REMOVED - WYSIWYG mode)
-- local showHandles = false
-- local moveHandles = nil
-- local rotateHandles = nil
-- local handlesPart = nil -- Invisible part for handles to attach

-- ViewportFrame Preview (REMOVED - WYSIWYG mode)
-- local viewportFrame = nil
-- local viewportCamera = nil
-- local viewportModel = nil
-- local viewportAnimator = nil
-- local viewportAnimTrack = nil

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

-- Constants
local PRESETS_KEY = "ViewmodelEditor_Presets_v2"
local STEP_SIZE = 0.05 -- Step size for keyboard adjustments
local ROT_STEP = 1.0  -- Rotation step size in degrees
local FINE_MULT = 0.2 -- Multiplier for fine adjustment (Shift)
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

	-- [REDACTED] ViewportFrame removed for WYSIWYG Mode
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 60)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "WYSIWYG MODE - Use Keyboard (HOLD):\\nArrow Keys: X/Y | W/S: Z (Maju/Mundur)\\nQ/E: Pitch | Z/C: Yaw | R/T: Roll\\nShift: Fine Adjust"
	infoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	infoLabel.TextSize = 11
	infoLabel.Font = Enum.Font.GothamMedium
	infoLabel.Parent = scrollFrame
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

	-- Handles Toggle Button (REMOVED - WYSIWYG mode)
	-- local handlesToggle = Instance.new("TextButton")
	-- handlesToggle.Name = "HandlesToggle"
	-- handlesToggle.Size = UDim2.new(0, 70, 0, 30)
	-- handlesToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	-- handlesToggle.Text = "📐 Handles"
	-- handlesToggle.TextColor3 = Color3.new(1, 1, 1)
	-- handlesToggle.TextSize = 10
	-- handlesToggle.Font = Enum.Font.GothamMedium
	-- handlesToggle.Parent = toggleFrame
	-- Instance.new("UICorner", handlesToggle).CornerRadius = UDim.new(0, 4)

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

		-- ViewportFrame removed, so no viewportModel or viewportAnimator
		-- This function will now only update the status label, as the actual animation
		-- will be handled by the in-game system in WYSIWYG mode.

		if not currentTool then 
			if statusLabel then statusLabel.Text = "No weapon selected!" end
			return 
		end

		if not currentWeaponAnimations then 
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

		-- In WYSIWYG mode, we don't play animations in the plugin UI.
		-- We just indicate that an animation is selected.
		if statusLabel then statusLabel.Text = "Selected: " .. animKey .. " animation." end
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

	local copyFrame = Instance.new("Frame")
	copyFrame.Size = UDim2.new(1, 0, 0, 30)
	copyFrame.BackgroundTransparency = 1
	copyFrame.LayoutOrder = 82
	copyFrame.Parent = scrollFrame

	local copyButton = Instance.new("TextButton")
	copyButton.Name = "CopyButton"
	copyButton.Size = UDim2.new(0.65, -4, 1, 0)
	copyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
	copyButton.Text = "Print to Output"
	copyButton.TextColor3 = Color3.new(1, 1, 1)
	copyButton.TextSize = 12
	copyButton.Font = Enum.Font.GothamMedium
	copyButton.Parent = copyFrame
	Instance.new("UICorner", copyButton).CornerRadius = UDim.new(0, 6)

	local quickCopyButton = Instance.new("TextButton")
	quickCopyButton.Name = "QuickCopyButton"
	quickCopyButton.Size = UDim2.new(0.35, 0, 1, 0)
	quickCopyButton.Position = UDim2.new(0.65, 4, 0, 0)
	quickCopyButton.BackgroundColor3 = Color3.fromRGB(150, 80, 150)
	quickCopyButton.Text = "📋 Copy"
	quickCopyButton.TextColor3 = Color3.new(1, 1, 1)
	quickCopyButton.TextSize = 12
	quickCopyButton.Font = Enum.Font.GothamMedium
	quickCopyButton.Parent = copyFrame
	Instance.new("UICorner", quickCopyButton).CornerRadius = UDim.new(0, 6)

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
		QuickCopyButton = quickCopyButton,
		-- Viewmodel Position/Rotation (now per-animation)
		PosX = posXSlider, PosY = posYSlider, PosZ = posZSlider,
		RotX = rotXSlider, RotY = rotYSlider, RotZ = rotZSlider,
		HitmarkerToggle = hitmarkerToggle,
		-- HandlesToggle = handlesToggle, -- [x] 1. Remove ViewportFrame & Workspace Rig
		TargetSelector = targetSelector,
		-- ViewportFrame Preview (REMOVED - WYSIWYG mode)
		-- ViewportFrame = vpFrame,
		-- ViewportCamera = vpCamera,
		-- ViewportWorldModel = vpWorldModel, -- For animation support
		-- Mobile Overlay
		DeviceButtons = deviceButtons,
		UpdateDeviceButtons = updateDeviceButtons,

		-- Helper for Status
		SetStatus = function(text, type)
			statusLabel.Text = text
			if type == "error" then
				statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			elseif type == "success" then
				statusLabel.TextColor3 = Color3.fromRGB(80, 255, 100)
			else
				statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
			end

			-- Auto clear after 4s
			task.delay(4, function()
				if statusLabel.Text == text then
					statusLabel.Text = ""
				end
			end)
		end
	}
end

local ui = createUI()

-- [REDACTED] Viewport Model Functions removed for WYSIWYG
local function updateViewportPosition()
	-- No-op
end

-- Workspace Rig System (for 3D editing)
local workspaceRig = nil
local cameraRefPart = nil
local workspaceHandles = nil
local workspaceArcHandles = nil

-- [REDACTED] Workspace Rig Functions removed for WYSIWYG
local function clearWorkspaceRig()
	-- No-op
end

local function loadWorkspaceRig(tool)
	-- No-op
end

local function loadViewportModel(tool)
	-- No-op
end

local function playViewportAnimation(animId)
	-- [REMOVED] No longer needed in WYSIWYG mode
	-- Animation is handled by the game's HybridViewmodel system
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

-- [REMOVED] Handles Functions for Visual Positioning - No longer needed in WYSIWYG mode

-- Consolidated Render Loop (WYSIWYG Mode)
RunService.RenderStepped:Connect(function()
	-- Only Live Edit Logic needed now
	if isActive then
		if not RunService:IsRunning() then
			-- Show warning if not in Play Mode
			ui.StatusLabel.Text = "⚠️ MUST BE IN PLAY MODE TO EDIT!"
			ui.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			return
		end

		-- Sync Attributes
		local cam = workspace.CurrentCamera
		if cam then
			local vm = cam:FindFirstChild("HybridViewmodel")
			if vm then
				vm:SetAttribute("Editor_AnimPos", Vector3.new(posX, posY, posZ))
				vm:SetAttribute("Editor_AnimRot", Vector3.new(rotX, rotY, rotZ))
				vm:SetAttribute("Editor_AnimState", selectedAnimState)
				-- ui.StatusLabel.Text = "Live Editing: " .. selectedAnimState
			end
		end
	end
end)

-- [NEW] Keyboard Input Handler for WYSIWYG - HOLD MODE
-- Process held keys every frame for continuous movement
local function processKeyboardInput()
	if not isActive then return end
	if not RunService:IsRunning() then return end -- Only working in Play Mode

	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	local delta = shift and STEP_SIZE * FINE_MULT or STEP_SIZE
	local rotDelta = shift and ROT_STEP * FINE_MULT or ROT_STEP

	-- Position Adjustments (Arrow Keys + W/S for Z)
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		posY = posY + delta
		ui.PosY.SetValue(posY)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		posY = posY - delta
		ui.PosY.SetValue(posY)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		posX = posX + delta
		ui.PosX.SetValue(posX)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		posX = posX - delta
		ui.PosX.SetValue(posX)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then -- Z Forward (closer)
		posZ = posZ - delta
		ui.PosZ.SetValue(posZ)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then -- Z Backward (farther)
		posZ = posZ + delta
		ui.PosZ.SetValue(posZ)
	end

	-- Rotation Adjustments
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then -- Pitch Up
		rotX = rotX + rotDelta
		ui.RotX.SetValue(rotX)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then -- Pitch Down
		rotX = rotX - rotDelta
		ui.RotX.SetValue(rotX)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.C) then -- Yaw Right
		rotY = rotY + rotDelta
		ui.RotY.SetValue(rotY)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Z) then -- Yaw Left
		rotY = rotY - rotDelta
		ui.RotY.SetValue(rotY)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.T) then -- Roll Right
		rotZ = rotZ + rotDelta
		ui.RotZ.SetValue(rotZ)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.R) then -- Roll Left
		rotZ = rotZ - rotDelta
		ui.RotZ.SetValue(rotZ)
	end
end

-- Run keyboard input processing every frame
RunService.RenderStepped:Connect(processKeyboardInput)
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

		ui.SetStatus("Updated! Animation refreshed.", "success")

		-- Auto-Refresh View
		loadAnimationPosition()

	else
		ui.SetStatus("Warning: No changes for " .. selectedAnimState .. " in " .. targetWeaponName, "warn")
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
		item.Size = UDim2.new(1, 0, 0, 36) -- Increased height for details
		item.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		item.BorderSizePixel = 0
		item.Parent = ui.PresetsList

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.6, 0, 0.5, 0)
		label.Position = UDim2.new(0, 4, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 12
		label.Font = Enum.Font.GothamBold
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = item

		local subLabel = Instance.new("TextLabel")
		subLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		subLabel.Position = UDim2.new(0, 4, 0.5, 0)
		subLabel.BackgroundTransparency = 1
		local wName = data.Weapon or "Any"
		subLabel.Text = wName .. " (" .. (data.AnimState or "Unknown") .. ")"
		subLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		subLabel.TextSize = 10
		subLabel.Font = Enum.Font.Gotham
		subLabel.TextXAlignment = Enum.TextXAlignment.Left
		subLabel.Parent = item

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


			-- Note: ADS presets removed - positions are now per-animation

			ui.SetStatus("Loaded Preset: " .. name, "success")
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
			presets[name] = nil
			plugin:SetSetting(PRESETS_KEY, presets)
			renderPresets()
			ui.SetStatus("Deleted Preset: " .. name, "warn")
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
	-- Save current values (per-animation - saves current position)
	presets[name] = {
		AnimState = selectedAnimState,
		Pos = {X=posX, Y=posY, Z=posZ},
		Rot = {X=rotX, Y=rotY, Z=rotZ},
		Weapon = targetWeaponName or "None"
	}

	plugin:SetSetting(PRESETS_KEY, presets)
	renderPresets()
	ui.SetStatus("Saved Preset: " .. name, "success")
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
	ui.SetStatus("Values printed to Output!", "success")
end)

-- Quick Copy
ui.QuickCopyButton.MouseButton1Click:Connect(function()
	local code = string.format([[
%s = {
	Id = "%s",
	Position = Vector3.new(%.3f, %.3f, %.3f),
	Rotation = Vector3.new(%.0f, %.0f, %.0f)
},]], selectedAnimState, 
		currentWeaponAnimations and currentWeaponAnimations[selectedAnimState] and 
			(type(currentWeaponAnimations[selectedAnimState]) == "table" and currentWeaponAnimations[selectedAnimState].Id or currentWeaponAnimations[selectedAnimState]) or "rbxassetid://",
		posX, posY, posZ, rotX, rotY, rotZ)

	-- In Studio, we can't write to clipboard directly via script for security, 
	-- but we can output minimal specific code that is easy to select
	print(code)
	ui.SetStatus("Code printed to output. Select & Copy!", "success")
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
-- Removed duplicate RenderStepped (merged with first one)

print("[Viewmodel Editor] Plugin loaded with per-animation position support!")
