# 🔊 Sound Master Guide

Master list semua Audio yang dibutuhkan untuk game.

> 📎 Lihat juga: [VFX Master Guide](vfx-master-guide.md) | [Asset Master Guide](asset-master-guide.md)

---

# 🔫 WEAPON SOUNDS

| Status | Category | Fire Sound | Reload Sound |
|:------:|:---------|:-----------|:-------------|
| ✅ | Pistol | rbxassetid://4502821590 | rbxassetid://8302576808 |
| ✅ | Rifle | rbxassetid://116169266166053 | rbxassetid://110520432216161 |
| ✅ | SMG | rbxassetid://87534588983395 | rbxassetid://801171060 |
| ✅ | Shotgun | rbxassetid://7282759187 | rbxassetid://145081845 |
| ✅ | Sniper | rbxassetid://5679835770 | rbxassetid://7641927705 |
| ✅ | LMG | rbxassetid://5679835770 | rbxassetid://7641927705 |
| ✅ | Empty Click | rbxassetid://9113104337 | - |

---

# 🔥 ELEMENT SOUNDS

| Status | Element | Sound ID |
|:------:|:--------|:---------|
| ✅ | Fire | rbxassetid://7106659874 |
| ✅ | Ice | rbxassetid://9118068272 |
| ✅ | Earth | rbxassetid://9066038215 |
| ✅ | Wind | rbxassetid://9046003215 |
| ❌ | Shock | Missing |
| ❌ | Poison | Missing |
| ❌ | Light | Missing |
| ❌ | Dark | Missing |

---

# 👹 BOSS SOUNDS

| Status | Sound | ID | Use |
|:------:|:------|:---|:----|
| ✅ | Alert | rbxassetid://9119663003 | Boss spawn warning |
| ✅ | Complete | rbxassetid://9119663691 | Boss defeated |
| ✅ | Bass | rbxassetid://130863833 | Boss presence |

---

# 🧪 VFX SOUNDS

| Status | Sound | ID |
|:------:|:------|:---|
| ✅ | Poison | rbxassetid://9117168972 |
| ✅ | Acid | rbxassetid://138081500 |

---

# 👹 ZOMBIE SOUNDS

| Status | Sound | Notes |
|:------:|:------|:------|
| ❌ | Runner Groan | Fast zombie |
| ❌ | Shooter Attack | Ranged attack |
| ❌ | Tank Roar | Heavy zombie |
| ❌ | Death Sound | Zombie killed |
| ❌ | Spawn Sound | Emerging |
| ❌ | Hit Reaction | Taking damage |

---

# 🌍 AMBIENT SOUNDS

## Lobby
| Status | Sound | Notes |
|:------:|:------|:------|
| ❌ | Crickets | Night ambience |
| ❌ | Wind (Gentle) | Outdoor |
| ❌ | Fire Crackling | Campfire |
| ❌ | Distant Birds | Morning |
| ❌ | Radio Static | Occasional |
| ❌ | Wood Creaking | House |

## ACT 1: Village
| Status | Sound | Notes |
|:------:|:------|:------|
| ❌ | Wind (Eerie) | Constant |
| ❌ | Rustling Leaves | Trees |
| ❌ | Distant Groans | Atmosphere |
| ❌ | Generator Hum | Near generator |

---

# 🎵 MUSIC

## Lobby
| Status | Track | Notes |
|:------:|:------|:------|
| ❌ | Main Theme | Cozy, hopeful |
| ❌ | Safe Zone | Calm, peaceful |

## ACT 1: Village
| Status | Track | Notes |
|:------:|:------|:------|
| ❌ | Exploration | Tense, curious |
| ❌ | Combat (Normal) | Action |
| ❌ | Combat (Intense) | High wave |
| ❌ | Boss Theme 1 | Plague Titan |
| ❌ | Boss Theme 2 | Hive Mother |
| ❌ | Boss Theme 3 | Blighted Alchemist |
| ❌ | Victory | Triumphant |
| ❌ | Game Over | Somber |

---

# 🖥️ UI SOUNDS

| Status | Sound | Trigger |
|:------:|:------|:--------|
| ❌ | Button Click | Menu interaction |
| ❌ | Button Hover | Mouse over |
| ❌ | Purchase | Shop buy |
| ❌ | Error | Invalid action |
| ❌ | Notification | Alert popup |
| ❌ | Level Up | XP gained |
| ❌ | Achievement | Unlock |
| ❌ | Wave Start | New wave |
| ❌ | Wave Complete | Wave cleared |
| ❌ | Objective Start | New objective |
| ❌ | Objective Complete | Success |

---

# 💬 VOICE LINES (FUTURE)

## NPCs
| Status | NPC | Notes |
|:------:|:----|:------|
| ❌ | Alexander | Mission briefings |
| ❌ | Quartermaster | Shop greetings |
| ❌ | Doc | Medical tips |
| ❌ | Rosco | Child innocence |
| ❌ | Gramps | Veteran wisdom |

## Boss Dialogue
| Status | Boss | Notes |
|:------:|:-----|:------|
| ❌ | Plague Titan | Mid-fight lines |
| ❌ | Hive Mother | Mid-fight lines |
| ❌ | Blighted Alchemist | Mid-fight lines |

---

# 🎨 AUDIO STYLE GUIDE

## Volume Levels
| Category | Volume |
|:---------|:-------|
| Music | 0.3-0.5 |
| Ambient | 0.4-0.6 |
| Weapons | 0.7-0.9 |
| UI | 0.5-0.7 |
| Voice | 0.8-1.0 |

## Distance Settings (3D Audio)
| Category | Max Distance |
|:---------|:-------------|
| Weapons | 100 studs |
| Zombies | 80 studs |
| Ambient | 50 studs |
| Boss | 200 studs |

## Technical Notes
- Use `RollOffMode = Enum.RollOffMode.InverseTapered`
- Auto-cleanup sounds after `Ended` event
- Pool frequently used sounds
- Randomize pitch ±10% for variety

---

# 📊 PROGRESS SUMMARY

| Category | Done | Total | % |
|:---------|:-----|:------|:--:|
| Weapon Sounds | 7 | 7 | 100% |
| Element Sounds | 4 | 8 | 50% |
| Boss Sounds | 3 | 3 | 100% |
| VFX Sounds | 2 | 2 | 100% |
| Zombie Sounds | 0 | 6 | 0% |
| Ambient Sounds | 0 | 10 | 0% |
| Music | 0 | 10 | 0% |
| UI Sounds | 0 | 11 | 0% |
| Voice Lines | 0 | 8 | 0% |
| **TOTAL** | **16** | **65** | **25%** |

> ✅ = Done | ❌ = Todo
