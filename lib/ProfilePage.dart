import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_guardian/EditProfilePage.dart'; // Update with your actual import
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = '';
  int age = 0;
  String gender = '';
  String email = '';
  String caregiverEmail = ''; // Added

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('user_email') ?? '';

    if (email.isNotEmpty) {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/profile/?email=$email'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name = data['name'];
          age = data['age'];
          gender = data['gender'];
          email = data['email'];
          caregiverEmail =
              data['caregiver_email'] ?? ''; // Fetch caregiver email
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Icon(
                Icons.person,
                size: 40,
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text('Name'),
                subtitle: Text(name),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text('Age'),
                subtitle: Text('$age'),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text('Gender'),
                subtitle: Text(gender),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text('Email'),
                subtitle: Text(email),
              ),
            ),
            SizedBox(height: 10), // Added SizedBox
            Card(
              elevation: 4,
              child: ListTile(
                title: Text('Caregiver Email'), // Display caregiver's email
                subtitle: Text(caregiverEmail),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              child: Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
