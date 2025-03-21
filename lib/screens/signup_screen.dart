/// @main feature: Sign-up
///
/// @description: หน้า Sign-up
///
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'signin_screen.dart';
import 'home_screen.dart';
import 'dart:convert';
import '../main.dart'; // Import main.dart

class SignupScreen extends StatefulWidget {
  @override
  SignupScreenState createState() => SignupScreenState();
}
/// Enum to represent the selected user type (personal or company).
enum SelectedType { personal, company }

class SignupScreenState extends State<SignupScreen> with WidgetsBindingObserver {
  /// The selected user type (personal or company).
  SelectedType _character = SelectedType.personal;

  /// Controller for the firstname input field.
  final TextEditingController _firstname = TextEditingController();

  /// Controller for the lastname input field.
  final TextEditingController _lastname = TextEditingController();

  /// Controller for the email input field.
  final TextEditingController _emailController = TextEditingController();

  /// Controller for the password input field.
  final TextEditingController _passwordController = TextEditingController();

  /// Controller for the confirm password input field.
  final TextEditingController _confirmPasswordController = TextEditingController();

  /// Controller for the phone number input field.
  final TextEditingController _phoneNumber = TextEditingController();

  /// Controller for the company name input field.
  final TextEditingController _companyName = TextEditingController();

  /// Controller for the company phone number input field.
  final TextEditingController _companyPhoneNumber = TextEditingController();

  /// Boolean to toggle password visibility.
  var _isObscured;

  /// Boolean to toggle confirm password visibility.
  var _isConfirmObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = true;
    _isConfirmObscured = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // fetchData(); // You might have other logic here on app resume.
    }
  }

  /// Handles login after successful signup.
  /// Sends login details to the API, stores the token, and navigates to the main screen.
  Future<void> _loginAfterSignup(String email, String password) async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }
    Uri apiUrl = Uri.parse(baseUrl).replace(path: '${Uri.parse(baseUrl).path}/auth/login');

    var response = await http.post(
      apiUrl,
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
      headers: {
        'Content-type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Access the token from the decoded data:
      final String token = data['token'];

      // Securely store the token
      final _storage = FlutterSecureStorage();
      await _storage.write(key: 'auth_token', value: token);
      String? storedToken = await _storage.read(key: 'auth_token'); // เรียก token
      print("login successful - token : $storedToken");

      final Map<String, dynamic> user = data['user'];
      final String userJson = jsonEncode(user);
      await _storage.write(key: 'user_data', value: userJson);

      String? storedData = await _storage.read(key: 'user_data');

      print('User data : $storedData');

      // Login successful
      // Navigate to MainScreen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen()),
              (Route<dynamic> route) => false
      );


    } else {
      // Handle login failure (e.g., show an error message)
      print('Login failed: ${response.body}');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child:  AlertDialog(
              title: Text("Login Failed"),
              content: Text("Login failed after signup. Please check your credentials."),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }
/// Handles user registration by sending registration details to the API.
  /// On success, shows a success dialog and calls _loginAfterSignup to log the user in.
  Future<void> registerPost() async {
    print('registerPost');
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    print('API baseUrl: ${baseUrl}');

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUrl = Uri.parse(baseUrl).replace(path: '${Uri.parse(baseUrl).path}/auth/register');
    print("URL : ${apiUrl}");

    // Create JSON body based on user type
    Map<String, dynamic> body = {
      "email": _emailController.text,
      "password": _passwordController.text,
      "user_type": _character == SelectedType.personal ? "applicant" : "company",
    };

    if (_character == SelectedType.personal) {
      body["name"] = "${_firstname.text} ${_lastname.text}";
      body["phone"] = _phoneNumber.text;
    } else {
      body["name"] = _companyName.text;
      body["phone"] = _companyPhoneNumber.text;
    }

    var response = await http.post(
      apiUrl,
      body: jsonEncode(body),
      headers: {
        'Content-type': 'application/json; charset=UTF-8',
      },
    );
    print('API Response: ${response.body}');


    if (response.statusCode == 200 || response.statusCode == 201) {
      // Signup successful
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              title: Text("Signup Successful"),
              content: Text("You have successfully signed up!"),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _loginAfterSignup(_emailController.text, _passwordController.text); // Call login
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // Prevent back button
            child: AlertDialog(
              title: Text("Signup Failed"),
              content: Text("There was a problem with your signup.  ${response.body}"),
              actions: <Widget>[
                TextButton(
                  child: Text("OK"),
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
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Container(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Form(
                      child: Column(
                        children: [
                          Text('Signup',  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                          SizedBox(height: 40,),
                          buildTextFormField('Email', _emailController),
                          buildPasswordField('Password', _passwordController),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _isConfirmObscured,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isConfirmObscured =!_isConfirmObscured;
                                  });
                                },
                                icon: _isConfirmObscured ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off) ,
                                padding: const EdgeInsetsDirectional.only(end: 12),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              labelText: 'Confirm password',
                              border: OutlineInputBorder(),
                              prefixIconColor: Colors.grey,
                              floatingLabelStyle: const TextStyle(color: Colors.black),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(width: 2, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Radio Buttons for Personal and Company Selection
                          // Conditional Forms
                          if (_character == SelectedType.personal) ...[
                            buildTextFormField('Firstname', _firstname),
                            buildTextFormField('Lastname', _lastname),
                            buildTextFormField('Phone number', _phoneNumber),
                          ] else ...[
                            buildTextFormField('Company Name', _companyName),
                            // buildTextFormField('Company Registration Number'),
                            buildTextFormField('Company Phone Number', _companyPhoneNumber),
                          ],

                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Radio(
                                value: SelectedType.personal,
                                groupValue: _character,
                                onChanged: (value) {
                                  setState(() {
                                    _character = value!;
                                  });
                                },
                              ),
                              Text('Personal'),
                              SizedBox(width: 20),
                              Radio(
                                value: SelectedType.company,
                                groupValue: _character,
                                onChanged: (value) {
                                  setState(() {
                                    _character = value!;
                                  });
                                },
                              ),
                              Text('Company'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          registerPost();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3498DB),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide.none,
                          ),
                        ),
                        child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SigninScreen()),
                              );
                            },
                            child: const Text(
                              'Login now',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.normal),
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
        )
    );
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
          prefixIconColor: Colors.grey,
          floatingLabelStyle: const TextStyle(color: Colors.black),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        obscureText: _isObscured,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _isObscured =!_isObscured;
              });
            },
            icon: _isObscured ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off) ,
            padding: const EdgeInsetsDirectional.only(end: 12),
          ),
          fillColor: Colors.white,
          filled: true,
          labelText: label,
          border: OutlineInputBorder(),
          prefixIconColor: Colors.grey,
          floatingLabelStyle: const TextStyle(color: Colors.black),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(width: 2, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}