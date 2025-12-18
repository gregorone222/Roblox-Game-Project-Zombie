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

local function spawnTracer(startPos, endPos)
	local tracerPart = Instance.new("Part")
	tracerPart.Name = "Tracer"
	tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tracerPart.Transparency = 1
	tracerPart.Anchored = true
	tracerPart.CanCollide = false
	tracerPart.CFrame = CFrame.new(startPos, endPos)
	
	local beam = Instance.new("Beam")
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50))
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.Brightness = 5
	beam.LightEmission = 0.8
	beam.LightInfluence = 0
	beam.Texture = "rbxassetid://446111271"
	beam.TextureSpeed = 10
	
	local distance = (startPos - endPos).Magnitude
	beam.TextureLength = distance / 2
	beam.Parent = tracerPart
	
	local att0 = Instance.new("Attachment")
	att0.Parent = tracerPart
	att0.WorldPosition = startPos
	
	local att1 = Instance.new("Attachment")
	att1.Parent = tracerPart
	att1.WorldPosition = endPos
	
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	
	-- Fade cepat
	local tween = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Width0 = 0,
		Width1 = 0,
		Brightness = 0
	})
	tween:Play()
	
	tracerPart.Parent = workspace
	Debris:AddItem(tracerPart, 0.3)
end

-- Terima siaran dari server
TracerBroadcast.OnClientEvent:Connect(function(shooter, startPos, endPos, weaponName)
	-- Ignore self (handled locally by WeaponClient for zero latency)
	if shooter == localPlayer then return end

	-- Cek pengaturan client apakah tracer diaktifkan
	local showTracers = localPlayer:GetAttribute("ShowTracers")
	if showTracers == nil then showTracers = true end -- Default on
	
	if not showTracers then return end
	
	spawnTracer(startPos, endPos)
end)
