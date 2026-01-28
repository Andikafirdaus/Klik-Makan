import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng restaurantLocation;
  
  const MapPickerScreen({
    super.key,
    this.initialPosition,
    required this.restaurantLocation,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  
  // LOKASI RESTAURANT (CONTOH: JAKARTA)
  static const LatLng _restaurantLatLng = LatLng(-6.1202778, 106.1915000);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Cek permission dulu
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Fallback ke restaurant location
        setState(() {
          _selectedLocation = _restaurantLatLng;
          _isLoading = false;
        });
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      // Pindah kamera ke lokasi user
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 14),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error getting location: $e");
      }
      setState(() {
        _selectedLocation = _restaurantLatLng;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Pengiriman'),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _restaurantLatLng,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                  },
                  markers: {
                    if (_selectedLocation != null)
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        infoWindow: const InfoWindow(
                          title: 'Lokasi Pengiriman',
                          snippet: 'Ketuk untuk mengubah',
                        ),
                      ),
                    // Marker restaurant
                    Marker(
                      markerId: const MarkerId('restaurant'),
                      position: _restaurantLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      infoWindow: const InfoWindow(
                        title: 'Klik Makan Outlet',
                        snippet: 'Lokasi restaurant',
                      ),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                
                // Tombol tengah bawah
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk peta untuk pilih lokasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_selectedLocation != null)
                            Text(
                              'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                              'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}