/// @author Ackarapon Muenrach 
/// 
/// @student_id 640510689
/// 
/// @feature ค้นหา Job (Search)
/// 
/// @description ผู้ใช้สามารถค้นหา Job ตามหัวข้อ Job ได้
/// 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'dart:convert';

/// Instance of the secure storage for storing sensitive data.
final _storage = FlutterSecureStorage();

/// Displays the main job listing screen.
class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

/// Manages the state for the HomeScreen widget.
class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// List of all jobs fetched from the API.
  List<Job> jobs = [];
  /// List of jobs filtered based on the search query.
  List<Job> filteredJobs = [];
  /// Indicates whether the data is being loaded.
  bool isLoading = true;
  /// Stores the current search query.
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData();
    }
  }

  /// Fetches job data from the API.
  Future<void> fetchData() async {
    setState(() => isLoading = true);
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';

    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUri = Uri.parse('$baseUrl/api/jobs');

    try {
      String? token = await _storage.read(key: 'auth_token');

      var response = await http.get(
        apiUri,
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> jsonData = json.decode(response.body);
        List<Job> fetchedJobs =
            jsonData.map((data) => Job.fromJson(data)).toList();

        setState(() {
          jobs = fetchedJobs;
          filteredJobs = _filterJobs(_searchQuery);
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Map<String, String> user = await _storage.readAll();
        print("userinfo : ${user}");
        await _storage.deleteAll();

        throw Exception('Failed to load jobs : (${response.statusCode})');
      } else {
        throw Exception('Failed to load jobs : (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      setState(() => isLoading = false);
    }
  }

  /// Filters the job list based on the search query.
  List<Job> _filterJobs(String query) {
    if (query.isEmpty) {
      return jobs; // ถ้าคำค้นหาเป็นค่าว่าง ให้แสดงรายการงานทั้งหมด
    } else {
      return jobs
          .where((job) => job.title.toLowerCase().contains(query.toLowerCase()))
          .toList(); // กรองงานที่มีคำค้นหาใน title
    }
  }

  /// Updates the search query and filters the job list.
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      filteredJobs = _filterJobs(query);
    });
    print("_searchQuery  :  ${_searchQuery}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              Center(
                child: Text(
                  "JOB THAI V2",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Hello BEKBEK !",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 15),
              // เพิ่ม TextField สำหรับค้นหา
              TextField(
                onChanged: _updateSearchQuery, // เรียกฟังก์ชันเมื่อมีการพิมพ์
                decoration: InputDecoration(
                  hintText: 'Search for jobs...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              Expanded(
                child: isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator()) // แสดงตัวหมุนเมื่อโหลด
                    : jobs == null
                        ? Center(
                            child: Text(
                                "Failed   to load jobs or no job at the moment."), // แสดงข้อความเมื่อ jobs เป็น null
                          )
                        : ListView.builder(
                            itemCount: filteredJobs.length,
                            itemBuilder: (context, index) {
                              return JobCard(job: filteredJobs[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Represents a job object.
class Job {
  final int id;
  final String title;
  final String description;
  final String location;
  final String salaryRange;
  final int quantity;
  final String jobPosition;
  final bool status;
  final String createdAt;
  final String updatedAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.salaryRange,
    required this.quantity,
    required this.jobPosition,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Job object from JSON data.
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? 0, // แก้จาก 'ID' เป็น 'id' และใช้ ?? 0 กัน null
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      salaryRange: json['salary_range'] ?? '',
      quantity: json['quantity'] ?? 0, // ใช้ ?? 0 กัน null
      jobPosition: json['job_position'] ?? '',
      status: json['status'] ?? false, // ถ้า null ให้เป็น false
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  /// Converts the Job object to JSON format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'salaryRange': salaryRange,
      'quantity': quantity,
      'jobPosition': jobPosition,
      'description': description,
    };
  }
}

/// Displays a card representing a single job.
class JobCard extends StatelessWidget {
  final Job job;

  JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(job: job),
          ),
        );
      },
      child: Card(
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
                      job.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // ตัดข้อความหากยาวเกิน
                      maxLines: 2,
                    ),
                    SizedBox(height: 4),
                    Text(
                      job.title,
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
                            child: _buildInfo(Icons.location_on, job.location)),
                      ],
                    ),
                    SizedBox(height: 8), // เพิ่มระยะห่างระหว่างบรรทัด
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfo(
                                Icons.attach_money, job.salaryRange)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfo(
                                Icons.people, job.quantity.toString())),
                      ],
                    ),
                    SizedBox(height: 8), // เพิ่มระยะห่างระหว่างบรรทัด
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfo(Icons.work, job.jobPosition)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/images/opendurian.png",
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
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
/// Represents the screen to display detailed information about a job.
///
/// This screen shows the job title, description, location, salary, and allows the user to save the job or apply for it.
class JobDetailScreen extends StatefulWidget {

  final Job job;
  /// Creates a [JobDetailScreen].
  ///
  /// The [job] parameter must not be null.
  JobDetailScreen({required this.job});

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  /// Indicates whether the job is saved by the user.
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfJobSaved();
  }

  /// Checks if the job is already saved in secure storage.
  Future<void> _checkIfJobSaved() async {
    String? savedJob = await _storage.read(key: 'saved_job_${widget.job.id}');
    if (savedJob != null) {
      setState(() {
        isSaved = true;
      });
    }
  }

  /// Saves the job to secure storage.
  Future<void> saveJob() async {
    try {
      String jobJson = jsonEncode(widget.job.toJson());

      await _storage.write(
        key: 'saved_job_${widget.job.id}',
        value: jobJson,
      );

      String? storedJob =
          await _storage.read(key: 'saved_job_${widget.job.id}');
      if (storedJob != null) {
        print("Saved Job: $storedJob");
      } else {
        print("No job found in storage.");
      }
    } catch (e) {
      // Consider adding error handling for the save operation.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // เพิ่มบรรทัดนี้
      appBar: AppBar(
        backgroundColor: Colors.transparent, // เปลี่ยนสีพื้นหลังเป็นโปร่งใส
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.job.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.job.title,
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
                        Text(
                          widget.job.location,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          widget.job.salaryRange,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          widget.job.quantity.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.work, size: 18, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          widget.job.jobPosition,
                          style: TextStyle(fontSize: 16),
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
                      padding: EdgeInsets.symmetric(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UploadResumeScreen(widget.job.id),
                                ),
                              ).then((result) {
                                if (result == 'success') {
                                  setState(() {});
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              "สมัครงาน",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaved ? null : saveJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCADDFA),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              textStyle: TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                // เพิ่ม shape
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              isSaved
                                  ? "บันทึกแล้ว"
                                  : "บันทึก", // เปลี่ยนข้อความตามสถานะ
                              style: TextStyle(
                                color:
                                    isSaved ? Colors.grey : Color(0xFF0065FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.job.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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

/// Displays a card that shows the job in detail.
class UploadResumeScreen extends StatefulWidget {
  /// The ID of the job for which the resume is being uploaded.
  final int jobId; // เพิ่มตัวแปรเก็บ jobId

  /// Creates an [UploadResumeScreen].
  ///
  /// The [jobId] parameter is required and represents the ID of the job
  const UploadResumeScreen(this.jobId, {Key? key}) : super(key: key);

  @override
  UploadResumeScreenState createState() => UploadResumeScreenState();
}

/// The state of the [UploadResumeScreen] widget.
class UploadResumeScreenState extends State<UploadResumeScreen> {
  /// Indicates whether the file upload is in progress.
  bool isLoading = false;
  /// The selected file to be uploaded.
  File? selectedFile;
  /// The name of the selected file.
  String? fileName;
  /// The status message to display after the upload attempt.
  String? uploadStatusMessage;

  /// Allows the user to pick a PDF file from their device.
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // อนุญาตเฉพาะไฟล์ PDF
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  /// Uploads the selected file to the server.
  Future<void> uploadFile() async {
    if (selectedFile == null) return;

    setState(() {
      isLoading = true; // เริ่มโหลด
    });

    String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
    String url =
        "$baseUrl/api/jobs/${widget.jobId}/apply"; // ใช้ jobId ที่รับมา

    String? token = await _storage.read(key: 'auth_token');

    var uri = Uri.parse(url);
    var request = http.MultipartRequest("POST", uri)
      ..headers['Authorization'] =
          'Bearer $token' // เพิ่ม Token เข้าไปใน Header
      ..headers['Content-Type'] = 'multipart/form-data' // กำหนด Content-Type
      ..files.add(await http.MultipartFile.fromPath(
        'resume',
        selectedFile!.path,
      ));

    var response = await request.send();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        uploadStatusMessage = "✅ อัปโหลดสำเร็จ!";
        Navigator.pop(this.context, "success");
      } else {
        uploadStatusMessage = "❌ อัปโหลดไม่สำเร็จ (${response.statusCode})";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // จัดให้อยู่ตรงกลางแนวตั้ง
              crossAxisAlignment:
                  CrossAxisAlignment.center, // จัดให้อยู่ตรงกลางแนวนอน
              children: [
                Text(
                  "Upload file Resume",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: pickFile,
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file,
                              size: 40, color: Colors.grey[700]),
                          SizedBox(height: 10),
                          Text(
                            fileName ?? "Upload file\n(รองรับเฉพาะ PDF)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed:
                      selectedFile != null && !isLoading ? uploadFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Submit",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
                if (uploadStatusMessage != null) ...[
                  SizedBox(height: 20),
                  Text(
                    uploadStatusMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      color: uploadStatusMessage!.contains("✅")
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
