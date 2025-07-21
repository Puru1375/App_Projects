import 'dart:io'; // Needed for Platform.isAndroid etc. and Image.file
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scan_well_/health_analyzer.dart'; // IMPORTANT: This path assumes your project name is 'scan_well_'

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
      home: const ProductScanScreen(), // Our starting screen
    );
  }
}

class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  // Variables to hold the picked image, recognized text, and health analysis result
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  String _recognizedText = '';
  HealthAnalysisResult? _healthResult;

  // Function to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _recognizedText = ''; // Clear previous text when new image selected
        _healthResult = null; // Clear previous health result
      });
      // For now, just print the path. Later, we'll process this image.
      print('Image picked from gallery: ${image.path}');
    }
  }

  // Function to take image from camera
  Future<void> _takeImageWithCamera() async {
    // Only allow camera on Android/iOS due to plugin limitations on desktop
    if (Platform.isAndroid || Platform.isIOS) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _recognizedText = ''; // Clear previous text
          _healthResult = null; // Clear previous health result
        });
        print('Image taken with camera: ${image.path}');
      }
    } else {
      // Show a message if camera is not available on the current platform (e.g., desktop)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not available on desktop. Please use "Pick from Gallery".'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Function to perform OCR and then health analysis
  Future<void> _performOcr() async {
    // Only allow OCR on Android/iOS due to plugin limitations on desktop
    if (!(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _recognizedText = 'OCR not supported on this platform.';
        _healthResult = null; // Clear previous health result
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR not available on desktop. This feature is for mobile devices.'),
          duration: Duration(seconds: 4),
        ),
      );
      print('OCR not available on desktop for google_mlkit_text_recognition.');
      return; // Exit the function early if not supported
    }

    // Check if an image has been selected
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    // Set loading state for UI feedback
    setState(() {
      _recognizedText = 'Analyzing image...';
      _healthResult = null; // Clear previous health result
    });

    // Prepare the image for ML Kit Text Recognition
    print('Attempting OCR on image path: ${_pickedImage!.path}');
    final inputImage = InputImage.fromFilePath(_pickedImage!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      // Process the image and get the recognized text
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text; // Update the UI with the full OCR result
      });

      // Perform health analysis using the HealthAnalyzer
      final HealthAnalyzer analyzer = HealthAnalyzer();
      final HealthAnalysisResult result = analyzer.analyzeProduct(recognizedText.text);
      setState(() {
        _healthResult = result; // Store the detailed analysis result
      });

      // Print results to console for debugging
      print('OCR Result:\n${recognizedText.text}');
      print('Health Analysis Result: ${result.message} (Score: ${result.healthScore})');
      result.warnings.forEach((warning) => print('Warning: $warning'));
      result.nutritionFacts.forEach((key, value) => print('Parsed $key: $value'));
      result.rawDetectedText.forEach((key, value) => print('Raw $key: $value'));
      if (result.ingredientsList != null) print('Ingredients: ${result.ingredientsList}');

    } catch (e) {
      // Handle any errors during OCR or analysis
      setState(() {
        _recognizedText = 'Error during OCR: $e';
        _healthResult = null;
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
        child: SingleChildScrollView( // Allows content to scroll if it overflows
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Display the picked image (if available)
              if (_pickedImage != null) ...[
                Image.file(
                  File(_pickedImage!.path),
                  height: 200,
                  fit: BoxFit.contain, // Adjusts image to fit within bounds
                ),
                const SizedBox(height: 20),
                Text(
                  'Image path: ${_pickedImage!.path}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
              ],

              // Buttons for picking/taking images
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                // Button is enabled only on Android or iOS
                onPressed: (Platform.isAndroid || Platform.isIOS) ? _takeImageWithCamera : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              // Display warning for desktop if camera is not supported
              if (!(Platform.isAndroid || Platform.isIOS))
                const Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Camera is not fully supported on desktop.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 30),

              // Button to trigger OCR and analysis
              ElevatedButton(
                // Button is enabled only on Android or iOS
                onPressed: (Platform.isAndroid || Platform.isIOS) ? _performOcr : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Analyze Product (OCR)'),
              ),
              // Display warning for desktop if OCR is not supported
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

              // Display Raw OCR Result
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
                constraints: const BoxConstraints(minHeight: 100), // Ensure some height for the box
                child: Text(
                  _recognizedText.isEmpty ? 'No text recognized yet.' : _recognizedText,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              // Display Health Analysis Result
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

                          // Display Product Name if available
                          if (_healthResult!.productName != null && _healthResult!.productName!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Product Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_healthResult!.productName!),
                          ],

                          // Display Warnings if any
                          if (_healthResult!.warnings.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                            // Using spread operator (...) to add multiple Text widgets directly
                            ..._healthResult!.warnings.map((w) => Text('- $w', style: const TextStyle(color: Colors.orange))),
                          ],

                          // Display Parsed Nutrition Facts (numerical values)
                          if (_healthResult!.nutritionFacts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Parsed Nutrition Facts:', style: TextStyle(fontWeight: FontWeight.bold)),
                            // Iterate over the numerical map and display with one decimal place for doubles
                            ..._healthResult!.nutritionFacts.entries
                                .map((e) => Text('${e.key}: ${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 1)}${e.key == 'Sodium' ? 'mg' : 'g'}')),
                          ],

                          // Display Raw Detected Nutrients (string values)
                          // This is useful for debugging what the regex actually found if parsed values are off
                          if (_healthResult!.rawDetectedText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Raw Detected Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                            // Iterate over the raw string map
                            ..._healthResult!.rawDetectedText.entries.map((e) => Text('${e.key}: ${e.value}')),
                          ],

                          // Display Ingredients List if available
                          if (_healthResult!.ingredientsList != null && _healthResult!.ingredientsList!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_healthResult!.ingredientsList!, softWrap: true,), // softWrap for long text
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