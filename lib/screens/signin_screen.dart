import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'dart:convert';

class SigninScreen extends StatefulWidget {
  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _isObscured;

  Future<Map<String, String>> _readMockData() async {
    try {
      final contents = await rootBundle.loadString('assets/variables.json');
      final jsonData = jsonDecode(contents); // Use jsonDecode to parse the JSON data
      return jsonData.cast<String, String>();
    } catch (e) {
      print('Error reading mock data: $e');
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    _isObscured = true;

    // Set the mock data to the text fields
    _readMockData().then((mockData) {
      _emailController.text = mockData['email']?? '';
      _passwordController.text = mockData['password']?? '';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    _readMockData().then((mockData) {
      if (email == mockData['email'] && password == mockData['password']) {
        // Show "Login Successfully" popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: Icon(Icons.check_circle, color: Colors.green, size: 48.0)),
              content: Text('Login Successful!\nWelcome back!', textAlign: TextAlign.center),
            );
          },
        );

        // Wait for 2 seconds and then close the popups and screen
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context); // Close the "Login Successfully" popup
          Navigator.pop(context); // Close the SigninScreen
        });
      } else {
        // Show an error message or handle incorrect credentials
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Login Failed'),
              content: Text(
                'Incorrect email or password.',
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
      // appBar: AppBar(
      //   centerTitle: true,
      //   leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios)),
      //   title: Padding(
      //     padding: EdgeInsets.only(top: 30.0),
      //     child: Text(
      //       'Welcome',
      //       style: const TextStyle(
      //         fontWeight: FontWeight.bold,
      //         fontSize: 24,
      //         color: Colors.black,
      //       ),
      //     ),
      //   ),
      // ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              child: Container(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text('Welcome',  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
                    SizedBox(height: 40,),
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
                                    _isObscured =!_isObscured;
                                  });
                                },
                                icon: _isObscured ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off) ,
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
                        child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 30,),
                    const Divider(),
                    const SizedBox(height: 30,),
                    SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0), side: const BorderSide(width: 3.0, color: Color(0xFFE74C3C))
                          )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset('assets/images/google_icon.png', height: 24,),
                              const SizedBox(width: 10),
                              Expanded(
                                  child:
                                  Text('Google', style: TextStyle(color: Color(0xFFE74C3C)), textAlign: TextAlign.center,)
                              ),
                            ],
                          ),
                        )
                    ),
                    const SizedBox(height: 12,),
                    SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0), side: const BorderSide(width: 3.0, color: Color(0xFF3498DB))
                          )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/facebook_icon.png', height: 24,),
                              const SizedBox(width : 10),
                              Expanded(
                                child: Text('Facebook', style: TextStyle(color: Color(0xFF1877F2)), textAlign: TextAlign.center,),
                              ),
                            ],
                          ),
                        )
                    ),
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
                                MaterialPageRoute(builder: (context) => SignupScreen()),
                              );
                            },
                            child: const Text(
                              'Sign up now',
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

// Widget buildPasswordField(String label, TextEditingController controller) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 20),
//     child: TextFormField(
//       controller: controller,
//       obscureText: true,
//       style: TextStyle(color: Colors.black),
//       decoration: InputDecoration(
//         suffixIcon: IconButton(
//             onPressed: onPressed,
//             icon: _isObscured ? ,
//           padding: const EdgeInsetsDirectional.only(end: 12),
//         ),
//         fillColor: Colors.white,
//         filled: true,
//         labelText: label,
//         border: OutlineInputBorder(),
//         floatingLabelStyle: const TextStyle(color: Colors.black),
//         focusedBorder: const OutlineInputBorder(
//           borderSide: BorderSide(width: 2, color: Colors.grey),
//         ),
//       ),
//     ),
//   );
// }
