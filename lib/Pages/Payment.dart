import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:movein/Pages/PremiumPage.dart';
import 'package:movein/UserPreferences.dart';
import 'package:pay/pay.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Auth code/auth.dart';
import '../Themes/lMode.dart';

class Payment extends StatefulWidget {
  final int index;

  const Payment({
    super.key,
    required this.index,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  final String currency = "£";
  final List<double> prices = [0.99, 3.49, 6.49];
  final List<double> weeklyPrices = [0.99, 0.80, 0.50];
  final List<String> priceIds = [
    'price_1NnhZsEPYvdEvEgTfT27cIFM',
    'price_1NnhafEPYvdEvEgTRYcaliV0',
    'price_1NnhbTEPYvdEvEgTDYccpP3G'
  ];
  final List<int> periodLength = [1, 1, 3];
  final List<String> periodName = ["week".tr, "month".tr, "months".tr];
  final List<String> productNames = ["premium weekly", "premium monthly", "premium tri-monthly"];
  bool _appReady = false;
  bool _ready = false;
  bool _payReady = false;
  bool _startSubscription = false;
  int _selectedIndex = 0;
  String _customerId = "";
  CardFieldInputDetails _card = const CardFieldInputDetails(complete: false);
  bool _hasDefaultPayment = false;
  Map<String, dynamic> paymentMethod = {};

  var controller = CardFormEditController();

  @override
  void initState() {
    fetchDefaultPaymentMethod();
    retCustomerId();
    controller.addListener(update);
    super.initState();
  }

  void update() => setState(() {});
  @override
  void dispose() {
    controller.removeListener(update);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_startSubscription){
      subscriptionSetup();
    }
    _ready = ( !_payReady & _card!.complete & (controller.details.complete == true))!;
    return Scaffold(
      body:
      Stack(
        children: [
          if (!_appReady)
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.width * 0.9,
                width: MediaQuery.of(context).size.width * 0.9,
                child: const CircularProgressIndicator(),
              ),
            ),
          if (_appReady)
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SafeArea(
                  child: Form(
                    child: Column(
                      children: [
                        const SizedBox(height: 25),
                        if (!_hasDefaultPayment)
                        SizedBox(
                          height: MediaQuery.of(context).size.width,
                          width: MediaQuery.of(context).size.width,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Container(
                                  height: MediaQuery.of(context).size.width * 0.7,
                                  width: MediaQuery.of(context).size.width,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    // Background color
                                    borderRadius: BorderRadius.circular(8.0),
                                    // Add rounded corners
                                    border: Border.all(
                                      color: LAppTheme.lightTheme.primaryColor
                                          .withOpacity(0.7), // Border color
                                      width: 2.0, // Border width
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3), // Shadow offset
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.width,
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: CardFormField(
                                      disabled: _hasDefaultPayment,
                                      controller: controller,
                                      style: CardFormStyle(
                                        borderWidth: 0,
                                        cursorColor: LAppTheme.lightTheme.primaryColor,
                                        placeholderColor: Colors.black,
                                        textErrorColor: Colors.red,
                                      ),
                                      onCardChanged: (card) {
                                        setState(() {
                                          _card = card!;
                                        });
                                      },
                                    ),
                                  ),
                                )
                              ]
                            ),
                          ),
                        ),
                        if (!_hasDefaultPayment)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                                  if (!controller.details.complete == true) {
                                    return Colors.grey[600]; // Disabled state color
                                  } else {
                                    return LAppTheme.lightTheme.primaryColor; // Enabled state color
                                  }
                                }),
                              ),
                              onPressed: controller.details.complete == true? () {
                                initsetupIntent();
                              }: null,
                              child: Center(
                                  child: Text(
                                    "conf_pay".tr,
                                    style: LAppTheme.darkTheme.textTheme.headlineSmall,
                                  ))),
                        ),
                        if (_hasDefaultPayment)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.width * 0.9,
                            child: Image.asset("assets/Pictures/1.png")
                          ),
                        if (_hasDefaultPayment)
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: ElevatedButton(
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
                        if (_hasDefaultPayment)
                          Padding(
                              padding: const EdgeInsets.all(15),
                              child: Text("has_default_payment".tr,
                                  style: GoogleFonts.redHatDisplay(
                                      color: Colors.grey[600], fontSize: 14))
                          ),
                      ],
                    ),
                  ),
                )),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  LineAwesomeIcons.angle_down,
                  color: LAppTheme.lightTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: LAppTheme.lightTheme.primaryColor,
                // Specify the border color
                width: 1.0, // Specify the border width
              ),
            ), // Background color
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      // Background color set to grey[200]
                      borderRadius: BorderRadius.circular(
                          20.0), // Rounded corners with radius 20
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "package".tr,
                            style: GoogleFonts.lexend(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                                fontSize: 20),
                            textAlign: TextAlign.start,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "${periodLength[widget.index]} ${periodName[widget.index]}",
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.grey[600], fontSize: 16.5),
                            ),
                            const Expanded(
                              child: Text(""),
                            ),
                            Text(
                              "${"weekly-cost".tr} $currency${weeklyPrices[widget.index]}",
                              style: GoogleFonts.redHatDisplay(
                                  color: Colors.grey[600], fontSize: 16.5),
                            )
                          ],
                        ),
                        const Divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${"total".tr} $currency${prices[widget.index]}",
                            style: GoogleFonts.lexend(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                                fontSize: 30),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text("pay_desc".tr,
                    style: GoogleFonts.redHatDisplay(
                        color: Colors.grey[600], fontSize: 10)),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                ),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
                        if (!_payReady) {
                          return Colors.grey[600]; // Disabled state color
                        } else {
                          return LAppTheme.lightTheme.primaryColor; // Enabled state color
                        }
                      }),
                    ),
                    onPressed: _payReady ? () {
                      setState(() {
                        _payReady = false;
                        _startSubscription = true;
                      });
                    } : null,
                    child: Center(
                        child: Text(
                      "pay".tr,
                      style: LAppTheme.darkTheme.textTheme.headlineSmall,
                    ))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void retCustomerId() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(Auth().currentUser())
        .get();
    setState(() {
      _customerId = userDoc.get("StripeCustomerId");
    });
  }

  Future<Map<String, dynamic>> _createSetupIntent() async {
    final url = Uri.parse(
        'https://europe-west2-test-7a857.cloudfunctions.net/createStripeSetupIntent');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'uid': Auth().currentUser(),
        'priceId': "price_1NqGNKEPYvdEvEgT5bAsp5KL",//priceIds[_selectedIndex],
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data;

    } else {
      throw Exception('Failed to create Setup Intent: ${response.body}');
    }
  }

Future<void> initsetupIntent() async {
  try {
    // 1. create payment intent on the server
    final data = await _createSetupIntent();
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;
    // 2. initialize the payment sheet
  final setupIntent = await Stripe.instance.confirmSetupIntent(
      paymentIntentClientSecret: data['clientSecret'],
      params: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: BillingDetails(
            email: email,
          ),
        ),
      ),
    );
    if (setupIntent.status.toLowerCase() == 'succeeded') {
      _customerId = data["customerId"];

      final url = Uri.parse('https://europe-west2-test-7a857.cloudfunctions.net/makeDefaultPayment');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerId': data["customerId"],
          'paymentId': setupIntent.paymentMethodId,
        }),
      );
      if (response.statusCode == 200){
        setState(() {
          _payReady = true;
        });
      }else{
        throw Exception('Failed to make the payment');
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    rethrow;
  }
}

Future<void> subscriptionSetup() async {
  final url = Uri.parse(
      'https://europe-west2-test-7a857.cloudfunctions.net/createStripeSubscription');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'uid' : Auth().currentUser(),
      'customerId' : _customerId,
      'planId': priceIds[_selectedIndex],
    }),
  );

  if (response.statusCode == 200) {
    await UserPreferences.setAppsMax(5);
    Navigator.of(context).pop();
  } else {
    throw Exception('Failed to setup subscription: ${response.body}');
  }
}

  void fetchDefaultPaymentMethod() async {
    try{
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(Auth().currentUser())
          .get();

      final response = await http.post(
        Uri.parse('https://europe-west2-test-7a857.cloudfunctions.net/checkDefaultPaymentMethod'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{'customerId': userDoc.get("StripeCustomerId")}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        CardFieldInputDetails inpDetails = const CardFieldInputDetails(complete: false);
        if (data['paymentMethod'] != null){
          paymentMethod = data['paymentMethod'];
          final last4 = paymentMethod["card"]["last4"];
          final expMonth = paymentMethod["card"]["expMonth"];
          final expYear = paymentMethod["card"]["expYear"];
          CardFieldInputDetails(
            complete: true, // Assuming the card details are complete
            last4: last4,
            expiryMonth: expMonth,
            expiryYear: expYear,
            postalCode: paymentMethod["billingDetails"]["address"]["postalCode"] ?? "", // You may not have the postal code in the PaymentMethod
            brand: paymentMethod["card"]["brand"], // Assuming PaymentMethod has brand information
            number: '',
            cvc: '',
            validExpiryDate: CardValidationState.Valid,
            validCVC: CardValidationState.Valid,
            validNumber: CardValidationState.Valid,
          );
        }

        setState(() {
          controller = CardFormEditController( initialDetails: inpDetails);
          _appReady = true;
          _hasDefaultPayment = data['hasDefaultPaymentMethod'];
          _payReady = data['hasDefaultPaymentMethod'];
        });
      } else {
        throw Exception('Failed to fetch default payment method');
      }
    } catch (err){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')),
      );
    }
    // Make an HTTP request to your Firebase Cloud Function to fetch the default payment method details
  }

}
