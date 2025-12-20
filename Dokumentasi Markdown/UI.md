# 🖥️ Dokumentasi User Interface (UI)

Daftar lengkap modul antarmuka pengguna, dikelompokkan berdasarkan fungsinya.

## 🎨 Visual Design Guidelines
*   **Theme:** Makeshift Survivor Camp (Stylized Post-Apocalypse).
*   **Color Palette:**
    *   **Primary:** Warm Brown / Forest Green / Sunset Orange.
    *   **Accent:** Bright Yellow / Soft Cyan (untuk highlight/tombol).
    *   **Alert:** Soft Red / Orange (Hindari warna darah gelap).
*   **Shape Language:**
    *   Rounded Corners (8-12px, organic feel).
    *   Tekstur kayu/kain sebagai background (subtle, bukan realistis).
    *   Elemen "hand-drawn" atau "sticker" untuk ikon.
*   **Forbidden:** Hologram, neon grid, chrome, elemen sci-fi (lihat `Rule.md`).

## 📊 Heads-Up Display (HUD)
Elemen yang selalu aktif di layar gameplay.

*   **`StatusHUD`:** Indikator Vital (Health: Hijau, Shield: Biru, Stamina: Kuning).
*   **`AmmoUI` & `CrosshairUI`:** Informasi peluru dan reticle bidikan dinamis.
*   **`WaveCounterUI`:** Penunjuk Wave saat ini dan sisa musuh.
*   **`PointsUI`:** Skor sesi pemain saat ini.
*   **`HitmarkerUI`:** Feedback visual saat peluru mengenai musuh (Putih: Body, Merah: Headshot).

## 📱 Menu Systems
*   **`StartUI`:** Main Menu, Mission Briefing, dan Lobi Ready.
*   **`InventoryUI`:** Manajemen item dan skin.
*   **`GameSettingsUI`:** Pengaturan grafis, audio, dan kontrol.
*   **`ProfileUI`:** Statistik pemain, Level, dan Title.

## 🛒 Shop & Interactions
*   **`UpgradeShopUI`:** Upgrade senjata (Tier 1-3).
*   **`GachaUI`:** Animasi dan hasil mystery box.
*   **`BoosterShopUI`:** Pembelian buff sementara.
*   **`ElementShopUI`:** Pembelian elemen skill.
*   **`APShopUI`:** Toko Achievement Points (Skin premium).
*   **`MPShopUI`:** Toko Mission Points (Item khusus).
*   **`PerkShopUI`:** Tempat membeli Perk.
*   **`RandomWeaponShopUI`:** Mystery Box pembelian senjata acak.

## ⚠️ Alerts & Notifications
*   **`BossAlertUI`:** Bar HP Boss di atas layar.
*   **`SpecialWaveAlertUI`:** Peringatan "Dark Wave" atau "Fast Wave".
*   **`GameOverUI` / `VictoryUI`:** Layar akhir permainan.
