import 'dart:convert';
import 'package:eco_guardian/_SplashScreenState.dart';
import 'package:eco_guardian/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import Font Awesome icons
import 'package:shared_preferences/shared_preferences.dart';

class LoginRegistrationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AD Solution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(), // Change to LoginScreen initially
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome to AD Solution',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 29, 255, 119),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),
            Center(
              child: CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage('assets/adsolution.png'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: LoginForm(),
            ),
            SizedBox(height: 20), // Added some space before the icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Continue with',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.google,
                            size: 28, // Adjust the size of the icon here
                          ),
                          onPressed: () {
                            // Implement Google sign in functionality
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.facebook,
                            size: 34, // Adjust the size of the icon here
                          ),
                          onPressed: () {
                            // Implement Facebook sign in functionality
                          },
                        ),
                      ),
                      Container(
                        child: IconButton(
                          icon: FaIcon(
                            FontAwesomeIcons.github,
                            size: 35, // Adjust the size of the icon here
                          ),
                          onPressed: () {
                            // Implement GitHub sign in functionality
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20), // Added some space after the icons
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController =
      TextEditingController(text: "tousif.n64@gmail.com");
  final TextEditingController passwordController =
      TextEditingController(text: "Qwe@123456");
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your email';
              }
              // Regular expression for email validation
              final emailRegex = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                caseSensitive: false,
                multiLine: false,
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your password';
              }

              // Password length validation
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }

              // Password complexity validation (requires at least one letter, one number, and one special character)
              final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
              final hasNumber = RegExp(r'[0-9]').hasMatch(value);
              final hasSpecialChar =
                  RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

              if (!hasLetter || !hasNumber || !hasSpecialChar) {
                return 'Password must contain at least one letter, one number, and one special character';
              }

              return null;
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Call the login function
                login(context);
              }
            },
            child: Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegistrationScreen()),
              );
            },
            child: Text('Create an account'),
          ),
        ],
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    final url = Uri.parse('http://127.0.0.1:8000/login/');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Store email in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', emailController.text);

      // Login successful, navigate to MainPage
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else {
      // Login failed, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect Email or Password')),
      );
    }
  }
}

class RegistrationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 29, 255, 119),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap with SingleChildScrollView
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RegistrationForm(),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class User {
  final String username;
  final String password;
  final String email;
  final String caregiverEmail; // New field for caregiver email

  User({
    required this.username,
    required this.password,
    required this.email,
    required this.caregiverEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'caregiver_email': caregiverEmail, // Include caregiver email
    };
  }
}

class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController =
      TextEditingController(); // New age field
  final TextEditingController _otpController = TextEditingController();
  String? _selectedGender; // New gender field
  final TextEditingController caregiverEmailController =
      TextEditingController(); // New controller for caregiver email
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _createUser() async {
    final url = Uri.parse('http://127.0.0.1:8000/signup/');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'age': ageController.text, // Include age
        'gender': _selectedGender!, // Include gender
        'caregiver_email':
            caregiverEmailController.text, // Include caregiver email
      }),
    );

    if (response.statusCode == 200) {
      // Registration successful
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Successful')),
      );
    } else if (response.statusCode == 409) {
      // Email already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The email address is already in use.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user')),
      );
    }
  }

  Future<void> _generateOTP() async {
    final String apiUrl = 'http://localhost:8000/generate_otp/';
    final Uri uri = Uri.parse(apiUrl);

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      print('OTP generated successfully');
      _showOTPDialog();
    } else {
      print('Failed to generate OTP: ${response.body}');
    }
  }

  Future<void> _validateOTP() async {
    final String apiUrl = 'http://localhost:8000/validate_otp/';
    final Uri uri = Uri.parse(apiUrl).replace(queryParameters: {
      'email': emailController.text,
      'entered_otp': _otpController.text,
    });

    final response = await http.post(
      uri,
    );

    if (response.statusCode == 200) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  Future<void> _showOTPDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // Set contentPadding to zero
          content: SingleChildScrollView(
            // Wrap content in SingleChildScrollView
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ensure minimum height
                children: <Widget>[
                  Text(
                    'Enter OTP',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'OTP'),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _validateOTP();
                _createUser();
                Navigator.of(context).pop();
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your email';
              }
              // Regular expression for email validation
              final emailRegex = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                caseSensitive: false,
                multiLine: false,
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your password';
              }

              // Password length validation
              if (value.length < 8) {
                return 'Password must be at least 8 characters long';
              }

              // Password complexity validation (requires at least one letter, one number, and one special character)
              final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
              final hasNumber = RegExp(r'[0-9]').hasMatch(value);
              final hasSpecialChar =
                  RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

              if (!hasLetter || !hasNumber || !hasSpecialChar) {
                return 'Password must contain at least one letter, one number, and one special character';
              }

              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock),
            ),
            validator: (value) {
              if (value != passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your age';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            hint: Text('Select Gender'),
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select your gender';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: caregiverEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Caregiver Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter caregiver email';
              }
              // Regular expression for email validation
              final emailRegex = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                caseSensitive: false,
                multiLine: false,
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateOTP,
            child: Text('Register'),
          ),
        ],
      ),
    );
  }

  Future<void> register(BuildContext context) async {
    final url = Uri.parse('http://127.0.0.1:8000/signup/');
    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'age': ageController.text,
        'gender': _selectedGender!,
        'caregiver_email':
            caregiverEmailController.text, // Include caregiver email
      }),
    );

    if (response.statusCode == 200) {
      // Registration successful
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup Successful')),
      );
    } else if (response.statusCode == 409) {
      // Email already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The email address is already in use.')),
      );
    } else {
      // Registration failed for other reasons
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed')),
      );
    }
  }
}
