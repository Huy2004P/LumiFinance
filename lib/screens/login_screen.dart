import 'package:flutter/material.dart';
import '../theme/apple_design.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'main_navigation.dart'; // Chuyển hướng vào màn hình chính sau khi Login thành công

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // HÀM XỬ LÝ ĐĂNG NHẬP
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Kiểm tra rỗng
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ Email và Mật khẩu"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Bật hiệu ứng loading
    setState(() => _isLoading = true);

    // Gọi API Auth
    final result = await AuthService().login(email, password);

    // Tắt loading
    if (mounted) setState(() => _isLoading = false);

    // Xử lý kết quả
    if (result == "SUCCESS") {
      if (mounted) {
        // Đăng nhập thành công
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      // Lỗi (Sai pass, không có mạng...) -> Báo lỗi ra màn hình
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: $result"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController resetEmailController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppleColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Reset Password",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your email address and we will send you a link to reset your password.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: AppleColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black45),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppleColors.appleBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                String? result = await AuthService().resetPassword(
                  resetEmailController.text,
                );
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result == "SUCCESS"
                            ? "Đã gửi email khôi phục!"
                            : "Lỗi: $result",
                      ),
                      backgroundColor: result == "SUCCESS"
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Send Link",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.pureWhite,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [AppleColors.pureWhite, AppleColors.lightGray],
            center: Alignment.topRight,
            radius: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 80,
                color: AppleColors.appleBlue,
              ),
              const SizedBox(height: 24),
              const Text("Sign in.", style: AppleTextStyles.displayHero),
              const SizedBox(height: 48),

              // Đã truyền Controller vào ô nhập liệu
              _buildModernInput("Email", controller: _emailController),
              const SizedBox(height: 16),
              _buildModernInput(
                "Password",
                isPassword: true,
                controller: _passwordController,
              ),

              const SizedBox(height: 32),
              _buildAppleButton("Continue", _isLoading ? null : _handleLogin),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _handleForgotPassword,
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: AppleColors.brightBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: AppleColors.nearBlack.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Create one",
                      style: TextStyle(
                        color: AppleColors.appleBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cập nhật hàm này để nhận thêm TextEditingController
  Widget _buildModernInput(
    String hint, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller, // Nhận phím gõ ở đây
        obscureText: isPassword,
        style: const TextStyle(color: AppleColors.nearBlack),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          filled: true,
          fillColor: AppleColors.pureWhite,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppleColors.appleBlue,
          disabledBackgroundColor: AppleColors.appleBlue.withOpacity(
            0.6,
          ), // Màu khi bị khóa (đang loading)
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppleColors.appleBlue.withOpacity(0.4),
        ),
        onPressed: onPressed,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
