import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full interactive 9:16 frame preview editor allowing drag & resize of:
/// - Banner / Overlay
/// - Text Hook
/// - Part numbering badge
/// - Subtitle karaoke block
class FullPreviewEditor extends StatefulWidget {
  final String? previewVideoPath;
  final String? bannerPath;
  final double bannerXRatio;
  final double bannerYRatio;
  final double bannerWidthRatio;
  final double bannerHeightRatio;
  final Function(double x, double y, double w, double h) onBannerChanged;

  final String? textHook;
  final double textHookYRatio;
  final ValueChanged<double>? onTextHookYChanged;

  final bool autoNumbering;
  final double numberingYRatio;
  final ValueChanged<double>? onNumberingYChanged;

  final bool showSubtitles;
  final double subtitleYRatio;
  final ValueChanged<double>? onSubtitleYChanged;

  final ValueChanged<bool>? onDragStateChanged;

  const FullPreviewEditor({
    super.key,
    this.previewVideoPath,
    required this.bannerPath,
    required this.bannerXRatio,
    required this.bannerYRatio,
    required this.bannerWidthRatio,
    required this.bannerHeightRatio,
    required this.onBannerChanged,
    this.textHook,
    this.textHookYRatio = 0.04,
    this.onTextHookYChanged,
    this.autoNumbering = true,
    this.numberingYRatio = 0.12,
    this.onNumberingYChanged,
    this.showSubtitles = false,
    this.subtitleYRatio = 0.75,
    this.onSubtitleYChanged,
    this.onDragStateChanged,
  });

  @override
  State<FullPreviewEditor> createState() => _FullPreviewEditorState();
}

class _FullPreviewEditorState extends State<FullPreviewEditor> {
  late double _bX;
  late double _bY;
  late double _bW;
  late double _bH;

  late double _hookY;
  late double _numY;
  late double _subY;

  VideoPlayerController? _previewController;
  bool _previewInitialized = false;
  String? _currentPreviewPath;

  static bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _bX = widget.bannerXRatio;
    _bY = widget.bannerYRatio;
    _bW = widget.bannerWidthRatio;
    _bH = widget.bannerHeightRatio;
    _hookY = widget.textHookYRatio;
    _numY = widget.numberingYRatio;
    _subY = widget.subtitleYRatio;
    _initPreviewIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FullPreviewEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannerXRatio != widget.bannerXRatio ||
        oldWidget.bannerYRatio != widget.bannerYRatio ||
        oldWidget.bannerWidthRatio != widget.bannerWidthRatio ||
        oldWidget.bannerHeightRatio != widget.bannerHeightRatio) {
      _bX = widget.bannerXRatio;
      _bY = widget.bannerYRatio;
      _bW = widget.bannerWidthRatio;
      _bH = widget.bannerHeightRatio;
    }
    if (oldWidget.textHookYRatio != widget.textHookYRatio) {
      _hookY = widget.textHookYRatio;
    }
    if (oldWidget.numberingYRatio != widget.numberingYRatio) {
      _numY = widget.numberingYRatio;
    }
    if (oldWidget.subtitleYRatio != widget.subtitleYRatio) {
      _subY = widget.subtitleYRatio;
    }
    if (oldWidget.previewVideoPath != widget.previewVideoPath) {
      _initPreviewIfNeeded();
    }
  }

  @override
  void dispose() {
    _disposePreview();
    super.dispose();
  }

  void _disposePreview() {
    final c = _previewController;
    _previewController = null;
    _previewInitialized = false;
    c?.dispose();
  }

  void _initPreviewIfNeeded() {
    final path = widget.previewVideoPath;
    if (path == null || path.isEmpty) {
      if (_previewController != null) _disposePreview();
      _currentPreviewPath = null;
      return;
    }
    if (_currentPreviewPath == path && _previewInitialized) {
      return;
    }

    _disposePreview();
    _currentPreviewPath = path;

    final file = File(path);
    if (!file.existsSync()) {
      return;
    }

    final controller = VideoPlayerController.file(file);
    _previewController = controller;

    controller
        .initialize()
        .then((_) async {
          if (!mounted || _previewController != controller) {
            controller.dispose();
            return;
          }
          await controller.setVolume(0.0);
          await controller.setLooping(false);
          await controller.pause();
          if (mounted && _previewController == controller) {
            setState(() => _previewInitialized = true);
          }
        })
        .catchError((e) {
          controller.dispose();
          if (mounted) {
            setState(() {
              _previewController = null;
              _previewInitialized = false;
            });
          }
        });
  }

  void _notifyBanner() {
    widget.onBannerChanged(_bX, _bY, _bW, _bH);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 400;

    final maxCanvasW = screenW - 100;
    double canvasW = isMobile ? 162.0 : 216.0;
    double canvasH = isMobile ? 288.0 : 384.0;
    if (canvasW > maxCanvasW) {
      final scale = maxCanvasW / canvasW;
      canvasW = maxCanvasW;
      canvasH = canvasH * scale;
    }

    final bannerLeft = (_bX * canvasW).clamp(0.0, canvasW - 20.0);
    final bannerTop = (_bY * canvasH).clamp(0.0, canvasH - 20.0);
    final bannerWidth = (_bW * canvasW).clamp(30.0, canvasW - bannerLeft);
    final bannerHeight = (_bH * canvasH).clamp(20.0, canvasH - bannerTop);

    final hasBannerFile = widget.bannerPath != null && widget.bannerPath!.isNotEmpty;
    final isVideoBanner = hasBannerFile &&
        (widget.bannerPath!.toLowerCase().endsWith('.mp4') ||
            widget.bannerPath!.toLowerCase().endsWith('.mov') ||
            widget.bannerPath!.toLowerCase().endsWith('.avi') ||
            widget.bannerPath!.toLowerCase().endsWith('.mkv'));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final title = const Text(
                  'Интерактивный предпросмотр кадра (9:16)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                final resetButton = TextButton.icon(
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Сброс позиций'),
                  onPressed: () {
                    setState(() {
                      _bX = 0.0;
                      _bY = 0.844;
                      _bW = 1.0;
                      _bH = 0.156;
                      _hookY = 0.04;
                      _numY = 0.12;
                      _subY = 0.75;
                    });
                    _notifyBanner();
                    widget.onTextHookYChanged?.call(0.04);
                    widget.onNumberingYChanged?.call(0.12);
                    widget.onSubtitleYChanged?.call(0.75);
                  },
                );
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      Align(alignment: Alignment.centerRight, child: resetButton),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    resetButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              _isMobilePlatform
                  ? 'Тяните элементы пальцем. Синий кружок снизу-справа меняет размер плашки.'
                  : 'Тяните элементы мышью. Синий кружок снизу-справа меняет размер плашки.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: canvasW,
                height: canvasH,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withAlpha(128), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Video Background
                      Positioned.fill(
                        child: _buildVideoBackground(canvasW, canvasH),
                      ),

                      // 1. Draggable Text Hook
                      Builder(
                        builder: (context) {
                          final hookLabel = (widget.textHook != null && widget.textHook!.isNotEmpty)
                              ? widget.textHook!
                              : 'ЗАГОЛОВОК ВИДЕО (ХУК)';
                          return Positioned(
                            top: (_hookY * canvasH).clamp(0.0, canvasH - 30.0),
                            left: 8,
                            right: 8,
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) => widget.onDragStateChanged?.call(true),
                              onPointerUp: (_) => widget.onDragStateChanged?.call(false),
                              onPointerCancel: (_) => widget.onDragStateChanged?.call(false),
                              onPointerMove: (event) {
                                setState(() {
                                  _hookY = (_hookY + event.delta.dy / canvasH).clamp(0.0, 0.9);
                                });
                                widget.onTextHookYChanged?.call(_hookY);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  border: Border.all(color: Colors.white70, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hookLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // 2. Draggable Part Numbering
                      if (widget.autoNumbering)
                        Positioned(
                          top: (_numY * canvasH).clamp(0.0, canvasH - 24.0),
                          left: canvasW * 0.2,
                          right: canvasW * 0.2,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) => widget.onDragStateChanged?.call(true),
                            onPointerUp: (_) => widget.onDragStateChanged?.call(false),
                            onPointerCancel: (_) => widget.onDragStateChanged?.call(false),
                            onPointerMove: (event) {
                              setState(() {
                                _numY = (_numY + event.delta.dy / canvasH).clamp(0.0, 0.9);
                              });
                              widget.onNumberingYChanged?.call(_numY);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withAlpha(200),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Text(
                                'Часть 1',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 3. Draggable Subtitles
                      if (widget.showSubtitles)
                        Positioned(
                          top: (_subY * canvasH).clamp(0.0, canvasH - 26.0),
                          left: 12,
                          right: 12,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) => widget.onDragStateChanged?.call(true),
                            onPointerUp: (_) => widget.onDragStateChanged?.call(false),
                            onPointerCancel: (_) => widget.onDragStateChanged?.call(false),
                            onPointerMove: (event) {
                              setState(() {
                                _subY = (_subY + event.delta.dy / canvasH).clamp(0.0, 0.9);
                              });
                              widget.onSubtitleYChanged?.call(_subY);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(160),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.greenAccent, width: 1),
                              ),
                              child: const Text(
                                'Субтитры (Караоке)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 4. Draggable & Resizable Banner
                      Positioned(
                        left: bannerLeft,
                        top: bannerTop,
                        width: bannerWidth,
                        height: bannerHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) => widget.onDragStateChanged?.call(true),
                                onPointerUp: (_) => widget.onDragStateChanged?.call(false),
                                onPointerCancel: (_) => widget.onDragStateChanged?.call(false),
                                onPointerMove: (event) {
                                  setState(() {
                                    final maxBX = (1.0 - _bW).clamp(0.0, 1.0);
                                    final maxBY = (1.0 - _bH).clamp(0.0, 1.0);
                                    _bX = (_bX + event.delta.dx / canvasW).clamp(0.0, maxBX);
                                    _bY = (_bY + event.delta.dy / canvasH).clamp(0.0, maxBY);
                                  });
                                  _notifyBanner();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hasBannerFile
                                        ? Colors.black26
                                        : Colors.blue.withAlpha(77),
                                    border: Border.all(color: Colors.blueAccent, width: 2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: hasBannerFile
                                        ? (isVideoBanner
                                            ? Container(
                                                color: Colors.black54,
                                                alignment: Alignment.center,
                                                child: const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.movie, color: Colors.white70, size: 16),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      'Видео-плашка',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Image.file(
                                                File(widget.bannerPath!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Center(
                                                  child: Icon(Icons.broken_image, size: 14, color: Colors.white),
                                                ),
                                              ))
                                        : const Center(
                                            child: Text(
                                              'Плашка',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            // Resize Handle bottom-right
                            Positioned(
                              right: -14,
                              bottom: -14,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) => widget.onDragStateChanged?.call(true),
                                onPointerUp: (_) => widget.onDragStateChanged?.call(false),
                                onPointerCancel: (_) => widget.onDragStateChanged?.call(false),
                                onPointerMove: (event) {
                                  setState(() {
                                    final newW = (_bW + event.delta.dx / canvasW).clamp(0.15, (1.0 - _bX).clamp(0.15, 1.0));
                                    final newH = (_bH + event.delta.dy / canvasH).clamp(0.05, (1.0 - _bY).clamp(0.05, 1.0));
                                    _bW = newW;
                                    _bH = newH;
                                  });
                                  _notifyBanner();
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.aspect_ratio,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.vertical_align_bottom, size: 14),
                  label: const Text('Снизу', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _bX = 0.0;
                      _bY = 0.844;
                      _bW = 1.0;
                      _bH = 0.156;
                    });
                    _notifyBanner();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.vertical_align_top, size: 14),
                  label: const Text('Сверху', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _bX = 0.0;
                      _bY = 0.0;
                      _bW = 1.0;
                      _bH = 0.156;
                    });
                    _notifyBanner();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.vertical_align_center, size: 14),
                  label: const Text('По центру', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _bX = 0.1;
                      _bY = 0.42;
                      _bW = 0.8;
                      _bH = 0.16;
                    });
                    _notifyBanner();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.fit_screen, size: 14),
                  label: const Text('Во всю ширину', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _bX = 0.0;
                      _bW = 1.0;
                    });
                    _notifyBanner();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Плашка: X=${(_bX * 100).toStringAsFixed(0)}%, Y=${(_bY * 100).toStringAsFixed(0)}% | W=${(_bW * 100).toStringAsFixed(0)}%, H=${(_bH * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground(double canvasW, double canvasH) {
    final controller = _previewController;
    if (_previewInitialized && controller != null && controller.value.isInitialized) {
      final aspect = controller.value.aspectRatio;
      return FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: aspect >= 1.0 ? canvasH * aspect : canvasW,
          height: aspect >= 1.0 ? canvasH : canvasW / aspect,
          child: VideoPlayer(controller),
        ),
      );
    }

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 40, color: Colors.white.withAlpha(50)),
          const SizedBox(height: 4),
          Text(
            'Нет видео в очереди',
            style: TextStyle(color: Colors.white.withAlpha(77), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// Backward compatibility alias for BannerPositionEditor
class BannerPositionEditor extends StatelessWidget {
  final String? bannerPath;
  final double xRatio;
  final double yRatio;
  final double widthRatio;
  final double heightRatio;
  final Function(double x, double y, double w, double h) onChanged;
  final String? previewVideoPath;
  final Widget Function(double canvasW, double canvasH)? overlayChild;

  const BannerPositionEditor({
    super.key,
    required this.bannerPath,
    required this.xRatio,
    required this.yRatio,
    required this.widthRatio,
    required this.heightRatio,
    required this.onChanged,
    this.previewVideoPath,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    return FullPreviewEditor(
      previewVideoPath: previewVideoPath,
      bannerPath: bannerPath,
      bannerXRatio: xRatio,
      bannerYRatio: yRatio,
      bannerWidthRatio: widthRatio,
      bannerHeightRatio: heightRatio,
      onBannerChanged: onChanged,
    );
  }
}
