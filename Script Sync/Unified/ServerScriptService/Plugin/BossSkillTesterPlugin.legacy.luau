-- Plugin Guard: Only run in Plugin context
if not plugin then return {} end

-- BossSkillTesterPlugin.lua
-- A Roblox Studio Plugin for testing boss skills during Play Mode
-- Save this file to: %localappdata%\Roblox\Plugins\BossSkillTesterPlugin.lua

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Plugin Setup
local toolbar = plugin:CreateToolbar("Boss Skill Tester")
local toggleButton = toolbar:CreateButton(
	"Boss Tester",
	"Spawn bosses and trigger skills for testing",
	"rbxassetid://6031068433" -- Skull icon
)

-- Widget Setup
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	400,
	650,
	350,
	500
)

local widget = plugin:CreateDockWidgetPluginGuiAsync("BossSkillTesterWidget", widgetInfo)
widget.Title = "🧪 Boss Skill Tester"

-- ==================== THEME COLORS ====================
local Theme = {
	Background = Color3.fromRGB(20, 18, 25),
	Surface = Color3.fromRGB(32, 28, 38),
	SurfaceHover = Color3.fromRGB(45, 40, 55),
	Accent = Color3.fromRGB(138, 43, 226), -- Purple
	AccentHover = Color3.fromRGB(168, 73, 255),
	Success = Color3.fromRGB(87, 242, 135),
	Warning = Color3.fromRGB(254, 231, 92),
	Danger = Color3.fromRGB(237, 66, 69),
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(148, 155, 164),
	Border = Color3.fromRGB(60, 50, 75),

	-- Boss Colors
	Boss1 = Color3.fromRGB(147, 197, 114), -- Green (Plague Titan)
	Boss2 = Color3.fromRGB(200, 100, 150), -- Pink (Hive Mother)
	Boss3 = Color3.fromRGB(100, 150, 200), -- Blue (Blighted Alchemist)
}

-- ==================== BOSS DATA ====================
local BossData = {
	{
		Key = "Boss",
		Name = "Plague Titan",
		Color = Theme.Boss1,
		Phase1Skills = {"Radiation", "CorrosiveSlam", "ToxicLob"},
		Phase2Skills = {"VolatileMinions", "FissionBarrage"},
		TransitionSkill = "PhaseTransition"
	},
	{
		Key = "Boss2",
		Name = "The Hive Mother",
		Color = Theme.Boss2,
		Phase1Skills = {"AcidSpit", "SpawnLarva"},
		Phase2Skills = {"ToxicCloud", "BroodFrenzy"},
		TransitionSkill = "Metamorphosis"
	},
	{
		Key = "Boss3",
		Name = "The Blighted Alchemist",
		Color = Theme.Boss3,
		Phase1Skills = {"SyringeVolley", "UnstableVials"},
		Phase2Skills = {"CausticCatalyst", "SymbioticLink", "MutatedSpecimens", "PlagueBomb"},
		TransitionSkill = nil
	}
}

-- ==================== STATE ====================
local currentBoss = nil -- Model reference
local currentBossData = nil -- Data from BossData table
local godModeEnabled = false
local mainFrame = nil

-- ==================== HELPER FUNCTIONS ====================
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

local function tweenHover(button, hoverColor, normalColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
	end)
end

local function logStatus(statusLabel, text, color)
	if statusLabel and statusLabel.Parent then
		statusLabel.Text = text
		statusLabel.TextColor3 = color or Theme.Text

		-- Auto fade
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
end

-- ==================== BOSS FUNCTIONS ====================
local function getZombieConfig()
	local modFolder = ReplicatedStorage:FindFirstChild("ModuleScript")
	if modFolder then
		local cfg = modFolder:FindFirstChild("ZombieConfig")
		if cfg then
			return require(cfg)
		end
	end
	return nil
end

local function despawnCurrentBoss()
	if currentBoss and currentBoss.Parent then
		currentBoss:Destroy()
	end
	currentBoss = nil
	currentBossData = nil
end

local function spawnBoss(bossData, statusLabel)
	if not RunService:IsRunning() then
		logStatus(statusLabel, "❌ Start Play Mode first! (F5)", Theme.Danger)
		return false
	end

	-- Get player for spawn position
	local player = Players.LocalPlayer
	if not player or not player.Character then
		logStatus(statusLabel, "❌ No player character found!", Theme.Danger)
		return false
	end

	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		logStatus(statusLabel, "❌ Player has no HumanoidRootPart!", Theme.Danger)
		return false
	end

	-- Despawn existing boss
	despawnCurrentBoss()

	-- Get config
	local zombieConfig = getZombieConfig()
	if not zombieConfig or not zombieConfig.Types[bossData.Key] then
		logStatus(statusLabel, "❌ ZombieConfig not found: " .. bossData.Key, Theme.Danger)
		return false
	end

	local cfg = zombieConfig.Types[bossData.Key]

	-- Create boss model (simplified for testing)
	local spawnPos = rootPart.Position + rootPart.CFrame.LookVector * 25

	-- Try to find existing boss template
	local bossTemplate = nil
	local zombieFolder = Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Enemies")
	if zombieFolder then
		bossTemplate = zombieFolder:FindFirstChild(bossData.Name) or zombieFolder:FindFirstChild(bossData.Key)
	end

	-- Fallback: create simple test model
	local bossModel = Instance.new("Model")
	bossModel.Name = bossData.Name .. "_TEST"

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(6, 8, 4)
	torso.Position = spawnPos
	torso.Anchored = false
	torso.CanCollide = true
	torso.BrickColor = BrickColor.new("Bright violet")
	torso.Material = Enum.Material.Neon
	torso.Parent = bossModel
	bossModel.PrimaryPart = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = cfg.MaxHealth or 75000
	humanoid.Health = cfg.MaxHealth or 75000
	humanoid.WalkSpeed = cfg.WalkSpeed or 8
	humanoid.Parent = bossModel

	-- Add boss tag
	local bossTag = Instance.new("BoolValue")
	bossTag.Name = "IsBoss"
	bossTag.Value = true
	bossTag.Parent = bossModel

	-- Add test marker
	local testTag = Instance.new("BoolValue")
	testTag.Name = "IsTestBoss"
	testTag.Value = true
	testTag.Parent = bossModel

	-- Add billboard for visibility
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = torso

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🧪 " .. bossData.Name .. " (TEST)"
	nameLabel.TextColor3 = bossData.Color
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	bossModel.Parent = Workspace

	currentBoss = bossModel
	currentBossData = bossData

	logStatus(statusLabel, "✅ Spawned: " .. bossData.Name, Theme.Success)
	return true
end

local function toggleGodMode(statusLabel)
	if not RunService:IsRunning() then
		logStatus(statusLabel, "❌ Start Play Mode first!", Theme.Danger)
		return
	end

	local player = Players.LocalPlayer
	if not player or not player.Character then return end

	local hum = player.Character:FindFirstChild("Humanoid")
	if not hum then return end

	godModeEnabled = not godModeEnabled

	if godModeEnabled then
		hum.MaxHealth = math.huge
		hum.Health = math.huge
		logStatus(statusLabel, "🛡️ God Mode: ON", Theme.Success)
	else
		hum.MaxHealth = 100
		hum.Health = 100
		logStatus(statusLabel, "💀 God Mode: OFF", Theme.Warning)
	end
end

local function triggerSkill(skillName, statusLabel)
	if not currentBoss or not currentBoss.Parent then
		logStatus(statusLabel, "❌ No boss spawned!", Theme.Danger)
		return
	end

	if not RunService:IsRunning() then
		logStatus(statusLabel, "❌ Start Play Mode first!", Theme.Danger)
		return
	end

	-- Log skill trigger
	logStatus(statusLabel, "⚡ Triggered: " .. skillName, Theme.Accent)

	-- Fire VFX event if available
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if remoteEvents then
		local skillEvent = remoteEvents:FindFirstChild("PlayBossSkillEvent")
		if skillEvent then
			pcall(function()
				-- Fire to all clients for VFX
				skillEvent:FireAllClients(currentBossData.Key, skillName, currentBoss.PrimaryPart.Position)
			end)
		end
	end

	-- Get boss config
	local zombieConfig = getZombieConfig()
	if not zombieConfig or not zombieConfig.Types[currentBossData.Key] then
		warn("[BossSkillTester] Could not get config for " .. currentBossData.Key)
		return
	end

	local cfg = zombieConfig.Types[currentBossData.Key]
	local skillCfg = cfg[skillName]

	if not skillCfg then
		logStatus(statusLabel, "⚠️ Skill config not found: " .. skillName, Theme.Warning)
		return
	end

	-- TODO: Call actual skill execution from BossModule
	-- This would require exposing skill functions from BossModules
	-- For now, we just log and trigger VFX

	print("[BossSkillTester] Skill triggered: " .. skillName)
	print("[BossSkillTester] Config:", skillCfg)
end

local function forceDamagePercent(percent, statusLabel)
	if not currentBoss or not currentBoss.Parent then
		logStatus(statusLabel, "❌ No boss spawned!", Theme.Danger)
		return
	end

	local hum = currentBoss:FindFirstChild("Humanoid")
	if not hum then return end

	local targetHealth = hum.MaxHealth * (percent / 100)
	hum.Health = math.max(1, targetHealth)

	logStatus(statusLabel, "💥 Set HP to " .. percent .. "%", Theme.Warning)
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
	header.Size = UDim2.new(1, 0, 0, 55)
	header.BackgroundColor3 = Theme.Surface
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerGrad = Instance.new("Frame")
	headerGrad.Size = UDim2.new(1, 0, 0, 3)
	headerGrad.Position = UDim2.new(0, 0, 1, -3)
	headerGrad.BackgroundColor3 = Theme.Accent
	headerGrad.BorderSizePixel = 0
	headerGrad.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 25)
	title.Position = UDim2.new(0, 15, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🧪 Boss Skill Tester"
	title.TextColor3 = Theme.Text
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -20, 0, 15)
	subtitle.Position = UDim2.new(0, 15, 0, 32)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Test boss skills in Play Mode"
	subtitle.TextColor3 = Theme.TextMuted
	subtitle.TextSize = 11
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	-- Status Label
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -20, 0, 25)
	statusLabel.Position = UDim2.new(0, 10, 0, 60)
	statusLabel.BackgroundColor3 = Theme.Surface
	statusLabel.Text = ""
	statusLabel.TextColor3 = Theme.Text
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = mainFrame
	createCorner(statusLabel, 6)

	-- Content Scroll
	local content = Instance.new("ScrollingFrame")
	content.Size = UDim2.new(1, -20, 1, -100)
	content.Position = UDim2.new(0, 10, 0, 90)
	content.BackgroundTransparency = 1
	content.ScrollBarThickness = 6
	content.ScrollBarImageColor3 = Theme.Accent
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.Parent = mainFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.Parent = content

	-- ===== CONTROLS SECTION =====
	local controlsSection = Instance.new("Frame")
	controlsSection.Size = UDim2.new(1, 0, 0, 80)
	controlsSection.BackgroundColor3 = Theme.Surface
	controlsSection.Parent = content
	createCorner(controlsSection, 10)
	createStroke(controlsSection, Theme.Border, 1)

	local controlsTitle = Instance.new("TextLabel")
	controlsTitle.Size = UDim2.new(1, 0, 0, 25)
	controlsTitle.Position = UDim2.new(0, 10, 0, 5)
	controlsTitle.BackgroundTransparency = 1
	controlsTitle.Text = "⚙️ Controls"
	controlsTitle.TextColor3 = Theme.Text
	controlsTitle.TextSize = 14
	controlsTitle.Font = Enum.Font.GothamBold
	controlsTitle.TextXAlignment = Enum.TextXAlignment.Left
	controlsTitle.Parent = controlsSection

	local godModeBtn = Instance.new("TextButton")
	godModeBtn.Size = UDim2.new(0.45, 0, 0, 35)
	godModeBtn.Position = UDim2.new(0.03, 0, 0, 35)
	godModeBtn.BackgroundColor3 = Theme.Success
	godModeBtn.Text = "🛡️ God Mode"
	godModeBtn.TextColor3 = Theme.Background
	godModeBtn.TextSize = 12
	godModeBtn.Font = Enum.Font.GothamBold
	godModeBtn.Parent = controlsSection
	createCorner(godModeBtn, 8)

	godModeBtn.MouseButton1Click:Connect(function()
		toggleGodMode(statusLabel)
	end)

	local despawnBtn = Instance.new("TextButton")
	despawnBtn.Size = UDim2.new(0.45, 0, 0, 35)
	despawnBtn.Position = UDim2.new(0.52, 0, 0, 35)
	despawnBtn.BackgroundColor3 = Theme.Danger
	despawnBtn.Text = "💀 Despawn Boss"
	despawnBtn.TextColor3 = Theme.Text
	despawnBtn.TextSize = 12
	despawnBtn.Font = Enum.Font.GothamBold
	despawnBtn.Parent = controlsSection
	createCorner(despawnBtn, 8)

	despawnBtn.MouseButton1Click:Connect(function()
		despawnCurrentBoss()
		logStatus(statusLabel, "💀 Boss despawned", Theme.Warning)
	end)

	-- ===== BOSS CARDS =====
	for _, bossData in ipairs(BossData) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0) -- Auto height
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = Theme.Surface
		card.Parent = content
		createCorner(card, 10)
		createStroke(card, bossData.Color, 2)

		local cardLayout = Instance.new("UIListLayout")
		cardLayout.Padding = UDim.new(0, 8)
		cardLayout.Parent = card

		local cardPadding = Instance.new("UIPadding")
		cardPadding.PaddingTop = UDim.new(0, 10)
		cardPadding.PaddingBottom = UDim.new(0, 10)
		cardPadding.PaddingLeft = UDim.new(0, 10)
		cardPadding.PaddingRight = UDim.new(0, 10)
		cardPadding.Parent = card

		-- Boss Header
		local bossHeader = Instance.new("Frame")
		bossHeader.Size = UDim2.new(1, 0, 0, 40)
		bossHeader.BackgroundTransparency = 1
		bossHeader.Parent = card

		local bossName = Instance.new("TextLabel")
		bossName.Size = UDim2.new(0.6, 0, 1, 0)
		bossName.BackgroundTransparency = 1
		bossName.Text = "👹 " .. bossData.Name
		bossName.TextColor3 = bossData.Color
		bossName.TextSize = 16
		bossName.Font = Enum.Font.GothamBold
		bossName.TextXAlignment = Enum.TextXAlignment.Left
		bossName.Parent = bossHeader

		local spawnBtn = Instance.new("TextButton")
		spawnBtn.Size = UDim2.new(0.35, 0, 0, 30)
		spawnBtn.Position = UDim2.new(0.65, 0, 0, 5)
		spawnBtn.BackgroundColor3 = bossData.Color
		spawnBtn.Text = "⚡ Spawn"
		spawnBtn.TextColor3 = Theme.Background
		spawnBtn.TextSize = 12
		spawnBtn.Font = Enum.Font.GothamBold
		spawnBtn.Parent = bossHeader
		createCorner(spawnBtn, 6)

		spawnBtn.MouseButton1Click:Connect(function()
			spawnBoss(bossData, statusLabel)
		end)

		-- Phase 1 Skills
		local phase1Label = Instance.new("TextLabel")
		phase1Label.Size = UDim2.new(1, 0, 0, 20)
		phase1Label.BackgroundTransparency = 1
		phase1Label.Text = "📍 Phase 1 Skills"
		phase1Label.TextColor3 = Theme.TextMuted
		phase1Label.TextSize = 11
		phase1Label.Font = Enum.Font.Gotham
		phase1Label.TextXAlignment = Enum.TextXAlignment.Left
		phase1Label.Parent = card

		local phase1Grid = Instance.new("Frame")
		phase1Grid.Size = UDim2.new(1, 0, 0, 0)
		phase1Grid.AutomaticSize = Enum.AutomaticSize.Y
		phase1Grid.BackgroundTransparency = 1
		phase1Grid.Parent = card

		local phase1GridLayout = Instance.new("UIGridLayout")
		phase1GridLayout.CellSize = UDim2.new(0.48, 0, 0, 32)
		phase1GridLayout.CellPadding = UDim2.new(0.02, 0, 0, 5)
		phase1GridLayout.Parent = phase1Grid

		for _, skillName in ipairs(bossData.Phase1Skills) do
			local skillBtn = Instance.new("TextButton")
			skillBtn.BackgroundColor3 = Theme.SurfaceHover
			skillBtn.Text = "🎯 " .. skillName
			skillBtn.TextColor3 = Theme.Text
			skillBtn.TextSize = 10
			skillBtn.Font = Enum.Font.GothamBold
			skillBtn.Parent = phase1Grid
			createCorner(skillBtn, 5)
			tweenHover(skillBtn, Theme.Accent, Theme.SurfaceHover)

			skillBtn.MouseButton1Click:Connect(function()
				triggerSkill(skillName, statusLabel)
			end)
		end

		-- Phase 2 Skills
		local phase2Label = Instance.new("TextLabel")
		phase2Label.Size = UDim2.new(1, 0, 0, 20)
		phase2Label.BackgroundTransparency = 1
		phase2Label.Text = "🔥 Phase 2 Skills"
		phase2Label.TextColor3 = Theme.TextMuted
		phase2Label.TextSize = 11
		phase2Label.Font = Enum.Font.Gotham
		phase2Label.TextXAlignment = Enum.TextXAlignment.Left
		phase2Label.Parent = card

		local phase2Grid = Instance.new("Frame")
		phase2Grid.Size = UDim2.new(1, 0, 0, 0)
		phase2Grid.AutomaticSize = Enum.AutomaticSize.Y
		phase2Grid.BackgroundTransparency = 1
		phase2Grid.Parent = card

		local phase2GridLayout = Instance.new("UIGridLayout")
		phase2GridLayout.CellSize = UDim2.new(0.48, 0, 0, 32)
		phase2GridLayout.CellPadding = UDim2.new(0.02, 0, 0, 5)
		phase2GridLayout.Parent = phase2Grid

		for _, skillName in ipairs(bossData.Phase2Skills) do
			local skillBtn = Instance.new("TextButton")
			skillBtn.BackgroundColor3 = Theme.SurfaceHover
			skillBtn.Text = "💥 " .. skillName
			skillBtn.TextColor3 = Theme.Text
			skillBtn.TextSize = 10
			skillBtn.Font = Enum.Font.GothamBold
			skillBtn.Parent = phase2Grid
			createCorner(skillBtn, 5)
			tweenHover(skillBtn, Theme.Danger, Theme.SurfaceHover)

			skillBtn.MouseButton1Click:Connect(function()
				triggerSkill(skillName, statusLabel)
			end)
		end

		-- Transition / Damage Control
		local damageFrame = Instance.new("Frame")
		damageFrame.Size = UDim2.new(1, 0, 0, 35)
		damageFrame.BackgroundTransparency = 1
		damageFrame.Parent = card

		local dmg50Btn = Instance.new("TextButton")
		dmg50Btn.Size = UDim2.new(0.3, 0, 0, 30)
		dmg50Btn.Position = UDim2.new(0, 0, 0, 0)
		dmg50Btn.BackgroundColor3 = Theme.Warning
		dmg50Btn.Text = "HP 50%"
		dmg50Btn.TextColor3 = Theme.Background
		dmg50Btn.TextSize = 10
		dmg50Btn.Font = Enum.Font.GothamBold
		dmg50Btn.Parent = damageFrame
		createCorner(dmg50Btn, 5)

		dmg50Btn.MouseButton1Click:Connect(function()
			forceDamagePercent(50, statusLabel)
		end)

		local dmg25Btn = Instance.new("TextButton")
		dmg25Btn.Size = UDim2.new(0.3, 0, 0, 30)
		dmg25Btn.Position = UDim2.new(0.35, 0, 0, 0)
		dmg25Btn.BackgroundColor3 = Theme.Warning
		dmg25Btn.Text = "HP 25%"
		dmg25Btn.TextColor3 = Theme.Background
		dmg25Btn.TextSize = 10
		dmg25Btn.Font = Enum.Font.GothamBold
		dmg25Btn.Parent = damageFrame
		createCorner(dmg25Btn, 5)

		dmg25Btn.MouseButton1Click:Connect(function()
			forceDamagePercent(25, statusLabel)
		end)

		local killBtn = Instance.new("TextButton")
		killBtn.Size = UDim2.new(0.3, 0, 0, 30)
		killBtn.Position = UDim2.new(0.7, 0, 0, 0)
		killBtn.BackgroundColor3 = Theme.Danger
		killBtn.Text = "Kill"
		killBtn.TextColor3 = Theme.Text
		killBtn.TextSize = 10
		killBtn.Font = Enum.Font.GothamBold
		killBtn.Parent = damageFrame
		createCorner(killBtn, 5)

		killBtn.MouseButton1Click:Connect(function()
			if currentBoss and currentBoss.Parent then
				local hum = currentBoss:FindFirstChild("Humanoid")
				if hum then
					hum.Health = 0
					logStatus(statusLabel, "💀 Boss killed", Theme.Danger)
				end
			end
		end)
	end

	-- ===== PLAY MODE WARNING =====
	if not RunService:IsRunning() then
		local warning = Instance.new("Frame")
		warning.Size = UDim2.new(1, 0, 0, 60)
		warning.BackgroundColor3 = Theme.Danger
		warning.LayoutOrder = -1 -- Show first
		warning.Parent = content
		createCorner(warning, 10)

		local warningText = Instance.new("TextLabel")
		warningText.Size = UDim2.new(1, -20, 1, 0)
		warningText.Position = UDim2.new(0, 10, 0, 0)
		warningText.BackgroundTransparency = 1
		warningText.Text = "⚠️ PLAY MODE REQUIRED\nPress F5 to start Play Mode"
		warningText.TextColor3 = Theme.Text
		warningText.TextSize = 14
		warningText.Font = Enum.Font.GothamBold
		warningText.Parent = warning
	end
end

-- ==================== CLEANUP ====================
plugin.Unloading:Connect(function()
	despawnCurrentBoss()
	if mainFrame then mainFrame:Destroy() end
end)

-- ==================== INIT ====================
toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		createUI()
	end
end)

-- Refresh UI when play mode changes
RunService:BindToRenderStep("BossSkillTesterCheck", Enum.RenderPriority.Last.Value, function()
	-- One-time check, unbind after
	RunService:UnbindFromRenderStep("BossSkillTesterCheck")
	if widget.Enabled then
		createUI()
	end
end)

print("[Boss Skill Tester] Plugin Loaded ✅")
