# 🧟 Zombie? - Project Documentation

**Zombie?** adalah game **Stylized Hero Co-op Shooter** di Roblox.
Target audiens utama adalah pemain berusia <13 tahun, dengan visual yang ramah anak, vibran, dan penuh aksi.

## 🎨 Art Direction & Vision
- **Style:** Stylized, Cartoon, Vibrant (Fortnite/Overwatch Style)
- **Tone:** Fun, Arcade, Heroic (Bukan Horror/Grime)
- **Visuals:** Warna cerah (Neon/Pastel), UI Rounded

## ❤️ Core Philosophy
**"Memory over Addiction"** - Menciptakan pengalaman Co-op yang hangat dan bermakna.

---

## 📚 Documentation Index

### 🎮 Gameplay
| Document | Description |
|:---------|:------------|
| [Wave System](gameplay/wave-system.md) | Wave mechanics, special events, boss spawns |
| [Combat System](gameplay/combat-system.md) | Weapons, perks, tactical boosts, damage |
| [Economy](gameplay/economy.md) | Survival Coins, Valor, AP, MP, progression, leveling |
| [Shop System](gameplay/shop-system.md) | In-game Valor shops (Tactical Boost, Perk, Weapon, Upgrade) |
| [Tactical Boosts](gameplay/tactical-boosts.md) | Combat boost items (formerly Elements) |
| [Field Kit](gameplay/field-kit.md) | Pre-mission supplies (rewards only) |
| [Difficulty Modes](gameplay/difficulty-modes.md) | Easy → Crazy settings |
| [Title System](gameplay/title-system.md) | Player title progression |

### 🎨 Design
| Document | Description |
|:---------|:------------|
| [Asset Master Guide](design/asset-master-guide.md) | Master asset creation guidelines |
| [UI Master Guide](design/ui-master-guide.md) | UI design system & standards |
| [Sound Master Guide](design/sound-master-guide.md) | Audio design guidelines |
| [VFX Master Guide](design/vfx-master-guide.md) | Visual effects guidelines |

### 🛠️ Technical
| Document | Description |
|:---------|:------------|
| [Architecture](technical/architecture.md) | Service-Manager pattern, module list |
| [DataStore](technical/datastore.md) | ProfileStore, full data schema |
| [Remote Events API](technical/remote-events-api.md) | RemoteEvents & RemoteFunctions reference |
| [Deprecated API](technical/deprecated-api.md) | Usang API & solusi |

### 🗺️ Maps & Places
| Document | Description |
|:---------|:------------|
| [Lobby - Farmhouse](maps/lobby-farmhouse.md) | Abandoned farmhouse basecamp |
| [ACT 1 - Village](maps/act1-village.md) | The Cursed Village |

### 👾 Entities
| Document | Description |
|:---------|:------------|
| [Characters](entities/characters.md) | NPCs, Bosses, Player character |
| [Zombies](entities/zombies.md) | Enemy types & behavior |
| [Zombie Progression](entities/zombie-progression.md) | Enemy scaling per wave |

### 📜 Story
| Document | Description |
|:---------|:------------|
| [Story & Lore](story/story.md) | Narrative, characters, campaign |

### 🔧 Workflows
| Document | Description |
|:---------|:------------|
| [UI Development](workflows/ui-development.md) | UI development workflow |
| [VFX Development](workflows/vfx-development.md) | VFX development workflow |
| [Environment Development](workflows/environment-development.md) | Environment development workflow |
| [Builder Scripting](workflows/builder-scripting.md) | Building structures with createPart & createWedge |
| [Debugging](workflows/debugging.md) | Debugging guides |

### 🔌 Tools & Plugins
| Document | Description |
|:---------|:------------|
| [Viewmodel Editor](tools/viewmodel-editor.md) | FPS viewmodel positioning |
| [Live Config Tuner](tools/live-config-tuner.md) | Real-time config tuning |
| [AI NPC Integration](tools/ai-npc-integration.md) | AI NPC workflow |
| [Phone Companion App](tools/phone-companion-app.md) | Mobile companion app |
| [Procedural 3D Generator](tools/procedural-3d-generator.md) | 3D asset generation |
| [Arsenal Forge](tools/arsenal-forge.md) | Weapon stats editor & tester |
| [Wave Director](tools/wave-director.md) | Wave composition editor |
| [Loot Balancer](tools/loot-balancer.md) | Drop rate balancer |
| [Unified Shop Editor](tools/unified-shop-editor.md) | AP/MP shop editor |
| [Boss Skill Tester](tools/boss-skill-tester.md) | Boss skill testing in Play Mode |

### 📋 Reference
| Document | Description |
|:---------|:------------|
| [Controls](reference/controls.md) | PC & Mobile controls |
| [Rules](reference/rules.md) | Development rules & guidelines |
| [Error Log](reference/error-log.md) | Technical constraints |

---

## 🛠️ Project Summary
- **Genre:** Co-op FPS/TPS Survival
- **Engine:** Roblox (Luau)
- **Architecture:** Service-Manager Pattern, Modular, Event-Driven
