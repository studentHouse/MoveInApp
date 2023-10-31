import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:azstore/azstore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/Friend%20And%20Groups%20Code/FriendFunctions.dart';
import 'package:movein/Scroller%20Code/swipe_card.dart';
import 'package:movein/Friend%20And%20Groups%20Code/GroupFunctions.dart';
import 'package:uuid/uuid.dart';
import '../Auth code/auth.dart';
import '../Themes/lMode.dart';
import '../main.dart';

final imageURL = 'https://movein.blob.core.windows.net/moveingroupimages/';
final imageURL2 = 'https://movein.blob.core.windows.net/moveinimages/';

Future<String?> _uploadGroupImageToAzure(File imageFile) async {
  Uint8List bytes = imageFile.readAsBytesSync();
  var x = AzureStorage.parse('DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net');
  try {
    var uuid = const Uuid();
    String imageName = uuid.v1();
    await x.putBlob('/moveingroupimages/$imageName.jpg', contentType: 'image/jpg', bodyBytes: bytes);
    return imageName;
  } catch (e) {
    print('Exception $e');
  }
}

Future<void> _deleteImageFromAzure(String imageName) async {
  var x = AzureStorage.parse(
    'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net'
    );
  try {
    await x.deleteBlob('/moveinimages/$imageName.jpg');
  } catch (e) {
    print('Exception: $e');
  }
}

class GroupOptions extends StatefulWidget {
  const GroupOptions({Key? key}) : super(key: key);

  @override
  State<GroupOptions> createState() => _GroupOptionsState();
}

class _GroupOptionsState extends State<GroupOptions> {
  var data = {};
  late String groupId;

  // Future<List<dynamic>> getUsers(groupId) async {
  //   List<Map<String, dynamic>> memberDetails = [];
  //   List<Map<String, dynamic>> applicants = [];
  //   List<String> voteKicks = [];
  //   Map<String, List<int>> kickVals = {};
  //   Map<String, List<int>> appVals = {};
  //   String groupName;
  //   String groupPicture;
  //   double avgCleanliness;
  //   double avgNoisiness ;
  //   double avgNightLife;
  //   double avgYearOfStudy;
  //   List<dynamic> allowedUnis;
  //   Timestamp avgBedTime;
  //
  //   final CollectionReference docUsers =
  //       FirebaseFirestore.instance.collection("Users");
  //
  //   try {
  //     DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
  //         .collection("Groups")
  //         .doc(groupId)
  //         .get();
  //
  //     Map<String, dynamic>? groupData =
  //         groupSnapshot.data() as Map<String, dynamic>?;
  //
  //       groupName = groupData?['GroupName'];
  //       groupPicture = groupData?['GroupPicture'];
  //       avgCleanliness = (groupData?['AvgCleanliness'] as num).toDouble();
  //       avgNoisiness = (groupData?['AvgNoisiness'] as num).toDouble();
  //       avgNightLife = (groupData?['AvgNightLife']as num).toDouble();
  //       avgYearOfStudy = (groupData?['AvgYearOfStudy']as num).toDouble();
  //       avgBedTime = groupData?['AvgBedTime'];
  //       allowedUnis = groupData?['AllowedUnis'];
  //
  //       var tempKickVals = groupData?["KickVals"];
  //       for (var key in tempKickVals.keys) {
  //         int agree = 0;
  //         int disagree = 0;
  //         var innerMap = tempKickVals[key];
  //
  //         innerMap.forEach((innerKey, innerValue) {
  //           if (innerValue == 1) {
  //             agree += 1;
  //           } else {
  //             disagree += 1;
  //           }
  //         });
  //
  //         kickVals[key] = [agree, disagree];
  //       }
  //
  //       var tempAppVals = groupData?["AppVals"];
  //       for (var key in tempAppVals.keys) {
  //         int agree = 0;
  //         int disagree = 0;
  //         var innerMap = tempAppVals[key];
  //
  //         innerMap.forEach((innerKey, innerValue) {
  //           if (innerValue == 1) {
  //             agree += 1;
  //           } else {
  //             disagree += 1;
  //           }
  //         });
  //
  //         appVals[key] = [agree, disagree];
  //       }
  //
  //       var applicantIds = groupData?["Applicants"];
  //       for (var aId in applicantIds) {
  //         if (!(aId == "")) {
  //           DocumentSnapshot docSnapshot = await docUsers.doc(aId).get();
  //           Map<String, dynamic>? data =
  //               docSnapshot.data() as Map<String, dynamic>?;
  //
  //           final dateTime = data?['DOB'].toDate();
  //           final currentDate = DateTime.now();
  //           final difference = currentDate.difference(dateTime);
  //           final yearsAgo = difference.inDays ~/ 365;
  //           applicants.add({
  //             "ForeName": data?['ForeName'],
  //             "SurName": data?['SurName'],
  //             "Age": yearsAgo,
  //             "Uni": data?['UniAttended'],
  //             "Preferences": data?['Preferences'],
  //             "Images": data?['Images'],
  //             "Bio": data?['Bio'],
  //             "Subject": data?['Subject'],
  //             "YearOfStudy": data?['YearOfStudy'],
  //             "Id": aId,
  //           });
  //         }
  //       }
  //
  //       var members = groupData?['Members'];
  //       var kickIds = groupData?["Kicks"];
  //       for (String id in members) {
  //         try {
  //           DocumentSnapshot docSnapshot = await docUsers.doc(id).get();
  //           Map<String, dynamic>? data =
  //               docSnapshot.data() as Map<String, dynamic>?;
  //
  //           final dateTime = data?['DOB'].toDate();
  //           final currentDate = DateTime.now();
  //           final difference = currentDate.difference(dateTime);
  //           final yearsAgo = difference.inDays ~/ 365;
  //
  //           if (kickIds.contains(id)) {
  //             voteKicks.add(id);
  //           }
  //
  //           memberDetails.add({
  //             "ForeName": data?['ForeName'],
  //             "SurName": data?['SurName'],
  //             "Age": yearsAgo,
  //             "Uni": data?['UniAttended'],
  //             "Preferences": data?['Preferences'],
  //             "Images": data?['Images'],
  //             "Bio": data?['Bio'],
  //             "Subject": data?['Subject'],
  //             "YearOfStudy": data?['YearOfStudy'],
  //             "Id": id,
  //           });
  //         } catch (e) {
  //           throw FirebaseException(
  //             message: 'Error fetching member data in GroupOptions: $e',
  //             plugin: 'cloud_firestore',
  //           );
  //         }
  //       }
  //   } catch (e) {
  //     throw FirebaseException(
  //       message: 'Error fetching group data in GroupOptions: $e',
  //       plugin: 'cloud_firestore',
  //     );
  //   }
  //   return [
  //     memberDetails,
  //     applicants,
  //     voteKicks,
  //     kickVals,
  //     appVals,
  //     groupName,
  //     groupPicture,
  //     avgCleanliness,
  //     avgNoisiness,
  //     avgNightLife,
  //     avgBedTime,
  //     avgYearOfStudy,
  //     allowedUnis
  //   ];
  // }

  Stream<List<dynamic>> getUsersStream(String groupId) async* {
    final CollectionReference docUsers =
    FirebaseFirestore.instance.collection("Users");

    final streamController = StreamController<List<dynamic>>();

    final groupDocRef = FirebaseFirestore.instance.collection("Groups").doc(groupId);

    // Listen to updates in the group document using snapshots()
    final groupStream = groupDocRef.snapshots();

    final subscription = groupStream.listen((groupSnapshot) async {

      try {
        Map<String, dynamic>? groupData = groupSnapshot.data();

        List<Map<String, dynamic>> memberDetails = [];
        List<Map<String, dynamic>> applicants = [];
        List<String> voteKicks = [];
        Map<String, List<int>> kickVals = {};
        Map<String, List<int>> appVals = {};
        String groupName = '';
        String groupPicture = '';
        double avgCleanliness = 0.0;
        double avgNoisiness = 0.0;
        double avgNightLife = 0.0;
        double avgYearOfStudy = 0.0;
        Timestamp avgBedTime = Timestamp.now();
        List<dynamic> allowedUnis = [];

        if (groupData != null) {
          groupName = groupData['GroupName'];
          groupPicture = groupData['GroupPicture'];
          avgCleanliness = (groupData['AvgCleanliness'] as num).toDouble();
          avgNoisiness = (groupData['AvgNoisiness'] as num).toDouble();
          avgNightLife = (groupData['AvgNightLife'] as num).toDouble();
          avgYearOfStudy = (groupData['AvgYearOfStudy'] as num).toDouble();
          avgBedTime = groupData['AvgBedTime'];
          allowedUnis = groupData['AllowedUnis'];

          var tempKickVals = groupData["KickVals"];
          for (var key in tempKickVals.keys) {
            int agree = 0;
            int disagree = 0;
            var innerMap = tempKickVals[key];

            innerMap.forEach((innerKey, innerValue) {
              if (innerValue == 1) {
                agree += 1;
              } else {
                disagree += 1;
              }
            });

            kickVals[key] = [agree, disagree];
          }

          var tempAppVals = groupData["AppVals"];
          for (var key in tempAppVals.keys) {
            int agree = 0;
            int disagree = 0;
            var innerMap = tempAppVals[key];

            innerMap.forEach((innerKey, innerValue) {
              if (innerValue == 1) {
                agree += 1;
              } else {
                disagree += 1;
              }
            });

            appVals[key] = [agree, disagree];
          }

          var applicantIds = groupData["Applicants"];
          for (var aId in applicantIds) {
            if (!(aId == "")) {
              DocumentSnapshot docSnapshot = await docUsers.doc(aId).get();
              Map<String, dynamic>? data =
              docSnapshot.data() as Map<String, dynamic>?;

              final dateTime = data?['DOB'].toDate();
              final currentDate = DateTime.now();
              final difference = currentDate.difference(dateTime);
              final yearsAgo = difference.inDays ~/ 365;
              applicants.add({
                "ForeName": data?['ForeName'],
                "SurName": data?['SurName'],
                "Age": yearsAgo,
                "Uni": data?['UniAttended'],
                "Preferences": data?['Preferences'],
                "Images": data?['Images'],
                "Bio": data?['Bio'],
                "Subject": data?['Subject'],
                "YearOfStudy": data?['YearOfStudy'],
                "verified" : data?['EmailVerified'],
                "Id": aId,
              });
            }
          }

          var members = groupData['Members'];
          var kickIds = groupData["Kicks"];
          for (String id in members) {
            try {
              DocumentSnapshot docSnapshot = await docUsers.doc(id).get();
              Map<String, dynamic>? data =
              docSnapshot.data() as Map<String, dynamic>?;

              final dateTime = data?['DOB'].toDate();
              final currentDate = DateTime.now();
              final difference = currentDate.difference(dateTime);
              final yearsAgo = difference.inDays ~/ 365;

              if (kickIds.contains(id)) {
                voteKicks.add(id);
              }

              memberDetails.add({
                "ForeName": data?['ForeName'],
                "SurName": data?['SurName'],
                "Age": yearsAgo,
                "Uni": data?['UniAttended'],
                "Preferences": data?['Preferences'],
                "Images": data?['Images'],
                "Bio": data?['Bio'],
                "Subject": data?['Subject'],
                "YearOfStudy": data?['YearOfStudy'],
                "verified" : data?['EmailVerified'],
                "Id": id,
              });
            } catch (e) {
              throw FirebaseException(
                message: 'Error fetching member data in GroupOptions: $e',
                plugin: 'cloud_firestore',
              );
            }
          }
        }

        // Emit the data once it's available.
        streamController.add([
          memberDetails,
          applicants,
          voteKicks,
          kickVals,
          appVals,
          groupName,
          groupPicture,
          avgCleanliness,
          avgNoisiness,
          avgNightLife,
          avgBedTime,
          avgYearOfStudy,
          allowedUnis,
        ]);
      } catch (e) {
        // Handle errors and emit an error state if needed.
        streamController.addError(e);
      }
    });

    // Add a cancel callback to close the stream when no longer needed.
    // You can call this when you dispose of your widget or no longer need the stream.
    streamController.onCancel = () {
      subscription.cancel();
    };

    yield* streamController.stream;
  }


  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    data = ModalRoute.of(context)?.settings.arguments as Map;
    groupId = data['groupId'];
  }

  var groupImageString;

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
  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: getUsersStream(groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List data = snapshot.data!;
          List<Map<String, dynamic>> memberDetails = data[0] as List<Map<String, dynamic>>;
          List<Map<String, dynamic>> applicants = data[1] as List<Map<String, dynamic>>;
          var kicks = data[2];
          var kickVals = data[3];
          var appVals = data[4];
          var groupName = data[5];
          var groupPicture = data[6];
          var avgCleanliness = data[7];
          var avgNoisiness = data[8];
          var avgNightLife = data[9];
          var avgBedTime = data[10];
          var avgYearOfStudy = data[11];
          var allowedUnis = data[12];

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                      children: [
                        const SizedBox(height:20,),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: IconButton(
                              icon: Icon(LineAwesomeIcons.angle_up, color: LAppTheme.lightTheme.primaryColor,),
                              color: Colors.grey[500],
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        Stack(
                          // Group picture
                          children: [
                            GestureDetector(
                              onTap: () async {
                                // Needs testing
                                final pickedImage = await pickImage();
                                groupImageString = await _uploadGroupImageToAzure(pickedImage!);
                                _deleteImageFromAzure('$groupPicture.jpg');
                                updateGroupImage(groupImageString, groupId);      
                              },
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: groupPicture == '' ? const Image(image: NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png'), fit: BoxFit.cover,) : Image(image: NetworkImage('$imageURL$groupPicture.jpg'), fit: BoxFit.cover,)
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 30.0,
                                width: 30.0,
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.grey.withOpacity(0.5),
                                    width: 1, // Adjust the border width as needed
                                  ),
                                ),
                                child: Icon(LineAwesomeIcons.pen_nib,
                                    color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        GestureDetector(
                          onTap: () async {
                            await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) =>
                                  EditGroupName(name: groupName, groupId: groupId),
                            );
                          },
                          child: Text(
                            groupName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        Container(
                          color: Theme.of(context).primaryColor,
                          height: 1.0,
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const SizedBox(width: 13),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("mems".tr,
                                  style: Theme.of(context).textTheme.headlineSmall),
                            ),
                          ],
                        ),
                        // Group Members builder
                        LayoutBuilder(
                          //Members constructor
                          builder: (context, constraints) {
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: memberDetails.length,
                                  itemBuilder: (context, index) {
                                    bool isVoteKick = kicks.contains(memberDetails[index]['Id']) & (kickVals[memberDetails[index]["Id"]] != null);

                                    return GestureDetector(
                                      onTap: () {
                                        showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              CustomDialog(
                                                id: memberDetails[index]['Id'],
                                                foreName: memberDetails[index]['ForeName'],
                                                age: memberDetails[index]['Age'].toInt(),
                                                uni: memberDetails[index]['Uni'],
                                                preferences: memberDetails[index]['Preferences'],
                                                images: memberDetails[index]['Images'],
                                                bio: memberDetails[index]['Bio'],
                                                subject: memberDetails[index]['Subject'],
                                                yearOfStudy: memberDetails[index]['YearOfStudy'].toInt(),
                                                isVerified: memberDetails[index]['verified'],
                                              ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                      BorderRadius.circular(25),
                                                      child: Image(
                                                          image: memberDetails[index]['Images'][0] == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('${imageURL2 + memberDetails[index]['Images'][0]}.jpg'),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    if (memberDetails[index]['verified'])
                                                      Positioned(
                                                        bottom: -5,
                                                        right: -5,
                                                        child: Container(
                                                          width: 15, // Adjust the width and height as needed
                                                          height: 15,
                                                          decoration: const BoxDecoration(
                                                            color: Colors.blue,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons.check,
                                                              color: Colors.white,
                                                              size: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                              child: ClipRect(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${memberDetails[index]["ForeName"]} ${memberDetails[index]["SurName"]}",
                                                      style: isVoteKick
                                                          ? GoogleFonts.lexend(
                                                        color: Colors.red,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        fontSize: 20.0,
                                                      )
                                                          : Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall,
                                                    ),
                                                  ],
                                                ),
                                              )),
                                              if (isVoteKick)
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      left: 8.0),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        "vote-kick".tr,
                                                        style:
                                                        GoogleFonts.sourceCodePro(
                                                          color: Colors.red,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16.0,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "${"Agree".tr}: ${kickVals[memberDetails[index]["Id"]][0]}",
                                                            style: GoogleFonts
                                                                .sourceCodePro(
                                                              color: Colors.red,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                              fontSize: 10.0,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 3),
                                                          SizedBox(
                                                            width: 2,
                                                            height: 13,
                                                            child: Container(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            "${'Disagree'.tr}: ${kickVals[memberDetails[index]["Id"]][1]}",
                                                            style: GoogleFonts
                                                                .sourceCodePro(
                                                              color: Colors.red,
                                                              fontWeight:
                                                              FontWeight.bold,
                                                              fontSize: 10.0,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (memberDetails[index]["Id"] != Auth().currentUser())
                                              PopupMenuButton<String>(
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'add',
                                                    child: Text(
                                                      'add_friend'.tr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                  ),
                                                  if (isVoteKick)
                                                    const PopupMenuDivider(height: 5),
                                                  if (isVoteKick)
                                                    PopupMenuItem(
                                                      value: 'agree',
                                                      child: Text(
                                                        'agree'.tr,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                  if (isVoteKick)
                                                    PopupMenuItem(
                                                      value: 'disagree',
                                                      child: Text(
                                                        'disagree'.tr,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                  if (!isVoteKick)
                                                    PopupMenuItem<String>(
                                                      value: 'kick',
                                                      child: Text(
                                                        'start_vote_kick'.tr,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                ],
                                                onSelected: (value) async {
                                                  if (value == 'add') {
                                                    sendFriendInvite(
                                                      memberDetails[index]["Id"], Auth().currentUser(),).then((value) {
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          backgroundColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                          content: Text(
                                                            'invite_sent'.tr, style: Theme.of(context).textTheme.bodySmall,),
                                                        ),
                                                      );
                                                    });
                                                  } else if (value == 'kick') {
                                                    await startKickVote(
                                                      memberDetails[index]["Id"],
                                                      groupId,
                                                      Auth().currentUser(),);
                                                  } else if (value == 'agree') {
                                                    await updateKickVote(
                                                      groupId,
                                                      true,
                                                      memberDetails[index]["Id"],
                                                      memberDetails.length,
                                                      Auth().currentUser(),
                                                    );
                                                  } else if (value == 'disagree') {
                                                    await updateKickVote(
                                                      groupId,
                                                      false,
                                                      memberDetails[index]["Id"],
                                                      memberDetails.length,
                                                      Auth().currentUser(),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(Icons.more_vert),
                                                splashRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            const SizedBox(width: 13),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("applications".tr,
                                  style: Theme.of(context).textTheme.headlineSmall),
                            ),
                          ],
                        ),
                        LayoutBuilder(
                          // applications Section
                          builder: (context, constraints) {
                            bool hasApps = applicants.isEmpty;
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: hasApps
                                    ? SizedBox(
                                  width: double.maxFinite,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("empty".tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge),
                                  ),
                                )
                                    : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: applicants.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) =>
                                              CustomDialog(
                                                id: applicants[index]['Id'],
                                                foreName: applicants[index]
                                                ['ForeName'],
                                                age: applicants[index]['Age'].toInt(),
                                                uni: applicants[index]['Uni'],
                                                preferences: applicants[index]
                                                ['Preferences'],
                                                images: applicants[index]['Images'],
                                                bio: applicants[index]['Bio'],
                                                subject: applicants[index]
                                                ['Subject'],
                                                yearOfStudy: applicants[index]
                                                ['YearOfStudy'].toInt(),
                                                isVerified: applicants[index]['verified'],
                                              ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding:
                                          const EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 50,
                                                height: 50,
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          25),
                                                      child: Image(
                                                          image: applicants[index]['Images'][0] == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('${imageURL2 + applicants[index]['Images'][0]}.jpg'),
                                                              fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    if (applicants[index]['verified'])
                                                    Positioned(
                                                      bottom: -5,
                                                      right: -5,
                                                      child: Container(
                                                        width: 15, // Adjust the width and height as needed
                                                        height: 15,
                                                        decoration: const BoxDecoration(
                                                          color: Colors.blue,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ClipRect(child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${applicants[index]["ForeName"]} ${applicants[index]["SurName"]}",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall,
                                                    ),
                                                    if (appVals[applicants[index]["Id"]] != null)
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "${"accept".tr}: ${(appVals[applicants[index]["Id"]][0]) ?? 0}",
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          SizedBox(
                                                            width: 2,
                                                            height: 18,
                                                            child: Container(
                                                                color: Colors.black87),
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            "${"reject".tr}: ${(appVals[applicants[index]["Id"]][1]) ?? 0}",
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium,
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                )),
                                              ),
                                              PopupMenuButton<String>(
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'accept',
                                                    child: Text(
                                                      'vote-accept'.tr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'decline',
                                                    child: Text(
                                                      'vote-decline'.tr,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                    ),
                                                  ),
                                                ],
                                                onSelected: (value) async {
                                                  if (value == 'accept') {
                                                    await updateApplicationVote(
                                                      groupId,
                                                      true,
                                                      applicants[index]["Id"],
                                                      memberDetails.length,
                                                      Auth().currentUser(),
                                                    );
                                                  } else if (value ==
                                                      'decline') {
                                                    await updateApplicationVote(
                                                      groupId,
                                                      false,
                                                      applicants[index]["Id"],
                                                      memberDetails.length,
                                                      Auth().currentUser(),
                                                    );
                                                  }
                                                },
                                                icon:
                                                const Icon(Icons.more_vert),
                                                splashRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        //Configuration buttons
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0.0, 10.0, 0.0),
                          child: Column(
                            children: [
                              ListTile(
                                splashColor: Theme.of(context).primaryColor,
                                onTap: () async {
                                  await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => changeAllowedUnis(allowedUnis: allowedUnis, groupId: groupId,)
                                  );
                                },
                                title: Text(
                                  "add-allowed-unis".tr,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              ListTile(
                                splashColor: Theme.of(context).primaryColor,
                                onTap: () async {
                                  await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) => GroupExpand(
                                        id: groupId,
                                        groupName: groupName,
                                        groupPicture: groupPicture,
                                        members: memberDetails.map((item) => item["Id"] as String).toList(),
                                        avgCleanliness: avgCleanliness,
                                        avgNoisiness: avgNoisiness,
                                        avgNightLife: avgNightLife,
                                        avgBedTime: avgBedTime,
                                        avgYearOfStudy: avgYearOfStudy,
                                      )
                                  );
                                },
                                title: Text(
                                  "preview".tr,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              ListTile(
                                splashColor: Theme.of(context).primaryColor,
                                onTap: () async {
                                  await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) => EditGroupName(
                                        name: groupName, groupId: groupId),
                                  );
                                },
                                title: Text(
                                  "edit_groupname".tr,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              ListTile(
                                splashColor: Theme.of(context).primaryColor,
                                onTap: () async {
                                  await showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) => ConfirmLeave(
                                      groupId: groupId,
                                      memCount: memberDetails.length,
                                      userId: Auth().currentUser(),
                                    ),
                                  );
                                },
                                title: Text(
                                  "leave_group".tr,
                                  style: GoogleFonts.roboto(
                                      color: Colors.red, fontSize: 16.5),
                                ),
                              ),
                            ],
                          ),
                        ),
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