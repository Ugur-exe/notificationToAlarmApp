// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:developer';
// import 'package:audio_session/audio_session.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:just_audio_background/just_audio_background.dart';
// import 'package:nofication_to_audio/alarm_page.dart';
// import 'package:nofication_to_audio/main.dart';
// import 'package:vibration/vibration.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();
//   static final AudioPlayer _audioPlayer = AudioPlayer();
//   static int _notificationId = 0;
//   static const String stopActionId = 'stop_audio';
//   static bool _isNotificationActive = false;
//   // Titreşim modelini Int64List olarak tanımla
//   static final Int64List vibrationPattern =
//       Int64List.fromList([0, 500, 200, 500]);

//   static Future<void> initialize() async {
//     try {
//       await JustAudioBackground.init(
//         androidNotificationChannelId: 'com.app.bg_demo.channel.audio',
//         androidNotificationChannelName: 'Audio playback',
//         androidNotificationOngoing: true,
//       );
//     } catch (e) {
//       log('HATA: $e');
//     }

//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration(
//       avAudioSessionCategory: AVAudioSessionCategory.playback,
//       avAudioSessionCategoryOptions:
//           AVAudioSessionCategoryOptions.mixWithOthers,
//       avAudioSessionMode: AVAudioSessionMode.defaultMode,
//       androidAudioAttributes: AndroidAudioAttributes(
//         contentType: AndroidAudioContentType.music,
//         flags: AndroidAudioFlags.audibilityEnforced,
//         usage: AndroidAudioUsage.media,
//       ),
//       androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
//       androidWillPauseWhenDucked: true,
//     ));

//     final androidChannel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//       vibrationPattern: vibrationPattern, // Int64List kullan
//     );

//     await _notifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(androidChannel);

//     await _notifications.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@mipmap/ic_launcher'),
//         iOS: DarwinInitializationSettings(
//           requestSoundPermission: true,
//           requestBadgePermission: true,
//           requestAlertPermission: true,
//         ),
//       ),
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         if (response.actionId == stopActionId) {
//           _audioPlayer.stop();
//           stopVibration();
//         }
//       },
//     );
//     await _notifications.cancelAll();
//     _isNotificationActive = false;
//   }

//   static Future<void> showNotification(RemoteMessage message) async {
//     if (_isNotificationActive) {
//       log('Active notification exists, new notification will not be shown');
//       return;
//     }

//     try {
//       _isNotificationActive = true;
//       _notificationId++;

//       await playBackgroundAudio();
//       startVibration();

//       // Set notification icon and content
//       await _notifications.show(
//         _notificationId,
//         message.notification?.title ?? 'Alarm',
//         message.notification?.body ?? '',
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             channelDescription:
//                 'This channel is used for important notifications',
//             importance: Importance.max,
//             priority: Priority.max,
//             fullScreenIntent: true, // Enable full-screen intent
//             color: Colors.red,
//             enableLights: true,
//             ledColor: Colors.red,
//             ledOnMs: 1000,
//             ledOffMs: 500,
//             ticker: 'Alarm Notification',
//             playSound: false,
//             enableVibration: true,
//             vibrationPattern: vibrationPattern,
//             icon: '@mipmap/ic_launcher', // Make sure the icon is present
//           ),
//           iOS: DarwinNotificationDetails(
//             presentSound: false,
//           ),
//         ),
//       );

//       // Open the Alarm page
//       try {
//         // await Navigator.push(
//         //   navigatorKey.currentContext!,
//         //   MaterialPageRoute(
//         //     builder: (context) => AlarmPage(),
//         //   ),
//         // );
//       } catch (e) {
//         log('Failed to open Alarm Page: $e');
//       }
//     } catch (e) {
//       log('Notification error: $e');
//       _isNotificationActive = false;
//     }
//   }

//   // Sürekli titreşim için Timer
//   static Timer? _vibrationTimer;

//   static void startVibration() {
//     if (_vibrationTimer?.isActive ?? false) return;

//     // Her 1 saniyede bir titret
//     _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       Vibration.vibrate(
//         pattern: [0, 500, 200, 500], // Normal List<int> kullan
//         intensities: [0, 255, 128, 255],
//       );
//     });
//   }

//   static Future<void> clearNotification() async {
//     await _notifications.cancelAll();
//     _isNotificationActive = false;
//     stopVibration();
//     await _audioPlayer.stop();
//   }

//   static void stopVibration() {
//     _vibrationTimer?.cancel();
//     _vibrationTimer = null;
//     Vibration.cancel();
//   }

//   static Future<void> playBackgroundAudio() async {
//     try {
//       await _audioPlayer.setAudioSource(
//         AudioSource.uri(
//           Uri.parse('asset:///assets/sounds/alarm_sound.mp3'),
//         ),
//       );

//       await _audioPlayer.play();
//       log('Ses çalmaya başladı');

//       await _audioPlayer.processingStateStream.firstWhere(
//         (state) => state == ProcessingState.completed,
//       );

//       log('Ses çalma tamamlandı');
//       stopVibration();
//     } catch (e) {
//       log('Ses çalma hatası: $e');
//       stopVibration();
//     }
//   }

//   static Future<void> handleBackgroundMessage(RemoteMessage message) async {
//     await showNotification(message);
//   }

//   static void dispose() {
//     _audioPlayer.dispose();
//     stopVibration();
//     clearNotification();
//   }
// }

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   await NotificationService.handleBackgroundMessage(message);
// }
