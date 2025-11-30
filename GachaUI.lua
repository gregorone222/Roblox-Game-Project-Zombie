-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby
-- Reworked based on the new HTML prototype.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

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

-- ================== STATE MANAGEMENT ==================
local state = {
	coins = 0,
	currentWeaponId = nil,
	currentSkinId = nil,
	freeRollAvailable = false,
	isRolling = false,
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

-- Forward declare functions that are called before they are defined
local createUI, toggleGachaUI, updateMainUI, populateWeaponSelector

-- ================== HELPER & CORE LOGIC ==================

local function create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties) do
		inst[prop] = value
	end
	return inst
end

local function formatCoins(amount)
	local s = tostring(math.floor(amount or 0))
	local r = s:reverse()
	local formatted = r:gsub("(...)", "%1,")
	return formatted:reverse():gsub("^(,)", "") .. " ??"
end

local function playSound(soundName, props)
	task.spawn(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. (AudioManager.Sounds[soundName] or "")
		for prop, value in pairs(props or {}) do
			sound[prop] = value
		end
		sound.Parent = ui.gachaScreen
		sound:Play()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end

local function showButtonFeedback(button, message)
	local originalText = button.Text
	local originalColor = button.BackgroundColor3

	button.Text = message
	button.BackgroundColor3 = Color3.fromRGB(220, 38, 38) -- red-600
	playSound("UI/menu_error")

	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true)
	local tween = TweenService:Create(button, tweenInfo, { Position = button.Position + UDim2.fromOffset(10, 0) })
	tween:Play()
	tween.Completed:Wait()

	task.wait(0.8)

	button.Text = originalText
	button.BackgroundColor3 = originalColor
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
		local button = rollType == "single" and ui.rollButton1 or (rollType == "multi" and ui.rollButton10 or ui.freeRollButton)
		showButtonFeedback(button, "Koin Tidak Cukup")
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

-- ================== UI LOGIC & MANAGEMENT ==================

local function openModal(modal)
	if modal then modal.Visible = true end
end

local function closeModal(modal)
	if modal then modal.Visible = false end
end

local function highlightSelectedWeapon(selectedButton)
	if not ui.weaponList then return end
	for _, child in ipairs(ui.weaponList:GetChildren()) do
		if child:IsA("TextButton") then
			local stroke = child:FindFirstChild("Stroke")
			if stroke then
				child.BackgroundColor3 = Color3.fromRGB(51, 65, 85) -- slate-700
				stroke.Color = Color3.fromRGB(71, 85, 105) -- slate-600
			end
		end
	end
	if selectedButton then
		local stroke = selectedButton:FindFirstChild("Stroke")
		if stroke then
			selectedButton.BackgroundColor3 = Color3.fromRGB(8, 145, 178) -- cyan-600
			stroke.Color = Color3.fromRGB(56, 189, 248) -- sky-400
		end
	end
end

local function populatePrizeList()
	if not ui.prizeListGrid then return end
	for _, child in ipairs(ui.prizeListGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end

	local weaponData = WeaponModule.Weapons[state.currentWeaponId]
	if not weaponData then return end

	ui.prizeListTitle.Text = "Daftar Hadiah: " .. (weaponData.Name or "Crate")

	local skins = {}
	for skinName, skinData in pairs(weaponData.Skins or {}) do
		if skinName ~= "Default Skin" then
			table.insert(skins, {name = skinName, data = skinData})
		end
	end

	table.sort(skins, function(a,b) return a.name < b.name end)

	for _, skin in ipairs(skins) do
		local item = create("Frame", { Parent = ui.prizeListGrid, BackgroundColor3 = Color3.fromRGB(51, 65, 85), BorderSizePixel = 0 })
		create("UICorner", {Parent=item, CornerRadius=UDim.new(0,8)})
		create("UIStroke", {Parent=item, Color=Color3.fromRGB(250, 204, 21)})
		create("UIPadding", {Parent=item, PaddingLeft=UDim.new(0,5), PaddingRight=UDim.new(0,5), PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5)})
		create("UIListLayout", {Parent=item, Padding=UDim.new(0,5)})

		local vp = create("ViewportFrame", {Parent=item, Size=UDim2.new(1,0,0.65,0), BackgroundColor3=Color3.fromRGB(15,23,42)})
		create("UICorner", {Parent=vp, CornerRadius=UDim.new(0,6)})

		local preview = ModelPreviewModule.create(vp, weaponData, skin.data)
		ModelPreviewModule.startRotation(preview, 5)

		create("TextLabel", {Parent=item, Size=UDim2.new(1,0,0.15,0), Text=skin.name, Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(250, 204, 21), BackgroundTransparency=1, TextSize=14})
		create("TextLabel", {Parent=item, Size=UDim2.new(1,0,0.1,0), Text="Legendary", Font=Enum.Font.Gotham, TextColor3=Color3.fromRGB(156, 163, 175), BackgroundTransparency=1, TextSize=12})
	end
end

updateMainUI = function()
	if not state.currentWeaponId or not ui.gachaScreen then return end

	local weaponData = WeaponModule.Weapons[state.currentWeaponId]
	if not weaponData then return end

	local firstSkinName = next(weaponData.Skins)
	local firstSkinData = firstSkinName and weaponData.Skins[firstSkinName]

	ui.crateName.Text = (weaponData.Name or "Crate") .. " Crate"
	ui.skinName.Text = firstSkinName or ""

	if ui.viewport then
		for _, child in ipairs(ui.viewport:GetChildren()) do
			if not child:IsA("UICorner") then child:Destroy() end
		end
		if firstSkinData then
			local preview = ModelPreviewModule.create(ui.viewport, weaponData, firstSkinData)
			ModelPreviewModule.startRotation(preview, 5)
		end
	end

	-- ui.coinsLabel.Text = formatCoins(state.coins) -- Disabled as per request

	ui.rollButton1.Interactable = not state.isRolling
	ui.rollButton10.Interactable = not state.isRolling
	ui.freeRollButton.Interactable = not state.isRolling

	ui.rollButton1.BackgroundTransparency = 0
	ui.rollButton10.BackgroundTransparency = 0

	if state.freeRollAvailable and not state.isRolling then
		ui.freeRollButton.Text = "Roll Gratis Harian (Tersedia)"
		ui.freeRollButton.BackgroundColor3 = Color3.fromRGB(22, 163, 74) -- green-600
	else
		ui.freeRollButton.Text = "Roll Gratis (Sudah Diklaim)"
		ui.freeRollButton.BackgroundColor3 = Color3.fromRGB(71, 85, 105) -- slate-600
	end
end

populateWeaponSelector = function()
	if not ui.weaponList then return end
	for _, child in ipairs(ui.weaponList:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
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
		local btn = create("TextButton", { Name = weapon.name, Parent = ui.weaponList, Size = UDim2.new(1, 0, 0, 50), Text = "  " .. weapon.name, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(226, 232, 240), TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Color3.fromRGB(51, 65, 85), BorderSizePixel = 0 })
		create("UICorner", {Parent=btn, CornerRadius=UDim.new(0,8)})
		create("UIStroke", {Name = "Stroke", Parent=btn, Thickness=2, Color=Color3.fromRGB(71, 85, 105)})

		btn.MouseButton1Click:Connect(function()
			state.currentWeaponId = weapon.name
			highlightSelectedWeapon(btn)
			updateMainUI()
		end)

		if state.currentWeaponId == weapon.name then
			highlightSelectedWeapon(btn)
		end
	end
end

local function showRollAnimation(onComplete)
	openModal(ui.rollAnimationModal)

	local weapon = WeaponModule.Weapons[state.currentWeaponId]
	local possiblePrizes = {}
	if weapon and weapon.Skins then
		for skinName, _ in pairs(weapon.Skins) do table.insert(possiblePrizes, {name = skinName, rarity = "Legendary"}) end
	end
	for _, prize in ipairs(state.gachaConfig.prizes.booster) do table.insert(possiblePrizes, {name = prize.name, rarity = "Booster"}) end
	for _, prize in ipairs(state.gachaConfig.prizes.common) do table.insert(possiblePrizes, {name = prize.name, rarity = "Common"}) end

	local start = tick()
	while tick() - start < 2.5 do
		if #possiblePrizes > 0 then
			local randomPrize = possiblePrizes[math.random(#possiblePrizes)]
			ui.reelItemName.Text = randomPrize.name
			if randomPrize.rarity == "Legendary" then ui.reelItemName.TextColor3 = Color3.fromRGB(250, 204, 21)
			elseif randomPrize.rarity == "Booster" then ui.reelItemName.TextColor3 = Color3.fromRGB(96, 165, 250)
			else ui.reelItemName.TextColor3 = Color3.fromRGB(156, 163, 175) end
		end
		task.wait(0.1)
	end

	closeModal(ui.rollAnimationModal)
	if onComplete then onComplete() end
end

local function showResultModal(prize)
	if not prize then return end
	ui.resultTitle.Text = (prize.Rarity or "HADIAH"):upper() .. "!"
	ui.resultItemName.Text = prize.SkinName or prize.Name or ""

	local itemType, titleColor, borderColor

	if prize.Type == "Skin" then
		itemType, titleColor, borderColor = (prize.WeaponName or "") .. " Skin", Color3.fromRGB(250, 204, 21), Color3.fromRGB(250, 204, 21)
	elseif prize.Type == "Booster" then
		itemType, titleColor, borderColor = "Booster", Color3.fromRGB(96, 165, 250), Color3.fromRGB(96, 165, 250)
	else -- Coins
		itemType, titleColor, borderColor = "Mata Uang", Color3.fromRGB(156, 163, 175), Color3.fromRGB(156, 163, 175)
		ui.resultItemName.Text = (prize.Amount or 0) .. " BloodCoins"
	end

	ui.resultTitle.TextColor3 = titleColor
	ui.resultModalStroke.Color = borderColor
	ui.resultItemType.Text = itemType

	state.isRolling = false
	openModal(ui.resultModal)
end

local function showMultiResultModal(prizes)
	if not ui.multiResultGrid then return end
	for _, child in ipairs(ui.multiResultGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then child:Destroy() end
	end

	for _, prize in ipairs(prizes or {}) do
		local item = create("Frame", { Parent = ui.multiResultGrid, BackgroundColor3 = Color3.fromRGB(51, 65, 85), BorderSizePixel = 0 })
		create("UICorner", {Parent=item, CornerRadius=UDim.new(0,8)})
		local stroke = create("UIStroke", {Parent=item, Thickness=2})
		create("UIListLayout", {Parent=item, Padding=UDim.new(0,5), HorizontalAlignment=Enum.HorizontalAlignment.Center})

		create("Frame", {Parent=item, Size=UDim2.new(1,-10,0.5,0), BackgroundColor3=Color3.fromRGB(15,23,42)})

		local nameLabel = create("TextLabel", {Parent=item, Size=UDim2.new(1,-10,0.15,0), Font=Enum.Font.GothamBold, BackgroundTransparency=1, TextSize=14})
		create("TextLabel", {Parent=item, Size=UDim2.new(1,-10,0.1,0), Text=prize.Type or "", Font=Enum.Font.Gotham, TextColor3=Color3.fromRGB(156,163,175), BackgroundTransparency=1, TextSize=12})

		if prize.Type == "Skin" then
			stroke.Color, nameLabel.TextColor3, nameLabel.Text = Color3.fromRGB(250, 204, 21), Color3.fromRGB(250, 204, 21), prize.SkinName or ""
		elseif prize.Type == "Booster" then
			stroke.Color, nameLabel.TextColor3, nameLabel.Text = Color3.fromRGB(96, 165, 250), Color3.fromRGB(96, 165, 250), prize.Name or ""
		else
			stroke.Color, nameLabel.TextColor3, nameLabel.Text = Color3.fromRGB(156, 163, 175), Color3.fromRGB(255, 255, 255), (prize.Amount or 0) .. " Coins"
		end
	end

	state.isRolling = false
	openModal(ui.multiResultModal)
end

local function setupEventListeners()
	ui.closeButton.MouseButton1Click:Connect(function() toggleGachaUI(false) end)
	ui.prizeListButton.MouseButton1Click:Connect(function() populatePrizeList(); openModal(ui.prizeListModal) end)
	ui.closePrizeListButton.MouseButton1Click:Connect(function() closeModal(ui.prizeListModal) end)
	ui.resultOkButton.MouseButton1Click:Connect(function() closeModal(ui.resultModal); updateMainUI() end)
	ui.multiResultOkButton.MouseButton1Click:Connect(function() closeModal(ui.multiResultModal); updateMainUI() end)

	ui.rollButton1.MouseButton1Click:Connect(function() handleRoll("single") end)
	ui.rollButton10.MouseButton1Click:Connect(function() handleRoll("multi") end)
	ui.freeRollButton.MouseButton1Click:Connect(function() handleRoll("free") end)

	local function handleResult()
		-- local status = GetGachaStatus:InvokeServer() -- No longer needed for pity
		-- if status then updatePityUI(status.PityCount) end
	end

	GachaRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize); handleResult() end) end)
	GachaMultiRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showMultiResultModal(result.Prizes); handleResult() end) end)
	GachaFreeRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize); handleResult() end) end)
end

-- ================== UI CREATION ==================

createUI = function()
	local oldGui = player.PlayerGui:FindFirstChild("GachaSkinGUI")
	if oldGui then oldGui:Destroy() end

	ui.gachaScreen = create("ScreenGui", { Name = "GachaSkinGUI", Parent = player:WaitForChild("PlayerGui"), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	ui.background = create("Frame", { Name = "Background", Parent = ui.gachaScreen, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.8, ZIndex = 1 })
	ui.mainContainer = create("Frame", { Name = "MainContainer", Parent = ui.gachaScreen, Size = UDim2.new(0.9, 0, 0.9, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(15, 23, 42), BorderSizePixel = 0, ZIndex = 2 })
	create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = ui.mainContainer })
	create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(51, 65, 85), Parent = ui.mainContainer })
	create("UIAspectRatioConstraint", { AspectRatio = 1.77, Parent = ui.mainContainer })
	ui.header = create("Frame", { Name = "Header", Parent = ui.mainContainer, Size = UDim2.new(1, 0, 0.1, 0), BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel = 0 })
	create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(51, 65, 85), ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ui.header })
	ui.title = create("TextLabel", { Name = "Title", Parent = ui.header, Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Text = "ARSENAL CRATE", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 1 })
	ui.closeButton = create("TextButton", { Name = "CloseButton", Parent = ui.header, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -20, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.fromRGB(220, 38, 38), Text = "X", Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = Color3.fromRGB(255, 255, 255) })
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ui.closeButton })
	ui.mainContent = create("Frame", { Name = "MainContent", Parent = ui.mainContainer, Size = UDim2.new(0.98, 0, 0.88, 0), Position = UDim2.new(0.5, 0, 0.55, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 })
	create("UIListLayout", { Parent = ui.mainContent, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.01, 0) })
	ui.weaponListColumn = create("Frame", { Name = "WeaponListColumn", Parent = ui.mainContent, Size = UDim2.new(0.25, 0, 1, 0), LayoutOrder = 1, BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel = 0 })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.weaponListColumn})
	create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(51, 65, 85), Parent = ui.weaponListColumn })
	create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), Parent = ui.weaponListColumn})
	create("UIListLayout", { Parent = ui.weaponListColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
	ui.weaponListTitle = create("TextLabel", { Name = "WeaponListTitle", Parent = ui.weaponListColumn, Size = UDim2.new(1, 0, 0.08, 0), LayoutOrder = 1, Text = "Pilih Crate", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.fromRGB(226, 232, 240), BackgroundTransparency = 1 })
	ui.weaponList = create("ScrollingFrame", { Name = "WeaponList", Parent = ui.weaponListColumn, Size = UDim2.new(1, 0, 0.92, 0), LayoutOrder = 2, BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6 })
	create("UIListLayout", { Parent = ui.weaponList, SortOrder = Enum.SortOrder.Name, Padding = UDim.new(0, 5) })
	ui.previewColumn = create("Frame", { Name = "PreviewColumn", Parent = ui.mainContent, Size = UDim2.new(0.45, 0, 1, 0), LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel = 0 })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.previewColumn})
	create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(51, 65, 85), Parent = ui.previewColumn })
	create("UIPadding", { PaddingTop = UDim.new(0, 15), PaddingBottom = UDim.new(0, 15), PaddingLeft = UDim.new(0,15), PaddingRight = UDim.new(0,15), Parent = ui.previewColumn})
	ui.crateName = create("TextLabel", { Name = "CrateName", Parent = ui.previewColumn, Size = UDim2.new(1, 0, 0.1, 0), Text = "AK-47 CRATE", Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(34, 211, 238), BackgroundTransparency = 1, TextSize=30 })
	ui.viewport = create("ViewportFrame", { Name = "Viewport", Parent = ui.previewColumn, Size = UDim2.new(1, 0, 0.75, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(15, 23, 42) })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.viewport})
	ui.skinName = create("TextLabel", { Name = "SkinName", Parent = ui.previewColumn, Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.new(0.5, 0, 0.95, 0), AnchorPoint = Vector2.new(0.5, 0.5), Text = "Magma Wyrm", Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(203, 213, 225), BackgroundTransparency = 1, TextSize=24 })
	ui.controlsColumn = create("Frame", { Name = "ControlsColumn", Parent = ui.mainContent, Size = UDim2.new(0.28, 0, 1, 0), LayoutOrder = 3, BackgroundTransparency = 1 })
	create("UIListLayout", { Parent = ui.controlsColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
	ui.oddsPanel = create("Frame", { Name = "OddsPanel", Parent = ui.controlsColumn, Size = UDim2.new(1, 0, 0.25, 0), LayoutOrder = 1, BackgroundColor3 = Color3.fromRGB(30, 41, 59) })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.oddsPanel })
	create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(51, 65, 85), Parent = ui.oddsPanel })
	create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), Parent = ui.oddsPanel})
	create("UIListLayout", { Parent = ui.oddsPanel, Padding = UDim.new(0, 2) })
	create("TextLabel", { Parent = ui.oddsPanel, Size = UDim2.new(1,0,0.2,0), Text = "Peluang Hadiah", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(241,245,249), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextSize=18})
	local function createOdd(name, value, color, parent)
		local frame = create("Frame", { Parent = parent, Size = UDim2.new(1,0,0.2,0), BackgroundTransparency=1})
		create("UIListLayout", { Parent = frame, FillDirection=Enum.FillDirection.Horizontal, VerticalAlignment=Enum.VerticalAlignment.Center})
		create("TextLabel", { Parent = frame, Size = UDim2.new(0.7,0,1,0), Text = name, Font=Enum.Font.GothamMedium, TextColor3=color, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextSize=14})
		create("TextLabel", { Parent = frame, Size = UDim2.new(0.3,0,1,0), Text = value, Font=Enum.Font.GothamMedium, TextColor3=color, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Right, TextSize=14})
	end
	createOdd("Legendary Skin", "5.0%", Color3.fromRGB(250, 204, 21), ui.oddsPanel)
	createOdd("Booster", "10.0%", Color3.fromRGB(96, 165, 250), ui.oddsPanel)
	createOdd("Coins (Common)", "85.0%", Color3.fromRGB(156, 163, 175), ui.oddsPanel)
	ui.otherPrizesPanel = create("Frame", { Name = "OtherPrizesPanel", Parent = ui.controlsColumn, Size = UDim2.new(1, 0, 0.2, 0), LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(30, 41, 59) })
	create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ui.otherPrizesPanel })
	create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(51, 65, 85), Parent = ui.otherPrizesPanel })
	create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), Parent = ui.otherPrizesPanel})
	create("UIListLayout", { Parent = ui.otherPrizesPanel, Padding = UDim.new(0, 2) })
	create("TextLabel", { Parent = ui.otherPrizesPanel, Size = UDim2.new(1,0,0.3,0), Text = "Hadiah Lainnya", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(241,245,249), BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextSize=18})
	local function createPrize(text, icon, color, parent)
		local frame = create("Frame", { Parent = parent, Size = UDim2.new(1,0,0.3,0), BackgroundTransparency=1})
		create("UIListLayout", { Parent = frame, FillDirection=Enum.FillDirection.Horizontal, VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,5)})
		create("TextLabel", { Parent = frame, Size = UDim2.new(0,20,0,20), Text = icon, Font=Enum.Font.GothamBold, TextColor3=color, BackgroundColor3=Color3.fromRGB(15,23,42), TextSize=16})
		create("TextLabel", { Parent = frame, Size = UDim2.new(1,-25,1,0), Text = text, Font=Enum.Font.GothamMedium, TextColor3=color, BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left, TextSize=14})
	end
	createPrize("Self Revive Booster", "?", Color3.fromRGB(96, 165, 250), ui.otherPrizesPanel)
	createPrize("10-50 BloodCoins", "??", Color3.fromRGB(156, 163, 175), ui.otherPrizesPanel)
	ui.buttonsPanel = create("Frame", { Name = "ButtonsPanel", Parent = ui.controlsColumn, Size = UDim2.new(1, 0, 0.5, 0), LayoutOrder = 3, BackgroundTransparency = 1 })
	create("UIListLayout", { Parent = ui.buttonsPanel, Padding = UDim.new(0, 8), HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Bottom})
	local function createButton(name, text, color, textColor, order, size, textSize)
		local btn = create("TextButton", { Name = name, Parent = ui.buttonsPanel, Size = size, LayoutOrder = order, BackgroundColor3 = color, Text = text, Font = Enum.Font.GothamBold, TextColor3 = textColor, TextSize = textSize, BorderSizePixel = 0 })
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
		return btn
	end
	ui.rollButton1 = createButton("RollButton1", "Roll x1 <font size='12'>(1,500 ??)</font>", Color3.fromRGB(14, 165, 233), Color3.fromRGB(255,255,255), 1, UDim2.new(1,0,0.25,0), 20)
	ui.rollButton1.RichText = true
	ui.rollButton10 = createButton("RollButton10", "Roll 10+1 <font size='12'>(15,000 ??)</font>", Color3.fromRGB(8, 145, 178), Color3.fromRGB(255,255,255), 2, UDim2.new(1,0,0.25,0), 20)
	ui.rollButton10.RichText = true
	ui.freeRollButton = createButton("FreeRollButton", "Roll Gratis Harian (Tersedia)", Color3.fromRGB(22, 163, 74), Color3.fromRGB(255,255,255), 3, UDim2.new(1,0,0.18,0), 16)
	ui.prizeListButton = createButton("PrizeListButton", "Lihat Daftar Hadiah", Color3.fromRGB(51, 65, 85), Color3.fromRGB(203,213,225), 4, UDim2.new(1,0,0.15,0), 14)
	ui.prizeListModal = create("Frame", { Name = "PrizeListModal", Parent = ui.gachaScreen, Size = UDim2.new(0.6, 0, 0.8, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel = 0, Visible = false, ZIndex = 10 })
	create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = ui.prizeListModal })
	create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(51, 65, 85), Parent = ui.prizeListModal })
	local prizeListHeader = create("Frame", { Name = "Header", Parent = ui.prizeListModal, Size = UDim2.new(1, 0, 0.1, 0), BackgroundColor3 = Color3.fromRGB(51, 65, 85) })
	ui.prizeListTitle = create("TextLabel", { Name = "Title", Parent = prizeListHeader, Size = UDim2.new(0.9, 0, 1, 0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), Text="Daftar Hadiah: AK-47 Crate", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(255,255,255), TextSize=22, BackgroundTransparency=1})
	ui.closePrizeListButton = create("TextButton", { Name = "Close", Parent = prizeListHeader, Size = UDim2.new(0, 30, 0, 30), Position=UDim2.new(1,-20,0.5,0), AnchorPoint=Vector2.new(1,0.5), BackgroundColor3=Color3.fromRGB(220,38,38), Text="X", Font=Enum.Font.GothamBold, TextColor3=Color3.fromRGB(255,255,255), TextSize=20})
	create("UICorner", { Parent = ui.closePrizeListButton, CornerRadius = UDim.new(1,0)})
	ui.prizeListGrid = create("ScrollingFrame", { Name = "Grid", Parent = ui.prizeListModal, Size = UDim2.new(0.95, 0, 0.88, 0), Position=UDim2.new(0.5,0,0.55,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=6})
	create("UIGridLayout", { Parent = ui.prizeListGrid, CellSize=UDim2.new(0.23, 0, 0.2, 0), CellPadding=UDim2.new(0.02,0,0.02,0)})
	ui.rollAnimationModal = create("Frame", { Name = "RollAnimationModal", Parent = ui.gachaScreen, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency=0.9, Visible = false, ZIndex = 50})
	ui.reelItemName = create("TextLabel", { Parent = ui.rollAnimationModal, Position=UDim2.new(0.5,0,0.4,0), AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.new(1,0,0.1,0), Font=Enum.Font.GothamBlack, Text="Magma Wyrm", TextColor3=Color3.fromRGB(250, 204, 21), TextSize=40, BackgroundTransparency=1})
	create("TextLabel", { Parent = ui.rollAnimationModal, Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.new(1,0,0.1,0), Font=Enum.Font.GothamBold, Text="??", TextSize=80, BackgroundTransparency=1})
	create("TextLabel", { Parent = ui.rollAnimationModal, Position=UDim2.new(0.5,0,0.6,0), AnchorPoint=Vector2.new(0.5,0.5), Size=UDim2.new(1,0,0.05,0), Font=Enum.Font.Gotham, Text="Rolling...", TextColor3=Color3.fromRGB(156,163,175), TextSize=18, BackgroundTransparency=1})
	ui.resultModal = create("Frame", { Name = "ResultModal", Parent = ui.gachaScreen, Size = UDim2.new(0.3, 0, 0.5, 0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel=0, Visible = false, ZIndex = 40})
	create("UICorner", { Parent = ui.resultModal, CornerRadius = UDim.new(0, 16)})
	ui.resultModalStroke = create("UIStroke", { Parent = ui.resultModal, Thickness = 2, Color = Color3.fromRGB(51, 65, 85)})
	create("UIPadding", { Parent=ui.resultModal, PaddingTop=UDim.new(0,20), PaddingBottom=UDim.new(0,20), PaddingLeft=UDim.new(0,20), PaddingRight=UDim.new(0,20)})
	create("UIListLayout", { Parent = ui.resultModal, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center})
	ui.resultTitle = create("TextLabel", { Parent = ui.resultModal, Size=UDim2.new(1,0,0.1,0), Font=Enum.Font.GothamBlack, Text="LEGENDARY!", TextSize=40, TextColor3=Color3.fromRGB(250, 204, 21), BackgroundTransparency=1})
	ui.resultImage = create("ImageLabel", { Parent = ui.resultModal, Size=UDim2.new(1,0,0.4,0), BackgroundColor3=Color3.fromRGB(15,23,42)})
	create("UICorner", {Parent=ui.resultImage, CornerRadius=UDim.new(0,8)})
	ui.resultItemName = create("TextLabel", { Parent = ui.resultModal, Size=UDim2.new(1,0,0.1,0), Font=Enum.Font.GothamBold, Text="Magma Wyrm", TextSize=28, TextColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=1})
	ui.resultItemType = create("TextLabel", { Parent = ui.resultModal, Size=UDim2.new(1,0,0.05,0), Font=Enum.Font.Gotham, Text="AK-47 Skin", TextSize=18, TextColor3=Color3.fromRGB(156,163,175), BackgroundTransparency=1})
	ui.resultOkButton = createButton("ResultOkButton", "OK", Color3.fromRGB(14, 165, 233), Color3.fromRGB(255,255,255), 5, UDim2.new(0.8,0,0.15,0), 20)
	ui.resultOkButton.Parent = ui.resultModal
	ui.multiResultModal = create("Frame", { Name = "MultiResultModal", Parent = ui.gachaScreen, Size = UDim2.new(0.5, 0, 0.8, 0), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3 = Color3.fromRGB(30, 41, 59), BorderSizePixel=0, Visible = false, ZIndex = 40})
	create("UICorner", { Parent = ui.multiResultModal, CornerRadius = UDim.new(0, 16)})
	create("UIStroke", { Parent = ui.multiResultModal, Thickness = 2, Color = Color3.fromRGB(51, 65, 85)})
	create("UIPadding", { Parent=ui.multiResultModal, PaddingTop=UDim.new(0,20), PaddingBottom=UDim.new(0,20), PaddingLeft=UDim.new(0,20), PaddingRight=UDim.new(0,20)})
	create("UIListLayout", { Parent = ui.multiResultModal, Padding = UDim.new(0, 15), HorizontalAlignment = Enum.HorizontalAlignment.Center})
	create("TextLabel", { Parent = ui.multiResultModal, Size=UDim2.new(1,0,0.08,0), Font=Enum.Font.GothamBlack, Text="Hasil Roll 10+1", TextSize=32, TextColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=1})
	ui.multiResultGrid = create("ScrollingFrame", { Name = "Grid", Parent = ui.multiResultModal, Size = UDim2.new(1, 0, 0.75, 0), BackgroundColor3=Color3.fromRGB(15,23,42), BorderSizePixel=0, ScrollBarThickness=6})
	create("UICorner", {Parent=ui.multiResultGrid, CornerRadius=UDim.new(0,8)})
	create("UIGridLayout", { Parent = ui.multiResultGrid, CellSize=UDim2.new(0,100,0,120), CellPadding=UDim2.new(0,10,0,10)})
	ui.multiResultOkButton = createButton("MultiResultOkButton", "OK", Color3.fromRGB(14, 165, 233), Color3.fromRGB(255,255,255), 3, UDim2.new(0.5,0,0.1,0), 20)
	ui.multiResultOkButton.Parent = ui.multiResultModal

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
	else
		if ui.gachaScreen and ui.gachaScreen.Enabled then
			ui.gachaScreen.Enabled = false
		end

		-- Sync handler state
		if proximityHandler then
			proximityHandler:SetOpen(false)
		end
	end
end

initializeGachaData = function()
	-- No longer need to wait for PlayerData object, as data is fetched from RemoteFunction

	-- Connect to the global coins update event first
	CoinsUpdateEvent.OnClientEvent:Connect(function(newAmount)
		state.coins = newAmount
		if ui.gachaScreen and ui.gachaScreen.Enabled then
			updateMainUI()
		end
	end)

	local config = GetGachaConfig:InvokeServer()
	if config then state.gachaConfig.rarities = config end

	local status = GetGachaStatus:InvokeServer()
	if status then
		state.coins = status.Coins or 0
		local lastClaim = status.LastFreeGachaClaimUTC or 0
		state.freeRollAvailable = (os.time() - lastClaim) > 86400
		-- updatePityUI(status.PityCount) -- Removed
	end
end

-- Initialize data when the script starts
initializeGachaData()

-- Register Proximity Interaction via Module
local ShopFolder = Workspace:WaitForChild("Shop", 10) or Workspace

proximityHandler = ProximityUIHandler.Register({
	name = "GachaShop",
	partName = "GachaShopSkin",
	parent = ShopFolder,
	onToggle = function(isOpen)
		toggleGachaUI(isOpen)
	end
})

print("GachaUI Initialized and ready.")
