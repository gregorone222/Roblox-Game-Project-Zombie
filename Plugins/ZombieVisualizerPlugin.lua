-- ZombieVisualizerPlugin.lua
-- A Roblox Studio Plugin to visualize Spawners and Simulate Waves
-- Save this file to: %localappdata%\Roblox\Plugins\ZombieVisualizerPlugin.lua

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Game Intelligence")
local toggleButton = toolbar:CreateButton(
	"Zombie Visualizer",
	"Visualize Spawners & Simulate Waves",
	"rbxassetid://6031071053" -- Generic Icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	300,
	450,
	250,
	300
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("ZombieVisualizerWidget", widgetInfo)
widget.Title = "Zombie Visualizer"

-- Data
local spawnerFolder = workspace:FindFirstChild("Spawners")
local vizContainer = nil
local isVizEnabled = false
local currentWave = 1

-- Load Config safely
local ZombieConfig = nil
local function loadConfig()
	local mod = game.ReplicatedStorage:FindFirstChild("ModuleScript")
	if mod then mod = mod:FindFirstChild("ZombieConfig") end
	-- Fallback
	if not mod then
		mod = game.ReplicatedStorage:FindFirstChild("ZombieConfig", true)
	end
	
	if mod then
		local success, result = pcall(function() return require(mod) end)
		if success then
			ZombieConfig = result
			return true
		end
	end
	return false
end

loadConfig()

-- UI Construction
local mainFrame = nil
local simulatorScroll = nil

local function createUI()
	if mainFrame then mainFrame:Destroy() end
	
	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	mainFrame.Parent = widget
	
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -20)
	scroll.Position = UDim2.new(0, 10, 0, 10)
	scroll.BackgroundTransparency = 1
	scroll.Parent = mainFrame
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scroll
	
	-- Header: Visualizer
	createHeader("👁️ Spawner Visualizer", scroll)
	
	local toggleVizBtn = Instance.new("TextButton")
	toggleVizBtn.Size = UDim2.new(1, 0, 0, 40)
	toggleVizBtn.BackgroundColor3 = isVizEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 60)
	toggleVizBtn.Text = isVizEnabled and "Visualizer: ON" or "Visualizer: OFF"
	toggleVizBtn.TextColor3 = Color3.new(1,1,1)
	toggleVizBtn.Font = Enum.Font.GothamBold
	toggleVizBtn.Parent = scroll
	Instance.new("UICorner", toggleVizBtn).CornerRadius = UDim.new(0, 4)
	
	toggleVizBtn.MouseButton1Click:Connect(function()
		toggleVisualizer()
		toggleVizBtn.Text = isVizEnabled and "Visualizer: ON" or "Visualizer: OFF"
		toggleVizBtn.BackgroundColor3 = isVizEnabled and Color3.fromRGB(0, 150, 80) or Color3.fromRGB(60, 60, 60)
	end)
	
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.new(1, 0, 0, 25)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 150)
	refreshBtn.Text = "Refresh Spawners Manual"
	refreshBtn.TextColor3 = Color3.new(1,1,1)
	refreshBtn.Parent = scroll
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)
	
	refreshBtn.MouseButton1Click:Connect(function()
		if isVizEnabled then
			updateVisuals()
		end
	end)
	
	-- Header: Simulator
	createHeader("📈 Wave Simulator", scroll)
	
	local waveInputFrame = Instance.new("Frame")
	waveInputFrame.Size = UDim2.new(1, 0, 0, 30)
	waveInputFrame.BackgroundTransparency = 1
	waveInputFrame.Parent = scroll
	
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Size = UDim2.new(0.4, 0, 1, 0)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "Wave Number:"
	waveLabel.TextColor3 = Color3.new(1,1,1)
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Font = Enum.Font.Gotham
	waveLabel.Parent = waveInputFrame
	
	local waveInput = Instance.new("TextBox")
	waveInput.Size = UDim2.new(0.6, 0, 1, 0)
	waveInput.Position = UDim2.new(0.4, 0, 0, 0)
	waveInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	waveInput.TextColor3 = Color3.new(1,1,1)
	waveInput.Text = tostring(currentWave)
	waveInput.Parent = waveInputFrame
	Instance.new("UICorner", waveInput).CornerRadius = UDim.new(0, 4)
	
	waveInput.FocusLost:Connect(function()
		currentWave = tonumber(waveInput.Text) or 1
		waveInput.Text = tostring(currentWave)
	end)
	
	local calcBtn = Instance.new("TextButton")
	calcBtn.Size = UDim2.new(1, 0, 0, 35)
	calcBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	calcBtn.Text = "Simulate Wave Spawn"
	calcBtn.TextColor3 = Color3.new(1,1,1)
	calcBtn.Font = Enum.Font.GothamBold
	calcBtn.Parent = scroll
	Instance.new("UICorner", calcBtn).CornerRadius = UDim.new(0, 4)
	
	-- Results
	local resultsLabel = Instance.new("TextLabel")
	resultsLabel.Size = UDim2.new(1, 0, 0, 150)
	resultsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	resultsLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	resultsLabel.TextXAlignment = Enum.TextXAlignment.Left
	resultsLabel.TextYAlignment = Enum.TextYAlignment.Top
	resultsLabel.Text = "Click Simulate to see results..."
	resultsLabel.Font = Enum.Font.Code
	resultsLabel.TextSize = 12
	resultsLabel.Parent = scroll
	Instance.new("UIPadding", resultsLabel).PaddingLeft = UDim.new(0, 5)
	Instance.new("UIPadding", resultsLabel).PaddingTop = UDim.new(0, 5)
	
	calcBtn.MouseButton1Click:Connect(function()
		if not ZombieConfig then
			local loaded = loadConfig()
			if not loaded then
				resultsLabel.Text = "Error: Could not load ZombieConfig Module!"
				return
			end
		end
		
		local text = simulateWave(currentWave)
		resultsLabel.Text = text
	end)
end

function createHeader(text, parent)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 30)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 200, 100)
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

-- Visualizer Logic
function toggleVisualizer()
	isVizEnabled = not isVizEnabled
	if isVizEnabled then
		updateVisuals()
	else
		if vizContainer then
			vizContainer:Destroy()
			vizContainer = nil
		end
	end
end

function updateVisuals()
	if vizContainer then vizContainer:Destroy() end
	spawnerFolder = workspace:FindFirstChild("Spawners")
	
	if not spawnerFolder then
		warn("[ZombieVisualizer] 'Spawners' folder not found in Workspace!")
		return
	end
	
	vizContainer = Instance.new("Folder")
	vizContainer.Name = "ZombieVisualizerContainer"
	vizContainer.Parent = CoreGui
	
	local count = 0
	for _, spawnPoint in ipairs(spawnerFolder:GetChildren()) do
		if spawnPoint:IsA("BasePart") then
			count = count + 1
			local bb = Instance.new("BillboardGui")
			bb.Name = "SpawnerViz"
			bb.Adornee = spawnPoint
			bb.Size = UDim2.new(0, 40, 0, 40) -- Slightly larger
			bb.AlwaysOnTop = true
			bb.ExtentsOffset = Vector3.new(0, 2, 0) -- Float above
			bb.Parent = vizContainer
			
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundTransparency = 1
			frame.Parent = bb
			
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.new(1, 0, 1, 0)
			icon.BackgroundTransparency = 1
			icon.Text = "🧟" -- Emoji is safer than AssetId
			icon.TextSize = 30
			icon.Parent = frame
			
			-- Add text shadow/outline for visibility
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			stroke.Parent = icon
		end
	end
	print("[ZombieVisualizer] Visualized " .. count .. " spawners.")
end

-- Simulator Logic
function simulateWave(wave)
	local output = "Simulation for Wave " .. wave .. ":\n"
	
	-- Copied Logic from SpawnerModule Idea
	-- Gather valid types
	local validTypes = {}
	
	-- Boss Checks
	local bossSpawn = nil
	for bossName, bossConf in pairs(ZombieConfig.Types) do
		if string.find(bossName, "Boss") then
			if wave >= (bossConf.ChanceWaveMin or 999) and wave <= (bossConf.ChanceWaveMax or -1) then
				output = output .. "- [!] Potential Boss Window: " .. bossName .. "\n"
			end
		end
	end
	
	-- Normal Zombies
	for typeName, config in pairs(ZombieConfig.Types) do
		if not string.find(typeName, "Boss") then
			if wave >= (config.MinWave or 0) then
				table.insert(validTypes, {Type = typeName, Chance = config.Chance or 0})
			end
		end
	end
	
	output = output .. "\nSpawn Probabilities (Normalized):\n"
	
	-- Simple Simulation (100 samples)
	local samples = 100
	local resultCounts = {}
	
	-- Simplified matching logic (Highest MinWave Priority as per previous observation)
	table.sort(validTypes, function(a, b) 
		local wa = ZombieConfig.Types[a.Type].MinWave or 0
		local wb = ZombieConfig.Types[b.Type].MinWave or 0
		return wa > wb 
	end)
	
	for i=1, samples do
		local chosen = "Zombie" -- Default
		for _, entry in ipairs(validTypes) do
			if math.random() < entry.Chance then
				chosen = entry.Type
				break
			end
		end
		resultCounts[chosen] = (resultCounts[chosen] or 0) + 1
	end
	
	for name, count in pairs(resultCounts) do
		output = output .. string.format("- %s: %d%%\n", name, count)
	end
	
	return output
end

-- Cleanup
plugin.Unloading:Connect(function()
	if vizContainer then vizContainer:Destroy() end
	if mainFrame then mainFrame:Destroy() end
end)

-- Init
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		createUI()
	else
		-- Hide visualizer? Optional. Better keep if enabled.
	end
end)

print("[Zombie Visualizer] Plugin Loaded")
