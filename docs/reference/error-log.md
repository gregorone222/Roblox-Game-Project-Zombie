# 🐛 Error Log & Technical Constraints

Batasan teknis yang ditemukan selama pengembangan.

## 🚫 Roblox Engine Constraints

| Feature | Problem | Solution |
|:--------|:--------|:---------|
| **Attributes** | Cannot store Function/Table/UserData | Use ModuleScript or BindableEvent |
| **CanvasGroup** | Performance/rendering issues (flickering) | **FORBIDDEN.** Use ImageLabel overlay |
| **UIGradient** | `Transparency` cannot be tweened | Use RunService loop manually |
| **UIListLayout** | Random element order | Set `SortOrder = Enum.SortOrder.LayoutOrder` |
| **ColorSequence** | Max 20 Keypoints | Split into 2 gradients if needed |
| **Enum.Font** | Some fonts not supported | Use `PermanentMarker` or `Michroma` |

## ⚠️ Common Scripting Pitfalls

| Issue | Cause | Solution |
|:------|:------|:---------|
| **Race Conditions** | Access UI before loading | Use `:WaitForChild()` |
| **String Concatenation** | Error if nil value | Use `tostring(val)` |
| **Math Safety** | `math.max(nil, 5)` errors | Use `tonumber(input) or 0` |
| **Remote Security** | Trust client input | Validate types on server |
| **Variable Shadowing** | Redefine global with local | Check scope carefully |

## 🔄 Deprecated Modules

| Module | Status | Replacement |
|:-------|:-------|:------------|
| `ProximityUIHandler` | Removed | Direct `ProximityPrompt.Triggered` connection |
