import 'package:flutter_test/flutter_test.dart';
import 'package:frappe_flutter_app/core/barrel_file.dart';
import 'package:frappe_flutter_app/providers/auth_provider.dart';
import 'package:frappe_flutter_app/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createTestWidget(Widget child) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: MaterialApp(
        scaffoldMessengerKey: SnackbarGlobal.key,
        home: Builder(
          builder: (context) {
            ScreenUtil.init(
              context,
              designSize: const Size(375, 812),
            );
            return Scaffold(
              body: MediaQuery(
                data: MediaQuery.of(context).copyWith(),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }

  group('LoginScreen Tests', () {
    testWidgets('renders login form correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      expect(
          find.byType(CustomTextField), findsNWidgets(2)); // Email & Password
      expect(find.byType(CustomElevatedButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('displays error when email is empty', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      await tester.tap(find.byType(CustomElevatedButton));
      await tester.pump();

      expect(find.text('Please enter Email'), findsOneWidget);
    });

    testWidgets('displays error when password is empty', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      await tester.enterText(
          find.byType(CustomTextField).first, 'test@example.com');
      await tester.tap(find.byType(CustomElevatedButton));
      await tester.pump();

      expect(find.text('Please enter Password'), findsOneWidget);
    });

    testWidgets('calls login API on valid input', (tester) async {
      const email = 'test@example.com';
      const password = 'password123';

      // when(() => mockAuthProvider.login(email, password))
      //     .thenAnswer((_) async => true);
      when(() => mockAuthProvider.login(any(), any()))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Input valid email and password
      final emailField = find.byType(CustomTextField).first;
      final passwordField = find.byType(CustomTextField).at(1);
      final loginButton = find.byType(CustomElevatedButton);

      // Enter values into the email and password fields
      await tester.enterText(emailField, email);
      await tester.enterText(passwordField, password);

      // Tap the login button
      await tester.tap(loginButton);
      await tester.pump();

      // Verify that the login method was called with the correct arguments
      verify(() => mockAuthProvider.login(email, password)).called(1);
    });

    testWidgets('displays Snackbar on login failure', (tester) async {
      const email = 'test@example.com';
      const password = 'wrongpassword';

      when(() => mockAuthProvider.login(email, password))
          .thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      await tester.enterText(find.byType(CustomTextField).first, email);
      await tester.enterText(find.byType(CustomTextField).last, password);
      await tester.tap(find.byType(CustomElevatedButton));
      await tester.pump();

      expect(find.textContaining('Login Failed with error'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      final iconButton = find.byIcon(Icons.visibility_off);
      expect(iconButton, findsOneWidget);

      await tester.tap(iconButton);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
    testWidgets('displays app version on success', (tester) async {
      const mockVersion = '1.0.0';
      PackageInfo.setMockInitialValues(
        appName: 'appName',
        packageName: 'packageName',
        version: mockVersion,
        buildNumber: mockVersion,
        buildSignature: mockVersion,
      );
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Wait for async operations to complete
      await tester.pump();

      // Verify that the app version text is displayed
      expect(find.textContaining('App Version'), findsOneWidget);
    });
  });
}
