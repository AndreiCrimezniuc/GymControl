import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/domain/models/import/history_csv_parser.dart';

void main() {
  group('HistoryCsvParser', () {
    test('parses Strong CSV and preserves two identical sets', () {
      const csv = '''Date,Workout Name,Exercise Name,Set Order,Weight,Reps,RPE
2024-03-04 18:30:00,"Push, heavy",Bench Press,1,100,5,8
2024-03-04 18:30:00,"Push, heavy",Bench Press,2,100,5,8''';
      final parsed = HistoryCsvParser.parse(csv);
      expect(parsed.rows, hasLength(2));
      expect(parsed.rows.first['workout_name'], 'Push, heavy');
      expect(parsed.rows.first['session_key'], parsed.rows.last['session_key']);
      expect(parsed.rows.first['weight'], 100);
      expect(parsed.skippedRows, 0);
    });

    test('parses Hevy names, pounds and quoted line breaks', () {
      const csv = '''title,start_time,exercise_title,weight_lbs,reps,set_type
Legs,2023-06-12T09:15:00,"Rear Foot\nElevated Split Squat",88,10,warmup''';
      final parsed = HistoryCsvParser.parse(csv);
      expect(
        parsed.rows.single['exercise_name'],
        'Rear Foot\nElevated Split Squat',
      );
      expect(parsed.rows.single['workout_name'], 'Legs');
      expect(parsed.rows.single['unit'], 'lb');
      expect(parsed.rows.single['set_type'], 'warmup');
    });

    test('skips incomplete rows but rejects a wholly invalid import', () {
      const csv = '''date,exercise,weight_kg,reps
2024-01-01,Squat,120,5
not-a-date,Squat,120,5''';
      final parsed = HistoryCsvParser.parse(csv);
      expect(parsed.rows, hasLength(1));
      expect(parsed.skippedRows, 1);
    });

    test('accepts semicolon spreadsheets with decimal commas', () {
      const csv = 'date;exercise;weight_kg;reps\n04.03.2024;Squat;82,5;8';
      final parsed = HistoryCsvParser.parse(csv);
      expect(parsed.rows.single['date'], '2024-03-04');
      expect(parsed.rows.single['weight'], 82.5);
    });
  });
}
