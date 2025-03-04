import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import SecureStorageService
import 'package:http/http.dart' as http; // Import http package
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Chat {
  final String name;
  final String image;

  Chat({required this.name, required this.image});
}



class ChatScreen extends StatelessWidget {
  final int id;
  ChatScreen({required this.id});

  final List<Chat> chats = [
    Chat(name: "ThaiBev", image: "assets/images/thaibev.png"),
    Chat(name: "Thai Beverage Plc", image: "assets/images/thaibev.png"),
  ];


  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     _getChat();
  //   }
  // }

  // Future<void> _getChat() async {
  //   String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
  //   if (!baseUrl.startsWith('http')) {
  //     baseUrl = 'https://$baseUrl';
  //   }
  //   Uri apiUrl = Uri.parse(baseUrl).replace(path: '${Uri.parse(baseUrl).path}/auth/login');
  //   print("URL : ${apiUrl}");
  //
  //
  //
  //   // Use http.post to make the API request
  //   final response = await http.post(
  //     apiUrl,
  //     headers: {
  //       'Content-Type': 'application/json; charset=UTF-8', // Set Content-Type
  //     },
  //     body: jsonEncode({
  //       'email': _emailController.text.trim(),
  //       'password': _passwordController.text.trim(),
  //     }),
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     // Login successful
  //     final Map<String, dynamic> data = jsonDecode(response.body);
  //     final String token = data['token'];
  //     final Map<String, dynamic> user = data['user'];
  //
  //     final String userJson = jsonEncode(user);
  //
  //     // Store the token securely
  //     await _storage.write(key: 'auth_token', value: token);
  //     await _storage.write(key: 'user_data', value: userJson);
  //     String? storedToken = await _storage.read(key: 'auth_token'); // เรียก token
  //     print("login successful - token : $storedToken");
  //
  //     print('API Response: ${response.body}');
  //
  //     // Show success dialog (optional, but good for user feedback)
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext context) {
  //         return WillPopScope(
  //             onWillPop: () async => false, // Prevent back button
  //             child: AlertDialog(
  //               backgroundColor: Colors.white,
  //               title: Center(child: Icon(Icons.check_circle, color: Colors.green, size: 48.0)),
  //               content: Text('Login Successful!\nWelcome back!', textAlign: TextAlign.center),
  //             )
  //         );
  //       },
  //     );
  //
  //     // Wait for 2 seconds and then close the popups and screen
  //     Future.delayed(Duration(seconds: 2), () {
  //       Navigator.of(context).pop(); // Close dialog
  //       Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => MainScreen()));
  //     });
  //
  //
  //   } else {
  //     // Login failed - Show error dialog
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext context) {
  //         return WillPopScope(
  //           onWillPop: () async => false, // Prevent back button
  //           child: AlertDialog(
  //             title: Text('Login Failed'),
  //             content: Text(
  //               'Incorrect email or password.  ${response.body}',  // Show API error
  //             ),
  //             actions: <Widget>[
  //               TextButton(
  //                 child: Text('Close'),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle:  true,
        title: Text("Recent Chat"),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage: AssetImage(chat.image),
                ),
                title: Text(chat.name),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chat: chat),
                    ),
                  );
                },
              ),
              Padding( // Add padding around the divider
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(height: 1,color: Color(0xFFE0E0E0)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final Chat chat;
  final String userProfileImage = "assets/images/user_profile.png";
  final List<Map<String, dynamic>> messages = [
    {"sender": "user", "message": "Hi, I'm following up on the Full Stack Developer position. I submitted my resume last week."},
    {"sender": "chat", "message": "Hello! Thank you for reaching out. We appreciate your interest in the position. We've received your resume and are currently reviewing it."},
    {"sender": "user", "message": "Great, thank you! Is there a timeline for when I can expect to hear back?"},
    {"sender": "chat", "message": "We're aiming to finalize our shortlist by the end of this week. If you're selected for the next stage, we'll contact you to schedule an interview."},
    {"sender": "user", "message": "I understand. I'm really excited about this opportunity and confident I'd be a great fit for your team. I have experience with all the technologies listed in the job description, and I'm eager to contribute to your company's success."},
    {"sender": "chat", "message": "We appreciate your enthusiasm! Your experience sounds promising. We're particularly interested in your work on [mention a specific project or skill from the resume]. Could you tell us more about that?"},
    {"sender": "user", "message": "Certainly! [Provide a brief explanation of the project or skill]. I'm proficient in [list some relevant skills] and have a strong understanding of [mention relevant concepts]."},
    {"sender": "chat", "message": "That's impressive. We value candidates with a strong foundation in those areas. We'll be in touch soon to discuss the next steps in the hiring process."},
    {"sender": "user", "message": "Thank you for your time and consideration. I look forward to hearing from you soon."},
    {"sender": "chat", "message": "You're welcome! We appreciate your application and will be in touch shortly."},
    //... add more messages
  ];

  ChatDetailScreen({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Center(
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(chat.image),
              ),
              SizedBox(width: 8),
              Text(chat.name),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column( // Use Column with Flexible
        children: [
          Flexible(
            child: Scrollbar( // Add Scrollbar
              child: ListView.builder(
                itemCount: messages.length,
                reverse: false, // Set reverse to false
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message["sender"] == "user";

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(chat.image),
                              radius: 16,
                            ),
                          ),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Color(0xFFF5F5F5) : Color(0xFFE9E9E9),
                              borderRadius: isUser ? BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(6),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ) : BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Flexible(
                              child: Text(
                                message["message"],
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        if (isUser)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CircleAvatar(
                              backgroundImage: AssetImage(userProfileImage),
                              radius: 16,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                // Upload button
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.upload_file, color: Color(0xFF6C6C6C)),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: "Message ${chat.name}",
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send, color: Colors.orange),
                          onPressed: () {},
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}