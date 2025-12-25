# 🎛️ Live Config Tuner

Mengubah statistik game secara **Real-Time** saat Play Test.

## 📁 Struktur File
| File | Fungsi |
|:-----|:-------|
| `LocalAnalytics/LiveConfig.json` | Config source (edit angka di sini) |
| `LocalAnalytics/server.js` | Endpoint `GET /config` |
| `ReplicatedStorage/ModuleScript/LiveConfig.lua` | Download JSON tiap 2 detik |
| `ZombieModule.lua` | Consumer (cek LiveConfig data) |

---

## 🚀 Cara Menggunakan

### 1. Pastikan Server Nyala
```bash
cd LocalAnalytics && node server.js
```

### 2. Play Test
Jalankan game di Roblox Studio, spawn zombie

### 3. Tuning
1. Alt-Tab ke VS Code
2. Buka `LocalAnalytics/LiveConfig.json`
3. Ubah value (misal: `MaxHealth: 100` → `5000`)
4. Save (Ctrl+S)

### 4. Hasil Instan
Tunggu 2 detik - zombie **baru** akan spawn dengan stats baru

> **Note:** Zombie yang sudah ada tidak berubah (stats diset saat spawn)

---

## 🔒 Keamanan
- **HANYA aktif di Studio** (cek `RunService:IsStudio()`)
- Game publik **tidak terpengaruh** (aman dari hacker)
