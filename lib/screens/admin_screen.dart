import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  String _pageTitle = "Pesanan Masuk";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  
  String _selectedCategory = 'Kopi';
  final List<String> _categories = ['Kopi', 'Non-Kopi', 'Snack', 'Makanan'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  void _onItemTapped(int index, String title) {
    setState(() {
      _selectedIndex = index;
      _pageTitle = title;
    });
    Navigator.pop(context);
  }

  // --- FITUR: LIHAT GAMBAR FULL SCREEN (ZOOM) ---
  void _showFullImage(String base64Image) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA TOMBOL STATUS YANG BARU (CERDAS) ---
  Widget _buildActionButtons(String docId, String status, bool isDelivery) {
    // 1. Jika Pesanan Baru Masuk
    if (status == 'Menunggu Konfirmasi' || status == 'Menunggu Verifikasi') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text("Tolak"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red),
              onPressed: () => _updateStatus(docId, "Dibatalkan"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text("Terima & Proses"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () => _updateStatus(docId, "Diproses"),
            ),
          ),
        ],
      );
    }

    // 2. Jika Sedang Diproses (Dimasak/Disiapkan)
    if (status == 'Diproses') {
      if (isDelivery) {
        // KHUSUS DELIVERY: Tombolnya "Antar Pesanan"
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delivery_dining, size: 18),
            label: const Text("Mulai Pengantaran (Kurir Jalan)"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () => _updateStatus(docId, "Diantar"),
          ),
        );
      } else {
        // KHUSUS PICKUP/AMBIL SENDIRI: Langsung Selesai
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text("Pesanan Siap & Selesai"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => _updateStatus(docId, "Selesai"),
          ),
        );
      }
    }

    // 3. Jika Sedang Diantar (Khusus Delivery)
    if (status == 'Diantar') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.done_all, size: 18),
          label: const Text("Pesanan Sampai (Selesai)"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => _updateStatus(docId, "Selesai"),
        ),
      );
    }

    // 4. Jika Sudah Selesai / Batal
    return const SizedBox.shrink(); // Tidak ada tombol lagi
  }

  void _updateStatus(String docId, String status) {
    FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': status});
  }

  // --- FORM INPUT MENU ---
  void _showProductForm({String? docId, Map<String, dynamic>? data}) {
    if (data != null) {
      _nameController.text = data['name'];
      _descController.text = data['description'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _imageController.text = data['image_url'] ?? '';
      _selectedCategory = data['category'] ?? 'Kopi';
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _imageController.clear();
      _selectedCategory = 'Kopi';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(docId == null ? "Tambah Menu" : "Edit Menu", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, "Nama Menu"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: Colors.white,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              _buildTextField(_priceController, "Harga", isNumber: true),
              const SizedBox(height: 10),
              _buildTextField(_imageController, "Link Gambar (URL)"),
              const SizedBox(height: 10),
              _buildTextField(_descController, "Deskripsi", maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _priceController.text.isEmpty) return;
              Navigator.pop(context);

              try {
                Map<String, dynamic> productData = {
                  'name': _nameController.text,
                  'category': _selectedCategory,
                  'price': int.parse(_priceController.text),
                  'image_url': _imageController.text.isEmpty ? 'https://via.placeholder.com/150' : _imageController.text,
                  'description': _descController.text,
                  'rating': 4.5,
                  'created_at': Timestamp.now(), 
                };

                if (docId == null) {
                  await FirebaseFirestore.instance.collection('products').add(productData);
                } else {
                  productData.remove('created_at'); 
                  await FirebaseFirestore.instance.collection('products').doc(docId).update(productData);
                }
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil disimpan!")));
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              } finally {
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  void _deleteProduct(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Menu?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('products').doc(docId).delete();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_pageTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
           Padding(
            padding: const EdgeInsets.only(right: 15),
            child: CircleAvatar(backgroundColor: Colors.orange.shade50, child: const Icon(Icons.person, color: Colors.orange)),
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange])),
              accountName: Text("Admin Klik Makan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text("admin@klikmakan.com", style: GoogleFonts.poppins()),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 50, color: Colors.orange)),
            ),
            _buildDrawerItem(0, "Transaksi Pesanan", Icons.shopping_bag_outlined),
            _buildDrawerItem(1, "Kelola Menu", Icons.restaurant_menu),
            _buildDrawerItem(2, "Laporan Pendapatan", Icons.monetization_on_outlined),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text("Keluar", style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () async => await AuthService().logout(),
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(onPressed: () => _showProductForm(), backgroundColor: Colors.orange, child: const Icon(Icons.add, color: Colors.white))
          : null,
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: isSelected ? Colors.orange.shade50 : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
        title: Text(title, style: GoogleFonts.poppins(color: isSelected ? Colors.orange : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () => _onItemTapped(index, title),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildIncomingOrders();
      case 1: return _buildMenuManagement();
      case 2: return _buildRevenueReport();
      default: return _buildIncomingOrders();
    }
  }

  // --- TAB PESANAN (YANG DIPERBARUI) ---
  Widget _buildIncomingOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('order_date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
           return Center(child: Text("Belum ada pesanan.", style: GoogleFonts.poppins(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String? proofImage = data['proof_image']; 
            String status = data['status'] ?? 'Menunggu';
            
            // Cek apakah ini Delivery atau Pickup
            bool isDelivery = (data['type'] ?? 'Delivery') == 'Delivery';

            Color statusColor = Colors.grey;
            if (status == 'Diproses') statusColor = Colors.blue;
            if (status == 'Diantar') statusColor = Colors.purple;
            if (status == 'Selesai') statusColor = Colors.green;
            if (status == 'Dibatalkan') statusColor = Colors.red;
            if (status == 'Menunggu Konfirmasi') statusColor = Colors.orange;

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  // ignore: deprecated_member_use
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.receipt_long, color: statusColor),
                ),
                title: Text(data['customer_name'] ?? 'Pelanggan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text("$status - ${formatRupiah(data['summary']['total'])}", style: GoogleFonts.poppins(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO TYPE ORDER (PENTING)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                          child: Text("Tipe: ${data['type'] ?? 'Delivery'}", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),

                        if (data['items'] != null)
                          ...(data['items'] as List).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item['image_url'] ?? '',
                                      width: 50, height: 50, fit: BoxFit.cover,
                                      errorWidget: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, size: 20)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text("${item['quantity']}x ${item['name']}", style: GoogleFonts.poppins())),
                                  Text(formatRupiah(item['price'] * item['quantity']), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                            );
                          }),
                        const Divider(),

                        if (proofImage != null)
                          GestureDetector(
                            onTap: () => _showFullImage(proofImage),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bukti Transfer (Klik untuk Perbesar):", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 5),
                                Container(
                                  height: 150, width: double.infinity,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                                  child: Image.memory(base64Decode(proofImage), fit: BoxFit.contain, errorBuilder: (_,__,___) => const Text("Gambar Error")),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 15),
                        const Divider(),
                        
                        // --- TOMBOL STATUS YANG BARU (GANTI WRAP DENGAN INI) ---
                        _buildActionButtons(doc.id, status, isDelivery),
                        // -----------------------------------------------------
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB MENU ---
  Widget _buildMenuManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text("Menu Kosong.", style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length + 1,
          itemBuilder: (context, index) {
            if (index == docs.length) return const SizedBox(height: 80);
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: data['image_url'] ?? '',
                    width: 60, height: 60, fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: Colors.orange),
                  ),
                ),
                title: Text(data['name'] ?? 'Tanpa Nama', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text(formatRupiah(data['price'] ?? 0), style: GoogleFonts.poppins(color: Colors.orange)),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(doc.id)),
                onTap: () => _showProductForm(docId: doc.id, data: data),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRevenueReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'Selesai').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        int grandTotal = 0;
        for (var doc in snapshot.data!.docs) { grandTotal += (doc['summary']['total'] as num).toInt(); }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Total Pendapatan", style: GoogleFonts.poppins(fontSize: 18)),
              Text(formatRupiah(grandTotal), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}