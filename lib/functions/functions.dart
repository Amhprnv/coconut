import 'dart:io';

import 'package:coconut/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

// void imageFromGallery() async {
//   await picker
//       .pickImage(source: ImageSource.gallery, imageQuality: 50)
//       .then((value) {
//     if (value != null) {
//       cropImageFile(File(value.path));
//     }
//   });
// }

// void imageFromCamera() async {
//   await picker
//       .pickImage(source: ImageSource.camera, imageQuality: 50)
//       .then((value) {
//     if (value != null) {
//       cropImageFile(File(value.path));
//     }
//   });
// }

// void cropImageFile(File imgFile) async {
//   final croppedFile = await ImageCropper().cropImage(
//     sourcePath: imgFile.path,
//     aspectRatioPresets: Platform.isAndroid
//         ? [
//             CropAspectRatioPreset.square,
//             CropAspectRatioPreset.ratio3x2,
//             CropAspectRatioPreset.original,
//             CropAspectRatioPreset.ratio4x3,
//             CropAspectRatioPreset.ratio16x9
//           ]
//         : [
//             CropAspectRatioPreset.original,
//             CropAspectRatioPreset.square,
//             CropAspectRatioPreset.ratio3x2,
//             CropAspectRatioPreset.ratio4x3,
//             CropAspectRatioPreset.ratio5x3,
//             CropAspectRatioPreset.ratio5x4,
//             CropAspectRatioPreset.ratio7x5,
//             CropAspectRatioPreset.ratio16x9
//           ],
//     uiSettings: [
//       AndroidUiSettings(
//           toolbarTitle: "Image Cropper",
//           toolbarColor: Colors.deepOrange,
//           toolbarWidgetColor: Colors.white,
//           initAspectRatio: CropAspectRatioPreset.original,
//           lockAspectRatio: false),
//       IOSUiSettings(
//         title: "Image Cropper",
//       ),
//     ],
//   );
//   if (croppedFile != null) {
//     imageCache.clear();
//     setState(() {
//       var imageFile = File(croppedFile.path);
//     });
//   }
// }



// void showImagePicker(BuildContext context) {
//   showModalBottomSheet(
//       context: context,
//       builder: (builder) {
//         return Card(
//           child: Container(
//             height: MediaQuery.of(context).size.height / 5.2,
//             width: MediaQuery.of(context).size.width,
//             margin: EdgeInsets.only(
//               top: 8.0,
//             ),
//             padding: EdgeInsets.all(12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: InkWell(
//                     child: Column(
//                       children: [
//                         Icon(
//                           Icons.image,
//                           size: 60.0,
//                         ),
//                         SizedBox(
//                           height: 12.0,
//                         ),
//                         Text(
//                           "Gallery",
//                           textAlign: TextAlign.center,
//                         )
//                       ],
//                     ),
//                     onTap: () {
//                       imageFromGallery();
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   child: InkWell(
//                     child: SizedBox(
//                       child: Column(
//                         children: [
//                           Icon(
//                             Icons.camera,
//                             size: 60,
//                           ),
//                           SizedBox(
//                             height: 12.0,
//                           ),
//                           Text(
//                             "Cmera",
//                             textAlign: TextAlign.center,
//                           )
//                         ],
//                       ),
//                     ),
//                     onTap: () {
//                       imageFromCamera();
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       });
// }

