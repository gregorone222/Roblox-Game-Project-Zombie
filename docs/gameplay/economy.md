# 💰 Economy & Progression

Sistem mata uang dan kemajuan pemain.

> 📎 Lihat juga: [Shop System](shop-system.md) | [Field Kit](field-kit.md)

## Currency Types

| Currency | Type | Source | Usage | Handler |
|:---------|:-----|:-------|:------|:--------|
| **Survival Coins** | Permanen | Wave Clear & Damage | Skin/Item permanen, Gacha | `CoinsModule.luau` |
| **Valor** | Sesi | In-game kills/objectives | In-game shops | `ValorModule.luau` |
| **AP (Achievement Points)** | Permanen | Achievements | AP Shop items | `StatsModule.luau` |
| **MP (Mission Points)** | Permanen | Missions | MP Shop items | `MissionPointsModule.luau` |

---

## 💵 Survival Coins (Permanent Currency)

### Formula
**Base Ratio:** 20 Damage = 1 Coin

| Difficulty | Multiplier |
|:-----------|:-----------|
| Easy | 1.0x |
| Normal | 1.2x |
| Hard | 1.5x |
| Expert | 2.0x |
| Hell | 2.5x |
| Crazy | 3.0x |

### Usage
- **Gacha** - Roll for weapon skins
- **Skin purchases** - Buy specific skins

---

## ⚔️ Valor - Session Currency

Valor is earned during gameplay and **resets every session**.

### Earning Valor
| Source | Valor Earned |
|:-------|:----------|
| Kill zombie | 10-50 Valor |
| Kill special zombie | 50-100 Valor |
| Kill boss | 500-1000 Valor |
| Wave objective complete | 200-500 Valor |

### Spending Valor
- Tactical Boosts (1,500-5,000 Valor)
- Perks (2,000-6,000 Valor)
- Random Weapon (1,000+ Valor, scaling)
- Weapon Upgrade (varies)


---

## 🏆 AP (Achievement Points) - Permanent

Earned by completing achievements. Tracked by `StatsModule.luau`.

### AP Shop (`APShopManager.luau`)
| Item | AP Cost |
|:-----|:--------|
| Skill Reset Token | varies |
| Exclusive Titles | varies |
| Special Skins | varies |

### Earning AP
- Complete achievements (one-time rewards)
- Achievement tiers unlock more AP

---

## 📋 MP (Mission Points) - Permanent

Earned by completing daily/weekly missions. Tracked by `MissionPointsModule.luau`.

### MP Shop (`MPShopManager.luau`)
| Item | MP Cost |
|:-----|:--------|
| Daily Mission Reroll | varies |
| Boosters | varies |
| Special Skins | varies |

### Earning MP
- Complete Daily Missions
- Complete Weekly Missions
- Complete Global Missions

---

## 📈 XP System

**Base Ratio:** 5 Damage = 1 XP

| Difficulty | Multiplier |
|:-----------|:-----------|
| Easy | 1.0x |
| Normal | 1.2x |
| Hard | 1.5x |
| Expert | 2.0x |
| Hell | 2.2x |
| Crazy | 2.5x |

---

## 🎮 Progression Features

| Feature | Handler | Description |
|:--------|:--------|:------------|
| **Leveling** | `LevelModule.luau` | XP dari kills/damage |
| **Leaderboards** | `StatsModule.luau` | Global tracking (Kill, Damage, Level) |
| **Daily Rewards** | `DailyRewardManager.luau` | Login bonus di Lobby |
| **Titles** | `TitleManager.luau` | Unlockable via achievements |
| **Skills** | `SkillModule.luau` | Passive stat upgrades |
| **Achievements** | `AchievementManager.luau` | One-time challenges |
