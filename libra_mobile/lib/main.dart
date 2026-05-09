import 'package:flutter/material.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/products/screens/home_screen.dart';
import 'features/auth/screens/register_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiBRA Shop',
      debugShowMaterialGrid: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),

      // Check if user is already logged in
      home: FutureBuilder<bool>(
        future: TokenStorage.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show splash while checking token

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // If logged in go to home, else go to login

          if (snapshot.data == true) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/cart': (context) => Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: const Center(child: Text('Cart - Coming in phase 8')),
        ),
      },
    );
  }
}
