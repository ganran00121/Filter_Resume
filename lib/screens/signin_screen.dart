import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'signup_screen.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import 'reset_password_screen.dart';

/// A screen that handles user authentication via email and password.
/// Displays a login form and interacts with an authentication API.
class SigninScreen extends StatefulWidget {
  /// Callback when switching to the signup screen.
  final VoidCallback? onSwitchToSignup;
  /// Callback when login is successful.
  final VoidCallback? onLoginSuccess;

  SigninScreen({Key? key, this.onSwitchToSignup, this.onLoginSuccess})
      : super(key: key);

  @override
  SigninScreenState createState() => SigninScreenState();
}

class SigninScreenState extends State<SigninScreen> {
  /// Controller for the email input field.
  final TextEditingController _emailController = TextEditingController();
  /// Controller for the password input field.
  final TextEditingController _passwordController = TextEditingController();
  /// Secure storage instance for saving authentication tokens.
  final _storage = FlutterSecureStorage();
  /// Boolean to toggle password visibility.
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles user sign-in by sending authentication details to the API.
  /// On success, stores authentication token and navigates to the main screen.
  Future<void> _handleSignIn() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }
    Uri apiUrl = Uri.parse(baseUrl)
        .replace(path: '${Uri.parse(baseUrl).path}/auth/login');

    final response = await http.post(
      apiUrl,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String token = data['token'];
      final Map<String, dynamic> user = data['user'];
      final String userJson = jsonEncode(user);

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_data', value: userJson);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Center(
                    child: Icon(Icons.check_circle,
                        color: Colors.green, size: 48.0)),
                content: Text('Login Successful!\nWelcome back!',
                    textAlign: TextAlign.center),
              ));
        },
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainScreen()));
      });
    } else {
      _showLoginError(response.body);
    }
  }

  /// Shows a login error dialog with the given [message].
  void _showLoginError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Login Failed'),
            content: Text('Incorrect email or password. $message'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            child: Container(
              padding: EdgeInsets.all(40.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text('Welcome',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 40),
                  Form(
                    child: Column(
                      children: [
                        buildTextFormField('Email', _emailController),
                        buildPasswordField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _handleSignIn,
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a password input field with toggle visibility option.
  Widget buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: 'Password',
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
          icon: _isObscured
              ? const Icon(Icons.visibility)
              : const Icon(Icons.visibility_off),
        ),
      ),
    );
  }
}

/// Builds a reusable text input field.
Widget buildTextFormField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    ),
  );
}