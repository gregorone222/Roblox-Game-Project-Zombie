# 📏 Development Rules & Guidelines

Aturan baku pengembangan untuk menjaga kualitas kode dan konsistensi UI.

## 1. UI/UX Standards
*   **Scale Over Offset:** Semua elemen UI **WAJIB** menggunakan `Scale` untuk ukuran dan posisi. `Offset` dilarang kecuali untuk border/padding kecil.
*   **Anchor Point:** Gunakan `0.5, 0.5` untuk elemen tengah.
*   **Text Scaling:** Gunakan `TextScaled` atau `UITextSizeConstraint`.
*   **Mobile Support:**
    *   Cek `TouchEnabled`.
    *   Perbesar tombol pada layar mobile (Safe Padding minimal 15%).
*   **Immersive Menus:** Terapkan `BlurEffect` kamera saat membuka menu full-screen.

## 2. Code Structure
*   **Modular:** Gunakan `ModuleScript` di `ServerScriptService` untuk logika.
*   **Services:** Gunakan `GetService` di awal script, jangan panggil berulang-ulang.
*   **Type Safety:** Gunakan `tonumber()` saat mengolah data konfigurasi.

## 3. Environment
*   **Hierarchy:** Workspace harus rapi. Gunakan Folder (`Map_Village`, `LobbyEnv`).
*   **Optimization:** Pastikan part statis di-Anchor. Gunakan Fog untuk menyembunyikan rendering jarak jauh.
