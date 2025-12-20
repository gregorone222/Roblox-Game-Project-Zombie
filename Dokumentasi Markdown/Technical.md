# 🛠️ Dokumentasi Teknis

Arsitektur sistem, skema data, dan manajemen backend.

## 💾 DataStore & ProfileStore
Menggunakan **ProfileStore** untuk integritas data dan locking sesi.

### Data Schema (Version 1)
Struktur tabel `PlayerData`:

```lua
Stats = {
    TotalCoins = 0,
    TotalKills = 0,
    AchievementPoints = 0,
    WeaponStats = {}
}
Inventory = {
    Coins = 0,
    Skins = { Owned = {}, Equipped = {} },
    PityCount = 0 -- Gacha pity
}
Progression = {
    Level = 1,
    XP = 0,
    Titles = { Unlocked = {} }
}
```

### Leaderboards
Menggunakan `OrderedDataStore`.
*   **Tipe:** Kill, Total Damage, Level, Mission Points.
*   **Best Practice:** Semua nilai yang dikirim ke `SetAsync` dibulatkan ke bawah (`math.floor`) untuk mencegah error "double is not allowed".
*   **Update:** Real-time saat pemain keluar atau interval tertentu.

## 🏗️ Technical Architecture
*   **Module-Based:** Logika inti dipecah menjadi ModuleScript di `ServerScriptService`.
*   **Networking:** Pola `RemoteEvent` searah (Client -> Server Action) dan `RemoteFunction` untuk request data.
*   **Session Locking:** Mencegah eksploit duplikasi item dengan memblokir login ganda.

## 🤸 Ragdoll Physics System
Implementasi sistem ragdoll server-side yang realistis (`RagdollModule`) menggantikan animasi kematian standar.

### Komponen Utama:
1.  **Constraint Conversion:** Mengubah `Motor6D` menjadi `BallSocketConstraint` saat karakter mati.
2.  **Hybrid Stability:**
    *   **Limbs (Tangan/Kaki):** Menggunakan `BallSocketConstraint` dengan limit sudut (`UpperAngle=45`) untuk mencegah putaran liar ("helicopter effect").
    *   **Torso/Hip:** `HumanoidRootPart` dikunci ke Torso menggunakan `RigidConstraint` (Weld) untuk mencegah getaran (jitter) pada bagian pinggang saat jatuh tengkurap.
3.  **Bullet Force:**
    *   Menyimpan arah tembakan terakhir (`LastHitDirection`) dan kekuatan (`LastHitForce`) di atribut karakter.
    *   Force dihitung berdasarkan `Damage * 0.5` + komponen upward kecil.
    *   Impulse diterapkan ke Torso saat ragdoll aktif untuk efek terdorong yang sesuai arah peluru.
4.  **Optimization:**
    *   **Animator Destruction:** `animator:Destroy()` dipanggil untuk mencegah interpolasi animasi mengganggu fisika (penyebab utama jitter).
    *   **Physics Cleanup:** Bagian tubuh diset ke High Friction (`1.0`) dan Zero Elasticity (`0.0`) agar cepat berhenti bergerak di lantai.
