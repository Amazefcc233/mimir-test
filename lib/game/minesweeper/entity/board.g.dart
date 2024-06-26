// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CellBoardCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// CellBoard(...).copyWith(id: 12, name: "My name")
  /// ````
  CellBoard call({
    int? mines,
    List2D<Cell>? cells,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCellBoard.copyWith(...)`.
class _$CellBoardCWProxyImpl implements _$CellBoardCWProxy {
  const _$CellBoardCWProxyImpl(this._value);

  final CellBoard _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// CellBoard(...).copyWith(id: 12, name: "My name")
  /// ````
  CellBoard call({
    Object? mines = const $CopyWithPlaceholder(),
    Object? cells = const $CopyWithPlaceholder(),
  }) {
    return CellBoard(
      mines: mines == const $CopyWithPlaceholder() || mines == null
          ? _value.mines
          // ignore: cast_nullable_to_non_nullable
          : mines as int,
      cells: cells == const $CopyWithPlaceholder() || cells == null
          ? _value.cells
          // ignore: cast_nullable_to_non_nullable
          : cells as List2D<Cell>,
    );
  }
}

extension $CellBoardCopyWith on CellBoard {
  /// Returns a callable class that can be used as follows: `instanceOfCellBoard.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$CellBoardCWProxy get copyWith => _$CellBoardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CellBoard _$CellBoardFromJson(Map<String, dynamic> json) => CellBoard(
      mines: (json['mines'] as num).toInt(),
      cells: List2D<Cell>.fromJson(
          json['cells'] as Map<String, dynamic>, (value) => Cell.fromJson(value as Map<String, dynamic>)),
    );

Map<String, dynamic> _$CellBoardToJson(CellBoard instance) => <String, dynamic>{
      'mines': instance.mines,
      'cells': instance.cells.toJson(
        (value) => value,
      ),
    };
