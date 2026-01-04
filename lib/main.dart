import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';

// Screens - SPLASH FILE DELETE कर दिया ✅
import 'screens/signup_screen.dart';  // 🔥 DIRECT START
import 'screens/login_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_itinerary_screen.dart';
import 'screens/add_traveler_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/itinerary_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AI Travel Support App',
        debugShowCheckedModeBanner: false,
        initialRoute: '/signup',  // 🔥 DIRECT SIGNUP - NO SPLASH!

        routes: {
          // Auth - SPLASH हटाया ✅
          '/signup': (_) => const SignupScreen(),  // 🔥 पहला screen
          '/login': (_) => LoginScreen(),
          '/forgot': (_) => const ForgetPasswordScreen(),

          // Main
          '/dashboard': (_) => const DashboardScreen(),
          '/upload': (_) => UploadItineraryScreen(),

          // Add Traveler with arguments
          '/add-traveler': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final mapArgs = args as Map<String, dynamic>?;
            return AddTravelerScreen(
              itineraryId: mapArgs?['id'] ?? '',
              itineraryTitle: mapArgs?['title'] ?? 'Trip',
            );
          },

          '/notifications': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final mapArgs = args as Map<String, dynamic>?;
            return NotificationsScreen(
              itineraryId: mapArgs?['id'] ?? 'default',
              itineraryTitle: mapArgs?['title'] ?? 'Your Trip',
            );
          },

          '/ai-chat': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final mapArgs = args as Map<String, dynamic>?;
            return AIChatScreen(
              itineraryId: mapArgs?['id'] ?? 'default',
              itineraryTitle: mapArgs?['title'] ?? 'Your Trip',
            );
          },

          '/itinerary-detail': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final itinerary = (args as Map<String, dynamic>?) ?? {};
            return ItineraryDetailScreen(itinerary: itinerary);
          },
        },
      ),
    );
  }
}
