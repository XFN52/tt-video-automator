import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/isar_service.dart';
import '../../domain/video_task.dart';

class TaskQueueNotifier extends StateNotifier<List<VideoTask>> {
  final IsarService _isarService;

  TaskQueueNotifier(this._isarService) : super([]) {
    _loadTasksFromDb();
  }

  /// Returns current list of tasks in the queue.
  List<VideoTask> get tasks => state;

  Future<void> _loadTasksFromDb() async {
    final tasks = await _isarService.getAllTasks();
    // Сброс "зависших" задач при холодном старте: если приложение убили посреди
    // обработки, в БД могли остаться задачи со статусом processing/analyzing —
    // они больше ни к чему не подключены, возвращаем их в очередь.
    for (final t in tasks) {
      if (t.status == TaskStatus.processing || t.status == TaskStatus.analyzing) {
        t.status = TaskStatus.pending;
        t.progress = 0.0;
        await _isarService.saveTask(t);
      }
    }
    state = tasks;
  }

  Future<void> addTasksFromPaths(
    List<String> filePaths,
    String outputFolderPath,
  ) async {
    final newTasks = <VideoTask>[];

    for (final path in filePaths) {
      final task = VideoTask()
        ..inputFilePath = path
        ..outputFolderPath = outputFolderPath
        ..status = TaskStatus.pending
        ..progress = 0.0;

      final id = await _isarService.saveTask(task);
      task.id = id;
      newTasks.add(task);
    }

    state = [...state, ...newTasks];
  }

  Future<void> addCustomTasks(List<VideoTask> tasks) async {
    final addedTasks = <VideoTask>[];

    for (final task in tasks) {
      final id = await _isarService.saveTask(task);
      task.id = id;
      addedTasks.add(task);
    }

    state = [...state, ...addedTasks];
  }

  Future<void> removeTask(int taskId) async {
    await _isarService.deleteTask(taskId);
    state = state.where((t) => t.id != taskId).toList();
  }

  Future<void> updateTaskProgress(
    int taskId,
    double progress,
    TaskStatus status, {
    String? errorMsg,
  }) async {
    await _isarService.updateTaskProgress(
      taskId,
      progress,
      status,
      errorMsg: errorMsg,
    );

    state = [
      for (final task in state)
        if (task.id == taskId)
          // Копируем сам объект задачи и обновляем только изменяемые поля:
          // если в модель добавят новые (например outputFilePath, presetId),
          // они здесь не потеряются.
          (task
            ..status = status
            ..progress = progress
            ..errorMsg = (status == TaskStatus.failed) ? errorMsg : null)
        else
          task,
    ];
  }

  Future<void> clearCompletedTasks() async {
    final remaining = <VideoTask>[];
    for (final task in state) {
      if (task.status == TaskStatus.success) {
        await _isarService.deleteTask(task.id);
      } else {
        remaining.add(task);
      }
    }
    state = remaining;
  }

  /// Удаляем только pending — задачи в работе не трогаем: трогать их
  /// опасно, т.к. процессу нужны id для обновления прогресса.
  Future<void> removePendingTasks() async {
    final remaining = <VideoTask>[];
    for (final task in state) {
      if (task.status == TaskStatus.pending) {
        await _isarService.deleteTask(task.id);
      } else {
        remaining.add(task);
      }
    }
    state = remaining;
  }
}

final taskQueueProvider =
    StateNotifierProvider<TaskQueueNotifier, List<VideoTask>>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return TaskQueueNotifier(isarService);
});
