import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'history_screen.dart';

class PlantHealthScreen extends StatelessWidget {
  const PlantHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor:
              Colors.teal, // Ensure background matches if needed, or use theme
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.camera_alt), text: 'Camera'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(children: [CameraScreen(), HistoryScreen()]),
      ),
    );
  }
}
