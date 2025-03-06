import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final FlutterSecureStorage _storage = FlutterSecureStorage();

class Chat {
  final int receiverId;
  final String name;
  final String image;

  Chat({required this.receiverId, required this.name, required this.image});
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Chat> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatList();
  }

  Future<void> fetchChatList() async {
    print('Fetching Chat List...');
    String baseUrl = dotenv.env['BASE_URL'] ?? 'https://default_url.com';
    String? token = await _storage.read(key: 'auth_token');
    String? userData = await _storage.read(key: 'user_data');

    if (userData == null) {
      print('No user data found.');
      setState(() => isLoading = false);
      return;
    }

    Map<String, dynamic> userMap = json.decode(userData);
    int userId = userMap['id'];
    String userType = userMap['user_type'];
    print('UserType: $userType');

    Uri apiUri = Uri.parse('$baseUrl/api/messages/$userId');

    try {
      var response = await http.get(apiUri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('Received Messages: $jsonData');

        // Group messages by receiver ID
        Map<int, Map<String, dynamic>> groupedChats = {};

        for (var message in jsonData) {
          int receiverId = message["ReceiverID"] ?? 0;
          int senderId = message["SenderID"] ?? 0;
          if (senderId == receiverId) continue;

          int otherUserId = (senderId == userId) ? receiverId : senderId;
          Map<String, dynamic> otherUser =
          (senderId == userId) ? message["Receiver"] : message["Sender"];

          if (!groupedChats.containsKey(otherUserId)) {
            groupedChats[otherUserId] = {
              "id": otherUserId,
              "name": otherUser["Name"] ?? "Unknown",
              "profileImage": otherUser["ProfileImage"] ??
                  "assets/images/user_placeholder.png",
              "lastMessage": message["MessageText"] ?? "",
              "timestamp": message["CreatedAt"] ?? "",
            };
          }
        }

        List<Chat> chatList = groupedChats.values.map((chat) {
          return Chat(
            receiverId: chat["id"],
            name: chat["name"],
            image: chat["profileImage"],
          );
        }).toList();

        setState(() {
          chats = chatList;
          isLoading = false;
        });
      } else {
        print('Failed to load messages. Status: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Chats"), backgroundColor: Colors.white),
        body: isLoading
            ? Container(
            color: Colors.white,
            child: Center(child: CircularProgressIndicator()))
            : chats.isEmpty
            ? Container(
          // เพิ่ม Container ครอบ Center
          color: Colors.white,
          child: Center(child: Text("No chats available")),
        )
            : Container(
          color: Colors.white,
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                        backgroundImage: AssetImage(chat.image)),
                    title: Text(chat.name),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                              receiverId: chat.receiverId,
                              receiverName: chat.name),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                            child: Divider(
                              height: 1,
                              color: Color(0xFFE0E0E0),
                            ))
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ));
  }
}

// Chat Room
class ChatDetailScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;

  ChatDetailScreen({required this.receiverId, required this.receiverName});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  int userId = 0;
  String userType = '';
  TextEditingController messageController =
  TextEditingController(); // Input field controller

  @override
  void initState() {
    super.initState();
    fetchChatHistory();
  }

  Future<void> fetchChatHistory() async {
    print('Fetching Chat History...');
    String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.207.73:3000';
    String? token = await _storage.read(key: 'auth_token');
    String? userData = await _storage.read(key: 'user_data');

    if (userData == null) {
      print('No user data found.');
      setState(() => isLoading = false);
      return;
    }

    Map<String, dynamic> userMap = json.decode(userData);
    userId = userMap['id'];
    userType = userMap['user_type'];

    Uri apiUri = Uri.parse('$baseUrl/api/messages/$userId');

    try {
      var response = await http.get(apiUri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        print('Received Chat History: $jsonData');

        //
        Set<int> seenIds = {}; // Track message IDs to prevent duplicates

        setState(() {
          messages = jsonData
              .where((message) =>
          (message["SenderID"] == userId &&
              message["ReceiverID"] == widget.receiverId) ||
              (message["SenderID"] == widget.receiverId &&
                  message["ReceiverID"] == userId))
              .map((message) {
            int messageId = message["ID"] ?? 0;

            if (seenIds.contains(messageId)) {
              return null; // Skip this message
            }

            seenIds.add(messageId); // Mark message as seen

            return {
              "id": messageId,
              "sender_id": message["SenderID"] ?? 0,
              "receiver_id": message["ReceiverID"] ?? 0,
              "message_text": message["MessageText"] ?? "",
              "created_at": message["CreatedAt"] ?? "",
            };
          })
              .where((message) => message != null) //
              .toList()
              .cast<Map<String, dynamic>>(); //

          isLoading = false;
        });
      } else {
        print('Failed to load messages. Status: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching chat history: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> sendMessage() async {
    String baseUrl = dotenv.env['BASE_URL'] ?? '';
    String? token = await _storage.read(key: 'auth_token');

    if (messageController.text.trim().isEmpty) {
      print("Message is empty. Not sending.");
      return;
    }

    String messageText = messageController.text.trim();
    messageController.clear();

    Map<String, dynamic> newMessage = {
      "id": DateTime.now().millisecondsSinceEpoch, // Temporary unique ID
      "sender_id": userId,
      "receiver_id": widget.receiverId,
      "message_text": messageText,
      "created_at": DateTime.now().toString(),
      "job_id": null, // Placeholder for job_id
    };

    setState(() {
      messages.insert(0, newMessage);
    });

    Uri apiUriMessage = Uri.parse('$baseUrl/api/messages');
    Uri apiUriJob = Uri.parse('$baseUrl/api/jobs/user/$userId/applications');

    try {
      var resJob = await http.get(
        apiUriJob,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      int latestJobId = 0;

      if (resJob.statusCode == 200) {
        List<dynamic> jobData = json.decode(resJob.body);
        if (jobData.isNotEmpty) {
          latestJobId = jobData.last["JobID"] ?? 0;
        }
      } else {
        print("Failed to fetch job ID. Status: ${resJob.statusCode}");
      }
      print("Latest Job ID: $latestJobId");

      var response = await http.post(
        apiUriMessage,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "sender_id": userId,
          "receiver_id": widget.receiverId,
          "message_text": messageText,
          "job_id": latestJobId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Message sent successfully!");
        setState(() {
          newMessage["job_id"] = latestJobId;
        });
        Future.delayed(Duration(seconds: 1), () {
          fetchChatHistory();
        });
      } else {
        print("Failed to send message: ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(''),
                ),
                SizedBox(
                  width: 8,
                ),
                Text(widget.receiverName)
              ],
            ),
          ),
          backgroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
              child: isLoading
                  ? Container(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()))
                  : messages.isEmpty
                  ? Center(child: Text("No messages yet"))
                  : Container(
                color: Colors.white,
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    bool isUser = message["sender_id"] == userId;

                    return Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            Padding(
                              padding:
                              const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(''),
                                radius: 16,
                              ),
                            ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.orange[100]
                                    : Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                      isUser ? 10 : 0),
                                  topRight: Radius.circular(
                                      isUser ? 0 : 10),
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message["message_text"],
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    message["created_at"],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isUser)
                            Padding(
                              padding:
                              const EdgeInsets.only(left: 8.0),
                              child: CircleAvatar(
                                backgroundImage: AssetImage(''),
                                radius: 16,
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
              )),
          // Text Input & Send Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFFE9E9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      controller: messageController,
                      enabled: userType != "company",
                      decoration: InputDecoration(
                        hintText: userType == "company"
                            ? "HR cannot send messages"
                            : "Type a message...",
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send,
                      color:
                      userType == "company" ? Colors.grey : Colors.orange),
                  onPressed: userType == "company" ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
