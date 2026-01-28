import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/menu_model.dart';
import 'detail_menu_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_favorites')
          .doc(_user.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      setState(() {
        _favorites = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error loading favorites: $e");
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(String menuId) async {
    if (_user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('user_favorites')
          .doc(_user.uid)
          .collection('favorites')
          .doc(menuId)
          .delete();

      setState(() {
        _favorites.removeWhere((item) => item['id'] == menuId);
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Menu dihapus dari favorit"),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error removing favorite: $e");
      }
    }
  }

  String _formatRupiah(int price) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite, BuildContext context) {
    return GestureDetector(
      onTap: () {
        final menu = MenuModel(
          id: favorite['id'],
          nama: favorite['menuName'] ?? '',
          harga: (favorite['menuPrice'] as num?)?.toInt() ?? 0,
          gambarUrl: favorite['menuImage'] ?? '',
          deskripsi: '', // Tidak ada deskripsi di data favorit
          kategori: favorite['menuCategory'] ?? 'Makanan',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailMenuScreen(menu: menu),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar Menu
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                image: favorite['menuImage'] != null && favorite['menuImage'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(favorite['menuImage'].toString()),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('assets/placeholder_food.png'),
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            // Detail Menu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            favorite['menuName'] ?? 'Menu',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.pink, size: 20),
                          onPressed: () => _removeFavorite(favorite['id']),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Kategori
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        favorite['menuCategory'] ?? 'Makanan',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Harga
                    Text(
                      _formatRupiah((favorite['menuPrice'] as num?)?.toInt() ?? 0),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Favorit Saya", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 20),
                      Text(
                        "Belum Ada Favorit",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          "Tambahkan menu favorit Anda dengan menekan ikon hati pada detail menu.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: Colors.orange,
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      return _buildFavoriteItem(_favorites[index], context);
                    },
                  ),
                ),
    );
  }
}