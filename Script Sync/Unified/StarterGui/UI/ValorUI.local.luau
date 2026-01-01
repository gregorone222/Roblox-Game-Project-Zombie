-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- ValorUI.local.luau (LocalScript)
-- Path: StarterGui/UI/ValorUI.local.luau
-- Script Place: ACT 1: Village

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
local FONTS = {
	Label = Enum.Font.GothamBold,
	Value = Enum.Font.SciFi -- Similar to Black Ops One
}

local COLORS = {
	Background = Color3.fromRGB(20, 10, 10),
	Border = Color3.fromRGB(220, 38, 38),
	TextLabel = Color3.fromRGB(156, 163, 175), -- Slate-400
	TextValue = Color3.fromRGB(255, 255, 255),
	AccentStart = Color3.fromRGB(239, 68, 68),
	AccentEnd = Color3.fromRGB(127, 29, 29),
	IconBg = Color3.fromRGB(69, 10, 10),
	Gain = Color3.fromRGB(74, 222, 128), -- Green-400
	Loss = Color3.fromRGB(248, 113, 113) -- Red-400
}

local VALOR_ICON_ASSET_ID = "rbxassetid://94386323640684" -- Valor icon

-- --- UI CREATION ---

-- Main Card Container
local card = Instance.new("Frame")
card.Name = "ValorContainer"
card.BackgroundColor3 = COLORS.Background
card.BackgroundTransparency = 0.15
card.BorderSizePixel = 0
card.ClipsDescendants = false -- Allow shadow/glow to show
card.Parent = screenGui

local cardScale = Instance.new("UIScale")
cardScale.Parent = card

-- Card Shape & Border
local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 12)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = COLORS.Border
cardStroke.Transparency = 0.7
cardStroke.Thickness = 1.5
cardStroke.Parent = card

-- Icon Container (Circle)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.BackgroundColor3 = COLORS.IconBg
iconContainer.BackgroundTransparency = 0.3
iconContainer.Size = UDim2.new(0, 45, 0, 45)
iconContainer.Position = UDim2.new(0, 10, 0.5, 0) -- Adjusted left position since bar is gone
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.Parent = card

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0) -- Circle
iconCorner.Parent = iconContainer

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = COLORS.AccentStart
iconStroke.Transparency = 0.5
iconStroke.Thickness = 1.5
iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
iconStroke.Parent = iconContainer

-- Icon Image (Using Asset ID instead of emoji)
local iconImage = Instance.new("ImageLabel")
iconImage.Name = "Icon"
iconImage.Size = UDim2.new(0.75, 0, 0.75, 0)
iconImage.Position = UDim2.new(0.5, 0, 0.5, 0)
iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
iconImage.BackgroundTransparency = 1
iconImage.Image = VALOR_ICON_ASSET_ID
iconImage.ScaleType = Enum.ScaleType.Fit
iconImage.Parent = iconContainer

-- Content Layout (Text)
local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.BackgroundTransparency = 1
contentFrame.Size = UDim2.new(1, -65, 1, -10)
contentFrame.Position = UDim2.new(0, 65, 0, 5) -- Adjusted left padding
contentFrame.Parent = card

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, -2)
listLayout.Parent = contentFrame

-- Label "VALOR"
local labelText = Instance.new("TextLabel")
labelText.Name = "Label"
labelText.BackgroundTransparency = 1
labelText.Size = UDim2.new(1, 0, 0, 14)
labelText.Text = "VALOR"
labelText.TextColor3 = COLORS.TextLabel
labelText.TextXAlignment = Enum.TextXAlignment.Left
labelText.Font = FONTS.Label
labelText.TextSize = 12
labelText.LayoutOrder = 1
labelText.Parent = contentFrame

-- Value Number
local valueText = Instance.new("TextLabel")
valueText.Name = "Value"
valueText.BackgroundTransparency = 1
valueText.Size = UDim2.new(1, 0, 0, 32)
valueText.Text = "0"
valueText.TextColor3 = COLORS.TextValue
valueText.TextXAlignment = Enum.TextXAlignment.Left
valueText.Font = FONTS.Value
valueText.TextSize = 32
valueText.LayoutOrder = 2
valueText.Parent = contentFrame

-- Add UIScale to Value Text for easy enlarging without layout issues (layout ignores UIScale changes)
local valueScale = Instance.new("UIScale")
valueScale.Parent = valueText

-- Glow Effect using UIStroke on Text
local valueGlow = Instance.new("UIStroke")
valueGlow.Name = "Glow"
valueGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Applies to text outline
valueGlow.Thickness = 0
valueGlow.Transparency = 1
valueGlow.Color = Color3.fromRGB(239, 68, 68) -- Red-500
valueGlow.Parent = valueText

local valueGradient = Instance.new("UIGradient")
valueGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 113, 113))
})
valueGradient.Rotation = 90
valueGradient.Parent = valueText

-- --- RESPONSIVE LOGIC ---

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function updateLayout()
	if isMobile() then
		card.Size = UDim2.new(0, 180, 0, 50)
		card.Position = UDim2.new(1, -10, 0, 60) -- Below top-right controls
		card.AnchorPoint = Vector2.new(1, 0)

		iconContainer.Size = UDim2.new(0, 35, 0, 35)
		iconContainer.Position = UDim2.new(0, 8, 0.5, 0)
		iconImage.Size = UDim2.new(0.7, 0, 0.7, 0)

		contentFrame.Position = UDim2.new(0, 50, 0, 5)
		contentFrame.Size = UDim2.new(1, -50, 1, -10)

		labelText.TextSize = 10
		valueText.TextSize = 24
	else
		card.Size = UDim2.new(0, 240, 0, 65)
		card.Position = UDim2.new(1, -20, 0, 20) -- Top Right
		card.AnchorPoint = Vector2.new(1, 0)

		iconContainer.Size = UDim2.new(0, 45, 0, 45)
		iconContainer.Position = UDim2.new(0, 12, 0.5, 0)
		iconImage.Size = UDim2.new(0.75, 0, 0.75, 0)

		contentFrame.Position = UDim2.new(0, 65, 0, 5)
		contentFrame.Size = UDim2.new(1, -65, 1, -10)

		labelText.TextSize = 12
		valueText.TextSize = 34
	end
end

updateLayout()
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)

-- --- ANIMATION LOGIC ---

-- Format number: 1250 -> 1.250 (Indonesian/European style for thousands)
local function formatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

-- Shake Effect
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

-- Bounce Card Effect (Scale Up)
local function bounceCard()
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)
	local tween = TweenService:Create(cardScale, tweenInfo, { Scale = 1.05 })
	tween:Play()
end

-- Pulse Effect for Value (Scale + Glow, no flying text)
local function pulseValue()
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, true)

	-- 1. Color Flash
	local colorTween = TweenService:Create(valueText, tweenInfo, { TextColor3 = Color3.fromRGB(252, 165, 165) }) -- Flash Red
	colorTween:Play()

	-- 2. Scale Up (Enlarge)
	local scaleTween = TweenService:Create(valueScale, tweenInfo, { Scale = 1.3 }) -- Scale to 1.3x
	scaleTween:Play()

	-- 3. Glow (Stroke)
	local glowTween = TweenService:Create(valueGlow, tweenInfo, { 
		Thickness = 2, 
		Transparency = 0.3 
	})
	glowTween:Play()

	-- Return to normal
	task.delay(0.15, function()
		valueText.TextColor3 = COLORS.TextValue
		local returnInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		TweenService:Create(valueScale, returnInfo, { Scale = 1 }):Play()
		TweenService:Create(valueGlow, returnInfo, { Thickness = 0, Transparency = 1 }):Play()
	end)
end

-- Counting Animation
local currentDisplayValue = 0
local targetValue = 0
local countCoroutine = nil

local function updateDisplay()
	if currentDisplayValue == targetValue then return end

	-- Determine step
	local diff = targetValue - currentDisplayValue

	-- Handle negative differences correctly for math.ceil/floor
	local step
	if math.abs(diff) < 1 then
		currentDisplayValue = targetValue
		step = 0
	else
		-- Move 20% of distance, but at least 1 unit
		step = diff * 0.2
		if diff > 0 then
			step = math.ceil(step)
		else
			step = math.floor(step)
		end
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
			-- Positive Feedback: Enlarge + Glow + Card Bounce
			pulseValue()
			bounceCard()
		else
			-- Negative Feedback: Shake
			shakeCard(0.5)
		end
	end

	if countCoroutine then return end -- Loop already running

	countCoroutine = task.spawn(function()
		while currentDisplayValue ~= targetValue do
			updateDisplay()
			task.wait(0.03) -- ~30fps update
		end
		countCoroutine = nil
	end)
end

-- Event Listener for Valor updates
ValorUpdate.OnClientEvent:Connect(function(points)
	-- Show card if hidden (only after game has started)
	if not card.Visible then
		card.Visible = true
	end
	animateTo(points)
end)

-- Game Start Detection: Listen for WaveUpdateEvent to show UI
-- This ensures UI only appears when the game actually starts
local WaveUpdateEvent = RemoteEvents:FindFirstChild("WaveUpdateEvent")
if WaveUpdateEvent then
	WaveUpdateEvent.OnClientEvent:Connect(function(waveNumber)
		if not card.Visible then
			card.Visible = true
			-- Initialize to 0 if no Valor update received yet
			if valueText.Text == "0" then
				animateTo(0)
			end
		end
	end)
end

-- Start hidden - UI only appears when game starts (wave 1)
card.Visible = false
