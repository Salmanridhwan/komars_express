import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komars_express/features/onboarding/screens/onboarding_screen.dart';
import 'package:komars_express/features/auth/screens/login_screen.dart';
import 'package:komars_express/features/onboarding/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pumps OnboardingScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Pumps LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen(initialApp: 'express')));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Pumps SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
