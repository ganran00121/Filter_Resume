import 'package:flutter/material.dart';

class CompanyScreen extends StatelessWidget {
  final List<Company> companies = [
    Company(
      name: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      image: "assets/images/opendurian.png",
    )
  ];
  final List<Job> jobs = [
    Job(
      title: "Full Stack Developer (WFH) [J108]",
      company: "OpenDurian Co., Ltd.",
      location: "จตุจักร กรุงเทพมหานคร",
      salary: "25,000 - 40,000 per month",
      people: "1-4 คน",
      position: "Full Stack Developer",
      image: "assets/images/opendurian.png",
      applicant_count: "150",
    )
  ];

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
      people,
      position,
      image,
      applicant_count;

  Job({
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.people,
    required this.position,
    required this.image,
    required this.applicant_count,
  });
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
                      _buildInfo(Icons.people, job.people),
                      _buildInfo(Icons.work, job.position),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text("Count :"),
                            SizedBox(width: 8),
                            Text(job.applicant_count),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFCADDFA),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
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
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFACACA),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
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
