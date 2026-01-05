-- MeleeViewmodelOffsetEditor.lua
-- A Roblox Studio Plugin for editing Melee Viewmodel Position/Rotation offsets in REAL-TIME
-- Sliders update viewmodel position instantly when weapon is equipped
-- Save to: %localappdata%\Roblox\Plugins\MeleeViewmodelOffsetEditor.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Melee VM Editor")
local toggleButton = toolbar:CreateButton(
	"Melee VM Offset",
	"Edit melee viewmodel position/rotation offsets in real-time",
	"rbxassetid://6031071053"
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	380,
	480,
	320,
	400
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("MeleeVMOffsetWidget", widgetInfo)
widget.Title = "Melee VM Offset Editor"

-- State
local isActive = false
local selectedWeapon = nil
local WeaponModule = nil

-- Current offset values
local posX, posY, posZ = 0, -1.5, -2
local rotX, rotY, rotZ = 0, 0, 0

-- Create or get the offset values in ReplicatedStorage for real-time sync
local function getOrCreateOffsetFolder()
	local folder = ReplicatedStorage:FindFirstChild("VMOffsetEditor")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "VMOffsetEditor"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function updateOffsetValues()
	local folder = getOrCreateOffsetFolder()
	
	-- Create or update position value
	local posValue = folder:FindFirstChild("Position")
	if not posValue then
		posValue = Instance.new("Vector3Value")
		posValue.Name = "Position"
		posValue.Parent = folder
	end
	posValue.Value = Vector3.new(posX, posY, posZ)
	
	-- Create or update rotation value
	local rotValue = folder:FindFirstChild("Rotation")
	if not rotValue then
		rotValue = Instance.new("Vector3Value")
		rotValue.Name = "Rotation"
		rotValue.Parent = folder
	end
	rotValue.Value = Vector3.new(rotX, rotY, rotZ)
	
	-- Set active flag
	local activeValue = folder:FindFirstChild("Active")
	if not activeValue then
		activeValue = Instance.new("BoolValue")
		activeValue.Name = "Active"
		activeValue.Parent = folder
	end
	activeValue.Value = true
end

local function disableOffsetEditor()
	local folder = ReplicatedStorage:FindFirstChild("VMOffsetEditor")
	if folder then
		local activeValue = folder:FindFirstChild("Active")
		if activeValue then
			activeValue.Value = false
		end
	end
end

-- Load WeaponModule
local function loadWeaponModule()
	local mod = ReplicatedStorage:FindFirstChild("ModuleScript")
	if mod then mod = mod:FindFirstChild("WeaponModule") end
	if not mod then mod = ReplicatedStorage:FindFirstChild("WeaponModule", true) end
	
	if mod then
		local success, result = pcall(function() return require(mod) end)
		if success then
			WeaponModule = result
			return true
		end
	end
	return false
end

-- Get all melee weapon names
local function getMeleeWeapons()
	local names = {}
	if WeaponModule and WeaponModule.Weapons then
		for k, v in pairs(WeaponModule.Weapons) do
			if v.IsMelee then
				table.insert(names, k)
			end
		end
		table.sort(names)
	end
	return names
end

-- Load offset for current weapon
local function loadCurrentOffset()
	if not WeaponModule or not selectedWeapon then return end
	
	local weaponData = WeaponModule.Weapons[selectedWeapon]
	if not weaponData then return end
	
	local vmAnims = weaponData.ViewmodelAnimations
	if vmAnims and vmAnims.Hold then
		local animData = vmAnims.Hold
		if type(animData) == "table" then
			if animData.Position then
				posX = animData.Position.X
				posY = animData.Position.Y
				posZ = animData.Position.Z
			end
			if animData.Rotation then
				rotX = animData.Rotation.X
				rotY = animData.Rotation.Y
				rotZ = animData.Rotation.Z
			end
		end
	end
end

-- Create UI
local function createUI()
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
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scrollFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = scrollFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "🗡️ Melee VM Offset Editor"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.LayoutOrder = 1
	title.Parent = scrollFrame
	
	-- Info label
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 35)
	infoLabel.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	infoLabel.Text = "⚡ REAL-TIME: Sliders update viewmodel instantly when weapon equipped!"
	infoLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	infoLabel.TextSize = 10
	infoLabel.TextWrapped = true
	infoLabel.Font = Enum.Font.GothamMedium
	infoLabel.LayoutOrder = 2
	infoLabel.Parent = scrollFrame
	Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 4)
	
	-- Section Header Helper
	local function createSectionHeader(text, parent, order)
		local header = Instance.new("TextLabel")
		header.Size = UDim2.new(1, 0, 0, 25)
		header.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		header.Text = text
		header.TextColor3 = Color3.new(1, 1, 1)
		header.TextSize = 12
		header.Font = Enum.Font.GothamBold
		header.LayoutOrder = order
		header.Parent = parent
		Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)
		return header
	end
	
	-- Weapon Dropdown
	createSectionHeader("🎯 Select Weapon", scrollFrame, 3)
	
	local weaponFrame = Instance.new("Frame")
	weaponFrame.Size = UDim2.new(1, 0, 0, 35)
	weaponFrame.BackgroundTransparency = 1
	weaponFrame.LayoutOrder = 4
	weaponFrame.Parent = scrollFrame
	
	local weaponBtn = Instance.new("TextButton")
	weaponBtn.Size = UDim2.new(1, 0, 0, 30)
	weaponBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	weaponBtn.Text = "Select Weapon..."
	weaponBtn.TextColor3 = Color3.new(1, 1, 1)
	weaponBtn.TextSize = 12
	weaponBtn.Font = Enum.Font.Gotham
	weaponBtn.Parent = weaponFrame
	Instance.new("UICorner", weaponBtn).CornerRadius = UDim.new(0, 4)
	
	local dropdownList = nil
	local isDropdownOpen = false
	
	-- Slider Helper
	local sliders = {}
	local function createSlider(name, label, min, max, default, step, callback, parent, order)
		local group = Instance.new("Frame")
		group.Name = name .. "Group"
		group.Size = UDim2.new(1, 0, 0, 45)
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
		
		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, 0, 0, 24)
		sliderFrame.Position = UDim2.new(0, 0, 0, 18)
		sliderFrame.BackgroundTransparency = 1
		sliderFrame.Parent = group
		
		local track = Instance.new("Frame")
		track.Name = "Track"
		track.Size = UDim2.new(0.65, 0, 0, 6)
		track.Position = UDim2.new(0, 0, 0.5, -3)
		track.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		track.BorderSizePixel = 0
		track.Parent = sliderFrame
		Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
		
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		fill.BorderSizePixel = 0
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
		
		local inputBox = Instance.new("TextBox")
		inputBox.Size = UDim2.new(0.3, -5, 1, 0)
		inputBox.Position = UDim2.new(0.7, 5, 0, 0)
		inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		inputBox.TextColor3 = Color3.new(1, 1, 1)
		inputBox.Text = string.format("%.2f", default)
		inputBox.TextSize = 12
		inputBox.Font = Enum.Font.Gotham
		inputBox.Parent = sliderFrame
		Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 3)
		
		local dragging = false
		
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
			end
		end)
		
		track.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		
		track.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local relativeX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				local value = min + relativeX * (max - min)
				value = math.floor(value / step + 0.5) * step
				fill.Size = UDim2.new(relativeX, 0, 1, 0)
				inputBox.Text = string.format("%.2f", value)
				callback(value)
				updateOffsetValues()  -- Real-time update!
			end
		end)
		
		inputBox.FocusLost:Connect(function()
			local value = tonumber(inputBox.Text)
			if value then
				value = math.clamp(value, min, max)
				value = math.floor(value / step + 0.5) * step
				inputBox.Text = string.format("%.2f", value)
				fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
				callback(value)
				updateOffsetValues()  -- Real-time update!
			else
				inputBox.Text = string.format("%.2f", default)
			end
		end)
		
		sliders[name] = {
			SetValue = function(val)
				val = math.clamp(val, min, max)
				inputBox.Text = string.format("%.2f", val)
				fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
			end,
			GetValue = function()
				return tonumber(inputBox.Text) or default
			end
		}
		
		return sliders[name]
	end
	
	-- Position Sliders
	createSectionHeader("📍 Position Offset", scrollFrame, 10)
	local posXSlider = createSlider("PosX", "X Position", -5, 5, posX, 0.01, function(v) posX = v end, scrollFrame, 11)
	local posYSlider = createSlider("PosY", "Y Position", -5, 5, posY, 0.01, function(v) posY = v end, scrollFrame, 12)
	local posZSlider = createSlider("PosZ", "Z Position", -10, 2, posZ, 0.01, function(v) posZ = v end, scrollFrame, 13)
	
	-- Rotation Sliders
	createSectionHeader("🔄 Rotation Offset", scrollFrame, 20)
	local rotXSlider = createSlider("RotX", "X Rotation (°)", -180, 180, rotX, 1, function(v) rotX = v end, scrollFrame, 21)
	local rotYSlider = createSlider("RotY", "Y Rotation (°)", -180, 180, rotY, 1, function(v) rotY = v end, scrollFrame, 22)
	local rotZSlider = createSlider("RotZ", "Z Rotation (°)", -180, 180, rotZ, 1, function(v) rotZ = v end, scrollFrame, 23)
	
	-- Apply Button
	createSectionHeader("💾 Actions", scrollFrame, 30)
	
	local copyBtn = Instance.new("TextButton")
	copyBtn.Size = UDim2.new(1, 0, 0, 35)
	copyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
	copyBtn.Text = "📋 Copy Values to Output"
	copyBtn.TextColor3 = Color3.new(1, 1, 1)
	copyBtn.TextSize = 14
	copyBtn.Font = Enum.Font.GothamBold
	copyBtn.LayoutOrder = 31
	copyBtn.Parent = scrollFrame
	Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)
	
	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	statusLabel.TextSize = 11
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextWrapped = true
	statusLabel.LayoutOrder = 40
	statusLabel.Parent = scrollFrame
	
	-- Update sliders from loaded values
	local function updateSliders()
		posXSlider.SetValue(posX)
		posYSlider.SetValue(posY)
		posZSlider.SetValue(posZ)
		rotXSlider.SetValue(rotX)
		rotYSlider.SetValue(rotY)
		rotZSlider.SetValue(rotZ)
		updateOffsetValues()
	end
	
	-- Status helper
	local function setStatus(text, statusType)
		statusLabel.Text = text
		if statusType == "error" then
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		elseif statusType == "success" then
			statusLabel.TextColor3 = Color3.fromRGB(80, 255, 100)
		else
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		end
		task.delay(4, function()
			if statusLabel.Text == text then statusLabel.Text = "" end
		end)
	end
	
	-- Weapon dropdown logic
	weaponBtn.MouseButton1Click:Connect(function()
		isDropdownOpen = not isDropdownOpen
		if isDropdownOpen then
			local weapons = getMeleeWeapons()
			dropdownList = Instance.new("ScrollingFrame")
			dropdownList.Size = UDim2.new(1, 0, 0, math.min(#weapons * 27, 150))
			dropdownList.Position = UDim2.new(0, 0, 1, 2)
			dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			dropdownList.BorderSizePixel = 0
			dropdownList.ZIndex = 10
			dropdownList.Parent = weaponBtn
			
			local listLayout = Instance.new("UIListLayout")
			listLayout.Padding = UDim.new(0, 2)
			listLayout.Parent = dropdownList
			
			for _, wName in ipairs(weapons) do
				local item = Instance.new("TextButton")
				item.Size = UDim2.new(1, 0, 0, 25)
				item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				item.Text = wName
				item.TextColor3 = Color3.new(1, 1, 1)
				item.TextSize = 12
				item.ZIndex = 11
				item.Parent = dropdownList
				
				item.MouseButton1Click:Connect(function()
					selectedWeapon = wName
					weaponBtn.Text = wName
					if dropdownList then dropdownList:Destroy() dropdownList = nil end
					isDropdownOpen = false
					loadCurrentOffset()
					updateSliders()
					setStatus("Loaded offsets for: " .. wName .. "\nEquip weapon to see changes!", "success")
				end)
			end
			dropdownList.CanvasSize = UDim2.new(0, 0, 0, #weapons * 27)
		else
			if dropdownList then dropdownList:Destroy() dropdownList = nil end
		end
	end)
	
	-- Copy button logic
	copyBtn.MouseButton1Click:Connect(function()
		if not selectedWeapon then
			setStatus("Select a weapon first!", "error")
			return
		end
		
		local posStr = string.format("Vector3.new(%.2f, %.2f, %.2f)", posX, posY, posZ)
		local rotStr = string.format("Vector3.new(%.2f, %.2f, %.2f)", rotX, rotY, rotZ)
		
		-- Get animation ID if available
		local animId = "YOUR_ANIM_ID"
		if WeaponModule and WeaponModule.Weapons[selectedWeapon] then
			local vmAnims = WeaponModule.Weapons[selectedWeapon].ViewmodelAnimations
			if vmAnims and vmAnims.Hold then
				local holdData = vmAnims.Hold
				if type(holdData) == "table" and holdData.Id then
					animId = holdData.Id
				elseif type(holdData) == "string" then
					animId = holdData
				end
			end
		end
		
		print("\n========== MELEE VM OFFSET ==========")
		print("Weapon:", selectedWeapon)
		print("------")
		print("ViewmodelAnimations = {")
		print("    Hold = {")
		print("        Id = \"" .. animId .. "\",")
		print("        Position = " .. posStr .. ",")
		print("        Rotation = " .. rotStr)
		print("    },")
		print("    Attack = {")
		print("        Id = \"YOUR_ATTACK_ANIM_ID\",")
		print("        Position = " .. posStr .. ",")
		print("        Rotation = " .. rotStr)
		print("    }")
		print("}")
		print("======================================\n")
		
		setStatus("Values printed to Output! Copy to WeaponModule.", "success")
	end)
	
	return {
		UpdateSliders = updateSliders,
		SetStatus = setStatus
	}
end

-- Toggle Plugin
local ui = nil

local function togglePlugin()
	isActive = not isActive
	widget.Enabled = isActive
	toggleButton:SetActive(isActive)
	
	if isActive then
		loadWeaponModule()
		if not ui then
			ui = createUI()
		end
		updateOffsetValues()
	else
		disableOffsetEditor()
	end
end

toggleButton.Click:Connect(togglePlugin)
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	isActive = widget.Enabled
	toggleButton:SetActive(isActive)
	if not isActive then
		disableOffsetEditor()
	end
end)

print("[MeleeViewmodelOffsetEditor] Plugin loaded!")
print("[MeleeViewmodelOffsetEditor] Sliders update viewmodel in real-time when weapon equipped!")
