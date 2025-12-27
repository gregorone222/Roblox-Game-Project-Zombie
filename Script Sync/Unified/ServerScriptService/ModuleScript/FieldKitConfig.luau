-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- FieldKitConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/FieldKitConfig.lua
-- Script Place: Lobby
-- NOTE: Field Kits are now REWARD-ONLY (Daily Reward / Gacha), NOT purchasable

local FieldKitConfig = {
	-- Common (40% drop rate)
	StarterPoints = {
		Name = "Starting Funds",
		Icon = "rbxassetid://115097892301473",
		Description = "Start the game with 1,500 bonus BP.",
		Rarity = "Common",
		Color = Color3.fromRGB(180, 180, 180), -- Abu-abu
		Source = "Daily Day 3 / Gacha"
	},
	
	-- Uncommon (30% drop rate)
	AmmoCache = {
		Name = "Ammo Stockpile",
		Icon = "rbxassetid://133597625207661",
		Description = "Start the game with 50% bonus max ammo.",
		Rarity = "Uncommon",
		Color = Color3.fromRGB(0, 200, 0), -- Hijau
		Source = "Gacha"
	},
	
	-- Rare (20% drop rate)
	StartingShield = {
		Name = "Body Armor",
		Icon = "rbxassetid://118302588106310",
		Description = "Start the game with 50% bonus shield health.",
		Rarity = "Rare",
		Color = Color3.fromRGB(0, 150, 255), -- Biru
		Source = "Gacha"
	},
	
	-- Epic (8% drop rate)
	LegionsLegacy = {
		Name = "Mystery Loadout",
		Icon = "rbxassetid://117164757148539",
		Description = "Replace your starter weapon with a random weapon from the full arsenal.",
		Rarity = "Epic",
		Color = Color3.fromRGB(150, 0, 200), -- Ungu
		Source = "Gacha"
	},
	
	-- Legendary (2% drop rate)
	CommanderBuff = {
		Name = "Commander's Authority",
		Icon = "rbxassetid://78698774904955",
		Description = "All allies gain +10% damage for the entire game.",
		Rarity = "Legendary",
		Color = Color3.fromRGB(255, 200, 0), -- Emas
		Source = "Gacha"
	}
}

return FieldKitConfig

