// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confession_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConfessionEntryCollection on Isar {
  IsarCollection<ConfessionEntry> get confessions => this.collection();
}

const ConfessionEntrySchema = CollectionSchema(
  name: r'ConfessionEntry',
  id: -7357659382700038943,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'encryptedPayload': PropertySchema(
      id: 1,
      name: r'encryptedPayload',
      type: IsarType.longList,
    )
  },
  estimateSize: _confessionEntryEstimateSize,
  serialize: _confessionEntrySerialize,
  deserialize: _confessionEntryDeserialize,
  deserializeProp: _confessionEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _confessionEntryGetId,
  getLinks: _confessionEntryGetLinks,
  attach: _confessionEntryAttach,
  version: '3.1.0+1',
);

int _confessionEntryEstimateSize(
  ConfessionEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.encryptedPayload.length * 8;
  return bytesCount;
}

void _confessionEntrySerialize(
  ConfessionEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLongList(offsets[1], object.encryptedPayload);
}

ConfessionEntry _confessionEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConfessionEntry();
  object.date = reader.readDateTime(offsets[0]);
  object.encryptedPayload = reader.readLongList(offsets[1]) ?? [];
  object.id = id;
  return object;
}

P _confessionEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _confessionEntryGetId(ConfessionEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _confessionEntryGetLinks(ConfessionEntry object) {
  return [];
}

void _confessionEntryAttach(
    IsarCollection<dynamic> col, Id id, ConfessionEntry object) {
  object.id = id;
}

extension ConfessionEntryQueryWhereSort
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QWhere> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension ConfessionEntryQueryWhere
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QWhereClause> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause>
      dateNotEqualTo(DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause>
      dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause>
      dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ConfessionEntryQueryFilter
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QFilterCondition> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      dateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'encryptedPayload',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'encryptedPayload',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'encryptedPayload',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'encryptedPayload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      encryptedPayloadLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'encryptedPayload',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterFilterCondition>
      idBetween(
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
}

extension ConfessionEntryQueryObject
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QFilterCondition> {}

extension ConfessionEntryQueryLinks
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QFilterCondition> {}

extension ConfessionEntryQuerySortBy
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QSortBy> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy>
      sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }
}

extension ConfessionEntryQuerySortThenBy
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QSortThenBy> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy>
      thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension ConfessionEntryQueryWhereDistinct
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QDistinct> {
  QueryBuilder<ConfessionEntry, ConfessionEntry, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<ConfessionEntry, ConfessionEntry, QDistinct>
      distinctByEncryptedPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'encryptedPayload');
    });
  }
}

extension ConfessionEntryQueryProperty
    on QueryBuilder<ConfessionEntry, ConfessionEntry, QQueryProperty> {
  QueryBuilder<ConfessionEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConfessionEntry, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<ConfessionEntry, List<int>, QQueryOperations>
      encryptedPayloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'encryptedPayload');
    });
  }
}
