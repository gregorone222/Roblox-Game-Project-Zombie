--[[
    AnalyticsLoader
    Path: ServerScriptService/Script/AnalyticsLoader.server.lua
    
    This script automatically initializes the LocalAnalytics module when the server starts.
    It ensures the error logger is active BEFORE other scripts run or crash.
]]

local LocalAnalyticsModule = game:GetService("ServerScriptService"):WaitForChild("ModuleScript"):WaitForChild("LocalAnalytics")
local LocalAnalytics = require(LocalAnalyticsModule)

-- Start listening immediately
LocalAnalytics.Init()

print("🛡️ Analytics Loader Active: Monitoring for errors...")
