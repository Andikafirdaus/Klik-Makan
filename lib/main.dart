import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'layouts/main_layout.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'services/auth_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/popup/promo_popup.dart'; // IMPORT POPUP

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _loadingProcess;

  @override
  void initState() {
    super.initState();
    _loadingProcess = Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      Future.delayed(const Duration(seconds: 2)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingProcess,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: Text("Error: ${snapshot.error}"))),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => CartProvider()),
            ChangeNotifierProvider(create: (context) => FavoriteProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Klik Makan',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(),
            ),
            home: const AuthGateWithPopup(), // GUNAKAN YANG BARU
          ),
        );
      },
    );
  }
}

// GERBANG LOGIKA DENGAN POPUP
class AuthGateWithPopup extends StatefulWidget {
  const AuthGateWithPopup({super.key});

  @override
  State<AuthGateWithPopup> createState() => _AuthGateWithPopupState();
}

class _AuthGateWithPopupState extends State<AuthGateWithPopup> {
  bool _shouldShowPopup = true;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    _checkPopupStatus();
  }

  Future<void> _checkPopupStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getString('last_popup_shown') ?? '';
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      if (lastShown == today) {
        setState(() {
          _shouldShowPopup = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking popup status: $e');
    }
  }

  Future<void> _markPopupAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('last_popup_shown', today);
      debugPrint('Popup ditandai sudah ditampilkan untuk tanggal: $today');
    } catch (e) {
      debugPrint('Error marking popup as shown: $e');
    }
  }

  void _showPromoPopup(BuildContext context) {
    if (!_shouldShowPopup || _popupShown) return;
    
    // Tambahkan delay untuk memastikan UI sudah siap
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      _popupShown = true;
      
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (context) => PromoPopup(
          onClose: () async {
            await _markPopupAsShown();
            setState(() {
              _shouldShowPopup = false;
            });
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final User user = snapshot.data!;
            final String email = user.email ?? "";

            if (email.trim().toLowerCase() == 'admin@klikmakan.com') {
              return const AdminScreen();
            }

            // Tampilkan MainLayout, lalu tampilkan popup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPromoPopup(context);
            });

            return const MainLayout();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}