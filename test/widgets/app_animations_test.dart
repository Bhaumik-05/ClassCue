import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/widgets/app_animations.dart';

void main() {
  testWidgets('FadeSlideIn ends fully visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideIn(index: 2, child: Text('Hello')),
        ),
      ),
    );

    // Starts faded out.
    final start = tester.widget<Opacity>(find.byType(Opacity));
    expect(start.opacity, lessThan(1.0));

    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    final end = tester.widget<Opacity>(find.byType(Opacity));
    expect(end.opacity, 1.0);
  });

  testWidgets('AppRoute.push opens and pops a page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                AppRoute.push(const Scaffold(body: Text('Second page'))),
              ),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Second page'), findsNothing);

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsNothing);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('AnimatedSwitcher with AppAnim swaps content', (tester) async {
    Widget app(String key) => MaterialApp(
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: AppAnim.short,
          transitionBuilder: AppAnim.fadeSlide,
          layoutBuilder: AppAnim.topLayout,
          child: Text(key, key: ValueKey(key)),
        ),
      ),
    );

    await tester.pumpWidget(app('Monday'));
    expect(find.text('Monday'), findsOneWidget);

    await tester.pumpWidget(app('Tuesday'));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('Monday'), findsNothing);
  });
}