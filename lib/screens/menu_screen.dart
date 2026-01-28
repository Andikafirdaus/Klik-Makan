import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/menu_model.dart';
import '../providers/cart_provider.dart';
import 'detail_menu_screen.dart';
import 'checkout_screen.dart';

class MenuScreen extends StatefulWidget {
  final String? initialCategory; 

  const MenuScreen({super.key, this.initialCategory});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['Semua', 'Kopi', 'Non-Kopi', 'Snack']; 

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && widget.initialCategory != 'Makanan') {
      _selectedCategory = widget.initialCategory!;
    }
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    // HAPUS Provider.of DARI SINI AGAR TIDAK REBUILD SATU LAYAR
    // final cart = Provider.of<CartProvider>(context); <-- HAPUS INI

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari menu favoritmu...',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- 1. FILTER KATEGORI ---
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    String cat = _categories[index];
                    bool isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- 2. LIST MENU ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("Menu belum tersedia", style: GoogleFonts.poppins()));
                    }

                    final allDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '').toString();
                      int price = (data['price'] is int) ? data['price'] : 0;
                      String category = (data['category'] ?? 'Lainnya').toString();

                      if (name.isEmpty || name == 'Tanpa Nama' || price <= 0) return false; 

                      bool categoryMatch = _selectedCategory == 'Semua' || category == _selectedCategory;
                      bool searchMatch = name.toLowerCase().contains(_searchQuery);

                      return categoryMatch && searchMatch;
                    }).toList();

                    if (allDocs.isEmpty) {
                      return const Center(child: Text("Menu tidak ditemukan"));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                      itemCount: allDocs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        var data = allDocs[index].data() as Map<String, dynamic>;
                        MenuModel menu = MenuModel.fromMap(data, allDocs[index].id);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DetailMenuScreen(menu: menu)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                // ignore: deprecated_member_use
                                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                // FOTO
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: menu.gambarUrl,
                                    width: 80, height: 80, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.fastfood, color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // INFO
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        menu.nama,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatRupiah(menu.harga),
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),

                                // --- BAGIAN TOMBOL ADD (DIBUNGKUS CONSUMER) ---
                                // Consumer hanya akan membangun ulang bagian KECIL ini saja saat data berubah
                                Consumer<CartProvider>(
                                  builder: (context, cart, child) {
                                    int qty = cart.getQuantity(menu.id);
                                    
                                    if (qty == 0) {
                                      // TOMBOL (+)
                                      return InkWell(
                                        onTap: () => cart.addOne(menu),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                                        ),
                                      );
                                    } else {
                                      // TOMBOL (- 1 +)
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.orange),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cart.removeOne(menu.id),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 18, color: Colors.orange),
                                              ),
                                            ),
                                            Text('$qty', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                                            InkWell(
                                              onTap: () => cart.addOne(menu),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 18, color: Colors.orange),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // --- 3. FLOATING BOTTOM BAR (CART SUMMARY) ---
          // Gunakan Consumer disini juga agar bar muncul mulus
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) return const SizedBox.shrink(); // Hilang kalau kosong

              return Positioned(
                bottom: 75,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        // ignore: deprecated_member_use
                        BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${cart.items.length} Item", style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            Text(formatRupiah(cart.totalPrice), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Row(
                          children: [
                            Text("Checkout", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}