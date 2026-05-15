import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskScreen extends StatefulWidget {
  final String? taskId;
  final String? taskText;

  const AddTaskScreen({super.key, this.taskId, this.taskText});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.taskText != null) {
      taskController.text = widget.taskText!;
    }
    _migrateLegacyTasks();
  }

  Future<void> _migrateLegacyTasks() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // ✅ Fetch ALL tasks (no filter) and check in Dart
    final snapshot = await FirebaseFirestore.instance.collection('tasks').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('userId') || data['userId'] == null) {
        await doc.reference.update({'userId': uid});
      }
    }
  }

  @override
  void dispose() {
    taskController.dispose();
    super.dispose();
  }

  void submitTask() async {
    final text = taskController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      if (widget.taskId == null) {
        await FirebaseFirestore.instance.collection('tasks').add({
          'userId': uid,
          'title': text,
          'isDone': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        taskController.clear();
      } else {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskId)
            .update({'title': text, 'updatedAt': FieldValue.serverTimestamp()});
        if (mounted) Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskId == null
                  ? "Task Added Successfully"
                  : "Task Updated Successfully",
            ),
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  Future<void> toggleTaskStatus(String taskId, bool isDone) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': isDone ? FieldValue.serverTimestamp() : null,
    });
  }

  void openEditTask(String taskId, String taskText) {
    if (widget.taskId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Already on Update Screen"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskId: taskId, taskText: taskText),
      ),
    );
  }

  Widget buildTaskList() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load tasks'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No tasks yet. Add one above.',
              style: TextStyle(color: Colors.green.shade700, fontSize: 16),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString();
            final isDone = data['isDone'] == true;
            final Timestamp? createdAt = data['createdAt'];
            final DateTime? time = createdAt?.toDate().toLocal();
            final Timestamp? completedAt = data['completedAt'];
            final DateTime? completedTime = completedAt?.toDate().toLocal();

            final String displayTime = isDone
                ? (completedTime != null
                      ? '${TimeOfDay.fromDateTime(completedTime).format(context)} on ${completedTime.day}/${completedTime.month}/${completedTime.year}'
                      : 'Date & Time not available')
                : (time != null
                      ? '${TimeOfDay.fromDateTime(time).format(context)} on ${time.day}/${time.month}/${time.year}'
                      : 'Date & Time not available');

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Checkbox(
                  value: isDone,
                  activeColor: Colors.green,
                  onChanged: (value) {
                    toggleTaskStatus(doc.id, value ?? false);
                  },
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "${isDone ? 'Completed' : 'Pending'} • at $displayTime",
                  style: TextStyle(color: Colors.green.shade600),
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => openEditTask(doc.id, title),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteTask(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskId != null;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Task" : "Add Task"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                hintText: "Enter your task",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.task, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEdit ? "Update Task" : "Save Task",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: buildTaskList()),
          ],
        ),
      ),
    );
  }
}
