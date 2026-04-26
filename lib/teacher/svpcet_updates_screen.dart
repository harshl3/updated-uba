import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firestore_service.dart';
import '../theme/app_colors.dart';

class SvpcetUpdatesScreen extends StatefulWidget {
  final String schoolCode;

  const SvpcetUpdatesScreen({super.key, required this.schoolCode});

  @override
  State<SvpcetUpdatesScreen> createState() => _SvpcetUpdatesScreenState();
}

class _SvpcetUpdatesScreenState extends State<SvpcetUpdatesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _timeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _createUpdate() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and message'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);
      final now = DateTime.now();
      final date = _dateController.text.trim().isNotEmpty
          ? _dateController.text.trim()
          : '${now.day}/${now.month}/${now.year}';
      final time = _timeController.text.trim().isNotEmpty
          ? _timeController.text.trim()
          : '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      await firestore.collection('svpcet_updates').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'date': date,
        'time': time,
        'schoolCode': widget.schoolCode,
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': Timestamp.now(),
      });

      if (!mounted) return;
      _titleController.clear();
      _messageController.clear();
      _dateController.clear();
      _timeController.clear();
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SVPCET update posted successfully!'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post update: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot> _getUpdatesStream() {
    return Stream.fromFuture(
      FirestoreService.firestore(widget.schoolCode),
    ).asyncExpand((firestore) {
      return firestore
          .collection('svpcet_updates')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .snapshots();
    });
  }

  Future<void> _deleteUpdate(String updateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Update'),
        content: const Text('Are you sure you want to delete this update?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final firestore = await FirestoreService.firestore(widget.schoolCode);
        await firestore.collection('svpcet_updates').doc(updateId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update deleted'),
            backgroundColor: AppColors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SVPCET Updates')),
      body: Container(
        color: AppColors.backgroundLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Post SVPCET Update',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter update title',
                          prefixIcon: Icon(Icons.title),
                          filled: true,
                          fillColor: AppColors.cardWhite,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Enter update details',
                          prefixIcon: Icon(Icons.message),
                          filled: true,
                          fillColor: AppColors.cardWhite,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: _selectDate,
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                hintText: 'Select date',
                                prefixIcon: Icon(Icons.calendar_today),
                                filled: true,
                                fillColor: AppColors.cardWhite,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              onTap: _selectTime,
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                hintText: 'Select time',
                                prefixIcon: Icon(Icons.access_time),
                                filled: true,
                                fillColor: AppColors.cardWhite,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.textWhite,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  'Post Update',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent SVPCET Updates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _getUpdatesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No updates posted yet.'));
                  }

                  final updates = snapshot.data!.docs;
                  updates.sort((a, b) {
                    final timestampA =
                        (a.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    final timestampB =
                        (b.data() as Map<String, dynamic>)['timestamp']
                            as Timestamp?;
                    if (timestampA == null || timestampB == null) return 0;
                    return timestampB.compareTo(timestampA);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: updates.length,
                    itemBuilder: (context, index) {
                      final update = updates[index].data() as Map<String, dynamic>;
                      final updateId = updates[index].id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                update['title'] ?? 'No Title',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(update['message'] ?? ''),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (update['date'] != null)
                                    Chip(
                                      label: Text(update['date']),
                                      avatar: const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                    ),
                                  if (update['time'] != null)
                                    Chip(
                                      label: Text(update['time']),
                                      avatar: const Icon(
                                        Icons.access_time,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _deleteUpdate(updateId),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.red,
                                    side: const BorderSide(color: AppColors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
