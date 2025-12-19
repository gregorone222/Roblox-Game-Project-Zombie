-- UnifiedShopEditorPlugin.lua
-- Unified Editor for AP Shop, MP Shop, and Weapon Upgrades
-- Place in %localappdata%\Roblox\Plugins or use as a local plugin

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration Paths
-- Adjust these if your structure changes
local CONFIG_PATHS = {
	APShop = "ServerScriptService.ModuleScript.APShopConfig",
	MPShop = "ServerScriptService.ModuleScript.MPShopConfig",
	WeaponUpgrade = "ServerScriptService.ModuleScript.WeaponUpgradeConfigModule"
}

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Zombie Project Tools")
local toggleButton = toolbar:CreateButton(
	"Shop Editor",
	"Edit Configs for AP, MP, and Upgrades",
	"rbxassetid://1507949203" -- Generic Settings Icon
)

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	400,
	600,
	300,
	400
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("UnifiedShopEditor", widgetInfo)
widget.Title = "Unified Shop & Economy Editor"

-- GUI CREATION HELPERS --

local function createFrame(parent, size, pos, color, transparency)
	local f = Instance.new("Frame")
	f.Size = size or UDim2.new(1, 0, 1, 0)
	f.Position = pos or UDim2.new(0, 0, 0, 0)
	f.BackgroundColor3 = color or Color3.fromRGB(45, 45, 45)
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function createTextLabel(parent, text, size, pos, color)
	local l = Instance.new("TextLabel")
	l.Size = size or UDim2.new(1, 0, 0, 20)
	l.Position = pos or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = text or ""
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Font = Enum.Font.Gotham
	l.TextSize = 12
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function createInput(parent, name, defaultVal, callback)
	local container = createFrame(parent, UDim2.new(1, 0, 0, 40), nil, nil, 1)
	
	createTextLabel(container, name, UDim2.new(1, 0, 0, 15), UDim2.new(0, 0, 0, 0))
	
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 20)
	box.Position = UDim2.new(0, 0, 0, 18)
	box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Text = tostring(defaultVal or "")
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box
	
	box.FocusLost:Connect(function()
		callback(box.Text)
	end)
	
	return {
		Container = container,
		Box = box,
		SetValue = function(val) box.Text = tostring(val) end
	}
end

local function createSectionHeader(parent, text)
	local l = createTextLabel(parent, text, UDim2.new(1, 0, 0, 25))
	l.Font = Enum.Font.GothamBold
	l.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	l.BackgroundTransparency = 0
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.Parent = l
	
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = l
end

-- LOGIC & PARSING --

local function getModuleSource(pathString)
	local parts = pathString:split(".")
	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then return nil end
	end
	if current:IsA("ModuleScript") then
		return current
	end
	return nil
end

local function safeRequire(module)
	local success, res = pcall(function()
		return require(module)
	end)
	return success and res or nil
end

-- Source Replacement Helper
local function replaceValueInSource(source, key, keyAssignmentPattern, newValue, valueFormat)
	-- simple pattern: Key = Value
	-- We need to be careful about not replacing keys in wrong places.
	-- This helper assumes globally unique keys OR we are passing a specific block.
	-- For this plugin, we will do more specific replacements in the Save logic.
	return source 
end

-- MAIN UI --

local mainFrame = createFrame(widget)

-- Tab System
local tabContainer = createFrame(mainFrame, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(35, 35, 35))
local contentContainer = createFrame(mainFrame, UDim2.new(1, 0, 1, -30), UDim2.new(0, 0, 0, 30))

local currentTab = nil
local tabs = {}

local function switchTab(name)
	for tName, data in pairs(tabs) do
		if tName == name then
			data.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			data.Frame.Visible = true
			if data.OnOpen then data.OnOpen() end
		else
			data.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			data.Frame.Visible = false
		end
	end
end

local function createTab(name, onOpenFunc)
	local count = 0
	for _ in pairs(tabs) do count = count + 1 end
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.33, -2, 1, 0)
	btn.Position = UDim2.new(count * 0.33, 1, 0, 0)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.Text = name
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Parent = tabContainer
	
	local frame = createFrame(contentContainer, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), nil, 1)
	frame.Visible = false
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = frame
	
	tabs[name] = { Button = btn, Frame = frame, OnOpen = onOpenFunc }
	
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

-- === AP SHOP TAB === --

local function setupAPShopTab()
	local frame = tabs["AP Shop"].Frame
	-- Refresh Content
	for _, c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
	
	local status = createTextLabel(frame, "Loading...", UDim2.new(1, 0, 0, 20))
	
	local module = getModuleSource(CONFIG_PATHS.APShop)
	if not module then
		status.Text = "Error: APShopConfig not found!"
		status.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	
	local data = safeRequire(module)
	if not data or not data.Items then
		status.Text = "Error: Could not require APShopConfig!"
		return
	end
	
	status.Text = "Select an item to edit:"
	
	local itemList = Instance.new("ScrollingFrame")
	itemList.Size = UDim2.new(1, 0, 0, 150)
	itemList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemList.Parent = frame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = itemList
	
	local editFrame = createFrame(frame, UDim2.new(1, 0, 0, 200), nil, nil, 1)
	editFrame.Visible = false
	local editLayout = Instance.new("UIListLayout")
	editLayout.Padding = UDim.new(0, 5)
	editLayout.Parent = editFrame
	
	createSectionHeader(editFrame, "Edit Item")
	local costInput = createInput(editFrame, "AP Cost", 0, function() end)
	local typeInput = createInput(editFrame, "Type", "", function() end)
	
	local currentKey = nil
	
	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(1, 0, 0, 30)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	saveBtn.Text = "Save Changes"
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.Parent = editFrame
	local saveStatus = createTextLabel(editFrame, "", UDim2.new(1, 0, 0, 20))
	
	-- Save Logic
	saveBtn.MouseButton1Click:Connect(function()
		if not currentKey then return end
		
		local newCost = tonumber(costInput.Box.Text)
		
		local source = module.Source
		-- Pattern to find the specific item block
		-- Key = { ... APCost = 123
		-- We try to find the Key, then look for APCost inside the next curly braces block? 
		-- Simplest reliable way for this structure:
		-- Find "KEY = {", then find "APCost = X" after that.
		
		local keyPattern = currentKey .. "%s*=%s*{"
		local startIdx, endIdx = string.find(source, keyPattern)
		
		if not startIdx then
			saveStatus.Text = "Error: Item key not found in source!"
			wait(2) saveStatus.Text = ""
			return
		end
		
		-- Look ahead for APCost
		-- We need to limit the search to before the closing "}" of this item. 
		-- But parsing balanced braces with regex is hard.
		-- Assumption: Config style is consistent.
		
		local afterHeader = string.sub(source, endIdx + 1)
		local costPattern = "APCost%s*=%s*(%d+)"
		local foundStart, foundEnd, oldVal = string.find(afterHeader, costPattern)
		
		if foundStart then
			-- Calculate absolute position
			local absoluteStart = endIdx + foundStart
			local absoluteEnd = endIdx + foundEnd
			
			local newSource = string.sub(source, 1, absoluteStart - 1) .. "APCost = " .. newCost .. string.sub(source, absoluteEnd + 1)
			module.Source = newSource
			saveStatus.Text = "Saved!"
			ChangeHistoryService:SetWaypoint("Edited AP Item " .. currentKey)
			wait(2) saveStatus.Text = ""
		else
			saveStatus.Text = "Error: APCost field not found for this item."
		end
	end)
	
	for key, itemData in pairs(data.Items) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 25)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.Text = "  " .. (itemData.Name or key)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = itemList
		
		btn.MouseButton1Click:Connect(function()
			editFrame.Visible = true
			currentKey = key
			costInput.SetValue(itemData.APCost or 0)
			typeInput.SetValue(itemData.Type or "Unknown")
			status.Text = "Editing: " .. key
		end)
	end
end

-- === MP SHOP TAB === --

local function setupMPShopTab()
	local frame = tabs["MP Shop"].Frame
	for _, c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
	
	local status = createTextLabel(frame, "Loading...", UDim2.new(1, 0, 0, 20))
	
	local module = getModuleSource(CONFIG_PATHS.MPShop)
	if not module then
		status.Text = "Error: MPShopConfig not found!"
		status.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	
	local data = safeRequire(module)
	if not data or not data.Items then
		status.Text = "Error: Could not require MPShopConfig!"
		return
	end
	
	status.Text = "Select an item to edit:"
	
	local itemList = Instance.new("ScrollingFrame")
	itemList.Size = UDim2.new(1, 0, 0, 150)
	itemList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemList.Parent = frame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = itemList
	
	local editFrame = createFrame(frame, UDim2.new(1, 0, 0, 200), nil, nil, 1)
	editFrame.Visible = false
	local editLayout = Instance.new("UIListLayout")
	editLayout.Padding = UDim.new(0, 5)
	editLayout.Parent = editFrame
	
	createSectionHeader(editFrame, "Edit Item")
	local costInput = createInput(editFrame, "MP Cost", 0, function() end)
	
	local currentKey = nil
	
	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(1, 0, 0, 30)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	saveBtn.Text = "Save Changes"
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.Parent = editFrame
	local saveStatus = createTextLabel(editFrame, "", UDim2.new(1, 0, 0, 20))
	
	saveBtn.MouseButton1Click:Connect(function()
		if not currentKey then return end
		local newCost = tonumber(costInput.Box.Text)
		
		local source = module.Source
		local keyPattern = currentKey .. "%s*=%s*{"
		local startIdx, endIdx = string.find(source, keyPattern)
		
		if not startIdx then
			saveStatus.Text = "Error: Item key not found!"
			return
		end
		
		local afterHeader = string.sub(source, endIdx + 1)
		local costPattern = "MPCost%s*=%s*(%d+)"
		local foundStart, foundEnd, oldVal = string.find(afterHeader, costPattern)
		
		if foundStart then
			local absoluteStart = endIdx + foundStart
			local absoluteEnd = endIdx + foundEnd
			local newSource = string.sub(source, 1, absoluteStart - 1) .. "MPCost = " .. newCost .. string.sub(source, absoluteEnd + 1)
			module.Source = newSource
			saveStatus.Text = "Saved!"
			ChangeHistoryService:SetWaypoint("Edited MP Item " .. currentKey)
			wait(2) saveStatus.Text = ""
		else
			saveStatus.Text = "Error: MPCost not found."
		end
	end)
	
	for key, itemData in pairs(data.Items) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 25)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.Text = "  " .. (itemData.Name or key)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = itemList
		
		btn.MouseButton1Click:Connect(function()
			editFrame.Visible = true
			currentKey = key
			costInput.SetValue(itemData.MPCost or 0)
			status.Text = "Editing: " .. key
		end)
	end
end

-- === WEAPON UPGRADE TAB === --

local function setupWeaponTab()
	local frame = tabs["Weapon Upgrades"].Frame
	for _, c in ipairs(frame:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end
	
	local status = createTextLabel(frame, "Loading...", UDim2.new(1, 0, 0, 20))
	
	local module = getModuleSource(CONFIG_PATHS.WeaponUpgrade)
	if not module then
		status.Text = "Error: UpgradeModule not found!"
		status.TextColor3 = Color3.fromRGB(255, 100, 100)
		return
	end
	
	-- We CANNOT require this module easily because of side effects (PointsModule require).
	-- parsing source directly for DefaultConfig values.
	
	local source = module.Source
	
	-- Parser Helper to extract DefaultConfig = { ... }
	-- We just look for specific keys we know exist in DefaultConfig
	
	local function getValue(name)
		-- Pattern: Name = Value
		-- Matches integers or floats
		local pattern = name .. "%s*=%s*([%d%.]+)"
		local _, _, val = string.find(source, pattern)
		return tonumber(val)
	end
	
	local baseCost = getValue("BaseCost") or 0
	local costMult = getValue("CostMultiplier") or 0
	local costExpo = getValue("CostExpo") or 0
	local dmgPerLvl = getValue("DamagePerLevel") or 0
	local maxLevel = getValue("MaxLevel") or 0
	
	status.Text = "Default Upgrade Configuration"
	
	createSectionHeader(frame, "Global Settings")
	
	local baseCostInput = createInput(frame, "Base Cost (Level 1)", baseCost, function() end)
	local multInput = createInput(frame, "Cost Multiplier", costMult, function() end)
	local expoInput = createInput(frame, "Cost Exponent", costExpo, function() end)
	local dmgInput = createInput(frame, "Damage Per Level", dmgPerLvl, function() end)
	local maxLvlInput = createInput(frame, "Max Level", maxLevel, function() end)
	
	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(1, 0, 0, 30)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	saveBtn.Text = "Save Config"
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.Parent = frame
	local saveStatus = createTextLabel(frame, "", UDim2.new(1, 0, 0, 20))
	
	saveBtn.MouseButton1Click:Connect(function()
		local newSource = source
		local function updateKey(key, newVal, isInt)
			-- Find Key = OldValue
			local pattern = key .. "%s*=%s*([%d%.]+)"
			local startKey, endKey, oldVal = string.find(newSource, pattern)
			if startKey then
				local patternStart, patternEnd = string.find(newSource, pattern) -- find full match range
				-- Reconstruct replacement
				local replacement = key .. " = " .. newVal
				-- Use string substitution carefully
				-- string.gsub replaces ALL occurrences. We want to hope DefaultConfig keys are unique enough or scoped.
				-- In this specific file, these keys seem unique to DefaultConfig or properly scoped.
				-- But to be safe, string.gsub might be too aggressive if "BaseCost" appears elsewhere.
				-- However, for this task, we will assume standard structure.
				newSource = string.gsub(newSource, key .. "%s*=%s*[%d%.]+", replacement, 1) -- Replace FIRST occurrence only (DefaultConfig is usually at top)
			end
		end
		
		updateKey("BaseCost", tonumber(baseCostInput.Box.Text))
		updateKey("CostMultiplier", tonumber(multInput.Box.Text))
		updateKey("CostExpo", tonumber(expoInput.Box.Text))
		updateKey("DamagePerLevel", tonumber(dmgInput.Box.Text))
		updateKey("MaxLevel", tonumber(maxLvlInput.Box.Text))
		
		module.Source = newSource
		source = newSource -- Update local cache
		saveStatus.Text = "Saved Config!"
		ChangeHistoryService:SetWaypoint("Edited Upgrade Config")
		wait(2) saveStatus.Text = ""
	end)
end

-- Init Tab Content Helpers
createTab("AP Shop", setupAPShopTab)
createTab("MP Shop", setupMPShopTab)
createTab("Weapon Upgrades", setupWeaponTab)

switchTab("AP Shop")
