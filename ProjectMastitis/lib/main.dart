import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const UdderHealthApp());
}

class UdderHealthApp extends StatelessWidget {
  const UdderHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    const primaryTeal = Color(0xFF0F766E); // Modern Slate Teal
    const secondarySlate = Color(0xFF475569);
    const bgSlate = Color(0xFFF8FAFC);
    const borderSlate = Color(0xFFE2E8F0);

    return MaterialApp(
      title: 'mastitis_research',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          secondary: secondarySlate,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgSlate,
        textTheme: baseTextTheme.copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 26, letterSpacing: -0.5),
          displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 22),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 17, color: const Color(0xFF0F172A)),
          titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B)),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 14, height: 1.4, color: const Color(0xFF334155)),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.4, color: const Color(0xFF475569)),
          bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12, height: 1.3, color: const Color(0xFF64748B)),
          labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          labelMedium: baseTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF334155), size: 20),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderSlate, width: 1),
          ),
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primaryTeal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: borderSlate, width: 1),
            foregroundColor: const Color(0xFF334155),
            textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderSlate, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderSlate, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryTeal, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        dividerTheme: const DividerThemeData(
          color: borderSlate,
          thickness: 1,
          space: 1,
        ),
      ),
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}
