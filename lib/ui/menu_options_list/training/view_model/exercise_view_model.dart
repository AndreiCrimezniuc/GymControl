import 'package:gymboss/domain/models/trainings/exercise.dart';

typedef _UndoCallback = void Function();

class ExerciseViewModel {
  ExerciseViewModel({required List<ExerciseSet> initialSets})
      : _sets = List.from(initialSets);

  static const int _maxHistory = 50;

  List<ExerciseSet> _sets;
  final List<_UndoCallback> _undoHistory = [];

  List<ExerciseSet> get sets => List.unmodifiable(_sets);
  bool get canUndo => _undoHistory.isNotEmpty;

  void updateReps(int index, int newReps) {
    if (!_isValidIndex(index)) return;

    final previous = _sets[index];
    if (previous.reps == newReps) return;

    _pushUndo(() {
      if (_isValidIndex(index)) {
        _sets[index] = previous;
      }
    });

    _sets[index] = ExerciseSet(weight: previous.weight, reps: newReps);
  }

  void updateWeight(int index, double newWeight) {
    if (!_isValidIndex(index)) return;

    final previous = _sets[index];
    if (previous.weight == newWeight) return;

    _pushUndo(() {
      if (_isValidIndex(index)) {
        _sets[index] = previous;
      }
    });

    _sets[index] = ExerciseSet(weight: newWeight, reps: previous.reps);
  }

  void removeSet(int index) {
    if (!_isValidIndex(index)) return;

    final removedSet = _sets[index];
    _pushUndo(() {
      final targetIndex = index <= _sets.length ? index : _sets.length;
      _sets.insert(targetIndex, removedSet);
    });

    _sets.removeAt(index);
  }

  void addSet() {
    final newSet = ExerciseSet(weight: 0, reps: 10);

    _pushUndo(() {
      if (_sets.isNotEmpty) {
        _sets.removeLast();
      }
    });

    _sets.add(newSet);
  }

  bool undo() {
    if (_undoHistory.isEmpty) return false;

    final action = _undoHistory.removeLast();
    action();
    return true;
  }

  void _pushUndo(_UndoCallback callback) {
    _undoHistory.add(callback);
    if (_undoHistory.length > _maxHistory) {
      _undoHistory.removeAt(0);
    }
  }

  bool _isValidIndex(int index) => index >= 0 && index < _sets.length;
}

