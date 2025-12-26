-- DialogueController.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DialogueController.lua
-- Script Place: Lobby, ACT 1: Village
-- Description: Client-side handler for NPC dialogues with Typewriter effect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for Remotes
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local StartDialogueEvent = RemoteEvents:WaitForChild("StartDialogueEvent")

-- Module: DialogueConfig
local DialogueConfig = require(ReplicatedStorage:WaitForChild("ModuleScript"):WaitForChild("DialogueConfig"))

-- ================== THEME (Military/Tactical) ==================
local THEME = {
	Colors = {
		Background = Color3.fromRGB(10, 12, 10),
		Panel = Color3.fromRGB(20, 25, 20), -- Dark grey-green
		PanelBorder = Color3.fromRGB(50, 200, 80), -- Neon green border
		Text = Color3.fromRGB(220, 225, 220), -- Off-white
		SpeakerName = Color3.fromRGB(80, 255, 120), -- Bright tactical green
		Prompt = Color3.fromRGB(100, 180, 100), -- Muted green
		ChoiceDefault = Color3.fromRGB(35, 40, 35),
		ChoiceHover = Color3.fromRGB(50, 80, 50),
		ChoiceBorder = Color3.fromRGB(60, 180, 80),
	},
	Fonts = {
		Speaker = Enum.Font.Sarpanch, -- Military stencil-like
		Body = Enum.Font.SourceSans, -- Clean typewriter feel
		Prompt = Enum.Font.Code, -- Tactical/tech
		Choice = Enum.Font.Sarpanch,
	},
	TypewriterSpeed = 0.025, -- Slightly faster
}

-- ================== STATE ==================
local state = {
	isActive = false,
	currentDialogue = nil,
	currentNodeIndex = 1,
	skipRequested = false,
	typewriterComplete = false,
	isWaitingForChoice = false,
	currentJobId = 0, -- Unique ID for the current typewriter job
}

local skipToChoice = nil -- Forward declaration

-- ================== UI ==================
local dialogueGui = nil
local mainFrame = nil
local speakerLabel = nil
local textLabel = nil
local promptLabel = nil
local continueConnection = nil

local function createUI()
	if dialogueGui then return end

	dialogueGui = Instance.new("ScreenGui")
	dialogueGui.Name = "DialogueUI"
	dialogueGui.IgnoreGuiInset = true
	dialogueGui.ResetOnSpawn = false
	dialogueGui.DisplayOrder = 100
	dialogueGui.Parent = playerGui

	-- Cinematic Bars (Top & Bottom)
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0.08, 0)
	topBar.Position = UDim2.new(0, 0, -0.08, 0) -- Start hidden
	topBar.BackgroundColor3 = Color3.new(0, 0, 0)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 5
	topBar.Parent = dialogueGui

	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.Size = UDim2.new(1, 0, 0.08, 0)
	bottomBar.Position = UDim2.new(0, 0, 1, 0) -- Start hidden
	bottomBar.AnchorPoint = Vector2.new(0, 0)
	bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
	bottomBar.BorderSizePixel = 0
	bottomBar.ZIndex = 5
	bottomBar.Parent = dialogueGui

	-- Mobile Check
	local isMobile = UserInputService.TouchEnabled
	local panelWidth = isMobile and 0.95 or 0.75
	local panelHeight = isMobile and 0.25 or 0.20

	-- Main Dialogue Panel (Military/Tactical Style)
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "DialoguePanel"
	mainFrame.Size = UDim2.new(panelWidth, 0, panelHeight, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 1, 0) -- Start below screen
	mainFrame.AnchorPoint = Vector2.new(0.5, 1)
	mainFrame.BackgroundColor3 = THEME.Colors.Panel
	mainFrame.BackgroundTransparency = 0.15
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 10
	mainFrame.Parent = dialogueGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame

	-- Glowing Green Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Colors.PanelBorder
	stroke.Thickness = 3
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = mainFrame

	-- Inner glow effect (via secondary frame)
	local innerGlow = Instance.new("Frame")
	innerGlow.Name = "InnerGlow"
	innerGlow.Size = UDim2.new(1, -4, 1, -4)
	innerGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	innerGlow.BackgroundTransparency = 1
	innerGlow.ZIndex = 10
	innerGlow.Parent = mainFrame
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = THEME.Colors.PanelBorder
	innerStroke.Thickness = 1
	innerStroke.Transparency = 0.7
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	innerStroke.Parent = innerGlow
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = innerGlow

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.Parent = mainFrame

	-- Speaker Name (Top Left) - Military Stencil Style
	speakerLabel = Instance.new("TextLabel")
	speakerLabel.Name = "SpeakerName"
	speakerLabel.Size = UDim2.new(0.5, 0, 0.22, 0)
	speakerLabel.Position = UDim2.new(0, 0, 0, 0)
	speakerLabel.BackgroundTransparency = 1
	speakerLabel.Text = "COMMANDER"
	speakerLabel.Font = THEME.Fonts.Speaker
	speakerLabel.TextScaled = true
	speakerLabel.TextColor3 = THEME.Colors.SpeakerName
	speakerLabel.TextXAlignment = Enum.TextXAlignment.Left
	speakerLabel.ZIndex = 11
	speakerLabel.Parent = mainFrame

	local speakerConstraint = Instance.new("UITextSizeConstraint")
	speakerConstraint.MaxTextSize = 26
	speakerConstraint.Parent = speakerLabel

	-- Dialogue Text (Main Area) - Clean Typewriter Feel
	textLabel = Instance.new("TextLabel")
	textLabel.Name = "DialogueText"
	textLabel.Size = UDim2.new(1, 0, 0.55, 0)
	textLabel.Position = UDim2.new(0, 0, 0.22, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = ""
	textLabel.Font = THEME.Fonts.Body
	textLabel.TextScaled = true
	textLabel.TextColor3 = THEME.Colors.Text
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextWrapped = true
	textLabel.ZIndex = 11
	textLabel.Parent = mainFrame

	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = 22
	textConstraint.Parent = textLabel

	-- Continue Prompt (Bottom Right) - Tactical Style
	promptLabel = Instance.new("TextLabel")
	promptLabel.Name = "ContinuePrompt"
	promptLabel.Size = UDim2.new(0.35, 0, 0.18, 0)
	promptLabel.Position = UDim2.new(1, 0, 1, 0)
	promptLabel.AnchorPoint = Vector2.new(1, 1)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Text = "[ CLICK / ENTER ]"
	promptLabel.Font = THEME.Fonts.Prompt
	promptLabel.TextScaled = true
	promptLabel.TextColor3 = THEME.Colors.Prompt
	promptLabel.TextXAlignment = Enum.TextXAlignment.Right
	promptLabel.TextTransparency = 1 -- Hidden until text is complete
	promptLabel.ZIndex = 11
	promptLabel.Parent = mainFrame

	local promptConstraint = Instance.new("UITextSizeConstraint")
	promptConstraint.MaxTextSize = 14
	promptConstraint.Parent = promptLabel

	-- Skip Button (Tactical Style with Border)
	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipButton"
	skipBtn.Size = UDim2.new(0.12, 0, 0.25, 0) -- Converted to Scale
	skipBtn.Position = UDim2.new(1, 0, -0.3, 0) -- Moved up slightly
	skipBtn.AnchorPoint = Vector2.new(1, 0)
	skipBtn.BackgroundColor3 = THEME.Colors.ChoiceDefault
	skipBtn.BackgroundTransparency = 0.3
	skipBtn.Text = "SKIP >>"
	skipBtn.Font = THEME.Fonts.Prompt
	skipBtn.TextScaled = true -- Rule Compliance
	skipBtn.TextColor3 = THEME.Colors.Prompt
	skipBtn.ZIndex = 12
	skipBtn.Parent = mainFrame

	local skipPadding = Instance.new("UIPadding") -- Rule Compliance
	skipPadding.PaddingLeft = UDim.new(0.1, 0)
	skipPadding.PaddingRight = UDim.new(0.1, 0)
	skipPadding.Parent = skipBtn

	local skipSizeConstraint = Instance.new("UITextSizeConstraint")
	skipSizeConstraint.MaxTextSize = 18
	skipSizeConstraint.Parent = skipBtn

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 4)
	skipCorner.Parent = skipBtn

	local skipStroke = Instance.new("UIStroke")
	skipStroke.Color = THEME.Colors.ChoiceBorder
	skipStroke.Thickness = 1
	skipStroke.Transparency = 0.5
	skipStroke.Parent = skipBtn

	skipBtn.MouseEnter:Connect(function()
		skipBtn.BackgroundColor3 = THEME.Colors.ChoiceHover
	end)
	skipBtn.MouseLeave:Connect(function()
		skipBtn.BackgroundColor3 = THEME.Colors.ChoiceDefault
	end)
	skipBtn.MouseButton1Click:Connect(function()
		skipToChoice()
	end)

	dialogueGui.Enabled = false
end

-- ================== ANIMATION ==================
local function showUI()
	dialogueGui.Enabled = true

	local topBar = dialogueGui:FindFirstChild("TopBar")
	local bottomBar = dialogueGui:FindFirstChild("BottomBar")

	-- Animate bars (0.08 height bars)
	TweenService:Create(topBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0, 0)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 0.92, 0)}):Play()

	-- Animate panel
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.90, 0)}):Play()
end

local function hideUI()
	local topBar = dialogueGui:FindFirstChild("TopBar")
	local bottomBar = dialogueGui:FindFirstChild("BottomBar")

	-- Animate out
	TweenService:Create(topBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, -0.1, 0)}):Play()
	TweenService:Create(bottomBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 0, 1, 0)}):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, 0, 1.1, 0)}):Play()

	task.delay(0.5, function()
		dialogueGui.Enabled = false
	end)
end

-- ================== TYPEWRITER ==================
local function typewriterEffect(text, jobId)
	state.typewriterComplete = false
	state.skipRequested = false
	promptLabel.TextTransparency = 1
	textLabel.Text = ""

	-- Show Skip Button
	local skipBtn = mainFrame:FindFirstChild("SkipButton")
	if skipBtn then skipBtn.Visible = true end

	for i = 1, #text do
		if state.currentJobId ~= jobId then return end -- Job changed, abort

		if state.skipRequested then
			-- Skip to full text
			textLabel.Text = text
			break
		end

		textLabel.Text = string.sub(text, 1, i)
		task.wait(THEME.TypewriterSpeed)
	end

	if state.currentJobId ~= jobId then return end -- Check again

	-- Keep Skip Button visible until choice or end
	-- if skipBtn then skipBtn.Visible = false end

	textLabel.Text = text -- Ensure full text is shown
	state.typewriterComplete = true
	state.completionTime = os.clock() -- Track when it finished for safety

	-- Show prompt with fade
	TweenService:Create(promptLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	-- Blinking effect
	task.spawn(function()
		while state.isActive and state.typewriterComplete do
			if state.currentJobId ~= jobId then break end -- Job changed, abort
			for alpha = 0, 1, 0.1 do
				if not state.isActive or not state.typewriterComplete or state.currentJobId ~= jobId then break end
				promptLabel.TextTransparency = alpha * 0.5
				task.wait(0.05)
			end
			for alpha = 1, 0, -0.1 do
				if not state.isActive or not state.typewriterComplete or state.currentJobId ~= jobId then break end
				promptLabel.TextTransparency = alpha * 0.5
				task.wait(0.05)
			end
		end
	end)
end

-- ================== DIALOGUE FLOW ==================
local function displayNode(node)
	if not node then return end

	-- New Job
	state.currentJobId = state.currentJobId + 1

	speakerLabel.Text = string.upper(node.Speaker or "???" )

	-- [FIX] Spawn typewriter and wait for completion before showing choices
	task.spawn(function()
		typewriterEffect(node.Text or "", state.currentJobId)

		-- If job changed during wait, abort
		if state.currentJobId ~= state.currentJobId then return end

		-- Execute Actions
		if node.Actions then
			if node.Actions.PlaySound then
				-- Placeholder
			end
		end

		-- Handle Choices AFTER text is done
		if node.Choices and #node.Choices > 0 then
			state.isWaitingForChoice = true
			promptLabel.Visible = false -- Hide continue prompt

			-- Create container if missing
			local choiceContainer = mainFrame:FindFirstChild("ChoiceContainer")
			if not choiceContainer then
				choiceContainer = Instance.new("Frame")
				choiceContainer.Name = "ChoiceContainer"
				choiceContainer.Size = UDim2.new(0.5, 0, 0.6, 0) -- Reduced width to 50%
				choiceContainer.Position = UDim2.new(1, 0, -0.1, 0) -- Align to Right edge
				choiceContainer.AnchorPoint = Vector2.new(1, 1) -- Bottom-Right anchor
				choiceContainer.BackgroundTransparency = 1
				choiceContainer.Parent = mainFrame

				local layout = Instance.new("UIListLayout")
				layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Right -- Align items to Right
				layout.Padding = UDim.new(0.05, 0) 
				layout.Parent = choiceContainer
			end

			-- clear old choices
			for _, child in ipairs(choiceContainer:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			-- Spawn buttons (Tactical Style)
			for idx, choice in ipairs(node.Choices) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0.25, 0) -- Scale Height
				btn.BackgroundColor3 = THEME.Colors.ChoiceDefault
				btn.BackgroundTransparency = 0.1
				btn.Text = "  [ " .. idx .. " ]  " .. choice.Text:upper()
				btn.TextColor3 = THEME.Colors.Text
				btn.Font = THEME.Fonts.Choice
				btn.TextScaled = true -- Rule Compliance
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.ZIndex = 12
				btn.Parent = choiceContainer

				local btnPadding = Instance.new("UIPadding") -- Rule Compliance
				btnPadding.PaddingLeft = UDim.new(0.05, 0)
				btnPadding.Parent = btn

				local btnSizeConstraint = Instance.new("UITextSizeConstraint")
				btnSizeConstraint.MaxTextSize = 20
				btnSizeConstraint.Parent = btn

				-- Styling
				local stroke = Instance.new("UIStroke")
				stroke.Color = THEME.Colors.ChoiceBorder
				stroke.Thickness = 2
				stroke.Transparency = 0.3
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Parent = btn

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 6)
				corner.Parent = btn

				-- Hover Effects
				btn.MouseEnter:Connect(function()
					btn.BackgroundColor3 = THEME.Colors.ChoiceHover
					stroke.Color = THEME.Colors.SpeakerName
					stroke.Transparency = 0
				end)
				btn.MouseLeave:Connect(function()
					btn.BackgroundColor3 = THEME.Colors.ChoiceDefault
					stroke.Color = THEME.Colors.ChoiceBorder
					stroke.Transparency = 0.3
				end)

				-- Click event
				btn.MouseButton1Click:Connect(function()
					state.isWaitingForChoice = false

					-- Handle Signal
					if choice.Signal then
						-- Fire BindableEvent for UI
						local evt = ReplicatedStorage:FindFirstChild(choice.Signal .. "UI")
						if evt then 
							evt:Fire() 
						else
							-- Fallback: If signal is full event name
							evt = ReplicatedStorage:FindFirstChild(choice.Signal)
							if evt then evt:Fire() end
						end
					end

					-- Find next node based on choice
					if choice.NextID then
						-- Manual advance logic for choice
						local nextNodeID = choice.NextID

						-- Find next node
						local found = false
						for i, n in ipairs(state.currentDialogue) do
							if n.ID == nextNodeID then
								state.currentNodeIndex = i
								displayNode(n)
								found = true
								break
							end
						end
						if not found then endDialogue() end
					else
						endDialogue()
					end

					-- Clear choices
					for _, c in ipairs(choiceContainer:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
				end)
			end
		else
			state.isWaitingForChoice = false
			promptLabel.Visible = true
		end
	end)
end

local function advanceDialogue()
	if not state.isActive or not state.currentDialogue then return end
	if state.isWaitingForChoice then return end -- Block advance if waiting for choice

	-- If typewriter is still running, skip it
	if not state.typewriterComplete then
		state.skipRequested = true
		return
	end

	-- Safety check removed as per user request for fast skipping
	-- if os.clock() - (state.completionTime or 0) < 0.2 then return end

	local currentNode = state.currentDialogue[state.currentNodeIndex]
	if not currentNode then
		-- End of dialogue
		endDialogue()
		return
	end

	-- Get next node
	local nextID = currentNode.NextID
	if nextID == nil then
		-- Check for Signal on the final node
		if currentNode.Signal then
			local evt = ReplicatedStorage:FindFirstChild(currentNode.Signal .. "UI")
			if evt then 
				evt:Fire() 
			else
				-- Fallback
				evt = ReplicatedStorage:FindFirstChild(currentNode.Signal)
				if evt then evt:Fire() end
			end
		end

		-- No more nodes
		endDialogue()
		return
	end

	-- Find next node
	for i, node in ipairs(state.currentDialogue) do
		if node.ID == nextID then
			state.currentNodeIndex = i
			displayNode(node)
			return
		end
	end

	-- NextID not found, end dialogue
	endDialogue()
end

local isProcessingInput = false
local function safeAdvance()
	if isProcessingInput then return end
	isProcessingInput = true
	advanceDialogue()
	task.delay(0.2, function()
		isProcessingInput = false
	end)
end

skipToChoice = function()
	if not state.isActive or not state.currentDialogue then return end

	-- 1. Finish current typewriter if running
	if not state.typewriterComplete then
		state.skipRequested = true
		task.wait() -- Allow render cycle to update
	end

	-- 2. Find next node with choices
	local currentNode = state.currentDialogue[state.currentNodeIndex]

	-- [FIX] If current node already has choices, stop here and let them show
	if currentNode and currentNode.Choices and #currentNode.Choices > 0 then
		return
	end

	local nextNodeID = currentNode and currentNode.NextID
	local targetNode = nil
	local targetIndex = nil

	-- BFS/Traversal to find next choice
	-- Simple traversal following NextID
	local ptrID = nextNodeID
	local loopCount = 0
	while ptrID and loopCount < 50 do -- Safety limit
		loopCount += 1
		-- Find node with ptrID
		local foundNode = nil
		local foundIdx = nil
		for i, node in ipairs(state.currentDialogue) do
			if node.ID == ptrID then
				foundNode = node
				foundIdx = i
				break
			end
		end

		if foundNode then
			-- Check if this node has choices
			if foundNode.Choices and #foundNode.Choices > 0 then
				targetNode = foundNode
				targetIndex = foundIdx
				break
			end
			ptrID = foundNode.NextID
		else
			break -- Broken link
		end
	end

	if targetNode then
		state.currentNodeIndex = targetIndex
		displayNode(targetNode)
	else
		-- No choices found ahead, end dialogue
		endDialogue()
	end
end

local distanceConnection = nil
local characterConnection = nil

local function startDialogue(dialogueID, sourcePos)
	local dialogue = DialogueConfig.GetDialogue(dialogueID)
	if not dialogue or #dialogue == 0 then
		warn("DialogueController: Invalid dialogue ID:", dialogueID)
		return
	end

	state.isActive = true
	state.currentDialogue = dialogue
	state.currentNodeIndex = 1

	createUI()
	showUI()
	displayNode(dialogue[1])

	-- Update Skip Button connection
	local skipBtn = mainFrame:FindFirstChild("SkipButton")
	if skipBtn then
		-- Reconnect skip button logic just in case
		skipBtn.MouseButton1Click:Connect(function()
			skipToChoice()
		end)
	end


	-- Connect input
	if continueConnection then continueConnection:Disconnect() end
	continueConnection = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch or
			input.KeyCode == Enum.KeyCode.Return or
			input.KeyCode == Enum.KeyCode.E then
			safeAdvance() -- safeAdvance is now just a debounce wrapper
		end
	end)

	-- Distance & Death Check
	if distanceConnection then distanceConnection:Disconnect() end
	if characterConnection then characterConnection:Disconnect() end

	-- Death Check
	characterConnection = player.CharacterRemoving:Connect(function()
		endDialogue()
	end)

	-- Distance Check
	if sourcePos then
		distanceConnection = RunService.RenderStepped:Connect(function()
			if not state.isActive then 
				if distanceConnection then distanceConnection:Disconnect() end
				return
			end

			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local dist = (char.HumanoidRootPart.Position - sourcePos).Magnitude
				if dist > 20 then -- 20 studs max distance
					endDialogue()
				end
			end
		end)
	end
end



function endDialogue()
	state.isActive = false
	state.currentDialogue = nil
	state.currentNodeIndex = 1
	state.typewriterComplete = false

	if continueConnection then
		continueConnection:Disconnect()
		continueConnection = nil
	end

	if distanceConnection then
		distanceConnection:Disconnect()
		distanceConnection = nil
	end
	if characterConnection then
		characterConnection:Disconnect()
		characterConnection = nil
	end

	hideUI()
end

-- ================== REMOTE EVENT ==================
StartDialogueEvent.OnClientEvent:Connect(function(dialogueID, sourcePos)
	if state.isActive then return end -- Don't interrupt ongoing dialogue
	startDialogue(dialogueID, sourcePos)
end)

-- ================== INIT ==================
createUI()
print("DialogueController Initialized.")
