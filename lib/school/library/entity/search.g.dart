// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchHistoryItem _$SearchHistoryItemFromJson(Map<String, dynamic> json) => SearchHistoryItem(
      keyword: json['keyword'] as String,
      searchMethod: $enumDecode(_$SearchMethodEnumMap, json['searchMethod']),
      time: DateTime.parse(json['time'] as String),
    );

Map<String, dynamic> _$SearchHistoryItemToJson(SearchHistoryItem instance) => <String, dynamic>{
      'keyword': instance.keyword,
      'searchMethod': _$SearchMethodEnumMap[instance.searchMethod]!,
      'time': instance.time.toIso8601String(),
    };

const _$SearchMethodEnumMap = {
  SearchMethod.any: 'any',
  SearchMethod.title: 'title',
  SearchMethod.primaryTitle: 'primaryTitle',
  SearchMethod.isbn: 'isbn',
  SearchMethod.author: 'author',
  SearchMethod.subject: 'subject',
  SearchMethod.$class: r'$class',
  SearchMethod.bookId: 'bookId',
  SearchMethod.orderNumber: 'orderNumber',
  SearchMethod.publisher: 'publisher',
  SearchMethod.callNumber: 'callNumber',
};

LibraryTrendsItem _$LibraryTrendsItemFromJson(Map<String, dynamic> json) => LibraryTrendsItem(
      keyword: json['keyword'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$LibraryTrendsItemToJson(LibraryTrendsItem instance) => <String, dynamic>{
      'keyword': instance.keyword,
      'count': instance.count,
    };

LibraryTrends _$LibraryTrendsFromJson(Map<String, dynamic> json) => LibraryTrends(
      recent30days: (json['recent30days'] as List<dynamic>)
          .map((e) => LibraryTrendsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total:
          (json['total'] as List<dynamic>).map((e) => LibraryTrendsItem.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$LibraryTrendsToJson(LibraryTrends instance) => <String, dynamic>{
      'recent30days': instance.recent30days,
      'total': instance.total,
    };
