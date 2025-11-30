-- ProximityUIHandler.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/ProximityUIHandler.lua
-- Script Place: Lobby, ACT 1: Village
-- Purpose: Centralized handler for connecting Client-Side UIs to ProximityPrompts in Workspace.
-- Prevents duplicate code and ensures robust interaction logic (toggle behavior, validation).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local ProximityUIHandler = {}
ProximityUIHandler.__index = ProximityUIHandler

local player = Players.LocalPlayer

--[[
	Register a new UI interaction.
	
	Params:
	- config (table):
		- name (string): Identifier for logging.
		- partName (string): The name of the Part/Model in Workspace to search for.
		- parent (Instance, optional): The specific parent to search in (defaults to Workspace).
		- searchRecursive (boolean, optional): Whether to search recursively for the part/prompt (default: true).
		- onToggle (function): Callback function(isOpen). Return true if handled successfully.
]]
function ProximityUIHandler.Register(config)
	if not RunService:IsClient() then
		warn("ProximityUIHandler is a client-side module only.")
		return
	end

	local self = setmetatable({}, ProximityUIHandler)
	self.Name = config.name or "UnknownUI"
	self.PartName = config.partName
	self.Parent = config.parent or Workspace
	self.Recursive = config.searchRecursive ~= false -- Default true
	self.OnToggle = config.onToggle
	self.IsOpen = false
	self.Prompt = nil
	self.Connection = nil

	-- Attempt to setup immediately, but also wait if needed
	task.spawn(function()
		self:Setup()
	end)

	return self
end

function ProximityUIHandler:Setup()
	-- 1. Find the Target Part
	local targetPart
	if self.Recursive then
		-- Use recursion if needed, but simple WaitForChild is often safer for root parts
		targetPart = self.Parent:WaitForChild(self.PartName, 10)
	else
		targetPart = self.Parent:FindFirstChild(self.PartName)
	end

	if not targetPart then
		warn(string.format("[%s] Target part '%s' not found in %s.", tostring(self.Name), tostring(self.PartName), tostring(self.Parent.Name)))
		return
	end

	-- 2. Find the ProximityPrompt
	local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")

	-- Recursive search by ClassName if standard search fails
	if not prompt and self.Recursive then
		for _, descendant in ipairs(targetPart:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") then
				prompt = descendant
				break
			end
		end
	end

	if not prompt then
		warn(string.format("[%s] ProximityPrompt not found in '%s' (Recursive: %s).", tostring(self.Name), tostring(self.PartName), tostring(self.Recursive)))
		return
	end

	self.Prompt = prompt

	-- 3. Connect Event
	self.Connection = prompt.Triggered:Connect(function(triggeredBy)
		if triggeredBy == player then
			self:Toggle()
		end
	end)

	print(string.format("[%s] Successfully connected to ProximityPrompt in '%s'.", tostring(self.Name), tostring(self.PartName)))
end

function ProximityUIHandler:Toggle()
	self.IsOpen = not self.IsOpen
	self:_TriggerCallback()
end

-- Force Set State (Used when UI is closed via X button)
function ProximityUIHandler:SetOpen(isOpen)
	if self.IsOpen ~= isOpen then
		self.IsOpen = isOpen
		-- We usually don't trigger callback here to avoid loops, 
		-- as this is called BY the UI when it changes state.
	end
end

function ProximityUIHandler:_TriggerCallback()
	if self.OnToggle then
		local success = pcall(function()
			self.OnToggle(self.IsOpen)
		end)
		if not success then
			warn(string.format("[%s] Error in OnToggle callback.", tostring(self.Name)))
		end
	end
end

function ProximityUIHandler:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self.Prompt = nil
end

return ProximityUIHandler
