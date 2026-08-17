import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/presets/domain/render_preset.dart';
import '../../features/tasks/domain/video_task.dart';

class IsarService {
  late Isar _isar;

  Isar get isar => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    try {
      _isar = await Isar.open(
        [RenderPresetSchema, VideoTaskSchema],
        directory: dir.path,
      );
    } catch (e) {
      debugPrint('Error initializing Isar DB: $e. Clearing stale DB files and retrying...');
      try {
        final dbDir = Directory(dir.path);
        if (await dbDir.exists()) {
          final files = dbDir.listSync();
          for (final f in files) {
            if (f.path.endsWith('.isar') || f.path.endsWith('.isar.lock')) {
              await f.delete();
            }
          }
        }
        _isar = await Isar.open(
          [RenderPresetSchema, VideoTaskSchema],
          directory: dir.path,
        );
      } catch (retryError, retryStack) {
        debugPrint('Critical Error initializing Isar DB after reset: $retryError\n$retryStack');
        rethrow;
      }
    }
  }

  Future<int> savePreset(RenderPreset preset) async {
    try {
      return await _isar.writeTxn(() async {
        return await _isar.renderPresets.put(preset);
      });
    } catch (e, stack) {
      debugPrint('Error saving preset to Isar DB: $e\n$stack');
      if (e.toString().contains('No space left') || e is FileSystemException) {
        throw const FileSystemException('Недостаточно места на диске для сохранения шаблона');
      }
      rethrow;
    }
  }

  Future<List<RenderPreset>> getAllPresets() async {
    try {
      return await _isar.renderPresets.where().findAll();
    } catch (e, stack) {
      debugPrint('Error getting presets from Isar DB: $e\n$stack');
      return [];
    }
  }

  Future<bool> deletePreset(int id) async {
    try {
      return await _isar.writeTxn(() async {
        return await _isar.renderPresets.delete(id);
      });
    } catch (e, stack) {
      debugPrint('Error deleting preset from Isar DB: $e\n$stack');
      return false;
    }
  }

  // --- Tasks CRUD & Queue Methods ---

  Future<int> saveTask(VideoTask task) async {
    try {
      return await _isar.writeTxn(() async {
        return await _isar.videoTasks.put(task);
      });
    } catch (e, stack) {
      debugPrint('Error saving task to Isar DB: $e\n$stack');
      if (e.toString().contains('No space left') || e is FileSystemException) {
        throw const FileSystemException('Недостаточно места на диске для сохранения задачи');
      }
      return -1;
    }
  }

  Future<List<VideoTask>> getAllTasks() async {
    try {
      return await _isar.videoTasks.where().findAll();
    } catch (e, stack) {
      debugPrint('Error getting tasks from Isar DB: $e\n$stack');
      return [];
    }
  }

  Future<void> updateTaskProgress(
    int id,
    double progress,
    TaskStatus status, {
    String? errorMsg,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final task = await _isar.videoTasks.get(id);
        if (task != null) {
          task.progress = progress;
          task.status = status;
          if (status == TaskStatus.failed) {
            task.errorMsg = errorMsg;
          } else if (status == TaskStatus.processing || status == TaskStatus.pending || status == TaskStatus.success) {
            task.errorMsg = null;
          }
          await _isar.videoTasks.put(task);
        }
      });
    } catch (e, stack) {
      debugPrint('Error updating task progress in Isar DB: $e\n$stack');
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      return await _isar.writeTxn(() async {
        return await _isar.videoTasks.delete(id);
      });
    } catch (e, stack) {
      debugPrint('Error deleting task from Isar DB: $e\n$stack');
      return false;
    }
  }
}
