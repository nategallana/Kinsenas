import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        scaffoldBackgroundColor: const Color(0xFF0C0D10),
        primaryColor: const Color(0xFFF43F5E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF43F5E),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF14151B),
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
