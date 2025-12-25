# 🌫️ Environment Development Workflow

Prosedur standar untuk membangun dunia (Level Design & Atmosphere).

## 🔄 Ringkasan Alur Kerja
1. **Atmosphere Setup:** Lighting, Skybox, Fog
2. **Geometry Pass:** Terrain, Gedung
3. **Prop Placement:** Detail objects
4. **Ambient FX:** Partikel, suara lingkungan

---

## 1. Atmosphere (The "Vibe")

### Visual Pillar: "Ethereal & Bittersweet"
- **Time of Day:** Sunset / Twilight (Golden Hour)
- **Sky:** Gradasi Ungu ke Oranye
- **Fog:** Pink/Lavender lembut, bercahaya
- **Reference:** Fortnite Save The World

### Technical Settings

```lua
-- Lighting Service
Technology = "Future" atau "ShadowMap"
OutdoorAmbient = Color3.fromRGB(80, 70, 100)
Brightness = 2
ClockTime = 17.5

-- Effects
Atmosphere.Haze = 2.0  -- High for volumetric
ColorCorrection.Contrast = 0.1
ColorCorrection.Saturation = 0.2
Bloom.Intensity = 0.3  -- Low
SunRays.Enabled = true  -- God rays
```

---

## 2. Props & Set Dressing

### Cover & Combat Assets
- **Function over Form:** Furniture = valid Cover
- **Destructibility:** Beberapa objek bisa hancur
- **Flow:** Jangan hambat pergerakan kiting

### Environmental Storytelling
Gunakan area Out of Bounds:
- Gedung terbakar di kejauhan
- Konvoi militer hancur
- Poster propaganda pudar

---

## 3. Ambient FX

| Effect | Description |
|:-------|:------------|
| Dust Motes | Debu melayang (kena sinar matahari) |
| Falling Leaves | Daun kering jatuh perlahan |
| Sparks/Drips | Percikan listrik, tetesan air |

> Lihat `vfx-development.md` untuk cara teknis membuat partikel
