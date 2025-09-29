// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyge/main.dart'; // pastikan name: moneyge di pubspec.yaml

void main() {
  testWidgets('Moneyge app renders home and FAB', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const MoneygeApp());

    // Cek AppBar/title muncul
    expect(find.text('Moneyge'), findsOneWidget);

    // Cek ada tombol tambah (FAB) dengan ikon +
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
