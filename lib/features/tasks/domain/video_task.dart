import 'package:isar/isar.dart';

part 'video_task.g.dart';

enum TaskStatus { pending, analyzing, processing, success, failed }

@Name('T_43700')
@collection
class VideoTask {
  Id id = Isar.autoIncrement;

  late String inputFilePath;
  late String outputFolderPath;

  @enumerated
  TaskStatus status = TaskStatus.pending;

  double progress = 0.0;
  String? errorMsg;

  String? startTime;
  String? endTime;
  int? partNumber;
}
