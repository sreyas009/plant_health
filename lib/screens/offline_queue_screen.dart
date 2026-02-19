import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';
import '../services/sync_service.dart';

enum QueueFilter { all, pending, uploaded, missing }

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  List<Map<String, dynamic>> _queue = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isDownloading = false;
  bool _isReattaching = false;
  final Set<int> _selectedIds = <int>{};
  final ImagePicker _picker = ImagePicker();
  QueueFilter _activeFilter = QueueFilter.all;

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
        final validIds = _queue.map((item) => item['id'] as int).toSet();
        _selectedIds.removeWhere((id) => !validIds.contains(id));
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSync() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isSyncing = true);
    final result = await SyncService.processQueue(onlyIds: _selectedIds);
    // Reload queue after sync attempts
    await _loadQueue();
    if (mounted) {
      setState(() => _isSyncing = false);
      final message = result.isEmpty
          ? 'No selected pending items to sync'
          : 'Selected sync done: ${result.synced}/${result.total} uploaded, '
                '${result.failed} failed, '
                '${result.missingFiles} missing image files.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteRequest(int id) async {
    await DatabaseHelper.instance.deleteRequest(id);
    _selectedIds.remove(id);
    _loadQueue();
  }

  void _toggleSelect(int id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleSelectAll() {
    final allIds = _filteredQueue().map((item) => item['id'] as int).toSet();
    setState(() {
      if (_selectedIds.length == allIds.length && allIds.isNotEmpty) {
        _selectedIds.removeAll(allIds);
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  Future<void> _downloadSelected() async {
    if (_selectedIds.isEmpty || _isDownloading) return;

    setState(() => _isDownloading = true);
    var copied = 0;
    var missing = 0;
    var failed = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(
        p.join(
          appDir.path,
          'offline_exports',
          DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
      await exportDir.create(recursive: true);

      for (final item in _queue) {
        final id = item['id'] as int;
        if (!_selectedIds.contains(id)) continue;

        final sourcePath = item['imagePath'] as String;
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) {
          missing++;
          continue;
        }

        final sourceName = p.basename(sourcePath);
        final targetName = '${id}_$sourceName';
        final destinationPath = p.join(exportDir.path, targetName);

        try {
          await sourceFile.copy(destinationPath);
          copied++;
        } catch (_) {
          failed++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download finished: $copied copied, $missing missing, $failed failed.\nSaved in: ${exportDir.path}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _reattachImage(int id) async {
    if (_isReattaching) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Capture from Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _isReattaching = true);
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      final persistentPath = await _copyImageToOfflineStorage(picked.path);
      await DatabaseHelper.instance.updateRequestImagePath(id, persistentPath);
      await _loadQueue();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image re-attached successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to re-attach image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReattaching = false);
      }
    }
  }

  Future<String> _copyImageToOfflineStorage(String originalPath) async {
    final source = File(originalPath);
    if (!await source.exists()) {
      throw FileSystemException('Image not found', originalPath);
    }

    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline_queue_images'));
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }

    final baseName = p.basenameWithoutExtension(originalPath);
    final ext = p.extension(originalPath);
    final safeBaseName = baseName.isEmpty ? 'image' : baseName;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeBaseName$ext';
    final destinationPath = p.join(offlineDir.path, fileName);
    await source.copy(destinationPath);
    return destinationPath;
  }

  bool _hasFile(Map<String, dynamic> item) {
    final imagePath = item['imagePath'] as String;
    return File(imagePath).existsSync();
  }

  bool _isUploaded(Map<String, dynamic> item) {
    return (item['uploaded'] as int? ?? 0) == 1;
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    switch (_activeFilter) {
      case QueueFilter.all:
        return true;
      case QueueFilter.pending:
        return !_isUploaded(item) && _hasFile(item);
      case QueueFilter.uploaded:
        return _isUploaded(item);
      case QueueFilter.missing:
        return !_hasFile(item);
    }
  }

  List<Map<String, dynamic>> _filteredQueue() {
    return _queue.where(_matchesFilter).toList();
  }

  void _setFilter(QueueFilter filter) {
    final visibleIds = _queue
        .where((item) {
          switch (filter) {
            case QueueFilter.all:
              return true;
            case QueueFilter.pending:
              return !_isUploaded(item) && _hasFile(item);
            case QueueFilter.uploaded:
              return _isUploaded(item);
            case QueueFilter.missing:
              return !_hasFile(item);
          }
        })
        .map((item) => item['id'] as int)
        .toSet();

    setState(() {
      _activeFilter = filter;
      _selectedIds.removeWhere((id) => !visibleIds.contains(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredQueue = _filteredQueue();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (_isSyncing || _selectedIds.isEmpty) ? null : _triggerSync,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: filteredQueue.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final total = _queue.length;
                  final uploadedCount = _queue
                      .where((item) => (item['uploaded'] as int? ?? 0) == 1)
                      .length;
                  final missingFileCount = _queue.where((item) {
                    final imagePath = item['imagePath'] as String;
                    return !File(imagePath).existsSync();
                  }).length;
                  final pendingCount = _queue.where((item) {
                    final isUploaded = (item['uploaded'] as int? ?? 0) == 1;
                    final hasFile = File(
                      item['imagePath'] as String,
                    ).existsSync();
                    return !isUploaded && hasFile;
                  }).length;
                  final visibleIds = filteredQueue
                      .map((item) => item['id'] as int)
                      .toSet();
                  final selectedVisible = _selectedIds
                      .where(visibleIds.contains)
                      .length;
                  final allSelected =
                      visibleIds.isNotEmpty &&
                      selectedVisible == visibleIds.length;
                  return Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text('Total: $total'),
                              Text('Pending: $pendingCount'),
                              Text('Uploaded: $uploadedCount'),
                              Text('Missing file: $missingFileCount'),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _activeFilter == QueueFilter.all,
                              onSelected: (_) => _setFilter(QueueFilter.all),
                            ),
                            ChoiceChip(
                              label: const Text('Pending'),
                              selected: _activeFilter == QueueFilter.pending,
                              onSelected: (_) =>
                                  _setFilter(QueueFilter.pending),
                            ),
                            ChoiceChip(
                              label: const Text('Uploaded'),
                              selected: _activeFilter == QueueFilter.uploaded,
                              onSelected: (_) =>
                                  _setFilter(QueueFilter.uploaded),
                            ),
                            ChoiceChip(
                              label: const Text('Missing'),
                              selected: _activeFilter == QueueFilter.missing,
                              onSelected: (_) =>
                                  _setFilter(QueueFilter.missing),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              TextButton.icon(
                                onPressed: _toggleSelectAll,
                                icon: Icon(
                                  allSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                ),
                                label: Text(
                                  allSelected ? 'Unselect All' : 'Select All',
                                ),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed:
                                    selectedVisible > 0 && !_isDownloading
                                    ? _downloadSelected
                                    : null,
                                icon: _isDownloading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: Text('Download ($selectedVisible)'),
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final item = filteredQueue[index - 1];
                final imagePath = item['imagePath'] as String;
                final file = File(imagePath);
                final id = item['id'] as int;
                final isSelected = _selectedIds.contains(id);
                final isUploaded = (item['uploaded'] as int? ?? 0) == 1;
                final hasFile = file.existsSync();
                final serial = index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    onTap: () => _toggleSelect(id, !isSelected),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (selected) => _toggleSelect(id, selected),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            image: file.existsSync()
                                ? DecorationImage(
                                    image: FileImage(file),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: !file.existsSync()
                              ? const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ],
                    ),
                    title: Text('#$serial  ${item['type'] ?? 'Unknown Type'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !hasFile
                              ? 'Status: Missing file'
                              : isUploaded
                              ? 'Status: Uploaded'
                              : 'Status: Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: !hasFile
                                ? Colors.red.shade700
                                : isUploaded
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (item['subtype'] != null)
                          Text(
                            'Subtype: ${item['subtype']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        Text(
                          'Created: ${item['createdAt'].toString().split('.').first}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: !hasFile
                        ? IconButton(
                            icon: const Icon(Icons.link, color: Colors.blue),
                            tooltip: 'Re-attach image',
                            onPressed: _isReattaching
                                ? null
                                : () => _reattachImage(id),
                          )
                        : isUploaded
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteRequest(id),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
