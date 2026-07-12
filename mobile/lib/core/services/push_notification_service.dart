import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../Features/devices/actuators/ac/presentation/manager/ac_control_cubit.dart';
import '../network/api_constants.dart';
import '../network/api_service.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../utils/constants/app_colors.dart';
import '../utils/functions/device_helpers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("Background message received: ${message.notification?.title}");
}

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'TURN_OFF_AC') {
    final String? deviceId = notificationResponse.payload;
    log('Background Action: TURN_OFF_AC triggered for device: $deviceId');

    if (deviceId != null) {
      try {
        // this line ensures that the Flutter engine is initialized before making any API calls to make sure secure storage are ready to be used in the background
        WidgetsFlutterBinding.ensureInitialized();

        // new instance of the API service to make the request
        final api = APiService();

        await api.post(
          ApiConstants.deviceCommands(deviceId),
          data: {
            "action": "SET_STATE",
            "parameters": {"power": "OFF"}
          },
        );

        // cancel the ongoing notification after successfully turning off the AC
        await FlutterLocalNotificationsPlugin().cancel(id: 888);
        log("AC turned off from background successfully!");
      } catch (e) {
        log("Failed to turn off AC in background: $e");
      }
    }
  }
}

class PushNotificationService {
  final _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final APiService apiService;

  final _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationReceived =>
      _notificationStreamController.stream;
  PushNotificationService(this.apiService);

  Future<void> init() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    const AndroidNotificationChannel timerChannel = AndroidNotificationChannel(
      'timer_channel',
      'Active Timers',
      description: 'Shows ongoing AC timers',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerChannel);

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // 1. Asking user for permission to receive notifications.
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      log('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      log('Error requesting permission: $e');
    }

    // 2. Extract the FCM Token
    try {
      String? token = await _fcm.getToken();
      log('FCM Token: $token');
    } catch (e) {
      log('Error getting token: $e');
    }

    // 3. Receive notifications when the app is in the foreground

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('=== NEW MESSAGE RECEIVED IN FOREGROUND ===');

      log('Notification Block: ${message.notification?.toMap()}');

      log('Data Block: ${message.data}');

      log('=============================================');

      if (message.notification != null) {
        log('The message has a notification block. Showing local notification...');
        _showLocalNotification(message);
        _notificationStreamController.add(message);
      } else {
        log('ALERT: The notification block is NULL! Jana sent a "Data-Only" message.');
      }
      log('Message received in Foreground!');
      // if (message.notification != null) {
      //   log('Title: ${message.notification?.title}');

      //   _showLocalNotification(message);
      // }
    });

    // 4. Receive notifications when the app is in the background or terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      log("FCM Token refreshed by Firebase: $newToken");
      await _updateTokenOnBackend(newToken);
    });
  }

  Future<void> showACTimerNotification({
    required int durationInMinutes,
    required String deviceId,
  }) async {
    try {
      // calculate the end time for the timer notification
      final int endTime = DateTime.now()
          .add(Duration(minutes: durationInMinutes))
          .millisecondsSinceEpoch;

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'timer_channel',
        'Active Timers',
        channelDescription: 'Shows ongoing AC timers',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true, // to make it persistent and not dismissible by swipe
        autoCancel: false,
        usesChronometer: true, // turn on the chronometer
        chronometerCountDown: true, // count down instead of up
        when: endTime,
        color: AppColors.jetBlack,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'TURN_OFF_AC',
            'Turn Off Now',
            cancelNotification:
                true, // turn off the notification when this action is tapped
            showsUserInterface:
                true, // turn on the app UI when this action is tapped
          ),
        ],
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        id: 888, // Fixed ID for the timer notification so it can be updated or canceled later
        title: 'AC Timer Active',
        body: 'Time remaining until shutoff',
        notificationDetails: platformDetails,
        payload: deviceId, // pass the device ID as payload for action handling
      );

      log('Timer notification displayed successfully!');
    } catch (e) {
      log('Error showing timer notification: $e');
    }
  }

  // handle the action when the user taps "Turn Off Now" from the notification
  void _handleNotificationAction(NotificationResponse response) async {
    if (response.actionId == 'TURN_OFF_AC') {
      final String? deviceId = response.payload;
      log('Foreground Action: Turning off AC for device [$deviceId]');

      if (deviceId != null) {
        try {
          // 1. Send the command to turn off the AC to the backend
          await apiService.post(
            ApiConstants.deviceCommands(deviceId),
            data: {
              "action": "SET_STATE",
              "parameters": {"power": "OFF"}
            },
          );

          // 2. make sure to update the local state of the AC in the app if it's currently open
          if (GetIt.I.isRegistered<AcControlCubit>()) {
            // make sure the ID is the same as the one in the notification before forcing it to turn off.
            final acCubit = GetIt.I<AcControlCubit>();
            if (acCubit.deviceId == deviceId) {
              acCubit.forceTurnOffLocal();
            }
          }

          // 3. cancel ongoing notification.
          await cancelACTimerNotification();
        } catch (e) {
          log("Failed to turn off AC in foreground: $e");
        }
      }
    }
  }

  // a method to cancel the timer notification when the AC is turned off manually or when the timer expires
  Future<void> cancelACTimerNotification() async {
    await _localNotifications.cancel(id: 888);
  }

  // register the new token with the backend
  Future<void> registerDeviceForNotifications() async {
    try {
      final String hardwareId = await DeviceHelpers.getUniqueHardwareId();
      final String? fcmToken = await _fcm.getToken();

      if (fcmToken == null) {
        log("FCM Token is null, cannot register device.");
        return;
      }

      await apiService.put(
        ApiConstants.userPreferences,
        data: {
          'hardware_id': hardwareId,
          'fcm_token': fcmToken,
          'receive_notifications': true,
          'receive_critical': true,
          'receive_warnings': true
        },
      );

      log("Device [$hardwareId] registered for push notifications successfully!");
    } catch (e) {
      log("Failed to register device: $e");
    }
  }

  // unregister the device
  Future<void> unregisterDevice() async {
    try {
      final String hardwareId = await DeviceHelpers.getUniqueHardwareId();

      await apiService.put(
        ApiConstants.userPreferences,
        data: {
          'hardware_id': hardwareId,
          'fcm_token':
              "", // sends empty string to delete this device notifications.
        },
      );

      log("Device [$hardwareId] unregistered successfully!");
    } catch (e) {
      log("Failed to unregister device: $e");
    }
  }

  // update the token on the backend when it changes
  Future<void> _updateTokenOnBackend(String newToken) async {
    try {
      final String hardwareId = await DeviceHelpers.getUniqueHardwareId();
      await apiService.put(
        ApiConstants.userPreferences,
        data: {
          'hardware_id': hardwareId,
          'fcm_token': newToken,
        },
      );
      log("FCM Token updated on backend for device: $hardwareId");
    } catch (e) {
      log("Failed to update token on backend: $e");
    }
  }

  Future<void> updatePreferences({
    required bool isPushEnabled,
    required bool criticalAlerts,
    required bool warningAlerts,
  }) async {
    try {
      final String hardwareId = await DeviceHelpers.getUniqueHardwareId();
      final String? fcmToken = await _fcm.getToken();

      await apiService.put(
        ApiConstants.userPreferences,
        data: {
          'hardware_id': hardwareId,
          'fcm_token': fcmToken ?? "",
          'receive_notifications': isPushEnabled,
          'receive_critical': criticalAlerts,
          'receive_warnings': warningAlerts,
        },
      );
      log("Notification preferences updated successfully on backend!");
    } catch (e) {
      log("Failed to update preferences: $e");
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      AndroidNotificationDetails androidDetails =
          const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alert_sound'),
        color: AppColors.jetBlack,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentSound: true,
          sound: 'alert_sound.wav',
        ),
      );

      int safeId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        id: safeId,
        title: message.notification?.title,
        body: message.notification?.body,
        notificationDetails: platformDetails,
        payload: message.data.toString(),
      );
      log('Local notification displayed successfully on screen!');
    } catch (e) {
      log(' FATAL ERROR showing local notification: $e');
    }
  }
}
