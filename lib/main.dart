import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Labeling App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageLabelingScreen(),
    );
  }
}

class ImageLabelingScreen extends StatefulWidget {
  @override
  _ImageLabelingScreenState createState() => _ImageLabelingScreenState();
}

class _ImageLabelingScreenState extends State<ImageLabelingScreen> {
  File? _selectedImage;
  List<Map<String, dynamic>> _labels = [];
  final picker = ImagePicker();

  // Function to pick an image from the camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _labels.clear(); // Clear previous labels
      });
      await _labelImage(File(pickedFile.path));
    }
  }

  // Function to label the image using Google ML Kit
  Future<void> _labelImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final imageLabeler = GoogleMlKit.vision.imageLabeler();

    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    setState(() {
      _labels = labels
          .map((label) => {
                'label': label.label,
                'confidence': (label.confidence * 100).toStringAsFixed(2),
              })
          .toList();
    });

    imageLabeler.close();
  }

  // UI for displaying image and labels
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Labeling')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Image display
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 250, fit: BoxFit.cover),
            const SizedBox(height: 20),

            // Buttons for camera and gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Label display
            if (_labels.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _labels.length,
                  itemBuilder: (context, index) {
                    final label = _labels[index];
                    return ListTile(
                      title: Text(label['label']),
                      subtitle: Text('Confidence: ${label['confidence']}%'),
                    );
                  },
                ),
              ),
            if (_labels.isEmpty)
              Center(child: Text('No labels detected yet.')),
          ],
        ),
      ),
    );
  }
}
