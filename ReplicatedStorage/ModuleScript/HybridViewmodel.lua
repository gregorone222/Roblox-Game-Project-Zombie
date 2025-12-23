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
	self.adsBlend = 0
	
	-- Sway & Bob
	self.lastCameraCFrame = self.camera.CFrame
	self.currentSway = CFrame.new()
	self.targetSway = CFrame.new()
	self.bobTime = 0
	
	-- Get weapon stats
	local weaponStats = self.WeaponModule.Weapons[self.weaponName] or {}
	self.swayIntensity = weaponStats.SwayIntensity or 0.5
	self.bobIntensity = weaponStats.BobIntensity or 0.3
	self.bobFrequency = weaponStats.BobFrequency or 8
	
	-- Viewmodel positioning from weapon stats
	self.viewmodelPosition = weaponStats.ViewmodelPosition or Vector3.new(0.5, -1, -1.8)
	self.viewmodelRotation = weaponStats.ViewmodelRotation or Vector3.new(0, 0, 0)
	
	-- ADS Positioning
	self.adsPosition = weaponStats.ADS_Position or Vector3.new(0, -1, -1)
	self.adsRotation = weaponStats.ADS_Rotation or Vector3.new(0, 0, 0)
	
	-- Mobile ADS (Optional Override)
	if game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").MouseEnabled then
		if weaponStats.ADS_Position_Mobile then self.adsPosition = weaponStats.ADS_Position_Mobile end
		if weaponStats.ADS_Rotation_Mobile then self.adsRotation = weaponStats.ADS_Rotation_Mobile end
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
	
	-- 3. Make all parts non-collidable, no shadows
	for _, part in pairs(self.viewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CastShadow = false
			part.Anchored = false
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
	
	-- 6. Get AnimationController for animations
	self.animController = self.viewmodel:FindFirstChildOfClass("AnimationController")
	if not self.animController then
		self.animController = Instance.new("AnimationController")
		self.animController.Parent = self.viewmodel
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
	-- Calculate final position with ADS interpolation
	local targetBlend = self.isAiming and 1 or 0
	-- Simple linear interpolation for blend factor (can be eased if needed)
	self.adsBlend = self.adsBlend + (targetBlend - self.adsBlend) * math.min(dt * 15, 1)
	
	-- [EDITOR Overrides]
	local editorHipPos = self.viewmodel:GetAttribute("Editor_HipPos")
	local editorHipRot = self.viewmodel:GetAttribute("Editor_HipRot")
	local editorAdsPos = self.viewmodel:GetAttribute("Editor_AdsPos")
	local editorAdsRot = self.viewmodel:GetAttribute("Editor_AdsRot")
	
	local targetHipPos = editorHipPos or self.viewmodelPosition
	local targetHipRot = editorHipRot or self.viewmodelRotation
	local targetAdsPos = editorAdsPos or self.adsPosition
	local targetAdsRot = editorAdsRot or self.adsRotation
	
	local currentPos = targetHipPos:Lerp(targetAdsPos, self.adsBlend)
	local currentRot = targetHipRot:Lerp(targetAdsRot, self.adsBlend)
	
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

function HybridViewmodel:playAnimation(animId, loop, priority)
	if not self.animController or not animId then return end
	
	-- Stop previous track
	self:stopAnimation()
	
	-- Create new animation object
	local anim = Instance.new("Animation")
	anim.AnimationId = animId
	
	local track = self.animController:LoadAnimation(anim)
	if not track then return end
	
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
