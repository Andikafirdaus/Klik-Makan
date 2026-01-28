import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import semua halaman
import '../screens/dashboard_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';
import '../providers/cart_provider.dart'; 
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  late PageController _pageController; // 1. Controller untuk PageView

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Inisialisasi controller
  }

  @override
  void dispose() {
    _pageController.dispose(); // Wajib dimatikan biar gak bocor memory
    super.dispose();
  }

  // DAFTAR HALAMAN
  final List<Widget> _pages = [
    const DashboardScreen(),      
    const MenuScreen(),           
    const NotificationScreen(),   
    const ProfileScreen(),        
  ];

  // Fungsi saat Icon Bawah diklik
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // 2. Animasi geser ke halaman yang dipilih
    _pageController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 300), // Kecepatan geser
      curve: Curves.easeInOut, // Gaya animasi
    );
  }

  // Fungsi saat Layar digeser (Swipe)
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index; // 3. Update icon bawah biar sesuai halaman
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil jumlah item keranjang buat badge (opsional)
    int _ = Provider.of<CartProvider>(context).items.length;

    return Scaffold(
      extendBody: true, 
      
      // 4. GANTI BODY JADI PAGEVIEW
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged, // Deteksi geseran tangan
        physics: const BouncingScrollPhysics(), // Efek mantul dikit kalo mentok
        children: _pages, // Daftar halaman yang mau ditampilkan
      ),
      
      // --- DESAIN NAVBAR BARU ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1), 
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped, // Panggil fungsi tap yang baru
            
            // Styling Item
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
            elevation: 0, 

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded), 
                label: 'Beranda'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_rounded), 
                label: 'Menu'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_rounded), // <-- PERUBAHAN DI SINI
                activeIcon: Icon(Icons.receipt_long_rounded), // <-- Active state
                label: 'Riwayat'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), 
                label: 'Profil'
              ),
            ],
          ),
        ),
      ),
    );
  }
}