# Error Log & Technical Constraints

Berikut adalah daftar error, bug, dan batasan teknis yang ditemukan selama pengembangan:

## Roblox API Constraints & Errors
*   **Instance:SetAttribute():** Roblox tidak mendukung penyimpanan fungsi, tabel, atau UserData dalam atribut; mencoba melakukannya menyebabkan error 'Function is not a supported attribute type'. Gunakan variabel Lua standar atau tabel untuk penyimpanan callback.
*   **Helper UI & Return Value:** Fungsi pembantu UI yang membungkus pembuatan instance (misalnya, `addStroke`, `addCorner`) harus mengembalikan Instance yang dibuat untuk memungkinkan penetapan properti atau chaining oleh pemanggil, mencegah error 'attempt to index nil'.
*   **Pencarian Remote yang Kuat:** Saat mengimplementasikan penemuan remote (mencari di beberapa folder), secara eksplisit periksa tipe objek menggunakan `IsA('RemoteFunction')` atau `IsA('RemoteEvent')` sebelum penugasan untuk mencegah error runtime.
*   **Forward Declarations di UI:** Dalam skrip UI sisi klien, gunakan deklarasi maju untuk variabel lokal (misalnya, `local updateRoomList`) di bagian atas file jika akan dipanggil oleh fungsi yang didefinisikan sebelumnya dalam skrip (seperti pendengar RemoteEvent) untuk mencegah error 'unknown global'.
*   **Batas Keypoint Sequence:** Konstruktor `ColorSequence` dan `NumberSequence` di Roblox memiliki batas ketat 20 keypoint per urutan; melebihi ini menyebabkan error runtime.
*   **Nilai Waktu Sequence:** Saat menghasilkan keypoint `NumberSequence` atau `ColorSequence` secara prosedural, pastikan nilai waktu meningkat secara ketat dengan menambahkan epsilon kecil (misalnya, 0.001).
*   **SortOrder UIListLayout:** Instance `UIListLayout` harus secara eksplisit menggunakan `SortOrder = Enum.SortOrder.LayoutOrder` untuk menjamin pemosisian elemen berdasarkan properti `LayoutOrder`.
*   **Matematika Tipe Aman:** Saat melakukan operasi matematika (`math.max`, `math.min`) pada nilai konfigurasi, secara eksplisit tegakkan tipe angka menggunakan `tonumber(value) or default` untuk menghindari error dengan `nil`.
*   **Tweening Scale:** Saat menganimasikan penskalaan UI di `TweenService` yang menggunakan Scale, pastikan properti target menggunakan nilai `UDim2.new(scaleX, offsetX, scaleY, offsetY)` daripada `UDim2.fromOffset` untuk menjaga responsivitas.
*   **Larangan CanvasGroup:** Instance `CanvasGroup` dilarang keras dalam proyek ini; alternatif seperti overlay `ImageLabel` harus digunakan untuk efek.
*   **InvokeServer Pcall:** Panggilan `RemoteFunction:InvokeServer()` sisi klien harus dibungkus dalam `pcall` untuk mencegah crash skrip karena error server atau timeout.
*   **Tweening UIGradient:** Roblox `TweenService` tidak dapat men-tween properti `Transparency` dari `UIGradient`. Gunakan loop kustom (misalnya, `RunService`) atau penumpukan frame.
*   **Enum Font:** `Enum.Font.BlackOpsOne` dan `Enum.Font.RussoOne` bukan anggota yang valid dari `Enum.Font` di Roblox.
*   **Enum Material:** Smoke bukan anggota yang valid dari "Enum.Material".
*   **Enum Material (Paper):** Paper bukan anggota yang valid dari "Enum.Material". Gunakan `Enum.Material.SmoothPlastic` atau material valid lainnya.
*   **Defensive FindFirstChild:** Selalu gunakan pemeriksaan defensif (misalnya, `if not element then return end`) sebelum mengakses field elemen UI yang dihasilkan secara terprogram.
*   **Instance.new Attachment:** Saat membuat instance `Attachment`, secara eksplisit instansiasi objek dan atur propertinya secara terpisah. Hindari sintaks `Instance.new("Attachment", parent, cframe)`.
*   **ImageTransparency pada Frame:** Mencoba mengatur `ImageTransparency` pada instance `Frame` menyebabkan error; gunakan `BackgroundTransparency` sebagai gantinya.
*   **Keamanan Konkatenasi String:** Selalu bungkus variabel dalam `tostring() or default` saat menggabungkan string.
*   **Argumen Anak pada Helper UI:** Fungsi pembantu UI `create` mengharuskan anak-anak diteruskan sebagai **argumen ketiga** (tabel).
*   **Type Checking Luau:** Argumen untuk fungsi manipulasi string (misalnya, `string.upper`) harus secara eksplisit dilemparkan ke string atau diperiksa untuk `nil`.
*   **TextLabel LetterSpacing:** Instance `TextLabel` tidak mendukung properti `LetterSpacing`.
*   **Akses Anggota UI:** Selalu gunakan `FindFirstChild` atau simpan referensi saat mengakses elemen UI yang dibuat secara prosedural untuk menghindari error "is not a valid member of" jika hierarki belum direplikasi atau berubah.
*   **ProximityUIHandler Removed:** Modul `ProximityUIHandler` telah dihapus dan diganti dengan koneksi `ProximityPrompt` langsung dalam LocalScripts untuk mengurangi kompleksitas dan error callback.
*   **Invalid Member Assignment:** Jangan mencoba menetapkan properti kustom (seperti `Title`, `ItemName`, `Rarity`) langsung ke instance Roblox (seperti `Frame`). Gunakan tabel terpisah untuk referensi UI atau cari elemen dengan `FindFirstChild`.
*   **UI Member Access Safety:** Saat mengakses hierarki UI yang dalam (misalnya `Panel.Section.Button`), jangan pernah menggunakan notasi titik langsung (`.`) tanpa verifikasi. Selalu gunakan `FindFirstChild` bertingkat atau simpan referensi elemen saat pembuatannya untuk mencegah error "is not a valid member of" jika elemen gagal dimuat atau belum ada.
*   **String Manipulation Safety:** Fungsi string Lua (seperti `string.upper`, `string.lower`, `string.len`) akan melempar error jika diberikan `nil`. Selalu berikan nilai default (misalnya `str or ""`) sebelum memproses data dari remote event.
*   **Safe UI Traversal:** Ketika struktur UI berubah (misalnya memindahkan elemen ke dalam parent baru), perbarui semua referensi kode. Gunakan `FindFirstChild` bertingkat dan kondisi fallback untuk mencegah error "not a valid member" selama hot-reload atau jika struktur tidak sinkron.
*   **Forward Declarations untuk Fungsi:** Jika fungsi A dipanggil oleh fungsi B tetapi didefinisikan setelah B dalam file, gunakan forward declaration di bagian atas file: `local functionA` lalu assign nanti `functionA = function(...) end`. Ini mencegah error 'unknown global'.
*   **Length Operator dalam string.format:** Luau type checker kadang gagal mengenali `#table` sebagai number dalam `string.format`. Simpan hasil ke variabel lokal terlebih dahulu: `local size = #queue` lalu gunakan `size` dalam format string.
