-- WeaponEditorPlugin.lua
-- A Roblox Studio Plugin for balancing Weapon Stats (Damage, Recoil, FireRate, etc.)
-- Save this file to: %localappdata%\Roblox\Plugins\WeaponEditorPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Game Balancing")
local toggleButton = toolbar:CreateButton(
	"Weapon Editor",
	"Edit weapon stats in a spreadsheet view",
	"rbxassetid://6031071053" -- Generic Edit Icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	800,
	500,
	600,
	300
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("WeaponEditorWidget", widgetInfo)
widget.Title = "Weapon Data Editor"

-- Data
local weaponsData = {} -- Stores current UI values: { ["AK-47"] = { Damage = 35, ... } }
local ORIGINAL_DATA = {} -- Stores loaded values for comparison

local STAT_COLUMNS = {
	{Key = "Damage", Label = "Dmg", Width = 50, Color = Color3.fromRGB(255, 100, 100)},
	{Key = "HeadshotMultiplier", Label = "HS x", Width = 40, Color = Color3.fromRGB(200, 100, 100)},
	{Key = "FireRate", Label = "Rate", Width = 50, Color = Color3.fromRGB(100, 255, 100)},
	{Key = "ReloadTime", Label = "R.Time", Width = 50, Color = Color3.fromRGB(100, 200, 100)},
	{Key = "MaxAmmo", Label = "Mag", Width = 40, Color = Color3.fromRGB(100, 100, 255)},
	{Key = "ReserveAmmo", Label = "Resv", Width = 50, Color = Color3.fromRGB(100, 100, 200)},
	{Key = "Recoil", Label = "Recoil", Width = 50, Color = Color3.fromRGB(255, 200, 0)},
	{Key = "Spread", Label = "Spread", Width = 50, Color = Color3.fromRGB(255, 255, 100)},
	{Key = "Range", Label = "Range", Width = 50, Color = Color3.fromRGB(200, 200, 200)},
}

-- Helpers
local function getWeaponModule()
	local mod = game.ReplicatedStorage:FindFirstChild("ModuleScript")
	if mod then mod = mod:FindFirstChild("WeaponModule") end
	-- Fallback search
	if not mod then
		mod = game.ReplicatedStorage:FindFirstChild("WeaponModule", true)
	end
	return mod
end

local function loadData()
	local mod = getWeaponModule()
	if not mod then
		print("Error: WeaponModule not found!")
		return false
	end
	
	local success, result = pcall(function()
		-- We iterate ModuleScript source or use require?
		-- Require is better for initial values.
		-- Note: require() caches, so reloading via require might need a trick or just trust the Source if we had a parser.
		-- Standard require() is fine for first load.
		return require(mod)
	end)
	
	if success and result and result.Weapons then
		weaponsData = {}
		-- Deep copy interesting fields
		for name, stats in pairs(result.Weapons) do
			weaponsData[name] = {}
			for _, col in ipairs(STAT_COLUMNS) do
				weaponsData[name][col.Key] = stats[col.Key] or 0
			end
		end
		-- Clone to original for dirty checking (optional, simplified here)
		return true
	else
		warn("Failed to require WeaponModule: " .. tostring(result))
		return false
	end
end

-- Test Function Logic
local function testWeapon(weaponName)
	if not RunService:IsRunning() then
		warn("You must actviate 'Play' mode to test weapons!")
		return
	end
	
	local plr = Players.LocalPlayer
	if not plr or not plr.Character then return end
	
	-- 1. Setup Test Room
	local TEST_Y = 500
	local testRoom = workspace:FindFirstChild("TestRoom")
	if not testRoom then
		testRoom = Instance.new("Folder")
		testRoom.Name = "TestRoom"
		testRoom.Parent = workspace
		
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Size = Vector3.new(100, 1, 100)
		floor.Position = Vector3.new(0, TEST_Y, 0)
		floor.Anchored = true
		floor.BrickColor = BrickColor.new("Dark stone grey")
		floor.Material = Enum.Material.Concrete
		floor.Parent = testRoom
		
		local light = Instance.new("PointLight")
		light.Range = 60
		light.Brightness = 2
		light.Parent = floor
		
		-- Dummy Target
		-- Simple block rig for now if real dummy not available
		local dummy = Instance.new("Model")
		dummy.Name = "Target Dummy"
		dummy.Parent = testRoom
		
		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 100
		hum.Health = 100
		hum.Parent = dummy
		
		local torso = Instance.new("Part")
		torso.Name = "HumanoidRootPart"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = Vector3.new(0, TEST_Y + 3, -20)
		torso.Anchored = true
		torso.BrickColor = BrickColor.new("Bright red")
		torso.Parent = dummy
		
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1, 1, 1)
		head.Position = Vector3.new(0, TEST_Y + 4.5, -20)
		head.Anchored = true
		head.BrickColor = BrickColor.new("Bright yellow")
		head.Parent = dummy
	end
	
	-- 2. Teleport
	plr.Character:PivotTo(CFrame.new(0, TEST_Y + 5, 0))
	
	-- 3. Equip Weapon
	-- Search in ReplicatedStorage or ServerStorage
	local tool = nil
	for _, child in ipairs(game.ReplicatedStorage:GetDescendants()) do
		if child:IsA("Tool") and child.Name == weaponName then
			tool = child
			break
		end
	end
	
	if not tool then
		-- Try ServerStorage just in case (though client plugin usually can't see it if in play mode context sometimes?)
		-- In Play mode, client sees ReplicatedStorage.
		warn("Weapon Tool '"..weaponName.."' not found in ReplicatedStorage!")
	else
		local clone = tool:Clone()
		clone.Parent = plr.Backpack
		plr.Character.Humanoid:EquipTool(clone)
	end
end

-- UI
local mainFrame = nil
local gridScroll = nil

local function createUI()
	if mainFrame then mainFrame:Destroy() end
	
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.Parent = widget
	
	-- Toolbar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 40)
	topBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	topBar.Parent = mainFrame
	
	local reloadBtn = Instance.new("TextButton")
	reloadBtn.Text = "Reload Data"
	reloadBtn.Size = UDim2.new(0, 100, 0, 30)
	reloadBtn.Position = UDim2.new(0, 10, 0, 5)
	reloadBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
	reloadBtn.TextColor3 = Color3.new(1,1,1)
	reloadBtn.Parent = topBar
	Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0,4)
	
	local applyBtn = Instance.new("TextButton")
	applyBtn.Text = "Apply Changes"
	applyBtn.Size = UDim2.new(0, 120, 0, 30)
	applyBtn.Position = UDim2.new(0, 120, 0, 5)
	applyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.TextColor3 = Color3.new(1,1,1)
	applyBtn.Parent = topBar
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,4)
	
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "Status"
	statusLbl.Size = UDim2.new(0, 300, 1, 0)
	statusLbl.Position = UDim2.new(0, 250, 0, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.TextColor3 = Color3.fromRGB(200,200,200)
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Text = "Ready"
	statusLbl.Parent = topBar
	
	-- Grid Header
	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, 0, 0, 30)
	headerFrame.Position = UDim2.new(0, 0, 0, 40)
	headerFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	headerFrame.Parent = mainFrame
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 120, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Weapon Name"
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = headerFrame
	
	local currentX = 120
	for _, col in ipairs(STAT_COLUMNS) do
		local h = Instance.new("TextLabel")
		h.Size = UDim2.new(0, col.Width, 1, 0)
		h.Position = UDim2.new(0, currentX, 0, 0)
		h.BackgroundTransparency = 1
		h.Text = col.Label
		h.TextColor3 = col.Color
		h.Font = Enum.Font.GothamBold
		h.Parent = headerFrame
		currentX = currentX + col.Width + 2
	end
	
	-- Action Header
	local actionLabel = Instance.new("TextLabel")
	actionLabel.Size = UDim2.new(0, 60, 1, 0)
	actionLabel.Position = UDim2.new(0, currentX, 0, 0)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Text = "Action"
	actionLabel.TextColor3 = Color3.new(1,1,1)
	actionLabel.Font = Enum.Font.GothamBold
	actionLabel.Parent = headerFrame
	
	-- Grid Content
	gridScroll = Instance.new("ScrollingFrame")
	gridScroll.Size = UDim2.new(1, 0, 1, -70)
	gridScroll.Position = UDim2.new(0, 0, 0, 70)
	gridScroll.BackgroundTransparency = 1
	gridScroll.CanvasSize = UDim2.new(0, 0, 0, 1000)
	gridScroll.Parent = mainFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = gridScroll
	
	-- Events
	reloadBtn.MouseButton1Click:Connect(function()
		statusLbl.Text = "Reloading..."
		if loadData() then
			renderGrid()
			statusLbl.Text = "Data Reloaded"
		else
			statusLbl.Text = "Error Reloading Data"
		end
	end)
	
	applyBtn.MouseButton1Click:Connect(function()
		statusLbl.Text = "Applying..."
		applyChanges(statusLbl)
	end)
	
	-- Initial Render
	if loadData() then
		renderGrid()
	else
		statusLbl.Text = "Failed to load Initial Data"
	end
end

function renderGrid()
	-- Clear old
	for _, c in ipairs(gridScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	
	local sortedNames = {}
	for n in pairs(weaponsData) do table.insert(sortedNames, n) end
	table.sort(sortedNames)
	
	gridScroll.CanvasSize = UDim2.new(0, 0, 0, #sortedNames * 32)
	
	for _, name in ipairs(sortedNames) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 30)
		row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		row.BorderSizePixel = 0
		row.Parent = gridScroll
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 115, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.new(1,1,1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.Gotham
		label.Parent = row
		
		local currentX = 120
		local stats = weaponsData[name]
		
		for _, col in ipairs(STAT_COLUMNS) do
			local val = stats[col.Key]
			
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(0, col.Width, 0, 26)
			box.Position = UDim2.new(0, currentX, 0, 2)
			box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			box.TextColor3 = Color3.new(1,1,1)
			box.Text = tostring(val)
			box.Parent = row
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
			
			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if n then
					weaponsData[name][col.Key] = n
				else
					box.Text = tostring(weaponsData[name][col.Key]) -- Revert invalid
				end
			end)
			
			currentX = currentX + col.Width + 2
		end
		
		-- Test Button
		local testBtn = Instance.new("TextButton")
		testBtn.Size = UDim2.new(0, 60, 0, 26)
		testBtn.Position = UDim2.new(0, currentX, 0, 2)
		testBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
		testBtn.Text = "TEST"
		testBtn.TextColor3 = Color3.new(1,1,1)
		testBtn.Font = Enum.Font.GothamBold
		testBtn.TextSize = 10
		testBtn.Parent = row
		Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 4)
		
		testBtn.MouseButton1Click:Connect(function()
			testWeapon(name)
		end)
	end
end

function escape(s)
	-- Escape regex magic characters
	return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
end

function applyChanges(statusLbl)
	local mod = getWeaponModule()
	if not mod then
		statusLbl.Text = "Error: Module not found"
		return
	end
	
	local source = mod.Source
	local totalReplaced = 0
	
	for name, stats in pairs(weaponsData) do
		for key, val in pairs(stats) do
			-- Regex Pattern:
			-- ["WeaponName"] ... Key = Value
			-- We use [%s%S]- to match anything (newlines) non-greedily between weapon name and key
			local safeName = escape(name)
			
			-- Pattern explanation:
			-- 1. (%["NAME"%][%s%S]-Key%s*=%s*) -> Capture everything up to the equals sign
			-- 2. ([%d%.%-]+) -> Capture the number (including negative and decimals)
			-- 3. Update to new value
			
			local pattern = '(%["' .. safeName .. '"%][%s%S]-' .. key .. '%s*=%s*)([%d%.%-]+)'
			
			-- Check if pattern exists first to avoid messing up if not found
			if source:find(pattern) then
				local newSource, count = source:gsub(pattern, "%1" .. tostring(val))
				if count > 0 then
					source = newSource
					totalReplaced = totalReplaced + count
				end
			end
		end
	end
	
	if totalReplaced > 0 then
		ChangeHistoryService:SetWaypoint("Weapon Stats Update")
		mod.Source = source
		ChangeHistoryService:SetWaypoint("Weapon Stats Applied")
		statusLbl.Text = "Success: Updated " .. totalReplaced .. " values."
	else
		statusLbl.Text = "Warning: No matching patterns found."
	end
end

-- Cleanup
plugin.Unloading:Connect(function()
	if mainFrame then mainFrame:Destroy() end
end)

-- Initial UI
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		createUI()
	end
end)

print("[Weapon Editor] Plugin Loaded")
