# ⚡ Tactical Boosts

Sistem upgrade sementara untuk senjata pemain.

> Sebelumnya disebut "Elements" - sekarang **reflavored ke tema survival/tactical** untuk konsistensi dengan Cozy Apocalypse aesthetic.

---

## 📋 Overview

Tactical Boosts adalah **consumable upgrades** yang dibeli per-wave dan memberikan efek sementara pada senjata/pemain.

### Cara Kerja
1. Beli Boost dari toko (1x per wave)
2. Aktivasi manual saat sudah dibeli
3. Efek aktif untuk durasi tertentu
4. Setelah habis, perlu beli lagi wave berikutnya

---

## 🎯 Tactical Boosts List

### Tier 1 (Cost: 1500 CP)

| Internal Key | Display Name | Effect | Duration |
|:-------------|:-------------|:-------|:---------|
| `Fire` | **Incendiary Rounds** | Damage +30%, burn 10% damage/tick (3 ticks) | 10s |
| `Ice` | **Cryo Compound** | Slow enemies 30% for 4s | 20s |
| `Poison` | **Toxic Agent** | 5 DPS poison for 6s | 10s |
| `Shock` | **EMP Burst** | Chain 50% damage to enemies within 6 studs | 10s |
| `Wind` | **Concussion Blast** | Push enemies back (knockback only) | 10s |
| `Earth` | **Hardened Armor** | 20% damage reduction | 10s |

### Tier 2 (Cost: 3000 CP)

| Internal Key | Display Name | Effect | Duration |
|:-------------|:-------------|:-------|:---------|
| `Light` | **Stimpack** | Complete invincibility | 3s |

### Tier 3 (Cost: 5000 CP)

| Internal Key | Display Name | Effect | Duration |
|:-------------|:-------------|:-------|:---------|
| `Dark` | **Adrenaline Serum** | 10% life steal on damage dealt | 5s |

---

## 🎨 Visual Theme

### Before (Magic/Fantasy) → After (Tactical/Survival)

| Old Name | New Name | Visual Direction |
|:---------|:---------|:-----------------|
| Fire Element | Incendiary Rounds | Orange glow, ammo tracer |
| Ice Element | Cryo Compound | Blue frost particles |
| Poison Element | Toxic Agent | Green chemical mist |
| Shock Element | EMP Burst | Electric sparks, blue-white |
| Wind Element | Concussion Blast | Shockwave ripple |
| Earth Element | Hardened Armor | Metallic shield overlay |
| Light Element | Stimpack | Medical glow, syringe effect |
| Dark Element | Adrenaline Serum | Red veins, heartbeat effect |

### VFX Modules (Unchanged internally)
```
ReplicatedStorage/
└── ElementVFX/
    ├── FireVFXModule.lua     → Incendiary visuals
    ├── IceVFXModule.lua      → Cryo visuals
    ├── PoisonVFXModule.lua   → Toxic visuals
    ├── ShockVFXModule.lua    → EMP visuals
    ├── WindVFXModule.lua     → Concussion visuals
    ├── EarthVFXModule.lua    → Armor visuals
    ├── LightVFXModule.lua    → Stimpack visuals
    └── DarkVFXModule.lua     → Adrenaline visuals
```

---

## 🛠️ Implementation Notes

### Code Compatibility
- Internal keys (`Fire`, `Ice`, etc.) **tidak diubah** untuk menjaga backward compatibility
- `DisplayName` field ditambahkan untuk UI
- `Description` field ditambahkan untuk tooltip

### UI Updates Needed
- [ ] Update shop UI untuk menggunakan `DisplayName` bukan key
- [ ] Update tooltip untuk menampilkan `Description`
- [ ] Update icons untuk match tema tactical

### Example Usage (UI)
```lua
local config = ElementModule.GetConfig()
for key, data in pairs(config) do
    print(data.DisplayName) -- "Incendiary Rounds"
    print(data.Description) -- "Peluru pembakar..."
    print(data.Cost)        -- 1500
end
```

---

## 📊 Balance Notes

| Boost | Use Case | Counter/Weakness |
|:------|:---------|:-----------------|
| Incendiary | High damage, DoT | Duration short |
| Cryo | Crowd control | No extra damage |
| Toxic | Sustained DPS | Slow tick rate |
| EMP | Group fights | Short range (6 studs) |
| Concussion | Escape/control | Speed boost short |
| Armor | Tank builds | No offense boost |
| Stimpack | Emergency/clutch | Very expensive, very short |
| Adrenaline | Sustain/solo | Expensive, needs constant damage |

---

*"Kita tidak punya sihir. Tapi kita punya sains dan rongsokan."*  
— Quartermaster
