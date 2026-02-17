import 'dart:io';

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    final queue = await DatabaseHelper.instance.getReferencedRequests();
    if (mounted) {
      setState(() {
        _queue = queue;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    await SyncService.processQueue();
    // Reload queue after sync attempts
    await _loadQueue();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync process completed')));
    }
  }

  Future<void> _deleteRequest(int id) async {
    await DatabaseHelper.instance.deleteRequest(id);
    _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isSyncing ? null : _triggerSync,
        tooltip: 'Sync Now',
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.sync),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pending offline data',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _queue.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final item = _queue[index];
                final imagePath = item['imagePath'] as String;
                final file = File(imagePath);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        image: file.existsSync()
                            ? DecorationImage(
                                image: FileImage(file),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: !file.existsSync()
                          ? const Icon(Icons.broken_image, color: Colors.grey)
                          : null,
                    ),
                    title: Text(item['type'] ?? 'Unknown Type'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['subtype'] != null)
                          Text('Subtype: ${item['subtype']}'),
                        Text(
                          'Created: ${item['createdAt'].toString().split('.').first}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteRequest(item['id']),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
