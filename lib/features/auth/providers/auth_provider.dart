import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as flutter_secure_storage;
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<void> login(String schoolId, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signInWithEmailPassword(email: email, password: password);
      
      if (credential.user != null) {
        // Verify user exists in the specified school
        final parentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(schoolId)
            .collection('parents')
            .doc(credential.user!.uid)
            .get();
            
        if (!parentDoc.exists) {
           await _authService.signOut();
           throw Exception('Invalid School ID or parent not found in this school.');
        }
        
        // Save schoolId to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_school_id', schoolId);

        const storage = flutter_secure_storage.FlutterSecureStorage(
          aOptions: flutter_secure_storage.AndroidOptions(encryptedSharedPreferences: true)
        );
        await storage.write(key: 'saved_email', value: email);
        await storage.write(key: 'saved_password', value: password);
        await storage.write(key: 'saved_school_id', value: schoolId);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
