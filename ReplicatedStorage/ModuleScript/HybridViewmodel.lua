-- HybridViewmodel.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/HybridViewmodel.lua
-- Purpose: Hybrid FPS viewmodel system - uses viewmodel arms + cloned weapon, while body uses True FPS

local HybridViewmodel = {}
HybridViewmodel.__index = HybridViewmodel

-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Get ViewmodelBase template
local ViewmodelBase = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Viewmodel"):WaitForChild("ViewmodelBase")

-- Configuration
local DEFAULT_OFFSET = CFrame.new(0, -1.5, -2) -- Position relative to camera
local DEFAULT_ROTATION = CFrame.Angles(0, 0, 0)

function HybridViewmodel.new(tool, player, weaponName, weaponModule)
	local self = setmetatable({}, HybridViewmodel)
	
	self.tool = tool
	self.player = player
	self.weaponName = weaponName
	self.WeaponModule = weaponModule
	self.camera = workspace.CurrentCamera
	
	-- Viewmodel state
	self.viewmodel = nil
	self.weaponClone = nil
	self.isAiming = false
	
	-- Animation-based positioning
	self.currentAnimState = "Idle" -- Current animation state (Idle, Run, ADS, Reload)
	self.targetAnimState = "Idle"
	self.animBlend = 0 -- For smooth transition between animation positions
	
	-- Sway & Bob
	self.lastCameraCFrame = self.camera.CFrame
	self.currentSway = CFrame.new()
	self.targetSway = CFrame.new()
	self.bobTime = 0
	
	-- Get weapon stats
	local weaponStats = self.WeaponModule.Weapons[self.weaponName] or {}
	self.weaponStats = weaponStats
	self.swayIntensity = weaponStats.SwayIntensity or 0.5
	self.bobIntensity = weaponStats.BobIntensity or 0.3
	self.bobFrequency = weaponStats.BobFrequency or 8
	
	-- Per-animation positions (from new Animations structure)
	self.animPositions = {}
	
	-- Legacy fallback: Get root-level ViewmodelPosition/Rotation if defined
	local legacyPosition = weaponStats.ViewmodelPosition or Vector3.new(1.3, -0.5, -2.5)
	local legacyRotation = weaponStats.ViewmodelRotation or Vector3.new(0, 0, 0)
	
	if weaponStats.Animations then
		for animName, animData in pairs(weaponStats.Animations) do
			if type(animData) == "table" then
				-- New format: Per-animation position
				self.animPositions[animName] = {
					Position = animData.Position or legacyPosition, -- Fallback to legacy
					Rotation = animData.Rotation or legacyRotation
				}
			else
				-- Legacy format (just animation ID string) - use legacy position
				self.animPositions[animName] = {
					Position = legacyPosition,
					Rotation = legacyRotation
				}
			end
		end
	end
	
	-- Default position if no animations defined (use legacy values)
	if not next(self.animPositions) then
		self.animPositions["Idle"] = {
			Position = legacyPosition,
			Rotation = legacyRotation
		}
	end
	
	return self
end

function HybridViewmodel:cleanupOldViewmodels()
	for _, inst in ipairs(self.camera:GetChildren()) do
		if inst:GetAttribute("IsHybridViewmodel") or inst.Name == "HybridViewmodel" then
			inst:Destroy()
		end
	end
end

function HybridViewmodel:createViewmodel()
	self:cleanupOldViewmodels()
	
	-- 1. Clone ViewmodelBase (arms rig)
	self.viewmodel = ViewmodelBase:Clone()
	self.viewmodel.Name = "HybridViewmodel"
	self.viewmodel:SetAttribute("IsHybridViewmodel", true)
	self.viewmodel.Parent = self.camera
	
	-- 2. Find the root part and RightHand
	local rootPart = self.viewmodel:FindFirstChild("HumanoidRootPart")
	local rightHand = self.viewmodel:FindFirstChild("RightHand")
	
	if not rootPart then
		warn("[HybridViewmodel] ViewmodelBase missing HumanoidRootPart!")
		return
	end
	
	-- 3. Configure Humanoid for viewmodel (disable physics interference)
	local humanoid = self.viewmodel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	end
	
	-- 4. Make all parts non-collidable, no shadows, and Massless for invisible parts
	local armParts = {
		["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
		["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true
	}
	
	for _, part in pairs(self.viewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CastShadow = false
			part.Anchored = false
			
			-- Make non-arm parts Massless so they don't affect physics
			if not armParts[part.Name] then
				part.Massless = true
			end
		end
	end
	
	-- Root part should be anchored (the whole assembly follows it)
	rootPart.Anchored = true
	
	-- 4. Clone weapon and weld to RightHand
	if rightHand then
		self.weaponClone = self.tool:Clone()
		self.weaponClone.Name = "ViewmodelWeapon"
		
		-- Remove scripts and sounds from cloned weapon
		for _, desc in pairs(self.weaponClone:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") then
				desc:Destroy()
			elseif desc:IsA("BasePart") then
				desc.CanCollide = false
				desc.CastShadow = false
				desc.Anchored = false
				-- Make visible
				if desc.Name ~= "Muzzle" then
					desc.Transparency = 0
				else
					desc.Transparency = 1
				end
			end
		end
		
		self.weaponClone.Parent = self.viewmodel
		
		-- Weld weapon handle to RightHand
		local handle = self.weaponClone:FindFirstChild("Handle")
		if handle then
			-- Use RightGripAttachment for accurate positioning
			local gripAttachment = rightHand:FindFirstChild("RightGripAttachment")
			if gripAttachment then
				handle.CFrame = gripAttachment.WorldCFrame
			else
				handle.CFrame = rightHand.CFrame
			end
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rightHand
			weld.Part1 = handle
			weld.Parent = handle
		end
	end
	
	-- 5. Store reference to muzzle for effects
	if self.weaponClone then
		self.viewmodelMuzzle = self.weaponClone:FindFirstChild("Muzzle")
	end
	
	-- 6. Get Humanoid or AnimationController for animations
	-- R15 rigs have Humanoid, use that for animations
	local humanoid = self.viewmodel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Use Humanoid's Animator for R15 rig
		self.animController = humanoid
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		self.animator = animator
	else
		-- Fallback to AnimationController for custom rigs
		self.animController = self.viewmodel:FindFirstChildOfClass("AnimationController")
		if not self.animController then
			self.animController = Instance.new("AnimationController")
			self.animController.Parent = self.viewmodel
		end
		local animator = self.animController:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = self.animController
		end
		self.animator = animator
	end
	
	-- Initial position
	self:updateViewmodel(0)
	
	print("[HybridViewmodel] Created viewmodel for:", self.weaponName)
end

function HybridViewmodel:destroyViewmodel()
	if self.viewmodel then
		self.viewmodel:Destroy()
		self.viewmodel = nil
	end
	self.weaponClone = nil
	self.viewmodelMuzzle = nil
end

function HybridViewmodel:updateViewmodel(dt, isAiming)
	if not self.viewmodel then return end
	
	local rootPart = self.viewmodel:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	self.isAiming = isAiming or false
	
	-- Calculate sway from mouse movement
	local cameraDelta = self.camera.CFrame:ToObjectSpace(self.lastCameraCFrame)
	self.lastCameraCFrame = self.camera.CFrame
	
	local swayAmount = self.swayIntensity
	if self.isAiming then swayAmount = swayAmount * 0.3 end
	
	local rx, ry, rz = cameraDelta:ToOrientation()
	self.targetSway = CFrame.Angles(ry * swayAmount * 0.5, -rx * swayAmount, rx * swayAmount * 0.2)
	self.currentSway = self.currentSway:Lerp(self.targetSway, dt * 10)
	
	-- Calculate bob from movement
	local char = self.player.Character
	local bobOffset = CFrame.new()
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChild("Humanoid")
		if hrp and humanoid then
			local speed = hrp.AssemblyLinearVelocity.Magnitude
			local maxSpeed = humanoid.WalkSpeed
			if speed > 1 and maxSpeed > 0 then
				local bobAmount = self.bobIntensity * (speed / maxSpeed)
				if self.isAiming then bobAmount = bobAmount * 0.3 end
				
				self.bobTime = self.bobTime + dt * self.bobFrequency * (speed / maxSpeed)
				local bobX = math.sin(self.bobTime * 0.5) * bobAmount * 0.05
				local bobY = math.sin(self.bobTime) * bobAmount * 0.08
				bobOffset = CFrame.new(bobX, bobY, 0)
			end
		end
	end
	
	-- Calculate final position
	-- Determine target animation state based on current conditions
	if self.isAiming then
		self.targetAnimState = "ADS"
	else
		-- Check if player is moving
		local char = self.player.Character
		local isMoving = false
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				isMoving = hrp.AssemblyLinearVelocity.Magnitude > 1
			end
		end
		self.targetAnimState = isMoving and "Run" or "Idle"
	end
	
	-- Get position for current and target animation states
	-- Use Idle as fallback for any missing animation positions
	local idlePos = self.animPositions["Idle"] or {
		Position = Vector3.new(1.3, -0.5, -2.5),
		Rotation = Vector3.new(0, 0, 0)
	}
	local currentAnimPos = self.animPositions[self.currentAnimState] or idlePos
	local targetAnimPos = self.animPositions[self.targetAnimState] or idlePos
	
	-- If Run has same position as default, use Idle position instead
	if self.targetAnimState == "Run" and targetAnimPos.Position == Vector3.new(1.3, -0.5, -2.5) then
		targetAnimPos = idlePos
	end
	if self.currentAnimState == "Run" and currentAnimPos.Position == Vector3.new(1.3, -0.5, -2.5) then
		currentAnimPos = idlePos
	end
	
	-- Smooth transition between animation positions
	if self.currentAnimState ~= self.targetAnimState then
		self.animBlend = self.animBlend + dt * 10
		if self.animBlend >= 1 then
			self.animBlend = 0
			self.currentAnimState = self.targetAnimState
		end
	end
	
	local blendFactor = math.min(self.animBlend, 1)
	local currentPos = currentAnimPos.Position:Lerp(targetAnimPos.Position, blendFactor)
	local currentRot = currentAnimPos.Rotation:Lerp(targetAnimPos.Rotation, blendFactor)
	
	-- [EDITOR Overrides] - Now per-animation
	local editorPos = self.viewmodel:GetAttribute("Editor_AnimPos")
	local editorRot = self.viewmodel:GetAttribute("Editor_AnimRot")
	if editorPos then currentPos = editorPos end
	if editorRot then currentRot = editorRot end

	local basePosition = CFrame.new(currentPos)
	local baseRotation = CFrame.Angles(
		math.rad(currentRot.X),
		math.rad(currentRot.Y),
		math.rad(currentRot.Z)
	)
	
	local finalCFrame = self.camera.CFrame * basePosition * baseRotation * self.currentSway * bobOffset
	
	rootPart.CFrame = finalCFrame
end

function HybridViewmodel:getMuzzle()
	return self.viewmodelMuzzle
end

function HybridViewmodel:applyVisualRecoil()
	-- Simple recoil kick - can be expanded
	if not self.viewmodel then return end
	-- Recoil is now handled by camera shake in WeaponClient
end

-- Set animation state manually (for external control)
function HybridViewmodel:setAnimState(animState)
	if self.animPositions[animState] then
		self.targetAnimState = animState
	end
end

-- Get animation ID from new Animations structure
function HybridViewmodel:getAnimationId(animName)
	local weaponStats = self.weaponStats
	if not weaponStats or not weaponStats.Animations then return nil end
	
	local animData = weaponStats.Animations[animName]
	if type(animData) == "table" then
		return animData.Id
	elseif type(animData) == "string" then
		return animData -- Legacy format
	end
	return nil
end

function HybridViewmodel:playAnimation(animId, loop, priority)
	if not self.animator or not animId then return end
	
	-- Handle new per-animation format (table with Id) or legacy format (string)
	local actualAnimId = animId
	if type(animId) == "table" then
		actualAnimId = animId.Id
	end
	if not actualAnimId then return end
	
	-- Stop previous track
	self:stopAnimation()
	
	-- Create new animation object
	local anim = Instance.new("Animation")
	anim.AnimationId = actualAnimId
	
	local success, track = pcall(function()
		return self.animator:LoadAnimation(anim)
	end)
	
	if not success or not track then 
		warn("[HybridViewmodel] Failed to load animation:", animId)
		return 
	end
	
	track.Looped = loop or false
	track.Priority = priority or Enum.AnimationPriority.Action
	track:Play()
	
	self.currentTrack = track
	return track
end

function HybridViewmodel:stopAnimation(fadeTime)
	if self.currentTrack and self.currentTrack.IsPlaying then
		self.currentTrack:Stop(fadeTime or 0.1)
	end
	self.currentTrack = nil
end

return HybridViewmodel
