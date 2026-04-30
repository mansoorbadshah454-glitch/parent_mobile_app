import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication auth = LocalAuthentication();
  bool _hasSavedCredentials = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.read(key: 'saved_email');
    final savedPassword = await _storage.read(key: 'saved_password');
    final savedSchoolId = await _storage.read(key: 'saved_school_id');
    final autoLoginStr = await _storage.read(key: 'auto_login');
    final autoLogin = autoLoginStr == 'true';

    if (savedEmail != null && savedPassword != null && savedSchoolId != null) {
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _schoolIdController.text = savedSchoolId;
          _hasSavedCredentials = true;
        });

        if (autoLogin) {
          ref.read(authControllerProvider.notifier).login(
            savedSchoolId,
            savedEmail,
            savedPassword,
          );
        }
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      if (mounted) {
        setState(() {
          _isAuthenticating = true;
        });
      }
      authenticated = await auth.authenticate(
        localizedReason: 'Please confirm your identity to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } on PlatformException catch (e) {
      print("Local Auth Error: $e");
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
      return;
    }
    
    if (!mounted) return;

    if (authenticated) {
      _login();
    }
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      String rawSchoolId = _schoolIdController.text.trim();
      // If user typed only numbers (e.g., "6257"), format it as "SCHOOL_6257"
      if (RegExp(r'^\d+$').hasMatch(rawSchoolId)) {
        rawSchoolId = 'SCHOOL_$rawSchoolId';
      }

      ref.read(authControllerProvider.notifier).login(
        rawSchoolId,
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(
      authControllerProvider,
      (_, state) {
        state.whenOrNull(
          error: (error, stackTrace) {
            final errorStr = error.toString();
            if (errorStr.contains('NO_INTERNET_CONNECTION') || errorStr.toLowerCase().contains('network')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.wifi_off, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No internet connection detected. Please try again.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFE53935),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(20),
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorStr.replaceAll('Exception: ', ''))),
              );
            }
          },
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.family_restroom,
                    size: 80,
                    color: Color(0xFF2E3B55),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Parents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3B55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to access your child\'s portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _schoolIdController,
                    keyboardType: TextInputType.text,
                    enabled: !isLoading && !_isAuthenticating,
                    decoration: const InputDecoration(
                      labelText: 'School ID',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your School ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading && !_isAuthenticating,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    enabled: !isLoading && !_isAuthenticating,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading || _isAuthenticating ? null : _login,
                    child: isLoading || _isAuthenticating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please contact your school administrator to reset your password.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password? Contact your school',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_hasSavedCredentials) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: isLoading || _isAuthenticating ? null : _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint, color: Color(0xFF2E3B55), size: 28),
                      label: const Text('Login with Device Lock', style: TextStyle(color: Color(0xFF2E3B55))),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
