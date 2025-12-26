-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- CollisionUtil.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/CollisionUtil.lua
-- Script Place: ACT 1: Village
-- A utility module for assigning collision groups to objects.

local PhysicsService = game:GetService("PhysicsService")

local CollisionUtil = {}

-- Define group names as constants to be used across different scripts
CollisionUtil.PLAYER_GROUP = "Players"
CollisionUtil.ZOMBIE_GROUP = "Zombies"
CollisionUtil.WALL_GROUP = "InvisibleWalls"
CollisionUtil.PROJECTILE_GROUP = "Projectiles"

--- Sets the collision group for all BaseParts within a given model or folder.
-- @param object The model, folder, or part to assign.
-- @param groupName The name of the collision group to assign.
function CollisionUtil.SetGroupRecursive(object, groupName)
	if not object or not groupName then return end

	if object:IsA("BasePart") then
		pcall(function()
			object.CollisionGroup = groupName
		end)
	end

	for _, child in ipairs(object:GetChildren()) do
		CollisionUtil.SetGroupRecursive(child, groupName)
	end
end

return CollisionUtil
