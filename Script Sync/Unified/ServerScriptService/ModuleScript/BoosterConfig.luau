-- PlaceId Guard: Only run in Lobby
local LOBBY_PLACE_ID = 101319079083908
if game.PlaceId ~= LOBBY_PLACE_ID then return {} end

-- BoosterConfig.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterConfig.lua
-- Script Place: Lobby
-- DEPRECATED: This module redirects to FieldKitConfig for backward compatibility

-- Redirect to FieldKitConfig
local FieldKitConfig = require(script.Parent:WaitForChild("FieldKitConfig"))
return FieldKitConfig

