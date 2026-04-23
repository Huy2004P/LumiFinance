import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/apple_design.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  String _selectedType = 'expense'; // Mặc định là chi tiêu khi thêm mới

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // --- 1. API: LẤY DANH SÁCH DANH MỤC ---
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get(ApiConstants.categoriesEndpoint);
      if (mounted) {
        setState(() {
          _categories = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Không thể tải danh sách danh mục lúc này");
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 2. API: TẠO DANH MỤC MỚI ---
  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await ApiService().post(
        ApiConstants.categoriesEndpoint,
        data: {"name": name, "type": _selectedType},
      );
      _nameController.clear();
      if (mounted) Navigator.pop(context); // Đóng Dialog
      _fetchCategories(); // Tải lại danh sách
      _showSnackBar("Đã thêm danh mục: $name");
    } catch (e) {
      _showSnackBar("Lỗi hệ thống khi thêm danh mục");
    }
  }

  // --- 3. API: XÓA DANH MỤC ---
  Future<void> _deleteCategory(String id) async {
    try {
      await ApiService().delete("${ApiConstants.categoriesEndpoint}/$id");
      _fetchCategories();
      _showSnackBar("Đã xóa danh mục thành công");
    } catch (e) {
      _showSnackBar(
        "Bạn không có quyền thực hiện thao tác xóa trên danh mục này",
      );
    }
  }

  // --- 4. UI: GIAO DIỆN KHI DANH SÁCH TRỐNG ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppleColors.appleBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 80,
                color: AppleColors.appleBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Chưa có danh mục nào",
              style: GoogleFonts.beVietnamPro(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppleColors.nearBlack,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Hãy tạo các danh mục như Ăn uống, Di chuyển hoặc Lương để bắt đầu phân loại các khoản thu chi của bạn.",
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text("Tạo danh mục ngay"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppleColors.appleBlue,
                side: const BorderSide(color: AppleColors.appleBlue),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. UI: HIỂN THỊ DIALOG THÊM MỚI ---
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Thêm danh mục mới",
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Tên danh mục (VD: Mua sắm)",
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildTypeOption(setDialogState, "Chi tiêu", "expense"),
                  const SizedBox(width: 12),
                  _buildTypeOption(setDialogState, "Thu nhập", "income"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppleColors.appleBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Lưu lại",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(Function setDialogState, String label, String type) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setDialogState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppleColors.appleBlue
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(
        title: Text(
          "Quản lý danh mục",
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppleColors.nearBlack,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppleColors.appleBlue),
            )
          : _categories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isIncome = cat['type'] == 'income';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: isIncome
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        child: Icon(
                          isIncome
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isIncome ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['name'],
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isIncome
                                  ? "Loại hình: Thu nhập"
                                  : "Loại hình: Chi tiêu",
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (cat['uid'] != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () =>
                              _confirmDelete(cat['id'], cat['name']),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _categories.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppleColors.appleBlue,
              elevation: 4,
              label: const Text(
                "Thêm mới",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
            ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa danh mục"),
        content: Text(
          "Dữ liệu của danh mục '$name' sẽ không còn xuất hiện trong các phân loại mới. Bạn có chắc chắn?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quay lại", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(id);
            },
            child: const Text(
              "Xác nhận xóa",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
