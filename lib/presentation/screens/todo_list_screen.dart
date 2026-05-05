import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/todo_model.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/todo/todo_bloc.dart';
import '../widgets/add_todo_dialog.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/todo_tile.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _syncMsgTimer;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _syncMsgTimer?.cancel();
    super.dispose();
  }

  void _scheduleSyncMsgDismiss() {
    _syncMsgTimer?.cancel();
    _syncMsgTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        final state = context.read<TodoBloc>().state;
        if (state is TodoLoaded && state.syncMessage != null) {
          context.read<TodoBloc>().emit(
                state.copyWith(clearSyncMessage: true),
              );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTodoDialog.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: BlocConsumer<TodoBloc, TodoStates>(
        listener: (context, state) {
          if (state is TodoLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red.shade700,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => context.read<TodoBloc>().add(SyncTodos()),
                ),
              ),
            );
          }
          if (state is TodoLoaded && state.syncMessage != null) {
            _scheduleSyncMsgDismiss();
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<TodoBloc>().add(SyncTodos());
            },
            displacement: 100,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                _ConnectivityBannerSliver(),
                if (state is TodoLoading)
                  const SliverFillRemaining(
                    child: Center(
                        child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator.adaptive())),
                  )
                else if (state is TodoError)
                  SliverFillRemaining(
                    child: _buildErrorView(context, state.message),
                  )
                else if (state is TodoLoaded) ...[
                  _TodoHeaderSliver(searchCtrl: _searchCtrl),
                  _TodoListSliver(),
                ] else
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.grey.shade50,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsetsDirectional.only(start: 16, bottom: 16),
        title: Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      actions: const [
        _PendingCountBadge(),
        SizedBox(width: 8),
        _AuthAction(),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 80, color: Colors.red.shade200),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<TodoBloc>().add(LoadTodos()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectivityBannerSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoStates, (bool, bool, String?)>(
      selector: (state) {
        if (state is TodoLoaded) {
          return (state.isOnline, state.isSyncing, state.syncMessage);
        }
        return (true, false, null);
      },
      builder: (context, data) {
        return SliverToBoxAdapter(
          child: ConnectivityBanner(
            isOnline: data.$1,
            isSyncing: data.$2,
            syncMessage: data.$3,
          ),
        );
      },
    );
  }
}

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoStates, int>(
      selector: (state) => state is TodoLoaded ? state.pendingCount : 0,
      builder: (context, pendingCount) {
        if (pendingCount == 0) return const SizedBox.shrink();
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              '$pendingCount pending',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _AuthAction extends StatelessWidget {
  const _AuthAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthStates>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: CircleAvatar(
              radius: 18,
              backgroundColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(
                authState.username[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Signed in as',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(authState.username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'logout') {
                context.read<AuthBloc>().add(LogoutRequested());
              }
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _TodoHeaderSliver extends StatelessWidget {
  final TextEditingController searchCtrl;

  const _TodoHeaderSliver({required this.searchCtrl});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              onChanged: (q) => context.read<TodoBloc>().add(SearchTodos(q)),
              decoration: InputDecoration(
                hintText: 'Search your tasks...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: ListenableBuilder(
                  listenable: searchCtrl,
                  builder: (context, _) {
                    return searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              searchCtrl.clear();
                              context.read<TodoBloc>().add(SearchTodos(''));
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.5)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            const _DailyProgressCard(),
            const SizedBox(height: 8),
            const _SearchCountLabel(),
          ],
        ),
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoStates, List<TodoModel>>(
      selector: (state) => state is TodoLoaded ? state.todos : [],
      builder: (context, todos) {
        if (todos.isEmpty) return const SizedBox.shrink();

        final completedCount = todos.where((t) => t.completed).length;
        final totalCount = todos.length;
        final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$completedCount of $totalCount tasks completed',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchCountLabel extends StatelessWidget {
  const _SearchCountLabel();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoStates, (int, int)>(
      selector: (state) {
        if (state is TodoLoaded) {
          return (state.filtered.length, state.todos.length);
        }
        return (0, 0);
      },
      builder: (context, counts) {
        final filteredCount = counts.$1;
        final totalCount = counts.$2;

        if (filteredCount == totalCount) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Found $filteredCount tasks',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
    );
  }
}

class _TodoListSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<TodoBloc, TodoStates, (List<TodoModel>, String)>(
      selector: (state) {
        if (state is TodoLoaded) {
          return (state.filtered, state.searchQuery);
        }
        return ([], '');
      },
      builder: (context, data) {
        final filtered = data.$1;
        final searchQuery = data.$2;

        if (filtered.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(query: searchQuery),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TodoTile(todo: filtered[index]),
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String query;

  const _EmptyView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                query.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.task_alt_rounded,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              query.isNotEmpty ? 'No results found' : 'No tasks yet',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              query.isNotEmpty
                  ? 'We couldn\'t find any tasks matching "$query"'
                  : 'Start your day by adding a new task!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
