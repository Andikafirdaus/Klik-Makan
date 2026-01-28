import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Makanan Putih
            const Icon(Icons.fastfood_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            
            // Tulisan "Klik Makan."
            Text(
              "Klik Makan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.w900, // ExtraBold
              ),
            ),
            
            // Loading Indicator SUDAH DIHAPUS disini
          ],
        ),
      ),
    );
  }
}