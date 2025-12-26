-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- APShopConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/APShopConfig.lua
-- Script Place: Lobby

local APShopConfig = {
	Items = {
		SKILL_RESET_TOKEN = {
			ID = "SKILL_RESET_TOKEN",
			Name = "Skill Reset Token",
			Description = "A token that allows you to reset all of your skill points for free.",
			APCost = 7500,
			Type = "Consumable"
		},
		EXCLUSIVE_TITLE_COLLECTOR = {
			ID = "EXCLUSIVE_TITLE_COLLECTOR",
			Name = "Title: The Collector",
			Description = "Unlocks the exclusive title 'The Collector'.",
			APCost = 10000,
			Type = "Permanent",
			Title = "The Collector"
		}
	}
}

return APShopConfig