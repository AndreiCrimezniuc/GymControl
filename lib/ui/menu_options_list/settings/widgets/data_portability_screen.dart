import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gymboss/data/repositories/account_data_repository.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/sync/network_failure.dart';
import 'package:gymboss/domain/models/import/history_csv_parser.dart';
import 'package:gymboss/ui/core/theme/theme_controller.dart';
import 'package:gymboss/ui/core/ui/widgets/app_dialog.dart';
import 'package:gymboss/ui/core/ui/widgets/app_page.dart';

class DataPortabilityScreen extends StatefulWidget {
  const DataPortabilityScreen({super.key});

  @override
  State<DataPortabilityScreen> createState() => _DataPortabilityScreenState();
}

class _DataPortabilityScreenState extends State<DataPortabilityScreen> {
  late final AccountDataRepository _repository;
  final _csv = TextEditingController();
  bool _busy = false;

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';

  @override
  void initState() {
    super.initState();
    _repository = AccountDataRepository(
      client: context.read<AuthenticatedClient>(),
    );
  }

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _export(bool json) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = json
          ? await _repository.exportJson()
          : await _repository.exportCsv();
      if (!mounted) return;
      final extension = json ? 'json' : 'csv';
      await SharePlus.instance.share(
        ShareParams(
          title: 'GymControl export',
          text: _ru
              ? 'Резервная копия данных GymControl'
              : 'GymControl data backup',
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType: json ? 'application/json' : 'text/csv',
            ),
          ],
          fileNameOverrides: ['gymcontrol-export.$extension'],
        ),
      );
    } catch (error) {
      if (mounted) await _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewImport() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final parsed = HistoryCsvParser.parse(_csv.text);
      final preview = await _repository.importRows(parsed.rows, dryRun: true);
      if (!mounted) return;
      final unknown = preview.unknownExercises;
      final message = _ru
          ? '${preview.rows} подходов в ${preview.sessions} тренировках. '
                'Пропущено неполных строк: ${parsed.skippedRows}.\n\n'
                '${unknown.isEmpty ? 'Все упражнения распознаны.' : 'Будут созданы: ${unknown.join(', ')}'}'
          : '${preview.rows} sets across ${preview.sessions} workouts. '
                'Incomplete rows skipped: ${parsed.skippedRows}.\n\n'
                '${unknown.isEmpty ? 'Every exercise was matched.' : 'Will be created: ${unknown.join(', ')}'}';
      final confirmed = await showAppDialog<bool>(
        context,
        title: _ru ? 'Проверка импорта' : 'Import review',
        message: message,
        actions: [
          AppDialogAction(
            _ru ? 'Отмена' : 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            _ru ? 'Импортировать' : 'Import',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
      if (confirmed != true || !mounted) return;
      final result = await _repository.importRows(parsed.rows, dryRun: false);
      if (!mounted) return;
      _csv.clear();
      await showAppDialog<void>(
        context,
        title: _ru ? 'История импортирована' : 'History imported',
        message: _ru
            ? '${result.rows} подходов добавлены. Повторный импорт безопасен: дубликаты не появятся.'
            : '${result.rows} sets added. Re-importing the same file is safe and will not create duplicates.',
        actions: [
          AppDialogAction('OK', onPressed: () => Navigator.pop(context)),
        ],
      );
    } on FormatException catch (error) {
      if (mounted) await _error(error.message);
    } catch (error) {
      if (mounted) await _error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _error(Object error) {
    final offline = isTransientNetworkFailure(error);
    return showAppDialog<void>(
      context,
      title: offline
          ? (_ru
                ? 'Нужно подключение к интернету'
                : 'Internet connection needed')
          : (_ru ? 'Не получилось' : 'Could not complete'),
      message: offline
          ? (_ru
                ? 'Полный импорт и экспорт обращаются к вашему аккаунту. Сохранённые на устройстве тренировки и изменения останутся на месте.'
                : 'Full import and export use your account. Workouts and changes already saved on this device will stay here.')
          : error.toString(),
      actions: [AppDialogAction('OK', onPressed: () => Navigator.pop(context))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPage(
      title: _ru ? 'Импорт и экспорт' : 'Import & export',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Card(
            title: _ru ? 'Забрать свои данные' : 'Take your data with you',
            body: _ru
                ? 'CSV открывается в таблицах и содержит каждый выполненный подход. JSON — полная резервная копия профиля, программ и истории.'
                : 'CSV opens in any spreadsheet and lists every performed set. JSON is a complete backup of your profile, programs and history.',
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _busy ? null : () => _export(false),
                    child: const Text('CSV'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    color: c.iconBg,
                    onPressed: _busy ? null : () => _export(true),
                    child: Text('JSON', style: TextStyle(color: c.textPrimary)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: _ru ? 'Перенести историю' : 'Bring your history',
            body: _ru
                ? 'Вставьте CSV из Strong, Hevy или своей таблицы. Сначала GymControl покажет проверку — ничего не запишется без подтверждения.'
                : 'Paste a CSV from Strong, Hevy or your own spreadsheet. GymControl previews it first; nothing is written before confirmation.',
            child: Column(
              children: [
                Container(
                  height: 190,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: CupertinoTextField.borderless(
                    controller: _csv,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    placeholder:
                        'date,exercise,weight_kg,reps\n2025-01-20,Bench Press,80,8',
                    placeholderStyle: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _busy ? null : _previewImport,
                    child: _busy
                        ? const CupertinoActivityIndicator()
                        : Text(_ru ? 'Проверить импорт' : 'Review import'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String body;
  final Widget child;

  const _Card({required this.title, required this.body, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: c.textSecondary, height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
