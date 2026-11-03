import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AyatApp());
}

class AyatApp extends StatelessWidget {
  const AyatApp({super.key});

  static const emerald = Color(0xFF064E3B);
  static const gold = Color(0xFFD6B56D);
  static const background = Color(0xFF071B16);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emerald,
        brightness: Brightness.dark,
        primary: const Color(0xFF0B8060),
        secondary: gold,
        surface: const Color(0xFF102820),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'آيات',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      ),
      home: const HomeScreen(),
    );
  }
}