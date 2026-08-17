// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_task.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVideoTaskCollection on Isar {
  IsarCollection<VideoTask> get videoTasks => this.collection();
}

const VideoTaskSchema = CollectionSchema(
  name: r'T_43700',
  id: 7802804282841357159,
  properties: {
    r'endTime': PropertySchema(
      id: 0,
      name: r'endTime',
      type: IsarType.string,
    ),
    r'errorMsg': PropertySchema(
      id: 1,
      name: r'errorMsg',
      type: IsarType.string,
    ),
    r'inputFilePath': PropertySchema(
      id: 2,
      name: r'inputFilePath',
      type: IsarType.string,
    ),
    r'outputFolderPath': PropertySchema(
      id: 3,
      name: r'outputFolderPath',
      type: IsarType.string,
    ),
    r'partNumber': PropertySchema(
      id: 4,
      name: r'partNumber',
      type: IsarType.long,
    ),
    r'progress': PropertySchema(
      id: 5,
      name: r'progress',
      type: IsarType.double,
    ),
    r'startTime': PropertySchema(
      id: 6,
      name: r'startTime',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.byte,
      enumMap: _VideoTaskstatusEnumValueMap,
    ),
    r'textHook': PropertySchema(
      id: 8,
      name: r'textHook',
      type: IsarType.string,
    )
  },
  estimateSize: _videoTaskEstimateSize,
  serialize: _videoTaskSerialize,
  deserialize: _videoTaskDeserialize,
  deserializeProp: _videoTaskDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _videoTaskGetId,
  getLinks: _videoTaskGetLinks,
  attach: _videoTaskAttach,
  version: '3.1.0+1',
);

int _videoTaskEstimateSize(
  VideoTask object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.endTime;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.errorMsg;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.inputFilePath.length * 3;
  bytesCount += 3 + object.outputFolderPath.length * 3;
  {
    final value = object.startTime;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.textHook;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _videoTaskSerialize(
  VideoTask object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.endTime);
  writer.writeString(offsets[1], object.errorMsg);
  writer.writeString(offsets[2], object.inputFilePath);
  writer.writeString(offsets[3], object.outputFolderPath);
  writer.writeLong(offsets[4], object.partNumber);
  writer.writeDouble(offsets[5], object.progress);
  writer.writeString(offsets[6], object.startTime);
  writer.writeByte(offsets[7], object.status.index);
  writer.writeString(offsets[8], object.textHook);
}

VideoTask _videoTaskDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VideoTask();
  object.endTime = reader.readStringOrNull(offsets[0]);
  object.errorMsg = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.inputFilePath = reader.readString(offsets[2]);
  object.outputFolderPath = reader.readString(offsets[3]);
  object.partNumber = reader.readLongOrNull(offsets[4]);
  object.progress = reader.readDouble(offsets[5]);
  object.startTime = reader.readStringOrNull(offsets[6]);
  object.status =
      _VideoTaskstatusValueEnumMap[reader.readByteOrNull(offsets[7])] ??
          TaskStatus.pending;
  object.textHook = reader.readStringOrNull(offsets[8]);
  return object;
}

P _videoTaskDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (_VideoTaskstatusValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskStatus.pending) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _VideoTaskstatusEnumValueMap = {
  'pending': 0,
  'analyzing': 1,
  'processing': 2,
  'success': 3,
  'failed': 4,
};
const _VideoTaskstatusValueEnumMap = {
  0: TaskStatus.pending,
  1: TaskStatus.analyzing,
  2: TaskStatus.processing,
  3: TaskStatus.success,
  4: TaskStatus.failed,
};

Id _videoTaskGetId(VideoTask object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _videoTaskGetLinks(VideoTask object) {
  return [];
}

void _videoTaskAttach(IsarCollection<dynamic> col, Id id, VideoTask object) {
  object.id = id;
}

extension VideoTaskQueryWhereSort
    on QueryBuilder<VideoTask, VideoTask, QWhere> {
  QueryBuilder<VideoTask, VideoTask, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VideoTaskQueryWhere
    on QueryBuilder<VideoTask, VideoTask, QWhereClause> {
  QueryBuilder<VideoTask, VideoTask, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VideoTaskQueryFilter
    on QueryBuilder<VideoTask, VideoTask, QFilterCondition> {
  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTime',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'endTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'endTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> endTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTime',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      endTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'endTime',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'errorMsg',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      errorMsgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'errorMsg',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'errorMsg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'errorMsg',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'errorMsg',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> errorMsgIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'errorMsg',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      errorMsgIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'errorMsg',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inputFilePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inputFilePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inputFilePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inputFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      inputFilePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inputFilePath',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'outputFolderPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'outputFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'outputFolderPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'outputFolderPath',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      outputFolderPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'outputFolderPath',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> partNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'partNumber',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      partNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'partNumber',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> partNumberEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'partNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      partNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'partNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> partNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'partNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> partNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'partNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> progressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> progressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> progressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'progress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> progressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'progress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      startTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startTime',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      startTimeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'startTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'startTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> startTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTime',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      startTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'startTime',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> statusEqualTo(
      TaskStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> statusGreaterThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> statusLessThan(
    TaskStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> statusBetween(
    TaskStatus lower,
    TaskStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'textHook',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      textHookIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'textHook',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textHook',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textHook',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition> textHookIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHook',
        value: '',
      ));
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterFilterCondition>
      textHookIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textHook',
        value: '',
      ));
    });
  }
}

extension VideoTaskQueryObject
    on QueryBuilder<VideoTask, VideoTask, QFilterCondition> {}

extension VideoTaskQueryLinks
    on QueryBuilder<VideoTask, VideoTask, QFilterCondition> {}

extension VideoTaskQuerySortBy on QueryBuilder<VideoTask, VideoTask, QSortBy> {
  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByErrorMsg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMsg', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByErrorMsgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMsg', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByInputFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputFilePath', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByInputFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputFilePath', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByOutputFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputFolderPath', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy>
      sortByOutputFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputFolderPath', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByPartNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNumber', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByPartNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNumber', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByTextHook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> sortByTextHookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.desc);
    });
  }
}

extension VideoTaskQuerySortThenBy
    on QueryBuilder<VideoTask, VideoTask, QSortThenBy> {
  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByEndTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByEndTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endTime', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByErrorMsg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMsg', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByErrorMsgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'errorMsg', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByInputFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputFilePath', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByInputFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inputFilePath', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByOutputFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputFolderPath', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy>
      thenByOutputFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'outputFolderPath', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByPartNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNumber', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByPartNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'partNumber', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByTextHook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.asc);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QAfterSortBy> thenByTextHookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.desc);
    });
  }
}

extension VideoTaskQueryWhereDistinct
    on QueryBuilder<VideoTask, VideoTask, QDistinct> {
  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByEndTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endTime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByErrorMsg(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'errorMsg', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByInputFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inputFilePath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByOutputFolderPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'outputFolderPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByPartNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'partNumber');
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByStartTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<VideoTask, VideoTask, QDistinct> distinctByTextHook(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textHook', caseSensitive: caseSensitive);
    });
  }
}

extension VideoTaskQueryProperty
    on QueryBuilder<VideoTask, VideoTask, QQueryProperty> {
  QueryBuilder<VideoTask, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<VideoTask, String?, QQueryOperations> endTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endTime');
    });
  }

  QueryBuilder<VideoTask, String?, QQueryOperations> errorMsgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'errorMsg');
    });
  }

  QueryBuilder<VideoTask, String, QQueryOperations> inputFilePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inputFilePath');
    });
  }

  QueryBuilder<VideoTask, String, QQueryOperations> outputFolderPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'outputFolderPath');
    });
  }

  QueryBuilder<VideoTask, int?, QQueryOperations> partNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'partNumber');
    });
  }

  QueryBuilder<VideoTask, double, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<VideoTask, String?, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<VideoTask, TaskStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<VideoTask, String?, QQueryOperations> textHookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textHook');
    });
  }
}
