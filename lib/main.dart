import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
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
        initialRoute: '/splash',

        routes: {
          // Splash
          '/splash': (_) => const SplashScreen(),

          // Auth ✅ UPDATED!
          '/login': (_) => LoginScreen(),
          '/signup': (_) => const SignupScreen(),
          '/forgot': (_) => const ForgetPasswordScreen(),  // ✅ baseUrl REMOVED!

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

          // Notifications with arguments
          '/notifications': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final mapArgs = args as Map<String, dynamic>?;
            return NotificationsScreen(
              itineraryId: mapArgs?['id'] ?? 'default',
              itineraryTitle: mapArgs?['title'] ?? 'Your Trip',
            );
          },

          // AI Chat with arguments
          '/ai-chat': (context) {
            final Object? args = ModalRoute.of(context)?.settings.arguments;
            final mapArgs = args as Map<String, dynamic>?;
            return AIChatScreen(
              itineraryId: mapArgs?['id'] ?? 'default',
              itineraryTitle: mapArgs?['title'] ?? 'Your Trip',
            );
          },

          // Itinerary detail screen
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
