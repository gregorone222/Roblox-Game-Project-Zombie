# 🎨 UI Icon Prompt Guide

Panduan prompt untuk generate UI icons menggunakan AI image generator.

> 📎 Lihat juga: [Asset Master Guide](asset-master-guide.md) | [UI Master Guide](ui-master-guide.md)

---

## 🎯 Art Direction Reminder

### ✅ ALLOWED
- Kayu, kain, logam berkarat, tanaman merambat
- Radio tua, generator bensin, kabel warna-warni
- Warm colors (sunset orange, forest green, wood brown)
- "Cozy Apocalypse" - makeshift survivor aesthetic

### ❌ FORBIDDEN
- Hologram, neon grid, laser, panel digital futuristik
- Warna biru dingin steril, chrome/metal bersih
- Alien, cyborg, teknologi sci-fi

---

## 📝 Prompt Template

### Base Structure
```
[Item Name] [visual description] icon for survival game, 
[detailed material and construction description], 
[lighting and glow effects], 
Fortnite and Overwatch polished 3D art style, 
soft diffused cel-shaded lighting from above, 
warm color palette with [specific colors], 
object floating with slight 15 degree tilt angle, 
completely clean solid dark charcoal gray background with no patterns or gradients, 
high quality game UI icon render, no text no labels
```

### Required Keywords
| Keyword | Purpose |
|:--------|:--------|
| `stylized 3D` | Ensures 3D render style |
| `Fortnite and Overwatch polished 3D art style` | Art direction |
| `soft diffused cel-shaded lighting` | Lighting style |
| `warm color palette` | Color theme |
| `slight 15 degree tilt angle` | Consistent angle |
| `solid dark charcoal gray background` | Clean background |
| `no patterns or gradients` | Prevents checkered bg |
| `game UI icon render` | Output type |
| `no text no labels` | Clean icon |

### Forbidden Keywords
- ~~transparent background~~ (causes checkered pattern)
- ~~animated~~
- ~~holographic~~
- ~~neon~~
- ~~sci-fi~~
- ~~futuristic~~
- ~~photorealistic~~

---

## 🏆 Example: Iron Will Perk Icon

### Visual Concept
- **Perk:** Iron Will (HP Plus)
- **Effect:** Max Health +30%
- **Symbol:** Heart ❤️
- **Theme:** Rugged protection, survivor resilience

### Full Prompt
```
Iron Will perk icon for survival game, a stylized 3D heart symbol made of 
rusted metal plates bolted together with rivets, wrapped with worn leather 
straps and bandages, reinforced with makeshift armor padding, glowing warm 
orange inner light showing through the cracks, Fortnite and Overwatch polished 
3D art style, soft diffused cel-shaded lighting from above, warm color palette 
with sunset orange rust brown and copper tones, object floating with slight 
15 degree tilt angle, completely clean solid dark charcoal gray background 
with no patterns or gradients, high quality game UI icon render, no text no labels
```

### Prompt Breakdown
| Aspect | Description |
|:-------|:------------|
| **Subject** | Heart symbol made of rusted metal plates |
| **Materials** | Bolted with rivets, leather straps, bandages, armor padding |
| **Lighting** | Warm orange inner glow through cracks |
| **Art Style** | Fortnite/Overwatch polished 3D, cel-shaded |
| **Colors** | Sunset orange, rust brown, copper |
| **Angle** | 15 degree tilt, floating |
| **Background** | Solid dark charcoal gray, no patterns |
| **Output** | Game UI icon, no text |

---

## 📋 Perk Icons Checklist

| Status | Perk | Display Name | Symbol | Prompt Ready |
|:------:|:-----|:-------------|:-------|:------------:|
| ❌ | HP Plus | Iron Will | ❤️ Heart | ✅ |
| ❌ | Stamina Plus | Second Wind | 🏃 Boots | ⏳ |
| ❌ | Reload Plus | Dexterity | ✋ Hand | ⏳ |
| ❌ | RateBoost | Adrenaline | 🔥 Flame | ⏳ |
| ❌ | Revive Plus | Humanity | 🤝 Hands | ⏳ |
| ❌ | Medic | Field Medic | 💚 Medical | ⏳ |

---

## 🔧 Workflow

1. **Copy prompt** dari contoh di atas
2. **Sesuaikan** subject dan material untuk item yang berbeda
3. **Generate** menggunakan AI image generator
4. **Review** hasil, iterasi jika perlu
5. **Export** sebagai PNG dengan background transparan (edit manual)
6. **Upload** ke Roblox dengan size 512x512 atau 1024x1024

---

## 📐 Technical Specifications

| Spec | Value |
|:-----|:------|
| **Resolution** | 512x512 atau 1024x1024 px |
| **Format** | PNG (transparan setelah edit) |
| **Aspect Ratio** | 1:1 (Square) |
| **Color Mode** | RGB |
| **Background** | Remove setelah generate |
