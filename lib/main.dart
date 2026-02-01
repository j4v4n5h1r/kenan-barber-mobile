import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/seller/seller_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..initialize(),
      child: MaterialApp(
        title: 'Poni Land',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Only show loading on initial app load, not during login
        if (authService.isLoading && authService.currentUser == null && authService.error == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }

        final user = authService.currentUser!;
        if (user.role == 'admin') {
          return const AdminHomeScreen();
        } else if (user.role == 'user') {
          return const UserHomeScreen();
        } else if (user.role == 'seller_barber' || user.role == 'seller_zoopark') {
          return const SellerHomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
