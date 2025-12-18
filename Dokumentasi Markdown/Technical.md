# 🛠️ Dokumentasi Teknis

Arsitektur sistem, skema data, dan manajemen backend.

## 💾 DataStore & ProfileStore
Menggunakan **ProfileStore** untuk integritas data dan locking sesi.

### Data Schema (Version 1)
Struktur tabel `PlayerData`:

```lua
Stats = {
    TotalCoins = 0,
    TotalKills = 0,
    AchievementPoints = 0,
    WeaponStats = {}
}
Inventory = {
    Coins = 0,
    Skins = { Owned = {}, Equipped = {} },
    PityCount = 0 -- Gacha pity
}
Progression = {
    Level = 1,
    XP = 0,
    Titles = { Unlocked = {} }
}
```

### Leaderboards
Menggunakan `OrderedDataStore`.
*   **Tipe:** Kill, Total Damage, Level, Mission Points.
*   **Update:** Real-time saat pemain keluar atau interval tertentu.

## 🏗️ Technical Architecture
*   **Module-Based:** Logika inti dipecah menjadi ModuleScript di `ServerScriptService`.
*   **Networking:** Pola `RemoteEvent` searah (Client -> Server Action) dan `RemoteFunction` untuk request data.
*   **Session Locking:** Mencegah eksploit duplikasi item dengan memblokir login ganda.
