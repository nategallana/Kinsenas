import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      activeColor: AppColors.whiteSmoke,
    ),
    _NavItemData(
      label: 'Sahod',
      outlineIcon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      activeColor: Color(0xFF38BDF8), // Electric blue accent as seen in mockup
    ),
    _NavItemData(
      label: 'Ipon',
      outlineIcon: Icons.savings_outlined,
      activeIcon: Icons.savings_rounded,
      activeColor: AppColors.whiteSmoke, // White filled piggy bank
    ),
    _NavItemData(
      label: 'Utang',
      outlineIcon: Icons.swap_horiz_rounded,
      activeIcon: Icons.swap_horizontal_circle,
      activeColor: AppColors.whiteSmoke,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 74.0;

    return Container(
      color: AppColors.background,
      height: barHeight + bottomPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / _items.length;
          final targetX = (widget.selectedIndex + 0.5) * tabWidth;

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: targetX, end: targetX),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, currentX, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Custom Abstract Wave Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _AbstractWavePainter(
                        activeX: currentX,
                        totalWidth: totalWidth,
                        totalHeight: barHeight + bottomPadding,
                      ),
                    ),
                  ),

                  // Navigation Items
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
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    transform: Matrix4.translationValues(
                                      0,
                                      isActive ? -2 : 0,
                                      0,
                                    ),
                                    child: Icon(
                                      isActive ? item.activeIcon : item.outlineIcon,
                                      size: 26,
                                      color: isActive ? item.activeColor : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
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
    // Olive wave color matching user's image & palette
    final olivePaint = Paint()
      ..color = const Color(0xFF5A6338)
      ..style = PaintingStyle.fill;

    // Dark base color
    final darkBasePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    // 1. Fill entire base with dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkBasePaint);

    // 2. Draw the upper abstract fluid wave with scoop around the active tab
    final path = Path();
    
    // Abstract left starting point (starts at top-left corner (0, 0))
    path.moveTo(0, 0);

    const double scoopRadius = 32.0;
    final double scoopStartX = (activeX - scoopRadius).clamp(0.0, size.width);
    final double scoopEndX = (activeX + scoopRadius).clamp(0.0, size.width);
    const double scoopMidY = 56.0;
    const double waveBaseY = 22.0;

    // Left abstract connecting line: from (0, 0) to (scoopStartX, waveBaseY)
    if (scoopStartX > 0) {
      final double cp1X = scoopStartX * 0.35;
      const double cp1Y = 26.0;
      final double cp2X = scoopStartX * 0.78;
      const double cp2Y = 14.0;
      path.cubicTo(cp1X, cp1Y, cp2X, cp2Y, scoopStartX, waveBaseY);
    }

    // The circular scoop dipping down around the active icon
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

    // Right abstract connecting line: from (scoopEndX, waveBaseY) to (size.width, 0)
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

    // Close path along the top
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, olivePaint);

    // 3. Circular highlight / bubble pad directly behind active icon
    final circleCenter = Offset(activeX, 28);
    final circlePaint = Paint()
      ..color = const Color(0xFF5A6338)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(circleCenter, 27, circlePaint);

    // Subtle edge highlight for tactile depth
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
