import 'package:flutter/material.dart';
import '../../../tasks/domain/video_task.dart';
import '../../../../core/utils/file_utils.dart';

class TaskItemCard extends StatelessWidget {
  final VideoTask task;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTrim;
  final VoidCallback? onAiSmartCut;
  final ValueChanged<String?>? onEditHook;

  const TaskItemCard({
    super.key,
    required this.task,
    this.onDoubleTap,
    this.onDelete,
    this.onTrim,
    this.onAiSmartCut,
    this.onEditHook,
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

  void _showHookDialog(BuildContext context) {
    final controller = TextEditingController(text: task.textHook ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Текстовый хук / Заголовок видео'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Файл: ${FileUtils.getFileName(task.inputFilePath)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Текст хука (плашка сверху)',
                hintText: 'Например: ШОК НОВОСТЬ или СЕКРЕТ 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          if (task.textHook != null && task.textHook!.isNotEmpty)
            TextButton(
              onPressed: () {
                onEditHook?.call(null);
                Navigator.of(dialogCtx).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('ОЧИСТИТЬ'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('ОТМЕНА'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              onEditHook?.call(val.isEmpty ? null : val);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('СОХРАНИТЬ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = FileUtils.getFileName(task.inputFilePath);
    final statusColor = _getStatusColor(task.status);
    final statusText = _getStatusText(task);
    final bool hasSegment = task.startTime != null && task.endTime != null;
    final bool hasHook = task.textHook != null && task.textHook!.isNotEmpty;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    hasSegment ? Icons.content_cut : Icons.movie_outlined,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1.0),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    tooltip: 'Удалить из очереди',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (task.partNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
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
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (hasSegment)
                          Text(
                            '${task.startTime} ➔ ${task.endTime}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        InkWell(
                          onTap: () => _showHookDialog(context),
                          borderRadius: BorderRadius.circular(4),
                          child: hasHook
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blueAccent.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.title,
                                        size: 11,
                                        color: Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 120),
                                        child: Text(
                                          task.textHook!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.edit,
                                        size: 10,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_comment_outlined,
                                      size: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+ Заголовок / хук',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (onAiSmartCut != null)
                    IconButton(
                      icon: const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFFFE2C55)),
                      tooltip: '🤖 ИИ Авто-нарезка',
                      onPressed: onAiSmartCut,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (onTrim != null)
                    IconButton(
                      icon: const Icon(Icons.content_cut, size: 18, color: Colors.grey),
                      tooltip: 'Нарезать вручную',
                      onPressed: onTrim,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      visualDensity: VisualDensity.compact,
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
