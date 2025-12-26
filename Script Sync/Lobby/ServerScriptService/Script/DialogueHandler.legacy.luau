-- DialogueHandler.lua (Script)
-- Path: ServerScriptService/Script/DialogueHandler.lua
-- Script Place: Lobby, ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Ensure RemoteEvent exists
local StartDialogueEvent = ReplicatedStorage:FindFirstChild("RemoteEvents") 
	and ReplicatedStorage.RemoteEvents:FindFirstChild("StartDialogueEvent")

if not StartDialogueEvent then
	-- Fallback safety if Constants/Init didn't run, though they should have
	local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "RemoteEvents"
		remotes.Parent = ReplicatedStorage
	end
	StartDialogueEvent = Instance.new("RemoteEvent")
	StartDialogueEvent.Name = "StartDialogueEvent"
	StartDialogueEvent.Parent = remotes
end

-- Map Prompt Names to Dialogue IDs
local promptMap = {
	["DialogueAlexander"] = "alexander_intro",
	["Quartermaster"] = "quartermaster_greet"
}

-- Handle Prompt Trigger
local function onPromptTriggered(promptObject, player)
	local part = promptObject.Parent
	if not part then return end

	local dialogueID = promptMap[part.Name]

	if dialogueID then
		print("Dialogue triggered for:", player.Name, "ID:", dialogueID)

		-- Get position source
		local sourcePos = part.Position
		if part:IsA("Model") then
			if part.PrimaryPart then
				sourcePos = part.PrimaryPart.Position
			else
				sourcePos = part:GetPivot().Position
			end
		end

		StartDialogueEvent:FireClient(player, dialogueID, sourcePos)
	end
end

-- Connect Service
ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

print("DialogueHandler Initialized. Listening for prompts...")
