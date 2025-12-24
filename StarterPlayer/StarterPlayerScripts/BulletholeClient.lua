local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local BulletholeEvent = RemoteEvents:WaitForChild("BulletholeEvent")

local BULLETHOLE_TEXTURE = "rbxassetid://94614436519456" -- Stylized Cracked Hole

local function createBullethole(position, normal)
	-- 1. Create a "sticker" part to hold the decal
	-- This avoids Z-fighting and ensures it works on MeshParts without UV issues
	local holePart = Instance.new("Part")
	holePart.Name = "StylizedBullethole"
	
	-- NEW: Random size variation (0.4 to 0.8 studs - not too excessive)
	local randomScale = 0.4 + (math.random() * 0.4) -- Range: 0.4 to 0.8
	holePart.Size = Vector3.new(randomScale, randomScale, 0.05) -- Thin plate with random size
	
	holePart.Transparency = 1
	holePart.CanCollide = false
	holePart.Anchored = true -- Static impact for now (Network doesn't send hitPart)
	holePart.Massless = true
	
	-- Orient part to face the normal
	-- CFrame.lookAt makes the Front face point to 'target'. 
	-- We want the Front face (where Decal is) to face OUT form the wall (Normal).
	local baseCFrame = CFrame.lookAt(position + (normal * 0.05), position + normal)
	
	-- NEW: Random rotation around the normal axis (0 to 360 degrees)
	local randomRotation = math.rad(math.random(0, 360))
	holePart.CFrame = baseCFrame * CFrame.Angles(0, 0, randomRotation)
	
	holePart.Parent = workspace

	-- 2. Create Decal
	local decal = Instance.new("Decal")
	decal.Texture = BULLETHOLE_TEXTURE
	decal.Face = Enum.NormalId.Front
	decal.Parent = holePart
	
	-- 3. Fade out and cleanup
	-- Long lifetime (10s) then fade
	task.delay(10, function()
		if not holePart then return end
		local tween = TweenService:Create(decal, TweenInfo.new(1), {Transparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			holePart:Destroy()
		end)
	end)
	
	-- Safety cleanup in case tween fails or logic hangs
	Debris:AddItem(holePart, 12)
end

BulletholeEvent.OnClientEvent:Connect(function(position, normal)
	createBullethole(position, normal)
end)
