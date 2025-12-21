# 🐛 Sistem Debug Lokal (Automated Console to File)

Panduan ini menyediakan solusi *copy-paste* untuk menerapkan **Sistem Pencatatan Error Lokal** untuk proyek Roblox.
Sistem ini secara otomatis menangkap **semua jenis error** (Runtime, Syntax, Engine) dari Roblox Studio dan menyimpannya ke file teks di komputer Anda, memudahkan analisis eksternal (misalnya oleh agen AI).

## 📁 Struktur File

| Komponen | Lokasi | Deskripsi |
|----------|--------|-----------|
| **Server Node.js** | `LocalAnalytics/server.js` | Berjalan di terminal, menerima & menyimpan log |
| **Client Module** | `ServerScriptService/ModuleScript/LocalAnalytics.lua` | Menangkap error via LogService |
| **Loader Script** | `ServerScriptService/Script/AnalyticsLoader.lua` | Menyalakan sistem di awal server |

---

## 1. Persiapan Server Node.js

Buat folder `LocalAnalytics` di root proyek. Di dalamnya, buat `server.js`:

```javascript
const http = require('http');
const fs = require('fs');
const path = require('path');
const port = 3000;

const getBody = (req) => {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => body += chunk.toString());
        req.on('end', () => {
            try { resolve(JSON.parse(body)); } 
            catch (e) { resolve({}); }
        });
        req.on('error', reject);
    });
};

const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir);

const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

    if (req.method === 'POST' && req.url === '/log-error') {
        const body = await getBody(req);
        const { scriptName, message, stackTrace, logName } = body;
        
        // Gunakan logName jika ada, jika tidak gunakan tanggal
        let fileName = "";
        if (logName) {
            // Bersihkan nama file agar aman (hanya huruf, angka, _, -)
            const safeName = logName.replace(/[^a-zA-Z0-9_\-]/g, '');
            fileName = `${safeName}.txt`;
        } else {
            const date = new Date().toISOString().split('T')[0];
            fileName = `error_log_${date}.txt`;
        }

        const logFile = path.join(logsDir, fileName);
        
        const logEntry = `[${new Date().toISOString()}] [${scriptName || 'Unknown'}] ${message}\nStack: ${stackTrace}\n----------------------------------\n`;
        
        fs.appendFile(logFile, logEntry, (err) => {
            if (err) {
                console.error("Gagal menulis log", err);
                res.writeHead(500);
                res.end("Error writing log");
                return;
            }
            console.log(`🚨 Error Masuk [${fileName}]: ${message}`);
            res.writeHead(200);
            res.end("Logged");
        });
        return;
    }

    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200); res.end('Roblox Local Analytics Server Running'); return;
    }
    res.writeHead(404); res.end('Not Found');
});

server.listen(port, () => {
    console.log(`🚀 Analytics Server listening on http://localhost:${port}`);
    console.log(`   Logs: ${logsDir}`);
});
```

---

## 2. Persiapan Roblox Studio

### `LocalAnalytics.lua` (ModuleScript di ServerScriptService)

```lua
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

local LocalAnalytics = {}
local SERVER_URL = "http://localhost:3000/log-error" 

-- KONFIGURASI NAMA LOG DI SINI
-- Ubah ini menjadi "Log_A", "Gameplay_Log", dll sesuai kebutuhan agen Anda
local SESSION_LOG_NAME = "Log_A"

function LocalAnalytics.Init()
    print("🔋 Local Analytics: Terhubung ke " .. SERVER_URL .. " (File: " .. SESSION_LOG_NAME .. ".txt)")
    
    LogService.MessageOut:Connect(function(message, messageType)
        -- Hanya tangkap ERROR (Runtime & Syntax)
        if messageType == Enum.MessageType.MessageError then
            if string.find(message, "LocalAnalytics") then return end
            
            warn("🚨 ERROR TERTANGKAP! Mengirim ke " .. SESSION_LOG_NAME .. "...")
            
            local payload = {
                scriptName = "Console Log",
                message = message,
                stackTrace = debug.traceback(),
                timestamp = os.time(),
                logName = SESSION_LOG_NAME -- Kirim nama file yang diinginkan
            }
            
            task.spawn(function()
                pcall(function()
                    HttpService:PostAsync(SERVER_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson, false)
                end)
            end)
        end
    end)
    
    print("✅ Local Analytics Mendengarkan...")
end

return LocalAnalytics
```

### `AnalyticsLoader.server.lua` (Script di ServerScriptService)

```lua
local LocalAnalyticsModule = game:GetService("ServerScriptService"):WaitForChild("ModuleScript"):WaitForChild("LocalAnalytics")
local LocalAnalytics = require(LocalAnalyticsModule)
LocalAnalytics.Init()
print("🛡️ Analytics Loader Aktif")
```

---

## 🚀 Cara Menggunakan

1. **Nyalakan Server:** `cd LocalAnalytics && node server.js`
2. **Aktifkan HTTP:** Game Settings → Security → ✅ Allow HTTP Requests
3. **Play Test** di Roblox Studio
4. **Monitoring:** Error muncul di terminal & tersimpan di `LocalAnalytics/logs/error_log_YYYY-MM-DD.txt`
5. **Laporkan ke Agen:** _"Cek log error terakhir dan perbaiki scriptnya."_

---

## 🛡️ Batasan & Keamanan

| Kondisi | Hasil |
|---------|-------|
| `print("Halo")` | ❌ Tidak dikirim |
| `warn("Awas")` | ❌ Tidak dikirim |
| `error("Rusak!")` | ✅ DIKIRIM |

**Rate Limit:** Roblox HttpService = 500 req/menit. Jika error membludak, pengiriman stall ~30 detik. Tidak ada risiko banned.

## ⚠️ Troubleshooting

- **Error tidak muncul?** Pastikan `node server.js` jalan
- **Syntax Error tidak tertangkap?** Pastikan `AnalyticsLoader.server.lua` ada di ServerScriptService
