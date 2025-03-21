/// @author Ackarapon Muenrach
///
/// @student_id 640510689
///
/// @feature Reset Password
///
/// @description This screen allows users to reset their password.
/// Users need to provide their email, new password, and confirm the new password.
/// The screen validates the input and communicates with the server to update the password.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A screen that allows users to reset their password.
class ResetPasswordScreen extends StatefulWidget {
  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  /// Controller for the email input field.
  final TextEditingController _emailController = TextEditingController();

  /// Controller for the password input field.
  final TextEditingController _passwordController = TextEditingController();

  /// Controller for the confirm password input field.
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  /// Indicates whether a password reset operation is in progress.
  bool isLoading = false;

  /// Indicates whether the password fields should be obscured.
  var _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = true;
  }

  /// Attempts to reset the user's password.
  ///
  /// Sends a request to the server with the user's email and new password.
  /// Displays a success or error message based on the server's response.
  Future<void> resetPassword() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'http://your-api-url.com';
    String apiUrl = '$baseUrl/auth/reset-password';

    // Check if passwords match
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "new_password": _passwordController.text.trim(),
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password reset successful!")));

        // Navigate back to the sign-in page after a successful reset.
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to reset password")));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("An error occurred")));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Reset Password")),
        body: SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Email input field
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        floatingLabelStyle: const TextStyle(color: Colors.black),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Password input field
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
                        floatingLabelStyle: const TextStyle(color: Colors.black),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Confirm password input field
                    TextFormField(
                      controller: _confirmPasswordController,
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
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        floatingLabelStyle: const TextStyle(color: Colors.black),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Show a loading indicator or the reset password button.
                    isLoading
                        ? CircularProgressIndicator()
                        : SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3498DB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Reset Password',
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            )));
  }
}
