import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/apple_design.dart';
import '../screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền trắng sang trọng thay cho màu đen cũ
      backgroundColor: AppleColors.pureWhite,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Thêm một chút gradient cực nhẹ để tạo chiều sâu Cinema
          gradient: RadialGradient(
            colors: [Colors.white, AppleColors.lightGray.withOpacity(0.5)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hầm hố hơn với đổ bóng và màu nhấn
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppleColors.nearBlack.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                size: 120, // To hơn cho hầm hố
                color: AppleColors.appleBlue, // Dùng màu xanh Apple đặc trưng
              ),
            ),
            const SizedBox(height: 32),
            // Tên app với hiệu ứng chữ đậm, chặt chẽ
            Text("LumiFinance", style: AppleTextStyles.displayHero),
            const SizedBox(height: 12),
            // Thêm slogan nhỏ cho "ngầu"
            Text(
              "THE NEW STANDARD OF FINANCE",
              style: TextStyle(
                color: AppleColors.nearBlack.withOpacity(0.4),
                fontSize: 12,
                letterSpacing: 4, // Slogan thì giãn cách rộng ra cho sang
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
