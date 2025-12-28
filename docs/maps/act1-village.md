# 🏚️ ACT 1 - The Cursed Village

Desa misterius yang menjadi lokasi pertama wabah. Tidak ada yang tahu bagaimana ini dimulai.

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

### 1. Village Square (Center)
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
**Location:** Ring sekitar Village Square (radius ~70 studs)  
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

## 🎯 WAVE OBJECTIVES (4 per ACT)

> **Note:** Setiap ACT memiliki 4 objectives yang tersebar merata untuk variasi gameplay.

### Wave 10: Scavenge Mission
**Objective:** Collect Fuel Cans & Refuel Generator  
**Spawn Points:** Inside houses (Spawn_Gas attachments)  
**Reward:** 500 Valor

| Requirement | Value |
|:------------|:------|
| Items to collect | 3 Fuel Cans |
| Time limit | 2 minutes |
| Location | Random houses |
| Delivery | Generator di Village Square |

---

### Wave 20: Defend Mission
**Objective:** Defend Radio Tower during signal boost  
**Zone:** Village Square center (Zone_Defend attachment)  
**Reward:** 750 Valor

| Requirement | Value |
|:------------|:------|
| Defend time | 90 seconds |
| Zone radius | ~20 studs from tower |
| Bonus | +10% speed per extra player in zone |

---

### Wave 35: Escort Mission (NEW)
**Objective:** Escort injured survivor to safe zone  
**Start:** Forest edge (Spawn_Survivor attachment)  
**Reward:** 1000 Valor

| Requirement | Value |
|:------------|:------|
| NPC Health | 500 HP (must survive) |
| Destination | Radio Tower |
| NPC Speed | 50% player speed |
| Fail condition | NPC dies |

**Mechanic:**
- Survivor NPC follows closest player
- Zombies will prioritize attacking NPC
- Players must protect while guiding to safety

---

### Wave 45: Retrieve Mission
**Objective:** Retrieve medical records from village clinic  
**Spawn Points:** Village clinic building (Spawn_Records attachment)  
**Reward:** 1250 Valor

| Requirement | Value |
|:------------|:------|
| Items to collect | 1 Medical Records Box |
| Hold duration | 4 seconds (interruptible) |
| Time limit | 3 minutes |
| Location | Inside locked building (door opens on objective start) |

---

## 📊 Objectives Summary

| Wave | Type | Difficulty | Reward |
|:-----|:-----|:-----------|:-------|
| 10 | SCAVENGE | Easy | 500 Valor |
| 20 | DEFEND | Medium | 750 Valor |
| 35 | ESCORT | Hard | 1000 Valor |
| 45 | RETRIEVE | Medium | 1250 Valor |

**Total Objective Rewards:** 3,500 Valor

## 👹 BOSS ENCOUNTERS

### Wave 10-15: Plague Titan
**Spawn:** Village Square edge  
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
- Village Square becomes arena
- Chemical hazards throughout
- Tower becomes tactical point

---

## 💡 LIGHTING PROGRESSION

ACT 1 menggunakan **Progressive Day Cycle** yang berubah seiring wave:

| Wave Range | Time of Day | ClockTime | Atmosphere |
|:-----------|:------------|:----------|:-----------|
| 1-10 | Morning | 6-8 | Warm, hopeful, clear |
| 11-25 | Afternoon | 8-12 | Bright, energetic |
| 26-40 | Late Afternoon | 12-15 | Warming up, tension |
| 41-50 | Golden Hour | 15-18 | Sunset glow, triumphant finish |

### Light Sources

| Source | Location | Color |
|:-------|:---------|:------|
| Street Lamps (4) | Around Village Square | Warm orange |
| Radio Tower Blinker | Top of tower | Red (blinking) |
| House Windows | Scattered | Faint warm glow |

### Atmospheric Effects

| Effect | Description |
|:-------|:------------|
| **Falling Leaves** | 5 emitters di area Forest Ring, tidak sampai tengah |
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
Village Square:    80W x 80D studs
Houses:         15-25W x 15-25D x 12H studs per house (varies)
Radio Tower:    8W x 8D x 45H studs
Trees:          Height 12-20 studs, canopy 8-12 diameter
Forest Ring:    100-190 stud radius
Map Total:      400 x 400 studs
```

---

## 📋 ACT 1 ASSET CHECKLIST

### Structures
- [x] Village Square pavement
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
