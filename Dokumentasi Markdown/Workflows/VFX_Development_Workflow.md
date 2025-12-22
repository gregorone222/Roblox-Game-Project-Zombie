# ✨ VFX Development Workflow

Dokumen ini menjelaskan alur kerja standar (Standard Operating Procedure) untuk pembuatan Visual Effects (VFX) di proyek ini, yang berfokus pada atmosfer "Ethereal/Bittersweet" dan efek tempur yang responsif.

## 🔄 Ringkasan Alur Kerja
1.  **Conceptualization:** Tentukan emosi/tujuan efek (Nostalgic vs Combat Impact).
2.  **Asset Generation (Textures):** Buat tekstur partikel (Flipbooks atau Single Texture).
3.  **Emitter Configuration (Studio):** Atur properti fisik partikel di Roblox Studio.
4.  **Scripting Integration:** Bungkus dalam ModuleScript untuk kontrol programatik.
5.  **Performance Tuning:** Optimasi count dan lifetime untuk mobile.

---

## 1. Conceptualization (The "Why")
Sebelum membuat partikel, pahami Pillar Visual proyek ini. Jangan membuat efek generik!

### Visual Pillars & References
1.  **Environment: "Ethereal & Bittersweet"**
    *   *Main Reference:* **Fortnite Save The World** (Post-apocalyptic namun colorful/hopeful).
    *   *Vibe:* Sunset, Twilight, Golden Hour.
    *   *Palette:* Warna lembut (Ungu/Pink senja), Kabut bercahaya (Volumetric).
    *   *Feeling:* **Nostalgia**. Dunia ini terasa seperti kenangan masa kecil yang sepi.

2.  **Combat: "Visceral & Punchy"**
    *   *Main Reference:* **Overwatch** (Terutama karakter Junkrat/Pharah).
    *   *Vibe:* Ledakan kartun, Bentuk tajam (Sharp Shapes).
    *   *Technique:* **Cleaner is Better**. Hindari noise/detail berlebih. Gunakan bentuk solid yang mudah dibaca mata.
    *   *Feeling:* **Satisfying**. Impact harus terasa "berat" namun cepat hilang.

## 2. Asset Generation (Texture Creation)
VFX yang bagus dimulai dari tekstur yang bagus.
*   **Tools:** Midjourney/DALL-E 3 untuk base shape, Photoshop untuk Alpha Channel.
*   **Format:**
    *   **Single Texture:** Untuk asap, debu, cahaya statis.
    *   **Flipbook (Spreadsheet):** Untuk ledakan, api, atau animasi kompleks (NxN Grid).
*   **Style:** Stylized/Cartoon (Hand-painted look), bukan foto-realistis.
*   **Black Background:** Pastikan background benar-benar hitam (untuk Additive Blending) atau transparan.

## 3. Emitter Configuration (Roblox Studio)
Tahap perakitan di Studio. Jangan biarkan properti default!

### Key Properties to Tune:
*   **`Transparency` & `Size` Sequence:** Gunakan *NumberSequence* untuk membuat partikel memudar (Fade in -> Stay -> Fade out) dan membesar/mengecil seiring waktu.
*   **`LightEmission`:** Set ke `1` untuk efek bercahaya (Api/Laser). Set ke `0` untuk asap tebal/darah.
*   **`Drag` & `Acceleration`:** Gunakan Drag untuk mensimulasikan gesekan udara (asap melambat). Gunakan Acceleration untuk gravitasi (darah jatuh).
*   **`FlipbookLayout`:** Pastikan diset sesuai jumlah grid jika menggunakan tekstur animasi (misal: 4x4).

## 4. Scripting Integration (Modular)
Jangan menaruh script di dalam Partikel. Gunakan **VFX Manager Pattern**.

### Struktur Module (`VFXManager.lua`)
```lua
function VFXManager:PlayEffect(effectName, position, normal)
    local template = ReplicatedStorage.VFX[effectName]
    local clone = template:Clone()
    clone.Parent = workspace.FXFolder
    clone.CFrame = CFrame.new(position, position + normal)
    
    -- Auto Cleanup
    Debris:AddItem(clone, 5) -- Sesuaikan dengan Lifetime partikel
    
    -- Emit
    for _, emitter in pairs(clone:GetChildren()) do
        if emitter:IsA("ParticleEmitter") then
            emitter:Emit(emitter:GetAttribute("EmitCount") or 10)
        end
    end
end
```

## 5. Hitscan Weapon VFX Standards (New)
Standar khusus untuk senjata api (Hitscan) guna memastikan responsivitas dan akurasi visual.

### A. Zero Latency Muzzle Flash
*   **Teknik:** Jangan weld part baru. Langsung **Parent** `ParticleEmitter` & `PointLight` ke part `Muzzle` senjata.
*   **Alasan:** Menghindari "Physics Drag" (efek tertinggal) saat player bergerak cepat/strafing.
*   **Client Implementation:** `WeaponClient` (Local) & `MuzzleFlashClient` (Network).

### B. Stylized Bullet Tracer
*   **Asset:** Beam dengan solid core & tapered tail (e.g., `rbxassetid://130004939944902`).
*   **Visual:** Warna Emas ke Oranye, `LightEmission = 1`, `TextureSpeed = 0` (Solid, no looping).
*   **Accuracy (WYSIWYG):**
    *   Gunakan **Client-Authoritative Spread**. Client menghitung acakan (spread), menggambar tracer ke sana, lalu mengirim *arah itu* ke server.
    *   Tracer visual harus selalu berakhir tepat di mana Bullethole muncul.

### C. Stylized Bullethole
*   **Teknik:** **Sticker Part**.
*   **Cara:** Spawn Part tipis transparan, tempel `Decal` di sisi depannya.
*   **Orientation:** `CFrame.lookAt(pos, pos + normal)`.
*   **Visual:** Gunakan tekstur "Spiderweb Crack" kontras tinggi (e.g., `rbxassetid://94614436519456`). Jangan gunakan puing fisika (Debris Parts) untuk performa.

## 6. Performance Tuning (Mobile First)
VFX adalah penyebab lag #1 di Mobile.
*   **Limit Rate:** Jangan spam partikel. Gunakan `Emit()` manual daripada `Rate` tinggi yang berjalan terus.
*   **Short Lifetime:** Partikel combat (darah/impact) maksimal 1-2 detik.
*   **Texture Size:** Maksimal 512x512 px untuk partikel.
*   **Transparency:** Terlalu banyak partikel transparan yang menumpuk (Overdraw) akan membunuh FPS. Gunakan partikel lebih sedikit tapi lebih besar ukurannya.
