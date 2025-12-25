# 🤖 AI NPC Integration (Ollama)

NPC yang "berbicara" cerdas menggunakan AI lokal.

## 📁 Struktur Sistem
| Komponen | Lokasi |
|:---------|:-------|
| AI Brain | Ollama (model `phi3`) |
| Server | `LocalAnalytics/server.js` |
| Client Module | `AIClient.lua` |
| NPC Logic | `TalkToAI.lua` (Server) |
| Chat Display | `AIChatDisplay.client.lua` |

---

## 🚀 Cara Menggunakan
1. Pastikan **Ollama** terinstall (`ollama --version`)
2. Jalankan `node server.js`
3. Play di Roblox Studio
4. Ketik di chat: `bot, halo` (prefix `bot,`)

---

## ⚠️ Batasan
| Limitation | Detail |
|:-----------|:-------|
| **Hanya Studio** | Tidak aktif di game publik |
| **Kecepatan** | 2-10 detik per balasan (tergantung hardware) |
| **Context** | 256 token (bot lupa cepat) |
| **Knowledge** | Tidak tahu posisi/HP/ammo pemain |
