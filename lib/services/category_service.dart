import '../services/api_service.dart';
import '../config/api_constants.dart';

class CategoryService {
  // --- 1. LẤY DANH SÁCH DANH MỤC ---
  // Trả về danh sách gồm các danh mục mặc định và danh mục do user tạo
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await ApiService().get(ApiConstants.categoriesEndpoint);

      // Xử lý dữ liệu trả về từ Backend (thường bọc trong key 'data')
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] ?? [];
      }

      // Trường hợp Server trả về List trực tiếp
      return response.data is List ? response.data : [];
    } catch (e) {
      print("Lỗi lấy danh sách danh mục: $e");
      return [];
    }
  }

  // --- 2. THÊM DANH MỤC MỚI ---
  // Data bao gồm: name, type ('income' hoặc 'expense')
  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await ApiService().post(
        ApiConstants.categoriesEndpoint,
        data: data,
      );

      // Trả về true nếu tạo thành công (201 Created)
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Lỗi tạo danh mục: $e");
      return false;
    }
  }

  // --- 3. XÓA DANH MỤC ---
  Future<bool> deleteCategory(String id) async {
    try {
      final response = await ApiService().delete(
        '${ApiConstants.categoriesEndpoint}/$id',
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi khi xóa danh mục: $e");
      return false;
    }
  }
}
