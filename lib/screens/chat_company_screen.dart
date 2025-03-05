import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import SecureStorageService
import 'package:http/http.dart' as http; // Import http package
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Chat {
  final String name;
  final double score;
  final String image;

  Chat({required this.name, required this.score, required this.image});
}

class ChatScreen extends StatefulWidget {
  // เปลี่ยน StatelessWidget เป็น StatefulWidget
  final int job_id;
  final String job_name;
  ChatScreen({required this.job_id, required this.job_name});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // สร้าง State class
  List<Chat> chats = [];
  String savedResponse = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getChatList();
  }

  Future<void> _getChatList() async {
    setState(() => isLoading = true);
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    final _storage = FlutterSecureStorage();

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }
    Uri apiUrl = Uri.parse(baseUrl).replace(
        path:
            '${Uri.parse(baseUrl).path}/api/jobs/${widget.job_id}/applications'); // ใช้ widget.job_id
    print("URL : ${apiUrl}");

    String? token = await _storage.read(key: 'auth_token');

    final response = await http.get(apiUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> data = jsonDecode(response.body);

      await _storage.write(key: 'auth_token', value: token);
      String? storedToken = await _storage.read(key: 'auth_token');
      print("login successful - token : $storedToken");

      print('_getChatList API Response: ${response.body}');
      savedResponse = response.body;

      setState(() {
        chats = data.map((item) {
          return Chat(
            name: item['applicant_name'],
            score: item['score'],
            image: "assets/images/thaibev.png", // ใช้รูป profile default
          );
        }).toList();
        isLoading = false;
      });
    } else {
      print('_getChatList API Response Failed: ${response.body}');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.job_name),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Expanded(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : chats.length > 0
                ? ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(chat.image),
                            ),
                            title: Text(chat.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child:
                                      Text("Score : ${chat.score.toString()}"),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatDetailScreen(chat: chat),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                      height: 1, color: Color(0xFFE0E0E0)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No chats for now."),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final Chat chat;
  final String userProfileImage = "assets/images/user_profile.png";
  final List<Map<String, dynamic>> messages = [
    {
      "sender": "user",
      "message":
          "Hi, I'm following up on the Full Stack Developer position. I submitted my resume last week."
    },
    {
      "sender": "chat",
      "message":
          "Hello! Thank you for reaching out. We appreciate your interest in the position. We've received your resume and are currently reviewing it."
    },
    {
      "sender": "user",
      "message":
          "Great, thank you! Is there a timeline for when I can expect to hear back?"
    },
    {
      "sender": "chat",
      "message":
          "We're aiming to finalize our shortlist by the end of this week. If you're selected for the next stage, we'll contact you to schedule an interview."
    },
    {
      "sender": "user",
      "message":
          "I understand. I'm really excited about this opportunity and confident I'd be a great fit for your team. I have experience with all the technologies listed in the job description, and I'm eager to contribute to your company's success."
    },
    {
      "sender": "chat",
      "message":
          "We appreciate your enthusiasm! Your experience sounds promising. We're particularly interested in your work on [mention a specific project or skill from the resume]. Could you tell us more about that?"
    },
    {
      "sender": "user",
      "message":
          "Certainly! [Provide a brief explanation of the project or skill]. I'm proficient in [list some relevant skills] and have a strong understanding of [mention relevant concepts]."
    },
    {
      "sender": "chat",
      "message":
          "That's impressive. We value candidates with a strong foundation in those areas. We'll be in touch soon to discuss the next steps in the hiring process."
    },
    {
      "sender": "user",
      "message":
          "Thank you for your time and consideration. I look forward to hearing from you soon."
    },
    {
      "sender": "chat",
      "message":
          "You're welcome! We appreciate your application and will be in touch shortly."
    },
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
      body: Column(
        // Use Column with Flexible
        children: [
          Flexible(
            child: Scrollbar(
              // Add Scrollbar
              child: ListView.builder(
                itemCount: messages.length,
                reverse: false, // Set reverse to false
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message["sender"] == "user";

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
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
                              color: isUser
                                  ? Color(0xFFF5F5F5)
                                  : Color(0xFFE9E9E9),
                              borderRadius: isUser
                                  ? BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(6),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )
                                  : BorderRadius.only(
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
