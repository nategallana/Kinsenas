import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A sleek, minimalist bottom navigation bar that renders:
/// 1. A clean, flat dark base background with zero full-width waves.
/// 2. An organic olive green teardrop / bell-curve scoop that dips down from the top edge
///    and neatly hugs only the currently active navigation item.
/// 3. Minimalist pure white outline icons for inactive tabs.
/// 4. Solid filled white icon perfectly centered inside the olive scoop for the active tab.
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
    const double barHeight = 64.0;

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
                  // LAYER 1: Dark background + Olive Teardrop Scoop Painter
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
/// 1. Solid dark bar base (#11140E)
/// 2. Subtle top border line along the flat edge
/// 3. S-curve olive teardrop scoop (#717744) dipping from the top edge around the active tab
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

    // 2. Subtle top edge line for crisp demarcation
    final topBorderPaint = Paint()
      ..color = const Color(0x18FFFFFF)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), topBorderPaint);

    // 3. Olive scoop matching user's design (#717744)
    final olivePaint = Paint()
      ..color = AppColors.dustyOlive
      ..style = PaintingStyle.fill;

    // Proportions calibrated to match the reference design:
    // Top flare width extends symmetrically around active tab center
    final double topSpread = (tabWidth * 0.44).clamp(32.0, 42.0);
    const double bulbRadius = 24.5;
    final double iconY = barHeight / 2.0;
    final double bottomY = (iconY + bulbRadius).clamp(0.0, barHeight - 4.0);
    final double neckY = iconY - 8.0;

    final path = Path();
    // Start at top edge left flare
    path.moveTo(activeX - topSpread, 0);

    // Left flare curve down into bulb waist:
    // Starts horizontal at top edge, curves inward and transitions smoothly vertical at neck
    path.cubicTo(
      activeX - topSpread * 0.55, 0,
      activeX - bulbRadius, neckY * 0.35,
      activeX - bulbRadius, neckY,
    );

    // Left bulb curve down to bottom apex:
    // Continues vertically from neck, rounds out around the icon, and flattens at bottom apex
    path.cubicTo(
      activeX - bulbRadius, neckY + 10.0,
      activeX - bulbRadius * 0.55, bottomY,
      activeX, bottomY,
    );

    // Right bulb curve up from bottom apex to waist:
    path.cubicTo(
      activeX + bulbRadius * 0.55, bottomY,
      activeX + bulbRadius, neckY + 10.0,
      activeX + bulbRadius, neckY,
    );

    // Right flare curve up to top edge:
    path.cubicTo(
      activeX + bulbRadius, neckY * 0.35,
      activeX + topSpread * 0.55, 0,
      activeX + topSpread, 0,
    );

    // Close straight across top edge
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
