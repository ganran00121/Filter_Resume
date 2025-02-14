import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {


  final Profile profile = Profile(
    firstname: 'BEKBEK',
    lastname: '101',
    email: 'bekbek@example.com',
    phone: '01234567789',
    gender: 'Male',
  );


  @override
  Widget build(BuildContext context) {
    // var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
      //   centerTitle: true,
      //   // actions: [
      //   //   IconButton(onPressed: () {}, icon: Icon(isDark? Icons.dark_mode : Icons.light_mode))
      //   // ],
      // ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20,),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.asset('assets/images/user_profile.png'),
                      ),
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   right: 0,
                    //   child: Container(
                    //     width: 35,
                    //     height: 35,
                    //     decoration:
                    //     BoxDecoration(borderRadius: BorderRadius.circular(100), color: Colors.red),
                    //     child: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
                    //   ),
                    // ),

                    const SizedBox(height: 10,),
                    Text(
                      profile.firstname,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 50),
                    Form(child: Column(
                      children: [
                        buildTextFormField('Firstname', profile.firstname),
                        buildTextFormField('Lastname', profile.lastname),
                        buildTextFormField('Email', profile.email),
                        buildTextFormField('Phone Number', profile.phone),
                        buildTextFormField('Gender', profile.gender),
                      ],
                    )),
                    const SizedBox(height: 30,),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple, side: BorderSide.none, shape: const StadiumBorder()),
                          child: const Text('Save Change', style: TextStyle(color: Colors.white)),
                        )
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
}

class Profile {
  final String firstname, lastname, email, phone, gender;

  Profile({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.gender,
  });
}

Widget buildTextFormField(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      style: TextStyle(color: Colors.black),
      initialValue: value,
      enabled: false,
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
