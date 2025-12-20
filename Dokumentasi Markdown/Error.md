# 🐛 Error Log & Technical Constraints

Daftar batasan teknis yang ditemukan selama pengembangan. Baca ini sebelum debugging!

## 🚫 Roblox Engine Constraints
Daftar fitur yang sering menyebabkan error jika salah penggunaan.

| Fitur | Masalah / Batasan | Solusi / Alternatif |
| :--- | :--- | :--- |

| **Attributes** | Tidak bisa menyimpan Function/Table/UserData. | Gunakan ModuleScript atau BindableEvent. |
| **CanvasGroup** | Masalah performa/rendering (flickering). | **DILARANG.** Gunakan ImageLabel overlay. |
| **UIGradient** | `Transparency` tidak bisa di-tween. | Gunakan loop `RunService` manual. |
| **UIListLayout** | Urutan elemen acak. | Set `SortOrder = Enum.SortOrder.LayoutOrder`. |
| **ColorSequence**| Max 20 Keypoints. | Pecah menjadi 2 gradient jika butuh lebih. |
| **Enum.Font** | `GloriaHallelujah`, `BlackOpsOne` belum disupport. | Gunakan `PermanentMarker` atau `Michroma`. |

## ⚠️ Common Scripting Pitfalls
*   **Race Conditions:** Akses UI sebelum loading selesai -> *Solusi:* Selalu gunakan `:WaitForChild()` atau `FindFirstChild` defensif.
*   **String Concatenation:** Error jika nilai `nil` -> *Solusi:* `tostring(val)`.
*   **Math Safety:** `math.max(nil, 5)` error -> *Solusi:* `tonumber(input) or 0`.
*   **Remote Security:** Jangan percaya input client mentah-mentah. Validasi tipe data di server.
*   **Variable Shadowing:** Mendifinisikan ulang variabel global/upvalue dengan `local` di dalam scope sempit. -> *Efek:* Variabel asli tetap `nil` atau tidak terupdate. -> *Contoh Error:* `attempt to index nil with 'ClearAllChildren'`.

## 🔄 Deprecated Modules
*   **`ProximityUIHandler`:** Dihapus. Gunakan event `ProximityPrompt` standar direct connection.
