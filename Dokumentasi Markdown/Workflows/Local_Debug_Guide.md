# 🐛 Sistem Debug Lokal (Console ke File)

Panduan ini menyediakan solusi *copy-paste* untuk menerapkan **Sistem Pencatatan Error Lokal** untuk proyek Roblox apa pun.
Sistem ini secara otomatis menangkap error dari Roblox Studio (termasuk Syntax Error) dan menyimpannya ke file teks di komputer Anda, memudahkan analisis eksternal (misalnya oleh agen AI).

## 🛠️ Komponen

1.  **Server Node.js:** Berjalan di komputer Anda untuk menerima data.
2.  **Modul Roblox (`LocalAnalytics`):** Menangkap output `LogService`.
3.  **Loader Roblox (`AnalyticsLoader`):** Menjalankan modul saat server dimulai.

---

## 1. Persiapan Server Node.js

Buat folder bernama `LocalAnalytics` di root proyek Anda.
Di dalamnya, buat file bernama `server.js`.

### 📄 `server.js` (Tanpa Dependensi)
Script ini menggunakan modul `http` bawaan, jadi **tidak perlu `npm install`**.

```javascript
const http = require('http');
const fs = require('fs');
const path = require('path');
const port = 3000;

// Helper untuk menangani parsing body
const getBody = (req) => {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            try {
                resolve(JSON.parse(body));
            } catch (e) {
                resolve({});
            }
        });
        req.on('error', reject);
    });
};

const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir);
}

const server = http.createServer(async (req, res) => {
    // Header CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.method === 'POST' && req.url === '/log-error') {
        const body = await getBody(req);
        const { scriptName, message, stackTrace } = body;
        const date = new Date().toISOString().split('T')[0];
        const logFile = path.join(logsDir, `error_log_${date}.txt`);
        
        const logEntry = `[${new Date().toISOString()}] [${scriptName || 'Unknown'}] ${message}\nStack: ${stackTrace}\n----------------------------------\n`;
        
        fs.appendFile(logFile, logEntry, (err) => {
            if (err) {
                console.error("Gagal menulis log", err);
                res.writeHead(500);
                res.end("Error writing log");
                return;
            }
            console.log(`🚨 Error Masuk dari Roblox: ${message}`);
            res.writeHead(200);
            res.end("Logged");
        });
        return;
    }

    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200);
        res.end('Roblox Local Analytics Server Running');
        return;
    }

    res.writeHead(404);
    res.end('Not Found');
});

server.listen(port, () => {
    console.log(`🚀 Analytics Server listening on http://localhost:${port}`);
    console.log(`   - Logs akan disimpan di: ${logsDir}`);
});
```

### ▶️ Cara Menjalankan
Buka terminal di folder tersebut dan ketik:
```bash
node server.js
```

---

## 2. Persiapan Roblox Studio

### 📄 `LocalAnalytics.lua`
Buat **ModuleScript** di `ServerScriptService` (atau subfolder seperti `Modules`).

```lua
--[[
    LocalAnalytics Module
    Modul ini menangkap SEMUA output konsol (termasuk Syntax Error) dan mengirim error ke server Node.js lokal.
]]

local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

local LocalAnalytics = {}
local SERVER_URL = "http://localhost:3000/log-error" 

function LocalAnalytics.Init()
    print("🔋 Local Analytics: Terhubung ke " .. SERVER_URL)
    
    -- Tangkap SEMUA pesan Output (Prints, Warnings, Errors, System Messages)
    LogService.MessageOut:Connect(function(message, messageType)
        -- Kita hanya peduli pada ERROR (Runtime & Syntax)
        if messageType == Enum.MessageType.MessageError then
            
            -- Mencegah infinite loop jika error berasal dari logger kita sendiri
            if string.find(message, "LocalAnalytics") then return end
            
            warn("🚨 ERROR TERTANGKAP via LogService! Mengirim ke Server Lokal...")
            
            local payload = {
                scriptName = "Console Log", -- LogService terkadang tidak memberikan script sumber dengan mudah untuk syntax error
                message = message,
                stackTrace = debug.traceback(), -- Traceback mungkin kosong untuk syntax error
                timestamp = os.time()
            }
            
            -- Kirim Request HTTP
            task.spawn(function()
                local success, err = pcall(function()
                    HttpService:PostAsync(
                        SERVER_URL,
                        HttpService:JSONEncode(payload),
                        Enum.HttpContentType.ApplicationJson,
                        false
                    )
                end)
            end)
        end
    end)
    
    print("✅ Local Analytics Mendengarkan (Mode LogService)...")
end

return LocalAnalytics
```

### 📄 `AnalyticsLoader.server.lua`
Buat **Script** (Server Script) di `ServerScriptService`.

```lua
--[[
    AnalyticsLoader
    Script ini secara otomatis menjalankan modul LocalAnalytics saat server dimulai.
]]

-- Sesuaikan path jika Anda menaruh modul di subfolder
local LocalAnalyticsModule = game:GetService("ServerScriptService"):WaitForChild("ModuleScript"):WaitForChild("LocalAnalytics")
local LocalAnalytics = require(LocalAnalyticsModule)

-- Mulai mendengarkan segera
LocalAnalytics.Init()

print("🛡️ Analytics Loader Aktif: Memantau error...")
```

---

## 3. Pengaturan Penting

Sebelum tes, pergi ke **Game Settings** -> **Security** di Roblox Studio dan aktifkan:
*   ✅ **Allow HTTP Requests**

## 4. Pengujian

1.  Nyalakan server Node (`node server.js`).
2.  Play game di Roblox Studio.
3.  Buat error buatan (contoh: `print(workspace.PartYangTidakAda.Name)`).
4.  Cek folder `logs/` di direktori `LocalAnalytics` Anda. Anda harusnya melihat file teks berisi detail error tersebut.
