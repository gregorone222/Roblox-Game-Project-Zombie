# 🏠 Lobby - Abandoned Farmhouse

Dokumentasi lengkap environment lobby - Survivor Basecamp.

> 📎 Lihat juga: [Characters](../entities/characters.md) | [Environment Art Guide](../design/environment-art-guide.md)

---

## 📋 Info Dasar

| Property | Value |
|:---------|:------|
| **Script** | `LobbyBuilder_Farmhouse.lua` |
| **Theme** | Abandoned Farmhouse (Cozy Apocalypse) |
| **Atmosphere** | Warm, Sunset/Golden Hour, Nostalgic |
| **Size** | ~120 x 120 studs area utama |

---

## 🗺️ Layout Overview

```
                    [FOREST/TREES]
                         ↑
    ┌────────────────────────────────────────┐
    │           SURVIVOR BARRICADE           │
    │  ┌──────────────────────────────────┐  │
    │  │                                  │  │
    │  │  [GAZEBO]         [LEADERBOARD]  │  │
    │  │  Alexander            Board      │  │
    │  │                                  │  │
    │  │         [CAMPFIRE]               │  │
    │  │          Rosco                   │  │
    │  │                                  │  │
    │  │  [BARN]      [MAIN]    [MEDICAL] │  │
    │  │  Quartermaster HOUSE    Doc      │  │
    │  │               Gramps             │  │
    │  │                                  │  │
    │  │  [TRUCK]  [SWING] [BIKE]         │  │
    │  │                                  │  │
    │  └──────────────────────────────────┘  │
    │           SURVIVOR BARRICADE           │
    └────────────────────────────────────────┘
                    [ENTRANCE]
                    SPAWN POINT
```

---

## 🏗️ AREAS (Detail)

### 1. Main House
**Location:** Center-South  
**NPC:** Gramps (di porch)

**Structure:**
- Rumah kayu 2 lantai (tampilan luar saja)
- Porch dengan rocking chair
- Perapian terlihat dari jendela (warm glow)
- Atap sebagian rusak tapi di-patch

**Furniture (Visible dari luar):**
| Item | Kondisi | Lokasi |
|:-----|:--------|:-------|
| Rocking Chair | Fungsional | Porch - Gramps duduk |
| Meja Kecil | Sedikit rusak | Samping rocking chair |
| Lentera | Menyala | Digantung di porch |
| Jendela | Pecah sebagian, ditape | Depan |

**Environmental Storytelling:**
- **Family Photo** di mantel (blur faces) - visible dari jendela
- **Child's Drawing** di dinding dapur
- **Unfinished Dinner** di meja makan (4 piring)

---

### 2. Barn (Gudang)
**Location:** West  
**NPC:** Quartermaster

**Structure:**
- Gudang merah classic
- Pintu besar setengah terbuka
- Hay bales bertumpuk
- Interior setup sebagai weapon shop

**Furniture & Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Workbench | Banyak tools | Display senjata |
| Tool Rack | Penuh | Dekorasi |
| Hay Bales | Kering | Seating/cover |
| Oil Lamp | Menyala | Lighting |
| Metal Shelves | Berkarat | Storage display |
| Weapon Crates | Tertutup | Shop inventory |

---

### 3. Medical Tent
**Location:** East  
**NPC:** Doc

**Structure:**
- Tenda canvas besar (army style)
- Cross merah di canvas
- Flaps setengah terbuka

**Furniture & Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Stretcher | Bersih | Emergency bed |
| Medical Crates | Terorganisir | Supplies |
| Folding Table | Sturdy | Doc's workspace |
| IV Stand | Kosong | Dekorasi medis |
| First Aid Boxes | Bertumpuk | Shop inventory |
| Lantern | Menyala | Lighting |

---

### 4. Campfire Area
**Location:** Center  
**NPC:** Rosco

**Structure:**
- Api unggun di tengah (menyala)
- Log benches melingkar (4-6 seat)
- Area berkumpul komunal

**Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Fire Pit | Menyala | Warmth, focal point |
| Log Benches | Kasar | Seating |
| Cooking Pot | Di atas api | Dekorasi |
| Backpacks | Beberapa | Survivor belongings |
| Blankets | Di bench | Comfort |
| Rosco's Drawings | Di tanah | Easter egg hints |

---

### 5. Gazebo (Command Post)
**Location:** North-West  
**NPC:** Alexander

**Structure:**
- Gazebo kayu dengan atap
- Meja strategi di tengah
- Radio equipment

**Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Strategy Table | Map terpasang | Mission briefing |
| Radio Set | Fungsional | Communication |
| Lanterns | Multiple | Lighting |
| Corkboard | Notes & photos | Intel board |
| Chairs | 2-3 buah | Seating |

---

### 6. Leaderboard Area
**Location:** North-East

**Structure:**
- Dinding kayu dengan papan skor
- Pohon besar dengan string lights
- Bench untuk viewing

**Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Leaderboard Wall | Chalk/paint | Top players |
| String Lights | Menyala | Festive touch |
| Old Tree | Besar | Shade/atmosphere |
| Bench | Weathered | Seating |

---

### 7. Perimeter (Barricade)
**Location:** Surrounding all areas

**Structure:**
- Pagar kayu tinggi (~10 studs)
- Diperkuat dengan metal/scrap
- Watchtower di sudut (non-functional, dekorasi)

**Props:**
| Item | Kondisi | Purpose |
|:-----|:--------|:--------|
| Wooden Fence | Patchy repairs | Perimeter |
| Sandbags | Di base fence | Reinforcement |
| Barbed Wire | Atas fence | Deterrent |
| Watchtower | 2 sudut | Dekorasi |
| Warning Signs | Handmade | "SURVIVORS ONLY" |

---

## 🧸 ENVIRONMENTAL STORYTELLING PROPS

Props dengan lore significance:

| Prop | Location | Story Significance |
|:-----|:---------|:-------------------|
| **Empty Swing** | Halaman depan Main House | Anak-anak Miller - melankolis |
| **Abandoned Teddy (Bella)** | Dekat swing | Milik Sarah Miller |
| **Broken Bicycle** | Halaman samping | Childhood interrupted |
| **Old Pickup Truck** | Belakang barn | Miller's truck, kunci masih di ignition |
| **Family Photo** | Mantel (visible dari jendela) | Miller Family, Summer |
| **Last Letter** | Meja dalam rumah | Interactable - bisa dibaca |
| **Memorial Board** | Dekat leaderboard | Foto survivor yang gugur |
| **Rosco's Drawings** | Tanah dekat campfire | Cipher hints |

---

## 💡 LIGHTING

### Time of Day
- **ClockTime:** Dynamic (mengikuti UTC Time)
- **Mood:** Warm, nostalgic, safe feeling

### Light Sources

| Source | Location | Color |
|:-------|:---------|:------|
| Campfire | Center | Warm orange |
| Lanterns | Scattered | Warm yellow |
| Torches | Perimeter | Orange flicker |
| String Lights | Leaderboard tree | Warm white |
| Porch Light | Main house | Soft warm |
| Barn Interior | Through door | Warm glow |

### Atmospheric Effects

| Effect | Description |
|:-------|:------------|
| **Fireflies** | Soft floating lights di malam |
| **Falling Leaves** | Occasional dari trees |
| **Sun Rays** | God rays dari sunset |
| **Fog** | Light, start 50 end 400 |
| **Smoke** | Dari campfire, gentle rise |

---

## 🔊 AMBIENT SOUNDS

| Sound | Location | Loop |
|:------|:---------|:-----|
| Crickets | Global ambient | Yes |
| Wind (gentle) | Global | Yes |
| Fire crackling | Campfire area | Yes |
| Distant birds | Global | Yes |
| Wood creaking | Near structures | Occasional |
| Radio static | Gazebo | Occasional |

> **Note:** NO MUSIC - hanya ambient sounds

---

## 📐 SCALE REFERENCE

```
Main House:     30W x 25D x 15H studs
Barn:           25W x 30D x 18H studs
Medical Tent:   15W x 12D x 8H studs
Gazebo:         12W x 12D x 10H studs
Campfire Area:  20 diameter studs
Perimeter:      ~120 x 120 studs enclosed
```

---

## 📝 Implementation Checklist

### Structures
- [x] Main House exterior
- [x] Barn
- [x] Medical Tent
- [x] Campfire
- [x] Gazebo
- [x] Leaderboard Area
- [x] Perimeter Barricade

### NPCs (Spawn Points)
- [x] Alexander (Gazebo)
- [x] Quartermaster (Barn)
- [x] Doc (Medical Tent)
- [x] Rosco (Campfire)
- [x] Gramps (Porch)

### Storytelling Props
- [x] Empty Swing
- [x] Abandoned Teddy
- [x] Broken Bicycle
- [x] Old Pickup Truck
- [ ] Family Photo (interactable)
- [ ] Last Letter (readable)
- [ ] Memorial Board (updateable)
- [ ] Rosco's Drawings (cipher)

### Lighting & Effects
- [x] Sunset lighting
- [x] Campfire light
- [ ] String lights
- [ ] Fireflies particles
- [ ] Falling leaves
- [x] Fog
