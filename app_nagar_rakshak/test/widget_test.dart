import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Make sure this matches the name in your pubspec.yaml
import 'package:app_nagar_rakshak/main.dart'; 

void main() {
  testWidgets('App loads and shows Open Camera button', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const NagarRakshakApp());

    // 2. Verify that the "Nagar Rakshak" title is on screen.
    expect(find.text('Nagar Rakshak'), findsOneWidget);

    // 3. Verify that the "Open Camera" button is present.
    expect(find.text('Open Camera'), findsOneWidget);
    

    expect(find.text('Ready to Scan'), findsOneWidget);
  });
}