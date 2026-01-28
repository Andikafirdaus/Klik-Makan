import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_model.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart'; // Provider baru untuk favorit

class DetailMenuScreen extends StatefulWidget {
  final MenuModel menu;

  const DetailMenuScreen({super.key, required this.menu});

  @override
  State<DetailMenuScreen> createState() => _DetailMenuScreenState();
}

class _DetailMenuScreenState extends State<DetailMenuScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Fungsi untuk cek apakah menu sudah di-favoritkan
  Future<void> _checkIfFavorite() async {
    setState(() => _isLoadingFavorite = true);
    
    try {
      // Cek menggunakan Provider jika ada
      if (context.mounted) {
        final favoriteProvider = context.read<FavoriteProvider>();
        _isFavorite = await favoriteProvider.isFavorite(widget.menu.id);
      }
      
      // Atau cek langsung dari SharedPreferences (fallback)
      if (!_isFavorite) {
        final prefs = await SharedPreferences.getInstance();
        final favorites = prefs.getStringList('favorites') ?? [];
        _isFavorite = favorites.contains(widget.menu.id);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking favorite: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  // Fungsi untuk toggle favorit
  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;
    
    setState(() => _isLoadingFavorite = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Simpan ke Firestore untuk user yang login
        final userFavoritesRef = FirebaseFirestore.instance
            .collection('user_favorites')
            .doc(user.uid)
            .collection('favorites')
            .doc(widget.menu.id);
        
        if (_isFavorite) {
          // Hapus dari favorit
          await userFavoritesRef.delete();
        } else {
          // Tambah ke favorit
          await userFavoritesRef.set({
            'menuId': widget.menu.id,
            'menuName': widget.menu.nama,
            'menuPrice': widget.menu.harga,
            'menuImage': widget.menu.gambarUrl,
            'menuCategory': widget.menu.kategori,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Simpan juga ke SharedPreferences untuk offline access
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorites') ?? [];
      
      if (_isFavorite) {
        favorites.remove(widget.menu.id);
      } else {
        favorites.add(widget.menu.id);
      }
      
      await prefs.setStringList('favorites', favorites);
      
      // Update Provider jika ada
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        final favoriteProvider = context.read<FavoriteProvider>();
        if (_isFavorite) {
          await favoriteProvider.removeFavorite(widget.menu.id);
        } else {
          await favoriteProvider.addFavorite(widget.menu);
        }
      }
      
      // Update UI state
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoadingFavorite = false;
        });
      }
      
      // Show snackbar feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite 
                ? '${widget.menu.nama} ditambahkan ke favorit! ❤️' 
                : '${widget.menu.nama} dihapus dari favorit',
            ),
            backgroundColor: _isFavorite ? Colors.pink.shade400 : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        print("Error toggling favorite: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  String formatRupiah(int price) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartQuantity = cartProvider.getQuantity(widget.menu.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Menu',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Tombol Favorit
          _isLoadingFavorite
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.pink : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
          
          // Badge Keranjang
          if (cartQuantity > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cartQuantity di keranjang',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION dengan tombol favorit di atas gambar
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  widget.menu.gambarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.menu.gambarUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => _buildFallbackImage(),
                        )
                      : _buildFallbackImage(),
                  
                  // Overlay gradient untuk teks lebih readable
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            // ignore: deprecated_member_use
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            // ignore: deprecated_member_use
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Tombol Favorit di atas gambar (opsional)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.pink : Colors.grey.shade700,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  // Kategori badge
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.menu.kategori,
                        style: GoogleFonts.poppins(
                          color: Colors.white, 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA, HARGA, dan STATUS FAVORIT
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.menu.nama,
                              style: GoogleFonts.poppins(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Badge Favorit di samping nama
                            if (_isFavorite)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.pink.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite, size: 12, color: Colors.pink),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Favorit',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.pink.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRupiah(widget.menu.harga),
                            style: GoogleFonts.poppins(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.orange
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '/porsi',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // INFO ESTIMASI WAKTU (ICON SHARE DIHAPUS)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time, color: Colors.grey, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estimasi: 15-20 menit', 
                        style: GoogleFonts.poppins(color: Colors.grey.shade700)
                      ),
                      // Tombol Share DIHAPUS dari sini
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  // DESKRIPSI
                  Text(
                    'Deskripsi',
                    style: GoogleFonts.poppins(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menu.deskripsi.isNotEmpty 
                        ? widget.menu.deskripsi 
                        : 'Tidak ada deskripsi untuk menu ini.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600, 
                      height: 1.5
                    ),
                  ),
                  
                  // INFORMASI NUTRISI (opsional, jika ada data)
                  if (widget.menu.deskripsi.length > 50) // Contoh kondisi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        Text(
                          'Informasi',
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildInfoChip(Icons.local_fire_department, '250-300', 'Kalori'),
                            const SizedBox(width: 10),
                            _buildInfoChip(Icons.restaurant, '1', 'Porsi'),
                            const SizedBox(width: 10),
                            _buildInfoChip(Icons.fastfood, 'Segar', 'Kondisi'),
                          ],
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 120), // Ruang ekstra untuk bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      
      // BOTTOM NAVIGATION BAR (TOTAL & TAMBAH KE KERANJANG)
      bottomNavigationBar: Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12, 
              blurRadius: 10, 
              spreadRadius: 1
            )
          ],
        ),
        child: Row(
          children: [
            // Tombol Pengatur Jumlah (Quantity)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }, 
                    icon: const Icon(Icons.remove, color: Colors.grey)
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantity', 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++), 
                    icon: const Icon(Icons.add, color: Colors.grey)
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            
            // Tombol Tambah ke Keranjang
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Menambahkan item ke provider sejumlah quantity
                  for (int i = 0; i < _quantity; i++) {
                    cartProvider.addOne(widget.menu);
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.menu.nama} ($_quantity item) ditambahkan ke keranjang! 🛒'), 
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Lihat',
                        textColor: Colors.white,
                        onPressed: () {
                          // Navigate to cart screen
                        },
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah - ${formatRupiah(widget.menu.harga * _quantity)}', 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                        fontSize: 14,
                      )
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

  // Widget untuk menampilkan icon makanan jika gambar gagal dimuat
  Widget _buildFallbackImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.fastfood, size: 100, color: Colors.grey)
      ),
    );
  }

  // Widget untuk chip informasi
  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.orange),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}