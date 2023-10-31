import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CardProfile {
  final String id;
  final String foreName;
  final int age;
  final String uni;
  final Map<String,dynamic> preferences;
  final List<String> images;
  final String bio;
  final String subject;
  final int yearOfStudy;
  final bool isVerified;

  CardProfile({
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
  });

  factory CardProfile.fromFirestore(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final dateTime = data['DOB'].toDate();
    final currentDate = DateTime.now();
    final difference = currentDate.difference(dateTime);
    final yearsAgo = difference.inDays ~/ 365;

    final preferencesData = data['Preferences'] as Map<String, dynamic>?; // Check if 'Preferences' exists and assign it to preferencesData
    final castedPreferences = <String, dynamic>{};
    preferencesData?.forEach((key, value) {
      if (key == 'NightLife' || key == 'Cleanliness' || key == 'Noisiness') {
        castedPreferences[key] = value.toInt();
      } else {
        castedPreferences[key] = value;
      }
    });
    final bed_dateTime = preferencesData?['BedTime']?.toDate(); // Check if 'BedTime' exists within preferencesData and assign it to bed_dateTime
    final timeFormat = DateFormat('hh:mm a');
    final timeOfDay = bed_dateTime != null ? timeFormat.format(bed_dateTime) : ''; // Format the time only if bed_dateTime is not null


    return CardProfile(
      id: document.id,
      foreName: data['ForeName'],
      age: yearsAgo,
      uni: data['UniAttended'],
      preferences: castedPreferences ?? {},
      images: List<String>.from(data['Images']),
      bio: data['Bio'],
      subject: data['Subject'],
      yearOfStudy: data['YearOfStudy'].toInt(),
      isVerified: data['EmailVerified'],
    );
  }

  static Future<CardProfile> fetchCardProfile(String id) async {
    final document = await FirebaseFirestore.instance.collection('Users').doc(id).get();

    if (document.exists) {
      return CardProfile.fromFirestore(document);
    } else {
      throw Exception('CardProfile not found for id: $id');
    }
  }
}