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
