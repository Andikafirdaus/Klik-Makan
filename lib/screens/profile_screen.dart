import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'favorites_screen.dart'; // Import halaman favorit yang baru

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  String _address = "Belum ada alamat tersimpan";
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- 1. LOAD DATA USER DARI DATABASE ---
  Future<void> _loadUserData() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        setState(() {
          _address = (doc.data() as Map<String, dynamic>)['address'] ?? "Belum ada alamat";
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading user data: $e");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. FUNGSI PILIH FOTO PROFIL ---
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // 
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto profil berhasil diubah!")),
      );
    }
  }

  // --- 3. FUNGSI LOGOUT ---
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Keluar Akun", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text("Anda yakin ingin keluar dari akun ini?", style: GoogleFonts.poppins(color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal", style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
            },
            child: Text("Keluar", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- HEADER PROFILE ---
                  Container(
                    padding: const EdgeInsets.only(top: 50, bottom: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.orange, Colors.orange.shade800],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Profil Saya",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // PROFILE PICTURE WITH EDIT BUTTON
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    // ignore: deprecated_member_use
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: _profileImage != null
                                    ? Image.file(_profileImage!, fit: BoxFit.cover)
                                    : user?.photoURL != null
                                        ? Image.network(
                                            user!.photoURL!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                _buildDefaultAvatar(),
                                          )
                                        : _buildDefaultAvatar(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickProfileImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        // ignore: deprecated_member_use
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.orange, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // USER NAME
                        Text(
                          user?.displayName ?? "Pengguna",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 5),
                        
                        // USER EMAIL
                        Text(
                          user?.email ?? "-",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        
                        // BAGIAN MEMBER BRONZE DIHAPUS
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- MENU SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // SECTION 1: AKUN SAYA
                        _buildSectionTitle("Akun Saya"),
                        const SizedBox(height: 10),
                        
                        _buildMenuCard(
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: "Edit Profil",
                              subtitle: "Ubah nama dan foto profil",
                              onTap: () {
                                _navigateToEditProfile();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.email_outlined,
                              title: "Email",
                              subtitle: user?.email ?? "-",
                              onTap: () {
                                _navigateToEditEmail();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.lock_outline,
                              title: "Password",
                              subtitle: "Ganti password akun",
                              onTap: () {
                                _navigateToChangePassword();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.location_on_outlined,
                              title: "Alamat Pengiriman",
                              subtitle: _address.length > 30 ? "${_address.substring(0, 30)}..." : _address,
                              onTap: () {
                                _navigateToEditAddress();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // SECTION 2: AKTIVITAS
                        _buildSectionTitle("Aktivitas"),
                        const SizedBox(height: 10),
                        
                        _buildMenuCard(
                          children: [
                            _buildMenuItem(
                              icon: Icons.history,
                              title: "Riwayat Pesanan",
                              subtitle: "Lihat semua pesanan Anda",
                              onTap: () {
                                _navigateToOrderHistory();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.favorite_border,
                              title: "Favorit Saya",
                              subtitle: "Menu yang Anda sukai",
                              onTap: () {
                                _navigateToFavorites();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.notifications_none,
                              title: "Notifikasi",
                              subtitle: "Pengaturan notifikasi",
                              onTap: () {
                                _navigateToNotifications();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // SECTION 3: BANTUAN
                        _buildSectionTitle("Bantuan & Lainnya"),
                        const SizedBox(height: 10),
                        
                        _buildMenuCard(
                          children: [
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              title: "Pusat Bantuan",
                              subtitle: "Pertanyaan yang sering diajukan",
                              onTap: () {
                                _navigateToHelpCenter();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.privacy_tip_outlined,
                              title: "Kebijakan Privasi",
                              subtitle: "Baca kebijakan privasi kami",
                              onTap: () {
                                _navigateToPrivacyPolicy();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.star_border,
                              title: "Beri Rating",
                              subtitle: "Beri rating aplikasi kami",
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Terima kasih atas dukungannya!")),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // LOGOUT BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: _handleLogout,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  "Keluar Akun",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // VERSION INFO
                        Text(
                          "Klik Makan v1.0.0",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "© 2024 Klik Makan. All rights reserved",
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- NAVIGATION METHODS ---
  
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditProfileScreen(
          user: user!,
          onProfileUpdated: () {
            _loadUserData();
            setState(() {
              user = FirebaseAuth.instance.currentUser;
            });
          },
        ),
      ),
    );
  }

  void _navigateToEditEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditEmailScreen(user: user!),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChangePasswordScreen(user: user!),
      ),
    );
  }

  void _navigateToEditAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditAddressScreen(
          currentAddress: _address,
          userId: user!.uid,
          onAddressUpdated: (newAddress) {
            setState(() {
              _address = newAddress;
            });
          },
        ),
      ),
    );
  }

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _OrderHistoryScreen(),
      ),
    );
  }

  void _navigateToFavorites() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FavoritesScreen(), // PAKAI CLASS YANG BARU
    ),
  );
}

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _NotificationsScreen(),
      ),
    );
  }

  void _navigateToHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HelpCenterScreen(),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PrivacyPolicyScreen(),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---
  
  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: const Icon(Icons.person, size: 50, color: Colors.orange),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.orange, size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================
// HALAMAN-HALAMAN PENGATURAN (DALAM FILE YANG SAMA)
// ============================================

// --- 1. HALAMAN EDIT PROFIL ---
class _EditProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback onProfileUpdated;

  const _EditProfileScreen({required this.user, required this.onProfileUpdated});

  @override
  __EditProfileScreenState createState() => __EditProfileScreenState();
}

class __EditProfileScreenState extends State<_EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Update display name di Firebase Auth
      await widget.user.updateDisplayName(_nameController.text.trim());
      await widget.user.reload();

      // Update di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': widget.user.email,
          }, SetOptions(merge: true));

      // 

      widget.onProfileUpdated();
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diperbarui!"),
          backgroundColor: Colors.green,
        ),
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profil", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Foto Profil
            GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : widget.user.photoURL != null
                              ? Image.network(widget.user.photoURL!, fit: BoxFit.cover)
                              : const Icon(Icons.person, size: 50, color: Colors.orange),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Form Nama
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Nama Lengkap",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Nama Anda akan ditampilkan pada aplikasi dan struk pesanan",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Simpan Perubahan",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. HALAMAN EDIT ALAMAT ---
class _EditAddressScreen extends StatefulWidget {
  final String currentAddress;
  final String userId;
  final Function(String) onAddressUpdated;

  const _EditAddressScreen({
    required this.currentAddress,
    required this.userId,
    required this.onAddressUpdated,
  });

  @override
  __EditAddressScreenState createState() => __EditAddressScreenState();
}

class __EditAddressScreenState extends State<_EditAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.currentAddress == "Belum ada alamat tersimpan" 
        ? "" 
        : widget.currentAddress;
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alamat tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get current user data
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
            'address': _addressController.text.trim(),
            'email': user?.email ?? '',
            'name': user?.displayName ?? "",
          }, SetOptions(merge: true));

      widget.onAddressUpdated(_addressController.text.trim());
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alamat berhasil disimpan!"),
          backgroundColor: Colors.green,
        ),
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Alamat", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alamat Pengiriman",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 10),
            
            TextField(
              controller: _addressController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Contoh: Jl. Mawar No. 12, RT 01/RW 05, Kel. Sukamaju, Kec. Sukasari, Kota Bandung",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 15),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pastikan alamat lengkap dan jelas untuk memudahkan kurir menemukan lokasi Anda",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Simpan Alamat",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. HALAMAN GANTI PASSWORD ---
class _ChangePasswordScreen extends StatefulWidget {
  final User user;

  const _ChangePasswordScreen({required this.user});

  @override
  __ChangePasswordScreenState createState() => __ChangePasswordScreenState();
}

class __ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  Future<void> _changePassword() async {
    if (_newController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password baru minimal 6 karakter")),
      );
      return;
    }

    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password baru dan konfirmasi tidak sama")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: widget.user.email!,
        password: _currentController.text,
      );
      
      await widget.user.reauthenticateWithCredential(credential);
      
      // Update password
      await widget.user.updatePassword(_newController.text);
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password berhasil diubah!"),
          backgroundColor: Colors.green,
        ),
      );
      
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "Terjadi kesalahan";
      if (e.code == 'wrong-password') {
        message = "Password saat ini salah";
      } else if (e.code == 'weak-password') {
        message = "Password terlalu lemah";
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ganti Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Password
            TextField(
              controller: _currentController,
              obscureText: !_showCurrent,
              decoration: InputDecoration(
                labelText: "Password Saat Ini",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // New Password
            TextField(
              controller: _newController,
              obscureText: !_showNew,
              decoration: InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showNew = !_showNew),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Confirm Password
            TextField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: "Konfirmasi Password Baru",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Password minimal 6 karakter dan mengandung kombinasi huruf dan angka",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Ganti Password",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. HALAMAN EDIT EMAIL ---
class _EditEmailScreen extends StatelessWidget {
  final User user;

  const _EditEmailScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Email", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Email Saat Ini:",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 5),
            
            Text(
              user.email ?? "-",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 24),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Perhatian",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Fitur perubahan email sedang dalam pengembangan. Untuk perubahan email, silakan hubungi customer service kami.",
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              "Hubungi Customer Service:",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 10),
            
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text("0812-3456-7890", style: GoogleFonts.poppins(fontSize: 15)),
              subtitle: Text("WhatsApp/Telepon", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hubungi CS: 0812-3456-7890")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. HALAMAN RIWAYAT PESANAN ---
class _OrderHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Pesanan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "Riwayat Pesanan",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Fitur riwayat pesanan akan segera tersedia. Anda dapat melihat pesanan yang sedang berjalan di halaman notifikasi.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. HALAMAN FAVORIT (DIKEMBALIKAN KE SEMULA) ---

// --- 7. HALAMAN NOTIFIKASI ---
class _NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pengaturan Notifikasi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "Pengaturan Notifikasi",
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Pengaturan notifikasi akan segera tersedia di versi aplikasi berikutnya.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 8. HALAMAN PUSAT BANTUAN ---
class _HelpCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pusat Bantuan", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pertanyaan yang Sering Diajukan",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 20),
            
            _buildFAQItem(
              "Bagaimana cara memesan makanan?",
              "Pilih menu makanan, tambahkan ke keranjang, lalu checkout dan pilih metode pembayaran."
            ),
            
            _buildFAQItem(
              "Berapa lama waktu pengiriman?",
              "Waktu pengiriman sekitar 30-60 menit tergantung jarak dan kondisi lalu lintas."
            ),
            
            _buildFAQItem(
              "Bagaimana cara membatalkan pesanan?",
              "Pesanan dapat dibatalkan sebelum status 'Sedang Diproses'. Hubungi CS untuk bantuan."
            ),
            
            const SizedBox(height: 30),
            
            Text(
              "Hubungi Kami",
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 15),
            
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: Text("0812-3456-7890", style: GoogleFonts.poppins(fontSize: 15)),
              subtitle: Text("WhatsApp/Telepon", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ),
            
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text("help@klikmakan.com", style: GoogleFonts.poppins(fontSize: 15)),
              subtitle: Text("Email", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

// --- 9. HALAMAN KEBIJAKAN PRIVASI ---
class _PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kebijakan Privasi", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Kebijakan Privasi Klik Makan",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              "Terakhir diperbarui: 1 Januari 2024",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            
            const SizedBox(height: 30),
            
            _buildPolicySection(
              "1. Informasi yang Kami Kumpulkan",
              "Kami mengumpulkan informasi yang Anda berikan secara langsung seperti nama, email, alamat, dan informasi pemesanan."
            ),
            
            _buildPolicySection(
              "2. Penggunaan Informasi",
              "Informasi digunakan untuk memproses pesanan, mengirim notifikasi, dan meningkatkan layanan kami."
            ),
            
            _buildPolicySection(
              "3. Perlindungan Data",
              "Kami menggunakan enkripsi dan protokol keamanan untuk melindungi data pribadi Anda."
            ),
            
            _buildPolicySection(
              "4. Pembagian Informasi",
              "Kami tidak menjual data pribadi Anda kepada pihak ketiga kecuali untuk keperluan pemrosesan pembayaran."
            ),
            
            _buildPolicySection(
              "5. Hak Pengguna",
              "Anda memiliki hak untuk mengakses, memperbaiki, atau menghapus data pribadi Anda."
            ),
            
            const SizedBox(height: 30),
            
            Text(
              "Jika Anda memiliki pertanyaan tentang kebijakan privasi kami, silakan hubungi kami di privacy@klikmakan.com",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}