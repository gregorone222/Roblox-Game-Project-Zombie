-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- RagdollModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/RagdollModule.lua
-- Description: Provides ragdoll functionality for characters (Players and Zombies)

local RagdollModule = {}

-- Parts that should have collision enabled during ragdoll
local COLLIDE_PARTS = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperLeg", "RightUpperLeg",
	"LeftLowerLeg", "RightLowerLeg",
	"LeftUpperArm", "RightUpperArm",
	"LeftLowerArm", "RightLowerArm",
	"LeftHand", "RightHand",
	"LeftFoot", "RightFoot"
}

--[[
	Converts Motor6D joints to BallSocketConstraints to create ragdoll physics.
	Should be called when a character dies.
	
	@param character: The character Model to ragdoll
]]
function RagdollModule.Rig(character)
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Prevent default joint breaking on death
		humanoid.BreakJointsOnDeath = false

		-- Fully disable humanoid control to prevent leg jitter
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true

		-- Destroy animator to prevent any animation from causing jitter
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				track:Stop(0) -- Stop instantly (0 fade time)
			end
			animator:Destroy() -- Completely remove to prevent physics interference
		end

		-- Force physics state
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	-- Convert Motor6D joints to BallSocketConstraints (except for RootPart which gets welded)
	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") then
			local part0 = joint.Part0
			local part1 = joint.Part1

			-- Check if this joint involves HumanoidRootPart - weld it instead of ragdoll
			local isRootJoint = (part0 and part0.Name == "HumanoidRootPart") or 
				(part1 and part1.Name == "HumanoidRootPart")

			if isRootJoint then
				-- Use RigidConstraint to keep RootPart locked to Torso
				local weld = Instance.new("RigidConstraint")
				local a1 = Instance.new("Attachment")
				local a2 = Instance.new("Attachment")

				a1.Parent = part0
				a2.Parent = part1
				a1.CFrame = joint.C0
				a2.CFrame = joint.C1

				weld.Attachment0 = a1
				weld.Attachment1 = a2
				weld.Parent = joint.Parent
			else
				-- Normal ragdoll joint with BallSocket
				local socket = Instance.new("BallSocketConstraint")
				local a1 = Instance.new("Attachment")
				local a2 = Instance.new("Attachment")

				a1.Parent = part0
				a2.Parent = part1
				socket.Parent = joint.Parent

				socket.Attachment0 = a1
				socket.Attachment1 = a2

				a1.CFrame = joint.C0
				a2.CFrame = joint.C1

				-- Enable limits for realistic joint behavior
				socket.LimitsEnabled = true
				socket.UpperAngle = 45 -- Restrict cone angle to 45 degrees
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = -45 -- Restrict twist to +-45 degrees
				socket.TwistUpperAngle = 45
			end

			-- Destroy the original motor
			joint:Destroy()
		end
	end

	-- Enable collision and set high friction on body parts
	local ragdollPhysics = PhysicalProperties.new(
		0.7,  -- Density (standard body)
		1,    -- Friction (maximum - stops sliding)
		0,    -- Elasticity (no bounce)
		1,    -- FrictionWeight
		0     -- ElasticityWeight
	)
	for _, name in pairs(COLLIDE_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CanCollide = true
			part.CustomPhysicalProperties = ragdollPhysics
		end
	end

	-- Configure HumanoidRootPart to not interfere with ragdoll physics
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CanCollide = false
		root.Massless = true -- Don't add weight to physics
		root.CanQuery = false -- Ignore raycasts
	end

	-- Apply impulse based on last hit direction (for bullet force ragdoll)
	local hitDirection = character:GetAttribute("LastHitDirection")
	local hitForce = character:GetAttribute("LastHitForce") or 500 -- Default fallback

	-- Find the main torso part to apply impulse
	local torsoPart = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")

	if torsoPart and torsoPart:IsA("BasePart") then
		if hitDirection and typeof(hitDirection) == "Vector3" then
			-- Apply directional impulse from bullet
			local impulse = hitDirection * hitForce
			torsoPart:ApplyImpulse(impulse)

			-- Add some random angular velocity for more chaotic ragdoll
			local randomSpin = Vector3.new(
				(math.random() - 0.5) * 10,
				(math.random() - 0.5) * 5,
				(math.random() - 0.5) * 10
			)
			torsoPart.AssemblyAngularVelocity = randomSpin
		else
			-- Fallback: Random small impulse if no hit direction stored
			local randomDir = Vector3.new(
				(math.random() - 0.5) * 2,
				0.5,
				(math.random() - 0.5) * 2
			).Unit
			torsoPart:ApplyImpulse(randomDir * 300)
		end
	end
end

--[[
	Sets up ragdoll to trigger on death for a character.
	Connects to Humanoid.Died event.
	
	@param character: The character Model to set up
]]
function RagdollModule.SetupDeathRagdoll(character)
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Pre-configure to prevent joint breaking
	humanoid.BreakJointsOnDeath = false

	-- Connect to death event
	humanoid.Died:Connect(function()
		RagdollModule.Rig(character)
	end)
end

return RagdollModule
