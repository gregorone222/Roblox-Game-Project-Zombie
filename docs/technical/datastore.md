# 💾 DataStore & ProfileStore

Sistem penyimpanan data pemain.

## Technology

- **Library:** ProfileStore
- **Benefits:** Session locking, data integrity

## Data Schema (v1)

```lua
PlayerData = {
    Stats = {
        TotalCoins = 0,
        TotalKills = 0,
        AchievementPoints = 0,
        WeaponStats = {}
    },
    Inventory = {
        Coins = 0,
        Skins = { Owned = {}, Equipped = {} },
        PityCount = 0  -- Gacha pity
    },
    Progression = {
        Level = 1,
        XP = 0,
        Titles = { Unlocked = {} }
    }
}
```

## Leaderboards

- **Storage:** OrderedDataStore
- **Types:** Kill, Total Damage, Level, Mission Points
- **Best Practice:** `math.floor()` sebelum `SetAsync` untuk mencegah error "double is not allowed"
- **Update:** Real-time saat pemain keluar atau interval tertentu

## Admin Whitelist Fields

Field yang boleh diubah oleh admin:
- **Leveling:** `Level`, `XP`
- **Resources:** `SkillPoints`, `MissionPoints`, `AchievementPoints`
- **Inventory:** `Coins`, `PityCount`

> [!CAUTION]
> **DILARANG:** Statistik inti seperti `TotalKills` atau `WeaponStats` dikunci untuk menjaga integritas Leaderboard.
