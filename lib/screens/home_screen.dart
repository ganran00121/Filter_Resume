import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<Job> jobs = [
    Job(
      title: "Full Stack Developer (WFH) [J108]",
      company: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      salary: "25,000 - 40,000 per month",
      people: "1-4 คน",
      position: "Full Stack Developer",
      image: "assets/images/opendurian.png",
    ),
    Job(
      title: "Full Stack Javascript Developer",
      company: "Future Makers Co., Ltd.",
      location: "คลองสาม กรุงเทพมหานคร",
      salary: "35,000 - 52,500 per month",
      people: "1-3 คน",
      position: "Full Stack Developer",
      image: "assets/images/futuremakers.png",
    ),
    Job(
      title: "เจ้าหน้าที่ประสานงานโครงการ (IT Support)",
      company: "บริษัท ไทยเบฟเวอเรจ จำกัด (มหาชน)",
      location: "จ.นครศรีธรรมราช",
      salary: "25,000 - 40,000 บาท",
      people: "1-4 คน",
      position: "IT Support",
      image: "assets/images/thaibev.png",
    ),
  ];

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
              Expanded(
                child: ListView.builder(
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
    );
  }
}

class Job {
  final String title, company, location, salary, people, position, image;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.people,
    required this.position,
    required this.image,
  });
}

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
                      _buildInfo(Icons.people, job.people),
                      _buildInfo(Icons.work, job.position),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                job.image,
                width: 50, // ลดขนาดเพื่อให้พอดีหน้าจอ
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
      mainAxisSize: MainAxisSize.min, // ไม่ให้ Row กินพื้นที่ทั้งหมด
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

class JobDetailScreen extends StatelessWidget {
  final Job job;

  JobDetailScreen({required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // เพิ่มบรรทัดนี้
      appBar: AppBar(
        backgroundColor: Colors.transparent, // เปลี่ยนสีพื้นหลังเป็นโปร่งใส
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white), // เปลี่ยนสี icon เป็นสีขาว
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
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent], // เพิ่ม opacity ให้สี orange
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
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
                      Text(
                        job.location,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 18, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        job.salary,
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
                        job.people,
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
                        job.position,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.symmetric(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            textStyle: TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder( // เพิ่ม shape
                              borderRadius: BorderRadius.circular(8.0), // กำหนดมุมโค้ง
                            ),
                          ),
                          child: Text(
                            "สมัครงาน",
                            style: TextStyle(color: Colors.white), // กำหนด color ที่ Text widget โดยตรง
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue[100],
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            textStyle: TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder( // เพิ่ม shape
                              borderRadius: BorderRadius.circular(8.0), // กำหนดมุมโค้ง
                            ),
                          ),
                          child: Text(
                            "บันทึก",
                            style: TextStyle(color: Colors.lightBlue), // กำหนด color ที่ Text widget โดยตรง
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Job Description",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                    style: TextStyle(fontSize: 16),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
