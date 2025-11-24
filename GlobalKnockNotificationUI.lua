-- GlobalKnockNotificationUI.lua (LocalScript)
-- Path: StarterGui/GlobalKnockNotificationUI.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local RemoteEvents = game.ReplicatedStorage.RemoteEvents
local GlobalKnockNotificationEvent = RemoteEvents:WaitForChild("GlobalKnockNotificationEvent")

-- Preload assets
ContentProvider:PreloadAsync({
	"rbxassetid://10151247863",  -- Skull icon
	"rbxassetid://10151249576",  -- Heart icon
})

-- Constants for Styling
local COLORS = {
	KNOCKED = Color3.fromRGB(239, 68, 68),    -- Red-500
	REVIVED = Color3.fromRGB(34, 197, 94),    -- Green-500
	BG = Color3.fromRGB(17, 24, 39),          -- Slate-900
	TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
	TEXT_SECONDARY = Color3.fromRGB(148, 163, 184) -- Slate-400
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GlobalKnockNotificationUI"
screenGui.Parent = gui
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false

-- Main Container (Right aligned list)
local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "NotificationContainer"
notificationContainer.Size = UDim2.new(0, 350, 0.8, 0)
notificationContainer.Position = UDim2.new(1, -20, 0.15, 0)
notificationContainer.AnchorPoint = Vector2.new(1, 0)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = notificationContainer
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
listLayout.Padding = UDim.new(0, 10)

-- Cache for profile pictures
local profilePictureCache = {}

-- Helper: Get Profile Picture
local function getPlayerProfilePicture(playerName, callback)
	if profilePictureCache[playerName] then
		callback(profilePictureCache[playerName])
		return
	end

	task.spawn(function()
		local success, result = pcall(function()
			local targetPlayer = Players:FindFirstChild(playerName)
			if targetPlayer then
				return Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			end
			return nil
		end)

		if success and result then
			profilePictureCache[playerName] = result
			callback(result)
		else
			callback(nil)
		end
	end)
end

-- Main Notification Function
local function createKnockNotification(playerName, position, isKnocked)
	local themeColor = isKnocked and COLORS.KNOCKED or COLORS.REVIVED
	local statusTitle = isKnocked and "CRITICAL STATUS" or "REVIVED"
	local statusSub = isKnocked and "NEEDS ASSISTANCE" or "BACK IN ACTION"
	local iconId = isKnocked and "rbxassetid://10151247863" or "rbxassetid://10151249576"
	local duration = isKnocked and 15 or 5 -- Show longer for knocked state

	-- 1. Card Frame (The main notification box)
	local card = Instance.new("Frame")
	card.Name = "NotificationCard"
	card.Size = UDim2.new(1, 0, 0, 80)
	card.BackgroundColor3 = COLORS.BG
	card.BackgroundTransparency = 0.15 -- Glass effect base
	card.BorderSizePixel = 0
	-- Initial Position for animation (Offset to the right)
	card.Position = UDim2.new(1.2, 0, 0, 0) 
	card.Parent = notificationContainer

	-- Blur effect (Glassmorphism simulation) - Note: Blur only works on lighting/camera, 
	-- but we simulate it with transparency and stroke. 
	-- Ideally, we'd use a CanvasGroup if we wanted real opacity control, 
	-- but Frame is safer for performance here.

	-- Rounded Corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 8)
	uiCorner.Parent = card

	-- Stroke (Border)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.9
	stroke.Thickness = 1
	stroke.Parent = card

	-- Gradient Background (Subtle)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(COLORS.BG)
	gradient.Transparency = NumberSequence.new(0.15)
	gradient.Parent = card

	-- 2. Left Accent Bar (Type Indicator)
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 4, 1, 0)
	accentBar.BackgroundColor3 = themeColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 8)
	accentCorner.Parent = accentBar

	-- Clip the accent bar to be square on right side? 
	-- Actually, let's just put it inside and mask it if needed, or keep it simple.
	-- To match prototype "border-left: 4px", we place it at 0,0.
	-- To ensure it respects the card's rounded corners, we can put it inside a clipping container 
	-- OR just accept it overlaps. Let's adjust z-index or just position it nicely.
	-- Simpler approach: Just a bar on the left edge.

	-- 3. Layout Content (Padding)
	local contentArea = Instance.new("Frame")
	contentArea.Size = UDim2.new(1, -16, 1, 0)
	contentArea.Position = UDim2.new(0, 12, 0, 0) -- Offset for accent bar + padding
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = card

	-- Avatar Container
	local avatarSize = 50
	local avatarFrame = Instance.new("ImageLabel")
	avatarFrame.Name = "Avatar"
	avatarFrame.Size = UDim2.new(0, avatarSize, 0, avatarSize)
	avatarFrame.Position = UDim2.new(0, 0, 0.5, 0)
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	avatarFrame.BackgroundTransparency = 0
	avatarFrame.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	avatarFrame.Parent = contentArea

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 6) -- Square with rounded corners
	avatarCorner.Parent = avatarFrame

	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = Color3.fromRGB(71, 85, 105) -- Slate-600
	avatarStroke.Thickness = 1
	avatarStroke.Parent = avatarFrame

	getPlayerProfilePicture(playerName, function(img)
		if img and avatarFrame.Parent then
			avatarFrame.Image = img
		end
	end)

	-- Status Icon Overlay (Small circle on bottom-right of avatar)
	local iconOverlay = Instance.new("Frame")
	iconOverlay.Size = UDim2.new(0, 20, 0, 20)
	iconOverlay.Position = UDim2.new(1, 4, 1, 4)
	iconOverlay.AnchorPoint = Vector2.new(1, 1)
	iconOverlay.BackgroundColor3 = themeColor
	iconOverlay.BackgroundTransparency = 0.1
	iconOverlay.Parent = avatarFrame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0) -- Circle
	iconCorner.Parent = iconOverlay

	local iconImg = Instance.new("ImageLabel")
	iconImg.Size = UDim2.new(0.6, 0, 0.6, 0)
	iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
	iconImg.BackgroundTransparency = 1
	iconImg.Image = iconId
	iconImg.ImageColor3 = Color3.new(1,1,1)
	iconImg.Parent = iconOverlay

	-- Text Info
	local textContent = Instance.new("Frame")
	textContent.Size = UDim2.new(1, - (avatarSize + 12), 1, -16) -- Height minus padding top/bottom
	textContent.Position = UDim2.new(0, avatarSize + 12, 0, 8)
	textContent.BackgroundTransparency = 1
	textContent.Parent = contentArea

	-- Player Name (Top Left)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.7, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.upper(playerName)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = COLORS.TEXT_PRIMARY
	nameLabel.TextSize = 18
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	nameLabel.Parent = textContent

	-- Distance (Top Right)
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.new(0.3, 0, 0.5, 0)
	distanceLabel.Position = UDim2.new(0.7, 0, 0, 0)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Text = "0m"
	distanceLabel.Font = Enum.Font.Code -- Mono-ish font
	distanceLabel.TextColor3 = COLORS.TEXT_SECONDARY
	distanceLabel.TextSize = 12
	distanceLabel.TextXAlignment = Enum.TextXAlignment.Right
	distanceLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	distanceLabel.Parent = textContent

	-- Status Title (Bottom Left)
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0.5, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = statusTitle
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextColor3 = themeColor
	statusLabel.TextSize = 12
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.Parent = textContent

	-- Sub status (Next to status title, optional, or just append)
	-- Using RichText to combine if needed, but let's stick to the prototype clean look
	-- "CRITICAL STATUS" is enough for the bold part.

	local subStatusLabel = Instance.new("TextLabel")
	subStatusLabel.Size = UDim2.new(1, -100, 0.5, 0) -- Give space
	subStatusLabel.Position = UDim2.new(0, 105, 0.5, 0) -- Offset from status
	subStatusLabel.BackgroundTransparency = 1
	subStatusLabel.Text = statusSub
	subStatusLabel.Font = Enum.Font.Gotham
	subStatusLabel.TextColor3 = COLORS.TEXT_SECONDARY
	subStatusLabel.TextSize = 10
	subStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	subStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
	subStatusLabel.Parent = textContent

	-- Adjust Status Label width to fit content so sub-status can sit next to it?
	-- Actually, let's just put subStatus below or next to it. 
	-- Prototype: Title Left, Sub Left (stacked). 
	-- In code above I used 0.5 height for each row.
	-- Row 1: Name --- Distance
	-- Row 2: Status Title -- SubStatus

	statusLabel.Size = UDim2.new(0, 0, 0.5, 0) -- Auto size would be nice
	statusLabel.AutomaticSize = Enum.AutomaticSize.X

	subStatusLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subStatusLabel.Size = UDim2.new(1, 0, 0.5, 0)
	subStatusLabel.AnchorPoint = Vector2.new(0,0)
	-- Adjusted: Status Title on Left, SubStatus on Right
	statusLabel.Size = UDim2.new(0.5, 0, 0.5, 0) -- Half width
	statusLabel.Position = UDim2.new(0, 0, 0.5, 0)
	statusLabel.Text = statusTitle
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	subStatusLabel.Size = UDim2.new(0.5, 0, 0.5, 0) -- Half width
	subStatusLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Start from middle
	subStatusLabel.Text = statusSub
	subStatusLabel.TextXAlignment = Enum.TextXAlignment.Right -- Right aligned

	-- 4. Progress Bar (Bottom)
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBarBg"
	progressBg.Size = UDim2.new(1, 0, 0, 2)
	progressBg.Position = UDim2.new(0, 0, 1, -2)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = card

	-- Corner radius for bar?
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = themeColor
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = progressFill

	-- ANIMATIONS

	-- 1. Slide In (Using LayoutOrder requires parent to be setup, but tweening position in a list layout is tricky)
	-- Actually, UIListLayout ignores position properties. It handles them.
	-- To animate "slide in", we usually animate the Size or Transparency, or use a container.
	-- However, for a notification feed, a simple Fade In + Slide In effect works best if we use a CanvasGroup,
	-- but without CanvasGroup (performance), we can animate the children's transparency.
	-- Alternatively, we animate the element *before* parenting it to the list, but the list forces position immediately.

	-- Trick: Parent it, but set size to 0 first (Vertical expansion) or 
	-- Use a "Ghost" frame for the list, and the real card animates inside it.
	-- Let's try the Ghost Frame approach for smooth list expansion.

	-- Re-parent card to a wrapper
	local wrapper = Instance.new("Frame")
	wrapper.Name = "Wrapper_" .. playerName
	wrapper.Size = UDim2.new(1, 0, 0, 0) -- Start height 0
	wrapper.BackgroundTransparency = 1
	wrapper.ClipsDescendants = true -- Important for slide effect
	wrapper.Parent = notificationContainer

	card.Parent = wrapper
	card.Position = UDim2.new(1, 0, 0, 0) -- Start off-screen to the right inside wrapper

	-- Tween Wrapper Height (Expand list)
	local expandTween = TweenService:Create(wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 80)})
	expandTween:Play()

	-- Tween Card Position (Slide in from right)
	local slideTween = TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
	slideTween:Play()

	-- Distance Updater
	local connection
	local function updateDistance()
		if not card.Parent then return end
		local localChar = player.Character
		if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
			distanceLabel.Text = "?m"
			return
		end

		local dist = (localChar.HumanoidRootPart.Position - position).Magnitude
		distanceLabel.Text = math.floor(dist) .. "m"
	end

	connection = RunService.RenderStepped:Connect(updateDistance)

	-- Progress Bar Animation
	local progressTween = TweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
	progressTween:Play()

	-- Exit Logic
	task.delay(duration, function()
		if connection then connection:Disconnect() end

		-- Slide Out to Right
		local exitSlide = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)})
		exitSlide:Play()

		exitSlide.Completed:Connect(function()
			-- Collapse Wrapper
			local collapseTween = TweenService:Create(wrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)})
			collapseTween:Play()

			collapseTween.Completed:Connect(function()
				wrapper:Destroy()
			end)
		end)
	end)
end

-- Event Listener
GlobalKnockNotificationEvent.OnClientEvent:Connect(function(playerName, isKnocked, position)
	-- Self check
	if playerName == player.Name then return end

	-- Directly create (The list layout handles the queue visually)
	createKnockNotification(playerName, position, isKnocked)
end)

-- Clean up on Game Over
local GameOverEvent = ReplicatedStorage.RemoteEvents:WaitForChild("GameOverEvent")
GameOverEvent.OnClientEvent:Connect(function()
	-- Clear all notifications
	for _, child in ipairs(notificationContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end)
