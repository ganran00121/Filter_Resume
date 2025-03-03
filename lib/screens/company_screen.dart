import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CompanyScreen extends StatefulWidget {
  @override
  _CompanyScreenState createState() => _CompanyScreenState();
}

final TextEditingController _title = TextEditingController();
final TextEditingController _location = TextEditingController();
final TextEditingController _salary = TextEditingController();
final TextEditingController _people = TextEditingController();
final TextEditingController _position = TextEditingController();
final TextEditingController _test = TextEditingController();

class _CompanyScreenState extends State<CompanyScreen> {

  Future<Job?> fetchData() async {
    print('FetchData');
    String baseUrl = dotenv.env['BASE_URL'] ?? 'default_url';
    print('API baseUrl: ${baseUrl}');
    // ตรวจสอบให้แน่ใจว่า baseUrl มี http:// หรือ https:// นำหน้า
    if (!baseUrl.startsWith('http')) {
      baseUrl = 'https://$baseUrl';
    }

    Uri apiUri = Uri.parse(baseUrl).replace(path: '${Uri
        .parse(baseUrl)
        .path}/api/jobs/2');
    print("URL : ${apiUri}");
    // ยิง API
    try {
      var response = await http.get(apiUri);

      if (response.statusCode == 200) {
        // Decode the JSON response
        Map<String, dynamic> jsonData = jsonDecode(response.body);
        print('API Response: ${response.body}');
        // Update the TextEditingController with the job title or any other field
        Job job = Job.frommJson(jsonData);

        _test.text = job.title;

        print('API Response: ${jsonData}');
        print('Job Title: ${job.title}');
        return job;
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
        return null;
      }
    }
    catch (e) {
      print('Error fetching data: $e');
      return null;
    }
  }

  final List<Company> companies = [
    Company(
      name: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      image: "assets/images/opendurian.png",
    )
  ];
  final List<Job> jobs = [
    Job(
      id: 1,
      title: "Full Stack Developer (WFH) [J108]",
      company: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      salary: "25,000 - 40,000 per month",
      people: 2,
      position: "Full Stack Developer",
      image: "assets/images/opendurian.png",
      applicant_count: "3",
      description: "\nlorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt\n\nRequirement\n\nlorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt\n\nAdditional\n\nlorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt",
    )
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _title.text = jobs[0].title;
    _salary.text = jobs[0].salary;
    _location.text = jobs[0].location;
    // _people.text = jobs[0].people;
    _position.text = jobs[0].position;
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
                          ? companies.first.name
                          : "No Company",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 35),
              Expanded(
                child: ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    return JobCard(job: jobs[index]);
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {},
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Company {
  final String name, location, image;

  Company({
    required this.name,
    required this.location,
    required this.image,
  });
}

class Job {
  final String title,
      company,
      location,
      salary,
      position,
      image,
      applicant_count,
      description;
  final int id,
      people;


  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.people,
    required this.position,
    required this.image,
    required this.applicant_count,
    required this.description,
    required this.id,
  });

  factory Job.frommJson(Map<String, dynamic> json) {
    return Job(
      id: json['ID'] ?? 0,
      title: json['Title'] ?? 'No Title',
      company: json['Company'] ?? 'Unknown Company',
      location: json['Location'] ?? 'Unknown Location',
      salary: json['SalaryRange'] ?? 'No Salary Info',
      description: json['description'] ?? 'No Description',
      people: json['Quantity'] ?? 'No People',
      position: json['JobPosition'] ?? 'No Position',
      image: json['image'] ?? 'No Image',
      applicant_count: json['count'] ?? 'No Count',
    );
  }


}

class CompanyCard extends StatelessWidget {
  final Company company;

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

class JobCard extends StatelessWidget {
  final Job job;

  JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
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
                    job.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  SizedBox(height: 4),
                  Text(
                    job.company,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfo(Icons.location_on, job.location),
                      _buildInfo(Icons.attach_money, job.salary),
                      // _buildInfo(Icons.people, job.people),
                      _buildInfo(Icons.work, job.position),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text("จำนวนคนสมัคร :"),
                            SizedBox(width: 8),
                            Text(job.applicant_count),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {

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
                            child: Text("ตรวจสอบ",
                              style: TextStyle(
                                color: Color(0xFF0065FF), // กำหนดสี
                                fontSize: 14.0,           // กำหนดขนาดตัวอักษร
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
                                    builder: (context) => JobDetail(job: job)
                                ),
                              );
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
                                style: TextStyle(
                                    color: Color(0xFFFF0000))
                            ),
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
                    job.image,
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

// TODO: add detail of company
class JobDetail extends StatelessWidget {
  final Job job;
  JobDetail({required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios,
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
                  job.image,
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
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      job.company,
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
                            children: [
                            ],
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
                            children: [
                            ],
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
                            children: [
                            ],
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
                            controller: _test,
                            maxLines: null, // Allow multiline
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
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
