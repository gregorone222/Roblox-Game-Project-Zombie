-- PerkConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/PerkConfig.lua
-- Script Place: ACT 1: Village

local PerkConfig = {}

PerkConfig.Perks = {
	HPPlus = {
		DisplayName = "Thick Skin",
		Description = "Tough survivor skin increases Max Health by 30%.",
		Icon = "❤️"
	},
	StaminaPlus = {
		DisplayName = "Runner's High",
		Description = "Adrenaline boost increases Max Stamina by 30%.",
		Icon = "🏃"
	},
	ReloadPlus = {
		DisplayName = "Quick Hands",
		Description = "Trained hands Reload 30% faster.",
		Icon = "✋"
	},
	RevivePlus = {
		DisplayName = "Helping Hand",
		Description = "Caring nature speeds up Ally Revive by 50%.",
		Icon = "🤝"
	},
	RateBoost = {
		DisplayName = "Rapid Fire",
		Description = "Quick trigger boosts Fire Rate by 30%.",
		Icon = "🔥"
	},
	Medic = {
		DisplayName = "Revival Expert",
		Description = "Medical expertise grants 30% HP upon revive.",
		Icon = "💚"
	},
}

return PerkConfig