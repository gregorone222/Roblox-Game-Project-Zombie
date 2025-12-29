# ⚔️ Combat System

Sistem pertempuran dan senjata.

## Weapons

### Classification
| Type | Weapons |
|:-----|:--------|
| **Melee** | Crowbar, Baseball Bat, Machete |
| **Pistol** | M1911, Desert-Eagle, Glock-19 |
| **SMG** | P90, MP5, KRISS-Vector |
| **Assault Rifle** | AK-47, SCAR, M4A1 |
| **Shotgun** | M590A1, Benelli-M4, Remington-870 |
| **Sniper** | L115A1, DSR, Barrett-M82 |
| **LMG** | RPD, MG42, M249, Minigun |

### Melee Weapons (Tool Slot 1)

Melee weapons adalah senjata permanen di slot 1 yang tidak bisa diganti selama gameplay.

> [!NOTE]
> Semua player **otomatis memiliki** ketiga melee weapons dari awal game. Default equipped: **Crowbar**.
> Pilih melee weapon di Inventory untuk mengganti.

| Weapon | Damage | Attack Speed | DPS | Range | Stamina Cost |
|:-------|:------:|:------------:|:---:|:-----:|:------------:|
| **Baseball Bat** | 35 | 0.5s | 70 | 4.5 | 4 |
| **Crowbar** | 45 | 0.8s | 56 | 5.0 | 5 |
| **Machete** | 55 | 1.0s | 55 | 5.5 | 6 |



### Acquisition
- **Mystery Box (Gacha):** Senjata acak dari Digital Fabricator
- **Starting Weapon:** Senjata awal saat spawn

### Upgrade System
- **Weapon Mod Station:** Meningkatkan Level 1-10
- **Effect:** Damage & Ammo capacity naik bertahap
- **Cost:** Eksponensial setiap level

---

## Perks (Power-Ups)

Holographic Data Chips yang memberikan upgrade permanen.

| ID | Display Name | Effect |
|:---|:-------------|:-------|
| **HP Plus** | Iron Will ❤️ | Max Health +30% |
| **Stamina Plus** | Second Wind 🏃 | Max Stamina +30% |
| **Reload Plus** | Quick Hands ✋ | Reload speed +30% |
| **RateBoost** | Rapid Fire 🔥 | Fire Rate +30% |
| **Revive Plus** | Battle Bond 🤝 | Revive 50% faster |
| **Medic** | Field Medic 💚 | Revived allies get 30% HP |

---

## Tactical Boosts

Upgrade sementara untuk senjata/pemain (dibeli per-wave):
- **Incendiary Rounds** - Burn damage over time
- **Cryo Compound** - Slow enemies
- **Toxic Agent** - DOT poison
- **EMP Burst** - Chain damage
- **Concussion Blast** - Knockback only
- **Hardened Armor** - Defense buff
- **Stimpack** - Brief invincibility
- **Adrenaline Serum** - Life steal

---

## Combat Features

| Feature | Description |
|:--------|:------------|
| **Raycast Ballistics** | Hitscan/Projectile system |
| **Damage Numbers** | Visual feedback on hit |
| **Hitmarkers** | White (body), Red (headshot) |
| **Revive System** | Knocked players can be revived |
| **Shield System** | Armor layer above HP |
| **Realistic Ragdoll** | Physics-based death animation |
