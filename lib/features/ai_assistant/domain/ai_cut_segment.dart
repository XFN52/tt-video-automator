class AiCutSegment {
  final String startTime;
  final String endTime;
  final int partNumber;
  final String hook;
  final String? summary;

  const AiCutSegment({
    required this.startTime,
    required this.endTime,
    required this.partNumber,
    required this.hook,
    this.summary,
  });

  factory AiCutSegment.fromJson(Map<String, dynamic> json, int defaultPart) {
    return AiCutSegment(
      startTime: json['start_time'] as String? ?? json['startTime'] as String? ?? '00:00:00',
      endTime: json['end_time'] as String? ?? json['endTime'] as String? ?? '00:01:00',
      partNumber: (json['part_number'] as num?)?.toInt() ?? (json['partNumber'] as num?)?.toInt() ?? defaultPart,
      hook: json['hook'] as String? ?? json['title'] as String? ?? 'Часть $defaultPart',
      summary: json['summary'] as String? ?? json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'start_time': startTime,
        'end_time': endTime,
        'part_number': partNumber,
        'hook': hook,
        if (summary != null) 'summary': summary,
      };
}
