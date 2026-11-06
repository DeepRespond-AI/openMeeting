import 'dart:ui' show Tristate;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/widgets/app_switch_list_tile.dart';

void main() {
  testWidgets('row, thumb and drag update the setting once per gesture', (tester) async {
    var value = false;
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSwitchListTile(
              title: const Text('Reminder'),
              value: value,
              onChanged: (next) => setState(() {
                value = next;
                changes++;
              }),
            ),
          ),
        ),
      ),
    );
    final control = find.byType(CupertinoSwitch);
    expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
    await tester.tap(find.text('Reminder'));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(changes, 1);
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(changes, 2);
    await tester.dragFrom(tester.getTopLeft(control) + const Offset(12, 22), const Offset(56, 0));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(changes, 3);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      final node = tester.getSemantics(control).getSemanticsData();
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
      expect(tester.getSemantics(find.byType(AppSwitchListTile)).label, 'Reminder');
    } finally {
      semantics.dispose();
    }
  });

  for (final value in [false, true]) {
    testWidgets('disabled $value keeps its value after row and thumb gestures', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AppSwitchListTile(
              title: const Text('Host only'),
              subtitle: const Text('Only the host can change this setting'),
              secondary: const Icon(Icons.lock_outline),
              value: value,
              onChanged: null,
            ),
          ),
        ),
      );
      final control = find.byType(CupertinoSwitch);
      await tester.tapAt(tester.getCenter(find.text('Host only')));
      await tester.tapAt(tester.getCenter(control));
      await tester.drag(control, const Offset(-50, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<CupertinoSwitch>(control).value, value);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        final node = tester.getSemantics(control).getSemanticsData();
        expect(node.flagsCollection.isToggled, value ? Tristate.isTrue : Tristate.isFalse);
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      } finally {
        semantics.dispose();
      }
    });
  }
}
