-- GlobalMissionClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/GlobalMissionClient.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Konfigurasi Warna & Gaya (Mengikuti Prototype Tailwind CSS)
local THEME = {
	Background = Color3.fromRGB(15, 23, 42),    -- slate-900
	Panel      = Color3.fromRGB(30, 41, 59),    -- slate-800
	Border     = Color3.fromRGB(51, 65, 85),    -- slate-700
	TextMain   = Color3.fromRGB(226, 232, 240), -- slate-200
	TextDim    = Color3.fromRGB(148, 163, 184), -- slate-400
	Primary    = Color3.fromRGB(79, 70, 229),   -- indigo-600
	PrimaryHover = Color3.fromRGB(67, 56, 202), -- indigo-700
	Success    = Color3.fromRGB(34, 197, 94),   -- green-500
	Warning    = Color3.fromRGB(250, 204, 21),  -- yellow-400
	Error      = Color3.fromRGB(239, 68, 68),   -- red-500
}

-- Referensi RemoteFunctions
local remoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local getGlobalMissionState = remoteFunctions:WaitForChild("GetGlobalMissionState")
local claimGlobalMissionReward = remoteFunctions:WaitForChild("ClaimGlobalMissionReward")
local getGlobalMissionLeaderboard = remoteFunctions:WaitForChild("GetGlobalMissionLeaderboard")
local getPlayerGlobalMissionRank = remoteFunctions:WaitForChild("GetPlayerGlobalMissionRank")

-- Variabel State
local updateLoopConnection = nil
local currentTab = "Active" -- "Active" or "Claim"

-- =============================================================================
-- FUNGSI UTILITAS UI
-- =============================================================================

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Border
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createTextLabel(props)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = THEME.TextMain
	label.TextSize = 14
	for k, v in pairs(props) do
		label[k] = v
	end
	return label
end

local function formatNumber(num)
	local formatted = tostring(math.floor(num))
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function formatTime(seconds)
	if seconds < 0 then seconds = 0 end
	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	return string.format("Sisa Waktu: %dh %dj %dm", days, hours, minutes)
end

-- =============================================================================
-- KONSTRUKSI UI (SURFACE GUI)
-- =============================================================================

-- Mencari part target
local boardPart = Workspace:WaitForChild("Leaderboard"):WaitForChild("GlobalMission")

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Name = "GlobalMissionDisplay"
surfaceGui.Face = Enum.NormalId.Front -- Sesuaikan dengan part
surfaceGui.CanvasSize = Vector2.new(900, 600)
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
surfaceGui.ResetOnSpawn = false
surfaceGui.Adornee = boardPart
surfaceGui.Parent = playerGui -- Simpan di PlayerGui agar input lokal bekerja

-- Main Container (Tanpa Overlay/Modal)
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.Size = UDim2.fromScale(1, 1)
mainContainer.BackgroundColor3 = THEME.Background
mainContainer.Parent = surfaceGui
createStroke(mainContainer, THEME.Border, 4)

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundColor3 = THEME.Panel
header.Parent = mainContainer

local titleLabel = createTextLabel({
	Text = "MISI KOMUNITAS",
	TextSize = 28,
	Font = Enum.Font.GothamBlack,
	Size = UDim2.new(1, 0, 1, 0), -- Full width since no close button
	Position = UDim2.new(0, 0, 0, 0), -- Reset position to 0
	TextXAlignment = Enum.TextXAlignment.Center, -- Centered
	TextColor3 = THEME.TextMain,
	Parent = header,
	RichText = true
})
titleLabel.Text = '<font color="rgb(250,204,21)">MISI</font> KOMUNITAS'

-- Content Area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -48, 1, -94) -- 70 header + 24 padding
contentArea.Position = UDim2.new(0, 24, 0, 82)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainContainer

-- Tabs
local tabContainer = Instance.new("Frame")
tabContainer.Name = "TabContainer"
tabContainer.Size = UDim2.new(1, 0, 0, 50)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = contentArea

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 12)
tabLayout.Parent = tabContainer

local function createTabButton(name, text)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.5, -6, 1, 0)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.BackgroundColor3 = THEME.Panel
	btn.TextColor3 = THEME.TextDim
	btn.AutoButtonColor = false
	btn.Parent = tabContainer
	createCorner(btn, 8)
	return btn
end

local tabActive = createTabButton("TabActive", "Misi Aktif")
local tabClaim = createTabButton("TabClaim", "Hadiah Selesai")

-- Panels
local panelContainer = Instance.new("Frame")
panelContainer.Name = "PanelContainer"
panelContainer.Size = UDim2.new(1, 0, 1, -62)
panelContainer.Position = UDim2.new(0, 0, 0, 62)
panelContainer.BackgroundTransparency = 1
panelContainer.ClipsDescendants = true
panelContainer.Parent = contentArea

-- =============================================================================
-- PANEL 1: ACTIVE MISSION
-- =============================================================================
local activePanel = Instance.new("Frame")
activePanel.Name = "ActivePanel"
activePanel.Size = UDim2.fromScale(1, 1)
activePanel.BackgroundTransparency = 1
activePanel.Visible = true
activePanel.Parent = panelContainer
local activeLayout = Instance.new("UIListLayout")
activeLayout.SortOrder = Enum.SortOrder.LayoutOrder
activeLayout.Padding = UDim.new(0, 20)
activeLayout.Parent = activePanel

-- Section: Global Progress
local globalSection = Instance.new("Frame")
globalSection.LayoutOrder = 1
globalSection.Size = UDim2.new(1, 0, 0, 140)
globalSection.BackgroundColor3 = THEME.Panel
globalSection.Parent = activePanel
createCorner(globalSection, 8)
createStroke(globalSection, THEME.Border, 1)

local globalPad = Instance.new("UIPadding")
globalPad.PaddingTop = UDim.new(0, 20)
globalPad.PaddingBottom = UDim.new(0, 20)
globalPad.PaddingLeft = UDim.new(0, 20)
globalPad.PaddingRight = UDim.new(0, 20)
globalPad.Parent = globalSection

local missionDescLabel = createTextLabel({
	Name = "MissionDescription",
	Text = "Memuat Misi...",
	TextSize = 20,
	Font = Enum.Font.GothamBold,
	TextColor3 = THEME.Warning,
	Size = UDim2.new(1, 0, 0, 25),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = globalSection
})

local labelProgressTitle = createTextLabel({
	Text = "PROGRES GLOBAL",
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = globalSection
})

local progressBarBg = Instance.new("Frame")
progressBarBg.Size = UDim2.new(1, 0, 0, 30)
progressBarBg.Position = UDim2.new(0, 0, 0, 55)
progressBarBg.BackgroundColor3 = THEME.Background
progressBarBg.Parent = globalSection
createCorner(progressBarBg, 15)
createStroke(progressBarBg, THEME.Border, 1)

local progressBarFill = Instance.new("Frame")
progressBarFill.Name = "Fill"
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.BackgroundColor3 = THEME.Success
progressBarFill.Parent = progressBarBg
createCorner(progressBarFill, 15)

local progressBarText = createTextLabel({
	Text = "0%",
	Size = UDim2.fromScale(1, 1),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextStrokeTransparency = 0.8,
	Parent = progressBarFill
})

local progressValuesLabel = createTextLabel({
	Name = "ProgressValues",
	Text = "0 / 0",
	TextColor3 = THEME.TextMain,
	Size = UDim2.new(0.5, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 90),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = globalSection
})

local countdownLabel = createTextLabel({
	Name = "Countdown",
	Text = "Sisa Waktu: ...",
	TextColor3 = THEME.Error,
	Size = UDim2.new(0.5, 0, 0, 20),
	Position = UDim2.new(0.5, 0, 0, 90),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = globalSection
})


-- Grid Container (Bottom Half)
local gridFrame = Instance.new("Frame")
gridFrame.LayoutOrder = 2
gridFrame.Size = UDim2.new(1, 0, 0, 300)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = activePanel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.485, 0, 1, 0) -- Roughly half
gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 0)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = gridFrame

-- Left Column: Player Contribution & Tiers
local leftCol = Instance.new("Frame")
leftCol.Name = "LeftCol"
leftCol.BackgroundColor3 = THEME.Panel
leftCol.Parent = gridFrame
createCorner(leftCol, 8)
createStroke(leftCol, THEME.Border, 1)

local leftPad = Instance.new("UIPadding")
leftPad.PaddingTop = UDim.new(0, 20)
leftPad.PaddingBottom = UDim.new(0, 20)
leftPad.PaddingLeft = UDim.new(0, 20)
leftPad.PaddingRight = UDim.new(0, 20)
leftPad.Parent = leftCol

createTextLabel({
	Text = "Kontribusi Anda",
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Size = UDim2.new(1, 0, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = leftCol
})

local myContribValue = createTextLabel({
	Name = "MyContribValue",
	Text = "0",
	TextSize = 32,
	Font = Enum.Font.GothamBlack,
	TextColor3 = THEME.Primary,
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 0, 25),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = leftCol
})

local tierHeader = createTextLabel({
	Text = "Tingkat Hadiah",
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0, 80),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = leftCol
})

local tierContainer = Instance.new("ScrollingFrame")
tierContainer.Name = "TierList"
tierContainer.Size = UDim2.new(1, 0, 1, -110)
tierContainer.Position = UDim2.new(0, 0, 0, 110)
tierContainer.BackgroundTransparency = 1
tierContainer.ScrollBarThickness = 4
tierContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
tierContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
tierContainer.Parent = leftCol
local tierLayout = Instance.new("UIListLayout")
tierLayout.Padding = UDim.new(0, 8)
tierLayout.SortOrder = Enum.SortOrder.LayoutOrder
tierLayout.Parent = tierContainer

-- Right Column: Leaderboard
local rightCol = Instance.new("Frame")
rightCol.Name = "RightCol"
rightCol.BackgroundColor3 = THEME.Panel
rightCol.Parent = gridFrame
createCorner(rightCol, 8)
createStroke(rightCol, THEME.Border, 1)

local rightPad = Instance.new("UIPadding")
rightPad.PaddingTop = UDim.new(0, 20)
rightPad.PaddingBottom = UDim.new(0, 20)
rightPad.PaddingLeft = UDim.new(0, 20)
rightPad.PaddingRight = UDim.new(0, 20)
rightPad.Parent = rightCol

createTextLabel({
	Text = "Kontributor Teratas",
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Size = UDim2.new(1, 0, 0, 20),
	TextXAlignment = Enum.TextXAlignment.Center,
	Parent = rightCol
})

local lbContainer = Instance.new("ScrollingFrame")
lbContainer.Name = "LeaderboardList"
lbContainer.Size = UDim2.new(1, 0, 1, -40)
lbContainer.Position = UDim2.new(0, 0, 0, 40)
lbContainer.BackgroundTransparency = 1
lbContainer.ScrollBarThickness = 4
lbContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
lbContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
lbContainer.Parent = rightCol
local lbLayout = Instance.new("UIListLayout")
lbLayout.Padding = UDim.new(0, 4)
lbLayout.SortOrder = Enum.SortOrder.LayoutOrder
lbLayout.Parent = lbContainer

-- =============================================================================
-- PANEL 2: CLAIM REWARD
-- =============================================================================
local claimPanel = Instance.new("Frame")
claimPanel.Name = "ClaimPanel"
claimPanel.Size = UDim2.fromScale(1, 1)
claimPanel.BackgroundTransparency = 1
claimPanel.Visible = false
claimPanel.Parent = panelContainer

local claimCenterBox = Instance.new("Frame")
claimCenterBox.Size = UDim2.new(0.7, 0, 0.8, 0)
claimCenterBox.Position = UDim2.fromScale(0.15, 0.1)
claimCenterBox.BackgroundColor3 = THEME.Panel
claimCenterBox.Parent = claimPanel
createCorner(claimCenterBox, 12)
createStroke(claimCenterBox, THEME.Border, 1)

local claimPad = Instance.new("UIPadding")
claimPad.PaddingTop = UDim.new(0, 30)
claimPad.PaddingBottom = UDim.new(0, 30)
claimPad.PaddingLeft = UDim.new(0, 30)
claimPad.PaddingRight = UDim.new(0, 30)
claimPad.Parent = claimCenterBox

local claimTitle = createTextLabel({
	Name = "ClaimTitle",
	Text = "Memeriksa...",
	TextSize = 24,
	Font = Enum.Font.GothamBold,
	Size = UDim2.new(1, 0, 0, 30),
	Parent = claimCenterBox
})

local claimDesc = createTextLabel({
	Name = "ClaimDesc",
	Text = "...",
	TextSize = 16,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 50),
	Position = UDim2.new(0, 0, 0, 40),
	TextWrapped = true,
	Parent = claimCenterBox
})

local claimInfoBox = Instance.new("Frame")
claimInfoBox.Name = "InfoBox"
claimInfoBox.Size = UDim2.new(1, 0, 0, 120)
claimInfoBox.Position = UDim2.new(0, 0, 0.4, 0)
claimInfoBox.BackgroundColor3 = THEME.Background
claimInfoBox.Parent = claimCenterBox
createCorner(claimInfoBox, 8)

local prevContribLabel = createTextLabel({
	Text = "KONTRIBUSI ANDA",
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0.1, 0),
	Parent = claimInfoBox
})
local prevContribValue = createTextLabel({
	Name = "PrevContribValue",
	Text = "0",
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	TextColor3 = THEME.Primary,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0.25, 0),
	Parent = claimInfoBox
})

local prevRewardLabel = createTextLabel({
	Text = "HADIAH",
	TextSize = 12,
	TextColor3 = THEME.TextDim,
	Size = UDim2.new(1, 0, 0, 20),
	Position = UDim2.new(0, 0, 0.55, 0),
	Parent = claimInfoBox
})
local prevRewardValue = createTextLabel({
	Name = "PrevRewardValue",
	Text = "-",
	TextSize = 24,
	Font = Enum.Font.GothamBlack,
	TextColor3 = THEME.Warning,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.new(0, 0, 0.7, 0),
	Parent = claimInfoBox
})

local actionClaimButton = Instance.new("TextButton")
actionClaimButton.Name = "ActionClaimButton"
actionClaimButton.Size = UDim2.new(1, 0, 0, 60)
actionClaimButton.Position = UDim2.new(0, 0, 1, -60)
actionClaimButton.Text = "KLAIM HADIAH"
actionClaimButton.Font = Enum.Font.GothamBlack
actionClaimButton.TextSize = 20
actionClaimButton.TextColor3 = Color3.new(1, 1, 1)
actionClaimButton.BackgroundColor3 = THEME.Success
actionClaimButton.Parent = claimCenterBox
createCorner(actionClaimButton, 8)

-- =============================================================================
-- LOGIKA APLIKASI
-- =============================================================================

local function switchTab(tabName)
	currentTab = tabName
	if tabName == "Active" then
		tabActive.BackgroundColor3 = THEME.Primary
		tabActive.TextColor3 = Color3.new(1, 1, 1)
		tabClaim.BackgroundColor3 = THEME.Panel
		tabClaim.TextColor3 = THEME.TextDim
		activePanel.Visible = true
		claimPanel.Visible = false
	else
		tabActive.BackgroundColor3 = THEME.Panel
		tabActive.TextColor3 = THEME.TextDim
		tabClaim.BackgroundColor3 = THEME.Primary
		tabClaim.TextColor3 = Color3.new(1, 1, 1)
		activePanel.Visible = false
		claimPanel.Visible = true
	end
end

local function clearList(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function updateActiveMissionUI(state)
	if not state then return end

	-- Description & Stats
	missionDescLabel.Text = state.Description or "Tidak ada misi aktif."
	local progVal = state.GlobalProgress or 0
	local targetVal = state.GlobalTarget or 1
	local pct = math.clamp(progVal / targetVal, 0, 1)

	progressValuesLabel.Text = string.format("%s / %s", formatNumber(progVal), formatNumber(targetVal))
	progressBarText.Text = string.format("%d%%", math.floor(pct * 100))

	TweenService:Create(progressBarFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = UDim2.new(pct, 0, 1, 0) }):Play()

	local timeLeft = (state.EndTime or 0) - os.time()
	countdownLabel.Text = formatTime(timeLeft)

	-- Player Contribution
	local myContrib = state.PlayerContribution or 0
	myContribValue.Text = formatNumber(myContrib)

	-- Reward Tiers
	clearList(tierContainer)
	local tiers = state.RewardTiers or {}
	-- Sort tiers just in case
	table.sort(tiers, function(a,b) return a.Contribution < b.Contribution end)

	for _, tier in ipairs(tiers) do
		local achieved = myContrib >= tier.Contribution

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = THEME.Background
		row.BackgroundTransparency = achieved and 0 or 0.5
		row.Parent = tierContainer
		createCorner(row, 6)
		if achieved then createStroke(row, THEME.Success, 1) end

		local icon = createTextLabel({
			Text = achieved and "?" or "??",
			Size = UDim2.new(0, 30, 1, 0),
			TextSize = 18,
			Parent = row
		})

		local text = createTextLabel({
			Text = "Kontribusi: " .. formatNumber(tier.Contribution),
			Size = UDim2.new(0.5, 0, 1, 0),
			Position = UDim2.new(0, 35, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = achieved and THEME.Success or THEME.TextDim,
			Parent = row
		})

		local rewardTxt = createTextLabel({
			Text = formatNumber(tier.Reward.Value) .. " " .. (tier.Reward.Type == "MissionPoints" and "MP" or tier.Reward.Type),
			Size = UDim2.new(0.4, 0, 1, 0),
			Position = UDim2.new(0.6, -10, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = achieved and THEME.Warning or THEME.TextDim,
			Font = Enum.Font.GothamBold,
			Parent = row
		})
	end
end

local function updateLeaderboardUI()
	local success, data = pcall(function() return getGlobalMissionLeaderboard:InvokeServer() end)
	if not success or not data then return end

	clearList(lbContainer)

	-- Get rank
	local sRank, myRank = pcall(function() return getPlayerGlobalMissionRank:InvokeServer() end)

	for i, entry in ipairs(data) do
		local isMe = (entry.Name == player.Name) -- Simplification, better check ID if available

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 36)
		row.BackgroundColor3 = isMe and THEME.Primary or THEME.Background
		row.Parent = lbContainer
		createCorner(row, 6)

		local rankColor = THEME.TextDim
		if entry.Rank == 1 then rankColor = THEME.Warning end
		if entry.Rank == 2 then rankColor = Color3.fromRGB(192, 192, 192) end
		if entry.Rank == 3 then rankColor = Color3.fromRGB(205, 127, 50) end
		if isMe then rankColor = THEME.Warning end

		createTextLabel({
			Text = "#" .. entry.Rank,
			TextColor3 = rankColor,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(0, 30, 1, 0),
			Parent = row
		})

		createTextLabel({
			Text = entry.Name,
			TextColor3 = isMe and Color3.new(1,1,1) or THEME.TextMain,
			Size = UDim2.new(0.6, 0, 1, 0),
			Position = UDim2.new(0, 35, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row
		})

		createTextLabel({
			Text = formatNumber(entry.Contribution),
			TextColor3 = isMe and Color3.new(1,1,1) or THEME.Primary,
			Font = Enum.Font.GothamBold,
			Size = UDim2.new(0.3, 0, 1, 0),
			Position = UDim2.new(0.7, -10, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row
		})
	end
end

-- Untuk simulasi klaim (karena server mungkin belum punya data previous yang real)
-- Kita gunakan logika generic:
local function updateClaimUI()
	-- Kita tidak punya API khusus untuk "GetPreviousMissionState" yang terpisah di kode lama
	-- Tapi kita bisa menggunakan state yang ada atau memodifikasi backend.
	-- Untuk saat ini, kita gunakan ClaimGlobalMissionReward untuk cek status (sedikit hacky karena tombol ini biasanya untuk eksekusi).
	-- NAMUN, agar aman, kita akan set default text dulu, dan biarkan tombol klaim yang bekerja.

	-- Dalam implementasi ini, kita asumsikan user harus klik "Klaim" untuk cek.
	-- Atau jika backend mendukung, kita bisa cek status.
	-- Mari buat tampilan netral.

	claimTitle.Text = "Hadiah Misi Sebelumnya"
	claimDesc.Text = "Jika Anda berpartisipasi dalam misi minggu lalu dan memenuhi target, Anda dapat mengklaim hadiah di sini."

	prevContribValue.Text = "-"
	prevRewardValue.Text = "?"

	actionClaimButton.Text = "PERIKSA & KLAIM"
	actionClaimButton.Interactable = true
	actionClaimButton.BackgroundColor3 = THEME.Success
end

local function startUpdateLoop()
	-- Store local end time for smooth countdown without server polling
	local localEndTime = 0

	-- Initial fetch
	task.spawn(function()
		local s, st = pcall(function() return getGlobalMissionState:InvokeServer() end)
		if s and st then
			localEndTime = st.EndTime or 0
			updateActiveMissionUI(st)
		end
		updateLeaderboardUI()
		updateClaimUI()
	end)

	local lastServerUpdate = os.clock()

	if updateLoopConnection then updateLoopConnection:Disconnect() end
	updateLoopConnection = game:GetService("RunService").Heartbeat:Connect(function()
		-- 1. Smooth local countdown update (every frame/tick)
		if localEndTime > 0 then
			local timeLeft = localEndTime - os.time()
			countdownLabel.Text = formatTime(timeLeft)
		end

		-- 2. Infrequent Server Poll (every 60 seconds) to sync progress
		if os.clock() - lastServerUpdate > 60 then
			lastServerUpdate = os.clock()
			task.spawn(function()
				local s, st = pcall(function() return getGlobalMissionState:InvokeServer() end)
				if s and st then
					localEndTime = st.EndTime or 0
					updateActiveMissionUI(st)
				end
				-- Also update leaderboard occasionally
				updateLeaderboardUI()
			end)
		end
	end)
end

-- =============================================================================
-- EVENT LISTENERS
-- =============================================================================

tabActive.MouseButton1Click:Connect(function() switchTab("Active") end)
tabClaim.MouseButton1Click:Connect(function() switchTab("Claim") end)

actionClaimButton.MouseButton1Click:Connect(function()
	actionClaimButton.Interactable = false
	actionClaimButton.Text = "MEMPROSES..."

	local success, result = pcall(function() return claimGlobalMissionReward:InvokeServer() end)

	if success then
		if result.Success then
			claimTitle.Text = "HADIAH DIKLAIM!"
			claimDesc.Text = "Selamat! Anda telah menerima hadiah Anda."
			prevRewardValue.Text = formatNumber(result.Reward.Value) .. " " .. result.Reward.Type
			actionClaimButton.Text = "BERHASIL"
			actionClaimButton.BackgroundColor3 = THEME.TextDim
		else
			claimTitle.Text = "GAGAL MENGKLAIM"
			claimDesc.Text = result.Reason or "Tidak ada hadiah yang tersedia."
			actionClaimButton.Text = "TUTUP"
			actionClaimButton.BackgroundColor3 = THEME.Error
			actionClaimButton.Interactable = true
		end
	else
		claimTitle.Text = "ERROR"
		claimDesc.Text = "Terjadi kesalahan koneksi."
		actionClaimButton.Text = "COBA LAGI"
		actionClaimButton.Interactable = true
	end
end)

-- Initial State
switchTab("Active")
startUpdateLoop()

-- Bersihkan prompt lama jika ada
if boardPart:FindFirstChild("MissionPrompt") then
	boardPart.MissionPrompt:Destroy()
end
