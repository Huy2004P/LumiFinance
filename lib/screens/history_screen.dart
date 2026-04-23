import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/apple_design.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasNextPage = true;
  List<dynamic> _transactions = [];
  String? _lastDocId;
  final int _pageSize = 15;
  Timer? _debounce;

  String _selectedType = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions({bool isRefresh = true}) async {
    if (isRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _lastDocId = null;
          _hasNextPage = true;
          _transactions = [];
        });
      }
    }

    try {
      String url = '${ApiConstants.transactionsEndpoint}?limit=$_pageSize';
      if (_lastDocId != null) url += '&lastDocId=$_lastDocId';
      if (_selectedType != 'ALL') url += '&type=$_selectedType';
      if (_searchQuery.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_searchQuery)}';
      }

      final response = await ApiService().get(url);
      final resData = response.data;

      List<dynamic> newData = (resData is Map) ? resData['data'] : resData;
      String? newLastId = (resData is Map) ? resData['lastDocId'] : null;

      if (mounted) {
        setState(() {
          _transactions.addAll(newData);
          _lastDocId = newLastId;
          _hasNextPage = newData.length >= _pageSize;
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.extentAfter < 300 &&
        _hasNextPage &&
        !_isFetchingMore) {
      setState(() => _isFetchingMore = true);
      _fetchTransactions(isRefresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollNotification(notification);
          return true;
        },
        child: RefreshIndicator(
          onRefresh: () => _fetchTransactions(isRefresh: true),
          color: AppleColors.appleBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. App Bar với tiêu đề Display Hero
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: AppleColors.lightGray,
                elevation: 0,
                centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    "Giao dịch",
                    style: AppleTextStyles.displayHero.copyWith(fontSize: 32),
                  ),
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 10),
                ),
              ),

              // 2. Thanh tìm kiếm tách biệt để không bị lỗi UI
              SliverToBoxAdapter(child: _buildSearchField()),

              SliverToBoxAdapter(child: SizedBox(height: 15)),

              // 3. Thanh lọc Chips
              _buildFilterBar(),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: AppleColors.appleBlue,
                      size: 30,
                    ),
                  ),
                )
              else if (_transactions.isEmpty)
                _buildEmptyState()
              else
                _buildTransactionList(),

              if (_isFetchingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: SpinKitThreeBounce(
                      color: AppleColors.appleBlue,
                      size: 20,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          style: AppleTextStyles.body.copyWith(fontSize: 16),
          onChanged: (value) {
            // CHIÊU DEBOUNCE: Đợi 500ms sau khi ngừng gõ mới gọi API
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              setState(() => _searchQuery = value);
              _fetchTransactions(isRefresh: true);
            });
          },
          decoration: InputDecoration(
            hintText: "Tìm theo nội dung, ví dụ: Ăn uống",
            hintStyle: TextStyle(
              color: AppleColors.nearBlack.withOpacity(0.3),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppleColors.nearBlack.withOpacity(0.3),
              size: 22,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SliverToBoxAdapter(
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 20),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildFilterChip("Tất cả", 'ALL'),
            _buildFilterChip("Thu", 'INCOME'),
            _buildFilterChip("Chi", 'EXPENSE'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = type);
        _fetchTransactions(isRefresh: true);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppleColors.appleBlue : AppleColors.pureWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppleColors.nearBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _transactions[index];
          final bool isIncome =
              item['type'].toString().toUpperCase() == 'INCOME';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppleColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['note'] != null && item['note'] != "")
                            ? item['note']
                            : (item['categoryName'] ?? 'Giao dịch'),
                        style: AppleTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['categoryName'] ?? 'Khác',
                        style: TextStyle(
                          color: AppleColors.nearBlack.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${isIncome ? '+' : '-'}${_currencyFormat.format(double.tryParse(item['amount'].toString())?.abs() ?? 0)}",
                  style: TextStyle(
                    color: isIncome ? Colors.green : AppleColors.nearBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          );
        }, childCount: _transactions.length),
      ),
    );
  }

  Widget _buildEmptyState() => SliverFillRemaining(
    child: Center(
      child: Text(
        "Không có giao dịch",
        style: AppleTextStyles.body.copyWith(color: Colors.grey),
      ),
    ),
  );
}
