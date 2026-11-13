import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A custom bottom navigation bar that renders:
/// 1. An organic, abstract olive green wave across the top layer.
/// 2. A smooth circular scoop / bubble that animates and centers behind the active tab.
/// 3. Inactive tabs showing outline-only icons and muted text.
/// 4. Active tab showing a filled, solid white icon inside the scoop with bold text.
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
  // =========================================================================
  // NAVIGATION ITEMS CONFIGURATION
  // To change icon colors, outlines, or labels, edit this list:
  // =========================================================================
  final List<_NavItemData> _items = const [
    _NavItemData(
      label: 'Home',
      outlineIcon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      activeColor: AppColors.whiteSmoke, // White icon when active
    ),
    _NavItemData(
      label: 'Sahod',
      outlineIcon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      activeColor: AppColors.whiteSmoke, // White icon when active (changed from blue)
    ),
    _NavItemData(
      label: 'Ipon',
      outlineIcon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
      activeColor: AppColors.whiteSmoke, // White icon when active (piggy bank)
    ),
    _NavItemData(
      label: 'Utang',
      outlineIcon: Icons.swap_horiz_rounded,
      activeIcon: Icons.swap_horizontal_circle,
      activeColor: AppColors.whiteSmoke, // White icon when active
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Accommodate safe area on mobile devices (e.g. gesture home bars)
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 74.0;

    return Container(
      color: AppColors.background,
      height: barHeight + bottomPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / _items.length;
          
          // Calculate the horizontal center position (X) for the active tab's scoop
          final targetX = (widget.selectedIndex + 0.5) * tabWidth;

          // Smoothly animate the scoop position when switching between tabs
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: targetX, end: targetX),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, currentX, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // ---------------------------------------------------------
                  // LAYER 1: Abstract Wave Background Painter
                  // ---------------------------------------------------------
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AbstractWavePainter(
                        activeX: currentX,
                        totalWidth: totalWidth,
                        totalHeight: barHeight + bottomPadding,
                      ),
                    ),
                  ),

                  // ---------------------------------------------------------
                  // LAYER 2: Clickable Navigation Icons & Labels
                  // ---------------------------------------------------------
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onItemSelected(index),
                            child: SizedBox(
                              height: barHeight,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated icon with subtle lift on active
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    transform: Matrix4.translationValues(
                                      0,
                                      isActive ? -2 : 0,
                                      0,
                                    ),
                                    child: Icon(
                                      // Outline icon when inactive, filled when active
                                      isActive ? item.activeIcon : item.outlineIcon,
                                      size: 26,
                                      // Active color (White) vs Muted Secondary text color
                                      color: isActive ? item.activeColor : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Text label underneath each icon
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isActive ? AppColors.whiteSmoke : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
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

/// Data class holding icon and label attributes for each navigation tab.
class _NavItemData {
  final String label;
  final IconData outlineIcon;
  final IconData activeIcon;
  final Color activeColor;

  const _NavItemData({
    required this.label,
    required this.outlineIcon,
    required this.activeIcon,
    required this.activeColor,
  });
}

/// Custom painter that draws the organic, abstract wave and the scoop bubble.
class _AbstractWavePainter extends CustomPainter {
  final double activeX;
  final double totalWidth;
  final double totalHeight;

  _AbstractWavePainter({
    required this.activeX,
    required this.totalWidth,
    required this.totalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Olive wave color matching user's palette (#5A6338)
    final olivePaint = Paint()
      ..color = const Color(0xFF5A6338)
      ..style = PaintingStyle.fill;

    // Dark base background color (#11140E)
    final darkBasePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    // 1. Fill entire rectangular navbar base with dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkBasePaint);

    // 2. Draw the upper abstract wave path with a circular scoop dipping down
    final path = Path();
    
    // Start at top-left corner (0, 0)
    path.moveTo(0, 0);

    const double scoopRadius = 32.0;
    final double scoopStartX = (activeX - scoopRadius).clamp(0.0, size.width);
    final double scoopEndX = (activeX + scoopRadius).clamp(0.0, size.width);
    const double scoopMidY = 56.0;
    const double waveBaseY = 22.0;

    // Left abstract connecting line:
    // Fluid cubic bezier curves connecting (0, 0) to the active scoop
    if (scoopStartX > 0) {
      final double cp1X = scoopStartX * 0.35;
      const double cp1Y = 26.0;
      final double cp2X = scoopStartX * 0.78;
      const double cp2Y = 14.0;
      path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, scoopStartX, waveBaseY);
    }

    // Circular scoop dipping down to embrace the active icon
    path.cubicTo(
      activeX - 22.0, scoopMidY - 6.0,
      activeX - 16.0, scoopMidY,
      activeX, scoopMidY,
    );
    path.cubicTo(
      activeX + 16.0, scoopMidY,
      activeX + 22.0, scoopMidY - 6.0,
      scoopEndX, waveBaseY,
    );

    // Right abstract connecting line:
    // Fluid cubic bezier curves connecting the scoop to (size.width, 0)
    final double rightRemaining = size.width - scoopEndX;
    if (rightRemaining > 0) {
      final double cp3X = scoopEndX + rightRemaining * 0.28;
      const double cp3Y = 26.0;
      final double cp4X = scoopEndX + rightRemaining * 0.72;
      const double cp4Y = 12.0;
      path.cubicTo(cp3X, cp3Y, cp4X, cp4Y, size.width, 0.0);
    } else {
      path.lineTo(size.width, 0.0);
    }

    // Close path back along the top
    path.lineTo(size.width, 0);
    path.close();

    // Fill the olive wave
    canvas.drawPath(path, olivePaint);

    // 3. Draw circular bubble pad behind the active icon
    final circleCenter = Offset(activeX, 28);
    final circlePaint = Paint()
      ..color = const Color(0xFF5A6338)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(circleCenter, 27, circlePaint);

    // 4. Subtle dry sage accent stroke along wave edge for tactile depth
    final outlinePaint = Paint()
      ..color = const Color(0x35BCBD8B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _AbstractWavePainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.totalWidth != totalWidth ||
        oldDelegate.totalHeight != totalHeight;
  }
}
