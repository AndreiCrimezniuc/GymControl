import 'package:gymboss/domain/models/json_readers.dart';

class ExerciseCatalogItem {
  final int id;
  final String name;
  final String nameRu;
  final String muscleGroup;
  final String equipment;
  final String category;
  final String level;
  final String force;
  final String imageUrl;
  final String imageUrl2;
  final String instructions;
  final String instructionsRu;
  final String exerciseType;
  final String loadMode;
  final List<String> secondaryMuscles;
  final List<String> aliases;
  final bool custom;

  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    this.nameRu = '',
    required this.muscleGroup,
    required this.equipment,
    required this.category,
    required this.level,
    required this.force,
    required this.imageUrl,
    required this.imageUrl2,
    required this.instructions,
    this.instructionsRu = '',
    this.exerciseType = 'weight_reps',
    this.loadMode = 'total',
    this.secondaryMuscles = const [],
    this.aliases = const [],
    this.custom = false,
  });

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> j) =>
      ExerciseCatalogItem(
        id: jsonInt(j['id']),
        name: jsonString(j['name']),
        nameRu: jsonString(j['name_ru']),
        muscleGroup: jsonString(j['muscle_group']),
        equipment: jsonString(j['equipment']),
        category: jsonString(j['category']),
        level: jsonString(j['level']),
        force: jsonString(j['force']),
        imageUrl: jsonString(j['image_url']),
        imageUrl2: jsonString(j['image_url2']),
        instructions: jsonString(j['instructions']),
        instructionsRu: jsonString(j['instructions_ru']),
        exerciseType: jsonString(j['exercise_type'], 'weight_reps'),
        loadMode: jsonString(j['load_mode'], 'total'),
        secondaryMuscles: jsonStringList(j['secondary_muscles']),
        aliases: jsonStringList(j['aliases']),
        custom:
            jsonBool(j['is_custom']) || jsonString(j['category']) == 'custom',
      );

  String displayName(String languageCode) => languageCode == 'ru'
      ? (nameRu.trim().isNotEmpty
            ? nameRu
            : (_coreRussianNames[name.toLowerCase()] ?? name))
      : name;

  String displayInstructions(String languageCode) =>
      languageCode == 'ru' && instructionsRu.trim().isNotEmpty
      ? instructionsRu
      : instructions;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      name,
      nameRu,
      muscleGroup,
      equipment,
      category,
      level,
      ...secondaryMuscles,
      ...aliases,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

// Offline fallback for the product-owned core catalog. Server translations
// win when present, while these names keep a first launch readable even before
// the translated catalog migration has been synced.
const _coreRussianNames = <String, String>{
  'bench press': 'Жим лёжа',
  'barbell bench press - medium grip': 'Жим штанги лёжа',
  'dumbbell bench press': 'Жим гантелей лёжа',
  'incline barbell bench press - medium grip': 'Жим штанги на наклонной скамье',
  'incline dumbbell press': 'Жим гантелей на наклонной скамье',
  'decline barbell bench press': 'Жим штанги на скамье с обратным наклоном',
  'dumbbell flyes': 'Разведение гантелей лёжа',
  'incline dumbbell flyes': 'Разведение гантелей на наклонной скамье',
  'cable crossover': 'Кроссовер',
  'cable chest press': 'Жим в кроссовере',
  'machine bench press': 'Жим в тренажёре',
  'butterfly': 'Сведение рук в тренажёре',
  'pushups': 'Отжимания',
  'push-up wide': 'Отжимания широким хватом',
  'dips - triceps version': 'Отжимания на брусьях',
  'barbell deadlift': 'Становая тяга',
  'romanian deadlift': 'Румынская тяга',
  'sumo deadlift': 'Становая тяга сумо',
  'rack pulls': 'Тяга с плинтов',
  'bent over barbell row': 'Тяга штанги в наклоне',
  'bent over two-dumbbell row': 'Тяга двух гантелей в наклоне',
  'one-arm dumbbell row': 'Тяга гантели одной рукой',
  't-bar row with handle': 'Тяга Т-грифа',
  'seated cable rows': 'Горизонтальная тяга блока',
  'wide-grip lat pulldown': 'Тяга верхнего блока широким хватом',
  'close-grip front lat pulldown': 'Тяга верхнего блока узким хватом',
  'straight-arm pulldown': 'Пуловер на верхнем блоке',
  'pullups': 'Подтягивания',
  'chin-up': 'Подтягивания обратным хватом',
  'face pull': 'Тяга каната к лицу',
  'squat': 'Приседание',
  'squats': 'Приседания',
  'barbell squat': 'Приседание со штангой',
  'barbell full squat': 'Глубокое приседание со штангой',
  'front barbell squat': 'Фронтальное приседание',
  'goblet squat': 'Гоблет-приседание',
  'bodyweight squat': 'Приседание с собственным весом',
  'hack squat': 'Гакк-приседание',
  'leg press': 'Жим ногами',
  'leg extensions': 'Разгибание ног',
  'lying leg curls': 'Сгибание ног лёжа',
  'seated leg curl': 'Сгибание ног сидя',
  'barbell lunge': 'Выпады со штангой',
  'dumbbell lunges': 'Выпады с гантелями',
  'dumbbell rear lunge': 'Обратные выпады с гантелями',
  'split squat with dumbbells': 'Сплит-приседание с гантелями',
  'barbell walking lunge': 'Ходьба выпадами со штангой',
  'barbell step ups': 'Зашагивания со штангой',
  'barbell hip thrust': 'Ягодичный мост со штангой',
  'barbell glute bridge': 'Ягодичный мост лёжа со штангой',
  'single leg glute bridge': 'Ягодичный мост на одной ноге',
  'glute kickback': 'Отведение ноги назад',
  'good morning': 'Наклоны со штангой',
  'standing calf raises': 'Подъёмы на носки стоя',
  'seated calf raise': 'Подъёмы на носки сидя',
  'thigh abductor': 'Разведение ног в тренажёре',
  'thigh adductor': 'Сведение ног в тренажёре',
  'barbell shoulder press': 'Жим штанги над головой',
  'seated barbell military press': 'Армейский жим сидя',
  'standing military press': 'Армейский жим стоя',
  'dumbbell shoulder press': 'Жим гантелей над головой',
  'seated dumbbell press': 'Жим гантелей сидя',
  'arnold dumbbell press': 'Жим Арнольда',
  'side lateral raise': 'Разведение гантелей в стороны',
  'front dumbbell raise': 'Подъём гантелей перед собой',
  'reverse flyes': 'Разведение на заднюю дельту',
  'reverse machine flyes': 'Обратная бабочка',
  'upright barbell row': 'Тяга штанги к подбородку',
  'barbell shrug': 'Шраги со штангой',
  'dumbbell shrug': 'Шраги с гантелями',
  'barbell curl': 'Сгибание рук со штангой',
  'ez-bar curl': 'Сгибание рук с EZ-грифом',
  'dumbbell bicep curl': 'Сгибание рук с гантелями',
  'hammer curls': 'Молотковые сгибания',
  'incline dumbbell curl': 'Сгибание гантелей на наклонной скамье',
  'concentration curls': 'Концентрированные сгибания',
  'preacher curl': 'Сгибание на скамье Скотта',
  'triceps pushdown': 'Разгибание рук на блоке',
  'triceps pushdown - rope attachment': 'Разгибание рук с канатом',
  'bench dips': 'Обратные отжимания от скамьи',
  'plank': 'Планка',
  'side bridge': 'Боковая планка',
  'crunches': 'Скручивания',
  'cable crunch': 'Скручивания на верхнем блоке',
  'reverse crunch': 'Обратные скручивания',
  'hanging leg raise': 'Подъём ног в висе',
  'dead bug': 'Мёртвый жук',
  'russian twist': 'Русские скручивания',
  'pallof press': 'Жим Палоффа',
  'ab crunch machine': 'Скручивания в тренажёре',
  'sit-up': 'Подъём корпуса',
  'air bike': 'Велосипед для пресса',
  'farmers walk': 'Прогулка фермера',
};

class ExerciseProgressionPoint {
  final String date;
  final double topWeightKg;
  final int topReps;
  final double volumeKg;
  const ExerciseProgressionPoint({
    required this.date,
    required this.topWeightKg,
    this.topReps = 0,
    this.volumeKg = 0,
  });

  factory ExerciseProgressionPoint.fromJson(Map<String, dynamic> j) =>
      ExerciseProgressionPoint(
        date: (j['date'] as String?) ?? '',
        topWeightKg: (j['top_weight_kg'] as num?)?.toDouble() ?? 0,
        topReps: (j['top_reps'] as num?)?.toInt() ?? 0,
        volumeKg: (j['volume_kg'] as num?)?.toDouble() ?? 0,
      );
}

class ExerciseStats {
  final int exerciseId;
  final int timesPerformed;
  final int totalSets;
  final int totalReps;
  final double avgSetsPerWorkout;
  final double maxWeightKg;
  final double maxVolumeKg;
  final double estimatedOneRmKg;
  final double maxSetVolumeKg;
  final String? rank;
  final List<ExerciseProgressionPoint> progression;
  final List<ExerciseRecord> records;

  const ExerciseStats({
    required this.exerciseId,
    required this.timesPerformed,
    required this.totalSets,
    required this.totalReps,
    required this.avgSetsPerWorkout,
    required this.maxWeightKg,
    required this.maxVolumeKg,
    this.estimatedOneRmKg = 0,
    this.maxSetVolumeKg = 0,
    required this.rank,
    required this.progression,
    this.records = const [],
  });

  factory ExerciseStats.fromJson(Map<String, dynamic> j) => ExerciseStats(
    exerciseId: jsonInt(j['exercise_id']),
    timesPerformed: jsonInt(j['times_performed'], min: 0),
    totalSets: jsonInt(j['total_sets'], min: 0),
    totalReps: jsonInt(j['total_reps'], min: 0),
    avgSetsPerWorkout: jsonDouble(j['avg_sets_per_workout'], min: 0),
    maxWeightKg: jsonDouble(j['max_weight_kg'], min: 0),
    maxVolumeKg: jsonDouble(j['max_volume_kg'], min: 0),
    estimatedOneRmKg: jsonDouble(j['estimated_one_rm_kg'], min: 0),
    maxSetVolumeKg: jsonDouble(j['max_set_volume_kg'], min: 0),
    rank: jsonNullableString(j['rank']),
    progression: jsonObjectList(
      j['progression'],
      ExerciseProgressionPoint.fromJson,
      maxItems: 1000,
    ),
    records: jsonObjectList(
      j['records'],
      ExerciseRecord.fromJson,
      maxItems: 100,
    ),
  );

  bool get hasData => totalSets > 0;
}

class ExerciseRecord {
  final String type;
  final String date;
  final double weightKg;
  final int reps;
  final double value;

  const ExerciseRecord({
    required this.type,
    required this.date,
    required this.weightKg,
    required this.reps,
    required this.value,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    type: json['type'] as String? ?? '',
    date: json['date'] as String? ?? '',
    weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
    reps: (json['reps'] as num?)?.toInt() ?? 0,
    value: (json['value'] as num?)?.toDouble() ?? 0,
  );
}

class ExerciseHistorySet {
  final double weightKg;
  final int reps;
  final String setType;
  final String progression;
  final double? rpe;

  const ExerciseHistorySet({
    required this.weightKg,
    required this.reps,
    required this.setType,
    required this.progression,
    this.rpe,
  });

  factory ExerciseHistorySet.fromJson(Map<String, dynamic> json) =>
      ExerciseHistorySet(
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        setType: json['set_type'] as String? ?? 'working',
        progression: json['progression'] as String? ?? '',
        rpe: (json['rpe'] as num?)?.toDouble(),
      );
}

class ExerciseHistorySession {
  final String date;
  final String workoutId;
  final String workoutName;
  final String sessionId;
  final List<ExerciseHistorySet> sets;

  const ExerciseHistorySession({
    required this.date,
    required this.workoutId,
    required this.workoutName,
    this.sessionId = '',
    required this.sets,
  });

  factory ExerciseHistorySession.fromJson(Map<String, dynamic> json) =>
      ExerciseHistorySession(
        date: jsonString(json['date']),
        workoutId: jsonString(json['workout_id']),
        workoutName: jsonString(json['workout_name']),
        sessionId: jsonString(json['session_id']),
        sets: jsonObjectList(
          json['sets'],
          ExerciseHistorySet.fromJson,
          maxItems: 500,
        ),
      );
}
