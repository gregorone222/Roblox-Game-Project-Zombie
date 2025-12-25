---
description: Panduan pembuatan struktur bangunan dengan createPart dan createWedge
---

# 🏗️ Builder Script Workflow

Panduan untuk menghindari kesalahan umum saat membuat bangunan di Lua.

---

## 🔺 A-Frame Roof Pattern (RECOMMENDED)

### Masalah Umum dengan Roof yang Overlap
Dua roof slopes yang bertemu di tengah akan menyebabkan **Z-fighting** (visual bug).

### ✅ Solusi: Gap + Ridge Cap

```lua
-- 1. Roof slopes LEBIH PENDEK agar tidak bertemu
local roofSlopeWidth = buildingWidth/2 - 2  -- Dikurangi agar ada gap

-- 2. Posisikan ke LUAR dari center
-- Kiri: origin.X - width/4 - 3 (geser ke kiri)
-- Kanan: origin.X + width/4 + 3 (geser ke kanan)

-- 3. Ridge cap LEBIH LEBAR untuk menutupi gap
createPart("RoofRidge", Vector3.new(12, 3, depth), ...)  -- Lebar 12+ studs
```

### Contoh Lengkap
```lua
-- Roof slopes dengan gap
local roofSlopeWidth = width/2 - 2
local roofAngle = math.rad(22)

-- Left roof - ends BEFORE center
createPart("RoofLeft", Vector3.new(roofSlopeWidth, 2, depth + 4), 
    CFrame.new(origin.X - width/4 - 3, floorY + height + 3, origin.Z) 
    * CFrame.Angles(0, 0, roofAngle), ...)

-- Right roof - ends BEFORE center  
createPart("RoofRight", Vector3.new(roofSlopeWidth, 2, depth + 4), 
    CFrame.new(origin.X + width/4 + 3, floorY + height + 3, origin.Z) 
    * CFrame.Angles(0, 0, -roofAngle), ...)

-- Ridge cap - WIDE enough to cover gap
createPart("RoofRidge", Vector3.new(12, 3, depth + 4), 
    CFrame.new(origin.X, floorY + height + 6, origin.Z), ...)
```

### Diagram
```
     ___________    <- Ridge cap (lebar 12+)
    /     |     \
   /      |      \  <- Gap di tengah
  /       |       \
 /________|________\
 ^        ^        ^
 |        |        |
Left    Gap     Right
slope  (ditutup  slope
       ridge)
```

---

## 🚫 Jangan Gunakan WedgePart untuk Atap

WedgePart orientasinya membingungkan. Gunakan Part + CFrame.Angles.

---

## 📏 Ketebalan Part

### ❌ Masalah: Part Terlalu Tipis
```lua
-- SALAH: Ketebalan 0.2 atau 1 terlalu tipis, akan tembus
Vector3.new(20, 0.2, 20) -- Tembus/tidak solid
```

### ✅ Solusi: Minimum 1.5-2 Studs
```lua
-- BENAR: Ketebalan minimal 1.5 untuk lantai/atap
Vector3.new(20, 1.5, 20) -- Solid, tidak tembus
```

### Rekomendasi Ketebalan:
| Tipe | Ketebalan |
|------|-----------|
| Lantai | 1.5 - 2 studs |
| Dinding | 1 - 2 studs |
| Atap | 1.5 - 2 studs |
| Balok/Beam | 1 - 1.5 studs |

---

## 🧱 Wall dengan Bukaan (Pintu/Jendela)

### Pattern: Split Wall
```lua
-- Buat 3 bagian: kiri, kanan, atas bukaan
createPart("WallLeft", Vector3.new(10, height, 1), leftPos, ...)
createPart("WallRight", Vector3.new(10, height, 1), rightPos, ...)
createPart("WallTop", Vector3.new(doorWidth, 3, 1), topPos, ...)
```

---

## 🔄 CFrame.Angles Cheatsheet

```lua
-- Rotasi sumbu X (pitch - tilt depan/belakang)
CFrame.Angles(math.rad(45), 0, 0)

-- Rotasi sumbu Y (yaw - putar kiri/kanan)
CFrame.Angles(0, math.rad(90), 0)

-- Rotasi sumbu Z (roll - miring samping)
CFrame.Angles(0, 0, math.rad(30))
```

---

## 🏠 Template Struktur Bangunan

```lua
local function buildHouse(parent, origin)
    local house = Instance.new("Model")
    house.Name = "House"
    house.Parent = parent
    
    local width, depth, height = 30, 20, 10
    local floorY = origin.Y
    
    -- 1. LANTAI (tebal 1.5)
    createPart("Floor", Vector3.new(width, 1.5, depth), 
        CFrame.new(origin.X, floorY, origin.Z), house, ...)
    
    -- 2. DINDING (tebal 1.5)
    createPart("WallBack", Vector3.new(width, height, 1.5), 
        CFrame.new(origin.X, floorY + height/2, origin.Z + depth/2), house, ...)
    
    -- 3. ATAP (sloped dengan Part, tebal 1.5)
    local roofAngle = math.rad(25)
    createPart("RoofL", Vector3.new(depth, 1.5, width/2), 
        CFrame.new(origin.X - width/4, floorY + height + 3, origin.Z) 
        * CFrame.Angles(0, 0, roofAngle), house, ...)
    createPart("RoofR", Vector3.new(depth, 1.5, width/2), 
        CFrame.new(origin.X + width/4, floorY + height + 3, origin.Z) 
        * CFrame.Angles(0, 0, -roofAngle), house, ...)
    
    return house
end
```

---

## ⚠️ Checklist Sebelum Test

- [ ] Ketebalan part minimal 1.5 studs
- [ ] Atap menggunakan Part + Angles, bukan Wedge
- [ ] Rotasi Z positif untuk kiri, negatif untuk kanan
- [ ] Ridge/puncak atap menutupi gap
- [ ] Test dari berbagai sudut kamera
