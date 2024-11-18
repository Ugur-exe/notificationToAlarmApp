import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:nofication_to_audio/alarm_page.dart';
import 'package:nofication_to_audio/home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alarm/model/notification_settings.dart' as alarm_settings;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

AlarmSettings? _createAlarmSettingsFromRemoteMessage(RemoteMessage message) {
  try {
    log('Create Alarm Settings Triggered');
    final title = message.notification?.title ?? 'Alarm';
    final body = message.notification?.body ?? 'Time to wake up!';
    var alarmDateTime = DateTime.now().add(const Duration(seconds: 5));

    return AlarmSettings(
      id: 55,
      dateTime: alarmDateTime,
      assetAudioPath: 'assets/alarm_sound.mp3',
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      androidFullScreenIntent: true,
      notificationSettings: alarm_settings.NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop the alarm',
        icon: 'ic_launcher',
      ),
    );
  } catch (e) {
    log('_createAlarmSettingsFromRemoteMessage error: $e');
  }
  return null;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Alarm service
  await Alarm.init();

  log('Mesaj : ${message.messageId} : ${message.sentTime}');
  final alarmSettings = _createAlarmSettingsFromRemoteMessage(message);

  try {
    if (alarmSettings != null) {
      log('Gelen veri null değil');
      await Alarm.set(alarmSettings: alarmSettings);
      log('Alarm set successfully in background');

      // Load alarms after setting
      final alarms = Alarm.getAlarms();
      log('Current alarms count: ${alarms.length}');
      Future.delayed(const Duration(milliseconds: 100));
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('flutter.android/alarm');
          await platform.invokeMethod('wakeUpScreen');
          log('Başarılı channel');
        } catch (e) {
          log('Başarısız Channel : $e');
        }
      }
      await navigatorKey.currentState?.push(
        MaterialPageRoute(
            builder: (_) => AlarmNotificationScreen(
                  alarmSettings: alarmSettings,
                )),
      );
      loadAlarms();
    } else {
      log('Veri null geldi');
    }
  } catch (e) {
    log('firebaseMessagingBackgroundHandler error: $e');
  }
}

void loadAlarms() {
  late List<AlarmSettings> alarms;
  try {
    alarms = Alarm.getAlarms();
    alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
  } catch (e) {
    log('loadAlarms error: $e');
    alarms = []; // Provide a default empty list if there's an error
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Alarm.init();
  await Firebase.initializeApp();

  if (Platform.isAndroid &&
      (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 25) {
    await Permission.notification.request();
  }

  final fcm = await FirebaseMessaging.instance.getToken();
  log('FCM Token: $fcm');

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((message) async {
    log('Message received in foreground');
    final alarmSettings = _createAlarmSettingsFromRemoteMessage(message);
    if (alarmSettings != null) {
      await Alarm.set(alarmSettings: alarmSettings);
      log('Alarm set for foreground notification');
    }
  });

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static StreamSubscription<AlarmSettings>? subscription;

  @override
  void initState() {
    super.initState();
    subscription ??= Alarm.ringStream.stream.listen(navigateToRingScreen);
    loadAlarms();
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await navigatorKey.currentState?.push(
      MaterialPageRoute(
          builder: (_) => AlarmNotificationScreen(
                alarmSettings: alarmSettings,
              )),
    );
    loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Alarm App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
