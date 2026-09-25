import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/parent_data_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../kids/providers/kids_provider.dart';
import '../services/fee_calculator_service.dart';

class PayFamilyFeeBottomSheet extends ConsumerStatefulWidget {
  final List<KidData> allKids;
  final String? feeMonth;
  final int? targetMonthIdx;
  final int? targetYear;

  const PayFamilyFeeBottomSheet({
    super.key,
    required this.allKids,
    this.feeMonth,
    this.targetMonthIdx,
    this.targetYear,
  });

  static Future<void> show(
    BuildContext context,
    List<KidData> allKids, {
    String? feeMonth,
    int? targetMonthIdx,
    int? targetYear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayFamilyFeeBottomSheet(
        allKids: allKids,
        feeMonth: feeMonth,
        targetMonthIdx: targetMonthIdx,
        targetYear: targetYear,
      ),
    );
  }

  @override
  ConsumerState<PayFamilyFeeBottomSheet> createState() => _PayFamilyFeeBottomSheetState();
}

class _PayFamilyFeeBottomSheetState extends ConsumerState<PayFamilyFeeBottomSheet> {
  final TextEditingController _trxController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late Set<String> _selectedKidIds;
  XFile? _selectedImage;
  int _selectedAccountIndex = 0;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final int? mIdx = widget.targetMonthIdx;
    final int? yr = widget.targetYear;
    final String? mKey = widget.feeMonth;

    // Pre-select all unpaid kids for this target month who do not already have a pending verification
    _selectedKidIds = widget.allKids
        .where((k) {
          final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
            k,
            targetMonthIdx: mIdx,
            targetYear: yr,
            targetMonthKey: mKey,
          );
          final bool isPaid = breakdown.isPaid;
          final bool isScholarship = breakdown.isFullScholarship && breakdown.totalPayable <= 0;
          final bool isPending = breakdown.isPending || (k.pendingPaymentSubmission != null &&
              (k.pendingPaymentSubmission!['status'] ?? '').toString() == 'pending' &&
              ((k.pendingPaymentSubmission!['month'] ?? '').toString().toLowerCase().contains(breakdown.targetMonthName.toLowerCase()) ||
                  mIdx == (DateTime.now().month - 1)));
          return !isPaid && !isScholarship && !isPending;
        })
        .map((k) => k.id)
        .toSet();

    // If none matched, select all unpaid for this target month
    if (_selectedKidIds.isEmpty) {
      _selectedKidIds = widget.allKids
          .where((k) {
            final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
              k,
              targetMonthIdx: mIdx,
              targetYear: yr,
              targetMonthKey: mKey,
            );
            return !breakdown.isPaid && !(breakdown.isFullScholarship && breakdown.totalPayable <= 0);
          })
          .map((k) => k.id)
          .toSet();
    }
  }

  @override
  void dispose() {
    _trxController.dispose();
    super.dispose();
  }

  double _calculateKidDue(KidData kid) {
    final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
      kid,
      targetMonthIdx: widget.targetMonthIdx,
      targetYear: widget.targetYear,
      targetMonthKey: widget.feeMonth,
    );
    return breakdown.totalPayable;
  }

  double get _totalCombinedDue {
    double sum = 0.0;
    for (final kid in widget.allKids) {
      if (_selectedKidIds.contains(kid.id)) {
        sum += _calculateKidDue(kid);
      }
    }
    return sum;
  }

  void _showChildBreakdownModal(BuildContext context, KidData kid) {
    final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
      kid,
      targetMonthIdx: widget.targetMonthIdx,
      targetYear: widget.targetYear,
      targetMonthKey: widget.feeMonth,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header with student info
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ThemeColors.primaryPurple.withOpacity(0.12),
                    child: Text(
                      kid.name.isNotEmpty ? kid.name[0].toUpperCase() : 'S',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kid.name,
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          'Class: ${kid.className} • Roll No: ${kid.rollNo}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: breakdown.status == 'paid'
                          ? Colors.green.shade50
                          : (breakdown.isFullScholarship ? const Color(0xFFECFDF5) : Colors.amber.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: breakdown.status == 'paid'
                            ? Colors.green.shade200
                            : (breakdown.isFullScholarship ? const Color(0xFFA7F3D0) : Colors.amber.shade200),
                      ),
                    ),
                    child: Text(
                      breakdown.status == 'paid'
                          ? 'Paid ✓'
                          : (breakdown.isFullScholarship ? 'Scholarship' : 'Due'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: breakdown.status == 'paid'
                            ? Colors.green.shade800
                            : (breakdown.isFullScholarship ? const Color(0xFF059669) : Colors.amber.shade900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Breakdown items
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Recurring Fees
                      Text(
                        'Monthly Dues (${breakdown.monthKey}):',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Base Tuition Fee', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                Text('Rs. ${breakdown.tuitionFee.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              ],
                            ),
                            if (breakdown.discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF059669)),
                                      const SizedBox(width: 4),
                                      Text(
                                        breakdown.concessionName.isNotEmpty
                                            ? breakdown.concessionName
                                            : 'Scholarship / Discount',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Text('- Rs. ${breakdown.discountAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                ],
                              ),
                            ],
                            if (breakdown.transportFee > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Transport / Van Fee', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                  Text('Rs. ${breakdown.transportFee.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                ],
                              ),
                            ],
                            for (final fee in breakdown.otherRecurringFees) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(fee['name']?.toString() ?? 'Fee', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  Text('Rs. ${fee['amount']?.toString() ?? '0'}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Store Items (Uniform, Books, Stationery)
                      if (breakdown.storeItems.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 15, color: Color(0xFF6B21A8)),
                            const SizedBox(width: 6),
                            Text(
                              'Store Purchases (${breakdown.monthKey}):',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Column(
                            children: breakdown.storeItems.map((item) {
                              final name = item['name']?.toString() ?? item['title']?.toString() ?? 'Store Item';
                              final amount = FeeCalculatorService.parseDouble(item['amount']);
                              final qty = item['quantity'] ?? item['qty'] ?? 1;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$name (x$qty)',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF581C87)),
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${amount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Custom / Individual Actions
                      if (breakdown.actions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.assignment_outlined, size: 15, color: Color(0xFF1E40AF)),
                            const SizedBox(width: 6),
                            Text(
                              'Exams & One-Time Charges:',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            children: breakdown.actions.map((act) {
                              final name = act['name']?.toString() ?? act['title']?.toString() ?? 'Charge';
                              final amount = FeeCalculatorService.parseDouble(act['amount']);
                              final actPaid = (act['status'] ?? '').toString().toLowerCase() == 'paid';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$name ${actPaid ? "(Paid ✓)" : ""}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: actPaid ? Colors.green.shade800 : const Color(0xFF1E3A8A),
                                          decoration: actPaid ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: actPaid ? Colors.green.shade800 : const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // Waived Late Fine Note
                      if (breakdown.fineWaived) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.celebration_rounded, color: Color(0xFF059669), size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Late penalty fee waived by school administration.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Grand total summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Net Child Payable:', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text(
                            breakdown.status == 'paid'
                                ? 'Rs. 0 (Cleared)'
                                : 'Rs. ${breakdown.totalPayable.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: breakdown.status == 'paid' ? Colors.green.shade700 : ThemeColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image. Please try again.';
      });
    }
  }

  Future<void> _submitFamilyPaymentProof(
      List<Map<String, dynamic>> accounts, String schoolId, ParentData? parentData) async {
    if (_selectedKidIds.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one student to pay for.';
      });
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please upload a screenshot or photo of your payment slip / receipt.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final selectedAcc = accounts.isNotEmpty && _selectedAccountIndex < accounts.length
          ? accounts[_selectedAccountIndex]
          : <String, dynamic>{};

      final paymentMethod = selectedAcc['bankName']?.toString() ?? selectedAcc['type']?.toString() ?? 'Bank Transfer';
      final accountNo = selectedAcc['accountNumber']?.toString() ?? '';
      final accountTitle = selectedAcc['accountTitle']?.toString() ?? '';

      // 1. Upload proof once to Firebase Storage
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String storagePath = 'schools/$schoolId/paymentProofs/proof_family_${parentData?.uid ?? 'parent'}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        uploadTask = storageRef.putData(bytes, metadata);
      } else {
        uploadTask = storageRef.putFile(File(_selectedImage!.path), metadata);
      }

      final TaskSnapshot snap = await uploadTask;
      final String downloadUrl = await snap.ref.getDownloadURL();

      final currentMonthStr = widget.feeMonth?.isNotEmpty == true
          ? widget.feeMonth!
          : DateFormat('MMMM yyyy').format(DateTime.now());
      final nowIso = DateTime.now().toIso8601String();

      final selectedKidsList = widget.allKids.where((k) => _selectedKidIds.contains(k.id)).toList();
      final double grandTotal = _totalCombinedDue;

      // 2. Prepare itemized breakdown for each student (Ensures 100% Transparency & Auditability)
      final List<Map<String, dynamic>> familyBreakdown = selectedKidsList.map((kid) {
        final double childDue = _calculateKidDue(kid);
        return {
          'studentId': kid.id,
          'studentName': kid.name,
          'classId': kid.classId,
          'className': kid.className,
          'rollNo': kid.rollNo,
          'subtotal': childDue,
          'feeStructure': kid.feeStructure,
          'individualActions': kid.individualActions,
        };
      }).toList();

      // 3. Create single master submission in schools/{schoolId}/paymentSubmissions
      final submissionRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('paymentSubmissions')
          .doc();

      final primaryKid = selectedKidsList.first;

      final submissionData = <String, dynamic>{
        'id': submissionRef.id,
        'schoolId': schoolId,
        'isFamilyCombined': selectedKidsList.length > 1,
        'familyCount': selectedKidsList.length,
        'familyStudents': familyBreakdown,
        'studentId': primaryKid.id,
        'studentName': selectedKidsList.length > 1
            ? 'Family of ${parentData?.name ?? primaryKid.name} (${selectedKidsList.length} Children)'
            : primaryKid.name,
        'classId': primaryKid.classId,
        'className': selectedKidsList.length > 1
            ? '${selectedKidsList.length} Classes'
            : primaryKid.className,
        'rollNo': selectedKidsList.length > 1 ? '-' : primaryKid.rollNo,
        'parentId': parentData?.uid ?? '',
        'parentName': parentData?.name ?? '',
        'parentPhone': parentData?.phone ?? '',
        'amount': grandTotal,
        'paymentMethod': paymentMethod,
        'accountNumberPaidTo': accountNo,
        'accountTitlePaidTo': accountTitle,
        'transactionId': _trxController.text.trim(),
        'proofUrl': downloadUrl,
        'status': 'pending',
        'submittedAt': nowIso,
        'month': currentMonthStr,
      };

      await submissionRef.set(submissionData);

      // 4. Update each selected student's doc with pending state so mobile UI shows 'Under Review' immediately
      for (final kid in selectedKidsList) {
        final double childDue = _calculateKidDue(kid);
        final pendingMap = <String, dynamic>{
          'status': 'pending',
          'isFamilyCombined': selectedKidsList.length > 1,
          'amount': childDue,
          'totalFamilyAmount': grandTotal,
          'familyCount': selectedKidsList.length,
          'paymentMethod': paymentMethod,
          'transactionId': _trxController.text.trim(),
          'proofUrl': downloadUrl,
          'submittedAt': nowIso,
          'submissionId': submissionRef.id,
          'month': currentMonthStr,
        };

        if (kid.classId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .collection('classes')
                .doc(kid.classId)
                .collection('students')
                .doc(kid.id)
                .set({'pendingPaymentSubmission': pendingMap}, SetOptions(merge: true));
          } catch (_) {}
        }

        try {
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(schoolId)
              .collection('students')
              .doc(kid.id)
              .set({'pendingPaymentSubmission': pendingMap}, SetOptions(merge: true));
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Family payment proof of Rs. ${grandTotal.toStringAsFixed(0)} for ${selectedKidsList.length} child(ren) submitted successfully! The school admin will verify shortly.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Error submitting payment: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentDataAsync = ref.watch(parentDataProvider);
    final parentData = parentDataAsync.value;
    final schoolId = parentData?.schoolId ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.diversity_3_rounded, color: ThemeColors.primaryPurple, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feeMonth?.isNotEmpty == true
                            ? 'Pay Family Fee (${widget.feeMonth})'
                            : 'Pay Family Fee (All Dues)',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Select children & submit combined proof for ${widget.feeMonth ?? "all dues"}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryPurple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rs. ${_totalCombinedDue.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 1: Select Children Checklist
            Text(
              '1. Select Children to Include:',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            ...widget.allKids.map((kid) {
              final isSelected = _selectedKidIds.contains(kid.id);
              final breakdown = FeeCalculatorService.calculateItemizedFeeBreakdown(
                kid,
                targetMonthIdx: widget.targetMonthIdx,
                targetYear: widget.targetYear,
                targetMonthKey: widget.feeMonth,
              );
              final isPaid = breakdown.isPaid;
              final isPending = breakdown.isPending || (kid.pendingPaymentSubmission != null &&
                  (kid.pendingPaymentSubmission!['status'] ?? '').toString() == 'pending' &&
                  ((kid.pendingPaymentSubmission!['month'] ?? '').toString().toLowerCase().contains(breakdown.targetMonthName.toLowerCase()) ||
                      widget.targetMonthIdx == (DateTime.now().month - 1)));
              final isRejected = kid.pendingPaymentSubmission != null &&
                  (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'rejected' &&
                  widget.targetMonthIdx == (DateTime.now().month - 1);
              final double due = breakdown.totalPayable;
              final bool isScholarship = breakdown.isFullScholarship && breakdown.totalPayable <= 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.shade50
                      : isPending
                          ? Colors.amber.shade50
                          : (isSelected ? ThemeColors.primaryPurple.withOpacity(0.05) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPaid
                        ? Colors.green.shade200
                        : isPending
                            ? Colors.amber.shade300
                            : (isSelected ? ThemeColors.primaryPurple : Colors.grey.shade200),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // 1. Checkbox for selection
                    Checkbox(
                      value: isSelected,
                      activeColor: ThemeColors.primaryPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (!isPaid && !isPending && !isScholarship)
                          ? (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedKidIds.add(kid.id);
                                } else {
                                  _selectedKidIds.remove(kid.id);
                                }
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 4),

                    // 2. Student Information (Name, Class, Roll)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  kid.name,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isScholarship) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Scholarship',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Class: ${kid.className} • Roll: ${kid.rollNo}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    // 3. Amount & Distinct Detail Breakdown Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaid
                              ? 'Paid ✓'
                              : isPending
                                  ? 'Under Review'
                                  : isScholarship
                                      ? 'Rs. 0 (Free)'
                                      : 'Rs. ${due.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green.shade800
                                : isPending
                                    ? Colors.amber.shade900
                                    : (isScholarship ? const Color(0xFF059669) : ThemeColors.primaryPurple),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showChildBreakdownModal(context, kid),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ThemeColors.primaryPurple.withOpacity(0.4), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long_rounded, size: 12, color: ThemeColors.primaryPurple),
                                const SizedBox(width: 4),
                                Text(
                                  'Breakdown',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ThemeColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isPaid && !isPending && isRejected) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Rejected • Resubmit',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Step 2: Select School Bank Account
            Text(
              '2. Transfer Total Fee (Rs. ${_totalCombinedDue.toStringAsFixed(0)}) To School Account:',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            if (schoolId.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('School information not found.', style: TextStyle(color: Colors.red)),
              )
            else
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .collection('settings')
                    .doc('banking')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final rawAccounts = data['accounts'] as List<dynamic>? ?? [];
                  final accounts = rawAccounts
                      .map((a) => a is Map ? Map<String, dynamic>.from(a) : <String, dynamic>{})
                      .toList();

                  if (accounts.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'No official bank accounts configured yet by school administration.',
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...accounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final acc = entry.value;
                        final isSelected = _selectedAccountIndex == index;
                        final method = acc['bankName']?.toString() ?? acc['type']?.toString() ?? 'Bank Account';
                        final title = acc['accountTitle']?.toString() ?? 'Official Account';
                        final number = acc['accountNumber']?.toString() ?? '';
                        final iban = acc['iban']?.toString() ?? '';

                        final isEasyPaisa = method.toLowerCase().contains('easypaisa');
                        final isJazzCash = method.toLowerCase().contains('jazzcash');

                        Color cardColor = isEasyPaisa
                            ? const Color(0xFF00A859)
                            : isJazzCash
                                ? const Color(0xFFD61F26)
                                : ThemeColors.primaryPurple;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedAccountIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? cardColor.withOpacity(0.06) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? cardColor : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _selectedAccountIndex,
                                  activeColor: cardColor,
                                  onChanged: (val) => setState(() => _selectedAccountIndex = val ?? 0),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: cardColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              method.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: cardColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: GoogleFonts.inter(
                                                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            'A/C: ',
                                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                                          ),
                                          SelectableText(
                                            number,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (iban.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'IBAN: $iban',
                                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                                  tooltip: 'Copy Account Number',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: number));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$method number copied: $number'),
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Step 3: Transaction ID
                      Text(
                        '3. Transaction / Reference ID (Optional):',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _trxController,
                        decoration: InputDecoration(
                          hintText: 'e.g. TRX12345678 / TID',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: ThemeColors.primaryPurple, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step 4: Upload Slip
                      Text(
                        '4. Upload Single Payment Slip / Screenshot:',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      if (_selectedImage == null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded, size: 20, color: ThemeColors.primaryPurple),
                                label: Text(
                                  'Choose from Gallery',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, fontWeight: FontWeight.w600, color: ThemeColors.primaryPurple),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: ThemeColors.primaryPurple.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt_rounded, color: ThemeColors.primaryPurple),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(14),
                                backgroundColor: ThemeColors.primaryPurple.withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? const Icon(Icons.image, size: 44, color: Colors.green)
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receipt Selected ✓',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13),
                                    ),
                                    Text(
                                      _selectedImage!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _selectedImage = null),
                                child: const Text('Change', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Submit Family Payment Button
                      ElevatedButton(
                        onPressed: _isUploading
                            ? null
                            : () => _submitFamilyPaymentProof(accounts, schoolId, parentData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isUploading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Uploading Proof for Verification...',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Submit Family Payment (Rs. ${_totalCombinedDue.toStringAsFixed(0)})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
