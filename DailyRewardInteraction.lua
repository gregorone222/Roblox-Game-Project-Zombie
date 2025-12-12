-- DailyRewardInteraction.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DailyRewardInteraction.lua
-- Handles the client-side interaction with the Daily Reward Supply Crate

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local ClaimDailyReward = RemoteFunctions:WaitForChild("ClaimDailyReward")
local GetDailyRewardInfo = RemoteFunctions:WaitForChild("GetDailyRewardInfo")

local function onPromptTriggered(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then return end

	if prompt.ObjectText == "Open Supply Drop" or prompt.Name == "DailyReward" then
		print("Attempting to claim daily reward...")

		-- Optional: Play animation/sound locally immediately for responsiveness

		-- Invoke Server
		local success, result = pcall(function()
			return ClaimDailyReward:InvokeServer()
		end)

		if success and result then
			print("Daily Reward Claimed Successfully!")
			-- Update Visuals: Disable Prompt locally or show success effect
			prompt.Enabled = false

			-- Show Success Notification (Simple Text for now, or use NotificationUI if available)
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Supply Drop Opened";
				Text = "You received your daily supplies!";
				Duration = 5;
			})

			-- Remove Highlight if exists
			if prompt.Parent then
				local highlight = prompt.Parent:FindFirstChildOfClass("Highlight")
				if highlight then highlight:Destroy() end
			end
		else
			warn("Failed to claim reward: " .. tostring(result))
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Locked";
				Text = "You have already claimed this today.";
				Duration = 3;
			})
		end
	end
end

ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

-- Initial Check to Enable/Disable Prompt based on status
task.spawn(function()
	task.wait(2) -- Wait for Lobby to load
	local success, state = pcall(function() return GetDailyRewardInfo:InvokeServer() end)

	if success and state then
		local lobby = workspace:FindFirstChild("LobbyEnvironment")
		if lobby then
			local crate = lobby:FindFirstChild("SupplyCrate", true)
			if crate then
				local prompt = crate:FindFirstChildWhichIsA("ProximityPrompt")
				if prompt then
					prompt.Enabled = state.CanClaim
					if not state.CanClaim then
						prompt.ActionText = "Come back tomorrow"
					end
				end
			end
		end
	end
end)
