import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:todo_app/presentation/screens/login_screen.dart';

class MockAuthBloc extends MockBloc<AuthEvents, AuthStates> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(LogoutRequested());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all initial UI elements', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Task Manager'), findsOneWidget);
      expect(find.text('Sign in to manage your tasks'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Demo credentials: admin / password123'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty and Sign In is pressed', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('adds LoginRequested event when valid credentials are submitted', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField).at(0), 'admin');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(() => mockAuthBloc.add(any(that: isA<LoginRequested>()
          .having((e) => e.username, 'username', 'admin')
          .having((e) => e.password, 'password', 'password123')))).called(1);
    });

    testWidgets('shows loading indicator when state is AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows snackbar when state is AuthFailure', (tester) async {
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([AuthFailure('Invalid credentials')]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      Finder findPasswordField() => find.descendant(
            of: find.ancestor(
              of: find.text('Password'),
              matching: find.byType(TextFormField),
            ),
            matching: find.byType(TextField),
          );

      expect(tester.widget<TextField>(findPasswordField()).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(tester.widget<TextField>(findPasswordField()).obscureText, isFalse);
    });
  });
}
