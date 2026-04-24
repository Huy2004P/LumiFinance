import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../config/api_constants.dart';
import '../theme/apple_design.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _errorMessage = '';

  // Dữ liệu thống kê theo tháng (12 tháng gần nhất)
  List<_MonthStat> _monthStats = [];
  int _selectedMonthIndex = -1; // -1 = không chọn

  final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Lấy toàn bộ giao dịch (giới hạn 500 để tổng hợp theo tháng)
      final response = await ApiService().get(
        '${ApiConstants.transactionsEndpoint}?limit=500',
      );

      final rawList = response.data is Map
          ? (response.data['data'] as List? ?? [])
          : (response.data as List? ?? []);

      // Nhóm theo tháng
      final Map<String, _MonthStat> map = {};
      for (final item in rawList) {
        final dateStr = item['date']?.toString() ?? '';
        DateTime? dt;
        try {
          dt = DateTime.parse(dateStr);
        } catch (_) {
          continue;
        }
        final key = DateFormat('yyyy-MM').format(dt);
        map.putIfAbsent(key, () => _MonthStat(year: dt!.year, month: dt.month));
        final amount =
            double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final type = item['type']?.toString().toUpperCase() ?? '';
        if (type == 'INCOME') {
          map[key]!.income += amount.abs();
        } else if (type == 'EXPENSE') {
          map[key]!.expense += amount.abs();
        }
      }

      // Sắp xếp theo thời gian, lấy 6 tháng gần nhất
      final sorted = map.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final last6 = sorted.length > 6
          ? sorted.sublist(sorted.length - 6)
          : sorted;

      // Tính tồn đọng tích lũy
      double running = 0;
      final result = last6.map((e) {
        running += e.value.income - e.value.expense;
        e.value.remaining = running;
        return e.value;
      }).toList();

      setState(() {
        _monthStats = result;
        _selectedMonthIndex = result.isNotEmpty ? result.length - 1 : -1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải dữ liệu thống kê';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        title: Text(
          'Thống kê',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: const Color(0xFF1459B3),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppleColors.appleBlue,
            ),
            onPressed: _loadStats,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppleColors.appleBlue,
          unselectedLabelColor: Colors.black38,
          indicatorColor: AppleColors.appleBlue,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Thu / Chi'),
            Tab(text: 'Tồn đọng'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppleColors.appleBlue),
            )
          : _errorMessage.isNotEmpty
          ? _buildError()
          : _monthStats.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildIncomeExpenseTab(), _buildRemainingTab()],
                  ),
                ),
              ],
            ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 1: THU / CHI theo tháng (grouped bar)
  // ──────────────────────────────────────────
  Widget _buildIncomeExpenseTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppleColors.appleBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildSectionHeader('Biểu đồ Thu / Chi theo tháng'),
            const SizedBox(height: 16),
            _buildBarChart(),
            const SizedBox(height: 24),
            _buildMonthDetailCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 2: TỒN ĐỌNG tích lũy (line chart)
  // ──────────────────────────────────────────
  Widget _buildRemainingTab() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppleColors.appleBlue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRemainingCard(),
            const SizedBox(height: 24),
            _buildSectionHeader('Biểu đồ tồn đọng tích lũy'),
            const SizedBox(height: 16),
            _buildLineChart(),
            const SizedBox(height: 24),
            _buildMonthRemainingList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────

  Widget _buildSummaryCards() {
    double totalIncome = _monthStats.fold(0, (s, m) => s + m.income);
    double totalExpense = _monthStats.fold(0, (s, m) => s + m.expense);
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Tổng thu nhập',
            totalIncome,
            Icons.arrow_downward_rounded,
            const Color(0xFF00C48C),
            const Color(0xFFE6FBF5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            'Tổng chi tiêu',
            totalExpense,
            Icons.arrow_upward_rounded,
            const Color(0xFFFF6B6B),
            const Color(0xFFFFF0F0),
          ),
        ),
      ],
    );
  }

  Widget _buildRemainingCard() {
    final last = _monthStats.isNotEmpty ? _monthStats.last.remaining : 0.0;
    final isPositive = last >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF00C48C), const Color(0xFF00A676)]
              : [const Color(0xFFFF6B6B), const Color(0xFFE05050)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (isPositive ? const Color(0xFF00C48C) : const Color(0xFFFF6B6B))
                    .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tồn đọng hiện tại',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _vnd.format(last.abs()),
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? '▲ Đang dư' : '▼ Đang âm',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    double amount,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _vnd.format(amount),
            style: GoogleFonts.beVietnamPro(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBarChart() {
    if (_monthStats.isEmpty) return const SizedBox.shrink();
    final maxVal = _monthStats
        .map((m) => m.income > m.expense ? m.income : m.expense)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.25,
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, BarTouchResponse? resp) {
              if (resp != null && resp.spot != null && event is FlTapUpEvent) {
                setState(() {
                  _selectedMonthIndex = resp.spot!.touchedBarGroupIndex;
                });
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1459B3),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final m = _monthStats[groupIndex];
                return BarTooltipItem(
                  rodIndex == 0
                      ? '+${_vnd.format(m.income)}'
                      : '-${_vnd.format(m.expense)}',
                  GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _monthStats.length) {
                    return const SizedBox.shrink();
                  }
                  final m = _monthStats[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'T${m.month}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: idx == _selectedMonthIndex
                            ? AppleColors.appleBlue
                            : Colors.black45,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.black.withOpacity(0.04), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_monthStats.length, (i) {
            final m = _monthStats[i];
            final isSelected = i == _selectedMonthIndex;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: m.income,
                  color: isSelected
                      ? const Color(0xFF00C48C)
                      : const Color(0xFF00C48C).withOpacity(0.5),
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
                BarChartRodData(
                  toY: m.expense,
                  color: isSelected
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFFFF6B6B).withOpacity(0.5),
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
              groupVertically: false,
              barsSpace: 4,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    if (_monthStats.isEmpty) return const SizedBox.shrink();
    final spots = _monthStats.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.remaining);
    }).toList();

    final minY = _monthStats
        .map((m) => m.remaining)
        .reduce((a, b) => a < b ? a : b);
    final maxY = _monthStats
        .map((m) => m.remaining)
        .reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() * 0.2 + 1000;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppleColors.appleBlue,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppleColors.appleBlue.withOpacity(0.08),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: AppleColors.appleBlue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1459B3),
              getTooltipItems: (spots) => spots.map((s) {
                final m = _monthStats[s.spotIndex];
                return LineTooltipItem(
                  'T${m.month}/${m.year}\n${_vnd.format(m.remaining)}',
                  GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _monthStats.length) {
                    return const SizedBox.shrink();
                  }
                  final m = _monthStats[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'T${m.month}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.black.withOpacity(0.04), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildMonthDetailCard() {
    if (_selectedMonthIndex < 0 || _selectedMonthIndex >= _monthStats.length) {
      return const SizedBox.shrink();
    }
    final m = _monthStats[_selectedMonthIndex];
    final net = m.income - m.expense;
    final isPositive = net >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết Tháng ${m.month}/${m.year}',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Thu nhập', m.income, const Color(0xFF00C48C)),
          const Divider(height: 20),
          _buildDetailRow('Chi tiêu', m.expense, const Color(0xFFFF6B6B)),
          const Divider(height: 20),
          _buildDetailRow(
            isPositive ? 'Tiết kiệm được' : 'Bội chi',
            net.abs(),
            isPositive ? AppleColors.appleBlue : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.black54),
        ),
        Text(
          _vnd.format(amount),
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthRemainingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Chi tiết theo tháng'),
        const SizedBox(height: 12),
        ...List.generate(_monthStats.length, (i) {
          final m = _monthStats[_monthStats.length - 1 - i];
          final isPositive = m.remaining >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFFE6FBF5)
                        : const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isPositive
                        ? const Color(0xFF00C48C)
                        : const Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tháng ${m.month}/${m.year}',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Thu: ${_vnd.format(m.income)}  |  Chi: ${_vnd.format(m.expense)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tồn đọng',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                    Text(
                      _vnd.format(m.remaining),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isPositive
                            ? const Color(0xFF00C48C)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_errorMessage),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadStats, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, color: Colors.black26, size: 60),
          SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu giao dịch',
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Model
// ──────────────────────────────────────────
class _MonthStat {
  final int year;
  final int month;
  double income;
  double expense;
  double remaining;

  _MonthStat({
    required this.year,
    required this.month,
    // ignore: unused_element_parameter
    this.income = 0,
    // ignore: unused_element_parameter
    this.expense = 0,
    // ignore: unused_element_parameter
    this.remaining = 0,
  });
}
