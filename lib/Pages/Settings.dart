import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/UserPreferences.dart';
import 'package:movein/navbar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../Pages/Profile.dart';
import '../Auth code/auth.dart';
import 'package:http/http.dart' as http;
import '../Friend And Groups Code/FriendFunctions.dart';
import '../Themes/lMode.dart';
import '../main.dart';
import 'PremiumPage.dart';

class SettingsScaffold extends StatefulWidget {
  const SettingsScaffold({Key? key}) : super(key: key);

  @override
  State<SettingsScaffold> createState() => _SettingsScaffoldState();
}

class _SettingsScaffoldState extends State<SettingsScaffold> {
  @override
  Widget build(BuildContext context) {
    return Builder(
        builder: (context) {
          final navigator = Navigator.of(context);

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).canvasColor,
              centerTitle: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(LineAwesomeIcons.angle_left, color: Theme.of(context).primaryColor),
                color: Colors.grey[500],
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: 
              SettingsPage()
            ,
          );
        }
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: ListView(
        children: [
          const SizedBox(height:30),
          Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).primaryColor,
                size: 50,
              ),
              const SizedBox(width: 10),
              Text("settings".tr, style: Theme.of(context).textTheme.headlineLarge)
            ],
          ),
          const Divider(height: 20, thickness: 1),
          const SizedBox(height: 10),
          //buildChangeEmail(context, 'Change Email'),
          //buildReviewAds(context, 'premium'.tr),
          buildChangeLanguage(context, 'language'.tr),
          buildAccountOption(context, 'p,t,c'.tr),
          buildAccountOption(context, 'contact'.tr),
          buildDeleteAccount(context, 'delete'.tr),

        ],
      ),
    );
  }

  buildDeleteAccount(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height:5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            icon: Icon(LineAwesomeIcons.angle_left, color: Theme.of(context).primaryColor),
                            color: Colors.grey[500],
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("delete-account-title".tr, style: GoogleFonts.lexend(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 23),),
                        const SizedBox(height: 10),
                        Text("delete-account-desc".tr, style: GoogleFonts.redHatDisplay(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16),),
                        const SizedBox(height: 20),
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
                                  onPressed: () async{
                                    await deleteDocumentAndAccount().then((_) => Navigator.pushReplacement(
                                      context, PageTransition(
                                      type: PageTransitionType.fade,
                                      child: const LoginScreen(),
                                      duration: const Duration(milliseconds: 400),
                                    ),));
                                  },
                                  child: Text("confirm".tr, style: Theme.of(context).textTheme.bodyMedium)
                              ),
                            ),

                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.red
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.red)
          ],
        ),
      ),
    );
  }
  Future<void> deleteDocumentAndAccount() async {
    await storageReset();
    try {

      // Delete document from Firestore's "Users" collection
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('Users').doc(currentUserId).get();


      // Access "Joined" and "Applications" arrays
      List<String> joinedGroups = List.from(userSnapshot.get('Joined'));
      List<String> applications = List.from(userSnapshot.get('Applications'));
      String stripeId = userSnapshot.get('Applications').toString();
      if (stripeId != ""){
        await deleteStripeCustomer(stripeId);
      }
      // Remove groups from user's Joined and Applications arrays
      for (String groupId in joinedGroups) {
        await removeGroupFromUser("Joined", groupId, currentUserId);
      }

      for (String groupId in applications) {
        await removeGroupFromUser("Applications", groupId, currentUserId);
      }

      // Delete the document
      await FirebaseFirestore.instance.collection('Users').doc(currentUserId).delete();

    } catch (e) {
      throw FirebaseException(message: 'Error deleting user document: $e', plugin: 'cloud_firestore');
    }

    try {
      // Delete user's account from Firebase Authentication
      await FirebaseAuth.instance.currentUser!.delete();
    } catch (e) {
      throw FirebaseAuthException(code: 'unknown-error', message: 'An unknown error occurred while deleting the account.');
    }
  }
  Future<void> deleteStripeCustomer(String customerId) async {

    final url = Uri.parse('https://europe-west2-test-7a857.cloudfunctions.net/deleteStripeCustomer'); // Replace with your Cloud Function URL
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'customerId': customerId}),
    );

    if (response.statusCode == 200) {
      // Successful response
      return;
    } else {
      throw Exception("unable to delete stripe account");
    }
  }

}


// Template for making a settings button
GestureDetector buildAccountOption(BuildContext context, String title) {
  return GestureDetector(
    onTap: () {
      launchWebsite();
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey)
        ],
      ),
    ),
  );
}

// GestureDetector buildContactUs(BuildContext context, String title) {
//   return 
// }


GestureDetector buildChangeEmail(BuildContext context, String title) {
  return GestureDetector(
    onTap: () {
      showDialog(context: context, builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(LineAwesomeIcons.angle_left, color: Colors.white),
                color: Colors.grey[500],
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  const Text('Change Email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                  const SizedBox(height: 20),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email'
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {print('The email has changed');},
                    child: const Text('Change Email'),
                  )
                ],
              ),
            ),
          )
        );
      });
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey)
        ],
      ),
    ),
  );
}

GestureDetector buildChangeLanguage(BuildContext context, String title) {
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height:5),
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: Icon(LineAwesomeIcons.angle_left, color: Theme.of(context).primaryColor),
                          color: Colors.grey[500],
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                        child: Text('language'.tr, style: Theme.of(context).textTheme.headlineSmall)
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioLanguage(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey)
        ],
      ),
    ),
  );
}

GestureDetector buildReviewAds(BuildContext context, String title) {
  return GestureDetector(
    onTap: () {
      Navigator.push(context,PageTransition(curve:Curves.linear,type: PageTransitionType.bottomToTop, child:const Premium()));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey)
        ],
      ),
    ),
  );
}

chosenItem(BuildContext context, item) {
  switch(item) {
    case 0: print('This will link to the about section on the UniMe Website');
    break;
    case 1: print('FAQs section of unime website loads');
    break;
    case 2: print('no idea yet');
    break;
  }
}

class RadioLanguage extends StatefulWidget {
  const RadioLanguage({super.key});

  @override
  State<RadioLanguage> createState() => _RadioLanguageState();
}

enum SingingCharacter { english, french, hindi, mandarin, spanish, }

class _RadioLanguageState extends State<RadioLanguage> {
  String? current;
  SingingCharacter? _character;
  @override
  void initState() {
    super.initState();
    current = UserPreferences.getLocale();
    _character = _getSingingCharacterFromLocale(current);
  }

  void _updateLocaleAndRebuild(String languageCode) async {
    await UserPreferences.setLocale(languageCode);
    Get.updateLocale(Locale(languageCode));
    setState(() {
      current = languageCode;
      _character = _getSingingCharacterFromLocale(current);
    });
  }

  SingingCharacter? _getSingingCharacterFromLocale(String? languageCode) {
    if (languageCode == null) return null;
    switch (languageCode) {
      case 'en':
        return SingingCharacter.english;
      case 'fr':
        return SingingCharacter.french;
      case 'es':
        return SingingCharacter.spanish;
      case 'zh':
        return SingingCharacter.mandarin;
      case 'hi':
        return SingingCharacter.hindi;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text('English'),
          leading: Radio<SingingCharacter>(
            activeColor: LAppTheme.lightTheme.primaryColor,
            groupValue: _character,
            value: SingingCharacter.english,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
                _updateLocaleAndRebuild("en");
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Français'),
          leading: Radio<SingingCharacter>(
            activeColor: LAppTheme.lightTheme.primaryColor,
            groupValue: _character,
            value: SingingCharacter.french,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
                _updateLocaleAndRebuild("fr");
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Español'),
          leading: Radio<SingingCharacter>(
            activeColor: LAppTheme.lightTheme.primaryColor,
            groupValue: _character,
            value: SingingCharacter.spanish,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
                _updateLocaleAndRebuild("es");
              });
            },
          ),
        ),
        ListTile(
          title: const Text('普通话'),
          leading: Radio<SingingCharacter>(
            activeColor: LAppTheme.lightTheme.primaryColor,
            groupValue: _character,
            value: SingingCharacter.mandarin,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
                _updateLocaleAndRebuild("zh");
              });
            },
          ),
        ),
        ListTile(
          title: const Text('हिंदी'),
          leading: Radio<SingingCharacter>(
            activeColor: LAppTheme.lightTheme.primaryColor,
            groupValue: _character,
            value: SingingCharacter.hindi,
            onChanged: (SingingCharacter? value) {
              setState(() {
                _character = value;
                _updateLocaleAndRebuild("hi");
              });
            },
          ),
        )
      ],
    );
  }
}

launchWebsite() async {
  final Uri url = Uri.parse('https://moveinwebsite.azurewebsites.net');
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}