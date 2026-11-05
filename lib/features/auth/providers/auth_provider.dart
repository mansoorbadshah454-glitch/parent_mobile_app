import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as flutter_secure_storage;
import '../services/auth_service.dart';
import '../../../services/push_notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// Actively monitor if the user's account is deleted from the backend
final userAccessStatusProvider = Provider<void>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) return;

  final subscription = FirebaseFirestore.instance
      .collection('global_users')
      .doc(user.uid)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) {
      print('AuthProvider: User document deleted. Forcing sign out.');
      ref.read(authControllerProvider.notifier).logout();
    }
  }, onError: (error) {
    print('AuthProvider: Snapshot error (likely permission denied). Forcing sign out.');
    ref.read(authControllerProvider.notifier).logout();
  });

  ref.onDispose(() {
    subscription.cancel();
  });
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncValue.data(null));

  Future<void> login(String schoolId, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();
      final cleanSchoolId = schoolId.trim();

      final credential = await _authService.signInWithEmailPassword(email: cleanEmail, password: cleanPassword);
      
      if (credential.user != null) {
        // Verify user exists in the specified school
        final parentDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(cleanSchoolId)
            .collection('parents')
            .doc(credential.user!.uid)
            .get();
            
        if (!parentDoc.exists) {
           await _authService.signOut();
           throw Exception('Invalid School ID or parent not found in this school.');
        }
        
        // Save schoolId to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_school_id', cleanSchoolId);

        const storage = flutter_secure_storage.FlutterSecureStorage(
          aOptions: flutter_secure_storage.AndroidOptions(encryptedSharedPreferences: true)
        );
        await storage.write(key: 'saved_email', value: cleanEmail);
        await storage.write(key: 'saved_password', value: cleanPassword);
        await storage.write(key: 'saved_school_id', value: cleanSchoolId);
        await storage.write(key: 'auto_login', value: 'true');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final currentUid = _authService.currentUser?.uid;
      final prefs = await SharedPreferences.getInstance();
      final currentSchoolId = prefs.getString('current_school_id');

      // 1. Purge all local notifications, OS alarms, and FCM topic subscriptions
      await PushNotificationService().cleanSession(currentSchoolId, currentUid);

      // 2. Clear fee reminder and session cache in SharedPreferences
      await prefs.remove('fee_reminder_count');
      await prefs.remove('last_fee_date');
      await prefs.remove('current_school_id');

      const storage = flutter_secure_storage.FlutterSecureStorage(
        aOptions: flutter_secure_storage.AndroidOptions(encryptedSharedPreferences: true)
      );
      await storage.write(key: 'auto_login', value: 'false');
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
