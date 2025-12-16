# Pelacakan API Usang (Deprecated)

Dokumen ini melacak API Roblox yang sudah usang yang ditemukan dalam proyek dan pengganti modernnya.

## UserInputService.ModalEnabled
- **Status**: Usang (Deprecated)
- **Pengganti**: `GuiService.TouchControlsEnabled` (untuk visibilitas kontrol seluler) dan `UserInputService.MouseBehavior` (untuk status kunci mouse).
- **Konteks**: Digunakan untuk menyembunyikan kontrol seluler (lompat/analog) dan membuka kunci mouse selama mode sinematik/UI.
- **Tindakan**: 
    - `ModalEnabled = true` -> `GuiService.TouchControlsEnabled = false` (Logika terbalik: Modal menyala = Kontrol mati)
    - `ModalEnabled = false` -> `GuiService.TouchControlsEnabled = true`
