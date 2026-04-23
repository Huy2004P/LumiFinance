import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_finance_tracker/screens/edit_profile_screen.dart';
import 'package:personal_finance_tracker/screens/login_screen.dart';
import '../theme/apple_design.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  bool _isDeleting = false;

  // --- HÀM XỬ LÝ REFRESH ---
  Future<void> _handleRefresh() async {
    setState(() {
      // Gọi setState để FutureBuilder thực hiện gọi lại getUserProfile()
    });
    // Đợi một khoảng ngắn để hiệu ứng quay của RefreshIndicator mượt mà hơn
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // --- HÀM ĐĂNG XUẤT ---
  void _handleLogout() async {
    final ok = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất?"),
        content: const Text(
          "Huy có chắc muốn đăng xuất khỏi LumiFinance không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // // --- HÀM XÓA TÀI KHOẢN (GỌI BACKEND DỌN DẸP DATA) ---
  // void _handleDeleteAccount() async {
  //   final confirm = await showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("XÓA TÀI KHOẢN VĨNH VIỄN?"),
  //       content: const Text(
  //         "Toàn bộ ví, giao dịch và dữ liệu của bạn sẽ bị xóa sạch. Hành động này không thể hoàn tác!",
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text("Quay lại"),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text(
  //             "Xóa sạch dữ liệu",
  //             style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirm == true) {
  //     setState(() => _isDeleting = true);
  //     final result = await _userService.deleteAccount();

  //     if (result['success'] == true && mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(result['message']),
  //           backgroundColor: Colors.black,
  //         ),
  //       );
  //       Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (context) => const LoginScreen()),
  //         (route) => false,
  //       );
  //     } else if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(result['message']),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       setState(() => _isDeleting = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppleColors.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Cá nhân",
          style: GoogleFonts.beVietnamPro(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        // THÊM NÚT REFRESH TRÊN THANH APPBAR
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppleColors.appleBlue,
            ),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : RefreshIndicator(
              onRefresh: _handleRefresh, // KÉO XUỐNG ĐỂ LÀM MỚI
              color: AppleColors.appleBlue,
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _userService.getUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data;
                  final userAuth = FirebaseAuth.instance.currentUser;

                  final String? avatarUrl = data?['avatarUrl'];

                  final String name =
                      data?['displayName'] ??
                      userAuth?.displayName ??
                      "Văn Bá Phát Huy";

                  final String email =
                      data?['e-mail'] ??
                      data?['email'] ??
                      userAuth?.email ??
                      "email@example.com";

                  final String bio = data?['organic'] ?? "Hello";
                  final String org = data?['organization'] ?? "Unknown";
                  final String phone = data?['phoneNumber'] ?? "Unknown";

                  return SingleChildScrollView(
                    // BẮT BUỘC có physics này để RefreshIndicator hoạt động khi nội dung ngắn
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildHeader(name, email, bio, avatarUrl),
                        const SizedBox(height: 30),
                        _buildMenuSection("Thông tin hồ sơ", [
                          _menuItem(
                            Icons.business_center_outlined,
                            "Tổ chức: $org",
                            null,
                          ),
                          _menuItem(
                            Icons.phone_iphone_rounded,
                            "SĐT: $phone",
                            null,
                          ),
                          _menuItem(
                            Icons.cake_outlined,
                            "Ngày sinh: ${data?['birthday'] ?? '19/08/2004'}",
                            null,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildMenuSection("Dữ liệu & Bảo mật", [
                          _menuItem(
                            Icons.person_outline_rounded,
                            "Chỉnh sửa hồ sơ",
                            () async {
                              // Lấy dữ liệu hiện tại từ snapshot.data của FutureBuilder
                              final currentData = snapshot.data;
                              if (currentData != null) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userData: currentData,
                                    ),
                                  ),
                                );
                                // Nếu lưu thành công (result == true), refresh lại trang
                                if (result == true) _handleRefresh();
                              }
                            },
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildMenuSection("Hệ thống", [
                          _menuItem(
                            Icons.logout_rounded,
                            "Đăng xuất",
                            _handleLogout,
                            textColor: Colors.red,
                          ),
                        ]),
                        const SizedBox(height: 40),
                        Text(
                          "LumiFinance v1.0.6",
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.black26,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader(
    String name,
    String email,
    String bio,
    String? avatarUrl,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppleColors.appleBlue,
          // Nếu avatarUrl không null và không rỗng thì nạp ảnh từ mạng
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? NetworkImage(avatarUrl)
              : null,
          // Nếu không có ảnh thì hiện chữ cái đầu của tên Huy
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "H",
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 15),
        Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          bio,
          style: const TextStyle(
            color: AppleColors.appleBlue,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(email, style: const TextStyle(color: Colors.black45)),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black38,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: textColor ?? AppleColors.appleBlue),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
          fontSize: 14,
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.black12,
            )
          : null,
    );
  }
}
