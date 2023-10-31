import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/UserPreferences.dart';
import 'package:movein/navbar.dart';
import 'package:movein/Friend%20And%20Groups%20Code/FriendFunctions.dart';
import 'package:movein/Scroller%20Code/swipe_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:movein/Pages/Scroller.dart';
import 'package:movein/Pages/Messages.dart' as mb;
import 'package:page_transition/page_transition.dart';
import 'package:http/http.dart' as http;
import '../Auth code/auth.dart';
import '../Themes/lMode.dart';
import '../main.dart';
import 'GroupOptions.dart';
import 'Messages.dart';
import 'Profile.dart';

class Friends extends StatefulWidget {
  const Friends({Key? key}) : super(key: key);

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  late List<dynamic> friends;
  late List<dynamic> searchResults;
  late List<dynamic> groupInvites;
  late List<dynamic> groupSearchResults;
  late List<dynamic> blockedGroups;
  late List<dynamic> blockedSearchResults;
  late List<dynamic> friendInvites;
  late List<dynamic> friendSearchResults;
  late List<dynamic> outgoingFriendInvites;
  List<dynamic> outgoingFriendInvitesResults = [];
  late List<dynamic> joined;
  late List<dynamic> joinedResults;
  late List<dynamic> applications;
  late List<dynamic> applicationsResults;
  late List<dynamic> shortList;
  late List<dynamic> shortListResults;
  late bool isSearchLoading;
  bool isLoading = true;
  late List<dynamic> fSSearchResults;
  bool loadExtra = false;
  String searchText = "";
  final appsMax = UserPreferences.getAppsMax();

  int stampToYear(var dateTime) {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(dateTime);
    final yearsAgo = difference.inDays ~/ 365;
    return yearsAgo;
  }

  final imageURL = 'https://movein.blob.core.windows.net/moveingroupimages/';
  final imageURL2 = 'https://movein.blob.core.windows.net/moveinimages/';

  Future<List<Friend>> searchUsers(String searchQuery) async {
    List<Friend> retlist = [];
    List<String> parts = searchQuery.toLowerCase().split(' ');

    final CollectionReference userCollection =
        FirebaseFirestore.instance.collection('Users');

    final QuerySnapshot firstnamequery = await userCollection
        .where('Forename', isEqualTo: parts[0])
        .orderBy('Surname')
        .get();

    final QuerySnapshot lastnamequery = await userCollection
        .where('Surname',
            isEqualTo:
                (parts.length > 1) ? '${parts[1]}\uf8ff' : '${parts[0]}\uf8ff')
        .get();

    final QuerySnapshot idquery = await userCollection
        .where(FieldPath.documentId, isEqualTo: '$searchQuery\uf8ff')
        .get();

    for (QuerySnapshot sS in [lastnamequery, idquery, firstnamequery]) {
      List<Friend> searched = sS.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Friend(
          profileImg: data['profileImg'],
          name: '${data['Forename']} ${data['Surname']}',
          id: doc.id,
        );
      }).toList();
      retlist.addAll(searched);
    }

    return retlist;
  }

  void filterSearchResults(String query) {
    setState(() {
      loadExtra = false;
      isSearchLoading = true;
      searchResults = friends
          .where((friend) =>
              friend["Id"].toLowerCase().contains(query.toLowerCase()) ||
              '${friend["ForeName"]} ${friend["SurName"]}'
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      groupSearchResults = groupInvites
          .where((group) =>
              group["Id"].toLowerCase().contains(query.toLowerCase()) ||
              group["GroupName"].toLowerCase().contains(query.toLowerCase()))
          .toList();

      blockedSearchResults = blockedGroups
          .where((group) =>
              group["Id"].toLowerCase().contains(query.toLowerCase()) ||
              group["GroupName"].toLowerCase().contains(query.toLowerCase()))
          .toList();

      friendSearchResults = friendInvites
          .where((friend) =>
              friend["Id"].toLowerCase().contains(query.toLowerCase()) ||
              '${friend["ForeName"]} ${friend["SurName"]}'
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      outgoingFriendInvitesResults = outgoingFriendInvites
          .where((friend) =>
              friend["Id"].toLowerCase().contains(query.toLowerCase()) ||
              '${friend["ForeName"]} ${friend["SurName"]}'
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();

      joinedResults = joined
          .where((group) =>
              group["GroupName"].toLowerCase().contains(query.toLowerCase()) ||
              group["Id"].toLowerCase().contains(query.toLowerCase()))
          .toList();

      applicationsResults = applications
          .where((group) =>
              group["GroupName"].toLowerCase().contains(query.toLowerCase()) ||
              group["Id"].toLowerCase().contains(query.toLowerCase()))
          .toList();

      shortListResults = shortList
          .where((group) =>
              group["GroupName"].toLowerCase().contains(query.toLowerCase()) ||
              group["Id"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Stream<List<List<dynamic>>> friendsDataStream() async* {
    final CollectionReference docGroups =
        FirebaseFirestore.instance.collection("Groups");
    final CollectionReference docUsers =
        FirebaseFirestore.instance.collection("Users");

    final streamController = StreamController<List<List<dynamic>>>();

    docUsers.doc(Auth().currentUser()).snapshots().listen((docSnapshot) async {
      List<Map<String, dynamic>> friends = [];
      List<Map<String, dynamic>> groupInvites = [];
      List<Map<String, dynamic>> blockedGroups = [];
      List<Map<String, dynamic>> friendInvites = [];
      List<dynamic> blockIgnores = [];
      List<Map<String, dynamic>> outgoingFriendInvites = [];
      List<dynamic> allGroups = [];

      try {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        for (String type in ["Joined", "Applications", "ShortList"]) {
          List<Map<String, dynamic>> groups = [];
          List<String> tGroups = [];

          tGroups = List<String>.from(data?[type] ?? []);

          for (var group in tGroups) {
            if (group.isNotEmpty) {
              DocumentSnapshot groupSnapshot = await docGroups.doc(group).get();
              Map<String, dynamic>? groupData =
                  groupSnapshot.data() as Map<String, dynamic>?;
              if (groupData != null) {
                blockIgnores.add(group);
                groups.add({
                  "Id": group,
                  "GroupName": groupData["GroupName"],
                  "GroupPicture": groupData["GroupPicture"],
                  "Members": groupData["Members"],
                  "AvgCleanliness":
                      (groupData["AvgCleanliness"] as num).toDouble(),
                  "AvgNoisiness": (groupData["AvgNoisiness"] as num).toDouble(),
                  "AvgNightLife": (groupData["AvgNightLife"] as num).toDouble(),
                  'AvgYearOfStudy':
                      (groupData["AvgYearOfStudy"] as num).toDouble(),
                  "AvgBedTime": groupData["AvgBedTime"],
                  "Noti": (groupData["Read"] != null)
                      ? !(groupData["Read"].contains(Auth().currentUser()))
                      : false
                });
              }
            }
          }

          allGroups.add(groups);
        }
        final groupIds = List<String>.from(data?['GroupInvites'] ?? []);
        for (String groupId in groupIds) {
          final friendSnapshot = await FirebaseFirestore.instance
              .collection('Groups')
              .doc(groupId)
              .get();
          final groupData = friendSnapshot.data();
          if (groupData != null) {
            groupInvites.add({
              "Id": groupId,
              "GroupName": groupData['GroupName'],
              "GroupPicture": groupData['GroupPicture'],
              "Members": groupData['Members'],
              "AvgCleanliness": (groupData['AvgCleanliness'] as num).toDouble(),
              "AvgNoisiness": (groupData['AvgNoisiness'] as num).toDouble(),
              "AvgNightLife": (groupData['AvgNightLife'] as num).toDouble(),
              'AvgYearOfStudy': (groupData["AvgYearOfStudy"] as num).toDouble(),
              "AvgBedTime": groupData['AvgBedTime'],
            });
          }
        }
        final blockedIds = List<String>.from(data?['BlockedGroups'] ?? []);
        blockedIds.removeWhere((element) => blockIgnores.contains(element));
        for (String groupId in blockedIds) {
          final friendSnapshot = await FirebaseFirestore.instance
              .collection('Groups')
              .doc(groupId)
              .get();
          final groupData = friendSnapshot.data();
          if (groupData != null) {
            blockedGroups.add({
              "Id": groupId,
              "GroupName": groupData['GroupName'],
              "GroupPicture": groupData['GroupPicture'],
              "Members": groupData['Members'],
              "AvgCleanliness": (groupData['AvgCleanliness'] as num).toDouble(),
              "AvgNoisiness": (groupData['AvgNoisiness'] as num).toDouble(),
              "AvgNightLife": (groupData['AvgNightLife'] as num).toDouble(),
              "AvgBedTime": groupData['AvgBedTime'],
              "AvgYearOfStudy": groupData['AvgYearOfStudy'],
            });
          }
        }

        final inviteIds = List<String>.from(data?['FriendInvites'] ?? []);
        final friendsIds = List<String>.from(data?['Friends'] ?? []);
        final outgoingIds =
            List<String>.from(data?['OutgoingFriendInvites'] ?? []);

        for (String inviteId in inviteIds) {
          final friendSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(inviteId)
              .get();
          final friendData = friendSnapshot.data();

          if (friendData != null) {
            int yearsAgo = stampToYear(friendData['DOB'].toDate());
            friendInvites.add({
              "ForeName": friendData['ForeName'],
              "SurName": friendData['SurName'],
              "Age": yearsAgo,
              "Uni": friendData['UniAttended'],
              "Preferences": friendData['Preferences'],
              "Images": friendData['Images'],
              "Bio": friendData['Bio'],
              "Subject": friendData['Subject'],
              "YearOfStudy": friendData['YearOfStudy'],
              "Id": inviteId,
              "verified": friendData['EmailVerified'],
            });
          }
        }

        for (String friendId in friendsIds) {
          final friendSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(friendId)
              .get();
          final friendData = friendSnapshot.data();

          final friendDmSnapshot = await FirebaseFirestore.instance
              .collection('DirectMessages')
              .doc(DMIdGen(Auth().currentUser(), friendId))
              .get();
          final friendDmData = friendDmSnapshot.data();

          if ((friendData != null) & (friendDmData != null)) {
            int yearsAgo = stampToYear(friendData?['DOB'].toDate());
            friends.add({
              "ForeName": friendData?['ForeName'],
              "SurName": friendData?['SurName'],
              "Age": yearsAgo,
              "Uni": friendData?['UniAttended'],
              "Preferences": friendData?['Preferences'],
              "Images": friendData?['Images'],
              "Bio": friendData?['Bio'],
              "Subject": friendData?['Subject'],
              "YearOfStudy": friendData?['YearOfStudy'],
              "Id": friendId,
              "verified": friendData?['EmailVerified'],
              "Noti": (friendDmData?["Read"] != null)
                  ? !(friendDmData?["Read"].contains(Auth().currentUser()))
                  : false
            });
          }
        }

        for (String outgoingId in outgoingIds) {
          final friendSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(outgoingId)
              .get();
          final friendData = friendSnapshot.data();

          if (friendData != null) {
            int yearsAgo = stampToYear(friendData['DOB'].toDate());
            outgoingFriendInvites.add({
              "ForeName": friendData['ForeName'],
              "SurName": friendData['SurName'],
              "Age": yearsAgo,
              "Uni": friendData['UniAttended'],
              "Preferences": friendData['Preferences'],
              "Images": friendData['Images'],
              "Bio": friendData['Bio'],
              "Subject": friendData['Subject'],
              "YearOfStudy": friendData['YearOfStudy'],
              "Id": outgoingId,
              "verified": friendData['EmailVerified'],
            });
          }
        }
      } catch (e) {
        streamController.addError(e);
      }

      streamController.add([
        friends,
        friendInvites,
        groupInvites,
        outgoingFriendInvites,
        allGroups,
        blockedGroups
      ]);
    });

    yield* streamController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<List<dynamic>>>(
        stream: friendsDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildScaffold(context, true);
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            isLoading = false;
            final data = snapshot.data;
            try {
              friends = data![0];
              searchResults = data[0];
              friendInvites = data[1];
              friendSearchResults = data[1];
              groupInvites = data[2];
              groupSearchResults = data[2];
              outgoingFriendInvites = data[3];
              outgoingFriendInvitesResults = data[3];
              joined = data[4][0];
              joinedResults = data[4][0];
              applications = data[4][1];
              applicationsResults = data[4][1];
              shortList = data[4][2];
              shortListResults = data[4][2];
              blockedGroups = data[5];
              blockedSearchResults = data[5];
            } catch (e) {
              friends = [];
              searchResults = [];
              friendInvites = [];
              friendSearchResults = [];
              groupInvites = [];
              groupSearchResults = [];
              outgoingFriendInvites = [];
              outgoingFriendInvitesResults = [];
              joined = [];
              joinedResults = [];
              applications = [];
              applicationsResults = [];
              shortList = [];
              shortListResults = [];
              blockedGroups = [];
              blockedSearchResults = [];
            }
            return buildScaffold(context, false);
          }
        });
  }

  Scaffold buildScaffold(BuildContext context, bool isLoading) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      height: 40,
                      width: double.maxFinite,
                      child: SearchBar(
                          hintText: "search".tr,
                          onChanged: (value) {
                            searchText = value;
                            filterSearchResults(value);
                          },
                          trailing: [
                            IconButton(
                              onPressed: () {
                                showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      SendFriendInvite(
                                    userId: Auth().currentUser(),
                                  ),
                                );
                              },
                              icon: const Icon(LineAwesomeIcons.user_plus),
                            ),
                          ]),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "your_groups".tr,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.left,
                        ),
                        Expanded(child: Container()),
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                LAppTheme.lightTheme.primaryColor),
                          ),
                          onPressed: () {
                            if (joined.length == appsMax) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'max_groups_title'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    content: Text('max_groups_desc'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                              context); // Close the dialog
                                        },
                                        child: Text('ok'.tr,
                                            style: GoogleFonts.redHatDisplay(
                                                color: LAppTheme
                                                    .lightTheme.primaryColor,
                                                fontSize: 16.5)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(
                                          20)), // Rounded top corners
                                ),
                                builder: (BuildContext context) {
                                  return CreateGroupForm(
                                    userId: Auth().currentUser(),
                                  ); // Using the extracted widget here
                                },
                              );
                            }
                          },
                          child: SizedBox(
                            height: 30,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('create_group'.tr,
                                    style: GoogleFonts.redHatDisplay(
                                        color: Colors.grey[100],
                                        fontSize: 16.0)),
                                Icon(LineAwesomeIcons.plus,
                                    size: 20, color: Colors.grey[100]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(42)),
                          boxShadow: [
                            BoxShadow(
                              color: LAppTheme.lightTheme.primaryColor
                                  .withAlpha(200),
                              offset: const Offset(0, 20),
                              blurRadius: 30,
                              spreadRadius: -5,
                            ),
                          ],
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomCenter,
                              colors: [
                                LAppTheme.lightTheme.primaryColor
                                    .withAlpha(150),
                                LAppTheme.lightTheme.primaryColor
                                    .withAlpha(200),
                                LAppTheme.lightTheme.primaryColor,
                                LAppTheme.lightTheme.primaryColor,
                              ],
                              stops: const [
                                0.1,
                                0.3,
                                0.9,
                                1.0
                              ])),
                      child: isLoading
                          ? const Text("")
                          : (joinedResults.isEmpty &
                                  applicationsResults.isEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    "no_groups".tr,
                                    style: GoogleFonts.redHatDisplay(
                                        color: Colors.grey[100],
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold),
                                  ))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: joinedResults.length +
                                      applicationsResults.length +
                                      3,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return joinedResults.isEmpty
                                          ? const SizedBox(
                                              height: 1,
                                            )
                                          : Column(children: [
                                              const SizedBox(height: 15),
                                              Row(children: [
                                                const SizedBox(width: 20),
                                                Text(
                                                  "joined".tr,
                                                  style: GoogleFonts.lexend(
                                                      color: Colors.grey[100],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 23),
                                                ),
                                                const SizedBox(width: 15),
                                                Text(
                                                  "${joined.length}/$appsMax",
                                                  style:
                                                      GoogleFonts.redHatDisplay(
                                                          color:
                                                              Colors.grey[100],
                                                          fontSize: 16.5,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                ),
                                              ]),
                                            ]);
                                    } else if (index <= joinedResults.length) {
                                      int joinedIndex = index - 1;
                                      String imageString;
                                      imageString = joinedResults[joinedIndex]
                                          ['GroupPicture'];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8.0),
                                        child: ClipRect(
                                          child: Slidable(
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          curve: Curves.linear,
                                                          type:
                                                              PageTransitionType
                                                                  .topToBottom,
                                                          child:
                                                              const Messages(),
                                                          settings:
                                                              RouteSettings(
                                                                  arguments: {
                                                                'members': joinedResults[
                                                                        joinedIndex]
                                                                    ["Members"],
                                                                'groupId':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        ["Id"],
                                                                'groupName':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        [
                                                                        "GroupName"],
                                                                'groupPicture':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        [
                                                                        "GroupPicture"],
                                                              })),
                                                    );
                                                  },
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: LAppTheme
                                                      .lightTheme.primaryColor,
                                                  icon: Icons.mail,
                                                  label: 'messages'.tr,
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    setState(() {
                                                      joinedResults[joinedIndex]
                                                          ["Noti"] = false;
                                                      joined[joinedIndex]
                                                          ["Noti"] = false;
                                                    });
                                                    Navigator.push(
                                                      context,
                                                      PageTransition(
                                                          curve: Curves.linear,
                                                          type:
                                                              PageTransitionType
                                                                  .topToBottom,
                                                          child:
                                                              const GroupOptions(),
                                                          settings:
                                                              RouteSettings(
                                                                  arguments: {
                                                                'members': joinedResults[
                                                                        joinedIndex]
                                                                    ["Members"],
                                                                'groupId':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        ["Id"],
                                                                'groupName':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        [
                                                                        "GroupName"],
                                                                'groupPicture':
                                                                    joinedResults[
                                                                            joinedIndex]
                                                                        [
                                                                        "GroupPicture"],
                                                              })),
                                                    );
                                                  },
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: LAppTheme
                                                      .lightTheme.primaryColor,
                                                  icon: Icons.more_vert,
                                                  label: 'more'.tr,
                                                ),
                                              ],
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  joinedResults[joinedIndex]
                                                      ["Noti"] = false;
                                                  joined[joinedIndex]["Noti"] =
                                                      false;
                                                });
                                                Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      curve: Curves.linear,
                                                      type: PageTransitionType
                                                          .topToBottom,
                                                      child: const Messages(),
                                                      settings: RouteSettings(
                                                          arguments: {
                                                            'members':
                                                                joinedResults[
                                                                        joinedIndex]
                                                                    ["Members"],
                                                            'groupId':
                                                                joinedResults[
                                                                        joinedIndex]
                                                                    ["Id"],
                                                            'groupName':
                                                                joinedResults[
                                                                        joinedIndex]
                                                                    [
                                                                    "GroupName"],
                                                            'groupPicture': imageURL +
                                                                joinedResults[
                                                                        joinedIndex]
                                                                    [
                                                                    "GroupPicture"],
                                                          })),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 12.0),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                        width: 1,
                                                        color: Colors.grey[100]!
                                                            .withOpacity(0.3)),
                                                    // Top border
                                                    bottom: BorderSide(
                                                        width: 1,
                                                        color: Colors.grey[100]!
                                                            .withOpacity(
                                                                0.3)), // Bottom border
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            child: imageString ==
                                                                    ''
                                                                ? Image.network(
                                                                    'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                                : Image.network(
                                                                    '$imageURL$imageString.jpg'),
                                                          ),
                                                          if (joinedResults[
                                                                      joinedIndex]
                                                                  ["Noti"] ==
                                                              true)
                                                            Positioned(
                                                              bottom: -5,
                                                              right: -5,
                                                              child: Container(
                                                                height: 20,
                                                                width: 20,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Colors
                                                                      .red, // Background color
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.3), // Shadow color and opacity
                                                                      blurRadius:
                                                                          5, // Adjust the blur radius as needed
                                                                      offset: const Offset(
                                                                          0,
                                                                          3), // Adjust the shadow offset
                                                                    ),
                                                                  ],
                                                                ),
                                                                //padding: EdgeInsets.all(8.0), // Padding inside the container
                                                                child:
                                                                    const Icon(
                                                                  LineAwesomeIcons
                                                                      .bell,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 15,
                                                                ), // Adjust the icon color
                                                              ),
                                                            )
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            joinedResults[
                                                                    joinedIndex]
                                                                ["GroupName"],
                                                            style: GoogleFonts.lexend(
                                                                color: Colors
                                                                    .grey[100],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                fontSize: 20.0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (index ==
                                        joinedResults.length + 1) {
                                      return applicationsResults.isEmpty
                                          ? const SizedBox(
                                              height: 1,
                                            )
                                          : Row(children: [
                                              const SizedBox(width: 20),
                                              Text(
                                                "applications".tr,
                                                style: GoogleFonts.lexend(
                                                    color: Colors.grey[100],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 23),
                                              ),
                                            ]);
                                    } else if (index ==
                                        joinedResults.length +
                                            applicationsResults.length +
                                            2) {
                                      return const SizedBox(height: 25);
                                    } else {
                                      int applicationIndex =
                                          index - joinedResults.length - 2;
                                      String imageName =
                                          applicationsResults[applicationIndex]
                                              ["GroupPicture"];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4.0, horizontal: 8.0),
                                        child: ClipRect(
                                          child: Slidable(
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          GroupExpand(
                                                        id: applicationsResults[
                                                                applicationIndex]
                                                            ["Id"],
                                                        groupName:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                ["GroupName"],
                                                        groupPicture:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                [
                                                                "GroupPicture"],
                                                        members:
                                                            applicationsResults[
                                                                        applicationIndex]
                                                                    ["Members"]
                                                                .cast<String>()
                                                                .toList(),
                                                        avgCleanliness:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                [
                                                                "AvgCleanliness"],
                                                        avgNoisiness:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                [
                                                                "AvgNoisiness"],
                                                        avgNightLife:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                [
                                                                "AvgNightLife"],
                                                        avgBedTime:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                ["AvgBedTime"],
                                                        avgYearOfStudy:
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                [
                                                                "AvgYearOfStudy"],
                                                      ),
                                                    );
                                                  },
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: LAppTheme
                                                      .lightTheme.primaryColor,
                                                  icon: LineAwesomeIcons.search,
                                                  label: 'preview'.tr,
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    showDialog<String>(
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            ConfirmGroupDel(
                                                              groupId:
                                                                  applicationsResults[
                                                                          applicationIndex]
                                                                      ["Id"],
                                                              groupType:
                                                                  "Applications",
                                                              userId: Auth()
                                                                  .currentUser(),
                                                            ));
                                                  },
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: LAppTheme
                                                      .lightTheme.primaryColor,
                                                  icon: LineAwesomeIcons
                                                      .alternate_trash,
                                                  label: 'remove'.tr,
                                                ),
                                              ],
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog<String>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          GroupExpand(
                                                    id: applicationsResults[
                                                        applicationIndex]["Id"],
                                                    groupName:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["GroupName"],
                                                    groupPicture:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["GroupPicture"],
                                                    members: applicationsResults[
                                                                applicationIndex]
                                                            ["Members"]
                                                        .cast<String>()
                                                        .toList(),
                                                    avgCleanliness:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["AvgCleanliness"],
                                                    avgNoisiness:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["AvgNoisiness"],
                                                    avgNightLife:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["AvgNightLife"],
                                                    avgBedTime:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["AvgBedTime"],
                                                    avgYearOfStudy:
                                                        applicationsResults[
                                                                applicationIndex]
                                                            ["AvgYearOfStudy"],
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                        horizontal: 12.0),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(
                                                        width: 1,
                                                        color: Colors.grey[100]!
                                                            .withOpacity(0.3)),
                                                    // Top border
                                                    bottom: BorderSide(
                                                        width: 1,
                                                        color: Colors.grey[100]!
                                                            .withOpacity(
                                                                0.3)), // Bottom border
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        child: imageName == ''
                                                            ? Image.network(
                                                                'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                            : Image.network(
                                                                '$imageURL$imageName.jpg'),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            applicationsResults[
                                                                    applicationIndex]
                                                                ["GroupName"],
                                                            style: GoogleFonts.lexend(
                                                                color: Colors
                                                                    .grey[100],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                fontSize: 20.0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                    ),
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text(
                        "your_friends".tr,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.left,
                      )),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (App.themeNotifier.value == ThemeMode.dark)
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        // Light grey background color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : (searchResults.isEmpty &
                                      outgoingFriendInvitesResults.isEmpty)
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                          height: 6, width: double.maxFinite))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: searchResults.length,
                                      itemBuilder: (context, index) {
                                        return ClipRect(
                                            child: Slidable(
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) {
                                                  showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          CustomDialog(
                                                            id: searchResults[
                                                                index]["Id"],
                                                            foreName:
                                                                searchResults[
                                                                        index][
                                                                    "ForeName"],
                                                            age: searchResults[
                                                                        index]
                                                                    ["Age"]
                                                                .toInt(),
                                                            uni: searchResults[
                                                                index]["Uni"],
                                                            preferences:
                                                                searchResults[
                                                                        index][
                                                                    "Preferences"],
                                                            images:
                                                                searchResults[
                                                                        index]
                                                                    ["Images"],
                                                            bio: searchResults[
                                                                index]["Bio"],
                                                            subject:
                                                                searchResults[
                                                                        index]
                                                                    ["Subject"],
                                                            yearOfStudy:
                                                                searchResults[
                                                                            index]
                                                                        [
                                                                        "YearOfStudy"]
                                                                    .toInt(),
                                                            showFriend: false,
                                                            isVerified:
                                                                searchResults[
                                                                        index][
                                                                    "verified"],
                                                          ));
                                                },
                                                backgroundColor: LAppTheme
                                                    .lightTheme.primaryColor,
                                                icon: LineAwesomeIcons.search,
                                                label: 'preview'.tr,
                                              ),
                                              SlidableAction(
                                                onPressed: (context) {
                                                  showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          GroupInvite(
                                                            inviteeId:
                                                                searchResults[
                                                                        index]
                                                                    ["Id"],
                                                            userId: Auth()
                                                                .currentUser(),
                                                          ));
                                                },
                                                backgroundColor:
                                                    Colors.lightGreen,
                                                icon: LineAwesomeIcons.users,
                                                label: 'invite_to_group'.tr,
                                              ),
                                              SlidableAction(
                                                onPressed: (context) {
                                                  showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          ConfirmDel(
                                                            friendId:
                                                                searchResults[
                                                                        index]
                                                                    ["Id"],
                                                            userId: Auth()
                                                                .currentUser(),
                                                          ));
                                                },
                                                backgroundColor:
                                                    Colors.redAccent,
                                                icon: LineAwesomeIcons
                                                    .remove_user,
                                                label: 'remove_friend'.tr,
                                              ),
                                            ],
                                          ),
                                          child: GestureDetector(
                                            onTap: () async {
                                              String clickedOnUser =
                                                  searchResults[index]["Id"];
                                              setState(() {
                                                searchResults[index]["Noti"] =
                                                    false;
                                                friends[index]["Noti"] = false;
                                              });
                                              String userId =
                                                  Auth().currentUser();

                                              var usersIds = [
                                                clickedOnUser,
                                                userId
                                              ];
                                              usersIds.sort();
                                              Navigator.push(
                                                  context,
                                                  PageTransition(
                                                      curve: Curves.linear,
                                                      type: PageTransitionType
                                                          .topToBottom,
                                                      child:
                                                          const mb.Messages(),
                                                      settings: RouteSettings(
                                                          arguments: {
                                                            'dmId': DMIdGen(
                                                                usersIds[0],
                                                                usersIds[1]),
                                                            'groupName':
                                                                "${searchResults[index]["ForeName"]} ${searchResults[index]["SurName"]}",
                                                            'groupPicture':
                                                                searchResults[
                                                                        index][
                                                                    "Images"][0],
                                                          })));
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 10, 15),
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
                                                      width: 40,
                                                      height: 40,
                                                      child: Stack(
                                                          clipBehavior:
                                                              Clip.none,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          100),
                                                              child: searchResults[index]
                                                                              [
                                                                              'Images']
                                                                          [0] ==
                                                                      ''
                                                                  ? Image.network(
                                                                      'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                                  : Image.network(
                                                                      '${imageURL2 + searchResults[index]["Images"][0]}.jpg'),
                                                            ),
                                                            if (searchResults[
                                                                        index]
                                                                    ['Noti'] ==
                                                                true)
                                                              Positioned(
                                                                bottom: -5,
                                                                right: -5,
                                                                child:
                                                                    Container(
                                                                  height: 20,
                                                                  width: 20,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color: Colors
                                                                        .red, // Background color
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withOpacity(0.3), // Shadow color and opacity
                                                                        blurRadius:
                                                                            5, // Adjust the blur radius as needed
                                                                        offset: const Offset(
                                                                            0,
                                                                            3), // Adjust the shadow offset
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  //padding: EdgeInsets.all(8.0), // Padding inside the container
                                                                  child:
                                                                      const Icon(
                                                                    LineAwesomeIcons
                                                                        .bell,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 15,
                                                                  ), // Adjust the icon color
                                                                ),
                                                              )
                                                          ]),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "${searchResults[index]["ForeName"]} ${searchResults[index]["SurName"]}",
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .headlineSmall,
                                                          ),
                                                          Text(
                                                            searchResults[index]
                                                                ["Id"],
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ));
                                      },
                                    ),
                          if (outgoingFriendInvitesResults.isNotEmpty)
                            SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                child: Text(
                                  'outGoing_friend_invite'.tr,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  textAlign: TextAlign.left,
                                )),
                          if (outgoingFriendInvitesResults.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: outgoingFriendInvitesResults.length,
                              itemBuilder: (context, index) {
                                return ClipRect(
                                  child: Slidable(
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) async {
                                            await removeOutFriendInvite(
                                              outgoingFriendInvitesResults[
                                                  index]['Id'],
                                              Auth().currentUser(),
                                            );
                                            //
                                            // if (mounted) {
                                            //   reloadData();
                                            // }
                                          },
                                          backgroundColor: Colors.redAccent,
                                          icon: LineAwesomeIcons.remove_user,
                                          label: 'cancel_invite'.tr,
                                        ),
                                      ],
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog<String>(
                                            context: context,
                                            builder: (BuildContext context) =>
                                                CustomDialog(
                                                  id: outgoingFriendInvitesResults[
                                                      index]["Id"],
                                                  foreName:
                                                      outgoingFriendInvitesResults[
                                                          index]["ForeName"],
                                                  age:
                                                      outgoingFriendInvitesResults[
                                                              index]["Age"]
                                                          .toInt(),
                                                  uni:
                                                      outgoingFriendInvitesResults[
                                                          index]["Uni"],
                                                  preferences:
                                                      outgoingFriendInvitesResults[
                                                          index]["Preferences"],
                                                  images:
                                                      outgoingFriendInvitesResults[
                                                          index]["Images"],
                                                  bio:
                                                      outgoingFriendInvitesResults[
                                                          index]["Bio"],
                                                  subject:
                                                      outgoingFriendInvitesResults[
                                                          index]["Subject"],
                                                  yearOfStudy:
                                                      outgoingFriendInvitesResults[
                                                                  index]
                                                              ["YearOfStudy"]
                                                          .toInt(),
                                                  isVerified:
                                                      outgoingFriendInvitesResults[
                                                          index]["verified"],
                                                ));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 10, 15),
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
                                                width: 40,
                                                height: 40,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  child: outgoingFriendInvitesResults[
                                                                  index]
                                                              ['Images'][0] ==
                                                          ''
                                                      ? Image.network(
                                                          'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                      : Image.network(
                                                          '${imageURL2 + outgoingFriendInvitesResults[index]["Images"][0]}.jpg'),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${outgoingFriendInvitesResults[index]['ForeName']} ${outgoingFriendInvitesResults[index]['SurName']}",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headlineSmall,
                                                    ),
                                                    Text(
                                                      outgoingFriendInvitesResults[
                                                          index]["Id"],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text(
                        "sList".tr,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.left,
                      )),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (App.themeNotifier.value == ThemeMode.dark)
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        // Light grey background color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : (shortListResults.isEmpty)
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                          height: 6, width: double.maxFinite),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: shortListResults.length,
                                      itemBuilder: (context, index) {
                                        return ClipRect(
                                          child: Slidable(
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext
                                                              context) =>
                                                          GroupExpand(
                                                        id: shortListResults[
                                                            index]["Id"],
                                                        groupName:
                                                            shortListResults[
                                                                    index]
                                                                ["GroupName"],
                                                        groupPicture:
                                                            shortListResults[
                                                                    index][
                                                                "GroupPicture"],
                                                        members:
                                                            shortListResults[
                                                                        index]
                                                                    ["Members"]
                                                                .cast<String>()
                                                                .toList(),
                                                        avgCleanliness:
                                                            shortListResults[
                                                                    index][
                                                                "AvgCleanliness"],
                                                        avgNoisiness:
                                                            shortListResults[
                                                                    index][
                                                                "AvgNoisiness"],
                                                        avgNightLife:
                                                            shortListResults[
                                                                    index][
                                                                "AvgNightLife"],
                                                        avgBedTime:
                                                            shortListResults[
                                                                    index]
                                                                ["AvgBedTime"],
                                                        avgYearOfStudy:
                                                            shortListResults[
                                                                    index][
                                                                "AvgYearOfStudy"],
                                                      ),
                                                    );
                                                  },
                                                  backgroundColor: LAppTheme
                                                      .lightTheme.primaryColor,
                                                  foregroundColor: Colors.white,
                                                  icon: LineAwesomeIcons.search,
                                                  label: 'preview'.tr,
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) {
                                                    showDialog<String>(
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            ConfirmGroupDel(
                                                              groupId:
                                                                  shortListResults[
                                                                          index]
                                                                      ["Id"],
                                                              groupType:
                                                                  "ShortList",
                                                              userId: Auth()
                                                                  .currentUser(),
                                                            ));
                                                  },
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  icon: LineAwesomeIcons
                                                      .alternate_trash,
                                                  label: 'remove'.tr,
                                                ),
                                              ],
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog<String>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          GroupExpand(
                                                    id: shortListResults[index]
                                                        ["Id"],
                                                    groupName:
                                                        shortListResults[index]
                                                            ["GroupName"],
                                                    groupPicture:
                                                        shortListResults[index]
                                                            ["GroupPicture"],
                                                    members:
                                                        shortListResults[index]
                                                                ["Members"]
                                                            .cast<String>()
                                                            .toList(),
                                                    avgCleanliness:
                                                        shortListResults[index]
                                                            ["AvgCleanliness"],
                                                    avgNoisiness:
                                                        shortListResults[index]
                                                            ["AvgNoisiness"],
                                                    avgNightLife:
                                                        shortListResults[index]
                                                            ["AvgNightLife"],
                                                    avgBedTime:
                                                        shortListResults[index]
                                                            ["AvgBedTime"],
                                                    avgYearOfStudy:
                                                        shortListResults[index]
                                                            ["AvgYearOfStudy"],
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 0, 10, 15),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 40,
                                                        height: 40,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                          child: shortListResults[
                                                                          index]
                                                                      [
                                                                      'GroupPicture'] ==
                                                                  ''
                                                              ? Image.network(
                                                                  'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                              : Image.network(
                                                                  '${imageURL + shortListResults[index]["GroupPicture"]}.jpg'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              shortListResults[
                                                                      index]
                                                                  ["GroupName"],
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headlineSmall,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Text("invites".tr,
                            style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 15),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text(
                        "group_invites".tr,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.left,
                      )),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (App.themeNotifier.value == ThemeMode.dark)
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        // Light grey background color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : groupSearchResults.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                          height: 6, width: double.maxFinite))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: groupSearchResults.length,
                                      itemBuilder: (context, index) {
                                        return ClipRect(
                                            child: Slidable(
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) async {
                                                  await removeGroupInvite(
                                                    groupSearchResults[index]
                                                        ["Id"],
                                                    Auth().currentUser(),
                                                  );
                                                  await addToApplicants(
                                                      groupSearchResults[index]
                                                          ["Id"]);
                                                  // reloadData();
                                                },
                                                backgroundColor:
                                                    Colors.lightGreen,
                                                icon: LineAwesomeIcons.check,
                                                label: 'apply_to_group'.tr,
                                              ),
                                              SlidableAction(
                                                onPressed: (context) async {
                                                  await removeGroupInvite(
                                                    groupSearchResults[index]
                                                        ["Id"],
                                                    Auth().currentUser(),
                                                  );
                                                  // reloadData();
                                                },
                                                backgroundColor:
                                                    Colors.redAccent,
                                                icon: LineAwesomeIcons.times,
                                                label: 'reject_group'.tr,
                                              ),
                                            ],
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              showDialog<String>(
                                                  context: context,
                                                  builder: (BuildContext
                                                          context) =>
                                                      GroupExpand(
                                                        id: groupSearchResults[
                                                            index]["Id"],
                                                        groupName:
                                                            groupSearchResults[
                                                                    index]
                                                                ["GroupName"],
                                                        groupPicture:
                                                            groupSearchResults[
                                                                    index][
                                                                "GroupPicture"],
                                                        members:
                                                            groupSearchResults[
                                                                        index]
                                                                    ["Members"]
                                                                .cast<String>()
                                                                .toList(),
                                                        avgCleanliness:
                                                            groupSearchResults[
                                                                    index][
                                                                "AvgCleanliness"],
                                                        avgNoisiness:
                                                            groupSearchResults[
                                                                    index][
                                                                "AvgNoisiness"],
                                                        avgNightLife:
                                                            groupSearchResults[
                                                                    index][
                                                                "AvgNightLife"],
                                                        avgBedTime:
                                                            groupSearchResults[
                                                                    index]
                                                                ["AvgBedTime"],
                                                        avgYearOfStudy:
                                                            groupSearchResults[
                                                                    index][
                                                                "AvgYearOfStudy"],
                                                      ));
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        10, 0, 10, 15),
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
                                                      width: 40,
                                                      height: 40,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
                                                        child: groupSearchResults[
                                                                        index][
                                                                    'GroupPicture'] ==
                                                                ''
                                                            ? Image.network(
                                                                'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                            : Image.network(
                                                                '${imageURL + groupSearchResults[index]["GroupPicture"]}.jpg'),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            groupSearchResults[
                                                                    index]
                                                                ["GroupName"],
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .headlineSmall,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ));
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text(
                        "friend_invites".tr,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.left,
                      )),
                  Padding(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.04),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (App.themeNotifier.value == ThemeMode.dark)
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        // Light grey background color
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : friendSearchResults.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: SizedBox(
                                          height: 6, width: double.maxFinite))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: friendSearchResults.length,
                                      itemBuilder: (context, index) {
                                        return ClipRect(
                                          child: Slidable(
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    await addFriend(
                                                      friendSearchResults[index]
                                                          ["Id"],
                                                      Auth().currentUser(),
                                                    );
                                                    final url = Uri.parse(
                                                        'https://europe-west2-test-7a857.cloudfunctions.net/createStripeSetupIntent');
                                                    await http.post(
                                                      url,
                                                      headers: {
                                                        'Content-Type':
                                                            'application/json'
                                                      },
                                                      body: json.encode({
                                                        "senderName":
                                                            "${friendSearchResults[index]["ForeName"]} ${friendSearchResults[index]["SurName"]}",
                                                        "deviceId":
                                                            friendSearchResults[
                                                                index]["Id"],
                                                        "notificationType":
                                                            'friendRequest',
                                                      }),
                                                    );
                                                  },
                                                  backgroundColor:
                                                      Colors.lightGreen,
                                                  icon: LineAwesomeIcons
                                                      .user_plus,
                                                  label: 'accept_friend'.tr,
                                                ),
                                                SlidableAction(
                                                  onPressed: (context) async {
                                                    await removeFriendInvite(
                                                      friendSearchResults[index]
                                                          ["Id"],
                                                      Auth().currentUser(),
                                                    );
                                                    // if (mounted) {
                                                    //   reloadData();
                                                    // }
                                                  },
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  icon: LineAwesomeIcons
                                                      .user_minus,
                                                  label: 'reject_friend'.tr,
                                                ),
                                              ],
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog<String>(
                                                    context: context,
                                                    builder: (BuildContext
                                                            context) =>
                                                        CustomDialog(
                                                          id: friendSearchResults[
                                                              index]["Id"],
                                                          foreName:
                                                              friendSearchResults[
                                                                      index]
                                                                  ["ForeName"],
                                                          age:
                                                              friendSearchResults[
                                                                          index]
                                                                      ["Age"]
                                                                  .toInt(),
                                                          uni:
                                                              friendSearchResults[
                                                                  index]["Uni"],
                                                          preferences:
                                                              friendSearchResults[
                                                                      index][
                                                                  "Preferences"],
                                                          images:
                                                              friendSearchResults[
                                                                      index]
                                                                  ["Images"],
                                                          bio:
                                                              friendSearchResults[
                                                                  index]["Bio"],
                                                          subject:
                                                              friendSearchResults[
                                                                      index]
                                                                  ["Subject"],
                                                          yearOfStudy:
                                                              friendSearchResults[
                                                                          index]
                                                                      [
                                                                      "YearOfStudy"]
                                                                  .toInt(),
                                                          isVerified:
                                                              friendSearchResults[
                                                                      index]
                                                                  ["verified"],
                                                        ));
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          10, 0, 10, 15),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 40,
                                                        height: 40,
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                          child: friendSearchResults[
                                                                              index]
                                                                          [
                                                                          'Images']
                                                                      [0] ==
                                                                  ''
                                                              ? Image.network(
                                                                  'https://movein.blob.core.windows.net/moveinimages/noimagefound.png')
                                                              : Image.network(
                                                                  '${imageURL2 + friendSearchResults[index]["Images"][0]}.jpg'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "${friendSearchResults[index]['ForeName']} ${friendSearchResults[index]['SurName']}",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .headlineSmall,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavbar(
        onItemSelected: (route) {
          switch (route) {
            case '/Scroller':
              Navigator.pushReplacement(
                  context,
                  PageTransition(
                      type: PageTransitionType.leftToRightJoined,
                      child: const Scroller(),
                      childCurrent: widget,
                      duration: const Duration(milliseconds: 200)));
              break;

            case '/Friends':
              Navigator.pushReplacement(
                  context,
                  PageTransition(
                      type: PageTransitionType.fade,
                      child: const Friends(),
                      duration: const Duration(milliseconds: 200)));
              break;

            case '/Profile':
              Navigator.pushReplacement(
                  context,
                  PageTransition(
                      type: PageTransitionType.rightToLeftJoined,
                      child: const Profile(),
                      childCurrent: widget,
                      duration: const Duration(milliseconds: 200)));
          }
        },
      ),
    );
  }
}

String DMIdGen(String userId1, String userId2) {
  int compareResult = userId1.compareTo(userId2);

  if (compareResult < 0) {
    return '$userId1$userId2';
  } else {
    return '$userId2$userId1';
  }
}

class Friend {
  final String profileImg;
  final String name;
  final String id;

  const Friend({
    required this.profileImg,
    required this.name,
    required this.id,
  });
}

Future<void> unblock(String groupId, String value, String currentUser) async {
  try {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser)
        .update({
      'BlockedGroups': FieldValue.arrayRemove([groupId])
    });
    await FirebaseFirestore.instance.collection('Groups').doc(groupId).update({
      'BlackList': FieldValue.arrayRemove([currentUser])
    });

    if (value == 'unblock-sList') {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser)
          .update({
        'ShortList': FieldValue.arrayUnion([groupId])
      });
    } else if (value == 'unblock-apply') {
      addToApplicants(groupId);
    }
  } catch (e) {
    throw FirebaseException(
      message: 'Error removing from BlockedGroups": $e',
      plugin: 'cloud_firestore',
    );
  }
}
