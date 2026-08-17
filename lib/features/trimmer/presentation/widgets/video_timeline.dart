import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Полоса миниатюр кадров с вертикальными линиями-метками.
/// Тап по метке её удаляет (индекс метки возвращается в onMarkerTap).
class VideoTimelineThumbnails extends StatefulWidget {
  final String videoPath;
  final Duration totalDuration;
  final int count;

  /// Метки на таймлайне в долях [0..1]. Рисуются поверх миниатюр
  /// жирными вертикальными линиями.
  final List<double> markerRatios;

  /// Колбэк: тапнули по метке → её надо удалить.
  final ValueChanged<int>? onMarkerTap;

  const VideoTimelineThumbnails({
    super.key,
    required this.videoPath,
    required this.totalDuration,
    this.count = 8,
    this.markerRatios = const [],
    this.onMarkerTap,
  });

  @override
  State<VideoTimelineThumbnails> createState() => _VideoTimelineThumbnailsState();
}

class _VideoTimelineThumbnailsState extends State<VideoTimelineThumbnails> {
  List<Future<String?>>? _futures;

  @override
  void initState() {
    super.initState();
    _scheduleExtraction();
  }

  @override
  void didUpdateWidget(covariant VideoTimelineThumbnails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        oldWidget.totalDuration != widget.totalDuration) {
      _scheduleExtraction();
    }
  }

  void _scheduleExtraction() {
    if (!mounted) return;
    if (widget.totalDuration.inMilliseconds <= 0 || widget.videoPath.isEmpty) {
      _futures = null;
      return;
    }

    _futures = List<Future<String?>>.generate(widget.count, (i) => _extractThumbnail(i));
  }

  Future<String?> _extractThumbnail(int index) async {
    try {
      final fraction = widget.count <= 1
          ? 0.0
          : (index / (widget.count - 1));
      final timeMs =
          (widget.totalDuration.inMilliseconds * fraction).clamp(0, widget.totalDuration.inMilliseconds - 100);

      if (Platform.isWindows) {
        final tempDir = await getTemporaryDirectory();
        final sec = (timeMs / 1000.0).toStringAsFixed(2);
        final hash = widget.videoPath.hashCode.abs();
        final outPath = '${tempDir.path}/thumb_${hash}_$index.jpg';
        final outFile = File(outPath);
        if (await outFile.exists() && await outFile.length() > 0) {
          return outPath;
        }
        final res = await Process.run('ffmpeg', [
          '-y',
          '-ss', sec,
          '-i', widget.videoPath,
          '-vframes', '1',
          '-vf', 'scale=200:-1',
          '-q:v', '3',
          outPath,
        ]);
        if (res.exitCode == 0 && await outFile.exists()) {
          return outPath;
        }
        return null;
      }

      final path = await VideoThumbnail.thumbnailFile(
        video: widget.videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 55,
        timeMs: timeMs.toInt(),
      );
      return path;
    } catch (e) {
      debugPrint('Thumbnail extraction failed at index $index: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_futures == null) {
      return Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade800),
        ),
      );
    }

    final primary = Theme.of(context).primaryColor;

    return SizedBox(
      height: 58,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Кадры
                Row(
                  children: List.generate(widget.count, (i) {
                    return Expanded(
                      child: FutureBuilder<String?>(
                        future: _futures![i],
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return Container(color: Colors.grey.shade900);
                          }
                          final path = snap.data;
                          if (path == null || path.isEmpty) {
                            return Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 14, color: Colors.grey),
                              ),
                            );
                          }
                          return Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (c, e, st) => Container(color: Colors.grey.shade800),
                          );
                        },
                      ),
                    );
                  }),
                ),

                // Вертикальные линии-метки
                for (var i = 0; i < widget.markerRatios.length; i++)
                  Positioned(
                    left: totalW * widget.markerRatios[i] - 1.5,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Область тапа по метке — широкая зона вокруг линии,
                // чтобы пальцем/мышью было попадать легче.
                for (var i = 0; i < widget.markerRatios.length; i++)
                  Positioned(
                    left: (totalW * widget.markerRatios[i] - 12).clamp(0.0, totalW - 24),
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onMarkerTap == null
                          ? null
                          : () => widget.onMarkerTap!(i),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Упрощённая версия VideoTimeline без ручек — оставлена для совместимости,
/// но триммер её больше не использует.
class VideoTimeline extends StatelessWidget {
  final Duration totalDuration;
  final RangeValues rangeValues;
  final ValueChanged<RangeValues> onChanged;

  const VideoTimeline({
    super.key,
    required this.totalDuration,
    required this.rangeValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
