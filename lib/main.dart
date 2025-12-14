import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:paperpulse/screens/auth_screen.dart';
import 'package:paperpulse/screens/dashboard_screen.dart';
import 'package:paperpulse/screens/splash_screen.dart';
import 'package:paperpulse/services/auth_services.dart';
import 'model/auth_model.dart';

// Colors
const Color primaryBlue = Color(0xFF4c51bf);
const Color secondaryPurple = Color(0xFF805ad5);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PaperPulseApp());
}

class PaperPulseApp extends StatelessWidget {
  const PaperPulseApp({super.key});

  // Function to artificially delay splash for 3 seconds
  Future<bool> loadSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaperPulse',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(color: primaryBlue),
        useMaterial3: true,
      ),

      // Step 1 → Wait for splash delay first
      home: FutureBuilder<bool>(
        future: loadSplash(),
        builder: (context, snapshot) {

          // Show splash while waiting
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }

          // Step 2 → After splash completed, now check Firebase auth
          return StreamBuilder<AppUser?>(
            stream: AuthService().user,
            builder: (context, snapshot) {

              // Firebase checking auth session
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              // User logged in
              if (snapshot.hasData && snapshot.data != null) {
                return DashboardScreen(initialUser: snapshot.data);
              }

              // Not logged in
              return const AuthScreen();
            },
          );
        },
      ),
    );
  }
}
