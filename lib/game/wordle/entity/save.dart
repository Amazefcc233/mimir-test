import 'package:json_annotation/json_annotation.dart';

part "save.g.dart";

@JsonSerializable()
class SaveWordle {
  final Duration playtime;
  final String word;
  final List<String> attempts;
  final String input;

  const SaveWordle({
    required this.playtime,
    required this.word,
    this.input = "",
    this.attempts = const [],
  });

  Map<String, dynamic> toJson() => _$SaveWordleToJson(this);

  factory SaveWordle.fromJson(Map<String, dynamic> json) => _$SaveWordleFromJson(json);
}
