import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './signin_screen.dart';

final _storage = FlutterSecureStorage();
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final Profile profile = Profile(
    firstname: 'BEKBEK',
    lastname: '101',
    email: 'bekbek@example.com',
    phone: '01234567789',
    gender: 'Male',
  );

  var _isEdited;

  @override
  void initState() {
    super.initState();
    _isEdited = false;
  }
  void logout() async {
    await _storage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SigninScreen()),
          (route) => false,
    );
  }

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
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16,  vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
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
                        const SizedBox(height: 20,),
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: (){
                                  setState(() {
                                    _isEdited = !_isEdited;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEdited ? Colors.green : Colors.blueAccent,
                                    side: BorderSide.none,
                                    shape:RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide.none,
                                    )),
                                child: _isEdited ? const Text('Save change', style: TextStyle(color: Colors.white)) : const Text('Edit profile', style: TextStyle(color: Colors.white)),
                              )
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        logout(); // ฟังก์ชันที่ใช้ในการออกจากระบบ
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          )
      ),
    );
  }

  Widget buildTextFormField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        style: TextStyle(color: Colors.black),
        initialValue: value,
        enabled: _isEdited,
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


