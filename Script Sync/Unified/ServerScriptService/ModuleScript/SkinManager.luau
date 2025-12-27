-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- SkinManager.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/SkinManager.lua
-- Script Place: Lobby, ACT 1: Village

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Memuat modul yang diperlukan
local DataStoreManager = require(ServerScriptService.ModuleScript:WaitForChild("DataStoreManager"))
local InventoryManager = require(ServerScriptService.ModuleScript:WaitForChild("InventoryManager"))
local CoinsManager = require(ServerScriptService.ModuleScript:WaitForChild("CoinsModule"))
local WeaponModule = require(ReplicatedStorage.ModuleScript:WaitForChild("WeaponModule"))

local SkinManager = {}

-- Fungsi untuk mendapatkan data inventaris pemain
function SkinManager.GetInventoryData(player)
	local playerData = DataStoreManager:GetOrWaitForPlayerData(player)
	if not playerData or not playerData.data then
		warn("[SkinManager] Gagal mendapatkan data inventaris untuk pemain: " .. player.Name)
		return nil
	end
	return playerData.data.inventory
end

-- Fungsi untuk mendapatkan skin yang sedang dipakai pemain untuk senjata tertentu
function SkinManager.GetEquippedSkin(player, weaponName)
	if not player or not weaponName then return nil end
	return InventoryManager.GetEquippedSkin(player, weaponName)
end

-- Fungsi untuk mengganti skin yang dipakai pemain
function SkinManager.EquipSkin(player, weaponName, skinName)
	if not player or not weaponName or not skinName then
		return {Success = false, Message = "Argumen tidak valid."}
	end

	local success, message = InventoryManager.EquipSkin(player, weaponName, skinName)
	if success then
		print(player.Name .. " berhasil menggunakan skin '" .. skinName .. "' untuk senjata '" .. weaponName .. "'.")
		return {Success = true, Message = "Skin berhasil digunakan!"}
	else
		return {Success = false, Message = message or "Gagal menggunakan skin."}
	end
end

-- Fungsi untuk memberikan skin acak (logika tidak berubah)
function SkinManager.GiveRandomSkin(player)
	if not player then return {Success = false, Message = "Player tidak valid."} end

	local ownedSkins = InventoryManager.GetOwnedSkins(player)
	local allWeapons = WeaponModule.Weapons
	local allPossibleSkins = {}
	for weaponName, weaponData in pairs(allWeapons) do
		for skinName, skinData in pairs(weaponData.Skins) do
			if skinData.Rarity ~= "Default" then
				table.insert(allPossibleSkins, {Weapon = weaponName, Skin = skinName})
			end
		end
	end

	local unownedSkins = {}
	for _, possibleSkin in ipairs(allPossibleSkins) do
		if not InventoryManager.OwnsSkin(player, possibleSkin.Weapon, possibleSkin.Skin) then
			table.insert(unownedSkins, possibleSkin)
		end
	end

	if #unownedSkins == 0 then
		CoinsManager.AddCoins(player, 1000)
		return {Success = true, Message = "Semua skin dimiliki, memberikan 1000 koin.", CompensatoryCoins = 1000}
	end

	local chosenReward = unownedSkins[math.random(#unownedSkins)]
	local success = InventoryManager.AddSkin(player, chosenReward.Weapon, chosenReward.Skin)
	if success then
		return {Success = true, Weapon = chosenReward.Weapon, Skin = chosenReward.Skin}
	else
		return {Success = false, Message = "Gagal menambahkan skin."}
	end
end

return SkinManager
