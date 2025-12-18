# 🧟 Dokumentasi Entities (Enemies & NPCs)

Data mengenai entitas hidup: Zombie, Bosses, dan Friendly NPCs.

## 💀 Enemies (Zombies)
Musuh standar yang muncul dalam wave.

| Tipe | Nama Script | Karakteristik |
| :--- | :--- | :--- |
| **Walker** | `ZombieModule` | Zombie standar. Kecepatan sedang. |
| **Runner** | `ZombieModule` | HP Rendah, Kecepatan Tinggi. Muncul banyak di Fast Wave. |
| **Shooter** | `ZombieModule` | Serangan jarak jauh. Meninggalkan genangan asam. |
| **Minion** | `VolatileMinionVFX`| Kecil, cepat, bisa meledak/racun. |

### Bosses
Musuh utama dengan HP bar besar dan fase serangan.
1.  **Plague Titan** (`Boss1Module`): Tank besar dengan serangan area asam.
2.  **The Crusher** (`Boss2Module`): Serangan fisik berat dan gempa (`EarthVFX`).
3.  **The Hive Mother** (`Boss3Module`): Summoner yang memanggil larva.

## 👥 Friendly NPCs
Karakter yang membantu pemain di Lobby.

*   **Alexander (The Handler):**
    *   *Lokasi:* Command Center.
    *   *Peran:* Memberikan narasi, briefing misi, dan petunjuk cerita.
*   **Quartermaster:**
    *   *Lokasi:* Center Train Car.
    *   *Peran:* Penjual senjata dan penukaran poin.
