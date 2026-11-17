import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A sleek, minimalist bottom navigation bar that renders:
/// 1. A clean, flat dark base background (#11140E) without full-width waves or cut-through lines.
/// 2. An organic olive green teardrop / bell-curve scoop (#717744) that dips down from the top edge
///    into a wide, perfectly round circular bowl surrounding only the active navigation tab.
/// 3. Minimalist pure white outline icons for inactive tabs.
/// 4. Solid filled white icon centered inside the round olive bulb for the active tab.
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
      activeIcon: Icons.savings_rounded,
    ),
    _NavItemData(
      label: 'Utang',
      outlineIcon: Icons.swap_horiz_rounded,
      activeIcon: Icons.swap_horiz_rounded,
    ),
    _NavItemData(
      label: 'Mga Bayarin',
      outlineIcon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 66.0;

    return Container(
      color: AppColors.background,
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
                  // LAYER 1: Dark background + Perfectly Round Olive Teardrop Scoop
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TeardropScoopPainter(
                        activeX: currentX,
                        tabWidth: tabWidth,
                        barHeight: barHeight,
                      ),
                    ),
                  ),

                  // LAYER 2: Navigation Icons centered vertically in the bar
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
                                  duration: const Duration(milliseconds: 200),
                                  scale: isActive ? 1.08 : 1.0,
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    isActive ? item.activeIcon : item.outlineIcon,
                                    size: isActive ? 27.0 : 25.0,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.90),
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

  const _NavItemData({
    required this.label,
    required this.outlineIcon,
    required this.activeIcon,
  });
}

/// Custom painter that draws:
/// 1. Solid flat dark base (#11140E)
/// 2. Clean, wide, perfectly round olive green (#717744) scoop dipping from the top edge
class _TeardropScoopPainter extends CustomPainter {
  final double activeX;
  final double tabWidth;
  final double barHeight;

  _TeardropScoopPainter({
    required this.activeX,
    required this.tabWidth,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark base background
    final darkBasePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkBasePaint);

    // 2. Olive scoop matching user's design (#717744)
    final olivePaint = Paint()
      ..color = AppColors.dustyOlive
      ..style = PaintingStyle.fill;

    // Geometric parameters matching reference design:
    final double iconY = barHeight / 2.0; // 33.0
    const double bulbRadius = 27.5;
    const double neckRadius = 25.0;
    final double neckY = iconY - 9.0; // 24.0
    final double bottomY = (iconY + bulbRadius).clamp(0.0, barHeight - 4.0); // 60.5
    final double topSpread = (tabWidth * 0.52).clamp(36.0, 48.0);
    const double kappa = 0.55228; // Standard quarter-circle Bezier constant

    final path = Path();
    // Start at top-left flare
    path.moveTo(activeX - topSpread, 0);

    // 1. Left flare: from (activeX - topSpread, 0) to (activeX - neckRadius, neckY)
    path.cubicTo(
      activeX - topSpread + (topSpread - neckRadius) * 0.40, 0,
      activeX - neckRadius, neckY * 0.45,
      activeX - neckRadius, neckY,
    );

    // 2. Left neck to bulb equator: from (activeX - neckRadius, neckY) to (activeX - bulbRadius, iconY)
    path.cubicTo(
      activeX - neckRadius, neckY + (iconY - neckY) * 0.45,
      activeX - bulbRadius, iconY - (iconY - neckY) * 0.35,
      activeX - bulbRadius, iconY,
    );

    // 3. Quarter-circle bottom-left: from (activeX - bulbRadius, iconY) to bottom apex (activeX, bottomY)
    path.cubicTo(
      activeX - bulbRadius, iconY + kappa * bulbRadius,
      activeX - kappa * bulbRadius, bottomY,
      activeX, bottomY,
    );

    // 4. Quarter-circle bottom-right: from bottom apex (activeX, bottomY) to (activeX + bulbRadius, iconY)
    path.cubicTo(
      activeX + kappa * bulbRadius, bottomY,
      activeX + bulbRadius, iconY + kappa * bulbRadius,
      activeX + bulbRadius, iconY,
    );

    // 5. Right bulb equator to neck: from (activeX + bulbRadius, iconY) to (activeX + neckRadius, neckY)
    path.cubicTo(
      activeX + bulbRadius, iconY - (iconY - neckY) * 0.35,
      activeX + neckRadius, neckY + (iconY - neckY) * 0.45,
      activeX + neckRadius, neckY,
    );

    // 6. Right flare: from (activeX + neckRadius, neckY) up to top edge (activeX + topSpread, 0)
    path.cubicTo(
      activeX + neckRadius, neckY * 0.45,
      activeX + topSpread - (topSpread - neckRadius) * 0.40, 0,
      activeX + topSpread, 0,
    );

    // Close path along the top edge
    path.close();

    canvas.drawPath(path, olivePaint);
  }

  @override
  bool shouldRepaint(covariant _TeardropScoopPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.tabWidth != tabWidth ||
        oldDelegate.barHeight != barHeight;
  }
}
