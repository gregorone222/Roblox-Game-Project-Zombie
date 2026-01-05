-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- MeleeClient.local.luau (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/Client/MeleeClient.local.luau
-- Purpose: Handle melee weapon input, animations, and effects

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Modules
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))
-- HybridViewmodel removed - using manual viewmodel approach
-- local HybridViewmodel = require(ReplicatedStorage.ModuleScript:WaitForChild("HybridViewmodel"))
local AudioManager = require(ReplicatedStorage.ModuleScript:WaitForChild("AudioManager"))

-- Remote Events
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MeleeAttackEvent = RemoteEvents:FindFirstChild("MeleeAttackEvent")
if not MeleeAttackEvent then
	MeleeAttackEvent = Instance.new("RemoteEvent")
	MeleeAttackEvent.Name = "MeleeAttackEvent"
	MeleeAttackEvent.Parent = RemoteEvents
end

local BindableEvents = ReplicatedStorage:WaitForChild("BindableEvents")

-- Track stamina from server
local currentStamina = 100
local StaminaUpdateEvent = RemoteEvents:FindFirstChild("StaminaUpdate")
if StaminaUpdateEvent then
	StaminaUpdateEvent.OnClientEvent:Connect(function(stamina)
		currentStamina = stamina
	end)
end

-- State
local currentMelee = nil
local meleeName = nil
local meleeStats = nil
-- local viewmodel = nil -- Removed: using manual viewmodel
local isAttacking = false
local canAttack = true
local nextAttackTime = 0
local isKnocked = false
local isGameOver = false

local currentHoldTrack = nil
local currentAttackTrack = nil
local connections = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- MANUAL MELEE VIEWMODEL SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

-- Viewmodel state
local meleeViewmodel = nil
local viewmodelAnimator = nil
local viewmodelHoldTrack = nil
local viewmodelAttackTrack = nil
local viewmodelUpdateConnection = nil

-- Per-animation offset system
local currentAnimState = "Hold"  -- Current animation state (Hold, Attack, etc.)
local currentVMPosition = Vector3.new(0.5, -1.5, -2)
local currentVMRotation = Vector3.new(0, 0, 0)
local targetVMPosition = Vector3.new(0.5, -1.5, -2)
local targetVMRotation = Vector3.new(0, 0, 0)
local VM_LERP_SPEED = 10  -- Speed of position/rotation interpolation

-- Default offset (used if no per-animation offset defined)
local DEFAULT_VM_POSITION = Vector3.new(0.5, -1.5, -2)
local DEFAULT_VM_ROTATION = Vector3.new(0, 0, 0)

-- Sway, Bob, and Breath state
local lastCameraCFrame = camera.CFrame
local currentSway = Vector3.new(0, 0, 0)
local targetSway = Vector3.new(0, 0, 0)
local currentBob = Vector3.new(0, 0, 0)
local bobTime = 0
local breathTime = 0

-- Sway/Bob/Breath config (will be loaded from WeaponModule)
local swayIntensity = 0.3
local swaySmoothing = 12
local bobIntensity = 0.4
local bobSmoothing = 10
local bobFrequency = 10
local breathIntensity = 0.05
local breathSpeed = 2

-- Viewmodel folder path (weapon-specific viewmodels stored here)

-- Get ViewmodelBase folder
local ViewmodelFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Viewmodel")

-- Helper function to get animation offset
local function getAnimationOffset(animName)
	if not meleeStats then return DEFAULT_VM_POSITION, DEFAULT_VM_ROTATION end
	
	local vmAnims = meleeStats.ViewmodelAnimations
	if vmAnims and vmAnims[animName] then
		local animData = vmAnims[animName]
		if type(animData) == "table" then
			local pos = animData.Position or DEFAULT_VM_POSITION
			local rot = animData.Rotation or DEFAULT_VM_ROTATION
			return pos, rot
		end
	end
	
	-- Fallback to Animations section
	local anims = meleeStats.Animations
	if anims and anims[animName] then
		local animData = anims[animName]
		if type(animData) == "table" then
			local pos = animData.Position or DEFAULT_VM_POSITION
			local rot = animData.Rotation or DEFAULT_VM_ROTATION
			return pos, rot
		end
	end
	
	return DEFAULT_VM_POSITION, DEFAULT_VM_ROTATION
end

-- Set target animation offset (call when changing animation)
local function setAnimationOffset(animName)
	currentAnimState = animName
	targetVMPosition, targetVMRotation = getAnimationOffset(animName)
end

-- Load sway/bob/breath config from WeaponModule
local function loadSwayBobConfig()
	if not meleeStats then return end
	
	swayIntensity = meleeStats.SwayIntensity or 0.3
	swaySmoothing = meleeStats.SwaySmoothing or 12
	bobIntensity = meleeStats.BobIntensity or 0.4
	bobSmoothing = meleeStats.BobSmoothing or 10
	bobFrequency = meleeStats.BobFrequency or 10
	breathIntensity = meleeStats.BreathIntensity or 0.05
	breathSpeed = meleeStats.BreathSpeed or 2
end

-- Calculate camera sway based on mouse/camera movement
local function calculateSway(cameraDelta)
	local intensity = swayIntensity
	local smoothing = swaySmoothing
	local swayFactor = intensity / smoothing
	
	return Vector3.new(
		-cameraDelta.Y * swayFactor * 0.5,
		-cameraDelta.X * swayFactor,
		cameraDelta.X * swayFactor * 0.2
	)
end

-- Calculate movement bob based on player velocity
local function calculateBob(dt)
	local char = player.Character
	if not char then return Vector3.new() end
	
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return Vector3.new() end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return Vector3.new() end
	
	local velocity = hrp.AssemblyLinearVelocity
	local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	local maxSpeed = humanoid.WalkSpeed
	
	-- No bob when stationary
	if speed < 0.1 then
		bobTime = 0
		return Vector3.new()
	end
	
	-- Update bob time based on movement speed
	bobTime = bobTime + dt * (speed / maxSpeed) * bobFrequency
	
	local bobX = math.sin(bobTime * 0.5) * bobIntensity * 0.1
	local bobY = math.sin(bobTime) * bobIntensity * 0.2
	local bobZ = math.cos(bobTime * 0.5) * bobIntensity * 0.05
	
	return Vector3.new(bobX, bobY, bobZ)
end

-- Calculate breathing effect (subtle up/down motion when idle)
local function calculateBreath(dt)
	breathTime = breathTime + dt * breathSpeed
	local breathOffset = math.sin(breathTime) * breathIntensity * 0.1
	return Vector3.new(0, breathOffset, 0)
end

local function createMeleeViewmodel(tool)
	-- Cleanup existing
	if meleeViewmodel then
		meleeViewmodel:Destroy()
		meleeViewmodel = nil
	end
	if viewmodelUpdateConnection then
		viewmodelUpdateConnection:Disconnect()
		viewmodelUpdateConnection = nil
	end
	
	-- Try to find weapon-specific ViewmodelBase (e.g., ViewmodelBaseBat for Bat)
	-- Falls back to generic ViewmodelBase if not found
	local weaponName = tool.Name
	local viewmodelName = "ViewmodelBase" .. weaponName  -- e.g., "ViewmodelBaseBat"
	local viewmodelTemplate = ViewmodelFolder:FindFirstChild(viewmodelName)
	
	if not viewmodelTemplate then
		viewmodelTemplate = ViewmodelFolder:FindFirstChild("ViewmodelBase")
		print("[MeleeClient] Using generic ViewmodelBase for:", weaponName)
	else
		print("[MeleeClient] Using weapon-specific viewmodel:", viewmodelName)
	end
	
	if not viewmodelTemplate then
		warn("[MeleeClient] No viewmodel template found!")
		return
	end
	
	-- Clone viewmodel (with integrated weapon if weapon-specific)
	meleeViewmodel = viewmodelTemplate:Clone()
	meleeViewmodel.Name = "MeleeViewmodel"
	meleeViewmodel:SetAttribute("IsMeleeViewmodel", true)
	meleeViewmodel.Parent = camera
	
	-- Find root
	local rootPart = meleeViewmodel:FindFirstChild("HumanoidRootPart")
	
	if not rootPart then
		warn("[MeleeClient] Viewmodel missing HumanoidRootPart!")
		return
	end
	
	-- RADICAL FIX: Get Animator from Humanoid, move to AnimationController, then destroy Humanoid
	-- Humanoid causes physics bugs even when disabled!
	local humanoid = meleeViewmodel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Get or create Animator
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
		end
		
		-- Create AnimationController and move Animator there
		local animController = Instance.new("AnimationController")
		animController.Parent = meleeViewmodel
		animator.Parent = animController
		viewmodelAnimator = animator
		
		-- DESTROY HUMANOID COMPLETELY - no more physics bugs!
		humanoid:Destroy()
		print("[MeleeClient] Humanoid destroyed, using AnimationController")
	else
		-- Fallback: create AnimationController with Animator
		local animController = meleeViewmodel:FindFirstChildOfClass("AnimationController")
		if not animController then
			animController = Instance.new("AnimationController")
			animController.Parent = meleeViewmodel
		end
		local animator = animController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = animController
		end
		viewmodelAnimator = animator
	end
	
	-- Configure parts - only anchor HumanoidRootPart
	-- Motor6D requires non-anchored Part1 to animate!
	for _, part in pairs(meleeViewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			part.Massless = true
			part.Anchored = false  -- Motor6D needs this false!
		end
	end
	
	-- Only anchor the root - this is what gets positioned
	rootPart.Anchored = true
	meleeViewmodel.PrimaryPart = rootPart
	
	-- NOTE: Weapon is already integrated into weapon-specific viewmodel via Motor6D
	-- No need to clone weapon separately!
	
	-- Load sway/bob/breath config from weapon stats
	loadSwayBobConfig()
	
	-- Initialize offset for Hold animation
	setAnimationOffset("Hold")
	currentVMPosition = targetVMPosition
	currentVMRotation = targetVMRotation
	
	-- Initialize camera tracking for sway
	lastCameraCFrame = camera.CFrame
	
	-- Camera follow update with sway, bob, breath effects
	viewmodelUpdateConnection = RunService.RenderStepped:Connect(function(dt)
		if meleeViewmodel and rootPart and rootPart.Parent then
			-- Check if plugin offset editor is active (real-time editing)
			local editorFolder = ReplicatedStorage:FindFirstChild("VMOffsetEditor")
			local pluginActive = editorFolder and editorFolder:FindFirstChild("Active") and editorFolder.Active.Value == true
			
			if pluginActive then
				-- Use plugin values directly (no effects for clean preview)
				local posValue = editorFolder:FindFirstChild("Position")
				local rotValue = editorFolder:FindFirstChild("Rotation")
				if posValue then
					currentVMPosition = posValue.Value
					targetVMPosition = posValue.Value
				end
				if rotValue then
					currentVMRotation = rotValue.Value
					targetVMRotation = rotValue.Value
				end
				
				-- Simple CFrame without effects
				local offsetCFrame = CFrame.new(currentVMPosition) 
					* CFrame.Angles(
						math.rad(currentVMRotation.X), 
						math.rad(currentVMRotation.Y), 
						math.rad(currentVMRotation.Z)
					)
				rootPart.CFrame = camera.CFrame * offsetCFrame
			else
				-- Normal gameplay with sway, bob, breath
				
				-- Smooth interpolation for offset
				local lerpFactor = math.min(dt * VM_LERP_SPEED, 1)
				currentVMPosition = currentVMPosition:Lerp(targetVMPosition, lerpFactor)
				currentVMRotation = currentVMRotation:Lerp(targetVMRotation, lerpFactor)
				
				-- Calculate camera delta for sway
				local cameraDelta = camera.CFrame:ToObjectSpace(lastCameraCFrame)
				lastCameraCFrame = camera.CFrame
				
				-- Calculate sway
				targetSway = calculateSway(Vector2.new(cameraDelta.Y, cameraDelta.X))
				currentSway = currentSway:Lerp(targetSway, dt * swaySmoothing)
				
				-- Calculate bob and breath
				local bobOffset = calculateBob(dt)
				currentBob = currentBob:Lerp(bobOffset, dt * bobSmoothing)
				local breathOffset = calculateBreath(dt)
				
				-- Combine all effects
				local offsetCFrame = CFrame.new(currentVMPosition) 
					* CFrame.Angles(
						math.rad(currentVMRotation.X), 
						math.rad(currentVMRotation.Y), 
						math.rad(currentVMRotation.Z)
					)
					* CFrame.Angles(
						math.rad(currentSway.X),
						math.rad(currentSway.Y),
						math.rad(currentSway.Z)
					)
					* CFrame.new(currentBob + breathOffset)
				
				rootPart.CFrame = camera.CFrame * offsetCFrame
			end
		end
	end)
	
	print("[MeleeClient] Created melee viewmodel for:", tool.Name)
end

local function destroyMeleeViewmodel()
	if viewmodelHoldTrack then
		viewmodelHoldTrack:Stop(0)
		viewmodelHoldTrack = nil
	end
	if viewmodelAttackTrack then
		viewmodelAttackTrack:Stop(0)
		viewmodelAttackTrack = nil
	end
	if viewmodelUpdateConnection then
		viewmodelUpdateConnection:Disconnect()
		viewmodelUpdateConnection = nil
	end
	if meleeViewmodel then
		meleeViewmodel:Destroy()
		meleeViewmodel = nil
	end
	viewmodelAnimator = nil
end

local function playViewmodelAnimation(animId, loop, priority)
	if not viewmodelAnimator or not animId then return nil end
	
	-- CRITICAL: Stop ALL playing tracks on this animator to prevent conflicts
	local playingTracks = viewmodelAnimator:GetPlayingAnimationTracks()
	for _, track in ipairs(playingTracks) do
		track:Stop(0.1)
	end
	
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	
	local success, track = pcall(function()
		return viewmodelAnimator:LoadAnimation(anim)
	end)
	
	if not success or not track then
		warn("[MeleeClient] Failed to load viewmodel animation:", animId)
		return nil
	end
	
	track.Looped = loop or false
	track.Priority = priority or Enum.AnimationPriority.Action
	track:Play(0.1)  -- Small fade-in for smoother transition
	
	return track
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════════

local function cleanupMelee()
	if not currentMelee then return end

	-- Stop character animations
	if currentHoldTrack then
		currentHoldTrack:Stop(0.2)
		currentHoldTrack = nil
	end
	if currentAttackTrack then
		currentAttackTrack:Stop(0)
		currentAttackTrack = nil
	end

	-- Cleanup melee viewmodel
	destroyMeleeViewmodel()

	-- Disconnect connections
	for _, conn in pairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	currentMelee = nil
	meleeName = nil
	meleeStats = nil
	isAttacking = false
	canAttack = true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

local function isMeleeWeapon(tool)
	if not tool or not tool:IsA("Tool") then return false end
	local weaponData = WeaponModule.Weapons[tool.Name]
	return weaponData and weaponData.IsMelee == true
end

local function getAttackCooldown()
	if not meleeStats then return 1 end
	return meleeStats.AttackSpeed or 1.0 -- Default 1 second cooldown
end

local function isAttackCooldownReady()
	return tick() >= nextAttackTime
end

local function markJustAttacked()
	nextAttackTime = tick() + getAttackCooldown()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SETUP MELEE
-- ═══════════════════════════════════════════════════════════════════════════════

local function setupMelee(tool)
	cleanupMelee()

	currentMelee = tool
	meleeName = tool.Name
	meleeStats = WeaponModule.Weapons[meleeName]

	if not meleeStats or not meleeStats.IsMelee then
		currentMelee = nil
		return
	end

	print("[MeleeClient] Setup melee:", meleeName)

	tool.CanBeDropped = false

	-- Create manual melee viewmodel
	createMeleeViewmodel(tool)
	
	-- Play viewmodel hold animation (using ViewmodelAnimations if available)
	if viewmodelAnimator then
		local vmAnims = meleeStats.ViewmodelAnimations
		local holdAnimId = nil
		
		if vmAnims and vmAnims.Hold then
			-- Handle both table format (with Id) and string format
			local holdData = vmAnims.Hold
			holdAnimId = type(holdData) == "table" and holdData.Id or holdData
			print("[MeleeClient] Using ViewmodelAnimations.Hold:", holdAnimId)
		elseif meleeStats.Animations and meleeStats.Animations.Hold then
			-- Fallback to Animations.Hold
			holdAnimId = meleeStats.Animations.Hold.Id
		end
		
		if holdAnimId then
			viewmodelHoldTrack = playViewmodelAnimation(holdAnimId, true, Enum.AnimationPriority.Idle)
		end
	end

	-- Setup animations
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and meleeStats.Animations then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			-- Hold Animation
			if meleeStats.Animations.Hold then
				local holdAnimId = meleeStats.Animations.Hold.Id
				if holdAnimId then
					local holdAnim = Instance.new("Animation")
					holdAnim.AnimationId = holdAnimId
					currentHoldTrack = animator:LoadAnimation(holdAnim)
					currentHoldTrack.Priority = Enum.AnimationPriority.Idle
					currentHoldTrack.Looped = true
					currentHoldTrack:Play()
				end
			end

			-- Attack Animation (loaded but not played yet)
			if meleeStats.Animations.Attack then
				local attackAnimId = meleeStats.Animations.Attack.Id
				if attackAnimId then
					local attackAnim = Instance.new("Animation")
					attackAnim.AnimationId = attackAnimId
					currentAttackTrack = animator:LoadAnimation(attackAnim)
					currentAttackTrack.Priority = Enum.AnimationPriority.Action4
					currentAttackTrack.Looped = false
				end
			end
		end
	end

	-- Disable default tool hold animation
	tool.ManualActivationOnly = true
	if player.Character then
		local animate = player.Character:FindFirstChild("Animate")
		if animate then
			local toolAnim = animate:FindFirstChild("toolnone")
			if toolAnim then toolAnim:Destroy() end
			local toolAnim2 = animate:FindFirstChild("toolslash")
			if toolAnim2 then toolAnim2:Destroy() end
			local toolAnim3 = animate:FindFirstChild("toollunge")
			if toolAnim3 then toolAnim3:Destroy() end
		end
	end

	-- Watch for tool being unequipped
	table.insert(connections, tool.AncestryChanged:Connect(function(_, parent)
		if parent ~= player.Character then
			cleanupMelee()
		end
	end))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- MELEE ATTACK
-- ═══════════════════════════════════════════════════════════════════════════════

local function performAttack()
	if not currentMelee or not meleeStats then return end
	if isAttacking or not canAttack then return end
	if not isAttackCooldownReady() then return end
	if isKnocked or isGameOver then return end

	-- Check stamina (tracked from server StaminaUpdate)
	local staminaCost = meleeStats.StaminaCost or 5
	if currentStamina < staminaCost then
		-- Not enough stamina
		print("[MeleeClient] Not enough stamina!")
		return
	end

	isAttacking = true
	markJustAttacked()

	-- Capture attack direction now (before async animation)
	local attackDirection = camera.CFrame.LookVector

	-- Stop hold animation before attack
	if currentHoldTrack and currentHoldTrack.IsPlaying then
		currentHoldTrack:Stop(0.1)
	end

	-- Play attack animation (ensure it doesn't loop)
	if currentAttackTrack then
		currentAttackTrack.Looped = false -- Force non-looped
		currentAttackTrack:Stop(0) -- Stop any previous play
		currentAttackTrack:Play(0.1)
		
		-- Listen for "Damage" animation event to trigger server hit
		-- This ensures damage happens at the exact moment of visual impact
		currentAttackTrack:GetMarkerReachedSignal("Damage"):Once(function(param)
			-- param = "Hit" as set in animation editor
			if currentMelee and meleeStats then
				MeleeAttackEvent:FireServer(currentMelee, attackDirection)
			end
		end)
	end

	-- Play viewmodel attack animation
	if viewmodelAnimator then
		-- Stop viewmodel hold first
		if viewmodelHoldTrack and viewmodelHoldTrack.IsPlaying then
			viewmodelHoldTrack:Stop(0.1)
		end
		
		local vmAnims = meleeStats.ViewmodelAnimations
		local attackAnimId = nil
		
		if vmAnims and vmAnims.Attack then
			-- Handle both table format (with Id) and string format
			local attackData = vmAnims.Attack
			attackAnimId = type(attackData) == "table" and attackData.Id or attackData
		elseif meleeStats.Animations and meleeStats.Animations.Attack then
			attackAnimId = meleeStats.Animations.Attack.Id
		end
		
		if attackAnimId then
			viewmodelAttackTrack = playViewmodelAnimation(attackAnimId, false, Enum.AnimationPriority.Action4)
			setAnimationOffset("Attack")  -- Apply Attack animation offset
		end
	end

	-- Play swing sound
	if meleeStats.Sounds and meleeStats.Sounds.Swing then
		AudioManager.playSound(meleeStats.Sounds.Swing, currentMelee)
	end
	
	-- Wait for viewmodel attack animation to finish, then resume hold
	if viewmodelAttackTrack then
		viewmodelAttackTrack.Stopped:Once(function()
			-- Only resume if weapon still equipped
			if viewmodelAnimator and currentMelee and meleeStats then
				local vmAnims = meleeStats.ViewmodelAnimations
				local holdAnimId = nil
				
				if vmAnims and vmAnims.Hold then
					local holdData = vmAnims.Hold
					holdAnimId = type(holdData) == "table" and holdData.Id or holdData
				elseif meleeStats.Animations and meleeStats.Animations.Hold then
					holdAnimId = meleeStats.Animations.Hold.Id
				end
				
				if holdAnimId then
					viewmodelHoldTrack = playViewmodelAnimation(holdAnimId, true, Enum.AnimationPriority.Idle)
					setAnimationOffset("Hold")
				end
			end
		end)
	end

	-- Wait for CHARACTER attack animation to finish naturally (separate from viewmodel)
	task.spawn(function()
		local track = currentAttackTrack -- Capture reference
		
		if track then
			-- Get the actual animation length from the track
			local animLength = track.Length
			if animLength <= 0 then
				animLength = 1.0 -- Fallback to 1 second if length unknown
			end
			
			-- Wait for animation to naturally stop (using Stopped event)
			local animFinished = false
			local stopConnection
			stopConnection = track.Stopped:Connect(function()
				animFinished = true
				if stopConnection then stopConnection:Disconnect() end
			end)
			
			-- Also set a timeout in case animation doesn't fire Stopped
			local startTime = tick()
			while not animFinished and (tick() - startTime) < animLength + 0.5 do
				task.wait(0.05)
			end
			
			-- Cleanup connection if still active
			if stopConnection and stopConnection.Connected then
				stopConnection:Disconnect()
			end
		else
			task.wait(1.0) -- Fallback wait
		end

		isAttacking = false

		-- Resume character hold animation after attack
		if currentHoldTrack and currentMelee then
			pcall(function() currentHoldTrack:Play(0.2) end)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════════

local function onInputBegan(input, gpe)
	if gpe then return end
	if not currentMelee or not meleeStats then return end

	-- Left click for melee attack
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		performAttack()
	end
end

local function onTouchStarted(touch, gpe)
	if gpe then return end
	if not UserInputService.TouchEnabled then return end
	if not currentMelee or not meleeStats then return end

	-- Tap on right side of screen for attack
	local tapPosition = touch.Position
	if tapPosition.X > camera.ViewportSize.X / 2 then
		performAttack()
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- GAME LOOP
-- ═══════════════════════════════════════════════════════════════════════════════

local function onRenderStepped(dt)
	if viewmodel then
		viewmodel:updateViewmodel(dt, false) -- Melee doesn't have ADS
	end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- CHARACTER HANDLING
-- ═══════════════════════════════════════════════════════════════════════════════

local function onCharacterAdded(character)
	cleanupMelee()

	local humanoid = character:WaitForChild("Humanoid")

	-- Watch for melee tools being equipped
	character.ChildAdded:Connect(function(child)
		if isMeleeWeapon(child) then
			if isGameOver or isKnocked then
				humanoid:UnequipTools()
				return
			end
			setupMelee(child)
		end
	end)

	-- Watch for tools being unequipped
	character.ChildRemoved:Connect(function(child)
		if child == currentMelee then
			cleanupMelee()
		end
	end)

	character.Destroying:Connect(cleanupMelee)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Listen for knock status
local KnockEvent = RemoteEvents:FindFirstChild("KnockEvent")
if KnockEvent then
	KnockEvent.OnClientEvent:Connect(function(knockStatus)
		isKnocked = knockStatus
		if isKnocked and currentMelee then
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:UnequipTools() end
			cleanupMelee()
		end
	end)
end

-- Listen for game over
local GameOverEvent = RemoteEvents:FindFirstChild("GameOverEvent")
if GameOverEvent then
	GameOverEvent.OnClientEvent:Connect(function()
		isGameOver = true
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:UnequipTools() end
		cleanupMelee()
	end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════════

-- Connect input events
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.TouchStarted:Connect(onTouchStarted)
RunService.RenderStepped:Connect(onRenderStepped)

-- Handle character
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

print("[MeleeClient] Initialized")
