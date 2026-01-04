-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- CollisionManager.lua (Script)
-- Path: ServerScriptService/Script/CollisionManager.lua
-- Script Place: ACT 1: Village
-- This script manages collision groups for players, zombies, and invisible walls.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- It's good practice to wait for modules to be available.
local CollisionUtil = require(ServerScriptService.ModuleScript:WaitForChild("CollisionUtil"))

-- =================================================================
-- STEP 1: REGISTER GROUPS AND SET UP RULES
-- =================================================================

-- Register all collision groups. Using pcall to prevent errors if the groups already exist.
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, CollisionUtil.PLAYER_GROUP)
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, CollisionUtil.ZOMBIE_GROUP)
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, CollisionUtil.WALL_GROUP)
pcall(PhysicsService.RegisterCollisionGroup, PhysicsService, CollisionUtil.PROJECTILE_GROUP)

-- Define collision relationships
local groups = {
	{Name = CollisionUtil.PLAYER_GROUP, CollidesWith = {"Default", CollisionUtil.WALL_GROUP, CollisionUtil.ZOMBIE_GROUP, CollisionUtil.PLAYER_GROUP}}, -- Added PLAYER_GROUP for player-to-player collision
	{Name = CollisionUtil.ZOMBIE_GROUP, CollidesWith = {"Default", CollisionUtil.PLAYER_GROUP, CollisionUtil.ZOMBIE_GROUP}},
	{Name = CollisionUtil.WALL_GROUP, CollidesWith = {"Default", CollisionUtil.PLAYER_GROUP}},
	{Name = CollisionUtil.PROJECTILE_GROUP, CollidesWith = {"Default", CollisionUtil.PLAYER_GROUP, CollisionUtil.ZOMBIE_GROUP}}
}

-- Set all groups to not collide with each other by default
local groupNames = {CollisionUtil.PLAYER_GROUP, CollisionUtil.ZOMBIE_GROUP, CollisionUtil.WALL_GROUP, CollisionUtil.PROJECTILE_GROUP}
for _, name1 in ipairs(groupNames) do
	for _, name2 in ipairs(groupNames) do
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(name1, name2, false)
		end)
	end
end

-- Explicitly set the desired collisions
for _, group in ipairs(groups) do
	for _, collidesWith in ipairs(group.CollidesWith) do
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(group.Name, collidesWith, true)
		end)
	end
end



-- =================================================================
-- STEP 2: ASSIGN OBJECTS TO COLLISION GROUPS
-- =================================================================

-- Assign Invisible Walls
local invisibleWallFolder = Workspace:WaitForChild("InvisibleWall", 60)
if invisibleWallFolder then
	for _, part in ipairs(invisibleWallFolder:GetChildren()) do
		if part:IsA("BasePart") then
			part.Transparency = 1 -- Make the part invisible
			part.CanCollide = true -- Ensure the part is physically solid
		end
	end
	-- Use the utility function to assign the entire folder to the collision group
	CollisionUtil.SetGroupRecursive(invisibleWallFolder, CollisionUtil.WALL_GROUP)
	print("Invisible walls have been configured and assigned to the '" .. CollisionUtil.WALL_GROUP .. "' collision group.")
else
	warn("Could not find the 'InvisibleWall' folder in Workspace after waiting for 60 seconds.")
end

-- Assign Player Characters
local function onCharacterAdded(character)
	CollisionUtil.SetGroupRecursive(character, CollisionUtil.PLAYER_GROUP)
	
	-- Disable default climbing
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end
	
	print("Character '" .. character.Name .. "' has been assigned to the '" .. CollisionUtil.PLAYER_GROUP .. "' collision group.")
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Handle players who are already in the game when the script runs
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
