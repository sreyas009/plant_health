import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p; // IMPORTANT FIX
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/image_provider.dart';
import '../models/saved_image.dart';
import '../services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _brixCtrl = TextEditingController();
  final TextEditingController _ndviCtrl = TextEditingController();

  Future<void> _openCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_image == null) {
      _showSnack("Capture an image before saving.");
      return;
    }

    final description = _textCtrl.text.trim();
    final brixText = _brixCtrl.text.trim();
    final ndviText = _ndviCtrl.text.trim();

    if (description.isEmpty) {
      _showSnack("Please add a description.");
      return;
    }

    if (brixText.isEmpty && ndviText.isEmpty) {
      _showSnack("Provide at least BRIX or NDVI value.");
      return;
    }

    final brix = brixText.isEmpty ? null : double.tryParse(brixText);
    final ndvi = ndviText.isEmpty ? null : double.tryParse(ndviText);

    if (brixText.isNotEmpty && brix == null) {
      _showSnack("Enter a valid BRIX value.");
      return;
    }

    if (ndviText.isNotEmpty && ndvi == null) {
      _showSnack("Enter a valid NDVI value.");
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(_image!.path); // FIXED
    final savedPath = "${appDir.path}/$fileName";

    await _image!.copy(savedPath);

    final store = Provider.of<ImageStore>(context, listen: false);
    final labelValue = store.nextLabel;
    final savedImage = SavedImage(
      path: savedPath,
      label: labelValue.toString(),
      text: description,
      brix: brix,
      ndvi: ndvi,
    );

    await store.addImage(savedImage);

    setState(() {
      _image = null;
      _textCtrl.clear();
      _brixCtrl.clear();
      _ndviCtrl.clear();
    });

    _showSnack("Saved locally. Syncing to cloud...", isError: false);

    try {
      await ApiService.addPlantHealthData(
        label: labelValue,
        ndvi: ndvi,
        brix: brix,
        imagePath: savedPath,
      );
      await store.removeImage(savedImage);
      _showSnack(
        "Saved locally and synced to cloud successfully.",
        isError: false,
      );
    } catch (_) {
      _showSnack("Saved locally but failed to sync with the server.");
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _brixCtrl.dispose();
    _ndviCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextLabel = Provider.of<ImageStore>(context).nextLabel;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Capture New Sample", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            "Image Label • $nextLabel",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),

          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _image == null
                  ? Center(
                      child: Text(
                        "No image captured",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    )
                  : Image.file(_image!, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _openCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Capture Image"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Sample Details", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Description",
                      hintText: "Location, notes, etc.",
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text("Optional Readings", style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _brixCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "BRIX",
                            hintText: "e.g. 12.5",
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ndviCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "NDVI",
                            hintText: "e.g. 0.72",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "At least one of BRIX or NDVI is required.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Save Sample"),
          ),
        ],
      ),
    );
  }
}
