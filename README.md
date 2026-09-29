# AUDIRA RECEIPT 🧾
> **Thermal Receipt Printer Application for Android**

Aplikasi Android profesional berbasis **Flutter & Material 3** yang difokuskan untuk pembuatan kwitansi dan pencetakan langsung (*direct printing*) ke **Bluetooth Thermal Printer** menggunakan perintah standar **ESC/POS** byte-level.

Aplikasi dirancang **100% Offline-First**, cepat, ringan, tidak memerlukan akun login, dan menyimpan semua data secara lokal menggunakan database **SQLite**.

---

## 🌟 Fitur Utama

- ⚡ **Direct ESC/POS Printing**: Data dikirim langsung ke thermal printer via Bluetooth Serial RFCOMM (bukan rendering PDF yang lambat).
- 📏 **Dual Paper Size Support**:
  - **Paper 58mm** (Lebar 32 karakter, format ringkas)
  - **Paper 80mm** (Lebar 48 karakter, layout komprehensif dua kolom & tanda tangan lengkap)
- 🔢 **Penomoran Kwitansi Otomatis**: Format `AUD-YYYY-00001` (misal `AUD-2026-00001`, `AUD-2026-00002`), kebal terhadap nomor duplikat.
- 🗣️ **Terbilang Otomatis Bahasa Indonesia**: Mengubah nominal secara *real-time* menjadi kalimat terbilang (contoh: `Rp 1.500.000` ➔ *"Satu Juta Lima Ratus Ribu Rupiah"*).
- 👁️ **Realistic Thermal Preview**: Menampilkan pratinjau digital bertekstur kertas thermal dan font monospace sebelum mencetak.
- 🖨️ **Printer Management & Discovery**:
  - Scan perangkat Bluetooth
  - Indikator status koneksi (🟢 Terhubung, 🔴 Terputus, 🟡 Menyambungkan)
  - Simpan printer default
  - Fitur **Test Print** ESC/POS (uji gaya font normal/tebal/garis bawah, alignment, dan auto-cut)
  - Konfigurasi kepadatan cetak (density) dan auto-cutter (`GS V`)
- 📊 **Dashboard & Statistik Harian**:
  - Total kwitansi hari ini
  - Total omset transaksi hari ini
  - Tombol aksi cepat dan kwitansi terbaru
- 📜 **Riwayat & Pencarian Kwitansi**:
  - Pencarian nomor kwitansi, nama pembayar, atau keterangan
  - Filter rentang tanggal
  - Cetak ulang (*Reprint*), edit kwitansi, dan hapus dengan dialog konfirmasi
- 🏢 **Profil Perusahaan (Header Kwitansi)**:
  - Ubah nama toko, alamat, telepon, dan email yang akan dicetak di kop atas kwitansi

---

## 🏗️ Struktur Project

```
lib/
├── main.dart                               # Entry point, inisialisasi SQLite & orientations
├── app/
│   ├── app.dart                            # MultiProvider & MaterialApp root
│   ├── routes.dart                         # Route generator & route constants
│   └── theme.dart                          # Material 3 Theme (#2563EB primary, modern card styling)
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart                 # Color palette tokens
│   │   └── app_constants.dart              # Default paper sizes, prefixes, constants
│   ├── services/
│   │   ├── bluetooth_service.dart          # Bluetooth scan, connect, disconnect, state stream
│   │   ├── printer_service.dart            # ESC/POS printer pipeline & error handling
│   │   └── receipt_service.dart            # Business logic, state, and dashboard stats
│   └── utils/
│       ├── currency_formatter.dart         # Rupiah formatting & live currency text input
│       ├── number_to_words.dart            # Algoritma Terbilang Rupiah Bahasa Indonesia
│       └── printer_utils.dart              # Byte ESC/POS command sequences (58mm & 80mm)
│
├── database/
│   ├── database.dart                       # SQLite database initializer & seeds
│   └── receipt_repository.dart             # CRUD Kwitansi, Company, Printer & Settings
│
├── models/
│   ├── receipt.dart                        # Model Kwitansi
│   ├── company.dart                        # Model Profil Bisnis / Perusahaan
│   ├── thermal_printer.dart                # Model Printer Bluetooth
│   └── app_settings.dart                   # Model Konfigurasi Aplikasi & ESC/POS
│
├── features/
│   ├── splash/
│   │   └── splash_page.dart                # Splash screen dengan logo dan transisi halus
│   ├── dashboard/
│   │   └── dashboard_page.dart             # Dashboard utama, statistik, & bottom navigation
│   ├── receipt/
│   │   ├── receipt_form_page.dart          # Form pembuatan & edit kwitansi
│   │   ├── receipt_preview_page.dart       # Preview digital mirip kertas thermal
│   │   ├── receipt_history_page.dart       # Riwayat transaksi, search, & filter tanggal
│   │   └── receipt_detail_page.dart        # Detail transaksi & aksi reprint
│   ├── printer/
│   │   ├── printer_page.dart               # Manajemen printer, status, & opsi cetak
│   │   ├── bluetooth_scan_page.dart        # Scan & koneksi printer Bluetooth
│   │   └── printer_test_page.dart          # Halaman pengujian cetak ESC/POS
│   └── settings/
│       ├── settings_page.dart              # Pengaturan nomor urut, auto-cut, dll.
│       └── company_profile_page.dart       # Pengaturan identitas toko / kop surat
│
└── widgets/
    ├── receipt_card.dart                   # Widget kartu kwitansi interaktif
    ├── amount_field.dart                   # Field nominal dengan live terbilang preview
    ├── printer_status.dart                 # Widget indikator status printer
    ├── quick_action_card.dart              # Kartu shortcut aksi cepat dashboard
    └── custom_dialogs.dart                 # Dialog konfirmasi, print retry dialog, snackbars
```

---

## 🗄️ Skema Database SQLite

Database lokal tersimpan di `audira_receipt.db`:

### 1. Tabel `receipts`
| Field | Tipe | Keterangan |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | ID internal |
| `receipt_number` | TEXT NOT NULL UNIQUE | Nomor unik (contoh: `AUD-2026-00001`) |
| `date` | TEXT NOT NULL | Tanggal transaksi (ISO8601) |
| `received_from` | TEXT NOT NULL | Nama pihak pembayar |
| `amount` | REAL NOT NULL | Nominal uang |
| `amount_words` | TEXT NOT NULL | Terbilang dalam Bahasa Indonesia |
| `description` | TEXT NOT NULL | Untuk pembayaran |
| `payment_method` | TEXT NOT NULL | Tunai / Transfer / QRIS / dll. |
| `notes` | TEXT | Catatan tambahan |
| `created_at` | TEXT NOT NULL | Timestamp pembuatan |
| `updated_at` | TEXT NOT NULL | Timestamp perubahan terakhir |

### 2. Tabel `company`
Menyimpan identitas toko/usaha (nama, alamat, telepon, email, logo).

### 3. Tabel `printer`
Menyimpan daftar printer Bluetooth yang pernah dihubungkan, MAC address, ukuran kertas (58mm/80mm), dan status default.

### 4. Tabel `settings`
Menyimpan prefix kwitansi (`AUD`), nomor urut terakhir, default paper size, dan konfigurasi auto-cut.

---

## 📱 Konfigurasi Permission Android

Izin Bluetooth telah dikonfigurasi pada `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 11 ke bawah (API <= 30) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="30" />

<uses-feature android:name="android.hardware.bluetooth" android:required="false" />
```

---

## 🚀 Panduan Instalasi & Menjalankan

### Persyaratan Sistem
- Flutter SDK `^3.12` / Flutter 3.20+
- Dart SDK `^3.0`
- Android Studio / Android SDK dengan build-tools & platform-tools

### 1. Unduh Dependensi
```bash
flutter pub get
```

### 2. Jalankan Pengujian (Unit & Smoke Tests)
```bash
flutter test
```
Semua 17 unit test mencakup:
- Konversi terbilang Rupiah
- Format mata uang
- Generator byte ESC/POS
- Lebar karakter kertas 58mm & 80mm
- Model serialisasi SQLite

### 3. Jalankan Aplikasi di Perangkat / Emulator
Pastikan perangkat Android terhubung via USB Debugging atau aktifkan emulator:
```bash
flutter run
```

### 4. Build APK Release untuk Android
Untuk menghasilkan file installer APK siap pakai:
```bash
flutter build apk --release
```
File APK akan berada di:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🖨️ Cara Menghubungkan Printer Bluetooth

1. **Nyalakan Printer**: Pastikan printer thermal Bluetooth dalam posisi ON dan kertas terpasang dengan benar.
2. **Pairing di Android**:
   - Buka menu **Pengaturan Bluetooth** di HP Android Anda.
   - Cari nama printer (contoh: *RPP02N*, *MTP-II*, *XP-58*, *POS-58*, *TM-T88*).
   - Masukkan PIN pairing bawaan printer (biasanya `0000` atau `1234`).
3. **Buka AUDIRA RECEIPT**:
   - Buka menu **Printer** di navigasi bawah atau ketuk kartu status printer di Dashboard.
   - Ketuk **Scan Printer**.
   - Pilih ukuran kertas (58mm atau 80mm).
   - Ketuk **Hubungkan** pada nama printer Anda.
   - Status akan berubah menjadi **🟢 Printer Terhubung**.
4. **Lakukan Test Print**:
   - Ketuk **Test Print Thermal** untuk memastikan printer mencetak hasil uji ESC/POS dengan rapi.

---

## 🛡️ Error Handling yang Ditangani

1. **Bluetooth OFF**: Muncul notifikasi ramah untuk menyalakan Bluetooth tanpa *crash*.
2. **Printer Terputus / Di luar Jangkauan**: Muncul dialog pemulihan dengan tombol **[Coba Lagi]** dan **[Pilih Printer]**.
3. **Cegah Nomor Duplikat**: Menggunakan pengecekan ganda atomik di SQLite dan settings counter.
4. **Validasi Form**: Mencegah input nominal 0 atau negatif, serta memvalidasi nama pembayar dan tujuan pembayaran.

---

## 📄 Lisensi

Project ini dilisensikan di bawah lisensi **MIT License** - hak cipta oleh **Audira (Agus Dwi R)**. Lihat file [LICENSE](LICENSE) untuk rincian lengkap.

