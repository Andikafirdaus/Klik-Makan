import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import 'invoice_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String paymentMethod;

  const PaymentScreen({
    super.key,
    required this.orderData,
    required this.paymentMethod,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _imageFile;
  bool _isLoading = false;

  String formatRupiah(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
    if (widget.paymentMethod != 'COD' && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wajib upload bukti pembayaran!")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      String? base64Image;

      if (_imageFile != null) {
        List<int> imageBytes = await _imageFile!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      Map<String, dynamic> finalData = {...widget.orderData};

      finalData['payment_method'] = widget.paymentMethod;
      finalData['proof_image'] = base64Image ?? "";

      if (widget.paymentMethod == 'COD') {
        finalData['status'] = 'Diproses';
      } else {
        finalData['status'] = 'Menunggu Verifikasi';
      }

      finalData['created_at'] = DateTime.now().toIso8601String();

      DocumentReference orderRef =
          await FirebaseFirestore.instance.collection('orders').add(finalData);
      String orderId = orderRef.id;

      if (!mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalBayar = widget.orderData['summary']['total'];
    String method = widget.paymentMethod;

    return Scaffold(
      appBar: AppBar(
        title: Text("Bayar via $method"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN INFO TOTAL ---
            const SizedBox(height: 10),
            const Text(
              "Total Tagihan",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formatRupiah(totalBayar),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 1),

            // --- LOGIKA TAMPILAN BERDASARKAN METODE ---

            // 1. TAMPILAN JIKA TRANSFER BANK
            if (method == 'Transfer Bank') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Transfer Bank",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Bank BCA",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "123-456-7890",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "A.N: Admin Klik Makan",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            // 2. TAMPILAN JIKA QRIS (E-WALLET) - DIPERBESAR
            if (method == 'QRIS') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // JUDUL QRIS
                    Text(
                      "QR Code Pembayaran",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Scan dengan aplikasi e-wallet Anda",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // CONTAINER UTAMA QRIS
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          // GAMBAR QRIS - DIPERBESAR
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: _buildQRISImage(),
                          ),
                          const SizedBox(height: 20),

                          // INFORMASI TAMBAHAN
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Petunjuk Pembayaran",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "1. Buka aplikasi e-wallet Anda\n"
                                  "2. Pilih fitur scan QRIS\n"
                                  "3. Arahkan kamera ke QR code di atas\n"
                                  "4. Konfirmasi pembayaran",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3. TAMPILAN JIKA COD
            if (method == 'COD') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.motorcycle,
                      size: 70,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Bayar tunai saat kurir sampai",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tidak perlu upload bukti transfer",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),
            const Divider(thickness: 1),
            const SizedBox(height: 20),

            // --- TOMBOL UPLOAD (HILANG JIKA COD) ---
            if (method != 'COD') ...[
              Text(
                "Bukti Pembayaran",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Upload screenshot bukti pembayaran Anda",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _imageFile != null ? Colors.green[50] : Colors.grey[50],
                    border: Border.all(
                      color: _imageFile != null ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "Terupload",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Klik untuk Upload Bukti",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Format: JPG/PNG",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              if (_imageFile == null)
                Text(
                  "*Wajib upload bukti pembayaran",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],

            const SizedBox(height: 40),

            // --- TOMBOL AKSI ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            method == 'COD'
                                ? Icons.shopping_cart_checkout
                                : Icons.send,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            method == 'COD'
                                ? "Pesan Sekarang"
                                : "Kirim Konfirmasi",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI UNTUK MEMBANGUN GAMBAR QRIS (DIPERBESAR) ---
  Widget _buildQRISImage() {
    return Container(
      width: 250, // LEBIH BESAR
      height: 250, // LEBIH BESAR
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Image.asset(
        'assets/qris.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // FALLBACK JIKA GAMBAR TIDAK ADA
          return Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 80,
                  // ignore: deprecated_member_use
                  color: Colors.orange.withOpacity(0.7),
                ),
                const SizedBox(height: 15),
                Text(
                  "QRIS Code",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Silakan bayar via QRIS dan upload bukti di bawah",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    // ignore: deprecated_member_use
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Jumlah: ${formatRupiah(widget.orderData['summary']['total'])}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}