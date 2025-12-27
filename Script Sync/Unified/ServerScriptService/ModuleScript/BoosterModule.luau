-- BoosterModule.lua (ModuleScript)
-- Path: ServerScriptService/ModuleScript/BoosterModule.lua
-- Script Place: Lobby & ACT 1: Village
-- DEPRECATED: This module redirects to FieldKitModule for backward compatibility

-- Redirect all calls to FieldKitModule
local FieldKitModule = require(script.Parent:WaitForChild("FieldKitModule"))

-- Return FieldKitModule directly for full backward compatibility
-- All functions like AddBooster, ActivateBooster, UseActiveBooster are aliased in FieldKitModule
return FieldKitModule

