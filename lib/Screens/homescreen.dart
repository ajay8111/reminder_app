import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reminder_app/Screens/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;
  String? selectedTone;

  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  final List<String> activities = [
    "Wake up",
    "Go to gym",
    "Breakfast",
    "Meetings",
    "Lunch",
    "Quick nap",
    "Go to library",
    "Dinner",
    "Go to sleep"
  ];

  final List<Map<String, String>> reminders = [];

  final AudioPlayer audioPlayer = AudioPlayer();
  final Map<String, String> toneFiles = {
    "Tone 1": "tone1.mp3",
    "Tone 2": "tone2.mp3",
    "Tone 3": "tone3.mp3",
    "Tone 4": "tone4.mp3",
    "Tone 5": "tone5.mp3",
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _loadSelectedTone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel_id',
      'Reminder Notification',
      description: 'Channel for reminder notifications',
      importance: Importance.max,
    );

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _loadSelectedTone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTone =
          prefs.getString('selectedTone') ?? 'Tone 1'; // Default to 'Tone 1'
    });
  }

  void _playSelectedTone() async {
    if (selectedTone != null) {
      final toneFile = toneFiles[selectedTone];
      if (toneFile != null) {
        await audioPlayer.stop();
        await audioPlayer.play(AssetSource('assets/$toneFile'));
      }
    }
  }

  Future<void> _scheduleNotification(
      String time, String activity, String day) async {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();
      final scheduledNotificationDateTime =
          DateTime(now.year, now.month, now.day, hour, minute).isBefore(now)
              ? DateTime(now.year, now.month, now.day + 1, hour, minute)
              : DateTime(now.year, now.month, now.day, hour, minute);

      final tzScheduledNotificationDateTime = tz.TZDateTime(
        tz.local,
        scheduledNotificationDateTime.year,
        scheduledNotificationDateTime.month,
        scheduledNotificationDateTime.day,
        scheduledNotificationDateTime.hour,
        scheduledNotificationDateTime.minute,
      );

      final soundResourceName =
          selectedTone?.replaceAll(' ', '_').toLowerCase() ?? 'tone3';

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'reminder_channel_id',
        'Reminder Notifications',
        channelDescription: 'Channel for reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundResourceName),
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Reminder',
        '$activity at $time on $day',
        tzScheduledNotificationDateTime,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  void _removeReminder(int index) {
    setState(() {
      reminders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 246, 243, 210),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 246, 243, 210),
        title: Text('Reminder App',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(onToneChanged: (tone) {
                    setState(() {
                      selectedTone = tone;
                    });
                    _playSelectedTone(); // Play the new tone immediately
                  }),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a New Reminder',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            SizedBox(height: 16),

            // Day Dropdown
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: InputDecoration(
                labelText: 'Select Day',
                labelStyle: TextStyle(color: Colors.blueGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueGrey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueGrey, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: days.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Time Picker Button
            ElevatedButton.icon(
              icon: Icon(Icons.access_time, size: 28),
              label: Text(
                selectedTime != null
                    ? "Selected Time: ${selectedTime!.format(context)}"
                    : "Pick Time",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
            ),
            SizedBox(height: 16),

            // Activity Dropdown
            DropdownButtonFormField<String>(
              value: selectedActivity,
              decoration: InputDecoration(
                labelText: 'Select Activity',
                labelStyle: TextStyle(color: Colors.blueGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueGrey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blueGrey, width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              isExpanded: true,
              items: activities.map((String activity) {
                return DropdownMenuItem<String>(
                  value: activity,
                  child: Text(activity),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedActivity = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Add Reminder Button
            ElevatedButton(
              onPressed: () {
                if (selectedDay != null &&
                    selectedTime != null &&
                    selectedActivity != null) {
                  setState(() {
                    reminders.add({
                      'day': selectedDay!,
                      'time': selectedTime!.format(context),
                      'activity': selectedActivity!,
                    });
                    selectedDay = null;
                    selectedTime = null;
                    selectedActivity = null;
                  });

                  _scheduleNotification(
                    selectedTime!.format(context),
                    selectedActivity!,
                    selectedDay!,
                  );
                }
              },
              child: Text(
                'Add Reminder',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Color.fromARGB(255, 255, 255, 255),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Display Reminders
            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                          '${reminder['activity']} at ${reminder['time']}'),
                      subtitle: Text(reminder['day']!),
                      contentPadding: EdgeInsets.all(16),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeReminder(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
