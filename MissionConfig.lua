-- MissionConfig.lua (ModuleScript)
-- Path: ReplicatedStorage/ModuleScript/MissionConfig.lua
-- Script Place: Lobby, ACT 1: Village

local MissionConfig = {}

--[[
    Mission Structure:
    {
        ID = string (unique),
        Description = string (description to display in UI),
        Type = string (mission type, e.g., "KILL_ZOMBIES", "COMPLETE_WAVES"),
        Target = number (target amount to achieve),
        Reward = {
            Type = "MissionPoints",
            Value = number
        }
    }
]]

-- ==================================================
-- MISSION SETTINGS
-- ==================================================
MissionConfig.DailyMissionCount = 3
MissionConfig.WeeklyMissionCount = 3

-- ==================================================
-- DAILY MISSIONS LIST
-- ==================================================
MissionConfig.DailyMissions = {
	{ ID = "D_COMPLETE_WAVES_EASY", Description = "Complete 3 Waves", Type = "WAVE_COMPLETE", Target = 3, Reward = { Type = "MissionPoints", Value = 100 } },
	{ ID = "D_KILL_ZOMBIES_EASY", Description = "Defeat 75 Zombies", Type = "ZOMBIE_KILL", Target = 75, Reward = { Type = "MissionPoints", Value = 150 } },
	{ ID = "D_GET_HEADSHOTS_EASY", Description = "Get 25 Headshots", Type = "HEADSHOT", Target = 25, Reward = { Type = "MissionPoints", Value = 200 } },
	{ ID = "D_KILL_ZOMBIES_MEDIUM", Description = "Defeat 150 Zombies", Type = "ZOMBIE_KILL", Target = 150, Reward = { Type = "MissionPoints", Value = 250 } },
	{ ID = "D_USE_BOOSTERS", Description = "Use 2 Boosters", Type = "USE_BOOSTER", Target = 2, Reward = { Type = "MissionPoints", Value = 300 } },
	{ ID = "D_KILL_SMG", Description = "Defeat 100 Zombies with SMG", Type = "ZOMBIE_KILL", WeaponType = "SMG", Target = 100, Reward = { Type = "MissionPoints", Value = 350 } },
	{ ID = "D_GET_HEADSHOTS_HARD", Description = "Get 50 Headshots", Type = "HEADSHOT", Target = 50, Reward = { Type = "MissionPoints", Value = 400 } },
	{ ID = "D_REVIVE_TEAMMATES", Description = "Revive 3 Teammates", Type = "REVIVE_PLAYER", Target = 3, Reward = { Type = "MissionPoints", Value = 400 } },
	{ ID = "D_COMPLETE_GAME_EASY", Description = "Complete 1 Game (min. 10 waves)", Type = "GAME_COMPLETE", Target = 1, Reward = { Type = "MissionPoints", Value = 500 } },
	{ ID = "D_KILL_SPECIAL_ZOMBIES", Description = "Defeat 10 Special Zombies (Tank/Shooter)", Type = "KILL_SPECIAL", Target = 10, Reward = { Type = "MissionPoints", Value = 500 } },
}

-- ==================================================
-- WEEKLY MISSIONS LIST
-- ==================================================
MissionConfig.WeeklyMissions = {
	{ ID = "W_COMPLETE_WAVES_MEDIUM", Description = "Complete 25 Waves", Type = "WAVE_COMPLETE", Target = 25, Reward = { Type = "MissionPoints", Value = 750 } },
	{ ID = "W_KILL_ZOMBIES_HARD", Description = "Defeat 1000 Zombies", Type = "ZOMBIE_KILL", Target = 1000, Reward = { Type = "MissionPoints", Value = 1000 } },
	{ ID = "W_GET_HEADSHOTS_MEDIUM", Description = "Get 250 Headshots", Type = "HEADSHOT", Target = 250, Reward = { Type = "MissionPoints", Value = 1250 } },
	{ ID = "W_KILL_BOSS", Description = "Defeat 3 Bosses", Type = "BOSS_KILL", Target = 3, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_COMPLETE_GAME_HARD", Description = "Complete 1 Game on Hard difficulty or higher", Type = "GAME_COMPLETE_HARD", Target = 1, Reward = { Type = "MissionPoints", Value = 2000 } },
	{ ID = "W_KILL_LMG", Description = "Defeat 500 Zombies with LMG", Type = "ZOMBIE_KILL", WeaponType = "LMG", Target = 500, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_NO_KNOCK_WAVES", Description = "Complete 10 consecutive waves without being knocked", Type = "NO_KNOCK_STREAK", Target = 10, Reward = { Type = "MissionPoints", Value = 1750 } },
	{ ID = "W_SPEND_COINS", Description = "Spend 50,000 Coins", Type = "SPEND_COINS", Target = 50000, Reward = { Type = "MissionPoints", Value = 1000 } },
	{ ID = "W_EARN_AP", Description = "Earn 1000 Achievement Points", Type = "EARN_AP", Target = 1000, Reward = { Type = "MissionPoints", Value = 1500 } },
	{ ID = "W_DEAL_DAMAGE", Description = "Deal 5,000,000 total damage", Type = "DEAL_DAMAGE", Target = 5000000, Reward = { Type = "MissionPoints", Value = 2000 } },
}

return MissionConfig
