import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:azstore/azstore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';
import '../Ad code/ad_helper.dart';
import '../Auth code/auth.dart';
import '../Themes/lMode.dart';
import '../main.dart';

const rootImagePath = 'https://movein.blob.core.windows.net/moveinimages/';

Future<void> _uploadImageToAzure(File imageFile) async {
  Uint8List bytes = imageFile.readAsBytesSync();
  var x = AzureStorage.parse(
      'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net');
  try {
    var uuid = const Uuid();
    String imageName = uuid.v1();
    await x.putBlob('/moveinimages/$imageName.jpg',
        contentType: 'image/jpg', bodyBytes: bytes);
  } catch (e) {
    print('Exception: $e');
  }
}

// For returning the string name for firebase upload
Future<String?> _uploadImageToAzure2(File imageFile) async {
  Uint8List bytes = imageFile.readAsBytesSync();
  var x = AzureStorage.parse(
      'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net');
  try {
    var uuid = const Uuid();
    String imageName = uuid.v1();
    await x.putBlob('/moveinimages/$imageName.jpg', contentType: 'image/jpg', bodyBytes: bytes);
    return imageName;
  } catch (e) {
    return ('Exception: $e');
  }
}

Future<void> _deleteProfileImageFromAzure(String fileString) async {
  var x = AzureStorage.parse(
    'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net'
    );
  try {
    await x.deleteBlob('/moveinimages/$fileString');
  } catch (e) {
    print('Exception: $e');
  }
}

Future<void> updateImage(imageArray) async {
  try {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(Auth().currentUser())
        .update({
      'Images': imageArray
    });
  } catch (e) {
    throw FirebaseException(
      message: 'Error saving user data: $e',
      plugin: 'cloud_firestore',
    );
  }
}

// ignore: camel_case_types
class accountImages extends StatefulWidget {
  const accountImages({super.key});

  @override
  State<accountImages> createState() => _accountImages();
}

class _accountImages extends State<accountImages> {
  @override
  File? _profileImage;
  File? accountPicture1;
  File? accountPicture2;
  String? profilePictureString;
  String? accountPicture1String;
  String? accountPicture2String;
  String? image1url;
  String? image2url;
  var defaultProfilePicture = Image.asset('assets/Pictures/turt.png');

  Future<List<String>> getNameAndPic() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(Auth().currentUser())
          .get();

      String foreName = userDoc.get("ForeName");
      String surname = userDoc.get("SurName");
      String profPic = userDoc.get("Images")[0];
      String picture1 = userDoc.get("Images")[1];
      String picture2 = userDoc.get("Images")[2];
      String fullName = "$foreName $surname";

      return [fullName, profPic, picture1, picture2];
    } catch (e) {
      throw FirebaseException(
          message: 'Error retrieving name or profile picture: $e',
          plugin: 'cloud_firestore');
    }
  }

  Future<File?> pickImage() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    // return File(image.path);
    CroppedFile? croppedImage = await cropImage(File(image.path));
    if (croppedImage != null) {
      return File(croppedImage.path);
    }
  } else {
    print('No image selected.');
    return null;
  }
}

  Future<CroppedFile?> cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(sourcePath: imageFile.path,
    compressFormat: ImageCompressFormat.jpg,
    maxWidth: 200,
    maxHeight: 200,
    compressQuality: 100,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Image Cropper',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false
        ),
        IOSUiSettings(
          title: 'Image Cropper'
        )
      ]
    );
    return croppedFile;
  }

  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getNameAndPic(),
      builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            var data = snapshot.data;
            // Other images for the user
            var image1 = data![2];
            var image2 = data[3];

            List<String?> imageArray = [];

            imageArray.add(data[1]);
            imageArray.add(data[2]);
            imageArray.add(data[3]);

            // network paths to user's images
            var image1path = '$rootImagePath$image1.jpg';
            var image2path = '$rootImagePath$image2.jpg';

            if (image1 == '') {
              image1path = '';
            }

            if (image2 == '') {
              image2path = '';
            }
            

            return Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(LineAwesomeIcons.angle_left, color: Theme.of(context).primaryColor,),
                      color: Colors.grey[500],
                      onPressed: (() {
                        Navigator.pop(context);
                      })
                    ),
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: ListView(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.image,
                                color: Theme.of(context).primaryColor,
                                size: 50,
                              ),
                              const SizedBox(width: 10),
                              Text("Account Images".tr, style: Theme.of(context).textTheme.headlineLarge,)
                            ],
                          ),
                          const Divider(height: 20, thickness: 1),
                          const SizedBox(height: 10,),
                          const SizedBox(height: 10,),
                          Text(
                            'Primary Image',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(height: 20, thickness: 1),
                          SizedBox(
                            height: 400,
                            width: 550,
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final pickedImage = await pickImage();
                                    if (pickedImage != null) {
                                      accountPicture1String = await _uploadImageToAzure2(pickedImage);
                                      imageArray[1] = accountPicture1String;
                                      updateImage(imageArray);
                                      _deleteProfileImageFromAzure(image1);
                                      setState(() {
                                        image1path = '$rootImagePath$accountPicture1String';
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(40)),
                                    image: DecorationImage(
                                      image: image1path == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage(image1path)
                                    )
                                  ),
                                  ),
                                ),
                                                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: IconButton(
                                        onPressed: () async {
                                          final pickedImage = await pickImage();
                                          if (pickedImage != null) {
                                            profilePictureString = await _uploadImageToAzure2(pickedImage);
                                            imageArray[0] = profilePictureString;
                                            updateImage(imageArray);
                                            _deleteProfileImageFromAzure(image1);
                                            setState(() {
                                              image1path = '$rootImagePath$accountPicture1String';
                                            });
                                          }
                                        },
                                        icon: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: LAppTheme.lightTheme.primaryColor, // Customize the border color
                                              width: 1.0, // Customize the border width
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Icon(
                                              LineAwesomeIcons.pen_nib,
                                              color: LAppTheme.lightTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                              ],
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Text(
                            'Secondary Image',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(height: 20, thickness: 1),
                          SizedBox(
                            height: 400,
                            width: 550,
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final pickedImage = await pickImage();
                                    if (pickedImage != null) {
                                      accountPicture1String = await _uploadImageToAzure2(pickedImage);
                                      imageArray[2] = accountPicture2String;
                                      updateImage(imageArray);
                                      _deleteProfileImageFromAzure(image1);
                                      setState(() {
                                        image2path = '$rootImagePath$accountPicture2String';
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(40)),
                                    image: DecorationImage(
                                      image: image2path == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage(image2path)
                                    )
                                  ),
                                  ),
                                ),
                                Align(
                                      alignment: Alignment.bottomRight,
                                      child: IconButton(
                                        onPressed: () async {
                                          final pickedImage = await pickImage();
                                          if (pickedImage != null) {
                                            accountPicture2String = await _uploadImageToAzure2(pickedImage);
                                            imageArray[2] = accountPicture2String;
                                            updateImage(imageArray);
                                            _deleteProfileImageFromAzure(image2);
                                            setState(() {
                                              image2path = '$rootImagePath$accountPicture2String';
                                            });
                                          }
                                        },
                                        icon: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: LAppTheme.lightTheme.primaryColor, // Customize the border color
                                              width: 1.0, // Customize the border width
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: Icon(
                                              LineAwesomeIcons.pen_nib,
                                              color: LAppTheme.lightTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                              ],
                            ),
                          ), 
                          const SizedBox(height: 10,),
                        ],
                      ),
                    ),
                  ),
                );
        }
      },
    );
  }
}