import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsScreen extends StatefulWidget {
  final Function(String?) onToneChanged;

  SettingsScreen({required this.onToneChanged});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedTone;
  String? currentlyPlayingTone;

  final Map<String, String> toneFiles = {
    "Tone 1": "tone1.mp3",
    "Tone 2": "tone2.mp3",
    "Tone 3": "tone3.mp3",
    "Tone 4": "tone4.mp3",
    "Tone 5": "tone5.mp3",
  };

  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSelectedTone();

    // Listen to the completion event of the audio to reset the UI
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        currentlyPlayingTone = null;
      });
    });
  }

  void _loadSelectedTone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedTone = prefs.getString('selectedTone');
    });
  }

  void _saveSelectedTone(String? tone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTone', tone ?? '');
    widget.onToneChanged(tone);
  }

  Future<void> _playPauseTone(String tone) async {
    if (currentlyPlayingTone == tone) {
      await audioPlayer.pause();
      setState(() {
        currentlyPlayingTone = null;
      });
    } else {
      final toneFile = toneFiles[tone];
      if (toneFile != null) {
        try {
          await audioPlayer.stop(); // Stop any currently playing sound
          await audioPlayer.setSource(AssetSource(toneFile));
          await audioPlayer.resume(); // Play the audio
          setState(() {
            currentlyPlayingTone = tone;
          });
        } catch (e) {
          print('Error playing audio: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Color.fromARGB(255, 246, 243, 210); // Light yellow color

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: toneFiles.keys.map((tone) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: backgroundColor, // Set list item background color
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              title: Text(
                tone,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(currentlyPlayingTone == tone
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () {
                      _playPauseTone(tone);
                    },
                  ),
                  Radio<String>(
                    value: tone,
                    groupValue: selectedTone,
                    onChanged: (value) {
                      setState(() {
                        selectedTone = value;
                        _saveSelectedTone(selectedTone);
                        _playPauseTone(selectedTone!);
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
