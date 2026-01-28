import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import InvoiceScreen agar bisa dipanggil
import 'invoice_screen.dart'; 

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  String formatRupiah(int price) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu konfirmasi': return Colors.orange;
      case 'diproses': return Colors.blue;
      case 'diantar': return Colors.purple;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Riwayat Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('order_date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("Belum ada riwayat pesanan", style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final orderDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orderDocs.length,
            itemBuilder: (context, index) {
              var data = orderDocs[index].data() as Map<String, dynamic>;
              String docId = orderDocs[index].id; // Ambil ID Dokumen untuk Invoice
              
              String status = data['status'] ?? 'Menunggu';
              int total = data['summary']?['total'] ?? 0;
              Timestamp? timestamp = data['order_date'];
              String dateStr = timestamp != null 
                  ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate()) 
                  : '-';
              List<dynamic> items = data['items'] ?? [];

              // PERBAIKAN: Dibungkus dengan InkWell agar bisa diklik
              return InkWell(
                onTap: () {
                  // Berpindah ke halaman Invoice dengan membawa data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceScreen(
                        orderData: data,
                        orderId: docId,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade100),
                    // ignore: deprecated_member_use
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateStr, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status, 
                              style: GoogleFonts.poppins(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                color: _getStatusColor(status)
                              )
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 20),
                      
                      ...items.take(2).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 50, height: 50,
                                  color: Colors.grey.shade100,
                                  child: CachedNetworkImage(
                                    imageUrl: item['image_url'] ?? '',
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: Colors.grey, size: 20),
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Menu', 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text("${item['quantity']} porsi", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      if (items.length > 2)
                        Text("+ ${items.length - 2} menu lainnya...", style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange)),

                      const SizedBox(height: 10),
                      const Divider(),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Pembayaran", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(formatRupiah(total), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Lihat Detail >",
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}