import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _passwordController;
  late TextEditingController _caregiverEmailController; // Added
  String _email = '';
  String _gender = '';
  String _caregiverEmail = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _passwordController = TextEditingController();
    _caregiverEmailController = TextEditingController(); // Added
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _caregiverEmailController.dispose(); // Added
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('user_email') ?? '';

    if (_email.isNotEmpty) {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:8000/profile/?email=$_email'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['name'];
          _ageController.text = data['age'].toString();
          _gender = data['gender'];
          _passwordController.text = data['password'];
          _caregiverEmail = data['caregiver_email'] ?? '';
          _caregiverEmailController.text = _caregiverEmail; // Added
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    }
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> profileData = {
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'email': _email,
        'password': _passwordController.text,
        'caregiver_email': _caregiverEmailController.text, // Updated
      };

      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/profile/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        await prefs.setString('user_name', _nameController.text);
        await prefs.setInt('user_age', int.parse(_ageController.text));
        await prefs.setString('user_gender', _gender);
        await prefs.setString('user_password', _passwordController.text);

        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save profile data: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildTextField(_nameController, 'Name', TextInputType.text),
                SizedBox(height: 10),
                _buildTextField(_ageController, 'Age', TextInputType.number),
                SizedBox(height: 10),
                _buildTextField(_caregiverEmailController, 'Caregiver Email',
                    TextInputType.emailAddress), // Updated
                SizedBox(height: 10),
                _buildDropdownField(),
                SizedBox(height: 10),
                _buildTextField(_passwordController, 'Password',
                    TextInputType.visiblePassword,
                    obscureText: true),

                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveUserProfile,
                    child: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      TextInputType keyboardType,
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $labelText';
        }
        if (labelText == 'Age') {
          final age = int.tryParse(value);
          if (age == null || age <= 0) {
            return 'Please enter a valid age';
          }
        }
        if (labelText == 'Password' && value.length < 8) {
          return 'Password must be at least 8 characters long';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _gender.isEmpty ? null : _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: ['Male', 'Female', 'Other']
          .map((label) => DropdownMenuItem(
                child: Text(label),
                value: label,
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _gender = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        return null;
      },
    );
  }
}
