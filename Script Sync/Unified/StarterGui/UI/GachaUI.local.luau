-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return end

-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby
-- Theme: Glitchy CRT / Vending Machine Interface (Retro-Futuristic, Cyberpunk Decay)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

-- ================== MODULE & EVENT REFERENCES ==================
local ModuleScriptReplicated = ReplicatedStorage:WaitForChild("ModuleScript")
local WeaponModule = require(ModuleScriptReplicated:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ModuleScriptReplicated:WaitForChild("ModelPreviewModule"))

local GachaRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaRollEvent")
local GachaMultiRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaMultiRollEvent")
local GachaFreeRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaFreeRollEvent")
local GetGachaConfig = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetGachaConfig")
local GetGachaStatus = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetGachaStatus")
local CoinsUpdateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CoinsUpdateEvent")

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		CRT_BG = Color3.fromRGB(10, 15, 20),      -- Dark Screen
		CRT_GLOW = Color3.fromRGB(0, 255, 255),   -- Cyan Phosphor
		CRT_DIM = Color3.fromRGB(0, 80, 80),      -- Dim Cyan
		CRT_ALERT = Color3.fromRGB(255, 0, 50),   -- Error Red
		CRT_GOLD = Color3.fromRGB(255, 200, 0),   -- Legendary Gold
		Scanline = Color3.fromRGB(0, 0, 0),
		Frame = Color3.fromRGB(40, 40, 50)        -- Machine Casing
	},
	Fonts = {
		Main = Enum.Font.Code,                -- Retro Terminal
		Header = Enum.Font.Arcade,            -- Blocky Header
		Label = Enum.Font.RobotoMono          -- Readable Tech
	}
}

-- ================== STATE MANAGEMENT ==================
local state = {
	coins = 0,
	currentWeaponId = nil,
	currentSkinId = nil,
	freeRollAvailable = false,
	isRolling = false,
	pityCount = 0,
	pityThreshold = 50, 
	gachaConfig = {
		costs = { roll1 = 1500, roll10 = 15000 },
		rarities = { legendary = 5, booster = 10, common = 85 },
	},
	blurEffect = nil -- Blur Effect Reference
}

-- ================== UI ELEMENT REFERENCES ==================
local ui = {}
local createUI, toggleGachaUI, updateMainUI, populateWeaponSelector

-- ================== HELPER FUNCTIONS ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		if prop == "BackgroundColor" then
			inst.BackgroundColor3 = value
		else
			inst[prop] = value
		end
	end
	return inst
end

local function addScanlines(parent)
	local scan = create("ImageLabel", {
		Name = "Scanlines",
		Parent = parent,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://7357494639", -- Scanline texture
		ImageColor3 = Color3.new(0,0,0),
		ImageTransparency = 0.8,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.new(0, 0, 0, 4),
		ZIndex = 100 -- Top layer
	})
	return scan
end

local function addCRTFlicker(frame)
	task.spawn(function()
		while frame and frame.Parent do
			local flicker = math.random()
			if flicker > 0.95 then
				frame.ImageTransparency = 0.5
				task.wait(0.05)
				frame.ImageTransparency = 0.8
			end
			task.wait(0.1)
		end
	end)
end

local function showButtonFeedback(button, message)
	local originalText = button.Text
	local originalColor = button.BackgroundColor3

	button.Text = "ERR: " .. message
	button.BackgroundColor3 = THEME.Colors.CRT_ALERT

	task.wait(1)

	if button and button.Parent then
		button.Text = originalText
		button.BackgroundColor3 = originalColor
	end
end

local function handleRoll(rollType)
	if state.isRolling or not state.currentWeaponId then return end

	local cost = 0
	local canAfford = false
	local remoteEvent = nil
	local isFree = false

	if rollType == "single" then
		cost = state.gachaConfig.costs.roll1
		canAfford = state.coins >= cost
		remoteEvent = GachaRollEvent
	elseif rollType == "multi" then
		cost = state.gachaConfig.costs.roll10
		canAfford = state.coins >= cost
		remoteEvent = GachaMultiRollEvent
	elseif rollType == "free" then
		canAfford = state.freeRollAvailable
		remoteEvent = GachaFreeRollEvent
		isFree = true
	end

	if not canAfford then
		local button
		if rollType == "single" then button = ui.rollButton1
		elseif rollType == "multi" then button = ui.rollButton10
		else button = ui.freeRollButton end
		showButtonFeedback(button, "INSUFFICIENT FUNDS")
		return
	end

	state.isRolling = true
	if not isFree then
		state.coins = state.coins - cost
	else
		state.freeRollAvailable = false
	end
	updateMainUI()

	remoteEvent:FireServer(state.currentWeaponId)
end

-- ================== VISUAL LOGIC ==================

updateMainUI = function()
	if not state.currentWeaponId or not ui.screen then return end

	local weaponData = WeaponModule.Weapons[state.currentWeaponId]
	if not weaponData then return end

	-- Update Text
	ui.headerText.Text = "> TARGET: " .. string.upper(weaponData.Name or "Unknown")

	ui.statsLabel.Text = string.format("DMG:%s\nAMMO:%s/%s\nRPM:%s", 
		weaponData.Damage or "ERR", 
		weaponData.MaxAmmo or "ERR", 
		weaponData.ReserveAmmo or "ERR",
		weaponData.FireRate or "ERR"
	)

	-- Update Viewport
	if ui.viewport then
		ui.viewport:ClearAllChildren()
		local firstSkinName = next(weaponData.Skins)
		local firstSkinData = firstSkinName and weaponData.Skins[firstSkinName]
		if firstSkinData then
			local preview = ModelPreviewModule.create(ui.viewport, weaponData, firstSkinData)
			ModelPreviewModule.startRotation(preview, 2)
		end
	end

	-- Update Buttons
	ui.rollButton1.Interactable = not state.isRolling
	ui.rollButton10.Interactable = not state.isRolling
	ui.freeRollButton.Interactable = not state.isRolling

	local cost1 = state.gachaConfig.costs.roll1 or 1500
	local cost10 = state.gachaConfig.costs.roll10 or 15000

	ui.rollButton1.Text = string.format("[ DISPENSE x1 ]\n%s CR", cost1)
	ui.rollButton10.Text = string.format("[ BATCH x10 ]\n%s CR", cost10)

	if state.freeRollAvailable and not state.isRolling then
		ui.freeRollButton.Text = "FREE SAMPLE\n[ READY ]"
		ui.freeRollButton.TextColor3 = THEME.Colors.CRT_GLOW
	else
		ui.freeRollButton.Text = "FREE SAMPLE\n[ COOLDOWN ]"
		ui.freeRollButton.TextColor3 = THEME.Colors.CRT_DIM
	end

	ui.coinsLabel.Text = "CREDITS: " .. state.coins

	local pityRemaining = math.max(0, state.pityThreshold - state.pityCount)
	ui.pityLabel.Text = string.format("PITY_COUNTER: %02d", pityRemaining)
end

populateWeaponSelector = function()
	if not ui.weaponList then return end
	for _, c in ipairs(ui.weaponList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	local gachaWeapons = {}
	for weaponName, weaponData in pairs(WeaponModule.Weapons) do
		if next(weaponData.Skins or {}) then
			table.insert(gachaWeapons, {name = weaponName, data = weaponData})
		end
	end
	table.sort(gachaWeapons, function(a, b) return a.name < b.name end)

	if not state.currentWeaponId and #gachaWeapons > 0 then
		state.currentWeaponId = gachaWeapons[1].name
	end

	for _, weapon in ipairs(gachaWeapons) do
		local btn = create("TextButton", { 
			Name = weapon.name, 
			Parent = ui.weaponList, 
			Size = UDim2.new(1, 0, 0, 40), 
			Text = " > " .. string.upper(weapon.name), 
			Font = THEME.Fonts.Main, 
			TextColor3 = (state.currentWeaponId == weapon.name) and THEME.Colors.CRT_GLOW or THEME.Colors.CRT_DIM,
			BackgroundColor = (state.currentWeaponId == weapon.name) and THEME.Colors.CRT_DIM or THEME.Colors.CRT_BG,
			BackgroundTransparency = 0.5,
			TextXAlignment = Enum.TextXAlignment.Left, 
			TextSize = 14
		})

		btn.MouseButton1Click:Connect(function()
			state.currentWeaponId = weapon.name
			populateWeaponSelector() -- Re-render to update highlights
			updateMainUI()
		end)
	end
end

-- Animation for result
local function showRollAnimation(onComplete)
	ui.overlay.Visible = true
	-- Access child StatusText safely
	local txt = ui.overlay:FindFirstChild("StatusText")
	if txt then
		txt.Text = "INITIALIZING..."

		local steps = {"CONNECTING...", "DOWNLOADING...", "DECRYPTING...", "FINALIZING..."}
		for _, s in ipairs(steps) do
			txt.Text = s
			task.wait(0.2)
		end
	end

	ui.overlay.Visible = false
	if onComplete then onComplete() end
end

local function showResultModal(prize)
	if not prize then 
		state.isRolling = false
		updateMainUI()
		return 
	end

	local name = prize.SkinName or prize.Name or "Unknown"
	local rarity = "COMMON"
	local color = THEME.Colors.CRT_GLOW

	if prize.Type == "Skin" then
		rarity = "LEGENDARY ITEM"
		color = THEME.Colors.CRT_GOLD
	elseif prize.Type == "Booster" then
		rarity = "RARE ITEM"
		color = Color3.fromRGB(200, 100, 255)
	else
		name = (prize.Amount or 0) .. " CREDITS"
	end

	ui.resultModal.Visible = true

	-- FIX: Access Title properly
	local title = ui.resultModal:FindFirstChild("Title")
	if title then title.Text = "ACQUISITION SUCCESSFUL" end

	ui.resultModal.ItemName.Text = string.upper(name)
	ui.resultModal.ItemName.TextColor3 = color
	ui.resultModal.Rarity.Text = rarity
	ui.resultModal.Rarity.TextColor3 = color

	state.isRolling = false
	updateMainUI()
end

local function showMultiResultModal(prizes)
	-- Populate grid
	for _, c in ipairs(ui.multiGrid:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	for _, prize in ipairs(prizes or {}) do
		local name = prize.SkinName or prize.Name or ((prize.Amount or 0).." CR")
		local color = THEME.Colors.CRT_GLOW
		if prize.Type == "Skin" then color = THEME.Colors.CRT_GOLD end

		local frame = create("Frame", {
			Parent = ui.multiGrid, BackgroundColor = Color3.fromRGB(20, 30, 40), BorderSizePixel = 1, BorderColor3 = color
		})
		create("TextLabel", {
			Parent = frame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
			Text = name, TextColor3 = color, TextWrapped = true, Font = THEME.Fonts.Main, TextSize = 12
		})
	end

	ui.multiModal.Visible = true
	state.isRolling = false
	updateMainUI()
end

-- ================== UI CREATION ==================

createUI = function()
	if player.PlayerGui:FindFirstChild("GachaUI") then player.PlayerGui.GachaUI:Destroy() end

	ui.screen = create("ScreenGui", { Name = "GachaUI", Parent = player.PlayerGui, ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false })

	-- Initialize Blur Effect
	local camera = workspace.CurrentCamera
	state.blurEffect = create("BlurEffect", {Parent = camera, Size = 0, Enabled = false})

	-- Dark Background
	create("Frame", { Parent=ui.screen, Size=UDim2.new(1,0,1,0), BackgroundColor=Color3.new(0,0,0), BackgroundTransparency=0.2 })

	-- Main CRT Monitor Frame
	local monitor = create("Frame", {
		Name = "Monitor", Parent = ui.screen,
		Size = UDim2.new(0, 900, 0, 600), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = THEME.Colors.Frame
	})
	create("UICorner", {Parent=monitor, CornerRadius=UDim.new(0, 16)})

	-- Screen Area
	local screenArea = create("Frame", {
		Name = "Screen", Parent = monitor,
		Size = UDim2.new(0.95, 0, 0.95, 0), Position = UDim2.new(0.025, 0, 0.025, 0),
		BackgroundColor = THEME.Colors.CRT_BG, ClipsDescendants = true
	})
	create("UICorner", {Parent=screenArea, CornerRadius=UDim.new(0, 8)})
	create("UIStroke", {Parent=screenArea, Color=THEME.Colors.CRT_GLOW, Thickness=2, Transparency=0.5})

	-- Scanlines Overlay
	local sl = addScanlines(screenArea)
	addCRTFlicker(sl)

	-- Close Button
	local closeBtn = create("TextButton", {
		Parent = screenArea, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1, 0),
		Text = "X", TextColor3 = THEME.Colors.CRT_ALERT, BackgroundTransparency = 1, Font = THEME.Fonts.Header, TextSize = 24, ZIndex=200
	})
	closeBtn.MouseButton1Click:Connect(function() toggleGachaUI(false) end)

	-- Header
	ui.headerText = create("TextLabel", {
		Parent = screenArea, Size = UDim2.new(1, -50, 0, 40), Position = UDim2.new(0, 20, 0, 10),
		Text = "> SYSTEM READY", Font = THEME.Fonts.Header, TextSize = 28,
		TextColor3 = THEME.Colors.CRT_GLOW, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})

	-- Left Column: Weapon List
	local leftCol = create("Frame", {
		Parent = screenArea, Size = UDim2.new(0.3, 0, 0.8, 0), Position = UDim2.new(0.02, 0, 0.15, 0),
		BackgroundColor = Color3.fromRGB(0, 20, 30), BackgroundTransparency = 0.5
	})
	create("UIStroke", {Parent=leftCol, Color=THEME.Colors.CRT_DIM, Thickness=1})

	ui.weaponList = create("ScrollingFrame", {
		Parent = leftCol, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.Colors.CRT_GLOW
	})
	create("UIListLayout", {Parent=ui.weaponList, Padding=UDim.new(0,2)})

	-- Right Column: Preview & Actions
	local rightCol = create("Frame", {
		Parent = screenArea, Size = UDim2.new(0.65, 0, 0.8, 0), Position = UDim2.new(0.33, 0, 0.15, 0),
		BackgroundTransparency = 1
	})

	-- Viewport (Grid Background)
	local viewFrame = create("Frame", {
		Parent = rightCol, Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor = Color3.fromRGB(0, 10, 10)
	})
	create("UIStroke", {Parent=viewFrame, Color=THEME.Colors.CRT_GLOW, Thickness=1})

	create("ImageLabel", { -- Grid
		Parent = viewFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
		Image = "rbxassetid://4801088331", ImageColor3 = THEME.Colors.CRT_DIM, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.new(0, 32, 0, 32)
	})

	ui.viewport = create("ViewportFrame", {
		Parent = viewFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1
	})

	-- Info Panel below viewport
	local infoPanel = create("Frame", {
		Parent = rightCol, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.52, 0),
		BackgroundColor = Color3.fromRGB(0, 20, 30), BackgroundTransparency = 0.5
	})

	ui.statsLabel = create("TextLabel", {
		Parent = infoPanel, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0.05, 0, 0, 0),
		Text = "STATS_NULL", Font = THEME.Fonts.Main, TextSize = 14, TextColor3 = THEME.Colors.CRT_GLOW,
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
	})

	ui.pityLabel = create("TextLabel", {
		Parent = infoPanel, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.55, 0, 0, 0),
		Text = "PITY: 00", Font = THEME.Fonts.Header, TextSize = 20, TextColor3 = THEME.Colors.CRT_ALERT,
		TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1
	})

	-- Buttons Area
	local btnArea = create("Frame", {
		Parent = rightCol, Size = UDim2.new(1, 0, 0.25, 0), Position = UDim2.new(0, 0, 0.75, 0),
		BackgroundTransparency = 1
	})

	ui.rollButton1 = create("TextButton", {
		Parent = btnArea, Size = UDim2.new(0.3, 0, 0.8, 0), Position = UDim2.new(0, 0, 0.1, 0),
		BackgroundColor = THEME.Colors.CRT_DIM, TextColor3 = THEME.Colors.CRT_GLOW, Font = THEME.Fonts.Label, TextSize = 14
	})
	ui.rollButton10 = create("TextButton", {
		Parent = btnArea, Size = UDim2.new(0.3, 0, 0.8, 0), Position = UDim2.new(0.35, 0, 0.1, 0),
		BackgroundColor = THEME.Colors.CRT_DIM, TextColor3 = THEME.Colors.CRT_GLOW, Font = THEME.Fonts.Label, TextSize = 14
	})
	ui.freeRollButton = create("TextButton", {
		Parent = btnArea, Size = UDim2.new(0.3, 0, 0.8, 0), Position = UDim2.new(0.7, 0, 0.1, 0),
		BackgroundColor = Color3.fromRGB(0, 40, 40), TextColor3 = THEME.Colors.CRT_DIM, Font = THEME.Fonts.Label, TextSize = 14
	})

	-- Footer info
	ui.coinsLabel = create("TextLabel", {
		Parent = screenArea, Size = UDim2.new(0.3, 0, 0.05, 0), Position = UDim2.new(0.02, 0, 0.95, 0),
		Text = "CREDITS: 0", Font = THEME.Fonts.Main, TextColor3 = THEME.Colors.CRT_GLOW, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left
	})

	-- Overlays
	ui.overlay = create("Frame", {
		Name = "LoadingOverlay", Parent = screenArea, Size = UDim2.new(1,0,1,0), BackgroundColor = Color3.new(0,0,0), BackgroundTransparency = 0.1, Visible = false, ZIndex=150
	})

	-- FIX: Removed assigning to ui.overlay.StatusText. Just create it as a child.
	create("TextLabel", {
		Name = "StatusText",
		Parent = ui.overlay, Size = UDim2.new(1,0,0.2,0), Position = UDim2.new(0,0,0.4,0),
		Text = "PROCESSING...", Font = THEME.Fonts.Header, TextColor3 = THEME.Colors.CRT_GLOW, TextSize = 36, BackgroundTransparency = 1
	})

	ui.resultModal = create("Frame", {
		Name = "ResultModal", Parent = screenArea, Size = UDim2.new(0.6, 0, 0.4, 0), Position = UDim2.new(0.2, 0, 0.3, 0),
		BackgroundColor = Color3.fromRGB(0, 20, 25), Visible = false, ZIndex=160
	})
	create("UIStroke", {Parent=ui.resultModal, Color=THEME.Colors.CRT_GLOW, Thickness=2})

	-- Store references in a separate table or just create them
	create("TextLabel", { Name="Title", Parent=ui.resultModal, Size=UDim2.new(1,0,0.2,0), Text="SUCCESS", Font=THEME.Fonts.Header, TextColor3=THEME.Colors.CRT_GLOW, TextSize=24, BackgroundTransparency=1 })
	create("TextLabel", { Name="ItemName", Parent=ui.resultModal, Size=UDim2.new(1,0,0.3,0), Position=UDim2.new(0,0,0.3,0), Text="ITEM", Font=THEME.Fonts.Main, TextColor3=THEME.Colors.CRT_GLOW, TextSize=20, BackgroundTransparency=1 })
	create("TextLabel", { Name="Rarity", Parent=ui.resultModal, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,0.6,0), Text="COMMON", Font=THEME.Fonts.Label, TextColor3=THEME.Colors.CRT_DIM, TextSize=14, BackgroundTransparency=1 })

	local resOk = create("TextButton", { Parent=ui.resultModal, Size=UDim2.new(0.4,0,0.2,0), Position=UDim2.new(0.3,0,0.8,0), Text="ACKNOWLEDGE", BackgroundColor=THEME.Colors.CRT_DIM, TextColor3=THEME.Colors.CRT_GLOW, Font=THEME.Fonts.Main })
	resOk.MouseButton1Click:Connect(function() ui.resultModal.Visible = false end)

	ui.multiModal = create("Frame", {
		Name = "MultiModal", Parent = screenArea, Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.1, 0, 0.1, 0),
		BackgroundColor = Color3.fromRGB(0, 20, 25), Visible = false, ZIndex=160
	})
	create("UIStroke", {Parent=ui.multiModal, Color=THEME.Colors.CRT_GLOW, Thickness=2})
	ui.multiGrid = create("ScrollingFrame", { Parent=ui.multiModal, Size=UDim2.new(0.9,0,0.8,0), Position=UDim2.new(0.05,0,0.05,0), BackgroundTransparency=1, BorderSizePixel=0 })
	create("UIGridLayout", {Parent=ui.multiGrid, CellSize=UDim2.new(0,100,0,100), CellPadding=UDim2.new(0,10,0,10)})

	local multiOk = create("TextButton", { Parent=ui.multiModal, Size=UDim2.new(0.3,0,0.1,0), Position=UDim2.new(0.35,0,0.88,0), Text="ACCEPT BATCH", BackgroundColor=THEME.Colors.CRT_DIM, TextColor3=THEME.Colors.CRT_GLOW, Font=THEME.Fonts.Main })
	multiOk.MouseButton1Click:Connect(function() ui.multiModal.Visible = false end)

	-- Events
	ui.rollButton1.MouseButton1Click:Connect(function() handleRoll("single") end)
	ui.rollButton10.MouseButton1Click:Connect(function() handleRoll("multi") end)
	ui.freeRollButton.MouseButton1Click:Connect(function() handleRoll("free") end)

	GachaRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)
	GachaMultiRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showMultiResultModal(result.Prizes) end) end)
	GachaFreeRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)

end


-- ================== INITIALIZATION ==================

toggleGachaUI = function(visible)
	if visible then
		if not ui.screen then createUI() end
		ui.screen.Enabled = true
		populateWeaponSelector()
		updateMainUI()

		-- Enable Blur
		if state.blurEffect then 
			state.blurEffect.Enabled = true
			TweenService:Create(state.blurEffect, TweenInfo.new(0.5), {Size=20}):Play()
		end

		-- Animation: CRT Turn On
		local frame = ui.screen.Monitor.Screen
		frame.Size = UDim2.new(0.95, 0, 0.01, 0)
		frame:TweenSize(UDim2.new(0.95, 0, 0.95, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Elastic, 0.5, true)
	else
		if ui.screen then 
			ui.screen.Enabled = false 
			-- Disable Blur
			if state.blurEffect then 
				TweenService:Create(state.blurEffect, TweenInfo.new(0.5), {Size=0}):Play()
				task.delay(0.5, function() state.blurEffect.Enabled = false end)
			end
		end
	end
end

initializeGachaData = function()
	CoinsUpdateEvent.OnClientEvent:Connect(function(newAmount)
		state.coins = newAmount
		if ui.screen and ui.screen.Enabled then updateMainUI() end
	end)

	task.spawn(function()
		local config = GetGachaConfig:InvokeServer()
		if config then state.gachaConfig.rarities = config end

		local status = GetGachaStatus:InvokeServer()
		if status then
			state.coins = status.Coins or 0
			state.pityCount = status.PityCount or 0
			state.pityThreshold = status.PityThreshold or 50
			local lastClaim = status.LastFreeGachaClaimUTC or 0
			state.freeRollAvailable = (os.time() - lastClaim) > 86400
		end
	end)
end

initializeGachaData()

local function setupPrompt()
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment", 10)
	if not lobbyEnv then return end

	local shopPart = lobbyEnv:WaitForChild("Gacha", 10)
	if shopPart then
		local prompt = shopPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function()
				if ui.screen and ui.screen.Enabled then
					toggleGachaUI(false)
				else
					toggleGachaUI(true)
				end
			end)
		end
	end
end

task.spawn(setupPrompt)

-- print removed
return {}
