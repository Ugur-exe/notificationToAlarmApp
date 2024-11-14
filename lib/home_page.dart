import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/notification_settings.dart' as alarm_settings;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nofication_to_audio/alarm_page.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<AlarmSettings> alarms;

  @override
  void initState() {
    super.initState();
    //notifcation permission
    checkAndroidNotificationPermission();
    //schedule alarm permission
    checkAndroidScheduleExactAlarmPermission();
    loadAlarms();
    //listen alarm if active than navigate to alarm screen
  }

  void loadAlarms() {
    setState(() {
      alarms = Alarm.getAlarms();
      alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    });
  }

  Future<void> checkAndroidNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      alarmPrint('Requesting notification permission...');
      final res = await Permission.notification.request();
      alarmPrint(
        'Notification permission ${res.isGranted ? '' : 'not '}granted',
      );
    }
  }

  Future<void> navigateToRingScreen(AlarmSettings alarmSettings) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            AlarmNotificationScreen(alarmSettings: alarmSettings),
      ),
    );
    loadAlarms();
  }

  Future<void> checkAndroidScheduleExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (kDebugMode) {
      print('Schedule exact alarm permission: $status.');
    }
    if (status.isDenied) {
      if (kDebugMode) {
        print('Requesting schedule exact alarm permission...');
      }
      final res = await Permission.scheduleExactAlarm.request();
      if (kDebugMode) {
        print(
            'Schedule exact alarm permission ${res.isGranted ? '' : 'not'} granted.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('qwjdnwqnodq9dqw'),
      ),
      body: ListView(
        children: List.generate(
            alarms.length,
            (index) => ListTile(
                  title: Text(alarms[index].dateTime.toString()),
                )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var alarmDateTime = DateTime.now().add(const Duration(seconds: 5));
          final alarmSettings = AlarmSettings(
            id: 42,
            dateTime: alarmDateTime,
            assetAudioPath: 'assets/alarm_sound.mp3',
            loopAudio: true,
            vibrate: true,
            fadeDuration: 3.0,
            androidFullScreenIntent: true,
            notificationSettings: const alarm_settings.NotificationSettings(
              title: 'Başlık',
              body: 'Body',
              stopButton: 'Stop the alarm',
            ),
          );

          await Alarm.set(alarmSettings: alarmSettings);
          loadAlarms();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
