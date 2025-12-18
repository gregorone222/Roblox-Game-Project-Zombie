-- ViewmodelEditorPlugin.lua
-- A Roblox Studio Plugin for editing Viewmodel Position and Rotation in real-time
-- Save this file to: %localappdata%\Roblox\Plugins\ViewmodelEditorPlugin.lua
-- Or install via Plugin Manager in Roblox Studio

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Viewmodel Editor")
local toggleButton = toolbar:CreateButton(
	"Viewmodel Editor",
	"Edit viewmodel position and rotation in real-time",
	"rbxassetid://6031071053" -- Icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- Initially disabled
	false, -- Override previous enabled state
	400,   -- Default width
	600,   -- Default height
	300,   -- Minimum width
	400    -- Minimum height
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("ViewmodelEditorWidget", widgetInfo)
widget.Title = "Viewmodel Editor"

-- State
local isActive = false
local currentWeaponName = nil
local currentTool = nil
local previewModel = nil
local renderConnection = nil

local posX, posY, posZ = 1.5, -1, -2.5
local rotX, rotY, rotZ = 0, 0, 0

-- UI Creation
local function createUI()
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = widget

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = mainFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "Viewmodel Editor"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, 0, 0, 40)
	instructions.BackgroundTransparency = 1
	instructions.Text = "1. Select a Tool (weapon) in Explorer\n2. Adjust sliders below\n3. Click 'Apply to WeaponModule'"
	instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
	instructions.TextSize = 12
	instructions.Font = Enum.Font.Gotham
	instructions.TextWrapped = true
	instructions.Parent = mainFrame

	-- Selected Weapon Display
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Size = UDim2.new(1, 0, 0, 25)
	selectedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	selectedLabel.Text = "Selected: None"
	selectedLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
	selectedLabel.TextSize = 14
	selectedLabel.Font = Enum.Font.GothamMedium
	selectedLabel.Parent = mainFrame

	-- Helper function to create slider group
	local function createSliderGroup(name, label, min, max, default, step, callback)
		local group = Instance.new("Frame")
		group.Name = name .. "Group"
		group.Size = UDim2.new(1, 0, 0, 50)
		group.BackgroundTransparency = 1
		group.Parent = mainFrame

		local groupLayout = Instance.new("UIListLayout")
		groupLayout.FillDirection = Enum.FillDirection.Vertical
		groupLayout.Padding = UDim.new(0, 2)
		groupLayout.Parent = group

		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.new(1, 0, 0, 16)
		labelText.BackgroundTransparency = 1
		labelText.Text = label
		labelText.TextColor3 = Color3.new(1, 1, 1)
		labelText.TextSize = 12
		labelText.Font = Enum.Font.GothamMedium
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Parent = group

		local sliderFrame = Instance.new("Frame")
		sliderFrame.Size = UDim2.new(1, 0, 0, 30)
		sliderFrame.BackgroundTransparency = 1
		sliderFrame.Parent = group

		local slider = Instance.new("Frame")
		slider.Name = "SliderTrack"
		slider.Size = UDim2.new(0.7, 0, 0, 8)
		slider.Position = UDim2.new(0, 0, 0.5, -4)
		slider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		slider.BorderSizePixel = 0
		slider.Parent = sliderFrame

		local sliderCorner = Instance.new("UICorner")
		sliderCorner.CornerRadius = UDim.new(0, 4)
		sliderCorner.Parent = slider

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		fill.BorderSizePixel = 0
		fill.Parent = slider

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = fill

		local inputBox = Instance.new("TextBox")
		inputBox.Name = "ValueInput"
		inputBox.Size = UDim2.new(0.25, -5, 1, 0)
		inputBox.Position = UDim2.new(0.75, 5, 0, 0)
		inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		inputBox.TextColor3 = Color3.new(1, 1, 1)
		inputBox.Text = tostring(default)
		inputBox.TextSize = 14
		inputBox.Font = Enum.Font.Gotham
		inputBox.Parent = sliderFrame

		local inputCorner = Instance.new("UICorner")
		inputCorner.CornerRadius = UDim.new(0, 4)
		inputCorner.Parent = inputBox

		-- Slider interaction
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
				inputBox.Text = string.format("%.2f", value)
				callback(value)
			end
		end)

		inputBox.FocusLost:Connect(function(enterPressed)
			local value = tonumber(inputBox.Text)
			if value then
				value = math.clamp(value, min, max)
				value = math.floor(value / step + 0.5) * step
				inputBox.Text = string.format("%.2f", value)
				fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
				callback(value)
			else
				inputBox.Text = string.format("%.2f", default)
			end
		end)

		return {
			SetValue = function(val)
				val = math.clamp(val, min, max)
				inputBox.Text = string.format("%.2f", val)
				fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
			end
		}
	end

	-- Position Sliders
	local posXSlider = createSliderGroup("PosX", "Position X", -5, 5, posX, 0.1, function(v) posX = v end)
	local posYSlider = createSliderGroup("PosY", "Position Y", -5, 5, posY, 0.1, function(v) posY = v end)
	local posZSlider = createSliderGroup("PosZ", "Position Z", -10, 0, posZ, 0.1, function(v) posZ = v end)

	-- Rotation Sliders
	local rotXSlider = createSliderGroup("RotX", "Rotation X (degrees)", -180, 180, rotX, 1, function(v) rotX = v end)
	local rotYSlider = createSliderGroup("RotY", "Rotation Y (degrees)", -180, 180, rotY, 1, function(v) rotY = v end)
	local rotZSlider = createSliderGroup("RotZ", "Rotation Z (degrees)", -180, 180, rotZ, 1, function(v) rotZ = v end)

	-- Apply Button
	local applyButton = Instance.new("TextButton")
	applyButton.Name = "ApplyButton"
	applyButton.Size = UDim2.new(1, 0, 0, 40)
	applyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
	applyButton.Text = "Apply to WeaponModule"
	applyButton.TextColor3 = Color3.new(1, 1, 1)
	applyButton.TextSize = 16
	applyButton.Font = Enum.Font.GothamBold
	applyButton.Parent = mainFrame

	local applyCorner = Instance.new("UICorner")
	applyCorner.CornerRadius = UDim.new(0, 6)
	applyCorner.Parent = applyButton

	-- Copy Code Button
	local copyButton = Instance.new("TextButton")
	copyButton.Name = "CopyButton"
	copyButton.Size = UDim2.new(1, 0, 0, 35)
	copyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
	copyButton.Text = "Copy Values to Clipboard"
	copyButton.TextColor3 = Color3.new(1, 1, 1)
	copyButton.TextSize = 14
	copyButton.Font = Enum.Font.GothamMedium
	copyButton.Parent = mainFrame

	local copyCorner = Instance.new("UICorner")
	copyCorner.CornerRadius = UDim.new(0, 6)
	copyCorner.Parent = copyButton

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = mainFrame

	return {
		MainFrame = mainFrame,
		SelectedLabel = selectedLabel,
		StatusLabel = statusLabel,
		ApplyButton = applyButton,
		CopyButton = copyButton,
		PosX = posXSlider,
		PosY = posYSlider,
		PosZ = posZSlider,
		RotX = rotXSlider,
		RotY = rotYSlider,
		RotZ = rotZSlider
	}
end

local ui = createUI()

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
end

local function createPreview(tool)
	cleanupPreview()
	
	if not tool or not tool:IsA("Tool") then return end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- Clone the tool for preview
	previewModel = tool:Clone()
	previewModel.Name = "ViewmodelPreview"
	
	-- Get the preview handle reference
	local previewHandle = previewModel:FindFirstChild("Handle")
	
	-- Setup parts - ONLY anchor Handle, keep others unanchored so welds work
	for _, desc in pairs(previewModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CastShadow = false
			
			-- Only anchor the Handle, other parts should follow via welds
			if desc == previewHandle then
				desc.Anchored = true
			else
				desc.Anchored = false
			end
		elseif desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") then
			desc:Destroy()
		end
	end
	
	previewModel.Parent = workspace.CurrentCamera
	
	-- Render loop
	renderConnection = RunService.RenderStepped:Connect(function()
		if not previewModel or not previewModel.Parent then return end
		
		local ph = previewModel:FindFirstChild("Handle")
		if not ph then return end
		
		local camera = workspace.CurrentCamera
		local offset = CFrame.new(posX, posY, posZ)
		local rotation = CFrame.Angles(math.rad(rotX), math.rad(rotY), math.rad(rotZ))
		
		ph.CFrame = camera.CFrame * offset * rotation
	end)
end

-- Selection handling
local function onSelectionChanged()
	local selected = Selection:Get()
	if #selected == 1 and selected[1]:IsA("Tool") then
		currentTool = selected[1]
		currentWeaponName = currentTool.Name
		ui.SelectedLabel.Text = "Selected: " .. currentWeaponName
		
		-- Try to load existing values from WeaponModule
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
				if stats.ViewmodelPosition then
					posX = stats.ViewmodelPosition.X
					posY = stats.ViewmodelPosition.Y
					posZ = stats.ViewmodelPosition.Z
					ui.PosX.SetValue(posX)
					ui.PosY.SetValue(posY)
					ui.PosZ.SetValue(posZ)
				end
				if stats.ViewmodelRotation then
					rotX = stats.ViewmodelRotation.X
					rotY = stats.ViewmodelRotation.Y
					rotZ = stats.ViewmodelRotation.Z
					ui.RotX.SetValue(rotX)
					ui.RotY.SetValue(rotY)
					ui.RotZ.SetValue(rotZ)
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
	if not currentWeaponName then
		ui.StatusLabel.Text = "Error: No weapon selected!"
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
	
	-- Find and replace ViewmodelPosition
	local posPattern = '(%[%"' .. currentWeaponName:gsub("%-", "%%-") .. '"%].-ViewmodelPosition = Vector3%.new%()([^%)]+)(%))' 
	local newPosValue = string.format("%.2f, %.2f, %.2f", posX, posY, posZ)
	
	local newSource, posReplaced = source:gsub(posPattern, "%1" .. newPosValue .. "%3")
	
	if posReplaced > 0 then
		source = newSource
	end
	
	-- Find and replace ViewmodelRotation
	local rotPattern = '(%[%"' .. currentWeaponName:gsub("%-", "%%-") .. '"%].-ViewmodelRotation = Vector3%.new%()([^%)]+)(%))' 
	local newRotValue = string.format("%.0f, %.0f, %.0f", rotX, rotY, rotZ)
	
	local newSource2, rotReplaced = source:gsub(rotPattern, "%1" .. newRotValue .. "%3")
	
	if rotReplaced > 0 then
		source = newSource2
	end
	
	if posReplaced > 0 or rotReplaced > 0 then
		ChangeHistoryService:SetWaypoint("Viewmodel Edit: " .. currentWeaponName)
		weaponModuleScript.Source = source
		ChangeHistoryService:SetWaypoint("Viewmodel Edit Applied")
		ui.StatusLabel.Text = "Success! Applied to " .. currentWeaponName
	else
		ui.StatusLabel.Text = "Warning: Pattern not found in WeaponModule"
	end
end)

-- Copy Button
ui.CopyButton.MouseButton1Click:Connect(function()
	local code = string.format(
		"ViewmodelPosition = Vector3.new(%.2f, %.2f, %.2f),\nViewmodelRotation = Vector3.new(%.0f, %.0f, %.0f),",
		posX, posY, posZ, rotX, rotY, rotZ
	)
	
	-- Note: setClipboard is not available in plugins, so we'll just display it
	ui.StatusLabel.Text = "Copy this:\n" .. code
	print("=== COPY THIS ===")
	print(code)
	print("=================")
end)

-- Toggle Button
toggleButton.Click:Connect(function()
	isActive = not isActive
	widget.Enabled = isActive
	toggleButton:SetActive(isActive)
	
	if isActive then
		onSelectionChanged() -- Refresh selection
	else
		cleanupPreview()
	end
end)

-- Cleanup on unload
plugin.Unloading:Connect(function()
	cleanupPreview()
end)

print("[Viewmodel Editor] Plugin loaded successfully!")
