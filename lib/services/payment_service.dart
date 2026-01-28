import 'dart:async'; // Untuk simulasi loading
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:klik_makan/screens/invoice_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData; 
  // Parameter untuk menangkap metode pembayaran dari halaman sebelumnya
  final String paymentMethod; 

  const PaymentScreen({
    super.key, 
    required this.orderData, 
    required this.paymentMethod // Wajib diisi
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _imageFile;
  bool _isLoading = false;

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 20, // Kompres agar database tidak penuh
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
    // Validasi: Kalau bukan COD, wajib upload bukti
    if (widget.paymentMethod != 'COD' && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wajib upload bukti pembayaran!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi loading 2 detik biar terlihat seperti proses API
    await Future.delayed(const Duration(seconds: 2));

    try {
      String? base64Image;

      // Hanya proses gambar jika ada filenya
      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      // Siapkan data final untuk disimpan ke Firestore
      Map<String, dynamic> finalData = {...widget.orderData};
      
      finalData['payment_method'] = widget.paymentMethod;
      finalData['proof_image'] = base64Image ?? ""; 
      
      // Tentukan Status
      if (widget.paymentMethod == 'COD') {
        finalData['status'] = 'Diproses'; 
      } else {
        finalData['status'] = 'Menunggu Verifikasi'; 
      }
      
      finalData['created_at'] = DateTime.now().toIso8601String();

      // Simpan ke Database
      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add(finalData);
      String orderId = orderRef.id;

      if (!mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();

      // Pindah ke Halaman Invoice
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InvoiceScreen(
            orderData: finalData,
            orderId: orderId,
          ),
        ),
      );

    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalBayar = widget.orderData['summary']['total'];
    String method = widget.paymentMethod;

    return Scaffold(
      appBar: AppBar(title: Text("Bayar via $method")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- INFO TOTAL HARGA ---
            const Text("Total Tagihan", style: TextStyle(color: Colors.grey)),
            Text(formatRupiah(totalBayar), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 30),

            // --- TAMPILAN DINAMIS SESUAI PILIHAN ---
            
            // 1. JIKA TRANSFER BANK
            if (method == 'Transfer Bank') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bank BCA", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("123-456-7890", style: TextStyle(fontSize: 18)),
                    Text("A.N: Admin Klik Makan"),
                  ],
                ),
              ),
            ],

            // 2. JIKA QRIS (E-WALLET)
            if (method == 'QRIS') ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    // --- INI BAGIAN YANG SAYA PERBAIKI ---
                    // Menggunakan API qrserver untuk generate QR Code dalam format PNG
                    Image.asset(
                      "assets/qris_pembayaran.png",
                      height: 250, 
                      width: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: Text("Gagal memuat QR Code")),
                        );
                      },
                    ),
                    // -------------------------------------
                  ],
                ), 
              ),
              const SizedBox(height: 10),
              const Text("Scan QRIS di atas pakai GoPay/OVO/Dana", textAlign: TextAlign.center),
            ],

            // 3. JIKA COD
            if (method == 'COD') ...[
               Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                child: const Column(
                  children: [
                    Icon(Icons.motorcycle, size: 50, color: Colors.orange),
                    SizedBox(height: 10),
                    Text("Siapkan uang pas saat kurir sampai.", textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // --- AREA UPLOAD FOTO (HANYA MUNCUL KALAU BUKAN COD) ---
            if (method != 'COD') ...[
              const Align(alignment: Alignment.centerLeft, child: Text("Bukti Pembayaran:")),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.upload_file), Text("Upload Bukti")],
                        ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            
            // --- TOMBOL AKSI ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      method == 'COD' ? "Pesan Sekarang" : "Kirim Konfirmasi", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }
}