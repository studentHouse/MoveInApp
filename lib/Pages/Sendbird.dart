import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sendbird_sdk/sendbird_sdk.dart';
import 'package:movein/Pages/Messages.dart' as mb;

class ConnectSendbird {
  Future<User> connect(
      String appId, String userId, String nickname, String accessToken) async {
    // Init Sendbird SDK and connect with current user id
    try {
      final sendbird = SendbirdSdk(
          appId: appId, apiToken: '93105a021966bf8582f776513998364b68e6fd3e');
      print(userId + nickname);
      final user = await sendbird.connect(userId,
          nickname: nickname, accessToken: accessToken);
      print('success');
      return user;
    } catch (e) {
      print('login_view: connect: ERROR: $e');
      rethrow;
    }
  }

  Future<String> findChannel(String channelUrl) async {
    try {
      final channel = await GroupChannel.getChannel(channelUrl);
      return 'success';
    } catch (e) {
      return 'Error';
    }
  }

  Future<GroupChannel> returnChannel(String channelUrl) async {
    try {
      final channel = await GroupChannel.getChannel(channelUrl);
      return channel;
    } catch (e) {
      print('Error retrieving channel');
      throw e;
    }
  }

  Future<GroupChannel> createChannel(String userId, String groupName,
      String? groupIcon, String channelURL) async {
    try {
      final params = GroupChannelParams()
        ..userIds = [userId]
        ..channelUrl = channelURL
        ..name = groupName;
      final groupChannel = await GroupChannel.createChannel(params);
      return groupChannel;
      //..coverImage = groupIcon;
    } catch (e) {
      print('createChannel: ERROR: $e');
      throw e;
    }
  }

  Future<GroupChannel> createDM(
      List<String> userIds, String groupName, String? groupIcon) async {
    try {
      userIds.sort();
      final params = GroupChannelParams()
        ..userIds = userIds
        ..channelUrl = userIds[0] + userIds[1]
        ..isDistinct = true
        ..customType = 'DM'
        ..name = groupName;
      final groupChannel = await GroupChannel.createChannel(params);
      return groupChannel;
      //..coverImage = groupIcon;
    } catch (e) {
      print('createChannel: ERROR: $e');
      throw e;
    }
  }

  void leaveChannel(String userId, String groupId) async {
    try {
      final channel = await returnChannel(groupId);
      await channel.leave();
    } catch (e) {
      print('Error');
    }
  }

  Future<User> findUserViaId(String userId) async {
    final query = ApplicationUserListQuery();
    query.userIds = [userId];

    try {
      final user = await query.loadNext();
      return user[0];
    } catch (e) {
      throw e;
    }
  }
}
