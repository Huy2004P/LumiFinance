import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/apple_design.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // --- KHẮC PHỤC LỖI "BỊP": Kiểm tra cả kind và type (không phân biệt hoa thường) ---
    final String rawType = (transaction['kind'] ?? transaction['type'] ?? '')
        .toString()
        .toUpperCase();

    // PHÂN LOẠI 3 TRẠNG THÁI GIAO DỊCH
    final bool isIncome = rawType == 'INCOME';
    final bool isTransfer = rawType == 'TRANSFER';

    Color iconColor;
    IconData iconData;
    String sign;
    String typeLabel;

    if (isIncome) {
      iconColor = Colors.green;
      iconData = Icons.trending_up_rounded;
      sign = '+';
      typeLabel = "Thu nhập";
    } else if (isTransfer) {
      iconColor = Colors.blue;
      iconData = Icons.swap_horiz_rounded;
      sign = ''; // Chuyển khoản không dùng dấu
      typeLabel = "Chuyển khoản nội bộ";
    } else {
      iconColor = Colors.red;
      iconData = Icons.trending_down_rounded;
      sign = '-';
      typeLabel = "Chi tiêu";
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Chi tiết giao dịch",
          style: GoogleFonts.beVietnamPro(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // --- Header: Icon và Số tiền ---
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, size: 44, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              "$sign${currencyFormat.format(transaction['amount']).replaceAll('-', '')}",
              style: GoogleFonts.beVietnamPro(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isTransfer ? AppleColors.nearBlack : iconColor,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transaction['category'] ??
                  transaction['categoryName'] ??
                  "Danh mục khác",
              style: GoogleFonts.beVietnamPro(
                color: Colors.black38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // --- Card Thông tin chi tiết (Style Apple) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppleColors.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    "Ghi chú",
                    transaction['note'] ??
                        transaction['title'] ??
                        "Không có ghi chú", // Check cả 2 field
                    isLast: false,
                  ),
                  _buildDetailRow(
                    "Thời gian",
                    _formatDate(
                      transaction['date'] ?? transaction['createdAt'],
                    ),
                    isLast: false,
                  ),
                  _buildDetailRow(
                    "Từ ví",
                    transaction['walletName'] ?? "Ví mặc định",
                    isLast: false,
                  ),
                  _buildDetailRow(
                    "Loại",
                    typeLabel,
                    valueColor: iconColor,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Ảnh hóa đơn (Cloudinary) ---
            if (transaction['imageUrl'] != null &&
                transaction['imageUrl'].toString().trim().isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    "Chứng từ / Hình ảnh",
                    style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppleColors.nearBlack,
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Image.network(
                    transaction['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Xử lý khi ảnh đang tải
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: AppleColors.lightGray,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF1459B3), // Màu LumiCare
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    // Xử lý khi lỗi link ảnh
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: AppleColors.lightGray,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black26,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Không thể tải hình ảnh",
                            style: TextStyle(color: Colors.black26),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // Widget dòng thông tin bổ trợ
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLast = false,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: valueColor ?? AppleColors.nearBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.black.withOpacity(0.05), height: 1),
      ],
    );
  }

  // Hàm format ngày giờ an toàn
  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) return "Chưa rõ thời gian";
      // Xử lý trường hợp Firestore Timestamp (nếu gửi thẳng từ snapshot)
      if (dateValue is Map && dateValue.containsKey('_seconds')) {
        DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(
          dateValue['_seconds'] * 1000,
        );
        return DateFormat('HH:mm - dd/MM/yyyy').format(parsedDate);
      }
      DateTime parsedDate = DateTime.parse(dateValue.toString()).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateValue.toString();
    }
  }
}
