-- UpgradeShopUI.lua (LocalScript)
-- Path: StarterGui/UpgradeShopUI.lua
-- Script Place: ACT 1: Village

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local ProximityUIHandler = require(ModuleScriptReplicatedStorage:WaitForChild("ProximityUIHandler"))
local ModelPreviewModule = require(ModuleScriptReplicatedStorage:WaitForChild("ModelPreviewModule"))

local proximityHandler
local upgradeEvent = RemoteEvents:WaitForChild("UpgradeUIOpen")
local confirmUpgradeEvent = RemoteEvents:WaitForChild("ConfirmUpgrade")
local upgradeRF = RemoteFunctions:WaitForChild("UpgradeWeaponRF")

-- === THEME CONFIG ===
local THEME = {
	Colors = {
		BgDark = Color3.fromRGB(18, 20, 22),       -- Deep Gunmetal
		BgPanel = Color3.fromRGB(35, 38, 41),      -- Worn Metal
		Border = Color3.fromRGB(70, 75, 70),       -- Rusted Steel
		AccentPrimary = Color3.fromRGB(255, 140, 20), -- Rust Orange
		AccentSecondary = Color3.fromRGB(200, 200, 190), -- Faded White
		Success = Color3.fromRGB(100, 220, 100),   -- Chem Light Green
		Danger = Color3.fromRGB(220, 60, 60),      -- Alert Red
		NodeInactive = Color3.fromRGB(50, 50, 50),
		NodeActive = Color3.fromRGB(255, 160, 40)
	},
	Fonts = {
		Stencil = Enum.Font.Sarpanch,    -- Military Stencil look
		Tech = Enum.Font.RobotoMono,     -- Data readout
		Standard = Enum.Font.GothamBold
	}
}

-- === UI CONSTRUCTION ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UpgradeShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false

-- Blur Effect
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = workspace.CurrentCamera

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 1
overlay.Parent = screenGui

-- Main Container (Landscape Workbench)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "WorkbenchFrame"
mainFrame.Size = UDim2.new(0, 850, 0, 500)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.Colors.BgDark
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = overlay

local mfCorner = Instance.new("UICorner")
mfCorner.CornerRadius = UDim.new(0, 4)
mfCorner.Parent = mainFrame

local mfStroke = Instance.new("UIStroke")
mfStroke.Color = THEME.Colors.Border
mfStroke.Thickness = 2
mfStroke.Parent = mainFrame

-- Top Bar (Visual Decoration)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = THEME.Colors.BgPanel
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Text = "FIELD MODIFICATION BENCH // MK-IV"
titleText.Font = THEME.Fonts.Tech
titleText.TextSize = 14
titleText.TextColor3 = THEME.Colors.AccentSecondary
titleText.Size = UDim2.new(1, -20, 1, 0)
titleText.Position = UDim2.new(0, 20, 0, 0)
titleText.BackgroundTransparency = 1
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -40, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.Font = THEME.Fonts.Stencil
closeBtn.TextSize = 20
closeBtn.TextColor3 = THEME.Colors.AccentSecondary
closeBtn.Parent = topBar

-- === LEFT SIDE: PREVIEW ===
local previewContainer = Instance.new("Frame")
previewContainer.Name = "PreviewSection"
previewContainer.Size = UDim2.new(0.45, 0, 1, -40)
previewContainer.Position = UDim2.new(0, 0, 0, 40)
previewContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
previewContainer.BorderSizePixel = 0
previewContainer.Parent = mainFrame

local viewportFrame = Instance.new("ViewportFrame")
viewportFrame.Size = UDim2.new(1, 0, 1, 0)
viewportFrame.BackgroundTransparency = 1
viewportFrame.Ambient = Color3.fromRGB(200, 200, 200)
viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
viewportFrame.Parent = previewContainer

-- Decorative Grid Line for Preview
local gridLine = Instance.new("Frame")
gridLine.Size = UDim2.new(1, 0, 0, 1)
gridLine.Position = UDim2.new(0, 0, 0.5, 0)
gridLine.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
gridLine.BackgroundTransparency = 0.5
gridLine.Parent = previewContainer

local gridLineV = Instance.new("Frame")
gridLineV.Size = UDim2.new(0, 1, 1, 0)
gridLineV.Position = UDim2.new(0.5, 0, 0, 0)
gridLineV.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
gridLineV.BackgroundTransparency = 0.5
gridLineV.Parent = previewContainer

local weaponTitlePreview = Instance.new("TextLabel")
weaponTitlePreview.Size = UDim2.new(1, -20, 0, 60)
weaponTitlePreview.Position = UDim2.new(0, 20, 0, 10)
weaponTitlePreview.BackgroundTransparency = 1
weaponTitlePreview.Text = "AK-47"
weaponTitlePreview.Font = THEME.Fonts.Stencil
weaponTitlePreview.TextSize = 42
weaponTitlePreview.TextColor3 = Color3.fromRGB(255, 255, 255)
weaponTitlePreview.TextTransparency = 0.9 -- Subtle background text
weaponTitlePreview.TextXAlignment = Enum.TextXAlignment.Left
weaponTitlePreview.Parent = previewContainer

-- === RIGHT SIDE: CONTROLS ===
local controlsContainer = Instance.new("Frame")
controlsContainer.Name = "ControlsSection"
controlsContainer.Size = UDim2.new(0.55, 0, 1, -40)
controlsContainer.Position = UDim2.new(0.45, 0, 0, 40)
controlsContainer.BackgroundTransparency = 1
controlsContainer.Parent = mainFrame

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 30)
contentPadding.PaddingRight = UDim.new(0, 30)
contentPadding.Parent = controlsContainer

-- 1. HEADER INFO
local nameHeader = Instance.new("TextLabel")
nameHeader.Size = UDim2.new(1, 0, 0, 30)
nameHeader.BackgroundTransparency = 1
nameHeader.Text = "ASSAULT RIFLE // AK-47"
nameHeader.Font = THEME.Fonts.Stencil
nameHeader.TextSize = 28
nameHeader.TextColor3 = THEME.Colors.AccentPrimary
nameHeader.TextXAlignment = Enum.TextXAlignment.Left
nameHeader.Parent = controlsContainer

-- 2. PROGRESSION TREE
local treeFrame = Instance.new("Frame")
treeFrame.Name = "ProgressionTree"
treeFrame.Size = UDim2.new(1, 0, 0, 60)
treeFrame.Position = UDim2.new(0, 0, 0, 45)
treeFrame.BackgroundTransparency = 1
treeFrame.Parent = controlsContainer

local nodeContainer = Instance.new("Frame")
nodeContainer.Size = UDim2.new(1, 0, 0, 20)
nodeContainer.Position = UDim2.new(0, 0, 0.5, -10)
nodeContainer.BackgroundTransparency = 1
nodeContainer.Parent = treeFrame

-- Line
local treeLine = Instance.new("Frame")
treeLine.Size = UDim2.new(1, 0, 0, 2)
treeLine.Position = UDim2.new(0, 0, 0.5, -1)
treeLine.BackgroundColor3 = THEME.Colors.NodeInactive
treeLine.BorderSizePixel = 0
treeLine.Parent = nodeContainer

local nodes = {}
local MAX_LEVEL_DISPLAY = 10
for i = 1, MAX_LEVEL_DISPLAY do
	local node = Instance.new("Frame")
	node.Size = UDim2.new(0, 12, 0, 12)
	-- Distribute evenly
	local pct = (i - 1) / (MAX_LEVEL_DISPLAY - 1)
	node.Position = UDim2.new(pct, -6, 0.5, -6)
	node.BackgroundColor3 = THEME.Colors.BgDark
	node.BorderSizePixel = 0
	node.Parent = nodeContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Colors.NodeInactive
	stroke.Thickness = 2
	stroke.Parent = node

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = node

	nodes[i] = {Frame = node, Stroke = stroke}
end

-- 3. STATS GRID
local statsFrame = Instance.new("Frame")
statsFrame.Size = UDim2.new(1, 0, 0, 180)
statsFrame.Position = UDim2.new(0, 0, 0, 120)
statsFrame.BackgroundTransparency = 1
statsFrame.Parent = controlsContainer

local statsList = Instance.new("UIListLayout")
statsList.FillDirection = Enum.FillDirection.Vertical
statsList.Padding = UDim.new(0, 15)
statsList.Parent = statsFrame

local function createStatBar(label)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.Parent = statsFrame

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text = label
	nameLbl.Size = UDim2.new(0.4, 0, 0.5, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = THEME.Fonts.Tech
	nameLbl.TextColor3 = THEME.Colors.AccentSecondary
	nameLbl.TextSize = 12
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = container

	local valLbl = Instance.new("TextLabel")
	valLbl.Text = "100 >> 120"
	valLbl.Size = UDim2.new(0.6, 0, 0.5, 0)
	valLbl.Position = UDim2.new(0.4, 0, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = THEME.Fonts.Tech
	valLbl.TextColor3 = THEME.Colors.AccentPrimary
	valLbl.TextSize = 12
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = container

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 8)
	barBg.Position = UDim2.new(0, 0, 1, -8)
	barBg.BackgroundColor3 = THEME.Colors.BgPanel
	barBg.BorderSizePixel = 0
	barBg.Parent = container
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 2)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.5, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Colors.AccentPrimary
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)

	return {Container = container, ValLabel = valLbl, Fill = fill}
end

local statDmg = createStatBar("DAMAGE OUTPUT")
local statMag = createStatBar("MAGAZINE SIZE")
local statRec = createStatBar("RECOIL STABILITY")

-- 4. ACTION AREA (Bottom)
local actionFrame = Instance.new("Frame")
actionFrame.Size = UDim2.new(1, 0, 0, 80)
actionFrame.Position = UDim2.new(0, 0, 1, -80)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = controlsContainer

local costLbl = Instance.new("TextLabel")
costLbl.Text = "COST: 1500 BP"
costLbl.Size = UDim2.new(1, 0, 0, 20)
costLbl.BackgroundTransparency = 1
costLbl.Font = THEME.Fonts.Tech
costLbl.TextColor3 = THEME.Colors.AccentSecondary
costLbl.TextSize = 14
costLbl.TextXAlignment = Enum.TextXAlignment.Center
costLbl.Parent = actionFrame

local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Name = "UpgradeBtn"
upgradeBtn.Size = UDim2.new(1, 0, 0, 50)
upgradeBtn.Position = UDim2.new(0, 0, 1, -50)
upgradeBtn.BackgroundColor3 = THEME.Colors.BgPanel
upgradeBtn.Text = "" -- Custom text handling
upgradeBtn.AutoButtonColor = false
upgradeBtn.Parent = actionFrame

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = THEME.Colors.AccentPrimary
btnStroke.Thickness = 2
btnStroke.Parent = upgradeBtn
Instance.new("UICorner", upgradeBtn).CornerRadius = UDim.new(0, 4)

local btnFill = Instance.new("Frame")
btnFill.Size = UDim2.new(0, 0, 1, 0)
btnFill.BackgroundColor3 = THEME.Colors.AccentPrimary
btnFill.BorderSizePixel = 0
btnFill.Parent = upgradeBtn
Instance.new("UICorner", btnFill).CornerRadius = UDim.new(0, 4)

local btnText = Instance.new("TextLabel")
btnText.Size = UDim2.new(1, 0, 1, 0)
btnText.BackgroundTransparency = 1
btnText.Text = "HOLD TO UPGRADE"
btnText.Font = THEME.Fonts.Stencil
btnText.TextSize = 18
btnText.TextColor3 = THEME.Colors.AccentPrimary
btnText.ZIndex = 5
btnText.Parent = upgradeBtn


-- === LOGIC ===
local currentTool = nil
local upgradeData = nil
local isUIOpen = false
local distanceConnection = nil
local previewObject = nil

-- Hold Logic
local isHolding = false
local holdTime = 0
local HOLD_DURATION = 1.0
local holdConnection = nil
local canAfford = false

local function cleanupPreview()
	if previewObject then
		ModelPreviewModule.destroy(previewObject)
		previewObject = nil
	end
end

local function closeUI()
	if not isUIOpen then return end
	isUIOpen = false
	isHolding = false
	if holdConnection then holdConnection:Disconnect() end
	if distanceConnection then distanceConnection:Disconnect() end

	if proximityHandler then proximityHandler:SetOpen(false) end

	cleanupPreview()

	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
	TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	local tw = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0)
	})
	tw:Play()
	task.wait(0.3)
	screenGui.Enabled = false
end

local function updateTree(current, nextLvl)
	for i, node in ipairs(nodes) do
		if i < current then
			node.Frame.BackgroundColor3 = THEME.Colors.AccentPrimary
			node.Stroke.Color = THEME.Colors.AccentPrimary
		elseif i == current then
			node.Frame.BackgroundColor3 = THEME.Colors.AccentPrimary
			node.Stroke.Color = THEME.Colors.Success
		elseif i == nextLvl then
			node.Frame.BackgroundColor3 = THEME.Colors.BgDark
			node.Stroke.Color = THEME.Colors.Success
			-- Pulse animation could go here
		else
			node.Frame.BackgroundColor3 = THEME.Colors.BgDark
			node.Stroke.Color = THEME.Colors.NodeInactive
		end
	end
end

-- Math Helpers
local function calcStats(name, level)
	local def = WeaponModule.Weapons[name]
	if not def then return 0,0,0 end

	-- Dmg
	local dmg = (def.Damage or 0) + ((def.UpgradeConfig and def.UpgradeConfig.DamagePerLevel or 5) * level)

	-- Mag
	local mag = def.MaxAmmo or 30
	if level >= 1 then mag = math.floor(mag * 1.5) end

	-- Recoil
	local rec = math.max(0, (def.Recoil or 1) - (level * 0.1))

	return dmg, mag, rec
end

local function updateStatsUI(data)
	local curDmg, curMag, curRec = calcStats(data.weaponName, data.currentLevel)
	local nxtDmg, nxtMag, nxtRec = calcStats(data.weaponName, data.nextLevel)

	statDmg.ValLabel.Text = string.format("%d >> <font color=\"#64dc64\">%d</font>", curDmg, nxtDmg)
	statDmg.ValLabel.RichText = true
	statDmg.Fill.Size = UDim2.new(math.clamp(curDmg/200, 0.05, 1), 0, 1, 0)

	statMag.ValLabel.Text = string.format("%d >> <font color=\"#64dc64\">%d</font>", curMag, nxtMag)
	statMag.ValLabel.RichText = true
	statMag.Fill.Size = UDim2.new(math.clamp(curMag/100, 0.05, 1), 0, 1, 0)

	statRec.ValLabel.Text = string.format("%.1f >> <font color=\"#64dc64\">%.1f</font>", curRec, nxtRec)
	statRec.ValLabel.RichText = true
	statRec.Fill.Size = UDim2.new(math.clamp(1-(curRec/10), 0.05, 1), 0, 1, 0)

	costLbl.Text = "COST: " .. data.cost .. " BP"
	if data.hasDiscount then
		costLbl.TextColor3 = THEME.Colors.Success
	else
		costLbl.TextColor3 = THEME.Colors.AccentSecondary
	end

	-- Check Affordability
	local bp = 0
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("BP") then
		bp = player.leaderstats.BP.Value
	end

	canAfford = (bp >= data.cost)
	if canAfford then
		btnText.Text = "HOLD TO UPGRADE"
		btnText.TextColor3 = THEME.Colors.AccentPrimary
		btnStroke.Color = THEME.Colors.AccentPrimary
		btnFill.BackgroundColor3 = THEME.Colors.AccentPrimary
	else
		btnText.Text = "INSUFFICIENT FUNDS"
		btnText.TextColor3 = THEME.Colors.Danger
		btnStroke.Color = THEME.Colors.Danger
		btnFill.BackgroundColor3 = THEME.Colors.Danger
	end
end

local function refresh()
	if not currentTool then return end
	task.spawn(function()
		local ok, res = pcall(function() return upgradeRF:InvokeServer(currentTool) end)
		if ok and res.success then
			upgradeData = res
			nameHeader.Text = (res.weaponName:upper())
			weaponTitlePreview.Text = res.weaponName:upper()
			updateTree(res.currentLevel, res.nextLevel)
			updateStatsUI(res)
		else
			closeUI()
		end
	end)
end

local function onConfirm()
	if not currentTool then return end
	confirmUpgradeEvent:FireServer(currentTool, true)
	-- Reset hold
	holdTime = 0
	btnFill.Size = UDim2.new(0, 0, 1, 0)
end

-- Input Handling for Hold Button
upgradeBtn.MouseButton1Down:Connect(function()
	if not canAfford then return end
	isHolding = true
	holdTime = 0

	if holdConnection then holdConnection:Disconnect() end
	holdConnection = RunService.RenderStepped:Connect(function(dt)
		if not isHolding then return end
		holdTime = holdTime + dt
		local alpha = math.clamp(holdTime / HOLD_DURATION, 0, 1)
		btnFill.Size = UDim2.new(alpha, 0, 1, 0)

		if alpha >= 1 then
			isHolding = false
			holdConnection:Disconnect()
			onConfirm()
		end
	end)
end)

local function stopHold()
	isHolding = false
	if holdConnection then holdConnection:Disconnect() end
	TweenService:Create(btnFill, TweenInfo.new(0.2), {Size = UDim2.new(0,0,1,0)}):Play()
end

upgradeBtn.MouseButton1Up:Connect(stopHold)
upgradeBtn.MouseLeave:Connect(stopHold)

local function openUI(tool, data)
	if isUIOpen then return end
	isUIOpen = true
	screenGui.Enabled = true
	currentTool = tool
	upgradeData = data

	-- Setup Preview
	cleanupPreview()
	local wStats = WeaponModule.Weapons[data.weaponName]
	local skinName = tool:GetAttribute("EquippedSkin") or wStats.Use_Skin or "Default Skin"
	local skinData = wStats.Skins and wStats.Skins[skinName] or {MeshId="", TextureId=""}

	-- Add MeshId if it's missing in skinData but exists in wStats default
	-- (Logic to ensure we have something to render)
	if (not skinData.MeshId or skinData.MeshId == "") and wStats.Skins["Default Skin"] then
		skinData = wStats.Skins["Default Skin"]
	end

	previewObject = ModelPreviewModule.create(viewportFrame, {Scale = Vector3.new(1.5,1.5,1.5)}, skinData, function(prev)
		ModelPreviewModule.startRotation(prev, 4) -- Zoom 4
	end)

	-- Refresh UI
	refresh()

	-- Anim In
	mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
	overlay.BackgroundTransparency = 1
	blur.Size = 0

	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 15}):Play()
	TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.2}):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	-- Distance Check
	if distanceConnection then distanceConnection:Disconnect() end
	local target = workspace:WaitForChild("Upgrade", 5)
	if target then
		distanceConnection = RunService.RenderStepped:Connect(function()
			if not isUIOpen or not player.Character then return end
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position - target.Position).Magnitude > 8 then
				closeUI()
			end
		end)
	end
end

closeBtn.MouseButton1Click:Connect(closeUI)
upgradeEvent.OnClientEvent:Connect(refresh)

-- Proximity
local upgPart = workspace:WaitForChild("Upgrade", 5)
if upgPart then
	proximityHandler = ProximityUIHandler.Register({
		name = "UpgradeShop",
		partName = "Upgrade",
		parent = workspace,
		searchRecursive = true,
		onToggle = function(isOpen)
			if isOpen then
				local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
				if not tool or not WeaponModule.Weapons[tool.Name] then
					if proximityHandler then proximityHandler:SetOpen(false) end
					return
				end
				local ok, res = pcall(function() return upgradeRF:InvokeServer(tool) end)
				if ok and res.success then
					openUI(tool, res)
				else
					if proximityHandler then proximityHandler:SetOpen(false) end
				end
			else
				closeUI()
			end
		end
	})
end

-- Mobile Scaling
local function onResize()
	if screenGui.AbsoluteSize.X < 850 then
		local scale = screenGui.AbsoluteSize.X / 900
		mainFrame.Size = UDim2.new(0, 850 * scale, 0, 500 * scale)
	else
		mainFrame.Size = UDim2.new(0, 850, 0, 500)
	end
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(onResize)
onResize()
