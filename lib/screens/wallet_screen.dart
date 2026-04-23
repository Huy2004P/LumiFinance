import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../theme/apple_design.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  List<dynamic> _wallets = [];
  List<dynamic> _walletTransactions = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  int _currentWalletIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  final _viFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  // --- HÀM HIỆN THÔNG BÁO STYLE APPLE ---
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

  Future<void> _fetchWallets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _walletService.getWallets();
    if (mounted) {
      setState(() {
        _wallets = data;
        _isLoading = false;
      });
      if (_wallets.isNotEmpty) {
        _fetchWalletHistory(_wallets[_currentWalletIndex]['id']);
      }
    }
  }

  Future<void> _fetchWalletHistory(String walletId) async {
    setState(() => _isLoadingHistory = true);
    final result = await _transactionService.getTransactions(limit: 20);
    if (mounted) {
      setState(() {
        _walletTransactions = (result?['data'] as List).where((t) {
          return t['walletId'] == walletId || t['toWalletId'] == walletId;
        }).toList();
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Ví của tôi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppleColors.appleBlue,
              size: 28,
            ),
            onPressed: () => _showAddWalletModal(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWallets,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildWalletSlider(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  _buildTransactionHistoryHeader(),
                  _buildHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletSlider() {
    if (_wallets.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Text("Hiện chưa có ví!")),
      );
    }
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _wallets.length,
        onPageChanged: (index) {
          setState(() => _currentWalletIndex = index);
          _fetchWalletHistory(_wallets[index]['id']);
        },
        itemBuilder: (context, index) => _buildWalletCard(_wallets[index]),
      ),
    );
  }

  Widget _buildWalletCard(dynamic wallet) {
    Color cardColor = Color(
      int.parse(
        (wallet['color'] ?? "#0071E3").toString().replaceAll('#', '0xFF'),
      ),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                wallet['name'] ?? "Ví",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => _confirmDelete(wallet['id'], wallet['name']),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            "Số dư",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            _viFormat.format(wallet['balance'] ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc muốn xóa ví '$name'? Hành động này không thể hoàn tác.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _walletService.deleteWallet(id);
              if (success is Map && success['success'] == true ||
                  success == true) {
                _showStatusSnackBar("Đã xóa ví '$name' thành công!");
                _fetchWallets();
              } else {
                _showStatusSnackBar(
                  success is Map ? success['message'] : "Xóa ví thất bại!",
                  isError: true,
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _actionItem(
              Icons.swap_horiz_rounded,
              "Chuyển",
              () => _showTransferModal(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionItem(
              Icons.add_chart_rounded,
              "Nạp tiền",
              () => _showDepositModal(),
            ),
          ),
          const SizedBox(width: 12),
          // NÚT SỬA ĐÃ ĐƯỢC GẮN VỚI HÀM _showEditWalletModal
          Expanded(
            child: _actionItem(Icons.edit_rounded, "Sửa", () {
              if (_wallets.isEmpty) {
                _showStatusSnackBar("Chưa có ví nào để sửa!", isError: true);
                return;
              }
              _showEditWalletModal();
            }),
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppleColors.appleBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODAL CHUYỂN TIỀN NỘI BỘ ---
  void _showTransferModal() {
    if (_wallets.isEmpty) {
      _showStatusSnackBar(
        "Chưa có ví nào để thực hiện chuyển tiền!",
        isError: true,
      );
      return;
    }
    if (_wallets.length < 2) {
      _showStatusSnackBar(
        "Cần ít nhất 2 ví để thực hiện chuyển tiền!",
        isError: true,
      );
      return;
    }

    final amountController = TextEditingController();

    String targetWalletId = _wallets.firstWhere(
      (w) => w['id'] != _wallets[_currentWalletIndex]['id'],
    )['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setMState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chuyển tiền nội bộ",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: targetWalletId,
                decoration: const InputDecoration(
                  labelText: "Đến ví",
                  border: OutlineInputBorder(),
                ),
                items: _wallets
                    .where(
                      (w) => w['id'] != _wallets[_currentWalletIndex]['id'],
                    )
                    .map(
                      (w) => DropdownMenuItem<String>(
                        value: w['id'],
                        child: Text(w['name']),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setMState(() => targetWalletId = val);
                  }
                },
              ),

              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Số tiền",
                  suffixText: "₫",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppleColors.appleBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;

                  final ok = await _walletService.transferMoney({
                    'fromWalletId': _wallets[_currentWalletIndex]['id'],
                    'toWalletId': targetWalletId,
                    'amount': amount,
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    if (ok is Map && ok['success'] == true || ok == true) {
                      _showStatusSnackBar(
                        "Chuyển ${_viFormat.format(amount)} thành công!",
                      );
                      _fetchWallets();
                    } else {
                      _showStatusSnackBar(
                        ok is Map
                            ? ok['message']
                            : "Chuyển tiền thất bại. Hãy kiểm tra số dư ví gửi!",
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text(
                  "Xác nhận",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL NẠP TIỀN NHANH ---
  void _showDepositModal() {
    if (_wallets.isEmpty) {
      _showStatusSnackBar("Chưa có ví nào để nạp tiền!", isError: true);
      return;
    }
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Nạp vào ${_wallets[_currentWalletIndex]['name']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: "Số tiền nạp",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                final res = await _transactionService.createTransactionResponse(
                  title: "Nạp tiền thủ công",
                  amount: amount,
                  type: 'INCOME',
                  categoryId: 'nap_tien',
                  category: 'Nạp tiền',
                  walletId: _wallets[_currentWalletIndex]['id'],
                  date: DateTime.now().toIso8601String(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (res['success'] == true) {
                    _showStatusSnackBar(
                      "Đã nạp ${_viFormat.format(amount)} vào ví!",
                    );
                    _fetchWallets();
                  } else {
                    _showStatusSnackBar(
                      res['message'] ?? "Lỗi nạp tiền",
                      isError: true,
                    );
                  }
                }
              },
              child: const Text(
                "Nạp ngay",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- MODAL THÊM VÍ MỚI ---
  void _showAddWalletModal() {
    final nameC = TextEditingController();
    final balanceC = TextEditingController();

    String selectedColor = '#0071E3';
    final List<String> appleColors = [
      '#0071E3', // Blue
      '#34C759', // Green
      '#FF3B30', // Red
      '#AF52DE', // Purple
      '#FF9500', // Orange
      '#1D1D1F', // Black
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tạo ví mới",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "Tên ví",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: balanceC,
                decoration: const InputDecoration(
                  labelText: "Số dư đầu",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Chọn màu ví",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: appleColors.map((color) {
                  bool isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(
                        int.parse(color.replaceAll('#', '0xFF')),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppleColors.appleBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (nameC.text.isEmpty) {
                    _showStatusSnackBar("Vui lòng nhập tên ví!", isError: true);
                    return;
                  }
                  final balance = double.tryParse(balanceC.text) ?? 0;
                  final ok = await _walletService.createWallet({
                    'name': nameC.text,
                    'balance': balance,
                    'type': 'CASH',
                    'color': selectedColor,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    if (ok is Map && ok['success'] == true || ok == true) {
                      _showStatusSnackBar("Tạo ví mới thành công!");
                      _fetchWallets();
                    } else {
                      _showStatusSnackBar(
                        ok is Map ? ok['message'] : "Không thể tạo ví!",
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text(
                  "Hoàn tất",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL SỬA VÍ (MỚI THÊM) ---
  void _showEditWalletModal() {
    final currentWallet = _wallets[_currentWalletIndex];
    final nameC = TextEditingController(text: currentWallet['name']);

    // Lấy màu hiện tại của ví để gán vào UI
    String selectedColor = currentWallet['color'] ?? '#0071E3';
    if (!selectedColor.startsWith('#')) selectedColor = '#0071E3';

    final List<String> appleColors = [
      '#0071E3', // Blue
      '#34C759', // Green
      '#FF3B30', // Red
      '#AF52DE', // Purple
      '#FF9500', // Orange
      '#1D1D1F', // Black
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sửa thông tin ví",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameC,
                decoration: const InputDecoration(
                  labelText: "Tên ví",
                  border: OutlineInputBorder(),
                ),
              ),
              // LƯU Ý: Không cho sửa số dư ở đây để bảo toàn lịch sử giao dịch
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Chọn màu ví",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: appleColors.map((color) {
                  bool isSelected =
                      selectedColor.toUpperCase() == color.toUpperCase();
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        selectedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(
                        int.parse(color.replaceAll('#', '0xFF')),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppleColors.appleBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (nameC.text.isEmpty) {
                    _showStatusSnackBar("Vui lòng nhập tên ví!", isError: true);
                    return;
                  }

                  // Gọi API cập nhật ví
                  final ok = await _walletService.updateWallet(
                    currentWallet['id'],
                    {
                      'name': nameC.text,
                      'color': selectedColor,
                      'type':
                          currentWallet['type'] ?? 'CASH', // Giữ nguyên loại ví
                    },
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    if (ok == true) {
                      _showStatusSnackBar("Cập nhật ví thành công!");
                      _fetchWallets();
                    } else {
                      _showStatusSnackBar(
                        "Không thể cập nhật ví. Vui lòng thử lại!",
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text(
                  "Lưu thay đổi",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionHistoryHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(25, 20, 20, 10),
      child: Text(
        "Lịch sử giao dịch ví",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_isLoadingHistory)
      return const Center(child: CircularProgressIndicator());
    if (_walletTransactions.isEmpty)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("Chưa có giao dịch nào cho ví này"),
        ),
      );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _walletTransactions.length,
      itemBuilder: (context, index) {
        final item = _walletTransactions[index];
        final isIncome =
            item['type'] == 'INCOME' ||
            item['toWalletId'] == _wallets[_currentWalletIndex]['id'];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isIncome
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['note'] ?? "Giao dịch",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item['categoryName'] ?? "Khác",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'}${_viFormat.format(item['amount'])}",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isIncome ? Colors.green : Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
