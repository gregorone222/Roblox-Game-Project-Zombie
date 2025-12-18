# Pelacakan API Usang (Deprecated)

Dokumen ini melacak API Roblox yang sudah usang yang ditemukan dalam proyek dan pengganti modernnya.

## UserInputService.ModalEnabled
- **Status**: Usang (Deprecated)
- **Pengganti**: `GuiService.TouchControlsEnabled` (untuk visibilitas kontrol seluler) dan `UserInputService.MouseBehavior` (untuk status kunci mouse).
- **Konteks**: Digunakan untuk menyembunyikan kontrol seluler (lompat/analog) dan membuka kunci mouse selama mode sinematik/UI.
- **Tindakan**: 
    - `ModalEnabled = true` -> `GuiService.TouchControlsEnabled = false` (Logika terbalik: Modal menyala = Kontrol mati)
    - `ModalEnabled = false` -> `GuiService.TouchControlsEnabled = true`

## TeleportService.ReserveServer
- **Status**: Usang (Deprecated)
- **Pengganti**: `TeleportService:ReserveServerAsync()`
- **Konteks**: Digunakan untuk mereservasi private server sebelum teleport pemain dalam matchmaking/room system.
- **Tindakan**: 
    - `TeleportService:ReserveServer(placeId)` -> `TeleportService:ReserveServerAsync(placeId)`
    - Catatan: Fungsi ini async, pastikan dibungkus dalam `pcall` untuk error handling.
