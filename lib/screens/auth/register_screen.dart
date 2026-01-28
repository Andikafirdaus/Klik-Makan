import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:google_fonts/google_fonts.dart'; // Import Font
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  
  // State untuk Mata (Visibility)
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _register() async {
    // Validasi field tidak boleh kosong
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua data!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan Konfirmasi tidak sama!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi panjang password
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter.'),
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
      // Panggil service register (TANPA auto-login)
      await AuthService().register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        birthDate: _dobController.text,
      );

      if (mounted) {
        // 1. Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 2. Tunggu sebentar agar user bisa baca pesan sukses
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // 3. Kembali ke halaman login (pop saja)
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal daftar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
      appBar: AppBar(
        title: Text(
          'Buat Akun Baru', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Lengkapi data diri kamu biar makin akrab!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            
            // 1. Nama Lengkap
            _buildLabel("Nama Lengkap"),
            _buildTextField(
              controller: _nameController, 
              hint: 'Cth: Agung Santoso', 
              icon: Icons.person_outline
            ),
            const SizedBox(height: 16),

            // 2. Nomor Telepon
            _buildLabel("Nomor Telepon"),
            _buildTextField(
              controller: _phoneController, 
              hint: 'Cth: 08123456789', 
              icon: Icons.phone_android,
              inputType: TextInputType.phone
            ),
            const SizedBox(height: 16),

            // 3. Tanggal Lahir
            _buildLabel("Tanggal Lahir"),
            TextField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: _inputDecoration(
                hint: 'Pilih Tanggal', 
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Email
            _buildLabel("Email"),
            _buildTextField(
              controller: _emailController, 
              hint: 'Cth: agung@email.com', 
              icon: Icons.email_outlined,
              inputType: TextInputType.emailAddress
            ),
            const SizedBox(height: 16),

            // 5. Password
            _buildLabel("Password"),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: _inputDecoration(
                hint: 'Minimal 6 karakter', 
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              ),
            ),
            const SizedBox(height: 16),

            // 6. Konfirmasi Password
            _buildLabel("Ulangi Password"),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              style: GoogleFonts.poppins(fontSize: 15),
              decoration: _inputDecoration(
                hint: 'Masukkan password lagi', 
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, 
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                )
              ),
            ),
            const SizedBox(height: 30),

            // --- TOMBOL DAFTAR ---
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                        'Daftar Sekarang', 
                        style: GoogleFonts.poppins(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
              ),
            ),

            // --- LINK KE LOGIN ---
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sudah punya akun?", 
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Login disini', 
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
    );
  }

  // Helper Widget biar kodingan lebih rapi
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label, 
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, 
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon,
    TextInputType inputType = TextInputType.text
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: _inputDecoration(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: Colors.grey.shade400,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(
        icon, 
        color: Colors.grey.shade600,
        size: 22,
      ),
      suffixIcon: suffixIcon,
    );
  }
}