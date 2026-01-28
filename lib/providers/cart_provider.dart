import 'package:flutter/material.dart';
import '../models/menu_model.dart';

class CartProvider with ChangeNotifier {
  // Gudang penyimpanan pesanan
  final List<MenuModel> _items = [];

  List<MenuModel> get items => _items;

  // Hitung Total Rupiah
  int get totalPrice {
    int total = 0;
    for (var item in _items) {
      total += item.harga;
    }
    return total;
  }

  // --- LOGIKA BARU UNTUK JUMLAH (QUANTITY) ---

  // 1. Cek ada berapa porsi untuk menu ID tertentu?
  int getQuantity(String id) {
    return _items.where((item) => item.id == id).length;
  }

  // 2. Tambah 1 Porsi (Sama kayak add biasa) - UBAH INI
  void addOne(MenuModel menu, {String? note}) { // Ubah required menjadi optional
    _items.add(menu);
    notifyListeners();
  }

  // 3. Kurangi 1 Porsi
  void removeOne(String id) {
    // Cari posisi barangnya di list
    int index = _items.indexWhere((item) => item.id == id);
    
    // Kalau ketemu, hapus satu saja
    if (index != -1) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // Bersihkan semua
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}