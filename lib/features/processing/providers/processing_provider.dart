import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/batch_queue_manager.dart';
import '../services/ffmpeg_engine.dart';

final ffmpegEngineProvider = Provider<FfmpegEngine>((ref) {
  return FfmpegEngine();
});

final batchQueueManagerProvider = ChangeNotifierProvider<BatchQueueManager>((ref) {
  final engine = ref.watch(ffmpegEngineProvider);
  return BatchQueueManager(engine);
});
