-- PlaceId Guard: Only run in ACT 1 Village
local ACT1_PLACE_ID = 91523772574713
if game.PlaceId ~= ACT1_PLACE_ID then return end

-- RandomWeaponManager.lua (Script)
-- Path: ServerScriptService/Script/RandomWeaponManager.lua
-- Script Place: ACT 1: Village

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local ModuleScriptReplicatedStorage = ReplicatedStorage.ModuleScript
local ModuleScriptServerScriptService = ServerScriptService.ModuleScript

local WeaponModule = require(ModuleScriptReplicatedStorage:WaitForChild("WeaponModule"))
local RandomConfig = require(ModuleScriptServerScriptService:WaitForChild("RandomWeaponConfig"))
local SessionDataManager = require(ModuleScriptServerScriptService:WaitForChild("SessionDataManager"))
local PointsSystem = require(ModuleScriptServerScriptService:WaitForChild("PointsModule"))
local InventoryManager = require(ModuleScriptServerScriptService:WaitForChild("InventoryManager"))
local BoosterModule = require(ModuleScriptServerScriptService:WaitForChild("BoosterModule"))

local openReplaceUI = RemoteEvents:WaitForChild("OpenReplaceUI")
local replaceChoiceEv = RemoteEvents:WaitForChild("ReplaceChoice")

local purchaseRF = RemoteFunctions:WaitForChild("PurchaseRandomWeapon")
local getCostRF = RemoteFunctions:WaitForChild("GetRandomWeaponCost")

local pendingOffers = {}

local function getPlayerWeapons(player, includeTemporary)
	local weapons = {}
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	local function checkContainer(container)
		if not container then return end
		for _, obj in pairs(container:GetChildren()) do
			if obj:IsA("Tool") and obj:FindFirstChild("Handle") and WeaponModule.Weapons[obj.Name] then
				if not includeTemporary and obj:GetAttribute("TemporaryDrop") == true then
					-- Lewati senjata sementara jika tidak diminta
				else
					table.insert(weapons, obj)
				end
			end
		end
	end

	checkContainer(backpack)
	if character then checkContainer(character) end
	return weapons
end

local function findWeaponTemplate(name)
	local weaponsFolder = ServerStorage:FindFirstChild("Weapons")
	if weaponsFolder and weaponsFolder:FindFirstChild(name) then
		return weaponsFolder:FindFirstChild(name)
	end
	return ServerStorage:FindFirstChild(name)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		-- Cek apakah sudah punya senjata awal atau senjata apapun
		local hasStarter = false
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name == RandomConfig.StarterWeapon then
				hasStarter = true
				break
			end
		end
		if char:FindFirstChildOfClass("Tool") then
			hasStarter = true
		end

		if hasStarter then return end

		-- Logika Booster "Legion's Legacy"
		local boosterData = BoosterModule.GetData(player)
		local usedLegacyBooster = false
		if boosterData and boosterData.Active == "LegionsLegacy" then
			local success, usedBoosterName = pcall(BoosterModule.UseActiveBooster, player)
			if success and usedBoosterName == "LegionsLegacy" then
				usedLegacyBooster = true
			end
		end

		local weaponNameToGive
		if usedLegacyBooster then
			-- Pilih senjata acak dari daftar
			local pool = RandomConfig.AvailableWeapons
			if #pool > 0 then
				weaponNameToGive = pool[math.random(1, #pool)]
				print(player.Name .. " used Legion's Legacy and got: " .. weaponNameToGive)
			else
				-- Fallback jika daftar kosong
				weaponNameToGive = RandomConfig.StarterWeapon
			end
		else
			-- Berikan senjata awal biasa
			weaponNameToGive = RandomConfig.StarterWeapon
		end

		local template = findWeaponTemplate(weaponNameToGive)
		if template then
			local clone = template:Clone()
			clone:SetAttribute("WeaponId", HttpService:GenerateGUID(false))

			local equippedSkin = InventoryManager.GetEquippedSkin(player, clone.Name)
			if equippedSkin then
				clone:SetAttribute("EquippedSkin", equippedSkin)
			end

			clone.Parent = player:FindFirstChild("Backpack") or player
		end
	end)
end)

purchaseRF.OnServerInvoke = function(player)
	if not player then return {success=false, message="Invalid player"} end

	local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
	local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
	local currentDifficulty = GameStatus:GetDifficulty()
	local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules

	local cost
	if difficultyRules and difficultyRules.IncreaseRandomWeaponCost then
		local purchaseCount = SessionDataManager:GetRandomWeaponPurchases(player)
		cost = GameConfig.RandomWeapon.BaseCost + (purchaseCount * GameConfig.RandomWeapon.CostIncrease)
	else
		cost = GameConfig.RandomWeapon.BaseCost
	end

	local hasDiscount = false
	local boosterData = BoosterModule.GetData(player)
	if boosterData and boosterData.Active == "CouponDiscount" then
		hasDiscount = true
		cost = math.floor(cost / 2)
	end

	if PointsSystem.GetPoints(player) < cost then
		return {success=false, message="Not enough points"}
	end

	PointsSystem.AddPoints(player, -cost)
	SessionDataManager:IncrementRandomWeaponPurchases(player)
	if hasDiscount then BoosterModule.UseActiveBooster(player) end

	local pool = RandomConfig.AvailableWeapons
	if #pool == 0 then return {success=false, message="No weapons configured"} end

	local newName = pool[math.random(1, #pool)]
	local template = findWeaponTemplate(newName)
	if not template then
		return {success=false, message="Weapon template not found: " .. newName}
	end

	local clone = template:Clone()
	local newWeaponId = HttpService:GenerateGUID(false)
	clone:SetAttribute("WeaponId", newWeaponId)

	local equippedSkin = InventoryManager.GetEquippedSkin(player, clone.Name)
	if equippedSkin then
		clone:SetAttribute("EquippedSkin", equippedSkin)
	end

	local weapons = getPlayerWeapons(player)
	if #weapons >= RandomConfig.MaxWeapons then
		local names = {}
		for _, w in ipairs(weapons) do table.insert(names, w.Name) end

		-- DO NOT PARENT CLONE YET
		pendingOffers[player] = { weaponId = newWeaponId, newWeaponInstance = clone, time = tick() }

		openReplaceUI:FireClient(player, names, newName, cost, hasDiscount)
		return {success=false, message="choose", weaponName=newName}
	else
		clone.Parent = player:FindFirstChildOfClass("Backpack") or player
	end

	return {success=true, message=("Purchased %s"):format(newName), weaponName=newName, replaced=false}
end

replaceChoiceEv.OnServerEvent:Connect(function(player, index)
	local offer = pendingOffers[player]
	if not offer or (tick() - offer.time > 60) then
		if offer then 
			if offer.newWeaponInstance then offer.newWeaponInstance:Destroy() end
			pendingOffers[player] = nil 
		end
		return
	end

	local newWeapon = offer.newWeaponInstance

	-- Aksi "Buang Senjata Baru"
	if index == -1 then
		if newWeapon then newWeapon:Destroy() end
	else -- Ganti senjata lama
		local weapons = getPlayerWeapons(player)

		if index >= 1 and index <= #weapons then
			local oldWeapon = weapons[index]

			if oldWeapon then
				-- Logic to ensure new weapon takes old weapon's slot:
				local newOrder = {}
				for i, w in ipairs(weapons) do
					if w == oldWeapon then
						if newWeapon then table.insert(newOrder, newWeapon) end
					else
						table.insert(newOrder, w)
					end
				end

				oldWeapon:Destroy()

				local backpack = player:FindFirstChild("Backpack")
				if backpack then
					-- Move active weapons to backpack first if equipped
					local char = player.Character
					if char then
						for _, t in ipairs(char:GetChildren()) do
							if t:IsA("Tool") then t.Parent = backpack end
						end
					end

					for _, w in ipairs(newOrder) do
						w.Parent = nil
					end
					task.wait()
					for _, w in ipairs(newOrder) do
						w.Parent = backpack
					end
				end
			end
		else
			-- Invalid index, just discard new
			if newWeapon then newWeapon:Destroy() end
		end
	end

	pendingOffers[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	pendingOffers[player] = nil
end)

getCostRF.OnServerInvoke = function(player)
	local GameStatus = require(ModuleScriptServerScriptService:WaitForChild("GameStatus"))
	local GameConfig = require(ModuleScriptServerScriptService:WaitForChild("GameConfig"))
	local currentDifficulty = GameStatus:GetDifficulty()
	local difficultyRules = GameConfig.Difficulty[currentDifficulty] and GameConfig.Difficulty[currentDifficulty].Rules

	local cost
	if difficultyRules and difficultyRules.IncreaseRandomWeaponCost then
		local purchaseCount = SessionDataManager:GetRandomWeaponPurchases(player)
		cost = GameConfig.RandomWeapon.BaseCost + (purchaseCount * GameConfig.RandomWeapon.CostIncrease)
	else
		cost = GameConfig.RandomWeapon.BaseCost
	end

	return cost
end
