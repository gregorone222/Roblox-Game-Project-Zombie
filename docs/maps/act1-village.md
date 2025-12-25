# 🏚️ ACT 1 - The Cursed Village

Ground Zero - Lokasi eksperimen awal. Desa yang pernah damai, sekarang dikuasai oleh tanaman liar dan kenangan yang ditinggalkan.

> 📎 Lihat juga: [Story](../story/story.md) | [Characters](../entities/characters.md) | [Asset Checklist](../design/asset-checklist.md)

---

## 📋 Info Dasar

| Property | Value |
|:---------|:------|
| **Place ID** | `91523772574713` |
| **Script** | `MapBuilderVillage.lua` |
| **Theme** | Cursed Village (Cozy Apocalypse - Overgrown) |
| **Atmosphere** | Golden Hour → Night progression |
| **Size** | 400 x 400 studs |

---

## 🗺️ Layout Overview

```
                    [FOREST RING]
                         ↑
    ┌────────────────────────────────────────┐
    │              OUTER TREES               │
    │  ┌──────────────────────────────────┐  │
    │  │                                  │  │
    │  │   [HOUSES]          [HOUSES]     │  │
    │  │      🏠                🏠         │  │
    │  │                                  │  │
    │  │         ┌──────────┐            │  │
    │  │   🏠    │  TOWN    │     🏠      │  │
    │  │         │  SQUARE  │            │  │
    │  │         │  📡      │            │  │
    │  │         │Radio Tower│            │  │
    │  │         └──────────┘            │  │
    │  │                                  │  │
    │  │   [HOUSES]          [HOUSES]     │  │
    │  │      🏠                🏠         │  │
    │  │                                  │  │
    │  └──────────────────────────────────┘  │
    │              OUTER TREES               │
    └────────────────────────────────────────┘
              [ZOMBIE SPAWN POINTS]
```

---

## 🏗️ AREAS (Detail)

### 1. Town Square (Center)
**Location:** Map center (0, 0, 0)  
**Size:** 80 x 80 studs

**Structures:**
- Radio Tower (objective point)
- Pavement (concrete)
- Street Lamps (4 unit, warm light)

**Purpose:**
- Primary defend zone
- Wave 22: Defend Mission location
- Central hub for player orientation

---

### 2. Residential Ruins (Ring)
**Location:** Ring sekitar Town Square (radius ~70 studs)  
**Count:** 12 houses

**House Features:**
| Element | Description |
|:--------|:------------|
| Floor | Kayu, intact |
| Walls | 80% chance intact per wall |
| Roof | Wedge shape, terracotta color |
| Interior | Destructible table & chairs |

**Props di House:**
- [ ] Destructible Table
- [ ] Destructible Chairs (1-2 per house)
- [ ] Spawn_Gas attachment (scavenge objective)

---

### 3. The Forest (Outer Ring)
**Location:** Ring terluar (radius 100-190 studs)  
**Tree Count:** 40 trees

**Tree Features:**
| Element | Description |
|:--------|:------------|
| Trunk | Kayu dengan moss patches |
| Canopy | Green ball (alive, overgrown) |
| Branches | 3-5 dengan leaf clusters |
| Ivy | Hanging ivy (50% chance) |

**Purpose:**
- Zombie spawn areas
- Wave 38: Sample retrieval location
- Visual boundary

---

## 🧸 NOSTALGIC/STORYTELLING PROPS

Props dengan environmental storytelling (sama seperti Lobby tapi scattered):

| Prop | Location | Quantity |
|:-----|:---------|:---------|
| **Empty Swing** | Near town square (35, 0, 25) | 1 |
| **Abandoned Teddy** | Scattered near houses | 2 |
| **Old Radio** | Near Radio Tower | 1 |
| **Broken Bicycle** | Scattered | 2 |

---

## 🎯 WAVE OBJECTIVES

### Wave 8: Scavenge Mission
**Objective:** Collect Gas Canisters  
**Spawn Points:** Inside houses (Spawn_Gas attachments)

| Requirement | Value |
|:------------|:------|
| Items to collect | 5 Gas Canisters |
| Time limit | 3 minutes |
| Location | Random houses |

---

### Wave 22: Defend Mission
**Objective:** Defend Radio Tower during data upload  
**Zone:** Town Square center (Zone_Defend attachment)

| Requirement | Value |
|:------------|:------|
| Defend time | 2 minutes |
| Zone radius | ~20 studs from tower |
| Fail condition | All players leave zone |

---

### Wave 38: Retrieve Mission
**Objective:** Retrieve virus sample from forest  
**Spawn Points:** Near trees (Spawn_Sample attachments)

| Requirement | Value |
|:------------|:------|
| Items to collect | 1 Sample Container |
| Time limit | 4 minutes |
| Location | Random forest area |

---

## 👹 BOSS ENCOUNTERS

### Wave 10-15: Plague Titan
**Spawn:** Town Square edge  
**HP:** 75,000

**Arena Setup:**
- Clear space needed
- Players can use houses for cover
- Radiation aura requires movement

---

### Wave 30-35: Hive Mother
**Spawn:** Near forest edge  
**HP:** 100,000

**Arena Setup:**
- Open area for larva spawns
- Acid pools create hazard zones
- Trees provide partial cover

---

### Wave 50: Blighted Alchemist (Final)
**Spawn:** Radio Tower platform  
**HP:** 125,000

**Arena Setup:**
- Town Square becomes arena
- Chemical hazards throughout
- Tower becomes tactical point

---

## 💡 LIGHTING PROGRESSION

ACT 1 menggunakan **Progressive Day Cycle** yang berubah seiring wave:

| Wave Range | Time of Day | ClockTime | Atmosphere |
|:-----------|:------------|:----------|:-----------|
| 1-10 | Morning | 6-8 | Warm, hopeful, clear |
| 11-25 | Afternoon | 8-14 | Bright, energetic |
| 26-40 | Golden Hour | 14-17 | Warm sunset, nostalgic |
| 41-50 | Dusk/Night | 17-20 | Darker, tense, final |

### Light Sources

| Source | Location | Color |
|:-------|:---------|:------|
| Street Lamps (4) | Around Town Square | Warm orange |
| Radio Tower Blinker | Top of tower | Red (blinking) |
| House Windows | Scattered | Faint warm glow |

### Atmospheric Effects

| Effect | Description |
|:-------|:------------|
| **Falling Leaves** | 5 emitters across map, green-yellow-brown |
| **Morning Fog** | Light, start 20 end 400 |
| **Golden Hour Fog** | Warm tinted, thicker late game |

---

## 🔊 AMBIENT SOUNDS

| Sound | When | Location |
|:------|:-----|:---------|
| Wind | Always | Global |
| Leaves rustling | Always | Near trees |
| Distant birds | Morning/Afternoon | Global |
| Radio static | Near Radio Tower | Tower area |
| Creaking wood | Occasional | Near houses |

---

## 📐 SCALE REFERENCE

```
Town Square:    80W x 80D studs
Houses:         15-25W x 15-25D x 12H studs per house (varies)
Radio Tower:    8W x 8D x 45H studs
Trees:          Height 12-20 studs, canopy 8-12 diameter
Forest Ring:    100-190 stud radius
Map Total:      400 x 400 studs
```

---

## 📋 ACT 1 ASSET CHECKLIST

### Structures
- [x] Town Square pavement
- [x] Radio Tower
- [x] Ruined Houses (12)
- [x] Street Lamps (4)
- [x] Invisible barriers

### Trees/Nature
- [x] Overgrown Trees (40)
- [x] Moss patches
- [x] Hanging ivy
- [x] Leaf canopy

### Furniture (In Houses)
- [x] Destructible Table
- [x] Destructible Chairs

### Nostalgic Props
- [x] Empty Swing
- [x] Abandoned Teddy (2)
- [x] Old Radio
- [x] Broken Bicycle (2)

### Particles
- [x] Falling Leaves emitters (5)

### Objectives
- [x] Spawn_Gas attachments
- [x] Zone_Defend attachment
- [x] Spawn_Sample attachments

### Bosses
- [ ] Plague Titan (model)
- [ ] Hive Mother (model)
- [ ] Blighted Alchemist (model)

### Audio
- [ ] Forest ambient
- [ ] Radio Tower static
- [ ] Boss entry sounds
- [ ] Wave objective announcements

---

## 📝 Implementation Notes

### Dari `MapBuilderVillage.lua`:
- Houses dihasilkan procedurally dengan variasi
- 20% chance wall hilang untuk "ruined" effect
- Trees sekarang "overgrown" bukan "dead"
- Warna palette: Cozy Apocalypse (warm, not grimy)

### Style Consistency:
- Visual tetap **Fortnite/Overwatch stylized**
- Meskipun "cursed village", tetap colorful
- Trees ALIVE (overgrown) bukan mati

---

*"Desa ini pernah penuh dengan tawa anak-anak. Sekarang hanya angin dan daun yang berbisik."*  
— Alexander
