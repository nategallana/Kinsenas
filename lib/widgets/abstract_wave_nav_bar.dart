import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A sleek, minimalist bottom navigation bar styled to match the Kinsenas
/// Earthy Botanical palette in both Dark Mode and Light Mode:
/// 1. Base bar: Solid black (#000000) in Dark Mode, crisp white (#FFFFFF)
///    with a subtle botanical border in Light Mode.
/// 2. Active tab: A well-proportioned U-shaped (half-capsule) badge in
///    Dusty Olive dipping from the top edge with generous bottom breathing room.
/// 3. Icons: High-contrast active and inactive icons that adapt automatically
///    to Dark Mode and Light Mode.
class AbstractWaveNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AbstractWaveNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<AbstractWaveNavBar> createState() => _AbstractWaveNavBarState();
}

class _AbstractWaveNavBarState extends State<AbstractWaveNavBar> {
  final List<_NavItemData> _items = const [
    _NavItemData(
      label: 'Home',
      outlineIcon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItemData(
      label: 'Sahod',
      outlineIcon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
    ),
    _NavItemData(
      label: 'Ipon',
      outlineIcon: Icons.savings_outlined,
      activeIcon: Icons.savings,
    ),
    _NavItemData(
      label: 'Utang',
      outlineIcon: Icons.swap_horiz_rounded,
      activeIcon: Icons.swap_horiz_rounded,
      sizeOffset: 2.5,
    ),
    _NavItemData(
      label: 'Mga Bayarin',
      outlineIcon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 64.0;
    final bool isDark = AppColors.isDark;
    final Color barColor = isDark ? Colors.black : AppColors.surface;
    final Color activeTabColor = AppColors.dustyOlive;
    final Color activeIconColor = isDark ? Colors.black : const Color(0xFF1B2117);
    final Color inactiveIconColor = isDark ? AppColors.rawWhiteSmoke : AppColors.textSecondary;

    return Container(
      height: barHeight + bottomPadding,
      decoration: BoxDecoration(
        color: barColor,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / _items.length;
          final targetX = (widget.selectedIndex + 0.5) * tabWidth;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetX),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, currentX, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // LAYER 1: Base bar with balanced U-shaped active tab & bottom cushion
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _UShapedCutoutNavPainter(
                        activeX: currentX,
                        tabWidth: tabWidth,
                        barHeight: barHeight,
                        barColor: barColor,
                        activeTabColor: activeTabColor,
                        borderColor: isDark ? Colors.transparent : AppColors.border,
                      ),
                    ),
                  ),

                  // LAYER 2: Navigation icons optically centered inside the U-tab
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: barHeight,
                    child: Row(
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final isActive = index == widget.selectedIndex;

                        return Expanded(
                          child: Tooltip(
                            message: item.label,
                            waitDuration: const Duration(milliseconds: 600),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onItemSelected(index),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                // Active icon sits higher inside the U-capsule (which occupies the top 72% of the bar)
                                alignment: isActive
                                    ? const Alignment(0.0, -0.34)
                                    : const Alignment(0.0, -0.05),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  scale: isActive ? 1.06 : 1.0,
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    isActive ? item.activeIcon : item.outlineIcon,
                                    size: (isActive ? 25.0 : 24.0) + item.sizeOffset,
                                    color: isActive ? activeIconColor : inactiveIconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData outlineIcon;
  final IconData activeIcon;
  final double sizeOffset;

  const _NavItemData({
    required this.label,
    required this.outlineIcon,
    required this.activeIcon,
    this.sizeOffset = 0.0,
  });
}

class _UShapedCutoutNavPainter extends CustomPainter {
  final double activeX;
  final double tabWidth;
  final double barHeight;
  final Color barColor;
  final Color activeTabColor;
  final Color borderColor;

  _UShapedCutoutNavPainter({
    required this.activeX,
    required this.tabWidth,
    required this.barHeight,
    required this.barColor,
    required this.activeTabColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base bar fill (Black in Dark Mode, White surface in Light Mode)
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), barPaint);

    // Subtle top border line in Light Mode
    if (borderColor != Colors.transparent) {
      final borderPaint = Paint()
        ..color = borderColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), borderPaint);
    }

    // 2. Balanced U-shaped half-capsule active tab with generous bottom margin (~28% of barHeight)
    final activeTabPaint = Paint()
      ..color = activeTabColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double tabDepth = barHeight * 0.72;
    final double tabRadius = math.min(barHeight * 0.37, tabWidth * 0.35);
    final double straightDepth = math.max(0.0, tabDepth - tabRadius);

    final double leftX = (activeX - tabRadius).clamp(0.0, size.width);
    final double rightX = (activeX + tabRadius).clamp(0.0, size.width);

    final path = Path()
      ..moveTo(leftX, 0)
      ..lineTo(leftX, straightDepth)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(activeX, straightDepth),
          radius: tabRadius,
        ),
        math.pi,
        -math.pi,
        false,
      )
      ..lineTo(rightX, 0)
      ..close();

    canvas.drawPath(path, activeTabPaint);
  }

  @override
  bool shouldRepaint(covariant _UShapedCutoutNavPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.tabWidth != tabWidth ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.barColor != barColor ||
        oldDelegate.activeTabColor != activeTabColor;
  }
}
