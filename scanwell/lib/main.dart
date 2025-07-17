// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scanwell/health_analyzer.dart'; // Make sure this path is correct for your project 'scanwell'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanWell',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProductScanScreen(),
    );
  }
}

class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  // --- VARIABLES ---
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';
  HealthAnalysisResult? _healthResult;

  // --- FUNCTIONS (MUST BE INSIDE THIS CLASS) ---

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _recognizedText = '';
      });
      print('Image picked from gallery: ${image.path}');
    }
  }

  Future<void> _takeImageWithCamera() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _recognizedText = '';
        });
        print('Image taken with camera: ${image.path}');
      }
    } else {
      print('Camera not directly supported on desktop. Use pick from gallery.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not available on desktop. Please use "Pick from Gallery".'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _performOcr() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _recognizedText = 'OCR is not directly supported on this desktop platform (Windows).';
        _healthResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR not available on desktop. This feature is for mobile devices.'),
          duration: Duration(seconds: 4),
        ),
      );
      print('OCR not available on desktop for google_mlkit_text_recognition.');
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    setState(() {
      _recognizedText = 'Analyzing image...';
      _healthResult = null;
    });

    final inputImage = InputImage.fromFilePath(_pickedImage!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text;
      });

      final HealthAnalyzer analyzer = HealthAnalyzer();
      final HealthAnalysisResult result = analyzer.analyzeProduct(recognizedText.text);
      setState(() {
        _healthResult = result;
      });

      print('OCR Result:\n${recognizedText.text}');
      print('Health Analysis Result: ${result.message} (Score: ${result.healthScore})');
      result.warnings.forEach((warning) => print('Warning: $warning'));
      result.detectedNutrients.forEach((key, value) => print('$key: $value')); // Print detected nutrients

    } catch (e) {
      setState(() {
        _recognizedText = 'Error during OCR: $e';
        _healthResult = null;
      });
      print('Error during OCR: $e');
    } finally {
      textRecognizer.close();
    }
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_pickedImage != null) ...[
                Image.file(File(_pickedImage!.path), height: 200, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(
                  'Image path: ${_pickedImage!.path}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton.icon(
                onPressed: _pickImageFromGallery, // Correctly references the method within the class
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: (Platform.isAndroid || Platform.isIOS) ? _takeImageWithCamera : null, // Correctly references
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              if (!(Platform.isAndroid || Platform.isIOS))
                const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Camera is not fully supported on desktop by default for direct capture. Please use "Pick from Gallery".',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: (Platform.isAndroid || Platform.isIOS) ? _performOcr : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Analyze Product (OCR)'),
              ),
              if (!(Platform.isAndroid || Platform.isIOS))
                const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'OCR is primarily supported on mobile devices.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),

              const Text(
                'Raw OCR Result:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                constraints: const BoxConstraints(minHeight: 100),
                child: Text(
                  _recognizedText.isEmpty ? 'No text recognized yet.' : _recognizedText,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Health Analysis:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _healthResult == null
                    ? const Text('No health analysis performed yet.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _healthResult!.message,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _healthResult!.isHealthy ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Health Score: ${_healthResult!.healthScore}/10'),
                          if (_healthResult!.warnings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._healthResult!.warnings
                                .map((w) => Text('- $w', style: const TextStyle(color: Colors.orange)))
                                .toList(),
                          ],
                          if (_healthResult!.detectedNutrients.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Detected Nutrients:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._healthResult!.detectedNutrients.entries
                                .map((e) => Text('${e.key}: ${e.value}'))
                                .toList(),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}