# ⚠️ Deprecated API

API Roblox yang sudah usang dan penggantinya.

## ProximityUIHandler (ModuleScript)
- **Status:** ❌ Dihapus
- **Pengganti:** Event `ProximityPrompt.Triggered` direct connection
- **Konteks:** Modul lama yang menyebabkan bug yield dan recursive dependency

## UserInputService.ModalEnabled
- **Status:** ⚠️ Deprecated
- **Pengganti:**
  - `GuiService.TouchControlsEnabled` - visibilitas kontrol mobile
  - `UserInputService.MouseBehavior` - status kunci mouse
- **Migration:**
  ```lua
  -- Old: ModalEnabled = true
  GuiService.TouchControlsEnabled = false
  
  -- Old: ModalEnabled = false
  GuiService.TouchControlsEnabled = true
  ```

## TeleportService.ReserveServer
- **Status:** ⚠️ Deprecated
- **Pengganti:** `TeleportService:ReserveServerAsync()`
- **Note:** Async function, bungkus dalam `pcall`

## Players:CreateHumanoidModelFromUserId
- **Status:** ⚠️ Deprecated
- **Pengganti:** `Players:CreateHumanoidModelFromUserIdAsync(userId)`
- **Note:** Memerlukan pcall karena network request
