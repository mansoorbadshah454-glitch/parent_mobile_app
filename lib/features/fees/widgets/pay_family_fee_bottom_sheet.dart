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

  const PayFamilyFeeBottomSheet({
    super.key,
    required this.allKids,
  });

  static Future<void> show(BuildContext context, List<KidData> allKids) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayFamilyFeeBottomSheet(allKids: allKids),
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
    // Pre-select all unpaid kids who do not already have a pending verification
    _selectedKidIds = widget.allKids
        .where((k) =>
            (k.monthlyFeeStatus.isNotEmpty ? k.monthlyFeeStatus.toLowerCase() : '') != 'paid' &&
            !(k.pendingPaymentSubmission != null && (k.pendingPaymentSubmission!['status'] ?? '').toString() == 'pending'))
        .map((k) => k.id)
        .toSet();

    // If none matched, select all unpaid
    if (_selectedKidIds.isEmpty) {
      _selectedKidIds = widget.allKids
          .where((k) => (k.monthlyFeeStatus.isNotEmpty ? k.monthlyFeeStatus.toLowerCase() : '') != 'paid')
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
    final isPaid = (kid.monthlyFeeStatus.isNotEmpty ? kid.monthlyFeeStatus.toLowerCase() : '') == 'paid';
    double totalRecurring = 0.0;
    for (var fee in kid.feeStructure) {
      totalRecurring += FeeCalculatorService.parseDouble(fee['amount']);
    }
    double totalActions = 0.0;
    double paidActions = 0.0;
    for (var action in kid.individualActions) {
      final actAmount = FeeCalculatorService.parseDouble(action['amount']);
      totalActions += actAmount;
      if ((action['status'] ?? '').toString().toLowerCase() == 'paid') {
        paidActions += actAmount;
      }
    }
    double calculatedDue = (totalRecurring + totalActions) - ((isPaid ? totalRecurring : 0) + paidActions);
    if (calculatedDue <= 0 && !isPaid) {
      calculatedDue = totalRecurring > 0 ? totalRecurring : 1000.0;
    }
    return calculatedDue;
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

      final currentMonthStr = DateFormat('MMMM yyyy').format(DateTime.now());
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
                        'Pay Family Fee (All Dues)',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        'Select children & submit 1 payment proof',
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
              final isPaid = (kid.monthlyFeeStatus.isNotEmpty ? kid.monthlyFeeStatus.toLowerCase() : '') == 'paid';
              final isPending = kid.pendingPaymentSubmission != null &&
                  (kid.pendingPaymentSubmission!['status'] ?? '').toString() == 'pending';
              final isRejected = kid.pendingPaymentSubmission != null &&
                  (kid.pendingPaymentSubmission!['status'] ?? '').toString().trim().toLowerCase() == 'rejected';
              final double due = _calculateKidDue(kid);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.shade50
                      : isPending
                          ? Colors.amber.shade50
                          : (isSelected ? ThemeColors.primaryPurple.withOpacity(0.05) : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isPaid
                        ? Colors.green.shade200
                        : isPending
                            ? Colors.amber.shade300
                            : (isSelected ? ThemeColors.primaryPurple : Colors.grey.shade200),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  activeColor: ThemeColors.primaryPurple,
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kid.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                            Text(
                              'Class: ${kid.className} • Roll: ${kid.rollNo}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isPaid
                                ? 'Paid ✓'
                                : isPending
                                    ? 'Under Review'
                                    : 'Rs. ${due.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPaid
                                  ? Colors.green.shade800
                                  : isPending
                                      ? Colors.amber.shade900
                                      : ThemeColors.primaryPurple,
                            ),
                          ),
                          if (!isPaid && !isPending && isRejected)
                            Text(
                              'Rejected • Resubmit',
                              style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                            )
                          else if (!isPaid && !isPending && kid.individualActions.isNotEmpty)
                            Text(
                              '+ ${kid.individualActions.length} add-ons',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                        ],
                      ),
                    ],
                  ),
                  value: isSelected,
                  enabled: !isPaid && !isPending,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        _selectedKidIds.add(kid.id);
                      } else {
                        _selectedKidIds.remove(kid.id);
                      }
                    });
                  },
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
