import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A sleek, minimalist bottom navigation bar styled to match the Kinsenas
/// Earthy Botanical palette:
/// 1. A solid black (#000000) rectangular base bar across the bottom.
/// 2. A crisp U-shaped (half-capsule) active tab in Dusty Olive (#717744)
///    dipping smoothly from the top edge around the selected icon.
/// 3. Crisp White Smoke (#EFF1ED) outline icons on the black bar for inactive tabs.
/// 4. Solid filled black (#000000) icon centered inside the green U-shaped tab
///    for the active tab.
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
  // Navigation tabs configuration matching Kinsenas layout
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
      sizeOffset: 3.0,
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
    const double barHeight = 56.0;

    return Container(
      color: Colors.black,
      height: barHeight + bottomPadding,
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
                  // LAYER 1: Solid black bar with Dusty Olive U-shaped active tab
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _UShapedCutoutNavPainter(
                        activeX: currentX,
                        tabWidth: tabWidth,
                        barHeight: barHeight,
                      ),
                    ),
                  ),

                  // LAYER 2: Navigation icons tightly centered with compact bottom margin
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
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  scale: isActive ? 1.08 : 1.0,
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    isActive ? item.activeIcon : item.outlineIcon,
                                    size: (isActive ? 28.0 : 26.0) + item.sizeOffset,
                                    color: isActive
                                        ? Colors.black
                                        : AppColors.whiteSmoke,
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

/// Custom painter that draws a solid black (#000000) bottom bar with a crisp
/// U-shaped (half-capsule) active tab in Dusty Olive (#717744) dipping straight
/// down from the top edge.
class _UShapedCutoutNavPainter extends CustomPainter {
  final double activeX;
  final double tabWidth;
  final double barHeight;

  _UShapedCutoutNavPainter({
    required this.activeX,
    required this.tabWidth,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Solid black base bar
    final barPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), barPaint);

    // 2. Dusty Olive (#717744) U-shaped half-capsule active tab
    final activeTabPaint = Paint()
      ..color = AppColors.dustyOlive
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double tabDepth = barHeight * 0.89;
    final double tabRadius = math.min(barHeight * 0.56, tabWidth * 0.44);
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
        oldDelegate.barHeight != barHeight;
  }
}
