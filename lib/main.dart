import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_provider.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ImageStore(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _index = 0;

  final List<Widget> _screens = [const CameraScreen(), const HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal.shade600,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 6,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal.shade700,
          unselectedItemColor: Colors.grey.shade500,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade500),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Camera Label App"),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: "Camera",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),
          ],
        ),
        body: _screens[_index],
      ),
    );
  }
}
