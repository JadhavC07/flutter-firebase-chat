import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isGoogleInitialized = false;

  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    try {
      if (!_isGoogleInitialized) {
        await _googleSignIn.initialize();
        setState(() => _isGoogleInitialized = true);
        debugPrint('✅ Google Sign-In initialized successfully');
      }
    } catch (e) {
      debugPrint('❌ Google Sign-In initialization error: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _initializeGoogle();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-id-token',
          message: 'Failed to retrieve ID token from Google Sign-In.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "name": user.displayName ?? 'Anonymous',
          "email": user.email ?? '',
          "photoUrl": user.photoURL ?? '',
          "createdAt": FieldValue.serverTimestamp(),
          "lastSignIn": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() => _isLoading = false);
      debugPrint('✅ Google sign-in successful: ${user?.email}');
      return user;
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('🔥 Sign-in error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ App Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 40),

                // ✅ Title
                Text(
                  'Welcome to G-Chat',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'Connect with friends and start chatting',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // ✅ Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isGoogleInitialized)
                        ? null
                        : () async => await signInWithGoogle(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 2,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login,
                                size: 24,
                                color: _isGoogleInitialized
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isGoogleInitialized
                                    ? 'Continue with Google'
                                    : 'Initializing...',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isGoogleInitialized
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Initialization Status
                if (!_isGoogleInitialized)
                  Text(
                    'Initializing Google Sign-In...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.orange),
                  ),

                const SizedBox(height: 32),

                // ✅ Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
