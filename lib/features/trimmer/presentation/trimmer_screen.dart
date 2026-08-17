import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/utils/file_utils.dart';
import '../../tasks/domain/video_task.dart';
import '../../tasks/presentation/providers/task_queue_provider.dart';
import 'widgets/video_timeline.dart';

class TrimmerScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const TrimmerScreen({super.key, required this.videoPath});

  @override
  ConsumerState<TrimmerScreen> createState() => _TrimmerScreenState();
}

class _TrimmerScreenState extends ConsumerState<TrimmerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  String? _initError;

  /// Метки на таймлайне в долях [0..1], отсортированные по возрастанию.
  /// Сегменты нарезки генерируются автоматически между соседними точками:
  ///   [0, m1, m2, ..., mN, 1]
  final List<double> _markerRatios = [];

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (widget.videoPath.isEmpty) {
      setState(() => _initError = 'Не указан путь к видео');
      return;
    }

    final file = File(widget.videoPath);
    if (!await file.exists()) {
      setState(() => _initError = 'Файл не найден:\n${widget.videoPath}');
      return;
    }

    _controller = VideoPlayerController.file(file);
    try {
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() => _initError = 'Не удалось открыть видео: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Duration get _totalDuration =>
      _isInitialized ? _controller!.value.duration : Duration.zero;
  Duration get _currentPosition =>
      _isInitialized ? _controller!.value.position : Duration.zero;

  /// Автогенерация сегментов: начало фильма + все метки + конец = точки,
  /// каждый кусок между соседними — отдельный VideoTask.
  List<VideoTask> get _generatedSegments {
    if (!_isInitialized || _totalDuration == Duration.zero) return [];

    final boundaries = <double>[0.0, ..._markerRatios, 1.0];
    final result = <VideoTask>[];
    for (var i = 0; i < boundaries.length - 1; i++) {
      final start = _totalDuration * boundaries[i];
      final end = _totalDuration * boundaries[i + 1];
      if (end <= start) continue; // защита на случай дырочки/пустоты

      final task = VideoTask()
        ..inputFilePath = widget.videoPath
        ..outputFolderPath = ''
        ..status = TaskStatus.pending
        ..progress = 0.0
        ..startTime = _formatDuration(start)
        ..endTime = _formatDuration(end)
        ..partNumber = result.length + 1;
      result.add(task);
    }
    return result;
  }

  void _addMarkerAtCurrentPosition() {
    if (!_isInitialized || _controller == null) return;
    final total = _totalDuration;
    if (total == Duration.zero) return;

    final ratio = (_currentPosition.inMilliseconds / total.inMilliseconds)
        .clamp(0.0, 1.0);

    // Метка в начале/конце бесполезна — они уже границы.
    if (ratio < 0.005 || ratio > 0.995) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Метки в самом начале и конце не нужны — это границы.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Не плодим дубликаты: ближе 0.5% — считаем той же.
    for (final existing in _markerRatios) {
      if ((existing - ratio).abs() < 0.005) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Метка в этом месте уже стоит.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _markerRatios.add(ratio);
      _markerRatios.sort();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📍 Метка ${_markerRatios.length} поставлена на ${_formatDuration(_currentPosition)}',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeMarkerAt(int index) {
    if (index < 0 || index >= _markerRatios.length) return;
    setState(() {
      _markerRatios.removeAt(index);
    });
  }

  Future<void> _addSegmentsToMainQueue() async {
    final segments = _generatedSegments;
    if (segments.isEmpty || _isSubmitting) return;
    _isSubmitting = true;

    try {
      final taskNotifier = ref.read(taskQueueProvider.notifier);
      await taskNotifier.addCustomTasks(segments);
    } finally {
      _isSubmitting = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Добавлено ${segments.length} частей в общую очередь!',
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Визуальная Нарезка (Trimmer)')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось открыть видео',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('НАЗАД'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fileName = FileUtils.getFileName(widget.videoPath);
    final totalDuration = _totalDuration;
    final currentPosition = _currentPosition;
    final currentRatio = totalDuration == Duration.zero
        ? 0.0
        : (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
            .clamp(0.0, 1.0);

    final segments = _generatedSegments;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Визуальная Нарезка (Trimmer)',
                style: TextStyle(fontSize: 16)),
            Text(
              fileName,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Main Video Player View
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.black,
              child: Center(
                child: _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),

          // Timeline & Markers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Полоса миниатюр с оверлеем меток
                if (_isInitialized && totalDuration > Duration.zero) ...[
                  VideoTimelineThumbnails(
                    videoPath: widget.videoPath,
                    totalDuration: totalDuration,
                    markerRatios: _markerRatios,
                    onMarkerTap: _removeMarkerAt,
                  ),
                  const SizedBox(height: 8),
                ],
                // ОДИН слайдер — только позиция воспроизведения, никаких ручек.
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    showValueIndicator: ShowValueIndicator.onDrag,
                  ),
                  child: Slider(
                    value: currentRatio,
                    label: _formatDuration(currentPosition),
                    activeColor: Theme.of(context).primaryColor,
                    inactiveColor: Colors.grey.shade800,
                    onChanged: !_isInitialized
                        ? null
                        : (v) {
                            _controller!.seekTo(totalDuration * v);
                          },
                  ),
                ),
                const SizedBox(height: 8),
                // Контролы
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 520;

                    final playbackTimer = Text(
                      '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );

                    Widget jumpButton(int seconds) {
                      return TextButton.icon(
                        icon: Icon(
                          seconds < 0 ? Icons.fast_rewind : Icons.fast_forward,
                          size: 16,
                        ),
                        label: Text('${seconds.abs()} с'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: !_isInitialized
                            ? null
                            : () {
                                final target = currentPosition +
                                    Duration(seconds: seconds);
                                final clamped = target < Duration.zero
                                    ? Duration.zero
                                    : (target > totalDuration
                                        ? totalDuration
                                        : target);
                                _controller!.seekTo(clamped);
                              },
                      );
                    }

                    final playButton = IconButton(
                      icon: Icon(
                        _isInitialized && _controller!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 44,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        if (_isInitialized) {
                          setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          });
                        }
                      },
                    );

                    final markerButton = ElevatedButton.icon(
                      onPressed:
                          _isInitialized ? _addMarkerAtCurrentPosition : null,
                      icon: const Icon(Icons.add_location_alt),
                      label: Text(
                        'Поставить метку (${_markerRatios.length})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          playbackTimer,
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              jumpButton(-1),
                              const SizedBox(width: 4),
                              jumpButton(1),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              playButton,
                              const SizedBox(width: 12),
                              Expanded(child: markerButton),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: playbackTimer),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            jumpButton(-1),
                            playButton,
                            jumpButton(1),
                            const SizedBox(width: 16),
                            markerButton,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Авто-генерация сегментов между метками
          Expanded(
            flex: 3,
            child: segments.isEmpty && _markerRatios.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.content_cut,
                              size: 48, color: Colors.grey.shade700),
                          const SizedBox(height: 12),
                          const Text(
                            'Меток пока нет',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Поставьте метки на нужных местах в видео.\nКаждый кусок между метками станет отдельной частью.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: segments.length,
                    itemBuilder: (context, index) {
                      final seg = segments[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${seg.partNumber}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('Часть ${seg.partNumber}'),
                          subtitle: Text('${seg.startTime} ➔ ${seg.endTime}'),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action Bar
          if (segments.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardTheme.color,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _addSegmentsToMainQueue,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done_all),
                  label: Text(
                    _isSubmitting
                        ? 'ДОБАВЛЯЮ...'
                        : 'НАРЕЗАТЬ (${segments.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
