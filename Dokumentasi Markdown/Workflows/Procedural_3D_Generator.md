# ⚔️ Workflow: Procedural 3D Generator (Blender Bridge)

Fitur paling canggih: Membuat aset 3D (Pedang) secara otomatis menggunakan script Python di Blender, diperintah lewat Web Dashboard.

## 📁 Struktur Sistem
1.  **Blender Script:** `LocalAnalytics/blender_scripts/sword_gen.py` (Script Python yang berisi rumus geometri pedang).
2.  **Server Agent:** Node.js menerima perintah `POST /generate-sword` -> Menjalankan `blender.exe` di background.
3.  **Output:** File `.fbx` hasil generate muncul di `LocalAnalytics/public/assets`.

## 🚀 Cara Menggunakan
1.  Pastikan **Blender** terinstall (Default path: `D:\Blender\blender.exe` - sesuaikan di `server.js` jika beda).
2.  Buka Web Dashboard (`http://localhost:3000` atau via HP).
3.  Klik tombol ungu **[⚔️ GENERATE SWORD]**.
4.  Tunggu notifikasi "✅ Ready".
5.  Buka folder `LocalAnalytics/public/assets`.
6.  **Drag & Drop** file `sword_xxxx.fbx` ke Roblox Studio.

## 🎨 Modifikasi
Anda bisa mengedit `sword_gen.py` untuk mengubah bentuk, warna, atau bahkan membuat benda lain (Pohon, Batu, Senjata Api).
