# 💾 DataStore & ProfileStore

Sistem penyimpanan data pemain.

## Technology

- **Library:** ProfileStore (by loleris)
- **Benefits:** Session locking, data integrity, auto-reconcile

## Environment

```lua
-- GameConfig.lua
DataStore = {
    Environment = "dev" | "prod"
}
-- Store name: "PlayerProfileStore_" .. ENVIRONMENT
```

## Data Schema (v1)

```lua
DEFAULT_PLAYER_DATA = {
    version = 1,
    lastSaveTimestamp = 0,

    -- === STATS (Permanent, tracked for leaderboards) ===
    stats = {
        TotalCoins = 0,           -- Lifetime coins earned
        TotalDamageDealt = 0,     -- Lifetime damage dealt
        TotalKills = 0,           -- Lifetime zombie kills
        TotalRevives = 0,         -- Players revived
        TotalKnocks = 0,          -- Times knocked down
        DailyRewardLastClaim = 0, -- Timestamp
        DailyRewardCurrentDay = 1,-- Current day streak
        AchievementPoints = 0,    -- AP currency
        MissionPoints = 0,        -- MP currency
        WeaponStats = {},         -- Per-weapon stats
        MissionsCompleted = 0,    -- Total missions done
    },

    -- === MISSIONS ===
    missions = {
        Daily = {
            Missions = {},    -- Active daily missions
            LastReset = 0,    -- Last reset timestamp
            RerollUsed = false
        },
        Weekly = {
            Missions = {},
            LastReset = 0,
            RerollUsed = false
        },
        RecentMissions = {}   -- Prevent duplicate spawns
    },

    -- === LEVELING ===
    leveling = {
        Level = 1,
        XP = 0,
    },

    -- === GLOBAL MISSIONS ===
    globalMissions = {},  -- Server-wide mission progress

    -- === TITLES ===
    titles = {
        UnlockedTitles = {}, -- Array of unlocked title IDs
        EquippedTitle = ""   -- Currently displayed title
    },

    -- === INVENTORY ===
    inventory = {
        Coins = 0,              -- Current spendable coins
        Skins = {
            Owned = {},         -- { [WeaponName] = {"Skin1", "Skin2"} }
            Equipped = {}       -- { [WeaponName] = "SkinName" }
        },
        Weapons = {},           -- Owned weapon list
        Boosters = {},          -- { [BoosterID] = quantity }
        Items = {},             -- { [ItemID] = quantity }
        PityCount = 0,          -- Gacha pity counter
        LastFreeGachaClaimUTC = 0
    },

    -- === ACHIEVEMENTS ===
    achievements = {
        Completed = {},  -- Array of completed achievement IDs
        Progress = {}    -- { [AchievementID] = currentProgress }
    },

    -- === FIELD KITS (formerly Boosters) ===
    boosters = {
        Owned = {},   -- { [BoosterID] = quantity }
        Active = nil  -- Currently equipped booster ID
    },

    -- === SETTINGS ===
    settings = {
        sound = {
            enabled = true,
            sfxVolume = 0.8
        },
        controls = {
            fireControlType = "FireButton" -- or "AutoFire"
        },
        hud = {},
        gameplay = {
            shadows = true
        }
    }
}
```

## Key Modules

| Module | Purpose |
|:-------|:--------|
| `DataStoreManager.luau` | Core data persistence |
| `InventoryManager.luau` | Inventory CRUD operations |
| `StatsModule.luau` | Stats tracking & leaderboards |
| `MissionManager.luau` | Mission data management |

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
