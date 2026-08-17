import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/domain/video_task.dart';
import 'task_item_card.dart';

class TaskListView extends ConsumerWidget {
  final List<VideoTask> tasks;
  final Function(VideoTask)? onTaskDoubleTap;
  final Function(VideoTask)? onTaskDelete;
  final Function(VideoTask)? onTaskTrim;
  final Function(VideoTask)? onTaskAiSmartCut;
  final void Function(VideoTask task, String? hook)? onTaskEditHook;

  const TaskListView({
    super.key,
    required this.tasks,
    this.onTaskDoubleTap,
    this.onTaskDelete,
    this.onTaskTrim,
    this.onTaskAiSmartCut,
    this.onTaskEditHook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      final isMobile = Platform.isAndroid || Platform.isIOS;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.playlist_add_outlined,
                size: 64,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 12),
              Text(
                'Очередь пустая',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMobile
                    ? 'Нажмите "Выбрать файлы" выше, чтобы добавить видео к обработке.'
                    : 'Перетащите MP4 файлы в область выше или нажмите на неё.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'После загрузки сможете нарезать части и наложить шаблон.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItemCard(
          task: task,
          onDoubleTap: () => onTaskDoubleTap?.call(task),
          onDelete: () => onTaskDelete?.call(task),
          onTrim: () => onTaskTrim?.call(task),
          onAiSmartCut: () => onTaskAiSmartCut?.call(task),
          onEditHook: (hook) => onTaskEditHook?.call(task, hook),
        );
      },
    );
  }
}
