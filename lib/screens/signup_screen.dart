import 'package:flutter/material.dart';
import 'signin_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

enum SelectedType { personal, company }

class _SignupScreenState extends State<SignupScreen> {
  SelectedType _character = SelectedType.personal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          onPressed: () { Navigator.pop(context);},
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            'Welcome',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Form(
                child: Column(
                  children: [
                    buildTextFormField('Email'),
                    buildPasswordField('Password'),
                    buildPasswordField('Confirm password'),

                    // Radio Buttons for Personal and Company Selection


                    // Conditional Forms
                    if (_character == SelectedType.personal) ...[
                      buildTextFormField('Firstname'),
                      buildTextFormField('Lastname'),
                      buildTextFormField('Phone number'),
                    ] else ...[
                      buildTextFormField('Company Name'),
                      // buildTextFormField('Company Registration Number'),
                      buildTextFormField('Company Phone Number'),
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
              const SizedBox(height: 50),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
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
                    const Text("Don't have an account? "),
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
    );
  }

  Widget buildTextFormField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
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

  Widget buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        obscureText: true,
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
}
