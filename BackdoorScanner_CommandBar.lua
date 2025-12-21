--[[
    🛡️ ROBLOX STUDIO BACKDOOR SCANNER 🛡️
    
    CARA PAKAI:
    1. Copy seluruh kode ini.
    2. Di Roblox Studio, buka tab "View" -> nyalakan "Command Bar".
    3. Paste kode ini di Command Bar (bawah layar).
    4. Tekan Enter.
    5. Lihat hasil scan di window Output.
]]

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

print(" ")
print("🕵️‍♂️ MEMULAI SCAN KEAMANAN (COMMAND BAR MODE)...")
print("--------------------------------------------------")

local suspiciousPatterns = {
    {name = "Backdoor (require Asset ID)", pattern = "require%s*%(%s*%d+%s*%)"},
    {name = "Environment (getfenv)", pattern = "getfenv"},
    {name = "Environment (setfenv)", pattern = "setfenv"},
    {name = "RCE (loadstring)", pattern = "loadstring"},
    {name = "Http (Get/PostAsync)", pattern = "HttpService"}, -- Bisa jadi false positive
}

local whitelist = {
    "LiveConfig",     -- Modul kita sendiri
    "LocalAnalytics", -- Modul kita sendiri
    "Chat",           -- Default Roblox
}

local foundCount = 0

-- Fungsi rekursif untuk scan
local function scanObj(obj)
    -- Cek jika ini adalah script (Script, LocalScript, ModuleScript)
    if obj:IsA("LuaSourceContainer") then
        local src = obj.Source
        local isSuspicious = false
        
        -- Cek whitelist
        for _, safeName in ipairs(whitelist) do
            if string.find(obj.Name, safeName) then
                return
            end
        end

        for _, check in ipairs(suspiciousPatterns) do
            if string.match(src, check.pattern) then
                -- Abaikan komentar (sederhana)
                if not string.match(src, "%-%-"..check.pattern) then
                    warn("⚠️ POTENSI BAHAYA: " .. check.name)
                    print("   📂 Lokasi: " .. obj:GetFullName())
                    print("   📝 Snippet: " .. string.sub(string.match(src, check.pattern) or "???", 1, 50))
                    print("--------------------------------------------------")
                    foundCount = foundCount + 1
                    isSuspicious = true
                end
            end
        end
    end
end

local allObjects = game:GetDescendants()
for _, obj in ipairs(allObjects) do
    pcall(function()
        scanObj(obj)
    end)
end

print("✅ SCAN SELESAI.")
if foundCount == 0 then
    print("✨ TIDAK DITEMUKAN SCRIPT MENCURIGAKAN.")
else
    warn("🚨 DITEMUKAN " .. foundCount .. " SCRIPT YANG PERLU DICEK!")
end
print(" ")
