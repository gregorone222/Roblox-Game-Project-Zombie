# 🐛 Workflow: Automated Debugging (Local Analytics)

Sistem ini memungkinkan **semua jenis error** (Runtime, Syntax, Engine) yang terjadi di Roblox Studio terkirim otomatis ke file log di komputer lokal. Ini memudahkan Antigravity (Agen AI) untuk membaca error dan melakukan perbaikan tanpa perlu copy-paste manual dari Output Console.

## 📁 Struktur File
1.  **Server (Node.js):** `LocalAnalytics/server.js`
    *   Berjalan di terminal VS Code. Menerima laporan dan menyimpannya ke file txt.
2.  **Client Module (Lua):** `ServerScriptService/ModuleScript/LocalAnalytics.lua`
    *   Menggunakan **MessageOut (LogService)** untuk menangkap teks merah di console.
    *   Memfilter log: Hanya mengirim `MessageError`. Print/Warn biasa **tidak** dikirim.
3.  **Loader (Lua):** `ServerScriptService/Script/AnalyticsLoader.server.lua`
    *   Script kecil yang bertugas menyalakan sistem ini di detik ke-0 server start.
    *   Memastikan Syntax Error di script lain tetap tertangkap.

## 🚀 Cara Menggunakan

### 1. Nyalakan Server Pelapor
Setiap kali membuka VS Code untuk coding, jalankan:

```bash
cd LocalAnalytics
node server.js
```

Terminal akan menampilkan:
> 🚀 Analytics Server listening on http://localhost:3000

### 2. Play Test
Mainkan game di Roblox Studio. Jangan lupa nyalakan **Allow HTTP Requests** di Game Settings.

### 3. Monitoring
Jika terjadi error (bahkan Syntax Error sekalipun):
1.  Terminal VS Code akan menampilkan pesan error merah secara **Real-Time**.
2.  File log akan tersimpan di `LocalAnalytics/logs/error_log_YYYY-MM-DD.txt`.

### 4. Laporkan ke Agen
Cukup perintahkan Antigravity:
> "Cek log error terakhir dan perbaiki scriptnya."

## 🛡️ Batasan & Keamanan

### Apakah aman dari Spam?
**Ya.** Sistem ini memiliki filter internal.
*   `print("Halo")` -> **Tidak dikirim.**
*   `warn("Awas")` -> **Tidak dikirim.**
*   `error("Rusak!")` -> **DIKIRIM.**
Ini menghemat kuota HTTP dan menjaga log tetap bersih.

### Bagaimana jika Error "Membludak" (Infinite Loop)?
Roblox `HttpService` memiliki batas **500 request per menit**.
*   Jika error melebihi 500/menit, pengiriman log akan **berhenti sementara (stall)** selama ~30 detik.
*   **Tidak ada risiko Banned.** Akun Roblox aman, hanya pengiriman log yang tertunda. Game tetap berjalan (walau mungkin script game-nya sendiri macet karena error).

## ⚠️ Troubleshooting
*   **Error tidak muncul?** Pastikan `node server.js` jalan di terminal.
*   **Syntax Error tidak tertangkap?** Pastikan file `AnalyticsLoader.server.lua` ada di `ServerScriptService`. Script ini yang menjamin sistem nyala sebelum script lain crash.

---

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

---

# 🤖 Workflow: AI NPC (Ollama Integration)

Fitur ini memungkinkan NPC di dalam game untuk "berbicara" secara cerdas menggunakan AI yang dijalankan di komputer lokal Anda.

## 📁 Struktur Sistem
1.  **AI Brain (Lokal):** Aplikasi **Ollama** menjalankan model `phi3`.
2.  **Server (Node.js):** `LocalAnalytics/server.js` menerima chat dari Roblox -> meneruskan ke Ollama -> mengirim jawaban ke Roblox.
3.  **Client (Roblox):**
    *   `AIClient.lua`: Modul kurir pesan.
    *   `TalkToAI.lua`: NPC Logic (Server) yang mendeteksi chat "bot, ...".
    *   `AIChatDisplay.client.lua`: Menampilkan balasan AI di layar chat pemain (merah).

## 🚀 Cara Menggunakan
1.  Pastikan **Ollama** sudah terinstall (`ollama --version`).
2.  Pastikan server Node.js jalan (`node server.js`).
3.  Play di Roblox Studio.
4.  Ketik di chat: `bot, halo` (Gunakan prefix `bot,`).

## ⚠️ Batasan (Limitations)
1.  **Hanya Studio:** Sama seperti Live Config, fitur ini hanya aktif di Studio.
2.  **Kecepatan:** Tergantung kecepatan Processor/RAM komputer Anda. (Bisa 2-10 detik per balasan).
3.  **Ingatan (Context):** Saya set ke **256 token** (sangat pendek) agar respons cepat. Bot mungkin lupa apa yang Anda katakan 3 kalimat yang lalu.
4.  **Pengetahuan:** Bot tidak tahu posisi pemain, darah, atau ammo, kecuali kita memprogramnya secara khusus untuk mengirim data tersebut (Context Injection).

---

# 📱 Workflow: Phone Companion App (Second Screen)

Fitur ini mengubah Handphone Anda menjadi "Remote Control" untuk game di Roblox Studio.

## 📁 Struktur Sistem
1.  **Web Dashboard:** `LocalAnalytics/public/index.html` & `config.html`.
2.  **Server:** Menyajikan website di `http://IP-LAPTOP:3000`.
3.  **Controller (Roblox):** `PhoneController.server.lua` (Polling perintah) & `PhoneClient.client.lua` (Eksekusi lokal seperti menembak).

## 🚀 Cara Menggunakan
1.  Pastikan Laptop dan HP terhubung ke **Wi-Fi yang SAMA**.
2.  Cari IP Laptop (buka Terminal, ketik `ipconfig`). Contoh: `192.168.1.104`.
3.  Buka Browser di HP, ketik: `http://192.168.1.104:3000`.
4.  **Fitur:**
    *   **SHOOT:** Memaksa karakter menembak (harus pegang senjata).
    *   **HEAL ME:** Mengisi darah penuh.
    *   **TANK:** Spawn Zombie Tank di depan muka.
    *   **AIRSTRIKE:** Ledakan dari langit.
    *   **KILL ALL:** Membunuh semua zombie di map.
    *   **🛠️ LIVE TUNER:** Mengubah statistik zombie (Health, Speed) lewat HP dan tersimpan permanen.

## ⚠️ Troubleshooting
*   **Tidak bisa akses di HP:** Cek Firewall laptop, pastikan Node.js allowed. Pastikan satu Wi-Fi.
*   **Shoot tidak jalan:** Pastikan karakter sedang memegang Tool/Senjata.

---

# ⚔️ Workflow: Procedural 3D Generator (Blender Bridge)

Fitur paling canggih: Membuat aset 3D (Pedang) secara otomatis menggunakan script Python di Blender, diperintah lewat Web Dashboard.

## 📁 Struktur Sistem
1.  **Blender Script:** `LocalAnalytics/blender_scripts/sword_gen.py` (Script Python yang berisi rumus geometri pedang).
2.  **Server Agent:** Node.js menerima perintah `POST /generate-sword` -> Menjalankan `blender.exe` di background.
3.  **Output:** File `.fbx` hasil generate muncul di `LocalAnalytics/public/assets`.

## 🚀 Cara Menggunakan
1.  Pastikan **Blender** terinstall (Default path: `D:\Blender\blender.exe` - sesuaikan di `server.js` jika beda).
2.  Buka Web Dashboard (`http://localhost:3000` atau via HP).
3.  Klik tombol ungu **[⚔️ GENERATE SWORD]**.
4.  Tunggu notifikasi "✅ Ready".
5.  Buka folder `LocalAnalytics/public/assets`.
6.  **Drag & Drop** file `sword_xxxx.fbx` ke Roblox Studio.

## 🎨 Modifikasi
Anda bisa mengedit `sword_gen.py` untuk mengubah bentuk, warna, atau bahkan membuat benda lain (Pohon, Batu, Senjata Api).

---

**🎉 Kesimpulan Sistem:**
Anda sekarang memiliki **Local Development Ecosystem** yang lengkap:
1.  **🔍 Analytics:** Debugging error otomatis.
2.  **🎛️ Live Config:** Balancing game realtime.
3.  **🤖 AI NPC:** Chatbot cerdas offline.
4.  **📱 Phone Remote:** Kontrol game dari HP.
5.  **🏭 3D Generator:** Pabrik aset otomatis.

*Semua berjalan di Laptop Anda sendiri tanpa biaya server.*
