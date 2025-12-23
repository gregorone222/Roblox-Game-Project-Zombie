-- FPS Animator Camera Plugin
-- Purpose: Lock Studio camera to a rig's Camera/Head part for FPS animation preview
-- Installation: Save this file to your Roblox Studio Plugins folder

local toolbar = plugin:CreateToolbar("FPS Animator")
local toggleButton = toolbar:CreateButton(
	"FPS Cam",
	"Lock camera to selected rig's camera part for FPS animation preview",
	"rbxassetid://6031075938" -- Camera icon
)

-- Services
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

-- State
local isLocked = false
local targetPart = nil
local connection = nil
local originalFOV = 70
local currentFOV = 70

-- UI Widget for FOV control
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- Initially disabled
	false, -- Override previous state
	200, -- Width
	120, -- Height
	150, -- Min Width
	100  -- Min Height
)
local widget = plugin:CreateDockWidgetPluginGuiAsync("FPSAnimatorSettings", widgetInfo)
widget.Title = "FPS Animator Camera"

-- Create simple UI
local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Parent = widget

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 25)
statusLabel.Position = UDim2.new(0, 5, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Text = "Status: Unlocked"
statusLabel.Parent = frame

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(1, -10, 0, 20)
fovLabel.Position = UDim2.new(0, 5, 0, 35)
fovLabel.BackgroundTransparency = 1
fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Text = "FOV: 70"
fovLabel.Parent = frame

local fovSlider = Instance.new("TextBox")
fovSlider.Size = UDim2.new(1, -10, 0, 25)
fovSlider.Position = UDim2.new(0, 5, 0, 55)
fovSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fovSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
fovSlider.Text = "70"
fovSlider.PlaceholderText = "Enter FOV (40-120)"
fovSlider.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -10, 0, 20)
infoLabel.Position = UDim2.new(0, 5, 0, 85)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextSize = 11
infoLabel.Text = "Select a rig, then click FPS Cam"
infoLabel.Parent = frame

fovSlider.FocusLost:Connect(function()
	local num = tonumber(fovSlider.Text)
	if num then
		currentFOV = math.clamp(num, 40, 120)
		fovLabel.Text = "FOV: " .. currentFOV
		if isLocked then
			workspace.CurrentCamera.FieldOfView = currentFOV
		end
	end
	fovSlider.Text = tostring(currentFOV)
end)

-- Find camera part in a rig
local function findCameraPart(model)
	-- Priority order for camera part detection
	local searchNames = {"Camera", "CameraPart", "CameraBone", "Head", "HumanoidRootPart"}

	for _, name in ipairs(searchNames) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end

	-- Fallback: return first BasePart found
	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			return child
		end
	end

	return nil
end

-- Get the rig from selection
local function getRigFromSelection()
	local selected = Selection:Get()
	if #selected == 0 then return nil end

	local obj = selected[1]

	-- If selected is a BasePart, check if parent is a Model (rig)
	if obj:IsA("BasePart") then
		if obj.Parent and obj.Parent:IsA("Model") then
			return obj.Parent, obj -- Return rig and the selected part as camera target
		else
			return nil, obj -- Just use the part directly
		end
	elseif obj:IsA("Model") then
		return obj, nil
	end

	return nil
end

-- Unlock camera
local function unlockCamera()
	if connection then
		connection:Disconnect()
		connection = nil
	end

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = originalFOV

	isLocked = false
	targetPart = nil
	toggleButton:SetActive(false)
	statusLabel.Text = "Status: Unlocked"
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	print("[FPS Animator] Camera unlocked")
end

-- Lock camera to target
local function lockCamera()
	local camera = workspace.CurrentCamera

	local rig, directPart = getRigFromSelection()

	if directPart then
		targetPart = directPart
	elseif rig then
		targetPart = findCameraPart(rig)
	else
		warn("[FPS Animator] Please select a Rig or Part first!")
		return false
	end

	if not targetPart then
		warn("[FPS Animator] Could not find a suitable camera part in the rig!")
		return false
	end

	-- Store original FOV and set custom
	originalFOV = camera.FieldOfView
	camera.FieldOfView = currentFOV
	camera.CameraType = Enum.CameraType.Scriptable

	-- Update loop
	connection = RunService.RenderStepped:Connect(function()
		if targetPart and targetPart.Parent then
			-- Position camera at the part, looking forward
			camera.CFrame = targetPart.CFrame
		else
			-- Part was deleted, unlock
			unlockCamera()
		end
	end)

	isLocked = true
	toggleButton:SetActive(true)
	statusLabel.Text = "Status: LOCKED to " .. targetPart.Name
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

	print("[FPS Animator] Camera locked to:", targetPart:GetFullName())
	return true
end

-- Toggle button handler
toggleButton.Click:Connect(function()
	if isLocked then
		unlockCamera()
	else
		lockCamera()
		widget.Enabled = true -- Show settings widget
	end
end)

-- Cleanup on plugin unload
plugin.Unloading:Connect(function()
	if isLocked then
		unlockCamera()
	end
end)

print("[FPS Animator Camera] Plugin loaded! Select a rig and click 'FPS Cam' to lock the camera.")
