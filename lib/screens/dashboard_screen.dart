import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Sesuaikan jika path beda
import '../models/menu_model.dart';
import 'menu_screen.dart';
import 'detail_menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _promoController = PageController(viewportFraction: 0.95);
  

  @override
  void initState() {
    super.initState();
    // Tampilkan popup setelah widget siap
    
          }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Sobat Kuliner';

    // 1. DATA KATEGORI (Hanya 3: Kopi, Non-Kopi, Snack)
    final List<Map<String, dynamic>> categories = [
      {
        'label': 'Kopi',
        'icon': Icons.coffee_rounded,
        'color': const Color(0xFF8D6E63)
      },
      {
        'label': 'Non-Kopi',
        'icon': Icons.local_drink_rounded,
        'color': const Color(0xFF42A5F5)
      },
      {
        'label': 'Snack',
        'icon': Icons.cookie,
        'color': const Color(0xFFEF5350)
      },
    ];

    // Data untuk banner promo yang bisa digeser
    final List<Map<String, dynamic>> promoBanners = [
      {
        'title': 'Diskon 20%',
        'subtitle': 'Spesial Hari Ini!',
        'imageUrl': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
      },
      {
        'title': 'Gratis Ongkir',
        'subtitle': 'Min. pembelian Rp 50.000',
        'imageUrl': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
      },
      {
        'title': 'Buy 1 Get 1',
        'subtitle': 'Untuk semua varian kopi',
        'imageUrl': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER USER (SIMPLE) ---
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selamat Datang,', 
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 200,
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.orange.shade50,
                      backgroundImage:
                          user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, color: Colors.orange, size: 30)
                          : null,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SEARCH BAR ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        readOnly: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MenuScreen(initialCategory: 'Semua')),
                          );
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Cari menu favoritmu...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                          icon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list, color: Colors.orange),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- BANNER PROMO YANG BISA DIGESER ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Promo Spesial',
                                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                Icon(Icons.circle, color: Colors.orange.shade300, size: 8),
                                const SizedBox(width: 5),
                                Icon(Icons.circle, color: Colors.grey.shade300, size: 8),
                                const SizedBox(width: 5),
                                Icon(Icons.circle, color: Colors.grey.shade300, size: 8),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 160,
                          child: PageView.builder(
                            controller: _promoController,
                            itemCount: promoBanners.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final banner = promoBanners[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(banner['imageUrl']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomRight,
                                      // ignore: deprecated_member_use
                                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'PROMO',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(banner['title'],
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Text(banner['subtitle'],
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          )),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- KATEGORI PILIHAN (Hanya 3) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kategori',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MenuScreen(initialCategory: 'Semua'),
                              ),
                            );
                          },
                          child: Text(
                            'Lihat semua',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Grid kategori dengan 3 item saja
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: categories.map((cat) {
                        return CategoryItem(
                          icon: cat['icon'],
                          label: cat['label'],
                          color: cat['color'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MenuScreen(initialCategory: cat['label']),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 25),

                    // --- REKOMENDASI HARI INI (TETAP SAMA) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rekomendasi Hari Ini',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MenuScreen(initialCategory: 'Semua')));
                          },
                          child: Text("Lihat Semua",
                              style: GoogleFonts.poppins(
                                  color: Colors.orange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('isFeatured', isEqualTo: true)
                          .limit(6)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            height: 230,
                            child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          // Jika tidak ada featured, tampilkan pesan
                          return Container(
                            height: 230,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_border, size: 50, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text('Belum ada rekomendasi',
                                    style: GoogleFonts.poppins(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        final featuredData = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data.containsKey('name') &&
                              data['name'].toString().isNotEmpty &&
                              data['name'].toString() != 'Tanpa Nama' &&
                              data.containsKey('price') &&
                              (data['price'] is int) &&
                              (data['price'] as int) > 0;
                        }).toList();

                        if (featuredData.isEmpty) {
                          return Container(
                            height: 230,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star_border, size: 50, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text('Belum ada rekomendasi',
                                    style: GoogleFonts.poppins(color: Colors.grey)),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          height: 230,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: featuredData.length,
                            itemBuilder: (context, index) {
                              var docId = featuredData[index].id;
                              var data = featuredData[index].data() as Map<String, dynamic>;
                              MenuModel menu = MenuModel.fromMap(data, docId);

                              return Container(
                                width: 150,
                                margin: EdgeInsets.only(
                                    right: index == featuredData.length - 1 ? 0 : 15),
                                child: FeaturedFoodCard(
                                  menu: menu,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => DetailMenuScreen(menu: menu)),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // --- MENU POPULER (PAKAI isPopular) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Menu Populer',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MenuScreen(initialCategory: 'Semua')));
                          },
                          child: Text("Lihat Semua",
                              style: GoogleFonts.poppins(
                                  color: Colors.orange, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),

                    // MENU POPULER dengan filter isPopular
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .where('isPopular', isEqualTo: true)  // Filter hanya yang isPopular = true
                          .limit(4)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          // Jika tidak ada yang isPopular, tampilkan semua produk sebagai fallback
                          return _buildAllProductsFallback();
                        }

                        final popularData = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          bool hasName = data.containsKey('name') &&
                              data['name'].toString().isNotEmpty &&
                              data['name'].toString() != 'Tanpa Nama';

                          bool hasPrice = data.containsKey('price') &&
                              (data['price'] is int) &&
                              (data['price'] as int) > 0;

                          return hasName && hasPrice;
                        }).toList();

                        if (popularData.isEmpty) {
                          return _buildAllProductsFallback();
                        }

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: popularData.length,
                          itemBuilder: (context, index) {
                            var docId = popularData[index].id;
                            var data = popularData[index].data() as Map<String, dynamic>;
                            MenuModel menu = MenuModel.fromMap(data, docId);

                            return FoodCard(
                              menu: menu,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => DetailMenuScreen(menu: menu)),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fallback jika tidak ada produk dengan isPopular = true
  Widget _buildAllProductsFallback() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').limit(4).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, size: 50, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('Belum ada menu populer',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        final validData = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          bool hasName = data.containsKey('name') &&
              data['name'].toString().isNotEmpty &&
              data['name'].toString() != 'Tanpa Nama';

          bool hasPrice = data.containsKey('price') &&
              (data['price'] is int) &&
              (data['price'] as int) > 0;

          return hasName && hasPrice;
        }).toList();

        final limitedData = validData.take(4).toList();

        if (limitedData.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, size: 50, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('Belum ada menu populer',
                    style: GoogleFonts.poppins(color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: limitedData.length,
          itemBuilder: (context, index) {
            var docId = limitedData[index].id;
            var data = limitedData[index].data() as Map<String, dynamic>;
            MenuModel menu = MenuModel.fromMap(data, docId);

            return FoodCard(
              menu: menu,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailMenuScreen(menu: menu)),
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- WIDGET PENDUKUNG ---

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class FeaturedFoodCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onTap;

  const FeaturedFoodCard({super.key, required this.menu, required this.onTap});

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar dengan badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: CachedNetworkImage(
                    imageUrl: menu.gambarUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      height: 120,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      height: 120,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '🔥 HOT',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.nama,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(menu.harga),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onTap;

  const FoodCard({super.key, required this.menu, required this.onTap});

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            // ignore: deprecated_member_use
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: menu.gambarUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.nama,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(menu.harga),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- POPUP DENGAN GAMBAR PRODUK DARI DATABASE ---
class ProductOfferPopup extends StatefulWidget {
  const ProductOfferPopup({super.key});

  @override
  State<ProductOfferPopup> createState() => _ProductOfferPopupState();
}

class _ProductOfferPopupState extends State<ProductOfferPopup> {
  late Future<MenuModel?> _featuredProductFuture;

  @override
  void initState() {
    super.initState();
    _featuredProductFuture = _getFeaturedProduct();
  }

  Future<MenuModel?> _getFeaturedProduct() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isPopular', isEqualTo: true)  // Ambil yang populer untuk popup
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return MenuModel.fromMap(data, doc.id);
      }

      // Jika tidak ada popular, ambil produk pertama
      final allSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(1)
          .get();

      if (allSnapshot.docs.isNotEmpty) {
        final doc = allSnapshot.docs.first;
        final data = doc.data();
        return MenuModel.fromMap(data, doc.id);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting featured product: $e');
      }
      return null;
    }
  }

  String formatRupiah(int price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: FutureBuilder<MenuModel?>(
        future: _featuredProductFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(30),
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.orange),
                  const SizedBox(height: 20),
                  Text(
                    'Memuat produk...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final MenuModel? menu = snapshot.data;

          if (menu == null) {
            return Container(
              padding: const EdgeInsets.all(30),
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey.shade400, size: 50),
                  const SizedBox(height: 15),
                  Text(
                    'Tidak ada produk',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada produk yang tersedia',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'TUTUP',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge Promo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PENAWARAN SPESIAL',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Gambar Produk
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(menu.gambarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Nama Produk
                Text(
                  menu.nama,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Harga
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (menu.harga > 30000) ...[
                      Text(
                        formatRupiah(menu.harga + 5000),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      formatRupiah(menu.harga),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Diskon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Text(
                    'DISKON 15%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Deskripsi singkat
                Text(
                  'Nikmati promo spesial untuk produk pilihan kami. Tawaran terbatas hanya untuk hari ini!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Tombol
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'LEWATI',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigasi ke detail produk
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailMenuScreen(menu: menu),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'BELI SEKARANG',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                // Teks kecil
                Text(
                  'Tawaran berlaku 24 jam',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
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