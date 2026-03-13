import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:twentyfivepuzzle/audio_play.dart';

class PuzzleBoardController {
  _PuzzleBoardState? _state;

  Future<void> showStart() async {
    final state = _state;
    if (state == null) {
      return;
    }
    await state._showStart();
  }

  Future<void> showGame() async {
    final state = _state;
    if (state == null) {
      return;
    }
    await state._startGame();
  }
}

class PuzzleBoard extends StatefulWidget {
  const PuzzleBoard({super.key, required this.controller, required this.audioPlay});
  final PuzzleBoardController controller;
  final AudioPlay audioPlay;

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

enum _PuzzleMode { start, game }

enum _Direction { up, down, left, right }

class _PuzzleBoardState extends State<PuzzleBoard> {
  static const _gridSize = 5;
  static const _tileCount = _gridSize * _gridSize;
  static const _stageColor = Color(0xFFDCD9FF);
  static const _moveDuration = Duration(milliseconds: 120);
  static const _fadeDuration = Duration(milliseconds: 900);

  final Random _random = Random();

  List<int?> _tiles = List<int?>.generate(
    _tileCount,
    (index) => index < _tileCount - 1 ? index + 1 : null,
  );
  int _blankIndex = _tileCount - 1;
  _PuzzleMode _mode = _PuzzleMode.start;
  bool _solved = false;

  Offset? _panStart;
  int? _panStartIndex;
  bool _handledMove = false;

  double _tileSize = 0;
  String _backgroundAsset = 'assets/image/cat1.webp';
  double _backgroundOpacity = 0;
  int? _animatedColumn;
  _Direction? _activeAnimationDirection;
  Timer? _columnAnimationResetTimer;

  int _swipeCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _columnAnimationResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        if (!size.isFinite || size <= 0) {
          return const SizedBox.shrink();
        }
        final tileSize = size / _gridSize;
        _tileSize = tileSize;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _mode == _PuzzleMode.start ? _handleStartTap : null,
          onPanStart: _mode == _PuzzleMode.game
            ? (details) => _handlePanStart(details.localPosition)
            : null,
          onPanUpdate: _mode == _PuzzleMode.game
            ? (details) => _handlePanUpdate(details.localPosition)
            : null,
          onPanEnd: _mode == _PuzzleMode.game ? (_) => _handlePanEnd() : null,
          child: Center(
            child: Column(children:[
              Text(_swipeCount.toString(),style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              SizedBox(
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: _stageColor),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      AnimatedOpacity(
                        opacity: _mode == _PuzzleMode.game
                            ? _backgroundOpacity
                            : 0,
                        duration: const Duration(milliseconds: 600),
                        child: Image.asset(_backgroundAsset, fit: BoxFit.cover),
                      ),
                      ..._buildTiles(tileSize),
                      if (_mode == _PuzzleMode.start)
                        Image.asset('assets/image/start.png', fit: BoxFit.cover),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  List<Widget> _buildTiles(double tileSize) {
    final widgets = <Widget>[];
    final animatedColumn = _animatedColumn;
    final direction = _activeAnimationDirection;
    for (var index = 0; index < _tiles.length; index++) {
      final value = _tiles[index];
      if (value == null) {
        continue;
      }
      final row = index ~/ _gridSize;
      final col = index % _gridSize;
      final isHorizontalDirection =
          direction == _Direction.left || direction == _Direction.right;
      final isVerticalDirection =
          direction == _Direction.up || direction == _Direction.down;
      Duration duration;
      if (direction == null) {
        duration = _moveDuration;
      } else if (isHorizontalDirection) {
        duration = _moveDuration;
      } else if (isVerticalDirection &&
          animatedColumn != null &&
          animatedColumn == col) {
        duration = _moveDuration;
      } else {
        duration = Duration.zero;
      }
      widgets.add(
        AnimatedPositioned(
          key: ValueKey<int>(value),
          duration: duration,
          curve: Curves.easeInOut,
          left: col * tileSize,
          top: row * tileSize,
          width: tileSize,
          height: tileSize,
          child: AnimatedOpacity(
            opacity: _solved ? 0 : 1,
            duration: _solved
              ? _fadeDuration
              : const Duration(milliseconds: 160),
            child: Image.asset('assets/image/b$value.png', fit: BoxFit.cover),
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _showStart() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _mode = _PuzzleMode.start;
      _solved = false;
      _swipeCount = 0;
    });
  }

  Future<void> _startGame() async {
    final tiles = List<int?>.generate(
      _tileCount,
      (index) => index < _tileCount - 1 ? index + 1 : null,
    );
    var blank = _tileCount - 1;
    _Direction? lastDirection;
    final scrambleMoves = 220 + _random.nextInt(80);
    for (var i = 0; i < scrambleMoves; i++) {
      final candidates = _availableMovesFromBlank(blank);
      if (lastDirection != null) {
        candidates.remove(_oppositeDirection(lastDirection));
      }
      final direction = candidates[_random.nextInt(candidates.length)];
      final neighbor = _neighborIndex(blank, direction);
      if (neighbor == null) {
        continue;
      }
      tiles[blank] = tiles[neighbor];
      tiles[neighbor] = null;
      blank = neighbor;
      lastDirection = direction;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _tiles = tiles;
      _blankIndex = blank;
      _mode = _PuzzleMode.game;
      _solved = false;
      _panStart = null;
      _panStartIndex = null;
      _handledMove = false;
      _backgroundAsset = 'assets/image/cat${(_random.nextInt(9) + 1)}.webp';
      _backgroundOpacity = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      setState(() {
        _backgroundOpacity = 1;
        _swipeCount = 0;
      });
    }
  }

  void _handleStartTap() {
    unawaited(_startGame());
  }

  void _handlePanStart(Offset localPosition) {
    if (_tileSize <= 0) {
      return;
    }
    final col = (localPosition.dx / _tileSize).floor();
    final row = (localPosition.dy / _tileSize).floor();
    if (col < 0 || row < 0 || col >= _gridSize || row >= _gridSize) {
      _panStartIndex = null;
      return;
    }
    final index = row * _gridSize + col;
    if (_tiles[index] == null) {
      _panStartIndex = null;
      return;
    }
    _panStart = localPosition;
    _panStartIndex = index;
    _handledMove = false;
    if (_solved) {
      setState(() {
        _solved = false;
      });
    }
  }

  void _handlePanUpdate(Offset localPosition) {
    final start = _panStart;
    final index = _panStartIndex;
    if (start == null || index == null || _handledMove) {
      return;
    }
    final delta = localPosition - start;
    final threshold = _tileSize * 0.2;
    if (delta.distance < threshold) {
      return;
    }
    final direction = delta.dx.abs() > delta.dy.abs()
        ? (delta.dx > 0 ? _Direction.right : _Direction.left)
        : (delta.dy > 0 ? _Direction.down : _Direction.up);
    if (_tryMoveFrom(index, direction)) {
      _handledMove = true;
    }
  }

  void _handlePanEnd() {
    _panStart = null;
    _panStartIndex = null;
    _handledMove = false;
  }

  bool _tryMoveFrom(int startIndex, _Direction direction) {
    if (_tiles[startIndex] == null) {
      return false;
    }
    final path = _buildPath(startIndex, direction);
    if (path.isEmpty) {
      return false;
    }
    setState(() {
      _applyPath(path);
      _solved = false;
      _updateAnimationState(direction, startIndex % _gridSize);
    });
    widget.audioPlay.play01();
    setState(() {
      _swipeCount += 1;
    });
    _checkSolved();
    return true;
  }

  List<int> _buildPath(int startIndex, _Direction direction) {
    final path = <int>[];
    final startRow = startIndex ~/ _gridSize;
    final startCol = startIndex % _gridSize;
    final blankRow = _blankIndex ~/ _gridSize;
    final blankCol = _blankIndex % _gridSize;

    switch (direction) {
      case _Direction.left:
        if (startRow != blankRow || blankCol >= startCol) {
          return path;
        }
        for (var col = blankCol + 1; col <= startCol; col++) {
          path.add(startRow * _gridSize + col);
        }
        break;
      case _Direction.right:
        if (startRow != blankRow || blankCol <= startCol) {
          return path;
        }
        for (var col = blankCol - 1; col >= startCol; col--) {
          path.add(startRow * _gridSize + col);
        }
        break;
      case _Direction.up:
        if (startCol != blankCol || blankRow >= startRow) {
          return path;
        }
        for (var row = blankRow + 1; row <= startRow; row++) {
          path.add(row * _gridSize + startCol);
        }
        break;
      case _Direction.down:
        if (startCol != blankCol || blankRow <= startRow) {
          return path;
        }
        for (var row = blankRow - 1; row >= startRow; row--) {
          path.add(row * _gridSize + startCol);
        }
        break;
    }
    return path;
  }

  void _applyPath(List<int> path) {
    var blank = _blankIndex;
    for (final idx in path) {
      _tiles[blank] = _tiles[idx];
      blank = idx;
    }
    _tiles[blank] = null;
    _blankIndex = blank;
  }

  List<_Direction> _availableMovesFromBlank(int blankIndex) {
    final row = blankIndex ~/ _gridSize;
    final col = blankIndex % _gridSize;
    final moves = <_Direction>[];
    if (row < _gridSize - 1) {
      moves.add(_Direction.up);
    }
    if (row > 0) {
      moves.add(_Direction.down);
    }
    if (col < _gridSize - 1) {
      moves.add(_Direction.left);
    }
    if (col > 0) {
      moves.add(_Direction.right);
    }
    return moves;
  }

  _Direction _oppositeDirection(_Direction direction) {
    switch (direction) {
      case _Direction.up:
        return _Direction.down;
      case _Direction.down:
        return _Direction.up;
      case _Direction.left:
        return _Direction.right;
      case _Direction.right:
        return _Direction.left;
    }
  }

  int? _neighborIndex(int blankIndex, _Direction direction) {
    switch (direction) {
      case _Direction.up:
        if (blankIndex >= _tileCount - _gridSize) {
          return null;
        }
        return blankIndex + _gridSize;
      case _Direction.down:
        if (blankIndex < _gridSize) {
          return null;
        }
        return blankIndex - _gridSize;
      case _Direction.left:
        if (blankIndex % _gridSize == _gridSize - 1) {
          return null;
        }
        return blankIndex + 1;
      case _Direction.right:
        if (blankIndex % _gridSize == 0) {
          return null;
        }
        return blankIndex - 1;
    }
  }

  void _updateAnimationState(_Direction direction, int column) {
    _animatedColumn = direction == _Direction.up || direction == _Direction.down
        ? column
        : null;
    _activeAnimationDirection = direction;
    _columnAnimationResetTimer?.cancel();
    _columnAnimationResetTimer = Timer(_moveDuration, () {
      if (!mounted) {
        _animatedColumn = null;
        _activeAnimationDirection = null;
        return;
      }
      setState(() {
        _animatedColumn = null;
        _activeAnimationDirection = null;
      });
    });
  }

  void _checkSolved() {
    if (_solved) {
      return;
    }
    for (var i = 0; i < _tileCount - 1; i++) {
      if (_tiles[i] != i + 1) {
        return;
      }
    }
    setState(() {
      _solved = true;
    });
  }

}
