# 🛡️ Data Safety & Disaster Recovery

Panduan keamanan data dan prosedur pemulihan untuk game ini.

## Arsitektur Perlindungan Data

```
ProfileStore.luau (Third-party library by loleris)
        ↓
DataStoreManager.luau (Wrapper)
        ↓
┌───────────────────────────────────────┐
│  SurvivalCoinsModule, StatsModule,    │
│  LevelModule, MissionManager,         │
│  InventoryManager, SkinManager, etc.  │
└───────────────────────────────────────┘
```

> [!IMPORTANT]
> **SEMUA** data player melalui DataStoreManager yang terintegrasi dengan ProfileStore.

---

## Fitur Keamanan Aktif

| Fitur | Deskripsi | Status |
|:------|:----------|:-------|
| **Session Locking** | Mencegah 2 server edit data yang sama | ✅ Aktif |
| **Auto-Save** | Data disimpan otomatis setiap 300 detik | ✅ Aktif |
| **BindToClose** | Data disimpan saat server shutdown | ✅ Aktif |
| **Reconcile** | Field baru otomatis ditambahkan ke data lama | ✅ Aktif |
| **Version History** | Roblox menyimpan 30 hari versi data | ✅ Tersedia |
| **Error Handling** | Exponential backoff jika DataStore error | ✅ Aktif |

---

## Estimasi Risiko

| Skenario | Kemungkinan | Penyebab Utama |
|:---------|:------------|:---------------|
| Data hilang total | < 0.01% | Roblox DataStore outage (sangat jarang) |
| Duplikasi item | < 0.1% | Session lock gagal (ProfileStore mencegah) |
| Data tidak tersimpan | ~0.5% | Server crash sebelum auto-save |
| Data rollback | ~1-2% | Roblox service outage |
| **Bug developer** | **>90% dari kasus** | Kode yang salah menghapus/overwrite data |

---

## Prosedur Recovery

### 1. Player Lapor Data Hilang

```
1. Player: Lapor via Discord/Support dengan UserId
2. Admin: Lookup version history
3. Admin: Preview data dari versi lama
4. Admin: Restore jika valid
5. Admin: Berikan kompensasi jika diperlukan
```

### 2. Menggunakan DataRecoveryAdmin

```lua
local DataRecoveryAdmin = require(ServerScriptService.ModuleScript.DataRecoveryAdmin)

-- Lihat version history (10 versi terakhir)
local versions = DataRecoveryAdmin.GetVersionHistory(targetUserId, 10)

-- Preview data restore
local preview = DataRecoveryAdmin.PreviewRestore(targetUserId, versionId)

-- Restore (player harus online)
local success, msg = DataRecoveryAdmin.RestoreToVersion(adminPlayer, targetUserId, versionId)

-- Berikan kompensasi
DataRecoveryAdmin.GiveCompensation(adminPlayer, targetPlayer, "SurvivalCoins", 1000)
```

### 3. Kompensasi Standar

| Tingkat Kehilangan | Kompensasi |
|:-------------------|:-----------|
| Minor (< 1 hari progress) | 1x nilai yang hilang |
| Moderate (1-7 hari) | 1.5x nilai + bonus item |
| Severe (>7 hari atau Robux) | 2x nilai + exclusive item + personal apology |

---

## Protected Files

> [!CAUTION]
> File berikut **DILARANG KERAS** untuk dimodifikasi.

| File | Alasan |
|:-----|:-------|
| `ProfileStore.luau` | Library pihak ketiga by loleris |

---

## Best Practices untuk Developer

```lua
-- ❌ JANGAN lakukan ini:
profile.Data = {}              -- Menghapus SEMUA data!
profile.Data.SurvivalCoins = nil  -- Menghapus field!

-- ✅ AMAN:
profile.Data.SurvivalCoins = profile.Data.SurvivalCoins + 100
profile.Data.SurvivalCoins = math.max(0, profile.Data.SurvivalCoins - 50)
```

---

## Related Documentation

- [DataStore Schema](datastore.md)
- [Development Rules](../reference/rules.md)
