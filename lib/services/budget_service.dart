import '../services/api_service.dart';
import '../config/api_constants.dart';

class BudgetService {
  // --- 1. LẤY DANH SÁCH NGÂN SÁCH ---
  // Trả về mảng chứa spentAmount, remainingAmount và percentUsed đã tính sẵn từ Server
  Future<List<dynamic>> getBudgets() async {
    try {
      final response = await ApiService().get(ApiConstants.budgetsEndpoint);

      // Kiểm tra cấu trúc trả về { status: 'success', data: [...] }
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'] ?? [];
      }

      // Trường hợp Server trả về mảng trực tiếp
      return response.data is List ? response.data : [];
    } catch (e) {
      print("Lỗi lấy danh sách ngân sách: $e");
      return [];
    }
  }

  // --- 2. THIẾT LẬP HOẶC CẬP NHẬT NGÂN SÁCH ---
  // Data bao gồm: categoryId, categoryName, limitAmount, period
  Future<bool> createBudget(Map<String, dynamic> data) async {
    try {
      final response = await ApiService().post(
        ApiConstants.budgetsEndpoint,
        data: data,
      );

      // Chấp nhận cả 201 (Created) và 200 (Updated) từ budgetController
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Lỗi thiết lập ngân sách: $e");
      return false;
    }
  }

  // --- 3. XÓA THIẾT LẬP NGÂN SÁCH ---
  Future<bool> deleteBudget(String id) async {
    try {
      // Sử dụng Endpoint từ ApiConstants thay vì viết cứng đường dẫn
      final response = await ApiService().delete(
        '${ApiConstants.budgetsEndpoint}/$id',
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi khi xóa ngân sách: $e");
      return false;
    }
  }
}
