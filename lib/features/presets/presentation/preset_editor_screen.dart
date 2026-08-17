import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../tasks/presentation/providers/task_queue_provider.dart';
import '../domain/render_preset.dart';
import 'widgets/banner_position_editor.dart';
import 'providers/preset_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final RenderPreset? presetToEdit;

  const PresetEditorScreen({super.key, this.presetToEdit});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Fields State
  late TextEditingController _nameController;
  late BackgroundMode _bgMode;
  late bool _isMirrored;
  late double _speedDelta;
  late double _colorDelta;
  late double _noiseLevel;
  String? _bannerPath;
  String? _gameplayVideoPath;
  late TextEditingController _textHookController;
  late bool _autoNumbering;
  String? _audioPath;
  late bool _useWhisper;
  late double _audioVolume;
  late BannerPosition _bannerPosition;
  late double _bannerXRatio;
  late double _bannerYRatio;
  late double _bannerWidthRatio;
  late double _bannerHeightRatio;
  late SubtitlePosition _subtitlePosition;
  // Вертикальные позиции предпросмотра [0..1]
  late double _textHookYRatio;
  late double _numberingYRatio;
  late double _subtitleYRatio;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    final p = widget.presetToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _bgMode = p?.bgMode ?? BackgroundMode.blur;
    _gameplayVideoPath = p?.gameplayVideoPath;
    _isMirrored = p?.isMirrored ?? false;
    _speedDelta = p?.speedDelta ?? 0.02;
    _colorDelta = p?.colorDelta ?? 0.03;
    _noiseLevel = p?.noiseLevel ?? 1.0;
    _bannerPath = p?.bannerPath;
    _bannerPosition = p?.bannerPosition ?? BannerPosition.bottom;
    _bannerXRatio = p?.bannerXRatio ?? 0.0;
    _bannerYRatio = p?.bannerYRatio ?? (p?.bannerPosition == BannerPosition.top ? 0.08 : 0.844);
    _bannerWidthRatio = p?.bannerWidthRatio ?? 1.0;
    _bannerHeightRatio = p?.bannerHeightRatio ?? 0.156;
    _textHookController = TextEditingController(text: p?.textHook ?? '');
    _autoNumbering = p?.autoNumbering ?? true;
    _audioPath = p?.audioPath;
    _useWhisper = p?.useWhisper ?? false;
    _subtitlePosition = p?.subtitlePosition ?? SubtitlePosition.bottom;
    _audioVolume = p?.audioVolume ?? 0.08;
    _textHookYRatio = p?.textHookYRatio ?? 0.04;
    _numberingYRatio = p?.numberingYRatio ?? 0.12;
    _subtitleYRatio = p?.subtitleYRatio ??
        // Конвертируем enum в коэффициент для обратной совместимости со
        // старыми шаблонами в БД.
        switch (_subtitlePosition) {
          SubtitlePosition.top => 0.15,
          SubtitlePosition.center => 0.5,
          SubtitlePosition.bottom => 0.75,
        };
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _textHookController.dispose();
    super.dispose();
  }

  Future<void> _savePreset() async {
    if (_formKey.currentState!.validate()) {
      final isarService = ref.read(isarServiceProvider);

      final preset = (widget.presetToEdit ?? RenderPreset())
        ..name = _nameController.text.trim()
        ..bgMode = _bgMode
        ..gameplayVideoPath = _gameplayVideoPath
        ..isMirrored = _isMirrored
        ..speedDelta = _speedDelta
        ..colorDelta = _colorDelta
        ..noiseLevel = _noiseLevel
        ..bannerPath = _bannerPath
        ..bannerPosition = _bannerPosition
        ..bannerXRatio = _bannerXRatio
        ..bannerYRatio = _bannerYRatio
        ..bannerWidthRatio = _bannerWidthRatio
        ..bannerHeightRatio = _bannerHeightRatio
        ..textHook = _textHookController.text.trim()
        ..autoNumbering = _autoNumbering
        ..audioPath = _audioPath
        ..useWhisper = _useWhisper
        ..subtitlePosition = _subtitleYRatio < 0.33
            ? SubtitlePosition.top
            : (_subtitleYRatio < 0.66
                ? SubtitlePosition.center
                : SubtitlePosition.bottom)
        ..subtitleYRatio = _subtitleYRatio
        ..textHookYRatio = _textHookYRatio
        ..numberingYRatio = _numberingYRatio
        ..audioVolume = _audioVolume;

      await isarService.savePreset(preset);

      // Refresh preset list on Dashboard Screen
      ref.invalidate(presetListProvider);
      ref.read(selectedPresetProvider.notifier).state = preset;
      await AppSettingsService.instance.setInt(
        AppSettingsService.keyLastSelectedPresetId,
        preset.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Шаблон "${preset.name}" успешно сохранен!'),
            backgroundColor: Theme.of(context).primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    }
  }

  Future<void> _deletePreset() async {
    final p = widget.presetToEdit;
    if (p == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: Text(
          'Шаблон "${p.name}" будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('ОТМЕНА'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('УДАЛИТЬ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final isarService = ref.read(isarServiceProvider);
    await isarService.deletePreset(p.id);

    // Если удаляемый шаблон был выбран на дашборде — сбрасываем выбор.
    final selected = ref.read(selectedPresetProvider);
    if (selected?.id == p.id) {
      ref.read(selectedPresetProvider.notifier).state = null;
    }
    ref.invalidate(presetListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Шаблон "${p.name}" удалён.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<void> _pickBannerFile() async {
    final initialDir = (_bannerPath != null && _bannerPath!.isNotEmpty)
        ? AppSettingsService.instance.getExistingDirectory(File(_bannerPath!).parent.path)
        : AppSettingsService.instance
            .getExistingDirectory(AppSettingsService.keyLastBannerDirectory);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'png', 'mov'],
      initialDirectory: initialDir,
    );

    if (result != null && result.files.single.path != null) {
      final picked = result.files.single.path!;
      setState(() {
        _bannerPath = picked;
      });
      await AppSettingsService.instance.rememberParentDirectoryForFile(
        AppSettingsService.keyLastBannerDirectory,
        picked,
      );
    }
  }

  Future<void> _pickGameplayVideoFile() async {
    final initialDir = (_gameplayVideoPath != null && _gameplayVideoPath!.isNotEmpty)
        ? AppSettingsService.instance.getExistingDirectory(File(_gameplayVideoPath!).parent.path)
        : AppSettingsService.instance
            .getExistingDirectory(AppSettingsService.keyLastGameplayDirectory);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
      dialogTitle: 'Выберите видеофайл с геймплеем (GTA V, Minecraft и т.д.)',
      initialDirectory: initialDir,
    );

    if (result != null && result.files.single.path != null) {
      final picked = result.files.single.path!;
      setState(() {
        _gameplayVideoPath = picked;
      });
      await AppSettingsService.instance.rememberParentDirectoryForFile(
        AppSettingsService.keyLastGameplayDirectory,
        picked,
      );
    }
  }

  Future<void> _pickAudioDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выбор папки недоступен на мобильном. Скопируйте треки в папку приложения.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final initialDir = (_audioPath != null && _audioPath!.isNotEmpty)
        ? AppSettingsService.instance.getExistingDirectory(_audioPath!)
        : AppSettingsService.instance
            .getExistingDirectory(AppSettingsService.keyLastAudioDirectory);

    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Выберите папку с фоновыми MP3 треками',
      initialDirectory: initialDir,
    );

    if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
      setState(() {
        _audioPath = selectedDirectory;
      });
      await AppSettingsService.instance.setString(
        AppSettingsService.keyLastAudioDirectory,
        selectedDirectory,
      );
    }
  }

  Widget _buildBasisTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Режим заднего фона (Форматирование в 9:16)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Размытие (Blur background)'),
                subtitle: const Text(
                  'Масштабирует и сильно размывает то же самое видео на заднем фоне сверху и снизу.',
                ),
                leading: Icon(
                  _bgMode == BackgroundMode.blur
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _bgMode == BackgroundMode.blur
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                onTap: () {
                  setState(() => _bgMode = BackgroundMode.blur);
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Залипательное видео (Split-Screen геймплей)'),
                subtitle: const Text(
                  'Помещает основной фильм в верхнюю половину экрана (1080x960), а снизу добавляет геймплей GTA V / Minecraft.',
                ),
                leading: Icon(
                  _bgMode == BackgroundMode.splitScreen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _bgMode == BackgroundMode.splitScreen
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                onTap: () {
                  setState(() => _bgMode = BackgroundMode.splitScreen);
                },
              ),
              if (_bgMode == BackgroundMode.splitScreen) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Видеофайл геймплея (низ кадра):',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _gameplayVideoPath ?? 'Файл не выбран (нужно выбрать .mp4)',
                              style: TextStyle(
                                color: _gameplayVideoPath != null ? Colors.white70 : Colors.orangeAccent,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.videogame_asset, size: 16),
                        label: const Text('Выбрать'),
                        onPressed: _pickGameplayVideoFile,
                      ),
                      if (_gameplayVideoPath != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          tooltip: 'Очистить',
                          onPressed: () => setState(() => _gameplayVideoPath = null),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Геометрическая уникализация',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Зеркалить видео по горизонтали (hflip)'),
            subtitle: const Text(
              'Разворачивает видеокадр слева направо. Эффективно снижает шанс распознавания залива алгоритмами TikTok/Reels.',
            ),
            value: _isMirrored,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              setState(() => _isMirrored = val);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUniquenessTab() {
    final speedPercent = (_speedDelta * 100).toStringAsFixed(1);
    final colorPercent = (_colorDelta * 100).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Рандомизация параметров (Обход дубликатов)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Изменение скорости видео и аудио:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_speedDelta >= 0 ? '+' : ''}$speedPercent%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ускоряет или замедляет ролик (фильтры setpts и atempo), полностью изменяя аудиовизуальный хэш.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Slider(
                  value: _speedDelta,
                  min: -0.20,
                  max: 0.20,
                  divisions: 40,
                  label: '${_speedDelta >= 0 ? '+' : ''}$speedPercent%',
                  onChanged: (val) {
                    setState(() => _speedDelta = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Цветовая коррекция (Яркость / Контраст):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '±$colorPercent%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Случайно смещает оттенки и гамму каждого кадра в заданном диапазоне (фильтр eq).',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Slider(
                  value: _colorDelta,
                  min: 0.0,
                  max: 0.10,
                  divisions: 20,
                  label: '±$colorPercent%',
                  onChanged: (val) {
                    setState(() => _colorDelta = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Уровень невидимого цифрового шума:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_noiseLevel.toStringAsFixed(1)} / 5.0',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Накладывает незаметный глазам микро-шум на каждый пиксель (фильтр noise), ломая нейросетевые детекторы видео.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Slider(
                  value: _noiseLevel,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  label: _noiseLevel.toStringAsFixed(1),
                  onChanged: (val) {
                    setState(() => _noiseLevel = val);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlaysTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Рекламная плашка / Водяной знак',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.branding_watermark_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              _bannerPath == null || _bannerPath!.isEmpty
                  ? 'Файл плашки не выбран'
                  : _bannerPath!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _bannerPath == null ? Colors.grey : Colors.white,
                fontSize: 14,
              ),
            ),
            subtitle: const Text('Форматы MP4 (зацикленный оверлей) или PNG (картинка)'),
            trailing: IconTheme(
              data: const IconThemeData(size: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_bannerPath != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => setState(() => _bannerPath = null),
                      visualDensity: VisualDensity.compact,
                    ),
                  TextButton(
                    onPressed: _pickBannerFile,
                    child: const Text('Обзор'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Позиция Текстового Хука и Заголовка',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textHookController,
                  decoration: const InputDecoration(
                    labelText: 'Текст для настройки позиции на предпросмотре',
                    hintText: 'Например: ЗАГОЛОВОК ВИДЕО (ХУК)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡 Индивидуальный заголовок для каждого ролика задаётся в очереди на главном экране (или списком). Здесь вы настраиваете положение плашки на кадре 9:16.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            title: const Text('Авто-нумерация частей ("Часть 1", "Часть 2")'),
            subtitle: const Text(
              'Автоматически прикрепляет текст с номером текущей нарезки при распиле сериала или фильма.',
            ),
            value: _autoNumbering,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              setState(() => _autoNumbering = val);
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Позицию плашки, пример субтитров и нумерацию смотрите во вкладке «Предпросмотр».',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTab() {
    final tasks = ref.watch(taskQueueProvider);
    String? previewVideoPath;
    for (final task in tasks) {
      final p = task.inputFilePath;
      if (p.isNotEmpty && File(p).existsSync()) {
        previewVideoPath = p;
        break;
      }
    }

    final sampleHook = _textHookController.text.trim().isNotEmpty
        ? _textHookController.text.trim()
        : 'Он не ожидал такого поворота...';

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Предпросмотр 9:16 (редактируемый)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Все элементы (плашка, хук, нумерация, субтитры) можно тянуть мышью/пальцем — они поедут за вашими движениями и сохранятся в шаблон.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        FullPreviewEditor(
          previewVideoPath: previewVideoPath,
          bannerPath: _bannerPath,
          bannerXRatio: _bannerXRatio,
          bannerYRatio: _bannerYRatio,
          bannerWidthRatio: _bannerWidthRatio,
          bannerHeightRatio: _bannerHeightRatio,
          onBannerChanged: (x, y, w, h) {
            setState(() {
              _bannerXRatio = x;
              _bannerYRatio = y;
              _bannerWidthRatio = w;
              _bannerHeightRatio = h;
              if (y < 0.4) {
                _bannerPosition = BannerPosition.top;
              } else {
                _bannerPosition = BannerPosition.bottom;
              }
            });
          },
          textHook: sampleHook,
          textHookYRatio: _textHookYRatio,
          onTextHookYChanged: (v) => setState(() => _textHookYRatio = v),
          autoNumbering: _autoNumbering,
          numberingYRatio: _numberingYRatio,
          onNumberingYChanged: (v) => setState(() => _numberingYRatio = v),
          showSubtitles: _useWhisper,
          subtitleYRatio: _subtitleYRatio,
          onSubtitleYChanged: (v) => setState(() => _subtitleYRatio = v),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Что двигать:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                _legendRow(Icons.title, 'Текст крючка — сверху (белая строка)'),
                if (_autoNumbering)
                  _legendRow(Icons.tag, '«Часть N» — под хуком (розовая рамка)'),
                _legendRow(Icons.branding_watermark, 'Плашка — синяя рамка (ресайз — синий кружок под ней)'),
                if (_useWhisper)
                  _legendRow(Icons.subtitles, 'Субтитры — зелёная рамка'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTab() {
    final volumePercent = (_audioVolume * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Фоновая музыка (Lo-Fi / Phonk)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.library_music_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              _audioPath == null || _audioPath!.isEmpty
                  ? 'Папка с MP3 музыкой не выбрана'
                  : _audioPath!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _audioPath == null ? Colors.grey : Colors.white,
                fontSize: 14,
              ),
            ),
            subtitle: const Text('Из этой папки будет случайно выбираться трек без авторских прав.'),
            trailing: IconTheme(
              data: const IconThemeData(size: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_audioPath != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => setState(() => _audioPath = null),
                      visualDensity: VisualDensity.compact,
                    ),
                  TextButton(
                    onPressed: _pickAudioDirectory,
                    child: const Text('Папка'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Громкость фоновой музыки:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$volumePercent%',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Музыка подмешивается к основному видео на заднем плане (рекомендуется 5-10%).',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Slider(
                  value: _audioVolume,
                  min: 0.0,
                  max: 0.30,
                  divisions: 30,
                  label: '$volumePercent%',
                  onChanged: (val) {
                    setState(() => _audioVolume = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Нейросетевые субтитры',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Авто-субтитры (Whisper AI Karaoke)'),
            subtitle: const Text(
              'Локальная оффлайн-генерация динамических караоке-субтитров с пословной подсветкой слов.',
            ),
            value: _useWhisper,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              setState(() => _useWhisper = val);
            },
          ),
        ),
        if (_useWhisper) ...[
          const SizedBox(height: 12),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 12, right: 16),
                  child: Text(
                    'Положение караоке-субтитров на экране',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioGroup<SubtitlePosition>(
                  groupValue: _subtitlePosition,
                  onChanged: (val) {
                    if (val != null) setState(() => _subtitlePosition = val);
                  },
                  child: const Column(
                    children: [
                      RadioListTile<SubtitlePosition>(
                        title: Text('Снизу (стандарт TikTok / Shorts)'),
                        value: SubtitlePosition.bottom,
                      ),
                      RadioListTile<SubtitlePosition>(
                        title: Text('По центру экрана'),
                        value: SubtitlePosition.center,
                      ),
                      RadioListTile<SubtitlePosition>(
                        title: Text('Сверху'),
                        value: SubtitlePosition.top,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.presetToEdit == null
            ? 'Создание Шаблона'
            : 'Редактирование Шаблона'),
        actions: [
          if (widget.presetToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Удалить шаблон',
              onPressed: _deletePreset,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Сохранить Шаблон',
            onPressed: _savePreset,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'Основа'),
            Tab(icon: Icon(Icons.security), text: 'Уникализация'),
            Tab(icon: Icon(Icons.layers), text: 'Оверлеи'),
            Tab(icon: Icon(Icons.audiotrack), text: 'Аудио'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Предпросмотр'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Top Preset Name Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название шаблона',
                  hintText: 'Например: TikTok Shorts (Blur + Music)',
                  prefixIcon: Icon(Icons.bookmark_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название шаблона';
                  }
                  return null;
                },
              ),
            ),

            // TabBarView Content Pages
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Basis
                  _buildBasisTab(),

                  // Tab 2: Unique/Anti-fraud
                  _buildUniquenessTab(),

                  // Tab 3: Overlays & Text
                  _buildOverlaysTab(),

                  // Tab 4: Audio & Subtitles
                  _buildAudioTab(),

                  // Tab 5: Preview
                  _buildPreviewTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
