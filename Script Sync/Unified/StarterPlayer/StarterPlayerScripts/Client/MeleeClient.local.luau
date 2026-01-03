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
local HybridViewmodel = require(ReplicatedStorage.ModuleScript:WaitForChild("HybridViewmodel"))
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
local viewmodel = nil
local isAttacking = false
local canAttack = true
local nextAttackTime = 0
local isKnocked = false
local isGameOver = false

local currentHoldTrack = nil
local currentAttackTrack = nil
local connections = {}

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
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════════

local function cleanupMelee()
	if not currentMelee then return end

	-- Stop animations
	if currentHoldTrack then
		currentHoldTrack:Stop(0.2)
		currentHoldTrack = nil
	end
	if currentAttackTrack then
		currentAttackTrack:Stop(0)
		currentAttackTrack = nil
	end

	-- Cleanup viewmodel
	if viewmodel then
		viewmodel:destroyViewmodel()
		viewmodel = nil
	end

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

	-- Create viewmodel
	viewmodel = HybridViewmodel.new(tool, player, meleeName, WeaponModule)
	viewmodel:createViewmodel()

	-- Play viewmodel idle/hold animation
	if viewmodel and meleeStats.Animations then
		local holdAnimData = meleeStats.Animations.Hold or meleeStats.Animations.Idle
		if holdAnimData then
			local animId = type(holdAnimData) == "table" and holdAnimData.Id or holdAnimData
			if animId then
				viewmodel:playAnimation(animId, true, Enum.AnimationPriority.Idle)
				print("[MeleeClient] Playing viewmodel hold animation")
			end
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
	if viewmodel and meleeStats.Animations and meleeStats.Animations.Attack then
		viewmodel:playAnimation(meleeStats.Animations.Attack, false, Enum.AnimationPriority.Action4)
	end

	-- Play swing sound
	if meleeStats.Sounds and meleeStats.Sounds.Swing then
		AudioManager.playSound(meleeStats.Sounds.Swing, currentMelee)
	end

	-- Wait for attack animation to finish naturally
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
			
			-- Don't force stop - let animation finish naturally
			-- Only cleanup connection if still active
			if stopConnection and stopConnection.Connected then
				stopConnection:Disconnect()
			end
		else
			task.wait(1.0) -- Fallback wait
		end

		isAttacking = false

		-- Resume hold animation after attack (character)
		if currentHoldTrack and currentMelee then
			pcall(function() currentHoldTrack:Play(0.2) end)
		end

		-- Resume viewmodel idle/hold animation after attack
		if viewmodel and currentMelee and meleeStats and meleeStats.Animations then
			local holdAnimData = meleeStats.Animations.Hold or meleeStats.Animations.Idle
			if holdAnimData then
				local animId = type(holdAnimData) == "table" and holdAnimData.Id or holdAnimData
				if animId then
					viewmodel:playAnimation(animId, true, Enum.AnimationPriority.Idle)
				end
			end
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
