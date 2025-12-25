-- BoosterConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterConfig.lua
-- Script Place: Lobby
-- NOTE: Boosters are now REWARD-ONLY (Daily Reward / Gacha), NOT purchasable

local BoosterConfig = {
	SelfRevive = {
		Name = "Second Chance",
		Icon = "💚",
		Description = "Automatically revive yourself once when knocked down.",
		Rarity = "Rare",
		Source = "Daily Day 7 / Gacha"
	},
	StarterPoints = {
		Name = "Starting Funds",
		Icon = "💰",
		Description = "Start the game with 1,500 bonus BP.",
		Rarity = "Common",
		Source = "Daily Day 3 / Gacha"
	},
	CouponDiscount = {
		Name = "Bargain Pass",
		Icon = "🏷️",
		Description = "Get 50% off your next in-game shop purchase.",
		Rarity = "Common",
		Source = "Daily Day 5 / Gacha"
	},
	StartingShield = {
		Name = "Body Armor",
		Icon = "🛡️",
		Description = "Start the game with 50% bonus shield health.",
		Rarity = "Rare",
		Source = "Gacha"
	},
	LegionsLegacy = {
		Name = "Mystery Loadout",
		Icon = "🎁",
		Description = "Replace your starter weapon with a random weapon from the full arsenal.",
		Rarity = "Epic",
		Source = "Gacha"
	}
}

return BoosterConfig

