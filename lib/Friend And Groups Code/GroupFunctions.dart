import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:movein/Friend%20And%20Groups%20Code/FriendFunctions.dart';
import 'package:movein/Pages/Sendbird.dart';
import 'package:movein/UserPreferences.dart';
import 'package:page_transition/page_transition.dart';

import '../Pages/Friends.dart';


Future<void> updateGroupName(String newName, String groupId) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection('Groups');
    final documentRef = collectionRef.doc(groupId);

    await documentRef.update({
      'GroupName': newName,
    });

  } catch (e) {
    throw FirebaseException(
      message: 'Error updating group Name: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> updateGroupImage(String newImageName, String groupID) async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection('Groups');
    final documentRef = collectionRef.doc(groupID);

    await documentRef.update({
      'GroupPicture': newImageName
    });
  } catch (e) {
    throw FirebaseException(
      message: 'Error updating group Name: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> removeFromGroupAndUser(String groupId, String userId) async {

  try {
    final groupsCollectionRef = FirebaseFirestore.instance.collection('Groups');
    final groupDocRef = groupsCollectionRef.doc(groupId);
    groupDocRef.update({
      "Members" : FieldValue.arrayRemove([userId]),
    });

    final usersCollectionRef = FirebaseFirestore.instance.collection('Users');
    final userDocRef = usersCollectionRef.doc(userId);
    userDocRef.update({
      "Joined": FieldValue.arrayRemove([groupId]),
    });

    final DocumentSnapshot groupSnapshot = await groupDocRef.get();
    final List<dynamic> members = groupSnapshot.get('Members');
    int groupSize = members.length;

    if (groupSize == 0) {
      await groupDocRef.delete();
    } else {
// Calculate the new average values
      double avgCleanliness = groupSnapshot.get('AvgCleanliness').toDouble();
      double avgNightLife = groupSnapshot.get('AvgNightLife').toDouble();
      double avgNoisiness = groupSnapshot.get('AvgNoisiness').toDouble();
      DateTime avgBedTime = groupSnapshot.get('AvgBedTime').toDate();
      double avgYearOfStudy = groupSnapshot.get('AvgYearOfStudy');

// Get the user document of the current user
      final usersCollectionRef = FirebaseFirestore.instance.collection('Users');
      final userDocRef = usersCollectionRef.doc(userId);
      final DocumentSnapshot userSnapshot = await userDocRef.get();

// Get the 'Preferences' map field from the user document
      final Map<String, dynamic> prefs = userSnapshot.get('Preferences');

// Get the corresponding fields from the user document
      double userCleanliness = prefs['Cleanliness'];
      double userNightLife = prefs['NightLife'];
      double userNoisiness = prefs['Noisiness'];
      int userYearOfStudy = prefs['YearOfStudy'];

// Calculate the new average values after removing the user from the group
      avgCleanliness = (avgCleanliness * groupSize - userCleanliness) / (groupSize - 1);
      avgNightLife = (avgNightLife * groupSize - userNightLife) / (groupSize - 1);
      avgNoisiness = (avgNoisiness * groupSize - userNoisiness) / (groupSize - 1);
      avgYearOfStudy = (avgYearOfStudy * groupSize - userYearOfStudy) / (groupSize - 1);

// Calculate the new average bed time after removing the user from the group
      int totalBedTimeInMilliseconds = 0;
      int totalYearOfStudy = 0;

      for (String memberId in members) {
          final DocumentSnapshot memberSnapshot = await usersCollectionRef.doc(memberId).get();
          final Map<String, dynamic> memberPrefs = memberSnapshot.get('Preferences');
          DateTime memberBedTime = memberPrefs['Lights Out'].toDate();
          totalBedTimeInMilliseconds += memberBedTime.millisecondsSinceEpoch;

          int memberYearOfStudy = memberPrefs['YearOfStudy'];
          totalYearOfStudy += memberYearOfStudy;
      }

      avgBedTime = DateTime.fromMillisecondsSinceEpoch(totalBedTimeInMilliseconds ~/ (groupSize - 1));
      final Timestamp avgBedTimeTimestamp = Timestamp.fromDate(avgBedTime);

      avgYearOfStudy = totalYearOfStudy / (groupSize - 1);

// Update the group document with the new average values and remove the user from the 'Members' array
      await groupDocRef.update({
        'AvgCleanliness': avgCleanliness,
        'AvgNightLife': avgNightLife,
        'AvgNoisiness': avgNoisiness,
        'AvgBedTime': avgBedTimeTimestamp,
        'AvgYearOfStudy': avgYearOfStudy,
        'Members': FieldValue.arrayRemove([userId]),
        'BlackList' : FieldValue.arrayRemove([userId]),
      });

    }
  } catch (e) {
    throw FirebaseException(
      message: 'Error leaving group: $e',
      plugin: 'cloud_firestore',
    );
  }
}

class EditGroupName extends StatefulWidget {
  final String name;
  final String groupId;
  const EditGroupName({
    Key? key,
    required this.name,
    required this.groupId,
  }) : super(key: key);

  @override
  State<EditGroupName> createState() => _EditGroupNameState();
}

class _EditGroupNameState extends State<EditGroupName> {
  late final TextEditingController _textEditingController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.name);
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Form(
                autovalidateMode: AutovalidateMode.always,
                key: formKey,
                onChanged: () {
                  setState(() {
                    _isButtonEnabled = formKey.currentState?.validate() ?? false;
                  });
                },
                child: TextFormField(
                  controller: _textEditingController,
                  maxLength: 15,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'Change Group name',
                  ),
                  validator: (value) {
                    if (value!.trim().isEmpty) {
                      return 'Group name must exist';
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
                        final String newName = _textEditingController.text;
                        updateGroupName(newName, widget.groupId).then((value) => Navigator.of(context).pop());
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

class ConfirmLeave extends StatelessWidget {
  final String groupId;
  final int memCount;
  final String userId;
  const ConfirmLeave({
    Key? key,
    required this.groupId,
    required this.memCount,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Text('leave_title'.tr, style: Theme.of(context).textTheme.bodyLarge,),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('leave_desc'.tr, style: Theme.of(context).textTheme.bodySmall,),
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
                      onPressed: () {
                        ConnectSendbird().leaveChannel(userId, groupId);
                        removeFromGroupAndUser(groupId, userId).then((_) {
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

Future<void> startKickVote(String kickId, String groupId, userId) async {
  try {
    final CollectionReference groupsCollection =
    FirebaseFirestore.instance.collection('Groups');

    // Access the group's document
    final DocumentReference groupDocRef = groupsCollection.doc(groupId);

    // Update Kicks field in the group's document
    await groupDocRef.update({
      'Kicks': FieldValue.arrayUnion([kickId]),
    });
    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(groupId).get();
    final Map<String, dynamic>? kickVals = groupSnapshot.data()?['KickVals'];

    if (kickVals != null) {
      // Update the KickVals field with the new key-value pair
      kickVals[kickId] = {userId: 1};
      await groupDocRef.update({'KickVals': kickVals});
    }

  } catch (e) {
    throw FirebaseException(
      message: 'Error kicking user: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> isKickVotesThresholdReached(String groupId, String kickId, int groupSize) async {
  try {
    final DocumentReference groupRef =
    FirebaseFirestore.instance.collection('Groups').doc(groupId);

    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(groupId).get();


    final Map<String, dynamic>? kickVals = groupSnapshot.data()?['KickVals'];

    if (kickVals != null && kickVals.containsKey(kickId)) {
      final Map<String, dynamic>? kickVotes =
      kickVals[kickId] as Map<String, dynamic>?;

      if (kickVotes != null) {
        int posSum = 0;
        int negSum = 0;
        kickVotes.forEach((key, value) {
          if (value is int) {
            if (value > 0) {
              posSum += value;
            } else {
              negSum += value;
            }
          }
        });

        if ((posSum > groupSize / 2) | (negSum.abs() >= groupSize / 2)) {
          if (posSum > groupSize / 2) {
            await removeFromGroupAndUser(groupId, kickId);
            await groupRef.update({
              'BlackList': FieldValue.arrayRemove([kickId])
            });
          }
          // Remove kickId from 'Kicks' array field
          await groupRef.update({
            'Kicks': FieldValue.arrayRemove([kickId])
          });

          // Remove key-value pair with key kickId from 'KickVals' map field
          kickVals.remove(kickId);
          await groupRef.update({'KickVals': kickVals});
          // Remove kickId from 'Kicks' array field
        }
      }
    }
  } catch (e) {
    // Error occurred
    throw FirebaseException(
      message: 'Error checking kick votes threshold: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> updateKickVote(String groupId, bool agree, String kickId, int groupSize, userId) async {
  try {
    final DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(groupId).get();
    final kickVals = groupSnapshot.data()?['KickVals'];


    if (kickVals != null && kickVals.containsKey(kickId)) {
      final Map<String, dynamic>? kickVotes = kickVals[kickId] as Map<String, dynamic>?;

      if (kickVotes != null) {
        int vote = agree ? 1 : -1;
        kickVotes[userId] = vote;

        await groupRef.update({'KickVals.$kickId': kickVotes});
      }
    }
    await isKickVotesThresholdReached(groupId,kickId,groupSize);
  } catch (e) {
    throw FirebaseException(
      message: 'Error updating kick vote: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> isAppVotesThresholdReached(String groupId, String appId, int groupSize) async {
  try {
    final DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    final DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(appId);

    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(groupId).get();
    final Map<String, dynamic>? appVals = groupSnapshot.data()?['AppVals'];

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(appId).get();
    final List<dynamic> joined = userSnapshot.data()?['Joined'];
    final int length = joined.length;
    if (appVals != null && appVals.containsKey(appId)) {
      final Map<String, dynamic>? appVotes = appVals[appId] as Map<String, dynamic>?;

      if (appVotes != null) {
        int posSum = 0;
        int negSum = 0;
        appVotes.forEach((key, value) {
          if (value is int) {
            if (value > 0) {
              posSum += value;
            } else {
              negSum += value;
            }
          }
        });

        if ((posSum > groupSize / 2) | (negSum.abs() >= groupSize / 2)) {
          appVals.remove(appId);
          await groupRef.update({
            'AppVals': appVals,
            'Applicants': FieldValue.arrayRemove([appId]),
          });
          await userRef.update({
            'Applications': FieldValue.arrayRemove([groupId]),
          });
          if (posSum > groupSize / 2) {
            await groupRef.update({
              'Members': FieldValue.arrayUnion([appId]),
              'BlackList': FieldValue.arrayUnion([appId])
            });
            await userRef.update({
              'Joined': FieldValue.arrayUnion([groupId]),
            });
            if(length+1 == UserPreferences.getAppsMax()){
              await maxGroupsReached(appId);
            }
          } else{
            await groupRef.update({
              'BlackList': FieldValue.arrayRemove([appId])
            });
          }
        }
      }
    }

  } catch (e) {
    // Error occurred
    throw FirebaseException(
      message: 'Error checking application votes threshold: $e',
      plugin: 'cloud_firestore',
    );
  }
}

Future<void> updateApplicationVote(String groupId, bool agree, String appId, int groupSize, userId) async {
  try {
    final DocumentReference groupRef = FirebaseFirestore.instance.collection('Groups').doc(groupId);
    final DocumentSnapshot<Map<String, dynamic>> groupSnapshot = await FirebaseFirestore.instance.collection('Groups').doc(groupId).get();
    final appVals = groupSnapshot.data()?['AppVals'];


    if (appVals != null && appVals.containsKey(appId)) {
      final Map<String, dynamic>? appVotes = appVals[appId] as Map<String, dynamic>?;

      if (appVotes != null) {
        int vote = agree ? 1 : -1;
        appVotes[userId] = vote;

        await groupRef.update({'AppVals.$appId': appVotes});
      }
    }
    await isAppVotesThresholdReached(groupId,appId,groupSize);
  } catch (e) {
    throw FirebaseException(
      message: 'Error updating kick vote: $e',
      plugin: 'cloud_firestore',
    );
  }
}
