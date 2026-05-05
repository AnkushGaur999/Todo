import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/todo/todo_bloc.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/todo_list_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<TodoBloc>(
          create: (_) => sl<TodoBloc>()..add(LoadTodos()),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0),
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthStates>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              return const TodoListScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
