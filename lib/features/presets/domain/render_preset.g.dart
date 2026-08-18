// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'render_preset.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRenderPresetCollection on Isar {
  IsarCollection<RenderPreset> get renderPresets => this.collection();
}

const RenderPresetSchema = CollectionSchema(
  name: r'RenderPreset',
  id: 8775103300980658858,
  properties: {
    r'audioPath': PropertySchema(
      id: 0,
      name: r'audioPath',
      type: IsarType.string,
    ),
    r'audioVolume': PropertySchema(
      id: 1,
      name: r'audioVolume',
      type: IsarType.double,
    ),
    r'autoNumbering': PropertySchema(
      id: 2,
      name: r'autoNumbering',
      type: IsarType.bool,
    ),
    r'bannerHeightRatio': PropertySchema(
      id: 3,
      name: r'bannerHeightRatio',
      type: IsarType.double,
    ),
    r'bannerPath': PropertySchema(
      id: 4,
      name: r'bannerPath',
      type: IsarType.string,
    ),
    r'bannerPosition': PropertySchema(
      id: 5,
      name: r'bannerPosition',
      type: IsarType.byte,
      enumMap: _RenderPresetbannerPositionEnumValueMap,
    ),
    r'bannerWidthRatio': PropertySchema(
      id: 6,
      name: r'bannerWidthRatio',
      type: IsarType.double,
    ),
    r'bannerXRatio': PropertySchema(
      id: 7,
      name: r'bannerXRatio',
      type: IsarType.double,
    ),
    r'bannerYRatio': PropertySchema(
      id: 8,
      name: r'bannerYRatio',
      type: IsarType.double,
    ),
    r'bgMode': PropertySchema(
      id: 9,
      name: r'bgMode',
      type: IsarType.byte,
      enumMap: _RenderPresetbgModeEnumValueMap,
    ),
    r'colorDelta': PropertySchema(
      id: 10,
      name: r'colorDelta',
      type: IsarType.double,
    ),
    r'gameplayVideoPath': PropertySchema(
      id: 11,
      name: r'gameplayVideoPath',
      type: IsarType.string,
    ),
    r'hashCode': PropertySchema(
      id: 12,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'isMirrored': PropertySchema(
      id: 13,
      name: r'isMirrored',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 14,
      name: r'name',
      type: IsarType.string,
    ),
    r'noiseLevel': PropertySchema(
      id: 15,
      name: r'noiseLevel',
      type: IsarType.double,
    ),
    r'numberingYRatio': PropertySchema(
      id: 16,
      name: r'numberingYRatio',
      type: IsarType.double,
    ),
    r'showSubtitles': PropertySchema(
      id: 17,
      name: r'showSubtitles',
      type: IsarType.bool,
    ),
    r'speedDelta': PropertySchema(
      id: 18,
      name: r'speedDelta',
      type: IsarType.double,
    ),
    r'subtitlePosition': PropertySchema(
      id: 19,
      name: r'subtitlePosition',
      type: IsarType.byte,
      enumMap: _RenderPresetsubtitlePositionEnumValueMap,
    ),
    r'subtitleYRatio': PropertySchema(
      id: 20,
      name: r'subtitleYRatio',
      type: IsarType.double,
    ),
    r'textHook': PropertySchema(
      id: 21,
      name: r'textHook',
      type: IsarType.string,
    ),
    r'textHookYRatio': PropertySchema(
      id: 22,
      name: r'textHookYRatio',
      type: IsarType.double,
    ),
    r'useWhisper': PropertySchema(
      id: 23,
      name: r'useWhisper',
      type: IsarType.bool,
    )
  },
  estimateSize: _renderPresetEstimateSize,
  serialize: _renderPresetSerialize,
  deserialize: _renderPresetDeserialize,
  deserializeProp: _renderPresetDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _renderPresetGetId,
  getLinks: _renderPresetGetLinks,
  attach: _renderPresetAttach,
  version: '3.1.0+1',
);

int _renderPresetEstimateSize(
  RenderPreset object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.audioPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.bannerPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.gameplayVideoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.textHook;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _renderPresetSerialize(
  RenderPreset object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.audioPath);
  writer.writeDouble(offsets[1], object.audioVolume);
  writer.writeBool(offsets[2], object.autoNumbering);
  writer.writeDouble(offsets[3], object.bannerHeightRatio);
  writer.writeString(offsets[4], object.bannerPath);
  writer.writeByte(offsets[5], object.bannerPosition.index);
  writer.writeDouble(offsets[6], object.bannerWidthRatio);
  writer.writeDouble(offsets[7], object.bannerXRatio);
  writer.writeDouble(offsets[8], object.bannerYRatio);
  writer.writeByte(offsets[9], object.bgMode.index);
  writer.writeDouble(offsets[10], object.colorDelta);
  writer.writeString(offsets[11], object.gameplayVideoPath);
  writer.writeLong(offsets[12], object.hashCode);
  writer.writeBool(offsets[13], object.isMirrored);
  writer.writeString(offsets[14], object.name);
  writer.writeDouble(offsets[15], object.noiseLevel);
  writer.writeDouble(offsets[16], object.numberingYRatio);
  writer.writeBool(offsets[17], object.showSubtitles);
  writer.writeDouble(offsets[18], object.speedDelta);
  writer.writeByte(offsets[19], object.subtitlePosition.index);
  writer.writeDouble(offsets[20], object.subtitleYRatio);
  writer.writeString(offsets[21], object.textHook);
  writer.writeDouble(offsets[22], object.textHookYRatio);
  writer.writeBool(offsets[23], object.useWhisper);
}

RenderPreset _renderPresetDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RenderPreset();
  object.audioPath = reader.readStringOrNull(offsets[0]);
  object.audioVolume = reader.readDouble(offsets[1]);
  object.autoNumbering = reader.readBool(offsets[2]);
  object.bannerHeightRatio = reader.readDoubleOrNull(offsets[3]);
  object.bannerPath = reader.readStringOrNull(offsets[4]);
  object.bannerPosition = _RenderPresetbannerPositionValueEnumMap[
          reader.readByteOrNull(offsets[5])] ??
      BannerPosition.top;
  object.bannerWidthRatio = reader.readDoubleOrNull(offsets[6]);
  object.bannerXRatio = reader.readDoubleOrNull(offsets[7]);
  object.bannerYRatio = reader.readDoubleOrNull(offsets[8]);
  object.bgMode =
      _RenderPresetbgModeValueEnumMap[reader.readByteOrNull(offsets[9])] ??
          BackgroundMode.blur;
  object.colorDelta = reader.readDouble(offsets[10]);
  object.gameplayVideoPath = reader.readStringOrNull(offsets[11]);
  object.id = id;
  object.isMirrored = reader.readBool(offsets[13]);
  object.name = reader.readString(offsets[14]);
  object.noiseLevel = reader.readDouble(offsets[15]);
  object.numberingYRatio = reader.readDouble(offsets[16]);
  object.showSubtitles = reader.readBool(offsets[17]);
  object.speedDelta = reader.readDouble(offsets[18]);
  object.subtitlePosition = _RenderPresetsubtitlePositionValueEnumMap[
          reader.readByteOrNull(offsets[19])] ??
      SubtitlePosition.top;
  object.subtitleYRatio = reader.readDouble(offsets[20]);
  object.textHook = reader.readStringOrNull(offsets[21]);
  object.textHookYRatio = reader.readDouble(offsets[22]);
  object.useWhisper = reader.readBool(offsets[23]);
  return object;
}

P _renderPresetDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (_RenderPresetbannerPositionValueEnumMap[
              reader.readByteOrNull(offset)] ??
          BannerPosition.top) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (_RenderPresetbgModeValueEnumMap[reader.readByteOrNull(offset)] ??
          BackgroundMode.blur) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readDouble(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (_RenderPresetsubtitlePositionValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SubtitlePosition.top) as P;
    case 20:
      return (reader.readDouble(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readDouble(offset)) as P;
    case 23:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RenderPresetbannerPositionEnumValueMap = {
  'top': 0,
  'bottom': 1,
};
const _RenderPresetbannerPositionValueEnumMap = {
  0: BannerPosition.top,
  1: BannerPosition.bottom,
};
const _RenderPresetbgModeEnumValueMap = {
  'blur': 0,
  'splitScreen': 1,
};
const _RenderPresetbgModeValueEnumMap = {
  0: BackgroundMode.blur,
  1: BackgroundMode.splitScreen,
};
const _RenderPresetsubtitlePositionEnumValueMap = {
  'top': 0,
  'center': 1,
  'bottom': 2,
};
const _RenderPresetsubtitlePositionValueEnumMap = {
  0: SubtitlePosition.top,
  1: SubtitlePosition.center,
  2: SubtitlePosition.bottom,
};

Id _renderPresetGetId(RenderPreset object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _renderPresetGetLinks(RenderPreset object) {
  return [];
}

void _renderPresetAttach(
    IsarCollection<dynamic> col, Id id, RenderPreset object) {
  object.id = id;
}

extension RenderPresetQueryWhereSort
    on QueryBuilder<RenderPreset, RenderPreset, QWhere> {
  QueryBuilder<RenderPreset, RenderPreset, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RenderPresetQueryWhere
    on QueryBuilder<RenderPreset, RenderPreset, QWhereClause> {
  QueryBuilder<RenderPreset, RenderPreset, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterWhereClause> idBetween(
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

extension RenderPresetQueryFilter
    on QueryBuilder<RenderPreset, RenderPreset, QFilterCondition> {
  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'audioPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'audioPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'audioPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'audioPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'audioPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioVolumeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'audioVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioVolumeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'audioVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioVolumeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'audioVolume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      audioVolumeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'audioVolume',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      autoNumberingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoNumbering',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bannerHeightRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bannerHeightRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerHeightRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerHeightRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerHeightRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerHeightRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerHeightRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bannerPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bannerPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bannerPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bannerPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bannerPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPositionEqualTo(BannerPosition value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPositionGreaterThan(
    BannerPosition value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPositionLessThan(
    BannerPosition value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerPosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerPositionBetween(
    BannerPosition lower,
    BannerPosition upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerPosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bannerWidthRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bannerWidthRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerWidthRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerWidthRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerWidthRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerWidthRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerWidthRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bannerXRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bannerXRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerXRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerXRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerXRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerXRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerXRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bannerYRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bannerYRatio',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bannerYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bannerYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bannerYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bannerYRatioBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bannerYRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> bgModeEqualTo(
      BackgroundMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bgMode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bgModeGreaterThan(
    BackgroundMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bgMode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      bgModeLessThan(
    BackgroundMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bgMode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> bgModeBetween(
    BackgroundMode lower,
    BackgroundMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bgMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      colorDeltaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'colorDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      colorDeltaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'colorDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      colorDeltaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'colorDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      colorDeltaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'colorDelta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gameplayVideoPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gameplayVideoPath',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gameplayVideoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gameplayVideoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gameplayVideoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gameplayVideoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      gameplayVideoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gameplayVideoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> idBetween(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      isMirroredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMirrored',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      noiseLevelEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noiseLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      noiseLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noiseLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      noiseLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noiseLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      noiseLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noiseLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      numberingYRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'numberingYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      numberingYRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'numberingYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      numberingYRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'numberingYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      numberingYRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'numberingYRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      showSubtitlesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'showSubtitles',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      speedDeltaEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speedDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      speedDeltaGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speedDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      speedDeltaLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speedDelta',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      speedDeltaBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speedDelta',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitlePositionEqualTo(SubtitlePosition value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitlePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitlePositionGreaterThan(
    SubtitlePosition value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtitlePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitlePositionLessThan(
    SubtitlePosition value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtitlePosition',
        value: value,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitlePositionBetween(
    SubtitlePosition lower,
    SubtitlePosition upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtitlePosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitleYRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subtitleYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitleYRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subtitleYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitleYRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subtitleYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      subtitleYRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subtitleYRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'textHook',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'textHook',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookEqualTo(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookGreaterThan(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookLessThan(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookBetween(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookStartsWith(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookEndsWith(
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

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textHook',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textHook',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHook',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textHook',
        value: '',
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookYRatioEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textHookYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookYRatioGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textHookYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookYRatioLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textHookYRatio',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      textHookYRatioBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textHookYRatio',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterFilterCondition>
      useWhisperEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useWhisper',
        value: value,
      ));
    });
  }
}

extension RenderPresetQueryObject
    on QueryBuilder<RenderPreset, RenderPreset, QFilterCondition> {}

extension RenderPresetQueryLinks
    on QueryBuilder<RenderPreset, RenderPreset, QFilterCondition> {}

extension RenderPresetQuerySortBy
    on QueryBuilder<RenderPreset, RenderPreset, QSortBy> {
  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByAudioPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByAudioPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByAudioVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioVolume', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByAudioVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioVolume', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByAutoNumbering() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoNumbering', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByAutoNumberingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoNumbering', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerHeightRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerHeightRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerHeightRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerHeightRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByBannerPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPosition', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPosition', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerWidthRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerWidthRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerWidthRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerWidthRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByBannerXRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerXRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerXRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerXRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByBannerYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByBannerYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByBgMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bgMode', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByBgModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bgMode', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByColorDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorDelta', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByColorDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorDelta', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByGameplayVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameplayVideoPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByGameplayVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameplayVideoPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByIsMirrored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMirrored', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByIsMirroredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMirrored', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByNoiseLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseLevel', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByNoiseLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseLevel', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByNumberingYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberingYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByNumberingYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberingYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByShowSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitles', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByShowSubtitlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitles', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortBySpeedDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedDelta', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortBySpeedDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedDelta', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortBySubtitlePosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitlePosition', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortBySubtitlePositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitlePosition', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortBySubtitleYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortBySubtitleYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByTextHook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByTextHookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByTextHookYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHookYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByTextHookYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHookYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> sortByUseWhisper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useWhisper', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      sortByUseWhisperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useWhisper', Sort.desc);
    });
  }
}

extension RenderPresetQuerySortThenBy
    on QueryBuilder<RenderPreset, RenderPreset, QSortThenBy> {
  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByAudioPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByAudioPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByAudioVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioVolume', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByAudioVolumeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'audioVolume', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByAutoNumbering() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoNumbering', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByAutoNumberingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoNumbering', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerHeightRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerHeightRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerHeightRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerHeightRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByBannerPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPosition', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerPosition', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerWidthRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerWidthRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerWidthRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerWidthRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByBannerXRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerXRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerXRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerXRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByBannerYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByBannerYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bannerYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByBgMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bgMode', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByBgModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bgMode', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByColorDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorDelta', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByColorDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorDelta', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByGameplayVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameplayVideoPath', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByGameplayVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gameplayVideoPath', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByHashCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hashCode', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByIsMirrored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMirrored', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByIsMirroredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMirrored', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByNoiseLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseLevel', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByNoiseLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noiseLevel', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByNumberingYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberingYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByNumberingYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'numberingYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByShowSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitles', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByShowSubtitlesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'showSubtitles', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenBySpeedDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedDelta', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenBySpeedDeltaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedDelta', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenBySubtitlePosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitlePosition', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenBySubtitlePositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitlePosition', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenBySubtitleYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenBySubtitleYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitleYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByTextHook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByTextHookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHook', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByTextHookYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHookYRatio', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByTextHookYRatioDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'textHookYRatio', Sort.desc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy> thenByUseWhisper() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useWhisper', Sort.asc);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QAfterSortBy>
      thenByUseWhisperDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useWhisper', Sort.desc);
    });
  }
}

extension RenderPresetQueryWhereDistinct
    on QueryBuilder<RenderPreset, RenderPreset, QDistinct> {
  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByAudioPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByAudioVolume() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioVolume');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByAutoNumbering() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoNumbering');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByBannerHeightRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerHeightRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByBannerPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByBannerPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerPosition');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByBannerWidthRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerWidthRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByBannerXRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerXRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByBannerYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bannerYRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByBgMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bgMode');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByColorDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorDelta');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByGameplayVideoPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gameplayVideoPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByHashCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hashCode');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByIsMirrored() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMirrored');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByNoiseLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noiseLevel');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByNumberingYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'numberingYRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByShowSubtitles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'showSubtitles');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctBySpeedDelta() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speedDelta');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctBySubtitlePosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitlePosition');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctBySubtitleYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitleYRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByTextHook(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textHook', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct>
      distinctByTextHookYRatio() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'textHookYRatio');
    });
  }

  QueryBuilder<RenderPreset, RenderPreset, QDistinct> distinctByUseWhisper() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useWhisper');
    });
  }
}

extension RenderPresetQueryProperty
    on QueryBuilder<RenderPreset, RenderPreset, QQueryProperty> {
  QueryBuilder<RenderPreset, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RenderPreset, String?, QQueryOperations> audioPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioPath');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations> audioVolumeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioVolume');
    });
  }

  QueryBuilder<RenderPreset, bool, QQueryOperations> autoNumberingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoNumbering');
    });
  }

  QueryBuilder<RenderPreset, double?, QQueryOperations>
      bannerHeightRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerHeightRatio');
    });
  }

  QueryBuilder<RenderPreset, String?, QQueryOperations> bannerPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerPath');
    });
  }

  QueryBuilder<RenderPreset, BannerPosition, QQueryOperations>
      bannerPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerPosition');
    });
  }

  QueryBuilder<RenderPreset, double?, QQueryOperations>
      bannerWidthRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerWidthRatio');
    });
  }

  QueryBuilder<RenderPreset, double?, QQueryOperations> bannerXRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerXRatio');
    });
  }

  QueryBuilder<RenderPreset, double?, QQueryOperations> bannerYRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bannerYRatio');
    });
  }

  QueryBuilder<RenderPreset, BackgroundMode, QQueryOperations>
      bgModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bgMode');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations> colorDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorDelta');
    });
  }

  QueryBuilder<RenderPreset, String?, QQueryOperations>
      gameplayVideoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gameplayVideoPath');
    });
  }

  QueryBuilder<RenderPreset, int, QQueryOperations> hashCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hashCode');
    });
  }

  QueryBuilder<RenderPreset, bool, QQueryOperations> isMirroredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMirrored');
    });
  }

  QueryBuilder<RenderPreset, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations> noiseLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noiseLevel');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations>
      numberingYRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'numberingYRatio');
    });
  }

  QueryBuilder<RenderPreset, bool, QQueryOperations> showSubtitlesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'showSubtitles');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations> speedDeltaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speedDelta');
    });
  }

  QueryBuilder<RenderPreset, SubtitlePosition, QQueryOperations>
      subtitlePositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitlePosition');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations>
      subtitleYRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitleYRatio');
    });
  }

  QueryBuilder<RenderPreset, String?, QQueryOperations> textHookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textHook');
    });
  }

  QueryBuilder<RenderPreset, double, QQueryOperations>
      textHookYRatioProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'textHookYRatio');
    });
  }

  QueryBuilder<RenderPreset, bool, QQueryOperations> useWhisperProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useWhisper');
    });
  }
}
