import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

//import 'package:money_converter/Currency.dart';
import 'package:http/http.dart' as http;
import 'package:movein/Themes/lMode.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:money_converter/money_converter.dart';

import '../Auth code/auth.dart';
import '../UserPreferences.dart';
import 'Payment.dart';

class Premium extends StatefulWidget {
  const Premium({Key? key}) : super(key: key);

  @override
  State<Premium> createState() => _PremiumState();
}

class _PremiumState extends State<Premium> {
  int _selectedIndex = 0;
  String current = UserPreferences.getLocale();
  String currency = "£";
  final List<double> prices = [0.99, 3.49, 6.49];
  final List<double> weeklyPrices = [0.99, 0.80, 0.50];
  final List<String> priceIds = ['price_1NnhZsEPYvdEvEgTfT27cIFM', 'price_1NnhafEPYvdEvEgTRYcaliV0', 'price_1NnhbTEPYvdEvEgTDYccpP3G'];
  List<int> periodLength = [1, 1, 3];
  List<String> periodName = ["week".tr, "month".tr, "months".tr];
  List<Uri> paymentURLS = [Uri.parse("https://buy.stripe.com/aEU4ic3Mm2npeOc4gg"), Uri.parse("https://buy.stripe.com/cN23e8aaKaTVaxW8wx"), Uri.parse("https://buy.stripe.com/5kAg0UaaKfab21q9AC")];
  bool _paymentReady = false;
  bool _showScreen = false;
  bool _hasSubscriptionFlag = false;

  @override
  void initState() {
    _hasSubscription();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
              height: double.maxFinite,
              width: double.maxFinite,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    stops: const [0.2, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform: const GradientRotation(pi / 4),
                    colors: [
                      Theme
                          .of(context)
                          .canvasColor, // Start with white
                      LAppTheme.lightTheme.primaryColor, // Transition to orange
                    ],
                  ),
                ),
              ) // Replace with your actual content
          ),
          if (_showScreen == false)
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.width * 0.9,
                width: MediaQuery.of(context).size.width * 0.9,
                child: const CircularProgressIndicator(),
              ),
            ),
          if (_showScreen == true)
            SingleChildScrollView(
              child: (_hasSubscriptionFlag) ? const SubscribedScreen()
                  : Column(
                  children: [
                    const SizedBox(height: 70),
                    SizedBox(
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      height: MediaQuery
                          .of(context)
                          .size
                          .width * 0.8,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                              top: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.03,
                              left: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.07,
                              child: SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.75,
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.75,
                                  child: const Image(image: AssetImage(
                                      "assets/Pictures/gradient.png")))
                          ),
                          Positioned(
                            bottom: MediaQuery
                                .of(context)
                                .size
                                .width * 0.27,
                            right: MediaQuery
                                .of(context)
                                .size
                                .width * 0.06,
                            child: Text(
                              "prem".tr,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                      colors: [
                                        Color(0xFFD4AF37),
                                        Color(0xFFFFD700),
                                      ],
                                      stops: [0.3, 0.7]
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 70),
                                  ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: SizedBox(width: MediaQuery
                            .of(context)
                            .size
                            .width,
                            child: Text("prem_desc".tr, style: Theme
                                .of(context)
                                .textTheme
                                .headlineLarge,))
                    ),
                    const SizedBox(height: 15),
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text("prem_desc2".tr,
                            style: GoogleFonts.redHatDisplay(
                                color: Colors.grey[600], fontSize: 14))
                    ),
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 15),
                          child: Text("select_plan".tr, style: Theme
                              .of(context)
                              .textTheme
                              .bodyLarge)
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              width: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: 5,
                                    left: 7,
                                    child: Text(
                                      "${"weekly-cost"
                                          .tr} $currency${weeklyPrices[index]}",
                                      style: LAppTheme.darkTheme.textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${periodLength[index]} ${periodName[index]} - $currency${prices[index]}",
                                      style: LAppTheme.darkTheme.textTheme
                                          .headlineMedium,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: Visibility(
                                      visible: (index == _selectedIndex),
                                      child: const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: Icon(
                                          LineAwesomeIcons.check,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Add the glowing effect layer
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius
                                            .circular(10),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: (index == _selectedIndex)
                                              ? 2
                                              : 0.5,
                                        ),
                                        boxShadow: [
                                          (index == _selectedIndex) ?
                                          BoxShadow(
                                            color: Colors.white
                                                .withOpacity(0.11),
                                            // Adjust opacity
                                            spreadRadius: 5,
                                            // Adjust spread radius
                                            blurRadius: 10,
                                            // Adjust blur radius
                                            offset: const Offset(0, 0),
                                          ) : const BoxShadow(
                                              color: Colors
                                                  .transparent // Adjust opacity
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 35),
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text("conf_desc".tr,
                            style: GoogleFonts.redHatDisplay(
                                color: Colors.grey[600], fontSize: 10))
                    ),
                    //const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.bottomToTop, child: Payment(index: _selectedIndex,), duration: const Duration(milliseconds: 200)));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(25.0),
                            // Semi-circular left side
                            right: Radius.circular(
                                25.0), // Semi-circular right side
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.8),
                            width: 0.5), // Set the background color to transparent
                      ),
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.9,
                        height: 44,
                        decoration: BoxDecoration(
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
                              ]),
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(25.0),
                            // Semi-circular left side
                            right: Radius.circular(
                                25.0), // Semi-circular right side
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "${"confirm"
                                .tr} - $currency${prices[_selectedIndex]
                                .toString()}",
                            style: LAppTheme.darkTheme.textTheme
                                .headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ]
              ),
            ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(LineAwesomeIcons.angle_down,
                  color: LAppTheme.lightTheme.primaryColor,),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _hasSubscription() async {
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(
        Auth().currentUser()).get();

    if (userDoc.exists) {
      final stripeCustomerId = userDoc.data()?['StripeCustomerId'];
      if (stripeCustomerId == "") {
        setState(() {
          _showScreen = true;
        });
      } else {
        final url = Uri.parse(
            'https://europe-west2-test-7a857.cloudfunctions.net/checkCustomerSubscriptions');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "customerId": stripeCustomerId,
          }),
        );
        setState(() {
          _showScreen = true;
          _hasSubscriptionFlag = json.decode(response.body)['hasActiveSubscriptions'];
        });
      }
    } else {
      setState(() {
        _showScreen = true;
      });
    }
  }

}

class SubscribedScreen extends StatelessWidget {
  const SubscribedScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 70),
      SizedBox(
        width: MediaQuery
            .of(context)
            .size
            .width,
        height: MediaQuery
            .of(context)
            .size
            .width * 0.8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
                top: MediaQuery
                    .of(context)
                    .size
                    .width * 0.03,
                left: MediaQuery
                    .of(context)
                    .size
                    .width * 0.07,
                child: SizedBox(
                    height: MediaQuery
                        .of(context)
                        .size
                        .width *
                        0.75,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width *
                        0.75,
                    child: const Image(
                        image: AssetImage(
                            "assets/Pictures/gradient.png")))),
            Positioned(
              bottom: MediaQuery
                  .of(context)
                  .size
                  .width * 0.27,
              right: MediaQuery
                  .of(context)
                  .size
                  .width * 0.06,
              child: Text(
                "prem".tr,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFFFD700),
                        ],
                        stops: [
                          0.3,
                          0.7
                        ]).createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
          padding: const EdgeInsets.all(15),
          child: SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              child: Text(
                "prem-subbed-title".tr,
                textAlign: TextAlign.center,
                style:
                Theme
                    .of(context)
                    .textTheme
                    .headlineLarge,
              ))),
      const SizedBox(height: 15),
      Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            height: 44,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFFFD700),
                  ],
                  stops: [0.3, 0.7]),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent),
              onPressed: () async {
                final Uri nUrl = Uri.parse("https://billing.stripe.com/p/login/4gw3cj3Hfgae4E0000");
                if (!await launchUrl(nUrl)) {
                throw Exception('Could not launch https://billing.stripe.com/p/login/4gw3cj3Hfgae4E0000');
                }
              },
              child: Text(
                "customer-portal".tr,
                style: LAppTheme.darkTheme.textTheme
                    .headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ),

      const SizedBox(height: 15),
      Padding(
          padding: const EdgeInsets.all(15),
          child: Text("prem-subbed-desc".tr,
              style: GoogleFonts.redHatDisplay(
                  color: Colors.grey[600], fontSize: 14))
      ),
    ]);
  }
}

//
// void currencyConverter(String currency) async{
//   late String nCurrency;
//   late List<dynamic> vals;
//   switch (currency){
//     case 'fr' :
//       nCurrency = "€";
//       vals = await valueChanges(Currency(Currency.EUR));
//       break;
//     case 'es' :
//       nCurrency = "€";
//       vals = await valueChanges(Currency(Currency.EUR));
//       break;
//     case 'zh' :
//       nCurrency = "¥";
//       vals = await valueChanges(Currency(Currency.CNY));
//       break;
//     case 'hi' :
//       nCurrency = "₹";
//       vals = await valueChanges(Currency(Currency.INR));
//       break;
//   }
//
//   setState(() {
//     currency = nCurrency;
//     prices = vals[0];
//     weeklyPrices = vals[1];
//   });
// }
// Future<List<dynamic>> valueChanges(Currency cur) async{
//   late double? conversion;
//   late List<double> nPrices;
//   late List<double> nWeeklyPrices;
//   conversion = await MoneyConverter.convert(Currency(Currency.GBP, amount: 1), cur);
//   print(conversion);
//   nPrices = prices.map((double value) {
//     return (value * conversion!).toStringAsFixed(2);
//   }).map(double.parse).toList();
//
//   nWeeklyPrices = prices.map((double value) {
//     return (value * conversion!).toStringAsFixed(2);
//   }).map(double.parse).toList();
//
//   return [nPrices, nWeeklyPrices];
// }

class HyperlinkWidget extends StatelessWidget {
  final String text;

  const HyperlinkWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _launchURL("https://billing.stripe.com/p/login/4gw3cj3Hfgae4E0000"),

      child: Text(
        text,
        style: GoogleFonts.redHatDisplay(color: Colors.blue, fontSize: 16, decoration: TextDecoration.underline,)),
    );
  }

  // Function to launch the URL
  _launchURL(String url) async {
    final Uri nUrl = Uri.parse("https://billing.stripe.com/p/login/4gw3cj3Hfgae4E0000");
    if (!await launchUrl(nUrl)) {
      throw Exception('Could not launch $url');
    }
  }
}

