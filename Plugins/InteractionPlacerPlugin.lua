-- InteractionPlacerPlugin.lua
-- A Roblox Studio Plugin for placing interactive objects (Doors, Ammo, Shops)
-- Save this file to: %localappdata%\Roblox\Plugins\InteractionPlacerPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Level Design")
local toggleButton = toolbar:CreateButton(
	"Interaction Placer",
	"Drag & Drop interactive objects to map",
	"rbxassetid://6031071053" -- Generic Icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	300,
	400,
	250,
	300
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("InteractionPlacerWidget", widgetInfo)
widget.Title = "Interaction Placer"

-- Constants
local INTERACTION_TYPES = {
	"Generic Interaction",
	"Ammo Pickup",
	"Weapon Shop",
	"Door",
	"Mystery Box"
}

-- State
local currentState = {
	isActive = false,
	selectedType = "Generic Interaction",
	properties = {
		Name = "Interactable",
		Price = 0,
		Amount = 30,
		AmmoType = "Rifle",
		ActionText = "Interact",
		ObjectText = "Item",
		IsLocked = false
	}
}

local mouse = plugin:GetMouse()
local ghostPart = nil
local placementConnection = nil
local clickConnection = nil

-- UI Creation
local mainFrame = nil
local inputs = {} -- Store input fields to update them dynamically

local function updatePropertyInputs(scrollFrame)
	-- Clear old inputs (except generic ones if wanted, but simpler to rebuild)
	for _, c in ipairs(scrollFrame:GetChildren()) do
		if c.Name == "PropInput" then c:Destroy() end
	end
	
	local function createInput(label, key, defaultVal, isNumber)
		local container = Instance.new("Frame")
		container.Name = "PropInput"
		container.Size = UDim2.new(1, 0, 0, 30)
		container.BackgroundTransparency = 1
		container.Parent = scrollFrame
		
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.4, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = label
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Font = Enum.Font.Gotham
		lbl.Parent = container
		
		local input = Instance.new("TextBox")
		input.Size = UDim2.new(0.6, 0, 1, 0)
		input.Position = UDim2.new(0.4, 0, 0, 0)
		input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		input.TextColor3 = Color3.new(1,1,1)
		input.Text = tostring(currentState.properties[key] or defaultVal)
		input.Parent = container
		Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
		
		input.FocusLost:Connect(function()
			if isNumber then
				currentState.properties[key] = tonumber(input.Text) or 0
			else
				currentState.properties[key] = input.Text
			end
		end)
	end
	
	-- Common Inputs
	createInput("Name", "Name", "Part", false)
	
	-- Specific Inputs based on Type
	local t = currentState.selectedType
	if t == "Generic Interaction" then
		createInput("Action Text", "ActionText", "Interact", false)
		createInput("Object Text", "ObjectText", "Item", false)
	elseif t == "Ammo Pickup" then
		createInput("Ammo Type", "AmmoType", "Rifle", false)
		createInput("Amount", "Amount", 30, true)
	elseif t == "Weapon Shop" or t == "Door" or t == "Mystery Box" then
		createInput("Price", "Price", 500, true)
		if t == "Door" then
			-- Checkbox for locked? specialized UI needed, stick to basic inputs for now
			createInput("Action Text", "ActionText", "Open", false)
		end
		if t == "Weapon Shop" then
			createInput("Weapon Name", "WeaponName", "AK-47", false)
		end
	end
end

local function createUI()
	if mainFrame then mainFrame:Destroy() end
	
	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.Parent = widget
	
	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -20, 1, -60)
	content.Position = UDim2.new(0, 10, 0, 10)
	content.BackgroundTransparency = 1
	content.Parent = mainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = content
	
	-- Type Selector
	local typeLabel = Instance.new("TextLabel")
	typeLabel.Size = UDim2.new(1, 0, 0, 20)
	typeLabel.BackgroundTransparency = 1
	typeLabel.Text = "Interaction Type"
	typeLabel.TextColor3 = Color3.fromRGB(200,200,200)
	typeLabel.Parent = content
	
	for _, typeName in ipairs(INTERACTION_TYPES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 25)
		btn.BackgroundColor3 = (currentState.selectedType == typeName) and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(60, 60, 60)
		btn.Text = typeName
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Parent = content
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
		
		btn.MouseButton1Click:Connect(function()
			currentState.selectedType = typeName
			-- Refresh UI for validation/highlight logic could be added here
			createUI() -- Simple refresh
		end)
	end
	
	-- Separator
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, 0, 0, 2)
	sep.BackgroundColor3 = Color3.fromRGB(80,80,80)
	sep.Parent = content
	
	-- Properties
	local propLabel = Instance.new("TextLabel")
	propLabel.Size = UDim2.new(1, 0, 0, 20)
	propLabel.BackgroundTransparency = 1
	propLabel.Text = "Properties"
	propLabel.TextColor3 = Color3.fromRGB(200,200,200)
	propLabel.Parent = content
	
	updatePropertyInputs(content)
	
	-- Toggle Place Mode
	local placeBtn = Instance.new("TextButton")
	placeBtn.Size = UDim2.new(1, -20, 0, 40)
	placeBtn.Position = UDim2.new(0, 10, 1, -50)
	placeBtn.BackgroundColor3 = currentState.isActive and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 80)
	placeBtn.Text = currentState.isActive and "STOP PLACING" or "START PLACING"
	placeBtn.TextColor3 = Color3.new(1,1,1)
	placeBtn.Font = Enum.Font.GothamBold
	placeBtn.Parent = mainFrame
	Instance.new("UICorner", placeBtn).CornerRadius = UDim.new(0,4)
	
	placeBtn.MouseButton1Click:Connect(function()
		togglePlacement()
		placeBtn.Text = currentState.isActive and "STOP PLACING" or "START PLACING"
		placeBtn.BackgroundColor3 = currentState.isActive and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(0, 150, 80)
	end)
end

-- Placement Logic
function togglePlacement()
	currentState.isActive = not currentState.isActive
	
	if currentState.isActive then
		plugin:Activate(true)
		mouse.Icon = "rbxasset://SystemCursors/Cross"
		
		-- Create Ghost
		ghostPart = Instance.new("Part")
		ghostPart.Name = "Ghost"
		ghostPart.Size = Vector3.new(2, 2, 2)
		ghostPart.Transparency = 0.5
		ghostPart.Color = Color3.fromRGB(0, 255, 255)
		ghostPart.CanCollide = false
		ghostPart.Anchored = true
		ghostPart.Material = Enum.Material.Neon
		ghostPart.Parent = workspace
		
		placementConnection = RunService.RenderStepped:Connect(function()
			if ghostPart then
				ghostPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 1, 0))
			end
		end)
		
		clickConnection = mouse.Button1Down:Connect(placeObject)
	else
		plugin:Deactivate()
		mouse.Icon = ""
		if ghostPart then ghostPart:Destroy() end
		if placementConnection then placementConnection:Disconnect() end
		if clickConnection then clickConnection:Disconnect() end
	end
end

function placeObject()
	if not ghostPart then return end
	
	ChangeHistoryService:SetWaypoint("Pre-Place Interaction")
	
	local pos = ghostPart.Position
	local props = currentState.properties
	local t = currentState.selectedType
	
	local part = Instance.new("Part")
	part.Name = props.Name or "Interactable"
	part.Size = Vector3.new(2, 2, 2)
	part.Anchored = true
	part.Position = pos
	part.Color = Color3.fromRGB(150, 150, 150)
	part.Parent = workspace
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.HoldDuration = 0.5
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = part
	
	-- Config based on type
	if t == "Generic Interaction" then
		prompt.ActionText = props.ActionText or "Interact"
		prompt.ObjectText = props.ObjectText or "Item"
		
	elseif t == "Ammo Pickup" then
		prompt.ActionText = "Pickup Ammo"
		prompt.ObjectText = (props.Amount or 30) .. " " .. (props.AmmoType or "Rifle")
		part.Color = Color3.fromRGB(50, 150, 50)
		part:SetAttribute("AmmoType", props.AmmoType)
		part:SetAttribute("Amount", tonumber(props.Amount) or 30)
		part.Name = "AmmoPickup"
		
	elseif t == "Weapon Shop" then
		prompt.ActionText = "Buy Weapon"
		prompt.ObjectText = (props.WeaponName or "Gun") .. " [$".. (props.Price or 0) .."]"
		part.Color = Color3.fromRGB(50, 50, 200)
		part:SetAttribute("Price", tonumber(props.Price) or 500)
		part:SetAttribute("WeaponName", props.WeaponName or "AK-47")
		part.Name = "WeaponShop"
		
	elseif t == "Door" then
		prompt.ActionText = props.ActionText or "Open"
		prompt.ObjectText = "Door"
		if (tonumber(props.Price) or 0) > 0 then
			prompt.ObjectText = "Door [$".. props.Price .."]"
			part:SetAttribute("Price", tonumber(props.Price))
		end
		part.Size = Vector3.new(6, 8, 1) -- Door shape
		part.Position = pos + Vector3.new(0, 3, 0) -- Adjust height
		part.Name = "Door"
	end
	
	Selection:Set({part})
	ChangeHistoryService:SetWaypoint("Placed Interaction")
end

-- Cleanup
plugin.Unloading:Connect(function()
	if mainFrame then mainFrame:Destroy() end
	if ghostPart then ghostPart:Destroy() end
end)

-- Init
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		createUI()
	else
		if currentState.isActive then togglePlacement() end
	end
end)

print("[Interaction Placer] Plugin Loaded")
