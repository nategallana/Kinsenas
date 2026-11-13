import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _activeDay = 0;
  int _phase = 1; // 1 = 1-15 (1st kinsenas), 2 = 16-31 (2nd kinsenas)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startKinsenasCalendarAnimation();
  }

  void _startKinsenasCalendarAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 110), (timer) {
      if (!mounted) return;

      setState(() {
        if (_phase == 1) {
          if (_activeDay < 15) {
            _activeDay++;
          } else {
            _phase = 2;
            _activeDay = 15;
          }
        } else {
          if (_activeDay < 31) {
            _activeDay++;
          } else {
            _timer?.cancel();
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                );
              }
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = _phase == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60000000),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: AppColors.drySage),
                        SizedBox(width: 6),
                        Text(
                          'DECEMBER 2026',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPhase1 ? const Color(0x30717744) : const Color(0x30BCBD8B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPhase1 ? AppColors.dustyOlive : AppColors.drySage,
                        ),
                      ),
                      child: Text(
                        isPhase1 ? '1st Kinsenas (Dec 1–15)' : '2nd Kinsenas (Dec 16–31)',
                        style: TextStyle(
                          color: isPhase1 ? AppColors.drySage : AppColors.whiteSmoke,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 31-Day Calendar Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderMuted),
                  ),
                  child: Column(
                    children: [
                      // Weekday Headers
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _WeekdayLabel('S'),
                          _WeekdayLabel('M'),
                          _WeekdayLabel('T'),
                          _WeekdayLabel('W'),
                          _WeekdayLabel('T'),
                          _WeekdayLabel('F'),
                          _WeekdayLabel('S'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Grid of Days
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 33,
                        itemBuilder: (context, index) {
                          if (index < 2) return const SizedBox();
                          final dayNum = index - 1;

                          final bool isActive = isPhase1
                              ? (dayNum <= _activeDay)
                              : (dayNum >= 16 && dayNum <= _activeDay);

                          final Color activeBg = isPhase1 ? AppColors.dustyOlive : AppColors.darkKhaki;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? activeBg
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.drySage
                                    : Colors.white.withValues(alpha: 0.04),
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.dustyOlive.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '$dayNum',
                                style: TextStyle(
                                  color: isActive ? AppColors.whiteSmoke : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Status Text
                Text(
                  isPhase1 ? 'Calculating Cutoff 1 (Dec $_activeDay)...' : 'Processing Cutoff 2 (Dec $_activeDay)...',
                  style: const TextStyle(
                    color: AppColors.whiteSmoke,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kinsenas · Every Centavo Accounted For',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
