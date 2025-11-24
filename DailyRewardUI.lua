-- DailyRewardUI.lua (LocalScript)
-- Path: StarterGui/DailyRewardUI.client.lua
-- Script Place: Lobby

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === PEMBERSIHAN UI LAMA ===
if playerGui:FindFirstChild("DailyRewardUI") then
	playerGui.DailyRewardUI:Destroy()
end
if playerGui:FindFirstChild("DailyRewardButton") then
	playerGui.DailyRewardButton:Destroy()
end

-- ======================================================
-- HELPER PEMBUATAN UI
-- ======================================================
local function Create(instanceType, properties)
	local inst = Instance.new(instanceType)
	for prop, value in pairs(properties or {}) do
		inst[prop] = value
	end
	return inst
end

-- ======================================================
-- KONSTRUKSI UI (TAMPILAN)
-- ======================================================

-- 1. ScreenGui & Main Canvas
local mainCanvas = Create("CanvasGroup", { Name = "MainCanvas", Size = UDim2.new(0, 1100, 0, 700), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), GroupTransparency = 1, BackgroundTransparency = 1, Parent = screenGui })

-- 2. Panel Kaca (Background)
local glassPanel = Create("Frame", { Name = "GlassPanel", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(15, 23, 42), BackgroundTransparency = 0.15, Parent = mainCanvas })
Create("UICorner", { CornerRadius = UDim.new(0, 24), Parent = glassPanel })
Create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1, Parent = glassPanel })

-- 3. Header
local header = Create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, Parent = glassPanel })
Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1, Parent = header })

local headerContent = Create("Frame", { Name = "HeaderContent", Size = UDim2.new(1, -64, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = header })
local titleGroup = Create("Frame", { Name = "TitleGroup", Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Parent = headerContent })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), Parent = titleGroup })

local titleIcon = Create("ImageLabel", { Name = "TitleIcon", Size = UDim2.new(0, 40, 0, 40), BackgroundColor3 = Color3.fromRGB(245, 158, 11), Image = "rbxassetid://6031238291", ImageColor3 = Color3.fromRGB(255, 255, 255), ScaleType = Enum.ScaleType.Fit, Parent = titleGroup })
Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = titleIcon })

local titleTextGroup = Create("Frame", { Name = "TitleTextGroup", Size = UDim2.new(0, 300, 1, 0), BackgroundTransparency = 1, Parent = titleGroup })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Parent = titleTextGroup })
Create("TextLabel", { Name = "Title", Text = "DAILY LOGIN", Font = Enum.Font.SourceSansBold, TextSize = 32, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Parent = titleTextGroup })
Create("TextLabel", { Name = "Subtitle", Text = "Login setiap hari untuk hadiah eksklusif!", Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = Color3.fromRGB(156, 163, 175), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = titleTextGroup })

local closeButton = Create("ImageButton", { Name = "CloseButton", Size = UDim2.new(0, 40, 0, 40), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(51, 65, 85), BackgroundTransparency = 0.5, Image = "rbxassetid://1351660348", Parent = headerContent })
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = closeButton })

-- 4. Body Layout
local body = Create("Frame", { Name = "Body", Size = UDim2.new(1, -64, 1, -112), Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Parent = glassPanel })
local leftPanel = Create("Frame", { Name = "LeftPanel", Size = UDim2.new(0.333, 0, 1, 0), BackgroundTransparency = 1, Parent = body })
local rightPanel = Create("Frame", { Name = "RightPanel", Size = UDim2.new(0.666, -32, 1, 0), Position = UDim2.new(0.35, 0, 0, 0), BackgroundTransparency = 1, Parent = body })

-- 5. Hero Card (Left Panel)
local rewardCard = Create("Frame", { Name = "RewardCard", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(30, 41, 59), Parent = leftPanel })
Create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = rewardCard })
Create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(51, 65, 85)), ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42)) }), Rotation = 90, Parent = rewardCard })

local dayIndicatorBG = Create("Frame", { Name = "DayIndicator", Size = UDim2.new(0, 0, 0, 32), Position = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Color3.fromRGB(15, 23, 42), BackgroundTransparency = 0.2, Parent = rewardCard })
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dayIndicatorBG })
Create("UIStroke", { Color = Color3.fromRGB(245, 158, 11), Transparency = 0.7, Parent = dayIndicatorBG })
Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = dayIndicatorBG })
local dayIndicatorLabel = Create("TextLabel", { Name = "Label", Text = "DAY X", Font = Enum.Font.SourceSansBold, TextSize = 16, TextColor3 = Color3.fromRGB(251, 191, 36), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = dayIndicatorBG })

local heroIconContainer = Create("Frame", { Name = "HeroIconContainer", Size = UDim2.new(1, 0, 0, 192), Position = UDim2.new(0.5, 0, 0.4, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = rewardCard })
local heroIcon = Create("ImageLabel", { Name = "HeroIcon", Size = UDim2.new(1, 0, 1, 0), Image = "", ImageColor3 = Color3.fromRGB(245, 158, 11), BackgroundTransparency = 1, Parent = heroIconContainer })

local heroTextGroup = Create("Frame", { Name = "HeroTextGroup", Size = UDim2.new(1, -64, 0, 100), Position = UDim2.new(0.5, 0, 0.65, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Parent = rewardCard })
Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), Parent = heroTextGroup })
local heroName = Create("TextLabel", { Name = "HeroName", Text = "Reward Name", Font = Enum.Font.SourceSansBold, TextSize = 36, TextColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = heroTextGroup })
local heroDesc = Create("TextLabel", { Name = "HeroDesc", Text = "Desc", Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = Color3.fromRGB(156, 163, 175), Size = UDim2.new(1, 0, 0, 40), TextWrapped = true, BackgroundTransparency = 1, Parent = heroTextGroup })

local claimButton = Create("TextButton", { Name = "ClaimButton", Size = UDim2.new(1, -64, 0, 60), Position = UDim2.new(0.5, 0, 1, -80), AnchorPoint = Vector2.new(0.5, 1), Text = "KLAIM HADIAH", Font = Enum.Font.SourceSansBold, TextSize = 24, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(245, 158, 11), Parent = rewardCard })
Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = claimButton })
local nextRewardTimer = Create("TextLabel", { Name = "Timer", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0.5, 0, 1, -40), AnchorPoint = Vector2.new(0.5, 1), Text = "Reset in: --:--:--", Font = Enum.Font.Code, TextSize = 12, TextColor3 = Color3.fromRGB(100, 116, 139), BackgroundTransparency = 1, Visible = false, Parent = rewardCard })

-- 6. Grid (Right Panel)
local progressSection = Create("Frame", { Name = "ProgressSection", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = rightPanel })
local progressLabels = Create("Frame", { Name = "Labels", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = progressSection })
Create("TextLabel", { Text = "PROGRES MINGGUAN", Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = Color3.fromRGB(156, 163, 175), TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Parent = progressLabels })
local progressText = Create("TextLabel", { Text = "0 / 28 Days", Font = Enum.Font.SourceSansBold, TextSize = 14, TextColor3 = Color3.fromRGB(156, 163, 175), TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Parent = progressLabels })
local progressBarBG = Create("Frame", { Name = "BarBG", Size = UDim2.new(1, 0, 0, 12), Position=UDim2.new(0,0,0,20), BackgroundColor3 = Color3.fromRGB(30, 41, 59), Parent = progressSection })
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBarBG })
local progressBar = Create("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(74, 222, 128), Parent = progressBarBG })
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBar })

local gridContainer = Create("ScrollingFrame", { Name = "GridContainer", Size = UDim2.new(1, 0, 1, -54), Position = UDim2.new(0, 0, 0, 54), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, Parent = rightPanel })
local rewardsGrid = Create("UIGridLayout", { Name = "RewardsGrid", CellPadding = UDim2.new(0, 12, 0, 12), CellSize = UDim2.new(0, 88, 0, 112), StartCorner = Enum.StartCorner.TopLeft, SortOrder = Enum.SortOrder.LayoutOrder, Parent = gridContainer })

-- Template for Grid Item (Hidden)
local dayTemplate = Create("TextButton", { Name = "DayTemplate", Visible = false, Size = UDim2.new(0, 88, 0, 112), BackgroundColor3 = Color3.fromRGB(15, 23, 42), AutoButtonColor = false, Text = "", Parent = gridContainer })
Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = dayTemplate })
Create("UIStroke", { Name = "Border", Color = Color3.fromRGB(51, 65, 85), Parent = dayTemplate })
Create("TextLabel", { Name = "DayNumber", Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 8, 0, 8), Text = "DAY 1", Font = Enum.Font.SourceSansBold, TextColor3 = Color3.fromRGB(156, 163, 175), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Parent = dayTemplate })
local iconBG = Create("Frame", { Name = "IconBG", Size = UDim2.new(1, 0, 1, -44), Position = UDim2.new(0, 0, 0, 22), BackgroundTransparency = 1, Parent = dayTemplate })
Create("ImageLabel", { Name = "ItemIcon", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = iconBG })
local rewardLabelBG = Create("Frame", { Name = "RewardLabelBG", Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.7, Parent = dayTemplate })
Create("TextLabel", { Name = "RewardLabel", Text = "REWARD", Font = Enum.Font.SourceSansBold, TextSize = 10, TextColor3 = Color3.fromRGB(209, 213, 219), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = rewardLabelBG })
Create("Frame", { Name = "ClaimedOverlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 0.4, Visible = false, Parent = dayTemplate })
Create("ImageLabel", { Name = "LockedOverlay", Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0, 8), AnchorPoint = Vector2.new(1, 0), Image = "rbxassetid://515322445", BackgroundTransparency = 1, Visible = false, Parent = dayTemplate })

-- 7. Success Modal
local successModal = Create("CanvasGroup", { Name = "SuccessModal", Size = UDim2.new(1, 0, 1, 0), GroupTransparency = 1, BackgroundTransparency = 1, Visible = false, Parent = screenGui })
local modalBackdrop = Create("Frame", { Name = "Backdrop", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.2, Parent = successModal })
local modalPanel = Create("Frame", { Name = "ModalPanel", Size = UDim2.new(0, 500, 0, 350), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(30, 41, 59), Parent = successModal })
Create("UICorner", { CornerRadius = UDim.new(0, 24), Parent = modalPanel })
Create("UIStroke", { Color = Color3.fromRGB(245, 158, 11), Thickness = 2, Parent = modalPanel })
local modalContentLayout = Create("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 16), Parent = modalPanel })
Create("UIPadding", { PaddingTop = UDim.new(0, 40), PaddingBottom = UDim.new(0, 40), Parent = modalPanel })
Create("TextLabel", { Name = "SuccessTitle", Text = "BERHASIL!", Font = Enum.Font.SourceSansBold, TextSize = 40, TextColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = modalPanel })
local receivedItemText = Create("TextLabel", { Name = "ReceivedItemText", Text = "Anda menerima Hadiah", Font = Enum.Font.SourceSans, TextSize = 18, TextColor3 = Color3.fromRGB(209, 213, 219), RichText = true, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = modalPanel })
local closeModalButton = Create("TextButton", { Name = "CloseModalButton", Size = UDim2.new(0, 120, 0, 48), Text = "TUTUP", Font = Enum.Font.SourceSansBold, TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(51, 65, 85), Parent = modalPanel })
Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = closeModalButton })

-- 8. Tombol Buka UI (HUD)
local rewardButtonGui = Create("ScreenGui", { Name = "DailyRewardButton", ResetOnSpawn = false, Parent = playerGui })
local openButton = Create("TextButton", { Name = "OpenDailyReward", Text = "??", Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 20, 0.5, 0), Font = Enum.Font.SourceSansBold, TextSize = 32, BackgroundColor3 = Color3.fromRGB(52, 152, 219), TextColor3 = Color3.fromRGB(255, 255, 255), Parent = rewardButtonGui })
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = openButton })

-- ======================================================
-- LOGIKA CLIENT & NETWORKING
-- ======================================================

-- State Variables
local currentDay = 1
local canClaimToday = false
local selectedDay = 1
local isOpening = false
local ICONS = { Coins = "rbxassetid://281938327", Booster = "rbxassetid://512856403", Skin = "rbxassetid://6379326447", Mystery = "rbxassetid://497939460" }

-- Config & Remotes
local rewardConfig = require(ReplicatedStorage.ModuleScript:WaitForChild("DailyRewardConfig"))
local RemoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")

-- [[ CRITICAL FIX: Validasi RemoteFunction ]]
local getRewardInfo = RemoteEventsFolder:WaitForChild("GetDailyRewardInfo", 10)
if getRewardInfo and not getRewardInfo:IsA("RemoteFunction") then
	-- Jika salah tipe, cari di folder RemoteFunctions (fallback)
	local RemoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if RemoteFunctionsFolder then
		getRewardInfo = RemoteFunctionsFolder:FindFirstChild("GetDailyRewardInfo")
	end
end

local claimRewardEvent = RemoteEventsFolder:WaitForChild("ClaimDailyReward", 10)
if claimRewardEvent and not claimRewardEvent:IsA("RemoteFunction") then
	local RemoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	if RemoteFunctionsFolder then
		claimRewardEvent = RemoteFunctionsFolder:FindFirstChild("ClaimDailyReward")
	end
end

local showRewardUIEvent = RemoteEventsFolder:WaitForChild("ShowDailyRewardUI", 10)

-- Functions
local function animateUI(fadeIn)
	local goal = { GroupTransparency = fadeIn and 0 or 1 }
	local tween = TweenService:Create(mainCanvas, TweenInfo.new(0.3), goal)
	tween:Play()
	if fadeIn then screenGui.Enabled = true else tween.Completed:Wait() screenGui.Enabled = false end
end

local function animateModal(fadeIn)
	successModal.Visible = true
	local goal = { GroupTransparency = fadeIn and 0 or 1 }
	TweenService:Create(successModal, TweenInfo.new(0.2), goal):Play()
	if not fadeIn then task.wait(0.2) successModal.Visible = false end
end

local function updateHero(day)
	selectedDay = day
	local reward = rewardConfig.Rewards[day]
	if not reward then return end

	dayIndicatorLabel.Text = "DAY " .. day
	heroIcon.Image = ICONS[reward.Type] or ""

	if reward.Type == "Coins" then
		heroName.Text = string.format("%d Coins", reward.Value)
		heroDesc.Text = "Mata uang untuk membeli senjata dan upgrade."
	elseif reward.Type == "Booster" then
		heroName.Text = reward.Value
		heroDesc.Text = "Buff sementara untuk membantu dalam pertempuran."
	elseif reward.Type == "Skin" then
		heroName.Text = "Random Skin"
		heroDesc.Text = "Skin senjata acak."
	else
		heroName.Text = "Mystery Box"
		heroDesc.Text = "Hadiah kejutan!"
	end

	if day == currentDay and canClaimToday then
		claimButton.Text = "KLAIM HADIAH"
		claimButton.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		claimButton.AutoButtonColor = true
		nextRewardTimer.Visible = false
	elseif day < currentDay then
		claimButton.Text = "SUDAH DIKLAIM"
		claimButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
		claimButton.AutoButtonColor = false
		nextRewardTimer.Visible = false
	else
		claimButton.Text = "TERKUNCI"
		claimButton.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		claimButton.AutoButtonColor = false
		if day == currentDay then nextRewardTimer.Visible = true end
	end
end

local function populateGrid()
	-- Bersihkan grid lama
	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("TextButton") and child ~= dayTemplate then child:Destroy() end
	end

	for day = 1, #rewardConfig.Rewards do
		local cell = dayTemplate:Clone()
		cell.Name = "Day_" .. day
		cell.Visible = true
		cell.Parent = gridContainer

		local reward = rewardConfig.Rewards[day]

		-- Update isi cell
		cell.DayNumber.Text = "DAY " .. day
		cell.IconBG.ItemIcon.Image = ICONS[reward.Type] or ""
		cell.RewardLabelBG.RewardLabel.Text = (reward.Type == "Coins") and (reward.Value.." Coins") or reward.Type

		-- Update status visual
		local border = cell.Border
		local claimed = cell.ClaimedOverlay
		local locked = cell.LockedOverlay

		if day < currentDay then
			claimed.Visible = true
			cell.BackgroundTransparency = 0.4
		elseif day == currentDay and canClaimToday then
			border.Color = Color3.fromRGB(245, 158, 11)
			border.Thickness = 2
			cell.BackgroundTransparency = 0
		else
			locked.Visible = true
			cell.BackgroundTransparency = 0.5
		end

		-- Click event
		cell.MouseButton1Click:Connect(function()
			updateHero(day)
		end)
	end
end

local function openUI()
	if isOpening then return end
	isOpening = true
	local originalText = openButton.Text
	openButton.Text = "..."
	openButton.Interactable = false

	-- Validasi Akhir RemoteFunction
	if not getRewardInfo or not getRewardInfo:IsA("RemoteFunction") then
		warn("DailyRewardUI: RemoteFunction INVALID. Mencari ulang...")
		-- Coba cari ulang
		local rf = ReplicatedStorage:FindFirstChild("RemoteFunctions")
		if rf then getRewardInfo = rf:FindFirstChild("GetDailyRewardInfo") end
	end

	if not getRewardInfo or not getRewardInfo:IsA("RemoteFunction") then
		warn("DailyRewardUI: RemoteFunction GAGAL DITEMUKAN.")
		game:GetService("StarterGui"):SetCore("SendNotification", { Title = "System Error", Text = "Gagal memuat sistem reward. Rejoin game.", Duration = 5 })
		openButton.Text = "X"
		task.wait(2)
		openButton.Text = originalText
		openButton.Interactable = true
		isOpening = false
		return
	end

	-- Invoke Server
	local success, result = pcall(function() return getRewardInfo:InvokeServer() end)

	openButton.Text = originalText
	openButton.Interactable = true
	isOpening = false

	if success and result then
		currentDay = result.CurrentDay
		canClaimToday = result.CanClaim
		populateGrid()
		updateHero(currentDay)
		local progress = (currentDay - 1) / #rewardConfig.Rewards
		progressBar.Size = UDim2.new(progress, 0, 1, 0)
		progressText.Text = string.format("%d / %d Days", currentDay-1, #rewardConfig.Rewards)

		animateUI(true)
	else
		warn("DailyRewardUI: Data gagal dimuat. " .. tostring(result))
		game:GetService("StarterGui"):SetCore("SendNotification", { Title = "Koneksi Gagal", Text = "Gagal mengambil data. Coba lagi.", Duration = 3 })
	end
end

-- Connections
openButton.MouseButton1Click:Connect(openUI)
closeButton.MouseButton1Click:Connect(function() animateUI(false) end)
closeModalButton.MouseButton1Click:Connect(function() animateModal(false); animateUI(false) end)

if showRewardUIEvent and showRewardUIEvent:IsA("RemoteEvent") then
	showRewardUIEvent.OnClientEvent:Connect(openUI)
end

-- Claim Logic
claimButton.MouseButton1Click:Connect(function()
	if not (selectedDay == currentDay and canClaimToday) then return end

	-- Validasi RemoteFunction Claim
	if not claimRewardEvent or not claimRewardEvent:IsA("RemoteFunction") then
		-- Coba cari ulang
		local rf = ReplicatedStorage:FindFirstChild("RemoteFunctions")
		if rf then claimRewardEvent = rf:FindFirstChild("ClaimDailyReward") end
	end

	if not claimRewardEvent or not claimRewardEvent:IsA("RemoteFunction") then
		warn("Claim RemoteFunction Missing")
		return
	end

	claimButton.Text = "..."
	claimButton.Interactable = false

	local success, result = pcall(function() return claimRewardEvent:InvokeServer() end)

	if success and result and result.Success then
		local reward = result.ClaimedReward
		local txt = (reward.Type == "Coins") and (reward.Value .. " Coins") or (reward.Value or reward.Type)
		receivedItemText.Text = "Anda menerima <font color='#fbbf24'><b>" .. txt .. "</b></font>"

		canClaimToday = false
		currentDay = result.NextDay
		updateHero(currentDay - 1) -- Tampilkan hari ini (yang baru diklaim)
		populateGrid() -- Refresh status
		animateModal(true)
	else
		claimButton.Text = "GAGAL"
		task.wait(1)
		updateHero(selectedDay) -- Reset tombol
		claimButton.Interactable = true
	end
end)

print("DailyRewardUI (Fixed) Loaded")