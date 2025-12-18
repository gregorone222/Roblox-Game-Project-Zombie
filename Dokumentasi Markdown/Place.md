# 🗺️ Dokumentasi Place & Map

Dokumentasi ini berisi informasi detil mengenai pengaturan Place, Environment, dan Map dalam game.

## 1. Lobby (Subway Station)

**ID Place:** `101319079083908`
**Script Utama:** `LobbyBuilderSubway.lua`
**Tema:** Stasiun Bawah Tanah Terbengkalai (Abandoned Subway).
**Atmosfer:** Gelap, Dingin, Industrial.

### 📍 Area Utama
*   **Station Platform:** Area spawn utama dangan api unggun.
*   **Leaderboard Room:** Ruangan khusus di belakang spawn berisi papan peringkat.
*   **Train Cars:**
    *   *Center Car:* Lokasi **Quartermaster** (Shop).
    *   *Cargo Car:* Area dekoratif.
*   **Command Center:** Meja strategi dengan hologram dan NPC **Alexander**.
*   **Medical Tent:** Area pembelian Booster & Medical Supplies.
*   **Gacha Corner:** Lokasi Vending Machine (Mystery Cache).

### 💡 Lighting & VFX
*   **Ambient:** Very Dark (20, 20, 25).
*   **Fog:** End Distance 150 (Klaustrofobik).
*   **Light Sources:**
    *   *Warm:* Api unggun tengah.
    *   *Cold:* Lampu neon berkedip.
    *   *Green:* Monitor Leaderboard.

---

## 2. ACT 1: The Village (Campaign)

**ID Place:** `91523772574713`
**Script Utama:** `MapBuilderVillage.lua`
**Tema:** Desa Terkutuk (Cursed Village - Ground Zero).
**Atmosfer:** Berkabut, Mencekam, Outdoor.

### 📍 Layout Map
*   **Town Square:** Pusat map dengan **Radio Tower** (Objective Zone).
*   **Residential Ruins:** Rumah-rumah kayu hancur yang mengelilingi alun-alun.
*   **The Forest (Outer Ring):** Hutan mati di pinggiran map, tempat spawn sample.

### 🎯 Objective Zones & Events
*   **Wave 8 (Scavenge):** Mencari Gas Canisters di area perumahan.
*   **Wave 22 (Defend):** Mempertahankan Radio Tower di Town Square.
*   **Wave 38 (Retrieve):** Mengambil sampel virus dari Hutan.

### 💡 Lighting & VFX
*   **Waktu:** Midnight (`ClockTime: 0`).
*   **Fog:** Tebal (Start: 10, End: 150) untuk membatasi jarak pandang.
*   **Light Sources:** Lampu jalanan tua (Dim Orange) dan cahaya jendela samar.
