import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/todo_model.dart';
import '../bloc/todo/todo_bloc.dart';

class TodoTile extends StatelessWidget {
  final TodoModel todo;

  const TodoTile({super.key, required this.todo});

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(todo.key),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
              Text('Delete', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        confirmDismiss: (_) async {
          return await _confirmDelete(context);
        },
        onDismissed: (_) {
          context.read<TodoBloc>().add(DeleteTodo(todo));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${todo.title}" deleted'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(label: 'UNDO', onPressed: () {}),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              leading: Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: todo.completed,
                  activeColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                  onChanged: (_) {
                    context.read<TodoBloc>().add(ToggleTodo(todo));
                  },
                ),
              ),
              title: Text(
                todo.title,
                style: TextStyle(
                  decoration: todo.completed ? TextDecoration.lineThrough : null,
                  color: todo.completed ? Colors.grey.shade400 : Colors.black87,
                  fontSize: 16,
                  fontWeight: todo.completed ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Created: ${_formatDate(todo.createdAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (todo.completed) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.green.shade300),
                          const SizedBox(width: 4),
                          Text(
                            'Completed: ${_formatDate(todo.updatedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSyncStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus() {
    if (todo.isSynced) {
      return todo.completed
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.done_all_rounded, color: Colors.green.shade400, size: 16),
            )
          : const SizedBox(width: 24);
    }

    return Tooltip(
      message: _pendingLabel(),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _pendingIcon(),
          color: Colors.orange.shade600,
          size: 14,
        ),
      ),
    );
  }

  String _pendingLabel() {
    switch (todo.pendingAction) {
      case 'create':
        return 'Pending upload';
      case 'update':
        return 'Pending sync';
      case 'delete':
        return 'Pending delete';
      default:
        return 'Unsynced';
    }
  }

  IconData _pendingIcon() {
    switch (todo.pendingAction) {
      case 'delete':
        return Icons.delete_outline_rounded;
      default:
        return Icons.cloud_upload_outlined;
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Task'),
          ],
        ),
        content: Text('Are you sure you want to delete "${todo.title}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
