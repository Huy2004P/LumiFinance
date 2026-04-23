import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/apple_design.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    MultiProvider(
      providers: [Provider<String>(create: (_) => "LumiFinance")],
      child: const MyApp(),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Đang xử lý thông báo chạy ngầm: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumiFinance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light, // Chuyển sang Light Mode
        scaffoldBackgroundColor: AppleColors.pureWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppleColors.appleBlue,
          primary: AppleColors.appleBlue,
          surface: AppleColors.pureWhite,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: AppleTextStyles.displayHero,
          bodyLarge: AppleTextStyles.body,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
