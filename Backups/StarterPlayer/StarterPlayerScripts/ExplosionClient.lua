-- ExplosionClient.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/ExplosionClient.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local ExplosionEvent = RemoteEvents:WaitForChild("ExplosionEvent")

-- Asset IDs
local STAR_TEXTURE = "rbxassetid://133346747446843" -- Sharp jagged shape
local SMOKE_TEXTURE = "rbxassetid://REPLACE_WITH_CLOUD_ID" -- User generated cloud (Placeholder)

local function createLayeredExplosion(position, radius)
	local vfxRoot = Instance.new("Part")
	vfxRoot.Name = "ExplosionVFX"
	vfxRoot.Position = position
	vfxRoot.Anchored = true
	vfxRoot.CanCollide = false
	vfxRoot.Transparency = 1
	vfxRoot.Size = Vector3.new(1, 1, 1)
	vfxRoot.Parent = workspace

	-- 1. FLASH LIGHT (Real Light point)
	local light = Instance.new("PointLight")
	light.Name = "ExplosionLight"
	light.Color = Color3.fromRGB(255, 200, 100) -- Gold/White
	light.Range = radius * 3
	light.Brightness = 5
	light.Shadows = true
	light.Parent = vfxRoot
	
	-- Tween Light Fade Out
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(light, tweenInfo, {Brightness = 0, Range = 0})
	tween:Play()

	-- 2. SPARKS (High Speed, Omni-directional)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Texture = STAR_TEXTURE
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 170, 0)) -- Orange
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	sparks.Lifetime = NumberRange.new(0.3, 0.6)
	sparks.Rate = 0
	sparks.Speed = NumberRange.new(10, 20)
	sparks.SpreadAngle = Vector2.new(180, 180) -- 360 sphere
	sparks.Drag = 5 -- Slow down fast for "Punchy" feel
	sparks.Acceleration = Vector3.new(0, -10, 0) -- Gravity
	sparks.Parent = vfxRoot
	sparks:Emit(10)

	-- 3. SMOKE CLOUD (Volume)
	-- Uses the Star texture rotated randomly for now if SMOKE_TEXTURE is invalid
	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	-- Fallback to STAR if needed, but intended for Cloud
	smoke.Texture = STAR_TEXTURE 
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80)) -- Dark Grey
	smoke.LightEmission = 0.1
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, radius * 0.5),
		NumberSequenceKeypoint.new(1, radius * 1.5) -- Expand
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Lifetime = NumberRange.new(0.5, 1.0)
	smoke.Rate = 0
	smoke.Speed = NumberRange.new(2, 5)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Rotation = NumberRange.new(0, 360)
	smoke.RotSpeed = NumberRange.new(-90, 90) -- Spin for volume
	smoke.Parent = vfxRoot
	smoke:Emit(5)

	Debris:AddItem(vfxRoot, 2)
end

ExplosionEvent.OnClientEvent:Connect(function(position, radius)
	radius = radius or 5
	createLayeredExplosion(position, radius)
end)

-- ===============================
-- DEBUG: Press F to test explosion
-- ===============================
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		-- Raycast from camera center to find target position
		local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
		local hitPosition = result and result.Position or (ray.Origin + ray.Direction * 50)
		
		-- Trigger explosion locally (for VFX test only)
		createLayeredExplosion(hitPosition, 5)
		print("[DEBUG] Explosion triggered at", hitPosition)
	end
end)
