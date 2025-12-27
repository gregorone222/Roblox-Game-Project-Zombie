# ✨ VFX Master Guide

Master list semua Visual Effects yang dibutuhkan untuk game.

> 📎 Lihat juga: [Asset Master Guide](asset-master-guide.md) | [UI Master Guide](ui-master-guide.md)

---

# 🔥 ELEMENT VFX

| Status | Element | Script | Effects |
|:------:|:--------|:-------|:--------|
| ✅ | Fire | FireVFXModule | Burn particles, flame trail |
| ✅ | Ice | IceVFXModule | Frost particles, freeze effect |
| ✅ | Shock | ShockVFXModule | Lightning bolts, static sparks |
| ✅ | Poison | PoisonVFXModule | Toxic bubbles, green mist |
| ✅ | Earth | EarthVFXModule | Rock debris, ground cracks |
| ✅ | Wind | WindVFXModule | Air swirls, dust particles |
| ✅ | Light | LightVFXModule | Holy glow, light beams |
| ✅ | Dark | DarkVFXModule | Shadow tendrils, void particles |

---

# 👹 ZOMBIE VFX

## Regular Zombies
| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Shooter Attack | ShooterVFXModule | Ranged projectile |
| ✅ | Acid Spit | AcidSpitVFX | Spitter attack |
| ❌ | Runner Trail | - | Speed lines |
| ❌ | Tank Charge | - | Ground shake |
| ❌ | Death Dissolve | - | Zombie death effect |
| ❌ | Spawn Emerge | - | Zombie spawn from ground |

## Boss 1: Plague Titan
| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Plague Titan VFX | Boss1VFXModule | Main boss effects |
| ✅ | Corrosive Slam | CorrosiveSlamVFX | Ground slam attack |
| ✅ | Fission Barrage | FissionBarrageVFX | Ranged attack |
| ✅ | Timeout Effect | Boss1TimeoutVFX | Phase timeout |
| ✅ | Void Meteor | VoidMeteorVFX | Special attack |
| ❌ | Radiation Aura | - | Passive damage zone |

## Boss 2: Hive Mother
| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Hive Mother VFX | Boss2VFXModule | Main boss effects |
| ✅ | Larva Spawn | LarvaSpawnVFX | Minion spawn effect |
| ✅ | Toxic Cloud | ToxicCloudVFX | Area denial |
| ✅ | Phase Transition | HiveMotherTransitionVFX | Phase change |
| ❌ | Protective Cocoon | - | Shield effect |

## Boss 3: Blighted Alchemist
| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Alchemist VFX | Boss3VFXModule | Main boss effects |
| ✅ | Syringe Volley | SyringeVolleyVFX | Ranged attack |
| ✅ | Volatile Minion | VolatileMinionVFX | Minion effects |
| ❌ | Plague Bomb | - | Area explosion |
| ❌ | Formula Switch | - | Element change effect |

## Shared Boss VFX
| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Phase Transition | BossPhaseTransitionVFX | All bosses |
| ✅ | Boss VFX Handler | BossVFXHandler | Client controller |

---

# 🔫 COMBAT VFX

## Weapon Effects
| Status | VFX | Notes |
|:------:|:----|:------|
| ✅ | Muzzle Flash | All weapons |
| ✅ | Bullet Tracer | Visible projectile |
| ✅ | Shell Casing | Ejected casings |
| ✅ | Impact Spark | Hit surface |
| ❌ | Reload Animation | Magazine change |

## Hit Effects
| Status | VFX | Notes |
|:------:|:----|:------|
| ✅ | Blood Splatter | Stylized (on hit) |
| ✅ | Hitmarker | UI feedback |
| ❌ | Critical Hit | Special effect |
| ❌ | Headshot | Bonus effect |
| ❌ | Kill Effect | Enemy death |

## Explosion Effects
| Status | VFX | Notes |
|:------:|:----|:------|
| ❌ | Grenade Explosion | Area damage |
| ❌ | Barrel Explosion | Destructible |
| ❌ | Drone Explosion | ACT 4 enemy |

---

# 🌍 ENVIRONMENT VFX

## Lobby
| Status | VFX | Notes |
|:------:|:----|:------|
| ❌ | Fireflies | Ambient particles |
| ❌ | Campfire Smoke | Fire pit |
| ❌ | God Rays | Volumetric light |
| ❌ | Dust Motes | Indoor particles |

## ACT 1: Village
| Status | VFX | Notes |
|:------:|:----|:------|
| ✅ | Falling Leaves | Autumn atmosphere |
| ❌ | Fog/Mist | Ground fog |
| ❌ | Wind Grass | Grass movement |
| ❌ | Radio Tower Light | Blinking beacon |

## General Environment
| Status | VFX | Notes |
|:------:|:----|:------|
| ❌ | Rain | Weather system |
| ❌ | Lightning Flash | Storm weather |
| ❌ | Fire (Props) | Burning debris |
| ❌ | Smoke (Props) | Damaged objects |
| ❌ | Sparks | Electrical |

---

# 📸 CAMERA EFFECTS

| Status | VFX | Script | Notes |
|:------:|:----|:-------|:------|
| ✅ | Camera Effects | CameraEffects | Base controller |
| ✅ | Screen Shake | - | Explosion, boss |
| ✅ | Damage Flash | - | Red screen overlay |
| ❌ | Motion Blur | - | Sprint effect |
| ❌ | Depth of Field | - | Aim down sights |
| ❌ | Vignette | - | Low health |

---

# 🎯 OBJECTIVE VFX

| Status | VFX | Notes |
|:------:|:----|:------|
| ❌ | Objective Marker | Floating icon |
| ❌ | Defend Zone | Circle indicator |
| ❌ | Collection Glow | Pickup highlight |
| ❌ | Escort Path | NPC direction |
| ❌ | Complete Burst | Success particles |

---

# 🎨 VFX STYLE GUIDE

## Color Palette
| Element | Primary Color | Secondary |
|:--------|:--------------|:----------|
| Fire | Orange #FF6B35 | Yellow #FFD93D |
| Ice | Cyan #6DD5ED | White #FFFFFF |
| Shock | Yellow #FFE66D | Blue #4ECDC4 |
| Poison | Green #2ECC71 | Purple #9B59B6 |
| Earth | Brown #8B4513 | Grey #696969 |
| Wind | White #F5F5F5 | Cyan #E0FFFF |
| Light | Gold #FFD700 | White #FFFFFF |
| Dark | Purple #4A0080 | Black #1A1A2E |

## Animation Guidelines
- **Duration:** 0.3-1.5 seconds
- **Particles:** Max 50 per emitter
- **Trails:** Fade over 0.5s
- **Loops:** Avoid infinite (performance)
- **LOD:** Reduce at distance

## Performance Rules
1. Particles auto-destroy after lifetime
2. Maximum 200 active particles per player
3. Disable VFX at low graphics settings
4. Use billboards over 3D meshes
5. Pool and reuse effects

---

# 📊 PROGRESS SUMMARY

| Category | Done | Total | % |
|:---------|:-----|:------|:--:|
| Element VFX | 8 | 8 | 100% |
| Zombie VFX | 2 | 6 | 33% |
| Boss 1 VFX | 5 | 6 | 83% |
| Boss 2 VFX | 4 | 5 | 80% |
| Boss 3 VFX | 3 | 5 | 60% |
| Combat VFX | 5 | 10 | 50% |
| Environment VFX | 1 | 13 | 8% |
| Camera Effects | 3 | 6 | 50% |
| Objective VFX | 0 | 5 | 0% |
| **TOTAL** | **31** | **64** | **48%** |

> ✅ = Done | ❌ = Todo
