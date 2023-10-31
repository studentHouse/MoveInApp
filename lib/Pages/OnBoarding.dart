import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';

import 'Scroller.dart';

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: IntroductionScreen(
            pages: [
              PageViewModel(
                title: "welcome".tr,
                body: "welcome-desc".tr,
                image: buildImage("assets/Pictures/1.png"),
                decoration: getPageDecoration(context),
              ),
              PageViewModel(
                title: "page-1-title".tr,
                body: "page-1-desc".tr,
                image: buildImage("assets/Pictures/2.png"),
                decoration: getPageDecoration(context),
              ),
              PageViewModel(
                  title: "page-2-title".tr,
                  body: "page-2-desc".tr,
                  image: buildImage("assets/Pictures/3.png"),
                  decoration: getPageDecoration(context),
              ),
              PageViewModel(
                title: "page-3-title".tr,
                body: "page-3-desc".tr,
                  image: buildImage("assets/Pictures/4.png"),
                  decoration: PageDecoration(
                    pageColor: Theme.of(context).canvasColor,
                    imageFlex: 7,
                    bodyFlex: 4,
                  ),
              ),
              PageViewModel(
                title: "page-4-title".tr,
                body: "page-4-desc".tr,
                image: buildImage("assets/Pictures/5.png"),
                decoration: PageDecoration(
                  pageColor: Theme.of(context).canvasColor,
                  imageFlex: 7,
                  bodyFlex: 4,
                ),
              ),
              PageViewModel(
                title: "page-4.5-title".tr,
                body: "page-4.5-desc".tr,
                image: buildImage("assets/Pictures/6.png"),
                decoration: PageDecoration(
                  pageColor: Theme.of(context).canvasColor,
                  imageFlex: 7,
                  bodyFlex: 4,
                ),
              ),
              PageViewModel(
                title: "page-5-title".tr,
                body: "page-5-desc".tr,
                  image: buildImage("assets/Pictures/7.png"),
                  decoration: getPageDecoration(context),
              ),
            ],

            done: Text("got-it".tr, style: Theme.of(context).textTheme.bodyMedium),
            onDone: () => Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Scroller(), duration: const Duration(milliseconds: 200))),
            showSkipButton: true,
            skip: Text('skip'.tr, style: Theme.of(context).textTheme.bodyMedium),
            onSkip: () => Navigator.pushReplacement(context, PageTransition(type: PageTransitionType.fade, child: const Scroller(), duration: const Duration(milliseconds: 200))),
            next: const Icon(LineAwesomeIcons.arrow_right, color: Colors.black87),
            dotsDecorator: getDotDecoration(context),
            dotsFlex: 2,
            nextFlex: 1,
            skipOrBackFlex: 1,
          )
      ),
    );
  }

  Widget buildImage(String path) =>
      Center(child: Image.asset(path, width: 350));


  PageDecoration getPageDecoration(context) => PageDecoration(
    titleTextStyle: Theme.of(context).textTheme.headlineSmall ?? GoogleFonts.lexend(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 20.0),
    bodyTextStyle: Theme.of(context).textTheme.bodyMedium ?? GoogleFonts.redHatDisplay(color: Colors.black87, fontSize: 16.5),
    imagePadding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
    titlePadding: const EdgeInsets.all(4),
    bodyPadding: const EdgeInsets.all(8).copyWith(bottom: 0),
    pageColor: Theme.of(context).canvasColor,
    imageFlex: 10,
    bodyFlex: 3,
    footerFlex: 3,
      );

  DotsDecorator getDotDecoration(context) => DotsDecorator(
    color: Colors.grey,
    activeColor: Theme.of(context).primaryColor,
    size: const Size(8, 8),
    activeSize: const Size(18, 12), // Decrease the size a bit
    spacing: const EdgeInsets.symmetric(horizontal: 4), // Add some horizontal spacing between dots
    activeShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Adjust the border radius
    ),
  );

}