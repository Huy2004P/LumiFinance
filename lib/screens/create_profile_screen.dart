import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/config/api_constants.dart';
import 'package:personal_finance_tracker/services/api_service.dart';
import '../theme/apple_design.dart';
import 'package:personal_finance_tracker/screens/main_navigation.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    if (nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Lấy mã định danh thiết bị (FCM Token)
      String? token = await FirebaseMessaging.instance.getToken();

      // 2. Gom toàn bộ dữ liệu vào một "gói"
      final Map<String, dynamic> profileData = {
        "displayName": nameController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "birthday": birthdayController.text.trim(),
        "organization": orgController.text.trim(),
        "bio": bioController.text.trim(),
        "fcmToken": token, // Đính kèm token để Backend nhận diện
      };

      // 3. Gọi API thông qua ApiService đã được cấu hình Header
      final response = await ApiService().post(
        ApiConstants.profileEndpoint,
        data: profileData,
      );

      if (mounted &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // 4. Thành công: Chuyển thẳng về Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MainNavigation(), // Đổi HomeScreen thành MainNavigation
          ),
          (route) => false, // Xóa sạch lịch sử các màn hình Setup trước đó
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Các field khớp với Backend API
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController orgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(
        title: const Text(
          "Setup Profile",
          style: TextStyle(
            color: AppleColors.nearBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppleColors.appleBlue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tell us about you.",
              style: AppleTextStyles.displayHero,
            ),
            const SizedBox(height: 32),

            _buildProfileInput(
              "Full Name",
              Icons.person_outline,
              nameController,
            ),
            const SizedBox(height: 16),
            _buildProfileInput(
              "Phone Number",
              Icons.phone_android_outlined,
              phoneController,
            ),
            const SizedBox(height: 16),
            _buildProfileInput(
              "Address",
              Icons.location_on_outlined,
              addressController,
            ),
            const SizedBox(height: 16),
            _buildProfileInput(
              "Birthday (YYYY-MM-DD)",
              Icons.cake_outlined,
              birthdayController,
            ),
            const SizedBox(height: 16),
            _buildProfileInput(
              "Organization",
              Icons.business_outlined,
              orgController,
            ),
            const SizedBox(height: 16),
            _buildProfileInput(
              "Bio",
              Icons.edit_note_outlined,
              bioController,
              maxLines: 3,
            ),

            const SizedBox(height: 48),

            _buildAppleButton(
              _isLoading ? "Processing..." : "Complete Profile",
              _isLoading ? () {} : _submitProfile,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInput(
    String hint,
    IconData icon,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppleColors.appleBlue),
          hintText: hint,
          filled: true,
          fillColor: AppleColors.pureWhite,
          contentPadding: const EdgeInsets.all(20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
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
          elevation: 10,
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
