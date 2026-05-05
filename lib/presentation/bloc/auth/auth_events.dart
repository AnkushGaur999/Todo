part of 'auth_bloc.dart';

sealed class AuthEvents {}

final class LoginRequested extends AuthEvents {
  final String username;
  final String password;

  LoginRequested({required this.username, required this.password});
}

final class LogoutRequested extends AuthEvents {}
