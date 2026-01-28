import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Tambahkan halaman notifikasi
import 'notification_screen.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const InvoiceScreen({
    super.key,
    required this.orderData,
    required this.orderId,
  });

  String formatRupiah(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  // --- FUNGSI UNTUK DOWNLOAD GAMBAR UNTUK PDF ---

  // --- FUNGSI PDF YANG DIPERBAIKI ---
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final Map<String, dynamic> summary = orderData['summary'] ?? {};
    final List<dynamic> items = orderData['items'] ?? [];
    final Timestamp orderDate = orderData['order_date'] ?? Timestamp.now();
    final String status = orderData['status'] ?? 'Menunggu Konfirmasi';
    final String paymentMethod = orderData['payment_method'] ?? 'Tunai';
    final String customerName = orderData['customer_name'] ?? 'Pelanggan';
    final String address = orderData['address'] ?? '-';
    final String type = orderData['type'] ?? 'Delivery';
    final String note = orderData['note'] ?? 'Tidak ada catatan';

    // Load font yang mendukung karakter Indonesia
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // HEADER
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Klik Makan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                        pw.Text('Restoran & Kafe', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.orange),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(status, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                // INFORMASI INVOICE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NO INVOICE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(orderId, style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TANGGAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(formatDate(orderDate), style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),
                
                // INFORMASI PELANGGAN
                pw.Text('INFORMASI PELANGGAN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfInfoRow('Nama', customerName),
                      _buildPdfInfoRow('Metode', '$type • $paymentMethod'),
                      if (address != '-') _buildPdfInfoRow('Alamat', address),
                      _buildPdfInfoRow('Catatan', note),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),
                
                // DETAIL PESANAN
                pw.Text('DETAIL PESANAN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // HEADER TABLE
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text('ITEM', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text('HARGA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text('QTY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(10),
                          child: pw.Text('SUBTOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // ITEM ROWS
                    for (var item in items)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(item['name'] ?? 'Menu', style: const pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(formatRupiah(item['price'] ?? 0), style: const pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text('${item['quantity'] ?? 1}', style: const pw.TextStyle(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(10),
                            child: pw.Text(
                              formatRupiah((item['price'] ?? 0) * (item['quantity'] ?? 1)),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 25),
                
                // RINGKASAN PEMBAYARAN
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(formatRupiah(summary['subtotal'] ?? 0), style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Ongkos Kirim', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(formatRupiah(summary['shipping_cost'] ?? 0), style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Divider(),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            formatRupiah(summary['total'] ?? 0),
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // FOOTER
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Terima kasih telah berbelanja di Klik Makan!',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );
    return await pdf.save();
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI AKSI ---
  Future<void> _downloadAndSavePDF(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Membuat PDF...", style: GoogleFonts.poppins()),
          backgroundColor: Colors.blue,
        ),
      );
      final pdfBytes = await _generatePdf();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoice_$orderId.pdf');
      await file.writeAsBytes(pdfBytes);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF berhasil disimpan", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice Pesanan Klik Makan - $orderId');
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _previewPdf(BuildContext context) async {
    try {
      final pdfBytes = await _generatePdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'invoice_klikmakan_$orderId.pdf',
        subject: 'Invoice Pesanan Klik Makan',
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FUNGSI UNTUK NAVIGASI KE NOTIFIKASI ---
  void _navigateToNotification(BuildContext context) {
    // Hapus semua halaman sebelumnya dan arahkan ke NotificationScreen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
      (route) => false, // Hapus semua route sebelumnya
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> summary = orderData['summary'] ?? {};
    final List<dynamic> items = orderData['items'] ?? [];
    final Timestamp orderDate = orderData['order_date'] ?? Timestamp.now();
    final String status = orderData['status'] ?? 'Menunggu Konfirmasi';
    final String paymentMethod = orderData['payment_method'] ?? 'Tunai';
    final String customerName = orderData['customer_name'] ?? 'Pelanggan';
    final String address = orderData['address'] ?? '-';
    final String type = orderData['type'] ?? 'Delivery';
    final String note = orderData['note'] ?? 'Tidak ada catatan';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Invoice Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'print') {
                _printPdf(context);
              // ignore: curly_braces_in_flow_control_structures
              } else if (value == 'share') _downloadAndSavePDF(context);
              // ignore: curly_braces_in_flow_control_structures
              else if (value == 'preview') _previewPdf(context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'preview', child: Text("Preview PDF")),
              const PopupMenuItem(value: 'print', child: Text("Print")),
              const PopupMenuItem(value: 'share', child: Text("Share PDF")),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER INVOICE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Klik Makan", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                            Text("Restoran & Kafe", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(status)),
                        ),
                        child: Text(status, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _getStatusColor(status), fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("NO INVOICE", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(orderId, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("TANGGAL", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(formatDate(orderDate), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // INFORMASI PELANGGAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Informasi Pelanggan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  _buildInfoRow("Nama", customerName),
                  _buildInfoRow("Metode", "$type • $paymentMethod"),
                  if (address != '-') _buildInfoRow("Alamat", address),
                  _buildInfoRow("Catatan", note),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // DAFTAR PESANAN
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Detail Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ...items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: item['image_url'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.fastfood),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Menu',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  formatRupiah(item['price'] ?? 0),
                                  style: GoogleFonts.poppins(color: Colors.orange, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${item['quantity'] ?? 1}x", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              Text(
                                formatRupiah((item['price'] ?? 0) * (item['quantity'] ?? 1)),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // RINGKASAN PEMBAYARAN
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  _buildSummaryRow("Subtotal", summary['subtotal'] ?? 0),
                  _buildSummaryRow("Ongkos Kirim", summary['shipping_cost'] ?? 0),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        formatRupiah(summary['total'] ?? 0),
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // CATATAN PEMBAYARAN
            if (paymentMethod == 'Transfer Bank' || paymentMethod == 'QRIS')
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Text(
                          "Informasi Pembayaran",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Silakan lakukan pembayaran sesuai nominal di atas. Setelah pembayaran, pesanan akan diproses.",
                      style: GoogleFonts.poppins(color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),

            // TOMBOL AKSI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _navigateToNotification(context), // UBAH INI
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: Text(
                      "Lihat Riwayat",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _previewPdf(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Cetak PDF",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PENDUKUNG ---
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.grey.shade700),
          ),
          Text(
            formatRupiah(value),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Selesai')) return Colors.green;
    if (status.contains('Diproses')) return Colors.blue;
    if (status.contains('Dikirim')) return Colors.purple;
    return Colors.orange;
  }
}