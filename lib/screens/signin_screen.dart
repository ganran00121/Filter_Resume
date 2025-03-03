import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http; // Import http package
import 'signup_screen.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import SecureStorageService
import '../main.dart'; // Import main.dart for MainScreen

class SigninScreen extends StatefulWidget {
  final VoidCallback? onSwitchToSignup;
  final VoidCallback? onLoginSuccess;

  SigninScreen({Key? key, this.onSwitchToSignup, this.onLoginSuccess}) : super(key: key);

  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage(); // Create instance
  var _isObscured;

  // No longer needed, as we will use the API
  // Future<Map<String, String>> _readMockData() async { ... }

  @override
  void initState() {
    super.initState();
    _isObscured = true;
    // Don't pre-fill from mock data.  We'll log in with the API.
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }
    Uri apiUrl = Uri.parse(baseUrl).replace(path: '${Uri.parse(baseUrl).path}/auth/login');
    print("URL : ${apiUrl}");


    // Use http.post to make the API request
    final response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8', // Set Content-Type
      },
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Login successful
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String token = data['token'];

      // Store the token securely
      await _storage.write(key: 'auth_token', value: token);
      String? storedToken = await _storage.read(key: 'auth_token'); // เรียก token
      print("login successful - token : $storedToken");

      print('API Response: ${response.body}');

      // Show success dialog (optional, but good for user feedback)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false, // Prevent back button
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Center(child: Icon(Icons.check_circle, color: Colors.green, size: 48.0)),
                content: Text('Login Successful!\nWelcome back!', textAlign: TextAlign.center),
              )
          );
        },
      );

      // Wait for 2 seconds and then close the popups and screen
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainScreen()));
      });


    } else {
      // Login failed - Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              title: Text('Login Failed'),
              content: Text(
                'Incorrect email or password.  ${response.body}',  // Show API error
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button and gesture
      child: GestureDetector( // Add GestureDetector
        onVerticalDragUpdate: (details) {
          // Do nothing to prevent swipe down to dismiss
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),  // IMPORTANT: Disable scrolling
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                child: Container(
                  padding: EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'Welcome',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 40),
                      Form(
                        child: Column(
                          children: [
                            buildTextFormField('Email', _emailController),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                  icon: _isObscured
                                      ? const Icon(Icons.visibility)
                                      : const Icon(Icons.visibility_off),
                                  padding: const EdgeInsetsDirectional.only(end: 12),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                floatingLabelStyle:
                                const TextStyle(color: Colors.black),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide:
                                  BorderSide(width: 2, color: Colors.grey),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3498DB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Sign in',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      const Divider(),
                      const SizedBox(
                        height: 30,
                      ),
                      SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: const BorderSide(
                                        width: 3.0, color: Color(0xFFE74C3C)))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/google_icon.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(
                                      'Google',
                                      style: TextStyle(color: Color(0xFFE74C3C)),
                                      textAlign: TextAlign.center,
                                    )),
                              ],
                            ),
                          )),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: const BorderSide(
                                        width: 3.0, color: Color(0xFF3498DB)))),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/facebook_icon.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Facebook',
                                    style: TextStyle(color: Color(0xFF1877F2)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignupScreen()),
                                );
                              },
                              child: const Text(
                                'Sign up now',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.normal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildTextFormField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: label,
        border: OutlineInputBorder(),
        floatingLabelStyle: const TextStyle(color: Colors.black),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2, color: Colors.grey),
        ),
      ),
    ),
  );
}