-- TracerClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/TracerClient.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")

local TracerBroadcast = RemoteEvents:WaitForChild("TracerBroadcast")

local function spawnTracer(shooter, startPos, endPos, weaponName)
	local tracerPart = Instance.new("Part")
	tracerPart.Name = "StylizedTracer"
	tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tracerPart.Transparency = 1
	tracerPart.Anchored = true
	tracerPart.CanCollide = false
	tracerPart.CFrame = CFrame.new(startPos, endPos)
	
	local beam = Instance.new("Beam")
	beam.FaceCamera = true
	-- Gold/Orange Core Color
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)), -- Bright Head
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0))   -- Trails off to orange
	})
	beam.Width0 = 0.12 -- Slightly thicker
	beam.Width1 = 0.12
	beam.Brightness = 8 -- Very Bright for Bloom
	beam.LightEmission = 1 -- Additive Blending
	beam.LightInfluence = 0
	beam.Texture = "rbxassetid://130004939944902" -- Stylized Tracer Asset
	beam.TextureSpeed = 0 -- FIX: Stop looping to prevent "Double Bullet" look
	
	-- Mode = Stretch so the texture isn't tiled, looks like one long streak
	beam.TextureMode = Enum.TextureMode.Stretch 
	
	local distance = (startPos - endPos).Magnitude
	-- Length logic: Stretch texture to fit the beam length
	beam.TextureLength = distance 
	beam.Parent = tracerPart
	
	-- ATTACHMENT LOGIC (Dynamic vs Static)
	local att0 = Instance.new("Attachment")
	local attachedToMuzzle = false
	
	if shooter and shooter.Character and weaponName then
		local tool = shooter.Character:FindFirstChild(weaponName)
		if tool then
			local muzzle = tool:FindFirstChild("Muzzle", true)
			if muzzle then
				att0.Parent = muzzle
				att0.Position = Vector3.new(0, 0, 0)
				attachedToMuzzle = true
			end
		end
	end
	
	if not attachedToMuzzle then
		att0.Parent = tracerPart
		att0.WorldPosition = startPos
	end
	
	local att1 = Instance.new("Attachment")
	att1.Parent = tracerPart
	att1.WorldPosition = endPos
	
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	
	-- Fast Fade (Zip effect)
	local tween = TweenService:Create(beam, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Width0 = 0,
		Width1 = 0
	})
	tween:Play()
	
	tracerPart.Parent = workspace
	Debris:AddItem(tracerPart, 0.2)
	-- If attached to gun, clean up attachment separately
	if attachedToMuzzle then
		Debris:AddItem(att0, 0.2)
	end
end

-- Terima siaran dari server
TracerBroadcast.OnClientEvent:Connect(function(shooter, startPos, endPos, weaponName)
	-- Ignore self (handled locally by WeaponClient for zero latency)
	if shooter == localPlayer then return end

	-- Cek pengaturan client apakah tracer diaktifkan
	local showTracers = localPlayer:GetAttribute("ShowTracers")
	if showTracers == nil then showTracers = true end -- Default on
	
	if not showTracers then return end
	
	spawnTracer(shooter, startPos, endPos, weaponName)
end)
