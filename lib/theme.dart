import 'package:flutter/material.dart';

// Paleta de Cores
const Color primaryColor = Color(0xFF3B82F6); // Azul
const Color darkBgColor = Color(0xFF18181B); // Cinza Escuro (Fundo)
const Color darkSurfaceColor = Color(0xFF27272A); // Cinza Escuro (Cards)
const Color lightBgColor = Color(0xFFF4F4F5); // Cinza Claro (Fundo)
const Color lightSurfaceColor = Colors.white; // Branco (Cards)

// Tema Escuro (Dark Mode)
final ThemeData darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: darkBgColor,
  cardColor: darkSurfaceColor,
  primaryColor: primaryColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: darkSurfaceColor,
    elevation: 1,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkBgColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white),
  ),
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: primaryColor,
    surface: darkSurfaceColor,
    background: darkBgColor,
    onSurface: Colors.white,
  ),
);

// Tema Claro (Light Mode)
final ThemeData lightTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: lightBgColor,
  cardColor: lightSurfaceColor,
  primaryColor: primaryColor,
  appBarTheme: const AppBarTheme(
      backgroundColor: lightSurfaceColor,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
          color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w500)),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: primaryColor,
    surface: lightSurfaceColor,
    background: lightBgColor,
  ),
);
