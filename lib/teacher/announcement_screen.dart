import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';

/// Announcement Screen - For teachers to create and manage announcements
/// 
/// Teachers can create announcements with date and time.
/// Announcements are visible only to students of the same school.
/// All data is school-scoped and isolated.
class AnnouncementScreen extends StatefulWidget {
  final String schoolCode;

  const AnnouncementScreen({
    super.key,
    required this.schoolCode,
  });

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
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

  /// Shows date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  /// Shows time picker
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Creates a new announcement
  Future<void> _createAnnouncement() async {
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

      await firestore.collection('announcements').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'date': date,
        'time': time,
        'schoolCode': widget.schoolCode, // CRITICAL: School isolation
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': Timestamp.now(), // For sorting
      });

      if (!mounted) return;

      // Clear form
      _titleController.clear();
      _messageController.clear();
      _dateController.clear();
      _timeController.clear();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement created successfully!'),
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
          content: Text('Failed to create announcement: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: Column(
          children: [
            // Create Announcement Form
            Expanded(
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
                              'Create New Announcement',
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
                                hintText: 'Enter announcement title',
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
                                hintText: 'Enter announcement message',
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
                                onPressed: _isLoading ? null : _createAnnouncement,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: AppColors.textWhite,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'Create Announcement',
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
                    
                    // Existing Announcements
                    const Text(
                      'Recent Announcements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAnnouncementsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of announcements
  Widget _buildAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getAnnouncementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No announcements yet.'),
          );
        }

        final announcements = snapshot.data!.docs;
        announcements.sort((a, b) {
          final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (timestampA == null || timestampB == null) return 0;
          return timestampB.compareTo(timestampA); // Newest first
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index].data() as Map<String, dynamic>;
            final announcementId = announcements[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  announcement['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(announcement['message'] ?? ''),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (announcement['date'] != null)
                          Chip(
                            label: Text(announcement['date']),
                            avatar: const Icon(Icons.calendar_today, size: 16),
                          ),
                        const SizedBox(width: 8),
                        if (announcement['time'] != null)
                          Chip(
                            label: Text(announcement['time']),
                            avatar: const Icon(Icons.access_time, size: 16),
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.red),
                  onPressed: () => _deleteAnnouncement(announcementId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Gets announcements stream for the school
  /// Note: We don't use orderBy here to avoid index requirement
  /// Sorting is done in memory
  Stream<QuerySnapshot> _getAnnouncementsStream() {
    return Stream.fromFuture(
      FirestoreService.firestore(widget.schoolCode),
    ).asyncExpand((firestore) {
      return firestore
          .collection('announcements')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .snapshots();
    });
  }

  /// Deletes an announcement
  Future<void> _deleteAnnouncement(String announcementId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
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
        await firestore.collection('announcements').doc(announcementId).delete();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted'),
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
}

