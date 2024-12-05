import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'MapPage.dart';
import 'NotificationPage.dart';

class SensorDataPage extends StatefulWidget {
  final List<Map<String, String>> notifications;
  final Function(String, String) onNewNotification;

  SensorDataPage(
      {required this.notifications, required this.onNewNotification});

  @override
  _SensorDataPageState createState() => _SensorDataPageState();
}

class _SensorDataPageState extends State<SensorDataPage> {
  dynamic _responseData = {
    "temperature": 0,
    "humidity": 0,
    "bpm": 0,
    "spo2": 0,
    "latitude": 0.0,
    "longitude": 0.0,
    "altitude": 0.0,
    "timestamp": ""
  };

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Initialize notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsDarwin = DarwinInitializationSettings();

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _createNotificationChannel();

    fetchData();
    fetchDataPeriodically();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel', // channel ID
      'High Importance Notifications', // channel name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);

    // Trigger the callback to add the notification to the list
    widget.onNewNotification(title, body);
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    if (email.isEmpty) {
      // Handle the case where the email is not found
      throw Exception('User email not found');
    }

    final response = await http
        .get(Uri.parse("http://127.0.0.1:8000/sensor-data/?email=$email"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _responseData = {
          "temperature": data["temperature"] ?? 0,
          "humidity": data["humidity"] ?? 0,
          "bpm": data["bpm"] ?? 0,
          "spo2": data["spo2"] ?? 0,
          "latitude": data["latitude"] ?? 0.0,
          "longitude": data["longitude"] ?? 0.0,
          "altitude": data["altitude"] ?? 0.0,
          "timestamp": data["timestamp"] ?? ""
        };
      });
      _checkForWarnings();
    } else {
      throw Exception('Failed to load sensor data');
    }
  }

  void fetchDataPeriodically() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      fetchData();
    });
  }

  void _checkForWarnings() {
    String warningMessage = "";
    bool hasWarning = false;

    if (_responseData["temperature"] > 38) {
      warningMessage += "Temperature is above 38°C. ";
      hasWarning = true;
    }
    if (_responseData["spo2"] < 90) {
      warningMessage += "SPO2 is below 90%. ";
      hasWarning = true;
    }
    if (_responseData["bpm"] > 85) {
      warningMessage += "BPM is above 85. ";
      hasWarning = true;
    }

    if (hasWarning) {
      showNotification("Warning", warningMessage.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Data'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(
                      notifications: widget
                          .notifications), // Pass notifications to NotificationPage
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSensorCard(
                "Temperature",
                _responseData["temperature"].toDouble(),
                50.0,
                _getColorForValue(
                    "Temperature", _responseData["temperature"].toDouble()),
              ),
              _buildSensorCard(
                "Humidity",
                _responseData["humidity"].toDouble(),
                100.0,
                _getColorForValue(
                    "Humidity", _responseData["humidity"].toDouble()),
              ),
              _buildSensorCard(
                "Blood Pressure",
                _responseData["bpm"].toDouble(),
                120.0,
                _getColorForValue(
                    "Blood Pressure", _responseData["bpm"].toDouble()),
              ),
              _buildSensorCard(
                "SPO2",
                _responseData["spo2"].toDouble(),
                100.0,
                _getColorForValue("SPO2", _responseData["spo2"].toDouble()),
              ),
              _buildLocationCard(
                _responseData["latitude"],
                _responseData["longitude"],
                _responseData["altitude"],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(
      String title, double value, double maxValue, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 10,
            ),
            SizedBox(height: 10),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(
      double latitude, double longitude, double altitude) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MapPage(latitude: latitude, longitude: longitude)),
        );
      },
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Location",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Latitude: $latitude",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Longitude: $longitude",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                "Altitude: $altitude",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForValue(String binName, double value) {
    if (binName == 'Temperature' && value > 38) {
      return Colors.red;
    } else if (binName == 'Humidity' && value > 70) {
      return Colors.red;
    } else if (binName == 'Blood Pressure' && value > 85) {
      return Colors.red;
    } else if (binName == 'SPO2' && value < 90) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }
}
