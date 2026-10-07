import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Runs when a push arrives while the app is backgrounded or terminated.
/// Must be a top-level (or static) function — the OS calls it in its own isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Messages that include a "notification" block are shown by the OS
  // automatically even here, so there's nothing to do unless you later
  // send data-only payloads.
}

class PushNotifications {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'order_updates',
    'Order updates',
    'Notifications about your print order status',
    importance: Importance.high,
  );

  /// Call once at app startup, before sign-in state is known.
  static Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _local.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(_channel.id, _channel.name, _channel.description,
              importance: Importance.high, priority: Priority.high),
        ),
      );
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _messaging.onTokenRefresh.listen((_) => syncToken());
  }

  /// Call right after a user signs in (and again on token refresh) to save
  /// this device's token to their Firestore profile.
  static Future<void> syncToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}
