# 🎨 UI Development Workflow (AI-Assisted)

Alur kerja kolaboratif standar untuk pembuatan User Interface (UI).

## 🔄 Ringkasan Alur Kerja
1. **Visual Mockup Reference:** User memberikan gambar referensi (mockup/sketsa)
2. **Asset Generation:** Agent men-generate komponen aset individual (modular)
3. **Asset Processing:** User memproses (crop/upload) aset ke Roblox
4. **Programmatic Layout:** Agent menyusun UI menggunakan Script Builder
5. **Refinement:** Iterasi visual dan logika

---

## 1. Visual Mockup Reference (User)
- User mengupload gambar referensi untuk menjelaskan **Visi Visual**
- Prompt: *"Buatkan UI seperti gambar ini."*

## 2. Asset Generation (Agent)

### 🎨 Standar Tema (Wajib)
- **Theme:** "Makeshift Survivor Camp" (Stylized Post-Apocalypse)
- **Vibe:** Rongsokan rapi, kayu, kain terpal, besi berkarat
- **Colors:**
  - Primary: Warm Brown, Forest Green, Rusty Orange
  - Accent: Bright Yellow, Soft Cyan
  - **Forbidden:** Neon Grid, sci-fi hologram, chrome

### Visual References
- Fortnite: Save the World (Homebase)
- Overwatch 2 (Junkrat style)

## 3. Asset Processing (User)
1. Selection - pilih variasi terbaik
2. Background Removal - pastikan transparan
3. Cropping - tight fit ke konten
4. Upload ke Roblox via Asset Manager
5. Provide Asset IDs (`rbxassetid://...`)

## 4. Programmatic Layout (Agent)
```lua
local ASSETS = {
    MainFrame = "rbxassetid://123...",
    Button    = "rbxassetid://456...",
}
-- Code to construct UI instances...
```

## 5. Visual Refinement & Logic
1. Play Test - lihat hasil di game
2. Feedback - posisi, ukuran
3. Finalization - simpan `.rbxmx`, buat script logika

---

## 🛠️ Tools
- **DALL-E 3 / Midjourney:** Generate aset
- **Roblox Studio:** Asset Manager & UI Editor
- **Photopea / Photoshop:** Cleaning & slicing
