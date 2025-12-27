# 🏷️ Title System

Sistem title/gelar yang bisa didapat dari **Exchange (AP/MP)** dan **Gacha**.

> **NOTE:** Titles hanya kosmetik, tidak memberikan stat bonus.

---

## 🎨 Rarity Tiers

| Rarity | Color | Gacha Rate | Exchange Cost (AP) |
|:-------|:------|:-----------|:-------------------|
| Common | Abu-abu | 40% | 100 AP |
| Uncommon | Hijau | 30% | 300 AP |
| Rare | Biru | 20% | 750 AP |
| Epic | Ungu | 8% | 1,500 AP |
| Legendary | Emas | 2% | 5,000 AP |

---

## 📜 Available Titles

### Common (Abu-abu)
| ID | Display Name | Source | Description |
|:---|:-------------|:-------|:------------|
| `Rookie` | Rookie | Exchange (100 AP) | Just starting out. |
| `Newbie` | Newbie | Exchange (50 MP) | Everyone starts somewhere. |
| `Trainee` | Trainee | Gacha | Learning the ropes. |

### Uncommon (Hijau)
| ID | Display Name | Source | Description |
|:---|:-------------|:-------|:------------|
| `Survivor` | Survivor | Exchange (300 AP) | You made it through. |
| `Fighter` | Fighter | Gacha | Never backs down. |
| `Defender` | Defender | Gacha | Protects the team. |

### Rare (Biru)
| ID | Display Name | Source | Description |
|:---|:-------------|:-------|:------------|
| `Veteran` | Veteran | Exchange (750 AP) | Experienced in combat. |
| `Sharpshooter` | Sharpshooter | Gacha | Never misses. |
| `Guardian` | Guardian | Gacha | Watches over allies. |

### Epic (Ungu)
| ID | Display Name | Source | Description |
|:---|:-------------|:-------|:------------|
| `EliteOperator` | Elite Operator | Exchange (1,500 AP) | Top tier survivor. |
| `Warlord` | Warlord | Gacha | Commands respect. |
| `Nightmare` | Nightmare | Gacha | Fear of all zombies. |

### Legendary (Emas)
| ID | Display Name | Source | Description |
|:---|:-------------|:-------|:------------|
| `ZombieSlayer` | Zombie Slayer | Exchange (5,000 AP) | The ultimate zombie hunter. |
| `Apocalypse` | Apocalypse | Gacha | The end of all zombies. |
| `Legendary` | Legendary | Gacha | A living legend. |

---

## 🎯 Cara Mendapatkan

### Exchange (AP/MP Shop)
1. Kumpulkan **AP** dari achievements atau **MP** dari missions
2. Buka **Exchange Shop** di Lobby
3. Pilih title yang diinginkan
4. Title langsung unlock setelah pembelian

### Gacha
1. Gunakan **Coins** untuk roll gacha
2. Title gacha setiap roll dengan drop rate berdasarkan rarity
3. Duplicate title = konversi ke currency

---

## ⚙️ Technical Files

| Purpose | File |
|:--------|:-----|
| Config | `TitleConfig.luau` |
| Logic | `TitleManager.luau` |
| Display | (UI inventory di lobby) |

---

*"A title is earned, not given."*  
— Alexander
