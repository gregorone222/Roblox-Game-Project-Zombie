-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return {} end

-- ObjectiveManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/ObjectiveManager.lua
-- Deskripsi: Mengelola logika objektif interaktif (Scavenge, Defend, Retrieve)

local ObjectiveManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
-- Event untuk update UI Objektif ke Client
local ObjectiveUpdateEvent = RemoteEvents:FindFirstChild("ObjectiveUpdateEvent") or Instance.new("RemoteEvent", RemoteEvents)
ObjectiveUpdateEvent.Name = "ObjectiveUpdateEvent"

-- STATE
ObjectiveManager.CurrentObjective = nil
ObjectiveManager.IsActive = false
ObjectiveManager.Progress = 0
ObjectiveManager.Target = 0
ObjectiveManager.Timer = 0
ObjectiveManager.ObjectiveObjects = {}

-- KONFIGURASI OBJEKTIF
local OBJECTIVE_TYPES = {
	SCAVENGE = "SCAVENGE",
	DEFEND = "DEFEND",
	RETRIEVE = "RETRIEVE"
}

-- === HELPER: CREATE ASSETS ===
local function createGasCan(pos)
	local model = Instance.new("Model")
	model.Name = "Objective_GasCan"

	local part = Instance.new("Part")
	part.Name = "Can"
	part.Size = Vector3.new(1.5, 2, 1.5)
	part.Color = Color3.fromRGB(200, 50, 50) -- Merah
	part.Material = Enum.Material.Metal
	part.Position = pos
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model

	-- Visual Handle
	local handle = Instance.new("Part")
	handle.Size = Vector3.new(1.5, 0.4, 0.4)
	handle.Color = Color3.fromRGB(50, 50, 50)
	handle.Position = pos + Vector3.new(0, 1.2, 0)
	handle.Anchored = true
	handle.CanCollide = false
	handle.Parent = model

	-- Highlight
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 100, 100)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Gas Can"
	prompt.ActionText = "Pick Up"
	prompt.HoldDuration = 1
	prompt.Parent = part

	return model, prompt
end

local function createGenerator(pos)
	local model = Instance.new("Model")
	model.Name = "Objective_Generator"

	local main = Instance.new("Part")
	main.Size = Vector3.new(6, 6, 6)
	main.Color = Color3.fromRGB(80, 80, 80)
	main.Position = pos
	main.Anchored = true
	main.Material = Enum.Material.DiamondPlate
	main.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Generator"
	prompt.ActionText = "Refuel"
	prompt.HoldDuration = 2
	prompt.Enabled = false -- Aktif hanya jika bawa bensin
	prompt.Parent = main

	return model, prompt
end

local function createUplinkZone(pos, radius)
	local part = Instance.new("Part")
	part.Name = "Objective_UplinkZone"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.5, radius*2, radius*2)
	part.Position = pos - Vector3.new(0, 2, 0) -- Di lantai
	part.Orientation = Vector3.new(0, 0, 90)
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.8
	part.Color = Color3.fromRGB(0, 255, 255)
	part.Material = Enum.Material.Neon
	part.Parent = workspace

	-- Visual Border
	local border = Instance.new("SelectionSphere")
	border.Adornee = part
	border.Color3 = Color3.fromRGB(0, 255, 255)
	border.Transparency = 0.5
	border.Parent = part

	return part
end

local function createSampleVial(pos)
	local model = Instance.new("Model")
	model.Name = "Objective_Sample"

	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 2, 1)
	part.Color = Color3.fromRGB(50, 255, 50) -- Hijau Toxic
	part.Material = Enum.Material.Neon
	part.Position = pos
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Viral Sample"
	prompt.ActionText = "Retrieve"
	prompt.HoldDuration = 4 -- Lama, butuh cover
	prompt.Parent = part

	return model, prompt
end

-- === CORE FUNCTIONS ===

function ObjectiveManager:StartObjective(type, config)
	if self.IsActive then return end
	self.IsActive = true
	self.CurrentObjective = type
	self.ObjectiveObjects = {}

	print("Starting Objective: " .. type)

	if type == OBJECTIVE_TYPES.SCAVENGE then
		-- Config: { Count = 3, GenPos = Vector3, Spawns = {Vector3...} }
		self.Target = config.Count
		self.Progress = 0

		-- Spawn Generator
		local gen, genPrompt = createGenerator(config.GenPos or Vector3.new(0, 5, 0))
		gen.Parent = workspace
		table.insert(self.ObjectiveObjects, gen)

		-- Spawn Gas Cans
		local itemsHeld = 0

		for i, pos in ipairs(config.Spawns) do
			local can, prompt = createGasCan(pos)
			can.Parent = workspace
			table.insert(self.ObjectiveObjects, can)

			prompt.Triggered:Connect(function(player)
				can:Destroy()
				-- Beri visual effect ke player (bawa bensin)
				local visualCan = Instance.new("Part")
				visualCan.Name = "CarriedGas"
				visualCan.Size = Vector3.new(1,1,1)
				visualCan.Color = Color3.fromRGB(200, 0, 0)
				visualCan.CanCollide = false
				visualCan.Parent = player.Character
				local w = Instance.new("WeldConstraint")
				w.Part0 = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
				w.Part1 = visualCan
				w.Parent = visualCan
				visualCan.CFrame = w.Part0.CFrame * CFrame.new(0, 0, 1)

				player:SetAttribute("HasGas", true)
				genPrompt.Enabled = true -- Bisa setor sekarang
				ObjectiveUpdateEvent:FireAllClients("ALERT", "Gas Can Collected! Return to Generator.")
			end)
		end

		genPrompt.Triggered:Connect(function(player)
			if player:GetAttribute("HasGas") then
				player:SetAttribute("HasGas", nil)
				if player.Character:FindFirstChild("CarriedGas") then
					player.Character.CarriedGas:Destroy()
				end

				self.Progress += 1
				ObjectiveUpdateEvent:FireAllClients("UPDATE", {
					Title = "RESTORE POWER",
					Desc = "Find Fuel Cans",
					Progress = self.Progress,
					Target = self.Target
				})

				if self.Progress >= self.Target then
					self:CompleteObjective()
				end
			else
				ObjectiveUpdateEvent:FireClient(player, "ALERT", "Find a Gas Can first!")
			end
		end)

		ObjectiveUpdateEvent:FireAllClients("START", {
			Title = "RESTORE POWER",
			Desc = "Find Fuel Cans and Refuel the Generator",
			Progress = 0,
			Target = self.Target
		})

	elseif type == OBJECTIVE_TYPES.DEFEND then
		-- Config: { Duration = 60, ZonePos = Vector3, Radius = 15 }
		self.Target = config.Duration
		self.Progress = 0
		self.Timer = config.Duration

		local zone = createUplinkZone(config.ZonePos, config.Radius)
		table.insert(self.ObjectiveObjects, zone)

		ObjectiveUpdateEvent:FireAllClients("START", {
			Title = "DATA UPLINK",
			Desc = "Defend the Uplink Zone",
			Progress = 0,
			Target = 100 -- Persen
		})

		task.spawn(function()
			while self.IsActive and self.Progress < 100 do
				task.wait(1)
				-- Cek pemain di zona
				local playersInZone = 0
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						local dist = (plr.Character.HumanoidRootPart.Position - config.ZonePos).Magnitude
						if dist <= config.Radius and plr.Character.Humanoid.Health > 0 then
							playersInZone += 1
						end
					end
				end

				if playersInZone > 0 then
					self.Progress += (100 / config.Duration) * (1 + (playersInZone * 0.1)) -- Bonus speed kalau rame
				end

				ObjectiveUpdateEvent:FireAllClients("UPDATE", {
					Title = "DATA UPLINK",
					Desc = playersInZone > 0 and "Uploading..." or "ZONE EMPTY - RETURN TO ZONE",
					Progress = math.min(100, math.floor(self.Progress)),
					Target = 100,
					IsCritical = (playersInZone == 0)
				})

				if self.Progress >= 100 then
					self:CompleteObjective()
					break
				end
			end
		end)

	elseif type == OBJECTIVE_TYPES.RETRIEVE then
		-- Config: { Count = 4, Spawns = {Vector3...} }
		self.Target = config.Count
		self.Progress = 0

		ObjectiveUpdateEvent:FireAllClients("START", {
			Title = "SAMPLE RETRIEVAL",
			Desc = "Collect Viral Samples",
			Progress = 0,
			Target = self.Target
		})

		for i, pos in ipairs(config.Spawns) do
			local vial, prompt = createSampleVial(pos)
			vial.Parent = workspace
			table.insert(self.ObjectiveObjects, vial)

			prompt.Triggered:Connect(function(player)
				vial:Destroy()
				self.Progress += 1
				ObjectiveUpdateEvent:FireAllClients("UPDATE", {
					Title = "SAMPLE RETRIEVAL",
					Desc = "Collect Viral Samples",
					Progress = self.Progress,
					Target = self.Target
				})

				if self.Progress >= self.Target then
					self:CompleteObjective()
				end
			end)
		end
	end
end

function ObjectiveManager:CompleteObjective()
	if not self.IsActive then return end
	self.IsActive = false

	print("Objective Completed!")
	ObjectiveUpdateEvent:FireAllClients("COMPLETE", "Objective Secured!")

	-- Cleanup
	for _, obj in ipairs(self.ObjectiveObjects) do
		if obj and obj.Parent then obj:Destroy() end
	end
	self.ObjectiveObjects = {}

	-- Reward (Bisa integrasi dengan PointsModule)
	for _, plr in ipairs(Players:GetPlayers()) do
		-- Beri bonus poin
		local PointsSystem = require(ServerScriptService.ModuleScript:WaitForChild("PointsModule"))
		PointsSystem.AddPoints(plr, 1000)
	end
end

-- API untuk cek apakah objektif sedang berjalan (bisa pause spawn zombie atau logic lain)
function ObjectiveManager:IsObjectiveActive()
	return self.IsActive
end

-- CLEANUP & RESET
function ObjectiveManager:Reset()
	print("ObjectiveManager: Resetting state...")
	self.IsActive = false
	self.CurrentObjective = nil
	self.Progress = 0
	self.Target = 0

	-- Destroy objects
	for _, obj in ipairs(self.ObjectiveObjects) do
		if obj and obj.Parent then obj:Destroy() end
	end
	self.ObjectiveObjects = {}

	-- Reset Player Attributes
	for _, plr in ipairs(Players:GetPlayers()) do
		plr:SetAttribute("HasGas", nil)
		if plr.Character and plr.Character:FindFirstChild("CarriedGas") then
			plr.Character.CarriedGas:Destroy()
		end
	end

	ObjectiveUpdateEvent:FireAllClients("COMPLETE", "Objective Reset") -- Hide UI
end

-- HANDLING PLAYER DISCONNECT / DEATH (Prevent Softlock)
local function handleDrop(player)
	if player:GetAttribute("HasGas") then
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local pos = char.HumanoidRootPart.Position
			local can, prompt = createGasCan(pos)
			can.Parent = workspace
			table.insert(ObjectiveManager.ObjectiveObjects, can)

			prompt.Triggered:Connect(function(picker)
				can:Destroy()
				local visualCan = Instance.new("Part")
				visualCan.Name = "CarriedGas"
				visualCan.Size = Vector3.new(1,1,1)
				visualCan.Color = Color3.fromRGB(200, 0, 0)
				visualCan.CanCollide = false
				visualCan.Parent = picker.Character
				local w = Instance.new("WeldConstraint")
				w.Part0 = picker.Character:FindFirstChild("UpperTorso") or picker.Character:FindFirstChild("Torso")
				w.Part1 = visualCan
				w.Parent = visualCan
				visualCan.CFrame = w.Part0.CFrame * CFrame.new(0, 0, 1)

				picker:SetAttribute("HasGas", true)
				-- Re-enable generator prompt if needed (simplified: gen prompt is always checking attr)
				ObjectiveUpdateEvent:FireAllClients("ALERT", "Gas Can Recovered!")
			end)
			print("Gas Can Dropped by " .. player.Name)
		end
		player:SetAttribute("HasGas", nil)
	end
end

Players.PlayerRemoving:Connect(handleDrop)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			handleDrop(player)
		end)
	end)
end)

return ObjectiveManager
