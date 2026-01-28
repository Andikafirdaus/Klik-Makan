import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- REGISTER (DIPERBAIKI - TANPA AUTO LOGIN) ---
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String birthDate,
  }) async {
    try {
      // 1. Buat user TANPA langsung login
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Update display name di Firebase Auth
        await user.updateDisplayName(name);
        
        // 3. Simpan data lengkap ke Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'birth_date': birthDate,
          'created_at': FieldValue.serverTimestamp(),
          'role': 'user',
        });

        // 4. LOGOUT SETELAH REGISTRASI (KUNCI UTAMA!)
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Gagal mendaftar.';
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // --- LOGIN (Tetap) ---
  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Gagal login.';
    }
  }

  // --- RESET PASSWORD (LUPA KATA SANDI) ---
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Gagal mengirim email reset password.';
    } catch (e) {
      throw 'Terjadi kesalahan: $e';
    }
  }

  // --- GOOGLE SIGN IN (Tetap) ---
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'User Google',
            'phone': '',
            'birth_date': '',
            'photo_url': user.photoURL,
            'created_at': FieldValue.serverTimestamp(),
            'role': 'user',
          });
        }
      }
      return user;
    } catch (e) {
      throw 'Gagal Login Google: $e';
    }
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
}