# 🍔 Klik Makan - Aplikasi Pemesanan Makanan

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue.svg?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10+-blue.svg?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange.svg?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green.svg)
</div>

<div align="center">
  <img src="https://i.imgur.com/6akAiVs.png" width="800" alt="Klik Makan Banner">
</div>

<br>

## 📖 Tentang Aplikasi

**Klik Makan** adalah aplikasi pemesanan makanan online yang dibangun dengan **Flutter** dan **Firebase**. Aplikasi ini memungkinkan pengguna untuk:
- Memesan makanan dari berbagai restoran
- Melakukan pembayaran dengan upload bukti transfer
- Melacak lokasi restoran dengan Google Maps
- Menerima notifikasi real-time tentang status pesanan
- Menyimpan makanan favorit

**Untuk Admin/Restoran**, aplikasi menyediakan dashboard untuk:
- Mengelola menu makanan
- Memantau pesanan masuk
- Mengatur informasi restoran

---

**Platform Pemesanan Makanan Modern dengan Fitur Lengkap**

</div>  

## 📱 Preview Aplikasi
<div align="center">
  <img src="https://i.imgur.com/2tycpxw.png" width="150">
  <img src="https://i.imgur.com/j72NCXR.png" width="150">
  <img src="https://i.imgur.com/vMh3X08.png" width="150">
  <img src="https://i.imgur.com/zAU5H8x.png" width="150">
  <img src="https://i.imgur.com/zAU5H8x.png" width="150">
  <img src="https://i.imgur.com/gEODdRi.png" width="150">
</div>

---

## ✨ Fitur Utama
### 👨‍🍳 **Untuk Pengguna:**
- ✅ **Login/Register** dengan Email & Google Sign-In
- ✅ **Pencarian & Kategori** makanan
- ✅ **Keranjang Belanja** dengan Provider state management
- ✅ **Favorit Makanan** (disimpan lokal)
- ✅ **Popup Promo Harian** (muncul sekali sehari)
- ✅ **Pembayaran** dengan upload bukti transfer
- ✅ **Generate PDF Invoice** setelah pembelian
- ✅ **Lokasi Restoran** dengan Google Maps
- ✅ **Notifikasi** pesanan (Firebase Cloud Messaging)
- ✅ **Riwayat Pesanan** lengkap

### 👨‍💼 **Untuk Admin:**
- 🔧 **Dashboard Admin** khusus
- 📊 **Kelola Menu** (tambah, edit, hapus)
- 📈 **Monitor Pesanan** real-time
- 👥 **Kelola Pengguna**
- 🏪 **Atur Informasi Restoran**

---

## 🛠️ Tech Stack
| Teknologi | Kegunaan |
|-----------|----------|
| **Flutter 3.19+** | Framework UI Cross-platform |
| **Dart 3.10+** | Bahasa pemrograman |
| **Firebase Auth** | Autentikasi pengguna |
| **Cloud Firestore** | Database NoSQL real-time |
| **Provider** | State management |
| **Google Maps** | Integrasi peta & lokasi |
| **PDF & Printing** | Generate invoice |
| **Firebase Messaging** | Push notification |
| **Shared Preferences** | Penyimpanan lokal |

### 📦 Dependencies Utama:
```yaml
# Firebase Core
firebase_core: ^3.6.0
firebase_auth: ^5.3.1
cloud_firestore: ^5.4.4

# UI & Utility
provider: ^6.1.2
google_fonts: ^6.2.1
cached_network_image: ^3.4.1

# Maps & Location
google_maps_flutter: ^2.5.0
geolocator: ^11.0.1

# PDF & Notifikasi
pdf: ^3.10.2
printing: ^5.11.2
firebase_messaging: ^14.7.0
```

## 📲 Download Aplikasi

### **Android APK:**
[![Download APK](https://img.shields.io/badge/Download-APK-brightgreen?style=for-the-badge&logo=android)](https://drive.google.com/file/d/1mvDp62oxkmXANYrbay_Gn5iOnJUX5i7N/view?usp=sharing)

**Cara Install:**
1. Klik tombol **Download APK** di atas
2. Buka file `.apk` yang sudah diunduh
3. Izinkan instalasi dari sumber tidak dikenal (jika diminta)
4. Install dan buka aplikasi

### **Build Sendiri dari Source:**
Jika ingin build sendiri dari source code:

1. **Clone repository:**
```bash
git clone https://github.com/[username-anda]/klik_makan.git
cd klik_makan
```
2. **install dependencies:**

```bash
flutter pub get
```
3. **Build APK**
```bash
flutter build apk --release
```
APK akan ada di: build/app/outputs/flutter-apk/app-release.apk

## 🔐 Login sebagai Admin

### **Informasi Login Admin:**
- Email: admin@klikmakan.com
- Password: admin123

## Cara Login Sebagai Admin
1. Install aplikasi Klik Makan
2. Klik **"Login"** di halaman awal
3. Masukkan email & password admin
4. Akan langsung diarahkan ke **Dashboard Admin**

### **Catatan Penting:**
- Email admin **tidak bisa** digunakan untuk pemesanan makanan biasa
- Hanya **satu akun admin** yang bisa dibuat (email khusus)
- Untuk keamanan, ganti password default setelah login pertama


## 🚀 Cara Penggunaan Aplikasi

### **Untuk Pengguna Baru:**
1. **Register/Login** - Daftar akun baru atau login dengan Google
2. **Pilih Makanan** - Browse menu dari berbagai restoran
3. **Tambahkan ke Keranjang** - Klik "+" pada makanan yang diinginkan
4. **Checkout** - Masukkan alamat pengiriman & pilih pembayaran
5. **Upload Bukti Transfer** - Setelah transfer, upload screenshot bukti
6. **Tunggu Pesanan** - Lacak status pesanan sampai diantar

### **Untuk Admin:**
1. **Login dengan email admin** (`admin@klikmakan.com`)
2. **Akses Dashboard** - Lihat semua pesanan masuk
3. **Kelola Menu** - Tambah/edit/hapus item makanan
4. **Konfirmasi Pembayaran** - Verifikasi bukti transfer dari user
5. **Update Status Pesanan** - Dari "Diproses" → "Dikirim" → "Selesai"

## 👥 Developer Team

| Role | Nama | Kontribusi |
|------|------|------------|
| **Project Manager** | Andika Firdaus | Koordinasi tim & manajemen proyek |
| **Frontend Dev** |Zidane Zamil Hakim | Implementasi UI dengan Flutter |
| **Backend Dev** | Muhammad Surya | Application Logic |
| **Database Developer** | Muhammad Yafi Heryawan | Manajemen Database |
| **Tester** | Fikriyandi Ihsan | Quality assurance & testing |
| **Documentation** | Ahmad Fauzy| Dokumentasi & deployment |

## 📄 Hak Cipta & Lisensi

**© 2026 Klik Makan** - Semua Hak Dilindungi

Aplikasi ini dilisensikan di bawah **Lisensi MIT**.
## 📞 Kontak & Dukungan Teknis

### **Sosial Media:**
[![Instagram](https://img.shields.io/badge/Instagram-@klikmakan-E4405F?logo=instagram)](https://www.instagram.com/andkafrdaus/)