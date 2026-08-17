import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/file_utils.dart';
import '../../../core/services/app_settings_service.dart';
import '../../presets/domain/render_preset.dart';
import '../../presets/presentation/providers/preset_provider.dart';
import '../../processing/providers/processing_provider.dart';
import '../../tasks/domain/video_task.dart';
import '../../tasks/presentation/providers/task_queue_provider.dart';
import 'widgets/task_list_view.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDragging = false;
  String _outputDirectory = '';

  static bool get _isMobilePlatform =>
      Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    // 1. Восстанавливаем ранее сохраненную папку вывода
    final savedOut = AppSettingsService.instance
        .getExistingDirectory(AppSettingsService.keyLastOutputDirectory);
    if (savedOut != null && savedOut.isNotEmpty) {
      _outputDirectory = savedOut;
    } else if (_isMobilePlatform) {
      getApplicationDocumentsDirectory().then((dir) {
        if (mounted) setState(() => _outputDirectory = dir.path);
      });
    }
  }

  Future<void> _pickFiles() async {
    final initialDir = AppSettingsService.instance
        .getExistingDirectory(AppSettingsService.keyLastInputVideoDirectory);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'mkv', 'avi'],
      initialDirectory: initialDir,
    );

    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      if (paths.isNotEmpty) {
        await AppSettingsService.instance.rememberParentDirectoryForFile(
          AppSettingsService.keyLastInputVideoDirectory,
          paths.first,
        );
      }
      ref
          .read(taskQueueProvider.notifier)
          .addTasksFromPaths(paths, _outputDirectory);
    }
  }

  Future<void> _selectOutputDirectory() async {
    // На мобильных платформах file_picker не умеет выбирать директории —
    // используем приложение-документы по умолчанию.
    if (_isMobilePlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('На мобильном результат сохраняется в папку приложения.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final initialDir = _outputDirectory.isNotEmpty
        ? _outputDirectory
        : AppSettingsService.instance
            .getExistingDirectory(AppSettingsService.keyLastOutputDirectory);

    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку для сохранения результатов',
      initialDirectory: initialDir,
    );

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      setState(() {
        _outputDirectory = selectedDirectory;
      });
      await AppSettingsService.instance.setString(
        AppSettingsService.keyLastOutputDirectory,
        selectedDirectory,
      );
    }
  }

  void _startProcessingQueue(List<VideoTask> tasks) {
    if (_outputDirectory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Пожалуйста, выберите папку для сохранения результатов!'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pendingTasks =
        tasks.where((t) => t.status == TaskStatus.pending).toList();

    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ Нет новых видео в очереди для обработки.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Resolve active preset with reliable fallbacks to database
    RenderPreset? selectedPreset = ref.read(selectedPresetProvider);
    if (selectedPreset == null) {
      final presets = ref.read(presetListProvider).valueOrNull ?? [];
      final savedPresetId = AppSettingsService.instance
          .getInt(AppSettingsService.keyLastSelectedPresetId);
      if (presets.isNotEmpty) {
        selectedPreset = (savedPresetId != null)
            ? presets.firstWhere((p) => p.id == savedPresetId, orElse: () => presets.first)
            : presets.first;
      }
      if (selectedPreset != null) {
        ref.read(selectedPresetProvider.notifier).state = selectedPreset;
      }
    }

    final effectivePreset = selectedPreset ?? RenderPreset();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚀 Запуск рендеринга ${pendingTasks.length} видео с шаблоном "${effectivePreset.name}"...',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    ref.read(batchQueueManagerProvider).startProcessing(
          taskNotifier: ref.read(taskQueueProvider.notifier),
          preset: effectivePreset,
          defaultOutputFolderPath: _outputDirectory,
        );
  }

  void _showBatchHooksDialog(BuildContext context, List<VideoTask> tasks) {
    final initialText = tasks.map((t) => t.textHook ?? '').join('\n');
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Задать заголовки/хуки списком'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Вставьте список заголовков (по 1 строке на каждое из ${tasks.length} видео):',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Заголовок для 1-го видео\nЗаголовок для 2-го видео\nЗаголовок для 3-го видео...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ОТМЕНА'),
          ),
          FilledButton(
            onPressed: () {
              final lines = controller.text.split('\n');
              ref.read(taskQueueProvider.notifier).batchSetHooks(lines);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Заголовки применены к видео в очереди!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('ПРИМЕНИТЬ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskQueueProvider);
    final presetsAsync = ref.watch(presetListProvider);
    final selectedPreset = ref.watch(selectedPresetProvider);
    final batchManager = ref.watch(batchQueueManagerProvider);

    final pendingCount =
        tasks.where((t) => t.status == TaskStatus.pending).length;
    final isProcessing = batchManager.isProcessing ||
        tasks.any((t) => t.status == TaskStatus.processing);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TT Video Automator'),
        actions: [
          // Очистить задачи, ещё не взятые в работу. Удобно, когда напихал
          // десяток файлов, а потом решил, что это не то.
          if (tasks.any((t) => t.status == TaskStatus.pending))
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Очистить ожидающие (не начатые)',
              onPressed: () {
                final pending =
                    tasks.where((t) => t.status == TaskStatus.pending).length;
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Очистить ожидающие задачи?'),
                    content: Text(
                      'Будет удалено $pending шт. Это видео, которое ещё не начало обрабатываться.\n\nФайлы на диске не пострадают.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('ОТМЕНА'),
                      ),
                      FilledButton(
                        onPressed: () {
                          ref
                              .read(taskQueueProvider.notifier)
                              .removePendingTasks();
                          Navigator.pop(ctx);
                        },
                        child: const Text('УДАЛИТЬ'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (tasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_add),
              tooltip: 'Задать заголовки списком',
              onPressed: () => _showBatchHooksDialog(context, tasks),
            ),
          if (tasks.any((t) => t.status == TaskStatus.success))
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Очистить завершенные',
              onPressed: () {
                ref.read(taskQueueProvider.notifier).clearCompletedTasks();
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Редактор Шаблонов',
            onPressed: () => context.push('/preset-editor'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Drag & Drop Area / Drop Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _isMobilePlatform
                ? GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Нажмите, чтобы выбрать видеофайлы (MP4 / MOV)',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add),
                            label: const Text('Выбрать файлы'),
                          ),
                        ],
                      ),
                    ),
                  )
                : DropTarget(
                    onDragEntered: (details) {
                      setState(() => _isDragging = true);
                    },
                    onDragExited: (details) {
                      setState(() => _isDragging = false);
                    },
                    onDragDone: (details) {
                      setState(() => _isDragging = false);
                      final validPaths = details.files
                          .map((f) => f.path)
                          .where(FileUtils.isVideoFile)
                          .toList();

                      if (validPaths.isNotEmpty) {
                        AppSettingsService.instance.rememberParentDirectoryForFile(
                          AppSettingsService.keyLastInputVideoDirectory,
                          validPaths.first,
                        );
                        ref
                            .read(taskQueueProvider.notifier)
                            .addTasksFromPaths(validPaths, _outputDirectory);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: _isDragging
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDragging
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade800,
                          width: _isDragging ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: _isDragging
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isDragging
                                ? 'Отпустите видеофайлы для добавления'
                                : 'Перетащите MP4 / MOV файлы сюда',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isDragging
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              fontWeight:
                                  _isDragging ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.add),
                            label: const Text('Выбрать файлы'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Queue Task List View
          Expanded(
            child: TaskListView(
              tasks: tasks,
              onTaskDoubleTap: (task) {
                // Даблклик по карточке открывает её в триммере
                context.push('/trimmer', extra: task.inputFilePath);
              },
              onTaskDelete: (task) {
                ref.read(taskQueueProvider.notifier).removeTask(task.id);
              },
              onTaskTrim: (task) {
                context.push('/trimmer', extra: task.inputFilePath);
              },
              onTaskEditHook: (task, hook) {
                ref.read(taskQueueProvider.notifier).updateTaskHook(task.id, hook);
              },
            ),
          ),

          // Bottom Settings Bar
          Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;

                      final folderButton = OutlinedButton.icon(
                        onPressed: _selectOutputDirectory,
                        icon: Icon(
                          _outputDirectory.isEmpty
                              ? Icons.folder_open
                              : Icons.folder_special,
                          color: _outputDirectory.isEmpty
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        // Убран вложенный Flexible: OutlinedButton.icon уже оборачивает
                        // label в Flexible — двойной Flexible даёт краш layout'а в debug/test.
                        label: Text(
                          _isMobilePlatform
                              ? 'Сохранение в папку приложения'
                              : (_outputDirectory.isEmpty
                                  ? 'Выберите папку сохранения'
                                  : _outputDirectory),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: _outputDirectory.isEmpty
                                ? Colors.grey
                                : Colors.white,
                            fontWeight: _outputDirectory.isEmpty
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          side: BorderSide(
                            color: _outputDirectory.isEmpty
                                ? Colors.grey.shade700
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      );

                      final presetSelector = presetsAsync.when(
                        data: (presetList) {
                          final savedPresetId = AppSettingsService.instance
                              .getInt(AppSettingsService.keyLastSelectedPresetId);
                          final savedPreset = (savedPresetId != null && presetList.isNotEmpty)
                              ? presetList.firstWhere(
                                  (p) => p.id == savedPresetId,
                                  orElse: () => presetList.first,
                                )
                              : (presetList.isNotEmpty ? presetList.first : null);

                          final currentPreset = selectedPreset ?? savedPreset;
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<RenderPreset>(
                                  // ValueKey форсирует смену значения внутри виджета,
                                  // иначе initialValue применяется только при первом build
                                  key: ValueKey(currentPreset?.id ?? 'none'),
                                  initialValue: currentPreset,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Пресет рендера',
                                    prefixIcon: Icon(Icons.auto_awesome),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: presetList.map((preset) {
                                    return DropdownMenuItem<RenderPreset>(
                                      value: preset,
                                      child: Text(
                                        preset.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref
                                          .read(selectedPresetProvider.notifier)
                                          .state = val;
                                      AppSettingsService.instance.setInt(
                                        AppSettingsService.keyLastSelectedPresetId,
                                        val.id,
                                      );
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Редактировать выбранный шаблон',
                                visualDensity: VisualDensity.compact,
                                onPressed: currentPreset == null
                                    ? null
                                    : () {
                                        context.push('/preset-editor',
                                            extra: currentPreset);
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: 'Создать новый шаблон',
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  context.push('/preset-editor');
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (err, stack) => const Text(
                          'Ошибка загрузки пресетов',
                          style: TextStyle(color: Colors.red),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            folderButton,
                            const SizedBox(height: 10),
                            presetSelector,
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: folderButton),
                            const SizedBox(width: 12),
                            Expanded(child: presetSelector),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (tasks.isEmpty || isProcessing)
                          ? null
                          : () => _startProcessingQueue(tasks),
                      icon: isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 28),
                      label: Text(
                        isProcessing
                            ? 'ИДЕТ ОБРАБОТКА...'
                            : (pendingCount > 0
                                ? 'СТАРТ ОБРАБОТКИ ($pendingCount)'
                                : 'СТАРТ ОБРАБОТКИ'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
