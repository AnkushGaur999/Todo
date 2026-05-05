import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_events.dart';

part 'auth_states.dart';

const _validUsername = 'admin';
const _validPassword = 'password123';

class AuthBloc extends Bloc<AuthEvents, AuthStates> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthStates> emit) async {
    emit(AuthLoading());

    await Future.delayed(const Duration(milliseconds: 600));

    if (event.username.trim() == _validUsername &&
        event.password == _validPassword) {
      emit(AuthAuthenticated(event.username.trim()));
    } else {
      emit(AuthFailure('Invalid username or password.'));
    }
  }

  void _onLogout(LogoutRequested event, Emitter<AuthStates> emit) {
    emit(AuthUnauthenticated());
  }
}
