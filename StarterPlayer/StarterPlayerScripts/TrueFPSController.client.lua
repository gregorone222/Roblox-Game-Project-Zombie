-- TrueFPSController.client.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/TrueFPSController.client.lua
-- Purpose: True First-Person camera system - manages body transparency based on camera distance, replicates look direction.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Configuration
local UPDATE_RATE = 0.1 -- Send look direction to server every 0.1 seconds
local FIRST_PERSON_THRESHOLD = 2.5 -- Distance from head to consider "first person" (studs)
local HEAD_HIDE_RADIUS = 2.0 -- Hide all parts within this distance from head center

-- State
local character = nil
local humanoid = nil
local head = nil
local lastLookSendTime = 0
local cachedJoints = {}
local isFirstPerson = false

-- Remote Event (will be created if not exists)
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local lookEvent = RemoteEvents and RemoteEvents:FindFirstChild("LookEvent")
if not lookEvent and RemoteEvents then
	lookEvent = Instance.new("RemoteEvent")
	lookEvent.Name = "LookEvent"
	lookEvent.Parent = RemoteEvents
end

-- Body parts that should NEVER be hidden (core rig)
local BODY_PART_NAMES = {
	["HumanoidRootPart"] = true,
	["Torso"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["LeftUpperArm"] = true,
	["LeftLowerArm"] = true,
	["LeftHand"] = true,
	["RightUpperArm"] = true,
	["RightLowerArm"] = true,
	["RightHand"] = true,
	["LeftUpperLeg"] = true,
	["LeftLowerLeg"] = true,
	["LeftFoot"] = true,
	["RightUpperLeg"] = true,
	["RightLowerLeg"] = true,
	["RightFoot"] = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
}

-- Parts to show (arms and hands)
local PARTS_TO_SHOW_KEYWORDS = { "Arm", "Hand" }

local function shouldShowPart(part)
	if not part:IsA("BasePart") then return false end
	for _, keyword in ipairs(PARTS_TO_SHOW_KEYWORDS) do
		if string.find(part.Name, keyword) then
			return true
		end
	end
	return false
end

local function cacheJoints()
	if not character then return end
	cachedJoints = {}
	
	local neck = character:FindFirstChild("Neck", true)
	local rightShoulder = character:FindFirstChild("RightShoulder", true) or character:FindFirstChild("Right Shoulder", true)
	local leftShoulder = character:FindFirstChild("LeftShoulder", true) or character:FindFirstChild("Left Shoulder", true)
	local waist = character:FindFirstChild("Waist", true)
	
	if neck then cachedJoints.Neck = { Joint = neck, OriginalC0 = neck.C0 } end
	if rightShoulder then cachedJoints.RightShoulder = { Joint = rightShoulder, OriginalC0 = rightShoulder.C0 } end
	if leftShoulder then cachedJoints.LeftShoulder = { Joint = leftShoulder, OriginalC0 = leftShoulder.C0 } end
	if waist then cachedJoints.Waist = { Joint = waist, OriginalC0 = waist.C0 } end
end

local function applyLocalLook(lookY)
	local angle = math.asin(math.clamp(lookY, -1, 1))
	
	-- Procedural Inverted Offset for shoulders
	-- When looking up (lookY > 0), pull shoulders back to prevent arms blocking view
	local shoulderOffsetZ = 0
	if lookY > 0 then
		-- The more we look up, the more we pull shoulders back
		-- At lookY = 0: offset = 0 (normal)
		-- At lookY = 1 (straight up): offset = -0.8 (pulled back 0.8 studs)
		shoulderOffsetZ = -lookY * 0.8
	end
	
	for name, data in pairs(cachedJoints) do
		if data.Joint and data.Joint.Parent then
			local factor = 1
			if name == "Waist" then factor = 0.3 end
			if name == "Neck" then factor = 0.7 end
			if name == "RightShoulder" or name == "LeftShoulder" then 
				factor = 0.4
				-- Apply procedural offset to shoulders (only Z axis - back)
				local proceduralOffset = CFrame.new(0, 0, shoulderOffsetZ)
				data.Joint.C0 = data.OriginalC0 * proceduralOffset * CFrame.Angles(angle * factor, 0, 0)
			else
				data.Joint.C0 = data.OriginalC0 * CFrame.Angles(angle * factor, 0, 0)
			end
		end
	end
end
-- [HYBRID FPS] Parts to HIDE (real arms - replaced by viewmodel)
local ARM_PART_NAMES = {
	["LeftUpperArm"] = true,
	["LeftLowerArm"] = true,
	["LeftHand"] = true,
	["RightUpperArm"] = true,
	["RightLowerArm"] = true,
	["RightHand"] = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
}

-- Update transparency based on whether we're in first person or not
-- [SIMPLIFIED FPS MODE] - Hide entire character (Viewmodel shows arms/weapon instead)
local function updateTransparency(inFirstPerson)
	if not character then return end
	
	if inFirstPerson then
		-- FIRST PERSON: Hide entire local character (Viewmodel will show arms)
		for _, child in pairs(character:GetDescendants()) do
			if child:IsA("BasePart") then
				child.LocalTransparencyModifier = 1
			elseif child:IsA("Decal") or child:IsA("Texture") then
				child.Transparency = 1
			end
		end
		
		-- Also hide equipped tools (viewmodel has its own weapon)
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			for _, part in pairs(tool:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
				end
			end
		end
	else
		-- THIRD PERSON: Show everything normally
		for _, child in pairs(character:GetDescendants()) do
			if child:IsA("BasePart") then
				child.LocalTransparencyModifier = 0
			elseif child:IsA("Decal") or child:IsA("Texture") then
				child.Transparency = 0
			end
		end
		
		-- Show equipped tools in third person
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			for _, part in pairs(tool:GetDescendants()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end
end


local function resetJoints()
	for name, data in pairs(cachedJoints) do
		if data.Joint and data.Joint.Parent then
			data.Joint.C0 = data.OriginalC0
		end
	end
end

local wasFirstPerson = false -- Track previous state for transition detection

local function onRenderStepped(dt)
	if not character or not head or not humanoid or humanoid.Health <= 0 then return end
	
	-- 1. Check camera distance to head for first-person detection
	local cameraPosition = camera.CFrame.Position
	local headPosition = head.Position
	local distanceToHead = (cameraPosition - headPosition).Magnitude
	isFirstPerson = distanceToHead < FIRST_PERSON_THRESHOLD
	
	-- 2. Update transparency based on view mode
	updateTransparency(isFirstPerson)
	
	-- 3. Get look direction from camera
	local lookVectorY = camera.CFrame.LookVector.Y
	
	-- 4. Apply local IK (works in BOTH first and third person)
	applyLocalLook(lookVectorY)
	
	-- 5. Send look direction to server (throttled) - only in first person for replication
	if isFirstPerson then
		local now = tick()
		if now - lastLookSendTime > UPDATE_RATE then
			lastLookSendTime = now
			if lookEvent then
				lookEvent:FireServer(lookVectorY)
			end
		end
	elseif wasFirstPerson then
		-- TRANSITION: Just exited first person, send neutral to server
		if lookEvent then
			lookEvent:FireServer(0)
		end
	end
	
	wasFirstPerson = isFirstPerson
end


local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid", 10)
	head = character:WaitForChild("Head", 10)
	
	task.wait(0.5)
	cacheJoints()
	
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("Motor6D") then
			cacheJoints()
		end
	end)
end

-- Initialize
player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end

-- Use BindToRenderStep with priority > Camera to prevent transparency flicker
-- This ensures our code runs AFTER Roblox's default character scripts
RunService:BindToRenderStep("TrueFPSUpdate", Enum.RenderPriority.Camera.Value + 1, onRenderStepped)

print("[TrueFPSController] Initialized - Distance-based hiding active")
