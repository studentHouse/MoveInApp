import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

@pragma('vm:entry-point')
Future <void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async
{
  debugPrint('[_firebaseMessagingBackgroundHandler()]');
  await _firebaseMessagingBackgroundHandler
      (

        message,
        //isBackgroundMessage:true,
      );
}

//Future<void> _firebaseMessa
class Notifications {
static Future<bool> registerPushToken() async
{
  if (kIsWeb) return false;

  final token = await _getToken();
  if (token != null)
  {
    PushTokenRegistrationStatus status = await _registerPushToken(token);
    switch (status) {
      case PushTokenRegistrationStatus.success:
        return true;
      case PushTokenRegistrationStatus.pending:
      case PushTokenRegistrationStatus.error:
        return false;

    }

  }
  return false; 
}

  static Future<PushTokenRegistrationStatus> _registerPushToken(
      String token) async {
    final pushTokenType = _getPushTokenType();
    
    if (pushTokenType != null) {
      return await SendbirdChat.registerPushToken(
        type: pushTokenType,
        token: token,
        unique: true,
      );
    }
    return PushTokenRegistrationStatus.error;
  }

    static Future<String?> _getToken() async {
    String? token;
    if (Platform.isAndroid) {
      token = await FirebaseMessaging.instance.getToken();
    } else if (Platform.isIOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
    }
    return token;
  }

  static PushTokenType? _getPushTokenType() {
    PushTokenType? pushTokenType;
    if (Platform.isAndroid) {
      pushTokenType = PushTokenType.fcm;
    } else if (Platform.isIOS) {
      pushTokenType = PushTokenType.apns;
    }
    return pushTokenType;
  }
}
