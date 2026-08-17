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
  BannerPosition bannerPosition = BannerPosition.top;

  @enumerated
  SubtitlePosition subtitlePosition = SubtitlePosition.bottom;

  bool isMirrored = false;
  double speedDelta = 0.02;
  double colorDelta = 0.03;
  double noiseLevel = 1.0;
  String? bannerPath;
  double? bannerXRatio = 0.0;
  double? bannerYRatio = 0.122;
  double? bannerWidthRatio = 1.0;
  double? bannerHeightRatio = 0.161;
  String? textHook;
  bool autoNumbering = true;
  String? audioPath;
  String? gameplayVideoPath;
  bool useWhisper = true;
  double audioVolume = 0.08;

  // Интерактивные позиции предпросмотра, все в долях от высоты кадра [0..1].
  // Храним явно, так как enum SubtitlePosition сохранён в БД и совместимость
  // ломать нельзя — при чтении используем эти точные значения, при записи
  // округляем до ближайшего enum-значения для обратной совместимости с
  // остальным пайплайном (ASS writer работает по top/center/bottom).
  double textHookYRatio = 0.686;   // хук снизу на 68.6%
  double numberingYRatio = 0.033;  // "Часть N" вверху на 3.3%
  double subtitleYRatio = 0.877;   // субтитры внизу на 87.7%

  // Equality по id — нужен DropdownButtonFormField (initialValue ищется
  // по == среди items): иначе выбор пресета в списке визуально терялся.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RenderPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
