import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  final KidData kid;

  const ApplyLeaveScreen({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTemplate = '';
  final TextEditingController _customReasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _templates = [
    'Sick Leave',
    'Urgent Work',
    'Medical Checkup',
    'Family Event',
    'Other'
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart 
        ? (_startDate ?? DateTime.now()) 
        : (_endDate ?? _startDate ?? DateTime.now());
        
    final firstDate = DateTime.now().subtract(const Duration(days: 1)); // allow from yesterday just in case
    final lastDate = DateTime.now().add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ThemeColors.primaryPurple,
              onPrimary: Colors.white,
              onSurface: ThemeColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's before start date or more than 3 days after
          if (_endDate != null) {
            final difference = _endDate!.difference(_startDate!).inDays;
            if (difference < 0 || difference >= 3) {
              _endDate = null;
            }
          }
        } else {
          if (_startDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a Start Date first')),
            );
            return;
          }
          final difference = picked.difference(_startDate!).inDays;
          if (difference < 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('End Date cannot be before Start Date')),
            );
          } else if (difference >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum leave allowed is 3 days')),
            );
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Start and End dates')),
      );
      return;
    }

    if (_selectedTemplate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason template')),
      );
      return;
    }

    String finalReason = _selectedTemplate;
    if (_selectedTemplate == 'Other') {
      if (_customReasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write a custom reason')),
        );
        return;
      }
      finalReason = _customReasonController.text.trim();
    }

    setState(() => _isLoading = true);

    try {
      final parentData = ref.read(parentDataProvider).value;
      if (parentData == null) throw Exception("Parent data missing");

      // The kid object contains the classId and id (studentId)
      // Path: schools/{schoolId}/classes/{classId}/students/{studentId}
      final studentRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(parentData.schoolId)
          .collection('classes')
          .doc(widget.kid.classId)
          .collection('students')
          .doc(widget.kid.id);

      final dateFormat = DateFormat('yyyy-MM-dd');
      
      await studentRef.update({
        'activeLeave': {
          'startDate': dateFormat.format(_startDate!),
          'endDate': dateFormat.format(_endDate!),
          'template': finalReason,
          'status': 'pending',
          'appliedAt': FieldValue.serverTimestamp(),
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting leave: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Apply for Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: ThemeColors.primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(widget.kid.imageUrl),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.kid.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Class ${widget.kid.className} | Roll No. ${widget.kid.rollNo}', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Select Dates (Max 3 days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_startDate != null ? dateFormat.format(_startDate!) : 'Select Date', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _startDate != null ? ThemeColors.primaryText : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('End Date', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(_endDate != null ? dateFormat.format(_endDate!) : 'Select Date', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _endDate != null ? ThemeColors.primaryText : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text('Reason for Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _templates.map((template) {
                final isSelected = _selectedTemplate == template;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTemplate = template;
                      if (template != 'Other') {
                        _customReasonController.clear();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? ThemeColors.primaryPurple : Colors.white,
                      border: Border.all(color: isSelected ? ThemeColors.primaryPurple : Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      template,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_selectedTemplate == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your custom reason here...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ThemeColors.primaryPurple, width: 2),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLeave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }
}
