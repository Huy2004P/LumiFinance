import 'dart:io';

import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../config/api_constants.dart';

class UserService {
  // 1. LẤY THÔNG TIN CÁ NHÂN (Profile)
  // Gọi đến: /users/profile (GET)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await ApiService().get(ApiConstants.profileEndpoint);
      print("DEBUG RESPONSE DATA: ${response.data}");
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print("Lỗi lấy thông tin cá nhân: $e");
      return null;
    }
  }

  // 2. CẬP NHẬT THÔNG TIN CÁ NHÂN
  // Gọi đến: /users/profile (PUT)
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      // Chặn tuyệt đối việc gửi email lên để tránh ghi đè nhầm ở Backend
      data.remove('e-mail');
      data.remove('email');

      final response = await ApiService().put(
        ApiConstants.profileEndpoint,
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi cập nhật: $e");
      return false;
    }
  }

  // 3. CẬP NHẬT FCM TOKEN
  // Dùng để nhận thông báo đẩy từ Firebase Cloud Messaging
  // Gọi đến: /users/fcm-token (POST)
  Future<void> updateFCMToken(String token) async {
    try {
      await ApiService().post(
        ApiConstants.fcmTokenEndpoint,
        data: {"fcmToken": token},
      );
    } catch (e) {
      print("Lỗi cập nhật FCM Token: $e");
    }
  }

  // 4. XÓA TÀI KHOẢN VĨNH VIỄN
  // Gọi đến hàm "máy hút bụi" ở Backend để xóa sạch Transactions, Wallets...
  // Gọi đến: /users/account (DELETE)
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await ApiService().delete(
        ApiConstants.deleteAccountEndpoint,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': 'Không thể xóa tài khoản lúc này'};
    } catch (e) {
      print("Lỗi khi xóa tài khoản: $e");
      return {'success': false, 'message': 'Lỗi kết nối hệ thống'};
    }
  }

  // 5. LẤY THÔNG TIN AUTH HIỆN TẠI
  // Gọi đến: /auth/me (GET)
  Future<Map<String, dynamic>?> getAuthMe() async {
    try {
      final response = await ApiService().get(ApiConstants.authMeEndpoint);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print("Lỗi kiểm tra Auth Me: $e");
      return null;
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Gọi đến route router.post('/upload', ...) của Huy
      final response = await ApiService().post('/upload', data: formData);
      print("BACKEND TRẢ VỀ: ${response.data}");
      if (response.statusCode == 200) {
        // Giả sử Cloudinary trả về link trong trường 'url' hoặc 'imageUrl'
        return response.data['imageUrl'];
      }
      return null;
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      return null;
    }
  }
}
