import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class WalletService {
  // --- 1. LẤY DANH SÁCH VÍ ---
  Future<List<dynamic>> getWallets() async {
    try {
      final response = await ApiService().get(ApiConstants.walletsEndpoint);
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] ?? [];
      }
      return response.data is List ? response.data : [];
    } catch (e) {
      print("Lỗi lấy danh sách ví: $e");
      return [];
    }
  }

  // --- 2. TẠO VÍ MỚI (Bắt lỗi Backend) ---
  Future<dynamic> createWallet(Map<String, dynamic> data) async {
    try {
      final response = await ApiService().post(
        ApiConstants.walletsEndpoint,
        data: data,
      );
      return {
        'success': response.statusCode == 201 || response.statusCode == 200,
      };
    } on DioException catch (e) {
      // Bắt chính xác câu lỗi từ backend gửi về
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? "Lỗi từ Server!",
      };
    } catch (e) {
      print("Lỗi tạo ví: $e");
      return {'success': false, 'message': "Lỗi kết nối máy chủ!"};
    }
  }

  // --- 3. CẬP NHẬT THÔNG TIN VÍ (MỚI THÊM) ---
  Future<bool> updateWallet(String id, Map<String, dynamic> data) async {
    try {
      final response = await ApiService().put(
        '${ApiConstants.walletsEndpoint}/$id',
        data: data,
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi cập nhật ví: $e");
      return false;
    }
  }

  // --- 4. XÓA VÍ (Bắt lỗi không cho xóa ví có tiền) ---
  Future<dynamic> deleteWallet(String id) async {
    try {
      final response = await ApiService().delete(
        '${ApiConstants.walletsEndpoint}/$id',
      );
      return {
        'success': response.statusCode == 200 || response.statusCode == 204,
      };
    } on DioException catch (e) {
      // Bắt chính xác lỗi "Không thể xóa ví vẫn còn số dư"
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? "Không thể xóa ví lúc này!",
      };
    } catch (e) {
      print("Lỗi xóa ví: $e");
      return {'success': false, 'message': "Lỗi kết nối hoặc hệ thống!"};
    }
  }

  // --- 5. CHUYỂN TIỀN NỘI BỘ (Bắt lỗi thiếu tiền) ---
  Future<dynamic> transferMoney(Map<String, dynamic> data) async {
    try {
      final response = await ApiService().post(
        ApiConstants.transferEndpoint,
        data: data,
      );
      return {'success': response.statusCode == 200};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['error'] ?? "Giao dịch bị từ chối!",
      };
    } catch (e) {
      print("Lỗi chuyển tiền: $e");
      return {'success': false, 'message': "Lỗi kết nối!"};
    }
  }

  // --- 6. PHỤC VỤ FUTURE.WAIT CHO HOME ---
  Future<Response> getWalletsRaw() async {
    return await ApiService().get(ApiConstants.walletsEndpoint);
  }
}
