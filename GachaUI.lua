-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby
-- Theme: Survivor's Journal (Post-Apocalyptic/Sketchbook)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ================== MODULE & EVENT REFERENCES ==================
local AudioManager = require(ReplicatedStorage.ModuleScript:WaitForChild("AudioManager"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
local ModelPreviewModule = require(ReplicatedStorage.ModuleScript:WaitForChild("ModelPreviewModule"))
local ProximityUIHandler = require(ReplicatedStorage.ModuleScript:WaitForChild("ProximityUIHandler"))

local GachaRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaRollEvent")
local GachaMultiRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaMultiRollEvent")
local GachaFreeRollEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GachaFreeRollEvent")
local GetGachaConfig = ReplicatedStorage.RemoteFunctions:WaitForChild("GetGachaConfig")
local GetGachaStatus = ReplicatedStorage.RemoteFunctions:WaitForChild("GetGachaStatus")
local CoinsUpdateEvent = ReplicatedStorage.RemoteEvents:WaitForChild("CoinsUpdateEvent")

-- ================== THEME CONSTANTS ==================
local THEME = {
	Colors = {
		Paper = Color3.fromRGB(245, 240, 225),     -- Aged paper
		PaperDark = Color3.fromRGB(225, 215, 195), -- Fold/Shadow
		Ink = Color3.fromRGB(40, 40, 45),          -- Black ink
		Pencil = Color3.fromRGB(80, 80, 90),       -- Graphite
		Blood = Color3.fromRGB(160, 20, 20),       -- Red marker/Blood
		Highlighter = Color3.fromRGB(255, 220, 100), -- Yellow highlight
		Tape = Color3.fromRGB(220, 220, 200),      -- Masking tape
		TapeBorder = Color3.fromRGB(200, 200, 180),
		PolaroidBg = Color3.fromRGB(250, 250, 250),
		PolaroidDark = Color3.fromRGB(20, 20, 20),
	},
	Fonts = {
		Handwritten = Enum.Font.AmaticSC,      -- Main text (if available) or IndieFlower
		Typewriter = Enum.Font.SpecialElite,   -- Stats/Data (if available) or Code
		Stamp = Enum.Font.Bangers,             -- Buttons
		Body = Enum.Font.GothamMedium,         -- Fallback
	}
}

-- Fallback font check (just in case)
local function getFont(type)
	return THEME.Fonts[type] or Enum.Font.SourceSans
end

-- ================== STATE MANAGEMENT ==================
local state = {
	coins = 0,
	currentWeaponId = nil,
	currentSkinId = nil,
	freeRollAvailable = false,
	isRolling = false,
	pityCount = 0,
	pityThreshold = 50, -- Default fallback
	gachaConfig = {
		costs = { roll1 = 1500, roll10 = 15000 },
		rarities = { legendary = 5, booster = 10, common = 85 },
		prizes = {
			booster = {
				{ name = 'Self Revive', type = 'Booster' },
				{ name = 'Starter Points', type = 'Booster' }
			},
			common = {
				{ name = '10 BloodCoins', type = 'Coins', value = 10 },
				{ name = '25 BloodCoins', type = 'Coins', value = 25 },
				{ name = '50 BloodCoins', type = 'Coins', value = 50 }
			}
		}
	}
}

-- ================== UI ELEMENT REFERENCES ==================
local ui = {}
local proximityHandler -- Forward declaration
local createUI, toggleGachaUI, updateMainUI, populateWeaponSelector

-- ================== HELPER FUNCTIONS ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

-- Helper to add "Hand-drawn" borders
local function addHandDrawnBorder(parent, color, thickness)
	local stroke = create("UIStroke", {
		Parent = parent,
		Color = color or THEME.Colors.Ink,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0.2
	})
	return stroke
end

-- Helper to make something look like it's taped on
local function addTape(parent, positionUDim2, rotation)
	local tape = create("Frame", {
		Name = "Tape",
		Parent = parent,
		Size = UDim2.new(0, 40, 0, 15),
		Position = positionUDim2,
		BackgroundColor3 = THEME.Colors.Tape,
		BorderSizePixel = 0,
		Rotation = rotation or math.random(-20, 20),
		ZIndex = (parent.ZIndex or 1) + 1
	})
	create("UICorner", {Parent = tape, CornerRadius = UDim.new(0, 2)})
	-- Add slightly darker edges for depth
	local stroke = create("UIStroke", {Parent = tape, Color = THEME.Colors.TapeBorder, Thickness = 1})
	return tape
end

local function playSound(soundName)
	-- Fallback to simple sounds if AudioManager is empty or not set up
	-- In a real scenario, use AudioManager.Sounds[soundName]
	local soundId = "rbxassetid://4612375233" -- Generic paper/click sound
	if soundName == "Scratch" then soundId = "rbxassetid://452267918" end
	if soundName == "Stamp" then soundId = "rbxassetid://4801968213" end -- Thud

	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = 0.5
	s.Parent = ui.gachaScreen or player.PlayerGui
	s.PlayOnRemove = true
	s:Destroy()
end

local function showButtonFeedback(button, message)
	local originalText = button.Text
	local originalColor = button.TextColor3

	button.Text = "X " .. message .. " X"
	button.TextColor3 = THEME.Colors.Blood
	playSound("Scratch")

	task.wait(1)

	if button and button.Parent then
		button.Text = originalText
		button.TextColor3 = originalColor
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
		showButtonFeedback(button, "NOT ENOUGH SCRAP!")
		return
	end

	state.isRolling = true
	if not isFree then
		state.coins = state.coins - cost
	else
		state.freeRollAvailable = false
	end
	updateMainUI()

	playSound("Stamp")
	remoteEvent:FireServer(state.currentWeaponId)
end

-- ================== VISUAL & ANIMATION LOGIC ==================

local function openModal(modal)
	if modal then 
		modal.Visible = true 
		modal.Size = UDim2.new(0,0,0,0)
		modal:TweenSize(UDim2.new(1,0,1,0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
	end
end

local function closeModal(modal)
	if modal then modal.Visible = false end
end

local function highlightSelectedWeapon(selectedButton)
	if not ui.weaponList then return end
	for _, child in ipairs(ui.weaponList:GetChildren()) do
		if child:IsA("TextButton") then
			-- Reset style
			child.TextColor3 = THEME.Colors.Pencil
			child.Font = getFont("Handwritten")
			local circle = child:FindFirstChild("SelectionCircle")
			if circle then circle.Visible = false end
		end
	end
	if selectedButton then
		selectedButton.TextColor3 = THEME.Colors.Ink
		selectedButton.Font = Enum.Font.GothamBold -- Emphasize
		local circle = selectedButton:FindFirstChild("SelectionCircle")
		if circle then 
			circle.Visible = true 
			circle.Rotation = math.random(0, 360) -- Random scribble rotation
		end
	end
end

updateMainUI = function()
	if not state.currentWeaponId or not ui.gachaScreen then return end

	local weaponData = WeaponModule.Weapons[state.currentWeaponId]
	if not weaponData then return end

	-- Update Text
	ui.crateName.Text = (weaponData.Name or "Unknown") .. " Crate"
	-- Randomly rotate the crate name slightly to look handwritten
	ui.crateName.Rotation = math.random(-2, 2)

	ui.statsLabel.Text = string.format("DMG: %s\nAMMO: %s/%s\nRATE: %s", 
		weaponData.Damage or "?", 
		weaponData.MaxAmmo or "?", 
		weaponData.ReserveAmmo or "?",
		weaponData.FireRate or "?"
	)

	-- Update Viewport
	if ui.viewport then
		ui.viewport:ClearAllChildren()
		-- Add default skin preview
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

	ui.rollButton1.Text = "SCAVENGE (x1)\nCost: " .. cost1
	ui.rollButton10.Text = "HOARD (x10)\nCost: " .. cost10

	if state.freeRollAvailable and not state.isRolling then
		ui.freeRollButton.Text = "LUCKY FIND\n(Free Roll)"
		ui.freeRollButton.BackgroundColor3 = THEME.Colors.Highlighter
		ui.freeRollButton.TextColor3 = THEME.Colors.Ink
	else
		ui.freeRollButton.Text = "NOTHING LEFT\n(Cooldown)"
		ui.freeRollButton.BackgroundColor3 = THEME.Colors.PaperDark
		ui.freeRollButton.TextColor3 = Color3.fromRGB(150,150,150)
	end

	-- Update Coins Display
	ui.coinsLabel.Text = "SCRAP: " .. state.coins

	-- Update Pity Display
	local pityRemaining = math.max(0, state.pityThreshold - state.pityCount)
	if pityRemaining <= 5 then
		ui.pityLabel.Text = "FEELING LUCKY... (" .. pityRemaining .. " LEFT)"
		ui.pityLabel.TextColor3 = THEME.Colors.Highlighter
	else
		-- Simulate tally marks text
		ui.pityLabel.Text = "BAD LUCK STREAK: " .. state.pityCount
		ui.pityLabel.TextColor3 = THEME.Colors.Pencil
	end
end

populateWeaponSelector = function()
	if not ui.weaponList then return end
	ui.weaponList:ClearAllChildren()
	create("UIListLayout", { Parent = ui.weaponList, SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0, 5) })
	create("UIPadding", { Parent = ui.weaponList, PaddingLeft=UDim.new(0,10)})

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
			Size = UDim2.new(1, 0, 0, 35), 
			Text = "- " .. weapon.name, 
			Font = getFont("Handwritten"), 
			TextColor3 = THEME.Colors.Pencil, 
			TextXAlignment = Enum.TextXAlignment.Left, 
			BackgroundTransparency = 1,
			TextSize = 24
		})

		-- Selection Circle (Hidden by default)
		local circle = create("ImageLabel", {
			Name = "SelectionCircle",
			Parent = btn,
			Size = UDim2.new(0.8, 0, 1.2, 0),
			Position = UDim2.new(0.1, 0, -0.1, 0),
			BackgroundTransparency = 1,
			Image = "rbxassetid://12558557348", -- Generic sketchy circle asset ID (Placeholder logic)
			-- Since I can't guarantee asset IDs, I'll use a UIStroke on a transparent frame with rounded corners
			Visible = false
		})
		-- Fallback procedural circle
		local strokeFrame = create("Frame", {
			Parent = btn, Name = "SelectionCircle",
			Size = UDim2.new(0.9, 0, 1, 0), Position = UDim2.new(0.05, 0, 0, 0),
			BackgroundTransparency = 1, Visible = false
		})
		create("UICorner", {Parent=strokeFrame, CornerRadius=UDim.new(1,0)})
		create("UIStroke", {Parent=strokeFrame, Color=THEME.Colors.Blood, Thickness=2, Transparency=0.3})


		btn.MouseButton1Click:Connect(function()
			state.currentWeaponId = weapon.name
			highlightSelectedWeapon(btn)
			updateMainUI()
			playSound("Scratch")
		end)

		if state.currentWeaponId == weapon.name then
			highlightSelectedWeapon(btn)
		end
	end
end

-- Animation for result
local function showRollAnimation(onComplete)
	openModal(ui.rollAnimationOverlay)

	-- Simple "Shuffling Pages" animation
	local textLabel = ui.rollAnimationOverlay:FindFirstChild("StatusText")
	local texts = {"SEARCHING...", "RUMMAGING...", "FOUND SOMETHING...", "IS IT GOOD?", "CHECKING..."}

	for i = 1, 10 do
		textLabel.Text = texts[(i % #texts) + 1]
		textLabel.Rotation = math.random(-5, 5)
		task.wait(0.15)
	end

	closeModal(ui.rollAnimationOverlay)
	if onComplete then onComplete() end
end

local function showResultModal(prize)
	if not prize then 
		state.isRolling = false
		updateMainUI()
		return 
	end

	ui.resultTitle.Text = "YOU FOUND:"
	ui.resultItemName.Text = prize.SkinName or prize.Name or "Supplies"

	local rarityText = "COMMON"
	local color = THEME.Colors.Pencil

	if prize.Type == "Skin" then
		rarityText = "LEGENDARY!"
		color = THEME.Colors.Blood
	elseif prize.Type == "Booster" then
		rarityText = "RARE FIND"
		color = Color3.fromRGB(0, 100, 200)
	else
		ui.resultItemName.Text = (prize.Amount or 0) .. " Scrap"
	end

	ui.resultRarity.Text = rarityText
	ui.resultRarity.TextColor3 = color
	ui.resultItemName.TextColor3 = color

	-- Stamp Effect
	ui.resultStamp.Rotation = math.random(-10, 10)
	ui.resultStamp.Visible = true
	ui.resultStamp.Size = UDim2.new(2,0,2,0)
	ui.resultStamp.Transparency = 1

	openModal(ui.resultModal)

	-- Stamp Animation
	local tween = TweenService:Create(ui.resultStamp, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.6,0,0.3,0), Transparency=0})
	tween:Play()
	playSound("Stamp")

	state.isRolling = false
	updateMainUI()
end

local function showMultiResultModal(prizes)
	-- Populate grid
	ui.multiResultGrid:ClearAllChildren()
	create("UIGridLayout", {Parent=ui.multiResultGrid, CellSize=UDim2.new(0,120,0,120), CellPadding=UDim2.new(0,10,0,10)})

	for _, prize in ipairs(prizes or {}) do
		local frame = create("Frame", {Parent=ui.multiResultGrid, BackgroundColor3=THEME.Colors.Paper, BorderSizePixel=0})
		addHandDrawnBorder(frame)
		addTape(frame, UDim2.new(0.3,0,-0.1,0))

		local name = prize.SkinName or prize.Name or ((prize.Amount or 0).." Scrap")
		local color = THEME.Colors.Ink
		if prize.Type == "Skin" then color = THEME.Colors.Blood end

		create("TextLabel", {
			Parent=frame, Size=UDim2.new(1,0,1,0), 
			Text=name, TextWrapped=true, Font=getFont("Handwritten"), 
			TextColor3=color, BackgroundTransparency=1, TextSize=20
		})
	end

	openModal(ui.multiResultModal)
	state.isRolling = false
	updateMainUI()
end

local function setupEventListeners()
	ui.closeButton.MouseButton1Click:Connect(function() toggleGachaUI(false) end)
	ui.resultOkButton.MouseButton1Click:Connect(function() closeModal(ui.resultModal); updateMainUI() end)
	ui.multiResultOkButton.MouseButton1Click:Connect(function() closeModal(ui.multiResultModal); updateMainUI() end)

	ui.rollButton1.MouseButton1Click:Connect(function() handleRoll("single") end)
	ui.rollButton10.MouseButton1Click:Connect(function() handleRoll("multi") end)
	ui.freeRollButton.MouseButton1Click:Connect(function() handleRoll("free") end)

	GachaRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)
	GachaMultiRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showMultiResultModal(result.Prizes) end) end)
	GachaFreeRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)
end

-- ================== UI CREATION ==================

createUI = function()
	local oldGui = player.PlayerGui:FindFirstChild("GachaSkinGUI")
	if oldGui then oldGui:Destroy() end

	ui.gachaScreen = create("ScreenGui", { Name = "GachaSkinGUI", Parent = player:WaitForChild("PlayerGui"), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true })

	-- Dark overlay behind the journal
	create("Frame", { Name = "Overlay", Parent = ui.gachaScreen, Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.6 })

	-- Main Container: The Open Journal
	ui.mainContainer = create("Frame", {
		Name = "JournalBook",
		Parent = ui.gachaScreen,
		Size = UDim2.new(0.85, 0, 0.85, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = THEME.Colors.Paper,
		BorderSizePixel = 0
	})
	-- Add book cover/shadow effect behind
	local shadow = create("Frame", {
		Name = "BookShadow", Parent = ui.mainContainer,
		Size = UDim2.new(1.02, 0, 1.05, 0), Position = UDim2.new(-0.01, 0, -0.025, 0),
		BackgroundColor3 = Color3.fromRGB(40, 30, 20), ZIndex = -1
	})
	create("UICorner", {Parent=shadow, CornerRadius=UDim.new(0, 12)})
	create("UICorner", {Parent=ui.mainContainer, CornerRadius=UDim.new(0, 8)})

	-- Center Fold (Spine)
	create("Frame", {
		Name = "Spine", Parent = ui.mainContainer,
		Size = UDim2.new(0.04, 0, 1, 0), Position = UDim2.new(0.48, 0, 0, 0),
		BackgroundColor3 = THEME.Colors.PaperDark, BorderSizePixel = 0, ZIndex = 2
	})
	create("Frame", { -- Binding thread
		Name = "Binding", Parent = ui.mainContainer,
		Size = UDim2.new(0.005, 0, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0, ZIndex = 3
	})

	-- Close Button (Red "X" doodle on top right)
	ui.closeButton = create("TextButton", {
		Name = "CloseButton", Parent = ui.mainContainer,
		Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -20, 0, 20), AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1, Text = "X", Font = getFont("Stamp"),
		TextColor3 = THEME.Colors.Blood, TextSize = 40, Rotation = 5
	})

	-- LEFT PAGE: The Manifest (Weapon List)
	local leftPage = create("Frame", {
		Name = "LeftPage", Parent = ui.mainContainer,
		Size = UDim2.new(0.48, 0, 0.9, 0), Position = UDim2.new(0, 0, 0.05, 0),
		BackgroundTransparency = 1
	})

	create("TextLabel", { -- Header
		Parent = leftPage, Size = UDim2.new(1, 0, 0.15, 0),
		Text = "SIGHTED CRATES", Font = getFont("Stamp"),
		TextColor3 = THEME.Colors.Ink, TextSize = 36, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center
	})
	create("Frame", { -- Divider Line
		Parent = leftPage, Size = UDim2.new(0.8, 0, 0, 2), Position = UDim2.new(0.1, 0, 0.15, 0),
		BackgroundColor3 = THEME.Colors.Ink, BorderSizePixel = 0
	})

	ui.weaponList = create("ScrollingFrame", {
		Name = "WeaponList", Parent = leftPage,
		Size = UDim2.new(0.9, 0, 0.75, 0), Position = UDim2.new(0.05, 0, 0.2, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageColor3 = THEME.Colors.Ink
	})

	-- Coin Display (Bottom Left Scribble)
	ui.coinsLabel = create("TextLabel", {
		Parent = leftPage, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.9, 0),
		Text = "SCRAP: 0", Font = getFont("Typewriter"),
		TextColor3 = THEME.Colors.Pencil, TextSize = 20, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- RIGHT PAGE: The Inspection (Preview & Roll)
	local rightPage = create("Frame", {
		Name = "RightPage", Parent = ui.mainContainer,
		Size = UDim2.new(0.48, 0, 0.9, 0), Position = UDim2.new(0.52, 0, 0.05, 0),
		BackgroundTransparency = 1
	})

	-- Polaroid Frame for Viewport
	local polaroid = create("Frame", {
		Name = "Polaroid", Parent = rightPage,
		Size = UDim2.new(0.8, 0, 0.45, 0), Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = THEME.Colors.PolaroidBg,
		Rotation = -3
	})
	create("UICorner", {Parent=polaroid, CornerRadius=UDim.new(0, 2)})
	-- Add Tape
	addTape(polaroid, UDim2.new(0.4, 0, -0.05, 0))

	-- The Viewport (Dark square inside polaroid)
	ui.viewport = create("ViewportFrame", {
		Name = "Viewport", Parent = polaroid,
		Size = UDim2.new(0.9, 0, 0.75, 0), Position = UDim2.new(0.05, 0, 0.05, 0),
		BackgroundColor3 = THEME.Colors.PolaroidDark
	})

	ui.crateName = create("TextLabel", { -- Text written on polaroid bottom
		Parent = polaroid, Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.new(0, 0, 0.8, 0),
		Text = "Weapon Name", Font = getFont("Handwritten"),
		TextColor3 = THEME.Colors.Ink, TextSize = 24, BackgroundTransparency = 1
	})

	-- Stats Area (Scribbled notes)
	ui.statsLabel = create("TextLabel", {
		Parent = rightPage, Size = UDim2.new(0.9, 0, 0.2, 0), Position = UDim2.new(0.05, 0, 0.5, 0),
		Text = "Stats...", Font = getFont("Typewriter"),
		TextColor3 = THEME.Colors.Pencil, TextSize = 18, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top
	})

	-- Pity Tracker (Tally Marks)
	ui.pityLabel = create("TextLabel", {
		Parent = rightPage, Size = UDim2.new(0.9, 0, 0.1, 0), Position = UDim2.new(0.05, 0, 0.65, 0),
		Text = "Days without luck: 0", Font = getFont("Handwritten"),
		TextColor3 = THEME.Colors.Blood, TextSize = 22, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	-- Buttons (Stamps/Scraps)
	ui.rollButton1 = create("TextButton", {
		Name = "Roll1", Parent = rightPage,
		Size = UDim2.new(0.4, 0, 0.15, 0), Position = UDim2.new(0.05, 0, 0.75, 0),
		BackgroundColor3 = THEME.Colors.Paper, TextColor3 = THEME.Colors.Ink,
		Font = getFont("Stamp"), TextSize = 18
	})
	addHandDrawnBorder(ui.rollButton1, THEME.Colors.Ink, 3)

	ui.rollButton10 = create("TextButton", {
		Name = "Roll10", Parent = rightPage,
		Size = UDim2.new(0.4, 0, 0.15, 0), Position = UDim2.new(0.55, 0, 0.75, 0),
		BackgroundColor3 = THEME.Colors.Paper, TextColor3 = THEME.Colors.Blood,
		Font = getFont("Stamp"), TextSize = 18
	})
	addHandDrawnBorder(ui.rollButton10, THEME.Colors.Blood, 3)

	ui.freeRollButton = create("TextButton", {
		Name = "FreeRoll", Parent = rightPage,
		Size = UDim2.new(0.5, 0, 0.08, 0), Position = UDim2.new(0.25, 0, 0.92, 0),
		BackgroundColor3 = THEME.Colors.Highlighter, TextColor3 = THEME.Colors.Ink,
		Font = getFont("Handwritten"), TextSize = 20
	})
	addTape(ui.freeRollButton, UDim2.new(-0.1,0,0,0), -45)

	-- === MODALS (Overlays on the book) ===

	-- Roll Animation Overlay (Full screen darken)
	ui.rollAnimationOverlay = create("Frame", {
		Parent = ui.gachaScreen, Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.8,
		Visible = false, ZIndex = 10
	})
	create("TextLabel", {
		Name="StatusText", Parent = ui.rollAnimationOverlay,
		Size = UDim2.new(1,0,0.2,0), Position = UDim2.new(0,0,0.4,0),
		Text = "SEARCHING...", Font = getFont("Stamp"),
		TextColor3 = THEME.Colors.Paper, TextSize = 48, BackgroundTransparency = 1
	})

	-- Single Result Modal (A card placed on top of the book)
	ui.resultModal = create("Frame", {
		Name = "ResultModal", Parent = ui.gachaScreen,
		Size = UDim2.new(0.3, 0, 0.5, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.Paper,
		Visible = false, ZIndex = 20, Rotation = 2
	})
	addHandDrawnBorder(ui.resultModal)

	ui.resultTitle = create("TextLabel", {
		Parent=ui.resultModal, Size=UDim2.new(1,0,0.2,0),
		Text="FOUND:", Font=getFont("Stamp"), TextSize=30,
		BackgroundTransparency=1, TextColor3=THEME.Colors.Ink
	})
	ui.resultRarity = create("TextLabel", {
		Parent=ui.resultModal, Size=UDim2.new(1,0,0.1,0), Position=UDim2.new(0,0,0.2,0),
		Text="COMMON", Font=getFont("Typewriter"), TextSize=20,
		BackgroundTransparency=1, TextColor3=THEME.Colors.Pencil
	})
	ui.resultItemName = create("TextLabel", {
		Parent=ui.resultModal, Size=UDim2.new(1,0,0.2,0), Position=UDim2.new(0,0,0.4,0),
		Text="Item Name", Font=getFont("Handwritten"), TextSize=36,
		BackgroundTransparency=1, TextColor3=THEME.Colors.Ink, TextWrapped=true
	})
	ui.resultStamp = create("TextLabel", { -- "APPROVED" Stamp effect
		Parent=ui.resultModal, Size=UDim2.new(0.6,0,0.3,0), Position=UDim2.new(0.2,0,0.3,0),
		Text="LOOTED", Font=getFont("Stamp"), TextSize=40,
		BackgroundTransparency=1, TextColor3=THEME.Colors.Blood,
		Rotation = -15, Visible = false
	})
	create("UIStroke", {Parent=ui.resultStamp, Color=THEME.Colors.Blood, Thickness=3})

	ui.resultOkButton = create("TextButton", {
		Parent=ui.resultModal, Size=UDim2.new(0.5,0,0.15,0), Position=UDim2.new(0.25,0,0.8,0),
		BackgroundColor3=THEME.Colors.Ink, TextColor3=THEME.Colors.Paper,
		Text="KEEP IT", Font=getFont("Stamp"), TextSize=20
	})

	-- Multi Result Modal (Grid of cards)
	ui.multiResultModal = create("Frame", {
		Name = "MultiResultModal", Parent = ui.gachaScreen,
		Size = UDim2.new(0.6, 0, 0.8, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = THEME.Colors.PaperDark,
		Visible = false, ZIndex = 20
	})
	create("UICorner", {Parent=ui.multiResultModal, CornerRadius=UDim.new(0,12)})
	ui.multiResultGrid = create("ScrollingFrame", {
		Parent=ui.multiResultModal, Size=UDim2.new(0.9,0,0.8,0), Position=UDim2.new(0.05,0,0.05,0),
		BackgroundTransparency=1, BorderSizePixel=0
	})
	ui.multiResultOkButton = create("TextButton", {
		Parent=ui.multiResultModal, Size=UDim2.new(0.3,0,0.1,0), Position=UDim2.new(0.35,0,0.88,0),
		BackgroundColor3=THEME.Colors.Ink, TextColor3=THEME.Colors.Paper,
		Text="TAKE ALL", Font=getFont("Stamp"), TextSize=24
	})

	setupEventListeners()
end


-- ================== INITIALIZATION ==================

toggleGachaUI = function(visible)
	if visible then
		if not ui.gachaScreen then
			createUI()
		end
		ui.gachaScreen.Enabled = true
		populateWeaponSelector()
		updateMainUI()

		-- Intro Animation: Book opening
		ui.mainContainer.Position = UDim2.new(0.5, 0, 1.5, 0) -- Start from bottom
		ui.mainContainer:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
	else
		if ui.gachaScreen and ui.gachaScreen.Enabled then
			ui.gachaScreen.Enabled = false
		end
		if proximityHandler then
			proximityHandler:SetOpen(false)
		end
	end
end

initializeGachaData = function()
	CoinsUpdateEvent.OnClientEvent:Connect(function(newAmount)
		state.coins = newAmount
		if ui.gachaScreen and ui.gachaScreen.Enabled then
			updateMainUI()
		end
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

-- Initialize data
initializeGachaData()

-- Register Proximity Interaction
local ShopFolder = Workspace:WaitForChild("Shop", 10) or Workspace
proximityHandler = ProximityUIHandler.Register({
	name = "GachaShop",
	partName = "GachaShopSkin",
	parent = ShopFolder,
	onToggle = function(isOpen)
		toggleGachaUI(isOpen)
	end
})

print("GachaUI (Journal Theme) Initialized.")
