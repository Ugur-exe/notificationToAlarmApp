import 'dart:io';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class AlarmNotificationScreen extends StatefulWidget {
  AlarmSettings alarmSettings;
  AlarmNotificationScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmNotificationScreen> createState() =>
      _AlarmNotificationScreenState();
}

class _AlarmNotificationScreenState extends State<AlarmNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Alram is ringing......."),
          const Text('NBqaqweewq'),
          const Text('body'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    //skip alarm for next time
                    final now = DateTime.now();
                    Alarm.set(
                      alarmSettings: widget.alarmSettings.copyWith(
                        dateTime: DateTime(
                          now.year,
                          now.month,
                          now.day,
                          now.hour,
                          now.minute,
                        ).add(const Duration(minutes: 1)),
                      ),
                      // ignore: use_build_context_synchronously
                    ).then((_) => Navigator.pop(context));
                  },
                  child: const Text("Snooze")),
              ElevatedButton(
                onPressed: () {
                  // Alarmı durdur
                  Alarm.stop(widget.alarmSettings.id).then((_) {
                    // Uygulamayı kapat
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0); // iOS'ta uygulamayı kapatır
                    }
                  });
                },
                child: const Text("Stop"),
              )
            ],
          )
        ],
      ),
    );
  }
}
