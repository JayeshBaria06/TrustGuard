import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/features/members/presentation/avatar_picker.dart';
import 'package:trustguard/src/features/members/services/avatar_service.dart';

class MockAvatarService extends Mock implements AvatarService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAvatarService mockAvatarService;

  setUpAll(() {
    registerFallbackValue(File(''));
  });

  setUp(() {
    mockAvatarService = MockAvatarService();

    // Mock image_picker MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/image_picker'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'pickImage') {
              return 'mock/path/picked.jpg';
            }
            return null;
          },
        );
  });

  Widget createPicker({
    String? memberId = 'm1',
    String? initialPath,
    int? initialColor,
    required void Function(String?, int?) onSelectionChanged,
  }) {
    return ProviderScope(
      overrides: [avatarServiceProvider.overrideWithValue(mockAvatarService)],
      child: MaterialApp(
        home: Scaffold(
          body: AvatarPicker(
            memberId: memberId,
            initialAvatarPath: initialPath,
            initialAvatarColor: initialColor,
            onSelectionChanged: onSelectionChanged,
          ),
        ),
      ),
    );
  }

  group('AvatarPicker', () {
    testWidgets('renders initial state with initials/icon if no avatar', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPicker(onSelectionChanged: (path, color) {}),
      );

      expect(find.text('Choose Avatar'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders with initial color', (tester) async {
      final color = Member.presetColors.first;
      await tester.pumpWidget(
        createPicker(initialColor: color, onSelectionChanged: (path, color) {}),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, equals(Color(color)));
    });

    testWidgets('selecting a color triggers callback', (tester) async {
      String? resultPath;
      int? resultColor;

      await tester.pumpWidget(
        createPicker(
          onSelectionChanged: (path, color) {
            resultPath = path;
            resultColor = color;
          },
        ),
      );

      final firstColor = Member.presetColors.first;
      await tester.tap(find.bySemanticsLabel('Preset color 1'));
      await tester.pump();

      expect(resultPath, isNull);
      expect(resultColor, equals(firstColor));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('picking an image triggers AvatarService and callback', (
      tester,
    ) async {
      String? resultPath;
      int? resultColor;
      const memberId = 'm1';
      const savedPath = 'app/docs/avatars/m1.jpg';

      when(
        () => mockAvatarService.saveAvatar(any(), any()),
      ).thenAnswer((_) async => savedPath);

      await tester.pumpWidget(
        createPicker(
          memberId: memberId,
          onSelectionChanged: (path, color) {
            resultPath = path;
            resultColor = color;
          },
        ),
      );

      await tester.tap(find.bySemanticsLabel('Gallery'));
      await tester.pump();
      await tester.pump();

      verify(() => mockAvatarService.saveAvatar(memberId, any())).called(1);
      expect(resultPath, equals(savedPath));
      expect(resultColor, isNull);
    });

    testWidgets('Clear Avatar button works', (tester) async {
      String? resultPath = 'existing';
      int? resultColor = 123;

      await tester.pumpWidget(
        createPicker(
          initialPath: 'path',
          initialColor: null,
          onSelectionChanged: (path, color) {
            resultPath = path;
            resultColor = color;
          },
        ),
      );

      final clearButton = find.text('Clear Avatar');
      await tester.ensureVisible(clearButton);
      await tester.tap(clearButton);
      await tester.pump();

      expect(resultPath, isNull);
      expect(resultColor, isNull);
    });
  });
}
