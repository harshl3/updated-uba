import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class TestPage extends StatefulWidget {
  final String schoolCode;
  const TestPage({super.key, required this.schoolCode});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Test - School ${widget.schoolCode}')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 60),
            backgroundColor: Colors.green,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            try {
              final firestore = await FirestoreService.firestore(widget.schoolCode);
              
              await firestore.collection('students').add({
                'name': 'Rahul',
                'school': 'School ${widget.schoolCode}',
                'time': DateTime.now(),
              });

              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Data added to School ${widget.schoolCode}'),
                  backgroundColor: Colors.green,
                ),
              );

              if (kDebugMode) {
                debugPrint('Data added to School ${widget.schoolCode}');
              }
            } catch (e) {
              if (!mounted) return;

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              if (kDebugMode) {
                debugPrint('Error adding data to School ${widget.schoolCode}: $e');
              }
            }
          },
          child: Text('Add Data to School ${widget.schoolCode}', style: const TextStyle(color: Colors.white),),
        ),
      ),
    );
  }
}
