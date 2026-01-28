import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';

class FavoriteProvider with ChangeNotifier {
  final List<MenuModel> _favoriteMenus = [];
  bool _isLoading = false;

  List<MenuModel> get favoriteMenus => _favoriteMenus;
  bool get isLoading => _isLoading;

  Future<bool> isFavorite(String menuId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      return favorites.contains(menuId);
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  Future<void> addFavorite(MenuModel menu) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _favoriteMenus.add(menu);
      
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorites') ?? [];
      if (!favorites.contains(menu.id)) {
        favorites.add(menu.id);
        await prefs.setStringList('favorites', favorites);
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_favorites')
            .doc(user.uid)
            .collection('favorites')
            .doc(menu.id)
            .set({
              'menuId': menu.id,
              'menuName': menu.nama,
              'menuPrice': menu.harga,
              'menuImage': menu.gambarUrl,
              'menuCategory': menu.kategori,
              'addedAt': FieldValue.serverTimestamp(),
            });
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding favorite: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String menuId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _favoriteMenus.removeWhere((menu) => menu.id == menuId);
      
      final prefs = await SharedPreferences.getInstance();
      List<String> favorites = prefs.getStringList('favorites') ?? [];
      favorites.remove(menuId);
      await prefs.setStringList('favorites', favorites);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_favorites')
            .doc(user.uid)
            .collection('favorites')
            .doc(menuId)
            .delete();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error removing favorite: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await SharedPreferences.getInstance();
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}