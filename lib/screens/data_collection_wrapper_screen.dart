import 'package:flutter/material.dart';
import 'data_collection_screen.dart';
import 'offline_queue_screen.dart';

class DataCollectionWrapperScreen extends StatelessWidget {
  const DataCollectionWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: 'New Entry'),
              Tab(icon: Icon(Icons.wifi_off), text: 'Offline Queue'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [DataCollectionScreen(), OfflineQueueScreen()],
        ),
      ),
    );
  }
}
