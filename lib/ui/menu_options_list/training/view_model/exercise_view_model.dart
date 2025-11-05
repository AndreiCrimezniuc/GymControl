import 'package:gymboss/domain/models/trainigs/exercise.dart';

enum UndoActionType {
  updateReps,
  updateWeight,
  removeSet,
  addSet,
}

class UndoAction {
  final UndoActionType type;
  final int? index;
  final ExerciseSet? oldSet;
  final ExerciseSet? newSet;

  UndoAction({
    required this.type,
    this.index,
    this.oldSet,
    this.newSet,
  });
}

class ExerciseViewModel {
  List<ExerciseSet> _sets = [];
  List<UndoAction> _undoHistory = [];
  List<UndoAction> _redoHistory = [];

  List<ExerciseSet> get sets => List.unmodifiable(_sets);

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  ExerciseViewModel({required List<ExerciseSet> initialSets}) {
    _sets = List.from(initialSets);
  }

  void _addToUndoHistory(UndoAction action) {
    _undoHistory.add(action);
    // Ограничиваем историю до 50 действий
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
    }
    // Очищаем redo при новом действии
    _redoHistory.clear();
  }

  void _addToRedoHistory(UndoAction action) {
    _redoHistory.add(action);
    if (_redoHistory.length > 50) {
      _redoHistory.removeAt(0);
    }
  }

  void updateReps(int index, int newReps) {
    if (index < 0 || index >= _sets.length) return;

    final oldSet = _sets[index];
    _addToUndoHistory(UndoAction(
      type: UndoActionType.updateReps,
      index: index,
      oldSet: oldSet,
      newSet: ExerciseSet(weight: oldSet.weight, reps: newReps),
    ));

    _sets[index] = ExerciseSet(weight: _sets[index].weight, reps: newReps);
  }

  void updateWeight(int index, double newWeight) {
    if (index < 0 || index >= _sets.length) return;

    final oldSet = _sets[index];
    _addToUndoHistory(UndoAction(
      type: UndoActionType.updateWeight,
      index: index,
      oldSet: oldSet,
      newSet: ExerciseSet(weight: newWeight, reps: oldSet.reps),
    ));

    _sets[index] = ExerciseSet(weight: newWeight, reps: _sets[index].reps);
  }

  void removeSet(int index) {
    if (index < 0 || index >= _sets.length) return;

    final removedSet = _sets[index];
    _addToUndoHistory(UndoAction(
      type: UndoActionType.removeSet,
      index: index,
      oldSet: removedSet,
    ));

    _sets.removeAt(index);
  }

  void addSet() {
    final newSet = ExerciseSet(weight: 0, reps: 10);
    final index = _sets.length;
    _addToUndoHistory(UndoAction(
      type: UndoActionType.addSet,
      index: index,
      oldSet: newSet, // Сохраняем сет для возможности redo
    ));

    _sets.add(newSet);
  }

  bool undo() {
    if (_undoHistory.isEmpty) return false;

    final action = _undoHistory.removeLast();
    UndoAction? redoAction;

    switch (action.type) {
      case UndoActionType.updateReps:
        if (action.index != null && action.oldSet != null && action.newSet != null) {
          redoAction = UndoAction(
            type: UndoActionType.updateReps,
            index: action.index,
            oldSet: action.oldSet,
            newSet: action.newSet,
          );
          _sets[action.index!] = action.oldSet!;
        }
        break;
      case UndoActionType.updateWeight:
        if (action.index != null && action.oldSet != null && action.newSet != null) {
          redoAction = UndoAction(
            type: UndoActionType.updateWeight,
            index: action.index,
            oldSet: action.oldSet,
            newSet: action.newSet,
          );
          _sets[action.index!] = action.oldSet!;
        }
        break;
      case UndoActionType.removeSet:
        if (action.index != null && action.oldSet != null) {
          redoAction = UndoAction(
            type: UndoActionType.addSet,
            index: action.index,
            oldSet: action.oldSet, // Сохраняем oldSet для redo
          );
          _sets.insert(action.index!, action.oldSet!);
        }
        break;
      case UndoActionType.addSet:
        if (action.index != null && action.index! < _sets.length) {
          final removedSet = _sets[action.index!];
          redoAction = UndoAction(
            type: UndoActionType.removeSet,
            index: action.index,
            oldSet: removedSet,
          );
          _sets.removeAt(action.index!);
        }
        break;
    }

    if (redoAction != null) {
      _addToRedoHistory(redoAction);
    }

    return true;
  }

  bool redo() {
    if (_redoHistory.isEmpty) return false;

    final action = _redoHistory.removeLast();
    UndoAction? undoAction;

    // Redo должен применять действие, которое возвращает нас к состоянию ДО undo
    // То есть мы применяем то, что было в newSet или восстанавливаем действие
    switch (action.type) {
      case UndoActionType.updateReps:
        if (action.index != null && action.newSet != null) {
          // При undo мы вернули oldSet, при redo нужно применить newSet
          final currentSet = _sets[action.index!];
          undoAction = UndoAction(
            type: UndoActionType.updateReps,
            index: action.index,
            oldSet: currentSet, // Текущее состояние (после undo)
            newSet: action.newSet, // Состояние, к которому возвращаемся
          );
          _sets[action.index!] = action.newSet!;
        }
        break;
      case UndoActionType.updateWeight:
        if (action.index != null && action.newSet != null) {
          // При undo мы вернули oldSet, при redo нужно применить newSet
          final currentSet = _sets[action.index!];
          undoAction = UndoAction(
            type: UndoActionType.updateWeight,
            index: action.index,
            oldSet: currentSet, // Текущее состояние (после undo)
            newSet: action.newSet, // Состояние, к которому возвращаемся
          );
          _sets[action.index!] = action.newSet!;
        }
        break;
      case UndoActionType.addSet:
        // При undo мы удалили сет, при redo нужно снова его добавить
        if (action.index != null && action.oldSet != null) {
          final newSet = action.oldSet!;
          // Сохраняем текущее состояние для undo (сет будет добавлен)
          undoAction = UndoAction(
            type: UndoActionType.removeSet,
            index: action.index,
            oldSet: newSet, // Сет, который мы добавили (для undo)
          );
          _sets.insert(action.index!, newSet);
        }
        break;
      case UndoActionType.removeSet:
        // При undo мы добавили сет обратно, при redo нужно снова его удалить
        if (action.index != null && action.index! < _sets.length) {
          final removedSet = _sets[action.index!];
          undoAction = UndoAction(
            type: UndoActionType.addSet,
            index: action.index,
            oldSet: removedSet, // Сет, который мы удалили (для undo)
          );
          _sets.removeAt(action.index!);
        }
        break;
    }

    if (undoAction != null) {
      _undoHistory.add(undoAction);
      if (_undoHistory.length > 50) {
        _undoHistory.removeAt(0);
      }
    }

    return true;
  }
}

