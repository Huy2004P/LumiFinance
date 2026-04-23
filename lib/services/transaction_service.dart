import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class TransactionService {
  // --- 1. LẤY DANH SÁCH DANH MỤC ---
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await ApiService().get(ApiConstants.categoriesEndpoint);
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] ?? [];
      }
      return response.data ?? [];
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
      return [];
    }
  }

  // --- 2. TẠO GIAO DỊCH MỚI (Đã đồng bộ với Schema và Backend Validation) ---
  // Trả về Map để UI có thể hiển thị thông báo lỗi cụ thể từ Server
  Future<Map<String, dynamic>> createTransactionResponse({
    required String title,
    required double amount,
    required String type, // 'INCOME', 'EXPENSE'
    required String categoryId,
    required String walletId,
    required String category,
    required String date,
    String? imageUrl,
  }) async {
    try {
      final response = await ApiService().post(
        ApiConstants.transactionsEndpoint,
        data: {
          "note": title, // Map 'title' từ UI vào 'note' của Schema
          "amount": amount,
          "type": type.toUpperCase(),
          "categoryId": categoryId,
          "walletId": walletId,
          "categoryName": category, // Dùng categoryName theo Schema mới
          "imageUrl": imageUrl ?? "",
          "date": date,
        },
      );

      // Nếu thành công (200 hoặc 201)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        // Trả về lỗi từ backend (Ví dụ: "Số dư ví không đủ")
        return {
          'success': false,
          'message': response.data['error'] ?? "Lỗi từ hệ thống",
        };
      }
    } catch (e) {
      print("Lỗi tạo giao dịch: $e");
      return {'success': false, 'message': "Không thể kết nối đến máy chủ"};
    }
  }

  // --- 3. LẤY DANH SÁCH GIAO DỊCH (Hỗ trợ phân trang và lọc theo loại) ---
  Future<Map<String, dynamic>?> getTransactions({
    required int limit,
    String? lastDocId,
    String type = 'ALL',
  }) async {
    try {
      String url =
          '${ApiConstants.transactionsEndpoint}?limit=$limit&type=$type';
      if (lastDocId != null && lastDocId.isNotEmpty)
        url += '&lastDocId=$lastDocId';

      final response = await ApiService().get(url);
      if (response.data is Map) {
        return {
          'data': response.data['data'] ?? [],
          'lastDocId': response.data['lastDocId'],
        };
      }
      return null;
    } catch (e) {
      print("Lỗi lấy danh sách giao dịch: $e");
      return null;
    }
  }

  // --- 4. UPLOAD ẢNH LÊN CLOUDINARY QUA BACKEND ---
  Future<String?> uploadTransactionImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadImageEndpoint}'),
      );

      final token = await ApiService().getToken();
      request.headers['Authorization'] = 'Bearer $token';

      // Field 'image' phải khớp với upload.single('image') ở Backend
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Trả về link imageUrl nhận được từ Cloudinary
        return data['imageUrl'];
      }
      return null;
    } catch (e) {
      print("Lỗi upload ảnh: $e");
      return null;
    }
  }

  // --- 5. XÓA GIAO DỊCH ---
  Future<bool> deleteTransaction(String id) async {
    try {
      final response = await ApiService().delete(
        '${ApiConstants.transactionsEndpoint}/$id',
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi xóa giao dịch: $e");
      return false;
    }
  }

  // --- 6. LẤY THÔNG KÊ (Thu nhập, Chi tiêu, Số dư) ---
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await ApiService().get(ApiConstants.statsEndpoint);
      if (response.data is Map) {
        return response.data;
      }
      return null;
    } catch (e) {
      print("Lỗi lấy stats: $e");
      return null;
    }
  }
}
