/// @main feature: Company Post Management
///
/// @description: Allows company users to create, edit, and delete job postings.
///

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'chat_company_screen.dart';

/// StatefulWidget that displays company information, including job listings.
class CompanyScreen extends StatefulWidget {
  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

/// Secure storage instance for storing sensitive data.
final FlutterSecureStorage _storage = FlutterSecureStorage();
/// Counter variable (currently unused).
int _count = 0;

/// State for the [CompanyScreen] widget.
class _CompanyScreenState extends State<CompanyScreen> {
  /// List to store fetched jobs.
  List<Job> jobs = [];
  /// Indicates whether data is being loaded.
  bool isLoading = true;
  /// Stores the company name.
  String companyName = '';

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data when the state is initialized.
  }

  /// Fetches job data from the API based on the user's company ID.
  Future<Job?> fetchData() async {
    setState(() => isLoading = true);
    print('FetchData');
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    print('API baseUrl: ${baseUrl}');
    int? id;


    String? token = await _storage.read(key: 'auth_token');
    String? userData = await _storage.read(key: 'user_data');
    print("userData : $userData");

    if (userData != null) {
      Map<String, dynamic> userMap = json.decode(userData);
      id = userMap['id'];
      companyName = userMap['company_name'] ?? 'Unknown Company';
      print(id);
      print(companyName);
    } else {
      print('No user data found.');
    }

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUri = Uri.parse(baseUrl)
        .replace(path: '${Uri.parse(baseUrl).path}/api/jobs/user/$id'); //
    print("URL : ${apiUri}");
    // ยิง API
    try {
      var response = await http.get(apiUri,
          headers: {
            'Authorization': 'Bearer ${token}',
            'Content-Type': 'application/json',
          }
      );

      if (response.statusCode == 200) {
        // Decode the JSON response
        List<dynamic> jsonData = json.decode(response.body);
        print('Json data : $jsonData');

        List<Job> fetchedJobs = jsonData.map((data) => Job.fromJson(data)).toList();
        // Update the TextEditingController with the job title or any other field
        setState(() {
          jobs = fetchedJobs;
          isLoading = false;
        });

      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  final List<Company> companies = [
    Company(
      name: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      image: "assets/images/opendurian.png",
    )
  ];
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData(); // Refetch data when the app resumes.
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12), // ทำให้มุมมน
                      child: Image.asset(
                        companies.isNotEmpty
                            ? companies.first.image
                            : "assets/images/placeholder.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      companies.isNotEmpty
                          ? companyName.toString()
                          : "No Company",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 35),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return JobCard(job: jobs[index]);
                  },
                ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton:   FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CreatePost(
                  job: Job(
                    id: 0, // Default ID
                    title: "",
                    description: "",
                    location: "",
                    salaryRange: "",
                    jobPosition: "",
                    company: "",
                    status: true,
                    quantity: 0,
                    applicant_count: 0,
                    createdAt: "",
                    updatedAt: "",
                  ),
                ),
            ),
          ).then((result) {
            if (result == "created") {
              setState(() {});
            }

          });
        },
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30,),
      ),
    );
  }
}

/// Represents a company with a name, location, and image.
class Company {
  final String name, location, image;

  Company({
    required this.name,
    required this.location,
    required this.image,
  });
}

/// Represents a job with details like title, description, etc.
class Job {
  final int id;
  final String title;
  final String description;
  final String location;
  final String company;
  final String salaryRange;
  final int quantity;
  final String jobPosition;
  final bool status;
  final int applicant_count;
  final String createdAt;
  final String updatedAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.company,
    required this.salaryRange,
    required this.quantity,
    required this.jobPosition,
    required this.status,
    required this.applicant_count,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Job] instance from a JSON map.
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? 0, // แก้จาก 'ID' เป็น 'id' และใช้ ?? 0 กัน null
      company: json['company_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      salaryRange: json['salary_range'] ?? '',
      quantity: json['quantity'] ?? 0, // ใช้ ?? 0 กัน null
      jobPosition: json['job_position'] ?? '',
      status: json['status'] ?? false, // ถ้า null ให้เป็น false
      createdAt: json['created_at'] ?? '',
      applicant_count: json['applicant_count'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

/// A StatelessWidget that displays company information in a card format.
class CompanyCard extends StatelessWidget {
  /// The company data to display.
  final Company company;

  /// Constructor for [CompanyCard].
  CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: 4),
                  Text(
                    company.location,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                company.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A StatefulWidget that displays job information in a card format.
class JobCard extends StatefulWidget {
  /// The job data to display.
  final Job job;
  /// Constructor for [JobCard].
  JobCard({required this.job});

  @override
  _JobCardState createState() => _JobCardState();
}

/// State for the [JobCard] widget.
class _JobCardState extends State<JobCard> {
  @override
  Widget build(BuildContext context) {
    _count = widget.job.applicant_count;
    return GestureDetector(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: EdgeInsets.only(bottom: 12),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.job.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.job.company,
                    style: TextStyle(color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      "รับสมัครด่วน",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfo(
                              Icons.location_on, widget.job.location)),
                    ],
                  ),
                  SizedBox(height: 8), // เพิ่มระยะห่างระหว่างบรรทัด
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfo(
                              Icons.attach_money, widget.job.salaryRange)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: _buildInfo(
                              Icons.people, widget.job.quantity.toString())),
                    ],
                  ),
                  SizedBox(height: 8), // เพิ่มระยะห่างระหว่างบรรทัด
                  Row(
                    children: [
                      Expanded(
                          child:
                              _buildInfo(Icons.work, widget.job.jobPosition)),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text('จำนวนผู้สมัคร: $_count'),
                            SizedBox(width: 8),
                            Text(''),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              int job_id = widget.job.id;
                              String Job_name = widget.job.title;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    job_id: job_id,
                                    job_name: Job_name,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCADDFA),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size(30, 24),
                              shape: RoundedRectangleBorder(
                                // เพิ่ม shape
                                borderRadius:
                                    BorderRadius.circular(8.0), // กำหนดมุมโค้ง
                              ),
                            ),
                            child: Text(
                              "ตรวจสอบ",
                              style: TextStyle(
                                color: Color(0xFF0065FF), // กำหนดสี
                                fontSize: 14.0, // กำหนดขนาดตัวอักษร
                                // fontWeight: FontWeight.w600, // ทำให้ตัวอักษรหนา
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JobDetail(
                                      job: widget.job), // Open Job Detail
                                ),
                              ).then((result) {
                                if (result == "updated" ||
                                    result == "deleted") {
                                  setState(() {});
                                  if (context.findAncestorStateOfType<
                                          _CompanyScreenState>() !=
                                      null) {
                                    context
                                        .findAncestorStateOfType<
                                            _CompanyScreenState>()!
                                        .fetchData();
                                  }
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFACACA),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size(30, 24),
                              shape: RoundedRectangleBorder(
                                // เพิ่ม shape
                                borderRadius:
                                    BorderRadius.circular(8.0), // กำหนดมุมโค้ง
                              ),
                            ),
                            child: Text("แก้ไข",
                                style: TextStyle(color: Color(0xFFFF0000))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/images/opendurian.png",
                    // job.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

/// StatefulWidget that displays detailed job information and allows editing/deletion.
class JobDetail extends StatefulWidget {
  /// The job data to display and edit.
  final Job job;
  /// Constructor for [JobDetail].
  JobDetail({required this.job});

  @override
  _JobDetailState createState() => _JobDetailState();
}

/// State for the [JobDetail] widget.
class _JobDetailState extends State<JobDetail> {
  /// Controller for the job title input field.
  final TextEditingController _title = TextEditingController();

  /// Controller for the job location input field.
  final TextEditingController _location = TextEditingController();

  /// Controller for the job salary input field.
  final TextEditingController _salary = TextEditingController();

  /// Controller for the number of people needed input field.
  final TextEditingController _people = TextEditingController();

  /// Controller for the job position input field.
  final TextEditingController _position = TextEditingController();

  /// Controller for the job description input field.
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title.text = widget.job.title;
    _location.text = widget.job.location;
    _salary.text = widget.job.salaryRange;
    _people.text = widget.job.quantity.toString();
    _position.text = widget.job.jobPosition;
    _description.text = widget.job.description;
  }

  /// Updates the job information on the server.
  Future<void> updatePost(int jobId, Job updatedPost) async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUri = Uri.parse("$baseUrl/api/jobs/$jobId");

    String? token = await _storage.read(key: 'auth_token');

    try {
      var response = await http.put(
        apiUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "Title": updatedPost.title,
          "Description": updatedPost.description,
          "Location": updatedPost.location,
          "salaryRange": updatedPost.salaryRange,
          "JobPosition": updatedPost.jobPosition,
          "Quantity": updatedPost.quantity,
        }),
      );

      if (response.statusCode == 200) {
        print('Post updated successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post updated successfully!")));
        // _SuccessDialog(context, 'Post updated successfully');
        Navigator.pop(context, "updated");  /// Updates the job information on the server.
      } else {
        print('Failed to update job. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  /// Shows a confirmation dialog before deleting the job.
  Future<void> showDeleteConfirmationDialog(
      BuildContext context, int jobId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this job?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                deletePost(jobId); // Call delete function
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes the job from the server.
  Future<void> deletePost(int jobId) async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUri = Uri.parse("$baseUrl/api/jobs/$jobId");

    String? token = await _storage.read(key: 'auth_token');

    try {
      var response = await http.delete(
        apiUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        print("Post deleted successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post deleted successfully!")));
        // _SuccessDialog(context, 'Post deleted successfully');
        Navigator.pop(context, "deleted");
      } else {
        print("Failed to delete job. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error deleting job: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  "assets/images/opendurian.png",
                  // job.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ], // เพิ่ม opacity ให้สี orange
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.white, // เปลี่ยนสีพื้นหลังที่ต้องการ
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.job.company,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _location,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Image.asset(job.image, height: 100, width: 100, fit: BoxFit.cover,)
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _salary,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _people,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.work, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _position,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Posted 13 ชั่วโมงทีผ่านมา",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Job Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _description,
                            maxLines: null, // Allow multiline
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          Job updatedPost = Job(
                            id: widget.job.id,
                            title: _title.text,
                            description: _description.text,
                            location: _location.text,
                            salaryRange: _salary.text,
                            jobPosition: _position.text,
                            company: widget.job.company,
                            status: widget.job.status,
                            quantity: int.tryParse(_people.text) ??
                                widget.job.quantity,
                            applicant_count: widget.job.applicant_count,
                            createdAt: widget.job.createdAt,
                            updatedAt: DateTime.now().toString(),
                          );

                          await updatePost(widget.job.id, updatedPost);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Save Changes",
                            style: TextStyle(color: Colors.deepOrange)),
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Align(
                      child: ElevatedButton(
                        onPressed: () {
                          showDeleteConfirmationDialog(context, widget.job.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _salary.dispose();
    _people.dispose();
    _position.dispose();
    _description.dispose();
    super.dispose();
  }
}

/// StatefulWidget for creating a new job post.
// TODO: add CreatePost of company
class CreatePost extends StatefulWidget{
  /// Job data, passed in for potential initial values.
  final Job job;

  /// Constructor for [CreatePost].
  CreatePost({required this.job});

  @override
  _CreatePostState createState() => _CreatePostState();
}

/// State for the [CreatePost] widget.
class _CreatePostState extends State<CreatePost> {
  /// Controller for the job title input field.
  final TextEditingController _title = TextEditingController();

  /// Controller for the job location input field.
  final TextEditingController _location = TextEditingController();

  /// Controller for the job salary input field.
  final TextEditingController _salary = TextEditingController();

  /// Controller for the number of people needed input field.
  final TextEditingController _people = TextEditingController();

  /// Controller for the job position input field.
  final TextEditingController _position = TextEditingController();

  /// Controller for the job description input field.
  final TextEditingController _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _title.text = '';
    _location.text = '';
    _salary.text = '';
    _people.text ='';
    _position.text = '';
    _description.text = '';
  }

  /// Creates a new job post on the server.
  Future<void> createJob(int jobId, Job updatedJob) async {
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    print('API baseUrl: ${baseUrl}');
    int? id;

    String? token = await _storage.read(key: 'auth_token');
    String? userData = await _storage.read(key: 'user_data');
    print("userData : $userData");

    if (userData != null) {
      Map<String, dynamic> userMap = json.decode(userData);
      id = userMap['id'];
      print(id);
    } else {
      print('No user data found.');
    }

    Uri apiUri = Uri.parse("$baseUrl/api/jobs");

    try {
      var response = await http.post(
        apiUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "UserID": id,
          "Title": updatedJob.title,
          "Description": updatedJob.description,
          "Location": updatedJob.location,
          "salaryRange": updatedJob.salaryRange,
          "JobPosition": updatedJob.jobPosition,
          "Quantity": updatedJob.quantity,
          "Status": true
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Post create successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post create successfully!")));
        // _SuccessDialog(context, 'Post create successfully');
        Navigator.pop(context, "created"); // Notify the previous screen of creation.
      } else {
        print('Failed to update job. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _salary.dispose();
    _people.dispose();
    _position.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  "assets/images/opendurian.png",
                  // job.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent
                      ], // เพิ่ม opacity ให้สี orange
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.white, // เปลี่ยนสีพื้นหลังที่ต้องการ
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.job.company,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _location,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              // Image.asset(job.image, height: 100, width: 100, fit: BoxFit.cover,)
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _salary,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _people,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.work, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _position,
                              style: TextStyle(
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Posted 13 ชั่วโมงทีผ่านมา",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Job Description",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _description,
                            maxLines: null, // Allow multiline
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          Job updatedJob = Job(
                            id: widget.job.id,
                            title: _title.text,
                            description: _description.text,
                            location: _location.text,
                            salaryRange: _salary.text,
                            jobPosition: _position.text,
                            company: widget.job.company,
                            status: widget.job.status,
                            quantity:
                                int.tryParse(_people.text) ?? widget.job.quantity,
                            applicant_count: widget.job.applicant_count,
                            createdAt: widget.job.createdAt,
                            updatedAt: DateTime.now().toString(),
                          );

                          await createJob(widget.job.id, updatedJob);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Create",
                            style: TextStyle(color: Colors.deepOrange)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
