-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

-- LootBalancerPlugin.lua
-- A Roblox Studio Plugin for balancing drop rates in DropManager.lua
-- Save this file to: %localappdata%\Roblox\Plugins\LootBalancerPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Game Balancing")
local toggleButton = toolbar:CreateButton(
	"Loot Balancer",
	"Balance drop rates visually",
	"rbxassetid://6031097920" -- Dice Icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	400,
	500,
	350,
	400
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("LootBalancerWidget", widgetInfo)
widget.Title = "Loot Table Balancer"

-- State
local lootData = {} -- { {name = "Health", weight = 25}, ... }
local mainFrame = nil

-- Colors for items
local ITEM_COLORS = {
	Points = Color3.fromRGB(255, 215, 0),      -- Gold
	Health = Color3.fromRGB(255, 100, 100),    -- Red
	Shield = Color3.fromRGB(100, 150, 255),    -- Blue
	Ammo = Color3.fromRGB(100, 255, 100),      -- Green
	AutoUpgrade = Color3.fromRGB(200, 100, 255), -- Purple
	Minigun = Color3.fromRGB(255, 165, 0)       -- Orange
}

-- Helper: Find DropManager script
local function getDropManagerScript()
	local scriptFolder = ServerScriptService:FindFirstChild("Script")
	if scriptFolder then
		return scriptFolder:FindFirstChild("DropManager")
	end
	return nil
end

-- Helper: Parse WEIGHTED_DROPS from source
local function parseDropsFromSource(source)
	local drops = {}
	-- Pattern: { name = "ItemName", weight = 123 }
	for name, weight in source:gmatch('%{%s*name%s*=%s*"([^"]+)"%s*,%s*weight%s*=%s*(%d+)%s*%}') do
		table.insert(drops, { name = name, weight = tonumber(weight) })
	end
	return drops
end

-- Helper: Calculate total weight
local function getTotalWeight()
	local total = 0
	for _, item in ipairs(lootData) do
		total = total + item.weight
	end
	return total
end

-- Load data from DropManager
local function loadData()
	local dm = getDropManagerScript()
	if not dm then
		warn("[LootBalancer] DropManager.lua not found in ServerScriptService/Script")
		return false
	end

	local source = dm.Source
	lootData = parseDropsFromSource(source)

	if #lootData == 0 then
		warn("[LootBalancer] Could not parse WEIGHTED_DROPS from DropManager")
		return false
	end

	print("[LootBalancer] Loaded " .. #lootData .. " items")
	return true
end

-- Simulate drops
local function simulateDrops(count)
	local totalWeight = getTotalWeight()
	if totalWeight == 0 then return {} end

	local results = {}
	for _, item in ipairs(lootData) do
		results[item.name] = 0
	end

	for _ = 1, count do
		local roll = math.random(1, totalWeight)
		local current = 0
		for _, item in ipairs(lootData) do
			current = current + item.weight
			if roll <= current then
				results[item.name] = results[item.name] + 1
				break
			end
		end
	end

	return results
end

-- Apply changes to DropManager source
local function applyChanges(statusLabel)
	local dm = getDropManagerScript()
	if not dm then
		statusLabel.Text = "Error: DropManager not found"
		return
	end

	local source = dm.Source
	local modified = source

	ChangeHistoryService:SetWaypoint("Pre-Loot Balance Update")

	for _, item in ipairs(lootData) do
		-- Pattern to find and replace weight for specific item
		local pattern = '(%{%s*name%s*=%s*"' .. item.name .. '"%s*,%s*weight%s*=%s*)%d+(%s*%})'
		local replacement = "%1" .. tostring(item.weight) .. "%2"
		modified = modified:gsub(pattern, replacement)
	end

	dm.Source = modified
	ChangeHistoryService:SetWaypoint("Loot Balance Updated")

	statusLabel.Text = "✓ Changes applied!"
	statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end

-- Create UI
local function createUI()
	if mainFrame then mainFrame:Destroy() end

	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	mainFrame.Parent = widget

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	title.Text = "🎲 Drop Rate Balancer"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = mainFrame

	-- Items ScrollFrame
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 0.5, -40)
	scrollFrame.Position = UDim2.new(0, 10, 0, 40)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #lootData * 60)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scrollFrame

	local totalWeight = getTotalWeight()

	-- Create item rows
	for i, item in ipairs(lootData) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 55)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		row.Parent = scrollFrame
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		-- Color indicator
		local colorBar = Instance.new("Frame")
		colorBar.Size = UDim2.new(0, 5, 1, 0)
		colorBar.BackgroundColor3 = ITEM_COLORS[item.name] or Color3.fromRGB(150, 150, 150)
		colorBar.Parent = row
		Instance.new("UICorner", colorBar).CornerRadius = UDim.new(0, 3)

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.4, 0, 0, 25)
		nameLabel.Position = UDim2.new(0, 15, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.name
		nameLabel.TextColor3 = ITEM_COLORS[item.name] or Color3.new(1, 1, 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.Parent = row

		-- Percentage label
		local pct = totalWeight > 0 and math.floor((item.weight / totalWeight) * 1000) / 10 or 0
		local pctLabel = Instance.new("TextLabel")
		pctLabel.Name = "PctLabel"
		pctLabel.Size = UDim2.new(0, 50, 0, 25)
		pctLabel.Position = UDim2.new(1, -60, 0, 5)
		pctLabel.BackgroundTransparency = 1
		pctLabel.Text = pct .. "%"
		pctLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		pctLabel.TextXAlignment = Enum.TextXAlignment.Right
		pctLabel.Font = Enum.Font.Gotham
		pctLabel.TextSize = 12
		pctLabel.Parent = row

		-- Weight TextBox
		local weightBox = Instance.new("TextBox")
		weightBox.Size = UDim2.new(0, 50, 0, 22)
		weightBox.Position = UDim2.new(0.55, 0, 0, 5)
		weightBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		weightBox.TextColor3 = Color3.new(1, 1, 1)
		weightBox.Text = tostring(item.weight)
		weightBox.Font = Enum.Font.GothamBold
		weightBox.TextSize = 14
		weightBox.Parent = row
		Instance.new("UICorner", weightBox).CornerRadius = UDim.new(0, 4)

		-- Slider
		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(0.9, 0, 0, 8)
		sliderBg.Position = UDim2.new(0.05, 0, 0, 35)
		sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		sliderBg.Parent = row
		Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(math.clamp(item.weight / 100, 0, 1), 0, 1, 0)
		sliderFill.BackgroundColor3 = ITEM_COLORS[item.name] or Color3.fromRGB(100, 200, 100)
		sliderFill.Parent = sliderBg
		Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

		-- Update logic
		local function updateItem(newWeight)
			newWeight = math.clamp(newWeight, 0, 100)
			lootData[i].weight = newWeight
			weightBox.Text = tostring(newWeight)
			sliderFill.Size = UDim2.new(math.clamp(newWeight / 100, 0, 1), 0, 1, 0)

			-- Recalculate percentages
			local newTotal = getTotalWeight()
			for _, child in ipairs(scrollFrame:GetChildren()) do
				if child:IsA("Frame") then
					local pctL = child:FindFirstChild("PctLabel")
					if pctL then
						local idx = child.LayoutOrder or 1
						local w = lootData[idx] and lootData[idx].weight or 0
						local p = newTotal > 0 and math.floor((w / newTotal) * 1000) / 10 or 0
						pctL.Text = p .. "%"
					end
				end
			end
		end

		row.LayoutOrder = i

		weightBox.FocusLost:Connect(function()
			local n = tonumber(weightBox.Text)
			if n then updateItem(n) end
		end)

		-- Slider drag
		local dragging = false
		sliderBg.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
			end
		end)
		sliderBg.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		sliderBg.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local rel = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
				local newW = math.floor(math.clamp(rel, 0, 1) * 100)
				updateItem(newW)
			end
		end)
	end

	-- Simulation Section
	local simFrame = Instance.new("Frame")
	simFrame.Size = UDim2.new(1, -20, 0.35, 0)
	simFrame.Position = UDim2.new(0, 10, 0.55, 0)
	simFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	simFrame.Parent = mainFrame
	Instance.new("UICorner", simFrame).CornerRadius = UDim.new(0, 6)

	local simTitle = Instance.new("TextLabel")
	simTitle.Size = UDim2.new(1, 0, 0, 25)
	simTitle.BackgroundTransparency = 1
	simTitle.Text = "🎯 Simulation (100 Drops)"
	simTitle.TextColor3 = Color3.new(1, 1, 1)
	simTitle.Font = Enum.Font.GothamBold
	simTitle.TextSize = 14
	simTitle.Parent = simFrame

	local simResults = Instance.new("TextLabel")
	simResults.Name = "SimResults"
	simResults.Size = UDim2.new(1, -10, 1, -60)
	simResults.Position = UDim2.new(0, 5, 0, 25)
	simResults.BackgroundTransparency = 1
	simResults.Text = "Click 'Run Simulation' to test drop rates"
	simResults.TextColor3 = Color3.fromRGB(180, 180, 180)
	simResults.TextWrapped = true
	simResults.TextXAlignment = Enum.TextXAlignment.Left
	simResults.TextYAlignment = Enum.TextYAlignment.Top
	simResults.Font = Enum.Font.Gotham
	simResults.TextSize = 12
	simResults.Parent = simFrame

	local simBtn = Instance.new("TextButton")
	simBtn.Size = UDim2.new(0.5, -5, 0, 30)
	simBtn.Position = UDim2.new(0, 5, 1, -35)
	simBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
	simBtn.Text = "Run Simulation"
	simBtn.TextColor3 = Color3.new(1, 1, 1)
	simBtn.Font = Enum.Font.GothamBold
	simBtn.Parent = simFrame
	Instance.new("UICorner", simBtn).CornerRadius = UDim.new(0, 4)

	simBtn.MouseButton1Click:Connect(function()
		local results = simulateDrops(100)
		local text = ""
		for _, item in ipairs(lootData) do
			local count = results[item.name] or 0
			text = text .. item.name .. ": " .. count .. " (" .. count .. "%)\n"
		end
		simResults.Text = text
	end)

	-- Bottom buttons
	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(0.45, 0, 0, 35)
	applyBtn.Position = UDim2.new(0.025, 0, 0.92, 0)
	applyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
	applyBtn.Text = "✓ Apply Changes"
	applyBtn.TextColor3 = Color3.new(1, 1, 1)
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.Parent = mainFrame
	Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 4)

	local reloadBtn = Instance.new("TextButton")
	reloadBtn.Size = UDim2.new(0.45, 0, 0, 35)
	reloadBtn.Position = UDim2.new(0.525, 0, 0.92, 0)
	reloadBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
	reloadBtn.Text = "↻ Reload"
	reloadBtn.TextColor3 = Color3.new(1, 1, 1)
	reloadBtn.Font = Enum.Font.GothamBold
	reloadBtn.Parent = mainFrame
	Instance.new("UICorner", reloadBtn).CornerRadius = UDim.new(0, 4)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0.98, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.Parent = mainFrame

	applyBtn.MouseButton1Click:Connect(function()
		applyChanges(statusLabel)
	end)

	reloadBtn.MouseButton1Click:Connect(function()
		if loadData() then
			createUI()
		end
	end)
end

-- Cleanup
plugin.Unloading:Connect(function()
	if mainFrame then mainFrame:Destroy() end
end)

-- Init
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		if loadData() then
			createUI()
		end
	end
end)

print("[Loot Balancer] Plugin Loaded")
