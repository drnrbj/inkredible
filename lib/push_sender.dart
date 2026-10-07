import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushSender {
  static const _projectId = 'inkredible-f7b9f'; // your Firebase project ID
  static auth.AutoRefreshingAuthClient? _client;

  static Future<auth.AutoRefreshingAuthClient> _authClient() async {
    if (_client != null) return _client!;
    final jsonStr = await rootBundle.loadString('assets/service_account.json');
    final creds = auth.ServiceAccountCredentials.fromJson(jsonStr);
    _client = await auth.clientViaServiceAccount(
      creds,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );
    return _client!;
  }

  static Future<void> send({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final client = await _authClient();
      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/inkredible-f7b9f/messages:send');
      final res = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            if (data != null) 'data': data,
          },
        }),
      );
      if (res.statusCode >= 300) {
        // Non-fatal: push just doesn't arrive. Log and move on.
        // ignore: avoid_print
        print('FCM send failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('FCM send error: $e');
    }
  }
}