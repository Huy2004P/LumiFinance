import 'package:flutter/material.dart';
import 'package:personal_finance_tracker/screens/profile_screen.dart';
import 'package:personal_finance_tracker/screens/wallet_screen.dart';
import 'dart:ui'; // Bắt buộc phải có để dùng hiệu ứng ImageFilter (Blur)
import '../theme/apple_design.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ĐƯA DANH SÁCH SCREENS VÀO TRONG BUILD ĐỂ TRUYỀN LỆNH CHUYỂN TAB
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToWallet: () {
          setState(() {
            _selectedIndex = 1; // Chuyển sang tab Wallet (Vị trí số 1)
          });
        },
      ),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // Thuộc tính CỰC KỲ QUAN TRỌNG: Cho phép nội dung (HomeScreen) trượt chìm xuống dưới thanh Nav
      extendBody: true,

      body: IndexedStack(index: _selectedIndex, children: screens),

      // Thanh Navigation kiểu Kính mờ (Glassmorphism)
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Độ mờ chuẩn Apple
          child: Container(
            decoration: BoxDecoration(
              // Màu trắng trong suốt 80%
              color: AppleColors.pureWhite.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withOpacity(0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),

              // Xóa nền mặc định để nhường chỗ cho lớp kính mờ
              backgroundColor: Colors.transparent,
              elevation: 0,

              selectedItemColor: AppleColors.appleBlue,
              unselectedItemColor: Colors.black38,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),

              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.grid_view_rounded),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.person_rounded),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
