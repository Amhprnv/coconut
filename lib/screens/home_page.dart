import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'result_page.dart'; // Import ResultPage class

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? imagefile;
  bool uploading = false; // Track uploading status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Coconut Maturity Estimation",
          style: Theme.of(context).textTheme.displayMedium,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imagefile == null
                ? Image.asset(
              'assets/imageicon.png',
              height: 300,
              width: 300,
            )
                : ClipRRect(
              child: Image.file(
                imagefile!,
                height: 300,
                width: 300,
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () async {
                Map<Permission, PermissionStatus> statuses =
                await [Permission.storage, Permission.camera].request();
                if (statuses[Permission.storage]!.isGranted &&
                    statuses[Permission.camera]!.isGranted) {
                  showImagePicker(context, this);
                }
              },
              child: Container(
                height: 48,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Select Image",
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            uploading
                ? Container(
              height: 48,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
                : InkWell(
              onTap: () async {
                if (imagefile != null) {
                  _submitImage();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Please select the image"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                height: 48,
                width: 250,
                decoration: BoxDecoration(
                  color: imagefile != null ? Colors.teal : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Submit Image",
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateImage(File image) {
    setState(() {
      imagefile = image;
    });
  }

  void _submitImage() async {
    setState(() {
      uploading = true; // Set uploading to true when submitting image
    });
    try {
      await uploadImageToFirebase(imagefile!);
      // You can add additional logic here after the image is uploaded.
      // Navigate to the next page after image upload is complete
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultPage(requestData: {/* Your data here */})),
      );
    } finally {
      setState(() {
        uploading = false; // Reset uploading status
      });
    }
  }
}

final picker = ImagePicker();
void showImagePicker(BuildContext context, _HomePageState homePageState) {
  showModalBottomSheet(
    context: context,
    builder: (builder) {
      return Card(
        child: Container(
          height: MediaQuery.of(context).size.height / 5.2,
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(
            top: 8.0,
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  child: Column(
                    children: [
                      Icon(
                        Icons.image,
                        size: 60.0,
                      ),
                      SizedBox(
                        height: 12.0,
                      ),
                      Text(
                        "Gallery",
                        textAlign: TextAlign.center,
                      )
                    ],
                  ),
                  onTap: () {
                    imageFromGallery(homePageState);
                    Navigator.pop(context);
                  },
                ),
              ),
              Expanded(
                child: InkWell(
                  child: SizedBox(
                    child: Column(
                      children: [
                        Icon(
                          Icons.camera,
                          size: 60,
                        ),
                        SizedBox(
                          height: 12.0,
                        ),
                        Text(
                          "Camera",
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    imageFromCamera(homePageState);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void imageFromGallery(_HomePageState homePageState) async {
  final pickedImage = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 50,
  );
  if (pickedImage != null) {
    cropImageFile(File(pickedImage.path), homePageState);
  }
}

void imageFromCamera(_HomePageState homePageState) async {
  final pickedImage = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 50,
  );
  if (pickedImage != null) {
    cropImageFile(File(pickedImage.path), homePageState);
  }
}

void cropImageFile(File imgFile, _HomePageState homePageState) async {
  final croppedFile = await ImageCropper().cropImage(
    sourcePath: imgFile.path,
    aspectRatioPresets: Platform.isAndroid
        ? [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ]
        : [
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio5x3,
      CropAspectRatioPreset.ratio5x4,
      CropAspectRatioPreset.ratio7x5,
      CropAspectRatioPreset.ratio16x9
    ],
    uiSettings: [
      AndroidUiSettings(
          toolbarTitle: "Image Cropper",
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
      IOSUiSettings(
        title: "Image Cropper",
      ),
    ],
  );
  if (croppedFile != null) {
    homePageState.updateImage(File(croppedFile.path));
  }
}

Future<void> uploadImageToFirebase(File imageFile) async {
  try {
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref =
    storage.ref().child('images').child('${DateTime.now()}.jpg');

    await ref.putFile(imageFile);
    print('Image uploaded to Firebase Storage.');
  } catch (e) {
    print('Error uploading image to Firebase: $e');
  }
}


