import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:movein/Friend%20And%20Groups%20Code/FriendFunctions.dart';
import 'package:movein/Themes/lMode.dart';
import '../Auth code/auth.dart';
import '../main.dart';

const rootImagePath = 'https://movein.blob.core.windows.net/moveinimages/';

class SwipeCard extends StatelessWidget {
  final String id;
  final String foreName;
  final int age;
  final String uni;
  final Map<String, dynamic> preferences;
  final String bio;
  final String subject;
  final int yearOfStudy;
  final List<String> images;
  final bool showFriend;
  final bool isVerified;

  const SwipeCard({
    Key? key,
    required this.id,
    required this.foreName,
    required this.age,
    required this.uni,
    required this.preferences,
    required this.images,
    required this.bio,
    required this.subject,
    required this.yearOfStudy,
    required this.isVerified,
    this.showFriend = false,

  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    var profileImage = '${images[0]}.jpg';
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = width; // Calculate the height based on the width

        return GestureDetector(
          onTap: () {
            showDialog<String>(
                context: context,
                builder: (BuildContext context) => CustomDialog(id: id,foreName: foreName ,age: age, uni: uni, preferences: preferences,images: images, bio: bio, subject: subject, yearOfStudy: yearOfStudy, showFriend: showFriend, isVerified: isVerified)
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16.0, 5.0, 16.0, 5.0),
            // Need to do more testing to see if this is okay
            // height: height,
            child: Container(
              margin: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 4.0),
                    child: Stack(
                      alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(
                        child: Container(
                          height: 400,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(40)),
                            boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(
                        5.0,
                        5.0,
                      ),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ), //BoxShadow
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(0.0, 0.0),
                      blurRadius: 0.0,
                      spreadRadius: 0.0,
                    ), //BoxShadow
                  ],
                            image: DecorationImage(
                              image: profileImage == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('$rootImagePath$profileImage'),
                              fit: BoxFit.fill
                            )
                            )
                          ),
                        ),
                      Positioned(
                        top: 0,
                        left: 20,
                        child: Row(
                          children: [
                            Text(
                                "$foreName - $age",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  shadows: <Shadow>[
                                    Shadow(
                                      offset: Offset(2, 2), // Adjust the values for the shadow's position
                                      blurRadius: 6.0,     // Adjust the blur radius as needed
                                      color: Colors.black.withOpacity(0.5), // Adjust the shadow color and opacity
                                    ),
                                  ],
                                )

                            ),
                            const SizedBox(width: 10),
                            if (isVerified)
                              Container(
                                width: 15, // Adjust the width and height as needed
                                height: 15,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                ),
                              )
                          ]
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        child: SizedBox(
                          width: width * 0.8,
                          child: Center(
                            child: Text(
                                      bio,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.normal,
                                        shadows: <Shadow>[
                                          Shadow(
                                            offset: const Offset(2, 2), // Adjust the values for the shadow's position
                                            blurRadius: 6.0,     // Adjust the blur radius as needed
                                            color: Colors.black.withOpacity(0.5), // Adjust the shadow color and opacity
                                          ),
                                        ],
                                      ),
                                  ),
                          ),
                        ),
                      ),
                    ],
              ),
            )],
          ),
        )),
    );});
  }
}

class RoundedBox extends StatelessWidget {
  final String image;
  const RoundedBox({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = width; // Calculate the height based on the width,
        return Container(
          margin: const EdgeInsets.fromLTRB(16.0, 5.0, 16.0, 5.0),
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(255, 67, 67, 67),
                spreadRadius: 0,
                blurRadius: 6,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              // This needs to be remade - formatting is fucked
              // child: Image(
              //   image: AssetImage(image),
              //   fit: BoxFit.cover,
              // ),
              child: Image.network('$rootImagePath$image'),
            ),
          ),
        );
      },
    );
  }
}

class CustomDialog extends StatefulWidget {
  final List<dynamic> images;
  final String id;
  final String foreName;
  final int age;
  final String uni;
  final Map<String, dynamic> preferences;
  final String bio;
  final String subject;
  final int yearOfStudy;
  final bool showFriend;
  final bool isVerified;
  const CustomDialog({
    Key? key,
    required this.id,
    required this.foreName,
    required this.age,
    required this.uni,
    required this.preferences,
    required this.images,
    required this.bio,
    required this.subject,
    required this.yearOfStudy,
    required this.isVerified,
    this.showFriend = false,
  }) : super(key: key);

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  bool _friended = false;

  @override
  Widget build(BuildContext context) {
    DateTime? dateTime;
    String formattedTime = '';

    if (widget.preferences.containsKey("Lights Out")) {
      var lightsOutValue = widget.preferences["Lights Out"];
      if (lightsOutValue is Timestamp) {
        dateTime = lightsOutValue.toDate();
        DateFormat timeFormat = DateFormat.jm();
        formattedTime = timeFormat.format(dateTime);
      }
    }

    List<Widget> preferenceWidgets = widget.preferences.entries.map((entry) {
      if (entry.key == "Lights Out") {
        return Text(
          " - ${"asleep-by".tr}: $formattedTime",
          style: Theme.of(context).textTheme.bodyMedium,
        );
      } else {
        switch (entry.key) {
          case 'Cleanliness':
            return Text(
              ' - ${"my-cleanliness-importance".tr}: ${entry.value}/5',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          case 'Noisiness':
            return Text(
              ' - ${"my-noisiness-importance".tr}: ${entry.value}/5',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          case 'NightLife':
            return Text(
              ' - ${"my-nightlife-importance".tr}: ${entry.value}/5',
              style: Theme.of(context).textTheme.bodyMedium,
            );
          default:
            return Text(
              ' - Empty',
              style: Theme.of(context).textTheme.bodyMedium,
            );
        }
      }

    }).toList();

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).canvasColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        width: MediaQuery.of(context).size.width * 0.90,
        height: MediaQuery.of(context).size.height * 0.90,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Stack(
          children: [
            SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.images.length+5,
                itemBuilder: (context, index) {
                  switch(index){
                    case 0 :{
                      return const SizedBox(
                        height: 25,
                      );
                    }
                    case 1 :{
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          //width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // Shadow color
                                spreadRadius: 2, // Spread radius
                                blurRadius: 5, // Blur radius
                                offset: const Offset(0, 2), // Offset of the shadow
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text("${widget.foreName} (${widget.age})", style: Theme.of(context).textTheme.headlineMedium,),
                                Container(
                                  width: 15, // Adjust the width and height as needed
                                  height: 15,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ]),
                              Text(widget.id, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      );
                    }
                    case 2: {
                      return Container(
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          image: DecorationImage(
                            image: widget.images[index-2] == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('${rootImagePath + widget.images[index-2]}.jpg'),
                            fit: BoxFit.fill
                          )
                        ),
                      );
                    }
                    case 3: {
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          //width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // Shadow color
                                spreadRadius: 2, // Spread radius
                                blurRadius: 5, // Blur radius
                                offset: const Offset(0, 2), // Offset of the shadow
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${"attends".tr} ${widget.uni}", style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height:3),
                              Text("${"studying".tr} ${widget.subject}", style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    }
                    case 4: {
                      // return RoundedBox(image: widget.images[index-3]);
                      return Container(
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          image: DecorationImage(
                            image: widget.images[index-3] == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('${rootImagePath + widget.images[index-3]}.jpg'),
                            fit: BoxFit.fill
                          )
                        ),
                      );
                    }
                    case 5: {
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          //width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5), // Shadow color
                                spreadRadius: 2, // Spread radius
                                blurRadius: 5, // Blur radius
                                offset: const Offset(0, 2), // Offset of the shadow
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${"bio".tr}:", style: Theme.of(context).textTheme.headlineSmall),
                              Text(widget.bio, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    }
                    case 6: {
                      // return RoundedBox(image: widget.images[index-4]);
                      return Container(
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          image: DecorationImage(
                            image: widget.images[index-4] == '' ? const NetworkImage('https://movein.blob.core.windows.net/moveinimages/noimagefound.png') : NetworkImage('${rootImagePath + widget.images[index-4]}.jpg'),
                            fit: BoxFit.fill
                          )
                        ),
                      );
                    }
                    case 7: {
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                            padding: const EdgeInsets.all(10),
                            //width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              color: (App.themeNotifier.value == ThemeMode.dark)? Theme.of(context).primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5), // Shadow color
                                  spreadRadius: 2, // Spread radius
                                  blurRadius: 5, // Blur radius
                                  offset: const Offset(0, 2), // Offset of the shadow
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${"preferences".tr}:", style: Theme.of(context).textTheme.headlineSmall,),
                                const SizedBox(height: 5), // Add a small gap between title and widgets
                                ...preferenceWidgets.map((widget) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget,
                                    const SizedBox(height: 5), // Add a small gap between preference widgets
                                  ],
                                )),
                              ],
                            )

                        ),
                      );
                    }
                    // Not needed as there are only 3 images per user
                    // default: {
                    //   return RoundedBox(image: widget.images[index-5]);
                    // }
                  }
                  return null;
                },
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                splashRadius: 20,
                icon: const Icon(LineAwesomeIcons.times_circle),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Visibility(
              visible: widget.showFriend,
              child: Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  splashRadius: 20,
                  icon: _friended?  Icon(LineAwesomeIcons.user_check, color: LAppTheme.lightTheme.primaryColor,) : const Icon(LineAwesomeIcons.user_plus),
                  onPressed: () {
                    if(!_friended){
                      sendFriendInvite(widget.id, Auth().currentUser(),);
                    }
                    setState(() {
                      _friended = true;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
