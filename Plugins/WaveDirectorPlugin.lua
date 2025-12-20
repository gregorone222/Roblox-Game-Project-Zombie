-- WaveDirectorPlugin.lua
-- A Roblox Studio Plugin for visual wave composition editing and simulation
-- Save this file to: %localappdata%\Roblox\Plugins\WaveDirectorPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Wave Director")
local toggleButton = toolbar:CreateButton(
	"Wave Director",
	"Edit zombie spawn rates and simulate waves",
	"rbxassetid://6031068420" -- Wave icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	500,
	700,
	450,
	550
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("WaveDirectorWidget", widgetInfo)
widget.Title = "🌊 Wave Director"

-- ==================== THEME COLORS ====================
local Theme = {
	Background = Color3.fromRGB(22, 22, 30),
	Surface = Color3.fromRGB(32, 32, 42),
	SurfaceHover = Color3.fromRGB(42, 42, 55),
	Accent = Color3.fromRGB(88, 101, 242), -- Discord-like purple
	AccentHover = Color3.fromRGB(108, 121, 255),
	Success = Color3.fromRGB(87, 242, 135),
	Warning = Color3.fromRGB(254, 231, 92),
	Danger = Color3.fromRGB(237, 66, 69),
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(148, 155, 164),
	Border = Color3.fromRGB(48, 48, 60),
	
	-- Zombie Type Colors
	ZombieColors = {
		Base = Color3.fromRGB(100, 100, 100),
		Runner = Color3.fromRGB(50, 205, 50),
		Shooter = Color3.fromRGB(255, 165, 0),
		Tank = Color3.fromRGB(220, 20, 60),
		Boss = Color3.fromRGB(148, 0, 211),
		Boss2 = Color3.fromRGB(138, 43, 226),
		Boss3 = Color3.fromRGB(75, 0, 130),
	}
}

-- ==================== STATE ====================
local zombieData = {} -- { {TypeName = "Runner", MinWave = 3, Chance = 0.3}, ... }
local gameConfigData = {
	ZombiesPerWavePerPlayer = 5,
	BloodMoonMultiplier = 1.5,
}
local currentTab = "config" -- "config" or "simulator"
local mainFrame = nil

-- ==================== HELPER: Create UI Elements ====================
local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, c1, c2)
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(c1, c2)
	grad.Rotation = 90
	grad.Parent = parent
	return grad
end

local function tweenHover(button, hoverColor, normalColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
	end)
end

-- ==================== DATA PARSING ====================
local function getZombieConfigScript()
	local modFolder = ReplicatedStorage:FindFirstChild("ModuleScript")
	if modFolder then
		return modFolder:FindFirstChild("ZombieConfig")
	end
	return nil
end

local function getGameConfigScript()
	local modFolder = ServerScriptService:FindFirstChild("ModuleScript")
	if modFolder then
		return modFolder:FindFirstChild("GameConfig")
	end
	return nil
end

local function parseZombieConfig()
	local script = getZombieConfigScript()
	if not script then
		warn("[WaveDirector] ZombieConfig not found!")
		return false
	end
	
	zombieData = {}
	local source = script.Source
	
	-- Pattern to find ZombieConfig.Types = { ... }
	local typesBlock = source:match("ZombieConfig%.Types%s*=%s*(%b{})")
	if not typesBlock then
		warn("[WaveDirector] Could not find ZombieConfig.Types table")
		return false
	end

	-- Now iterate inside the Types block
	for typeName, block in typesBlock:gmatch("(%w+)%s*=%s*(%b{})") do
		local minWave = tonumber(block:match("MinWave%s*=%s*(%d+)")) or 0
		local chance = tonumber(block:match("Chance%s*=%s*([%d%.]+)")) or 0
		
		-- Parse stats for Zombie Editor
		local maxHealth = tonumber(block:match("MaxHealth%s*=%s*(%d+)")) or 100
		local walkSpeed = tonumber(block:match("WalkSpeed%s*=%s*([%d%.]+)")) or 10
		local attackDamage = tonumber(block:match("AttackDamage%s*=%s*(%d+)")) or 10
		local attackCooldown = tonumber(block:match("AttackCooldown%s*=%s*([%d%.]+)")) or 1.5
		
		-- Only add if it has Chance or MinWave (i.e., it's a spawnable type)
		if chance > 0 or minWave > 0 then
			table.insert(zombieData, {
				TypeName = typeName,
				MinWave = minWave,
				Chance = chance,
				-- Zombie Stats
				MaxHealth = maxHealth,
				WalkSpeed = walkSpeed,
				AttackDamage = attackDamage,
				AttackCooldown = attackCooldown,
			})
		end
	end
	
	-- Sort by MinWave
	table.sort(zombieData, function(a, b) return a.MinWave < b.MinWave end)
	
	print("[WaveDirector] Parsed " .. #zombieData .. " zombie types.")
	return true
end

local function parseGameConfig()
	local script = getGameConfigScript()
	if not script then
		warn("[WaveDirector] GameConfig not found!")
		return false
	end
	
	local source = script.Source
	gameConfigData.ZombiesPerWavePerPlayer = tonumber(source:match("ZombiesPerWavePerPlayer%s*=%s*(%d+)")) or 5
	gameConfigData.BloodMoonMultiplier = tonumber(source:match("SpawnMultiplier%s*=%s*([%d%.]+)")) or 1.5
	
	print("[WaveDirector] GameConfig loaded. ZombiesPerWave: " .. gameConfigData.ZombiesPerWavePerPlayer)
	return true
end

-- ==================== SAVE LOGIC ====================
local function applyChanges(statusLabel)
	local script = getZombieConfigScript()
	if not script then
		statusLabel.Text = "❌ ZombieConfig not found!"
		statusLabel.TextColor3 = Theme.Danger
		return
	end
	
	ChangeHistoryService:SetWaypoint("Pre-WaveDirector Edit")
	
	local source = script.Source
	local modified = source
	
	for _, data in ipairs(zombieData) do
		-- Replace Chance
		local chancePattern = "(" .. data.TypeName .. "%s*=%s*%b{})"
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(Chance%s*=%s*)[%d%.]+", "%1" .. string.format("%.2f", data.Chance))
		end)
		
		-- Replace MinWave
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(MinWave%s*=%s*)%d+", "%1" .. tostring(data.MinWave))
		end)
		
		-- Replace MaxHealth
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(MaxHealth%s*=%s*)%d+", "%1" .. tostring(data.MaxHealth))
		end)
		
		-- Replace WalkSpeed
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(WalkSpeed%s*=%s*)[%d%.]+", "%1" .. string.format("%.1f", data.WalkSpeed))
		end)
		
		-- Replace AttackDamage
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(AttackDamage%s*=%s*)%d+", "%1" .. tostring(data.AttackDamage))
		end)
		
		-- Replace AttackCooldown
		modified = modified:gsub(chancePattern, function(block)
			return block:gsub("(AttackCooldown%s*=%s*)[%d%.]+", "%1" .. string.format("%.1f", data.AttackCooldown))
		end)
	end
	
	script.Source = modified
	ChangeHistoryService:SetWaypoint("WaveDirector Edit Applied")
	
	statusLabel.Text = "✅ Changes saved!"
	statusLabel.TextColor3 = Theme.Success
	
	-- Fade out status
	task.delay(3, function()
		if statusLabel and statusLabel.Parent then
			TweenService:Create(statusLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
			task.wait(0.5)
			if statusLabel and statusLabel.Parent then
				statusLabel.Text = ""
				statusLabel.TextTransparency = 0
			end
		end
	end)
end

-- ==================== SIMULATION ====================
local function simulateWave(waveNumber, playerCount)
	local total = waveNumber * gameConfigData.ZombiesPerWavePerPlayer * playerCount
	local results = { TotalZombies = total, Breakdown = {} }
	
	-- Create valid types for this wave
	local validTypes = {}
	for _, data in ipairs(zombieData) do
		if not string.find(data.TypeName, "Boss") then -- Skip bosses for now
			if waveNumber >= data.MinWave then
				table.insert(validTypes, { TypeName = data.TypeName, Chance = data.Chance })
			end
		end
	end
	
	-- Sort by MinWave descending (replicating SpawnerModule logic)
	table.sort(validTypes, function(a, b)
		local ma, mb = 0, 0
		for _, d in ipairs(zombieData) do
			if d.TypeName == a.TypeName then ma = d.MinWave end
			if d.TypeName == b.TypeName then mb = d.MinWave end
		end
		return ma > mb
	end)
	
	-- Initialize counts
	for _, data in ipairs(zombieData) do
		results.Breakdown[data.TypeName] = 0
	end
	results.Breakdown["Base"] = 0
	
	-- Simulate spawns
	for _ = 1, total do
		local chosen = nil
		for _, entry in ipairs(validTypes) do
			if math.random() < entry.Chance then
				chosen = entry.TypeName
				break
			end
		end
		
		if chosen then
			results.Breakdown[chosen] = results.Breakdown[chosen] + 1
		else
			results.Breakdown["Base"] = results.Breakdown["Base"] + 1
		end
	end
	
	return results
end

-- ==================== UI CREATION ====================
local function createUI()
	if mainFrame then mainFrame:Destroy() end
	
	-- Main Container
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Theme.Background
	mainFrame.Parent = widget
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Theme.Surface
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	createCorner(header, 0)
	
	local headerGrad = Instance.new("Frame")
	headerGrad.Size = UDim2.new(1, 0, 0, 3)
	headerGrad.Position = UDim2.new(0, 0, 1, -3)
	headerGrad.BorderSizePixel = 0
	headerGrad.Parent = header
	createGradient(headerGrad, Theme.Accent, Theme.Success)
	
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 30)
	title.Position = UDim2.new(0, 15, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🌊 Wave Director"
	title.TextColor3 = Theme.Text
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -20, 0, 18)
	subtitle.Position = UDim2.new(0, 15, 0, 35)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Visual Wave Composition Editor"
	subtitle.TextColor3 = Theme.TextMuted
	subtitle.TextSize = 12
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header
	
	-- Tab Buttons
	local tabFrame = Instance.new("Frame")
	tabFrame.Size = UDim2.new(1, -20, 0, 40)
	tabFrame.Position = UDim2.new(0, 10, 0, 70)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = mainFrame
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabFrame
	
	local function createTabButton(text, tabId, icon)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.48, 0, 1, 0)
		btn.BackgroundColor3 = currentTab == tabId and Theme.Accent or Theme.Surface
		btn.Text = icon .. " " .. text
		btn.TextColor3 = Theme.Text
		btn.TextSize = 13
		btn.Font = Enum.Font.GothamBold
		btn.Parent = tabFrame
		createCorner(btn, 8)
		createStroke(btn, Theme.Border, 1)
		
		return btn
	end
	
	local configTab = createTabButton("Config Editor", "config", "⚙️")
	local simTab = createTabButton("Simulator", "simulator", "🎯")
	
	-- Content Area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -180)
	contentFrame.Position = UDim2.new(0, 10, 0, 120)
	contentFrame.BackgroundColor3 = Theme.Surface
	contentFrame.Parent = mainFrame
	createCorner(contentFrame, 12)
	createStroke(contentFrame, Theme.Border, 1)
	
	-- ===== CONFIG TAB CONTENT =====
	local configContent = Instance.new("ScrollingFrame")
	configContent.Name = "ConfigContent"
	configContent.Size = UDim2.new(1, -16, 1, -16)
	configContent.Position = UDim2.new(0, 8, 0, 8)
	configContent.BackgroundTransparency = 1
	configContent.ScrollBarThickness = 6
	configContent.ScrollBarImageColor3 = Theme.Accent
	configContent.CanvasSize = UDim2.new(0, 0, 0, 0)
	configContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
	configContent.Visible = currentTab == "config"
	configContent.Parent = contentFrame
	
	local configLayout = Instance.new("UIListLayout")
	configLayout.Padding = UDim.new(0, 10)
	configLayout.Parent = configContent
	
	-- Create zombie type cards
	for i, data in ipairs(zombieData) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, -8, 0, 90)
		card.BackgroundColor3 = Theme.SurfaceHover
		card.Parent = configContent
		createCorner(card, 10)
		
		-- Color indicator bar
		local colorBar = Instance.new("Frame")
		colorBar.Size = UDim2.new(0, 5, 1, -10)
		colorBar.Position = UDim2.new(0, 5, 0, 5)
		colorBar.BackgroundColor3 = Theme.ZombieColors[data.TypeName] or Theme.Accent
		colorBar.Parent = card
		createCorner(colorBar, 3)
		
		-- Type Name
		local typeName = Instance.new("TextLabel")
		typeName.Size = UDim2.new(0.5, 0, 0, 25)
		typeName.Position = UDim2.new(0, 20, 0, 8)
		typeName.BackgroundTransparency = 1
		typeName.Text = "🧟 " .. data.TypeName
		typeName.TextColor3 = Theme.Text
		typeName.TextSize = 16
		typeName.Font = Enum.Font.GothamBold
		typeName.TextXAlignment = Enum.TextXAlignment.Left
		typeName.Parent = card
		
		-- MinWave Label & Input
		local minWaveLabel = Instance.new("TextLabel")
		minWaveLabel.Size = UDim2.new(0.35, 0, 0, 18)
		minWaveLabel.Position = UDim2.new(0, 20, 0, 38)
		minWaveLabel.BackgroundTransparency = 1
		minWaveLabel.Text = "Min Wave:"
		minWaveLabel.TextColor3 = Theme.TextMuted
		minWaveLabel.TextSize = 11
		minWaveLabel.Font = Enum.Font.Gotham
		minWaveLabel.TextXAlignment = Enum.TextXAlignment.Left
		minWaveLabel.Parent = card
		
		local minWaveInput = Instance.new("TextBox")
		minWaveInput.Size = UDim2.new(0, 50, 0, 24)
		minWaveInput.Position = UDim2.new(0.25, 0, 0, 35)
		minWaveInput.BackgroundColor3 = Theme.Background
		minWaveInput.Text = tostring(data.MinWave)
		minWaveInput.TextColor3 = Theme.Text
		minWaveInput.TextSize = 12
		minWaveInput.Font = Enum.Font.GothamBold
		minWaveInput.Parent = card
		createCorner(minWaveInput, 5)
		createStroke(minWaveInput, Theme.Border, 1)
		
		minWaveInput.FocusLost:Connect(function()
			local val = tonumber(minWaveInput.Text)
			if val and val >= 0 then
				zombieData[i].MinWave = math.floor(val)
				minWaveInput.Text = tostring(zombieData[i].MinWave)
			else
				minWaveInput.Text = tostring(data.MinWave)
			end
		end)
		
		-- Chance Slider
		local chanceLabel = Instance.new("TextLabel")
		chanceLabel.Size = UDim2.new(0.35, 0, 0, 18)
		chanceLabel.Position = UDim2.new(0, 20, 0, 65)
		chanceLabel.BackgroundTransparency = 1
		chanceLabel.Text = "Chance:"
		chanceLabel.TextColor3 = Theme.TextMuted
		chanceLabel.TextSize = 11
		chanceLabel.Font = Enum.Font.Gotham
		chanceLabel.TextXAlignment = Enum.TextXAlignment.Left
		chanceLabel.Parent = card
		
		local sliderBg = Instance.new("Frame")
		sliderBg.Size = UDim2.new(0.45, 0, 0, 10)
		sliderBg.Position = UDim2.new(0.25, 0, 0, 68)
		sliderBg.BackgroundColor3 = Theme.Background
		sliderBg.Parent = card
		createCorner(sliderBg, 5)
		
		local sliderFill = Instance.new("Frame")
		sliderFill.Size = UDim2.new(math.clamp(data.Chance, 0, 1), 0, 1, 0)
		sliderFill.BackgroundColor3 = Theme.ZombieColors[data.TypeName] or Theme.Accent
		sliderFill.Parent = sliderBg
		createCorner(sliderFill, 5)
		
		local chanceValue = Instance.new("TextLabel")
		chanceValue.Size = UDim2.new(0, 50, 0, 18)
		chanceValue.Position = UDim2.new(0.72, 0, 0, 65)
		chanceValue.BackgroundTransparency = 1
		chanceValue.Text = string.format("%.0f%%", data.Chance * 100)
		chanceValue.TextColor3 = Theme.Text
		chanceValue.TextSize = 12
		chanceValue.Font = Enum.Font.GothamBold
		chanceValue.TextXAlignment = Enum.TextXAlignment.Left
		chanceValue.Parent = card
		
		-- Slider Drag Logic
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
				local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
				sliderFill.Size = UDim2.new(rel, 0, 1, 0)
				zombieData[i].Chance = rel
				chanceValue.Text = string.format("%.0f%%", rel * 100)
			end
		end)
		
		-- Edit Stats Button
		local editBtn = Instance.new("TextButton")
		editBtn.Size = UDim2.new(0, 60, 0, 24)
		editBtn.Position = UDim2.new(1, -70, 0, 8)
		editBtn.BackgroundColor3 = Theme.Accent
		editBtn.Text = "✏️ Edit"
		editBtn.TextColor3 = Theme.Text
		editBtn.TextSize = 11
		editBtn.Font = Enum.Font.GothamBold
		editBtn.Parent = card
		createCorner(editBtn, 6)
		tweenHover(editBtn, Theme.AccentHover, Theme.Accent)
		
		editBtn.MouseButton1Click:Connect(function()
			-- Create Modal Overlay
			local overlay = Instance.new("Frame")
			overlay.Name = "ModalOverlay"
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			overlay.BackgroundTransparency = 0.5
			overlay.ZIndex = 100
			overlay.Parent = mainFrame
			
			local modal = Instance.new("Frame")
			modal.Name = "StatModal"
			modal.Size = UDim2.new(0, 320, 0, 320)
			modal.Position = UDim2.new(0.5, -160, 0.5, -160)
			modal.BackgroundColor3 = Theme.Surface
			modal.ZIndex = 101
			modal.Parent = overlay
			createCorner(modal, 12)
			createStroke(modal, Theme.Accent, 2)
			
			-- Modal Header
			local modalTitle = Instance.new("TextLabel")
			modalTitle.Size = UDim2.new(1, 0, 0, 40)
			modalTitle.BackgroundColor3 = Theme.Accent
			modalTitle.Text = "🧟 Edit: " .. data.TypeName
			modalTitle.TextColor3 = Theme.Text
			modalTitle.TextSize = 16
			modalTitle.Font = Enum.Font.GothamBold
			modalTitle.ZIndex = 102
			modalTitle.Parent = modal
			createCorner(modalTitle, 12)
			
			-- Input Fields
			local function createStatRow(labelText, value, yPos, onChange)
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.5, -10, 0, 30)
				lbl.Position = UDim2.new(0, 15, 0, yPos)
				lbl.BackgroundTransparency = 1
				lbl.Text = labelText
				lbl.TextColor3 = Theme.TextMuted
				lbl.TextSize = 12
				lbl.Font = Enum.Font.Gotham
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 102
				lbl.Parent = modal
				
				local input = Instance.new("TextBox")
				input.Size = UDim2.new(0.4, 0, 0, 28)
				input.Position = UDim2.new(0.55, 0, 0, yPos + 1)
				input.BackgroundColor3 = Theme.Background
				input.Text = tostring(value)
				input.TextColor3 = Theme.Text
				input.TextSize = 13
				input.Font = Enum.Font.GothamBold
				input.ZIndex = 102
				input.Parent = modal
				createCorner(input, 6)
				createStroke(input, Theme.Border, 1)
				
				input.FocusLost:Connect(function()
					local v = tonumber(input.Text)
					if v then onChange(v) end
				end)
				
				return input
			end
			
			local hpInput = createStatRow("❤️ Max Health", data.MaxHealth, 55, function(v) zombieData[i].MaxHealth = math.floor(v) end)
			local speedInput = createStatRow("⚡ Walk Speed", data.WalkSpeed, 95, function(v) zombieData[i].WalkSpeed = v end)
			local dmgInput = createStatRow("⚔️ Attack Damage", data.AttackDamage, 135, function(v) zombieData[i].AttackDamage = math.floor(v) end)
			local cdInput = createStatRow("⏱️ Attack Cooldown", data.AttackCooldown, 175, function(v) zombieData[i].AttackCooldown = v end)
			
			-- Buttons
			local cancelBtn = Instance.new("TextButton")
			cancelBtn.Size = UDim2.new(0.4, 0, 0, 35)
			cancelBtn.Position = UDim2.new(0.05, 0, 0, 230)
			cancelBtn.BackgroundColor3 = Theme.Danger
			cancelBtn.Text = "Cancel"
			cancelBtn.TextColor3 = Theme.Text
			cancelBtn.TextSize = 13
			cancelBtn.Font = Enum.Font.GothamBold
			cancelBtn.ZIndex = 102
			cancelBtn.Parent = modal
			createCorner(cancelBtn, 8)
			
			local confirmBtn = Instance.new("TextButton")
			confirmBtn.Size = UDim2.new(0.4, 0, 0, 35)
			confirmBtn.Position = UDim2.new(0.55, 0, 0, 230)
			confirmBtn.BackgroundColor3 = Theme.Success
			confirmBtn.Text = "Confirm"
			confirmBtn.TextColor3 = Theme.Background
			confirmBtn.TextSize = 13
			confirmBtn.Font = Enum.Font.GothamBold
			confirmBtn.ZIndex = 102
			confirmBtn.Parent = modal
			createCorner(confirmBtn, 8)
			
			local noteLabel = Instance.new("TextLabel")
			noteLabel.Size = UDim2.new(1, -20, 0, 30)
			noteLabel.Position = UDim2.new(0, 10, 0, 275)
			noteLabel.BackgroundTransparency = 1
			noteLabel.Text = "Click 'Apply Changes' to save"
			noteLabel.TextColor3 = Theme.TextMuted
			noteLabel.TextSize = 10
			noteLabel.Font = Enum.Font.Gotham
			noteLabel.ZIndex = 102
			noteLabel.Parent = modal
			
			cancelBtn.MouseButton1Click:Connect(function()
				overlay:Destroy()
			end)
			
			confirmBtn.MouseButton1Click:Connect(function()
				-- Values already updated via FocusLost
				overlay:Destroy()
			end)
		end)
	end
	
	-- ===== SIMULATOR TAB CONTENT =====
	local simContent = Instance.new("Frame")
	simContent.Name = "SimContent"
	simContent.Size = UDim2.new(1, -16, 1, -16)
	simContent.Position = UDim2.new(0, 8, 0, 8)
	simContent.BackgroundTransparency = 1
	simContent.Visible = currentTab == "simulator"
	simContent.Parent = contentFrame
	
	local simLayout = Instance.new("UIListLayout")
	simLayout.Padding = UDim.new(0, 12)
	simLayout.Parent = simContent
	
	-- Wave Input
	local waveInputFrame = Instance.new("Frame")
	waveInputFrame.Size = UDim2.new(1, 0, 0, 60)
	waveInputFrame.BackgroundColor3 = Theme.SurfaceHover
	waveInputFrame.Parent = simContent
	createCorner(waveInputFrame, 10)
	
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Size = UDim2.new(0.5, 0, 0, 25)
	waveLabel.Position = UDim2.new(0, 15, 0, 8)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "🌊 Target Wave"
	waveLabel.TextColor3 = Theme.Text
	waveLabel.TextSize = 14
	waveLabel.Font = Enum.Font.GothamBold
	waveLabel.TextXAlignment = Enum.TextXAlignment.Left
	waveLabel.Parent = waveInputFrame
	
	local waveInput = Instance.new("TextBox")
	waveInput.Size = UDim2.new(0.3, 0, 0, 30)
	waveInput.Position = UDim2.new(0.6, 0, 0, 15)
	waveInput.BackgroundColor3 = Theme.Background
	waveInput.Text = "10"
	waveInput.TextColor3 = Theme.Text
	waveInput.TextSize = 16
	waveInput.Font = Enum.Font.GothamBold
	waveInput.Parent = waveInputFrame
	createCorner(waveInput, 8)
	createStroke(waveInput, Theme.Accent, 2)
	
	-- Player Count Input
	local playerInputFrame = Instance.new("Frame")
	playerInputFrame.Size = UDim2.new(1, 0, 0, 60)
	playerInputFrame.BackgroundColor3 = Theme.SurfaceHover
	playerInputFrame.Parent = simContent
	createCorner(playerInputFrame, 10)
	
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Size = UDim2.new(0.5, 0, 0, 25)
	playerLabel.Position = UDim2.new(0, 15, 0, 8)
	playerLabel.BackgroundTransparency = 1
	playerLabel.Text = "👥 Player Count"
	playerLabel.TextColor3 = Theme.Text
	playerLabel.TextSize = 14
	playerLabel.Font = Enum.Font.GothamBold
	playerLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerLabel.Parent = playerInputFrame
	
	local playerInput = Instance.new("TextBox")
	playerInput.Size = UDim2.new(0.3, 0, 0, 30)
	playerInput.Position = UDim2.new(0.6, 0, 0, 15)
	playerInput.BackgroundColor3 = Theme.Background
	playerInput.Text = "4"
	playerInput.TextColor3 = Theme.Text
	playerInput.TextSize = 16
	playerInput.Font = Enum.Font.GothamBold
	playerInput.Parent = playerInputFrame
	createCorner(playerInput, 8)
	createStroke(playerInput, Theme.Accent, 2)
	
	-- Simulate Button
	local simButton = Instance.new("TextButton")
	simButton.Size = UDim2.new(1, 0, 0, 45)
	simButton.BackgroundColor3 = Theme.Accent
	simButton.Text = "🎲 Run Simulation"
	simButton.TextColor3 = Theme.Text
	simButton.TextSize = 16
	simButton.Font = Enum.Font.GothamBold
	simButton.Parent = simContent
	createCorner(simButton, 10)
	tweenHover(simButton, Theme.AccentHover, Theme.Accent)
	
	-- Results Display
	local resultsFrame = Instance.new("ScrollingFrame")
	resultsFrame.Size = UDim2.new(1, 0, 1, -200)
	resultsFrame.BackgroundColor3 = Theme.Background
	resultsFrame.ScrollBarThickness = 4
	resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	resultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	resultsFrame.Parent = simContent
	createCorner(resultsFrame, 10)
	
	local resultsLayout = Instance.new("UIListLayout")
	resultsLayout.Padding = UDim.new(0, 6)
	resultsLayout.Parent = resultsFrame
	
	local resultsPadding = Instance.new("UIPadding")
	resultsPadding.PaddingTop = UDim.new(0, 10)
	resultsPadding.PaddingBottom = UDim.new(0, 10)
	resultsPadding.PaddingLeft = UDim.new(0, 10)
	resultsPadding.PaddingRight = UDim.new(0, 10)
	resultsPadding.Parent = resultsFrame
	
	local resultsPlaceholder = Instance.new("TextLabel")
	resultsPlaceholder.Size = UDim2.new(1, 0, 0, 50)
	resultsPlaceholder.BackgroundTransparency = 1
	resultsPlaceholder.Text = "Click 'Run Simulation' to see results"
	resultsPlaceholder.TextColor3 = Theme.TextMuted
	resultsPlaceholder.TextSize = 12
	resultsPlaceholder.Font = Enum.Font.Gotham
	resultsPlaceholder.Parent = resultsFrame
	
	simButton.MouseButton1Click:Connect(function()
		local wave = tonumber(waveInput.Text) or 10
		local players = tonumber(playerInput.Text) or 4
		
		-- Clear old results
		for _, child in ipairs(resultsFrame:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		
		local results = simulateWave(wave, players)
		
		-- Total header
		local totalLabel = Instance.new("TextLabel")
		totalLabel.Size = UDim2.new(1, 0, 0, 35)
		totalLabel.BackgroundTransparency = 1
		totalLabel.Text = "📊 Total Zombies: " .. results.TotalZombies
		totalLabel.TextColor3 = Theme.Text
		totalLabel.TextSize = 18
		totalLabel.Font = Enum.Font.GothamBold
		totalLabel.TextXAlignment = Enum.TextXAlignment.Left
		totalLabel.Parent = resultsFrame
		
		-- Breakdown bars
		for typeName, count in pairs(results.Breakdown) do
			if count > 0 then
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 40)
				row.BackgroundColor3 = Theme.SurfaceHover
				row.Parent = resultsFrame
				createCorner(row, 8)
				
				local typeLabel = Instance.new("TextLabel")
				typeLabel.Size = UDim2.new(0.35, 0, 1, 0)
				typeLabel.Position = UDim2.new(0, 10, 0, 0)
				typeLabel.BackgroundTransparency = 1
				typeLabel.Text = typeName
				typeLabel.TextColor3 = Theme.ZombieColors[typeName] or Theme.Text
				typeLabel.TextSize = 13
				typeLabel.Font = Enum.Font.GothamBold
				typeLabel.TextXAlignment = Enum.TextXAlignment.Left
				typeLabel.Parent = row
				
				local barBg = Instance.new("Frame")
				barBg.Size = UDim2.new(0.45, 0, 0, 12)
				barBg.Position = UDim2.new(0.35, 0, 0.5, -6)
				barBg.BackgroundColor3 = Theme.Background
				barBg.Parent = row
				createCorner(barBg, 6)
				
				local barFill = Instance.new("Frame")
				barFill.Size = UDim2.new(math.clamp(count / results.TotalZombies, 0, 1), 0, 1, 0)
				barFill.BackgroundColor3 = Theme.ZombieColors[typeName] or Theme.Accent
				barFill.Parent = barBg
				createCorner(barFill, 6)
				
				local countLabel = Instance.new("TextLabel")
				countLabel.Size = UDim2.new(0.15, 0, 1, 0)
				countLabel.Position = UDim2.new(0.82, 0, 0, 0)
				countLabel.BackgroundTransparency = 1
				countLabel.Text = tostring(count)
				countLabel.TextColor3 = Theme.Text
				countLabel.TextSize = 14
				countLabel.Font = Enum.Font.GothamBold
				countLabel.TextXAlignment = Enum.TextXAlignment.Right
				countLabel.Parent = row
			end
		end
	end)
	
	-- Tab Switching
	local function switchTab(tabId)
		currentTab = tabId
		configContent.Visible = tabId == "config"
		simContent.Visible = tabId == "simulator"
		
		configTab.BackgroundColor3 = tabId == "config" and Theme.Accent or Theme.Surface
		simTab.BackgroundColor3 = tabId == "simulator" and Theme.Accent or Theme.Surface
	end
	
	configTab.MouseButton1Click:Connect(function() switchTab("config") end)
	simTab.MouseButton1Click:Connect(function() switchTab("simulator") end)
	
	-- Bottom Action Bar
	local actionBar = Instance.new("Frame")
	actionBar.Size = UDim2.new(1, -20, 0, 50)
	actionBar.Position = UDim2.new(0, 10, 1, -60)
	actionBar.BackgroundTransparency = 1
	actionBar.Parent = mainFrame
	
	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0, 12)
	actionLayout.Parent = actionBar
	
	local applyBtn = Instance.new("TextButton")
	applyBtn.Size = UDim2.new(0, 140, 0, 42)
	applyBtn.BackgroundColor3 = Theme.Success
	applyBtn.Text = "✅ Apply Changes"
	applyBtn.TextColor3 = Theme.Background
	applyBtn.TextSize = 14
	applyBtn.Font = Enum.Font.GothamBold
	applyBtn.Parent = actionBar
	createCorner(applyBtn, 10)
	tweenHover(applyBtn, Color3.fromRGB(110, 255, 155), Theme.Success)
	
	local reloadBtn = Instance.new("TextButton")
	reloadBtn.Size = UDim2.new(0, 120, 0, 42)
	reloadBtn.BackgroundColor3 = Theme.Warning
	reloadBtn.Text = "🔄 Reload"
	reloadBtn.TextColor3 = Theme.Background
	reloadBtn.TextSize = 14
	reloadBtn.Font = Enum.Font.GothamBold
	reloadBtn.Parent = actionBar
	createCorner(reloadBtn, 10)
	tweenHover(reloadBtn, Color3.fromRGB(255, 245, 120), Theme.Warning)
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(0, 150, 0, 42)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Theme.TextMuted
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Parent = actionBar
	
	applyBtn.MouseButton1Click:Connect(function()
		applyChanges(statusLabel)
	end)
	
	reloadBtn.MouseButton1Click:Connect(function()
		if parseZombieConfig() and parseGameConfig() then
			createUI() -- Rebuild UI with new data
		end
	end)
end

-- ==================== PLUGIN INIT ====================
plugin.Unloading:Connect(function()
	if mainFrame then mainFrame:Destroy() end
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		if parseZombieConfig() and parseGameConfig() then
			createUI()
		end
	end
end)

print("[Wave Director] Plugin Loaded! ✨")
