# Pembagian Divisi & Batasan Kerja Agent (SOP)

Dokumen ini mengatur pembagian tugas antara agen otonom (AI Agents) untuk mencegah konflik suntingan (merge conflicts) dan tumpang tindih logika dalam proyek "Zombie?".

---

## 🎭 Peran 1: Systems Architect (Backend & Core)
**Fokus Utama:** Logika Server, Game Loop, Data Persistence, dan Manajerial AI Musuh.

### ✅ Area Otoritas (Exclusive Write Access)
*   **Direktori:**
    *   `ServerScriptService/*` (Kecuali VFX Handler tertentu)
    *   `ServerStorage/Modules/*`
*   **File Kunci:**
    *   `GameManager.lua`: Loop utama, state management.
    *   `DataStoreManager.lua`: Penyimpanan data pemain.
    *   `ZombieModule.lua`: Logika pathfinding & spawning server-side.
    *   `LobbyManager.lua`, `MissionManager.lua`.

### 🚫 Batasan (Read-Only)
*   Jangan menyentuh **LocalScript** di `StarterGui` atau `StarterPlayer`.
*   Jangan mengubah **Visual Effects** client-side secara langsung (gunakan RemoteEvent).

---

## 🎮 Peran 2: Gameplay Scripter (Client Controllers)
**Fokus Utama:** Interaksi Pemain, Sistem Senjata (Client), Kontrol, dan Kamera.

### ✅ Area Otoritas (Exclusive Write Access)
*   **Direktori:**
    *   `StarterPlayer/StarterPlayerScripts/*`
    *   `ReplicatedStorage/ModuleScript/ViewmodelModule.lua`
    *   `ReplicatedStorage/ModuleScript/WeaponModule.lua` (Definisi stat senjata)
*   **File Kunci:**
    *   `WeaponClient.lua`: Input tembakan, recoil, handling.
    *   `MobileControlsClient.lua`: Touch input context.
    *   `CameraEffects.lua`: Shake, FOV, Tilt.

### 🚫 Batasan (Read-Only)
*   Jangan menyentuh logika validasi damage di Server (`WeaponManager.lua` di ServerScriptService).
*   Jangan mengubah UI tata letak (serahkan ke Peran 3).

---

## 🎨 Peran 3: Frontend Engineer (UI/UX & Environment)
**Fokus Utama:** Antarmuka Pengguna, Efek Visual (VFX), Lighting, dan Map Building.

### ✅ Area Otoritas (Exclusive Write Access)
*   **Direktori:**
    *   `StarterGui/*` (Semua ScreenGui)
    *   `Lighting/*` (Post-processing)
    *   `ReplicatedStorage/ZombieVFX/*`
*   **File Kunci:**
    *   `StartUI.lua`, `GameOverUI.lua`, `HUDManager` (jika ada).
    *   `EffectManagers` (Client-side listeners untuk VFX).
    *   `.md` Files (Dokumentasi cerita/aturan).
*   **Shared Config:** Berhak mengubah `Rule.md` terkait desain visual.

### 🚫 Batasan (Read-Only)
*   Jangan mengubah logika gameplay inti (damage calculation, xp gain).

---

## 🤝 Protokol Sumber Daya Bersama (Shared Resources)
File di `ReplicatedStorage` sering diakses oleh semua pihak. Ikuti aturan ini:

1.  **GameConfig.lua:**
    *   **Peran 1 (System)** memiliki hak veto untuk perubahan balancing (Economy flow, Wave difficulty).
    *   **Peran 3 (Frontend)** boleh mengubah nilai visual (warna lighting, teks pesan).
2.  **RemoteEvents:**
    *   **Peran 1** *membuat* Event baru (mendefinisikan kontrak).
    *   **Peran 2 & 3** *mengkonsumsi* (Listen/Fire) Event tersebut.
3.  **Conflict Resolution:**
    *   Jika dua agent perlu mengubah file yang sama (misal `GameConfig.lua`), diskusikan perubahan *interface* atau *struktur data* terlebih dahulu sebelum implementasi.

---

## 📋 Checklist Sebelum Pengerjaan
1.  Identifikasi kategori tugas Anda (Server / Client / UI).
2.  Cek apakah file target masuk dalam "Area Otoritas" Anda.
3.  Jika harus cross-boundary, buat **Request** untuk agent penanggung jawab area tersebut, atau update file dengan sangat hati-hati dan isolasi perubahan.
