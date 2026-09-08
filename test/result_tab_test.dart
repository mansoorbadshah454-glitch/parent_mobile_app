import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parent_mobile_app/features/kids/widgets/result_tab_content.dart';
import 'package:parent_mobile_app/features/kids/providers/kids_provider.dart';

void main() {
  testWidgets('ResultTabContent renders and demo button activates scorecard', (WidgetTester tester) async {
    final dummyKid = KidData(
      id: 'student_123',
      name: 'Zayan Ghani',
      imageUrl: '',
      className: 'Prep',
      classId: 'class_prep_id',
      rollNo: '1211',
      wellness: {},
      attendanceHistory: {},
      monthlyFeeStatus: 'Paid',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ResultTabContent(kid: dummyKid),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Academic Examination Results'), findsOneWidget);
    expect(find.text('✨ Demo Presentation: Active Result Preview'), findsOneWidget);

    // Tap the Demo button
    await tester.tap(find.text('✨ Demo Presentation: Active Result Preview'));
    await tester.pump();

    // Verify Active metrics appear
    expect(find.text('467/500'), findsOneWidget);
    expect(find.text('93.4%'), findsOneWidget);
    expect(find.text('PASSED'), findsOneWidget);
    expect(find.text('View & Download Result Card'), findsOneWidget);
  });
}
