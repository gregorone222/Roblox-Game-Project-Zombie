-- LobbyRoomUI.lua (LocalScript)
-- Path: StarterPlayerScripts/LobbyRoomUI.lua
-- Script Place: Lobby
-- Purpose: Create a lobby UI that matches the HTML prototype design

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lobbyRemote = ReplicatedStorage:WaitForChild("LobbyRemote")
local ProximityUIHandler = require(ReplicatedStorage.ModuleScript:WaitForChild("ProximityUIHandler"))

local state = {
	currentScreenContainer = "main-hub",
	currentContentPanel = "solo-options",
	isHost = true,
	isReady = false,
	settings = {
		visibility = "public",
		mode = "Story",
		difficulty = "Easy",
		playerCount = 4
	},
	currentRoom = nil,
	publicRooms = {},
	isUIOpen = false
}

local gui
local screenContainers = {}
local contentPanels = {}
local navButtons = {}

--[[
ALL FUNCTION DEFINITIONS COME FIRST - NO FUNCTION CALLS
]]

-- UI Control Functions
local function showLobbyUI()
	if gui and gui.Parent then
		gui.Enabled = true
		state.isUIOpen = true
		print("LobbyRoomUI opened via proximity prompt")
	end
end

local function hideLobbyUI()
	if gui and gui.Parent then
		gui.Enabled = false
		state.isUIOpen = false
		print("LobbyRoomUI closed")

		-- Sync handler state if registered
		if state.proximityHandler then
			state.proximityHandler:SetOpen(false)
		end
	end
end
local function selectButtonInGroup(groupName, selectedValue)
	for name, button in pairs(gui:GetDescendants()) do
		if button:GetAttribute("data-group") == groupName then
			local value = button:GetAttribute("data-value")
			if value == selectedValue then
				button.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
				button.BackgroundTransparency = 0
			else
				button.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
				button.BackgroundTransparency = 0.3
			end
		end
	end
end

-- UI Section Creation Functions
local function createGameModeSection(parent, groupName, yPos, layoutOrder)
	local gameModeSection = Instance.new("Frame")
	gameModeSection.Name = groupName .. "Section"
	gameModeSection.Size = UDim2.new(1, 0, 0, 100)
	if layoutOrder then
		gameModeSection.LayoutOrder = layoutOrder
	else
		gameModeSection.Position = UDim2.new(0, 0, yPos, 0)
	end
	gameModeSection.BackgroundTransparency = 1
	gameModeSection.Parent = parent

	local gameModeLabel = Instance.new("TextLabel")
	gameModeLabel.Name = "Label"
	gameModeLabel.Size = UDim2.new(1, 0, 0.2, 0)
	gameModeLabel.Position = UDim2.new(0, 0, 0, 0)
	gameModeLabel.BackgroundTransparency = 1
	gameModeLabel.Text = "Mode Game"
	gameModeLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	gameModeLabel.TextScaled = true
	gameModeLabel.Font = Enum.Font.Gotham
	gameModeLabel.TextXAlignment = Enum.TextXAlignment.Center
	gameModeLabel.TextYAlignment = Enum.TextYAlignment.Center
	gameModeLabel.Parent = gameModeSection

	local gameModeButtons = Instance.new("Frame")
	gameModeButtons.Name = "Buttons"
	gameModeButtons.Size = UDim2.new(1, 0, 0.6, 0)
	gameModeButtons.Position = UDim2.new(0, 0, 0.3, 0)
	gameModeButtons.BackgroundTransparency = 1
	gameModeButtons.Parent = gameModeSection

	-- Manual creation for "Story" button
	local storyButton = Instance.new("TextButton")
	storyButton.Name = groupName .. "Story"
	storyButton.Size = UDim2.new(0.45, -8, 1, 0)
	storyButton.Position = UDim2.new(0.025, 0, 0, 0)
	storyButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	storyButton.BackgroundTransparency = 0
	storyButton.BorderSizePixel = 0
	storyButton.Text = "Story"
	storyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	storyButton.TextScaled = true
	storyButton.Font = Enum.Font.GothamBold
	storyButton.AutoButtonColor = false

	local storyPadding = Instance.new("UIPadding")
	storyPadding.PaddingTop = UDim.new(0.20, 0)
	storyPadding.PaddingLeft = UDim.new(0.10, 0)
	storyPadding.PaddingRight = UDim.new(0.10, 0)
	storyPadding.PaddingBottom = UDim.new(0.20, 0)
	storyPadding.Parent = storyButton

	storyButton.Parent = gameModeButtons

	local storyCorner = Instance.new("UICorner")
	storyCorner.CornerRadius = UDim.new(0, 8)
	storyCorner.Parent = storyButton

	storyButton:SetAttribute("data-value", "Story")
	storyButton:SetAttribute("data-group", groupName)

	storyButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Story")
		state.settings.mode = "Story"
	end)

	-- Manual creation for "Endless" button
	local endlessButton = Instance.new("TextButton")
	endlessButton.Name = groupName .. "Endless"
	endlessButton.Size = UDim2.new(0.45, -8, 1, 0)
	endlessButton.Position = UDim2.new(0.525, 0, 0, 0)
	endlessButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	endlessButton.BackgroundTransparency = 0.3
	endlessButton.BorderSizePixel = 0
	endlessButton.Text = "Endless"
	endlessButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	endlessButton.TextScaled = true
	endlessButton.Font = Enum.Font.GothamBold
	endlessButton.AutoButtonColor = false

	local endlessPadding = Instance.new("UIPadding")
	endlessPadding.PaddingTop = UDim.new(0.20, 0)
	endlessPadding.PaddingLeft = UDim.new(0.10, 0)
	endlessPadding.PaddingRight = UDim.new(0.10, 0)
	endlessPadding.PaddingBottom = UDim.new(0.20, 0)
	endlessPadding.Parent = endlessButton

	endlessButton.Parent = gameModeButtons

	local endlessCorner = Instance.new("UICorner")
	endlessCorner.CornerRadius = UDim.new(0, 8)
	endlessCorner.Parent = endlessButton

	endlessButton:SetAttribute("data-value", "Endless")
	endlessButton:SetAttribute("data-group", groupName)

	endlessButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Endless")
		state.settings.mode = "Endless"
	end)
end

local function createPlayerCountSection(parent, groupName, yPos, layoutOrder)
	local playerCountSection = Instance.new("Frame")
	playerCountSection.Name = groupName .. "Section"
	playerCountSection.Size = UDim2.new(1, 0, 0, 150)
	if layoutOrder then
		playerCountSection.LayoutOrder = layoutOrder
	else
		playerCountSection.Position = UDim2.new(0, 0, yPos, 0)
	end
	playerCountSection.BackgroundTransparency = 1
	playerCountSection.Parent = parent

	local playerCountLabel = Instance.new("TextLabel")
	playerCountLabel.Name = "Label"
	playerCountLabel.Size = UDim2.new(1, 0, 0, 20)
	playerCountLabel.Position = UDim2.new(0, 0, 0, 0)
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.Text = "Jumlah Pemain"
	playerCountLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	playerCountLabel.TextScaled = true
	playerCountLabel.Font = Enum.Font.Gotham
	playerCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	playerCountLabel.Parent = playerCountSection

	local playerCountButtons = Instance.new("Frame")
	playerCountButtons.Name = "Buttons"
	playerCountButtons.Size = UDim2.new(1, 0, 0.8, 0)  -- Increased height
	playerCountButtons.Position = UDim2.new(0, 0, 0.133, 0)
	playerCountButtons.BackgroundTransparency = 1
	playerCountButtons.Parent = playerCountSection

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.3, 0)
	gridLayout.StartCorner = Enum.StartCorner.TopLeft
	gridLayout.Parent = playerCountButtons

	-- Manual creation for player count buttons
	-- Button 1
	local button1 = Instance.new("TextButton")
	button1.Name = groupName .. "1"
	button1.Size = UDim2.new(1, 0, 1, 0)
	button1.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button1.BackgroundTransparency = 0.3
	button1.BorderSizePixel = 0
	button1.Text = "1"
	button1.TextColor3 = Color3.fromRGB(255, 255, 255)
	button1.TextScaled = true
	button1.Font = Enum.Font.GothamBold
	button1.AutoButtonColor = false
	button1.LayoutOrder = 1
	local padding1 = Instance.new("UIPadding")
	padding1.PaddingTop = UDim.new(0.10, 0)
	padding1.PaddingLeft = UDim.new(0.05, 0)
	padding1.PaddingRight = UDim.new(0.05, 0)
	padding1.PaddingBottom = UDim.new(0.10, 0)
	padding1.Parent = button1
	button1.Parent = playerCountButtons
	local corner1 = Instance.new("UICorner")
	corner1.CornerRadius = UDim.new(0, 6)
	corner1.Parent = button1
	button1:SetAttribute("data-value", 1)
	button1:SetAttribute("data-group", groupName)
	button1.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "1")
		state.settings.playerCount = 1
	end)

	-- Button 2
	local button2 = Instance.new("TextButton")
	button2.Name = groupName .. "2"
	button2.Size = UDim2.new(1, 0, 1, 0)
	button2.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button2.BackgroundTransparency = 0.3
	button2.BorderSizePixel = 0
	button2.Text = "2"
	button2.TextColor3 = Color3.fromRGB(255, 255, 255)
	button2.TextScaled = true
	button2.Font = Enum.Font.GothamBold
	button2.AutoButtonColor = false
	button2.LayoutOrder = 2
	local padding2 = Instance.new("UIPadding")
	padding2.PaddingTop = UDim.new(0.10, 0)
	padding2.PaddingLeft = UDim.new(0.05, 0)
	padding2.PaddingRight = UDim.new(0.05, 0)
	padding2.PaddingBottom = UDim.new(0.10, 0)
	padding2.Parent = button2
	button2.Parent = playerCountButtons
	local corner2 = Instance.new("UICorner")
	corner2.CornerRadius = UDim.new(0, 6)
	corner2.Parent = button2
	button2:SetAttribute("data-value", 2)
	button2:SetAttribute("data-group", groupName)
	button2.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "2")
		state.settings.playerCount = 2
	end)

	-- Button 3
	local button3 = Instance.new("TextButton")
	button3.Name = groupName .. "3"
	button3.Size = UDim2.new(1, 0, 1, 0)
	button3.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button3.BackgroundTransparency = 0.3
	button3.BorderSizePixel = 0
	button3.Text = "3"
	button3.TextColor3 = Color3.fromRGB(255, 255, 255)
	button3.TextScaled = true
	button3.Font = Enum.Font.GothamBold
	button3.AutoButtonColor = false
	button3.LayoutOrder = 3
	local padding3 = Instance.new("UIPadding")
	padding3.PaddingTop = UDim.new(0.10, 0)
	padding3.PaddingLeft = UDim.new(0.05, 0)
	padding3.PaddingRight = UDim.new(0.05, 0)
	padding3.PaddingBottom = UDim.new(0.10, 0)
	padding3.Parent = button3
	button3.Parent = playerCountButtons
	local corner3 = Instance.new("UICorner")
	corner3.CornerRadius = UDim.new(0, 6)
	corner3.Parent = button3
	button3:SetAttribute("data-value", 3)
	button3:SetAttribute("data-group", groupName)
	button3.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "3")
		state.settings.playerCount = 3
	end)

	-- Button 4
	local button4 = Instance.new("TextButton")
	button4.Name = groupName .. "4"
	button4.Size = UDim2.new(1, 0, 1, 0)
	button4.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	button4.BackgroundTransparency = 0
	button4.BorderSizePixel = 0
	button4.Text = "4"
	button4.TextColor3 = Color3.fromRGB(255, 255, 255)
	button4.TextScaled = true
	button4.Font = Enum.Font.GothamBold
	button4.AutoButtonColor = false
	button4.LayoutOrder = 4
	local padding4 = Instance.new("UIPadding")
	padding4.PaddingTop = UDim.new(0.10, 0)
	padding4.PaddingLeft = UDim.new(0.05, 0)
	padding4.PaddingRight = UDim.new(0.05, 0)
	padding4.PaddingBottom = UDim.new(0.10, 0)
	padding4.Parent = button4
	button4.Parent = playerCountButtons
	local corner4 = Instance.new("UICorner")
	corner4.CornerRadius = UDim.new(0, 6)
	corner4.Parent = button4
	button4:SetAttribute("data-value", 4)
	button4:SetAttribute("data-group", groupName)
	button4.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "4")
		state.settings.playerCount = 4
	end)

	-- Button 5
	local button5 = Instance.new("TextButton")
	button5.Name = groupName .. "5"
	button5.Size = UDim2.new(1, 0, 1, 0)
	button5.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button5.BackgroundTransparency = 0.3
	button5.BorderSizePixel = 0
	button5.Text = "5"
	button5.TextColor3 = Color3.fromRGB(255, 255, 255)
	button5.TextScaled = true
	button5.Font = Enum.Font.GothamBold
	button5.AutoButtonColor = false
	button5.LayoutOrder = 5
	local padding5 = Instance.new("UIPadding")
	padding5.PaddingTop = UDim.new(0.10, 0)
	padding5.PaddingLeft = UDim.new(0.05, 0)
	padding5.PaddingRight = UDim.new(0.05, 0)
	padding5.PaddingBottom = UDim.new(0.10, 0)
	padding5.Parent = button5
	button5.Parent = playerCountButtons
	local corner5 = Instance.new("UICorner")
	corner5.CornerRadius = UDim.new(0, 6)
	corner5.Parent = button5
	button5:SetAttribute("data-value", 5)
	button5:SetAttribute("data-group", groupName)
	button5.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "5")
		state.settings.playerCount = 5
	end)

	-- Button 6
	local button6 = Instance.new("TextButton")
	button6.Name = groupName .. "6"
	button6.Size = UDim2.new(1, 0, 1, 0)
	button6.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button6.BackgroundTransparency = 0.3
	button6.BorderSizePixel = 0
	button6.Text = "6"
	button6.TextColor3 = Color3.fromRGB(255, 255, 255)
	button6.TextScaled = true
	button6.Font = Enum.Font.GothamBold
	button6.AutoButtonColor = false
	button6.LayoutOrder = 6
	local padding6 = Instance.new("UIPadding")
	padding6.PaddingTop = UDim.new(0.10, 0)
	padding6.PaddingLeft = UDim.new(0.05, 0)
	padding6.PaddingRight = UDim.new(0.05, 0)
	padding6.PaddingBottom = UDim.new(0.10, 0)
	padding6.Parent = button6
	button6.Parent = playerCountButtons
	local corner6 = Instance.new("UICorner")
	corner6.CornerRadius = UDim.new(0, 6)
	corner6.Parent = button6
	button6:SetAttribute("data-value", 6)
	button6:SetAttribute("data-group", groupName)
	button6.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "6")
		state.settings.playerCount = 6
	end)

	-- Button 7
	local button7 = Instance.new("TextButton")
	button7.Name = groupName .. "7"
	button7.Size = UDim2.new(1, 0, 1, 0)
	button7.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button7.BackgroundTransparency = 0.3
	button7.BorderSizePixel = 0
	button7.Text = "7"
	button7.TextColor3 = Color3.fromRGB(255, 255, 255)
	button7.TextScaled = true
	button7.Font = Enum.Font.GothamBold
	button7.AutoButtonColor = false
	button7.LayoutOrder = 7
	local padding7 = Instance.new("UIPadding")
	padding7.PaddingTop = UDim.new(0.10, 0)
	padding7.PaddingLeft = UDim.new(0.05, 0)
	padding7.PaddingRight = UDim.new(0.05, 0)
	padding7.PaddingBottom = UDim.new(0.10, 0)
	padding7.Parent = button7
	button7.Parent = playerCountButtons
	local corner7 = Instance.new("UICorner")
	corner7.CornerRadius = UDim.new(0, 6)
	corner7.Parent = button7
	button7:SetAttribute("data-value", 7)
	button7:SetAttribute("data-group", groupName)
	button7.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "7")
		state.settings.playerCount = 7
	end)

	-- Button 8
	local button8 = Instance.new("TextButton")
	button8.Name = groupName .. "8"
	button8.Size = UDim2.new(1, 0, 1, 0)
	button8.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button8.BackgroundTransparency = 0.3
	button8.BorderSizePixel = 0
	button8.Text = "8"
	button8.TextColor3 = Color3.fromRGB(255, 255, 255)
	button8.TextScaled = true
	button8.Font = Enum.Font.GothamBold
	button8.AutoButtonColor = false
	button8.LayoutOrder = 8
	local padding8 = Instance.new("UIPadding")
	padding8.PaddingTop = UDim.new(0.10, 0)
	padding8.PaddingLeft = UDim.new(0.05, 0)
	padding8.PaddingRight = UDim.new(0.05, 0)
	padding8.PaddingBottom = UDim.new(0.10, 0)
	padding8.Parent = button8
	button8.Parent = playerCountButtons
	local corner8 = Instance.new("UICorner")
	corner8.CornerRadius = UDim.new(0, 6)
	corner8.Parent = button8
	button8:SetAttribute("data-value", 8)
	button8:SetAttribute("data-group", groupName)
	button8.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "8")
		state.settings.playerCount = 8
	end)

	-- Button 9
	local button9 = Instance.new("TextButton")
	button9.Name = groupName .. "9"
	button9.Size = UDim2.new(1, 0, 1, 0)
	button9.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	button9.BackgroundTransparency = 0.3
	button9.BorderSizePixel = 0
	button9.Text = "9"
	button9.TextColor3 = Color3.fromRGB(255, 255, 255)
	button9.TextScaled = true
	button9.Font = Enum.Font.GothamBold
	button9.AutoButtonColor = false
	button9.LayoutOrder = 9
	local padding9 = Instance.new("UIPadding")
	padding9.PaddingTop = UDim.new(0.10, 0)
	padding9.PaddingLeft = UDim.new(0.05, 0)
	padding9.PaddingRight = UDim.new(0.05, 0)
	padding9.PaddingBottom = UDim.new(0.10, 0)
	padding9.Parent = button9
	button9.Parent = playerCountButtons
	local corner9 = Instance.new("UICorner")
	corner9.CornerRadius = UDim.new(0, 6)
	corner9.Parent = button9
	button9:SetAttribute("data-value", 9)
	button9:SetAttribute("data-group", groupName)
	button9.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "9")
		state.settings.playerCount = 9
	end)
end

local function createDifficultySection(parent, groupName, yPos, layoutOrder)
	local difficultySection = Instance.new("Frame")
	difficultySection.Name = groupName .. "Section"
	difficultySection.Size = UDim2.new(1, 0, 0, 150)
	if layoutOrder then
		difficultySection.LayoutOrder = layoutOrder
	else
		difficultySection.Position = UDim2.new(0, 0, yPos, 0)
	end
	difficultySection.BackgroundTransparency = 1
	difficultySection.Parent = parent

	local difficultyLabel = Instance.new("TextLabel")
	difficultyLabel.Name = "Label"
	difficultyLabel.Size = UDim2.new(1, 0, 0, 20)
	difficultyLabel.Position = UDim2.new(0, 0, 0, 0)
	difficultyLabel.BackgroundTransparency = 1
	difficultyLabel.Text = "Kesulitan"
	difficultyLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	difficultyLabel.TextScaled = true
	difficultyLabel.Font = Enum.Font.Gotham
	difficultyLabel.TextXAlignment = Enum.TextXAlignment.Center
	difficultyLabel.Parent = difficultySection

	local difficultyButtons = Instance.new("Frame")
	difficultyButtons.Name = "Buttons"
	difficultyButtons.Size = UDim2.new(1, 0, 0.933, 0)  -- Increased height
	difficultyButtons.Position = UDim2.new(0, 0, 0.133, 0)
	difficultyButtons.BackgroundTransparency = 1
	difficultyButtons.Parent = difficultySection

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
	gridLayout.CellSize = UDim2.new(0.3, 0, 0.4, 0)
	gridLayout.Parent = difficultyButtons

	-- Manual creation for difficulty buttons
	local difficulties = {"Easy", "Normal", "Hard", "Expert", "Hell", "Crazy"}

	-- Easy
	local easyButton = Instance.new("TextButton")
	easyButton.Name = groupName .. "Easy"
	easyButton.Size = UDim2.new(1, 0, 1, 0)
	easyButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	easyButton.BackgroundTransparency = 0
	easyButton.BorderSizePixel = 0
	easyButton.Text = "Easy"
	easyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	easyButton.TextScaled = true
	easyButton.Font = Enum.Font.GothamBold
	easyButton.AutoButtonColor = false
	local easyPadding = Instance.new("UIPadding")
	easyPadding.PaddingTop = UDim.new(0.15, 0)
	easyPadding.PaddingLeft = UDim.new(0.15, 0)
	easyPadding.PaddingRight = UDim.new(0.15, 0)
	easyPadding.PaddingBottom = UDim.new(0.15, 0)
	easyPadding.Parent = easyButton
	easyButton.Parent = difficultyButtons
	local easyCorner = Instance.new("UICorner")
	easyCorner.CornerRadius = UDim.new(0, 6)
	easyCorner.Parent = easyButton
	easyButton:SetAttribute("data-value", "Easy")
	easyButton:SetAttribute("data-group", groupName)
	easyButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Easy")
		state.settings.difficulty = "Easy"
	end)

	-- Normal
	local normalButton = Instance.new("TextButton")
	normalButton.Name = groupName .. "Normal"
	normalButton.Size = UDim2.new(1, 0, 1, 0)
	normalButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	normalButton.BackgroundTransparency = 0.3
	normalButton.BorderSizePixel = 0
	normalButton.Text = "Normal"
	normalButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	normalButton.TextScaled = true
	normalButton.Font = Enum.Font.GothamBold
	normalButton.AutoButtonColor = false
	local normalPadding = Instance.new("UIPadding")
	normalPadding.PaddingTop = UDim.new(0.15, 0)
	normalPadding.PaddingLeft = UDim.new(0.15, 0)
	normalPadding.PaddingRight = UDim.new(0.15, 0)
	normalPadding.PaddingBottom = UDim.new(0.15, 0)
	normalPadding.Parent = normalButton
	normalButton.Parent = difficultyButtons
	local normalCorner = Instance.new("UICorner")
	normalCorner.CornerRadius = UDim.new(0, 6)
	normalCorner.Parent = normalButton
	normalButton:SetAttribute("data-value", "Normal")
	normalButton:SetAttribute("data-group", groupName)
	normalButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Normal")
		state.settings.difficulty = "Normal"
	end)

	-- Hard
	local hardButton = Instance.new("TextButton")
	hardButton.Name = groupName .. "Hard"
	hardButton.Size = UDim2.new(1, 0, 1, 0)
	hardButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	hardButton.BackgroundTransparency = 0.3
	hardButton.BorderSizePixel = 0
	hardButton.Text = "Hard"
	hardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	hardButton.TextScaled = true
	hardButton.Font = Enum.Font.GothamBold
	hardButton.AutoButtonColor = false
	local hardPadding = Instance.new("UIPadding")
	hardPadding.PaddingTop = UDim.new(0.15, 0)
	hardPadding.PaddingLeft = UDim.new(0.15, 0)
	hardPadding.PaddingRight = UDim.new(0.15, 0)
	hardPadding.PaddingBottom = UDim.new(0.15, 0)
	hardPadding.Parent = hardButton
	hardButton.Parent = difficultyButtons
	local hardCorner = Instance.new("UICorner")
	hardCorner.CornerRadius = UDim.new(0, 6)
	hardCorner.Parent = hardButton
	hardButton:SetAttribute("data-value", "Hard")
	hardButton:SetAttribute("data-group", groupName)
	hardButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Hard")
		state.settings.difficulty = "Hard"
	end)

	-- Expert
	local expertButton = Instance.new("TextButton")
	expertButton.Name = groupName .. "Expert"
	expertButton.Size = UDim2.new(1, 0, 1, 0)
	expertButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	expertButton.BackgroundTransparency = 0.3
	expertButton.BorderSizePixel = 0
	expertButton.Text = "Expert"
	expertButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	expertButton.TextScaled = true
	expertButton.Font = Enum.Font.GothamBold
	expertButton.AutoButtonColor = false
	local expertPadding = Instance.new("UIPadding")
	expertPadding.PaddingTop = UDim.new(0.15, 0)
	expertPadding.PaddingLeft = UDim.new(0.15, 0)
	expertPadding.PaddingRight = UDim.new(0.15, 0)
	expertPadding.PaddingBottom = UDim.new(0.15, 0)
	expertPadding.Parent = expertButton
	expertButton.Parent = difficultyButtons
	local expertCorner = Instance.new("UICorner")
	expertCorner.CornerRadius = UDim.new(0, 6)
	expertCorner.Parent = expertButton
	expertButton:SetAttribute("data-value", "Expert")
	expertButton:SetAttribute("data-group", groupName)
	expertButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Expert")
		state.settings.difficulty = "Expert"
	end)

	-- Hell
	local hellButton = Instance.new("TextButton")
	hellButton.Name = groupName .. "Hell"
	hellButton.Size = UDim2.new(1, 0, 1, 0)
	hellButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	hellButton.BackgroundTransparency = 0.3
	hellButton.BorderSizePixel = 0
	hellButton.Text = "Hell"
	hellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	hellButton.TextScaled = true
	hellButton.Font = Enum.Font.GothamBold
	hellButton.AutoButtonColor = false
	local hellPadding = Instance.new("UIPadding")
	hellPadding.PaddingTop = UDim.new(0.15, 0)
	hellPadding.PaddingLeft = UDim.new(0.15, 0)
	hellPadding.PaddingRight = UDim.new(0.15, 0)
	hellPadding.PaddingBottom = UDim.new(0.15, 0)
	hellPadding.Parent = hellButton
	hellButton.Parent = difficultyButtons
	local hellCorner = Instance.new("UICorner")
	hellCorner.CornerRadius = UDim.new(0, 6)
	hellCorner.Parent = hellButton
	hellButton:SetAttribute("data-value", "Hell")
	hellButton:SetAttribute("data-group", groupName)
	hellButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Hell")
		state.settings.difficulty = "Hell"
	end)

	-- Crazy
	local crazyButton = Instance.new("TextButton")
	crazyButton.Name = groupName .. "Crazy"
	crazyButton.Size = UDim2.new(1, 0, 1, 0)
	crazyButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	crazyButton.BackgroundTransparency = 0.3
	crazyButton.BorderSizePixel = 0
	crazyButton.Text = "Crazy"
	crazyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	crazyButton.TextScaled = true
	crazyButton.Font = Enum.Font.GothamBold
	crazyButton.AutoButtonColor = false
	local crazyPadding = Instance.new("UIPadding")
	crazyPadding.PaddingTop = UDim.new(0.15, 0)
	crazyPadding.PaddingLeft = UDim.new(0.15, 0)
	crazyPadding.PaddingRight = UDim.new(0.15, 0)
	crazyPadding.PaddingBottom = UDim.new(0.15, 0)
	crazyPadding.Parent = crazyButton
	crazyButton.Parent = difficultyButtons
	local crazyCorner = Instance.new("UICorner")
	crazyCorner.CornerRadius = UDim.new(0, 6)
	crazyCorner.Parent = crazyButton
	crazyButton:SetAttribute("data-value", "Crazy")
	crazyButton:SetAttribute("data-group", groupName)
	crazyButton.MouseButton1Click:Connect(function()
		selectButtonInGroup(groupName, "Crazy")
		state.settings.difficulty = "Crazy"
	end)
end

-- Entry Creation Functions
local function createPlayerEntry(playerData, isHost)
	local entry = Instance.new("Frame")
	entry.Name = "PlayerEntry" .. playerData.UserId
	entry.Size = UDim2.new(1, 0, 0, 80)
	entry.BackgroundColor3 = isHost and Color3.fromRGB(6, 182, 212) or Color3.fromRGB(51, 65, 85)
	entry.BackgroundTransparency = isHost and 0 or 0.3
	entry.BorderSizePixel = 0
	entry.Parent = nil

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 64, 0, 64)
	avatar.Position = UDim2.new(0, 8, 0, 8)
	avatar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	avatar.BorderSizePixel = 0
	avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	avatar.Parent = entry

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 8)
	avatarCorner.Parent = avatar

	local nameFrame = Instance.new("Frame")
	nameFrame.Name = "NameFrame"
	nameFrame.Size = UDim2.new(1, -80, 0, 40)
	nameFrame.Position = UDim2.new(0, 80, 0, 8)
	nameFrame.BackgroundTransparency = 1
	nameFrame.Parent = entry

	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(1, 0, 0, 24)
	playerName.Position = UDim2.new(0, 0, 0, 0)
	playerName.BackgroundTransparency = 1
	playerName.Text = (isHost and "?? " or "") .. playerData.Name .. " [Lv. " .. playerData.Level .. "]"
	playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerName.TextScaled = true
	playerName.Font = Enum.Font.GothamBold
	playerName.TextXAlignment = Enum.TextXAlignment.Left
	playerName.Parent = nameFrame

	local boosterText = Instance.new("TextLabel")
	boosterText.Name = "BoosterText"
	boosterText.Size = UDim2.new(1, 0, 0, 16)
	boosterText.Position = UDim2.new(0, 0, 0, 24)
	boosterText.BackgroundTransparency = 1
	-- Safely handle ActiveBooster which might be a table or string
	local boosterTextValue = playerData.ActiveBooster
	if type(boosterTextValue) == "table" and boosterTextValue.Name then
		boosterTextValue = boosterTextValue.Name
	elseif type(boosterTextValue) == "table" then
		boosterTextValue = tostring(boosterTextValue)
	end
	boosterText.Text = "Booster: " .. (boosterTextValue or "None")
	boosterText.TextColor3 = Color3.fromRGB(6, 182, 212)
	boosterText.TextScaled = true
	boosterText.Font = Enum.Font.Gotham
	boosterText.TextXAlignment = Enum.TextXAlignment.Left
	boosterText.Parent = nameFrame

	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusFrame"
	statusFrame.Size = UDim2.new(0, 120, 0, 32)
	statusFrame.Position = UDim2.new(1, -128, 0, 24)
	statusFrame.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	statusFrame.BorderSizePixel = 0
	statusFrame.Parent = entry

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 16)
	statusCorner.Parent = statusFrame

	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, 0, 1, 0)
	statusText.Position = UDim2.new(0, 0, 0, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Siap"
	statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.GothamBold
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Parent = statusFrame

	return entry
end

local function joinRoomByCode(code)
	if not code or code == "" then
		print("Please enter a room code")
		return
	end

	print("Joining room with code:", code)
	lobbyRemote:FireServer("joinRoom", {
		roomCode = code
	})
end

local function createRoomEntry(roomData, roomId)
	local entry = Instance.new("TextButton")
	entry.Name = "RoomEntry" .. roomId
	entry.Size = UDim2.new(1, 0, 0, 48)
	entry.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	entry.BorderSizePixel = 0
	entry.Text = ""
	entry.AutoButtonColor = false
	entry.Parent = nil

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 4)
	entryCorner.Parent = entry

	entry.MouseEnter:Connect(function()
		entry.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	end)

	entry.MouseLeave:Connect(function()
		entry.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	end)

	entry.MouseButton1Click:Connect(function()
		joinRoomByCode(roomData.roomId)
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 8, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = roomData.roomName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = entry

	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(0.2, 0, 1, 0)
	modeLabel.Position = UDim2.new(0.4, 0, 0, 0)
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = roomData.gameMode
	modeLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	modeLabel.TextScaled = true
	modeLabel.Font = Enum.Font.Gotham
	modeLabel.TextXAlignment = Enum.TextXAlignment.Center
	modeLabel.Parent = entry

	local difficultyLabel = Instance.new("TextLabel")
	difficultyLabel.Name = "DifficultyLabel"
	difficultyLabel.Size = UDim2.new(0.2, 0, 1, 0)
	difficultyLabel.Position = UDim2.new(0.6, 0, 0, 0)
	difficultyLabel.BackgroundTransparency = 1
	difficultyLabel.Text = "Easy"
	difficultyLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
	difficultyLabel.TextScaled = true
	difficultyLabel.Font = Enum.Font.Gotham
	difficultyLabel.TextXAlignment = Enum.TextXAlignment.Center
	difficultyLabel.Parent = entry

	local playerCountLabel = Instance.new("TextLabel")
	playerCountLabel.Name = "PlayerCountLabel"
	playerCountLabel.Size = UDim2.new(0.2, 0, 1, 0)
	playerCountLabel.Position = UDim2.new(0.8, 0, 0, 0)
	playerCountLabel.BackgroundTransparency = 1
	playerCountLabel.Text = roomData.playerCount .. "/" .. roomData.maxPlayers
	playerCountLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	playerCountLabel.TextScaled = true
	playerCountLabel.Font = Enum.Font.Gotham
	playerCountLabel.TextXAlignment = Enum.TextXAlignment.Center
	playerCountLabel.Parent = entry

	return entry
end

local function showContentPanel(panelId)
	for id, panel in pairs(contentPanels) do
		if panel and panel.Parent then
			if id == panelId then
				panel.Visible = true
			else
				panel.Visible = false
			end
		end
	end

	for id, button in pairs(navButtons) do
		if button and button.Parent then
			if id == panelId then
				button.BackgroundTransparency = 0.1
			else
				button.BackgroundTransparency = 0.3
			end
		end
	end

	state.currentContentPanel = panelId
	print("Pindah ke Panel Konten:", panelId)
end

-- Navigation Functions
local function showScreenContainer(containerId, returnToContentId)
	for id, container in pairs(screenContainers) do
		if container and container.Parent then
			if id == containerId then
				container.Visible = true
			else
				container.Visible = false
			end
		end
	end
	state.currentScreenContainer = containerId

	if containerId == "main-hub" and returnToContentId then
		showContentPanel(returnToContentId)
	end

	print("Pindah ke Kontainer Layar:", containerId)
end

-- Server Interaction Functions
local function startSoloGame()
	print("Starting solo game...")
	lobbyRemote:FireServer("startSoloGame", {
		gameMode = state.settings.mode,
		difficulty = state.settings.difficulty
	})
	showScreenContainer("teleporting")
end

local function createRoom()
	-- Safe access to UI elements with null checks
	local roomName = ""

	if gui and gui:FindFirstChild("MainContainer") then
		local mainContainer = gui.MainContainer
		if mainContainer:FindFirstChild("CreateOptionsPanel") then
			local createPanel = mainContainer.CreateOptionsPanel
			if createPanel:FindFirstChild("NameSection") then
				local nameSection = createPanel.NameSection
				local nameInput = nameSection:FindFirstChild("NameInput")
				if nameInput and nameInput:IsA("TextBox") then
					roomName = nameInput.Text
				end
			end
		end
	end

	print("Creating room with name:", roomName or "(empty)")
	lobbyRemote:FireServer("createRoom", {
		roomName = roomName,
		isPrivate = state.settings.visibility == "private",
		maxPlayers = state.settings.playerCount,
		gameMode = state.settings.mode,
		difficulty = state.settings.difficulty
	})
end

local function startMatchmaking()
	print("Starting matchmaking...")
	lobbyRemote:FireServer("startMatchmaking", {
		playerCount = state.settings.playerCount,
		gameMode = state.settings.mode,
		difficulty = state.settings.difficulty
	})
	showScreenContainer("matchmaking-wait")
end

local function cancelMatchmaking()
	print("Cancelling matchmaking...")
	lobbyRemote:FireServer("cancelMatchmaking")
	showScreenContainer("main-hub", "matchmaking-options")
end

local function leaveRoom()
	print("Leaving room...")
	lobbyRemote:FireServer("leaveRoom")
end

local function startGame()
	print("Starting game...")
	lobbyRemote:FireServer("forceStartGame")
end

local function toggleReady()
	state.isReady = not state.isReady

	-- Safe access to ready button
	local preGameContainer = screenContainers["pre-game-lobby"]
	if preGameContainer and
		preGameContainer:FindFirstChild("ClientControls") and
		preGameContainer.ClientControls:FindFirstChild("ReadyButton") then

		local readyButton = preGameContainer.ClientControls.ReadyButton
		if state.isReady then
			readyButton.Text = "BATAL SIAP"
			readyButton.BackgroundColor3 = Color3.fromRGB(107, 114, 128)
		else
			readyButton.Text = "SIAP"
			readyButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
		end
		print("Ready state toggled to:", state.isReady)
	else
		print("Ready button not found, state changed but UI not updated")
	end
end

-- Update Functions
local function updateRoomInfo(roomData)
	state.currentRoom = roomData
	state.isHost = (roomData.hostName == player.Name)

	local preGameContainer = screenContainers["pre-game-lobby"]
	if not preGameContainer then
		print("Pre-game lobby container not found, skipping update")
		return
	end

	-- Safe access to room info labels
	if preGameContainer:FindFirstChild("LeftPanel") and
		preGameContainer.LeftPanel:FindFirstChild("RoomInfoSection") then

		local roomInfoSection = preGameContainer.LeftPanel.RoomInfoSection
		local codeLabel = roomInfoSection:FindFirstChild("CodeLabel")
		local modeLabel = roomInfoSection:FindFirstChild("ModeLabel")
		local difficultyLabel = roomInfoSection:FindFirstChild("DifficultyLabel")

		if codeLabel and codeLabel:IsA("TextLabel") then
			codeLabel.Text = "Kode Lobi: " .. (roomData.roomCode or "N/A")
		end
		if modeLabel and modeLabel:IsA("TextLabel") then
			modeLabel.Text = "Mode Game: " .. roomData.gameMode
		end
		if difficultyLabel and difficultyLabel:IsA("TextLabel") then
			difficultyLabel.Text = "Kesulitan: " .. roomData.difficulty
		end
	end

	-- Safe access to squad title
	if preGameContainer:FindFirstChild("RightPanel") then
		local rightPanel = preGameContainer.RightPanel
		local squadTitle = rightPanel:FindFirstChild("SquadTitle")
		if squadTitle and squadTitle:IsA("TextLabel") then
			squadTitle.Text = "SKUAD (" .. #roomData.players .. "/" .. roomData.maxPlayers .. ")"
		end

		-- Safe access to players list
		if rightPanel:FindFirstChild("PlayersListContainer") and
			rightPanel.PlayersListContainer:FindFirstChild("PlayersScrollFrame") then

			local playersScrollFrame = rightPanel.PlayersListContainer.PlayersScrollFrame

			-- Clear existing entries
			for _, child in ipairs(playersScrollFrame:GetChildren()) do
				if child.Name:match("PlayerEntry") then
					child:Destroy()
				end
			end

			-- Add new player entries
			for i, playerData in ipairs(roomData.players) do
				local playerEntry = createPlayerEntry(playerData, i == 1)
				playerEntry.Parent = playersScrollFrame
			end
		end
	end

	-- Safe access to host/client controls
	if preGameContainer:FindFirstChild("LeftPanel") then
		local leftPanel = preGameContainer.LeftPanel
		local hostControls = leftPanel:FindFirstChild("HostControls")
		local clientControls = leftPanel:FindFirstChild("ClientControls")

		if hostControls and hostControls:IsA("Frame") then
			hostControls.Visible = state.isHost
		end
		if clientControls and clientControls:IsA("Frame") then
			clientControls.Visible = not state.isHost
		end
	end

	print("Room info updated successfully")
end

local function updatePublicRooms(roomsData)
	state.publicRooms = roomsData

	local joinPanel = contentPanels["join-options"]
	if not joinPanel then return end

	local roomsScrollFrame = joinPanel:FindFirstChild("RoomsSection"):FindFirstChild("RoomsList")
	if not roomsScrollFrame then return end

	for _, child in ipairs(roomsScrollFrame:GetChildren()) do
		if child.Name:match("RoomEntry") then
			child:Destroy()
		end
	end

	for roomId, roomData in pairs(roomsData) do
		local roomEntry = createRoomEntry(roomData, roomId)
		roomEntry.Parent = roomsScrollFrame
	end
end

local function showCountdownUpdate(value)
	local preGameContainer = screenContainers["pre-game-lobby"]
	if not preGameContainer then return end

	local countdownFrame = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("CountdownFrame")
	if not countdownFrame then
		countdownFrame = Instance.new("Frame")
		countdownFrame.Name = "CountdownFrame"
		countdownFrame.Size = UDim2.new(1, -48, 0, 120)
		countdownFrame.Position = UDim2.new(0, 24, 1, -144)
		countdownFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
		countdownFrame.BorderSizePixel = 0
		countdownFrame.Parent = preGameContainer:FindFirstChild("LeftPanel")

		local countdownCorner = Instance.new("UICorner")
		countdownCorner.CornerRadius = UDim.new(0, 8)
		countdownCorner.Parent = countdownFrame

		local countdownTitle = Instance.new("TextLabel")
		countdownTitle.Name = "CountdownTitle"
		countdownTitle.Size = UDim2.new(1, 0, 0, 30)
		countdownTitle.Position = UDim2.new(0, 0, 0, 8)
		countdownTitle.BackgroundTransparency = 1
		countdownTitle.Text = "MEMULAI MISI DALAM..."
		countdownTitle.TextColor3 = Color3.fromRGB(6, 182, 212)
		countdownTitle.TextScaled = true
		countdownTitle.Font = Enum.Font.GothamBlack
		countdownTitle.TextXAlignment = Enum.TextXAlignment.Center
		countdownTitle.Parent = countdownFrame

		local countdownValue = Instance.new("TextLabel")
		countdownValue.Name = "CountdownValue"
		countdownValue.Size = UDim2.new(1, 0, 0, 60)
		countdownValue.Position = UDim2.new(0, 0, 0, 40)
		countdownValue.BackgroundTransparency = 1
		countdownValue.Text = tostring(value)
		countdownValue.TextColor3 = Color3.fromRGB(255, 255, 255)
		countdownValue.TextScaled = true
		countdownValue.Font = Enum.Font.GothamBlack
		countdownValue.TextXAlignment = Enum.TextXAlignment.Center
		countdownValue.Parent = countdownFrame
	else
		countdownFrame.Visible = true
		local countdownValue = countdownFrame:FindFirstChild("CountdownValue")
		if countdownValue then
			countdownValue.Text = tostring(value)
		end
	end

	local hostControls = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("HostControls")
	local clientControls = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("ClientControls")
	if hostControls then hostControls.Visible = false end
	if clientControls then clientControls.Visible = false end
end

local function hideCountdown()
	local preGameContainer = screenContainers["pre-game-lobby"]
	if not preGameContainer then return end

	local countdownFrame = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("CountdownFrame")
	if countdownFrame then
		countdownFrame.Visible = false
	end

	local hostControls = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("HostControls")
	local clientControls = preGameContainer:FindFirstChild("LeftPanel"):FindFirstChild("ClientControls")
	if hostControls then hostControls.Visible = state.isHost end
	if clientControls then clientControls.Visible = not state.isHost end
end

-- GUI Creation Functions
local function createGUI()
	gui = Instance.new("ScreenGui")
	gui.Name = "LobbyRoomUI"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.Size = UDim2.new(0.9, 0, 0.9, 0)  -- Reduced size to prevent overflow
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)  -- Adjusted position
	mainContainer.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	mainContainer.BackgroundTransparency = 0
	mainContainer.BorderSizePixel = 0
	mainContainer.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainContainer

	return mainContainer
end

local function createCloseButton(parent)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)  -- Slightly larger
	closeButton.Position = UDim2.new(1, -50, 0, 10)  -- Fixed position instead of scale
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "?"
	closeButton.TextColor3 = Color3.fromRGB(148, 163, 184)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.ZIndex = 10
	closeButton.Parent = parent

	closeButton.MouseEnter:Connect(function()
		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)

	closeButton.MouseLeave:Connect(function()
		closeButton.TextColor3 = Color3.fromRGB(148, 163, 184)
	end)

	closeButton.MouseButton1Click:Connect(function()
		hideLobbyUI()
	end)

	return closeButton
end

-- Content Panel Functions
local function createSoloOptionsPanel(parent)
	local panel = Instance.new("Frame")
	panel.Name = "SoloOptionsPanel"
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundTransparency = 1
	panel.Visible = true
	panel.BorderSizePixel = 0
	panel.Parent = parent
	contentPanels["solo-options"] = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(0.974, 0, 1, 0)  -- Adjusted width for scrollbar
	content.Position = UDim2.new(0.013, 0, 0, 0)  -- Already scale-based
	content.BackgroundTransparency = 1
	content.Parent = panel
	local UIListLayoutcontent = Instance.new("UIListLayout")
	UIListLayoutcontent.Padding = UDim.new(0, 0)
	UIListLayoutcontent.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayoutcontent.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayoutcontent.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayoutcontent.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	UIListLayoutcontent.Parent = content

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.095, 0)
	title.BackgroundTransparency = 1
	title.Text = "PENGATURAN SOLO"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = content
	local UIPaddingtitle = Instance.new("UIPadding")
	UIPaddingtitle.PaddingTop = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingLeft = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingRight = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingBottom = UDim.new(0.05, 0)
	UIPaddingtitle.Parent = title

	createGameModeSection(content, "solo-mode", 0.11)
	createDifficultySection(content, "solo-difficulty", 0.23)

	local startButton = Instance.new("TextButton")
	startButton.Name = "StartSoloButton"
	startButton.Size = UDim2.new(1, -32, 0, 50)  -- Reduced height and width with margins
	startButton.Position = UDim2.new(0, 0.016, 1, -0.07)  -- Scale-based positioning
	startButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	startButton.BorderSizePixel = 0
	startButton.Text = "MULAI SOLO"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.GothamBlack
	startButton.AutoButtonColor = false

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.20, 0)  -- Increased padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.20, 0)
	padding.Parent = startButton

	startButton.Parent = content

	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 8)
	startCorner.Parent = startButton

	startButton.MouseButton1Click:Connect(function()
		startSoloGame()
	end)

	startButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(74, 222, 128)})
		tween:Play()
	end)

	startButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 197, 94)})
		tween:Play()
	end)
end

local function createCreateOptionsPanel(parent)
	local panel = Instance.new("ScrollingFrame")
	panel.Name = "CreateOptionsPanel"
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.ScrollBarThickness = 8
	panel.BorderSizePixel = 0
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.CanvasSize = UDim2.new(0, 0, 0, 0)
	panel.Parent = parent
	contentPanels["create-options"] = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -16, 0, 0)  -- Adjusted width for scrollbar
	content.BackgroundTransparency = 1
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Parent = panel

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 10)
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	uiListLayout.Parent = content

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "BUAT LOBI BARU"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = content

	local nameSection = Instance.new("Frame")
	nameSection.Name = "NameSection"
	nameSection.Size = UDim2.new(1, 0, 0, 80)  -- Using full width
	nameSection.BackgroundTransparency = 1
	nameSection.LayoutOrder = 2
	nameSection.Parent = content

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Label"
	nameLabel.Size = UDim2.new(1, 0, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Nama Lobi (Opsional)"
	nameLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = nameSection

	local nameInput = Instance.new("TextBox")
	nameInput.Name = "NameInput"
	nameInput.Size = UDim2.new(1, 0, 0.5, 0)
	nameInput.Position = UDim2.new(0, 0, 0.25, 0)
	nameInput.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	nameInput.BorderColor3 = Color3.fromRGB(51, 65, 85)
	nameInput.BorderSizePixel = 1
	nameInput.Text = ""
	nameInput.PlaceholderText = "Lobi Host"
	nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameInput.TextScaled = true
	nameInput.Font = Enum.Font.Gotham
	nameInput.ClearTextOnFocus = false
	nameInput.Parent = nameSection

	local nameCorner = Instance.new("UICorner")
	nameCorner.CornerRadius = UDim.new(0, 8)
	nameCorner.Parent = nameInput

	local visibilitySection = Instance.new("Frame")
	visibilitySection.Name = "VisibilitySection"
	visibilitySection.Size = UDim2.new(1, 0, 0, 0)
	visibilitySection.BackgroundTransparency = 1
	visibilitySection.AutomaticSize = Enum.AutomaticSize.Y
	visibilitySection.LayoutOrder = 3
	visibilitySection.Parent = content

	local visibilityLayout = Instance.new("UIListLayout")
	visibilityLayout.SortOrder = Enum.SortOrder.LayoutOrder
	visibilityLayout.Padding = UDim.new(0, 5)
	visibilityLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	visibilityLayout.Parent = visibilitySection

	local visibilityLabel = Instance.new("TextLabel")
	visibilityLabel.Name = "Label"
	visibilityLabel.Size = UDim2.new(1, 0, 0, 20)
	visibilityLabel.BackgroundTransparency = 1
	visibilityLabel.Text = "Visibilitas"
	visibilityLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	visibilityLabel.TextScaled = true
	visibilityLabel.Font = Enum.Font.Gotham
	visibilityLabel.TextXAlignment = Enum.TextXAlignment.Left
	visibilityLabel.LayoutOrder = 1
	visibilityLabel.Parent = visibilitySection

	local visibilityButtons = Instance.new("Frame")
	visibilityButtons.Name = "Buttons"
	visibilityButtons.Size = UDim2.new(1, 0, 0, 40)
	visibilityButtons.BackgroundTransparency = 1
	visibilityButtons.LayoutOrder = 2
	visibilityButtons.Parent = visibilitySection

	local visibilityGrid = Instance.new("UIGridLayout")
	visibilityGrid.FillDirection = Enum.FillDirection.Horizontal
	visibilityGrid.SortOrder = Enum.SortOrder.LayoutOrder
	visibilityGrid.CellPadding = UDim2.new(0.05, 0, 0, 0)
	visibilityGrid.CellSize = UDim2.new(0.45, 0, 1, 0)
	visibilityGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	visibilityGrid.VerticalAlignment = Enum.VerticalAlignment.Center
	visibilityGrid.Parent = visibilityButtons

	-- Manual creation for "Public" button
	local publicButton = Instance.new("TextButton")
	publicButton.Name = "VisibilityPublic"
	publicButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	publicButton.BackgroundTransparency = 0
	publicButton.BorderSizePixel = 0
	publicButton.Text = "Publik"
	publicButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	publicButton.TextScaled = true
	publicButton.Font = Enum.Font.GothamBold
	publicButton.AutoButtonColor = false
	publicButton.LayoutOrder = 1
	local publicPadding = Instance.new("UIPadding")
	publicPadding.PaddingTop = UDim.new(0.20, 0)
	publicPadding.PaddingLeft = UDim.new(0.10, 0)
	publicPadding.PaddingRight = UDim.new(0.10, 0)
	publicPadding.PaddingBottom = UDim.new(0.20, 0)
	publicPadding.Parent = publicButton
	publicButton.Parent = visibilityButtons
	local publicCorner = Instance.new("UICorner")
	publicCorner.CornerRadius = UDim.new(0, 8)
	publicCorner.Parent = publicButton
	publicButton:SetAttribute("data-value", "public")
	publicButton:SetAttribute("data-group", "create-visibility")
	publicButton.MouseButton1Click:Connect(function()
		selectButtonInGroup("create-visibility", "public")
		state.settings.visibility = "public"
	end)

	-- Manual creation for "Private" button
	local privateButton = Instance.new("TextButton")
	privateButton.Name = "VisibilityPrivate"
	privateButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	privateButton.BackgroundTransparency = 0.3
	privateButton.BorderSizePixel = 0
	privateButton.Text = "Privat"
	privateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	privateButton.TextScaled = true
	privateButton.Font = Enum.Font.GothamBold
	privateButton.AutoButtonColor = false
	privateButton.LayoutOrder = 2
	local privatePadding = Instance.new("UIPadding")
	privatePadding.PaddingTop = UDim.new(0.20, 0)
	privatePadding.PaddingLeft = UDim.new(0.10, 0)
	privatePadding.PaddingRight = UDim.new(0.10, 0)
	privatePadding.PaddingBottom = UDim.new(0.20, 0)
	privatePadding.Parent = privateButton
	privateButton.Parent = visibilityButtons
	local privateCorner = Instance.new("UICorner")
	privateCorner.CornerRadius = UDim.new(0, 8)
	privateCorner.Parent = privateButton
	privateButton:SetAttribute("data-value", "private")
	privateButton:SetAttribute("data-group", "create-visibility")
	privateButton.MouseButton1Click:Connect(function()
		selectButtonInGroup("create-visibility", "private")
		state.settings.visibility = "private"
	end)

	createGameModeSection(content, "create-mode", nil, 4)

	createPlayerCountSection(content, "create-playercount", nil, 5)

	createDifficultySection(content, "create-difficulty", nil, 6)

	local createButton = Instance.new("TextButton")
	createButton.Name = "CreateRoomButton"
	createButton.Size = UDim2.new(1, -32, 0, 50)  -- Reduced height and width with margins
	createButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	createButton.BorderSizePixel = 0
	createButton.Text = "BUAT LOBI"
	createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	createButton.TextScaled = true
	createButton.Font = Enum.Font.GothamBlack
	createButton.AutoButtonColor = false
	createButton.LayoutOrder = 7

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.20, 0)  -- Increased padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.20, 0)
	padding.Parent = createButton

	createButton.Parent = content

	local createCorner = Instance.new("UICorner")
	createCorner.CornerRadius = UDim.new(0, 8)
	createCorner.Parent = createButton

	createButton.MouseButton1Click:Connect(function()
		createRoom()
	end)

	createButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(createButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(74, 222, 128)})
		tween:Play()
	end)

	createButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(createButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 197, 94)})
		tween:Play()
	end)
end

local function createJoinOptionsPanel(parent)
	local panel = Instance.new("Frame")
	panel.Name = "JoinOptionsPanel"
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.Parent = parent
	contentPanels["join-options"] = panel

	local panelLayout = Instance.new("UIListLayout")
	panelLayout.FillDirection = Enum.FillDirection.Vertical
	panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
	panelLayout.Padding = UDim.new(0, 10)
	panelLayout.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "CARI LOBI"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = panel

	local codeSection = Instance.new("Frame")
	codeSection.Name = "CodeSection"
	codeSection.Size = UDim2.new(1, 0, 0, 0)
	codeSection.BackgroundTransparency = 1
	codeSection.AutomaticSize = Enum.AutomaticSize.Y
	codeSection.LayoutOrder = 2
	codeSection.Parent = panel

	local codeLayout = Instance.new("UIListLayout")
	codeLayout.FillDirection = Enum.FillDirection.Horizontal
	codeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	codeLayout.Padding = UDim.new(0, 10)
	codeLayout.Parent = codeSection

	local codeInput = Instance.new("TextBox")
	codeInput.Name = "CodeInput"
	codeInput.Size = UDim2.new(1, -60, 0, 40)
	codeInput.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	codeInput.BorderColor3 = Color3.fromRGB(51, 65, 85)
	codeInput.BorderSizePixel = 1
	codeInput.Text = ""
	codeInput.PlaceholderText = "Masukkan Kode Lobi..."
	codeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	codeInput.TextScaled = true
	codeInput.Font = Enum.Font.Gotham
	codeInput.ClearTextOnFocus = false
	codeInput.LayoutOrder = 1
	codeInput.Parent = codeSection

	local codeCorner = Instance.new("UICorner")
	codeCorner.CornerRadius = UDim.new(0, 8)
	codeCorner.Parent = codeInput

	local joinButton = Instance.new("TextButton")
	joinButton.Name = "JoinButton"
	joinButton.Size = UDim2.new(0, 50, 0, 40)
	joinButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	joinButton.BorderSizePixel = 0
	joinButton.Text = "Gabung"
	joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	joinButton.TextScaled = true
	joinButton.Font = Enum.Font.GothamBold
	joinButton.AutoButtonColor = false
	joinButton.LayoutOrder = 2

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)  -- Good padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.Parent = joinButton

	joinButton.Parent = codeSection

	local joinCorner = Instance.new("UICorner")
	joinCorner.CornerRadius = UDim.new(0, 8)
	joinCorner.Parent = joinButton

	joinButton.MouseButton1Click:Connect(function()
		joinRoomByCode(codeInput.Text)
	end)

	local roomsSection = Instance.new("Frame")
	roomsSection.Name = "RoomsSection"
	roomsSection.Size = UDim2.new(1, 0, 0, 0)
	roomsSection.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	roomsSection.BackgroundTransparency = 0.3
	roomsSection.BorderColor3 = Color3.fromRGB(51, 65, 85)
	roomsSection.BorderSizePixel = 1
	roomsSection.AutomaticSize = Enum.AutomaticSize.Y
	roomsSection.LayoutOrder = 3
	roomsSection.Parent = panel

	local roomsCorner = Instance.new("UICorner")
	roomsCorner.CornerRadius = UDim.new(0, 8)
	roomsCorner.Parent = roomsSection

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "RoomsList"
	scrollFrame.Size = UDim2.new(1, 0, 0, 0)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.BorderSizePixel = 0
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = roomsSection

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scrollFrame

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
	header.BackgroundTransparency = 0.2
	header.BorderSizePixel = 0
	header.LayoutOrder = 1
	header.Parent = scrollFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 4)
	headerCorner.Parent = header

	local headerText = Instance.new("TextLabel")
	headerText.Name = "HeaderText"
	headerText.Size = UDim2.new(1, 0, 1, 0)
	headerText.BackgroundTransparency = 1
	headerText.Text = "Nama Lobi                    | Mode | Kesulitan | Pemain"
	headerText.TextColor3 = Color3.fromRGB(203, 213, 225)
	headerText.TextScaled = true
	headerText.Font = Enum.Font.Gotham
	headerText.TextXAlignment = Enum.TextXAlignment.Left
	headerText.Parent = header

	scrollFrame:SetAttribute("is-rooms-list", true)
end

local function createMatchmakingOptionsPanel(parent)
	local panel = Instance.new("ScrollingFrame")
	panel.Name = "MatchmakingOptionsPanel"
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundTransparency = 1
	panel.Visible = false
	panel.ScrollBarThickness = 8
	panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	panel.CanvasSize = UDim2.new(0, 0, 0, 0)
	panel.Parent = parent
	contentPanels["matchmaking-options"] = panel

	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0.05, 0)
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	uiListLayout.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.1, 0)
	title.Position = UDim2.new(0.5, 0, 0, 0)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Text = "CARI LOBI OTOMATIS"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = panel

	createGameModeSection(panel, "matchmaking-mode", nil, 2)
	local gameModeSection = panel:FindFirstChild("matchmaking-modeSection")
	if gameModeSection then
		local buttons = gameModeSection:FindFirstChild("Buttons")
		if buttons then
			for _, button in ipairs(buttons:GetChildren()) do
				if button:IsA("TextButton") then
					button.Size = UDim2.new(0.4, 0, 1, 0)
				end
			end
		end
	end
	createPlayerCountSection(panel, "matchmaking-playercount", nil, 3)
	local playerCountSection = panel:FindFirstChild("matchmaking-playercountSection")
	if playerCountSection then
		local label = playerCountSection:FindFirstChild("Label")
		if label then
			label.Size = UDim2.new(1, 0, 0.133, 0)
		end
	end
	createDifficultySection(panel, "matchmaking-difficulty", nil, 4)

	local startButton = Instance.new("TextButton")
	startButton.Name = "StartMatchmakingButton"
	startButton.Size = UDim2.new(1, -32, 0, 50)  -- Reduced height and width with margins
	startButton.Position = UDim2.new(0.5, 0, 0, 0)
	startButton.AnchorPoint = Vector2.new(0.5, 1)
	startButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	startButton.BorderSizePixel = 0
	startButton.Text = "CARI LOBI"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.GothamBlack
	startButton.AutoButtonColor = false
	startButton.LayoutOrder = 5

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.20, 0)  -- Increased padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.20, 0)
	padding.Parent = startButton

	startButton.Parent = panel

	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 8)
	startCorner.Parent = startButton

	startButton.MouseButton1Click:Connect(function()
		startMatchmaking()
	end)

	startButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(8, 145, 178)})
		tween:Play()
	end)

	startButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(startButton, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(6, 182, 212)})
		tween:Play()
	end)
end

local function createContentPanels(parent)
	createSoloOptionsPanel(parent)
	createCreateOptionsPanel(parent)
	createJoinOptionsPanel(parent)
	createMatchmakingOptionsPanel(parent)
end

-- Screen Container Functions
local function createMainHub()
	local container = Instance.new("Frame")
	container.Name = "MainHubContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Visible = true
	container.Parent = gui.MainContainer
	screenContainers["main-hub"] = container

	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.3, 0, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	leftPanel.BackgroundTransparency = 0.5
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = container

	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 0)
	leftCorner.Parent = leftPanel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.803, 0, 0.1, 0)
	title.Position = UDim2.new(0.096, 0, 0.061, 0)
	title.BackgroundTransparency = 1
	title.Text = "LOBI UTAMA"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.Parent = leftPanel
	local UIPaddingtitle = Instance.new("UIPadding")
	UIPaddingtitle.PaddingTop = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingLeft = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingRight = UDim.new(0.05, 0)
	UIPaddingtitle.PaddingBottom = UDim.new(0.05, 0)
	UIPaddingtitle.Parent = title

	local navContainer = Instance.new("Frame")
	navContainer.Name = "NavContainer"
	navContainer.Size = UDim2.new(0.809, 0, 0.818, 0)
	navContainer.Position = UDim2.new(0.096, 0, 0.182, 0)
	navContainer.BackgroundTransparency = 1
	navContainer.Parent = leftPanel
	local UIListLayoutnavContainer = Instance.new("UIListLayout")
	UIListLayoutnavContainer.Padding = UDim.new(0, 0)
	UIListLayoutnavContainer.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayoutnavContainer.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayoutnavContainer.VerticalAlignment = Enum.VerticalAlignment.Center
	UIListLayoutnavContainer.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	UIListLayoutnavContainer.Parent = navContainer

	-- Manual creation for navigation buttons
	-- Solo Button
	local navButton1 = Instance.new("TextButton")
	navButton1.Name = "NavButton1"
	navButton1.Size = UDim2.new(1, -16, 0.16, 0)
	navButton1.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	navButton1.BackgroundTransparency = 0.3
	navButton1.BorderSizePixel = 0
	navButton1.AutoButtonColor = false
	navButton1.Parent = navContainer
	local navPadding1 = Instance.new("UIPadding")
	navPadding1.PaddingTop = UDim.new(0.08, 0)
	navPadding1.PaddingLeft = UDim.new(0.08, 0)
	navPadding1.PaddingRight = UDim.new(0.08, 0)
	navPadding1.PaddingBottom = UDim.new(0.08, 0)
	navPadding1.Parent = navButton1
	local navCorner1 = Instance.new("UICorner")
	navCorner1.CornerRadius = UDim.new(0, 8)
	navCorner1.Parent = navButton1
	local icon1 = Instance.new("TextLabel")
	icon1.Name = "Icon"
	icon1.Size = UDim2.new(0.205, 0, 0.519, 0)
	icon1.Position = UDim2.new(0.01, 0, 0.189, 0)
	icon1.BackgroundTransparency = 1
	icon1.Text = "??"
	icon1.TextScaled = true
	icon1.Font = Enum.Font.GothamBold
	icon1.Parent = navButton1
	local titleText1 = Instance.new("TextLabel")
	titleText1.Name = "TitleText"
	titleText1.Size = UDim2.new(0.727, 0, 0.283, 0)
	titleText1.Position = UDim2.new(0.273, 0, 0.189, 0)
	titleText1.BackgroundTransparency = 1
	titleText1.Text = "Main Solo"
	titleText1.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText1.TextScaled = true
	titleText1.Font = Enum.Font.GothamBold
	titleText1.TextXAlignment = Enum.TextXAlignment.Left
	titleText1.Parent = navButton1
	local descText1 = Instance.new("TextLabel")
	descText1.Name = "DescText"
	descText1.Size = UDim2.new(0.727, 0, 0.189, 0)
	descText1.Position = UDim2.new(0.273, 0, 0.519, 0)
	descText1.BackgroundTransparency = 1
	descText1.Text = "Mulai misi sendirian."
	descText1.TextColor3 = Color3.fromRGB(148, 163, 184)
	descText1.TextScaled = true
	descText1.Font = Enum.Font.Gotham
	descText1.TextXAlignment = Enum.TextXAlignment.Left
	descText1.Parent = navButton1
	navButton1:SetAttribute("data-content-target", "solo-options")
	navButtons["solo-options"] = navButton1
	navButton1.MouseButton1Click:Connect(function()
		showContentPanel("solo-options")
	end)
	navButton1.MouseEnter:Connect(function()
		TweenService:Create(navButton1, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end)
	navButton1.MouseLeave:Connect(function()
		TweenService:Create(navButton1, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end)

	-- Create Lobby Button
	local navButton2 = Instance.new("TextButton")
	navButton2.Name = "NavButton2"
	navButton2.Size = UDim2.new(1, -16, 0.16, 0)
	navButton2.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	navButton2.BackgroundTransparency = 0.3
	navButton2.BorderSizePixel = 0
	navButton2.AutoButtonColor = false
	navButton2.Parent = navContainer
	local navPadding2 = Instance.new("UIPadding")
	navPadding2.PaddingTop = UDim.new(0.08, 0)
	navPadding2.PaddingLeft = UDim.new(0.08, 0)
	navPadding2.PaddingRight = UDim.new(0.08, 0)
	navPadding2.PaddingBottom = UDim.new(0.08, 0)
	navPadding2.Parent = navButton2
	local navCorner2 = Instance.new("UICorner")
	navCorner2.CornerRadius = UDim.new(0, 8)
	navCorner2.Parent = navButton2
	local icon2 = Instance.new("TextLabel")
	icon2.Name = "Icon"
	icon2.Size = UDim2.new(0.205, 0, 0.519, 0)
	icon2.Position = UDim2.new(0.01, 0, 0.189, 0)
	icon2.BackgroundTransparency = 1
	icon2.Text = "?"
	icon2.TextScaled = true
	icon2.Font = Enum.Font.GothamBold
	icon2.Parent = navButton2
	local titleText2 = Instance.new("TextLabel")
	titleText2.Name = "TitleText"
	titleText2.Size = UDim2.new(0.727, 0, 0.283, 0)
	titleText2.Position = UDim2.new(0.273, 0, 0.189, 0)
	titleText2.BackgroundTransparency = 1
	titleText2.Text = "Buat Lobi"
	titleText2.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText2.TextScaled = true
	titleText2.Font = Enum.Font.GothamBold
	titleText2.TextXAlignment = Enum.TextXAlignment.Left
	titleText2.Parent = navButton2
	local descText2 = Instance.new("TextLabel")
	descText2.Name = "DescText"
	descText2.Size = UDim2.new(0.727, 0, 0.189, 0)
	descText2.Position = UDim2.new(0.273, 0, 0.519, 0)
	descText2.BackgroundTransparency = 1
	descText2.Text = "Buat lobi privat atau publik."
	descText2.TextColor3 = Color3.fromRGB(148, 163, 184)
	descText2.TextScaled = true
	descText2.Font = Enum.Font.Gotham
	descText2.TextXAlignment = Enum.TextXAlignment.Left
	descText2.Parent = navButton2
	navButton2:SetAttribute("data-content-target", "create-options")
	navButtons["create-options"] = navButton2
	navButton2.MouseButton1Click:Connect(function()
		showContentPanel("create-options")
	end)
	navButton2.MouseEnter:Connect(function()
		TweenService:Create(navButton2, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end)
	navButton2.MouseLeave:Connect(function()
		TweenService:Create(navButton2, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end)

	-- Join Lobby Button
	local navButton3 = Instance.new("TextButton")
	navButton3.Name = "NavButton3"
	navButton3.Size = UDim2.new(1, -16, 0.16, 0)
	navButton3.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	navButton3.BackgroundTransparency = 0.3
	navButton3.BorderSizePixel = 0
	navButton3.AutoButtonColor = false
	navButton3.Parent = navContainer
	local navPadding3 = Instance.new("UIPadding")
	navPadding3.PaddingTop = UDim.new(0.08, 0)
	navPadding3.PaddingLeft = UDim.new(0.08, 0)
	navPadding3.PaddingRight = UDim.new(0.08, 0)
	navPadding3.PaddingBottom = UDim.new(0.08, 0)
	navPadding3.Parent = navButton3
	local navCorner3 = Instance.new("UICorner")
	navCorner3.CornerRadius = UDim.new(0, 8)
	navCorner3.Parent = navButton3
	local icon3 = Instance.new("TextLabel")
	icon3.Name = "Icon"
	icon3.Size = UDim2.new(0.205, 0, 0.519, 0)
	icon3.Position = UDim2.new(0.01, 0, 0.189, 0)
	icon3.BackgroundTransparency = 1
	icon3.Text = "??"
	icon3.TextScaled = true
	icon3.Font = Enum.Font.GothamBold
	icon3.Parent = navButton3
	local titleText3 = Instance.new("TextLabel")
	titleText3.Name = "TitleText"
	titleText3.Size = UDim2.new(0.727, 0, 0.283, 0)
	titleText3.Position = UDim2.new(0.273, 0, 0.189, 0)
	titleText3.BackgroundTransparency = 1
	titleText3.Text = "Gabung Lobi"
	titleText3.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText3.TextScaled = true
	titleText3.Font = Enum.Font.GothamBold
	titleText3.TextXAlignment = Enum.TextXAlignment.Left
	titleText3.Parent = navButton3
	local descText3 = Instance.new("TextLabel")
	descText3.Name = "DescText"
	descText3.Size = UDim2.new(0.727, 0, 0.189, 0)
	descText3.Position = UDim2.new(0.273, 0, 0.519, 0)
	descText3.BackgroundTransparency = 1
	descText3.Text = "Cari lobi atau masukkan kode."
	descText3.TextColor3 = Color3.fromRGB(148, 163, 184)
	descText3.TextScaled = true
	descText3.Font = Enum.Font.Gotham
	descText3.TextXAlignment = Enum.TextXAlignment.Left
	descText3.Parent = navButton3
	navButton3:SetAttribute("data-content-target", "join-options")
	navButtons["join-options"] = navButton3
	navButton3.MouseButton1Click:Connect(function()
		showContentPanel("join-options")
	end)
	navButton3.MouseEnter:Connect(function()
		TweenService:Create(navButton3, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end)
	navButton3.MouseLeave:Connect(function()
		TweenService:Create(navButton3, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end)

	-- Matchmaking Button
	local navButton4 = Instance.new("TextButton")
	navButton4.Name = "NavButton4"
	navButton4.Size = UDim2.new(1, -16, 0.16, 0)
	navButton4.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	navButton4.BackgroundTransparency = 0.3
	navButton4.BorderSizePixel = 0
	navButton4.AutoButtonColor = false
	navButton4.Parent = navContainer
	local navPadding4 = Instance.new("UIPadding")
	navPadding4.PaddingTop = UDim.new(0.08, 0)
	navPadding4.PaddingLeft = UDim.new(0.08, 0)
	navPadding4.PaddingRight = UDim.new(0.08, 0)
	navPadding4.PaddingBottom = UDim.new(0.08, 0)
	navPadding4.Parent = navButton4
	local navCorner4 = Instance.new("UICorner")
	navCorner4.CornerRadius = UDim.new(0, 8)
	navCorner4.Parent = navButton4
	local icon4 = Instance.new("TextLabel")
	icon4.Name = "Icon"
	icon4.Size = UDim2.new(0.205, 0, 0.519, 0)
	icon4.Position = UDim2.new(0.01, 0, 0.189, 0)
	icon4.BackgroundTransparency = 1
	icon4.Text = "??"
	icon4.TextScaled = true
	icon4.Font = Enum.Font.GothamBold
	icon4.Parent = navButton4
	local titleText4 = Instance.new("TextLabel")
	titleText4.Name = "TitleText"
	titleText4.Size = UDim2.new(0.727, 0, 0.283, 0)
	titleText4.Position = UDim2.new(0.273, 0, 0.189, 0)
	titleText4.BackgroundTransparency = 1
	titleText4.Text = "Matchmaking"
	titleText4.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleText4.TextScaled = true
	titleText4.Font = Enum.Font.GothamBold
	titleText4.TextXAlignment = Enum.TextXAlignment.Left
	titleText4.Parent = navButton4
	local descText4 = Instance.new("TextLabel")
	descText4.Name = "DescText"
	descText4.Size = UDim2.new(0.727, 0, 0.189, 0)
	descText4.Position = UDim2.new(0.273, 0, 0.519, 0)
	descText4.BackgroundTransparency = 1
	descText4.Text = "Cari lobi otomatis."
	descText4.TextColor3 = Color3.fromRGB(148, 163, 184)
	descText4.TextScaled = true
	descText4.Font = Enum.Font.Gotham
	descText4.TextXAlignment = Enum.TextXAlignment.Left
	descText4.Parent = navButton4
	navButton4:SetAttribute("data-content-target", "matchmaking-options")
	navButtons["matchmaking-options"] = navButton4
	navButton4.MouseButton1Click:Connect(function()
		showContentPanel("matchmaking-options")
	end)
	navButton4.MouseEnter:Connect(function()
		TweenService:Create(navButton4, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end)
	navButton4.MouseLeave:Connect(function()
		TweenService:Create(navButton4, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
	end)

	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.7, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.3, 0, 0, 0)
	rightPanel.BackgroundTransparency = 1
	rightPanel.Parent = container

	createContentPanels(rightPanel)
end

local function createPreGameLobby()
	local container = Instance.new("Frame")
	container.Name = "PreGameLobbyContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = gui.MainContainer
	screenContainers["pre-game-lobby"] = container

	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0.3, 0, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	leftPanel.BackgroundTransparency = 0.5
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = container

	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 12)
	leftCorner.Parent = leftPanel

	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Size = UDim2.new(0, 140, 0, 35)  -- Slightly larger
	backButton.Position = UDim2.new(0.05, 0, 0.05, 0)  -- Fixed positioning
	backButton.BackgroundTransparency = 1
	backButton.Text = "? Keluar Lobi"
	backButton.TextColor3 = Color3.fromRGB(148, 163, 184)
	backButton.TextScaled = true
	backButton.Font = Enum.Font.Gotham
	backButton.TextXAlignment = Enum.TextXAlignment.Left
	backButton.AutoButtonColor = false

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.10, 0)  -- Reduced padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.10, 0)
	padding.Parent = backButton

	backButton.Parent = leftPanel

	backButton.MouseEnter:Connect(function()
		backButton.TextColor3 = Color3.fromRGB(6, 182, 212)
	end)

	backButton.MouseLeave:Connect(function()
		backButton.TextColor3 = Color3.fromRGB(148, 163, 184)
	end)

	backButton.MouseButton1Click:Connect(function()
		leaveRoom()
	end)

	local roomTitle = Instance.new("TextLabel")
	roomTitle.Name = "RoomTitle"
	roomTitle.Size = UDim2.new(1, -0.04, 0, 50)  -- Using scale for width reduction
	roomTitle.Position = UDim2.new(0, 0.02, 0, 0.08)  -- Using scale for positioning
	roomTitle.BackgroundTransparency = 1
	roomTitle.Text = "Lobi Host"
	roomTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	roomTitle.TextScaled = true
	roomTitle.Font = Enum.Font.GothamBlack
	roomTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomTitle.Parent = leftPanel

	local roomInfoSection = Instance.new("Frame")
	roomInfoSection.Name = "RoomInfoSection"
	roomInfoSection.Size = UDim2.new(1, -0.04, 0, 200)  -- Using scale for width reduction
	roomInfoSection.Position = UDim2.new(0, 0.02, 0, 0.16)  -- Using scale for positioning
	roomInfoSection.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	roomInfoSection.BackgroundTransparency = 0.3
	roomInfoSection.BorderColor3 = Color3.fromRGB(51, 65, 85)
	roomInfoSection.BorderSizePixel = 1
	roomInfoSection.Parent = leftPanel

	local roomInfoCorner = Instance.new("UICorner")
	roomInfoCorner.CornerRadius = UDim.new(0, 12)
	roomInfoCorner.Parent = roomInfoSection

	local codeLabel = Instance.new("TextLabel")
	codeLabel.Name = "CodeLabel"
	codeLabel.Size = UDim2.new(1, -0.08, 0, 24)  -- Using scale for width reduction
	codeLabel.Position = UDim2.new(0, 0.04, 0, 0.04)  -- Using scale for positioning
	codeLabel.BackgroundTransparency = 1
	codeLabel.Text = "Kode Lobi: 12345"
	codeLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	codeLabel.TextScaled = true
	codeLabel.Font = Enum.Font.Gotham
	codeLabel.TextXAlignment = Enum.TextXAlignment.Left
	codeLabel.Parent = roomInfoSection

	local modeLabel = Instance.new("TextLabel")
	modeLabel.Name = "ModeLabel"
	modeLabel.Size = UDim2.new(1, -0.08, 0, 24)  -- Using scale for width reduction
	modeLabel.Position = UDim2.new(0, 0.04, 0, 0.2)  -- Using scale for positioning
	modeLabel.BackgroundTransparency = 1
	modeLabel.Text = "Mode Game: Story"
	modeLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	modeLabel.TextScaled = true
	modeLabel.Font = Enum.Font.Gotham
	modeLabel.TextXAlignment = Enum.TextXAlignment.Center
	modeLabel.Parent = roomInfoSection

	local difficultyLabel = Instance.new("TextLabel")
	difficultyLabel.Name = "DifficultyLabel"
	difficultyLabel.Size = UDim2.new(1, -0.08, 0, 24)  -- Using scale for width reduction
	difficultyLabel.Position = UDim2.new(0, 0.04, 0, 0.36)  -- Using scale for positioning
	difficultyLabel.BackgroundTransparency = 1
	difficultyLabel.Text = "Kesulitan: Hard"
	difficultyLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	difficultyLabel.TextScaled = true
	difficultyLabel.Font = Enum.Font.Gotham
	difficultyLabel.TextXAlignment = Enum.TextXAlignment.Left
	difficultyLabel.Parent = roomInfoSection

	local missionLabel = Instance.new("TextLabel")
	missionLabel.Name = "MissionLabel"
	missionLabel.Size = UDim2.new(1, -0.08, 0, 24)  -- Using scale for width reduction
	missionLabel.Position = UDim2.new(0, 0.04, 0, 0.52)  -- Using scale for positioning
	missionLabel.BackgroundTransparency = 1
	missionLabel.Text = "Misi: ACT 1: Village"
	missionLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	missionLabel.TextScaled = true
	missionLabel.Font = Enum.Font.Gotham
	missionLabel.TextXAlignment = Enum.TextXAlignment.Left
	missionLabel.Parent = roomInfoSection

	local hostControls = Instance.new("Frame")
	hostControls.Name = "HostControls"
	hostControls.Size = UDim2.new(1, -0.04, 0, 200)  -- Using scale for width reduction
	hostControls.Position = UDim2.new(0, 0.02, 1, -0.28)  -- Using scale for positioning
	hostControls.BackgroundTransparency = 1
	hostControls.Parent = leftPanel

	local startButton = Instance.new("TextButton")
	startButton.Name = "StartButton"
	startButton.Size = UDim2.new(1, -16, 0, 50)  -- Reduced height with margins
	startButton.Position = UDim2.new(0.02, 0, 0, 0)  -- Better positioning
	startButton.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	startButton.BorderSizePixel = 0
	startButton.Text = "MULAI GAME"
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.TextScaled = true
	startButton.Font = Enum.Font.GothamBlack
	startButton.AutoButtonColor = false

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.20, 0)  -- Increased padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.20, 0)
	padding.Parent = startButton

	startButton.Parent = hostControls

	local startCorner = Instance.new("UICorner")
	startCorner.CornerRadius = UDim.new(0, 8)
	startCorner.Parent = startButton

	startButton.MouseButton1Click:Connect(function()
		startGame()
	end)

	local clientControls = Instance.new("Frame")
	clientControls.Name = "ClientControls"
	clientControls.Size = UDim2.new(1, -0.04, 0, 200)  -- Using scale for width reduction
	clientControls.Position = UDim2.new(0, 0.02, 1, -0.28)  -- Using scale for positioning
	clientControls.BackgroundTransparency = 1
	clientControls.Visible = false
	clientControls.Parent = leftPanel

	local readyButton = Instance.new("TextButton")
	readyButton.Name = "ReadyButton"
	readyButton.Size = UDim2.new(1, -16, 0, 50)  -- Reduced height with margins
	readyButton.Position = UDim2.new(0.02, 0, 0, 0)  -- Better positioning
	readyButton.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	readyButton.BorderSizePixel = 0
	readyButton.Text = "SIAP"
	readyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	readyButton.TextScaled = true
	readyButton.Font = Enum.Font.GothamBlack
	readyButton.AutoButtonColor = false

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.20, 0)  -- Increased padding
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.20, 0)
	padding.Parent = readyButton

	readyButton.Parent = clientControls

	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, 8)
	readyCorner.Parent = readyButton

	readyButton.MouseButton1Click:Connect(function()
		toggleReady()
	end)

	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "RightPanel"
	rightPanel.Size = UDim2.new(0.7, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.3, 0, 0, 0)
	rightPanel.BackgroundTransparency = 1
	rightPanel.Parent = container

	local squadTitle = Instance.new("TextLabel")
	squadTitle.Name = "SquadTitle"
	squadTitle.Size = UDim2.new(1, -0.05, 0, 50)  -- Using scale for width reduction
	squadTitle.Position = UDim2.new(0, 0.03, 0, 0.03)  -- Using scale for positioning
	squadTitle.BackgroundTransparency = 1
	squadTitle.Text = "SKUAD (4/4)"
	squadTitle.TextColor3 = Color3.fromRGB(203, 213, 225)
	squadTitle.TextScaled = true
	squadTitle.Font = Enum.Font.GothamBold
	squadTitle.TextXAlignment = Enum.TextXAlignment.Left
	squadTitle.Parent = rightPanel

	local playersListContainer = Instance.new("Frame")
	playersListContainer.Name = "PlayersListContainer"
	playersListContainer.Size = UDim2.new(1, -0.05, 1, -0.12)  -- Using scale for dimensions
	playersListContainer.Position = UDim2.new(0, 0.03, 0, 0.11)  -- Using scale for positioning
	playersListContainer.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	playersListContainer.BackgroundTransparency = 0.3
	playersListContainer.BorderColor3 = Color3.fromRGB(51, 65, 85)
	playersListContainer.BorderSizePixel = 1
	playersListContainer.Parent = rightPanel

	local playersCorner = Instance.new("UICorner")
	playersCorner.CornerRadius = UDim.new(0, 12)
	playersCorner.Parent = playersListContainer

	local playersScrollFrame = Instance.new("ScrollingFrame")
	playersScrollFrame.Name = "PlayersScrollFrame"
	playersScrollFrame.Size = UDim2.new(1, -0.01, 1, -0.01)  -- Using scale for dimensions
	playersScrollFrame.Position = UDim2.new(0, 0.005, 0, 0.005)  -- Using scale for positioning
	playersScrollFrame.BackgroundTransparency = 1
	playersScrollFrame.ScrollBarThickness = 8
	playersScrollFrame.BorderSizePixel = 0
	playersScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	playersScrollFrame.Parent = playersListContainer

	local playersListLayout = Instance.new("UIListLayout")
	playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersListLayout.Padding = UDim.new(0, 8)
	playersListLayout.Parent = playersScrollFrame
end

local function createMatchmakingWait()
	local container = Instance.new("Frame")
	container.Name = "MatchmakingWaitContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = gui.MainContainer
	screenContainers["matchmaking-wait"] = container

	local centerFrame = Instance.new("Frame")
	centerFrame.Name = "CenterFrame"
	centerFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
	centerFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
	centerFrame.BackgroundTransparency = 1
	centerFrame.Parent = container

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.2, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "MENCARI LOBI..."
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = centerFrame

	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, 0, 0.1, 0)
	statusText.Position = UDim2.new(0, 0, 0.25, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Mencari lobi untuk 4 pemain, Mode Story, Kesulitan Easy..."
	statusText.TextColor3 = Color3.fromRGB(148, 163, 184)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.Gotham
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Parent = centerFrame

	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0.4, 0, 0.15, 0)
	cancelButton.AnchorPoint = Vector2.new(0.5, 0)
	cancelButton.Position = UDim2.new(0.5, 0, 0.8, 0)
	cancelButton.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "BATALKAN"
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.TextScaled = true
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.AutoButtonColor = false

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.15, 0)
	padding.PaddingLeft = UDim.new(0.10, 0)
	padding.PaddingRight = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.15, 0)
	padding.Parent = cancelButton

	cancelButton.Parent = centerFrame

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelButton

	cancelButton.MouseButton1Click:Connect(function()
		cancelMatchmaking()
	end)
end

local function createTeleporting()
	local container = Instance.new("Frame")
	container.Name = "TeleportingContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = gui.MainContainer
	screenContainers["teleporting"] = container

	local centerFrame = Instance.new("Frame")
	centerFrame.Name = "CenterFrame"
	centerFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
	centerFrame.Position = UDim2.new(0.1, 0, 0.2, 0)
	centerFrame.BackgroundTransparency = 1
	centerFrame.Parent = container

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.2, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "MEMULAI MISI..."
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.Parent = centerFrame

	local statusText = Instance.new("TextLabel")
	statusText.Name = "StatusText"
	statusText.Size = UDim2.new(1, 0, 0.1, 0)
	statusText.Position = UDim2.new(0, 0, 0.25, 0)
	statusText.BackgroundTransparency = 1
	statusText.Text = "Menyiapkan server. Anda akan diteleportasi sebentar lagi."
	statusText.TextColor3 = Color3.fromRGB(148, 163, 184)
	statusText.TextScaled = true
	statusText.Font = Enum.Font.Gotham
	statusText.TextXAlignment = Enum.TextXAlignment.Center
	statusText.Parent = centerFrame
end

-- Server Event Handlers (Only definitions, no calls)
local function setupServerEventHandlers()
	lobbyRemote.OnClientEvent:Connect(function(action, data)
		print("Received from server:", action, data)

		if action == "roomCreated" then
			if data.success then
				print("Room created successfully with code:", data.roomCode)
				showScreenContainer("pre-game-lobby")
			else
				print("Failed to create room")
			end
		elseif action == "joinSuccess" then
			print("Joined room successfully")
			showScreenContainer("pre-game-lobby")
		elseif action == "joinFailed" then
			print("Failed to join room:", data.reason)
		elseif action == "roomUpdate" then
			updateRoomInfo(data)
		elseif action == "publicRoomsUpdate" then
			updatePublicRooms(data)
		elseif action == "matchmakingStarted" then
			print("Matchmaking started")
			showScreenContainer("matchmaking-wait")
		elseif action == "matchFound" then
			print("Match found! Room ID:", data.roomId)
			showScreenContainer("pre-game-lobby")
		elseif action == "matchmakingCancelled" then
			print("Matchmaking cancelled")
			showScreenContainer("main-hub", "matchmaking-options")
		elseif action == "leftRoomSuccess" then
			print("Left room successfully")
			showScreenContainer("main-hub", "solo-options")
		elseif action == "countdownUpdate" then
			showCountdownUpdate(data.value)
		elseif action == "countdownCancelled" then
			hideCountdown()
		end
	end)
end

-- Initialization Function (Only definition, no calls)
local function initialize()
	local mainContainer = createGUI()
	createCloseButton(mainContainer)
	createMainHub()
	createPreGameLobby()
	createMatchmakingWait()
	createTeleporting()
	lobbyRemote:FireServer("getPublicRooms")

	-- Start with UI hidden - only show when proximity prompt is triggered
	hideLobbyUI()

	print("LobbyRoomUI.lua initialized successfully")
end

--[[
START EXECUTION - NOW WE CAN CALL FUNCTIONS
]]

-- Setup event handlers
setupServerEventHandlers()

-- Start the initialization
if playerGui.Parent then
	initialize()
else
	playerGui.AncestryChanged:Connect(function()
		if playerGui.Parent then
			initialize()
		end
	end)
end

-- Register Proximity Interaction via Module
state.proximityHandler = ProximityUIHandler.Register({
	name = "LobbyRoom",
	partName = "LobbyRoom",
	onToggle = function(isOpen)
		if isOpen then
			showLobbyUI()
		else
			hideLobbyUI()
		end
	end
})
