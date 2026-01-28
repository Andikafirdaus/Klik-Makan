import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Font
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; // <--- IMPORT BARU

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Variable untuk atur mata (show/hide)

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi format email sederhana
    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginGoogle() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- LOGO & HEADER ---
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fastfood_rounded, size: 50, color: Colors.orange),
              ),
              const SizedBox(height: 25),
              Text(
                'Klik Makan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black87
                ),
              ),
              Text(
                'Masuk untuk mulai jajan enak!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14, 
                  color: Colors.grey
                ),
              ),
              const SizedBox(height: 40),
              
              // --- INPUT EMAIL ---
              Text(
                "Email", 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Masukkan email kamu',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(
                    Icons.email_outlined, 
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // --- INPUT PASSWORD (DENGAN MATA) ---
              Text(
                "Password", 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Logika sembunyi/lihat
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), 
                    borderSide: BorderSide.none
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: Icon(
                    Icons.lock_outline, 
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                  
                  // TOMBOL MATA
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              
              // --- LINK LUPA PASSWORD ---
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Lupa Password?',
                    style: GoogleFonts.poppins(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // --- TOMBOL LOGIN ---
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Masuk Sekarang', 
                          style: GoogleFonts.poppins(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // --- PEMISAH ---
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "atau", 
                      style: GoogleFonts.poppins(
                        color: Colors.grey, 
                        fontSize: 12
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 20),

              // --- LOGIN GOOGLE ---
              SizedBox(
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginGoogle,
                  icon: const Icon(
                    Icons.g_mobiledata, 
                    size: 35, 
                    color: Colors.red
                  ), 
                  label: Text(
                    'Masuk dengan Google', 
                    style: GoogleFonts.poppins(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: Colors.black
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- KE REGISTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum punya akun?", 
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen()
                        ),
                      );
                    },
                    child: Text(
                      'Daftar dulu', 
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, 
                        color: Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}