import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppColors.loadTheme();
  runApp(const KinsenasApp());
}

class KinsenasApp extends StatelessWidget {
  const KinsenasApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    final textColor = isDark ? const Color(0xFFEFF1ED) : const Color(0xFF1B2117);
    final surfaceColor = isDark ? const Color(0xFF1B2117) : const Color(0xFFFFFFFF);
    final bgColor = isDark ? const Color(0xFF11140E) : const Color(0xFFF3F5EF);
    final primaryColor = isDark ? const Color(0xFF717744) : const Color(0xFFB5BC84);
    final accentColor = isDark ? const Color(0xFFBCBD8B) : const Color(0xFF555B30);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: bgColor,
      primaryColor: primaryColor,
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        onPrimary: textColor,
        onSurface: textColor,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: textColor,
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        baseTheme.textTheme,
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppColors.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Kinsenas',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const SplashScreen(),
        );
      },
    );
  }
}
