import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:movein/UserPreferences.dart';
import 'package:movein/navbar.dart';
import 'package:movein/Scroller%20Code/HScroll.dart';
import 'package:movein/Ad%20code/ad_helper.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';

import '../Auth code/auth.dart';
import '../Themes/lMode.dart';
import 'Friends.dart';
import 'Profile.dart';

const rootImagePath = 'https://movein.blob.core.windows.net/moveinimages/';

class Scroller extends StatefulWidget {
  const Scroller({Key? key}) : super(key: key);

  @override
  State<Scroller> createState() => _ScrollerState();
}

class _ScrollerState extends State<Scroller> {
  bool refresh = true;
  int index = 0;
  int _adCountdown = 2;
  bool _isButtonEnabled = false;
  late NativeAd _ad;
  bool _isAdLoaded = false;
  bool _loadApp = false;
  //bool _showApp = false;
  late int memPref;
  late int cleanPref;
  late int noisePref;
  late int nightPref;
  late int yearPref;
  List<Map<String, dynamic>> groupData = [];
  final CountdownController _timerController = CountdownController();
  final double _adAspectRatioMedium = (370.0 / 355.0);
  Widget _groupDisplay = const CircularProgressIndicator();

  Widget nextGroup() {
    return Center(
        key: ValueKey(index),
        child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
                child: Gscroller(
              groupName: groupData[index]['GroupName'],
              groupPicture: groupData[index]['GroupPicture'],
              members: groupData[index]['Members'],
              avgBedTime: groupData[index]['AvgBedTime'],
              avgNoisiness: groupData[index]['AvgNoisiness'],
              avgYearOfStudy: groupData[index]['AvgYearOfStudy'],
              avgCleanliness: groupData[index]['AvgCleanliness'],
              avgNightLife: groupData[index]['AvgNightLife'],
              showFriend: true,
            ))));
  }

  Widget initial() {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        child: const CircularProgressIndicator());
  }

  void getGroups() async {
    loadFilters();
    List<Map<String, dynamic>> groups = [];
    final CollectionReference docGroups =
        FirebaseFirestore.instance.collection("Groups");

    try {
      QuerySnapshot querySnapshot = await docGroups
          .where('AllowedUnis', arrayContains: UserPreferences.getUni())
          .get();
      for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;

        if (docSnapshot.exists &&
            !data?["BlackList"].contains(Auth().currentUser())) {
          //change this line to use the stored userId

          Map<String, dynamic> groupData = {
            'Id': docSnapshot.id,
            'GroupName': data!['GroupName'].toString(),
            'GroupPicture': data['GroupPicture'].toString(),
            'Members': List<String>.from(
                data['Members'].map((member) => member.toString())),
            'AvgYearOfStudy': (data['AvgYearOfStudy'] as num).toDouble(),
            'AvgCleanliness': (data['AvgCleanliness'] as num).toDouble(),
            'AvgNoisiness': (data['AvgNoisiness'] as num).toDouble(),
            'AvgNightLife': (data['AvgNightLife'] as num).toDouble(),
            'AvgBedTime': data['AvgBedTime']
          };
          groups.add(groupData);
        }
      }
    } catch (e) {
      throw FirebaseException(
          message: 'Error fetching data: $e', plugin: 'cloud_firestore');
    }
    groupData = groups;
    sortGroupsByPreferences();
    setState(() {
      _groupDisplay = (!groupData.isEmpty ? nextGroup() : const NoGroups())!;
      _loadApp = true;
    });
  }

  @override
  void initState() {
    getGroups();
    //_loadAd();
    super.initState();
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final navigator = Navigator.of(context);
        bool loadAd = ((_adCountdown == 0) &
            _isAdLoaded &
            (UserPreferences.getAppsMax() == 2));
        if (loadAd) {
          Future.delayed(const Duration(seconds: 1), () {
            _timerController.start();
          });
        }

        return Scaffold(
          // backgroundColor: LAppTheme.lightTheme.primaryColor,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: Stack(
            children: [
              (!_loadApp)
                  ? Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.8, // Adjust the width to control the size
                        height: MediaQuery.of(context).size.width *
                            0.8, // Adjust the height to control the size
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: (groupData.isEmpty)
                          ? const NoGroups()
                          : loadAd
                              ? Stack(
                                  children: [
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width,
                                        width:
                                            MediaQuery.of(context).size.height *
                                                _adAspectRatioMedium),
                                    if (_isAdLoaded)
                                      SizedBox(
                                          height:
                                              MediaQuery.of(context).size.width,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              _adAspectRatioMedium,
                                          child: AdWidget(ad: _ad)),
                                  ],
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  switchInCurve: Curves.easeInSine,
                                  switchOutCurve: Curves.easeOutSine,
                                  transitionBuilder: (widget, animation) {
                                    if (widget.key == ValueKey(index)) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: widget,
                                      );
                                    } else {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(-1, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: widget,
                                      );
                                    }
                                  },
                                  child: _groupDisplay),
                    ),
              Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: IconButton(
                        splashRadius: 35,
                        icon: Icon(
                          LineAwesomeIcons.horizontal_sliders,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      20)), // Rounded top corners
                            ),
                            builder: (BuildContext context) {
                              return const FiltersScreen(); // Using the extracted widget here
                            },
                          );
                        },
                      ))),
            ],
          ),
          bottomNavigationBar: CustomNavbar(
            onItemSelected: (route) {
              switch (route) {
                case '/Scroller':
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                          type: PageTransitionType.fade,
                          child: const Scroller(),
                          duration: const Duration(milliseconds: 200)));
                  break;

                case '/Friends':
                  Navigator.pushReplacement(
                      context,
                      PageTransition(
                          type: PageTransitionType.rightToLeftJoined,
                          child: const Friends(),
                          childCurrent: widget,
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
              navigator.pushReplacementNamed(route);
            },
          ),
          floatingActionButton: Visibility(
            visible: groupData.isNotEmpty,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
              child: loadAd
                  ? FloatingActionButton(
                      heroTag: "Skip",
                      backgroundColor: _isButtonEnabled
                          ? LAppTheme.lightTheme.primaryColor.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      onPressed: _isButtonEnabled
                          ? () {
                              _loadAd();
                              _adCountdown = 2;
                              setState(() {
                                //_showApp = false;
                              });
                            }
                          : null,
                      child: Column(
                        children: [
                          const SizedBox(height: 9),
                          const Icon(LineAwesomeIcons.angle_right,
                              color: Colors.white),
                          Countdown(
                            controller: _timerController,
                            seconds: 4,
                            build: (_, double time) => Text(time.toString(),
                                style: GoogleFonts.redHatDisplay(
                                    color: Colors.white, fontSize: 8)),
                            interval: const Duration(milliseconds: 100),
                            onFinished: () {
                              setState(() {
                                _isButtonEnabled = true;
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: "Block",
                          backgroundColor: LAppTheme.lightTheme.primaryColor
                              .withOpacity(0.5),
                          onPressed: () {
                            if (!loadAd & (_adCountdown != 0)) {
                              _adCountdown--;
                            }
                            addToBlacklist(groupData[index]['Id'], true)
                                .then((_) {
                              if (index < groupData.length - 1) {
                                index++;
                                setState(() {
                                  _groupDisplay = nextGroup();
                                  //_showApp = false;
                                });
                              } else {
                                setState(() {
                                  groupData = [];
                                });
                              }
                            }).catchError((e) {
                              throw FirebaseException(
                                message: 'Error calling addToBlacklist: $e',
                                plugin: 'cloud_firestore',
                              );
                            });
                          },
                          child: Column(children: [
                            const SizedBox(height: 9),
                            const Icon(LineAwesomeIcons.times,
                                color: Colors.white),
                            Text(
                              "block".tr,
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.white, fontSize: 8),
                            )
                          ]),
                        ),
                        FloatingActionButton(
                          heroTag: "Next",
                          backgroundColor: LAppTheme.lightTheme.primaryColor
                              .withOpacity(0.5),
                          onPressed: () {
                            if (!loadAd & (_adCountdown != 0)) {
                              _adCountdown--;
                            }
                            if (index < groupData.length - 1) {
                              index++;
                              setState(() {
                                _groupDisplay = nextGroup();
                                //_showApp = false;
                              });
                            } else {
                              setState(() {
                                groupData = [];
                              });
                            }
                          },
                          child: Column(children: [
                            const SizedBox(height: 9),
                            const Icon(LineAwesomeIcons.angle_right,
                                color: Colors.white),
                            Text(
                              "next".tr,
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.white, fontSize: 8),
                            )
                          ]),
                        ),
                        FloatingActionButton(
                          heroTag: "Shortlist",
                          backgroundColor: LAppTheme.lightTheme.primaryColor
                              .withOpacity(0.5),
                          onPressed: () {
                            if (!loadAd & (_adCountdown != 0)) {
                              _adCountdown--;
                            }
                            addToShortList(groupData[index]['Id']).then((_) {
                              if (index < groupData.length - 1) {
                                index++;
                                setState(() {
                                  _groupDisplay = nextGroup();
                                  //_showApp = false;
                                });
                              } else {
                                setState(() {
                                  groupData = [];
                                });
                              }
                            }).catchError((e) {
                              throw FirebaseException(
                                message: 'Error calling addToShortlist: $e',
                                plugin: 'cloud_firestore',
                              );
                            });
                          },
                          child: Column(children: [
                            const SizedBox(height: 9),
                            const Icon(LineAwesomeIcons.archive,
                                color: Colors.white),
                            Text(
                              "sList".tr,
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.white, fontSize: 8),
                            )
                          ]),
                        ),
                        FloatingActionButton(
                          heroTag: "Apply",
                          backgroundColor: LAppTheme.lightTheme.primaryColor
                              .withOpacity(0.5),
                          onPressed: () {
                            if (!loadAd & (_adCountdown != 0)) {
                              _adCountdown--;
                            }
                            addToApplicants(groupData[index]['Id'])
                                .then((result) {
                              if (result == true) {
                                if (index < groupData.length - 1) {
                                  index++;
                                  setState(() {
                                    _groupDisplay = nextGroup();
                                    //_showApp = false;
                                  });
                                } else {
                                  setState(() {
                                    groupData = [];
                                  });
                                }
                              } else {
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
                              }
                            }).catchError((e) {
                              throw FirebaseException(
                                message: 'Error calling addToApplicants: $e',
                                plugin: 'cloud_firestore',
                              );
                            });
                          },
                          child: Column(children: [
                            const SizedBox(height: 9),
                            const Icon(LineAwesomeIcons.check,
                                color: Colors.white),
                            Text(
                              "apply".tr,
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.white, fontSize: 8),
                            )
                          ]),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _loadAd() {
    setState(() {
      _isAdLoaded = false;
    });
    _ad = NativeAd(
        adUnitId: AdHelper.nativeAdUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            _ad.dispose();
          },
          onAdClicked: (ad) {},
          onAdImpression: (ad) {},
          onAdClosed: (ad) {
            _ad.dispose();
            setState(() {
              _adCountdown = 2;
            });
          },
          onAdOpened: (ad) {},
          onAdWillDismissScreen: (ad) {},
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
        ),
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: const Color(0xfffffbed),
          callToActionTextStyle: NativeTemplateTextStyle(
              textColor: Colors.white,
              style: NativeTemplateFontStyle.monospace,
              size: 16.0),
          primaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.black,
              style: NativeTemplateFontStyle.bold,
              size: 16.0),
          secondaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.black,
              style: NativeTemplateFontStyle.italic,
              size: 16.0),
          tertiaryTextStyle: NativeTemplateTextStyle(
              textColor: Colors.black,
              style: NativeTemplateFontStyle.normal,
              size: 16.0),
          cornerRadius: 15,
        ))
      ..load();
  }

  void loadFilters() {
    memPref = UserPreferences.getMemPref();
    cleanPref = UserPreferences.getMemPref();
    noisePref = UserPreferences.getMemPref();
    nightPref = UserPreferences.getMemPref();
    yearPref = UserPreferences.getMemPref();
  }

  double calculateScore(Map<String, dynamic> group) {
    const double memberWeight = 6;
    const double cleanWeight = 2;
    const double noiseWeight = 2;
    const double nightWeight = 2;
    const double yearWeight = 1;

    double memberScore = memPref != 0
        ? ((group['Members'] as List).length - memPref).abs() * memberWeight
        : 0;
    double cleanScore = cleanPref != 0
        ? ((group['AvgCleanliness'] as double) - cleanPref).abs() * cleanWeight
        : 0;
    double noiseScore = noisePref != 0
        ? ((group['AvgNoisiness'] as double) - noisePref).abs() * noiseWeight
        : 0;
    double nightScore = nightPref != 0
        ? ((group['AvgNightLife'] as double) - nightPref).abs() * nightWeight
        : 0;
    double yearScore = yearPref != 0
        ? ((group['AvgYearOfStudy'] as double) - yearPref).abs() * yearWeight
        : 0;
    return memberScore + cleanScore + noiseScore + nightScore + yearScore;
  }

  void sortGroupsByPreferences() {
    groupData.sort((group1, group2) {
      double score1 = calculateScore(group1);
      double score2 = calculateScore(group2);

      // Sort in ascending order - groups with lower scores come first
      return score1.compareTo(score2);
    });
  }
}

class NoGroups extends StatelessWidget {
  const NoGroups({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.3,
            height: MediaQuery.of(context).size.width * 0.3,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                LineAwesomeIcons.exclamation_circle,
                color: Theme.of(context).primaryColor,
                fill: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text('scrolls-empty'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 25),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.blue,
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    PageTransition(
                        type: PageTransitionType.fade,
                        child: const Scroller(),
                        duration: const Duration(milliseconds: 200)));
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                "Refresh",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> addToBlacklist(String groupId, bool block) async {
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection('Groups');
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('Users');

  try {
    // Access the group document
    DocumentSnapshot groupSnapshot = await groupCollection.doc(groupId).get();

    if (groupSnapshot.exists) {
      // Perform array union on BlackList field within the group document
      await groupCollection.doc(groupId).update({
        'BlackList': FieldValue.arrayUnion([Auth().currentUser()])
      });

      if (block) {
        DocumentSnapshot userSnapshot =
            await userCollection.doc(Auth().currentUser()).get();
        if (userSnapshot.exists) {
          // Perform array union on BlockedGroups field within the user document
          await userCollection.doc(Auth().currentUser()).update({
            'BlockedGroups': FieldValue.arrayUnion([groupId])
          });
        } else {
          throw FirebaseException(
              message: 'Error: User Does not exist', plugin: 'cloud_firestore');
        }
      }
    } else {
      throw FirebaseException(
          message: 'Error: Group Does not exist', plugin: 'cloud_firestore');
    }
  } catch (e) {
    throw FirebaseException(
        message: 'Error adding to BlackList: $e', plugin: 'cloud_firestore');
  }
}

Future<void> addToShortList(String groupId) async {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('Users');
  final CollectionReference groupsCollection =
      FirebaseFirestore.instance.collection('Groups');

  usersCollection.doc(Auth().currentUser()).update({
    'ShortList': FieldValue.arrayUnion([groupId])
  }).catchError((e) {
    throw FirebaseException(
        message: 'Error adding to shortlist: $e', plugin: 'cloud_firestore');
  });
  addToBlacklist(groupId, false);
}

Future<bool> addToApplicants(String groupId) async {
  final CollectionReference groupsCollection =
      FirebaseFirestore.instance.collection('Groups');
  final DocumentReference groupDocRef = groupsCollection.doc(groupId);

  final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(Auth().currentUser())
          .get();

  final int joinedGroups = userSnapshot.data()?['Joined'].length +
      userSnapshot.data()?['Applications'].length;

  if (joinedGroups == UserPreferences.getAppsMax()) {
    return false;
  } else {
    groupDocRef.update({
      'Applicants': FieldValue.arrayUnion([Auth().currentUser()]),
      'AppVals.${Auth().currentUser()}': {},
    }).catchError((e) {
      throw FirebaseException(
          message: 'Error adding to group field "Applicants": $e',
          plugin: 'cloud_firestore');
    });

    final DocumentReference userDocRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(Auth().currentUser());

    userDocRef.update({
      'Applications': FieldValue.arrayUnion([groupId])
    }).catchError((e) {
      throw FirebaseException(
          message: 'Error adding to user field "Applications": $e',
          plugin: 'cloud_firestore');
    });

    await addToBlacklist(groupId, false);
    return true;
  }
}

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

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
                    left: Radius.circular(20),
                    // Sets the radius for the left corner
                    right: Radius.circular(
                        20), // Sets the radius for the right corner
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text("filt-title".tr,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text('filt-desc'.tr,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  const Divider(),
                  FormBuilderSlider(
                    name: 'members',
                    min: 0,
                    max: 15,
                    initialValue: UserPreferences.getMemPref().toDouble(),
                    divisions: 15,
                    decoration: InputDecoration(labelText: 'mem-num'.tr),
                  ),
                  FormBuilderSlider(
                    name: 'averageCleanliness',
                    min: 0,
                    max: 5,
                    initialValue: UserPreferences.getCleanPref().toDouble(),
                    divisions: 5,
                    decoration: InputDecoration(labelText: 'avg-cln'.tr),
                  ),
                  FormBuilderSlider(
                    name: 'averageNoisiness',
                    min: 0,
                    max: 5,
                    initialValue: UserPreferences.getNoisePref().toDouble(),
                    divisions: 5,
                    decoration: InputDecoration(labelText: 'avg-noi'.tr),
                  ),
                  FormBuilderSlider(
                    name: 'averageNightLife',
                    min: 0,
                    max: 5,
                    initialValue: UserPreferences.getNightPref().toDouble(),
                    divisions: 5,
                    decoration: InputDecoration(labelText: 'avg-night'.tr),
                  ),
                  FormBuilderSlider(
                    name: 'averageYearOfStudy',
                    min: 0,
                    max: 7,
                    initialValue: UserPreferences.getYearPref().toDouble(),
                    divisions: 7,
                    decoration: InputDecoration(labelText: 'avg-yos'.tr),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await changePreferences(
                  _formKey.currentState?.fields['members']?.value.toInt(),
                  _formKey.currentState?.fields['averageCleanliness']?.value
                      .toInt(),
                  _formKey.currentState?.fields['averageNoisiness']?.value
                      .toInt(),
                  _formKey.currentState?.fields['averageNightLife']?.value
                      .toInt(),
                  _formKey.currentState?.fields['averageYearOfStudy']?.value
                      .toInt(),
                );
                Navigator.pushReplacement(
                    context,
                    PageTransition(
                        type: PageTransitionType.fade,
                        child: const Scroller(),
                        duration: const Duration(milliseconds: 200)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(
                'sub-filt'.tr,
                style: GoogleFonts.redHatDisplay(
                    color: Colors.white, fontSize: 16.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> changePreferences(value, value2, value3, value4, value5) async {
    try {
      await UserPreferences.setMemPref(value ?? 0);
      await UserPreferences.setCleanPref(value2 ?? 0);
      await UserPreferences.setNoisePref(value3 ?? 0);
      await UserPreferences.setNightPref(value4 ?? 0);
      await UserPreferences.setYearPref(value5 ?? 0);
    } catch (e) {
      throw Exception("Error while updating preferences: $e");
    }
  }
}
