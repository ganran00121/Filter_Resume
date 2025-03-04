import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './signin_screen.dart';
import 'dart:convert';

final _storage = FlutterSecureStorage();

TextEditingController nameController = TextEditingController();
TextEditingController emailController = TextEditingController();
TextEditingController phoneController = TextEditingController();
TextEditingController userTypeController = TextEditingController();

class Profile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String user_type;
  final int company_name;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.user_type,
    required this.company_name,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0, // แก้จาก 'ID' เป็น 'id' และใช้ ?? 0 กัน null
      name: json['title'] ?? '',
      email: json['description'] ?? '',
      phone: json['location'] ?? '',
      user_type: json['salary_range'] ?? '',
      company_name: json['quantity'] ?? 0, // ใช้ ?? 0 กัน null
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;


  var _isEdited;

  @override
  void initState()  {
    super.initState();
    _isEdited = false;
    fetchData();
  }
  void logout() async {
    await _storage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SigninScreen()),
          (route) => false,
    );
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    Map<String, String> storedData = await _storage.readAll();

    String? storedToken = storedData["user_data"];

    if (storedToken != null && storedToken.isNotEmpty) {
      try {
        Map<String, dynamic> userData = jsonDecode(storedToken);
        setState(() {
          userProfile = userData;
          isLoading = false;

          nameController.text = userProfile?['name'] ?? '';
          emailController.text = userProfile?['email'] ?? '';
          phoneController.text = userProfile?['phone'] ?? '';
          userTypeController.text = userProfile?['user_type'] ?? '';
        });
      } catch (e) {
        print("Error decoding user data: $e");
        setState(() => isLoading = false);
      }
    } else {
      print("No stored user data found");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        const SizedBox(height: 10,),
                        Text(
                          userProfile?['name'] ?? 'No Name',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: emailController,
                          enabled: _isEdited,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Email", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(color: Colors.black, fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder( // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder( // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: userTypeController,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          readOnly: true,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: "User Type", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(color: Colors.black, fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder( // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder( // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: phoneController,
                          enabled: _isEdited,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Phone", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(color: Colors.black, fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder( // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder( // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
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

