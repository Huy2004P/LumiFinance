import 'package:flutter/material.dart';
import '../theme/apple_design.dart';
import '../services/auth_service.dart'; // Import AuthService bạn đã viết
import 'create_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Tạo controller để lấy dữ liệu từ TextField
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false; // Trạng thái chờ khi gọi API
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 2. Hàm xử lý đăng ký
  Future<void> _handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Kiểm tra tính hợp lệ cơ bản
    if (email.isEmpty || password.isEmpty) {
      _showError("Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (password != confirmPassword) {
      _showError("Mật khẩu xác nhận không khớp");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi hàm register từ AuthService
      final result = await AuthService().register(email, password);

      if (result == "SUCCESS") {
        if (mounted) {
          // Đăng ký xong, Token đã được lưu vào SharedPreferences
          // Giờ mới chuyển sang màn hình Setup Profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateProfileScreen(),
            ),
          );
        }
      } else {
        _showError(result ?? "Đăng ký thất bại");
      }
    } catch (e) {
      _showError("Lỗi kết nối: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Join Us.", style: AppleTextStyles.displayHero),
            const SizedBox(height: 48),

            // Gắn controller vào các Input
            _buildModernInput(
              "Email Address",
              Icons.email_outlined,
              controller: emailController,
            ),
            const SizedBox(height: 16),
            _buildModernInput(
              "Password",
              Icons.lock_outline,
              isPassword: true,
              controller: passwordController,
              isVisible: _isPasswordVisible,
              onToggleVisibility: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            const SizedBox(height: 16),
            _buildModernInput(
              "Confirm",
              Icons.lock_reset_outlined,
              isPassword: true,
              controller: confirmPasswordController,
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
              ),
            ),

            const SizedBox(height: 48),

            // Nút bấm gọi hàm xử lý
            _buildAppleButton(
              _isLoading ? "Creating Account..." : "Next Step",
              _isLoading ? () {} : _handleRegister,
            ),
          ],
        ),
      ),
    );
  }

  // Cập nhật hàm build input để nhận controller và toggle visibility
  Widget _buildModernInput(
    String hint,
    IconData icon, {
    bool isPassword = false,
    required TextEditingController controller,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppleColors.appleBlue),
          hintText: hint,
          filled: true,
          fillColor: AppleColors.pureWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.black38,
                    size: 22,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildAppleButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppleColors.appleBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
