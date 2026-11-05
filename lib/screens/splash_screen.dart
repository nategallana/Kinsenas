import 'dart:async';
import 'package:flutter/material.dart';
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
            // Reached day 15! Clear and move to phase 2
            _phase = 2;
            _activeDay = 15;
          }
        } else {
          if (_activeDay < 31) {
            _activeDay++;
          } else {
            // Finished 2nd kinsenas! Transition to main app
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
      backgroundColor: const Color(0xFF0C0D10),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF14151B),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
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
                        Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'DECEMBER 2026',
                          style: TextStyle(
                            color: Colors.white60,
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
                        color: isPhase1 ? const Color(0x20F43F5E) : const Color(0x2010B981),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPhase1 ? const Color(0x40F43F5E) : const Color(0x4010B981),
                        ),
                      ),
                      child: Text(
                        isPhase1 ? '1st Kinsenas (Dec 1–15)' : '2nd Kinsenas (Dec 16–31)',
                        style: TextStyle(
                          color: isPhase1 ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 31-Day Calendar Grid (Dec 2026 starts on Tuesday = 2 blank days)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0C0F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        itemCount: 33, // 2 blank + 31 days
                        itemBuilder: (context, index) {
                          if (index < 2) return const SizedBox(); // Tuesday start offset
                          final dayNum = index - 1;

                          final bool isActive = isPhase1
                              ? (dayNum <= _activeDay)
                              : (dayNum >= 16 && dayNum <= _activeDay);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFF43F5E)
                                  : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFF43F5E)
                                    : Colors.white.withOpacity(0.04),
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E).withOpacity(0.4),
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
                                  color: isActive ? Colors.white : Colors.white38,
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kinsenas · Every Centavo Accounted For',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
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
        style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
