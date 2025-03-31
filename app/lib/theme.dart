import 'package:flutter/material.dart';

// Catppuccin Mocha color palette
class CatppuccinMocha {
  // Base colors
  static const Color rosewater = Color(0xFFF5E0DC);
  static const Color flamingo = Color(0xFFF2CDCD);
  static const Color pink = Color(0xFFF5C2E7);
  static const Color mauve = Color(0xFFCBA6F7);
  static const Color red = Color(0xFFF38BA8);
  static const Color maroon = Color(0xFFEBA0AC);
  static const Color peach = Color(0xFFFAB387);
  static const Color yellow = Color(0xFFF9E2AF);
  static const Color green = Color(0xFFA6E3A1);
  static const Color teal = Color(0xFF94E2D5);
  static const Color sky = Color(0xFF89DCEB);
  static const Color sapphire = Color(0xFF74C7EC);
  static const Color blue = Color(0xFF89B4FA);
  static const Color lavender = Color(0xFFB4BEFE);
  
  // Surface colors
  static const Color crust = Color(0xFF11111B);
  static const Color mantle = Color(0xFF181825);
  static const Color base = Color(0xFF1E1E2E);
  static const Color surface0 = Color(0xFF313244);
  static const Color surface1 = Color(0xFF45475A);
  static const Color surface2 = Color(0xFF585B70);
  
  // Text colors
  static const Color text = Color(0xFFCDD6F4);
  static const Color subtext1 = Color(0xFFBAC2DE);
  static const Color subtext0 = Color(0xFFA6ADC8);
  static const Color overlay2 = Color(0xFF9399B2);
  static const Color overlay1 = Color(0xFF7F849C);
  static const Color overlay0 = Color(0xFF6C7086);
}

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: CatppuccinMocha.mauve,
    secondary: CatppuccinMocha.pink,
    tertiary: CatppuccinMocha.sapphire,
    surface: CatppuccinMocha.surface0,
    background: CatppuccinMocha.base,
    error: CatppuccinMocha.red,
    onPrimary: CatppuccinMocha.crust,
    onSecondary: CatppuccinMocha.crust,
    onSurface: CatppuccinMocha.text,
    onBackground: CatppuccinMocha.text,
    onError: CatppuccinMocha.crust,
  ),
  scaffoldBackgroundColor: CatppuccinMocha.base,
  appBarTheme: AppBarTheme(
    backgroundColor: CatppuccinMocha.mantle,
    foregroundColor: CatppuccinMocha.text,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: CatppuccinMocha.mauve,
      foregroundColor: CatppuccinMocha.crust,
    ),
  ),
  textTheme: TextTheme(
    headlineMedium: TextStyle(
      color: CatppuccinMocha.lavender,
      fontWeight: FontWeight.bold,
    ),
    bodyLarge: TextStyle(color: CatppuccinMocha.text),
    bodyMedium: TextStyle(color: CatppuccinMocha.subtext1),
  ),
  iconTheme: IconThemeData(
    color: CatppuccinMocha.lavender,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: CatppuccinMocha.pink,
    foregroundColor: CatppuccinMocha.crust,
  ),
  cardTheme: CardTheme(
    color: CatppuccinMocha.surface0,
  ),
);
