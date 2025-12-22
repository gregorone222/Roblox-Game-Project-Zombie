-- AmbientFXClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/AmbientFXClient.lua
-- Creates floating atmospheric particles around the camera

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DUST_TEXTURE = "rbxassetid://REPLACE_WITH_DUST_ID" -- Soft blurred circle
local EMIT_RATE = 20 -- Particles per second

local camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

local fxAttachment = nil
local dustEmitter = nil

local function setupAmbientParticles()
	-- Create attachment that follows camera
	local part = Instance.new("Part")
	part.Name = "AmbientFX_Host"
	part.Size = Vector3.new(1,1,1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Parent = Workspace
	
	fxAttachment = Instance.new("Attachment")
	fxAttachment.Parent = part
	
	-- Dust Emitter
	dustEmitter = Instance.new("ParticleEmitter")
	dustEmitter.Name = "DustMotes"
	dustEmitter.Texture = DUST_TEXTURE
	dustEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 230, 200)) -- Warm White
	dustEmitter.LightEmission = 0.5
	dustEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.1)
	})
	dustEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.7),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	dustEmitter.Lifetime = NumberRange.new(5, 10)
	dustEmitter.Rate = EMIT_RATE
	dustEmitter.Speed = NumberRange.new(0.5, 1.0)
	dustEmitter.SpreadAngle = Vector2.new(180, 180) -- Omni-directional
	dustEmitter.Rotation = NumberRange.new(0, 360)
	dustEmitter.RotSpeed = NumberRange.new(-20, 20)
	
	-- Logic to keep particles in volume around player
	-- We put the emitter in front of camera
	dustEmitter.EmissionDirection = Enum.NormalId.Front
	dustEmitter.Parent = fxAttachment
	
	-- Update loop to position the emitter
	RunService.RenderStepped:Connect(function()
		if camera then
			-- Posisikan Part di posisi kamera
			part.CFrame = camera.CFrame
		end
	end)
end

-- Wait for character to ensure player is ready (optional, but good practice)
if player.Character then
	setupAmbientParticles()
else
	player.CharacterAdded:Connect(function()
		setupAmbientParticles()
	end)
end
