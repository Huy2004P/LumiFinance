import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/apple_design.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Biến giữ "tương lai" của dữ liệu để FutureBuilder hiển thị
  Future<List<dynamic>>? _budgetsFuture;

  // Huy nhớ thay UID động từ AuthService sau này nhé
  final String currentUserId = "5sRQZ3YiOTRTi6yCJ2mfBJCSlGB3";

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load dữ liệu ngay khi vào màn hình
    _budgetsFuture = BudgetService().getBudgets();
  }

  // Hàm reload dữ liệu
  Future<void> _refreshData() async {
    setState(() {
      _budgetsFuture = BudgetService().getBudgets();
    });
  }

  // Hàm xác nhận xóa ngân sách
  void _confirmDelete(BuildContext context, String budgetId) {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Xóa ngân sách?"),
        content: const Text(
          "Dữ liệu hạn mức chi tiêu cho danh mục này sẽ bị gỡ bỏ.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Hủy", style: TextStyle(color: Colors.black38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng Dialog

              final success = await BudgetService().deleteBudget(budgetId);

              if (success && mounted) {
                navigator
                    .pop(); // Đóng BottomSheet an toàn nhờ biến navigator đã lưu
                _refreshData();
              }
            },
            child: const Text(
              "Xóa",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      body: RefreshIndicator(
        onRefresh: _refreshData, // Kéo xuống để gọi hàm reload
        color: const Color(0xFF1459B3),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildAppBar(),

            // Sử dụng duy nhất FutureBuilder để tránh xung đột dữ liệu
            FutureBuilder<List<dynamic>>(
              future: _budgetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: SpinKitThreeBounce(
                        color: Color(0xFF1459B3),
                        size: 30,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final budgets = snapshot.data!;
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBudgetCard(budgets[index]),
                      childCount: budgets.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetSheet(),
        backgroundColor: const Color(0xFF1459B3),
        label: const Text(
          "Thiết lập mới",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppleColors.lightGray,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppleColors.nearBlack),
          onPressed: _refreshData, // Nút bấm reload thủ công
        ),
        const SizedBox(width: 10),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Ngân sách",
          style: AppleTextStyles.displayHero.copyWith(fontSize: 28),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
    );
  }

  Widget _buildBudgetCard(dynamic budget) {
    double percentUsed = (budget['percentUsed'] ?? 0.0).toDouble();
    double progressValue = (percentUsed / 100).clamp(0.0, 1.0);
    bool isOverLimit = percentUsed >= 100;

    return GestureDetector(
      onTap: () => _showAddBudgetSheet(existingBudget: budget),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppleColors.pureWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget['categoryName'] ?? 'Danh mục',
                  style: AppleTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  isOverLimit
                      ? "Vượt ${_currencyFormat.format((budget['remainingAmount'] ?? 0).abs())}"
                      : "Còn ${_currencyFormat.format(budget['remainingAmount'] ?? 0)}",
                  style: TextStyle(
                    color: isOverLimit
                        ? Colors.redAccent
                        : const Color(0xFF1459B3),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 10,
                backgroundColor: Colors.black.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverLimit ? Colors.redAccent : const Color(0xFF1C7AD6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Đã dùng ${percentUsed.toStringAsFixed(1)}%",
                  style: AppleTextStyles.body.copyWith(
                    fontSize: 13,
                    color: isOverLimit ? Colors.redAccent : Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Hạn mức: ${_currencyFormat.format(budget['limitAmount'] ?? 0)}",
                  style: AppleTextStyles.body.copyWith(
                    fontSize: 13,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 80,
              color: Colors.black.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              "Chưa đặt mục tiêu chi tiêu nào!",
              style: AppleTextStyles.body.copyWith(color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetSheet({dynamic existingBudget}) async {
    final categories = await CategoryService().getCategories();
    final expenseCategories = categories
        .where((c) => c['type'] == 'expense')
        .toList();

    String? selectedCategoryId = existingBudget?['categoryId'];
    String? selectedCategoryName = existingBudget?['categoryName'];
    final TextEditingController amountController = TextEditingController(
      text: existingBudget != null
          ? existingBudget['limitAmount'].toString()
          : "",
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        decoration: const BoxDecoration(
          color: AppleColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              existingBudget == null
                  ? "Thiết lập ngân sách"
                  : "Cập nhật ngân sách",
              style: AppleTextStyles.displayHero.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 25),
            if (existingBudget == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppleColors.lightGray,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: "Chọn danh mục",
                    ),
                    items: expenseCategories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'].toString(),
                            child: Text(c['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      selectedCategoryId = val;
                      selectedCategoryName = expenseCategories.firstWhere(
                        (c) => c['id'] == val,
                      )['name'];
                    },
                  ),
                ),
              )
            else
              Text(
                "Đang chỉnh sửa: $selectedCategoryName",
                style: const TextStyle(
                  color: Color(0xFF1459B3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppleColors.lightGray,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: "Hạn mức mới (₫)",
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                if (existingBudget != null)
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () =>
                            _confirmDelete(context, existingBudget['id']),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                if (existingBudget != null) const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1459B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedCategoryId != null &&
                            amountController.text.isNotEmpty) {
                          // BẮT BUỘC: Lưu lại navigator trước khi gọi async
                          final navigator = Navigator.of(context);

                          final success = await BudgetService().createBudget({
                            "id": existingBudget?['id'],
                            "categoryId": selectedCategoryId,
                            "categoryName": selectedCategoryName,
                            "limitAmount":
                                double.tryParse(amountController.text) ?? 0,
                            "period": "monthly",
                          });

                          if (success && mounted) {
                            navigator.pop(); // Đóng BottomSheet an toàn
                            _refreshData(); // Load lại dữ liệu mới nhất
                          }
                        }
                      },
                      child: Text(
                        existingBudget == null
                            ? "Lưu thiết lập"
                            : "Cập nhật ngay",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
