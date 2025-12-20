-- PlayerRagdollHandler.lua (Server Script)
-- Path: ServerScriptService/Script/PlayerRagdollHandler.lua
-- Description: Sets up ragdoll for player characters on death

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RagdollModule = require(ServerScriptService.ModuleScript:WaitForChild("RagdollModule"))

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	
	-- Pre-configure
	humanoid.BreakJointsOnDeath = false
	
	-- Connect death event
	humanoid.Died:Connect(function()
		RagdollModule.Rig(character)
	end)
end

local function onPlayerAdded(player)
	-- Handle existing character
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	-- Handle future respawns
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Connect to existing players
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Connect to new players
Players.PlayerAdded:Connect(onPlayerAdded)
