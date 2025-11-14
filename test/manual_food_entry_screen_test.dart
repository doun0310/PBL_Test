import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meal_management_app/screens/manual_food_entry_screen.dart';

void main() {
  group('ManualFoodEntryScreen Tests', () {
    testWidgets('Should display all required input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManualFoodEntryScreen(),
        ),
      );

      // Verify title
      expect(find.text('직접 입력'), findsOneWidget);

      // Verify all input fields exist
      expect(find.text('음식명'), findsOneWidget);
      expect(find.text('식사 시간'), findsOneWidget);
      expect(find.text('칼로리'), findsOneWidget);
      expect(find.text('탄수화물'), findsOneWidget);
      expect(find.text('단백질'), findsOneWidget);
      expect(find.text('지방'), findsOneWidget);

      // Verify save button
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('Should show validation errors when form is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManualFoodEntryScreen(),
        ),
      );

      // Tap save button without filling the form
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      // Verify validation error messages appear
      expect(find.text('음식명을 입력하세요'), findsOneWidget);
      expect(find.text('칼로리를 입력하세요'), findsOneWidget);
    });

    testWidgets('Should accept valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManualFoodEntryScreen(),
        ),
      );

      // Enter food name
      await tester.enterText(
        find.widgetWithText(TextFormField, '음식명').first,
        '삼계탕',
      );

      // Enter calories
      await tester.enterText(
        find.widgetWithText(TextFormField, '칼로리').first,
        '500',
      );

      // Enter carbs
      await tester.enterText(
        find.widgetWithText(TextFormField, '탄수화물').first,
        '50',
      );

      // Enter protein
      await tester.enterText(
        find.widgetWithText(TextFormField, '단백질').first,
        '30',
      );

      // Enter fat
      await tester.enterText(
        find.widgetWithText(TextFormField, '지방').first,
        '15',
      );

      await tester.pumpAndSettle();

      // Verify no validation errors
      expect(find.text('음식명을 입력하세요'), findsNothing);
      expect(find.text('칼로리를 입력하세요'), findsNothing);
    });

    testWidgets('Should only accept numbers in numeric fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManualFoodEntryScreen(),
        ),
      );

      // Try to enter text in calories field
      final caloriesField = find.widgetWithText(TextFormField, '칼로리').first;
      await tester.enterText(caloriesField, 'abc');
      await tester.pumpAndSettle();

      // The field should filter out non-numeric characters
      final caloriesTextField = tester.widget<TextFormField>(caloriesField);
      // Input formatters should prevent non-numeric input
      expect(caloriesTextField.inputFormatters, isNotEmpty);
    });

    testWidgets('Meal type dropdown should have all options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ManualFoodEntryScreen(),
        ),
      );

      // Find and tap the dropdown
      final dropdown = find.byType(DropdownButtonFormField<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify all meal type options
      expect(find.text('아침').hitTestable(), findsWidgets);
      expect(find.text('점심').hitTestable(), findsWidgets);
      expect(find.text('저녁').hitTestable(), findsWidgets);
    });
  });
}
