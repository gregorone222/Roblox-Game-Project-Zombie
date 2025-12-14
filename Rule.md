# Development Rules & Guidelines

Dokumen ini berisi aturan baku dan panduan yang harus dipatuhi selama pengembangan proyek "Zombie?".

## 1. UI/UX Design & Responsiveness
*   **Wajib Menggunakan Scale:** Seluruh elemen UI (Frame, Button, TextLabel, dll) **HARUS** menggunakan properti `Scale` untuk posisi dan ukuran (`UDim2.new(scaleX, 0, scaleY, 0)`).
    *   **Dilarang** menggunakan `Offset` untuk ukuran utama agar UI responsif di PC, Mobile, dan Tablet.
    *   *Pengecualian:* Border tipis atau padding kecil boleh menggunakan Offset jika benar-benar diperlukan.
*   **Anchor Point:** Gunakan `AnchorPoint` (misal `0.5, 0.5`) untuk memudahkan pemosisian elemen di tengah layar atau container.
*   **Aspek Rasio:** Gunakan `UIAspectRatioConstraint` untuk elemen yang harus mempertahankan bentuknya (seperti ikon bulat atau gambar senjata).
*   **Text Scaling:** Gunakan `TextScaled = true` atau `UITextSizeConstraint` untuk memastikan teks terbaca di semua resolusi.
*   **ScrollingFrame:** Setiap `ScrollingFrame` **WAJIB** menggunakan:
    *   `CanvasSize = UDim2.new(0, 0, 0, 0)`
    *   `AutomaticCanvasSize = Enum.AutomaticSize.Y` (atau X/XY sesuai kebutuhan, tapi hindari manual pixel size).

## 2. Environment & Building
*   **Hierarchy:** Jaga kebersihan `Workspace`. Kelompokkan objek peta dalam Folder atau Model (misal `Map_Village`, `LobbyEnvironment`).
*   **Anchored:** Pastikan bagian statis lingkungan selalu `Anchored = true`.

---
*Perbarui dokumen ini jika ada aturan baru yang disepakati.*
