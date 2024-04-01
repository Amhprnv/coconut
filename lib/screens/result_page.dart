import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> requestData;
  const ResultPage({Key? key, required this.requestData}) : super(key: key);

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late Interpreter _interpreter;
  final List<String> _classNames = [
    "Back Bumper", "Bonnet", "Brakelight", "Front Bumper",
    "Front Door", "Front fender", "Front Windscreen Glass",
    "Full Damage", "Headlight", "Side Mirror", "Scratch/Dent", "Rear Glass"
  ];

  List<File> _images = [];
  List<String> _labels = [];

  Map<String, Map<String, double>> _costData = {};

  // Map to store the cost of parts for different vehicle models
  Map<String, Map<String, double>> vehiclePartsCost = {
    'Wagon R': {
      'Back Bumper': 1880,
      'Bonnet': 4500,
      'Brakelight': 1168,
      'Front Bumper': 3072,
      'Front Door': 5888,
      'Front Fender': 1090,
      'Front Windscreen Glass': 3968,
      'Full Damage': 1000,
      'Headlight': 2944,
      'Scratch/Dent': 1000,
      'Side Mirrors': 1000,
    },
    'Eco Sport': {
      'Back Bumper': 2766,
      'Bonnet': 10455,
      'Brakelight': 4943,
      'Front Bumper': 3461,
      'Front Door': 4867,
      'Front Fender': 2355,
      'Front Windscreen Glass': 4965,
      'Full Damage': 1000,
      'Headlight': 5452,
      'Scratch/Dent': 1000,
      'Side Mirrors': 7969,
    },
    // Add other vehicle models here following the same pattern
  };

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_unquant.tflite');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> resizeAndPreprocessImage(File imageFile, int width, int height) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img_lib.Image image = img_lib.decodeImage(imageBytes)!;
      img_lib.Image resizedImage = img_lib.copyResize(image, width: width, height: height);
      Uint8List resizedBytes = img_lib.encodePng(resizedImage);
      classifyImage(resizedBytes);
    } catch (error) {
      print('Error resizing and preprocessing image: $error');
    }
  }

  void classifyImage(Uint8List imageBytes) {
    try {
      final resizedImage = img_lib.decodeImage(imageBytes)!;
      final inputImage = img_lib.copyResize(resizedImage, width: 224, height: 224);
      final inputBuffer = Float32List(224 * 224 * 3);

      for (var i = 0; i < 224; i++) {
        for (var j = 0; j < 224; j++) {
          var pixel = inputImage.getPixel(j, i);
          inputBuffer[i * 224 * 3 + j * 3 + 0] = ((pixel.r.toDouble() - 127.5) / 127.5).toDouble();
          inputBuffer[i * 224 * 3 + j * 3 + 1] = ((pixel.g.toDouble() - 127.5) / 127.5).toDouble();
          inputBuffer[i * 224 * 3 + j * 3 + 2] = ((pixel.b.toDouble() - 127.5) / 127.5).toDouble();
        }
      }

      final outputBuffer = Float32List(1 * 12);
      _interpreter.run(inputBuffer.buffer.asUint8List(), outputBuffer.buffer.asUint8List());
      final double maxConfidence = outputBuffer.reduce((a, b) => a > b ? a : b);
      final int index = outputBuffer.indexOf(maxConfidence);

      setState(() {
        String label = _classNames[index];
        _labels.add(label);

        double partCost = (vehiclePartsCost[widget.requestData['vehicle_model']] ?? {})[label] ?? 0;

        if (_costData.containsKey(widget.requestData['vehicle_model'])) {
          _costData[widget.requestData['vehicle_model']]![label] = partCost;
        } else {
          _costData[widget.requestData['vehicle_model']] = {label: partCost};
        }
      });
    } catch (e) {
      print('Error classifying image: $e');
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      final File capturedImage = File(pickedImage.path);
      setState(() {
        _images.add(capturedImage);
      });
      resizeAndPreprocessImage(capturedImage, 224, 224);
    }
  }

  Future<void> _saveData() async {
    try {
      List<String> imageUrls = [];
      for (File image in _images) {
        String imageName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = firebase_storage.FirebaseStorage.instance.ref().child('images/$imageName.jpg');
        await ref.putFile(image);
        String imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      DocumentReference docRef = await FirebaseFirestore.instance.collection('inspectiondata').add({
        'name': widget.requestData['name'],
        'email': widget.requestData['email'],
        'phone': widget.requestData['phone'],
        'address': widget.requestData['address'],
        'vehicle_model': widget.requestData['vehicle_model'],
        'image_urls': imageUrls,
        'labels': _labels,
        'cost_data': _costData[widget.requestData['vehicle_model']],
      });

      // Get the document ID from the DocumentReference
      String docId = docRef.id;

      // Update the document to store the document ID
      await docRef.update({'doc_id': docId});

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Data saved successfully!'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error saving data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save data. Please try again later.'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  void _analyzeCostAndSave() {
    double totalCost = 0;
    String costDetails = '';

    _costData[widget.requestData['vehicle_model']]?.forEach((key, value) {
      totalCost += value;
      costDetails += '$key: ${value.toStringAsFixed(2)}\n';
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cost Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
              SizedBox(height: 10),
              Text('Cost Details:'),
              Text(costDetails),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveData();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _inspectionCompleted() async {
    try {
      // Fetch the document ID from requestData
      String documentId = widget.requestData['doc_id'];
      print('Document ID: $documentId');

      // Delete the document from Firestore
      print('Deleting document with ID: $documentId');
      await FirebaseFirestore.instance.collection('inspectionrequests').doc(documentId).delete();
      print('Document deleted successfully.');

      // Navigate to dealer page
      Navigator.pushReplacementNamed(context, '/dealer');
    } catch (e) {
      print('Error completing inspection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> requestDataFiltered = Map.from(widget.requestData);
    requestDataFiltered.remove('timestamp');

    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Image'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: requestDataFiltered.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key}:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('${entry.value}'),
                          SizedBox(height: 10),
                          Divider(),
                          SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                itemBuilder: (BuildContext context, int index) {
                  return Column(
                    children: <Widget>[
                      SizedBox(
                        height: 224,
                        width: 224,
                        child: Image.file(
                          _images[index],
                          height: 224,
                          width: 224,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Text('Labels: ${_labels[index]}'),
                      Divider(),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Choose an option'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              GestureDetector(
                                child: Text('Take a picture'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _captureImage(ImageSource.camera);
                                },
                              ),
                              Padding(padding: EdgeInsets.all(8.0)),
                              GestureDetector(
                                child: Text('Select from gallery'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _captureImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFEC2D33)), // Set button background color
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Set text color to white
                ),
                child: Text('Capture Image'),
              ),
              ElevatedButton(
                onPressed: _analyzeCostAndSave,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFEC2D33)), // Set button background color
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Set text color to white
                ),
                child: Text('Analyze Cost'),
              ),
              ElevatedButton(
                onPressed: _inspectionCompleted,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFFEC2D33)), // Set button background color
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white), // Set text color to white
                ),
                child: Text('Inspection Completed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => ResultPage(requestData: {}), // Define your initial route
    },
  ));
}
