# 🖥️ UI Master Guide

Master list semua UI yang dibutuhkan untuk game.

> 📎 Lihat juga: [Asset Master Guide](asset-master-guide.md) | [Shop System](../gameplay/shop-system.md)

---

# 🎮 GAMEPLAY HUD

## Core HUD Elements
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Health/Shield Bar | StatusHUD | Player HP & Shield |
| ✅ | Ammo Counter | AmmoUI | Current/Max ammo |
| ✅ | Crosshair | CrosshairUI | Dynamic crosshair |
| ✅ | Wave Counter | WaveCounterUI | Current wave display |
| ✅ | Points Display | PointsUI | Valor counter |
| ✅ | Coins Display | CoinsUI | Permanent currency |
| ✅ | Hitmarker | HitmarkerUI | Hit feedback |
| ✅ | Damage Flash | DamageFlashUI | Screen flash on hit |

## Combat UI
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Boss Alert | BossAlertUI | Boss spawn warning |
| ✅ | Boss Timer | BossTimerUI | Boss HP/Timer display |
| ✅ | Special Wave Alert | SpecialWaveAlertUI | Wave type notification |
| ✅ | Knock/Revive | KnockUI, ReviveUI | Down state & revive |
| ✅ | Global Knock Notification | GlobalKnockNotificationUI | Team knock alerts |

## Status Displays
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Perk Display | PerkDisplayUI | Active perks |
| ✅ | Tactical Boost Display | TacticalBoostDisplayUI | Equipped tactical boosts |
| ✅ | Skill Display | SkillUI | Active skills |
| ✅ | UTC Clock | UTCClockUI | Time display |

---

# 🏪 SHOP UI

| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Perk Shop | PerkShopUI | Buy perks |
| ✅ | Random Weapon Shop | RandomWeaponShopUI | Mystery box |
| ✅ | Upgrade Shop | UpgradeShopUI | Weapon upgrades |
| ✅ | Tactical Boost Shop | TacticalBoostShopUI | Buy tactical boosts |
| ✅ | AP Shop | APShopUI | Achievement Points shop |
| ✅ | MP Shop | MPShopUI | Mission Points shop |
| ✅ | Gacha | GachaUI | Gacha system |
| ✅ | Gacha Announcer | GachaAnnouncerUI | Gacha results |

---

# 📋 MENUS & SCREENS

## Main Menus
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Start Screen (Lobby) | StartLobby | Lobby main menu |
| ✅ | Start Screen (ACT) | StartUI | Game start UI |
| ✅ | Game Settings | GameSettingsUI | Options menu |
| ✅ | Profile | ProfileUI | Player stats |
| ✅ | Inventory | InventoryUI | Items & equipment |
| ✅ | Achievement | AchievementUI | Achievement list |
| ✅ | Achievement Points | AchievementPointsUI | AP display |
| ✅ | Mission Points | MissionPointsUI | MP display |
| ✅ | Mission | MissionUI | Daily/Weekly missions |
| ✅ | Daily Reward | DailyRewardUI | Login rewards |

## End Game Screens
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Victory | VictoryUI | Win screen |
| ✅ | Game Over | GameOverUI | Defeat screen |

## Admin
| Status | UI | Script | Notes |
|:------:|:---|:-------|:------|
| ✅ | Admin Panel | AdminUI | Dev tools |

---

# ❌ MISSING/PLANNED UI

## Objective UI
| Status | UI | Notes |
|:------:|:---|:------|
| ❌ | Objective HUD | Shows current objective + progress |
| ❌ | Objective Alert | New objective popup |
| ❌ | Objective Complete | Success notification |

## Field Kit UI
| Status | UI | Notes |
|:------:|:---|:------|
| ❌ | Field Kit Selection | Choose active kit |
| ❌ | Field Kit Display | Show equipped kit |

## Title UI
| Status | UI | Notes |
|:------:|:---|:------|
| ❌ | Title Selection | Choose active title |
| ❌ | Title Display (Overhead) | Show title above player |

## Lobby UI
| Status | UI | Notes |
|:------:|:---|:------|
| ❌ | NPC Dialogue | Conversation system |
| ❌ | Leaderboard Display | Top players |
| ❌ | Party System | Group up with friends |
| ❌ | Difficulty Selection | Choose difficulty |
| ❌ | ACT Selection | Choose which ACT |

## Feedback UI
| Status | UI | Notes |
|:------:|:---|:------|
| ❌ | Tutorial/Hints | Onboarding UI |
| ❌ | Kill Feed | Recent kills display |
| ❌ | Damage Numbers | Floating damage text |
| ❌ | XP/Level Up | Level progress |

---

# 🎨 UI DESIGN SYSTEM

## Visual Theme
| Aspect | Guideline |
|:-------|:----------|
| **Theme** | Makeshift Survivor Camp (Stylized Post-Apocalypse) |
| **Primary Colors** | Warm Brown, Forest Green, Sunset Orange |
| **Accent Colors** | Bright Yellow, Soft Cyan |
| **Alert Colors** | Soft Red, Orange |
| **Shape Language** | Rounded Corners (8-12px) |

## Color Palette
| Element | Color | Hex |
|:--------|:------|:----|
| Primary | Blue | #3498db |
| Secondary | Dark Blue | #2980b9 |
| Accent | Yellow | #f1c40f |
| Danger | Red | #e74c3c |
| Success | Green | #2ecc71 |
| Background | Dark Grey | #2c3e50 |
| Text | White | #ffffff |

## Rarity Colors
| Rarity | Color | Hex |
|:-------|:------|:----|
| Common | Grey | #b4b4b4 |
| Uncommon | Green | #00c800 |
| Rare | Blue | #0096ff |
| Epic | Purple | #9600c8 |
| Legendary | Gold | #ffc800 |

## Typography
| Usage | Font | Size |
|:------|:-----|:-----|
| Header | Luckiest Guy / FredokaOne | 24-32 |
| Body | GothamMedium / SemiBold | 14-20 |
| Button | GothamMedium | 18-24 |
| Small | Gotham | 10-12 |

## Standard Dimensions

### Safe Zone
- **Max Size:** Scale 0.9 (90% Layar)
- **Margin:** Minimal 5% dari setiap sisi

### Touch Target Size
- **Minimum:** 44x44 pixels
- **Ideal:** 60x60 pixels
- **Padding:** 10px antar tombol

### Aspect Ratios
| Type | Ratio | Example |
|:-----|:------|:--------|
| Landscape | 16:9 | Shop, Map |
| Portrait | 2:3 | Item Info |
| Square | 1:1 | Icons |

## ZIndex Layers
| Range | Usage |
|:------|:------|
| 0-10 | Backgrounds, Panels |
| 11-50 | Main Content |
| 100+ | Overlays, Popups |
| 1000+ | Global Effects |

## Naming Conventions
| Prefix | Element |
|:-------|:--------|
| `btn_` | Button |
| `lbl_` | Label |
| `fr_` | Frame |
| `sc_` | ScrollingFrame |

## Animation Guidelines
- Fade in/out: 0.2-0.3s
- Slide transitions: 0.3-0.5s
- Pop/bounce: 0.15s
- Use TweenService, TextScaled

## Technical Rules
- Use `Scale` not `Offset` for positioning
- Use `UITextSizeConstraint` (Min: 14, Max: 48)
- Check `TouchEnabled` for mobile
- Background images: 1024x1024px, PNG transparan

---

# 📊 PROGRESS SUMMARY

| Category | Done | Total | % |
|:---------|:-----|:------|:--:|
| Gameplay HUD | 13 | 13 | 100% |
| Shop UI | 8 | 8 | 100% |
| Menus | 12 | 12 | 100% |
| Objective UI | 0 | 3 | 0% |
| Field Kit UI | 0 | 2 | 0% |
| Title UI | 0 | 2 | 0% |
| Lobby UI | 0 | 5 | 0% |
| Feedback UI | 0 | 4 | 0% |
| **TOTAL** | **33** | **49** | **67%** |

> ✅ = Done | ❌ = Todo
