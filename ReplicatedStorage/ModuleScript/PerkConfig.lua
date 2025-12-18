-- PerkConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/PerkConfig.lua
-- Script Place: ACT 1: Village

local PerkConfig = {}

PerkConfig.Perks = {
	HPPlus = {
		Description = "Increases maximum health 30%",
		Icon = "??"
	},
	StaminaPlus = {
		Description = "Increases maximum stamina 30%",
		Icon = "?"
	},
	ReloadPlus = {
		Description = "Reload time 30% faster",
		Icon = "??"
	},
	RevivePlus = {
		Description = "Revive time 50% faster",
		Icon = "??"
	},
	RateBoost = {
		Description = "Fire rate 30% faster",
		Icon = "??"
	},
	Medic = {
		Description = "Saat menghidupkan kembali teman, teman tersebut akan hidup dengan 30% HP (naik dari 10%).",
		Icon = "?"
	},
	ExplosiveRounds = {
		Description = "Setiap tembakan memiliki peluang 10% untuk menghasilkan ledakan kecil saat mengenai musuh, memberikan splash damage ke zombie di sekitarnya.",
		Icon = "??"
	}
}

return PerkConfig