import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// About Us Screen
///
/// NOTE: Please update the developer names / college info below to match your team.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor:Color(0xFF4A90E2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildCard(
              'SVPCET',
              'St. Vincent Pallotti College of Engineering and Technology was established in 2004 by the Nagpur Pallottine Society. The College is accredited by NAAC with A grade. The College is affiliated to Nagpur University approved by Director of Technical Education, Mumbai and AICTE, Government of India',
              Colors.blue,
              'assets/drawer/svpcet.jpeg',
              largerImage: true,
              teamMembers: [],
            ),
            const SizedBox(height: 20),
            buildCard(
              'DEPARTMENT OF INFORMATION TECHNOLOGY',
              'To be a center of excellence in the domain of Information Technology to nurture future professionals. To impart computing knowledge in the field of information technology and emerging domains and to provide an effective learning environment for developing future technocrats with professional ethos and attitude for lifelong learning.',
              Colors.orange,
              'assets/drawer/college_logo.png',
              teamMembers: [],
            ),



            const SizedBox(height: 20),
            buildCard(
              'MEET OUR TEAM',
              'Mentored by: Dr. Manoj Bramhe \n\nGuided by: Dr. Priti Uparkar \n\nDeveloped by: ',
              const Color.fromARGB(255, 120, 31, 136),
              '',
              teamMembers: [
                TeamMember('1.Archit Kanadkhedkar'),
                TeamMember('2.Prasad Mankar'),
                TeamMember('3.Harshal Mendhule'),
                TeamMember('4.Gauri Thakre'),
                TeamMember('5.Anshu Bongade'),
                TeamMember('6.Divyanshu Nikhare')
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard(
      String title,
      String content,
      Color color,
      String imagePath, {
        bool largerImage = false,
        required List<TeamMember> teamMembers,
      }) {
    return AnimatedContainer(
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 175, 241, 195), // #84fab0
            Color.fromARGB(255, 142, 202, 234), // #8fd3f4
          ],
          begin: Alignment.topRight,   // matches 120deg direction
          end: Alignment.bottomLeft,
          stops: [0.0, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(40, 0, 0, 0), // stronger shadow for separation
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),



      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath.isNotEmpty)
            SizedBox(
              height: largerImage ? 150 : 50,
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  // Image click behavior removed since no external links
                },
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          if (teamMembers.isNotEmpty)
            ...teamMembers.map((member) => buildTeamMember(member)),
        ],
      ),
    );
  }

  Widget buildTeamMember(TeamMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        member.name,
        style: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }
}

class TeamMember {
  final String name;

  TeamMember(this.name);
}


