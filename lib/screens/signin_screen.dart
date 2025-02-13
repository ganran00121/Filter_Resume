import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class SigninScreen extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios)),
        title: Padding(
            padding: EdgeInsets.only(top: 30.0),
          child: Text('Welcome',
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
              const SizedBox(height: 20,),
              Form(
                  child: Column(
                    children: [
                      buildTextFormField('Email'),
                      TextFormField(
                        obscureText: true,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIconColor: Colors.grey,
                          floatingLabelStyle: const TextStyle(color: Colors.black),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(width: 2, color: Colors.grey),
                          ),
                        ),
                      )
                    ],
                  ),
              ),
              const SizedBox(height: 50,),
              SizedBox(
                height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3498DB), side: BorderSide.none, shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), side: BorderSide.none
                    )),
                    child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                  )
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
              const SizedBox(height: 12,),
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
                            MaterialPageRoute(builder: (context) => SignupScreen()));
                      },
                      child: const Text(
                        'Sign up now',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.normal, ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
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






