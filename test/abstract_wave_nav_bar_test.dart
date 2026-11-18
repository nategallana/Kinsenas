import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinsenas/widgets/abstract_wave_nav_bar.dart';

void main() {
  testWidgets('AbstractWaveNavBar renders all 5 tabs and switches selection on tap',
      (WidgetTester tester) async {
    int selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: AbstractWaveNavBar(
                selectedIndex: selected,
                onItemSelected: (idx) => setState(() => selected = idx),
              ),
            );
          },
        ),
      ),
    );

    expect(find.byTooltip('Home'), findsOneWidget);
    expect(find.byTooltip('Sahod'), findsOneWidget);
    expect(find.byTooltip('Ipon'), findsOneWidget);
    expect(find.byTooltip('Utang'), findsOneWidget);
    expect(find.byTooltip('Mga Bayarin'), findsOneWidget);

    // Tap Ipon (center tab)
    await tester.tap(find.byTooltip('Ipon'));
    await tester.pumpAndSettle();
    expect(selected, 2);

    // Tap Mga Bayarin (last tab)
    await tester.tap(find.byTooltip('Mga Bayarin'));
    await tester.pumpAndSettle();
    expect(selected, 4);

    // Tap Home (first tab)
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(selected, 0);
  });

  testWidgets('AbstractWaveNavBar renders cleanly on narrow and wide widths',
      (WidgetTester tester) async {
    for (final width in [320.0, 390.0, 800.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: AbstractWaveNavBar(
                  selectedIndex: 2,
                  onItemSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
