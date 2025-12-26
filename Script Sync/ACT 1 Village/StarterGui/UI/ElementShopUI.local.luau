-- ElementShopUI.lua (LocalScript)
-- Path: StarterGui/AchievementPointsUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local openEv = RemoteEvents:WaitForChild("OpenElementShop")
local requestOpenEvent = RemoteEvents:WaitForChild("RequestOpenElementShop")
local closeShop = RemoteEvents:WaitForChild("CloseElementShop")
local purchaseRF = RemoteFunctions:WaitForChild("PurchaseElement")

local elementsPrompt
if workspace:FindFirstChild("Elements") then
	local attachment = workspace.Elements:FindFirstChild("Attachment")
	if attachment then
		elementsPrompt = attachment:FindFirstChild("ElementsPrompt")
	end
end

-- --- CONFIGURATION DATA (REFLAVORED: Tactical Survival Theme) ---
local elementsData = {
	Fire = {
		name = "Incendiary Rounds",
		icon = "🔥",
		type = "Damage",
		cost = 1500,
		duration = 10,
		color = Color3.fromHex("#ef4444"), -- Red
		desc = "Peluru pembakar. Musuh terbakar dan menerima damage tambahan setiap detik.",
		stats = { {label="Burn Damage", val="10% / tick"}, {label="Ticks", val="3x"} }
	},
	Ice = {
		name = "Cryo Compound",
		icon = "❄️",
		type = "Control",
		cost = 1500,
		duration = 20,
		color = Color3.fromHex("#06b6d4"), -- Cyan
		desc = "Senyawa beku. Memperlambat gerakan musuh secara signifikan.",
		stats = { {label="Slow Effect", val="30%"}, {label="Duration", val="4s"} }
	},
	Poison = {
		name = "Toxic Agent",
		icon = "☠️",
		type = "DoT",
		cost = 1500,
		duration = 10,
		color = Color3.fromHex("#22c55e"), -- Green
		desc = "Agen beracun. Musuh menerima damage terus-menerus (Damage over Time).",
		stats = { {label="Poison DPS", val="5 Dmg"}, {label="Duration", val="6s"} }
	},
	Shock = {
		name = "EMP Burst",
		icon = "⚡",
		type = "AoE",
		cost = 1500,
		duration = 10,
		color = Color3.fromHex("#eab308"), -- Yellow
		desc = "Gelombang elektromagnetik. Damage menyebar ke musuh sekitar.",
		stats = { {label="Chain Range", val="6 Studs"}, {label="Chain Dmg", val="50%"} }
	},
	Wind = {
		name = "Concussion Blast",
		icon = "💨",
		type = "Utility",
		cost = 1500,
		duration = 10,
		color = Color3.fromHex("#f8fafc"), -- Slate/White
		desc = "Ledakan kejut. Mendorong musuh dan meningkatkan kecepatan gerak.",
		stats = { {label="Push Speed", val="60"}, {label="Move Speed", val="+50%"} }
	},
	Earth = {
		name = "Hardened Armor",
		icon = "🛡️",
		type = "Defense",
		cost = 1500,
		duration = 10,
		color = Color3.fromHex("#a8a29e"), -- Stone
		desc = "Pelindung temporal. Mengurangi damage yang diterima dari musuh.",
		stats = { {label="Dmg Reduction", val="20%"}, {label="Resilience", val="High"} }
	},
	Light = {
		name = "Stimpack",
		icon = "💉",
		type = "Ultimate",
		cost = 3000,
		duration = 3,
		color = Color3.fromHex("#fde047"), -- Light Yellow
		desc = "Suntikan adrenalin. Kebal damage sementara - penyelamat darurat.",
		stats = { {label="Invincible", val="TRUE"}, {label="Duration", val="3s"} }
	},
	Dark = {
		name = "Adrenaline Serum",
		icon = "🩸",
		type = "Sustain",
		cost = 5000,
		duration = 5,
		color = Color3.fromHex("#9333ea"), -- Purple
		desc = "Serum eksperimental. Mencuri HP dari musuh yang diserang (Lifesteal).",
		stats = { {label="Lifesteal", val="10%"}, {label="Duration", val="5s"} }
	}
}

local orderedKeys = {"Fire", "Ice", "Poison", "Shock", "Wind", "Earth", "Light", "Dark"}
local selectedElementKey = "Ice" -- Default
local currentBalance = 0 -- Will be updated

-- --- UI CREATION ---
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ElementShopUI"
screenGui.Parent = playerGui
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Fonts
local fontTech = Enum.Font.SciFi -- Use SciFi or GothamBold for tech feel
local fontStandard = Enum.Font.Gotham

-- Main Container (Glassmorphism Panel)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 950, 0, 600)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 55) -- Slightly brighter dark slate (was 15, 23, 42)
mainFrame.BackgroundTransparency = 0 -- No longer transparent
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.92
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- === LEFT SIDEBAR ===
local leftSidebar = Instance.new("Frame")
leftSidebar.Name = "LeftSidebar"
leftSidebar.Size = UDim2.new(0, 320, 1, 0)
leftSidebar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
leftSidebar.BackgroundTransparency = 0
leftSidebar.BorderSizePixel = 0
leftSidebar.Parent = mainFrame

local sidebarBorder = Instance.new("Frame") -- Right border
sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
sidebarBorder.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
sidebarBorder.BorderSizePixel = 0
sidebarBorder.Parent = leftSidebar

-- Header
local sidebarHeader = Instance.new("Frame")
sidebarHeader.Name = "Header"
sidebarHeader.Size = UDim2.new(1, 0, 0, 100)
sidebarHeader.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
sidebarHeader.BackgroundTransparency = 0
sidebarHeader.BorderSizePixel = 0
sidebarHeader.Parent = leftSidebar

local headerBorder = Instance.new("Frame") -- Bottom border
headerBorder.Size = UDim2.new(1, 0, 0, 1)
headerBorder.Position = UDim2.new(0, 0, 1, -1)
headerBorder.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
headerBorder.BorderSizePixel = 0
headerBorder.Parent = sidebarHeader

local titleLabel = Instance.new("TextLabel")
titleLabel.Text = "TACTICAL BOOSTS"
titleLabel.Font = fontTech
titleLabel.TextSize = 24
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.BackgroundTransparency = 1
titleLabel.Size = UDim2.new(1, -40, 0, 30)
titleLabel.Position = UDim2.new(0, 20, 0, 25)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center -- Centered
titleLabel.Parent = sidebarHeader

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Text = "Pilih boost untuk upgrade senjatamu."
subtitleLabel.Font = fontStandard
subtitleLabel.TextSize = 12
subtitleLabel.TextColor3 = Color3.fromRGB(148, 163, 184) -- Slate-400
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Size = UDim2.new(1, -40, 0, 20)
subtitleLabel.Position = UDim2.new(0, 20, 0, 55)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center -- Centered
subtitleLabel.Parent = sidebarHeader

-- List Container (Updated to fill space)
local listContainer = Instance.new("ScrollingFrame")
listContainer.Name = "ListContainer"
listContainer.Size = UDim2.new(1, 0, 1, -100) -- Was -180, now -100 (only header remains)
listContainer.Position = UDim2.new(0, 0, 0, 100)
listContainer.BackgroundTransparency = 1
listContainer.BorderSizePixel = 0
listContainer.ScrollBarThickness = 4
listContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
listContainer.ScrollBarImageTransparency = 0.8
listContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Set to 0
listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Enable auto size
listContainer.Parent = leftSidebar

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listContainer

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 12)
listPadding.PaddingBottom = UDim.new(0, 12)
listPadding.Parent = listContainer

-- Footer REMOVED

-- === RIGHT CONTENT ===
local rightContent = Instance.new("Frame")
rightContent.Name = "RightContent"
rightContent.Size = UDim2.new(1, -320, 1, 0)
rightContent.Position = UDim2.new(0, 320, 0, 0)
rightContent.BackgroundTransparency = 1
rightContent.Parent = mainFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Text = "X"
closeButton.Font = fontStandard
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
closeButton.BackgroundTransparency = 0.5
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -48, 0, 16)
closeButton.AutoButtonColor = true
closeButton.ZIndex = 10
closeButton.Parent = rightContent

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

-- Preview Area (Top 55%)
local previewArea = Instance.new("Frame")
previewArea.Name = "PreviewArea"
previewArea.Size = UDim2.new(1, 0, 0.55, 0)
previewArea.BackgroundTransparency = 1
previewArea.ClipsDescendants = true
previewArea.Parent = rightContent

local previewGradient = Instance.new("UIGradient")
previewGradient.Rotation = 90
previewGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 41, 59)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 23, 42))
})
previewGradient.Parent = previewArea

-- Dynamic Background Glow
local previewGlow = Instance.new("ImageLabel")
previewGlow.Name = "PreviewGlow"
previewGlow.Image = "rbxassetid://6008289213" -- Generic soft glow blob
previewGlow.ImageColor3 = Color3.fromRGB(6, 182, 212) -- Default Ice
previewGlow.ImageTransparency = 0.8
previewGlow.Size = UDim2.new(0, 400, 0, 400)
previewGlow.AnchorPoint = Vector2.new(0.5, 0.5)
previewGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
previewGlow.BackgroundTransparency = 1
previewGlow.Parent = previewArea

-- Preview Orb Container
local orbContainer = Instance.new("Frame")
orbContainer.Size = UDim2.new(0, 140, 0, 140)
orbContainer.AnchorPoint = Vector2.new(0.5, 0.5)
orbContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
orbContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
orbContainer.BackgroundTransparency = 0.9
orbContainer.Parent = previewArea

local orbCorner = Instance.new("UICorner")
orbCorner.CornerRadius = UDim.new(1, 0)
orbCorner.Parent = orbContainer

local orbStroke = Instance.new("UIStroke")
orbStroke.Color = Color3.fromRGB(255, 255, 255)
orbStroke.Transparency = 0.8
orbStroke.Thickness = 4
orbStroke.Parent = orbContainer

local previewIcon = Instance.new("TextLabel")
previewIcon.Name = "Icon"
previewIcon.Text = "❄️"
previewIcon.TextSize = 64
previewIcon.BackgroundTransparency = 1
previewIcon.Size = UDim2.new(1, 0, 1, 0)
previewIcon.Parent = orbContainer

-- Preview Text
local previewName = Instance.new("TextLabel")
previewName.Name = "PreviewName"
previewName.Text = "ICE"
previewName.Font = fontTech
previewName.TextSize = 42
previewName.TextColor3 = Color3.new(1, 1, 1)
previewName.BackgroundTransparency = 1
previewName.Size = UDim2.new(1, 0, 0, 50)
previewName.Position = UDim2.new(0, 0, 0.65, 0)
previewName.Parent = previewArea

local previewType = Instance.new("TextLabel")
previewType.Name = "PreviewType"
previewType.Text = "CROWD CONTROL"
previewType.Font = fontStandard
previewType.TextSize = 14
previewType.TextColor3 = Color3.fromRGB(147, 197, 253) -- Blue-300
previewType.BackgroundTransparency = 1
previewType.Size = UDim2.new(1, 0, 0, 20)
previewType.Position = UDim2.new(0, 0, 0.75, 0)
previewType.Parent = previewArea

-- Info & Action Area (Bottom 45%)
local infoArea = Instance.new("Frame")
infoArea.Name = "InfoArea"
infoArea.Size = UDim2.new(1, 0, 0.45, 0)
infoArea.Position = UDim2.new(0, 0, 0.55, 0)
infoArea.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
infoArea.BackgroundTransparency = 0.4
infoArea.BorderSizePixel = 0
infoArea.Parent = rightContent

local infoBorder = Instance.new("Frame") -- Top border
infoBorder.Size = UDim2.new(1, 0, 0, 1)
infoBorder.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
infoBorder.BorderSizePixel = 0
infoBorder.Parent = infoArea

local infoPadding = Instance.new("UIPadding")
infoPadding.PaddingTop = UDim.new(0, 24)
infoPadding.PaddingLeft = UDim.new(0, 32)
infoPadding.PaddingRight = UDim.new(0, 32)
infoPadding.PaddingBottom = UDim.new(0, 24)
infoPadding.Parent = infoArea

-- Stats Header
local statsHeader = Instance.new("Frame")
statsHeader.Size = UDim2.new(1, 0, 0, 20)
statsHeader.BackgroundTransparency = 1
statsHeader.Parent = infoArea

local statsTitle = Instance.new("TextLabel")
statsTitle.Text = "EFFECT STATISTICS"
statsTitle.Font = fontStandard
statsTitle.TextSize = 12
statsTitle.TextColor3 = Color3.fromRGB(203, 213, 225) -- Slate-300
statsTitle.BackgroundTransparency = 1
statsTitle.Size = UDim2.new(0.5, 0, 1, 0)
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Parent = statsHeader

local durationTag = Instance.new("TextLabel")
durationTag.Name = "DurationTag"
durationTag.Text = "Duration: 10s"
durationTag.Font = Enum.Font.Code
durationTag.TextSize = 12
durationTag.TextColor3 = Color3.fromRGB(148, 163, 184)
durationTag.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
durationTag.Size = UDim2.new(0, 100, 1, 0)
durationTag.Position = UDim2.new(1, -100, 0, 0)
durationTag.Parent = statsHeader

local tagCorner = Instance.new("UICorner")
tagCorner.CornerRadius = UDim.new(0, 4)
tagCorner.Parent = durationTag

-- Stats Grid
local statsGrid = Instance.new("Frame")
statsGrid.Size = UDim2.new(1, 0, 0, 70)
statsGrid.Position = UDim2.new(0, 0, 0, 35)
statsGrid.BackgroundTransparency = 1
statsGrid.Parent = infoArea

local stat1Frame = Instance.new("Frame")
stat1Frame.Name = "Stat1"
stat1Frame.Size = UDim2.new(0.48, 0, 1, 0)
stat1Frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
stat1Frame.BackgroundTransparency = 0.5
stat1Frame.Parent = statsGrid

local s1Corner = Instance.new("UICorner"); s1Corner.CornerRadius = UDim.new(0, 8); s1Corner.Parent = stat1Frame
local s1Stroke = Instance.new("UIStroke"); s1Stroke.Color = Color3.fromRGB(51, 65, 85); s1Stroke.Parent = stat1Frame

local stat1Label = Instance.new("TextLabel")
stat1Label.Name = "Label"
stat1Label.Text = "Damage Multiplier"
stat1Label.TextColor3 = Color3.fromRGB(148, 163, 184)
stat1Label.TextSize = 12
stat1Label.Font = fontStandard
stat1Label.BackgroundTransparency = 1
stat1Label.Size = UDim2.new(1, -20, 0, 20)
stat1Label.Position = UDim2.new(0, 10, 0, 10)
stat1Label.TextXAlignment = Enum.TextXAlignment.Left
stat1Label.Parent = stat1Frame

local stat1Val = Instance.new("TextLabel")
stat1Val.Name = "Value"
stat1Val.Text = "1.0x"
stat1Val.TextColor3 = Color3.new(1, 1, 1)
stat1Val.TextSize = 20
stat1Val.Font = fontTech
stat1Val.BackgroundTransparency = 1
stat1Val.Size = UDim2.new(1, -20, 0, 30)
stat1Val.Position = UDim2.new(0, 10, 0, 30)
stat1Val.TextXAlignment = Enum.TextXAlignment.Left
stat1Val.Parent = stat1Frame

local stat2Frame = Instance.new("Frame")
stat2Frame.Name = "Stat2"
stat2Frame.Size = UDim2.new(0.48, 0, 1, 0)
stat2Frame.Position = UDim2.new(0.52, 0, 0, 0)
stat2Frame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
stat2Frame.BackgroundTransparency = 0.5
stat2Frame.Parent = statsGrid

local s2Corner = Instance.new("UICorner"); s2Corner.CornerRadius = UDim.new(0, 8); s2Corner.Parent = stat2Frame
local s2Stroke = Instance.new("UIStroke"); s2Stroke.Color = Color3.fromRGB(51, 65, 85); s2Stroke.Parent = stat2Frame

local stat2Label = stat1Label:Clone(); stat2Label.Parent = stat2Frame
local stat2Val = stat1Val:Clone(); stat2Val.Parent = stat2Frame

-- Description
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Text = "Description goes here..."
descLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
descLabel.TextSize = 14
descLabel.Font = fontStandard
descLabel.BackgroundTransparency = 1
descLabel.Size = UDim2.new(1, 0, 0, 60)
descLabel.Position = UDim2.new(0, 0, 0, 120)
descLabel.TextXAlignment = Enum.TextXAlignment.Left
descLabel.TextYAlignment = Enum.TextYAlignment.Top
descLabel.TextWrapped = true
descLabel.Parent = infoArea

-- Action Bar (Bottom)
local actionBar = Instance.new("Frame")
actionBar.Size = UDim2.new(1, 0, 0, 60)
actionBar.Position = UDim2.new(0, 0, 1, -60)
actionBar.BackgroundTransparency = 1
actionBar.Parent = infoArea

-- Cost Info
local costHeader = Instance.new("TextLabel")
costHeader.Text = "Activation Cost"
costHeader.TextColor3 = Color3.fromRGB(148, 163, 184)
costHeader.TextSize = 12
costHeader.Font = fontStandard
costHeader.BackgroundTransparency = 1
costHeader.Size = UDim2.new(0.4, 0, 0, 15)
costHeader.TextXAlignment = Enum.TextXAlignment.Left
costHeader.Parent = actionBar

local costValue = Instance.new("TextLabel")
costValue.Name = "CostValue"
costValue.Text = "1,500"
costValue.TextColor3 = Color3.fromRGB(251, 191, 36)
costValue.TextSize = 32
costValue.Font = fontTech
costValue.BackgroundTransparency = 1
costValue.Size = UDim2.new(0.4, 0, 0, 40)
costValue.Position = UDim2.new(0, 0, 0, 15)
costValue.TextXAlignment = Enum.TextXAlignment.Left
costValue.Parent = actionBar

local costSuffix = Instance.new("TextLabel")
costSuffix.Text = "BP"
costSuffix.TextColor3 = Color3.fromRGB(217, 119, 6)
costSuffix.TextSize = 14
costSuffix.Font = Enum.Font.GothamBold
costSuffix.BackgroundTransparency = 1
costSuffix.Size = UDim2.new(0, 30, 0, 40)
costSuffix.Position = UDim2.new(0, 90, 0, 20) -- Approx position, will need adjustment logic if text varies wildy
costSuffix.Parent = actionBar

-- Purchase Button
local buyButton = Instance.new("TextButton")
buyButton.Name = "BuyButton"
buyButton.Text = ""
buyButton.BackgroundColor3 = Color3.fromRGB(37, 99, 235) -- Blue-600
buyButton.Size = UDim2.new(0.55, 0, 1, 0)
buyButton.Position = UDim2.new(0.45, 0, 0, 0)
buyButton.AutoButtonColor = true
buyButton.Parent = actionBar

local buyCorner = Instance.new("UICorner"); buyCorner.CornerRadius = UDim.new(0, 12); buyCorner.Parent = buyButton
local buyGradient = Instance.new("UIGradient")
buyGradient.Color = ColorSequence.new(Color3.fromRGB(37, 99, 235), Color3.fromRGB(59, 130, 246))
buyGradient.Parent = buyButton

local buyText = Instance.new("TextLabel")
buyText.Name = "Label"
buyText.Text = "BUY & ACTIVATE"
buyText.TextColor3 = Color3.new(1, 1, 1)
buyText.TextSize = 16
buyText.Font = Enum.Font.GothamBold
buyText.BackgroundTransparency = 1
buyText.Size = UDim2.new(1, 0, 1, 0)
buyText.Parent = buyButton

-- === LOGIC & FUNCTIONS ===

-- Render List Items
local function renderList()
	-- Clear existing
	for _, c in pairs(listContainer:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
	end

	for i, key in ipairs(orderedKeys) do
		local data = elementsData[key]

		local btn = Instance.new("TextButton")
		btn.Name = key
		btn.Size = UDim2.new(1, -24, 0, 60)
		btn.BackgroundColor3 = Color3.fromRGB(30, 41, 59) -- Slate-800 default
		btn.BackgroundTransparency = 0.6
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = listContainer

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(51, 65, 85)
		btnStroke.Transparency = 0.5
		btnStroke.Parent = btn

		-- Icon Box
		local iconBox = Instance.new("Frame")
		iconBox.Size = UDim2.new(0, 40, 0, 40)
		iconBox.Position = UDim2.new(0, 10, 0.5, -20)
		iconBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		iconBox.Parent = btn

		local iconCorner = Instance.new("UICorner"); iconCorner.CornerRadius = UDim.new(0, 6); iconCorner.Parent = iconBox

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Text = data.icon
		iconLabel.TextSize = 24
		iconLabel.BackgroundTransparency = 1
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.Parent = iconBox

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = data.name
		nameLabel.Font = fontTech
		nameLabel.TextSize = 18
		nameLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, -120, 0, 20)
		nameLabel.Position = UDim2.new(0, 60, 0, 10)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = btn

		-- Type
		local typeLabel = Instance.new("TextLabel")
		typeLabel.Text = string.upper(data.type)
		typeLabel.Font = fontStandard
		typeLabel.TextSize = 10
		typeLabel.TextColor3 = Color3.fromRGB(100, 116, 139)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Size = UDim2.new(1, -120, 0, 15)
		typeLabel.Position = UDim2.new(0, 60, 0, 32)
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		typeLabel.Parent = btn

		-- Cost (Small)
		local costLabel = Instance.new("TextLabel")
		costLabel.Text = tostring(data.cost)
		costLabel.Font = Enum.Font.Code
		costLabel.TextSize = 12
		costLabel.TextColor3 = data.color
		costLabel.BackgroundTransparency = 1
		costLabel.Size = UDim2.new(0, 50, 0, 20)
		costLabel.Position = UDim2.new(1, -60, 0.5, -10)
		costLabel.TextXAlignment = Enum.TextXAlignment.Right
		costLabel.Parent = btn

		-- Click Event
		btn.MouseButton1Click:Connect(function()
			selectElement(key)
		end)
	end
end

local function updateOrbAnimation()
	-- Simple "breathing" animation for the orb container
	-- In a real scenario, we might use a RenderStepped loop or TweenService loop
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(orbContainer, tweenInfo, {Position = UDim2.new(0.5, 0, 0.43, 0)})
	tween:Play()
end

local function updateBalance(amount)
	currentBalance = amount
	-- Balance text update removed as per request
	-- Check affordability for current selection
	selectElement(selectedElementKey) 
end

function selectElement(key)
	selectedElementKey = key
	local data = elementsData[key]

	-- Update List Visuals
	for _, child in pairs(listContainer:GetChildren()) do
		if child:IsA("TextButton") then
			local isSelected = (child.Name == key)
			local stroke = child:FindFirstChild("UIStroke")

			if isSelected then
				child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				child.BackgroundTransparency = 0.95
				if stroke then 
					stroke.Color = data.color
					stroke.Transparency = 0
					stroke.Thickness = 2
				end
				-- Add left border indicator simulation if possible, or just rely on stroke color
			else
				child.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
				child.BackgroundTransparency = 0.6
				if stroke then 
					stroke.Color = Color3.fromRGB(51, 65, 85)
					stroke.Transparency = 0.5
					stroke.Thickness = 1
				end
			end
		end
	end

	-- Update Preview Visuals
	previewGlow.ImageColor3 = data.color
	orbContainer.BackgroundColor3 = data.color -- Tint the orb background slightly
	orbContainer.BackgroundTransparency = 0.85
	orbStroke.Color = data.color

	previewIcon.Text = data.icon

	previewName.Text = string.upper(data.name)
	-- previewName.TextColor3 = data.color -- Keep white for contrast, or use color? Prototype says white.

	previewType.Text = string.upper(data.type)
	previewType.TextColor3 = data.color

	durationTag.Text = "Duration: " .. data.duration .. "s"
	descLabel.Text = data.desc

	-- Update Stats
	stat1Label.Text = data.stats[1].label
	stat1Val.Text = data.stats[1].val
	stat2Label.Text = data.stats[2].label
	stat2Val.Text = data.stats[2].val

	-- Update Cost & Buy Button
	costValue.Text = string.format("%d", data.cost)

	local canAfford = (currentBalance >= data.cost)
	if canAfford then
		buyButton.Active = true
		buyButton.AutoButtonColor = true
		buyButton.BackgroundColor3 = data.color
		buyText.Text = "BUY & ACTIVATE"
		costValue.TextColor3 = Color3.fromRGB(251, 191, 36) -- Amber
	else
		buyButton.Active = false
		buyButton.AutoButtonColor = false
		buyButton.BackgroundColor3 = Color3.fromRGB(51, 65, 85) -- Slate-700
		buyText.Text = "INSUFFICIENT FUNDS"
		costValue.TextColor3 = Color3.fromRGB(239, 68, 68) -- Red
	end
end

-- Fetch Balance Logic
local function fetchBalance()
	-- Try to get balance from a likely module (CoinsModule or PointsModule)
	-- For client side, usually we check attributes or leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = 0

	-- First check "Points" (BP usually implies Battle Points or similar)
	if leaderstats then
		local pt = leaderstats:FindFirstChild("Points") or leaderstats:FindFirstChild("BP") or leaderstats:FindFirstChild("Coins")
		if pt then coins = pt.Value end
	end

	-- Also check hidden attributes if your game uses them
	updateBalance(coins)
end

-- Update balance loop
task.spawn(function()
	while true do
		fetchBalance()
		task.wait(1)
	end
end)

-- Purchase Logic
buyButton.MouseButton1Click:Connect(function()
	if not buyButton.Active then return end

	local success, msg = purchaseRF:InvokeServer(selectedElementKey)
	if success then
		-- Show Success Visuals?
		buyText.Text = "SUCCESS!"
		task.wait(1)
		buyText.Text = "BUY & ACTIVATE"
		-- Refresh balance immediately
		fetchBalance()

		-- Close shop? Or stay open?
		-- closeElementShop()
	else
		-- Show Failure
		local oldText = buyText.Text
		buyText.Text = "FAILED!"
		task.wait(1)
		buyText.Text = oldText
	end
end)

-- Close Logic
local function closeElementShop()
	screenGui.Enabled = false
	-- Optional: Blur effect removal
end

closeButton.MouseButton1Click:Connect(closeElementShop)

-- Setup Prompt Connection
local function setupPrompt()
	print("Setup Prompt...")
	if workspace:WaitForChild("Elements") then
		local attachment = workspace.Elements:FindFirstChild("Attachment")
		if attachment then
			elementsPrompt = attachment:FindFirstChild("ElementsPrompt")
			if elementsPrompt then
				print("Prompt found! Connecting...")
				elementsPrompt.Triggered:Connect(function()
					print("Prompt Triggered!")
					screenGui.Enabled = true
					renderList()
					selectElement(selectedElementKey)
					fetchBalance()
				end)
			else
				warn("Prompt not found in Attachment")
			end
		else
			warn("Attachment not found in Elements")
		end
	else
		warn("Elements model not found in Workspace")
	end
end

-- Try to setup prompt immediately
setupPrompt()

-- If prompt missing, wait for it (StreamingEnabled or late load)
if not elementsPrompt then
	print("Prompt not found immediately, waiting...")
	task.spawn(function()
		local elements = workspace:WaitForChild("Elements", 10)
		if elements then
			local attachment = elements:WaitForChild("Attachment", 10)
			if attachment then
				elementsPrompt = attachment:WaitForChild("ElementsPrompt", 10)
				if elementsPrompt then
					print("Prompt found after wait! Connecting...")
					elementsPrompt.Triggered:Connect(function()
						print("Prompt Triggered (Delayed)!")
						screenGui.Enabled = true
						renderList()
						selectElement(selectedElementKey)
						fetchBalance()
					end)
				end
			end
		end
	end)
end

openEv.OnClientEvent:Connect(function()
	screenGui.Enabled = true
	renderList()
	selectElement(selectedElementKey)
	fetchBalance()
end)

closeShop.OnClientEvent:Connect(closeElementShop)

-- Initial Setup
renderList()
updateOrbAnimation()
