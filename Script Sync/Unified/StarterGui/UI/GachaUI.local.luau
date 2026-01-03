-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then 
	return 
end

-- GachaUI.lua (LocalScript)
-- Path: StarterGui/GachaUI.lua
-- Script Place: Lobby
-- Theme: Military Record / Medal Case (Matching APShopUI/MPShopUI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================== EVENT REFERENCES ==================
local GachaRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaRollEvent")
local GachaMultiRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaMultiRollEvent")
local GachaFreeRollEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GachaFreeRollEvent")
local GetGachaConfig = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetGachaConfig")
local GetGachaStatus = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("GetGachaStatus")
local SurvivalCoinsUpdateEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SurvivalCoinsUpdateEvent")

-- ================== REWARD CONFIG ==================
local FieldKitConfig = {
	StarterPoints = { Name = "Starting Funds", Icon = "rbxassetid://115097892301473", Rarity = "Common", Description = "Start with 1,500 bonus Valor" },
	AmmoCache = { Name = "Ammo Stockpile", Icon = "rbxassetid://133597625207661", Rarity = "Uncommon", Description = "Begin with extra ammo reserves" },
	StartingShield = { Name = "Body Armor", Icon = "rbxassetid://118302588106310", Rarity = "Rare", Description = "Start with protective armor" },
	LegionsLegacy = { Name = "Mystery Loadout", Icon = "rbxassetid://117164757148539", Rarity = "Epic", Description = "Random legendary weapon loadout" },
	CommanderBuff = { Name = "Commander's Authority", Icon = "rbxassetid://78698774904955", Rarity = "Legendary", Description = "All team members get stat buff" },
}

-- Gacha Rewards Pool (for display)
local RewardsPool = {
	{ Type = "Coins", Name = "100-500 Credits", Rarity = "Common", Chance = "60%", Desc = "In-game currency for purchases" },
	{ Type = "Coins", Name = "500-1000 Credits", Rarity = "Uncommon", Chance = "20%", Desc = "Bonus currency for your account" },
	{ Type = "FieldKit", Name = "Starting Funds", Key = "StarterPoints", Rarity = "Common", Chance = "8%" },
	{ Type = "FieldKit", Name = "Ammo Stockpile", Key = "AmmoCache", Rarity = "Uncommon", Chance = "5%" },
	{ Type = "FieldKit", Name = "Body Armor", Key = "StartingShield", Rarity = "Rare", Chance = "3%" },
	{ Type = "FieldKit", Name = "Mystery Loadout", Key = "LegionsLegacy", Rarity = "Epic", Chance = "2%" },
	{ Type = "FieldKit", Name = "Commander's Authority", Key = "CommanderBuff", Rarity = "Legendary", Chance = "1%" },
	{ Type = "Skin", Name = "Weapon Skin", Rarity = "Legendary", Chance = "1%", Desc = "Exclusive cosmetic for selected weapon" },
}

-- ================== THEME CONSTANTS ==================
local COLORS = {
	BG_ROOT = Color3.fromRGB(20, 20, 20),
	BG_PANEL = Color3.fromRGB(35, 35, 40),
	BG_HEADER = Color3.fromRGB(45, 45, 50),
	
	TEXT_MAIN = Color3.fromRGB(240, 240, 230),
	TEXT_DIM = Color3.fromRGB(160, 160, 165),
	
	ACCENT_GOLD = Color3.fromRGB(218, 165, 32),
	ACCENT_SUCCESS = Color3.fromRGB(100, 200, 100),
	ACCENT_FAIL = Color3.fromRGB(200, 80, 80),
	
	RARITY_COMMON = Color3.fromRGB(180, 180, 180),
	RARITY_UNCOMMON = Color3.fromRGB(100, 200, 100),
	RARITY_RARE = Color3.fromRGB(100, 150, 255),
	RARITY_EPIC = Color3.fromRGB(200, 80, 255),
	RARITY_LEGENDARY = Color3.fromRGB(255, 215, 0),
}

local FONTS = {
	Header = Enum.Font.SpecialElite,
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code
}

-- ================== STATE ==================
local state = {
	coins = 0,
	freeRollAvailable = false,
	isRolling = false,
	selectedWeapon = nil,
	weaponsList = {},
	gachaConfig = {
		costs = { roll1 = 1500, roll10 = 15000 },
	},
	blurEffect = nil,
	currentTab = "Roll" -- "Roll" or "Rewards"
}

local ui = {}
local createUI, toggleGachaUI, updateMainUI

-- ================== HELPERS ==================

local function create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do
		if k == "BackgroundColor" then
			instance.BackgroundColor3 = v
		else
			instance[k] = v
		end
	end
	return instance
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLORS.TEXT_DIM
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function formatNumber(n)
	return tostring(math.floor(n or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function getRarityColor(rarity)
	if rarity == "Legendary" then return COLORS.RARITY_LEGENDARY end
	if rarity == "Epic" then return COLORS.RARITY_EPIC end
	if rarity == "Rare" then return COLORS.RARITY_RARE end
	if rarity == "Uncommon" then return COLORS.RARITY_UNCOMMON end
	return COLORS.RARITY_COMMON
end

-- ================== ROLL HANDLERS ==================

local function handleRoll(rollType)
	if state.isRolling then return end
	
	local cost = 0
	if rollType == "single" then cost = state.gachaConfig.costs.roll1
	elseif rollType == "multi" then cost = state.gachaConfig.costs.roll10
	elseif rollType == "free" and not state.freeRollAvailable then return
	end
	
	if rollType ~= "free" and state.coins < cost then return end
	
	state.isRolling = true
	updateMainUI()
	
	if ui.overlay then ui.overlay.Visible = true end
	
	if rollType == "single" then
		GachaRollEvent:FireServer(state.selectedWeapon)
	elseif rollType == "multi" then
		GachaMultiRollEvent:FireServer(state.selectedWeapon)
	else
		GachaFreeRollEvent:FireServer(state.selectedWeapon)
	end
end

local function showRollAnimation(callback)
	if ui.overlay then
		local statusText = ui.overlay:FindFirstChild("StatusText")
		if statusText then statusText.Text = "PROCESSING REQUISITION..." end
		task.wait(0.8)
	end
	if callback then callback() end
	if ui.overlay then ui.overlay.Visible = false end
end

-- ================== RESULT DISPLAY ==================

local function showResultModal(prize)
	if not prize then 
		state.isRolling = false
		updateMainUI()
		return 
	end

	local name = prize.SkinName or prize.Name or "Unknown"
	local rarity = "COMMON"
	local color = COLORS.TEXT_MAIN
	local iconAsset = nil

	if prize.Type == "Skin" then
		rarity = "LEGENDARY SKIN"
		color = COLORS.RARITY_LEGENDARY
	elseif prize.Type == "FieldKit" or prize.Type == "Booster" then
		local fieldKitData = FieldKitConfig[prize.Name]
		if fieldKitData then
			name = fieldKitData.Name
			iconAsset = fieldKitData.Icon
			rarity = (fieldKitData.Rarity or "Common"):upper() .. " FIELD KIT"
			color = getRarityColor(fieldKitData.Rarity or "Common")
		end
	else
		name = formatNumber(prize.Amount or 0) .. " CREDITS"
		rarity = "CURRENCY"
		color = COLORS.ACCENT_GOLD
	end

	if ui.resultModal then
		ui.resultModal.Visible = true
		local title = ui.resultModal:FindFirstChild("Title")
		if title then title.Text = "ACQUISITION CONFIRMED" end

		local itemName = ui.resultModal:FindFirstChild("ItemName")
		if itemName then 
			itemName.Text = name:upper()
			itemName.TextColor3 = color
		end

		local rarityLabel = ui.resultModal:FindFirstChild("Rarity")
		if rarityLabel then 
			rarityLabel.Text = rarity
			rarityLabel.TextColor3 = color
		end

		local iconImage = ui.resultModal:FindFirstChild("IconImage")
		if iconImage then
			if iconAsset then
				iconImage.Image = iconAsset
				iconImage.Visible = true
			else
				iconImage.Visible = false
			end
		end
	end

	state.isRolling = false
	updateMainUI()
end

local function showMultiResultModal(prizes)
	if ui.multiGrid then
		for _, c in ipairs(ui.multiGrid:GetChildren()) do 
			if c:IsA("Frame") then c:Destroy() end 
		end

		for _, prize in ipairs(prizes or {}) do
			local name = prize.SkinName or prize.Name or ((prize.Amount or 0).." CR")
			local color = COLORS.TEXT_MAIN
			local iconAsset = nil
			
			if prize.Type == "Skin" then 
				color = COLORS.RARITY_LEGENDARY 
			elseif prize.Type == "FieldKit" or prize.Type == "Booster" then
				local fieldKitData = FieldKitConfig[prize.Name]
				if fieldKitData then
					name = fieldKitData.Name
					color = getRarityColor(fieldKitData.Rarity or "Common")
					iconAsset = fieldKitData.Icon
				end
			elseif prize.Type == "Coins" then
				color = COLORS.ACCENT_GOLD
			end

			local frame = create("Frame", {
				Parent = ui.multiGrid, 
				BackgroundColor3 = COLORS.BG_PANEL, 
				BorderSizePixel = 0
			})
			addCorner(frame, 4)
			addStroke(frame, color, 2)
			
			if iconAsset then
				create("ImageLabel", {
					Parent = frame, Size = UDim2.new(0.8, 0, 0.55, 0), Position = UDim2.new(0.1, 0, 0.05, 0),
					BackgroundTransparency = 1, Image = iconAsset, ScaleType = Enum.ScaleType.Fit
				})
				create("TextLabel", {
					Parent = frame, Size = UDim2.new(1, 0, 0.35, 0), Position = UDim2.new(0, 0, 0.62, 0),
					BackgroundTransparency = 1, Text = name, TextColor3 = color, TextWrapped = true, 
					Font = FONTS.Body, TextSize = 10, TextScaled = true
				})
			else
				create("TextLabel", {
					Parent = frame, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
					Text = name, TextColor3 = color, TextWrapped = true, Font = FONTS.Body, TextSize = 12
				})
			end
		end
	end

	if ui.multiModal then ui.multiModal.Visible = true end
	state.isRolling = false
	updateMainUI()
end

-- ================== UI UPDATE ==================

updateMainUI = function()
	if not ui.screen or not ui.screen.Enabled then return end
	
	if ui.coinsLabel then
		ui.coinsLabel.Text = formatNumber(state.coins)
	end
	
	local function updateButton(btn, cost, available)
		if not btn then return end
		local canAfford = state.coins >= cost
		local enabled = canAfford and not state.isRolling and (available == nil or available)
		
		btn.BackgroundColor3 = enabled and COLORS.ACCENT_GOLD or COLORS.BG_PANEL
		local label = btn:FindFirstChild("Label")
		if label then
			label.TextColor3 = enabled and COLORS.BG_ROOT or COLORS.TEXT_DIM
		end
	end
	
	updateButton(ui.rollButton1, state.gachaConfig.costs.roll1)
	updateButton(ui.rollButton10, state.gachaConfig.costs.roll10)
	
	if ui.freeRollButton then
		local enabled = state.freeRollAvailable and not state.isRolling
		ui.freeRollButton.BackgroundColor3 = enabled and COLORS.ACCENT_SUCCESS or COLORS.BG_PANEL
		local label = ui.freeRollButton:FindFirstChild("Label")
		if label then
			label.TextColor3 = enabled and COLORS.BG_ROOT or COLORS.TEXT_DIM
		end
	end
end

-- ================== POPULATE WEAPON LIST ==================

local function populateWeaponList()
	if not ui.weaponList then return end
	
	-- Clear existing
	for _, c in ipairs(ui.weaponList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	
	-- Get weapons from WeaponModule
	local ModuleScriptReplicated = ReplicatedStorage:FindFirstChild("ModuleScript")
	local WeaponModule = ModuleScriptReplicated and require(ModuleScriptReplicated:WaitForChild("WeaponModule", 5))
	
	state.weaponsList = {}
	if WeaponModule and WeaponModule.Weapons then
		for name, data in pairs(WeaponModule.Weapons) do
			if data.Skins and next(data.Skins) then
				table.insert(state.weaponsList, { name = name, data = data })
			end
		end
	end
	table.sort(state.weaponsList, function(a, b) return a.name < b.name end)
	
	-- Auto-select first if nothing selected
	if not state.selectedWeapon and #state.weaponsList > 0 then
		state.selectedWeapon = state.weaponsList[1].name
	end
	
	for _, weapon in ipairs(state.weaponsList) do
		local isSelected = (state.selectedWeapon == weapon.name)
		
		local btn = create("TextButton", {
			Name = weapon.name,
			Size = UDim2.new(1, -8, 0, 35),
			BackgroundColor3 = isSelected and COLORS.ACCENT_GOLD or COLORS.BG_ROOT,
			Text = "",
			Parent = ui.weaponList
		})
		addCorner(btn, 4)
		if isSelected then addStroke(btn, COLORS.ACCENT_GOLD, 2) end
		
		create("TextLabel", {
			Name = "Label",
			Text = weapon.name:upper(),
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0, 5, 0, 0),
			Font = FONTS.Header,
			TextSize = 11,
			TextColor3 = isSelected and COLORS.BG_ROOT or COLORS.TEXT_MAIN,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Parent = btn
		})
		
		btn.MouseButton1Click:Connect(function()
			state.selectedWeapon = weapon.name
			populateWeaponList()
			-- Update label
			if ui.selectedWeaponLabel then
				ui.selectedWeaponLabel.Text = "Rolling for: " .. weapon.name
			end
		end)
	end
	
	ui.weaponList.CanvasSize = UDim2.new(0, 0, 0, #state.weaponsList * 39)
	
	-- Update label
	if ui.selectedWeaponLabel and state.selectedWeapon then
		ui.selectedWeaponLabel.Text = "Rolling for: " .. state.selectedWeapon
	end
end

-- ================== POPULATE REWARDS LIST ==================

local function populateRewardsList()
	if not ui.rewardsList then return end
	
	for _, c in ipairs(ui.rewardsList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	
	for _, reward in ipairs(RewardsPool) do
		local color = getRarityColor(reward.Rarity)
		
		-- Get description
		local description = reward.Desc or ""
		if reward.Type == "FieldKit" and reward.Key then
			local fkData = FieldKitConfig[reward.Key]
			if fkData then
				description = fkData.Description or ""
			end
		end
		
		local card = create("Frame", {
			Size = UDim2.new(1, -10, 0, 75),
			BackgroundColor3 = COLORS.BG_PANEL,
			Parent = ui.rewardsList
		})
		addCorner(card, 6)
		addStroke(card, color, 1)
		
		-- Icon or type indicator
		local iconFrame = create("Frame", {
			Size = UDim2.new(0, 55, 0, 55),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = COLORS.BG_ROOT,
			Parent = card
		})
		addCorner(iconFrame, 27)
		addStroke(iconFrame, color, 2)
		
		local iconText = "🪙"
		if reward.Type == "FieldKit" then
			local fk = nil
			if reward.Key then fk = FieldKitConfig[reward.Key] end
			if fk and fk.Icon then
				create("ImageLabel", {
					Size = UDim2.new(0.75, 0, 0.75, 0),
					Position = UDim2.new(0.125, 0, 0.125, 0),
					BackgroundTransparency = 1,
					Image = fk.Icon,
					Parent = iconFrame
				})
			else
				iconText = "📦"
				create("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = iconText,
					TextSize = 26,
					Parent = iconFrame
				})
			end
		elseif reward.Type == "Skin" then
			iconText = "🎨"
			create("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = iconText,
				TextSize = 26,
				Parent = iconFrame
			})
		else
			create("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = iconText,
				TextSize = 26,
				Parent = iconFrame
			})
		end
		
		-- Name
		create("TextLabel", {
			Text = reward.Name:upper(),
			Size = UDim2.new(0.5, 0, 0, 20),
			Position = UDim2.new(0, 72, 0, 8),
			Font = FONTS.Header,
			TextSize = 13,
			TextColor3 = COLORS.TEXT_MAIN,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Parent = card
		})
		
		-- Rarity
		create("TextLabel", {
			Text = reward.Rarity:upper(),
			Size = UDim2.new(0.2, 0, 0, 14),
			Position = UDim2.new(0, 72, 0, 28),
			Font = FONTS.Mono,
			TextSize = 10,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Parent = card
		})
		
		-- Description
		if description ~= "" then
			create("TextLabel", {
				Text = description,
				Size = UDim2.new(0.55, 0, 0, 22),
				Position = UDim2.new(0, 72, 0, 45),
				Font = FONTS.Body,
				TextSize = 10,
				TextColor3 = COLORS.TEXT_DIM,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Parent = card
			})
		end
		
		-- Chance
		create("TextLabel", {
			Text = reward.Chance,
			Size = UDim2.new(0.15, -5, 1, 0),
			Position = UDim2.new(0.85, 0, 0, 0),
			Font = FONTS.Mono,
			TextSize = 15,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundTransparency = 1,
			Parent = card
		})
	end
	
	ui.rewardsList.CanvasSize = UDim2.new(0, 0, 0, #RewardsPool * 83)
end

-- ================== TAB SWITCHING ==================

local function switchTab(tabName)
	state.currentTab = tabName
	
	if ui.rollPanel then ui.rollPanel.Visible = (tabName == "Roll") end
	if ui.rewardsPanel then ui.rewardsPanel.Visible = (tabName == "Rewards") end
	
	if ui.tabRoll then
		ui.tabRoll.BackgroundColor3 = (tabName == "Roll") and COLORS.ACCENT_GOLD or COLORS.BG_PANEL
		local lbl = ui.tabRoll:FindFirstChild("Label")
		if lbl then lbl.TextColor3 = (tabName == "Roll") and COLORS.BG_ROOT or COLORS.TEXT_DIM end
	end
	
	if ui.tabRewards then
		ui.tabRewards.BackgroundColor3 = (tabName == "Rewards") and COLORS.ACCENT_GOLD or COLORS.BG_PANEL
		local lbl = ui.tabRewards:FindFirstChild("Label")
		if lbl then lbl.TextColor3 = (tabName == "Rewards") and COLORS.BG_ROOT or COLORS.TEXT_DIM end
	end
	
	if tabName == "Roll" then
		populateWeaponList()
	elseif tabName == "Rewards" then
		populateRewardsList()
	end
end

-- ================== UI CREATION ==================

createUI = function()
	if playerGui:FindFirstChild("GachaUI") then 
		playerGui.GachaUI:Destroy() 
	end

	ui.screen = create("ScreenGui", { 
		Name = "GachaUI", 
		Parent = playerGui, 
		ResetOnSpawn = false, 
		IgnoreGuiInset = false, 
		Enabled = false 
	})

	state.blurEffect = create("BlurEffect", {
		Parent = workspace.CurrentCamera, 
		Size = 15, 
		Enabled = false
	})

	-- Background Dim
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Parent = ui.screen
	})

	-- Main Panel
	local mainPanel = create("Frame", {
		Name = "MainPanel",
		Size = UDim2.new(0, 700, 0, 550),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_ROOT,
		BorderSizePixel = 0,
		Parent = ui.screen
	})
	addCorner(mainPanel, 8)
	addStroke(mainPanel, COLORS.BG_HEADER, 4)

	-- Header
	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundColor3 = COLORS.BG_HEADER,
		Parent = mainPanel
	})
	addCorner(header, 8)
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = COLORS.BG_HEADER,
		BorderSizePixel = 0,
		Parent = header
	})

	create("TextLabel", {
		Text = "🎰 SUPPLY DROP",
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		Font = FONTS.Header,
		TextSize = 22,
		TextColor3 = COLORS.ACCENT_GOLD,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Parent = header
	})

	-- Coins Badge
	local coinsBadge = create("Frame", {
		Size = UDim2.new(0, 150, 0, 35),
		Position = UDim2.new(1, -170, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = COLORS.BG_ROOT,
		Parent = header
	})
	addCorner(coinsBadge, 18)
	addStroke(coinsBadge, COLORS.ACCENT_GOLD, 1)

	ui.coinsLabel = create("TextLabel", {
		Text = "0",
		Size = UDim2.new(1, -35, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		Font = FONTS.Mono,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_MAIN,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Parent = coinsBadge
	})

	create("TextLabel", {
		Text = "🪙",
		Size = UDim2.new(0, 25, 1, 0),
		Position = UDim2.new(1, -25, 0, 0),
		TextSize = 18,
		BackgroundTransparency = 1,
		Parent = coinsBadge
	})

	-- Close Button
	local closeBtn = create("TextButton", {
		Text = "X",
		Size = UDim2.new(0, 32, 0, 32),
		Position = UDim2.new(1, -18, 0, -16),
		BackgroundColor3 = COLORS.ACCENT_FAIL,
		TextColor3 = COLORS.TEXT_MAIN,
		Font = FONTS.Body,
		TextSize = 16,
		Parent = mainPanel
	})
	addCorner(closeBtn, 16)
	addStroke(closeBtn, COLORS.TEXT_MAIN, 2)
	closeBtn.MouseButton1Click:Connect(function() toggleGachaUI(false) end)

	-- Tab Buttons
	local tabContainer = create("Frame", {
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0, 60),
		BackgroundTransparency = 1,
		Parent = mainPanel
	})

	ui.tabRoll = create("TextButton", {
		Size = UDim2.new(0.5, -5, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = COLORS.ACCENT_GOLD,
		Text = "",
		Parent = tabContainer
	})
	addCorner(ui.tabRoll, 6)
	create("TextLabel", {
		Name = "Label",
		Text = "🎲 ROLL",
		Size = UDim2.new(1, 0, 1, 0),
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = COLORS.BG_ROOT,
		BackgroundTransparency = 1,
		Parent = ui.tabRoll
	})
	ui.tabRoll.MouseButton1Click:Connect(function() switchTab("Roll") end)

	ui.tabRewards = create("TextButton", {
		Size = UDim2.new(0.5, -5, 1, 0),
		Position = UDim2.new(0.5, 5, 0, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Text = "",
		Parent = tabContainer
	})
	addCorner(ui.tabRewards, 6)
	create("TextLabel", {
		Name = "Label",
		Text = "📋 REWARDS",
		Size = UDim2.new(1, 0, 1, 0),
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = COLORS.TEXT_DIM,
		BackgroundTransparency = 1,
		Parent = ui.tabRewards
	})
	ui.tabRewards.MouseButton1Click:Connect(function() switchTab("Rewards") end)

	-- Content Area
	local contentArea = create("Frame", {
		Size = UDim2.new(1, -20, 1, -115),
		Position = UDim2.new(0, 10, 0, 105),
		BackgroundTransparency = 1,
		Parent = mainPanel
	})

	-- ========== ROLL PANEL ==========
	ui.rollPanel = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = true,
		Parent = contentArea
	})

	-- Left: Weapon Selector
	local weaponPanel = create("Frame", {
		Size = UDim2.new(0.35, -5, 1, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = ui.rollPanel
	})
	addCorner(weaponPanel, 8)
	addStroke(weaponPanel, COLORS.TEXT_DIM, 1)

	create("TextLabel", {
		Text = "🔫 SELECT WEAPON",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 0, 5),
		Font = FONTS.Header,
		TextSize = 13,
		TextColor3 = COLORS.ACCENT_GOLD,
		BackgroundTransparency = 1,
		Parent = weaponPanel
	})

	ui.weaponList = create("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -45),
		Position = UDim2.new(0, 5, 0, 38),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLORS.ACCENT_GOLD,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = weaponPanel
	})
	create("UIListLayout", { Padding = UDim.new(0, 4), Parent = ui.weaponList })

	-- Right: Roll Area
	local rollArea = create("Frame", {
		Size = UDim2.new(0.65, -5, 1, 0),
		Position = UDim2.new(0.35, 5, 0, 0),
		BackgroundTransparency = 1,
		Parent = ui.rollPanel
	})

	-- Gacha Display
	local gachaDisplay = create("Frame", {
		Size = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Parent = rollArea
	})
	addCorner(gachaDisplay, 8)
	addStroke(gachaDisplay, COLORS.ACCENT_GOLD, 2)

	create("TextLabel", {
		Text = "🎰",
		Size = UDim2.new(1, 0, 0.45, 0),
		Position = UDim2.new(0, 0, 0.05, 0),
		TextSize = 60,
		BackgroundTransparency = 1,
		Parent = gachaDisplay
	})

	ui.selectedWeaponLabel = create("TextLabel", {
		Text = "Select a weapon to roll for skins",
		Size = UDim2.new(1, 0, 0.2, 0),
		Position = UDim2.new(0, 0, 0.5, 0),
		Font = FONTS.Header,
		TextSize = 16,
		TextColor3 = COLORS.ACCENT_GOLD,
		BackgroundTransparency = 1,
		Parent = gachaDisplay
	})

	create("TextLabel", {
		Text = "Win Field Kits, Credits, or Skins!",
		Size = UDim2.new(1, 0, 0.18, 0),
		Position = UDim2.new(0, 0, 0.72, 0),
		Font = FONTS.Body,
		TextSize = 12,
		TextColor3 = COLORS.TEXT_DIM,
		BackgroundTransparency = 1,
		Parent = gachaDisplay
	})

	-- Buttons Area
	local btnArea = create("Frame", {
		Size = UDim2.new(1, 0, 0.45, 0),
		Position = UDim2.new(0, 0, 0.52, 0),
		BackgroundTransparency = 1,
		Parent = rollArea
	})

	local function createRollButton(name, text, cost, posX, iconId)
		local btn = create("TextButton", {
			Name = name,
			Size = UDim2.new(0.3, -10, 0.8, 0),
			Position = UDim2.new(posX, 5, 0.1, 0),
			BackgroundColor3 = COLORS.ACCENT_GOLD,
			Text = "",
			Parent = btnArea
		})
		addCorner(btn, 8)
		addStroke(btn, COLORS.BG_ROOT, 2)

		-- Icon
		if iconId then
			create("ImageLabel", {
				Name = "Icon",
				Image = iconId,
				Size = UDim2.new(0.6, 0, 0.6, 0),
				Position = UDim2.new(0.5, 0, 0.05, 0),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Parent = btn
			})
		end

		create("TextLabel", {
			Name = "Label",
			Text = text,
			Size = UDim2.new(1, 0, 0.25, 0),
			Position = UDim2.new(0, 0, 0.65, 0), -- Moved down
			Font = FONTS.Header,
			TextSize = 14, -- Slightly smaller
			TextColor3 = COLORS.BG_ROOT,
			BackgroundTransparency = 1,
			Parent = btn
		})

		if cost then
			create("TextLabel", {
				Text = formatNumber(cost) .. " 🪙",
				Size = UDim2.new(1, 0, 0.2, 0),
				Position = UDim2.new(0, 0, 0.82, 0),
				Font = FONTS.Mono,
				TextSize = 12,
				TextColor3 = COLORS.BG_HEADER,
				BackgroundTransparency = 1,
				Parent = btn
			})
		else
			create("TextLabel", {
				Text = "Daily Free",
				Size = UDim2.new(1, 0, 0.2, 0),
				Position = UDim2.new(0, 0, 0.82, 0),
				Font = FONTS.Mono,
				TextSize = 11,
				TextColor3 = COLORS.BG_HEADER,
				BackgroundTransparency = 1,
				Parent = btn
			})
		end

		return btn
	end

	ui.rollButton1 = createRollButton("Roll1", "ROLL x1", state.gachaConfig.costs.roll1, 0, "rbxassetid://132531780703465")
	ui.rollButton10 = createRollButton("Roll10", "ROLL x10", state.gachaConfig.costs.roll10, 0.33, "rbxassetid://76836446183603")
	ui.freeRollButton = createRollButton("FreeRoll", "FREE ROLL", nil, 0.66, "rbxassetid://132092333277896")
	ui.freeRollButton.BackgroundColor3 = COLORS.ACCENT_SUCCESS

	ui.rollButton1.MouseButton1Click:Connect(function() handleRoll("single") end)
	ui.rollButton10.MouseButton1Click:Connect(function() handleRoll("multi") end)
	ui.freeRollButton.MouseButton1Click:Connect(function() handleRoll("free") end)

	-- ========== REWARDS PANEL ==========
	ui.rewardsPanel = create("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = contentArea
	})

	create("TextLabel", {
		Text = "POSSIBLE REWARDS",
		Size = UDim2.new(1, 0, 0, 30),
		Font = FONTS.Header,
		TextSize = 18,
		TextColor3 = COLORS.ACCENT_GOLD,
		BackgroundTransparency = 1,
		Parent = ui.rewardsPanel
	})

	ui.rewardsList = create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -40),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundTransparency = 1,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = COLORS.ACCENT_GOLD,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = ui.rewardsPanel
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), Parent = ui.rewardsList })

	-- ========== OVERLAYS ==========
	ui.overlay = create("Frame", {
		Name = "LoadingOverlay",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Visible = false,
		ZIndex = 150,
		Parent = mainPanel
	})

	create("TextLabel", {
		Name = "StatusText",
		Text = "PROCESSING...",
		Size = UDim2.new(1, 0, 0.2, 0),
		Position = UDim2.new(0, 0, 0.4, 0),
		Font = FONTS.Header,
		TextColor3 = COLORS.ACCENT_GOLD,
		TextSize = 28,
		BackgroundTransparency = 1,
		Parent = ui.overlay
	})

	-- Result Modal
	ui.resultModal = create("Frame", {
		Name = "ResultModal",
		Size = UDim2.new(0.6, 0, 0.55, 0),
		Position = UDim2.new(0.2, 0, 0.22, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Visible = false,
		ZIndex = 160,
		Parent = mainPanel
	})
	addCorner(ui.resultModal, 12)
	addStroke(ui.resultModal, COLORS.ACCENT_GOLD, 3)

	create("TextLabel", { Name = "Title", Text = "ACQUISITION CONFIRMED", Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.02, 0), Font = FONTS.Header, TextColor3 = COLORS.ACCENT_GOLD, TextSize = 18, BackgroundTransparency = 1, Parent = ui.resultModal })
	create("ImageLabel", { Name = "IconImage", Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0.5, 0, 0.18, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Image = "", Visible = false, ZIndex = 161, Parent = ui.resultModal })
	create("TextLabel", { Name = "ItemName", Text = "ITEM", Size = UDim2.new(1, 0, 0.12, 0), Position = UDim2.new(0, 0, 0.62, 0), Font = FONTS.Header, TextColor3 = COLORS.TEXT_MAIN, TextSize = 20, BackgroundTransparency = 1, Parent = ui.resultModal })
	create("TextLabel", { Name = "Rarity", Text = "COMMON", Size = UDim2.new(1, 0, 0.1, 0), Position = UDim2.new(0, 0, 0.74, 0), Font = FONTS.Mono, TextColor3 = COLORS.TEXT_DIM, TextSize = 13, BackgroundTransparency = 1, Parent = ui.resultModal })

	local okBtn = create("TextButton", { Name = "OkButton", Text = "", Size = UDim2.new(0.35, 0, 0.1, 0), Position = UDim2.new(0.325, 0, 0.87, 0), BackgroundColor3 = COLORS.ACCENT_GOLD, Parent = ui.resultModal })
	addCorner(okBtn, 6)
	create("TextLabel", { Text = "CONFIRM", Size = UDim2.new(1, 0, 1, 0), Font = FONTS.Header, TextSize = 14, TextColor3 = COLORS.BG_ROOT, BackgroundTransparency = 1, Parent = okBtn })
	okBtn.MouseButton1Click:Connect(function() ui.resultModal.Visible = false end)

	-- Multi Result Modal
	ui.multiModal = create("Frame", {
		Name = "MultiModal",
		Size = UDim2.new(0.9, 0, 0.85, 0),
		Position = UDim2.new(0.05, 0, 0.075, 0),
		BackgroundColor3 = COLORS.BG_PANEL,
		Visible = false,
		ZIndex = 160,
		Parent = mainPanel
	})
	addCorner(ui.multiModal, 12)
	addStroke(ui.multiModal, COLORS.ACCENT_GOLD, 3)

	create("TextLabel", { Text = "BATCH RESULTS", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 5), Font = FONTS.Header, TextSize = 16, TextColor3 = COLORS.ACCENT_GOLD, BackgroundTransparency = 1, Parent = ui.multiModal })

	ui.multiGrid = create("ScrollingFrame", { Size = UDim2.new(0.95, 0, 0.75, 0), Position = UDim2.new(0.025, 0, 0.08, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = COLORS.ACCENT_GOLD, Parent = ui.multiModal })
	create("UIGridLayout", { CellSize = UDim2.new(0, 100, 0, 100), CellPadding = UDim2.new(0, 8, 0, 8), Parent = ui.multiGrid })

	local multiOkBtn = create("TextButton", { Text = "", Size = UDim2.new(0.25, 0, 0.08, 0), Position = UDim2.new(0.375, 0, 0.9, 0), BackgroundColor3 = COLORS.ACCENT_GOLD, Parent = ui.multiModal })
	addCorner(multiOkBtn, 6)
	create("TextLabel", { Text = "ACCEPT ALL", Size = UDim2.new(1, 0, 1, 0), Font = FONTS.Header, TextSize = 14, TextColor3 = COLORS.BG_ROOT, BackgroundTransparency = 1, Parent = multiOkBtn })
	multiOkBtn.MouseButton1Click:Connect(function() ui.multiModal.Visible = false end)

	-- Server Events
	GachaRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)
	GachaMultiRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showMultiResultModal(result.Prizes) end) end)
	GachaFreeRollEvent.OnClientEvent:Connect(function(result) showRollAnimation(function() showResultModal(result.Prize) end) end)
end

-- ================== TOGGLE UI ==================

toggleGachaUI = function(visible)
	if visible then
		if not ui.screen then createUI() end
		ui.screen.Enabled = true
		switchTab("Roll")
		updateMainUI()

		if state.blurEffect then 
			state.blurEffect.Enabled = true
			TweenService:Create(state.blurEffect, TweenInfo.new(0.3), {Size = 15}):Play()
		end

		local mainPanel = ui.screen:FindFirstChild("MainPanel")
		if mainPanel then
			mainPanel.Position = UDim2.new(0.5, 0, 0.6, 0)
			TweenService:Create(mainPanel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
		end
	else
		if ui.screen then 
			ui.screen.Enabled = false 
			if state.blurEffect then 
				TweenService:Create(state.blurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
				task.delay(0.3, function() if state.blurEffect then state.blurEffect.Enabled = false end end)
			end
		end
	end
end

-- ================== INIT ==================

local function initializeGachaData()
	SurvivalCoinsUpdateEvent.OnClientEvent:Connect(function(newAmount)
		state.coins = newAmount
		if ui.screen and ui.screen.Enabled then updateMainUI() end
	end)

	task.spawn(function()
		local config = GetGachaConfig:InvokeServer()
		if config then state.gachaConfig.rarities = config end

		local status = GetGachaStatus:InvokeServer()
		if status then
			state.coins = status.SurvivalCoins or 0
			state.freeRollAvailable = status.FreeRollAvailable or false
		end
	end)
end

initializeGachaData()

local function setupPrompt()
	print("[GachaUI] setupPrompt() starting... Waiting for LobbyEnvironment...")
	
	-- Infinite wait for LobbyEnvironment (it's essential)
	local lobbyEnv = Workspace:WaitForChild("LobbyEnvironment")
	print("[GachaUI] Found LobbyEnvironment")

	-- Retry logic for Gacha machine
	local gachaMachine = nil
	while not gachaMachine do
		gachaMachine = lobbyEnv:FindFirstChild("Gacha")
		if not gachaMachine then
			-- Helper for StreamingEnabled or delayed spawn
			gachaMachine = lobbyEnv:WaitForChild("Gacha", 5)
		end
		
		if not gachaMachine then
			print("[GachaUI] Waiting for Gacha machine...")
			task.wait(1)
		end
	end
	
	print("[GachaUI] Found Gacha machine: " .. gachaMachine:GetFullName())
	
	-- Wait for ProximityPrompt with retry logic
	local prompt = nil
	local retries = 0
	local maxRetries = 100 -- Increased retries
	
	while not prompt and retries < maxRetries do
		prompt = gachaMachine:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt then
			retries = retries + 1
			if retries % 5 == 0 then
				print("[GachaUI] Waiting for ProximityPrompt... attempt " .. retries)
			end
			task.wait(0.5)
		end
	end
	
	if prompt then
		print("[GachaUI] Found ProximityPrompt: " .. prompt:GetFullName())
		prompt.Triggered:Connect(function(playerWhoTriggered)
			print("[GachaUI] Prompt triggered by: " .. playerWhoTriggered.Name)
			if ui.screen and ui.screen.Enabled then
				toggleGachaUI(false)
			else
				toggleGachaUI(true)
			end
		end)
		print("[GachaUI] Connected to prompt successfully!")
	else
		warn("[GachaUI] ProximityPrompt not found after " .. maxRetries .. " retries!")
		-- Debug: list all descendants
		print("[GachaUI] Gacha machine descendants:")
		for _, desc in ipairs(gachaMachine:GetDescendants()) do
			print("  - " .. desc.ClassName .. ": " .. desc.Name)
		end
	end
end

task.spawn(setupPrompt)
print("[GachaUI] Script fully loaded!")

return {}

