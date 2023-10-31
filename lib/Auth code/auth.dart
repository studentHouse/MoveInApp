import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// For Sendgrid mailing
import 'package:sendgrid_mailer/sendgrid_mailer.dart';

void sendEmail(to, userid) async {
  print('Email is being sent to $to');
  print('ID for user is $userid');
  final mailer = Mailer(
      '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');
  final toAddress = Address(to);
  const fromAddress = Address('feedback@move1n.co.uk');
  final content = Content('text/html',
      '<html><h2>MoveIn Email Verification</h2><br></br><p>Hi Billy,</p><p>Please click the verification email below to verify your MoveIn account.</p><p><a href="https://www.move1n.co.uk/verifyuser/$userid">Verify</a></p><p>Many thanks,</p><p>The MoveIn Team</p></html>');
  const subject = 'MoveIn - Email Verification';
  final personalization = Personalization([toAddress]);

  final email =
      Email([personalization], fromAddress, subject, content: [content]);
  mailer.send(email).then((result) {
    print('Email has been sent.');
  }).catchError((err) {
    print('Email failed to send with error - $err');
  });
}

class Auth {
  //Creating new instance of firebase auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> hasAccount(String email) async {
    final List methods = await _auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  String currentUser() {
    final User? user = _auth.currentUser;
    final uid = user?.uid.toString();
    return uid ?? "";
  }

  addAccessToken(String accessToken, String userId) {
    FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .update({'AccessToken': accessToken}).then((_) {
      print('Success');
    }).catchError((error) {
      print('failed');
    });
  }

  Future<String> registerWithUserDetails(
      String email, String password, Map<String, dynamic> details) async {
    try {
      // This will create a new user in our firebase
      var user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      FirebaseFirestore.instance
          .collection("Users")
          .doc(user.user?.uid)
          .set(details);

      return 'success';
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return 'Unknown error.';
    }
  }

  Future<String> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // This will Log in the existing user in our firebase
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? uid = FirebaseAuth.instance.currentUser?.uid;

      final user =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      var y = user.data();
      var emailv = y!['EmailVerified'];
      if (emailv == true) {
        return 'success';
      } else {
        sendEmail(email, uid);
        return 'email verification';
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return e.code;
    } catch (e) {
      print(e);
      return "Unknown error.";
    }
  }
}
