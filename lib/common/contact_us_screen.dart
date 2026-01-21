import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'more_menu_page.dart';


class ContactDetail {
  final String description;
  final String action;

  ContactDetail(this.description, this.action);
}

/// Contact Us Screen
///
/// Shows static contact details (emails + phone numbers).
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.white, // Set the text color to white
            fontSize: 20, // Adjust the font size if needed
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'contactCard1',
              child: buildContactCard(
                'For any kind of query \ncontact between 9:00 a.m to 5:00 p.m.',
                Icons.mail,
                [
                  ContactDetail('it@stvincentngp.edu.in',
                      'mailto:it@stvincentngp.edu.in'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Hero(
              tag: 'contactCard2',
              child: buildContactCard(
                'Phone',
                Icons.phone,
                [
                  ContactDetail('Developer 1: 8625892362', 'tel:8625892362'),
                  ContactDetail('Developer 2: 9370324653', 'tel:9370324653'),
                  ContactDetail('Developer 3: 8766453345', 'tel:8766453345'),
                  ContactDetail('Developer 4: 9860725467', 'tel:9860725467'),
                  ContactDetail('Developer 5: 7385065507', 'tel:7385065507'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/drawer/test3.png', // Replace with your image asset path
              fit: BoxFit.cover, // Adjust the fit as needed
              height: 350, // Set the height as needed
              width: double.infinity, // Occupy full width
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContactCard(
      String title, IconData icon, List<ContactDetail> details) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.grey.withOpacity(0.5), // Set shadow color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 175, 241, 195), // #84fab0
              Color.fromARGB(255, 160, 212, 237), // #8fd3f4
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: details
                    .map(
                      (detail) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0), // Add space between items
                    child: InkWell(
                      onTap: () async {
                        if (await canLaunch(detail.action)) {
                          await launch(detail.action);
                        } else {
                          throw 'Could not launch ${detail.action}';
                        }
                      },
                      child: Row(
                        children: [
                          Icon(icon),
                          const SizedBox(width: 8),
                          Text(detail.description),
                        ],
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


