import 'package:isar/isar.dart';

part 'render_preset.g.dart';

enum BackgroundMode { blur, splitScreen }
enum BannerPosition { top, bottom }
enum SubtitlePosition { top, center, bottom }

@collection
class RenderPreset {
  Id id = Isar.autoIncrement;

  late String name;

  @enumerated
  BackgroundMode bgMode = BackgroundMode.blur;

  @enumerated
  BannerPosition bannerPosition = BannerPosition.bottom;

  @enumerated
  SubtitlePosition subtitlePosition = SubtitlePosition.bottom;

  bool isMirrored = false;
  double speedDelta = 0.02;
  double colorDelta = 0.03;
  double noiseLevel = 1.0;
  String? bannerPath;
  double? bannerXRatio;
  double? bannerYRatio;
  double? bannerWidthRatio;
  double? bannerHeightRatio;
  String? textHook;
  bool autoNumbering = true;
  String? audioPath;
  String? gameplayVideoPath;
  bool useWhisper = false;
  double audioVolume = 0.08;

  // Интерактивные позиции предпросмотра, все в долях от высоты кадра [0..1].
  // Храним явно, так как enum SubtitlePosition сохранён в БД и совместимость
  // ломать нельзя — при чтении используем эти точные значения, при записи
  // округляем до ближайшего enum-значения для обратной совместимости с
  // остальным пайплайном (ASS writer работает по top/center/bottom).
  double textHookYRatio = 0.04;   // глубина сверху
  double numberingYRatio = 0.12;  // "Часть N" под хуком
  double subtitleYRatio = 0.75;   // снизу по умолчанию

  // Equality по id — нужен DropdownButtonFormField (initialValue ищется
  // по == среди items): иначе выбор пресета в списке визуально терялся.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RenderPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
