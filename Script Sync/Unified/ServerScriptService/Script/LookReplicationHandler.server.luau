-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- LookReplicationHandler.server.lua (Script)
-- Path: ServerScriptService/Script/LookReplicationHandler.server.lua
-- Purpose: Receives look direction from clients and applies rotation to character joints for all other players to see.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Remote Event
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local lookEvent = RemoteEvents:FindFirstChild("LookEvent")
if not lookEvent then
	lookEvent = Instance.new("RemoteEvent")
	lookEvent.Name = "LookEvent"
	lookEvent.Parent = RemoteEvents
end

-- Cache for original C0 values per player
local playerJointCache = {}

local function cachePlayerJoints(player)
	local char = player.Character
	if not char then return end
	
	local cache = {}
	
	local neck = char:FindFirstChild("Neck", true)
	local rightShoulder = char:FindFirstChild("RightShoulder", true) or char:FindFirstChild("Right Shoulder", true)
	local leftShoulder = char:FindFirstChild("LeftShoulder", true) or char:FindFirstChild("Left Shoulder", true)
	local waist = char:FindFirstChild("Waist", true)
	
	if neck then cache.Neck = { Joint = neck, C0 = neck.C0 } end
	if rightShoulder then cache.RightShoulder = { Joint = rightShoulder, C0 = rightShoulder.C0 } end
	if leftShoulder then cache.LeftShoulder = { Joint = leftShoulder, C0 = leftShoulder.C0 } end
	if waist then cache.Waist = { Joint = waist, C0 = waist.C0 } end
	
	playerJointCache[player] = cache
	
	-- Clean up cache when humanoid dies
	local hum = char:FindFirstChild("Humanoid")
	if hum then
		hum.Died:Connect(function()
			playerJointCache[player] = nil
		end)
	end
end

lookEvent.OnServerEvent:Connect(function(player, lookY)
	-- Validate input
	if typeof(lookY) ~= "number" then return end
	lookY = math.clamp(lookY, -1, 1)
	
	local char = player.Character
	if not char then return end
	
	-- Initialize cache if not exists
	if not playerJointCache[player] then
		cachePlayerJoints(player)
	end
	
	local cache = playerJointCache[player]
	if not cache then return end
	
	local angle = math.asin(lookY)
	
	-- Apply rotation to joints
	for name, data in pairs(cache) do
		if data.Joint and data.Joint.Parent then
			-- Distribute rotation across spine
			local factor = 1
			if name == "Waist" then factor = 0.3 end
			if name == "Neck" then factor = 0.7 end
			if name == "RightShoulder" or name == "LeftShoulder" then factor = 0.4 end
			
			data.Joint.C0 = data.C0 * CFrame.Angles(angle * factor, 0, 0)
		end
	end
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	playerJointCache[player] = nil
end)

-- Handle new characters
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5) -- Wait for rig to load
		cachePlayerJoints(player)
	end)
end)

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		cachePlayerJoints(player)
	end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		cachePlayerJoints(player)
	end)
end

print("[LookReplicationHandler] Initialized")
