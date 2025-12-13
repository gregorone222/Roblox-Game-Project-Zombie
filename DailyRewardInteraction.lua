-- DailyRewardInteraction.lua (LocalScript)
-- Path: StarterPlayer/StarterPlayerScripts/DailyRewardInteraction.lua
-- Handles the client-side interaction with the Daily Reward Supply Crate

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local ClaimDailyReward = RemoteFunctions:WaitForChild("ClaimDailyReward")
local GetDailyRewardInfo = RemoteFunctions:WaitForChild("GetDailyRewardInfo")

local function playCrateAnimation(crate)
	if not crate then return end
	local lid = crate:FindFirstChild("Lid")
	if lid then
		-- Open Animation
		local goal = {CFrame = lid.CFrame * CFrame.Angles(math.rad(110), 0, 0)}
		local tween = TweenService:Create(lid, TweenInfo.new(1.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), goal)
		tween:Play()

		-- Play Sound
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://3802269741" -- Heavy metal chest open sound
		sound.Parent = lid
		sound:Play()
		game.Debris:AddItem(sound, 3)
	end

	-- Particles
	local particles = crate:FindFirstChild("Glow", true)
	if particles then particles.Enabled = true end
end

local function onPromptTriggered(prompt, triggeringPlayer)
	if triggeringPlayer ~= player then return end

	if prompt.Name == "DailyRewardPrompt" then
		print("Attempting to claim daily reward...")
		prompt.Enabled = false -- Prevent double clicks

		-- Play Animation Immediately for Feedback
		playCrateAnimation(prompt.Parent)

		-- Invoke Server
		local success, result = pcall(function()
			return ClaimDailyReward:InvokeServer()
		end)

		if success and result and result.Success then
			print("Daily Reward Claimed Successfully!")

			-- Show Success Notification
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "SUPPLY DROP SECURED";
				Text = "Received: " .. tostring(result.ClaimedReward.Value) .. " " .. result.ClaimedReward.Type;
				Duration = 5;
				Icon = "rbxassetid://13386920804" -- Crate Icon
			})

			-- Remove Highlight if exists
			if prompt.Parent then
				local highlight = prompt.Parent:FindFirstChildOfClass("Highlight")
				if highlight then highlight:Destroy() end
			end
		else
			warn("Failed to claim reward: " .. tostring(result))
			prompt.Enabled = true -- Re-enable if failed

			local reason = (result and result.Reason) or "Unknown Error"
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "ACCESS DENIED";
				Text = reason;
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
		local lobby = workspace:WaitForChild("LobbyEnvironment", 5)
		if lobby then
			local crate = lobby:FindFirstChild("SupplyCrate", true)
			if crate then
				-- Ensure Prompt Exists
				local prompt = crate:FindFirstChild("DailyRewardPrompt")
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.Name = "DailyRewardPrompt"
					prompt.ActionText = "Open Supply Drop"
					prompt.ObjectText = "Daily Ration"
					prompt.KeyboardKeyCode = Enum.KeyCode.E
					prompt.HoldDuration = 1
					prompt.MaxActivationDistance = 10
					prompt.RequiresLineOfSight = false
					prompt.Parent = crate
				end

				prompt.Enabled = state.CanClaim

				if state.CanClaim then
					-- Add Glow/Highlight
					local h = Instance.new("Highlight")
					h.FillColor = Color3.fromRGB(50, 255, 100)
					h.OutlineColor = Color3.fromRGB(255, 255, 255)
					h.FillTransparency = 0.5
					h.Parent = crate
				else
					prompt.ActionText = "Next Drop: Tomorrow"
					prompt.Enabled = false
				end
			end
		end
	end
end)
