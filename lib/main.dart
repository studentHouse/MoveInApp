// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

//import 'dart:html';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/Pages/OnBoarding.dart';
import 'package:movein/Pages/Scroller.dart';
import 'package:movein/Themes/lMode.dart';
import 'package:movein/Pages/Settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movein/Translations.dart';
import 'package:movein/UserPreferences.dart';
import 'package:provider/provider.dart';
import 'Auth code/auth.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:email_validator/email_validator.dart';
import 'package:azblob/azblob.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '.env';
import 'package:azstore/azstore.dart' as AzureStorage;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();
  //LinkFivePurchases.init("fae19762a8d0f160ead020291d33b644b70c69f576202d0c207d4a9153c72b7c");
  //LinkFivePurchases.products;
  //LinkFivePurchases.activeProducts;
  //LinkFivePurchases.purchase(productDetails);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await UserPreferences.init();
  // var ABlob = AzureStorage.parse('https://movein.blob.core.windows.net/moveinimages');

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const App());
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // Handle the background message here
}

class App extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.light);

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _loadSavedTheme();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: App.themeNotifier),
        ],
        child: ValueListenableBuilder<ThemeMode>(
            valueListenable: App.themeNotifier,
            builder: (context, currentMode, child) {
              final String foreName = UserPreferences.getForeName();
              final bool loggedIn = (foreName != "NotLoggedInError");
              if (loggedIn) {
                updateToken();
                checkSubscribed();
              }
              return GetMaterialApp(
                  debugShowCheckedModeBanner: false,
                  translations: AppTranslations(),
                  locale: Get.deviceLocale,
                  theme: LAppTheme.lightTheme,
                  darkTheme: LAppTheme.darkTheme,
                  themeMode: currentMode,
                  initialRoute: !loggedIn ? '/Login' : '/Scroller',
                  routes: {
                    '/OnBoarding': (context) => const OnBoardingPage(),
                  },
                  onGenerateInitialRoutes: (initialRoute) {
                    if (initialRoute == '/Scroller') {
                      return [
                        MaterialPageRoute(
                            builder: (context) => const Scroller())
                      ];
                    } else {
                      return [
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen())
                      ];
                    }
                  });
            }));
  }

  void _loadSavedTheme() {
    String? locale = UserPreferences.getLocale();

    Get.updateLocale(Locale(locale));

    bool? isDarkMode = UserPreferences.getBrightness();
    if (isDarkMode != null) {
      App.themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void checkSubscribed() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No authenticated user found.");
      }

      final docRef =
          FirebaseFirestore.instance.collection('Users').doc(currentUser.uid);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final subscribed = docSnapshot.data()?['Subscribed'] ?? false;
        if (subscribed) {
          await UserPreferences.setAppsMax(5);
        }
      }
    } catch (e) {
      throw Exception('Error updating token: $e');
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    bool isFirst = UserPreferences.getFirstTime() as bool;
    if (isFirst) {
      // here you check
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
          context: context,
          builder: (BuildContext context) => WillPopScope(
            onWillPop: () async {
              await UserPreferences.setFirstTime(false);
              return true;
            },
            child: AlertDialog(
              content: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Image.asset("assets/Pictures/Durham.png")),
                    const SizedBox(height: 30),
                    Text(
                      "Worldwide launch 1st November!",
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Thank you for downloading MoveIn! \n \n For now we're doing a localised launch in Durham, but we're excited to announce a 1st of November worldwide release date so make an account to receive a notification when we launch!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.redHatDisplay(
                          color: Colors.grey[600], fontSize: 16.5),
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    await UserPreferences.setFirstTime(false);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: GoogleFonts.redHatDisplay(
                        color: Theme.of(context).primaryColor, fontSize: 16.5),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            leading: null,
            automaticallyImplyLeading: false,
            expandedHeight: MediaQuery.of(context).size.height / 3,
            collapsedHeight: MediaQuery.of(context).size.height / 3,
            backgroundColor: LAppTheme.lightTheme.primaryColor,
            forceElevated: true,
            pinned: true,
            stretch: true,
            elevation: 40,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/Pictures/logo.png', // Replace with your image path
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(50.0),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(LineAwesomeIcons.language,
                            color: LAppTheme.lightTheme.primaryColor),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                contentPadding: const EdgeInsets.all(0),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 5),
                                    Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: IconButton(
                                            icon: Icon(
                                                LineAwesomeIcons.angle_left,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                            color: Colors.grey[500],
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                        Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Text('language'.tr,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall)),
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
                      ),
                    ),
                    const SizedBox(height: 50),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(labelText: 'Email'),
                      // enabled: false,

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },

                      // validator: FormBuilderValidators.compose([
                      // FormBuilderValidators.required(),
                      // FormBuilderValidators.email(),
                      // ]),
                    ),
                    const SizedBox(height: 10),
                    FormBuilderTextField(
                      name: 'password',
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // Text(errorMessage),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LAppTheme.lightTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust the radius as needed
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24), // Adjust padding as needed
                      ),
                      onPressed: () async {
                        var email =
                            _formKey.currentState?.fields['email']?.value;
                        email = email.trim();
                        if (_formKey.currentState?.saveAndValidate() == false) {
                          return;
                        }
                        RegExp regex =
                            RegExp(r"@durham\.ac\.uk$|@dur\.ac\.uk$");
                        if (!regex.hasMatch(email)) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) => WillPopScope(
                              onWillPop: () async {
                                Navigator.pushReplacement(
                                    context,
                                    PageTransition(
                                        type: PageTransitionType.fade,
                                        child: const LoginScreen(),
                                        duration:
                                            const Duration(milliseconds: 200)));
                                return true;
                              },
                              child: AlertDialog(
                                content: IntrinsicHeight(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Image.asset(
                                              "assets/Pictures/6.png")),
                                      const SizedBox(height: 30),
                                      Text(
                                        "Worldwide launch 1st November!",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        "Thank you for making an Account! \n \n For now we're doing a localised launch in Durham, but we're excited to announce a 1st of November worldwide release date - so keep the app downloaded and we'll notify you when we launch",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.redHatDisplay(
                                            color: Colors.grey[600],
                                            fontSize: 16.5),
                                      )
                                    ],
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () async {
                                      await UserPreferences.setFirstTime(false);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'Close',
                                      style: GoogleFonts.redHatDisplay(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 16.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          String response = await Auth()
                              .signInWithEmailAndPassword(
                                  email,
                                  _formKey
                                      .currentState?.fields['password']?.value);
                          if (response == 'success') {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(Auth().currentUser())
                                .get();

                            if (userDoc.exists) {
                              final userData =
                                  userDoc.data() as Map<String, dynamic>?;

                              if (userData != null) {
                                final subscribed = userData['Subscribed'];
                                await UserPreferences.setAppsMax(
                                    subscribed ? 5 : 2);
                                await UserPreferences.setUni(
                                    userData['UniAttended']);
                                await UserPreferences.setForeName(
                                    userData['ForeName']);
                              }
                            }
                            await updateToken();
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                child: const Scroller(),
                                isIos: true,
                                duration: const Duration(milliseconds: 400),
                              ),
                            );
                            return;
                          } else if (response == 'email verification') {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Email Verification"),
                                    // content: const Text(
                                    //     'Email verification is required. An email has been sent to your account. You might need to check junk / quarantine for this email.'),
                                    content: SizedBox(
                                      height: 400,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            Image.asset(
                                                'assets/Pictures/5.png'),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            const Text(
                                                'Email verification is required'),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            const Text(
                                                'Please check your inbox for an email from feedback@move1n.co.uk'),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            const Text(
                                                'You might need to check your spam or junk folder for it.')
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        child: const Text("Close"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                });
                          } else {
                            setState(() {
                              var errors = {
                                'invalid-email': 'Enter a valid email',
                                'wrong-password': 'Incorrect password'
                              };
                              errorMessage = errors[response] ?? response;

                              if (errorMessage == 'user-not-found') {
                                errorMessage =
                                    'No account linked to that email address :(';
                              }
                              if (errorMessage == 'wrong-password') {
                                errorMessage = 'Oh no! Wrong password.';
                              }

                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Sign In Error"),
                                      content: Text(errorMessage),
                                      actions: <Widget>[
                                        ElevatedButton(
                                          child: const Text("Close"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            });
                          }
                        }
                        return;
                      },
                      child: Text('Login',
                          style: GoogleFonts.redHatDisplay(
                              color: Colors.white, fontSize: 16.5)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: const SignupScreen(),
                            duration: const Duration(milliseconds: 500),
                            reverseDuration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Text('Want to sign up instead?',
                          style: GoogleFonts.redHatDisplay(
                              color: LAppTheme.lightTheme.primaryColor,
                              fontSize: 16.5)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> updateToken() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No authenticated user found.");
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();

    final timestamp = Timestamp.now();

    final docRef =
        FirebaseFirestore.instance.collection('fcmTokens').doc(currentUser.uid);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // The document exists, so update it with the new token and timestamp
      await docRef.update({
        'Token': fcmToken,
        'TimeStamp': timestamp,
      });
    } else {
      // The document doesn't exist, so create it with the new token and timestamp
      await docRef.set({
        'Token': fcmToken,
        'TimeStamp': timestamp,
      });
    }
  } catch (e) {
    throw Exception('Error updating token: $e');
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late Timer _timer;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _profilePicture1;
  File? _profilePicture2;
  File? _profilePicture3;

  String? _profilePicture1String = '';
  String? _profilePicture2String = '';
  String? _profilePicture3String = '';

  Widget defaultProfilePicture = Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
    ),
    child: DottedBorder(
      color: const Color(0xFFc0c0c0),
      dashPattern: const [8, 4],
      strokeWidth: 2,
      child: Container(
        height: 200,
        width: 120,
        color: Colors.grey[200],
      ),
    ),
  );

  var uuid = const Uuid();

  bool _passwordObscured = true;
  bool _passwordConfObscured = true;
  final _universityController = TextEditingController();
  bool _loadApp = false;
  String errorMessage = "";
  bool userInfoValid = false;
  bool profileInfoValid = false;
  bool preferenceInfoValid = false;
  late List<dynamic> universitiesData;
  late List<dynamic> domains;
  late List<dynamic> universitiesSuggestions;
  late String _accessToken;

  @override
  void initState() {
    super.initState();
    fetchJSON();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      _validateForm(); // Call your validation function here
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<bool> _uploadImageToAzure(
      File? imageFile1,
      File? imageFile2,
      File? imageFile3,
      String? imageString1,
      String? imageString2,
      String? imageString3) async {
    Uint8List bytes1 = imageFile1!.readAsBytesSync();
    Uint8List bytes2 = imageFile2!.readAsBytesSync();
    Uint8List bytes3 = imageFile3!.readAsBytesSync();

    var state1 = 0;
    var state2 = 0;
    var state3 = 0;

    var x = AzureStorage.AzureStorage.parse(
        'DefaultEndpointsProtocol=https;AccountName=movein;AccountKey=4MaJcz+DSy+KHInVIhTmtzj3OoWtTr0E+IDAjajCliKTaS5X5j3q2Rp69Q/oDiPtzGXfWw3OJPYh+ASt9PPo9w==;EndpointSuffix=core.windows.net');

    // uploads profile image
    if (imageString1 is String) {
      try {
        await x.putBlob('/moveinimages/$imageString1.jpg',
            contentType: 'image/jpg', bodyBytes: bytes1);
      } catch (e) {
        state1 = 1;
        print('Exception: $e');
      }
    }

    // picture 2
    if (imageString2 is String) {
      try {
        await x.putBlob('/moveinimages/$imageString2.jpg',
            contentType: 'image/jpg', bodyBytes: bytes2);
      } catch (e) {
        state2 = 1;
        print('Exception: $e');
      }
    }

    // picture 3
    if (imageString3 is String) {
      try {
        await x.putBlob('/moveinimages/$imageString3.jpg',
            contentType: 'image/jpg', bodyBytes: bytes3);
      } catch (e) {
        state3 = 1;
        print('Exception: $e');
      }
    }

    if (state1 == 0 && state2 == 0 && state3 == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<File?> pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      CroppedFile? croppedImage = await cropImage(File(image.path));
      if (croppedImage != null) {
        return File(croppedImage.path);
      }
    } else {
      return null;
    }
  }

  Future<CroppedFile?> cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        maxWidth: 400,
        maxHeight: 400,
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
              lockAspectRatio: false),
          IOSUiSettings(title: 'Image Cropper')
        ]);
    return croppedFile;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
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
              child: !_loadApp
                  ? Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.8, // Adjust the width to control the size
                        height: MediaQuery.of(context).size.width *
                            0.8, // Adjust the height to control the size
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FormBuilder(
                        autovalidateMode: AutovalidateMode.always,
                        key: _formKey,
                        child: Column(
                          children: [
                            ListTile(
                              enableFeedback: false,
                              enabled: true,
                              leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                      child: Text("1",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lexend(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 23)))),
                              title: Text("User Info",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                children: [
                                  FormBuilderTextField(
                                    name: 'ForeName',
                                    decoration: const InputDecoration(
                                        labelText: 'First Name'),
                                    // enabled: false,

                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your first name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  FormBuilderTextField(
                                    name: 'SurName',
                                    decoration: const InputDecoration(
                                        labelText: 'Last Name'),
                                    // enabled: false,

                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your Surname';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  FormBuilderTextField(
                                    name: 'email',
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                        labelText: 'University Email'),
                                    validator: (email) {
                                      if (email == null || email.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!EmailValidator.validate(email)) {
                                        return 'Please enter a valid email address';
                                      }
                                      if (!domains.any(
                                          (domain) => email.contains(domain))) {
                                        return 'Email domain is not valid';
                                      }
                                      findUni(email);
                                      return null;
                                    },
                                  ),
                                  FormBuilderTextField(
                                    enabled: false,
                                    name: 'uni',
                                    maxLength: 200,
                                    decoration: const InputDecoration(
                                        labelText: 'University'),
                                    controller: _universityController,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'password',
                                          decoration: const InputDecoration(
                                              labelText: 'Password'),
                                          obscureText: _passwordObscured,
                                          // Use the variable to control the obscuring
                                          controller: _passwordController,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 8) {
                                              return 'Password must be at least 8 characters long';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        splashRadius: 20,
                                        onPressed: () {
                                          setState(() {
                                            _passwordObscured =
                                                !_passwordObscured;
                                          });
                                        },
                                        icon: Icon(_passwordObscured
                                            ? Icons.visibility
                                            : Icons.visibility_off),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FormBuilderTextField(
                                          name: 'password_conf',
                                          decoration: const InputDecoration(
                                              labelText: 'Confirm password'),
                                          obscureText: _passwordConfObscured,
                                          // Use the variable to control the obscuring
                                          controller: _passwordConfController,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please Confirm your password';
                                            } else if (_passwordConfController
                                                    .text !=
                                                _passwordController.text) {
                                              return "Passwords don't match";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        splashRadius: 20,
                                        onPressed: () {
                                          setState(() {
                                            _passwordConfObscured =
                                                !_passwordConfObscured;
                                          });
                                        },
                                        icon: Icon(_passwordConfObscured
                                            ? Icons.visibility
                                            : Icons.visibility_off),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            ListTile(
                              enableFeedback: false,
                              enabled: true,
                              leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: userInfoValid
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                        width: 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                      child: Text("2",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lexend(
                                              color: userInfoValid
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.grey,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 23)))),
                              title: Text("Profile Info",
                                  style: GoogleFonts.lexend(
                                      color: userInfoValid
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20.0)),
                            ),
                            const SizedBox(height: 10),
                            if (userInfoValid)
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    FormBuilderTextField(
                                      name: 'Bio',
                                      maxLength: 200,
                                      decoration: const InputDecoration(
                                          labelText: 'Bio'),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a bio';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 25),
                                    // This is where the profile images go
                                    Text(
                                      "p-images".tr,
                                      style: GoogleFonts.redHatDisplay(
                                          color: Colors.grey[700],
                                          fontSize: 20),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            final pickedImage =
                                                await pickImage();
                                            if (pickedImage != null) {
                                              _profilePicture1String =
                                                  uuid.v1();
                                              setState(() {
                                                _profilePicture1 = pickedImage;
                                              });
                                            } else {
                                              _profilePicture1String = '';
                                            }
                                          },
                                          child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    height:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    child: _profilePicture1 ==
                                                            null
                                                        ? defaultProfilePicture
                                                        : ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Image.file(
                                                              _profilePicture1!,
                                                              fit: BoxFit.cover,
                                                            )),
                                                  ),
                                                  Positioned(
                                                    top: -20,
                                                    right: -20,
                                                    child: SizedBox(
                                                        width:
                                                            40, // Adjust the size as needed
                                                        height:
                                                            40, // Adjust the size as needed
                                                        child: Icon(
                                                            LineAwesomeIcons
                                                                .plus_circle,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor)),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    top: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Center(
                                                      child: Text(
                                                        "pp".tr,
                                                        style: GoogleFonts
                                                            .redHatDisplay(
                                                                color: Colors
                                                                    .grey[700],
                                                                fontSize: 16.5),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final pickedImage =
                                                await pickImage();
                                            if (pickedImage != null) {
                                              _profilePicture2String =
                                                  uuid.v1();
                                              setState(() {
                                                _profilePicture2 = pickedImage;
                                              });
                                            } else {
                                              _profilePicture2String = '';
                                            }
                                          },
                                          child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    height:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    child: _profilePicture2 ==
                                                            null
                                                        ? defaultProfilePicture
                                                        : ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Image.file(
                                                              _profilePicture2!,
                                                              fit: BoxFit.cover,
                                                            )),
                                                  ),
                                                  Positioned(
                                                    top: -20,
                                                    right: -20,
                                                    child: SizedBox(
                                                        width:
                                                            40, // Adjust the size as needed
                                                        height:
                                                            40, // Adjust the size as needed
                                                        child: Icon(
                                                            LineAwesomeIcons
                                                                .plus_circle,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor)),
                                                  ),
                                                ],
                                              )),
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            final pickedImage =
                                                await pickImage();
                                            if (pickedImage != null) {
                                              _profilePicture3String =
                                                  uuid.v1();
                                              setState(() {
                                                _profilePicture3 = pickedImage;
                                              });
                                            } else {
                                              _profilePicture3String = '';
                                            }
                                          },
                                          child: Padding(
                                              padding: const EdgeInsets.all(5),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    height:
                                                        (MediaQuery.of(context)
                                                                    .size
                                                                    .width -
                                                                92) /
                                                            3,
                                                    child: _profilePicture3 ==
                                                            null
                                                        ? defaultProfilePicture
                                                        : ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Image.file(
                                                              _profilePicture3!,
                                                              fit: BoxFit.cover,
                                                            )),
                                                  ),
                                                  Positioned(
                                                    top: -20,
                                                    right: -20,
                                                    child: SizedBox(
                                                        width:
                                                            40, // Adjust the size as needed
                                                        height:
                                                            40, // Adjust the size as needed
                                                        child: Icon(
                                                            LineAwesomeIcons
                                                                .plus_circle,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor)),
                                                  ),
                                                ],
                                              )),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    FormBuilderDateTimePicker(
                                      inputType: InputType.date,
                                      name: "DOB",
                                      decoration: const InputDecoration(
                                          labelText: 'Date of Birth'),
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a date';
                                        }

                                        final currentDate = DateTime.now();
                                        final selectedDate = value;
                                        final minimumAgeDate = DateTime(
                                            currentDate.year - 17,
                                            currentDate.month,
                                            currentDate.day);

                                        if (selectedDate
                                            .isAfter(minimumAgeDate)) {
                                          return 'You must be at least 17 years old';
                                        }

                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderTextField(
                                      name: 'Subject',
                                      decoration: const InputDecoration(
                                          labelText: 'Subject Studied'),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your Subject';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'YearOfStudy',
                                      initialValue: 1,
                                      min: 1,
                                      max: 7,
                                      divisions: 6,
                                      decoration: const InputDecoration(
                                          labelText: 'Year of Study'),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 25),
                            ListTile(
                              enableFeedback: false,
                              enabled: true,
                              leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color:
                                            (userInfoValid & profileInfoValid)
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                        width: 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(
                                      child: Text("3",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.lexend(
                                              color: (userInfoValid &
                                                      profileInfoValid)
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.grey,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 23)))),
                              title: Text("Preferences",
                                  style: GoogleFonts.lexend(
                                      color: (userInfoValid & profileInfoValid)
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20.0)),
                            ),
                            const SizedBox(height: 10),
                            if (userInfoValid & profileInfoValid)
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    FormBuilderSlider(
                                      name: 'Cleanliness',
                                      initialValue: 2,
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'How much does Cleanliness matter to you?'),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'Noisiness',
                                      initialValue: 2,
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'How much does Noisiness matter to you?'),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderSlider(
                                      name: 'NightLife',
                                      initialValue: 2,
                                      min: 0,
                                      max: 5,
                                      divisions: 5,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'How much does Nightlife matter to you?'),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderDateTimePicker(
                                      name: 'Lights Out',
                                      initialValue: DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                          DateTime.now().day,
                                          23,
                                          0),
                                      // 11:00 PM
                                      inputType: InputType.time,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'When are you normally in bed?'),
                                      validator: (value) {
                                        if (value == null) {
                                          return "Please select a time you're asleep by";
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            Text(errorMessage),
                            const SizedBox(height: 5),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: TextButton(
                                onPressed: () {
                                  launchWebsite();
                                },
                                child: Text(
                                  'view-privacy'.tr,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    // Change the color to your desired hyperlink color
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FormBuilderCheckbox(
                              name: 'acceptPrivacyPolicy',
                              validator: (value) {
                                if (value != true) {
                                  return "privacy-error".tr;
                                } else {
                                  return null;
                                }
                              },
                              title: Text(
                                'accept-privacy'.tr,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (profileInfoValid &
                                        userInfoValid &
                                        preferenceInfoValid)
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
                                if (_formKey.currentState?.saveAndValidate() ==
                                    false) {
                                  return;
                                }
                                // debugPrint(_formKey.currentState?.value.toString());
                                Map<String, dynamic> data =
                                    Map<String, dynamic>.from(
                                        _formKey.currentState?.value ?? {});
                                data['UniAttended'] =
                                    _universityController.text;

                                // TEST THIS FIREBASE CODE - SHOULD WORK

                                _uploadImageToAzure(
                                    _profilePicture1,
                                    _profilePicture2,
                                    _profilePicture3,
                                    _profilePicture1String,
                                    _profilePicture2String,
                                    _profilePicture3String);

                                Map<String, dynamic> reConfigedData =
                                    reConfigData(
                                  data,
                                  _profilePicture1String,
                                  _profilePicture2String,
                                  _profilePicture3String,
                                );

                                String response =
                                    await Auth().registerWithUserDetails(
                                  _formKey.currentState?.fields['email']?.value,
                                  _formKey
                                      .currentState?.fields['password']?.value,
                                  reConfigedData,
                                );

                                if (response == 'success') {
                                  await createNotiToken();
                                  RegExp regex =
                                      RegExp(r"@durham\.ac\.uk$|@dur\.ac\.uk$");
                                  if (!regex.hasMatch(_formKey
                                      .currentState?.fields['email']?.value)) {
                                    // ignore: use_build_context_synchronously
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          WillPopScope(
                                        onWillPop: () async {
                                          Navigator.pushReplacement(
                                              context,
                                              PageTransition(
                                                  type: PageTransitionType.fade,
                                                  child: const LoginScreen(),
                                                  duration: const Duration(
                                                      milliseconds: 200)));
                                          return true;
                                        },
                                        child: AlertDialog(
                                          content: IntrinsicHeight(
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Image.asset(
                                                        "assets/Pictures/6.png")),
                                                const SizedBox(height: 30),
                                                Text(
                                                  "Worldwide launch 1st November!",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge,
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 20),
                                                Text(
                                                  "Thank you for making an Account! \n \n For now we're doing a localised launch in Durham, but we're excited to announce a 1st of November worldwide release date - so keep the app downloaded and we'll notify you when we launch",
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      GoogleFonts.redHatDisplay(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 16.5),
                                                )
                                              ],
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pushReplacement(
                                                    context,
                                                    PageTransition(
                                                        type: PageTransitionType
                                                            .fade,
                                                        child:
                                                            const LoginScreen(),
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200)));
                                              },
                                              child: Text(
                                                'Close',
                                                style:
                                                    GoogleFonts.redHatDisplay(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        fontSize: 16.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    await UserPreferences.setUni(
                                        data['UniAttended']);
                                    await UserPreferences.setAppsMax(2);
                                    await UserPreferences.setForeName(
                                        data['ForeName']);
                                    // ignore: use_build_context_synchronously
                                    Navigator.pushReplacement(
                                        context,
                                        PageTransition(
                                            type: PageTransitionType.fade,
                                            child: const OnBoardingPage(),
                                            duration: const Duration(
                                                milliseconds: 200)));
                                    return;
                                  }
                                } else {
                                  setState(() {
                                    var errors = {
                                      'invalid-email': 'Enter a valid email',
                                      'wrong-password': 'Incorrect password'
                                    };

                                    if (response == 'email-already-in-use') {
                                      response =
                                          'Account already in use with email address - please sign in.';
                                    }

                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Sign In Error"),
                                            content: Text(response),
                                            actions: <Widget>[
                                              ElevatedButton(
                                                child: const Text("Close"),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        });
                                  });
                                }
                                return;
                              },
                              child: Text('Signup',
                                  style: GoogleFonts.redHatDisplay(
                                      color: Colors.white, fontSize: 16.5)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> fetchJSON() async {
    final String jsonContent = await rootBundle
        .loadString('assets/JSON/world_universities_and_domains.json');
    universitiesData = json.decode(jsonContent);
    domains = universitiesData
        .map<List<dynamic>>((university) => university['domains'])
        .expand((list) => list)
        .toList(); // Fetch the data when the widget is created

    universitiesSuggestions =
        universitiesData.map((university) => university['name']).toList();
    setState(() {
      _loadApp = true;
    });
  }

  void _validateForm() {
    if (_loadApp) {
      final userInfoComplete =
          (_formKey.currentState?.fields['ForeName']?.isValid ?? false) &
              (_formKey.currentState?.fields['SurName']?.isValid ?? false) &
              (_formKey.currentState?.fields['email']?.isValid ?? false) &
              (_formKey.currentState?.fields['password']?.isValid ?? false) &
              (_formKey.currentState?.fields['password_conf']?.isValid ??
                  false);

      // Check if profile info section fields are complete
      final profileInfoComplete =
          (_formKey.currentState?.fields['Bio']?.isValid ?? false) &
              (_formKey.currentState?.fields['DOB']?.isValid ?? false) &
              (_formKey.currentState?.fields['Subject']?.isValid ?? false) &
              (_formKey.currentState?.fields['YearOfStudy']?.isValid ?? false);

      final preferenceInfoComplete =
          (_formKey.currentState?.fields['Cleanliness']?.isValid ?? false) &
              (_formKey.currentState?.fields['Noisiness']?.isValid ?? false) &
              (_formKey.currentState?.fields['NightLife']?.isValid ?? false) &
              (_formKey.currentState?.fields['Lights Out']?.isValid ?? false);

      setState(() {
        userInfoValid = userInfoComplete;
        profileInfoValid = profileInfoComplete;
        preferenceInfoValid = preferenceInfoComplete;
      });
    }
  }

  Map<String, dynamic> reConfigData(Map<String, dynamic> data,
      String? imageString1, String? imageString2, String? imageString3) {
    data.remove('password');
    data.remove('password_conf');
    data.remove('email');
    data['Preferences'] = {
      'Noisiness': data['Noisiness'],
      'Cleanliness': data['Cleanliness'],
      'NightLife': data['NightLife'],
      'Lights Out': data['Lights Out']
    };
    data.remove('Noisiness');
    data.remove('Cleanliness');
    data.remove('NightLife');
    data.remove('Lights Out');
    data['Applications'] = [];
    data['BlockedGroups'] = [];
    data['FriendInvites'] = [];
    data['Friends'] = [];
    data['GroupInvites'] = [];
    data['Groups'] = [];
    data['Joined'] = [];
    data['OutgoingFriendInvites'] = [];
    data['ShortList'] = [];
    data['Images'] = [imageString1, imageString2, imageString3];
    data['Subscribed'] = false;
    data['StripeCustomerId'] = "";
    data['EmailVerified'] = false;
    return data;
  }

  Future<void> createNotiToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No authenticated user found.");
      }

      final fcmToken = await FirebaseMessaging.instance
          .getToken(); // Replace with the actual token

      final timestamp = Timestamp.now();

      final docRef = FirebaseFirestore.instance
          .collection('fcmTokens')
          .doc(Auth().currentUser());

      await docRef.set({
        'Token': fcmToken,
        'TimeStamp': timestamp,
      });
    } catch (e) {
      throw Exception("failed to create notification Token: $e");
    }
  }

  void findUni(String email) {
    String emailDomain = email.split('@')[1];

    // Check if the email domain is valid for the selected university
    Map<String, dynamic>? selectedUniversity = universitiesData.firstWhere(
      (university) => university['domains'].contains(emailDomain),
      orElse: () => null,
    );

    if (selectedUniversity != null) {
      // Update _universityController with the name of the selected university
      _universityController.text = selectedUniversity['name'];
    } else {
      // Handle the case when no matching university is found
      _universityController.text = 'Unknown University';
    }
  }
}
