# 🧪 Boss Skill Tester Plugin

Plugin untuk testing boss skills tanpa harus bermain hingga wave 10/30/50.

## Features

- **Boss Spawner** - Spawn boss instantly di depan player
- **Skill Buttons** - Trigger skill individual tanpa cooldown
- **God Mode** - Toggle invincibility untuk testing
- **HP Control** - Set HP ke 50%, 25%, atau kill langsung
- **Phase 2 Access** - Test phase 2 skills tanpa transisi natural

---

## 🚀 Cara Menggunakan

1. **Play Mode Required** - Tekan F5 untuk masuk Play Mode
2. Buka **Plugins > 🧪 Boss Tester**
3. Klik **⚡ Spawn** pada boss yang ingin dites
4. Klik skill buttons untuk trigger attack
5. Gunakan HP control untuk trigger phase transition

## 👹 Boss List

### Plague Titan (Boss1)
| Phase | Skills |
|:------|:-------|
| **Phase 1** | Radiation, CorrosiveSlam, ToxicLob |
| **Phase 2** | VolatileMinions, FissionBarrage |
| **Transition** | 50% HP |

### Hive Mother (Boss2)
| Phase | Skills |
|:------|:-------|
| **Phase 1** | AcidSpit, SpawnLarva |
| **Phase 2** | ToxicCloud, BroodFrenzy |
| **Transition** | Metamorphosis at 50% HP |

### Blighted Alchemist (Boss3)
| Phase | Skills |
|:------|:-------|
| **Phase 1** | SyringeVolley, UnstableVials |
| **Phase 2** | CausticCatalyst, SymbioticLink, MutatedSpecimens, PlagueBomb |

## ⚙️ Controls

| Button | Function |
|:-------|:---------|
| **🛡️ God Mode** | Toggle player invincibility |
| **💀 Despawn** | Remove current test boss |
| **HP 50%** | Set boss HP to 50% (trigger phase) |
| **HP 25%** | Set boss HP to 25% |
| **Kill** | Instantly kill boss |

## ⚠️ Notes

- Plugin hanya berfungsi di **Play Mode** (F5)
- Test boss muncul dengan model sederhana untuk testing
- VFX tetap ter-trigger via RemoteEvents
