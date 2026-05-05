part of 'auth_bloc.dart';

sealed class AuthStates {}

final class AuthInitial extends AuthStates {}

final class AuthLoading extends AuthStates {}

final class AuthAuthenticated extends AuthStates {
  final String username;

  AuthAuthenticated(this.username);
}

final class AuthUnauthenticated extends AuthStates {}

final class AuthFailure extends AuthStates {
  final String message;

  AuthFailure(this.message);
}
