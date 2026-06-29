import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:pemograman_mobile_2/dashboard.dart';
import 'package:pemograman_mobile_2/list_barang_kategori.dart';
import 'package:pemograman_mobile_2/list_barang.dart';
import 'package:pemograman_mobile_2/penjualan_screen.dart';
import 'package:pemograman_mobile_2/lainnya_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget build(BuildContext context) {
    Widget activeScreen;
    switch (_currentIndex) {
      case 0:
        activeScreen = DashboardScreen();
        break;
      case 1:
        activeScreen = ListBarangKategoriScreen();
        break;
      case 2:
        activeScreen = PenjualanScreen();
        break;
      case 3:
        activeScreen = ListBarangScreen();
        break;
      case 4:
        activeScreen = const LainnyaScreen();
        break;
      default:
        activeScreen = DashboardScreen();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: activeScreen,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _buildNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Produk',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildNavItem(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Penjualan',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  isCenter: true,
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Stok',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _buildNavItem(
                  icon: Icons.more_horiz_rounded,
                  label: 'Lainnya',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isCenter = false,
  }) {
    final activeColor = AppTheme.gold;
    final inactiveColor = const Color(0xFFADB5BD); // Neutral gray

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated indicator pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 32 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon with animated scale
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}