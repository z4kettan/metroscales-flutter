import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metroscales/core/theme/app_theme.dart';
import 'package:metroscales/features/auth/login_screen.dart';

void main() {
  testWidgets('login screen asks for username and password and validates them', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Enter the username your dealer gave you'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });
}
