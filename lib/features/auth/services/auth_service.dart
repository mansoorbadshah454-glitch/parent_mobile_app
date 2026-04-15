import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // We can also verify if they are actually a parent by checking Firestore here
      // if needed, or handle it in the provider.
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'NO_INTERNET_CONNECTION'; // Clean key string to catch in UI
      default:
        // Firebase auth can throw many errors, some generic ones might be related to network if e.message contains it.
        if (e.message != null && e.message!.toLowerCase().contains('network')) {
           return 'NO_INTERNET_CONNECTION';
        }
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}
