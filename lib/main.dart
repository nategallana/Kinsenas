import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KinsenasApp());
}

class KinsenasApp extends StatelessWidget {
  const KinsenasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinsenas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.dustyOlive,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.dustyOlive,
          secondary: AppColors.drySage,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: AppColors.whiteSmoke,
          displayColor: AppColors.whiteSmoke,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.whiteSmoke,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
