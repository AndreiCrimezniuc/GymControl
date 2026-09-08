// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionBodyMetrics => 'Параметры тела';

  @override
  String get sectionAppearance => 'Внешний вид';

  @override
  String get sectionAccount => 'Аккаунт';

  @override
  String get sectionApp => 'Приложение';

  @override
  String get sectionLanguage => 'Язык';

  @override
  String get labelWeight => 'Вес';

  @override
  String get labelHeight => 'Рост';

  @override
  String get labelDarkMode => 'Тёмная тема';

  @override
  String get labelAccentColor => 'Цвет акцента';

  @override
  String get accentBlue => 'Кобальт';

  @override
  String get accentRed => 'Красный';

  @override
  String get accentPurple => 'Фиолетовый';

  @override
  String get accentGreen => 'Зелёный';

  @override
  String get labelNotifications => 'Уведомления';

  @override
  String get labelAbout => 'О приложении';

  @override
  String get labelReenableWeightReminders => 'Снова напоминать о весе';

  @override
  String get labelLanguage => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get logOut => 'Выйти';

  @override
  String get signIn => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get passwordMin => 'Пароль (минимум 8 символов)';

  @override
  String get confirmPassword => 'Повторите пароль';

  @override
  String get continueGoogle => 'Продолжить с Google';

  @override
  String get or => 'или';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get register => 'Зарегистрироваться';

  @override
  String get alreadyAccount => 'Уже есть аккаунт? ';

  @override
  String get explore => 'Разделы';

  @override
  String get weekStreak => 'НЕДЕЛЬ ПОДРЯД';

  @override
  String get nextGoal => 'СЛЕДУЮЩАЯ ЦЕЛЬ';

  @override
  String get routines => 'ПРОГРАММЫ';

  @override
  String get workouts => 'Тренировки';

  @override
  String get workoutsSubtitle => 'Программы и планы';

  @override
  String get progress => 'Прогресс';

  @override
  String get progressSubtitle => 'История и личные рекорды';

  @override
  String get strengthPassport => 'Силовой паспорт';

  @override
  String get strengthPassportSubtitle =>
      'Ваш силовой профиль по медианным результатам';

  @override
  String get exercises => 'Упражнения';

  @override
  String get exercisesSubtitle => 'Библиотека движений';

  @override
  String get settingsSubtitle => 'Параметры и аккаунт';

  @override
  String get startWorkout => 'Начать тренировку';

  @override
  String get rankedLifts => 'УПРАЖНЕНИЙ В РЕЙТИНГЕ';

  @override
  String get bodyweight => 'ВЕС ТЕЛА';

  @override
  String get bestLift => 'ЛУЧШЕЕ УПРАЖНЕНИЕ';

  @override
  String get medianRankedNote => 'Рейтинг по медиане · выбросы исключены';

  @override
  String get passportLocked =>
      'Запишите 3+ упражнения,\nчтобы получить паспорт';

  @override
  String get resumeWorkout => 'Продолжить активную тренировку';

  @override
  String get chooseWorkout => 'Выбрать тренировку';

  @override
  String resumeSummary(String elapsed, int done, int total) {
    return '$elapsed · $done/$total подходов · нажмите, чтобы продолжить';
  }

  @override
  String get repetitions => 'Повторения';

  @override
  String weightField(String unit) {
    return 'Вес в $unit';
  }

  @override
  String get restoringSession => 'Восстанавливаем сессию…';

  @override
  String get gettingReady => 'Подготавливаем приложение…';

  @override
  String get takingLonger => 'Это занимает больше времени, чем ожидалось.';

  @override
  String get tryAgain => 'Повторить';

  @override
  String mineCount(int count) {
    return 'Мои ($count)';
  }

  @override
  String libraryCount(int count) {
    return 'Библиотека ($count)';
  }

  @override
  String get library => 'Библиотека';

  @override
  String get allWorkouts => 'Все тренировки';

  @override
  String get searchWorkouts => 'Поиск тренировок';

  @override
  String get noWorkoutsFound => 'Тренировки не найдены';

  @override
  String get noWorkoutsYet => 'Тренировок пока нет';

  @override
  String get libraryEmpty => 'Библиотека пуста';

  @override
  String get createWorkout => 'Создать тренировку';

  @override
  String get couldNotLoadWorkouts => 'Не удалось загрузить тренировки';

  @override
  String get retry => 'Повторить';

  @override
  String get sortExercises => 'Сортировка упражнений';

  @override
  String searchExercises(int count) {
    return 'Поиск среди $count упражнений';
  }

  @override
  String get catalog => 'Каталог';

  @override
  String get myExercises => 'Мои упражнения';

  @override
  String get noExercisesFound => 'Упражнения не найдены';

  @override
  String get yourStats => 'Ваша статистика';

  @override
  String get noDataYet => 'Данных пока нет';

  @override
  String get personalRecords => 'Личные рекорды';

  @override
  String get couldNotLoadExercises => 'Не удалось загрузить упражнения';

  @override
  String get newExercise => 'Новое упражнение';

  @override
  String get statistics => 'Статистика';

  @override
  String get trainingWorkload => 'Тренировочная нагрузка';

  @override
  String get workoutCalendar => 'Календарь тренировок';

  @override
  String get trainingTrends => 'Динамика тренировок';

  @override
  String get finishWorkoutForTrends =>
      'Завершите тренировку, чтобы увидеть динамику';

  @override
  String get noStatsYet => 'Статистики пока нет';

  @override
  String get highlights => 'Главное';

  @override
  String get noSessionsYet => 'Сессий пока нет';

  @override
  String get all => 'Все';

  @override
  String get recordStartsHere => 'Ваша история начинается здесь';

  @override
  String get recordStartsBody =>
      'Завершите рабочий подход, чтобы открыть мастерство, личные рекорды и траекторию прогресса.';

  @override
  String get estimatedOneRm => 'РАСЧЁТНЫЙ 1ПМ';

  @override
  String get currentPowerMark => 'Текущая отметка силы';

  @override
  String get heaviestSet => 'САМЫЙ ТЯЖЁЛЫЙ ПОДХОД';

  @override
  String sessionsLogged(int count) {
    return 'Тренировок: $count';
  }

  @override
  String get workingSets => 'РАБОЧИЕ ПОДХОДЫ';

  @override
  String totalReps(int count) {
    return 'Всего повторений: $count';
  }

  @override
  String get bestSetVolume => 'ЛУЧШИЙ ОБЪЁМ ПОДХОДА';

  @override
  String get peakSingleSetWork => 'Пиковая работа за подход';

  @override
  String masteryLevel(int level) {
    return 'УРОВЕНЬ МАСТЕРСТВА $level';
  }

  @override
  String rankAndLevel(String rank, int level) {
    return 'РАНГ $rank · УРОВЕНЬ $level';
  }

  @override
  String setsToNextLevel(int count, int level) {
    return 'Ещё $count рабочих подходов до уровня $level';
  }

  @override
  String get masteryInitiate => 'Новичок';

  @override
  String get masteryTrained => 'Подготовленный';

  @override
  String get masteryProven => 'Проверенный';

  @override
  String get masteryVeteran => 'Ветеран';

  @override
  String get masteryMaster => 'Мастер';

  @override
  String get lockedStatsPreview =>
      'УРОВЕНЬ 1 · ПЕРВЫЙ РЕКОРД · ТРАЕКТОРИЯ ПРОГРЕССА';

  @override
  String passportRatioSummary(String ratio, int count) {
    return '$ratio× медианы группы · медиана $count упражнений';
  }

  @override
  String passportTierProgress(String remaining, String next, int progress) {
    return 'Ещё $remaining× медианы до $next · $progress% ранга пройдено';
  }

  @override
  String exerciseMedianProgress(String ratio, String next) {
    return '$ratio× медианы · следующий $next';
  }

  @override
  String get medianCalibrationPending => 'Медиана ещё калибруется';

  @override
  String get passportNoLiftsTitle => 'Результатов пока нет';

  @override
  String get passportNoLiftsBody =>
      'Запишите контрольный подход, чтобы открыть запись в паспорте. Три упражнения откроют общий класс.';

  @override
  String get passportPreviewTitle => 'ЗАПИСЬ ПАСПОРТА · ПРИМЕР';

  @override
  String get passportPreviewExercise => 'Жим лёжа';

  @override
  String get passportPreviewSubtitle =>
      'Лучший подход · расчётный 1ПМ · место в группе';

  @override
  String get passportPreviewBody =>
      'Каждая запись объясняет, почему вы получили этот класс и сколько отделяет вас от следующего.';

  @override
  String get passportGuideTitle => 'КАК РАБОТАЕТ ПАСПОРТ';

  @override
  String get strengthConstellation => 'Созвездие силы';

  @override
  String constellationSignals(int active, int total) {
    return '$active/$total СИГНАЛОВ';
  }

  @override
  String get constellationBody =>
      'Каждое упражнение формирует личную сигнатуру силы. Яркость отражает медианный класс.';

  @override
  String get constellationEmptyBody =>
      'Слабые координаты показывают будущую сигнатуру, которую откроют первые контрольные подходы.';

  @override
  String get passportStepLiftTitle => 'Результат создаёт запись';

  @override
  String get passportStepLiftBody =>
      'Лучший расчётный 1ПМ нормализуется относительно веса тела.';

  @override
  String get passportStepMedianTitle => 'Середина определяет уровень';

  @override
  String get passportStepMedianBody =>
      'Ранги считаются по медиане группы после исключения крайних 10% с обеих сторон.';

  @override
  String get passportStepBreadthTitle => 'Разносторонность создаёт паспорт';

  @override
  String get passportStepBreadthBody =>
      'Общий класс — медиана минимум трёх рейтинговых упражнений.';

  @override
  String get aiSuggest => 'AI-РАЗБОР';

  @override
  String get aiReviewPlan => 'Сверить план с вашей историей и результатами';

  @override
  String get aiReviewStagedTitle => 'AI-разбор подготовлен';

  @override
  String get aiReviewStagedBody =>
      'GymControl уже безопасно собирает на сервере тренировку, недавнюю историю, статистику аккаунта и замеры. Подключите модель, чтобы активировать финальный шаг анализа.';

  @override
  String get aiReviewFailed =>
      'Не удалось подготовить разбор. Повторите, когда сервер будет доступен.';

  @override
  String get buildWarmup => 'Собрать разминку';

  @override
  String previousCompact(String value) {
    return 'БЫЛО $value';
  }

  @override
  String get trainingBrief => 'ТРЕНИРОВОЧНЫЙ ОРИЕНТИР';

  @override
  String get passportSignal => 'Сигнал паспорта';

  @override
  String get passportFirstBenchmark =>
      'Запишите контрольный подход на следующей тренировке. Теперь обычная тренировка может автоматически открыть первую запись паспорта.';

  @override
  String passportCalibration(int count) {
    return 'Калибровка паспорта · $count/3';
  }

  @override
  String passportCalibrationBody(int count) {
    return 'Добавьте ещё контрольных упражнений: $count. После этого откроется общий класс.';
  }

  @override
  String get passportClosestPromotion => 'Ближайшее повышение';

  @override
  String passportPromotionBody(String exercise, String rank, String next) {
    return '$exercise · класс $rank → $next. Самый ясный путь вперёд.';
  }

  @override
  String get passportHighestClass => 'Высший класс паспорта';

  @override
  String get passportHighestClassBody =>
      'Ваши контрольные упражнения достигли высшего доступного класса.';

  @override
  String get workoutComplete => 'Тренировка завершена';

  @override
  String get sessionSealed => 'СЕССИЯ ЗАФИКСИРОВАНА';

  @override
  String get sessionSealedBody =>
      'Сохранено на устройстве. Недельная серия и поддерживаемые контрольные упражнения синхронизируются с Силовым паспортом.';

  @override
  String setLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ПОДХОДА ЗАПИСАНО',
      many: 'ПОДХОДОВ ЗАПИСАНО',
      few: 'ПОДХОДА ЗАПИСАНО',
      one: 'ПОДХОД ЗАПИСАН',
    );
    return '$_temp0';
  }

  @override
  String get volumeLifted => 'ПОДНЯТЫЙ ОБЪЁМ';

  @override
  String get done => 'ГОТОВО';

  @override
  String get missionDebrief => 'РАЗБОР МИССИИ';

  @override
  String get sealed => 'ПРИНЯТО';

  @override
  String get baselineEstablished => 'Точка отсчёта создана';

  @override
  String get baselineEstablishedBody =>
      'Эта тренировка станет ориентиром для следующего сравнения.';

  @override
  String get outputRising => 'Сигнал усиливается';

  @override
  String outputRisingBody(int percent) {
    return 'Рабочий объём на $percent% выше сопоставимых подходов прошлой тренировки.';
  }

  @override
  String get outputSteady => 'Сигнал стабилен';

  @override
  String get outputSteadyBody =>
      'Сопоставимые рабочие подходы остались в устойчивом диапазоне.';

  @override
  String get recoverySignal => 'Сигнал восстановления';

  @override
  String get recoverySignalBody =>
      'Объём ниже прошлой тренировки. Это контекст восстановления, а не потерянная серия.';

  @override
  String get sessionDuration => 'ДЛИТЕЛЬНОСТЬ';

  @override
  String get shareRecord => 'ПОДЕЛИТЬСЯ';

  @override
  String get shareFailed => 'Не удалось подготовить карточку тренировки';

  @override
  String get trainingRecord => 'Запись тренировки';

  @override
  String get personalRecord => 'Личный рекорд';

  @override
  String get strongestSignal => 'СИЛЬНЕЙШИЙ ПОДХОД';

  @override
  String get estimatedOneRmShort => 'РАСЧ. 1ПМ';

  @override
  String get passportEntries => 'ПАСПОРТ';

  @override
  String get signalTrail => 'Траектория сигнала';

  @override
  String get signalBaseline => 'Формируем сигнал';

  @override
  String get signalRising => 'Силовой сигнал растёт';

  @override
  String get signalStable => 'Тренировочный сигнал стабилен';

  @override
  String get signalEasing => 'Сигнал нагрузки снижен';

  @override
  String signalDelta(int percent) {
    return '$percent% от первой точки в этом периоде.';
  }

  @override
  String get signalPlateauBody =>
      'Последние точки образуют плато — можно изменить нагрузку, повторы или восстановление.';

  @override
  String get signalBaselineBody =>
      'Ещё несколько тренировок покажут направление этого сигнала.';

  @override
  String get notEnoughSignalData =>
      'Для этого периода пока недостаточно данных';

  @override
  String get recoveryOrbit => 'Орбита восстановления';

  @override
  String get recoveryOrbitBaseline => 'Ждём первую орбиту';

  @override
  String get recoveryOrbitBaselineBody =>
      'Ритм тренировок появится здесь после первой завершённой сессии.';

  @override
  String get recoveryOrbitRecovery => 'Окно восстановления';

  @override
  String get recoveryOrbitRecoveryBody =>
      'Недавняя нагрузка резко выросла. Спокойный день поможет её закрепить.';

  @override
  String get recoveryOrbitReady => 'Орбита активна';

  @override
  String get recoveryOrbitReadyBody =>
      'Последняя тренировка была недавно. Следующую стоит провести осознанно.';

  @override
  String get recoveryOrbitBalanced => 'Ритм сбалансирован';

  @override
  String get recoveryOrbitBalancedBody =>
      'Тренировки и паузы между ними складываются в размеренный ритм.';

  @override
  String get recoveryOrbitReturning => 'Вектор возвращения';

  @override
  String get recoveryOrbitReturningBody =>
      'Орбита затихла. Вернитесь с контролируемой тренировкой, а не с проверкой сил.';

  @override
  String orbitActiveDays(int count) {
    return '$count/14 АКТИВНО';
  }

  @override
  String get daysSinceTraining => 'ДНЕЙ С ТРЕНИРОВКИ';

  @override
  String get recoveryOrbitDisclaimer =>
      'Сигнал основан на ритме записанных тренировок и не является медицинской оценкой готовности.';

  @override
  String get usePreviousSet => 'Подставить значения прошлого подхода';

  @override
  String get difficultyNormal => 'Обычная';

  @override
  String get difficultyDeload => 'Разгрузочная';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get syncLedger => 'Журнал синхронизации';

  @override
  String get syncCurrent => 'Все изменения надёжно синхронизированы';

  @override
  String get syncOfflineSafe => 'Офлайн · изменения сохранены на устройстве';

  @override
  String syncPending(int count) {
    return 'Ожидают синхронизации: $count';
  }

  @override
  String syncRejected(int count) {
    return 'Требуют внимания: $count · нажмите, чтобы повторить';
  }

  @override
  String offlinePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения синхронизируются позже',
      many: '$count изменений синхронизируются позже',
      few: '$count изменения синхронизируются позже',
      one: '1 изменение синхронизируется позже',
    );
    return 'Офлайн · $_temp0';
  }

  @override
  String get offlineSaved => 'Офлайн · изменения сохранены на устройстве';

  @override
  String syncingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения',
      many: '$count изменений',
      few: '$count изменения',
      one: '1 изменение',
    );
    return 'Синхронизация: $_temp0…';
  }

  @override
  String get notSet => 'Не указано';

  @override
  String get weightUnits => 'Единицы веса';

  @override
  String get addNote => 'Добавить заметку';

  @override
  String get editNote => 'Изменить заметку';

  @override
  String get groupWithNext => 'Объединить со следующим…';

  @override
  String get extendGroup => 'Добавить следующее в группу…';

  @override
  String get removeExerciseGroup => 'Разъединить группу';

  @override
  String get moveUp => 'Переместить выше';

  @override
  String get moveDown => 'Переместить ниже';

  @override
  String get removeExercise => 'Удалить упражнение';

  @override
  String get trainingGroup => 'Тренировочная группа';

  @override
  String get trainingGroupBody =>
      'В группе отдых начинается только после завершения полного круга упражнений.';

  @override
  String get superset => 'Суперсет';

  @override
  String get circuit => 'Круг';

  @override
  String get intervalBlock => 'Интервальный блок';

  @override
  String get exerciseNote => 'Заметка к упражнению';

  @override
  String get exerciseNoteHint => 'Техника, боль, ориентир на следующий раз…';

  @override
  String get quitWorkoutQuestion => 'Выйти из тренировки?';

  @override
  String get quitWorkoutBody =>
      'Тренировка и все отмеченные подходы будут удалены.';

  @override
  String get keepGoing => 'Продолжить';

  @override
  String get quit => 'Выйти';

  @override
  String get finishWorkoutQuestion => 'Завершить тренировку?';

  @override
  String finishWorkoutBody(int done, int total) {
    return 'Завершено подходов: $done из $total. Выберите способ завершения.';
  }

  @override
  String get finishWithoutSaving => 'Завершить без сохранения';

  @override
  String get saveKeepRoutine => 'Сохранить · не менять план';

  @override
  String get finishAndSave => 'Завершить и сохранить';

  @override
  String get saveUpdateRoutine => 'Сохранить · обновить план';

  @override
  String get couldNotSaveWorkout => 'Не удалось сохранить тренировку';

  @override
  String get setColumn => 'ПОДХОД';

  @override
  String get setType => 'Тип подхода';

  @override
  String get progressionTag => 'Отметить прогресс…';

  @override
  String progressionValue(String value) {
    return 'Прогресс: $value';
  }

  @override
  String get setProgressQuestion => 'В чём был прогресс подхода?';

  @override
  String get noProgressionTag => 'Без отметки прогресса';

  @override
  String get perceivedExertion => 'Субъективная тяжесть';

  @override
  String get perceivedExertionQuestion => 'Насколько тяжёлым был подход?';

  @override
  String get clearRpe => 'Очистить RPE';

  @override
  String get startNewWorkoutQuestion => 'Начать новую тренировку?';

  @override
  String get activeWorkoutBody =>
      'У вас уже идёт активная тренировка. Новая тренировка заменит её.';

  @override
  String get resumeActive => 'Продолжить активную';

  @override
  String get startNew => 'Начать новую';

  @override
  String get configureWorkout => 'Настройка тренировки';

  @override
  String get configureWorkoutBody =>
      'Необязательные и альтернативные упражнения можно менять перед каждым запуском.';

  @override
  String get optional => 'Необязательно';

  @override
  String get chooseOne => 'ВЫБЕРИТЕ ОДНО';

  @override
  String get alternative => 'Альтернатива';

  @override
  String get saved => 'Сохранено';

  @override
  String get copySavedBody =>
      'Приватная копия добавлена в ваши тренировки. Откройте «Мои», чтобы запустить или изменить её.';

  @override
  String get couldNotSaveCopy => 'Не удалось сохранить копию';

  @override
  String get whatWorks => 'Что хорошо';

  @override
  String get watch => 'Обратите внимание';

  @override
  String get nextFocus => 'Следующий фокус';

  @override
  String get deleteWorkoutQuestion => 'Удалить тренировку?';

  @override
  String get workoutHistory => 'История тренировок';

  @override
  String get volume => 'Объём';

  @override
  String get averageTime => 'Среднее время';

  @override
  String get streak => 'Серия';

  @override
  String get ranked => 'В рейтинге';

  @override
  String get sessions => 'Сессии';

  @override
  String get time => 'Время';

  @override
  String get hardSets => 'Тяжёлые подходы';

  @override
  String get longestWorkout => 'Самая долгая тренировка';

  @override
  String get favoriteExercise => 'Любимое упражнение';

  @override
  String get strongestBodyweight => 'Сильнейшее к весу тела';

  @override
  String get name => 'Название';

  @override
  String get imageUrl => 'Ссылка на изображение';

  @override
  String get description => 'Описание';

  @override
  String get bodyMeasurements => 'Замеры тела';

  @override
  String get deleteMeasurementQuestion => 'Удалить замер?';

  @override
  String deleteMeasurementBody(String date) {
    return 'Запись от $date будет удалена.';
  }

  @override
  String get couldNotLoadRetry => 'Не удалось загрузить · Повторить';

  @override
  String get saveMeasurement => 'Сохранить замер';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get support => 'Поддержка';

  @override
  String get logoutQuestion => 'Вы уверены, что хотите выйти?';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountCaption =>
      'Навсегда удалит тренировки, историю упражнений и профиль. Это действие нельзя отменить.';

  @override
  String get deleteAccountBody =>
      'Аккаунт, тренировки, история упражнений и профиль будут удалены навсегда. Это действие нельзя отменить.';

  @override
  String get couldNotDeleteAccount => 'Не удалось удалить аккаунт';

  @override
  String get rename => 'Переименовать';

  @override
  String get deleteFolder => 'Удалить папку';

  @override
  String deleteFolderQuestion(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String moveWorkout(String name) {
    return 'Переместить «$name»';
  }

  @override
  String get defaultFolder => 'Основная папка';

  @override
  String get couldNotSaveChanges => 'Не удалось сохранить изменения';

  @override
  String get sortWorkouts => 'Сортировка тренировок';

  @override
  String get newFolder => 'Новая папка';

  @override
  String openWorkout(String name) {
    return 'Открыть $name';
  }

  @override
  String get couldNotVerifyPro => 'Не удалось проверить доступ Pro';

  @override
  String get warmupSet => 'Разминка';

  @override
  String get warmupSetBody => 'Не входит в рабочий объём';

  @override
  String get workingSet => 'Рабочий';

  @override
  String get workingSetBody => 'Учитывается в объёме и рекордах';

  @override
  String get failureSet => 'До отказа';

  @override
  String get failureSetBody => 'Выполнен до мышечного отказа';

  @override
  String get dropSet => 'Дроп-сет';

  @override
  String get dropSetBody => 'Снижение веса без полного отдыха';

  @override
  String get heavierWeight => 'Больше вес';

  @override
  String get greaterAmplitude => 'Больше амплитуда';

  @override
  String get betterEfficiency => 'Выше эффективность';

  @override
  String get meoSet => 'MEO / myo-rep подход';

  @override
  String get weightKgLabel => 'Вес (кг)';

  @override
  String get heightCmLabel => 'Рост (см)';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get noDiagnostics => 'Нет данных для отправки';

  @override
  String get diagnosticsEmpty => 'Локальный журнал диагностики сейчас пуст.';

  @override
  String get sendDiagnosticsQuestion => 'Отправить диагностику?';

  @override
  String sendDiagnosticsBody(int count) {
    return 'В поддержку GymControl будут отправлены технические события: $count. Токены, почта, содержимое тренировок, комментарии и трассировки не передаются.';
  }

  @override
  String get diagnosticsSent => 'Диагностика отправлена';

  @override
  String diagnosticsSentBody(int count, String reference) {
    return 'Отправлено событий: $count. Номер: $reference';
  }

  @override
  String get diagnosticsFailed => 'Не удалось отправить диагностику';

  @override
  String get diagnosticsFailedBody =>
      'События остались на устройстве. Проверьте подключение и повторите попытку.';

  @override
  String get shareDiagnostics =>
      'Автоматически делиться технической диагностикой';

  @override
  String get diagnosticsPrivacyBody =>
      'Помогает находить ошибки приложения. Содержит только коды событий, версию приложения и платформу; без почты, тренировок, токенов и трассировок.';

  @override
  String get exerciseIllustrations => 'Иллюстрации упражнений';

  @override
  String get exerciseIllustrationsCredit =>
      'Иллюстрации мышц © Everkinetic используются по лицензии Creative Commons Attribution-ShareAlike (CC BY-SA).';

  @override
  String get exerciseData => 'Данные упражнений';

  @override
  String get exerciseDataCredit =>
      'Каталог основан на free-exercise-db, опубликованном в общественном достоянии по лицензии The Unlicense.';

  @override
  String get warmupCalculator => 'Расчёт разминки';

  @override
  String get workingKg => 'Рабочий вес, кг';

  @override
  String get barKg => 'Гриф, кг';

  @override
  String get plateCalculator => 'Расчёт блинов';

  @override
  String get totalKg => 'Общий вес, кг';

  @override
  String get pickExercise => 'Выберите упражнение';

  @override
  String get recent => 'Недавние';

  @override
  String get favorites => 'Избранное';

  @override
  String get anyEquipment => 'Любое оборудование';

  @override
  String get optionalBody => 'Можно включать или исключать перед запуском';

  @override
  String get alternativePrevious => 'Альтернатива предыдущему';

  @override
  String get alternativePreviousBody =>
      'Перед запуском выбирается одно из двух';

  @override
  String get restSeconds => 'Отдых (с)';

  @override
  String get repsShort => 'повт.';
}
