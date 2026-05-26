import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:todo_app/presentation/bloc/auth/auth_bloc.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc();
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthStates>(
      'emits [AuthLoading, AuthAuthenticated] when LoginRequested is successful',
      build: () => authBloc,
      act: (bloc) => bloc.add(LoginRequested(username: 'admin', password: 'password123')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.username, 'username', 'admin'),
      ],
    );

    blocTest<AuthBloc, AuthStates>(
      'emits [AuthLoading, AuthFailure] when LoginRequested fails due to wrong username',
      build: () => authBloc,
      act: (bloc) => bloc.add(LoginRequested(username: 'wrong', password: 'password123')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Invalid username or password.'),
      ],
    );

    blocTest<AuthBloc, AuthStates>(
      'emits [AuthLoading, AuthFailure] when LoginRequested fails due to wrong password',
      build: () => authBloc,
      act: (bloc) => bloc.add(LoginRequested(username: 'admin', password: 'wrong')),
      wait: const Duration(milliseconds: 600),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Invalid username or password.'),
      ],
    );

    blocTest<AuthBloc, AuthStates>(
      'emits [AuthUnauthenticated] when LogoutRequested is added',
      build: () => authBloc,
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}
