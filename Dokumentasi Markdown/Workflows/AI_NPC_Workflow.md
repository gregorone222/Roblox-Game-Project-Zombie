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
