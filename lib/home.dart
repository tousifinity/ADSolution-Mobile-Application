import 'package:eco_guardian/LoginRegistrationApp.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_guardian/SensorDataPage.dart';
import 'package:eco_guardian/PredictionPage.dart';
import 'package:eco_guardian/ProfilePage.dart';
import 'package:eco_guardian/NotificationPage.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, String>> notifications = [];

  @override
  void initState() {
    super.initState();
    // Load notifications from local storage or initialize as empty
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Here you can load saved notifications from storage if needed
    // For simplicity, we initialize it as an empty list
    setState(() {
      notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(
                'user_email'); // Remove user email from shared preferences
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginRegistrationApp()),
            ); // Navigate to login page
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationPage(notifications: notifications),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              context,
              icon: Icons.sensor_door,
              title: 'Sensor Data',
              page: SensorDataPage(
                notifications:
                    notifications, // Pass notifications to SensorDataPage
                onNewNotification: _addNotification,
              ),
              color: Colors.blue, // Color for Sensor Data
            ),
            SizedBox(height: 30.0),
            _buildCard(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Prediction',
              page: PredictionPage(),
              color: Colors.green, // Color for Prediction
            ),
            SizedBox(height: 30.0),
            _buildCard(
              context,
              icon: Icons.person,
              title: 'Profile',
              page: ProfilePage(),
              color: Colors.orange, // Color for Profile
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String title,
      required Widget page,
      required Color color}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Card(
        color: color, // Use the color parameter here
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50),
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNotification(String title, String body) {
    setState(() {
      notifications.add({"title": title, "body": body});
    });
  }
}
