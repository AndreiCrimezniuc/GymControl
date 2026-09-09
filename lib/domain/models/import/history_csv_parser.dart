import 'dart:convert';

class ParsedHistoryImport {
  final List<Map<String, dynamic>> rows;
  final int skippedRows;

  const ParsedHistoryImport({required this.rows, required this.skippedRows});
}

/// Converts exports from Strong, Hevy and simple spreadsheets into the small,
/// stable contract accepted by GymControl. The parser is deliberately RFC-CSV
/// aware: quoted commas, quotes and line breaks are preserved.
class HistoryCsvParser {
  static const _exerciseHeaders = [
    'exercise_name',
    'exercise_title',
    'exercise',
    'movement',
  ];
  static const _dateHeaders = [
    'date',
    'start_time',
    'performed_at',
    'workout_date',
  ];

  static ParsedHistoryImport parse(String source) {
    final records = _records(source);
    if (records.length < 2) {
      throw const FormatException(
        'CSV must contain a header and at least one set',
      );
    }
    final headers = records.first.map(_normalizeHeader).toList(growable: false);
    final exerciseIndex = _firstIndex(headers, _exerciseHeaders);
    final dateIndex = _firstIndex(headers, _dateHeaders);
    final repsIndex = _firstIndex(headers, const ['reps', 'repetitions']);
    if (exerciseIndex < 0 || dateIndex < 0 || repsIndex < 0) {
      throw const FormatException(
        'Required columns: exercise, date/start_time and reps',
      );
    }

    final kilogramsIndex = _firstIndex(headers, const [
      'weight_kg',
      'kilograms',
      'kg',
    ]);
    final poundsIndex = _firstIndex(headers, const [
      'weight_lbs',
      'weight_lb',
      'pounds',
      'lbs',
    ]);
    final weightIndex = _firstIndex(headers, const ['weight', 'load']);
    if (kilogramsIndex < 0 && poundsIndex < 0 && weightIndex < 0) {
      throw const FormatException(
        'Required column: weight, weight_kg or weight_lbs',
      );
    }

    final workoutIndex = _firstIndex(headers, const [
      'workout_name',
      'workout_title',
      'workout',
      'routine_name',
    ]);
    // In Hevy, "title" is the workout and "exercise_title" is the exercise.
    final fallbackTitleIndex = headers.indexOf('title');
    final unitIndex = _firstIndex(headers, const ['unit', 'weight_unit']);
    final typeIndex = _firstIndex(headers, const ['set_type', 'type']);
    final rpeIndex = headers.indexOf('rpe');
    final sessionIndex = _firstIndex(headers, const [
      'session_id',
      'session_key',
      'workout_id',
    ]);

    final result = <Map<String, dynamic>>[];
    var skipped = 0;
    for (var rowIndex = 1; rowIndex < records.length; rowIndex++) {
      final record = records[rowIndex];
      if (record.every((cell) => cell.trim().isEmpty)) continue;
      String cell(int index) =>
          index >= 0 && index < record.length ? record[index].trim() : '';

      final exercise = cell(exerciseIndex);
      final rawDate = cell(dateIndex);
      final date = _parseDate(rawDate);
      final reps = int.tryParse(cell(repsIndex));
      final rawWeight = cell(
        kilogramsIndex >= 0
            ? kilogramsIndex
            : poundsIndex >= 0
            ? poundsIndex
            : weightIndex,
      ).replaceAll(',', '.');
      final weight = double.tryParse(rawWeight);
      if (exercise.isEmpty ||
          date == null ||
          reps == null ||
          reps < 1 ||
          reps > 1000 ||
          weight == null ||
          !weight.isFinite ||
          weight < 0 ||
          weight > 2000) {
        skipped++;
        continue;
      }

      var unit = cell(unitIndex).toLowerCase();
      if (poundsIndex >= 0) unit = 'lb';
      if (kilogramsIndex >= 0) unit = 'kg';
      if (unit == 'lbs' || unit == 'pound' || unit == 'pounds') unit = 'lb';
      if (unit != 'lb') unit = 'kg';
      final rpeCell = cell(rpeIndex).replaceAll(',', '.');
      final parsedRpe = double.tryParse(rpeCell);
      if (rpeCell.isNotEmpty &&
          (parsedRpe == null ||
              !parsedRpe.isFinite ||
              parsedRpe < 6 ||
              parsedRpe > 10)) {
        skipped++;
        continue;
      }
      final rawRpe = parsedRpe;
      final workoutName = cell(
        workoutIndex >= 0 ? workoutIndex : fallbackTitleIndex,
      );
      final sourceSession = cell(sessionIndex);
      final day = _isoDay(date);
      result.add({
        'exercise_name': exercise,
        'workout_name': workoutName,
        'date': day,
        'weight': weight,
        'unit': unit,
        'reps': reps,
        'set_type': _setType(cell(typeIndex)),
        if (rawRpe != null) 'rpe': rawRpe,
        // Group by an explicit source id when available; otherwise by local
        // day + workout title. A row suffix is intentionally not added here:
        // all sets from one workout must remain one session.
        'session_key': sourceSession.isNotEmpty
            ? sourceSession
            : '$day|${workoutName.toLowerCase()}',
        'source_row': rowIndex,
      });
      if (result.length > 5000) {
        throw const FormatException('A single import is limited to 5000 sets');
      }
    }
    if (result.isEmpty) {
      throw const FormatException('No valid sets were found');
    }
    return ParsedHistoryImport(rows: result, skippedRows: skipped);
  }

  static List<List<String>> _records(String source) {
    final text = source.startsWith('\ufeff') ? source.substring(1) : source;
    final delimiter = _detectDelimiter(text);
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (quoted) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(char);
        }
        continue;
      }
      if (char == '"' && field.isEmpty) {
        quoted = true;
      } else if (char == delimiter) {
        row.add(field.toString());
        field = StringBuffer();
      } else if (char == '\n' || char == '\r') {
        if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(field.toString());
        field = StringBuffer();
        rows.add(row);
        if (rows.length > 5001) {
          throw const FormatException('A single import is limited to 5000 sets');
        }
        row = <String>[];
      } else {
        field.write(char);
      }
    }
    if (quoted) throw const FormatException('Unclosed quoted CSV field');
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
      if (rows.length > 5001) {
        throw const FormatException('A single import is limited to 5000 sets');
      }
    }
    return rows;
  }

  static String _detectDelimiter(String text) {
    var quoted = false;
    final counts = {',': 0, ';': 0, '\t': 0};
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '"') quoted = !quoted;
      if (!quoted && counts.containsKey(char)) counts[char] = counts[char]! + 1;
      if (!quoted && (char == '\n' || char == '\r')) break;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static int _firstIndex(List<String> source, List<String> candidates) {
    for (final candidate in candidates) {
      final index = source.indexOf(candidate);
      if (index >= 0) return index;
    }
    return -1;
  }

  static String _normalizeHeader(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    final direct = DateTime.tryParse(value);
    if (direct != null) return direct;
    final match = RegExp(
      r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
    ).firstMatch(value);
    if (match == null) return null;
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    // Strong commonly emits DD/MM/YYYY. For an ambiguous date this is a
    // deliberate European default; ISO dates remain unambiguous above.
    final parsed = DateTime(year, second, first);
    return parsed.year == year && parsed.month == second && parsed.day == first
        ? parsed
        : null;
  }

  static String _isoDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _setType(String source) {
    final value = source.trim().toLowerCase();
    if (value.contains('warm')) return 'warmup';
    if (value.contains('drop')) return 'dropset';
    if (value.contains('fail')) return 'failure';
    return 'working';
  }

  static String prettyJson(Object value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}
