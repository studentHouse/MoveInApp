import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import 'Themes/lMode.dart';

class CustomNavbar extends StatelessWidget {
  const CustomNavbar({Key? key, required this.onItemSelected})
      : super(key: key);

  final Function(String) onItemSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 0,
      color: LAppTheme.lightTheme.primaryColor,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(42), topRight: Radius.circular(42)),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [
                  LAppTheme.lightTheme.primaryColor.withAlpha(150),
                  LAppTheme.lightTheme.primaryColor.withAlpha(200),
                  LAppTheme.lightTheme.primaryColor,
                  LAppTheme.lightTheme.primaryColor,
                ],
                stops: const [
                  0.1,
                  0.3,
                  0.9,
                  1.0
                ])),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              onPressed: () {
                onItemSelected('/Scroller');
              },
              icon: const Icon(LineAwesomeIcons.bars),
              color: Colors.white,
            ),
            IconButton(
              onPressed: () {
                onItemSelected('/Friends');
              },
              icon: const Icon(Icons.group),
              color: Colors.white,
            ),
            IconButton(
              onPressed: () {
                onItemSelected('/Profile');
              },
              icon: const Icon(Icons.person),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
