import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/food_recognition_screen.dart';
import 'screens/nutrition_label_scan_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/analytics_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MealManagementApp());
}

class MealManagementApp extends StatelessWidget {
  const MealManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D(iet) 101 - 식단 관리 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/food-recognition': (context) => const FoodRecognitionScreen(),
        '/nutrition-scan': (context) => const NutritionLabelScanScreen(),
        '/recommendation': (context) => const RecommendationScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
