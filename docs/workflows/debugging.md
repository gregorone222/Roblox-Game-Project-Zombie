# 🐛 Debugging Workflow

Sistem Debug Lokal (Automated Console to File).

## 📁 Struktur File

| Komponen | Lokasi |
|:---------|:-------|
| Server Node.js | `LocalAnalytics/server.js` |
| Client Module | `ServerScriptService/ModuleScript/LocalAnalytics.lua` |
| Loader Script | `ServerScriptService/Script/AnalyticsLoader.lua` |

---

## 🚀 Quick Start

1. **Nyalakan Server:** `cd LocalAnalytics && node server.js`
2. **Aktifkan HTTP:** Game Settings → Security → ✅ Allow HTTP Requests
3. **Play Test** di Roblox Studio
4. **Monitoring:** Logs di `LocalAnalytics/logs/gameplay_zombie.txt`

---

## Server Setup (`LocalAnalytics/server.js`)

```javascript
const http = require('http');
const fs = require('fs');
const path = require('path');
const port = 3000;

const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir);

http.createServer(async (req, res) => {
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    if (req.method === 'POST' && req.url === '/log-error') {
        // Parse body and write to log file
        // Full code in LocalAnalytics/server.js
    }
}).listen(port);
```

---

## Roblox Module (`LocalAnalytics.lua`)

```lua
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")

function LocalAnalytics.Init()
    LogService.MessageOut:Connect(function(message, messageType)
        if messageType == Enum.MessageType.MessageError then
            -- Send to local server
            HttpService:PostAsync(SERVER_URL, payload)
        end
    end)
end
```

---

## 🛡️ What Gets Logged

| Type | Logged? |
|:-----|:--------|
| `print("...")` | ❌ No |
| `warn("...")` | ❌ No |
| `error("...")` | ✅ Yes |
| Runtime Error | ✅ Yes |
| Syntax Error | ✅ Yes |

---

## ⚠️ Troubleshooting

| Issue | Solution |
|:------|:---------|
| Error tidak muncul | Pastikan `node server.js` jalan |
| Syntax error tidak tertangkap | Pastikan `AnalyticsLoader.server.lua` ada |
| Cek status | `curl http://localhost:3000/` |
