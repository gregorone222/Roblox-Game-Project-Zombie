# 🧟 Zombie Types & ACT Progression

Dokumentasi jenis zombie dan kemunculannya per ACT.

> **Philosophy:** Setiap ACT memperkenalkan zombie baru untuk variasi gameplay dan merefleksikan setting cerita.

---

## 📊 Zombie Unlock per ACT

| ACT | New Zombies | Total Available |
|:----|:------------|:----------------|
| **1** | Runner, Shooter, Tank | 3 types |
| **2** | +Rioter, +Spitter, +Brute | 6 types |
| **3** | +Hazmat, +Screamer, +Crawler | 9 types |
| **4** | +Security, +Failed Subject, +Drone | 12 types |
| **5** | +Soldier, +Juggernaut, +Commander | 15 types |
| **6-10** | Elite variants dari semua | 15+ types |

---

## 🏚️ ACT 1: THE CURSED VILLAGE

**Theme:** Rural Infected - Warga desa yang terinfeksi

### Base Zombies (Available from Wave 1)

| Type | HP | Speed | Damage | Behavior |
|:-----|:---|:------|:-------|:---------|
| **Runner** | 100 | Fast | 10 | Standar zombie, berlari ke player |
| **Shooter** | 80 | Slow | 15 | Ranged attack, mundur jika dekat |
| **Tank** | 500 | Slow | 25 | High HP, knockback resistance |

**Spawn Weights ACT 1:**
- Runner: 60%
- Shooter: 25%
- Tank: 15%

---

## 🏙️ ACT 2: THE SILENT CITY

**Theme:** Urban Chaos - Penduduk kota yang terinfeksi

### New Zombies

| Type | HP | Speed | Damage | Behavior |
|:-----|:---|:------|:-------|:---------|
| **Rioter** | 150 | Medium | 20 | Charge attack, melee combo 3-hit |
| **Spitter** | 100 | Slow | 12 | Ranged acid spit, creates damage puddles |
| **Brute** | 350 | Slow | 30 | Grab attack, throws player |

**Visual Style:**
- Rioter: Pakaian sipil robek, tanda protes
- Spitter: Tubuh mengembung, warna kehijauan
- Brute: Besar, otot berlebih, konstruksi worker

**Spawn Weights ACT 2:**
- Runner: 40%
- Shooter: 15%
- Tank: 10%
- Rioter: 15%
- Spitter: 12%
- Brute: 8%

---

## 🔬 ACT 3: THE UNDERGROUND

**Theme:** Lab Experiments - Hasil eksperimen Zenith

### New Zombies

| Type | HP | Speed | Damage | Behavior |
|:-----|:---|:------|:-------|:---------|
| **Hazmat** | 300 | Slow | 18 | 50% damage reduction, resists elemental |
| **Screamer** | 80 | Fast | 5 | Alerts nearby zombies, +20% damage aura |
| **Crawler** | 60 | Medium | 8 | Underground burrow, ambush dari bawah |

**Visual Style:**
- Hazmat: Pakaian hazmat suit robek, mask
- Screamer: Mulut terbuka lebar, suara tinggi
- Crawler: Lab subject failed, bergerak merangkak

**Special Mechanic:**
- Screamer harus diprioritaskan - jika tidak dibunuh dalam 5 detik, spawn tambahan
- Crawler burrows dan muncul tiba-tiba dekat player

---

## 🏢 ACT 4: THE CORPORATION

**Theme:** Corporate Security - Karyawan & keamanan Zenith

### New Zombies

| Type | HP | Speed | Damage | Behavior |
|:-----|:---|:------|:-------|:---------|
| **Security** | 200 | Medium | 22 | Electric baton, stun 1 detik per hit |
| **Failed Subject** | 120 | Very Fast | 15 | Erratic movement, hard to hit |
| **Drone** | 50 | Fast | 10 | Flying, shoots laser, explodes on death |

**Visual Style:**
- Security: Seragam security Zenith, pistol di belt
- Failed Subject: Tubuh mutasi tidak sempurna, asimetris
- Drone: Mechanical drone dengan virus attachment

**Special Mechanic:**
- Drone explodes dealing AoE damage when destroyed

---

## 🏛️ ACT 5: THE COVER-UP

**Theme:** Military Response - Tentara yang gagal containment

### New Zombies

| Type | HP | Speed | Damage | Behavior |
|:-----|:---|:------|:-------|:---------|
| **Soldier** | 250 | Medium | 20 | Ranged firearm, takes cover behind objects |
| **Juggernaut** | 800 | Very Slow | 40 | Heavy armor, immune to knockback |
| **Commander** | 400 | Medium | 25 | Buffs nearby zombies +30% damage, priority target |

**Visual Style:**
- Soldier: Full military gear, helmet, rifle
- Juggernaut: Heavy riot gear, shield
- Commander: Officer uniform, radio equipment

**Special Mechanic:**
- Commander gives aura buff - kill first to weaken others

---

## ⭐ ACT 6-10: ELITE VARIANTS

Mulai ACT 6, zombie dari ACT sebelumnya punya **Elite variant** dengan:
- +50% HP
- +25% Damage
- Visual glow effect
- Chance drop reward lebih tinggi

| Base Type | Elite Name | Bonus Ability |
|:----------|:-----------|:--------------|
| Runner | **Sprinter** | Dodge first shot |
| Tank | **Behemoth** | Ground slam AoE |
| Shooter | **Sniper** | Longer range, higher damage |
| Brute | **Crusher** | Throws rocks ranged |
| Screamer | **Siren** | Larger alert radius |
| Juggernaut | **Titan** | Charge attack |
| Commander | **General** | Larger buff radius |

---

## ⚖️ Balance Notes

### HP Scaling per ACT
Base HP disesuaikan dengan difficulty:
```
ACT HP = Base HP × (1 + (ACT - 1) × 0.2)
```

| ACT | HP Multiplier |
|:----|:--------------|
| 1 | 1.0x |
| 2 | 1.2x |
| 3 | 1.4x |
| 4 | 1.6x |
| 5 | 1.8x |
| 6+ | 2.0x |

### Damage Scaling
Damage juga naik per ACT untuk menjaga tension:
```
ACT Damage = Base Damage × (1 + (ACT - 1) × 0.15)
```

---

## 🎨 Visual Design Rules

1. **Consistent Art Style:** Fortnite/Overwatch stylized, bukan horror realistis
2. **Color Coding:**
   - Runner: Neutral (grey/brown)
   - Special: Unique color per type
   - Elite: Glow effect + enhanced color
3. **Readability:** Player harus bisa identifikasi type dari kejauhan
4. **Theme Matching:** Zombie visual matches ACT setting

---

## 📝 Implementation Status

### ACT 1 (Implemented)
- [x] Runner
- [x] Shooter
- [x] Tank

### ACT 2 (Planned)
- [ ] Rioter
- [ ] Spitter
- [ ] Brute

### ACT 3 (Planned)
- [ ] Hazmat
- [ ] Screamer
- [ ] Crawler

### ACT 4 (Planned)
- [ ] Security
- [ ] Failed Subject
- [ ] Drone

### ACT 5 (Planned)
- [ ] Soldier
- [ ] Juggernaut
- [ ] Commander

### ACT 6+ (Planned)
- [ ] Elite variants

---

*"Mereka dulunya adalah kita. Sekarang mereka hanya sisa-sisa."*  
— Alexander
