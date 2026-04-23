import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/apple_design.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  const PdfViewScreen({super.key, required this.path});

  void _handleSaveOrShare(BuildContext context) {
    try {
      Share.shareXFiles([
        XFile(path),
      ], text: 'Báo cáo tài chính từ LumiFinance');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi thao tác file: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(
        title: const Text(
          "Báo cáo chi tiết",
          style: TextStyle(
            color: AppleColors.nearBlack,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppleColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF1459B3),
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_rounded, color: Color(0xFF1459B3)),
            onPressed: () => _handleSaveOrShare(context),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Color(0xFF1459B3)),
            onPressed: () => _handleSaveOrShare(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PDFView(
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: false, // Cuộn theo chiều dọc ("thẳng")
        autoSpacing: false, // Tắt khoảng cách tự động để các trang liền mạch
        pageFling: true,
        backgroundColor: Colors.white,
        fitPolicy:
            FitPolicy.WIDTH, // Ép PDF vừa khít chiều rộng màn hình điện thoại
      ),
    );
  }
}
