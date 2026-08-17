import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/presets/domain/render_preset.dart';
import '../../features/presets/presentation/preset_editor_screen.dart';
import '../../features/trimmer/presentation/trimmer_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/preset-editor',
      builder: (context, state) {
        final preset = state.extra as RenderPreset?;
        return PresetEditorScreen(presetToEdit: preset);
      },
    ),
    GoRoute(
      path: '/trimmer',
      builder: (context, state) {
        final videoPath = state.extra as String? ?? '';
        return TrimmerScreen(videoPath: videoPath);
      },
    ),
  ],
);
