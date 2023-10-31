import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/Pages/Scroller.dart';
import 'package:movein/Scroller%20Code/HScroll.dart';
import 'package:movein/Pages/Sendbird.dart' ;


import 'dart:io';
import 'package:azstore/azstore.dart' as AzureStorage;
import 'package:uuid/uuid.dart';
//import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:movein/UserPreferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:image_cropper/image_cropper.dart';
import '../Auth code/auth.dart';
import '../Pages/Friends.dart';
import 'GroupFunctions.dart';

String rootImagepath = 'https://movein.blob.core.windows.net/moveingroupimages/';
String rootImageProfilePath = 'https://movein.blob.core.windows.net/moveinimages/';

Future<List<Map<String, dynamic>>> getUserJoinedGroups(userId, inviteeId) async {
  try {
    final usersCollectionRef = FirebaseFirestore.instance.collection('Users');
    final userDocRef = usersCollectionRef.doc(userId);

    final userSnapshot = await userDocRef.get();
    final joinedGroups = userSnapshot.data()?['Joined'] as List<dynamic>;

    final groupsCollectionRef = FirebaseFirestore.instance.collection('Groups');

    final List<Map<String, dynamic>> result = [];

    for (var groupId in joinedGroups) {
      final groupDoc = await groupsCollectionRef.doc(groupId).get();

      if (groupDoc.exists) {
        final groupData = groupDoc.data();
        final groupName = groupData?['GroupName'] as String;
        final memberIds = groupData?['Members'] as List<dynamic>;
        final groupPicture = groupData?['GroupPicture'] as String;
        final documentId = groupDoc.id;

        if (!memberIds.contains(inviteeId)) {
          final List<String> memberForeNames = [];
          for (var memberId in memberIds) {
            final memberDoc = await usersCollectionRef.doc(memberId).get();
            final memberForeName = memberDoc.data()?['ForeName'] as String;
            memberForeNames.add(memberForeName);
          }

          result.add({
            'GroupName': groupName,
            "GroupPicture": groupPicture,
            'Members': memberForeNames,
            'Id': documentId,
          });
        }
      }
    }

    return result;
  } catch (e) {
    throw FirebaseException(
      message: 'Error getting groups for invite: $e',
      plugin: 'cloud_firestore',
    );
  }
}


class GroupInvite extends StatelessWidget {
  final String inviteeId;
  final String userId;
  const GroupInvite({
    Key? key,
    required this.inviteeId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: getUserJoinedGroups(userId, inviteeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the data to load, you can show a loading indicator
          return const Center(
            child: FractionallySizedBox(
              heightFactor: 0.3,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<dynamic> data = snapshot.data!;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            backgroundColor: Theme.of(context).canvasColor,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              width: MediaQuery.of(context).size.width * 0.6,
              child: Stack(
                children: [
                  Positioned(
                    top: 1,
                    right: 1,
                    child: IconButton(
                      splashRadius: 5,
                      icon: Icon(LineAwesomeIcons.times_circle, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                          child: Text("invite_to_group".tr, style: Theme.of(context).textTheme.headlineSmall)
                      ),
                      const Divider(),
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: SizedBox(
                          width: double.maxFinite,
                          height: MediaQuery.of(context).size.height,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.6))), // Add a bottom border
                                ),
                                child: ListTile(
                                  leading: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: data[index]['GroupPicture'] == '' ? Image.network('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : Image.network('${rootImagepath + data[index]["GroupPicture"]}.jpg'),
                                    ),
                                  ),
                                  title: Text(data[index]['GroupName'], style: Theme.of(context).textTheme.bodyMedium),
                                  subtitle: Text(
                                    data[index]?["Members"]!.join(', '),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  onTap: () {
                                    inviteFriendToGroup(inviteeId, data[index]?["Id"], userId);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );

                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      }
    );
  }
}

class ConfirmDel extends StatelessWidget {
  final String friendId;
  final String userId;
  const ConfirmDel({
    Key? key,
    required this.friendId,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      backgroundColor: Theme.of(context).canvasColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.3,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("friend-del-desc".tr, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("cancel".tr, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        removeFriend(friendId, userId).then((_){
                          Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Friends(), duration: const Duration(milliseconds: 400)));
                        });

                      },
                      child: Text("confirm".tr, style: Theme.of(context).textTheme.bodyMedium)
                  ),
                ),

              ],
            )
          ],
        ),
      ),

    );
  }
}

Future<void> removeFriend(String friendId, String userId) async{
  final userRef = FirebaseFirestore.instance.collection('Users').doc(userId);
  final friendRef = FirebaseFirestore.instance.collection('Users').doc(friendId);


  try {
        await userRef.update({'Friends': FieldValue.arrayRemove([friendId])});
        await friendRef.update({'Friends': FieldValue.arrayRemove([userId])});
  } catch (e) {
    throw FirebaseException(message: 'Error removing friend: $e', plugin: 'cloud_firestore');
  }
}

Future<void> inviteFriendToGroup(String friendId, String groupId, userId) async {
  try {
    final DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    final DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(friendId);

    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await groupRef.get() as DocumentSnapshot<Map<String, dynamic>>;
    final List<String> members = List<String>.from(groupSnapshot.data()!['Members']);

    if (!members.contains(friendId)) {
      await userRef.update({'GroupInvites': FieldValue.arrayUnion([groupId])});
    }

  } catch (e) {
    throw FirebaseException(message: 'Error Inviting friend: $e', plugin: 'cloud_firestore');
  }
}

class GroupExpand extends StatelessWidget {
  final String id;
  final String groupName;
  final String groupPicture;
  final dynamic members;
  final double avgCleanliness;
  final double avgNoisiness;
  final double avgNightLife;
  final double avgYearOfStudy;
  final Timestamp avgBedTime;

  const GroupExpand({
    Key? key,
    required this.id,
    required this.groupName,
    required this.groupPicture,
    required this.members,
    required this.avgCleanliness,
    required this.avgNoisiness,
    required this.avgNightLife,
    required this.avgYearOfStudy,
    required this.avgBedTime,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          //padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Stack(
            children: [
              SizedBox(
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: SingleChildScrollView(child: Gscroller(groupName: groupName, groupPicture: groupPicture, members: members, avgCleanliness: avgCleanliness, avgNoisiness: avgNoisiness, avgNightLife: avgNightLife, avgBedTime: avgBedTime, avgYearOfStudy: avgYearOfStudy,))
                ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  splashRadius: 20,
                  icon: const Icon(LineAwesomeIcons.times_circle),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),

              ),
            ],
          ),
        ),
    );
  }
}

Future<void> joinGroup(String groupId, String userId) async {
  try {
    final CollectionReference usersCollection = FirebaseFirestore.instance.collection('Users');
    final DocumentReference userDoc = usersCollection.doc(userId);

    // Update user's "Applications" and remove from "GroupInvites"
    await userDoc.update({
      'Applications': FieldValue.arrayUnion([groupId]),
      'GroupInvites': FieldValue.arrayRemove([groupId]),
      'Joined' : FieldValue.arrayUnion([groupId]),
    });

    final CollectionReference groupsCollection = FirebaseFirestore.instance.collection('Groups');
    final DocumentReference groupDoc = groupsCollection.doc(groupId);

    // Get the group document to access the average fields
    final DocumentSnapshot groupSnapshot = await groupDoc.get();

    // Get the group size from the 'Members' array field
    final List<dynamic> members = groupSnapshot.get('Members');
    int groupSize = members.length;

    // Calculate the new average values
    double avgCleanliness = groupSnapshot.get('AvgCleanliness');
    double avgNightLife = groupSnapshot.get('AvgNightLife');
    double avgNoisiness = groupSnapshot.get('AvgNoisiness');
    DateTime avgBedTime = groupSnapshot.get('AvgBedTime').toDate();

    // Get the user document of the current user
    final DocumentSnapshot userSnapshot = await userDoc.get();

    // Get the 'Preferences' map field from the user document
    final Map<String, dynamic> prefs = userSnapshot.get('Preferences');

    // Get the corresponding fields from the user document
    double userCleanliness = prefs['Cleanliness'];
    double userNightLife = prefs['NightLife'];
    double userNoisiness = prefs['Noisiness'];
    DateTime userBedTime = prefs['BedTime'].toDate();

    // Calculate the new average values after adding the user to the group
    avgCleanliness = (avgCleanliness * groupSize + userCleanliness) / (groupSize + 1);
    avgNightLife = (avgNightLife * groupSize + userNightLife) / (groupSize + 1);
    avgNoisiness = (avgNoisiness * groupSize + userNoisiness) / (groupSize + 1);

    // Calculate the new average bed time after adding the user to the group
    int totalBedTimeInMilliseconds = avgBedTime.millisecondsSinceEpoch * groupSize;
    totalBedTimeInMilliseconds += userBedTime.millisecondsSinceEpoch;
    avgBedTime = DateTime.fromMillisecondsSinceEpoch(totalBedTimeInMilliseconds ~/ (groupSize + 1));

    // Convert the average bedtime back to a Timestamp format
    final Timestamp avgBedTimeTimestamp = Timestamp.fromDate(avgBedTime);

    // Update the group document with the new average values and add the user to the 'Members' array
    await groupDoc.update({
      'AvgCleanliness': avgCleanliness,
      'AvgNightLife': avgNightLife,
      'AvgNoisiness': avgNoisiness,
      'AvgBedTime': avgBedTimeTimestamp,
      'Members': FieldValue.arrayUnion([userId]),
    });
  } catch (e) {
    throw FirebaseException(
      message: 'Error joining group: $e',
      plugin: 'cloud_firestore',
    );
  }
}


Future<void> removeGroupInvite(String groupId, userId) async {
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('Users');
  final DocumentReference userDoc = usersCollection.doc(userId);

  // Remove groupId from GroupInvites field
  await userDoc.update({
    'GroupInvites': FieldValue.arrayRemove([groupId]),
  });
}

Future<void> addFriend(String inviteId, userId) async {
  // Access the "Users" collection
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');
  final CollectionReference dmCollection =
  FirebaseFirestore.instance.collection('DirectMessages');

  String dmId = DMIdGen(userId, inviteId);

  Map<String, dynamic> dmData = {
    'Members': [userId, inviteId],
    'Read': [Auth().currentUser()]
  };

  try {
    // Use set with merge option to only create the document if it doesn't exist
    await dmCollection.doc(dmId).set(dmData, SetOptions(merge: true));
  } catch (e) {
    throw FirebaseException(
        plugin: 'cloud_firestore', message: "Firebase error with code: $e");
  }

  // Perform array union on the "Friends" field of inviteId document
  await usersCollection
      .doc(inviteId)
      .update({'Friends': FieldValue.arrayUnion([userId])});

  // Perform array union on the "Friends" field of userId document
  await usersCollection
      .doc(userId)
      .update({'Friends': FieldValue.arrayUnion([inviteId])});

  removeFriendInvite(inviteId, userId);
}


Future<void> removeFriendInvite(String inviteId, userId) async {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');

  try {
    // Remove inviteId from FriendInvites field in the user's document
    await usersCollection
        .doc(userId)
        .update({'FriendInvites': FieldValue.arrayRemove([inviteId])});

    // Remove userId from OutgoingFriendInvites field in the invitee's document
    await usersCollection
        .doc(inviteId)
        .update({'OutgoingFriendInvites': FieldValue.arrayRemove([userId])});

    // Success!
  } catch (e) {
    // Error occurred
    throw FirebaseException(
        message: 'Error removing friend invite: $e',
        plugin: 'cloud_firestore');
  }
}

Future<void> removeOutFriendInvite(String inviteId, userId) async {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');

  try {
    // Remove inviteId from FriendInvites field in the user's document
    await usersCollection
        .doc(inviteId)
        .update({'FriendInvites': FieldValue.arrayRemove([userId])});

    // Remove userId from OutgoingFriendInvites field in the invitee's document
    await usersCollection
        .doc(userId)
        .update({'OutgoingFriendInvites': FieldValue.arrayRemove([inviteId])});

    // Success!
  } catch (e) {
    // Error occurred
    throw FirebaseException(
        message: 'Error removing friend invite: $e',
        plugin: 'cloud_firestore');
  }
}

Future<void> sendFriendInvite(String invitee, userId) async {
  try {
    final CollectionReference usersCollection = FirebaseFirestore.instance.collection('Users');

    // Get the user document of the invitee
    DocumentSnapshot inviteeSnapshot = await usersCollection.doc(invitee).get();

    // Check if the invitee document exists
    if (inviteeSnapshot.exists) {
      DocumentSnapshot userSnapshot = await usersCollection.doc(userId).get();
      List<dynamic> friendList = userSnapshot.get('Friends');
      if (!friendList.contains(invitee)) {
        await usersCollection.doc(invitee).update({
          'FriendInvites': FieldValue.arrayUnion([userId])
        });

        // Update OutgoingFriendInvites field in the user's document
        await usersCollection.doc(userId).update({
          'OutgoingFriendInvites': FieldValue.arrayUnion([invitee])
        });
      }
    }
  } catch (e) {
    // Error occurred
    throw FirebaseException(message: 'Error sending friend invite: $e', plugin: 'cloud_firestore');
  }
}

class ConfirmGroupDel extends StatelessWidget {
  final String groupId;
  final String groupType;
  final String userId;
  const ConfirmGroupDel({
    Key? key,
    required this.groupId,
    required this.groupType,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.3,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("confirm-group-del".tr, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("cancel".tr, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        removeGroupFromUser(groupType, groupId, userId).then((_){
                          Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Friends(), duration: const Duration(milliseconds: 400)));
                        });

                      },
                      child: Text("confirm".tr, style: Theme.of(context).textTheme.bodyMedium)
                  ),
                ),

              ],
            )
          ],
        ),
      ),

    );
  }
}

Future<void> removeGroupFromUser(String groupType, String groupId, userId) async {
  try {
    final DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(userId);
    final DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);

    await userRef.update({
      groupType: FieldValue.arrayRemove([groupId]),
      "BlockedGroups": FieldValue.arrayRemove([groupId]),
    });

      final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await groupRef.get() as DocumentSnapshot<Map<String, dynamic>>;
      await groupRef.update({
        'BlackList': FieldValue.arrayRemove([userId]), // Update the AppVals map without the removed key
      });
    if (groupType == "Applications") {
      final appVals = groupSnapshot.data()?['AppVals'];
      if (appVals != null && appVals.containsKey(userId)) {
        appVals.remove(userId); // Remove the key-value pair from the map

        await groupRef.update({
          'BlackList': FieldValue.arrayRemove([userId]),
          'Applicants': FieldValue.arrayRemove([userId]),
          'AppVals': appVals, // Update the AppVals map without the removed key
        });
      }
    }
  } catch (e) {
    throw FirebaseException(
      message: 'Error removing group from user: $e',
      plugin: 'cloud_firestore',
    );
  }
}


class CreateGroupForm extends StatefulWidget {
  final String userId;
  const CreateGroupForm({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<CreateGroupForm> {
  String? currentGroupImage = '';
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  final TextEditingController _groupNameController = TextEditingController(text: "GroupName");
  File? _selectedImage;

  Future<void> _submitForm(int appsMax, String? groupImageString) async {
    if (_formKey.currentState!.validate()) {
      final String groupName = _groupNameController.text;
      final CollectionReference groupsCollection = FirebaseFirestore.instance.collection('Groups');
      final DocumentReference userDocument = FirebaseFirestore.instance.collection('Users').doc(widget.userId);
      final DocumentSnapshot userSnapshot = await userDocument.get();
      final Map<String,dynamic> prefs = userSnapshot.get('Preferences');
      List<String> allowedUnis = [userSnapshot.get('UniAttended')];
      Map<String, dynamic> appVals = {};
      List<String> applicants = [];
      var avgBedTime = prefs['Lights Out'];
      int avgCleanliness = prefs['Cleanliness'].toInt();
      int avgNightLife = prefs['NightLife'].toInt();
      int avgNoisiness = prefs['Noisiness'].toInt();
      List<String> blackList = [widget.userId];
      List<String> invitees = [];
      Map<String, dynamic> kickVals = {};
      List<String> kicks = [];
      List<String> members = [widget.userId];
      Map<String,dynamic> groupDoc = {
        'AllowedUnis': allowedUnis,
        'AppVals': appVals,
        'Applicants': applicants,
        'AvgBedTime': avgBedTime,
        'AvgCleanliness': avgCleanliness,
        'AvgNightLife': avgNightLife,
        'AvgNoisiness': avgNoisiness,
        'AvgYearOfStudy': userSnapshot.get('YearOfStudy'),
        'BlackList': blackList,
        'GroupName': groupName,
        'GroupPicture': groupImageString,
        'Invitees': invitees,
        'KickVals': kickVals,
        'Kicks': kicks,
        'Members': members,
        'Read': [Auth().currentUser()],
      };
      final newGroupDocument = await groupsCollection.add(groupDoc);
      await userDocument.update({
        'Joined': FieldValue.arrayUnion([newGroupDocument.id]),
      });
      var newChannel = ConnectSendbird().createChannel(widget.userId, groupName, null , newGroupDocument.id);

      // uploads image to azure after successful creation of group
      _uploadImageToAzure(_selectedImage, groupImageString);      

      List<dynamic> joinedGroups = userSnapshot.get('Joined');

      // Check if the user has joined the maximum number of groups
      if (joinedGroups.length >= appsMax) {
        // Call maxGroupsReached if the condition is met
        await maxGroupsReached(widget.userId);
      }
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

  Future<void> _uploadImageToAzure(File? imageFile, String? imageName) async {
    Uint8List bytes = imageFile!.readAsBytesSync();
    var x = AzureStorage.AzureStorage.parse(
        'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net');
    try {
      await x.putBlob('/moveingroupimages/$imageName.jpg',contentType: 'image/jpg', bodyBytes: bytes);
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.35,
              height: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20), // Sets the radius for the left corner
                    right: Radius.circular(20), // Sets the radius for the right corner
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(width: MediaQuery.of(context).size.width,child: Text('create_group'.tr, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.start,),),
            Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
              onChanged: () {
                setState(() {
                  _isButtonEnabled = _formKey.currentState?.validate() ?? false;
                });
              },
              child: Column(
                children: [
                  TextFormField(
                    controller: _groupNameController,
                    maxLength: 15,
                    autocorrect: false,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'change_groupname'.tr,
                    ),
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'groupname-null'.tr;
                      }
                      return null;
                    },
                    onTap: () {
                      // Select the whole text when tapped
                      _groupNameController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _groupNameController.text.length,
                      );
                    },
                  ),
                  GestureDetector(
                    // Azure upload goes here - Billy
                    onTap: () async {
                      final pickedImage = await pickImage();
                      if (pickedImage!= null) {
                        var uuid = const Uuid();
                        String uniqueID = uuid.v1();
                        currentGroupImage = uniqueID;
                        setState(() {
                          _selectedImage = pickedImage;
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonEnabled
                  ? () async {
                if (_formKey.currentState?.validate() ?? false) {
                  await _submitForm(UserPreferences.getAppsMax(), currentGroupImage).then((value) => Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Friends(), duration: const Duration(milliseconds: 400))));
                }
              }
                  : null,
              child: Text('submit'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class SendFriendInvite extends StatefulWidget {
  final String userId;
  const SendFriendInvite({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SendFriendInvite> createState() => _SendFriendInviteState();
}

class _SendFriendInviteState extends State<SendFriendInvite> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }
  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.3,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('add-by-id'.tr, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            Text('find-id'.tr, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),

            Form(
              autovalidateMode: AutovalidateMode.always,
              key: formKey,
              onChanged: () {
                setState(() {
                  _isButtonEnabled = formKey.currentState?.validate() ?? false;
                });
              },
              child: TextFormField(
                controller: _textEditingController,
                maxLength: 28,
                autocorrect: false,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: 'enter-friend-id'.tr,
                ),
                validator: (value) {
                  if (value?.length != 28) {
                  return 'friend-id-length'.tr;
                  }
                  return null;
                },
                onTap: () {
                  // Select the whole text when tapped
                  _textEditingController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _textEditingController.text.length,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("cancel".tr, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled ?  () {
                      if (formKey.currentState!.validate()) {
                        final String inviteeId = _textEditingController.text;
                        sendFriendInvite(inviteeId, widget.userId).then((value) => Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Friends(), duration: const Duration(milliseconds: 400))));
                      }
                    } : null,
                    child: Text("confirm".tr, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),

              ],
            )
          ],
        ),
      ),
    );
  }
}

class changeAllowedUnis extends StatefulWidget {
  final List<dynamic> allowedUnis;
  final String groupId;
  const changeAllowedUnis({
    Key? key,
    required this.allowedUnis,
    required this.groupId,
  }) : super(key: key);

  @override
  State<changeAllowedUnis> createState() => _changeAllowedUnisState();
}

class _changeAllowedUnisState extends State<changeAllowedUnis> {
  final _universityController = TextEditingController();
  late List<dynamic> universitiesData;
  late List<dynamic> allowedUnis;
  late List<dynamic> universitiesSuggestions;
  bool _loadDialog = false;
  bool _universityValid = false;

  @override
  void initState() {
    super.initState();
    allowedUnis = widget.allowedUnis;
    fetchJSON();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        //padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: !_loadDialog ? Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              child: const CircularProgressIndicator()
          ),
        )
            : Stack(
          children: [
            SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.9,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TypeAheadFormField(
                      textFieldConfiguration: TextFieldConfiguration(
                        decoration: const InputDecoration(
                          labelText: 'Add University',
                        ),
                        controller: _universityController,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a university';
                        }
                        final universitiesSuggestions =
                        universitiesData
                            .map((university) =>
                        university['name'])
                            .toList();

                        if (!universitiesSuggestions
                            .contains(value)) {
                          return 'Please select a valid university from the suggestions';
                        }
                        return null;
                      },
                      suggestionsCallback: (pattern) {
                        // Return filtered universities based on the pattern
                        return universitiesData
                            .where((university) => university['name']
                            .toLowerCase()
                            .contains(pattern.toLowerCase()))
                            .map((university) => university['name'])
                            .toList();
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (value) async {
                        if (_validateUniversity(value)){
                          await addUniToAllowedUnis(value);
                          allowedUnis.add(value);
                        }
                        _universityController.text = value;
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allowedUnis.length,
                        itemBuilder: (context, index) {
                          final allowedUni = allowedUnis[index];
                          return ListTile(
                            title: Text(allowedUni),
                            trailing: (index == 0)? const Text(""): IconButton(
                              icon: const Icon(LineAwesomeIcons.times, color: Colors.grey,),
                              onPressed: () async{
                                if (allowedUnis.length > 1){
                                  await removeUniFromAllowedUnis(allowedUni);
                                  setState(() {
                                    allowedUnis.remove(allowedUni);
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                splashRadius: 20,
                icon: const Icon(LineAwesomeIcons.times_circle),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),

            ),
          ],
        ),
      ),
    );
  }
  Future<void> fetchJSON() async {
    final String jsonContent = await rootBundle
        .loadString('assets/JSON/world_universities_and_domains.json');
    universitiesData = json.decode(jsonContent);
    universitiesSuggestions = universitiesData.map((university) => university['name']).toList();
    setState(() {
      _loadDialog = true;
    });
  }

  bool _validateUniversity(selectedUniversity) {
    bool temp = true;

    if (!universitiesSuggestions.contains(selectedUniversity)) {
      temp = false;
    }
    return temp;
  }

  Future<void> addUniToAllowedUnis(String university) async {
    final groupsCollectionRef = FirebaseFirestore.instance.collection('Groups');
    final groupDocRef = groupsCollectionRef.doc(widget.groupId);

    await groupDocRef.update({
      'AllowedUnis': FieldValue.arrayUnion([university]),
    });
  }

  Future<void> removeUniFromAllowedUnis(String university) async {
    final groupsCollectionRef = FirebaseFirestore.instance.collection('Groups');
    final groupDocRef = groupsCollectionRef.doc(widget.groupId);

    await groupDocRef.update({
      'AllowedUnis': FieldValue.arrayRemove([university]),
    });
  }
}


Future<void> maxGroupsReached(String userId) async {
  final usersCollectionRef = FirebaseFirestore.instance.collection('Users');
  final userDocRef = usersCollectionRef.doc(userId);

  final DocumentSnapshot userSnapshot = await userDocRef.get();

  List<dynamic> applications = userSnapshot.get('Applications');
  List<dynamic> blockedGroups = userSnapshot.get('BlockedGroups');
  List<dynamic> shortList = userSnapshot.get('ShortList');
  for (var id in applications){
    await removeGroupFromUser("Applications", id, userId);
    await addToShortList(id);
  }

  await userDocRef.update({
    'ShortList': shortList,
    'BlockedGroups': blockedGroups,
    'Applications': FieldValue.arrayRemove(applications),
  });
}
