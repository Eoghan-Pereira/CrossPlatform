import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<ParseObject> tasks = [];
  bool _isLoading = true;
  bool _isAdding = false;
  TabController? _tabController; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);  
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController?.dispose();  
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      
      if (currentUser == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final QueryBuilder<ParseObject> query =
          QueryBuilder<ParseObject>(ParseObject('Task'))
            ..whereEqualTo('user', ParseObject('_User')..objectId = currentUser.objectId)
            ..orderByDescending('createdAt');

      final response = await query.query();

      if (response.success && response.results != null) {
        if (!mounted) return;
        setState(() {
          tasks = response.results as List<ParseObject>;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error?.message ?? 'Failed to load tasks')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool dateSelected = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                'Due Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                      dateSelected = true;
                    });
                  }
                },
                child: const Text('Select Due Date'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _isAdding
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a task title')),
                        );
                        return;
                      }

                      setState(() => _isAdding = true);
                      try {
                        final currentUser = await ParseUser.currentUser() as ParseUser?;
                        
                        if (currentUser == null) {
                          throw Exception('User not logged in');
                        }
                        final userPointer = ParseObject('_User')..objectId = currentUser.objectId;

                        final task = ParseObject('Task')
                          ..set('title', titleController.text.trim())
                          ..set('dueDate', selectedDate)
                          ..set('isCompleted', false)
                          ..set('user', userPointer); 

                        final response = await task.save();
                        
                        if (response.success) {
                          Navigator.pop(context);
                          _loadTasks();
                        } else {
                          throw Exception(response.error?.message ?? 'Failed to save task');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding task: ${e.toString()}')),
                        );
                      } finally {
                        setState(() => _isAdding = false);
                      }
                    },
              child: _isAdding
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTaskStatus(ParseObject task) async {
    try {
      final currentStatus = task.get<bool>('isCompleted') ?? false;
      task.set('isCompleted', !currentStatus);
      final response = await task.save();
      
      if (response.success) {
        _loadTasks();
      } else {
        throw Exception(response.error?.message ?? 'Failed to update task');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTask(ParseObject task) async {
    try {
      final response = await task.delete();
      
      if (response.success) {
        _loadTasks();
      } else {
        throw Exception(response.error?.message ?? 'Failed to delete task');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: ${e.toString()}')),
      );
    }
  }

  List<ParseObject> _sortTasksByDueDate(List<ParseObject> taskList) {
    return List<ParseObject>.from(taskList)
      ..sort((a, b) {
        final aDate = a.get<DateTime>('dueDate');
        final bDate = b.get<DateTime>('dueDate');
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });
  }

  Widget _buildTaskList(List<ParseObject> taskList) {
    if (taskList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tasks',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add a task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];
        final isCompleted = task.get<bool>('isCompleted') ?? false;
        final dueDate = task.get<DateTime>('dueDate');

        return Dismissible(
          key: Key(task.objectId!),
          direction: DismissDirection.endToStart,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                task.get<String>('title') ?? '',
                style: TextStyle(
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(dueDate!)}',
              ),
              trailing: Checkbox(
                value: isCompleted,
                onChanged: (_) => _toggleTaskStatus(task),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasks = _sortTasksByDueDate(
      tasks.where((task) => !(task.get<bool>('isCompleted') ?? false)).toList()
    );
    
    final completedTasks = _sortTasksByDueDate(
      tasks.where((task) => task.get<bool>('isCompleted') ?? false).toList()
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickTask'),
        bottom: TabBar(
          controller: _tabController!,  
          tabs: const [
            Tab(text: 'Incomplete'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final user = await ParseUser.currentUser() as ParseUser?;
                if (user != null) {
                  await user.logout();
                }
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController!,  
              children: [
                _buildTaskList(incompleteTasks),
                _buildTaskList(completedTasks),
              ],
            ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton(
              onPressed: _addTask,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}