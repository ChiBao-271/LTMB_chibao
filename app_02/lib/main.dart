import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_02/notesApp/view/note_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Quản lý Ghi chú',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.lightBlueAccent,
          secondary: Colors.blueAccent,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      home: NoteListScreen(),
    );
  }
}