# 🎛️ Workflow: Live Config Tuner (Balancing)

Fitur ini memungkinkan Anda mengubah statistik game (seperti HP Zombie, Speed, Damage) secara **Real-Time** saat Play Test, tanpa perlu Stop/Start game.

## 📁 Struktur File
1.  **Config Source (JSON):** `LocalAnalytics/LiveConfig.json`
    *   File ini berisi salinan data statistik game.
    *   Anda mengedit angka di sini.
2.  **Server (Node.js):** `LocalAnalytics/server.js`
    *   Menyediakan endpoint `GET /config`.
3.  **Client (Roblox):** `ReplicatedStorage/ModuleScript/LiveConfig.lua`
    *   Mengunduh data JSON setiap 2 detik.
4.  **Consumer (Game Logic):** `ServerScriptService/ModuleScript/ZombieModule.lua`
    *   Mengecek apakah ada data dari LiveConfig. Jika ada, data itu yang dipakai.

## 🚀 Cara Menggunakan

### 1. Pastikan Server Nyala
Sama seperti Analytics, jalankan `node server.js` di terminal.

### 2. Play Test
Jalankan game di Roblox Studio. Spawn zombie.

### 3. Tuning (Balancing)
Misalkan Zombie terlalu lemah:
1.  `Alt-Tab` ke VS Code.
2.  Buka `LocalAnalytics/LiveConfig.json`.
3.  Cari `BaseZombie` atau `Tank`.
4.  Ubah `MaxHealth` dari `100` menjadi `5000`.
5.  Save (`Ctrl+S`).

### 4. Hasil Instan
Tunggu 2 detik. Zombie yang **baru muncul** (spawn berikutnya) akan langsung memiliki darah 5000.

> **Catatan:** Zombie yang *sudah ada* di map tidak akan berubah (karena stats mereka diset saat spawn). Hanya zombie baru yang terpengaruh.

---

## 🔒 Catatan Keamanan penting
Fitur Live Config ini **HANYA AKTIF DI ROBLOX STUDIO**.
*   Saya sudah memasang pengaman `RunService:IsStudio()`.
*   Jika Anda mem-publish game ini ke Roblox Public Server, fitur ini akan **otomatis mati** (disabled).
*   Jadi game Anda **AMAN** dari hacker, karena di server publik script ini tidak akan pernah mencoba menghubungi `localhost`.
