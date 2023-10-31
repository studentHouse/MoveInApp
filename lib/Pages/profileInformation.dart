import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/UserPreferences.dart';
import '../Ad code/ad_helper.dart';
import '../Auth code/auth.dart';
import '../Themes/lMode.dart';
import '../main.dart';

class ProfileInformation extends StatefulWidget {
  const ProfileInformation({super.key});

  @override
  State<ProfileInformation> createState() => _ProfileInformationState();
}

class _ProfileInformationState extends State<ProfileInformation> {
  final _formKey = GlobalKey<FormBuilderState>();
  late Timer _timer;
  late InterstitialAd? _ad;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController _passwordConfController = TextEditingController();
  List<bool> expansionTileStates = [false, false, false];
  String errorMessage = "";
  bool formValid = true;
  Map<String, dynamic> userData = {
    'ForeName': "",
    'SurName': "",
    'Bio': "",
    'DOB': null,
    'Subject': "",
    'YearOfStudy': 1.0,
    'Preferences': {
      'Cleanliness': 1.0,
      'Noisiness': 1.0,
      'NightLife': 1.0,
      'Lights Out': null,
    }
  };

  @override
  void initState() {
    super.initState();
    getUserData();
    //loadAd();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      _validateForm(); // Call your validation function here
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      bool isDark = App.themeNotifier.value == ThemeMode.dark;
      if (userData['DOB'] == null) {
        return Container();
      } else {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).canvasColor,
                centerTitle: true,
                elevation: 0,
                floating: true,
                // Make the SliverAppBar automatically hide when scrolling down
                leading: IconButton(
                  icon: Icon(LineAwesomeIcons.angle_left,
                      color: LAppTheme.lightTheme.primaryColor),
                  color: Colors.grey[500],
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: FormBuilder(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              LineAwesomeIcons.user,
                              color: isDark
                                  ? Colors.white70
                                  : Theme.of(context).primaryColor,
                              size: 50,
                            ),
                            const SizedBox(width: 10),
                            Text("edit_profile".tr,
                                style:
                                    Theme.of(context).textTheme.headlineLarge)
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        const SizedBox(height: 10),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: expansionTileStates[0],
                            onExpansionChanged: (newState) {
                              setState(() {
                                expansionTileStates[0] = newState;
                              });
                            },
                            leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: LAppTheme.lightTheme.primaryColor,
                                      width: 1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Center(
                                    child: Text("1",
                                        textAlign: TextAlign.center,
                                        style: isDark
                                            ? Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                            : GoogleFonts.lexend(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 23)))),
                            title: Text('user_info'.tr,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            children: [
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    FormBuilderTextField(
                                      name: 'ForeName',
                                      initialValue: userData['ForeName'],
                                      decoration: InputDecoration(
                                          labelText: 'first-name'.tr),
                                      // enabled: false,

                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'first-name-null'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderTextField(
                                      name: 'SurName',
                                      initialValue: userData['SurName'],
                                      decoration: InputDecoration(
                                          labelText: 'last-name'.tr),
                                      // enabled: false,

                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'last-name-null'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: expansionTileStates[1],
                            onExpansionChanged: (newState) {
                              setState(() {
                                expansionTileStates[1] = newState;
                              });
                            },
                            leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: LAppTheme.lightTheme.primaryColor,
                                      width: 1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Center(
                                    child: Text("2",
                                        textAlign: TextAlign.center,
                                        style: isDark
                                            ? Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                            : GoogleFonts.lexend(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 23)))),
                            title: Text('profile-info'.tr,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            children: [
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    FormBuilderTextField(
                                      name: 'Bio',
                                      initialValue: userData['Bio'],
                                      maxLength: 200,
                                      decoration: InputDecoration(
                                          labelText: 'bio'.tr),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'bio-null'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderDateTimePicker(
                                      inputType: InputType.date,
                                      enabled: false,
                                      initialValue: (userData['DOB'] == null)
                                          ? null
                                          : userData['DOB'].toDate(),
                                      name: "DOB",
                                      decoration: InputDecoration(
                                          labelText: 'dob'.tr),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderTextField(
                                      name: 'Subject',
                                      initialValue: userData['Subject'],
                                      decoration: InputDecoration(
                                          labelText: 'subject-studied'.tr),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'subject-null'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      enabled: false,
                                      initialValue: userData['UniAttended'],
                                      //university area
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'YearOfStudy',
                                      initialValue: userData['YearOfStudy'],
                                      min: 1,
                                      max: 7,
                                      divisions: 6,
                                      decoration: InputDecoration(
                                          labelText: 'year-of-study'.tr),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: expansionTileStates[2],
                            onExpansionChanged: (newState) {
                              setState(() {
                                expansionTileStates[2] = newState;
                              });
                            },
                            leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: LAppTheme.lightTheme.primaryColor,
                                      width: 1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Center(
                                    child: Text("3",
                                        textAlign: TextAlign.center,
                                        style: isDark
                                            ? Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                            : GoogleFonts.lexend(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.normal,
                                                fontSize: 23)))),
                            title: Text("preferences".tr,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            children: [
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    FormBuilderSlider(
                                      name: 'Cleanliness',
                                      initialValue: userData['Preferences']
                                          ['Cleanliness'],
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: InputDecoration(
                                          labelText:
                                          'cleanliness-importance'.tr),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'Noisiness',
                                      initialValue: userData['Preferences']
                                          ['Noisiness'],
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: InputDecoration(
                                          labelText:
                                          'noisiness-importance'.tr),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'NightLife',
                                      initialValue: userData['Preferences']
                                          ['NightLife'],
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: InputDecoration(
                                          labelText:
                                          'nightlife-importance'.tr),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderDateTimePicker(
                                      name: 'Lights Out',
                                      initialValue: (userData['Preferences']
                                                  ['Lights Out'] ==
                                              null)
                                          ? null
                                          : userData['Preferences']
                                                  ['Lights Out']
                                              .toDate(),
                                      inputType: InputType.time,
                                      decoration: InputDecoration(
                                          labelText:
                                          'bedtime'.tr),
                                      validator: (value) {
                                        if (value == null) {
                                          return 'bedtime-select'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(errorMessage),
                        const SizedBox(height: 5),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: formValid
                                ? LAppTheme.lightTheme.primaryColor
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20), // Adjust the radius as needed
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24), // Adjust padding as needed
                          ),
                          onPressed: () async {
                            if (formValid) {
                              await updateInfo();
                              if (UserPreferences.getAppsMax() == 2){
                                _ad?.show();
                              }
                              Navigator.of(context)
                                  .pushReplacementNamed('/Profile');
                            }
                          },
                          child: Text('save'.tr,
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.white, fontSize: 16.5)),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  void loadAd() {
    // InterstitialAd.load(
    //     adUnitId: AdHelper.interstitialAdUnitId,
    //     request: const AdRequest(),
    //     adLoadCallback: InterstitialAdLoadCallback(
    //       // Called when an ad is successfully received.
    //       onAdLoaded: (ad) {
    //         ad.fullScreenContentCallback = FullScreenContentCallback(
    //             // Called when the ad showed the full screen content.
    //             onAdShowedFullScreenContent: (ad) {},
    //             // Called when an impression occurs on the ad.
    //             onAdImpression: (ad) {},
    //             // Called when the ad failed to show full screen content.
    //             onAdFailedToShowFullScreenContent: (ad, err) {
    //               // Dispose the ad here to free resources.
    //               ad.dispose();
    //             },
    //             // Called when the ad dismissed full screen content.
    //             onAdDismissedFullScreenContent: (ad) {
    //               // Dispose the ad here to free resources.
    //               ad.dispose();
    //             },
    //             // Called when a click is recorded for an ad.
    //             onAdClicked: (ad) {});
    //         debugPrint('$ad loaded.');
    //         _ad = ad;
    //       },
    //
    //       // Called when an ad request failed.
    //       onAdFailedToLoad: (LoadAdError error) {
    //         debugPrint('InterstitialAd failed to load: $error');
    //       },
    //     ));
  }

  void getUserData() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('Users') // Replace 'Users' with your collection name
          .doc(Auth().currentUser()) // Replace 'yes' with your document ID
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? data =
            docSnapshot.data() as Map<String, dynamic>?;
        userData = {
          "ForeName": data?['ForeName'],
          "SurName": data?['SurName'],
          "Uni": data?['UniAttended'],
          "DOB": data?['DOB'],
          "Preferences": {
            "Cleanliness":
                (data?['Preferences']['Cleanliness'] as num).toDouble(),
            "Noisiness": (data?['Preferences']['Noisiness'] as num).toDouble(),
            "NightLife": (data?['Preferences']['NightLife'] as num).toDouble(),
            "Lights Out": data?['Preferences']['Lights Out']
          },
          "Images": data?['Images'],
          "Bio": data?['Bio'],
          "Subject": data?['Subject'],
          "YearOfStudy": (data?['YearOfStudy'] as num).toDouble(),
        };
        setState(() {});
      }
    } catch (e) {
      throw FirebaseException(
        message: 'Error getting userData: $e',
        plugin: 'cloud_firestore',
      );
    }
  }

  void _validateForm() {
    bool uservalid = true;
    bool profileValid = true;
    bool prefsValid = true;
    if (expansionTileStates.contains(true)) {
      if (expansionTileStates[0] == true) {
        uservalid =
            (_formKey.currentState?.fields['ForeName']?.isValid ?? false) &
                (_formKey.currentState?.fields['SurName']?.isValid ?? false);
        userData['ForeName'] = _formKey.currentState?.fields['ForeName']?.value;
        userData['SurName'] = _formKey.currentState?.fields['SurName']?.value;
      }
      if (expansionTileStates[1] == true) {
        profileValid = (_formKey.currentState?.fields['Bio']?.isValid ??
                false) &
            (_formKey.currentState?.fields['Subject']?.isValid ?? false) &
            (_formKey.currentState?.fields['YearOfStudy']?.isValid ?? false);
        userData['Bio'] = _formKey.currentState?.fields['Bio']?.value;
        userData['Subject'] = _formKey.currentState?.fields['Subject']?.value;
        userData['YearOfStudy'] =
            _formKey.currentState?.fields['YearOfStudy']?.value;
      }
      if (expansionTileStates[2] == true) {
        uservalid =
            (_formKey.currentState?.fields['Cleanliness']?.isValid ?? false) &
                (_formKey.currentState?.fields['Noisiness']?.isValid ?? false) &
                (_formKey.currentState?.fields['NightLife']?.isValid ?? false) &
                (_formKey.currentState?.fields['Lights Out']?.isValid ?? false);
        userData['Preferences']['Cleanliness'] =
            _formKey.currentState?.fields['Cleanliness']?.value;
        userData['Preferences']['Noisiness'] =
            _formKey.currentState?.fields['Noisiness']?.value;
        userData['Preferences']['NightLife'] =
            _formKey.currentState?.fields['NightLife']?.value;
        userData['Preferences']['Lights Out'] = Timestamp.fromDate(
            _formKey.currentState?.fields['Lights Out']?.value);
      }
    }
    final confFormvalid = uservalid & profileValid & prefsValid;
    setState(() {
      formValid = confFormvalid;
    });
  }

  Future<void> updateInfo() async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(Auth().currentUser())
          .update({
        'ForeName': userData['ForeName'],
        'SurName': userData['SurName'],
        'Bio': userData['Bio'],
        'DOB': userData['DOB'],
        'Subject': userData['Subject'],
        'YearOfStudy': userData['YearOfStudy'],
        'Preferences': {
          'Cleanliness': userData['Preferences']['Cleanliness'],
          'Noisiness': userData['Preferences']['Noisiness'],
          'NightLife': userData['Preferences']['NightLife'],
          'Lights Out': userData['Preferences']['Lights Out'],
        }
      });
    } catch (e) {
      throw FirebaseException(
        message: 'Error saving user data: $e',
        plugin: 'cloud_firestore',
      );
    }
  }
}
