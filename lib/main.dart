import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/image_provider.dart';
import 'screens/camera_screen.dart';
import 'screens/history_screen.dart';
import 'screens/instructions_screen.dart';
import 'widgets/brand_mark.dart';

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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  final List<Widget> _screens = [
    const CameraScreen(),
    const HistoryScreen(),
    const InstructionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Health Index',
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
      home: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: BrandMark(size: 36),
              ),
              title: const Text("FarmFuture PHI"),
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.info_outline),
                  label: "Instructions",
                ),
              ],
            ),
            body: _screens[_index],
          ),
          if (_showSplash) const Positioned.fill(child: _SplashView()),
        ],
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 120),
            const SizedBox(height: 16),
            Text(
              'FarmFuture PHI',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plant Health Index',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
