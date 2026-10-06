import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metroscales/core/theme/app_theme.dart';
import 'package:metroscales/features/auth/login_screen.dart';

void main() {
  testWidgets('login screen asks for email and PIN and validates them', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('PIN'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter the email your dealer set up'), findsOneWidget);
    expect(find.text('PIN is 4 to 8 digits'), findsOneWidget);
  });
}
