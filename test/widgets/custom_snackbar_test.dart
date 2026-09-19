import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/widgets/custom_snackbar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      scaffoldMessengerKey: CustomSnackbar.messengerKey,
      home: const Scaffold(body: SizedBox()),
    ),
  );

  testWidgets('shows a success message', (tester) async {
    await pumpApp(tester);

    CustomSnackbar.success(title: 'Saved', message: 'All good');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('All good'), findsOneWidget);
  });

  testWidgets('shows an error message', (tester) async {
    await pumpApp(tester);

    CustomSnackbar.error(title: 'Oops', message: 'Something failed');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Oops'), findsOneWidget);
    expect(find.text('Something failed'), findsOneWidget);
  });

  test('does nothing (no crash) before the app is built', () {
    expect(
          () => CustomSnackbar.warning(title: 'x', message: 'y'),
      returnsNormally,
    );
  });
}