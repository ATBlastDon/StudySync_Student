import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Forms extends StatefulWidget {
  final String year;
  final String rollNo;
  final String sem;
  final String ay;
  final String dept;

  const Forms({
    super.key,
    required this.year,
    required this.rollNo,
    required this.sem,
    required this.ay,
    required this.dept,
  });

  @override
  State<Forms> createState() => _FormsState();
}

class _FormsState extends State<Forms> {

  void _showNoticeDialogue() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          titlePadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          title: Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text(
                'Tip',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                    color: Colors.black, fontFamily: 'Outfit', fontSize: 16),
                children: <TextSpan>[
                  TextSpan(
                    text: "Tap on a Card: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "Tap on a leave card to view the complete details of the application.\n\n",
                  ),
                  TextSpan(
                    text: "Editing a Request: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "You can edit the 'Reason for Leave' after viewing the details of a specific leave application.\n\n",
                  ),
                  TextSpan(
                    text: "Status: ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  TextSpan(
                    text:
                    "The status of the leave application (Pending, Accepted, Rejected) is displayed on each card.",
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: 'Outfit',
                      fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'L E A V E   F O R M',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.greenAccent, Colors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.grey[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _showNoticeDialogue,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('leave_forms')
              .doc(widget.dept)
              .collection(widget.ay)
              .doc(widget.year)
              .collection(widget.sem)
              .doc('forms')
              .collection('details')
              .where('rollNo', isEqualTo: widget.rollNo)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              );
            }

            var leaveForms = snapshot.data!.docs;
            // Check if there are no submitted forms.
            if (leaveForms.isEmpty) {
              return const Center(
                child: Text(
                  'There is No Submitted Forms',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: leaveForms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var leaveForm = leaveForms[index];
                final status = leaveForm['status'];
                final submittedAt =
                (leaveForm['submittedAt'] as Timestamp).toDate();
                final theme = Theme.of(context);

                return _buildLeaveCard(leaveForm, status, submittedAt, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaveCard(QueryDocumentSnapshot leaveForm, String status,
      DateTime submittedAt, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showFormDetails(leaveForm),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoRow(leaveForm),
              const SizedBox(height: 12),
              _buildReasonSection(leaveForm),
              if (leaveForm['imageUrl'] != null &&
                  leaveForm['imageUrl'].isNotEmpty)
                _buildImagePreview(leaveForm),
              const SizedBox(height: 12),
              _buildStatusRow(status, submittedAt, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(QueryDocumentSnapshot leaveForm) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            leaveForm['rollNo']
                .toString()
                .substring(leaveForm['rollNo'].length - 2),
            style: const TextStyle(
                color: Colors.teal, fontFamily: 'Outfit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leaveForm['fullName'],
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${leaveForm['year']} • Sem ${widget.sem}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection(QueryDocumentSnapshot leaveForm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REASON FOR LEAVE',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          leaveForm['reason'],
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(QueryDocumentSnapshot leaveForm) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: leaveForm['imageUrl'],
          height: 150,
          fit: BoxFit.cover,
          progressIndicatorBuilder: (_, __, progress) => Center(
            child: CircularProgressIndicator(
              value: progress.progress,
              strokeWidth: 2,
            ),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      String status, DateTime submittedAt, ThemeData theme) {
    final statusColor = _getStatusColor(status);
    final formattedDate = DateFormat('MMM dd, yyyy').format(submittedAt);
    final formattedTime = DateFormat('hh:mm a').format(submittedAt);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(status),
                  size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              formattedTime,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  void _showFormDetails(QueryDocumentSnapshot leaveForm) {
    showDialog(
      context: context,
      builder: (context) => _buildDetailsDialog(leaveForm),
    );
  }

  Widget _buildDetailsDialog(QueryDocumentSnapshot leaveForm) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(leaveForm['status']);

    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                'Request Details',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Outfit',
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailItem('Full Name', leaveForm['fullName']),
            _buildDetailItem('Roll Number', leaveForm['rollNo']),
            _buildDetailItem('Academic Year', leaveForm['year']),
            _buildDetailItem('Start Date', leaveForm['startDate']),
            _buildDetailItem('End Date', leaveForm['endDate']),
            const Divider(height: 30),
            Text(
              'Reason for Leave',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              leaveForm['reason'],
              style: theme.textTheme.bodyMedium,
            ),
            if (leaveForm['imageUrl'] != null &&
                leaveForm['imageUrl'].isNotEmpty)
              _buildDialogImage(leaveForm['imageUrl']),
            const Divider(height: 30),
            _buildStatusChip(leaveForm['status'], statusColor),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontFamily: "Outfit"),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _showEditDialog(leaveForm.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                        color: Colors.white, fontFamily: 'Outfit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogImage(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 180,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 180,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Chip(
          label: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
      ],
    );
  }

  void _showEditDialog(String documentId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Reason',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'New Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        _editLeaveRequest(documentId, controller.text);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                          color: Colors.white, fontFamily: 'Outfit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editLeaveRequest(String docId, String newReason) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('leave_forms')
          .doc(widget.dept)
          .collection(widget.ay)
          .doc(widget.year)
          .collection(widget.sem)
          .doc('forms')
          .collection('details')
          .doc(docId);

      await docRef.update({'reason': newReason});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reason updated successfully'),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating reason: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
