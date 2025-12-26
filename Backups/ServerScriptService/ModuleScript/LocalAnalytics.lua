--[[
    LocalAnalytics Module
    Path: ServerScriptService/ModuleScript/LocalAnalytics.lua
    
    This module captures ALL console output (including Syntax Errors) and sends errors to the local Node.js server.
]]

local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

local LocalAnalytics = {}
local SESSION_LOG_NAME = "gameplay_zombie"
local SERVER_URL = "http://localhost:3000/log-error" 

function LocalAnalytics.Init()
    print("🔋 Local Analytics: Connecting to " .. SERVER_URL)
    
    -- Capture ALL Output messages (Prints, Warnings, Errors, System Messages)
    LogService.MessageOut:Connect(function(message, messageType)
        -- We only care about ERRORS (Runtime & Syntax)
        if messageType == Enum.MessageType.MessageError then
            
            -- Prevent infinite loop if the error is from our own logger
            if string.find(message, "LocalAnalytics") then return end
            
            warn("🚨 ERROR CAUGHT via LogService! Sending to Local Server...")
            
            local payload = {
                scriptName = "Console Log", -- LogService often doesn't give source script easily for syntax errors
                message = message,
                stackTrace = debug.traceback(), -- Traceback might be empty for syntax errors
                timestamp = os.time(),
                logName = SESSION_LOG_NAME
            }
            
            -- Send HTTP Request
            task.spawn(function()
                local success, err = pcall(function()
                    HttpService:PostAsync(
                        SERVER_URL,
                        HttpService:JSONEncode(payload),
                        Enum.HttpContentType.ApplicationJson,
                        false
                    )
                end)
                
                if success then
                    print("✅ Error logged to local file!")
                else
                    warn("❌ Failed to log error: " .. tostring(err))
                end
            end)
        end
    end)
    
    print("✅ Local Analytics Listening (LogService Mode)...")
end

return LocalAnalytics
