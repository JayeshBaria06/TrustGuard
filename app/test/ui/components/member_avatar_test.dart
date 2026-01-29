import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/ui/components/member_avatar.dart';

void main() {
  group('MemberAvatar', () {
    testWidgets('displays initials when no image is provided', (tester) async {
      final member = Member(
        id: 'm1',
        groupId: 'g1',
        displayName: 'Alice Smith',
        createdAt: DateTime.now(),
        avatarColor: Colors.blue.toARGB32(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MemberAvatar(member: member)),
        ),
      );

      expect(find.text('AS'), findsOneWidget);
      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(
        circleAvatar.backgroundColor!.toARGB32(),
        equals(Colors.blue.toARGB32()),
      );
    });

    testWidgets('displays icon when no initials can be formed', (tester) async {
      final member = Member(
        id: 'm1',
        groupId: 'g1',
        displayName: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MemberAvatar(member: member)),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    // Note: Testing FileImage with mock files is tricky in widget tests
    // because it actually tries to read from disk.
    // For this test, we verify the widget structure.
    testWidgets('renders CircleAvatar with correct radius', (tester) async {
      final member = Member(
        id: 'm1',
        groupId: 'g1',
        displayName: 'Alice',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MemberAvatar(member: member, radius: 30)),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(circleAvatar.radius, equals(30));
    });
  });
}
