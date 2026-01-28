import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/menu_model.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';
import 'map_picker_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _voucherController = TextEditingController();

  bool _isDelivery = true;
  final bool _isLoading = false;
  bool _isLoadingAddress = true;
  
  // VOUCHER VARIABEL
  bool _isApplyingVoucher = false;
  bool _voucherApplied = false;
  String _voucherMessage = '';
  Color _voucherMessageColor = Colors.grey;
  int _discountAmount = 0;
  String _voucherCode = '';

  String _metodePembayaran = 'COD';
  String _tampilanMetode = 'Tunai (COD)';

  IconData _iconPembayaran = Icons.money;
  Color _colorPembayaran = Colors.green;

  // === VARIABEL UNTUK MAPS ===
  LatLng? _selectedLocation;
  double _distanceInKm = 0.0;
  bool _isCalculatingDistance = false;
  
  LatLng? _userLocationForPickup;
  double _pickupDistanceInKm = 0.0;
  bool _isGettingPickupLocation = false;
  
  // Lokasi restaurant
  static const LatLng _restaurantLocation = LatLng(-6.1202778, 106.1915000);
  static const String _restaurantName = "Klik Makan Restaurant";
  static const String _restaurantAddress = "Jl. Contoh No. 123, Cempaka Purwakarta";
  
  // Dynamic ongkir
  int get _biayaOngkir {
    if (!_isDelivery || _distanceInKm == 0) return 10000;
    
    if (_distanceInKm <= 3) return 8000;
    if (_distanceInKm <= 6) return 12000;
    if (_distanceInKm <= 10) return 15000;
    return 20000;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  // --- FUNGSI APPLY VOUCHER SEDERHANA ---
  Future<void> _applyVoucher() async {
    if (_voucherController.text.isEmpty) {
      setState(() {
        _voucherMessage = 'Masukkan kode voucher';
        _voucherMessageColor = Colors.orange;
      });
      return;
    }

    setState(() {
      _isApplyingVoucher = true;
      _voucherMessage = '';
    });

    // TUNGGU SEBENTAR UNTUK ANIMASI
    await Future.delayed(const Duration(milliseconds: 500));

    final String code = _voucherController.text.trim().toUpperCase();
    
    // AMBIL CART DARI PROVIDER
    // ignore: use_build_context_synchronously
    final cart = Provider.of<CartProvider>(context, listen: false);
    final int subtotal = cart.totalPrice;

    // LOGIC SEDERHANA TANPA FIRESTORE DULU
    int discount = 0;
    String message = '';
    bool isValid = false;

    if (code == 'DISKON10') {
      if (subtotal >= 50000) {
        // Hitung 10% dari subtotal
        discount = (subtotal * 0.10).round();
        // Maksimal diskon 20000
        if (discount > 20000) discount = 20000;
        message = 'Diskon 10% (maks Rp 20.000)';
        isValid = true;
      } else {
        message = 'Minimal pembelian Rp 50.000 untuk DISKON10';
      }
    } 
    else if (code == 'DISKON20') {
      if (subtotal >= 75000) {
        discount = (subtotal * 0.20).round();
        if (discount > 30000) discount = 30000;
        message = 'Diskon 20% (maks Rp 30.000)';
        isValid = true;
      } else {
        message = 'Minimal pembelian Rp 75.000 untuk DISKON20';
      }
    }
    else if (code == 'HEMAT15') {
      if (subtotal >= 60000) {
        discount = 15000;
        message = 'Potongan Rp 15.000';
        isValid = true;
      } else {
        message = 'Minimal pembelian Rp 60.000 untuk HEMAT15';
      }
    }
    else if (code == 'GRATISONGKIR') {
      if (subtotal >= 100000) {
        discount = _isDelivery ? _biayaOngkir : 0;
        message = 'Gratis ongkir';
        isValid = true;
      } else {
        message = 'Minimal pembelian Rp 100.000 untuk GRATISONGKIR';
      }
    }
    else if (code == 'NEWUSER') {
      if (subtotal >= 30000) {
        discount = (subtotal * 0.25).round();
        if (discount > 25000) discount = 25000;
        message = 'Diskon 25% untuk pengguna baru';
        isValid = true;
      } else {
        message = 'Minimal pembelian Rp 30.000 untuk NEWUSER';
      }
    }
    else {
      message = 'Kode voucher tidak valid';
    }

    // UPDATE STATE
    setState(() {
      _isApplyingVoucher = false;
      
      if (isValid) {
        _voucherApplied = true;
        _discountAmount = discount;
        _voucherCode = code;
        _voucherMessage = '✓ $message';
        _voucherMessageColor = Colors.green;
        _voucherController.clear();
        FocusScope.of(context).unfocus();
      } else {
        _voucherApplied = false;
        _discountAmount = 0;
        _voucherMessage = message;
        _voucherMessageColor = Colors.orange;
      }
    });
  }

  // --- FUNGSI REMOVE VOUCHER ---
  void _removeVoucher() {
    setState(() {
      _voucherApplied = false;
      _discountAmount = 0;
      _voucherCode = '';
      _voucherMessage = 'Voucher dihapus';
      _voucherMessageColor = Colors.grey;
      _voucherController.clear();
    });
  }

  // --- FUNGSI LOAD ALAMAT DARI FIRESTORE ---
  Future<void> _loadSavedAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingAddress = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String savedAddress = "";

        if (data.containsKey('address') && data['address'] != null) {
          savedAddress = data['address'].toString().trim();
        } else if (data.containsKey('alamat') && data['alamat'] != null) {
          savedAddress = data['alamat'].toString().trim();
        }

        List<String> defaultValues = [
          "Belum ada alamat",
          "Belum ada alamat tersimpan",
          "-",
          ""
        ];

        if (savedAddress.isNotEmpty && !defaultValues.contains(savedAddress)) {
          setState(() {
            _alamatController.text = savedAddress;
          });
          _getCoordinatesFromAddress(savedAddress);
        } else {
          _alamatController.clear();
        }
      } else {
        _alamatController.clear();
      }
    } catch (e) {
      if (kDebugMode) {
        print("ERROR loading address: $e");
      }
      _alamatController.clear();
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  // --- FUNGSI DAPAT KOORDINAT DARI ALAMAT ---
  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });
        _calculateDistance();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting coordinates from address: $e");
      }
    }
  }

  // --- FUNGSI BUKA MAP PICKER ---
  Future<void> _openMapPicker() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          restaurantLocation: _restaurantLocation,
          initialPosition: _selectedLocation ?? _restaurantLocation,
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
        _isCalculatingDistance = true;
      });

      await _getAddressFromCoordinates(selectedLocation);
      _calculateDistance();
    }
  }

  // --- FUNGSI DAPAT ALAMAT DARI KOORDINAT ---
  Future<void> _getAddressFromCoordinates(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
        
        setState(() {
          _alamatController.text = address;
        });

        _saveAddressToFirestore(address, latLng);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting address from coordinates: $e");
      }
      setState(() {
        _alamatController.text = "Lat: ${latLng.latitude.toStringAsFixed(4)}, Lng: ${latLng.longitude.toStringAsFixed(4)}";
      });
    }
  }

  // --- FUNGSI HITUNG JARAK DELIVERY ---
  Future<void> _calculateDistance() async {
    if (_selectedLocation == null) return;
    
    setState(() => _isCalculatingDistance = true);
    
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        _restaurantLocation.latitude,
        _restaurantLocation.longitude,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      
      setState(() {
        _distanceInKm = distanceInMeters / 1000;
        _isCalculatingDistance = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error calculating distance: $e");
      }
      setState(() => _isCalculatingDistance = false);
    }
  }

  // --- FUNGSI HITUNG JARAK PICKUP ---
  Future<void> _calculatePickupDistance() async {
    if (_userLocationForPickup == null) return;
    
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        _restaurantLocation.latitude,
        _restaurantLocation.longitude,
        _userLocationForPickup!.latitude,
        _userLocationForPickup!.longitude,
      );
      
      setState(() {
        _pickupDistanceInKm = distanceInMeters / 1000;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error calculating pickup distance: $e");
      }
    }
  }

  // --- FUNGSI GET USER LOCATION UNTUK PICKUP ---
  Future<void> _getUserLocationForPickup() async {
    setState(() => _isGettingPickupLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin lokasi diperlukan untuk melihat jarak"),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isGettingPickupLocation = false);
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      setState(() {
        _userLocationForPickup = LatLng(
          position.latitude, 
          position.longitude
        );
        _isGettingPickupLocation = false;
      });
      
      _calculatePickupDistance();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting pickup location: $e");
      }
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mendapatkan lokasi: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isGettingPickupLocation = false);
    }
  }

  // --- FUNGSI BUKA GOOGLE MAPS UNTUK ARAH ---
  Future<void> _openDirectionsInMaps() async {
    final String url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${_restaurantLocation.latitude},${_restaurantLocation.longitude}'
        '&destination_name=${Uri.encodeComponent(_restaurantName)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak bisa membuka Google Maps")),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error opening maps: $e");
      }
    }
  }

  // --- FUNGSI SIMPAN ALAMAT KE FIRESTORE ---
  Future<void> _saveAddressToFirestore(String address, LatLng latLng) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'address': address,
            'latitude': latLng.latitude,
            'longitude': latLng.longitude,
            'email': user.email,
            'name': user.displayName ?? "",
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        print("ERROR saving address with coordinates: $e");
      }
    }
  }

  // --- FUNGSI EDIT ALAMAT ---
  void _editAddress() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ubah Alamat", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Manual"),
              subtitle: const Text("Ketik alamat secara manual"),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: const Text("Pilih di Peta"),
              subtitle: const Text("Pilih lokasi di peta"),
              onTap: () => Navigator.pop(context, 'map'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
        ],
      ),
    );

    if (choice == 'manual') {
      _editAddressManual();
    } else if (choice == 'map') {
      _openMapPicker();
    }
  }

  // --- FUNGSI EDIT MANUAL ---
  void _editAddressManual() async {
    TextEditingController editController = TextEditingController(text: _alamatController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Alamat", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Contoh: Jl. Mawar No. 12, RT 01/RW 05, Kelurahan..., Kecamatan..., Kota...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Alamat akan disimpan untuk pembelian selanjutnya",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              String address = editController.text.trim();
              if (address.isNotEmpty) {
                Navigator.pop(context, address);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Alamat tidak boleh kosong!")),
                );
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _alamatController.text = result;
        _selectedLocation = null;
        _distanceInKm = 0;
      });

      _getCoordinatesFromAddress(result);
    }
  }

  String formatRupiah(int price) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(price);
  }

  @override
  void dispose() {
    _alamatController.dispose();
    _catatanController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  void _pilihMetodePembayaran() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentSelectionScreen()),
    );

    if (result != null) {
      setState(() {
        _metodePembayaran = result['internal_code'];
        _tampilanMetode = result['display_name'];
        _iconPembayaran = result['icon'];
        _colorPembayaran = result['color'];
      });
    }
  }

  Future<void> _submitOrder(CartProvider cart) async {
    if (_isDelivery && _alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Alamat wajib diisi untuk pengiriman!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesi habis. Silakan login ulang.")),
      );
      return;
    }

    int subtotal = cart.totalPrice;
    int ongkir = _isDelivery ? _biayaOngkir : 0;
    int diskon = _discountAmount;
    int totalFinal = subtotal + ongkir - diskon;
    if (totalFinal < 0) totalFinal = 0;

    Map<String, int> qtyMap = {};
    for (var item in cart.items) {
      qtyMap[item.id] = (qtyMap[item.id] ?? 0) + 1;
    }

    List<Map<String, dynamic>> itemsForDb = [];
    Set<String> processedIds = {};

    for (var item in cart.items) {
      if (!processedIds.contains(item.id)) {
        itemsForDb.add({
          'product_id': item.id,
          'name': item.nama,
          'price': item.harga,
          'quantity': qtyMap[item.id],
          'image_url': item.gambarUrl,
        });
        processedIds.add(item.id);
      }
    }

    // DATA ORDER
    Map<String, dynamic> orderData = {
      'order_date': Timestamp.now(),
      'status': 'Menunggu Konfirmasi',
      'type': _isDelivery ? 'Delivery' : 'Pickup',
      'userId': user.uid,
      'customer_name': user.displayName ?? user.email ?? 'Pelanggan',
      'address': _isDelivery ? _alamatController.text : '-',
      'note': _catatanController.text,
      'payment_method': _metodePembayaran,
      'items': itemsForDb,
      'summary': {
        'subtotal': subtotal,
        'shipping_cost': ongkir,
        'discount': diskon,
        'voucher_code': _voucherApplied ? _voucherCode : null,
        'total': totalFinal,
      },
      'restaurant_location': {
        'name': _restaurantName,
        'address': _restaurantAddress,
        'latitude': _restaurantLocation.latitude,
        'longitude': _restaurantLocation.longitude,
      },
      if (_isDelivery && _selectedLocation != null)
        'delivery_location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'distance_km': _distanceInKm,
          'estimated_time_minutes': (_distanceInKm * 5).round(),
        },
      if (!_isDelivery && _userLocationForPickup != null)
        'pickup_info': {
          'user_latitude': _userLocationForPickup!.latitude,
          'user_longitude': _userLocationForPickup!.longitude,
          'distance_km': _pickupDistanceInKm,
          'estimated_time_minutes': (_pickupDistanceInKm * 5).round(),
        },
    };

    if (_metodePembayaran == 'COD') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            orderData: orderData,
            paymentMethod: 'COD'
          )
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            orderData: orderData,
            paymentMethod: _metodePembayaran
          )
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    int subtotal = cart.totalPrice;
    int ongkir = _isDelivery ? _biayaOngkir : 0;
    int diskon = _discountAmount;
    int grandTotal = subtotal + ongkir - diskon;
    if (grandTotal < 0) grandTotal = 0;

    Map<String, int> quantityMap = {};
    for (var item in cart.items) {
      quantityMap[item.id] = (quantityMap[item.id] ?? 0) + 1;
    }
    List<MenuModel> uniqueItems = [];
    Set<String> processedIds = {};
    for (var item in cart.items) {
      if (!processedIds.contains(item.id)) {
        uniqueItems.add(item);
        processedIds.add(item.id);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Delivery/Pickup
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(child: _buildToggleButton("Diantar (Delivery)", true)),
                        Expanded(child: _buildToggleButton("Ambil Sendiri", false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // === BAGIAN DELIVERY ===
                  if (_isDelivery) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Alamat Pengiriman", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _openMapPicker,
                              icon: const Icon(Icons.map, color: Colors.blue, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Pilih di peta",
                            ),
                            IconButton(
                              onPressed: _editAddress,
                              icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Edit alamat",
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // INFORMASI JARAK
                    if (_isDelivery && _distanceInKm > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Jarak pengiriman: ${_distanceInKm.toStringAsFixed(1)} km",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[800],
                              ),
                            ),
                            const Spacer(),
                            if (_isCalculatingDistance)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue[700],
                                ),
                              ),
                          ],
                        ),
                      ),

                    if (_isLoadingAddress)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text("Memuat alamat...", style: GoogleFonts.poppins(color: Colors.grey)),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: _editAddress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _selectedLocation != null ? Icons.location_on : Icons.location_off,
                                  color: _selectedLocation != null ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_alamatController.text.isNotEmpty)
                                        Row(
                                          children: [
                                            Text(
                                              "Alamat Tersimpan",
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.green[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (_selectedLocation != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  "Dari Peta",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _alamatController.text.isEmpty
                                            ? "Belum ada alamat tersimpan. Ketuk untuk menambahkan."
                                            : _alamatController.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: _alamatController.text.isEmpty ? Colors.grey[400] : Colors.black,
                                        ),
                                      ),
                                      if (_alamatController.text.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "Ketuk untuk mengubah alamat",
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.orange,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.map_outlined, size: 12, color: Colors.orange),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                if (_alamatController.text.isEmpty)
                                  const Icon(Icons.add_circle_outline, color: Colors.orange, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // === BAGIAN PICKUP ===
                  if (!_isDelivery) ...[
                    Text("Lokasi Restaurant", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // INFO RESTAURANT
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.restaurant, color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _restaurantName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _restaurantAddress,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // TOMBOL GET LOCATION
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isGettingPickupLocation ? null : _getUserLocationForPickup,
                                    icon: const Icon(Icons.location_searching),
                                    label: _isGettingPickupLocation 
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text("Cek Jarak dari Lokasi Saya"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: _openDirectionsInMaps,
                                  icon: const Icon(Icons.directions, color: Colors.green),
                                  tooltip: "Buka di Google Maps",
                                ),
                              ],
                            ),
                            
                            // JARAK PICKUP
                            if (_pickupDistanceInKm > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_walk, color: Colors.green[700]),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Jarak dari lokasi Anda",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            "${_pickupDistanceInKm.toStringAsFixed(1)} km",
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          Text(
                                            "Perkiraan waktu: ${(_pickupDistanceInKm * 5).round()} menit",
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
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
                    ),
                    const SizedBox(height: 20),
                  ],

                  // List Pesanan
                  Text("Daftar Menu", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    children: uniqueItems.map((item) {
                      int qty = quantityMap[item.id] ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.gambarUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.fastfood),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  Text(item.deskripsi,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(formatRupiah(item.harga),
                                      style: GoogleFonts.poppins(color: Colors.orange, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                              child:
                                  Text("${qty}x", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.orange)),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // --- BAGIAN VOUCHER ---
                  Text("Voucher / Diskon", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _voucherController,
                                  decoration: InputDecoration(
                                    hintText: "Masukkan kode voucher",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                    suffixIcon: _voucherApplied
                                        ? IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: _removeVoucher,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isApplyingVoucher ? null : _applyVoucher,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: _isApplyingVoucher
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _voucherApplied ? "Terpakai" : "Pakai",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          
                          // PESAN VOUCHER
                          if (_voucherMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _voucherMessage,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _voucherMessageColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          
                          const SizedBox(height: 8),
                          
                          // INFO VOUCHER YANG TERSEDIA
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_offer, color: Colors.orange[700], size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Voucher tersedia:",
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildVoucherChip('DISKON10'),
                                    _buildVoucherChip('DISKON20'),
                                    _buildVoucherChip('HEMAT15'),
                                    _buildVoucherChip('GRATISONGKIR'),
                                    _buildVoucherChip('NEWUSER'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Minimal pembelian berlaku untuk setiap voucher",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- BAGIAN PILIH PEMBAYARAN ---
                  Text("Metode Pembayaran", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _pilihMetodePembayaran,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: _colorPembayaran.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_iconPembayaran, color: _colorPembayaran),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_tampilanMetode,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Ketuk untuk mengganti",
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Catatan (Opsional)",
                      hintText: "Contoh: Jangan pedas, tambah sambal, dsb...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // BOTTOM BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryRow("Subtotal", subtotal),
                const SizedBox(height: 5),
                if (_isDelivery && _distanceInKm > 0)
                  Column(
                    children: [
                      _buildSummaryRow("Jarak pengiriman", 0, customValue: "${_distanceInKm.toStringAsFixed(1)} km"),
                      const SizedBox(height: 5),
                    ],
                  ),
                if (!_isDelivery && _pickupDistanceInKm > 0)
                  Column(
                    children: [
                      _buildSummaryRow("Jarak dari Anda", 0, customValue: "${_pickupDistanceInKm.toStringAsFixed(1)} km"),
                      const SizedBox(height: 5),
                    ],
                  ),
                _buildSummaryRow("Ongkos Kirim", ongkir, isOrange: true),
                
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text("Diskon ($_voucherCode)", style: GoogleFonts.poppins(color: Colors.green)),
                          const SizedBox(width: 5),
                          const Icon(Icons.discount, color: Colors.green, size: 14),
                        ],
                      ),
                      Text(
                        "-${formatRupiah(_discountAmount)}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Pembayaran",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(formatRupiah(grandTotal),
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _submitOrder(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text("Lanjut Pembayaran",
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isForDelivery) {
    bool isSelected = _isDelivery == isForDelivery;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDelivery = isForDelivery;
          if (!_isDelivery) {
            _selectedLocation = null;
            _distanceInKm = 0;
          } else {
            _userLocationForPickup = null;
            _pickupDistanceInKm = 0;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 5)] : [],
        ),
        child: Center(
          child: Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: isSelected ? Colors.orange : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildVoucherChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Text(
        code,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.orange[700],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value, {bool isOrange = false, String? customValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey)),
        customValue != null
            ? Text(customValue,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: isOrange ? Colors.orange : Colors.blue))
            : Text(formatRupiah(value),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: isOrange ? Colors.orange : Colors.black)),
      ],
    );
  }
}

// ==========================================
// HALAMAN PILIH METODE PEMBAYARAN
// ==========================================
class PaymentSelectionScreen extends StatelessWidget {
  const PaymentSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Pilih Pembayaran", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Transfer Manual", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          _buildPaymentOption(
            context,
            title: "Transfer Bank",
            internalCode: "Transfer Bank",
            subtitle: "BCA, Mandiri, BRI (Cek Manual)",
            icon: Icons.account_balance,
            color: Colors.blue,
          ),

          const SizedBox(height: 20),
          Text("E-Wallet / QRIS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          _buildPaymentOption(
            context,
            title: "QRIS (E-Wallet)",
            internalCode: "QRIS",
            subtitle: "Scan QRIS (Gopay/OVO/Dana)",
            icon: Icons.qr_code_2,
            color: Colors.purple,
          ),

          const SizedBox(height: 20),
          Text("Bayar di Tempat", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),

          _buildPaymentOption(
            context,
            title: "Tunai (COD)",
            internalCode: "COD",
            subtitle: "Bayar saat makanan sampai",
            icon: Icons.money,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context,
      {required String title,
      required String internalCode,
      required String subtitle,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.pop(context, {
            'display_name': title,
            'internal_code': internalCode,
            'icon': icon,
            'color': color,
          });
        },
      ),
    );
  }
}