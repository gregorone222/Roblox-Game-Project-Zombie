-- LeaderboardClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/LeaderboardClient.lua
-- Script Place: Lobby
-- Theme: Industrial / Digital Terminal (Overhauled)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local avatarCache = {}

-- Wait for necessary modules and remote objects
local LeaderboardConfig = require(ReplicatedStorage:WaitForChild("LeaderboardConfig"))
local remoteFolder = ReplicatedStorage:WaitForChild("RemoteFunctions")
local globalCountdownValue = remoteFolder:WaitForChild("LeaderboardCountdown")

local leaderboardUpdaters = {}
local countdownLabels = {}

-- ============================================================================
-- THEME CONFIG
-- ============================================================================
local THEME = {
	FrameColor = Color3.fromRGB(15, 20, 15),
	HeaderColor = Color3.fromRGB(0, 40, 0),
	TextColor = Color3.fromRGB(50, 255, 100), -- Toxic Green
	AltTextColor = Color3.fromRGB(200, 200, 200),
	StrokeColor = Color3.fromRGB(30, 80, 40),
	HighlightColor = Color3.fromRGB(200, 150, 0), -- Amber
	FontHeader = Enum.Font.Michroma,
	FontData = Enum.Font.Code,
}

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function createLeaderboardUI(part, title, face)
	if part:FindFirstChild("LeaderboardGui") then
		part.LeaderboardGui:Destroy()
	end

	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.AlwaysOnTop = true -- Changed to true for clarity on screens
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0.2 -- Slightly affected by light, but self-lit
	gui.Parent = part

	-- Main Container (Screen Background)
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = THEME.FrameColor
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	-- Scanline Effect (Tiled Image)
	local scanline = Instance.new("ImageLabel")
	scanline.Size = UDim2.new(1, 0, 1, 0)
	scanline.BackgroundTransparency = 1
	scanline.Image = "rbxassetid://6071575925" -- Generic noise/scanline texture
	scanline.ImageTransparency = 0.9
	scanline.ScaleType = Enum.ScaleType.Tile
	scanline.TileSize = UDim2.new(0, 50, 0, 50)
	scanline.Parent = mainFrame

	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = THEME.StrokeColor
	stroke.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0.15, 0)
	header.BackgroundColor3 = THEME.HeaderColor
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	-- Title Text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.Font = THEME.FontHeader
	titleLabel.TextColor3 = THEME.TextColor
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	-- Decorative Header Element
	local decor = Instance.new("Frame")
	decor.Size = UDim2.new(0.3, 0, 0.1, 0)
	decor.Position = UDim2.new(0.7, 0, 0.9, 0)
	decor.BackgroundColor3 = THEME.TextColor
	decor.BorderSizePixel = 0
	decor.Parent = header

	-- List Container
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(0.95, 0, 0.7, 0)
	listFrame.Position = UDim2.new(0.025, 0, 0.18, 0)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = THEME.TextColor
	listFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame

	-- Footer Status
	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(1, 0, 0.1, 0)
	footer.Position = UDim2.new(0, 0, 0.9, 0)
	footer.BackgroundColor3 = Color3.new(0,0,0)
	footer.BackgroundTransparency = 0.5
	footer.BorderSizePixel = 0
	footer.Parent = mainFrame

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.Size = UDim2.new(0.4, 0, 1, 0)
	countdownLabel.Position = UDim2.new(0.025, 0, 0, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Font = THEME.FontData
	countdownLabel.TextColor3 = THEME.AltTextColor
	countdownLabel.TextScaled = true
	countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
	countdownLabel.Text = "SYNCING..."
	countdownLabel.Parent = footer
	table.insert(countdownLabels, countdownLabel)

	local playerRankLabel = Instance.new("TextLabel")
	playerRankLabel.Name = "PlayerRankLabel"
	playerRankLabel.Size = UDim2.new(0.5, 0, 1, 0)
	playerRankLabel.Position = UDim2.new(0.475, 0, 0, 0)
	playerRankLabel.BackgroundTransparency = 1
	playerRankLabel.Font = THEME.FontData
	playerRankLabel.TextColor3 = THEME.HighlightColor
	playerRankLabel.TextScaled = true
	playerRankLabel.TextXAlignment = Enum.TextXAlignment.Right
	playerRankLabel.Text = ""
	playerRankLabel.Parent = footer

	-- Row Template
	local rowTemplate = Instance.new("Frame")
	rowTemplate.Name = "RowTemplate"
	rowTemplate.Size = UDim2.new(1, 0, 0, 40)
	rowTemplate.BackgroundColor3 = Color3.new(0,0,0)
	rowTemplate.BackgroundTransparency = 0.6
	rowTemplate.BorderSizePixel = 0
	rowTemplate.Visible = false
	rowTemplate.Parent = listFrame

	-- Rank Box
	local rankFrame = Instance.new("Frame")
	rankFrame.Name = "RankBox"
	rankFrame.Size = UDim2.new(0.15, 0, 1, 0)
	rankFrame.BackgroundTransparency = 1
	rankFrame.Parent = rowTemplate

	local rankTxt = Instance.new("TextLabel")
	rankTxt.Name = "Rank"
	rankTxt.Size = UDim2.new(1, -5, 1, 0)
	rankTxt.Position = UDim2.new(0, 5, 0, 0)
	rankTxt.BackgroundTransparency = 1
	rankTxt.Text = "#1"
	rankTxt.TextColor3 = THEME.TextColor
	rankTxt.Font = THEME.FontHeader
	rankTxt.TextScaled = true
	rankTxt.TextXAlignment = Enum.TextXAlignment.Left
	rankTxt.Parent = rankFrame

	-- Avatar
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Position = UDim2.new(0.16, 0, 0.1, 0)
	avatarImage.Size = UDim2.new(0.1, 0, 0.8, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ScaleType = Enum.ScaleType.Fit
	avatarImage.Parent = rowTemplate

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Username"
	nameLabel.Position = UDim2.new(0.28, 0, 0, 0)
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = THEME.FontData
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = rowTemplate

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
	valueLabel.Size = UDim2.new(0.28, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = THEME.FontData
	valueLabel.TextColor3 = THEME.HighlightColor
	valueLabel.TextScaled = true
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = rowTemplate

	-- Error State
	local errorLabel = Instance.new("TextLabel")
	errorLabel.Size = UDim2.new(1, 0, 0.5, 0)
	errorLabel.Position = UDim2.new(0, 0, 0.25, 0)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Font = THEME.FontData
	errorLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	errorLabel.Text = "CONNECTION ERROR // RETRYING"
	errorLabel.TextScaled = true
	errorLabel.Visible = false
	errorLabel.Parent = mainFrame

	return listFrame, rowTemplate, errorLabel, playerRankLabel
end


-- ============================================================================
-- INITIALIZATION
-- ============================================================================
-- Use a longer timeout (20s) to allow for Map Loading and Replication
local lbFolder = Workspace:WaitForChild("Leaderboard", 20)

if not lbFolder then
	-- Gracefully exit if not found (e.g. in game map)
	print("LeaderboardClient: Workspace.Leaderboard not found within 20s. Script disabled (Game Mode?).")
else
	for key, config in pairs(LeaderboardConfig) do
		-- Safe check for part with WaitForChild to allow for replication latency
		local leaderboardPart = lbFolder:WaitForChild(config.PartName, 10)

		if not leaderboardPart then
			-- Warn but don't error, just skip this specific board
			warn("LeaderboardClient: Part '" .. config.PartName .. "' not found in Leaderboard folder after 10s.")
			continue
		end

		local functionName = "GetLeaderboard_" .. key
		local getLeaderboardFunction = remoteFolder:WaitForChild(functionName, 10)

		if not getLeaderboardFunction then
			warn("LeaderboardClient: RemoteFunction " .. functionName .. " not found.")
			continue
		end

		local listFrame, rowTemplate, errorLabel, playerRankLabel = createLeaderboardUI(leaderboardPart, config.Title, config.Face)

		-- Update Function
		local function updateThisLeaderboard()
			local success, result = pcall(function()
				return getLeaderboardFunction:InvokeServer()
			end)

			if not success or not result then
				listFrame.Visible = false
				playerRankLabel.Visible = false
				errorLabel.Visible = true
				return
			end

			listFrame.Visible = true
			playerRankLabel.Visible = true
			errorLabel.Visible = false

			local newPlayerRanks = result.TopPlayers or {}

			-- Clear existing rows
			for _, child in ipairs(listFrame:GetChildren()) do
				if child.Name == "PlayerRow" then child:Destroy() end
			end

			for i, playerData in ipairs(newPlayerRanks) do
				if not playerData then break end

				local newRow = rowTemplate:Clone()
				newRow.Name = "PlayerRow"
				newRow.LayoutOrder = i
				newRow.Visible = true

				newRow.RankBox.Rank.Text = string.format("%02d", playerData.Rank)
				newRow.Username.Text = playerData.Username
				newRow.Value.Text = config.ValuePrefix .. tostring(playerData[config.ValueKey])

				if playerData.UserId == localPlayer.UserId then
					-- Highlight Self
					newRow.BackgroundColor3 = THEME.HighlightColor
					newRow.BackgroundTransparency = 0.8
					newRow.Username.TextColor3 = THEME.HighlightColor
				else
					-- Alternating colors
					if i % 2 == 0 then
						newRow.BackgroundTransparency = 0.95
					else
						newRow.BackgroundTransparency = 0.85
					end
				end

				-- Avatar Loading
				if avatarCache[playerData.UserId] then
					newRow.Avatar.Image = avatarCache[playerData.UserId]
				else
					task.spawn(function()
						local thumbSuccess, thumbContent, isReady = pcall(function()
							return Players:GetUserThumbnailAsync(playerData.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
						end)
						if thumbSuccess and isReady then
							avatarCache[playerData.UserId] = thumbContent
							if newRow.Parent then newRow.Avatar.Image = thumbContent end
						end
					end)
				end
				newRow.Parent = listFrame
			end

			local playerInfo = result.PlayerInfo
			if playerInfo and playerInfo.Score then
				if playerInfo.Rank then
					playerRankLabel.Text = string.format("RANK: #%d // %s%s", playerInfo.Rank, config.ValuePrefix, playerInfo.Score)
				else
					playerRankLabel.Text = string.format("UNRANKED // %s%s", config.ValuePrefix, playerInfo.Score)
				end
			else
				playerRankLabel.Text = "NO DATA"
			end
		end

		table.insert(leaderboardUpdaters, updateThisLeaderboard)
		-- Initial update
		task.spawn(updateThisLeaderboard)
	end
end

-- Global Timer
globalCountdownValue.Changed:Connect(function(newValue)
	local text = string.format("REFRESH: %02d", newValue)
	for _, label in ipairs(countdownLabels) do
		label.Text = text
	end

	if newValue == 60 then
		for _, updater in ipairs(leaderboardUpdaters) do
			task.spawn(updater)
		end
	end
end)

print("LeaderboardClient.lua: Terminal UI Loaded.")