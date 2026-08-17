import 'package:flutter/material.dart';
import '../../../tasks/domain/video_task.dart';
import '../../../../core/utils/file_utils.dart';

class TaskItemCard extends StatelessWidget {
  final VideoTask task;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTrim;

  const TaskItemCard({
    super.key,
    required this.task,
    this.onDoubleTap,
    this.onDelete,
    this.onTrim,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orangeAccent;
      case TaskStatus.analyzing:
        return Colors.lightBlueAccent;
      case TaskStatus.processing:
        return const Color(0xFF25F4EE); // TikTok cyan
      case TaskStatus.success:
        return const Color(0xFF00E676); // Vibrant Green
      case TaskStatus.failed:
        return const Color(0xFFFF5252); // Vibrant Red
    }
  }

  String _getStatusText(VideoTask task) {
    switch (task.status) {
      case TaskStatus.pending:
        return 'В очереди';
      case TaskStatus.analyzing:
        return 'Анализ...';
      case TaskStatus.processing:
        if (task.progress > 0.0 && task.progress < 0.25) {
          return 'Whisper AI (GPU)';
        }
        return 'Рендеринг (GPU)';
      case TaskStatus.success:
        return 'Готово';
      case TaskStatus.failed:
        return 'Ошибка';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = FileUtils.getFileName(task.inputFilePath);
    final statusColor = _getStatusColor(task.status);
    final statusText = _getStatusText(task);
    final bool hasSegment = task.startTime != null && task.endTime != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasSegment ? Icons.content_cut : Icons.movie_outlined,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (task.partNumber != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFE2C55).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Часть ${task.partNumber}',
                                  style: const TextStyle(
                                    color: Color(0xFFFE2C55),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (hasSegment)
                              Text(
                                '${task.startTime} ➔ ${task.endTime}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onTrim != null)
                    IconButton(
                      icon: const Icon(Icons.content_cut,
                          size: 20, color: Colors.grey),
                      tooltip: 'Нарезать',
                      onPressed: onTrim,
                      visualDensity: VisualDensity.compact,
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    tooltip: 'Удалить из очереди',
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (task.status == TaskStatus.processing ||
                  task.status == TaskStatus.analyzing) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.status == TaskStatus.processing
                        ? task.progress
                        : null,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade800,
                    color: const Color(0xFFFE2C55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Прогресс: ${(task.progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (task.status == TaskStatus.failed && task.errorMsg != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.errorMsg!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
