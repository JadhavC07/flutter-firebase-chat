import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/firebase_options.dart';
import 'package:myapp/home_page.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Function to store/update user data in Firestore
  Future<void> storeUserData(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'Unknown User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'uid': user.uid,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('User data stored successfully');
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "G-Chat",
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            // Store user data when authenticated
            storeUserData(snapshot.data!);
            return const HomePage();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
