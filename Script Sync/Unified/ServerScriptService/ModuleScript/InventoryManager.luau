-- InventoryManager.luau (ModuleScript)
-- Path: ServerScriptService/ModuleScript/InventoryManager.luau
-- Script Place: Lobby & ACT 1: Village
-- Purpose: Centralized inventory management (weapons, skins, boosters, items)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStoreManager = require(script.Parent:WaitForChild("DataStoreManager"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

-- RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local InventoryUpdateEvent = RemoteEvents:WaitForChild("InventoryUpdateEvent", 5)

local InventoryManager = {}

-- =============================================================================
-- INTERNAL HELPERS
-- =============================================================================

local function getPlayerInventory(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[InventoryManager] Failed to get data for player: " .. player.Name)
		return nil
	end
	
	-- Ensure inventory structure exists
	if not playerData.data.inventory then
		playerData.data.inventory = {
			Coins = 0,
			Skins = { Owned = {}, Equipped = {} },
			Weapons = {},
			Boosters = {},
			Items = {}
		}
		DataStoreManager:UpdatePlayerData(player, playerData.data)
	end
	
	return playerData.data.inventory, playerData.data
end

local function savePlayerInventory(player, inventoryData, fullData)
	fullData.inventory = inventoryData
	DataStoreManager:UpdatePlayerData(player, fullData)
	
	-- Fire update event to client
	if InventoryUpdateEvent then
		InventoryUpdateEvent:FireClient(player, inventoryData)
	end
end

-- =============================================================================
-- WEAPONS API
-- =============================================================================

function InventoryManager.GetOwnedWeapons(player)
	local inventory = getPlayerInventory(player)
	if not inventory then return {} end
	return inventory.Weapons or {}
end

function InventoryManager.OwnsWeapon(player, weaponName)
	local weapons = InventoryManager.GetOwnedWeapons(player)
	return table.find(weapons, weaponName) ~= nil
end

function InventoryManager.AddWeapon(player, weaponName)
	if not player or not weaponName then return false, "Invalid arguments" end
	if not WeaponModule.Weapons[weaponName] then return false, "Weapon not found in config" end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.Weapons = inventory.Weapons or {}
	if table.find(inventory.Weapons, weaponName) then
		return false, "Weapon already owned"
	end
	
	table.insert(inventory.Weapons, weaponName)
	savePlayerInventory(player, inventory, fullData)
	return true, "Weapon added successfully"
end

function InventoryManager.RemoveWeapon(player, weaponName)
	if not player or not weaponName then return false, "Invalid arguments" end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory or not inventory.Weapons then return false, "No weapons in inventory" end
	
	local idx = table.find(inventory.Weapons, weaponName)
	if not idx then return false, "Weapon not owned" end
	
	table.remove(inventory.Weapons, idx)
	savePlayerInventory(player, inventory, fullData)
	return true, "Weapon removed successfully"
end

-- =============================================================================
-- SKINS API
-- =============================================================================

function InventoryManager.GetOwnedSkins(player, weaponName)
	local inventory = getPlayerInventory(player)
	if not inventory or not inventory.Skins or not inventory.Skins.Owned then return {} end
	
	if weaponName then
		return inventory.Skins.Owned[weaponName] or {"Default Skin"}
	end
	return inventory.Skins.Owned
end

function InventoryManager.GetEquippedSkin(player, weaponName)
	local inventory = getPlayerInventory(player)
	if not inventory or not inventory.Skins or not inventory.Skins.Equipped then return "Default Skin" end
	return inventory.Skins.Equipped[weaponName] or "Default Skin"
end

function InventoryManager.OwnsSkin(player, weaponName, skinName)
	local skins = InventoryManager.GetOwnedSkins(player, weaponName)
	return table.find(skins, skinName) ~= nil
end

function InventoryManager.AddSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then return false, "Invalid arguments" end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.Skins = inventory.Skins or { Owned = {}, Equipped = {} }
	inventory.Skins.Owned = inventory.Skins.Owned or {}
	inventory.Skins.Owned[weaponName] = inventory.Skins.Owned[weaponName] or {"Default Skin"}
	
	if table.find(inventory.Skins.Owned[weaponName], skinName) then
		return false, "Skin already owned"
	end
	
	table.insert(inventory.Skins.Owned[weaponName], skinName)
	savePlayerInventory(player, inventory, fullData)
	return true, "Skin added successfully"
end

function InventoryManager.EquipSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then return false, "Invalid arguments" end
	
	-- Check if player owns the skin
	if not InventoryManager.OwnsSkin(player, weaponName, skinName) then
		return false, "Skin not owned"
	end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.Skins.Equipped = inventory.Skins.Equipped or {}
	inventory.Skins.Equipped[weaponName] = skinName
	savePlayerInventory(player, inventory, fullData)
	return true, "Skin equipped successfully"
end

-- =============================================================================
-- BOOSTERS API
-- =============================================================================

function InventoryManager.GetBoosters(player)
	local inventory = getPlayerInventory(player)
	if not inventory then return {} end
	return inventory.Boosters or {}
end

function InventoryManager.AddBooster(player, boosterID, amount)
	if not player or not boosterID then return false, "Invalid arguments" end
	amount = amount or 1
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.Boosters = inventory.Boosters or {}
	inventory.Boosters[boosterID] = (inventory.Boosters[boosterID] or 0) + amount
	savePlayerInventory(player, inventory, fullData)
	return true, "Booster added"
end

function InventoryManager.UseBooster(player, boosterID)
	if not player or not boosterID then return false, "Invalid arguments" end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory or not inventory.Boosters then return false, "No boosters" end
	
	if not inventory.Boosters[boosterID] or inventory.Boosters[boosterID] <= 0 then
		return false, "Booster not available"
	end
	
	inventory.Boosters[boosterID] -= 1
	if inventory.Boosters[boosterID] <= 0 then
		inventory.Boosters[boosterID] = nil
	end
	savePlayerInventory(player, inventory, fullData)
	return true, "Booster used"
end

-- =============================================================================
-- ITEMS API (Generic consumables)
-- =============================================================================

function InventoryManager.GetItems(player)
	local inventory = getPlayerInventory(player)
	if not inventory then return {} end
	return inventory.Items or {}
end

function InventoryManager.AddItem(player, itemID, amount)
	if not player or not itemID then return false, "Invalid arguments" end
	amount = amount or 1
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.Items = inventory.Items or {}
	inventory.Items[itemID] = (inventory.Items[itemID] or 0) + amount
	savePlayerInventory(player, inventory, fullData)
	return true, "Item added"
end

function InventoryManager.RemoveItem(player, itemID, amount)
	if not player or not itemID then return false, "Invalid arguments" end
	amount = amount or 1
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory or not inventory.Items then return false, "No items" end
	
	if not inventory.Items[itemID] or inventory.Items[itemID] < amount then
		return false, "Insufficient items"
	end
	
	inventory.Items[itemID] -= amount
	if inventory.Items[itemID] <= 0 then
		inventory.Items[itemID] = nil
	end
	savePlayerInventory(player, inventory, fullData)
	return true, "Item removed"
end

function InventoryManager.HasItem(player, itemID, amount)
	amount = amount or 1
	local items = InventoryManager.GetItems(player)
	return (items[itemID] or 0) >= amount
end

-- =============================================================================
-- FULL INVENTORY API
-- =============================================================================

function InventoryManager.GetFullInventory(player)
	local inventory = getPlayerInventory(player)
	if not inventory then
		return {
			Coins = 0,
			Weapons = {},
			Skins = { Owned = {}, Equipped = {} },
			Boosters = {},
			Items = {},
			MeleeWeapons = InventoryManager.GetAllMeleeWeapons(),
			EquippedMelee = "Crowbar"
		}
	end
	
	-- Inject melee weapons (always owned by all players)
	inventory.MeleeWeapons = InventoryManager.GetAllMeleeWeapons()
	inventory.EquippedMelee = inventory.EquippedMelee or "Crowbar"
	
	return inventory
end

-- =============================================================================
-- MELEE WEAPONS API
-- =============================================================================

-- All players own all melee weapons by default (no unlock required)
local ALL_MELEE_WEAPONS = {"Crowbar", "Bat", "Machete"}
local DEFAULT_MELEE = "Crowbar"

function InventoryManager.GetAllMeleeWeapons()
	return ALL_MELEE_WEAPONS
end

function InventoryManager.GetEquippedMelee(player)
	local inventory = getPlayerInventory(player)
	if not inventory then return DEFAULT_MELEE end
	return inventory.EquippedMelee or DEFAULT_MELEE
end

function InventoryManager.EquipMelee(player, meleeName)
	if not player or not meleeName then return false, "Invalid arguments" end
	if not table.find(ALL_MELEE_WEAPONS, meleeName) then
		return false, "Invalid melee weapon"
	end
	
	local inventory, fullData = getPlayerInventory(player)
	if not inventory then return false, "Failed to get inventory" end
	
	inventory.EquippedMelee = meleeName
	savePlayerInventory(player, inventory, fullData)
	return true, "Melee equipped successfully"
end

return InventoryManager
