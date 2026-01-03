-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- ValorUI.local.luau (LocalScript)
-- Path: StarterGui/UI/ValorUI.local.luau
-- Script Place: ACT 1: Village
-- Theme: Apocalypse Survival (Matched to Inventory, Ammo, StatusHUD)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local ValorUpdate = RemoteEvents:WaitForChild("ValorUpdate")

-- cleanup old UI if exists
for _, old in ipairs(playerGui:GetChildren()) do
	if old.Name == "ValorUI" then
		old:Destroy()
	end
end

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ValorUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- --- CONFIGURATION ---
local THEME = {
	Colors = {
		Background = Color3.fromRGB(20, 16, 12),      -- Warm dark brown
		Panel      = Color3.fromRGB(35, 28, 22),      -- Warm brown panel
		Border     = Color3.fromRGB(139, 90, 43),     -- Forest Brown
		Accent     = Color3.fromRGB(218, 165, 32),    -- Golden
		AccentHigh = Color3.fromRGB(255, 200, 80),    -- Bright Amber
		TextMain   = Color3.fromRGB(255, 248, 230),   -- Warm white
		TextDim    = Color3.fromRGB(180, 160, 130),   -- Muted gold
		Gain       = Color3.fromRGB(46, 204, 113),    -- Green (Success)
		Loss       = Color3.fromRGB(231, 76, 60)      -- Red (Error)
	},
	Fonts = {
		Header = Enum.Font.GothamBold,
		Body   = Enum.Font.GothamMedium,
		Mono   = Enum.Font.Code
	}
}

local VALOR_ICON_ASSET_ID = "rbxassetid://94386323640684" -- Valor icon

-- --- HELPER FUNCTIONS ---
local function create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do inst[k] = v end
	return inst
end

local function addCorner(parent, radius)
	create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius or 8)})
end

local function addStroke(parent, color, thickness)
	create("UIStroke", {
		Parent = parent, Color = color or THEME.Colors.Border,
		Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 0 -- Ensure visible
	})
end

-- --- UI CREATION ---

-- Main Card Container
local card = create("Frame", {
	Name = "ValorContainer",
	BackgroundColor3 = THEME.Colors.Background,
	BackgroundTransparency = 0.2, -- Glassy
	BorderSizePixel = 0,
	Parent = screenGui
})
addCorner(card, 12)
addStroke(card, THEME.Colors.Border, 2)

-- Inner Gradient
local grad = create("UIGradient", {
	Parent = card,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.8, 0.8, 0.8))
	}),
	Rotation = 90
})

local cardScale = create("UIScale", {Parent = card})

-- Icon Container (Circle)
local iconContainer = create("Frame", {
	Name = "IconContainer",
	BackgroundColor3 = THEME.Colors.Panel,
	BackgroundTransparency = 0.3,
	Size = UDim2.new(0, 40, 0, 40),
	AnchorPoint = Vector2.new(0, 0.5),
	Parent = card
})
addCorner(iconContainer, 20) -- Circle
local iconStroke = create("UIStroke", {
	Parent = iconContainer, Color = THEME.Colors.Accent,
	Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border
})

local iconImage = create("ImageLabel", {
	Parent = iconContainer, Name = "Icon",
	Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
	Image = VALOR_ICON_ASSET_ID, ImageColor3 = THEME.Colors.AccentHigh,
	ScaleType = Enum.ScaleType.Fit
})

-- Content
local contentFrame = create("Frame", {
	Name = "Content", BackgroundTransparency = 1, Parent = card
})

local listLayout = create("UIListLayout", {
	Parent = contentFrame, FillDirection = Enum.FillDirection.Vertical,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 0)
})

local labelText = create("TextLabel", {
	Parent = contentFrame, Name = "Label", BackgroundTransparency = 1,
	Text = "VALOR", TextColor3 = THEME.Colors.Accent,
	Font = THEME.Fonts.Header, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1
})

local valueText = create("TextLabel", {
	Parent = contentFrame, Name = "Value", BackgroundTransparency = 1,
	Text = "0", TextColor3 = THEME.Colors.TextMain,
	Font = THEME.Fonts.Mono, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left,
	Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 2
})

local valueScale = create("UIScale", {Parent = valueText})

-- Glow on Value
local valueGlow = create("UIStroke", {
	Parent = valueText, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	Thickness = 0, Transparency = 1, Color = THEME.Colors.AccentHigh
})

-- --- RESPONSIVE LOGIC ---

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function updateLayout()
	if isMobile() then
		card.Size = UDim2.new(0, 140, 0, 45)
		card.Position = UDim2.new(1, -10, 0, 80) -- Adjusted below other UIs
		card.AnchorPoint = Vector2.new(1, 0)

		iconContainer.Size = UDim2.new(0, 32, 0, 32)
		iconContainer.Position = UDim2.new(0, 6, 0.5, 0)
		
		contentFrame.Position = UDim2.new(0, 44, 0, 0)
		contentFrame.Size = UDim2.new(1, -44, 1, 0)

		labelText.TextSize = 8
		valueText.TextSize = 18
	else
		card.Size = UDim2.new(0, 180, 0, 55)
		card.Position = UDim2.new(1, -30, 0, 20) -- Top Right
		card.AnchorPoint = Vector2.new(1, 0)

		iconContainer.Size = UDim2.new(0, 40, 0, 40)
		iconContainer.Position = UDim2.new(0, 10, 0.5, 0)

		contentFrame.Position = UDim2.new(0, 60, 0, 0)
		contentFrame.Size = UDim2.new(1, -60, 1, 0)

		labelText.TextSize = 10
		valueText.TextSize = 24
	end
end

updateLayout()
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)

-- --- ANIMATION LOGIC ---

local function formatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if (k==0) then break end
	end
	return formatted
end

local function shakeCard(intensity)
	local originalPos = card.Position
	local duration = 0.4
	local startTime = os.clock()
	task.spawn(function()
		while os.clock() - startTime < duration do
			local elapsed = os.clock() - startTime
			local decay = 1 - (elapsed / duration)
			local offsetX = (math.random() - 0.5) * intensity * decay * 10
			local offsetY = (math.random() - 0.5) * intensity * decay * 5
			card.Position = UDim2.new(
				originalPos.X.Scale, originalPos.X.Offset + offsetX,
				originalPos.Y.Scale, originalPos.Y.Offset + offsetY
			)
			RunService.Heartbeat:Wait()
		end
		card.Position = originalPos
	end)
end

local function bounceCard()
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(cardScale, tweenInfo, { Scale = 1.05 }):Play()
end

local function pulseValue()
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
	
	-- Gold Flash
	TweenService:Create(valueText, tweenInfo, { TextColor3 = THEME.Colors.AccentHigh }):Play()
	TweenService:Create(valueScale, tweenInfo, { Scale = 1.2 }):Play()
	TweenService:Create(valueGlow, tweenInfo, { Thickness = 2, Transparency = 0.3 }):Play()

	task.delay(0.15, function()
		local returnInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(valueText, returnInfo, { TextColor3 = THEME.Colors.TextMain }):Play()
		TweenService:Create(valueScale, returnInfo, { Scale = 1 }):Play()
		TweenService:Create(valueGlow, returnInfo, { Thickness = 0, Transparency = 1 }):Play()
	end)
end

local currentDisplayValue = 0
local targetValue = 0
local countCoroutine = nil

local function updateDisplay()
	if currentDisplayValue == targetValue then return end
	local diff = targetValue - currentDisplayValue
	local step
	if math.abs(diff) < 1 then
		currentDisplayValue = targetValue
		step = 0
	else
		step = diff * 0.2
		if diff > 0 then step = math.ceil(step) else step = math.floor(step) end
	end
	currentDisplayValue += step
	valueText.Text = formatNumber(currentDisplayValue)
end

local function animateTo(newValue)
	local oldValue = targetValue
	targetValue = newValue

	local diff = targetValue - oldValue
	if diff ~= 0 then
		if diff > 0 then
			pulseValue()
			bounceCard()
		else
			shakeCard(0.5)
		end
	end

	if countCoroutine then return end
	countCoroutine = task.spawn(function()
		while currentDisplayValue ~= targetValue do
			updateDisplay()
			task.wait(0.03)
		end
		countCoroutine = nil
	end)
end

-- Event Listeners
ValorUpdate.OnClientEvent:Connect(function(points)
	if not card.Visible then card.Visible = true end
	animateTo(points)
end)

local WaveUpdateEvent = RemoteEvents:FindFirstChild("WaveUpdateEvent")
if WaveUpdateEvent then
	WaveUpdateEvent.OnClientEvent:Connect(function(waveNumber)
		if not card.Visible then
			card.Visible = true
			if valueText.Text == "0" then animateTo(0) end
		end
	end)
end

-- Start hidden
card.Visible = false
