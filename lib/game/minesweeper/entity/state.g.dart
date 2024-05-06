// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GameStateMinesweeperCWProxy {
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// GameStateMinesweeper(...).copyWith(id: 12, name: "My name")
  /// ````
  GameStateMinesweeper call({
    GameState? state,
    GameMode? mode,
    Board? board,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfGameStateMinesweeper.copyWith(...)`.
class _$GameStateMinesweeperCWProxyImpl implements _$GameStateMinesweeperCWProxy {
  const _$GameStateMinesweeperCWProxyImpl(this._value);

  final GameStateMinesweeper _value;

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored.
  ///
  /// Usage
  /// ```dart
  /// GameStateMinesweeper(...).copyWith(id: 12, name: "My name")
  /// ````
  GameStateMinesweeper call({
    Object? state = const $CopyWithPlaceholder(),
    Object? mode = const $CopyWithPlaceholder(),
    Object? board = const $CopyWithPlaceholder(),
  }) {
    return GameStateMinesweeper(
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as GameState,
      mode: mode == const $CopyWithPlaceholder() || mode == null
          ? _value.mode
          // ignore: cast_nullable_to_non_nullable
          : mode as GameMode,
      board: board == const $CopyWithPlaceholder() || board == null
          ? _value.board
          // ignore: cast_nullable_to_non_nullable
          : board as Board,
    );
  }
}

extension $GameStateMinesweeperCopyWith on GameStateMinesweeper {
  /// Returns a callable class that can be used as follows: `instanceOfGameStateMinesweeper.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$GameStateMinesweeperCWProxy get copyWith => _$GameStateMinesweeperCWProxyImpl(this);
}
