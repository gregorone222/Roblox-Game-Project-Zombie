# 🛡️ Dokumentasi Admin & Keamanan

Protokol keamanan data dan fitur manajemen user.

## 🔐 Security Protocols

### Whitelist Field (Safety Update)
Admin **HANYA** diizinkan mengubah field tertentu untuk mencegah kerusakan data:
1.  **Leveling:** `Level`, `XP`.
2.  **Resources:** `SkillPoints`, `MissionPoints`, `AchievementPoints`.
3.  **Inventory:** `Coins`, `PityCount`.

> **DILARANG:** Statistik inti seperti `TotalKills` atau `WeaponStats` dikunci dari sistem admin untuk menjaga integritas Leaderboard.

### Anti-Exploit
*   **Input Blocking:** Script `BlockArrowKeys` mematikan input default yang sering disalahgunakan exploit.
*   **Validation:** Semua input dari RemoteEvent divalidasi tipe datanya di server.

## 💻 Admin Commands
Perintah dijalankan melalui panel khusus (UI Admin) yang memanggil `AdminManager.lua`.

*   **Request Data:** Melihat data mentah pemain (ReadOnly).
*   **Update Data:** Mengedit nilai Whitelist (Safe Merge).
*   **Delete Data:** Menghapus data permanen (GDPR Compliance).
