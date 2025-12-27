-- AdminCommands.lua (Script)
-- Path: ServerScriptService/Script/AdminCommands.lua
-- Admin chat commands for testing and debugging

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptFolder = game.ServerScriptService:WaitForChild("ModuleScript")
local Constants = require(ModuleScriptFolder:WaitForChild("Constants"))
local LightingManager = require(ModuleScriptFolder:WaitForChild("LightingManager"))
local GameConfig = require(ModuleScriptFolder:WaitForChild("GameConfig"))

-- === CONFIGURATION ===
local ADMIN_IDS = {
	-- Add your Roblox UserIds here for admin access
	-- Example: 12345678,
	-- Leave empty to allow all players in Studio (for testing)
}

-- Allow all in Studio for easier testing
local RUN_SERVICE = game:GetService("RunService")
local IS_STUDIO = RUN_SERVICE:IsStudio()

-- === HELPER FUNCTIONS ===

local function isAdmin(player)
	if IS_STUDIO and #ADMIN_IDS == 0 then return true end -- Allow all in Studio if no admins defined
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	return false
end

local function getGameState()
	-- Access game state from GameStatus (BindableEvents/Values)
	local gameStatus = ReplicatedStorage:FindFirstChild("GameStatus")
	if gameStatus then
		local waveValue = gameStatus:FindFirstChild("CurrentWave")
		local gameStartedValue = gameStatus:FindFirstChild("GameStarted")
		return {
			wave = waveValue and waveValue.Value or 1,
			gameStarted = gameStartedValue and gameStartedValue.Value or false
		}
	end
	return nil
end

local function killAllZombies()
	local killed = 0
	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild(Constants.Attributes.IS_ZOMBIE) then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
				killed += 1
			end
		end
	end
	return killed
end

local function sendMessage(player, message)
	-- Send feedback to player via StarterGui:SetCore
	local success, err = pcall(function()
		game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
			Text = "[Admin] " .. message,
			Color = Color3.fromRGB(255, 200, 100),
			Font = Enum.Font.SourceSansBold
		})
	end)
	-- Also print to server console
	print("[AdminCommands] " .. message)
end

-- === COMMAND HANDLERS ===

local Commands = {}

Commands["help"] = function(player, args)
	print("=== ADMIN COMMANDS ===")
	print("/setwave <n> - Jump to wave n")
	print("/skipwave - Skip current wave")
	print("/killall - Kill all zombies")
	print("/victory - Jump to wave 50")
	print("/time <0-24> - Set time of day")
	print("/heal - Heal all players")
	print("/god - Toggle god mode")
	print("/points <n> - Add points")
	print("======================")
end

Commands["setwave"] = function(player, args)
	local targetWave = tonumber(args[1])
	if not targetWave then
		warn("Usage: /setwave <number>")
		return
	end
	
	targetWave = math.clamp(targetWave, 1, 50)
	
	-- Fire BindableEvent to GameManager
	local bindables = ReplicatedStorage:FindFirstChild("BindableEvents")
	if bindables then
		local setWaveEvent = bindables:FindFirstChild("AdminSetWave")
		if not setWaveEvent then
			setWaveEvent = Instance.new("BindableEvent")
			setWaveEvent.Name = "AdminSetWave"
			setWaveEvent.Parent = bindables
		end
		setWaveEvent:Fire(targetWave)
		print(player.Name .. " set wave to " .. targetWave)
	end
end

Commands["skipwave"] = function(player, args)
	local killed = killAllZombies()
	
	-- Also signal completion
	local bindables = ReplicatedStorage:FindFirstChild("BindableEvents")
	if bindables then
		local skipEvent = bindables:FindFirstChild("AdminSkipWave")
		if not skipEvent then
			skipEvent = Instance.new("BindableEvent")
			skipEvent.Name = "AdminSkipWave"
			skipEvent.Parent = bindables
		end
		skipEvent:Fire()
	end
	
	print(player.Name .. " skipped wave (killed " .. killed .. " zombies)")
end

Commands["killall"] = function(player, args)
	local killed = killAllZombies()
	print(player.Name .. " killed " .. killed .. " zombies")
end

Commands["victory"] = function(player, args)
	Commands["setwave"](player, {"50"})
	print(player.Name .. " jumped to victory wave!")
end

Commands["time"] = function(player, args)
	local targetTime = tonumber(args[1])
	if not targetTime then
		warn("Usage: /time <0-24>")
		return
	end
	
	targetTime = math.clamp(targetTime, 0, 24)
	LightingManager.SetTimeOfDay(targetTime, 3)
	print(player.Name .. " set time to " .. targetTime)
end

Commands["heal"] = function(player, args)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end
	print(player.Name .. " healed all players")
end

Commands["god"] = function(player, args)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			if humanoid.MaxHealth == math.huge then
				humanoid.MaxHealth = 100
				humanoid.Health = 100
				print(player.Name .. " god mode OFF")
			else
				humanoid.MaxHealth = math.huge
				humanoid.Health = math.huge
				print(player.Name .. " god mode ON")
			end
		end
	end
end

Commands["points"] = function(player, args)
	local amount = tonumber(args[1]) or 1000
	local PointsModule = require(ModuleScriptFolder:WaitForChild("CombatPointsModule"))
	if PointsModule and PointsModule.AddPoints then
		PointsModule.AddPoints(player, amount)
		print(player.Name .. " received " .. amount .. " points")
	end
end

-- === CHAT LISTENER ===

local function onPlayerChatted(player, message)
	if not isAdmin(player) then return end
	
	-- Check if message starts with /
	if string.sub(message, 1, 1) ~= "/" then return end
	
	local args = string.split(message:lower(), " ")
	local commandName = string.sub(args[1], 2) -- Remove the /
	table.remove(args, 1) -- Remove command from args
	
	local commandFunc = Commands[commandName]
	if commandFunc then
		local success, err = pcall(function()
			commandFunc(player, args)
		end)
		if not success then
			warn("Command error: " .. tostring(err))
		end
	end
end

-- === INITIALIZATION ===

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)

-- Handle players already in game (for late script load)
for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end

print("  /help, /setwave, /skipwave, /killall, /victory, /time, /heal, /god, /points")
print("  Admin access: " .. (IS_STUDIO and "All (Studio)" or #ADMIN_IDS .. " users"))
