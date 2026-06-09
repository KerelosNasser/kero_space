import 'package:isar/isar.dart';
import '../../../../core/data/isar_service.dart';
import '../models/productivity_collections.dart';

class ProductivityRepository {
  final IsarService _isarService;

  ProductivityRepository(this._isarService);

  Future<List<Task>> getAllTasks() async {
    final isar = IsarService.instance;
    return isar.tasks.where().findAll();
  }

  Future<List<Task>> getDailyChecklist() async {
    final isar = IsarService.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return isar.tasks.filter()
        .dueDateBetween(startOfDay, endOfDay)
        .findAll();
  }

  Future<void> saveTask(Task task) async {
    final isar = IsarService.instance;
    task.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
  }

  Future<void> deleteTaskRecursively(int taskId) async {
    final isar = IsarService.instance;
    
    // Find all children
    final children = await isar.tasks.filter().parentIdEqualTo(taskId).findAll();
    final childIds = children.map((e) => e.id).toList();

    await isar.writeTxn(() async {
      // Delete children first (only 3 levels max, so this covers task -> subtask)
      if (childIds.isNotEmpty) {
        await isar.tasks.deleteAll(childIds);
      }
      // Delete parent
      await isar.tasks.delete(taskId);
    });
  }

  Future<void> completeTaskRecursively(int taskId) async {
    final isar = IsarService.instance;
    final now = DateTime.now();

    await isar.writeTxn(() async {
      final task = await isar.tasks.get(taskId);
      if (task != null) {
        task.isCompleted = true;
        task.updatedAt = now;
        await isar.tasks.put(task);

        // Find all children
        final children = await isar.tasks.filter().parentIdEqualTo(taskId).findAll();
        for (var child in children) {
          child.isCompleted = true;
          child.updatedAt = now;
          await isar.tasks.put(child);
          
          // Find grandchildren (Subtasks)
          final grandChildren = await isar.tasks.filter().parentIdEqualTo(child.id).findAll();
          for (var grandChild in grandChildren) {
            grandChild.isCompleted = true;
            grandChild.updatedAt = now;
            await isar.tasks.put(grandChild);
          }
        }
      }
    });
  }

  Future<void> performCarryForwardLogic() async {
    final isar = IsarService.instance;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    // Find tasks that are not completed and due date is strictly before today
    final overdueTasks = await isar.tasks.filter()
        .isCompletedEqualTo(false)
        .and()
        .dueDateLessThan(startOfDay)
        .findAll();

    if (overdueTasks.isNotEmpty) {
      await isar.writeTxn(() async {
        for (var task in overdueTasks) {
          task.dueDate = now; // Carry forward to today
          task.updatedAt = now;
          await isar.tasks.put(task);
        }
      });
    }
  }

  // Notes
  Future<List<Note>> getAllNotes() async {
    final isar = IsarService.instance;
    return isar.notes.where().sortByUpdatedAtDesc().findAll();
  }

  Future<void> saveNote(Note note) async {
    final isar = IsarService.instance;
    note.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }
}
