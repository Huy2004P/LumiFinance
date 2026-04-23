import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/apple_design.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedCategoryId;
  String? _selectedWalletId;

  List<dynamic> _categories = [];
  List<dynamic> _wallets = [];

  bool _isSubmitting = false;
  bool _isLoadingData = true;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        TransactionService().getCategories(),
        WalletService().getWallets(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0];
          _wallets = results[1];
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['id'];
          }
          if (_wallets.isNotEmpty) {
            _selectedWalletId = _wallets[0]['id'];
          }
          _isLoadingData = false;
        });

        // KIỂM TRA NẾU KHÔNG CÓ VÍ NÀO THÌ BẬT THÔNG BÁO CHẶN LẠI NGAY LẬP TỨC
        if (_wallets.isEmpty) {
          _showNoWalletDialog();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // HÀM HIỂN THỊ HỘP THOẠI BẮT BUỘC TẠO VÍ
  void _showNoWalletDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              "Chưa có ví",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          "Bạn cần tạo ít nhất một ví thanh toán để có thể thêm giao dịch. Vui lòng quay lại và tạo ví trước.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(
                context,
              ); // Đóng luôn màn hình thêm giao dịch để về trang chủ
            },
            child: const Text(
              "Quay lại trang chủ",
              style: TextStyle(
                color: AppleColors.appleBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 60,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  void _submitData() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0;
    final title = _titleController.text.trim();

    if (amount <= 0 ||
        title.isEmpty ||
        _selectedCategoryId == null ||
        _selectedWalletId == null) {
      _showStatusSnackBar(
        "Vui lòng nhập đủ thông tin và chọn ví!",
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await TransactionService().uploadTransactionImage(_imageFile!);
    }

    final selectedCat = _categories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {'name': 'Khác'},
    );

    final response = await TransactionService().createTransactionResponse(
      title: title,
      amount: amount,
      type: _selectedType.toUpperCase(),
      categoryId: _selectedCategoryId!,
      walletId: _selectedWalletId!,
      category: selectedCat['name'],
      imageUrl: imageUrl,
      date: DateTime.now().toIso8601String(),
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (response['success'] == true) {
      if (mounted) {
        _showStatusSnackBar("Thêm giao dịch thành công!", isError: false);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } else {
      _showStatusSnackBar(
        response['message'] ?? "Lỗi khi thêm giao dịch!",
        isError: true,
      );
    }
  }

  void _showStatusSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.shade400
            : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Thêm giao dịch",
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSelector(),
                  const SizedBox(height: 30),
                  _buildLabel("Số tiền"),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1459B3),
                    ),
                    decoration: const InputDecoration(
                      hintText: "0",
                      suffixText: "₫",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildLabel("Chọn ví thanh toán"),
                  const SizedBox(height: 12),
                  _buildWalletSelector(),
                  const SizedBox(height: 20),
                  _buildLabel("Ghi chú"),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Nhập nội dung...",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 25),
                  _buildLabel("Danh mục"),
                  const SizedBox(height: 15),
                  _buildCategoryList(),
                  const SizedBox(height: 30),
                  _buildLabel("Hóa đơn đính kèm"),
                  const SizedBox(height: 15),
                  _buildImagePicker(),
                  const SizedBox(height: 50),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletSelector() {
    if (_wallets.isEmpty) {
      return const Text(
        "Không có ví nào khả dụng",
        style: TextStyle(color: Colors.red),
      );
    }
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          bool isSelected = _selectedWalletId == wallet['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedWalletId = wallet['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1459B3)
                    : AppleColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                wallet['name'],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppleColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTypeButton("Chi tiêu", 'expense'),
          _buildTypeButton("Thu nhập", 'income'),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String type) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1459B3) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return const Text("Đang tải danh mục...");
    }
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          bool isSelected = _selectedCategoryId == cat['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryId = cat['id']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1459B3).withOpacity(0.1)
                    : AppleColors.lightGray,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1459B3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat['name'] ?? "Khác",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1459B3) : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () => _showImageOptions(),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppleColors.lightGray,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_enhance_outlined,
                    color: Colors.black26,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Nhấn để thêm ảnh hóa đơn",
                    style: TextStyle(color: Colors.black26),
                  ),
                ],
              ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        // NẾU KHÔNG CÓ VÍ, NÚT SẼ BỊ VÔ HIỆU HÓA KHÔNG THỂ BẤM
        onPressed: _isSubmitting || _wallets.isEmpty ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1459B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Lưu giao dịch",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black54,
    ),
  );
}
