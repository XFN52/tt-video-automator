import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/render_preset.dart';

final presetListProvider =
    FutureProvider.autoDispose<List<RenderPreset>>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  final presets = await isarService.getAllPresets();

  if (presets.isEmpty) {
    final defaultPreset = RenderPreset()
      ..name = 'Базовый (Blur + Unique)'
      ..bgMode = BackgroundMode.blur
      ..isMirrored = false
      ..speedDelta = 0.02
      ..colorDelta = 0.03
      ..noiseLevel = 1.0
      ..autoNumbering = true
      ..audioVolume = 0.08;

    final id = await isarService.savePreset(defaultPreset);
    defaultPreset.id = id;
    return [defaultPreset];
  }

  return presets;
});

// Без autoDispose: выбранный пресет не должен теряться при навигации
// (дашборд → редактор пресетов/триммер → назад)
final selectedPresetProvider =
    StateProvider<RenderPreset?>((ref) => null);
