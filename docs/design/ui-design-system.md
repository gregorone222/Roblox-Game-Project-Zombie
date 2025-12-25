# 🖥️ UI Design System

Aturan pengembangan User Interface untuk menjaga konsistensi visual.

## Visual Design Guidelines

| Aspect | Guideline |
|:-------|:----------|
| **Theme** | Makeshift Survivor Camp (Stylized Post-Apocalypse) |
| **Primary Colors** | Warm Brown, Forest Green, Sunset Orange |
| **Accent Colors** | Bright Yellow, Soft Cyan |
| **Alert Colors** | Soft Red, Orange (hindari warna darah gelap) |
| **Shape Language** | Rounded Corners (8-12px), tekstur kayu/kain subtle |

---

## Standard Dimensions

### Safe Zone
- **Max Size:** Scale 0.9 (90% Layar)
- **Margin:** Minimal 5% (Scale 0.05) dari setiap sisi

### Touch Target Size
- **Minimum:** 44x44 pixels
- **Ideal:** 60x60 pixels
- **Padding:** 10px antar tombol

### Aspect Ratio Presets
| Type | Ratio | Example |
|:-----|:------|:--------|
| Landscape Window | 16:9 (~1.77) | Shop, Map |
| Portrait Card | 2:3 (~0.66) | Item Info |
| Square Icon | 1:1 (1.00) | Icons |

---

## Typography

| Usage | Font | Size |
|:------|:-----|:-----|
| **Header** | Luckiest Guy / FredokaOne | Max 32px (mobile) |
| **Body** | GothamMedium / SemiBold | Max 20px (mobile) |
| **Button** | GothamMedium | Max 24px |

### Text Rules
- Gunakan `TextScaled` dengan `UITextSizeConstraint`
- MinTextSize: 14, MaxTextSize: 48

---

## UI Standards

### Scale Over Offset
- Semua elemen **WAJIB** menggunakan `Scale`
- `Offset` hanya untuk border/padding kecil

### Mobile Support
- Cek `TouchEnabled`
- Perbesar tombol pada layar mobile (Safe Padding 15%)

### ZIndex Layers
| Range | Usage |
|:------|:------|
| 0-10 | Backgrounds, Panels, Shadows |
| 11-50 | Main Content (Buttons, Text) |
| 100+ | Overlays (Popups, Modals) |
| 1000+ | Global Effects (Flash, Loading) |

---

## Naming Conventions

| Prefix | Element |
|:-------|:--------|
| `btn_` | Button |
| `lbl_` | Text/ImageLabel |
| `fr_` | Frame |
| `sc_` | ScrollingFrame |

---

## Modular Asset Strategy

### ✅ Correct (Modular)
```
Frame_Kayu_A.png
Tombol_Merah_B.png
Ikon_Senjata_C.png
```

### ❌ Wrong (Full Image)
```
Shop_Menu_Full_Design.png  (Teks dan tombol menyatu)
```

## Asset Preparation

- **Background Removal:** Hasil akhir WAJIB transparan (.PNG)
- **Resolution:** Panel besar 1024x1024px, Ikon 500x500px
- **Engine Effects:** Gunakan UIStroke, UIGradient di Roblox, bukan baked
