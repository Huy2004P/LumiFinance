import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class AuthService {
  static const String _key = ApiConstants.firebaseApiKey;

  // 1. HÀM ĐĂNG KÝ (signUp)
  Future<String?> register(String email, String password) async {
    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_key",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email.trim(),
          "password": password,
          "returnSecureToken": true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['idToken']);
        return "SUCCESS";
      } else {
        return data['error']['message'];
      }
    } catch (e) {
      return "LỖI KẾT NỐI: Vui lòng kiểm tra mạng.";
    }
  }

  // 2. HÀM ĐĂNG NHẬP (signInWithPassword)
  Future<String?> login(String email, String password) async {
    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_key",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": email.trim(),
          "password": password,
          "returnSecureToken": true,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['idToken']);
        return "SUCCESS";
      } else {
        return data['error']['message'];
      }
    } catch (e) {
      return "LỖI KẾT NỐI: Vui lòng kiểm tra mạng.";
    }
  }

  // 3. HÀM LƯU VÉ THÔNG HÀNH (Két sắt)
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    print("Đã giấu Token vào két sắt thành công!");
  }

  // 4. HÀM QUÊN MẬT KHẨU (sendOobCode)
  Future<String?> resetPassword(String email) async {
    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$_key",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "requestType": "PASSWORD_RESET",
          "email": email.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return "SUCCESS";
      } else {
        return data['error']['message'];
      }
    } catch (e) {
      return "LỖI KẾT NỐI: Vui lòng kiểm tra mạng.";
    }
  }

  // 5. HÀM ĐĂNG XUẤT (Logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    print("Đã hủy vé, đăng xuất thành công!");
  }

  // 6. HÀM XÓA TÀI KHOẢN (Delete Account)
  Future<String?> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final idToken = prefs.getString('auth_token');

    if (idToken == null) return "LỖI: Không tìm thấy phiên đăng nhập.";

    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$_key",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"idToken": idToken}),
      );

      if (response.statusCode == 200) {
        await prefs.remove('auth_token');
        return "SUCCESS";
      } else {
        final data = json.decode(response.body);
        return data['error']['message'];
      }
    } catch (e) {
      return "LỖI KẾT NỐI: Vui lòng kiểm tra mạng.";
    }
  }

  // 7. HÀM LẤY TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
