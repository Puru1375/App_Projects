import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // <--- THIS IS CRUCIAL FOR PLATFORM CHECKS
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanWell', // Your app's title
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // You can choose any color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ProductScanScreen(), // Our new starting screen
    );
  }
}

class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = ''; // NEW: Variable to store the OCR result

  // Function to pick image from gallery (unchanged from previous step)
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _recognizedText = ''; // Clear previous text when new image selected
      });
      print('Image picked from gallery: ${image.path}');
    }
  }

  // Function to take image from camera (unchanged from previous step, with desktop conditional fix)
  Future<void> _takeImageWithCamera() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _recognizedText = ''; // Clear previous text
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

  // NEW FUNCTION: _performOcr - This is where the magic happens!
  Future<void> _performOcr() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    setState(() {
      _recognizedText = 'Analyzing image...'; // Show a loading message while processing
    });

    // Prepare the image for ML Kit
    final inputImage = InputImage.fromFilePath(_pickedImage!.path);
    // Initialize the text recognizer for Latin script (English, etc.)
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      // Process the image and get the recognized text
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text; // Update the UI with the result
      });
      print('OCR Result:\n${recognizedText.text}');
    } catch (e) {
      // Handle any errors during OCR
      setState(() {
        _recognizedText = 'Error during OCR: $e';
      });
      print('Error during OCR: $e');
    } finally {
      // Important: Close the recognizer to release resources
      textRecognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView( // Added for scrolling if content gets long
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display the picked image (optional, but good for feedback)
              if (_pickedImage != null) ...[
                // This uses dart:io.File to display the image from its path
                Image.file(File(_pickedImage!.path), height: 200, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(
                  'Image path: ${_pickedImage!.path}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],

              // Buttons for picking/taking images (from previous step)
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: (Platform.isAndroid || Platform.isIOS) ? _takeImageWithCamera : null,
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

              // NEW: Analyze Button - now calls _performOcr
              ElevatedButton(
                onPressed: _performOcr, // Call the new OCR function
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Analyze Product (OCR)'),
              ),
              const SizedBox(height: 30),

              // NEW: Display OCR Result
              const Text(
                'OCR Result:',
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
                constraints: const BoxConstraints(minHeight: 100), // Ensure some height
                child: Text(
                  _recognizedText.isEmpty ? 'No text recognized yet.' : _recognizedText,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}