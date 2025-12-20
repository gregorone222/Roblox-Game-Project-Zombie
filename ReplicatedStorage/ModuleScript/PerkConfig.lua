-- PerkConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/PerkConfig.lua
-- Script Place: ACT 1: Village

local PerkConfig = {}

PerkConfig.Perks = {
	HPPlus = {
		DisplayName = "Iron Will",
		Description = "Strong will increases Max Health by 30%.",
		Icon = "❤️"
	},
	StaminaPlus = {
		DisplayName = "Second Wind",
		Description = "Second wind increases Max Stamina by 30%.",
		Icon = "🏃"
	},
	ReloadPlus = {
		DisplayName = "Dexterity",
		Description = "Trained hands Reload 30% faster.",
		Icon = "✋"
	},
	RevivePlus = {
		DisplayName = "Humanity",
		Description = "Sense of humanity speeds up Ally Revive by 50%.",
		Icon = "🤝"
	},
	RateBoost = {
		DisplayName = "Adrenaline",
		Description = "Adrenaline boosts Fire Rate by 30%.",
		Icon = "🔥"
	},
	Medic = {
		DisplayName = "Field Medic",
		Description = "First aid grants 30% HP upon revive.",
		Icon = "💚"
	},
}

return PerkConfig