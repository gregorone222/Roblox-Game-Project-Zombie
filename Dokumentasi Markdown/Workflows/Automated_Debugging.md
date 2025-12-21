# 🐛 Workflow: Automated Debugging (Local Analytics)

Sistem ini memungkinkan **semua jenis error** (Runtime, Syntax, Engine) yang terjadi di Roblox Studio terkirim otomatis ke file log di komputer lokal. Ini memudahkan Antigravity (Agen AI) untuk membaca error dan melakukan perbaikan tanpa perlu copy-paste manual dari Output Console.

## 📁 Struktur File
1.  **Server (Node.js):** `LocalAnalytics/server.js`
    *   Berjalan di terminal VS Code. Menerima laporan dan menyimpannya ke file txt.
2.  **Client Module (Lua):** `ServerScriptService/ModuleScript/LocalAnalytics.lua`
    *   Menggunakan **MessageOut (LogService)** untuk menangkap teks merah di console.
    *   Memfilter log: Hanya mengirim `MessageError`. Print/Warn biasa **tidak** dikirim.
3.  **Loader (Lua):** `ServerScriptService/Script/AnalyticsLoader.lua`
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
