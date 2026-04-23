import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:html_to_pdf_plus/html_to_pdf_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:personal_finance_tracker/screens/add_transaction_screen.dart';
// import 'package:personal_finance_tracker/screens/category_screen.dart';
import 'package:personal_finance_tracker/screens/history_screen.dart';
import 'package:personal_finance_tracker/screens/notification_screen.dart';
import 'package:personal_finance_tracker/screens/pdf_view_screen.dart';
import 'package:personal_finance_tracker/screens/transaction_detail_screen.dart';
import 'package:personal_finance_tracker/services/auth_service.dart';
import 'package:personal_finance_tracker/services/wallet_service.dart';
import '../theme/apple_design.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';
import '../services/transaction_service.dart';
import 'budget_screen.dart';
import 'category_screen.dart';

class NotificationBell extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  const NotificationBell({super.key, required this.count, required this.onTap});
  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _updateFCMToken();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.count > 0) _controller.repeat(reverse: true);
  }

  Future<void> _updateFCMToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      String? token = await messaging.getToken();
      if (token != null) {
        await ApiService().post(
          ApiConstants.fcmTokenEndpoint,
          data: {"fcmToken": token},
        );
      }
    } catch (e) {
      print("Lỗi cập nhật Token: $e");
    }
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (widget.count == 0) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double rotation = widget.count > 0
                  ? (math.sin(_controller.value * math.pi * 2) * 0.4)
                  : 0;
              return Transform.rotate(
                angle: rotation,
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 28,
                  color: widget.count > 0
                      ? Colors.redAccent
                      : AppleColors.nearBlack,
                ),
              );
            },
          ),
          if (widget.count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToWallet;

  const HomeScreen({super.key, required this.onNavigateToWallet});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isBalanceVisible = true;
  String _errorMessage = '';
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<dynamic> _recentTransactions = [];
  List<dynamic> _wallets = [];

  String? _lastDocId;
  bool _isFetchingMore = false;
  bool _hasNextPage = true;
  final int _pageSize = 10;
  int _displayCount = 5;

  final NumberFormat _viCurrencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  Future<void> _fetchHomeData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _lastDocId = null;
      _hasNextPage = true;
      _displayCount = 5;
    });
    try {
      final List<Response<dynamic>> results = await Future.wait([
        ApiService().get(ApiConstants.statsEndpoint),
        ApiService().get(
          '${ApiConstants.transactionsEndpoint}?limit=$_pageSize',
        ),
        WalletService().getWalletsRaw(),
      ]);

      if (mounted) {
        setState(() {
          final statsData = results[0].data as Map<String, dynamic>;
          final transResponse = results[1].data;
          _wallets = results[2].data as List<dynamic>;

          // Lấy chính xác Tổng Thu Nhập, Chi Tiêu, Số dư từ API đã nâng cấp
          _totalBalance =
              double.tryParse(statsData['totalBalance']?.toString() ?? '0') ??
              0.0;
          _totalIncome =
              (double.tryParse(statsData['totalIncome']?.toString() ?? '0') ??
                      0.0)
                  .abs();
          _totalExpense =
              (double.tryParse(statsData['totalExpense']?.toString() ?? '0') ??
                      0.0)
                  .abs();

          // DỰ PHÒNG: Đảm bảo UI luôn hiển thị số dư khớp 100% với tổng các ví
          double fallbackTotalBalance = _wallets.fold(
            0.0,
            (sum, w) => sum + (double.tryParse(w['balance'].toString()) ?? 0.0),
          );
          if (_totalBalance == 0 && fallbackTotalBalance != 0) {
            _totalBalance = fallbackTotalBalance;
          }

          if (transResponse is Map && transResponse.containsKey('data')) {
            _recentTransactions = List.from(transResponse['data']);
            _lastDocId = transResponse['lastDocId'];
          } else {
            _recentTransactions = List.from(transResponse as List);
            _lastDocId = _recentTransactions.isNotEmpty
                ? _recentTransactions.last['id']
                : null;
          }
          _hasNextPage = _recentTransactions.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi kết nối Server!';
        });
      }
    }
  }

  Future<void> _handleLoadMore() async {
    if (_displayCount < _recentTransactions.length) {
      setState(() => _displayCount += 5);
      return;
    }
    if (_hasNextPage && !_isFetchingMore) {
      setState(() => _isFetchingMore = true);
      try {
        final response = await ApiService().get(
          '${ApiConstants.transactionsEndpoint}?limit=$_pageSize&lastDocId=$_lastDocId',
        );
        final resData = response.data;
        List<dynamic> newData = (resData is Map)
            ? resData['data']
            : (resData as List);
        if (mounted) {
          setState(() {
            _recentTransactions.addAll(newData);
            _lastDocId = (resData is Map)
                ? resData['lastDocId']
                : (newData.isNotEmpty ? newData.last['id'] : null);
            _displayCount += 5;
            _hasNextPage = newData.length >= _pageSize;
            _isFetchingMore = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isFetchingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        color: AppleColors.appleBlue,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: SpinKitThreeBounce(
                    color: AppleColors.appleBlue,
                    size: 30,
                  ),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              _buildSliverError()
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                  child: _buildBalanceCard(),
                ),
              ),
              SliverToBoxAdapter(child: _buildWalletMiniCarousel()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      _buildSectionTitle("Thao tác nhanh"),
                      const SizedBox(height: 15),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 30),
                      _buildRecentActivityHeader(),
                    ],
                  ),
                ),
              ),
              _buildSliverTransactionList(),
              _buildPaginationControls(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildWalletMiniCarousel() {
    if (_wallets.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12),
        ),
        child: InkWell(
          onTap: () {
            widget.onNavigateToWallet();
          },
          borderRadius: BorderRadius.circular(22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_card_rounded,
                color: AppleColors.appleBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                "Chưa có ví, nhấn để thêm ngay",
                style: GoogleFonts.beVietnamPro(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final w = _wallets[index];
          Color c = Color(
            int.parse(
              (w['color'] ?? '#0071E3').toString().replaceFirst('#', '0xFF'),
            ),
          );
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: c.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  w['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _viCurrencyFormat.format(w['balance'] ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      title: Text(
        "LumiFinance",
        style: GoogleFonts.beVietnamPro(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1459B3),
          fontSize: 26,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppleColors.appleBlue,
            size: 26,
          ),
          onPressed: () {
            _fetchHomeData();
          },
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('uid', isEqualTo: currentUserId)
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Padding(
              padding: const EdgeInsets.only(right: 15),
              child: NotificationBell(
                count: unreadCount,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                  _fetchHomeData();
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1459B3), Color(0xFF1C7AD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1459B3).withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
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
                "Tổng số dư",
                style: AppleTextStyles.body.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _isBalanceVisible = !_isBalanceVisible),
                child: Icon(
                  _isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible
                ? _viCurrencyFormat.format(_totalBalance)
                : "••••••••",
            style: AppleTextStyles.displayHero.copyWith(
              color: Colors.white,
              fontSize: 34,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMiniInfo(
                    "Thu nhập",
                    _totalIncome,
                    Icons.arrow_downward_rounded,
                    Colors.greenAccent,
                  ),
                ),
                Container(width: 1, height: 25, color: Colors.white24),
                Expanded(
                  child: _buildMiniInfo(
                    "Chi tiêu",
                    _totalExpense,
                    Icons.arrow_upward_rounded,
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _viCurrencyFormat.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.category_rounded, "Danh mục", () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryScreen()),
          );
          _fetchHomeData();
        }),
        _buildActionItem(Icons.pie_chart_rounded, "Ngân sách", () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetScreen()),
          );
          _fetchHomeData();
        }),
        _buildActionItem(Icons.history_rounded, "Lịch sử", () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
          _fetchHomeData();
        }),
        _buildActionItem(
          Icons.picture_as_pdf_rounded,
          "Xuất PDF",
          () => _handleExportPDF(),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: AppleColors.appleBlue, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTransactionList() {
    final int countToShow = _recentTransactions.length < _displayCount
        ? _recentTransactions.length
        : _displayCount;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _recentTransactions[index];

          // XỬ LÝ GIAO DIỆN PHÂN BIỆT 3 LOẠI GIAO DỊCH
          final String transType = item['type'].toString().toUpperCase();
          final bool isIncome = transType == 'INCOME';
          final bool isTransfer = transType == 'TRANSFER';

          Color iconColor;
          IconData iconData;
          String sign;

          if (isIncome) {
            iconColor = Colors.green;
            iconData = Icons.trending_up_rounded;
            sign = '+';
          } else if (isTransfer) {
            iconColor = Colors.blue;
            iconData = Icons.swap_horiz_rounded; // Mũi tên 2 chiều ngang
            sign = ''; // Chuyển khoản nội bộ nên không cần dấu +/-
          } else {
            iconColor = Colors.red;
            iconData = Icons.trending_down_rounded;
            sign = '-';
          }

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transaction: item),
              ),
            ),
            onLongPress: () => _showDeleteConfirm(item['id'].toString()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? item['note'] ?? 'Giao dịch',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${item['category'] ?? 'Khác'} • ${item['walletName'] ?? 'Ví'}",
                          style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "$sign${_viCurrencyFormat.format(double.tryParse(item['amount'].toString()) ?? 0).replaceAll('-', '')}",
                    style: TextStyle(
                      color: isTransfer ? AppleColors.nearBlack : iconColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: countToShow),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasNextPage || _displayCount < _recentTransactions.length)
              _buildListButton(
                label: "Xem thêm",
                icon: Icons.expand_more_rounded,
                onPressed: _handleLoadMore,
                isLoading: _isFetchingMore,
              ),
            const SizedBox(width: 15),
            if (_displayCount > 5)
              _buildListButton(
                label: "Thu gọn",
                icon: Icons.expand_less_rounded,
                onPressed: () => setState(() => _displayCount = 5),
                color: Colors.black45,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (res == true) _fetchHomeData();
        },
        backgroundColor: AppleColors.appleBlue,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildListButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color color = AppleColors.appleBlue,
  }) {
    return TextButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppleColors.appleBlue,
              ),
            )
          : Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: color.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSliverError() => SliverFillRemaining(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          Text(_errorMessage),
          TextButton(onPressed: _fetchHomeData, child: const Text("Thử lại")),
        ],
      ),
    ),
  );
  Widget _buildSectionTitle(String t) => Text(
    t,
    style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w800),
  );
  Widget _buildRecentActivityHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildSectionTitle("Hoạt động gần đây"),
      TextButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          );
          _fetchHomeData();
        },
        child: const Text(
          "Tất cả",
          style: TextStyle(
            color: AppleColors.appleBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  void _showDeleteConfirm(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xoá giao dịch?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDelete(id);
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    if (await TransactionService().deleteTransaction(id)) {
      _fetchHomeData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã cập nhật lại số dư")));
      }
    }
  }

  Future<void> _handleExportPDF() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: SpinKitThreeBounce(color: Color(0xFF1459B3), size: 30),
      ),
    );

    try {
      final String? token = await AuthService().getToken();

      final response = await Dio().get(
        "${ApiConstants.baseUrl}${ApiConstants.exportPdfEndpoint}",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      String htmlContent = response.data.toString();

      final Directory tempDir = await getTemporaryDirectory();

      final File pdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: htmlContent,
        configuration: PdfConfiguration(
          targetDirectory: tempDir.path,
          targetName: "LumiFinance_Report",
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Portrait,
        ),
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewScreen(path: pdfFile.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("Lỗi xuất PDF: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: ${e.toString().split(':').last.trim()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
