# 🛒 In-Game Shop System

Dokumentasi sistem pembelian dalam game menggunakan **Valor**.

> **IMPORTANT:** Shop ini hanya tersedia saat gameplay (ACT 1 dan seterusnya), TIDAK di Lobby.

---

## 💰 Mata Uang: Valor

Valor adalah mata uang utama dalam game yang didapat dari:

| Sumber | Valor Earned |
|:-------|:----------|
| Kill zombie biasa | ~10-50 Valor |
| Kill special zombie | ~50-100 Valor |
| Kill boss | ~500-1000 Valor |
| Complete wave objective | ~200-500 Valor |

> Valor **RESET setiap game session** (tidak tersimpan antar game)

---

## 🗺️ Lokasi Shop di Map

```
                ACT 1 MAP
    ┌────────────────────────────────┐
    │                                │
    │   [PERK]              [UPGRADE]│
    │   Machine             Station  │
    │                                │
    │         [RADIO TOWER]         │
    │            (center)            │
    │                                │
    │   [RANDOM]           [TACTICAL]│
    │   Mystery              Boosts  │
    │   Cache                Vendor  │
    │                                │
    └────────────────────────────────┘
```

---

## 🎯 4 SHOP SYSTEMS

### 1️⃣ Tactical Boosts Shop

**Objek:** Vending Machine / Tactical Crate  
**Trigger:** Proximity Prompt "E"

| Boost | Display Name | Cost | Duration | Effect |
|:------|:-------------|:-----|:---------|:-------|
| Fire | Incendiary Rounds | 1,500 | 10s | +30% damage, burn DoT |
| Ice | Cryo Compound | 1,500 | 20s | 30% slow |
| Poison | Toxic Agent | 1,500 | 10s | 5 DPS poison |
| Shock | EMP Burst | 1,500 | 10s | Chain damage |
| Wind | Concussion Blast | 1,500 | 10s | Knockback only |
| Earth | Hardened Armor | 1,500 | 10s | 20% damage reduction |
| Light | Stimpack | 3,000 | 3s | Invincibility |
| Dark | Adrenaline Serum | 5,000 | 5s | 10% lifesteal |

**Rules:**
- Hanya bisa beli **1 boost per wave**
- Harus **aktivasi manual** setelah dibeli
- Effect hilang setelah duration habis

---

### 2️⃣ Perk Shop

**Objek:** Perk Machine (model khusus dengan tampilan stylized/cartoon)  
**Trigger:** Proximity Prompt "E"

| Perk | Cost | Effect |
|:-----|:-----|:-------|
| Helping Hand | 2,000 | Revive ally 50% faster |
| Revival Expert | 2,000 | +30% HP saat revive |
| Thick Skin | 4,000 | Max HP +30% (130 HP) |
| Runner's High | 4,000 | Max Stamina +30% |
| Quick Hands | 4,000 | Reload 30% faster |
| Rapid Fire | 6,000 | Fire Rate +30% |

**Rules:**
- Perks **PERMANEN** untuk seluruh sesi game
- Limit jumlah perk berdasarkan **difficulty**:
  - Normal/Hard/Expert: Max 3
  - Hell: Max 2
  - Crazy: Max 1
- Tidak bisa beli perk yang sama dua kali

**Tier Structure:**
```
UTILITY (2,000 Valor)
├── Helping Hand
└── Revival Expert

CORE (4,000 Valor)
├── Thick Skin
├── Runner's High
└── Quick Hands

ELITE (6,000 Valor)
└── Rapid Fire
```

---

### 3️⃣ Random Weapon Shop (Mystery Cache)

**Objek:** Mystery Crate / Weapon Box (model kotak dengan tanda "?")  
**Trigger:** Proximity Prompt "E"

**Mechanics:**
- Cost meningkat setiap pembelian dalam game session
- Player mendapat senjata **RANDOM** dari pool yang tersedia
- Jika sudah punya 2 senjata, harus pilih mana yang di-replace

**Cost Scaling:**
| Purchase # | Cost |
|:-----------|:-----|
| 1st | 1,000 Valor |
| 2nd | 2,000 Valor |
| 3rd | 3,000 Valor |
| 4th+ | +1,000 per purchase |

**Weapon Pool:**
- Semua senjata yang tersedia di game
- Rarity/tier tidak mempengaruhi chance (equal weight)
- Tidak bisa dapat senjata yang sudah dimiliki (no duplicates)

**Rules:**
- Max 2 weapons per player
- UI muncul untuk pilih weapon mana yang di-replace

---

### 4️⃣ Upgrade Shop

**Objek:** Upgrade Station / Workbench  
**Trigger:** Proximity Prompt "E"

**Mechanics:**
- Upgrade senjata yang **sedang di-equip**
- Setiap upgrade meningkatkan damage dan ammo
- Cost meningkat per level

**Stats per Level:**

| Level | Damage Bonus | Ammo Bonus | Cost Formula |
|:------|:-------------|:-----------|:-------------|
| 1 → 2 | +6 | +3-8 (varies) | BaseCost |
| 2 → 3 | +6 | +3-8 | BaseCost × 1.5 |
| 3 → 4 | +6 | +3-8 | BaseCost × 1.5² |
| n → n+1 | +DamagePerLevel | +AmmoPerLevel | BaseCost × 1.5^(n-1) |

**Default Upgrade Config (per weapon):**
```lua
UpgradeConfig = {
    BaseCost = 150-250 (varies per weapon)
    CostMultiplier = 1.5
    CostExpo = 1.3
    DamagePerLevel = 5-8 (varies)
    AmmoPerLevel = 1-8 (varies)
    MaxLevel = 10
}
```

**Rules:**
- Setiap senjata punya **max level 10**
- Upgrade **TIDAK tersimpan** antar game session
- Harus memegang senjata yang ingin di-upgrade

---

## 🏪 Shop Access Summary

| Shop | Objek | Location | Access |
|:-----|:------|:---------|:-------|
| Tactical Boosts | Vending Machine | Village Square area | Prompt "E" |
| Perk | Perk Machine | Map corner | Prompt "E" |
| Random Weapon | Mystery Cache | Map opposite corner | Prompt "E" |
| Upgrade | Workbench | Near spawn | Prompt "E" |

---

## ⚙️ Technical Implementation

### Shop Interaction Flow:
```
Player walks near shop object
    ↓
ProximityPrompt appears (E to interact)
    ↓
Player presses E
    ↓
Client fires RemoteEvent: RequestOpen[Shop]
    ↓
Server validates proximity
    ↓
Server fires OpenEvent to Client with data
    ↓
Shop UI opens
    ↓
Player selects item and clicks Buy
    ↓
Client fires RemoteFunction: Purchase[Item]
    ↓
Server validates:
    - Enough Valor?
    - Already owned? (for perks)
    - Near shop?
    ↓
Server deducts Valor, grants item
    ↓
Server fires update events to Client
```

### Key Files:

| System | UI (Client) | Manager/Config (Server) |
|:-------|:------------|:------------------------|
| Tactical | `TacticalBoostShopUI.lua` | `TacticalBoostModule.lua` |
| Perk | `PerkShopUI.lua` | `PerkModule.lua`, `PerkConfig.lua` |
| Random | `RandomWeaponShopUI.lua` | (logic in manager) |
| Upgrade | `UpgradeShopUI.lua` | `WeaponModule.lua` (UpgradeConfig) |

---

## 🎁 Field Kit Integration

Field Kits (formerly Boosters) memberikan advantage di awal game. **TIDAK dijual** - hanya dari Daily Reward dan Gacha.

> 📎 Detail lengkap: [Field Kit Documentation](field-kit.md)

| Kit | Effect | Interaksi dengan Shop |
|:----|:-------|:----------------------|
| Starting Funds | +1,500 Valor | Lebih banyak uang untuk belanja |
| Ammo Stockpile | +50% max ammo | Tidak berpengaruh ke shop |
| Body Armor | 50% bonus shield | Tidak berpengaruh ke shop |
| Mystery Loadout | Random starting weapon | Tidak berpengaruh ke shop |
| Commander's Authority | +10% team damage | Tidak berpengaruh ke shop |

---

## 📊 Economy Balance Notes

**Target Valor per Wave:**
- Wave 1-10: ~500-1,500 Valor
- Wave 11-25: ~2,000-4,000 Valor
- Wave 26-40: ~5,000-8,000 Valor
- Wave 41-50: ~8,000-15,000 Valor

**Spending Priority (Recommended):**
1. **Early Game (Wave 1-15):** Random Weapon → Upgrade
2. **Mid Game (Wave 16-35):** Perks → Tactical Boosts
3. **Late Game (Wave 36-50):** Max Upgrades → Premium Tactical

---

*"Uang bukan segalanya. Tapi di dunia ini, uang bisa membelikanmu waktu hidup lebih lama."*  
— Quartermaster
