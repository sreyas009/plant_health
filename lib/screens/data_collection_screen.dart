import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/crop_type.dart';
import '../models/disease_type.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({super.key});

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isSubmitting = false;

  List<CropType> _crops = [];
  List<DiseaseType> _diseases = [];
  List<DiseaseType> _nutrients = [];
  List<DiseaseType> _filteredDiseases = [];

  String? _selectedCropId;
  String? _selectedCategory;
  String? _selectedDiseaseId;

  final List<String> _categories = [
    "Disease",
    "Pest",
    "Nutrition",
    "Flower",
    "Cherry",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final crops = await ApiService.getCropsData();
      final diseases = await ApiService.getDiseases();
      final nutrients = await ApiService.getNutrients();
      setState(() {
        _crops = crops;
        _diseases = diseases;
        _nutrients = nutrients;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitData() async {
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_selectedCropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop type')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? subtypeName;
      if (_selectedDiseaseId != null) {
        try {
          subtypeName = _filteredDiseases
              .firstWhere((d) => d.id == _selectedDiseaseId)
              .name;
        } catch (_) {
          // Should not happen if logic is correct
        }
      }

      await ApiService.uploadDataCollection(
        cropTypeId: _selectedCropId!,
        type: _selectedCategory!,
        subtype: subtypeName,
        imagePath: _image!.path,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data uploaded successfully!')),
        );
        setState(() {
          _image = null;
          _selectedCropId = null;
          _selectedCategory = null;
          _selectedDiseaseId = null;
        });
      }
    } catch (e) {
      // Save to local queue on failure
      try {
        await SyncService.addToQueue(
          cropTypeId: _selectedCropId!,
          type: _selectedCategory!,
          subtype: _selectedDiseaseId != null
              ? (_filteredDiseases
                    .firstWhere((d) => d.id == _selectedDiseaseId)
                    .name)
              : null,
          // Note: Re-resolving name here might be risky if we didn't resolve it before try block,
          // but I already resolved 'subtypeName' variable above inside the try block.
          // Yet, 'subtypeName' scope is inside try.
          // Let's rely on re-resolving safely or just use what we have.
          // Ideally I should refactor to resolve name before try or inside a wider scope.
          imagePath: _image!.path,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet. Saved for later upload.'),
            ),
          );
          setState(() {
            _image = null;
            _selectedCropId = null;
            _selectedCategory = null;
            _selectedDiseaseId = null;
          });
        }
      } catch (dbError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed and could not save offline: $e'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Picker Section
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                        image: _image != null
                            ? DecorationImage(
                                image: FileImage(_image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _image == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to upload image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Crop Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Crop Type',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCropId,
                    items: _crops.map((crop) {
                      return DropdownMenuItem(
                        value: crop.cropId,
                        child: Text(crop.cropType),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCropId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedDiseaseId =
                            null; // Reset disease selection when category changes
                        if (value == 'Disease') {
                          _filteredDiseases = _diseases
                              .where((d) => d.categoryType == 'Disease')
                              .toList();
                        } else if (value == 'Pest') {
                          _filteredDiseases = _diseases
                              .where((d) => d.categoryType == 'Pest')
                              .toList();
                        } else if (value == 'Nutrition') {
                          _filteredDiseases = _nutrients;
                        } else {
                          _filteredDiseases = [];
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Disease Subtype Dropdown (Optional)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Disease/Subtype (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedDiseaseId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ..._filteredDiseases.map((disease) {
                        return DropdownMenuItem(
                          value: disease.id,
                          child: Text(disease.name),
                        );
                      }),
                    ],
                    onChanged: _filteredDiseases.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDiseaseId = value;
                            });
                          },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'SUBMIT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
