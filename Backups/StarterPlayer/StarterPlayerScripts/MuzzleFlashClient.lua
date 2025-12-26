-- MuzzleFlashClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/MuzzleFlashClient.lua
-- Concept: Stylized Muzzle Flash (Fortnite/Overwatch Style)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local MuzzleFlashBroadcast = RemoteEvents:WaitForChild("MuzzleFlashBroadcast")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- Configuration
local FLASH_TEXTURE = "rbxassetid://133346747446843" -- Stylized Star Shape

MuzzleFlashBroadcast.OnClientEvent:Connect(function(shooter, flashCFrame, weaponName)
	-- Ignore self (handled locally by WeaponClient for zero latency)
	if shooter == localPlayer then return end
	
	-- 1. Attempt to find actual Muzzle Part for perfect sync
	local muzzlePart
	local character = shooter.Character
	if character then
		-- Search for the weapon model (assuming it's a Tool or Model equipped)
		local tool = character:FindFirstChild(weaponName)
		if tool then
			muzzlePart = tool:FindFirstChild("Muzzle", true) -- Recursive search
		end
	end

	-- 2. Setup Effect Source
	local effectParent
	local isTemporary = false
	
	if muzzlePart then
		effectParent = muzzlePart
	else
		-- Fallback: Create temporary part at server-reported CFrame
		local ghostPart = Instance.new("Part")
		ghostPart.Name = "MuzzleFlashFX_Ghost"
		ghostPart.Transparency = 1
		ghostPart.Size = Vector3.new(0.1, 0.1, 0.1)
		ghostPart.Anchored = true
		ghostPart.CanCollide = false
		ghostPart.CFrame = flashCFrame
		ghostPart.Parent = workspace
		
		effectParent = ghostPart
		isTemporary = true
	end
	
	-- 3. Create Particle Emitter (Stylized)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "FlashShape"
	emitter.Texture = FLASH_TEXTURE
	emitter.LightEmission = 1 -- Additive Blending
	emitter.LightInfluence = 0
	
	-- Dynamics (Punchy & Short)
	emitter.Lifetime = NumberRange.new(0.05, 0.08)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),    
		NumberSequenceKeypoint.new(1, 1)     
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18), -- Start Micro (0.375 / 2)
		NumberSequenceKeypoint.new(1, 0.43)  -- Explode Mini (0.875 / 2)
	})
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Speed = NumberRange.new(0) 
	emitter.Rate = 0 -- Manual Emit
	emitter.Parent = effectParent

	-- 4. Create Point Light
	local light = Instance.new("PointLight")
	light.Brightness = 8
	light.Range = 12
	light.Color = Color3.fromRGB(255, 180, 50) 
	light.Parent = effectParent

	-- 5. Trigger
	emitter:Emit(1) 
	
	-- 6. Cleanup
	-- If it's our temporary part, destroy it. If it's a real muzzle, just destroy the effects.
	if isTemporary then
		Debris:AddItem(effectParent, 0.2)
	else
		Debris:AddItem(emitter, 0.2)
		Debris:AddItem(light, 0.2)
	end
end)