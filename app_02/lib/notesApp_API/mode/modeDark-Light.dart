import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Định nghĩa các chủ đề màu sắc
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
        titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blue,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey,
      scaffoldBackgroundColor: Colors.grey[900]!,
      cardColor: Colors.grey[800],
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white54),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blueGrey,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ColorScheme.dark(
        primary: Colors.blueGrey,
        secondary: Colors.blueGrey[300]!,
        surface: Colors.grey[800]!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
      ),
    );
  }
}