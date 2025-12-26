# ✨ VFX Development Workflow

Alur kerja standar untuk pembuatan Visual Effects (VFX).

## 🔄 Ringkasan Alur Kerja
1. **Conceptualization:** Tentukan emosi/tujuan efek
2. **Asset Generation:** Buat tekstur partikel
3. **Emitter Configuration:** Atur properti di Studio
4. **Scripting Integration:** Bungkus dalam ModuleScript
5. **Performance Tuning:** Optimasi untuk mobile

---

## 1. Conceptualization

### Visual Pillars

**Environment: "Ethereal & Bittersweet"**
- Reference: Fortnite Save The World
- Vibe: Sunset, Twilight, Golden Hour
- Feeling: Nostalgia

**Combat: "Visceral & Punchy"**
- Reference: Overwatch (Junkrat/Pharah)
- Technique: Cleaner is Better
- Feeling: Satisfying impact

## 2. Asset Generation

| Format | Usage |
|:-------|:------|
| Single Texture | Asap, debu, cahaya statis |
| Flipbook (NxN Grid) | Ledakan, api, animasi kompleks |

- **Style:** Stylized/Cartoon (Hand-painted)
- **Background:** Hitam (Additive) atau transparan

## 3. Emitter Configuration

### Key Properties
| Property | Usage |
|:---------|:------|
| `Transparency` Sequence | Fade in → Stay → Fade out |
| `LightEmission = 1` | Efek bercahaya (api/laser) |
| `Drag` | Simulasi gesekan udara |
| `Acceleration` | Gravitasi (darah jatuh) |

## 4. Scripting Integration

```lua
function VFXManager:PlayEffect(effectName, position, normal)
    local template = ReplicatedStorage.VFX[effectName]
    local clone = template:Clone()
    clone.Parent = workspace.FXFolder
    Debris:AddItem(clone, 5)
    
    for _, emitter in pairs(clone:GetChildren()) do
        if emitter:IsA("ParticleEmitter") then
            emitter:Emit(emitter:GetAttribute("EmitCount") or 10)
        end
    end
end
```

## 5. Hitscan Weapon VFX

### Muzzle Flash
- Parent langsung ke part `Muzzle` (no weld)
- Menghindari Physics Drag saat bergerak

### Bullet Tracer
- Solid core + tapered tail
- Gold → Orange, `LightEmission = 1`
- Client-Authoritative Spread

### Bullethole
- Sticker Part dengan Decal
- `CFrame.lookAt(pos, pos + normal)`

## 6. Performance Tuning

| Rule | Guideline |
|:-----|:----------|
| Limit Rate | Gunakan `Emit()` manual |
| Short Lifetime | Max 1-2 detik untuk combat |
| Texture Size | Max 512x512 px |
| Avoid Overdraw | Lebih sedikit tapi lebih besar |