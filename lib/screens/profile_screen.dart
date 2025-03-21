/// @author Sirawit Mano
///
/// @student_id 640510685
///
/// @feature Edit profile (แก้ไขโปรไฟล์)
///
/// @description ผู้ใช้สามารถค้นหาจัดการ Profile ของตนเองได้
///
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './signin_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Instance of the secure storage for storing sensitive data.
final _storage = FlutterSecureStorage();

/// Controller for the name input field.
TextEditingController nameController = TextEditingController();
/// Controller for the email input field.
TextEditingController emailController = TextEditingController();
/// Controller for the phone number input field.
TextEditingController phoneController = TextEditingController();
/// Controller for the name user type field.
TextEditingController userTypeController = TextEditingController();

/// Represents the user's profile data.
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

  /// Creates a [Profile] instance from a JSON map.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      user_type: json['user_type'] ?? '',
      company_name: json['company_name'] ?? 0, // ใช้ ?? 0 กัน null
    );
  }
}

/// A StatefulWidget that displays and edits the user's profile.
class ProfileScreen extends StatefulWidget {
  @override
  ProfileScreenState createState() => ProfileScreenState();
}

/// State for the [ProfileScreen] widget.
class ProfileScreenState extends State<ProfileScreen> {
  /// Stores the user's profile data.
  Map<String, dynamic>? userProfile;
  /// Indicates whether the data is being loaded.
  bool isLoading = true;
  /// Indicates whether the profile is in edit mode.
  var _isEdited;
  /// Stores the user's type.
  String userType = '';

  @override
  void initState() {
    super.initState();
    _isEdited = false;
    fetchData();
    //fetch user's profile data
  }

  /// Logs the user out by clearing secure storage and navigating to the sign-in screen.
  void logout() async {
    await _storage.deleteAll(); // Clear all data from secure storage
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SigninScreen()),
          (route) => false, // Remove all previous routes from the stack
    );
  }

  /// Fetches user profile data from secure storage and updates the UI.
  Future<void> fetchData() async {
    setState(() => isLoading = true);
    Map<String, String> storedData = await _storage.readAll(); // Read all data from secure storage

    String? storedToken = storedData["user_data"];  // Get the user data token

    //If have stored token set each controller match user's data
    if (storedToken != null && storedToken.isNotEmpty) {
      try {
        Map<String, dynamic> userData = jsonDecode(storedToken);
        setState(() {
          userProfile = userData;
          userType = userData['user_type'];
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

  /// Updates the user's profile data on the server and in secure storage.
  Future<void> updateProfile(Profile updatedProfile) async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl'; // Ensure the base URL starts with http or https
    }

    String? token = await _storage.read(key: 'auth_token'); // Get the authentication token

    Uri apiUri = Uri.parse("$baseUrl/api/user/profile"); // Construct the API URI

    try {
      var response = await http.put(
        apiUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": updatedProfile.name,
          "phone": updatedProfile.phone,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully!")));

        Map<String, dynamic> updatedUserData = {
          "id": updatedProfile.id,
          "name": updatedProfile.name,
          "email": updatedProfile.email,
          "phone": updatedProfile.phone,
          "user_type": updatedProfile.user_type,
          "company_name": updatedProfile.company_name,
        };

        await _storage.write(key: 'user_data', value: jsonEncode(updatedUserData));

        setState(() {
          userProfile = updatedUserData;
          nameController.text = updatedProfile.name;
          phoneController.text = updatedProfile.phone;
        });

      } else {
        print("Failed to update profile: ${response.body} ${response.statusCode}");
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String userType = userProfile?['user_type'] ?? '';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset('assets/images/user_profile.png'),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        // Text(
                        //   userProfile?['name'] ?? 'No Name',
                        //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        // ),
                        const SizedBox(height: 50),
                        TextFormField(
                          controller: nameController,
                          enabled: _isEdited,
                          style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Name", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(
                              // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          enabled: false,
                          style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Email", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(
                              // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: userTypeController,
                          style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          readOnly: true,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: "User Type", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(
                              // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: phoneController,
                          enabled: _isEdited,
                          style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Phone", // หัวข้อของช่องป้อนข้อมูล
                            labelStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 16), // สไตล์ของหัวข้อ
                            filled: true, // เปิดการเติมสีพื้นหลัง
                            fillColor: Colors.white, // กำหนดสีพื้นหลังเป็นสีขาว
                            border: OutlineInputBorder(
                              // ใส่ขอบให้ช่องป้อนข้อมูล
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              // ขอบตอนโฟกัส
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 10), // จัดระยะห่างภายในช่อง
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: userType == 'company'
                                    ? null // Disable button if userType is 'company'
                                    : () {
                                  setState(() {
                                    _isEdited = !_isEdited;
                                  });
                                  if (!_isEdited) {
                                    Profile updatedProfile = Profile(
                                      id: userProfile?['id'] ?? 0,
                                      name: nameController.text,
                                      email: userProfile?['email'] ?? '',
                                      phone: phoneController.text,
                                      user_type: userType,
                                      company_name: userProfile?['company_name'] ?? 0,
                                    );
                                    updateProfile(updatedProfile);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: userType == 'company' ? Colors.grey : (_isEdited ? Colors.green : Colors.blueAccent),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide.none,
                                  ),
                                ),
                                child: _isEdited
                                    ? const Text('Save change', style: TextStyle(color: Colors.white))
                                    : const Text('Edit profile', style: TextStyle(color: Colors.white)),
                              )

                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
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
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          )),
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
